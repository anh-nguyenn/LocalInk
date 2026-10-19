#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
else
    DEVELOPER_DIR="$(xcode-select -p)"
fi

SWIFTC="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
SDK="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"

mkdir -p .build/icon Resources
"$SWIFTC" -sdk "$SDK" -target "$(uname -m)-apple-macosx13.0" \
    -framework AppKit scripts/make-icon.swift -o .build/icon/make-icon
.build/icon/make-icon

iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
echo "Wrote Resources/AppIcon.icns"
