import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../constants.dart';
import '../../model/my_user.dart';
import '../../utils/auth_helper.dart';
import '../../utils/profile_builder_helper.dart';
import '../../utils/snackbar.dart';
import '../../utils/url_launcher.dart';
import '../auth/auth_home.dart';
import '../screens/analytics_page.dart';
import '../widgets/reuseable.dart';

class ActionPopupMenu extends StatelessWidget {
  const ActionPopupMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        switch (value) {
          case 'Logout':
            // Use signOut which handles all providers
            await AuthHelper.signOut();
            if (context.mounted) {
              // Use pushAndRemoveUntil to clear navigation stack
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'AuthEntryPoint'),
                  builder: (context) => const AuthHome(),
                ),
                (route) => false, // Remove all routes
              );
            }
            break;
          case 'dwApp':
            launchURL(context, kPlayStoreUrl);
            break;
          case 'Analytics':
            Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'AnalyticsPage'),
                builder: (context) => AnalyticsPage(profileCode: MyUser.profileCode),
              ),
            );
            break;
          case 'DeleteAcc':
            var isDone = await showDialog<bool>(
              context: context,
              builder: (context) {
                bool isLoading = false;
                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      title: const Text('Delete Account Data'),
                      content: const Text(
                        'This will permanently delete all your data including:\n'
                        '• Profile information\n'
                        '• All your VLags\n'
                        '• Analytics data\n\n'
                        'You\'ll be signed out automatically.',
                      ),
                      actions: [
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: LoadingIndicator(),
                          ),
                        TextButton(
                          onPressed: isLoading ? null : () {
                            Navigator.pop(context, false);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: isLoading ? null : () async {
                            setDialogState(() => isLoading = true);
                            try {
                              // Use the new comprehensive delete method
                              await ProfileBuilderHelper.deleteAccountAndSignOut(
                                MyUser.profileCode,
                                MyUser.imageUrl,
                              );
                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            } on FirebaseException catch (e) {
                              if (context.mounted) {
                                CustomSnack.showErrorSnack(context,
                                    message: e.message ?? "Firebase Error");
                                Navigator.pop(context, false);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                CustomSnack.showErrorSnack(context,
                                    message: "Error deleting account");
                                Navigator.pop(context, false);
                              }
                            }
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      ],
                    );
                  },
                );
              },
            );

            if (isDone ?? false) {
              // Use pushAndRemoveUntil to clear the navigation stack
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'AuthEntryPoint'),
                  builder: (_) => const AuthHome(),
                ),
                (route) => false, // Remove all routes
              );
            }
            break;
        }
      },
      icon: const FaIcon(
        FontAwesomeIcons.ellipsisVertical,
        size: 14,
        color: Colors.blueGrey,
      ),
      tooltip: 'Your account',
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem(
            value: 'Logout',
            child: Text('Log out'),
          ),
          if (kIsWeb)
            const PopupMenuItem(
              value: 'dwApp',
              child: Text('Download Android app...'),
            ),
          const PopupMenuItem(
            value: 'Analytics',
            child: Text('Detailed Analytics...'),
          ),
          const PopupMenuItem(
            value: 'DeleteAcc',
            child: Text(
              'Delete account data...',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ];
      },
    );
  }
}
