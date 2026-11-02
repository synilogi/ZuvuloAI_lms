# FLUTTER-013 Learner Assignments — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## ASG-001 — Assignments lists this learner's work with its state

- **Module:** FLUTTER-013
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** More → Assignments shows every assignment from /learning/assignments, the overdue one marked Overdue.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Assignments

**Expected**

- Each assignment title
- An overdue one shows "Overdue"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## ASG-002 — Write a draft and save it

- **Module:** FLUTTER-013
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** A learner drafts an answer on an open assignment and the draft is saved on the server.
- **Preconditions:** an assignment the learner can still work on (not submitted)
- **Test data:** none

**Actions**

1. More → Assignments → an open assignment
2. Type into "Your work"
3. Save draft

**Expected**

- "Draft saved"
- GET /learning/assignments/:id holds the typed text

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Only the learner's own draft on that assignment is changed
