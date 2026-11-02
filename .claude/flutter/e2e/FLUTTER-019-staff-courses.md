# FLUTTER-019 Staff Courses & Curriculum — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## SCRS-001 — The instructor sees exactly her courses

- **Module:** FLUTTER-019
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Courses lists GET /courses for the instructor, and a search narrows to one.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Courses tab
2. Search for one of her titles

**Expected**

- Each of her course titles listed
- Search leaves that course

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## SCRS-002 — Course detail and its curriculum

- **Module:** FLUTTER-019
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** A course opens its stats and its read-only curriculum (chapters and lessons from the server).
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Courses → her first course
2. Curriculum

**Expected**

- Title, "Published" badge, "How it is going"
- "{n} chapters · {n} lessons" and the first chapter title

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## SCRS-003 — Admin unpublishes a course and publishes it back

- **Module:** FLUTTER-019
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The lifecycle actions ask first and the server's status follows (reversible pair). Done as the academy admin: this academy's policy sends an instructor's publish to admin review (403), so only an admin can bring a course back.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Admin: Courses → a published course → Unpublish → confirm
2. Publish → confirm

**Expected**

- "Take it out of the catalogue?" then "Draft"; API status draft
- "Take this course live?" then "The course is live"; API status published

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Course published again (as admin) even if the scenario fails
