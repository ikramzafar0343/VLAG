# VLag - Running and Building Guide

## 📱 Running on Web

### Prerequisites
1. Ensure Flutter is installed and up to date:
   ```bash
   flutter doctor
   flutter upgrade
   ```

2. Install Chrome browser (recommended for development)

### Steps to Run on Web

1. **Navigate to project directory:**
   ```bash
   cd flutree
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on web:**
   ```bash
   flutter run -d chrome
   ```
   
   **Note:** In Flutter 3.x, the web renderer is automatically selected. HTML renderer is used by default for better compatibility.

4. **For production web build:**
   ```bash
   flutter build web
   ```
   
   **To specify renderer (if needed in older Flutter versions):**
   ```bash
   flutter build web --web-renderer html
   ```
   
   The built files will be in `build/web/` directory.

### Web Deployment Options

#### Option 1: Firebase Hosting (Recommended)
1. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase Hosting (if not already done):
   ```bash
   firebase init hosting
   ```

4. Build and deploy:
   ```bash
   flutter build web --web-renderer html
   firebase deploy --only hosting
   ```

#### Option 2: Deploy to any web server
1. Build the web app:
   ```bash
   flutter build web --web-renderer html
   ```

2. Upload the contents of `build/web/` to your web server

---

## 🤖 Building Android APK

### Prerequisites

1. **Install Android Studio** and set up Android SDK
   - Download from: https://developer.android.com/studio
   - Install Android SDK (API level 35)
   - Install Android SDK Build-Tools

2. **Set up Java Development Kit (JDK)**
   - Install JDK 17 or higher
   - Set JAVA_HOME environment variable

3. **Configure Android SDK path:**
   ```bash
   flutter doctor
   ```
   Follow any instructions to fix Android setup issues.

4. **Accept Android licenses:**
   ```bash
   flutter doctor --android-licenses
   ```

### Steps to Build APK

#### 1. Navigate to project directory:
```bash
cd flutree
```

#### 2. Get dependencies:
```bash
flutter pub get
```

#### 3. Check connected devices:
```bash
flutter devices
```

#### 4. Build Debug APK (for testing):
```bash
flutter build apk --debug
```
- Output location: `build/app/outputs/flutter-apk/app-debug.apk`
- This APK is larger but includes debugging symbols

#### 5. Build Release APK (for distribution):
```bash
flutter build apk --release
```
- Output location: `build/app/outputs/flutter-apk/app-release.apk`
- This is the optimized version for production

#### 6. Build Split APKs (by ABI - smaller file size):
```bash
flutter build apk --split-per-abi
```
- Creates separate APKs for:
  - `app-armeabi-v7a-release.apk` (32-bit ARM)
  - `app-arm64-v8a-release.apk` (64-bit ARM)
  - `app-x86_64-release.apk` (64-bit x86)
- Users only download the APK for their device architecture

### Signing the APK (Required for Play Store)

#### Option 1: Using key.properties file (Recommended)

1. **Create a keystore file:**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   - Replace `~/upload-keystore.jks` with your desired path
   - Remember the password and alias name

2. **Create `android/key.properties` file:**
   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```
   - Replace with your actual passwords and keystore path

3. **Build signed APK:**
   ```bash
   flutter build apk --release
   ```
   The signing is already configured in `android/app/build.gradle`

#### Option 2: Manual signing (Alternative)

1. Build unsigned APK:
   ```bash
   flutter build apk --release
   ```

2. Sign the APK:
   ```bash
   jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore your-keystore.jks build/app/outputs/flutter-apk/app-release-unsigned.apk upload
   ```

3. Align the APK:
   ```bash
   zipalign -v 4 build/app/outputs/flutter-apk/app-release-unsigned.apk build/app/outputs/flutter-apk/app-release.apk
   ```

### Building Android App Bundle (AAB) for Play Store

Google Play Store requires AAB format (not APK) for new apps:

```bash
flutter build appbundle --release
```

- Output location: `build/app/outputs/bundle/release/app-release.aab`
- Upload this file to Google Play Console

### Troubleshooting

#### Issue: "Gradle build failed"
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

#### Issue: "SDK location not found"
**Solution:**
1. Open Android Studio
2. Go to File → Project Structure → SDK Location
3. Note the Android SDK location
4. Set environment variable:
   ```bash
   # Windows (PowerShell)
   $env:ANDROID_HOME = "C:\Users\YourName\AppData\Local\Android\Sdk"
   
   # Windows (CMD)
   set ANDROID_HOME=C:\Users\YourName\AppData\Local\Android\Sdk
   
   # Linux/Mac
   export ANDROID_HOME=$HOME/Android/Sdk
   ```

#### Issue: "Java version mismatch"
**Solution:**
- Ensure JDK 17 is installed
- Set JAVA_HOME to JDK 17:
  ```bash
  # Windows
  set JAVA_HOME=C:\Program Files\Java\jdk-17
  ```

#### Issue: "Build failed: namespace"
**Solution:**
- The namespace is already configured in `android/app/build.gradle`
- If issues persist, run:
  ```bash
  flutter clean
  flutter pub get
  ```

### Testing the APK

1. **Install on connected device:**
   ```bash
   flutter install
   ```

2. **Or manually install:**
   - Transfer APK to Android device
   - Enable "Install from unknown sources" in device settings
   - Tap the APK file to install

### APK Size Optimization

To reduce APK size:

1. **Enable ProGuard/R8 (already enabled):**
   - Check `android/app/build.gradle` - `android.enableR8=true` is set

2. **Remove unused resources:**
   ```bash
   flutter build apk --release --shrink
   ```

3. **Use split APKs:**
   ```bash
   flutter build apk --split-per-abi --release
   ```

---

## 📋 Quick Reference Commands

### Web
```bash
# Run on web
flutter run -d chrome

# Build for web
flutter build web

# Deploy to Firebase
flutter build web && firebase deploy --only hosting
```

### Android
```bash
# Run on connected Android device
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build split APKs
flutter build apk --split-per-abi --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### General
```bash
# Check Flutter setup
flutter doctor

# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Check for updates
flutter upgrade
```

---

## 🔧 Configuration Files

### Important Files:
- `pubspec.yaml` - Project configuration and dependencies
- `android/app/build.gradle` - Android build configuration
- `android/app/src/main/AndroidManifest.xml` - Android app manifest
- `web/index.html` - Web app entry point
- `lib/firebase_options.dart` - Firebase configuration
- `android/key.properties` - Keystore configuration (create this for signing)

---

## 📝 Notes

1. **Web Renderer**: Use `--web-renderer html` for better image compatibility
2. **APK vs AAB**: Use APK for direct distribution, AAB for Google Play Store
3. **Signing**: Always sign release builds before distribution
4. **Testing**: Test on real devices before releasing
5. **Firebase**: Ensure Firebase configuration is correct in `firebase_options.dart`

---

## 🆘 Need Help?

- Flutter Documentation: https://docs.flutter.dev
- Firebase Documentation: https://firebase.google.com/docs
- Android Developer Guide: https://developer.android.com
