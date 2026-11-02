# FLUTTER-027 Academy Billing & Provider-Agnostic Checkout — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## BILL-001 — Billing tells the admin the academy has no plan, and lists plans

- **Module:** FLUTTER-027
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** GET /tenant/billing is rendered: the academy's state and the plans on sale (no change is made).
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Admin: More → Billing
2. See the plans

**Expected**

- "Your plan" with the no-plan / ended state
- "Plans" with each plan name from the API

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## BILL-002 — Billing usage and invoices sections

- **Module:** FLUTTER-027
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The usage and invoice sections render from the same response.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Admin: More → Billing
2. Scroll

**Expected**

- "What you’re using", "Invoices" (or "No invoices yet.")

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
