# FLUTTER-006 Authorization, Permissions & Entitlement States — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## ENT-001 — An academy admin is told the academy has no active plan

- **Module:** FLUTTER-006
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The admin sees the academy-wide restricted banner (the seed academy has no subscription, /tenant/subscription/usage reports restricted) and it leads to Billing.
- **Preconditions:** seed academy without a subscription (GET /tenant/subscription/usage → restricted: true)
- **Test data:** none

**Actions**

1. Check restricted from the API (as admin)
2. Sign in as the admin
3. Read the banner
4. Tap Review plan

**Expected**

- "Your academy has no active plan" banner with "Review plan"
- Review plan opens "Your plan"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## ENT-002 — Instructor and learner do not see the billing banner or Billing

- **Module:** FLUTTER-006
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The banner and Billing are for whoever may view billing — not an instructor, not a learner.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as the instructor; open More
2. Sign in as the learner

**Expected**

- Instructor: no banner, no Billing in More
- Learner: no banner

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## ENT-003 — A learner following a staff link stays in the learner app

- **Module:** FLUTTER-006
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** Another role's screen is not reachable by link (UX guard; the server refuses anyway).
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Sign in as the learner
2. Open https://shubhlms.com/staff/billing in the app

**Expected**

- The learner home, not billing and not a staff shell

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
