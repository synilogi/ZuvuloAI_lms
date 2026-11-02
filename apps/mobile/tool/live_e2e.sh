#!/usr/bin/env bash
# LIVE UI E2E: drives the installed dev-flavor app on the Android Emulator from outside, through the
# accessibility tree and `adb input` (tool/live_e2e/driver.py). Not a replacement for
# `flutter test integration_test` — a different layer (.claude/flutter/e2e/README.md).
#
#   SCRATCH=<scratch dir> E2E_SEED_PASSWORD=… tool/live_e2e.sh run [--module FLUTTER-004] [--scenario AUTH-003] [--resume|--failed]
#   tool/live_e2e.sh install      build the dev debug APK, install it on the emulator, record the install
#                                 (every scenario checks the build was not replaced since)
#   APK=<path> tool/live_e2e.sh install   install a prebuilt APK (e.g. from an isolated worktree)
#   tool/live_e2e.sh list | docs | matrix | inspect
#
# Targets emulator-* only (E2E_DEVICE, default emulator-5554); the driver refuses anything else.
# The contract server must be running (tool/contract_server.sh start) on the same SCRATCH.
set -euo pipefail
cd "$(dirname "$0")/.."
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
DEVICE="${E2E_DEVICE:-emulator-5554}"
case "$DEVICE" in emulator-*) ;; *) echo "E2E_DEVICE must be an emulator-* device (got $DEVICE)" >&2; exit 2 ;; esac

if [[ "${1:-}" == install && -n "${APK:-}" ]]; then
  "$ANDROID_SDK_ROOT/platform-tools/adb" -s "$DEVICE" install -r "$APK"
  exec python3 tool/live_e2e/runner.py record-install
fi
if [[ "${1:-}" == install ]]; then
  # The E2E build reads config/dev_e2e.local.json (git-ignored) when present: same dev flavor and
  # keys, its own API port (the relay), so no other contract server on the machine is involved.
  config=config/dev.json
  [[ -f config/dev_e2e.local.json ]] && config=config/dev_e2e.local.json
  echo "building dev flavor with $config"
  flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file="$config"
  "$ANDROID_SDK_ROOT/platform-tools/adb" -s "$DEVICE" install -r build/app/outputs/flutter-apk/app-dev-debug.apk
  exec python3 tool/live_e2e/runner.py record-install
fi
exec python3 tool/live_e2e/runner.py "$@"
