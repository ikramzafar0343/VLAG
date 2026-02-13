import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Mobile implementation using dart:io File.
/// This file is used when dart:io is available (Android/iOS).
Future<void> uploadFile(Reference reference, String path) async {
  final File file = File(path);
  await reference.putFile(file);
}
