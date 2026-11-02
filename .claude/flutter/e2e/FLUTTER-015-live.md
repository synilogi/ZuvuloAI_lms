# FLUTTER-015 Learner Live Classes — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## LIVE-001 — Live lists her upcoming class and its detail

- **Module:** FLUTTER-015
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The Live tab shows the upcoming class from /live/learner and its detail page.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Live tab
2. Open the upcoming class

**Expected**

- "Upcoming" with that class title
- Detail: "About this class" and the instructor

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## LIVE-002 — Take a seat and give it back

- **Module:** FLUTTER-015
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Registration toggles on the server for that same class.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Live → upcoming class
2. Save my seat (or Give up my seat first if already registered)
3. Give up my seat

**Expected**

- "Give up my seat" + "Registered" after saving; API registered=true
- Back to "Save my seat"; API registered as at the start

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Registration returned to its initial state
