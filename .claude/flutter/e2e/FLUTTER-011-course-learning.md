# FLUTTER-011 Course Learning & Lesson Player — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## LEARN-001 — Resume opens the next lesson of that course

- **Module:** FLUTTER-011
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Home's Resume takes the learner to the lesson the server says is next, in the same course.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Home → Continue learning → Resume

**Expected**

- The lesson player shows the next lesson title from /learning/home
- "{n} of {total}" position

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## LEARN-002 — The course page lists its curriculum and moves between lessons

- **Module:** FLUTTER-011
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Opening an enrolled course shows chapters and lessons; Next and Previous move within the course.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. My Learning → an in-progress course
2. Open its first lesson
3. Next
4. Previous

**Expected**

- "Curriculum" with the first chapter title
- Next shows a different lesson; Previous returns to the first

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
