import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../utils/analytics_service.dart';
import '../../utils/linkcard_model.dart';
import '../../utils/social_list.dart';
import '../../utils/social_model.dart';
import '../../utils/url_launcher.dart';
import 'reuseable.dart';

class LinkCard extends StatelessWidget {
  ///This linkcard will be the one showing in appPage
  const LinkCard({
    super.key,
    required this.linkcardModel,
    this.isSample = false,
    this.isEditing = false,
    this.profileOwnerCode,
  });
  final LinkcardModel linkcardModel;
  final bool isSample;

  /// Block onPressed method. Enable overriding gesture from other widget. Defaulted to false
  final bool isEditing;

  /// Profile owner code for analytics tracking
  final String? profileOwnerCode;

  final snackbar = const SnackBar(
    content: Text(
        'To fully customize the card. Register or login with VLag now.'),
  );

  @override
  Widget build(BuildContext context) {
    SocialModel socialModel = SocialLists.getSocial(linkcardModel.exactName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Stack(
      children: [
        Card(
          color: VLagButtonStyle.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            splashColor: Colors.pink.withAlpha(10),
            onTap: !isEditing
                ? () {
                    if (!isSample) {
                      final url = linkcardModel.link!;
                      // Track link click if profile owner code is provided
                      if (profileOwnerCode != null) {
                        final linkId = AnalyticsService.generateLinkId(url);
                        AnalyticsService.trackLinkClick(
                          profileOwnerCode: profileOwnerCode!,
                          linkId: linkId,
                          title: linkcardModel.displayName ?? '',
                          url: url,
                        );
                      }
                      // Ensure URL has proper protocol
                      final launchableUrl = url.startsWith('http') ? url : 'https://$url';
                      launchURL(context, launchableUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(snackbar);
                    }
                  }
                : null,
            child: ListTile(
              leading: FaIcon(
                socialModel.icon,
                color: textColor,
              ),
              title: Text(
                linkcardModel.displayName!,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor),
              ),
              trailing: const Icon(null), //to keep the text centered
            ),
          ),
        ),
      ],
    );
  }
}
