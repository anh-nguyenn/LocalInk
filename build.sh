#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
APP="$PWD/dist/LocalInk.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
DEVELOPER_DIR="$(xcode-select -p)"
XCODE_SWIFTC="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
XCODE_SDK="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
mkdir -p "$PWD/.build/module-cache"
if [[ -x "$XCODE_SWIFTC" && -d "$XCODE_SDK" ]]; then
    "$XCODE_SWIFTC" -O -sdk "$XCODE_SDK" -target "$(uname -m)-apple-macosx13.0" \
        -module-cache-path "$PWD/.build/module-cache" \
        -framework AppKit -framework Carbon Sources/main.swift -o "$APP/Contents/MacOS/LocalInk"
else
    xcrun swiftc -O -module-cache-path "$PWD/.build/module-cache" \
        -framework AppKit -framework Carbon Sources/main.swift -o "$APP/Contents/MacOS/LocalInk"
fi
chmod +x "$APP/Contents/MacOS/LocalInk"
codesign --force --sign - "$APP"
echo "Built: $APP"
echo "Start with: open '$APP'"
