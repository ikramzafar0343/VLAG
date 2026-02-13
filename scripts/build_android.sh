#!/bin/bash
# VLagIt Android Build Script
# Builds Android release APK and App Bundle

set -e  # Exit on error

echo "🚀 Building VLagIt Android App for Production..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build APK
echo "🔨 Building Android APK..."
flutter build apk --release

# Build App Bundle (for Play Store)
echo "🔨 Building Android App Bundle..."
flutter build appbundle --release

# Check if builds were successful
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ] && \
   [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo "✅ Builds successful!"
    echo "📁 APK: build/app/outputs/flutter-apk/app-release.apk"
    echo "📁 Bundle: build/app/outputs/bundle/release/app-release.aab"
else
    echo "❌ Build failed! Check errors above."
    exit 1
fi
