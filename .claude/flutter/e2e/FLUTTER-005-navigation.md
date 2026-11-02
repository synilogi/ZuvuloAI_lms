# FLUTTER-005 App Shell, Routing & Role Navigation — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## NAV-001 — Each role lands in its own shell

- **Module:** FLUTTER-005
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The session decides the shell: a learner gets the learner tabs, an instructor and an admin get their staff tabs (§5.2).
- **Preconditions:** seeded learner, instructor and admin
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Sign in as the instructor
3. Sign in as the admin

**Expected**

- Learner: Home · My Learning · Explore · Live · More
- Instructor: Dashboard · Review · Courses · Live · More
- Admin: Dashboard · People · Courses · Review · More

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## NAV-002 — Tabs switch screens and Back returns to the first tab before leaving

- **Module:** FLUTTER-005
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** §5.5: Back pops within a tab, then returns to the first tab, then exits.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Learner: tap My Learning, Explore, Live
2. Press Back on Live

**Expected**

- Each tap selects that tab
- Back from Live lands on Home (still in the app)

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## NAV-003 — A More page is titled with its own name

- **Module:** FLUTTER-005
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** §5.2: "Every shell has an app bar with the page title". A page opened from More must say what it is.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Learner: More → Assignments
2. Read the app bar
3. More → Certificates
4. Read the app bar

**Expected**

- App bar reads "Assignments"
- App bar reads "Certificates"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## NAV-004 — Back from a More page returns to the app, not out of it

- **Module:** FLUTTER-005
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** §5.5: Back from a page reached through More goes back inside the app (to the first tab), never straight out of it.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Learner: More → Assignments
2. Press Back

**Expected**

- Still in the app, on Home

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## NAV-005 — An unknown link shows the not-found screen with a way home

- **Module:** FLUTTER-005
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** A signed-in person following a link the app does not know gets a clear dead end and a Back that goes home.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Open https://shubhlms.com/courses/BAD_SLUG_x in the app
3. Tap Back

**Expected**

- "This isn't available." screen
- Back returns to the learner home

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
