# FLUTTER-024 Staff Calendar — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## CAL-001 — Add a private reminder, see it, remove it

- **Module:** FLUTTER-024
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The instructor creates her own reminder (Only me), finds it on the agenda, opens it and removes it.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Calendar → Add to the calendar
2. Title "E2E reminder <stamp>", Only me → Add it
3. Open it → Remove → confirm

**Expected**

- "It is on the calendar" and the reminder on the agenda
- The server lists it
- "The event is removed" and it is gone from the server

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** The reminder is removed even if the scenario fails
