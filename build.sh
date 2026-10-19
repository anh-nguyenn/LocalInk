#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP="$PWD/dist/LocalInk.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"

# Prefer a full Xcode toolchain (matching compiler + SDK). The standalone
# Command Line Tools can ship an SDK that is newer than its compiler, which
# makes the Swift standard library unbuildable.
DEVELOPER_DIR="${DEVELOPER_DIR:-}"
if [[ -z "$DEVELOPER_DIR" || ! -d "$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain" ]]; then
    if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
        DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    else
        DEVELOPER_DIR="$(xcode-select -p)"
    fi
fi

XCODE_SWIFTC="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
XCODE_SDK="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

mkdir -p "$PWD/.build/module-cache"

# Collect every Swift source file so the project can grow past a single file.
SOURCES=()
while IFS= read -r -d '' file; do
    SOURCES+=("$file")
done < <(find Sources -name '*.swift' -print0 | sort -z)

if [[ -x "$XCODE_SWIFTC" && -d "$XCODE_SDK" ]]; then
    "$XCODE_SWIFTC" -O -sdk "$XCODE_SDK" -target "$(uname -m)-apple-macosx13.0" \
        -module-cache-path "$PWD/.build/module-cache" \
        -framework AppKit -framework Carbon -framework ScreenCaptureKit \
        -framework ServiceManagement -framework UniformTypeIdentifiers \
        "${SOURCES[@]}" -o "$APP/Contents/MacOS/LocalInk"
else
    xcrun swiftc -O -module-cache-path "$PWD/.build/module-cache" \
        -framework AppKit -framework Carbon -framework ScreenCaptureKit \
        -framework ServiceManagement -framework UniformTypeIdentifiers \
        "${SOURCES[@]}" -o "$APP/Contents/MacOS/LocalInk"
fi

chmod +x "$APP/Contents/MacOS/LocalInk"
codesign --force --sign - "$APP"
echo "Built: $APP"
echo "Start with: open '$APP'"
