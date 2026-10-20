#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 || -z "$3" ]]; then
    echo "Usage: $0 SUBMISSION_FILE STAPLE_TARGET KEYCHAIN_PROFILE" >&2
    exit 2
fi

submission="$1"
staple_target="$2"
profile="$3"
if [[ ! -f "$submission" || ( ! -f "$staple_target" && ! -d "$staple_target" ) ]]; then
    echo "Notarization input or staple target does not exist" >&2
    exit 2
fi

if [[ -d /Applications/Xcode.app/Contents/Developer/usr/bin ]]; then
    tool_dir=/Applications/Xcode.app/Contents/Developer/usr/bin
else
    tool_dir="$(xcode-select -p)/usr/bin"
fi
notarytool="${LOCALINK_NOTARYTOOL:-$tool_dir/notarytool}"
stapler="${LOCALINK_STAPLER:-$tool_dir/stapler}"

response="$("$notarytool" submit "$submission" --keychain-profile "$profile" --wait --output-format json)"
submission_status="$(printf '%s' "$response" | plutil -extract status raw -o - -)"
if [[ "$submission_status" != Accepted ]]; then
    echo "Apple notarization failed for $submission:" >&2
    printf '%s\n' "$response" >&2
    exit 1
fi

"$stapler" staple "$staple_target"
"$stapler" validate "$staple_target"
