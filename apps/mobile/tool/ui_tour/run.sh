#!/usr/bin/env bash
# Device UI tour (docs/ui-redesign-checklist.md). Screenshots every screen of one role on a device.
#
#   DEVICE=<adb id> CONFIG=<define file> TOUR_PASSWORD=<seed password> UI_TOUR_OUT=<dir> \
#     tool/ui_tour/run.sh <public|student|instructor|admin> [light|dark] [text scale] [stop,stop]
#
# CONFIG must point the app at a scratch API (tool/contract_server.sh), never production.
# TOUR_IDS (optional) is a define file of real ids and tokens from that API (TOUR_RESET, TOUR_COURSE, …)
# for the stops that need them; see `_ids` in ui_tour_test.dart.
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${DEVICE:?set DEVICE}" "${CONFIG:?set CONFIG}" "${TOUR_PASSWORD:?set TOUR_PASSWORD}"
# The device reaches the scratch API (and web, for the policy pages) through adb reverse; a USB
# reconnect drops those mappings, so set them again on every run. REVERSE_PORTS="4300 5173".
ADB="$(command -v adb || echo "${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb")"
for port in ${REVERSE_PORTS:-}; do "$ADB" -s "$DEVICE" reverse "tcp:$port" "tcp:$port" >/dev/null; done
flutter drive --flavor dev -d "$DEVICE" \
  --driver tool/ui_tour/driver.dart --target tool/ui_tour/ui_tour_test.dart \
  --dart-define-from-file="$CONFIG" \
  --dart-define=TOUR_ROLE="${1:-student}" --dart-define=TOUR_THEME="${2:-light}" \
  --dart-define=TOUR_SCALE="${3:-1}" --dart-define=TOUR_ONLY="${4:-}" \
  --dart-define=TOUR_PASSWORD="$TOUR_PASSWORD" \
  ${TOUR_IDS:+--dart-define-from-file="$TOUR_IDS"}
