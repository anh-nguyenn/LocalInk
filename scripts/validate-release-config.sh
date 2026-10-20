#!/usr/bin/env bash
set -euo pipefail

if [[ "${CODESIGN_IDENTITY:-}" != "Developer ID Application:"* ]]; then
    echo "A Developer ID Application certificate is required for a trusted release." >&2
    echo "Set CODESIGN_IDENTITY to the certificate name in your keychain." >&2
    exit 2
fi
if [[ -z "${NOTARYTOOL_PROFILE:-}" ]]; then
    echo "Set NOTARYTOOL_PROFILE to a notarytool keychain profile." >&2
    exit 2
fi
