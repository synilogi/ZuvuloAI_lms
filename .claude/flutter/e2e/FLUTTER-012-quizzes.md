# FLUTTER-012 Learner Quizzes & Assessments — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## QUIZ-001 — Assessments lists this learner's quizzes with their state

- **Module:** FLUTTER-012
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** More → Assessments shows each quiz from /learning/assessments with its pass mark.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Assessments

**Expected**

- Each quiz title listed
- "pass 70%"-style pass mark shown

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## QUIZ-002 — Take a passed quiz again as practice and pass it

- **Module:** FLUTTER-012
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** A quiz already passed can be practised again; answering it right ends in "Passed" (the server scores it).
- **Preconditions:** a quiz in state passed (unlimited practice after a pass)
- **Test data:** none

**Actions**

1. More → Assessments → the passed quiz
2. Start the quiz
3. Answer each question
4. Review answers → Submit → Submit

**Expected**

- "Question 1 of N"
- "Submit this attempt?"
- A result screen ("Passed" or "Not passed this time") from the server

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
