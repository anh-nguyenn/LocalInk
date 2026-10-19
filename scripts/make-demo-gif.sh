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

mkdir -p .build/gif
"$SWIFTC" -sdk "$SDK" -target "$(uname -m)-apple-macosx13.0" \
    -framework AppKit -framework ImageIO -framework UniformTypeIdentifiers \
    scripts/make-demo-gif.swift -o .build/gif/make-demo-gif
.build/gif/make-demo-gif
ls -lh website/assets/demo.gif
