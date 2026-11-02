# FLUTTER-028 Push Notifications & Deep Links — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## LINK-001 — A certificate verification link opens the public result

- **Module:** FLUTTER-028
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** /verify/<credential> from outside the app opens the in-app result for that same credential, signed out.
- **Preconditions:** the learner's own issued certificate (GET /learning/certificates)
- **Test data:** none

**Actions**

1. Pick the learner's issued credential from the API
2. Open https://shubhlms.com/verify/<id> with the app signed out

**Expected**

- "This certificate is valid" for that credential ID, awarded to the same learner

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## LINK-002 — A course link opens that course's public page

- **Module:** FLUTTER-028
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** /courses/<slug> maps to the catalogue page of exactly that course.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Pick a published course slug from GET /catalog/courses
2. Open https://shubhlms.com/courses/<slug>

**Expected**

- The public course page for that title, with "Sign in to enrol"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## LINK-003 — A protected link survives signing in from Welcome

- **Module:** FLUTTER-028
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** A signed-out person following /notifications is asked to sign in and then taken where the link pointed.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Signed out: open the notifications link
2. Welcome → Sign in → sign in as the learner

**Expected**

- After signing in, the Notifications page — not just the home

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
