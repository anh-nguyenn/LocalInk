#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

./scripts/validate-release-config.sh

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
NAME="LocalInk-$VERSION"

./build.sh
codesign --verify --deep --strict "dist/LocalInk.app"

mkdir -p dist/release

# Submit a temporary ZIP so Apple issues a ticket for the app itself. Staple
# that ticket before creating either downloadable artifact.
NOTARY_ZIP="dist/release/$NAME-notary.zip"
rm -f "$NOTARY_ZIP"
ditto -c -k --sequesterRsrc --keepParent "dist/LocalInk.app" "$NOTARY_ZIP"
./scripts/notarize.sh "$NOTARY_ZIP" "dist/LocalInk.app" "$NOTARYTOOL_PROFILE"
rm -f "$NOTARY_ZIP"

# Zip: keeps LocalInk.app as a single bundle that Safari extracts directly.
rm -f "dist/$NAME.zip"
ditto -c -k --sequesterRsrc --keepParent "dist/LocalInk.app" "dist/$NAME.zip"

# DMG: a familiar drag-to-Applications install with a short read me.
STAGE="dist/release/dmg"
rm -rf "$STAGE"
mkdir -p "$STAGE"
ditto "dist/LocalInk.app" "$STAGE/LocalInk.app"
ln -s /Applications "$STAGE/Applications"
cp "packaging/Read Me.txt" "$STAGE/Read Me.txt"
rm -f "dist/$NAME.dmg"
hdiutil create -volname "$NAME" -srcfolder "$STAGE" -ov -format UDZO "dist/$NAME.dmg" >/dev/null
codesign --force --sign "$CODESIGN_IDENTITY" --timestamp "dist/$NAME.dmg"
codesign --verify "dist/$NAME.dmg"
./scripts/notarize.sh "dist/$NAME.dmg" "dist/$NAME.dmg" "$NOTARYTOOL_PROFILE"

cp "dist/$NAME.zip" "dist/LocalInk.zip"
cp "dist/$NAME.dmg" "dist/LocalInk.dmg"

echo ""
echo "Release artifacts:"
echo "  dist/$NAME.zip  (and stable dist/LocalInk.zip)"
echo "  dist/$NAME.dmg  (and stable dist/LocalInk.dmg)"
echo ""
shasum -a 256 "dist/$NAME.zip" "dist/$NAME.dmg"
