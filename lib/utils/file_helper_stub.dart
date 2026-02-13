import 'package:firebase_storage/firebase_storage.dart';

/// Stub implementation for web platform.
/// This file is used when dart:io is not available.
Future<void> uploadFile(Reference reference, String path) async {
  // This should never be called on web as we use putData() instead.
  // The kIsWeb check in profile_builder_helper.dart prevents this path.
  throw UnsupportedError('File upload via path is not supported on web');
}
