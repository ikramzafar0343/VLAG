import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:dough/dough.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants.dart';
import '../../main.dart' show themeProvider;
import '../../model/my_user.dart';
import '../../utils/analytics_service.dart';
import '../../utils/linkcard_model.dart';
import '../../utils/meta_tags_updater.dart';
import '../../utils/profile_builder_helper.dart';
import '../../utils/snackbar.dart';
import '../../utils/url_launcher.dart';
import '../screens/consent_screen.dart';
import '../widgets/help_dialog.dart';
import '../widgets/link_card.dart';
import '../widgets/reuseable.dart';
import 'action_popup_menu.dart';
import 'add_edit_card.dart';
import 'share_profile.dart';

const _bottomSheetStyle = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)));

enum Mode { edit, preview }

var box = Hive.box(kMainBoxName);

class EditPage extends StatefulWidget {
  const EditPage({super.key});
  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _authInstance = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _websiteController = TextEditingController();
  late DocumentReference<Map<String, dynamic>> _userDocument;
  DocumentSnapshot<Map<String, dynamic>>? _documentSnapshotData;
  Mode? mode;
  bool _isdpLoading = false;
  bool _isReorderable = false;
  late String _subtitleText;
  late bool _isShowSubtitle;
  late String _websiteText;
  late bool _isShowWebsite;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    mode = Mode.edit;
    _userDocument =
        MyUser.userDocument as DocumentReference<Map<String, dynamic>>;
    initFirestore();
    if (!kIsWeb) {
      _createBannerAd();
    }
    // Listen to theme changes
    themeProvider.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {});
  }

  void initFirestore() async {
    var snapshot = await _userDocument.get();

    if (!snapshot.exists) {
      print('Document not exist. Creating...');
      // Document with id == docId doesn't exist.
      MyUser.setupInitialDoc();
      _nameController.text = _authInstance.currentUser!.displayName!;
    } else {
      _subtitleController.text = snapshot.data()!["subtitle"] ?? "Link. Share. Shine.";
      _websiteController.text = snapshot.data()!["website"] ?? "";
      _nameController.text = snapshot.data()!["nickname"];
    }
  }

  void _createBannerAd() {
    if (kIsWeb) return; // Ads not supported on web
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-1896379146653594/7250471616',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();

          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );

    _bannerAd!.load();
  }

  // VLag styled segment button for Edit/Preview toggle
  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const primaryGreen = Color(0xFF1DB877);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shadowColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        toolbarHeight: 50,
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.grey.shade800 
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegmentButton(
                label: 'EDIT',
                isSelected: mode == Mode.edit,
                onTap: () {
                  setState(() => mode = Mode.edit);
                },
              ),
              _buildSegmentButton(
                label: 'PREVIEW',
                isSelected: mode == Mode.preview,
                onTap: () {
                  setState(() => mode = Mode.preview);
                  // Track profile view when switching to preview mode
                  AnalyticsService.trackProfileView(MyUser.profileCode);
                },
              ),
            ],
          ),
        ),
        actions: [
          // Theme toggle button
          IconButton(
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: themeProvider.isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          // Share button
          IconButton(
            onPressed: () async {
              /// Check whether the getstorage was not true or the user hasn't
              /// agree with the consent yet
              if ((box.get(kHasAgreeConsent) ?? false) ||
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        settings: const RouteSettings(name: 'ConsentScreen'),
                        builder: (_) => const ConsentScreen()),
                  )) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: 'ShareProfile'),
                    builder: (_) => ShareProfile(
                      docs: _documentSnapshotData,
                    ),
                  ),
                );
              }
            },
            tooltip: 'Share Profile',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40),
            icon: Icon(
              Icons.share_rounded,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
          ),
          const ActionPopupMenu(),
        ],
      ),
      body: SafeArea(
        // Main content
        child: StreamBuilder(
          stream: _userDocument.snapshots(),
          builder: (context,
              AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              _documentSnapshotData = snapshot.data;

              _subtitleText = _documentSnapshotData!.data()!['subtitle'] ??
                  'Something about yourself';
              _isShowSubtitle =
                  _documentSnapshotData!.data()!['showSubtitle'] ?? false;
              _websiteText = _documentSnapshotData!.data()!['website'] ?? '';
              _isShowWebsite =
                  _documentSnapshotData!.data()!['showWebsite'] ?? false;
              MyUser.imageUrl = _documentSnapshotData!.data()!['dpUrl'] ??
                  'https://picsum.photos/200';
              
              // Update meta tags for rich link previews (web only)
              if (kIsWeb) {
                MetaTagsUpdater.updateMetaTagsForProfile(
                  profileCode: MyUser.profileCode,
                  nickname: _documentSnapshotData!.data()!['nickname'],
                  subtitle: _subtitleText,
                  profileImageUrl: MyUser.imageUrl,
                );
              }

              List<dynamic>? socialsList =
                  _documentSnapshotData!.data()!['socials'];
              List<LinkcardModel> datas = [];
              for (var item in socialsList ?? []) {
                datas.add(
                  LinkcardModel(
                    exactName: item['exactName'],
                    displayName: item['displayName'],
                    link: item['link'],
                  ),
                );
              }
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32.0, 0, 32.0, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 15.0),
                      GestureDetector(
                        onTap: kIsWeb
                            ? () => CustomSnack.showSnack(context,
                                message:
                                    'Change image only available in Android App',
                                barAction: SnackBarAction(
                                    textColor: Colors.blueGrey.shade200,
                                    label: 'Get the app',
                                    onPressed: () {
                                      launchURL(context, kPlayStoreUrl);
                                    }))
                            : mode == Mode.edit
                                ? () async {
                                    ImageSource? response = await showDialog(
                                      context: context,
                                      builder: (context) {
                                        return const ChooseImageDialog();
                                      },
                                    );
                                    if (response != null) {
                                      setState(() => _isdpLoading = true);
                                      String? url;
                                      try {
                                        url = await ProfileBuilderHelper
                                            .updateProfilePicture(response);

                                        await _userDocument
                                            .update({'dpUrl': url});
                                        CustomSnack.showSnack(context,
                                            message: 'Profile picture updated');
                                      } on FirebaseException catch (e) {
                                        CustomSnack.showErrorSnack(context,
                                            message:
                                                e.message ?? "Firebase Error");
                                      } finally {
                                        setState(() => _isdpLoading = false);
                                      }
                                    }
                                  }
                                : null,
                        child: PressableDough(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50.0,
                                backgroundColor: Colors.transparent,
                                backgroundImage: NetworkImage(MyUser.imageUrl!),
                                child: _isdpLoading
                                    ? Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            VLagButtonStyle.primaryGreen,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              mode == Mode.edit
                                  ? buildChangeDpIcon()
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      GestureDetector(
                        onTap: mode == Mode.edit
                            ? () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    bool isNicknameLoading = false;
                                    return StatefulBuilder(
                                      builder: (context, setDialogState) {
                                        return AlertDialog(
                                          title: const Text('Change nickname'),
                                          content: NameTextField(
                                            nameController: _nameController,
                                            keyboardAction:
                                                TextInputAction.done,
                                          ),
                                          actions: [
                                            isNicknameLoading
                                                ? const LoadingIndicator()
                                                : const SizedBox.shrink(),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                // ignore if nickname empty
                                                if (_nameController
                                                    .text.isEmpty) {
                                                  return;
                                                }

                                                setDialogState(() =>
                                                    isNicknameLoading = true);
                                                await _userDocument.update({
                                                  'nickname': _nameController
                                                      .text
                                                      .trim()
                                                });

                                                setState(() {
                                                  isNicknameLoading = false;
                                                  Navigator.pop(context);
                                                });
                                              },
                                              child: const Text('Confirm'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              }
                            : null,
                        child: Text(
                          '${_documentSnapshotData!.data()!['nickname']}',
                          style: mode == Mode.preview
                              ? const TextStyle(fontSize: 22)
                              : const TextStyle(
                                  fontSize: 22,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted),
                        ),
                      ), //just a plain text
                      const SizedBox(height: 5),
                      Visibility(
                        visible: (mode == Mode.edit) || _isShowSubtitle,
                        child: GestureDetector(
                          onTap: mode == Mode.edit
                              ? () async {
                                  var res = await showDialog(
                                    context: context,
                                    builder: (context) {
                                      bool isSubtitleLoading = false;
                                      return StatefulBuilder(
                                          builder: (context, setWidgetState) {
                                        return AlertDialog(
                                          title: const Text('Slogan'),
                                          contentPadding:
                                              const EdgeInsets.all(8.0),
                                          content: SubtitleTextField(
                                            subsController: _subtitleController,
                                          ),
                                          actions: [
                                            isSubtitleLoading
                                                ? const LoadingIndicator()
                                                : const SizedBox.shrink(),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () async {
                                                  setWidgetState(() {
                                                    isSubtitleLoading = true;
                                                  });
                                                  await _userDocument.update({
                                                    'subtitle':
                                                        _subtitleController.text
                                                  });
                                                  setWidgetState(() {
                                                    isSubtitleLoading = true;
                                                  });

                                                  Navigator.pop(
                                                      context,
                                                      _subtitleController
                                                          .text.isNotEmpty);
                                                },
                                                child: const Text('Save')),
                                          ],
                                        );
                                      });
                                    },
                                  );
                                  // Avoid rebuild when no change
                                  if (res == null) return;
                                  await _userDocument
                                      .update({'showSubtitle': res});
                                }
                              : null,
                          child: _isShowSubtitle
                              ? Text(
                                  _subtitleText,
                                  style: mode == Mode.edit
                                      ? dottedUnderlinedStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        )
                                      : TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                )
                              : Text(
                                  'Add Slogan',
                                  style: dottedUnderlinedStyle(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Visibility(
                        visible: (mode == Mode.edit) || _isShowWebsite,
                        child: GestureDetector(
                          onTap: mode == Mode.edit
                              ? () async {
                                  var res = await showDialog(
                                    context: context,
                                    builder: (context) {
                                      bool isWebsiteLoading = false;
                                      String? urlError;
                                      final formKey = GlobalKey<FormState>();
                                      
                                      // URL validation function
                                      String? validateUrl(String? value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return null; // Allow empty to clear website
                                        }
                                        final trimmed = value.trim();
                                        // Check if it's a valid URL format
                                        final urlPattern = RegExp(
                                          r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
                                          caseSensitive: false,
                                        );
                                        if (!urlPattern.hasMatch(trimmed)) {
                                          return 'Please enter a valid URL';
                                        }
                                        return null;
                                      }
                                      
                                      return StatefulBuilder(
                                          builder: (context, setWidgetState) {
                                        return AlertDialog(
                                          title: const Text('Website'),
                                          contentPadding:
                                              const EdgeInsets.all(16.0),
                                          content: Form(
                                            key: formKey,
                                            child: TextFormField(
                                              controller: _websiteController,
                                              validator: validateUrl,
                                              autovalidateMode: AutovalidateMode.onUserInteraction,
                                              decoration: InputDecoration(
                                                hintText: 'https://example.com',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                prefixIcon: const Icon(Icons.link),
                                                helperText: 'Enter your website URL',
                                                errorText: urlError,
                                              ),
                                              keyboardType: TextInputType.url,
                                            ),
                                          ),
                                          actions: [
                                            isWebsiteLoading
                                                ? const LoadingIndicator()
                                                : const SizedBox.shrink(),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Cancel')),
                                            TextButton(
                                                onPressed: () async {
                                                  // Validate URL before saving
                                                  if (!formKey.currentState!.validate()) {
                                                    return;
                                                  }
                                                  
                                                  setWidgetState(() {
                                                    isWebsiteLoading = true;
                                                  });
                                                  await _userDocument.update({
                                                    'website':
                                                        _websiteController.text.trim()
                                                  });
                                                  setWidgetState(() {
                                                    isWebsiteLoading = false;
                                                  });

                                                  Navigator.pop(
                                                      context,
                                                      _websiteController
                                                          .text.trim().isNotEmpty);
                                                },
                                                child: const Text('Save')),
                                          ],
                                        );
                                      });
                                    },
                                  );
                                  // Avoid rebuild when no change
                                  if (res == null) return;
                                  await _userDocument
                                      .update({'showWebsite': res});
                                }
                              : (_isShowWebsite && _websiteText.isNotEmpty)
                                  ? () {
                                      // In preview mode, open the website URL
                                      final url = _websiteText.startsWith('http')
                                          ? _websiteText
                                          : 'https://$_websiteText';
                                      launchURL(context, url);
                                    }
                                  : null,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            child: FaIcon(
                              FontAwesomeIcons.globe,
                              size: 28,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Builder(
                        builder: (builder) {
                          if (mode == Mode.edit) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Help button on the left
                                TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                          context: context,
                                          builder: (builder) {
                                            return HelpDialogs
                                                .editModehelpDialog(context);
                                          });
                                    },
                                    icon: FaIcon(
                                        FontAwesomeIcons.circleQuestion,
                                        size: 16,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                    ),
                                    label: Text(
                                      'Help',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    )),
                                // Reorder button on the right
                                if (datas.isNotEmpty)
                                  Tooltip(
                                    message:
                                        'Toggle whether the cards should be\nreorderable or locked in place.',
                                    child: TextButton.icon(
                                      icon: FaIcon(
                                        !_isReorderable
                                            ? FontAwesomeIcons.toggleOff
                                            : FontAwesomeIcons.toggleOn,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isReorderable = !_isReorderable;
                                        });
                                      },
                                      label: const Text('Reorder'),
                                    ),
                                  ),
                              ],
                            );
                          } else {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (builder) {
                                          return HelpDialogs
                                              .previewModeHelpDialog(context);
                                        });
                                  },
                                  icon: FaIcon(
                                      FontAwesomeIcons.circleQuestion,
                                      size: 16,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                  ),
                                  label: Text(
                                    'Help',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  )),
                            );
                          }
                        },
                      ),
                      Builder(
                        builder: (context) {
                          if (mode == Mode.edit) {
                            return ReorderableListView.builder(
                                buildDefaultDragHandles: _isReorderable,
                                itemCount: datas.length,
                                onReorderStart: (_) =>
                                    HapticFeedback.lightImpact(),
                                onReorder: (oldIndex, newIndex) {
                                  if (oldIndex < newIndex) {
                                    newIndex -= 1;
                                  }
                                  final LinkcardModel item =
                                      datas.removeAt(oldIndex);
                                  datas.insert(newIndex, item);
                                  List<Map<String, String?>> tempData = [];
                                  for (var item in datas) {
                                    tempData.add(item.toMap());
                                  }
                                  _userDocument.update({'socials': tempData});
                                },
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return Dismissible(
                                    onDismissed: (direction) {
                                      _userDocument.update({
                                        'socials': FieldValue.arrayRemove(
                                            [datas[index].toMap()])
                                      });
                                    },
                                    direction: !_isReorderable
                                        ? DismissDirection.startToEnd
                                        : DismissDirection.none,
                                    confirmDismiss: (direction) async {
                                      return await showModalBottomSheet(
                                        shape: _bottomSheetStyle,
                                        context: context,
                                        builder: (_) =>
                                            DeleteCardWidget(datas[index]),
                                      );
                                    },
                                    background: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: const <Widget>[
                                          SizedBox(width: 8),
                                          FaIcon(FontAwesomeIcons.trashCan,
                                              size: 20,
                                              color: Colors.redAccent),
                                          SizedBox(width: 10),
                                          Text(
                                            'Swipe to delete >>>',
                                            style: TextStyle(
                                                color: Colors.redAccent),
                                          )
                                        ],
                                      ),
                                    ),
                                    key: Key(datas[index].hashCode.toString()),
                                    child: GestureDetector(
                                      onLongPress: mode == Mode.preview
                                          ? () {}
                                          : null, // disable reorderable when in preview mode
                                      onTap: () async {
                                        LinkcardModel temp = datas[index];

                                        dynamic result =
                                            await showModalBottomSheet(
                                          isScrollControlled: true,
                                          shape: _bottomSheetStyle,
                                          context: context,
                                          builder: (context) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom),
                                              child:
                                                  AddCard(linkcardModel: temp),
                                            );
                                          },
                                        );
                                        if (result != null) {
                                          await _userDocument.update({
                                            'socials': FieldValue.arrayRemove(
                                                [datas[index].toMap()])
                                          });
                                          _userDocument.update({
                                            'socials': FieldValue.arrayUnion(
                                                [result.toMap()])
                                          }).then((value) {
                                            setState(() {});
                                          }).catchError((Object error) {
                                            print(error);
                                            CustomSnack.showErrorSnack(context,
                                                message: 'Unable to sync');
                                          });
                                        }
                                      },
                                      child: LinkCard(
                                        linkcardModel: datas[index],
                                        isEditing: mode == Mode.edit,
                                        profileOwnerCode: MyUser.profileCode,
                                      ),
                                    ),
                                  );
                                });
                          } else {
                            return ListView.builder(
                              itemCount: datas.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return PressableDough(
                                  child: LinkCard(
                                    linkcardModel: datas[index],
                                    profileOwnerCode: MyUser.profileCode,
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      Visibility(
                        visible: mode == Mode.edit,
                        child: Transform.scale(
                          scale: 0.97,
                          child: Opacity(
                            opacity: .75,
                            child: DottedBorder(
                              dashPattern: const [6, 5],
                              color: Theme.of(context).iconTheme.color!,
                              child: Card(
                                color: Theme.of(context).canvasColor,
                                margin: EdgeInsets.zero,
                                shadowColor: Colors.transparent,
                                child: ListTile(
                                  onTap: () async {
                                    dynamic result = await showModalBottomSheet(
                                      isScrollControlled: true,
                                      shape: _bottomSheetStyle,
                                      context: context,
                                      builder: (context) {
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              bottom: MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom),
                                          child: const AddCard(),
                                        );
                                      },
                                    );

                                    if (result != null) {
                                      print('Adding ${result.toMap()}');
                                      _userDocument.update({
                                        'socials': FieldValue.arrayUnion(
                                            [result.toMap()])
                                      }).then((value) {
                                        setState(() {});
                                      }).catchError((Object error) {
                                        print(error);
                                        CustomSnack.showErrorSnack(context,
                                            message: 'Unable to sync');
                                      });
                                    }
                                  },
                                  leading: const FaIcon(
                                    FontAwesomeIcons.plus,
                                  ),
                                  title: const Text(
                                    'Add VLag',
                                    textAlign: TextAlign.center,
                                  ),
                                  trailing: const Icon(null),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      _isBannerAdLoaded
                          ? bannerAdWidget()
                          : const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Loading')
                    ]),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text(
                        'We have trouble connecting....\nIf the problem still persists, try log out and log in again',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      )
                    ]),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  Widget bannerAdWidget() {
    if (_bannerAd == null || kIsWeb) {
      return const SizedBox.shrink();
    }
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: 72.0,
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }


  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    _nameController.dispose();
    _subtitleController.dispose();
    _websiteController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}

class DeleteCardWidget extends StatelessWidget {
  const DeleteCardWidget(
    this.linkcard, {
    super.key,
  });

  final LinkcardModel linkcard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delete ${linkcard.displayName} ?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 14),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    label: const Text('Cancel')),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.trashCan, size: 14),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.redAccent,
                        side: BorderSide.none),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    label: const Text('Delete')),
              ),
            ],
          ),
          const SizedBox(height: 5)
        ],
      ),
    );
  }
}

class ChooseImageDialog extends StatelessWidget {
  const ChooseImageDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(title: const Text("Choose source"), children: [
      SimpleDialogOption(
        child: const Text("Take picture"),
        onPressed: () => Navigator.of(context).pop(ImageSource.camera),
      ),
      SimpleDialogOption(
          child: const Text("Pick from Gallery"),
          onPressed: () => Navigator.of(context).pop(ImageSource.gallery))
    ]);
  }
}
