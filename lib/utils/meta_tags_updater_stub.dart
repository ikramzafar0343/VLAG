// Stub implementation for non-web platforms

/// Stub implementation - does nothing on non-web platforms
class MetaTagsUpdaterImpl {
  static Future<void> updateMetaTagsForProfile({
    required String profileCode,
    String? nickname,
    String? subtitle,
    String? profileImageUrl,
  }) async {
    // No-op on non-web platforms
  }

  static void resetToDefault() {
    // No-op on non-web platforms
  }
}
