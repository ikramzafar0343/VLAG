// Conditional import for web
import 'meta_tags_updater_stub.dart'
    if (dart.library.html) 'meta_tags_updater_web.dart' as meta_tags_impl;

/// Utility class to update Open Graph meta tags dynamically for rich link previews
/// This enables rich link previews similar to Linkfly when profiles are shared
class MetaTagsUpdater {
  /// Updates Open Graph meta tags with user profile information
  /// This enables rich link previews similar to Linkfly
  static Future<void> updateMetaTagsForProfile({
    required String profileCode,
    String? nickname,
    String? subtitle,
    String? profileImageUrl,
  }) async {
    await meta_tags_impl.MetaTagsUpdaterImpl.updateMetaTagsForProfile(
      profileCode: profileCode,
      nickname: nickname,
      subtitle: subtitle,
      profileImageUrl: profileImageUrl,
    );
  }

  /// Resets meta tags to default app values
  static void resetToDefault() {
    meta_tags_impl.MetaTagsUpdaterImpl.resetToDefault();
  }
}
