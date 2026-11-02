# FLUTTER-010 Explore & Enrollment — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## EXP-001 — Explore shows enrolled and new courses differently

- **Module:** FLUTTER-010
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Explore lists the academy's courses and marks the ones this learner is already in.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Explore tab
2. Find an enrolled course and a not-enrolled course (from the API)

**Expected**

- Both listed
- The enrolled one carries "Enrolled"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## EXP-002 — Save a course, see it in Saved, unsave it

- **Module:** FLUTTER-010
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Save/unsave round-trips through the server and My Learning → Saved.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Explore → a course she is not in
2. Save this course
3. My Learning → Saved
4. Back to the course → Remove from saved

**Expected**

- "Remove from saved" after saving
- The course under Saved
- Unsaved again (API agrees)

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** The course is unsaved at the end

## EXP-003 — Enrol asks first; Cancel enrols nobody

- **Module:** FLUTTER-010
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The enrol confirmation appears and cancelling leaves the learner not enrolled (the irreversible confirm is deep QA).
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Explore → a course she is not in
2. Enrol
3. Cancel

**Expected**

- "Enrol in this course?" dialog
- After Cancel: still not enrolled (API), Enrol still offered

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
