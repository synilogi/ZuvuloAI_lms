# FLUTTER-000 Workspace Bootstrap & Tooling — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## BOOT-001 — Open the dev build from the launcher like a person

- **Module:** FLUTTER-000
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The dev flavor is installed under its own launcher label and opens on Welcome when tapped there.
- **Preconditions:** dev flavor installed
- **Test data:** none

**Actions**

1. Go to the Android home screen
2. Open the app drawer
3. Tap "SyniastroLMS Dev"

**Expected**

- The drawer lists "SyniastroLMS Dev"
- Tapping it brings the dev package to the foreground on Welcome

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## BOOT-002 — Back on Welcome leaves the app cleanly; reopening returns to Welcome

- **Module:** FLUTTER-000
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The root screen hands Back to Android (no blank page, no crash) and a reopen starts normally.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Launch to Welcome
2. Press Back
3. Reopen the app

**Expected**

- The launcher is in front after Back
- No crash logged
- Welcome again on reopen

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
