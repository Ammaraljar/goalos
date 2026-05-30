#!/bin/bash
# GoalOS Setup Script
# Run this after placing this folder inside a Flutter project

set -e

echo "🚀 GoalOS Setup Script"
echo "======================"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Install from https://flutter.dev"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -1)"

# Get dependencies
echo ""
echo "📦 Installing dependencies..."
flutter pub get

# Generate localizations
echo ""
echo "🌍 Generating localizations..."
flutter gen-l10n

# Check assets
echo ""
echo "🔤 Checking font assets..."
if [ ! -f "assets/fonts/Cairo-Regular.ttf" ]; then
    echo "⚠️  Cairo font files missing!"
    echo "   Download from: https://fonts.google.com/specimen/Cairo"
    echo "   Place in: assets/fonts/"
    echo "   Files needed: Cairo-Regular.ttf, Cairo-Bold.ttf, Cairo-SemiBold.ttf"
else
    echo "✅ Cairo font files found"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Build commands:"
echo "  Debug APK:    flutter build apk --debug"
echo "  Release APK:  flutter build apk --release"
echo "  Split APKs:   flutter build apk --split-per-abi --release"
echo ""
echo "APK output: build/app/outputs/flutter-apk/"
