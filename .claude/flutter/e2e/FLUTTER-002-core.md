# FLUTTER-002 Core Infrastructure — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## CORE-001 — Offline banner appears when the device loses its network and clears on return

- **Module:** FLUTTER-002
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The connectivity monitor tells a signed-in person they are offline and that they are seeing what was already loaded.
- **Preconditions:** learner signed in
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Turn Wi-Fi and data off
3. Read the shell
4. Turn them back on

**Expected**

- "You're offline. Showing what was loaded." appears above the content
- Content already loaded stays on screen
- The banner disappears once online

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Network restored even on failure
