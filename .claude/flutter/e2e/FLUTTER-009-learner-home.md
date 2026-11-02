# FLUTTER-009 Learner Home & My Learning — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## HOME-001 — Home shows this learner's own courses and what is coming up

- **Module:** FLUTTER-009
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The learner home renders /learning/home for the signed-in learner.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Read Continue learning, Coming up, Your courses

**Expected**

- Each in-progress course of hers from /learning/home appears
- "Continue learning" offers Resume

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## HOME-002 — My Learning: in progress, completed and saved

- **Module:** FLUTTER-009
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The three segments list exactly this learner's enrolments by state.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. My Learning tab
2. In progress
3. Completed
4. Saved

**Expected**

- In-progress course titles from /learning/courses
- Completed ones under Completed (or its empty state)
- Saved ones (or "Nothing saved")

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
