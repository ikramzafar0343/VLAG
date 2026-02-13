#!/bin/bash
# VLagIt Web Build Script
# Builds Flutter web app for production deployment

set -e  # Exit on error

echo "🚀 Building VLagIt Web App for Production..."

# Navigate to project root
cd "$(dirname "$0")/.."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for production
echo "🔨 Building Flutter web..."
flutter build web --release

# Check if build was successful
if [ -d "build/web" ]; then
    echo "✅ Build successful!"
    echo "📁 Build output: build/web/"
    echo ""
    echo "📋 Next steps:"
    echo "1. Upload all files from build/web/ to public_html/"
    echo "2. Ensure .htaccess files are uploaded"
    echo "3. Test the deployment at https://vlagit.com"
else
    echo "❌ Build failed! Check errors above."
    exit 1
fi
