#!/bin/bash
set -euo pipefail

# Build and package Glance.app into a DMG for distribution.
# Usage: ./scripts/build-dmg.sh

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Glance"
DMG_NAME="Glance"
BUILD_DIR="$PROJECT_ROOT/build"
RELEASE_DIR="$PROJECT_ROOT/release"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"

echo "==> Building $APP_NAME (Release)..."
xcodebuild -project "$PROJECT_ROOT/$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  build \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -quiet

if [ ! -d "$APP_PATH" ]; then
  echo "Error: $APP_PATH not found. Build may have failed."
  exit 1
fi

# Get version from the built app
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "1.0.0")
DMG_FILENAME="${DMG_NAME}-${VERSION}.dmg"

echo "==> Packaging $APP_NAME v${VERSION}..."

mkdir -p "$RELEASE_DIR"
rm -f "$RELEASE_DIR/$DMG_FILENAME"

# Create a temporary folder for DMG contents
DMG_TEMP="$BUILD_DIR/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

cp -R "$APP_PATH" "$DMG_TEMP/"

# Create a symlink to /Applications for drag-and-drop install
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_TEMP" \
  -ov \
  -format UDZO \
  "$RELEASE_DIR/$DMG_FILENAME"

rm -rf "$DMG_TEMP"

# Also create a ZIP for GitHub releases
ZIP_FILENAME="${DMG_NAME}-${VERSION}.zip"
rm -f "$RELEASE_DIR/$ZIP_FILENAME"
cd "$BUILD_DIR/Build/Products/Release"
zip -r -q "$RELEASE_DIR/$ZIP_FILENAME" "$APP_NAME.app"
cd "$PROJECT_ROOT"

echo ""
echo "==> Done!"
echo "    DMG: $RELEASE_DIR/$DMG_FILENAME"
echo "    ZIP: $RELEASE_DIR/$ZIP_FILENAME"
