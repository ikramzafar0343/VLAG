// ignore_for_file: deprecated_member_use
// Firebase Dynamic Links is deprecated but still functional until August 2025
// See: https://firebase.google.com/support/dynamic-links-faq

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/constants.dart';

class DynamicLinkApi {
  /// Generates a short URL using Firebase Dynamic Links.
  /// 
  /// Returns `null` on Web platform as Dynamic Links are not supported.
  /// On Android/iOS, returns the generated short URL.
  static Future<String?> generateShortUrl(
      {required String profileUrl,
      required DocumentSnapshot<Map<String, dynamic>> userInfo}) async {
    // Firebase Dynamic Links is not supported on Web
    if (kIsWeb) {
      // Return null to indicate dynamic links unavailable on web
      // Callers should handle this gracefully (e.g., use original URL)
      return null;
    }

    var parameters = DynamicLinkParameters(
      uriPrefix: 'https://$kPageUrl',
      link: Uri.parse(profileUrl),
      googleAnalyticsParameters: const GoogleAnalyticsParameters(
        campaign: 'advanced-link',
        medium: 'social',
        source: 'app',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
          title: '${userInfo.data()!["nickname"]}',
          description:
              'VLag. Connect audiences to all of your content with just one link.',
          imageUrl: Uri.parse(userInfo.data()!["dpUrl"])),
    );

    var shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }
}
