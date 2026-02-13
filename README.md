# VLAG

VLAG is a Flutter app for creating a shareable profile/links page (link-in-bio). It uses Firebase for authentication and data storage, and includes optional backend utilities for web hosting and profile assets.

**Web:** https://vlagit.com  
**Android package:** `com.VLagit.VLag`

## Features

- Profile builder with avatar, bio, and links
- Shareable profile URL + QR code
- Firebase Authentication (Google/Apple/Facebook where configured)
- Firestore + Storage for user data and media
- Optional Bitly link shortening
- Optional Google Mobile Ads (Android/iOS)

## Tech Stack

- Flutter (Dart)
- Firebase: Auth, Firestore, Storage, Analytics, Dynamic Links
- Node.js (Firebase Functions) in `functions/`
- PHP utilities for cPanel hosting in `server/`

## Repository Layout

- `lib/` Flutter application source
- `web/` Flutter web assets (for hosting the web build)
- `functions/` Firebase Cloud Functions
- `server/` cPanel/PHP backend helpers (uploads, simple endpoints)
- `scripts/` build/deploy scripts

## Getting Started

### Prerequisites

- Flutter SDK (Dart >= 3.0)
- A Firebase project (Auth + Firestore + Storage enabled)
- Node.js (only if you use `functions/`)

### 1) Install dependencies

```bash
flutter pub get
```

### 2) Create `lib/PRIVATE.dart`

This repo expects a private file for tokens/IDs. Create `lib/PRIVATE.dart`:

```dart
const kAdmobAppId = 'ca-app-pub-xxxxxxxxxxxxxxxxxxxxxxx';
const kShareBannerUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
const kEditPageBannerUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
const kInterstitialShareUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
const kInterstitialPreviewUnitId = 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
const kBitlyApiToken = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
```

If you are not using Ads or Bitly, you can still add placeholder values to compile.

### 3) Configure Firebase

```bash
flutterfire configure
```

### 4) Run the app

```bash
flutter run
```

Run on web (Chrome):

```bash
flutter run -d chrome
```

## Build & Deploy

Build web:

```bash
flutter build web
```

Deploy with Firebase Hosting (if configured):

```bash
firebase deploy --only hosting
```

For cPanel deployment and domain setup, see [CPANEL_SETUP_GUIDE.md](CPANEL_SETUP_GUIDE.md) and [TROUBLESHOOTING_DOMAIN.md](TROUBLESHOOTING_DOMAIN.md).

## Notes

- The base URLs used by the app are defined in [app_config.dart](lib/config/app_config.dart).
- Do not commit `lib/PRIVATE.dart` or any real API tokens.

## License

MIT. See [LICENSE](LICENSE).

## Credits

This codebase is based on the open-source Flutree project and has been customized/rebranded for VLagIt.
