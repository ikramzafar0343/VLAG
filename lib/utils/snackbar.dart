import 'package:flutter/material.dart';

class CustomSnack {
  static void showErrorSnack(BuildContext context, {String message = 'Error'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(message),
      backgroundColor: Colors.redAccent.shade700,
    ));
  }

  static void showSuccessSnack(BuildContext context,
      {String message = 'Success'}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(message),
      backgroundColor: Colors.green.shade700,
    ));
  }

  static void showSnack(BuildContext context,
      {required String message, SnackBarAction? barAction}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      action: barAction,
      behavior: SnackBarBehavior.floating,
      content: Text(message),
      duration: const Duration(milliseconds: 2100),
    ));
  }
}
