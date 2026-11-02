# FLUTTER-021 Staff Quizzes Overview — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## SQZ-001 — Quizzes list and one quiz's set-up and results

- **Module:** FLUTTER-021
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** More → Quizzes lists GET /quizzes; a quiz opens its configuration and statistics.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Quizzes
2. Open the first quiz

**Expected**

- That quiz title listed
- "How it is set up" with "Pass mark" and the attempts statistics

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## SQZ-002 — Staff see the answer key

- **Module:** FLUTTER-021
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The questions section shows answers to staff only.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Quizzes → first quiz → The questions

**Expected**

- "The answers below are shown to staff only." and a "Correct" marker

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
