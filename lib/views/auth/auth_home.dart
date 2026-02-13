import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/adapters.dart';

import '../../constants.dart';
import '../../main.dart' show themeProvider;
import '../../utils/auth_helper.dart';
import '../../utils/snackbar.dart';
import '../../utils/url_launcher.dart';
import '../profilebuilder/editing_page.dart';
import '../widgets/reuseable.dart';

class AuthHome extends StatefulWidget {
  const AuthHome({super.key});
  @override
  State<AuthHome> createState() => _AuthHomeState();
}

class _AuthHomeState extends State<AuthHome> {
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;
  bool _isFacebookLoading = false;
  bool _isAppleAvailable = false;

  @override
  void initState() {
    super.initState();
    _clearHiveData();
    _checkAppleSignInAvailability();
    // Listen to theme changes
    themeProvider.addListener(_onThemeChanged);
  }

  Future<void> _checkAppleSignInAvailability() async {
    final available = await AuthHelper.isAppleSignInAvailable();
    if (mounted) {
      setState(() => _isAppleAvailable = available);
    }
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  ///to make sure it sign in as a new user.
  ///Preserve theme setting when clearing user data
  Future<void> _clearHiveData() async {
    final box = Hive.box(kMainBoxName);
    final savedTheme = box.get('themeMode');
    await box.clear();
    if (savedTheme != null) {
      await box.put('themeMode', savedTheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // Theme toggle button
            IconButton(
              onPressed: () {
                themeProvider.toggleTheme();
              },
              tooltip: themeProvider.isDarkMode
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                size: 22,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34.0),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < 450) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const VLagLogo(),
                    const SizedBox(height: 20),
                    googleButton(context),
                    const SizedBox(height: 8),
                    appleButton(context),
                    const SizedBox(height: 8),
                    facebookButton(context),
                    const SizedBox(height: kIsWeb ? 10 : 8),
                    const SizedBox(height: 20),
                    const Column(
                      children: [
                        PlayStoreButton(),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              return Row(
                children: [
                  const Expanded(child: VLagLogo()),
                  const VerticalDivider(
                    indent: 20.0,
                    endIndent: 20.0,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          googleButton(context),
                          const SizedBox(height: 8),
                          appleButton(context),
                          const SizedBox(height: 8),
                          facebookButton(context),
                          const SizedBox(height: kIsWeb ? 10 : 8),
                          const SizedBox(height: 20),
                          const Column(
                            children: [
                              PlayStoreButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          }),
        ),
      ),
    );
  }

  Widget googleButton(BuildContext context) {
    return ElevatedButton.icon(
      style: VLagButtonStyle.primary,
      onPressed: _isGoogleLoading
          ? null
          : () async {
              setState(() => _isGoogleLoading = true);
              try {
                // Trigger the authentication flow
                await AuthHelper.signInWithGoogle();

                if (!mounted) return;
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "EditingPage"),
                      builder: (_) => const EditPage(),
                    ));
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                setState(() => _isGoogleLoading = false);
                
                // Don't show error for user cancellation
                if (e.code == 'ERROR_ABORTED_BY_USER' || 
                    e.code == 'sign_in_canceled' ||
                    e.message?.toLowerCase().contains('cancel') == true ||
                    e.message?.toLowerCase().contains('abort') == true) {
                  // User cancelled, don't show error
                  return;
                }
                
                // Show specific error message based on error code
                String errorMessage = e.message ?? 'Google sign in failed';
                if (e.code == 'network-request-failed') {
                  errorMessage = 'Network error. Please check your internet connection.';
                } else if (e.code == 'account-exists-with-different-credential') {
                  errorMessage = 'An account already exists with this email.';
                } else if (e.code == 'invalid-credential') {
                  errorMessage = 'Invalid credentials. Please try again.';
                } else if (e.code == 'ERROR_MISSING_CREDENTIALS' || 
                           e.code == 'sign_in_failed' ||
                           e.code == 'invalid_client') {
                  errorMessage = e.message ?? 'Google Sign-In configuration error. Please check Firebase setup.';
                }
                
                debugPrint('Error code: ${e.code}, Error message: $errorMessage');
                CustomSnack.showErrorSnack(context, message: errorMessage);
              } catch (e) {
                if (!mounted) return;
                setState(() => _isGoogleLoading = false);
                
                // Don't show error for user cancellation
                final errorString = e.toString().toLowerCase();
                if (errorString.contains('aborted') || 
                    errorString.contains('cancel') ||
                    errorString.contains('cancelled') ||
                    errorString.contains('user_cancelled')) {
                  // User cancelled, don't show error
                  return;
                }
                
                // Show error with more details for debugging
                String errorMessage = 'Failed to sign in with Google.';
                if (errorString.contains('network') || errorString.contains('connection')) {
                  errorMessage = 'Network error. Please check your internet connection.';
                } else if (errorString.contains('platform_exception')) {
                  errorMessage = 'Google Sign-In configuration error. Please contact support.';
                }
                
                CustomSnack.showErrorSnack(context, message: errorMessage);
                debugPrint('Google Sign-In Error: $e');
              }
            },
      icon: _isGoogleLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : SvgPicture.asset(
              'images/logo/google_g.svg',
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              semanticsLabel: 'Google logo',
            ),
      label: const Text(
        'Sign in with Google',
        style: VLagButtonStyle.buttonText,
      ),
    );
  }

  Widget appleButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade800,
        disabledForegroundColor: Colors.grey.shade400,
        minimumSize: const Size(100, 55),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
      ),
      onPressed: _isAppleLoading
          ? null
          : () async {
              setState(() => _isAppleLoading = true);
              try {
                if (!_isAppleAvailable) {
                  setState(() => _isAppleLoading = false);
                  CustomSnack.showErrorSnack(
                    context,
                    message:
                        'Apple Sign-In is not available on this device.',
                  );
                  return;
                }
                await AuthHelper.signInWithApple();

                if (!mounted) return;
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "EditingPage"),
                      builder: (_) => const EditPage(),
                    ));
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                setState(() => _isAppleLoading = false);
                if (e.code == 'ERROR_ABORTED_BY_USER' ||
                    e.message?.toLowerCase().contains('cancel') == true ||
                    e.message?.toLowerCase().contains('canceled') == true) {
                  return;
                }
                CustomSnack.showErrorSnack(
                  context,
                  message: e.message ?? 'Apple sign in failed',
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _isAppleLoading = false);
                // Don't show error for user cancellation
                if (!e.toString().contains('canceled') && 
                    !e.toString().contains('cancel') &&
                    !e.toString().contains('AuthorizationErrorCode.canceled')) {
                  CustomSnack.showErrorSnack(context,
                      message: 'Failed to Sign in with Apple. Please try again');
                }
              }
            },
      icon: const FaIcon(FontAwesomeIcons.apple, size: 18),
      label: _isAppleLoading
          ? const LoadingIndicator()
          : const Text(
              'Sign in with Apple',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget facebookButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1877F2), // Facebook blue
        foregroundColor: Colors.white,
        minimumSize: const Size(100, 55),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
      ),
      onPressed: _isFacebookLoading
          ? null
          : () async {
              setState(() => _isFacebookLoading = true);
              try {
                await AuthHelper.signInWithFacebook();

                if (!mounted) return;
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "EditingPage"),
                      builder: (_) => const EditPage(),
                    ));
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                setState(() => _isFacebookLoading = false);
                CustomSnack.showErrorSnack(context, 
                    message: e.message ?? 'Facebook sign in failed');
              } catch (e) {
                if (!mounted) return;
                setState(() => _isFacebookLoading = false);
                // Don't show error for user cancellation
                if (!e.toString().contains('aborted') && 
                    !e.toString().contains('cancel')) {
                  CustomSnack.showErrorSnack(context,
                      message: 'Failed to Sign in with Facebook. Please try again');
                }
              }
            },
      icon: const FaIcon(FontAwesomeIcons.facebookF, size: 15),
      label: _isFacebookLoading
          ? const LoadingIndicator()
          : const Text(
              'Sign in with Facebook',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
    );
  }
}

class VLagLogo extends StatelessWidget {
  const VLagLogo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/logo/vlag_app.png',
      width: 100,
    );
  }
}

class PlayStoreButton extends StatelessWidget {
  const PlayStoreButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size(220, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => launchURL(context, kPlayStoreUrl),
            icon: const FaIcon(FontAwesomeIcons.googlePlay, size: 20),
            label: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GET IT ON',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
                ),
                Text(
                  'Google Play',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}
