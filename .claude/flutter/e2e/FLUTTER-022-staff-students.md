# FLUTTER-022 Staff Students — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## STU-001 — Search the roster and open a learner

- **Module:** FLUTTER-022
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** People lists the academy's learners; a search finds one and her profile shows her own enrolments.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Admin: People tab
2. Search "Ananya"
3. Open her

**Expected**

- Ananya Rao listed
- Profile tabs Overview/Courses/Progress/Activity; her enrolled course titles under Courses

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## STU-002 — Status filter: Active

- **Module:** FLUTTER-022
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The Active chip narrows the roster to active learners (counts from the server).
- **Preconditions:** none
- **Test data:** none

**Actions**

1. People → Active

**Expected**

- Chip reads "Active, {n}" with n from GET /students counts

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
