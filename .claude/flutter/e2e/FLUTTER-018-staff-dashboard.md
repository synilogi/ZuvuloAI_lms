# FLUTTER-018 Staff Dashboard — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## DASH-001 — The instructor's dashboard shows her figures and next class

- **Module:** FLUTTER-018
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** GET /dashboard for the instructor is rendered: KPIs, needs-attention, upcoming live.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as the instructor
2. Read the dashboard top to bottom

**Expected**

- "Needs you", "How things stand" with the KPI tiles
- Her next live class title from the API under "Coming up live" (if any)

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## DASH-002 — Admin switches between the academy and one instructor

- **Module:** FLUTTER-018
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The admin scope control re-reads the dashboard for one instructor and back.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as the admin
2. One instructor
3. Pick the instructor
4. Whole LMS

**Expected**

- "Active instructors" KPI for the academy
- Instructor chips appear for one instructor
- Back to the academy view

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## DASH-003 — "Do next" opens the review queue

- **Module:** FLUTTER-018
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** A dashboard shortcut lands on the screen it names.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Instructor dashboard → Do next → Review queue

**Expected**

- The Review tab is selected with its queue

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
