#!/usr/bin/env bash
# Runs the workflow's verification commands (.claude/flutter/workflow.md §7.1) in order and stops at
# the first failure. Usage, from apps/mobile:
#   tool/verify.sh                  format, analyze, unit/widget tests, dev debug APK
#   tool/verify.sh --all-flavors    also builds the staging and prod debug APKs
#   DEVICE=11015313C8063805 tool/verify.sh --integration   (the USB test phone; emulators need USE_EMULATOR=1)
#                                   also runs integration_test on that device
set -euo pipefail
cd "$(dirname "$0")/.."

all_flavors=false
integration=false
for arg in "$@"; do
  case "$arg" in
    --all-flavors) all_flavors=true ;;
    --integration) integration=true ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

step() { printf '\n==> %s\n' "$*"; }

step "flutter pub get"
flutter pub get

if grep -rqs --include='*.dart' -E "^part '.+\.(g|freezed)\.dart';" lib; then
  step "code generation"
  # --force-jit: build_runner's AOT compile of its build script fails while a transitive
  # dependency ships native build hooks ("'dart compile' does not support build hooks").
  dart run build_runner build --delete-conflicting-outputs --force-jit
  # Generated files come out at the generator's own line width; format them (they are not
  # hand-written) so the strict check below covers only code a person wrote.
  find lib -name '*.g.dart' -o -name '*.freezed.dart' | xargs dart format >/dev/null
fi

step "dart format"
dart format --output=none --set-exit-if-changed lib test integration_test

step "flutter analyze"
flutter analyze --fatal-infos --fatal-warnings

step "flutter test"
flutter test --coverage

flavors=(dev)
if $all_flavors; then flavors=(dev staging prod); fi
for flavor in "${flavors[@]}"; do
  step "flutter build apk --debug --flavor $flavor"
  flutter build apk --debug --flavor "$flavor" -t "lib/main_$flavor.dart" \
    --dart-define-from-file="config/$flavor.json"
done

if $integration; then
  : "${DEVICE:?set DEVICE to the adb id of the USB test phone (adb devices), e.g. 11015313C8063805}"
  # The physical phone is the test target; an emulator only when explicitly asked for.
  case "$DEVICE" in emulator-*)
    [ "${USE_EMULATOR:-0}" = 1 ] || { echo "DEVICE is an emulator; set USE_EMULATOR=1 only when the owner asked for one." >&2; exit 2; } ;;
  esac
  if [ "$(adb -s "$DEVICE" get-state 2>/dev/null)" != device ]; then
    echo "Device $DEVICE is not connected and authorized. Reconnect the phone (USB debugging) and retry." >&2
    exit 2
  fi
  step "flutter test integration_test on $DEVICE"
  # A phone reaches the local contract server through adb reverse (config/dev_device.json); an
  # emulator through 10.0.2.2 (config/dev.json).
  case "$DEVICE" in
    emulator-*) define=config/dev.json ;;
    *) adb -s "$DEVICE" reverse tcp:4100 tcp:4100 >/dev/null; define=config/dev_device.json ;;
  esac
  flutter test integration_test -d "$DEVICE" --flavor dev --dart-define-from-file="$define"
fi

step "verification passed"
