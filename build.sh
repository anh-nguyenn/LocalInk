#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

APP="$PWD/dist/LocalInk.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Info.plist "$APP/Contents/Info.plist"
if [[ -f Resources/AppIcon.icns ]]; then
    cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi

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
LIPO="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo"
STRIP="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/strip"

mkdir -p "$PWD/.build/module-cache" "$PWD/.build/universal"

# Collect every Swift source file so the project can grow past a single file.
SOURCES=()
while IFS= read -r -d '' file; do
    SOURCES+=("$file")
done < <(find Sources -name '*.swift' -print0 | sort -z)

compile() {
    local target="$1"
    local arch="${target%%-*}"
    local out="$PWD/.build/universal/LocalInk-$arch"
    "$XCODE_SWIFTC" -O -sdk "$XCODE_SDK" -target "$target" \
        -module-cache-path "$PWD/.build/module-cache" \
        -framework AppKit -framework Carbon -framework ScreenCaptureKit \
        -framework ServiceManagement -framework UniformTypeIdentifiers \
        "${SOURCES[@]}" -o "$out"
    echo "$out"
}

if [[ -x "$XCODE_SWIFTC" && -d "$XCODE_SDK" ]]; then
    ARM_BIN="$(compile "arm64-apple-macosx13.0")"
    INTEL_BIN="$(compile "x86_64-apple-macosx13.0")"
    "$LIPO" -create -output "$APP/Contents/MacOS/LocalInk" "$ARM_BIN" "$INTEL_BIN"
else
    echo "warning: full Xcode toolchain not found; building for the current architecture only" >&2
    xcrun swiftc -O -module-cache-path "$PWD/.build/module-cache" \
        -framework AppKit -framework Carbon -framework ScreenCaptureKit \
        -framework ServiceManagement -framework UniformTypeIdentifiers \
        "${SOURCES[@]}" -o "$APP/Contents/MacOS/LocalInk"
fi

chmod +x "$APP/Contents/MacOS/LocalInk"
"$STRIP" -x "$APP/Contents/MacOS/LocalInk" 2>/dev/null || true

# Ad-hoc signing keeps the bundle launchable locally. Set CODESIGN_IDENTITY to
# a "Developer ID Application" identity to sign a notarizable release instead.
SIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
if [[ "$SIGN_IDENTITY" == "-" ]]; then
    codesign --force --sign - "$APP"
else
    codesign --force --options runtime --sign "$SIGN_IDENTITY" "$APP"
fi

echo "Built: $APP"
if [[ -x "$LIPO" ]]; then
    echo "Architectures: $("$LIPO" -archs "$APP/Contents/MacOS/LocalInk")"
fi
echo "Start with: open '$APP'"
