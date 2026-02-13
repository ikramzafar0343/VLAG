import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb, debugPrint;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../firebase_options.dart';

class AuthHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: '',
  );
  static const String _appleRedirectUri = String.fromEnvironment(
    'APPLE_REDIRECT_URI',
    defaultValue: '',
  );

  static bool get _hasAppleAndroidWebConfig =>
      _appleServiceId.isNotEmpty && _appleRedirectUri.isNotEmpty;

  // ============== GOOGLE SIGN IN ==============
  static Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Use Firebase Auth directly for web - more reliable
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? DefaultFirebaseOptions.ios.iosClientId
              : null,
        );

        // Sign out first to ensure fresh sign-in (clears any cached credentials)
        try {
          await googleSignIn.signOut();
          debugPrint('Google Sign-In - Signed out from previous session');
        } catch (e) {
          debugPrint('Google Sign-In - Sign out error (ignored): $e');
        }

        // Sign in with Google
        debugPrint('Google Sign-In - Starting sign-in flow...');
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'ERROR_ABORTED_BY_USER',
            message: 'Sign in aborted by user',
          );
        }

        debugPrint('Google user signed in: ${googleUser.email}');

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        debugPrint(
          'Access token: ${googleAuth.accessToken != null ? "present" : "missing"}',
        );
        debugPrint(
          'ID token: ${googleAuth.idToken != null ? "present" : "missing"}',
        );

        // Validate that we have at least one usable token
        if (googleAuth.accessToken == null && googleAuth.idToken == null) {
          debugPrint(
            'Missing credentials - AccessToken: ${googleAuth.accessToken}, IDToken: ${googleAuth.idToken}',
          );
          throw FirebaseAuthException(
            code: 'ERROR_MISSING_CREDENTIALS',
            message:
                'Failed to obtain Google authentication credentials. Please check your Firebase configuration and SHA-1 fingerprint.',
          );
        }

        // Create a new credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Once signed in, return the UserCredential
        debugPrint('Signing in with Firebase credential...');
        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'Google Sign In FirebaseAuthException: ${e.code} - ${e.message}');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Google Sign In Error: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');

      // Convert generic exceptions to FirebaseAuthException for better handling
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('socket')) {
        throw FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network error. Please check your internet connection.',
        );
      } else if (errorString.contains('platform_exception') ||
          errorString.contains('sign_in_required') ||
          errorString.contains('sign_in_failed') ||
          errorString
              .contains('10:') || // Common Google Sign-In error code format
          errorString.contains('12500') || // DEVELOPER_ERROR
          errorString.contains('12501')) {
        // INTERNAL_ERROR
        // Platform exception from Google Sign-In - usually configuration issue
        String detailedMessage = 'Google Sign-In configuration error. ';
        if (errorString.contains('12500')) {
          detailedMessage +=
              'Please verify your SHA-1 fingerprint is added to Firebase Console.';
        } else if (errorString.contains('12501')) {
          detailedMessage +=
              'Please check your OAuth client configuration in Firebase.';
        } else {
          detailedMessage +=
              'Please check your Firebase configuration and SHA-1 fingerprint.';
        }

        throw FirebaseAuthException(
          code: 'sign_in_failed',
          message: detailedMessage,
        );
      } else if (errorString.contains('invalid_client') ||
          errorString.contains('unauthorized_client')) {
        throw FirebaseAuthException(
          code: 'invalid_client',
          message:
              'Invalid OAuth client. Please verify your Firebase configuration.',
        );
      }
      rethrow;
    }
  }

  static Future<void> googleSignOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
  }

  // ============== APPLE SIGN IN ==============
  /// Generates a cryptographically secure random nonce
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the sha256 hash of [input] in hex notation
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<UserCredential> signInWithApple() async {
    try {
      if (kIsWeb) {
        // Use Firebase Auth directly for web
        OAuthProvider appleProvider = OAuthProvider('apple.com');
        appleProvider.addScope('email');
        appleProvider.addScope('name');

        return await _auth.signInWithPopup(appleProvider);
      } else {
        final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
        if (isAndroid && !_hasAppleAndroidWebConfig) {
          throw FirebaseAuthException(
            code: 'invalid-configuration',
            message:
                'Apple Sign-In on Android requires configuration. Build with --dart-define=APPLE_SERVICE_ID=... and --dart-define=APPLE_REDIRECT_URI=...',
          );
        }

        // iOS uses native flow; Android uses web flow
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        // Request credential for Apple sign in
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
          webAuthenticationOptions: isAndroid
              ? WebAuthenticationOptions(
                  clientId: _appleServiceId,
                  redirectUri: Uri.parse(_appleRedirectUri),
                )
              : null,
        );

        if (appleCredential.identityToken == null) {
          throw FirebaseAuthException(
            code: 'missing-identity-token',
            message:
                'Apple Sign-In did not return an identity token. Please retry.',
          );
        }

        // Create an OAuthCredential from the credential returned by Apple
        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
          rawNonce: rawNonce,
        );

        // Sign in with Firebase
        final userCredential =
            await _auth.signInWithCredential(oauthCredential);

        // Apple only returns user name on first sign in, so we need to update profile
        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          final displayName = [
            appleCredential.givenName ?? '',
            appleCredential.familyName ?? '',
          ].where((s) => s.isNotEmpty).join(' ');

          if (displayName.isNotEmpty) {
            await userCredential.user?.updateDisplayName(displayName);
          }
        }

        return userCredential;
      }
    } catch (e) {
      debugPrint('Apple Sign In Error: $e');
      rethrow;
    }
  }

  /// Check if Apple Sign In is available on this device
  static Future<bool> isAppleSignInAvailable() async {
    if (kIsWeb) {
      // Show Apple Sign In on web - it will use popup/redirect flow
      return true;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return true;
    }
    try {
      return await SignInWithApple.isAvailable();
    } catch (e) {
      debugPrint('Apple Sign In availability check error: $e');
      return false;
    }
  }

  // ============== FACEBOOK SIGN IN ==============
  static Future<UserCredential> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // Use Firebase Auth directly for web
        FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        facebookProvider.addScope('email');
        facebookProvider.addScope('public_profile');

        return await _auth.signInWithPopup(facebookProvider);
      } else {
        // Mobile platforms use flutter_facebook_auth package
        final LoginResult loginResult = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );

        if (loginResult.status == LoginStatus.cancelled) {
          throw FirebaseAuthException(
            code: 'ERROR_ABORTED_BY_USER',
            message: 'Sign in aborted by user',
          );
        }

        if (loginResult.status == LoginStatus.failed) {
          throw FirebaseAuthException(
            code: 'ERROR_FACEBOOK_LOGIN_FAILED',
            message: loginResult.message ?? 'Facebook login failed',
          );
        }

        if (loginResult.accessToken == null) {
          throw FirebaseAuthException(
            code: 'ERROR_NO_ACCESS_TOKEN',
            message: 'No access token received from Facebook',
          );
        }

        // Create a credential from the access token
        final OAuthCredential facebookAuthCredential =
            FacebookAuthProvider.credential(
                loginResult.accessToken!.tokenString);

        // Sign in with Firebase
        return await _auth.signInWithCredential(facebookAuthCredential);
      }
    } catch (e) {
      debugPrint('Facebook Sign In Error: $e');
      rethrow;
    }
  }

  static Future<void> facebookSignOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}
    }
  }

  // ============== GENERAL SIGN OUT ==============
  static Future<void> signOut() async {
    await _auth.signOut();

    // Try to sign out from Google if signed in
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}

    // Try to sign out from Facebook if signed in
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
