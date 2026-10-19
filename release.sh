#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
NAME="LocalInk-$VERSION"

./build.sh

mkdir -p dist/release

# Zip: keeps LocalInk.app as a single bundle that Safari extracts directly.
rm -f "dist/$NAME.zip"
ditto -c -k --sequesterRsrc --keepParent "dist/LocalInk.app" "dist/$NAME.zip"
cp "dist/$NAME.zip" "dist/LocalInk.zip"

# DMG: a familiar drag-to-Applications install with a short read me.
STAGE="dist/release/dmg"
rm -rf "$STAGE"
mkdir -p "$STAGE"
ditto "dist/LocalInk.app" "$STAGE/LocalInk.app"
ln -s /Applications "$STAGE/Applications"
cp "packaging/Read Me.txt" "$STAGE/Read Me.txt"
rm -f "dist/$NAME.dmg"
hdiutil create -volname "$NAME" -srcfolder "$STAGE" -ov -format UDZO "dist/$NAME.dmg" >/dev/null
cp "dist/$NAME.dmg" "dist/LocalInk.dmg"

echo ""
echo "Release artifacts:"
echo "  dist/$NAME.zip  (and stable dist/LocalInk.zip)"
echo "  dist/$NAME.dmg  (and stable dist/LocalInk.dmg)"
echo ""
shasum -a 256 "dist/$NAME.zip" "dist/$NAME.dmg"
