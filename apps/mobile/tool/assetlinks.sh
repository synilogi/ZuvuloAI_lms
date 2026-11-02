#!/usr/bin/env bash
# Generates the Android App Links statement file for each flavor (FLUTTER-028, B13).
#
# Android verifies an App Link by fetching
#   https://zuviloai.com/.well-known/assetlinks.json
# and checking that it names this app's package **and** the SHA-256 fingerprint of the certificate the
# installed build was signed with. Serving that file is a web-hosting change outside this workflow, so
# this script only writes the content a human then deploys.
#
#   tool/assetlinks.sh                      # from the debug keystore Flutter uses
#   KEYSTORE=… ALIAS=… tool/assetlinks.sh   # from a release keystore, once C6/C16 exist
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$HERE/android/assetlinks"
PACKAGE='com.shubhlms.mobile'
KEYSTORE="${KEYSTORE:-$HOME/.android/debug.keystore}"
ALIAS="${ALIAS:-androiddebugkey}"
STOREPASS="${STOREPASS:-android}"

[[ -f "$KEYSTORE" ]] || { echo "no keystore at $KEYSTORE" >&2; exit 1; }

FINGERPRINT="$(keytool -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$STOREPASS" 2>/dev/null \
  | awk -F'SHA256: ' '/SHA256:/ {print $2; exit}' | tr -d '[:space:]')"
[[ -n "$FINGERPRINT" ]] || { echo "could not read a SHA-256 fingerprint from $KEYSTORE" >&2; exit 1; }

mkdir -p "$OUT"
# One statement per flavor: each flavor is its own package, so each needs its own entry, and all three
# go in the single file the host serves.
{
  printf '[\n'
  first=1
  for suffix in '.dev' '.staging' ''; do
    [[ $first -eq 1 ]] || printf ',\n'
    first=0
    printf '  {\n'
    printf '    "relation": ["delegate_permission/common.handle_all_urls"],\n'
    printf '    "target": {\n'
    printf '      "namespace": "android_app",\n'
    printf '      "package_name": "%s%s",\n' "$PACKAGE" "$suffix"
    printf '      "sha256_cert_fingerprints": ["%s"]\n' "$FINGERPRINT"
    printf '    }\n'
    printf '  }'
  done
  printf '\n]\n'
} > "$OUT/assetlinks.json"

cat > "$OUT/DEPLOY.md" <<EOF
# Deploying assetlinks.json (B13)

Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) from \`$KEYSTORE\` (alias \`$ALIAS\`).
Fingerprint: \`$FINGERPRINT\`

Android will only open the academy's links in the app once this file is served, **unencoded**, at

    https://zuviloai.com/.well-known/assetlinks.json

with \`Content-Type: application/json\`, over https, with no redirect. Until then the links open the
browser and the web app handles them, which is the intended fallback.

## The step a human takes

1. Copy \`assetlinks.json\` to the web host's \`public/.well-known/\` (or the equivalent for the
   deployment) and deploy.
2. Confirm it is served: \`curl -sI https://zuviloai.com/.well-known/assetlinks.json\`
   returns 200 and \`application/json\`.
3. Reinstall the app, then check Android agrees:
   \`adb shell pm get-app-links $PACKAGE.dev\` should report \`verified\` for the host.

## Checking the routes without the file (dev)

Verification can be overridden locally, which is how the acceptance criteria were checked:

    adb shell pm set-app-links --package $PACKAGE.dev 0 all
    adb shell pm verify-app-links --re-verify $PACKAGE.dev
    adb shell am start -a android.intent.action.VIEW \\
      -d "https://zuviloai.com/verify/SA-JY-2026-00142"

## When the release key exists (C6/C16)

Re-run with that keystore and replace the file — a release build signed with a different certificate
will not verify against a debug fingerprint:

    KEYSTORE=/path/to/release.jks ALIAS=upload STOREPASS=… tool/assetlinks.sh
EOF

echo "wrote $OUT/assetlinks.json and $OUT/DEPLOY.md"
