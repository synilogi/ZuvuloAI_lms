# FLUTTER-003 API Client & Contract Layer — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## API-001 — Academy unreachable at launch: keep the session, offer Try again

- **Module:** FLUTTER-003
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** A stored session is not thrown away because the server cannot be reached; the splash explains and recovers.
- **Preconditions:** learner signed in
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Make the API unreachable (relay refuses; device stays online)
3. Relaunch
4. Restore the API
5. Tap Try again

**Expected**

- "Can't reach SyniastroLMS" with "Try again" — not the sign-in form
- After Try again: the learner home for Ananya, without signing in again

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** API reachable again even on failure

## API-002 — A screen that fails to load offers a retry that works

- **Module:** FLUTTER-003
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** A data screen opened while the API is unreachable shows the shared error state, and its retry loads the real data.
- **Preconditions:** learner signed in
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Make the API unreachable
3. Open the My Learning tab
4. Restore the API
5. Tap the retry action

**Expected**

- An error state with a retry action (no endless spinner, no crash)
- After retry: the first of this learner's own enrolled courses (read from /learning/courses) is listed

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** API reachable again even on failure
