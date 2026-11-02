# FLUTTER-004 Secure Session & Authentication — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## AUTH-001 — Cold launch shows Welcome, then the sign-in form

- **Module:** FLUTTER-004
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** A first-run app opens on the unauthenticated Welcome screen and its Sign in action opens the form.
- **Preconditions:** dev flavor installed; app data cleared
- **Test data:** none

**Actions**

1. Clear app data
2. Launch the app
3. Read the Welcome screen
4. Tap Sign in

**Expected**

- Welcome shows the headline and Sign in / Create account / Browse courses / Verify a certificate / Help centre
- No learner home and no tab bar
- Sign in screen shows Email, Password, Show password, Sign in, Forgot password?, Create account

**Evidence:** welcome screenshot; sign-in screenshot

**Cleanup:** none needed

## AUTH-002 — Empty email and password are refused on the device

- **Module:** FLUTTER-004
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Submitting an empty form shows both field errors and sends nothing.
- **Preconditions:** signed out
- **Test data:** none

**Actions**

1. Open Sign in
2. Leave both fields empty
3. Tap Sign in

**Expected**

- "Enter a valid email address." under Email
- "Enter your password." under Password
- No server error banner
- Still on Sign in

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-003 — Malformed email is refused

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** An address without a domain is caught by the client check before any request.
- **Preconditions:** signed out
- **Test data:** email "not-an-email"; any password

**Actions**

1. Type "not-an-email" into Email
2. Type a password
3. Tap Sign in

**Expected**

- "Enter a valid email address." shown
- No password error
- No server banner
- Still on Sign in

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-004 — Valid email with an empty password is refused

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** Only the password error appears when only the password is missing.
- **Preconditions:** signed out
- **Test data:** seeded learner email

**Actions**

1. Type the learner email
2. Leave Password empty
3. Tap Sign in

**Expected**

- "Enter your password." shown
- No email error
- Still on Sign in

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-005 — Empty email with a password is refused

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** Only the email error appears when only the email is missing.
- **Preconditions:** signed out
- **Test data:** none

**Actions**

1. Leave Email empty
2. Type a password
3. Tap Sign in

**Expected**

- "Enter a valid email address." shown
- No password error
- Still on Sign in

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-006 — Wrong password is refused and the person stays signed out

- **Module:** FLUTTER-004
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The server's 401 is shown as the app's title plus the server's message; nothing is stored.
- **Preconditions:** seeded learner exists
- **Test data:** seeded learner email; a wrong password

**Actions**

1. Sign in with the learner email and a wrong password
2. Read the banner
3. Relaunch the app

**Expected**

- Banner "We couldn't sign you in." with "Incorrect email or password."
- Still on Sign in; the email stays filled in; no learner home
- After a relaunch the app is still signed out (Welcome)

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-007 — Unknown email gets the same refusal as a wrong password

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The app does not reveal whether an account exists.
- **Preconditions:** none
- **Test data:** nonexistent_<stamp>@example.test

**Actions**

1. Sign in with an address that has no account

**Expected**

- Same banner text as AUTH-006 ("Incorrect email or password.")
- Still signed out

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-008 — Network failure on sign-in, then retry once back online

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** With no network the app explains it cannot reach the academy, keeps the form, and the same tap works once online.
- **Preconditions:** seeded learner exists
- **Test data:** none

**Actions**

1. Turn Wi-Fi and mobile data off
2. Sign in with valid credentials
3. Read the banner
4. Turn the network back on
5. Tap Sign in again

**Expected**

- Banner "We couldn't sign you in." with "You're offline. Connect to continue."
- Still on Sign in while offline
- The retry signs Ananya in

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Network restored even if the scenario fails

## AUTH-009 — Valid sign-in: busy state, then that learner's own home

- **Module:** FLUTTER-004
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The button shows its busy state while the request is in flight and the home that opens belongs to the account that signed in.
- **Preconditions:** seeded learner exists
- **Test data:** seeded learner (Ananya)

**Actions**

1. Slow the emulator network
2. Sign in as the learner
3. Watch the Sign in button
4. Wait for home
5. Open Profile

**Expected**

- Sign in button is disabled (busy) while the request runs, and the form is not left half-submitted
- Learner home greets "Ananya" with the five learner tabs
- Profile shows Ananya Rao, ananya@syniastrolms.test, Learner — the same account /auth/me returns for those credentials

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Network latency removed

## AUTH-010 — A signed-in session survives a relaunch

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The token in secure storage restores the session through GET /auth/me after the process is killed.
- **Preconditions:** learner signed in (AUTH-009 or fresh sign-in)
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Force-stop the app
3. Launch it again

**Expected**

- The learner home opens again for Ananya without the sign-in form

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-011 — Back from the signed-in home does not return to the sign-in form

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The sign-in stack is cleared after signing in, so Back cannot land on the form (or bypass anything).
- **Preconditions:** signed out
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Press Back on the home
3. Reopen the app

**Expected**

- Back does not show Sign in or Welcome
- Reopening shows the learner home

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-012 — Sign out from Profile returns to Welcome and stays signed out

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Sign out asks for confirmation, clears the session, and neither Back nor a relaunch brings the home back.
- **Preconditions:** seeded learner exists
- **Test data:** none

**Actions**

1. Sign in as the learner
2. More → Profile → Sign out
3. Confirm in the dialog
4. Press Back
5. Relaunch

**Expected**

