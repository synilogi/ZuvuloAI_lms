# FLUTTER-008 Public Experience — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## PUB-001 — A visitor browses the catalogue and opens a course

- **Module:** FLUTTER-008
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Signed out, Browse courses lists the published catalogue and a course opens its public page.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Welcome → Browse courses
2. Find the first published course from GET /catalog/courses
3. Open it

**Expected**

- "Courses" with that course listed
- Its page: the title, "About this course", "Curriculum", "Sign in to enrol"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## PUB-002 — Level filter narrows the catalogue

- **Module:** FLUTTER-008
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** Choosing a level shows exactly the courses at that level.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Browse courses
2. Tap the Intermediate chip

**Expected**

- Every intermediate course from GET /catalog/courses?levelId=… is listed
- A beginner-only course is not

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## PUB-003 — Verify a certificate by credential ID, and an unknown ID

- **Module:** FLUTTER-008
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** A visitor checks a real credential (the learner's own) and a made-up one.
- **Preconditions:** the learner's issued certificate
- **Test data:** none

**Actions**

1. Welcome → Verify a certificate
2. Verify with an empty field
3. Enter the issued ID → Verify
4. Check another ID → an unknown ID → Verify

**Expected**

- "Enter a credential ID."
- "This certificate is valid" for that ID and learner
- "No certificate found for this ID"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## PUB-004 — The help centre opens an article

- **Module:** FLUTTER-008
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** A visitor reads help without signing in.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Welcome → Help centre
2. Open the first popular article from GET /help/articles

**Expected**

- "Help centre" with "Popular articles"
- The article title as its page

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
