import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';

// Conditional import for File (mobile only)
import 'file_helper_stub.dart'
    if (dart.library.io) 'file_helper_io.dart' as file_helper;

final FirebaseStorage _storageInstance = FirebaseStorage.instance;
final FirebaseAuth _authInstance = FirebaseAuth.instance;
final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

class ProfileBuilderHelper {
  /// Allows pick/capture image, upload to Storage bucket, and returns `url`.
  /// Works on Web (using putData) and Mobile (using putFile).
  static Future<String?> updateProfilePicture(ImageSource source) async {
    XFile? pickedFile;

    pickedFile = await ImagePicker().pickImage(
        source: source, imageQuality: 70, maxWidth: 300, maxHeight: 200);

    if (pickedFile == null) return null;

    if (AppConfig.useCpanelProfileImages) {
      final url = await apiService.uploadProfileImage(pickedFile);
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }

    final Reference reference =
        _storageInstance.ref('userdps').child(_authInstance.currentUser!.uid);

    // if already exist, it will be overwritten
    if (kIsWeb) {
      // Web: use readAsBytes() + putData()
      final bytes = await pickedFile.readAsBytes();
      await reference.putData(bytes);
    } else {
      // Mobile: use File + putFile()
      await file_helper.uploadFile(reference, pickedFile.path);
    }

    final String url = await reference.getDownloadURL();
    return url;
  }

  /// Completely delete all user data and sign out
  /// This includes: profile picture, user document, analytics data
  static Future<void> deleteAccountAndSignOut(String profileCode, String? imageUrl) async {
    try {
      // 1. Delete profile picture from Storage
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          if (imageUrl.contains('firebasestorage.googleapis.com')) {
            await _storageInstance.refFromURL(imageUrl).delete();
            debugPrint('Profile picture deleted');
          }
        } catch (e) {
          debugPrint("Can't delete profile picture: $e");
        }
      }

      // 2. Delete analytics data (subcollection)
      await _deleteAnalyticsData(profileCode);

      // 3. Delete user document from Firestore
      await _firestoreInstance.collection('users').doc(profileCode).delete();
      debugPrint('User document deleted');

      // 4. Delete analytics events related to this user
      await _deleteAnalyticsEvents(profileCode);

      // 5. Sign out from all providers
      await _signOutFromAllProviders();
      
      debugPrint('Account deletion completed successfully');
    } catch (e) {
      debugPrint('Error during account deletion: $e');
      // Still try to sign out even if deletion fails
      await _signOutFromAllProviders();
      rethrow;
    }
  }

  /// Delete all analytics data for a user
  static Future<void> _deleteAnalyticsData(String profileCode) async {
    try {
      final analyticsRef = _firestoreInstance
          .collection('users')
          .doc(profileCode)
          .collection('analytics');

      // Get all documents in analytics collection
      final analyticsSnapshot = await analyticsRef.get();
      
      for (final doc in analyticsSnapshot.docs) {
        // If this is the summary doc, delete links subcollection first
        if (doc.id == 'summary') {
          final linksSnapshot = await doc.reference.collection('links').get();
          for (final linkDoc in linksSnapshot.docs) {
            await linkDoc.reference.delete();
          }
        }
        await doc.reference.delete();
      }
      debugPrint('Analytics data deleted');
    } catch (e) {
      debugPrint('Error deleting analytics data: $e');
    }
  }

  /// Delete analytics events related to this user
  static Future<void> _deleteAnalyticsEvents(String profileCode) async {
    try {
      final eventsSnapshot = await _firestoreInstance
          .collection('analytics_events')
          .where('uid', isEqualTo: profileCode)
          .get();

      for (final doc in eventsSnapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('Analytics events deleted');
    } catch (e) {
      debugPrint('Error deleting analytics events: $e');
    }
  }

  /// Sign out from Firebase and all OAuth providers
  static Future<void> _signOutFromAllProviders() async {
    // Sign out from Firebase Auth
    await _authInstance.signOut();
    debugPrint('Signed out from Firebase');

    // Sign out from Google
    if (!kIsWeb) {
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
          await googleSignIn.disconnect(); // Revoke access
          debugPrint('Signed out and disconnected from Google');
        }
      } catch (e) {
        debugPrint('Error signing out from Google: $e');
      }

      // Sign out from Facebook
      try {
        await FacebookAuth.instance.logOut();
        debugPrint('Signed out from Facebook');
      } catch (e) {
        debugPrint('Error signing out from Facebook: $e');
      }
    }
  }

  /// Legacy method - kept for backward compatibility
  /// Use deleteAccountAndSignOut instead
  static Future<void> resetAccountData(
      String imageUrl, DocumentReference userDocument) async {
    try {
      _storageInstance.refFromURL(imageUrl).delete();
    } catch (e) {
      print("Can't delete profile picture, ignoring..");
    }

    await userDocument.delete();
  }
}
