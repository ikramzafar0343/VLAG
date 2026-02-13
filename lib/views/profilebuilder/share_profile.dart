import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gal/gal.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/secrets.dart';
import '../../constants.dart';
import '../../model/my_user.dart';
import '../../utils/copy_link.dart';
import '../../utils/snackbar.dart';
import '../../utils/url_launcher.dart';
import '../widgets/reuseable.dart';

class ShareProfile extends StatefulWidget {
  const ShareProfile({super.key, this.docs});
  final DocumentSnapshot<Map<String, dynamic>>? docs;

  @override
  State<ShareProfile> createState() => _ShareProfileState();
}

class _ShareProfileState extends State<ShareProfile> {
  InterstitialAd? _interstitialAd;
  BannerAd? _bannerAdPotrait;
  BannerAd? _bannerAdLandscape; // Smaller height ad
  String? _profileLink;
  bool _isPotraitBannerAdLoaded = false;
  bool _isLandscapeBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _profileLink = '$kWebappUrl/${MyUser.profileCode}';
    // _createInterstitialAd();
    if (!kIsWeb) {
      _createPotraitBannerAd();
      _createLandscapeBannerAd();
    }
  }

  void _createPotraitBannerAd() {
    if (kIsWeb) return; // Ads not supported on web
    if (kShareBannerUnitId.isEmpty) return;
    _bannerAdPotrait = BannerAd(
      adUnitId: kShareBannerUnitId,
      size: AdSize.largeBanner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isPotraitBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();

          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );

    _bannerAdPotrait!.load();
  }

  void _createLandscapeBannerAd() {
    if (kIsWeb) return; // Ads not supported on web
    if (kShareBannerUnitId.isEmpty) return;
    _bannerAdLandscape = BannerAd(
      adUnitId: kShareBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isLandscapeBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Releases an ad resource when it fails to load
          ad.dispose();

          print('Ad load failed (code=${error.code} message=${error.message})');
        },
      ),
    );

    _bannerAdLandscape!.load();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //to dismiss selectable text
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          title: const Text('Share your VLag profile'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.shareNodes),
              onPressed: () {
                Share.share(
                    'Hey. Visit our profile page on https://$_profileLink',
                    subject: 'Sharing my VLag profile');
              },
            )
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: SizedBox(
              width: double.infinity,
              child: OrientationBuilder(
                builder: (context, orientation) {
                  if (orientation == Orientation.portrait) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 25),
                        InfoWidget(profileLink: _profileLink!),
                        const SizedBox(height: 20),
                        ProfileQrCode(profileLink: _profileLink!),
                        const Spacer(),
                        if (_isPotraitBannerAdLoaded)
                          MyBannerAd(_bannerAdPotrait!),
                      ],
                    );
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Column(
                              children: [
                                InfoWidget(profileLink: _profileLink!),
                                if (_isLandscapeBannerAdLoaded)
                                  MyBannerAd(_bannerAdLandscape!),
                              ],
                            )),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ProfileQrCode(profileLink: _profileLink!),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    _bannerAdPotrait?.dispose();
    super.dispose();
  }
}

// ignore: todo
// TODO: enabled balik nanti
// class AskSquishCard extends StatelessWidget {
//   const AskSquishCard({
//     Key key,
//     @required this.context,
//   }) : super(key: key);

//   final BuildContext context;

//   @override
//   Widget build(BuildContext context) {
//     return TextButton(
//       onPressed: () {
//         showDialog(
//           context: context,
//           builder: (context) {
//             return AssetGiffyDialog(
//               onlyOkButton: true,
//               onOkButtonPressed: () => Navigator.pop(context),
//               image: Image.asset(
//                 'images/intro.gif',
//               ),
//               title: const Text(
//                   'Try this out!\nSquishable (or dough effect) UI elements'),
//             );
//           },
//         );
//       },
//       child: Text(
//         'Ask others to squish the cards 👀',
//         style: dottedUnderlinedStyle(),
//       ),
//     );
//   }
// }

