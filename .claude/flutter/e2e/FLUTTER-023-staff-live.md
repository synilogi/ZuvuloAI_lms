# FLUTTER-023 Staff Live Classes — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## SLIV-001 — The instructor's upcoming classes and one class

- **Module:** FLUTTER-023
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Live lists GET /live?view=upcoming; a class opens with its sections and actions.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Live tab
2. Open the first upcoming class

**Expected**

- That class title
- "About this class", "Who registered", and Edit / "Cancel the class" actions

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## SLIV-002 — The schedule form will not send an empty class

- **Module:** FLUTTER-023
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** "Schedule a class" opens the form, and with nothing filled in its submit stays disabled, so nothing can be created.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Live → Schedule a class
2. Look at "Schedule it" with the form empty
3. Back

**Expected**

- The form "Schedule a class" with Course, Title and Meeting link fields
- "Schedule it" disabled
- No new class on the server

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