- A "Sign out?" confirmation appears first
- Welcome after confirming
- Back does not reopen the home
- Relaunch stays on Welcome

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-013 — Sign out ends the session on the server too

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** POST /auth/logout exists (SAAS-020, backend item B1 settled): signing out in the app must end that session server-side, not only forget the token locally.
- **Preconditions:** seeded learner exists
- **Test data:** none

**Actions**

1. Count the learner's open sessions (API)
2. Sign in through the app
3. Count again (+1)
4. Sign out through the app
5. Count again

**Expected**

- Signing in opens exactly one new session
- Signing out closes it again

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-014 — Signing in again after signing out

- **Module:** FLUTTER-004
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The sign-in form works normally after a sign-out in the same app process.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Sign out
3. Sign in as the learner again

**Expected**

- Learner home for Ananya again

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-015 — Rapid repeated taps on Sign in open one session

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** A busy form ignores further taps, so three quick taps cannot create three sessions.
- **Preconditions:** seeded learner exists
- **Test data:** none

**Actions**

1. Fill valid credentials
2. Slow the network
3. Tap Sign in three times quickly
4. Count new sessions (API)

**Expected**

- Exactly one new server session
- Learner home opens once

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Network latency removed

## AUTH-016 — Session ended elsewhere sends the person back to sign in

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** When every session of the account is revoked (logout-all from another device), the app notices on its next request and says so.
- **Preconditions:** seeded learner exists
- **Test data:** none

**Actions**

1. Sign in as the learner in the app
2. End all of the learner's sessions through the API (another device)
3. Relaunch the app

**Expected**

- Sign in with "Your session ended. Sign in again."
- No learner home

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-017 — Super Admin is told the app is not for them

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The platform Super Admin role is refused by the app (it lives on the web).
- **Preconditions:** platform super admin provisioned in the scratch database
- **Test data:** none

**Actions**

1. Sign in as the super admin

**Expected**

- "Platform administration is on the web" screen
- No learner or staff shell

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-018 — Registration form checks its fields

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The learner registration form refuses empty and too-short input before sending.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Welcome → Create account
2. Tap Create account with every field empty
3. Type a 1-letter name, a bad email and a 5-character password
4. Tap Create account

**Expected**

- Errors for name, email and password ("Use at least 8 characters.")
- Still on "Create your account"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-019 — Register a new learner and land on their own home

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P0
- **Safe to repeat:** no
- **Purpose:** Public registration creates a learner, signs them in and greets that exact new account.
- **Preconditions:** academy accepts self-registration (seed)
- **Test data:** ai_e2e_<stamp>_<tag>@example.test, name "Qa<tag> Learner", password E2E_SEED_PASSWORD

**Actions**

1. Welcome → Create account
2. Enter the new identity
3. Tap Create account
4. Open Profile

**Expected**

- The learner shell opens on the empty home ("Your learning starts here" → Explore courses): a new learner has no enrolments
- Profile shows the new name, email and Learner
- GET /auth/me for those credentials: same email, role student

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** The account stays in the scratch database for AUTH-020…AUTH-024; nothing shared is changed

## AUTH-020 — The new account signs out and back in

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The account created in AUTH-019 is a real, reusable account.
- **Preconditions:** AUTH-019 created the account
- **Test data:** none

**Actions**

1. Sign in as the new account
2. Sign out
3. Sign in again

**Expected**

- Each time, the learner shell opens and Profile names the new account

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-021 — Registering the same email twice is refused

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The server's 409 is shown on the form and no second account or session appears.
- **Preconditions:** AUTH-019 created the account
- **Test data:** none

**Actions**

1. Welcome → Create account
2. Enter a different name with the AUTH-019 email
3. Tap Create account

**Expected**

- Banner "We couldn't create your account." with "An account with this email already exists."
- Still on Create your account

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-022 — Forgot password: validation, then the neutral confirmation

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The reset request checks the address, then confirms without saying whether it exists — and a link really is queued for a real account.
- **Preconditions:** AUTH-019 created the account
- **Test data:** none

**Actions**

1. Sign in → Forgot password?
2. Tap Send with an invalid address
3. Enter the new account's email and send

**Expected**

- Email validation error
- "Check your email" confirmation
- The dev outbox holds a reset link addressed to that account

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## AUTH-023 — Reset link opened in the app sets a new password

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** no
- **Purpose:** Opening the e-mailed link (as the academy's App Link) shows the reset form; the new password works and the old one stops working; the used link is dead.
- **Preconditions:** AUTH-022 queued a link
- **Test data:** none

**Actions**

1. Open https://shubhlms.com/reset-password/<token> from the outbox in the app
2. Enter mismatched passwords → error
3. Enter the new password twice → Password updated
4. Sign in with the old password → refused
5. Sign in with the new password → home
6. Open the same link again

**Expected**

- "Set a new password" form
- "Both passwords must match."
- "Password updated"
- Old password refused
- The new account signs in with the new password (Profile names it)
- "This link is no longer valid"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** The password is set back to E2E_SEED_PASSWORD through a second reset link so later scenarios still sign in

## AUTH-024 — A suspended learner cannot sign in

- **Module:** FLUTTER-004
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** An academy suspension is enforced at sign-in and the app shows the server's reason.
- **Preconditions:** AUTH-019 created the account; admin holds learners.suspend
- **Test data:** none

**Actions**

1. Admin suspends the new learner (API setup)
2. Sign in as that learner in the app
3. Admin restores the learner (cleanup)
4. Sign in again

**Expected**

- Banner with "This account is suspended. Contact your admin to continue."
- No home while suspended
- After restore the same learner signs in

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Suspension lifted even if the scenario fails
