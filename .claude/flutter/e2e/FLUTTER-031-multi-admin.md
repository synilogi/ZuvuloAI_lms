# FLUTTER-031 Multi-Admin SaaS Integration — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## MA-001 — A join link opens Create account for that Admin’s LMS, and the learner joins it

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** no
- **Purpose:** A learner who taps Admin A's join link registers into Admin A's LMS — not the host's default one.
- **Preconditions:** contract server with two Admins (created by the scenario through the Super Admin API)
- **Test data:** none

**Actions**

1. Open https://shubhlms.com/join/<A's address>
2. Check the LMS address is filled in
3. Enter a new learner and Create account
4. Open Profile

**Expected**

- LMS address shows A's address
- The new learner home opens and Profile names the new learner
- The platform lists the learner in Admin A's LMS

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-002 — A typed (or pasted) LMS address joins that Admin’s LMS

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** no
- **Purpose:** The LMS address field accepts a pasted join link and the learner joins Admin B's LMS.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Welcome → Create account
2. Paste B's whole join link into LMS address
3. Enter a new learner and Create account

**Expected**

- The new learner home opens
- The platform lists the learner in Admin B's LMS, not A's

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-003 — An LMS address nobody has is refused, and an empty one is caught on the device

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** A wrong address creates nothing and says why; a missing one is never sent.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Create account with no LMS address
2. Then with "no-such-lms-anywhere"

**Expected**

- "Enter the LMS address from your join link." under the field
- Banner "No LMS has this address"
- Still on Create your account; no home

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-004 — Each learner sees only their own Admin’s messages, on the same device one after the other

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Admin A messages its learners; learner A sees it; learner B, signing in next on the same device, sees nothing of it.
- **Preconditions:** MA-001 and MA-002 created learner A and learner B
- **Test data:** none

**Actions**

1. Admin A sends a message to learner A (API)
2. Learner A signs in → bell → the message is listed
3. Sign out
4. Learner B signs in → bell

**Expected**

- Learner A's notifications list Admin A's message
- Learner B's notifications do not show it — neither from the server nor left over on the device

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-005 — Session restoration keeps the same learner; sign out and back in works

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** A relaunch restores exactly the account that was signed in, and a sign-out ends it.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Learner A signs in
2. Kill and relaunch the app
3. Profile
4. Sign out
5. Sign in again

**Expected**

- After the relaunch, Profile still names learner A with no sign-in
- After sign-out, Welcome
- Signing in again lands on learner A

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-006 — Wrong credentials are refused without saying which part was wrong

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** A wrong password for a real learner signs nobody in.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as learner A with a wrong password

**Expected**

- The sign-in failure banner
- No home

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-007 — An instructor Admin A invited signs in to A’s staff workspace

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** no
- **Purpose:** Admin A adds an instructor; the instructor sets a password from the invitation and signs in on the device.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Admin A creates an instructor (API)
2. The invitation link sets a password (API)
3. Sign in as the instructor

**Expected**

- The instructor staff shell (Dashboard, Review, Courses, Live, More)
- The platform lists the instructor in Admin A's LMS

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-008 — Admin A signs in on the device and sees only A’s learners

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The Admin's People list holds Admin A's learners and none of Admin B's.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as Admin A
2. People tab

**Expected**

- Admin dashboard
- Learner A listed
- Learner B absent

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-009 — Cross-LMS requests are refused by the API whatever the client sends

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** Tokens of Admin A's learner and admin cannot reach Admin B's records; a tenant id in a body is ignored.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. A's admin: GET/suspend B's learner; A's learner: GET B's notifications by id; register with a forged tenantId

**Expected**

- 404 for every record of B
- The forged registration lands where its LMS address says, never where tenantId says

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## MA-010 — A suspended LMS signs its learner out with the reason, and refuses sign-in

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** When the platform suspends Admin B, learner B — already signed in on the device — is told why, and cannot sign in until it is restored.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Learner B signs in
2. The Super Admin suspends Admin B (API)
3. Relaunch the app
4. Try to sign in again
5. The Super Admin reactivates B (API)
6. Sign in

**Expected**

- After the relaunch: the sign-in screen with "This account is suspended…"
- Signing in: banner "This account is suspended"
- After reactivation, learner B signs in

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Admin B is reactivated

## MA-011 — A lapsed plan is shown to Admin A’s instructor as the backend reports it

- **Module:** FLUTTER-031
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** no
- **Purpose:** When Admin A's subscription ends, A's instructor sees the restricted state the server reports — and Admin B is untouched.
- **Preconditions:** MA-007 created the instructor
- **Test data:** none

**Actions**

1. The Super Admin ends A's subscription now (API)
2. A's instructor signs in

**Expected**

- /academy/plan for A: restricted
- The device marks the plan modules (Review, Courses, Live) "Read-only"
- /academy/plan for B: not restricted

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
