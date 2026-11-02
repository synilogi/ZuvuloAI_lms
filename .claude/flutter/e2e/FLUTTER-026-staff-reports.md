# FLUTTER-026 Admin Reports — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## REP-001 — The overview report and a period change

- **Module:** FLUTTER-026
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** More → Reports shows the overview; changing the period re-reads it.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Admin: More → Reports
2. Filters → Last 30 days → Show the reports

**Expected**

- "Last 90 days" caption with KPIs
- "Last 30 days" caption afterwards

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## REP-002 — Courses report lists the busiest courses

- **Module:** FLUTTER-026
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The Courses report opens from the overview and names real courses.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Reports → Courses

**Expected**

- A published course title from GET /courses

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
