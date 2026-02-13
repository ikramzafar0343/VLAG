// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// dart:html is the standard way to interact with DOM in Flutter web
// This is isolated with conditional imports and only used on web platforms
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Web implementation for updating Open Graph meta tags
class MetaTagsUpdaterImpl {
  /// Updates Open Graph meta tags with user profile information
  static Future<void> updateMetaTagsForProfile({
    required String profileCode,
    String? nickname,
    String? subtitle,
    String? profileImageUrl,
  }) async {
    try {
      // Get profile data from Firestore if not provided
      if (nickname == null || profileImageUrl == null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(profileCode)
            .get();
        
        if (doc.exists) {
          final data = doc.data()!;
          nickname ??= data['nickname'] ?? 'VLag Profile';
          subtitle ??= data['subtitle'] ?? 'Visit my VLag profile';
          profileImageUrl ??= data['dpUrl'] ?? 'https://vlagit.com/static/vlag-meta.png';
        } else {
          // Fallback values
          nickname ??= 'VLag Profile';
          subtitle ??= 'Visit my VLag profile';
          profileImageUrl ??= 'https://vlagit.com/static/vlag-meta.png';
        }
      }

      final profileUrl = 'https://vlagit.com/$profileCode';
      final title = '$nickname - VLag Profile';
      final description = (subtitle?.isNotEmpty == true) 
          ? subtitle! 
          : 'Visit my VLag profile to see all my links in one place';

      // Ensure profileImageUrl is not null
      final imageUrl = profileImageUrl ?? 'https://vlagit.com/static/vlag-meta.png';
      
      // Update or create meta tags
      _updateMetaTag('og:title', title);
      _updateMetaTag('og:description', description);
      _updateMetaTag('og:image', imageUrl);
      _updateMetaTag('og:url', profileUrl);
      _updateMetaTag('og:type', 'website');
      _updateMetaTag('og:site_name', 'VLag');

      // Twitter Card meta tags
      _updateMetaTag('twitter:card', 'summary_large_image');
      _updateMetaTag('twitter:title', title);
      _updateMetaTag('twitter:description', description);
      _updateMetaTag('twitter:image', imageUrl);
      _updateMetaTag('twitter:url', profileUrl);

      // Standard meta tags
      _updateMetaTag('title', title);
      _updateMetaTag('description', description);
    } catch (e) {
      print('Error updating meta tags: $e');
    }
  }

  /// Helper method to update or create a meta tag
  static void _updateMetaTag(String property, String content) {
    late html.MetaElement metaTag;
    
    // Handle both property and name attributes
    if (property.startsWith('og:') || property.startsWith('twitter:')) {
      final existing = html.document.querySelector('meta[property="$property"]') as html.MetaElement?;
      if (existing != null) {
        metaTag = existing;
      } else {
        metaTag = html.MetaElement();
        metaTag.setAttribute('property', property);
        html.document.head!.append(metaTag);
      }
    } else {
      // Try to find by name attribute (standard meta tags)
      final existing = html.document.querySelector('meta[name="$property"]') as html.MetaElement?;
      if (existing != null) {
        metaTag = existing;
      } else {
        metaTag = html.MetaElement();
        metaTag.setAttribute('name', property);
        html.document.head!.append(metaTag);
      }
    }

    // Update content (metaTag is guaranteed to be initialized at this point)
    metaTag.setAttribute('content', content);

    // Also update title tag directly
    if (property == 'title') {
      html.document.title = content;
    }
  }

  /// Resets meta tags to default app values
  static void resetToDefault() {
    _updateMetaTag('og:title', 'VLag - A place for all of your social links');
    _updateMetaTag('og:description', 'Let your audiences find you in one place.');
    _updateMetaTag('og:image', 'https://vlagit.com/static/vlag-meta.png');
    _updateMetaTag('og:url', 'https://vlagit.com/');
    _updateMetaTag('title', 'VLag Create - A place for all of your social links');
  }
}
