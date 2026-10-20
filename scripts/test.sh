#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

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

mkdir -p .build/test
"$XCODE_SWIFTC" -sdk "$XCODE_SDK" -target "$(uname -m)-apple-macosx13.0" \
    -framework AppKit -framework ImageIO -framework CoreText \
    Sources/Annotation.swift Sources/Renderer.swift Sources/ExportService.swift \
    Sources/StateController.swift \
    Tests/Logic/main.swift -o .build/test/logic

.build/test/logic