class InfoWidget extends StatelessWidget {
  const InfoWidget({super.key, required this.profileLink});

  final String profileLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Your profile link:',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 5),
        LinkContainer(
          child: MarkdownBody(
            data: '$kWebappUrl/**${MyUser.profileCode}**',
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 21,
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              label: const Text('Copy'),
              onPressed: () => CopyLink.copy(url: 'https://$profileLink'),
              icon: const FaIcon(
                FontAwesomeIcons.copy,
                size: 18,
              ),
            ),
            TextButton.icon(
              label: const Text('Open'),
              onPressed: () => launchURL(context, 'https://$profileLink'),
              icon: const FaIcon(
                FontAwesomeIcons.upRightFromSquare,
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProfileQrCode extends StatefulWidget {
  const ProfileQrCode({super.key, required this.profileLink});

  final String profileLink;

  @override
  State<ProfileQrCode> createState() => _ProfileQrCodeState();
}

class _ProfileQrCodeState extends State<ProfileQrCode> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isDownloading = false;

  Future<void> _downloadQrCode() async {
    setState(() => _isDownloading = true);
    try {
      // Capture the QR code widget as an image
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final filename = 'vlag_qr_${widget.profileLink.split('/').last}.png';

      if (kIsWeb) {
        // For web, use share as download alternative
        final result = await Share.shareXFiles(
          [XFile.fromData(pngBytes, name: filename, mimeType: 'image/png')],
          text: 'VLag Profile QR Code',
        );

        if (mounted) {
          if (result.status == ShareResultStatus.success) {
            CustomSnack.showSuccessSnack(context,
                message: 'QR code downloaded successfully');
          } else {
            CustomSnack.showErrorSnack(context,
                message: 'Failed to download QR code');
          }
        }
      } else {
        try {
          const albumName = 'VLag';
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/$filename');
          await tempFile.writeAsBytes(pngBytes);

          final hasAccess = await Gal.hasAccess(toAlbum: true);
          if (!hasAccess) {
            await Gal.requestAccess(toAlbum: true);
          }

          final hasAccessAfter = await Gal.hasAccess(toAlbum: true);
          if (!hasAccessAfter) {
            if (mounted) {
              CustomSnack.showErrorSnack(
                context,
                message: 'Permission to access gallery is denied.',
              );
            }
            return;
          }

          await Gal.putImage(tempFile.path, album: albumName);

          try {
            await tempFile.delete();
          } catch (_) {}

          if (mounted) {
            CustomSnack.showSuccessSnack(
              context,
              message: 'QR code saved to $albumName album',
            );
          }
        } catch (e) {
          debugPrint('Error saving to gallery: $e');
          if (!mounted) return;
          String message =
              'Error saving QR code. Please check app permissions.';
          if (e is GalException) {
            message = e.type.message;
          }
          CustomSnack.showErrorSnack(context, message: message);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnack.showErrorSnack(context,
            message: 'Error saving QR code: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _qrKey,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: QrImageView(
              data: 'https://${widget.profileLink}',
              size: 210,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
              embeddedImage: const AssetImage(
                'images/logo/vlag_qr.png',
              ),
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(40, 40),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isDownloading ? null : _downloadQrCode,
          style: VLagButtonStyle.primary,
          icon: _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const FaIcon(FontAwesomeIcons.download, size: 16),
          label: Text(
            _isDownloading ? 'Downloading...' : 'Download QR Code',
            style: VLagButtonStyle.buttonText,
          ),
        ),
      ],
    );
  }
}

class MyBannerAd extends StatefulWidget {
  const MyBannerAd(this.bannerAd, {super.key});

  final BannerAd bannerAd;

  @override
  State<MyBannerAd> createState() => _MyBannerAdState();
}

class _MyBannerAdState extends State<MyBannerAd> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.bannerAd.size.width.toDouble(),
      height: 100.0,
      alignment: Alignment.center,
      child: AdWidget(ad: widget.bannerAd),
    );
  }
}
