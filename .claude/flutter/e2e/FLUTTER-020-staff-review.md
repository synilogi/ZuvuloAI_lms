# FLUTTER-020 Staff Assignment Review & Grading — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## REV-001 — The review queue lists hand-ins waiting for her

- **Module:** FLUTTER-020
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Review shows GET /assignments/submissions?filter=to-review for the instructor.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Review tab

**Expected**

- "To review" selected; the first waiting learner and assignment listed (or "Nothing to review")

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## REV-002 — Open a hand-in and see what the learner sent

- **Module:** FLUTTER-020
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The submission detail shows that learner, the brief, what they handed in and the score panel.
- **Preconditions:** at least one hand-in waiting for review
- **Test data:** none

**Actions**

1. Review → the first waiting hand-in

**Expected**

- That learner's name, "The brief", "What the learner handed in", "The score"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## REV-003 — Status filters switch the list

- **Module:** FLUTTER-020
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The Graded filter shows graded work from the server.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Review → Graded

**Expected**

- A graded learner from filter=graded listed (or the empty state)

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
