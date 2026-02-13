import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'snackbar.dart';

///lauch URL to a new web browser
launchURL(BuildContext context, String url) async {
  try {
    // Ensure URL has proper protocol
    final launchableUrl = url.startsWith('http') ? url : 'https://$url';
    final uri = Uri.parse(launchableUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      CustomSnack.showErrorSnack(context,
          message: 'Could not launch $url. Please check url');
    }
  } catch (e) {
    CustomSnack.showErrorSnack(context,
        message: 'Could not launch $url. Please check url');
  }
}
