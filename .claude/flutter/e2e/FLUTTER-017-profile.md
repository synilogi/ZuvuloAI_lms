# FLUTTER-017 Profile, Account & App Settings — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## PROF-001 — Profile shows who is signed in

- **Module:** FLUTTER-017
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Profile renders /auth/me for the signed-in account.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Profile

**Expected**

- Name, email and "Learner" of the account /auth/me returns

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## PROF-002 — Switch to the dark theme and back

- **Module:** FLUTTER-017
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** App settings → Appearance changes the theme immediately and the choice is kept.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Profile → App settings
2. Dark
3. Relaunch
4. Match my phone

**Expected**

- Dark selected and kept after a relaunch
- Restored to Match my phone

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Appearance back to Match my phone

## PROF-003 — About this app names the app and its version

- **Module:** FLUTTER-017
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The About dialog identifies the build.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Profile → About this app

**Expected**

- "SyniastroLMS" and "Version …"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
