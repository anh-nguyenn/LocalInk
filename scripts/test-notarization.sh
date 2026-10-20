#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

cat > "$test_dir/notarytool" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$MOCK_LOG"
printf '{"status":"%s","id":"test-submission"}\n' "$MOCK_STATUS"
MOCK
cat > "$test_dir/stapler" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_STAPLE_LOG"
MOCK
chmod +x "$test_dir/notarytool" "$test_dir/stapler"
touch "$test_dir/LocalInk.dmg"
touch "$test_dir/app-submission.zip"
mkdir "$test_dir/LocalInk.app"

export LOCALINK_NOTARYTOOL="$test_dir/notarytool"
export LOCALINK_STAPLER="$test_dir/stapler"
export MOCK_LOG="$test_dir/notary.log"
export MOCK_STAPLE_LOG="$test_dir/staple.log"

export MOCK_STATUS=Accepted
./scripts/notarize.sh "$test_dir/app-submission.zip" "$test_dir/LocalInk.app" test-profile
[[ "$(cat "$MOCK_LOG")" == "submit $test_dir/app-submission.zip --keychain-profile test-profile --wait --output-format json" ]]
[[ "$(cat "$MOCK_STAPLE_LOG")" == "staple $test_dir/LocalInk.app"$'\n'"validate $test_dir/LocalInk.app" ]]

rm "$MOCK_STAPLE_LOG"
export MOCK_STATUS=Invalid
if ./scripts/notarize.sh "$test_dir/LocalInk.dmg" "$test_dir/LocalInk.dmg" test-profile >"$test_dir/rejected.log" 2>&1; then
    echo "FAIL: invalid notarization was accepted" >&2
    exit 1
fi
[[ ! -e "$MOCK_STAPLE_LOG" ]]
grep -q '"status":"Invalid"' "$test_dir/rejected.log"

if env -u CODESIGN_IDENTITY -u NOTARYTOOL_PROFILE bash scripts/validate-release-config.sh >/dev/null 2>&1; then
    echo "FAIL: release accepted missing signing credentials" >&2
    exit 1
fi
if CODESIGN_IDENTITY=- NOTARYTOOL_PROFILE=test-profile bash scripts/validate-release-config.sh >/dev/null 2>&1; then
    echo "FAIL: release accepted ad hoc signing" >&2
    exit 1
fi
CODESIGN_IDENTITY="Developer ID Application: Test (TESTTEAM)" NOTARYTOOL_PROFILE=test-profile \
    bash scripts/validate-release-config.sh
if env -u CODESIGN_IDENTITY -u NOTARYTOOL_PROFILE ./release.sh >"$test_dir/preflight.log" 2>&1; then
    echo "FAIL: release built without notarization credentials" >&2
    exit 1
fi
grep -q 'Developer ID Application certificate is required' "$test_dir/preflight.log"

echo "PASS: accepted submissions are stapled and invalid submissions stop"
