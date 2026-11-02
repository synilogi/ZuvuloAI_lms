# FLUTTER-007 Media Foundation — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## MEDIA-001 — Choose a file opens the system picker and coming back is safe

- **Module:** FLUTTER-007
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** A file assignment's upload hands over to Android's document picker; backing out returns to the same assignment with nothing attached.
- **Preconditions:** a published file-format assignment on a course the learner is enrolled in (created by the scenario through the staff API, deleted afterwards)
- **Test data:** assignment "E2E file upload <stamp>" (format file) on the learner's first enrolled course

**Actions**

1. Instructor API: create and publish the file assignment
2. Learner: More → Assignments → that assignment
3. Tap Choose a file
4. Back out of the system picker

**Expected**

- Android's document picker opens (another package in front)
- Back returns to the same assignment, no crash, nothing attached

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** The assignment is deleted through the staff API

## MEDIA-002 — A preview lesson without a file says so instead of failing

- **Module:** FLUTTER-007
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The seeded preview video has no media attached; the player must show its empty state, not an error or a spinner.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Welcome → Browse courses → the first course
2. Curriculum → open its first chapter
3. Tap the free-preview lesson (isPreview in GET /catalog/courses)

**Expected**

- "Nothing to show yet" with "The academy has not attached a file to this lesson."

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
