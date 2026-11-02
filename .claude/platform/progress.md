# ZuviloAI Platform Conversion — Progress

PLATFORM PHASE STATUS: IN PROGRESS — PLAT-000 (audit and plan) completed 1 Nov 2026; PLAT-001 in build.

The build record of the conversion from a multi-tenant SaaS into one centralized learning platform
(specification: `docs/16-PLATFORM-CONVERSION.md`). The SaaS record is `.claude/saas/progress.md` (history now),
the MLM record `.claude/mlm/progress.md` (continues inside PLAT-005), the Flutter record `.claude/flutter/progress.md`.

## Session Checkpoint

```
Module:            PLAT-008 verification
Completed:         PLAT-000 to PLAT-006 (1 Nov 2026)
Blocked:           PLAT-007 Flutter: no toolchain here. Two navigation edits only, unverified. MLM-010 not built.
Not possible here: rollout rehearsal on a copy of production (no copy on this machine).
Dev servers:       API `npx tsx src/index.ts` with PORT=4010 CORS_ORIGIN=http://localhost:5175 APP_URL=http://localhost:5175 PAYMENT_SANDBOX=on;
                   `tsx watch` leaves its child running when stopped, so it holds the port. KYC needs PAYMENT_CREDENTIALS_KEY in the environment.
                   Vite --port 5175 --strictPort (4000/5173 belong to other apps on this machine). E2E: E2E_API_PORT=4300 E2E_WEB_PORT=4373.
Dev accounts:      drive-owner@example.test, drive-owner-2@example.test, drive-learner-*@example.test: local dev database only.
```

## Completed

### PLAT-000 — Audit and plan (1 Nov 2026)

Three parallel code sweeps (API, web, schema + mobile) produced the inventory in `docs/16` §1; the architecture
(§2), migration plan (§3), module list (§4) and decisions D-PLAT-01…14 (§5) follow from it. Key facts: 81 models,
45 migrations, 28 SaaS-only models none of which an LMS model references; course sales already verified and
idempotent but keyed to a per-academy gateway; a platform gateway with an encrypted vault already exists; every
registration door already confirms an emailed code; the dev database has one tenant. Decision taken: keep tenancy as
an internal invariant (one workspace), additive migrations only, retire SaaS code now and its tables later.

### PLAT-001: Backend core (1 Nov 2026)

**Built.** Every request runs in the one workspace (`lib/requestContext.ts`); accounts of other tenants get `WORKSPACE_CLOSED`.
`superadmin` passes `requireRole` and `requirePermission` and is unscoped (`lib/scope.ts`). Plan gates removed from the LMS routes. Course
sales use the platform gateway (`lib/coursePayments.ts`, webhook `/webhooks/:provider/courses`, old academy path kept as an alias). Gateway
routes moved to `routes/paymentGateways.ts`. `scripts/platform-convert.ts` is dry-run by default. Web: plan machinery, SaaS pages and SaaS
service groups removed; `/superadmin` navigation merged with the workspace.

**Removed code is in `.retired/`, not deleted.** The harness refused a permanent delete, and this checkout has no git history, so the files
were moved there unchanged. Delete the folder only after review.

**Test coverage that left with it and must be replaced.** API: `emailVerification`, `instructorRequests`, `learnerJoin`, `sandboxGateway`,
`educationCatalog` (the last has no replacement yet because its fixture is a second academy). Web: `http/platform`, `mock/platform`,
`sharedStore`. Suite sizes fell: API 82 to about 60 files, web 75 to 57 files. Most of that is the SaaS code itself.

### PLAT-002: Registration (1 Nov 2026)

Migration `platform_workspace`. `POST /public/register` (phone required) and `POST /public/instructor-applications`; web `/register` and `/teach/apply`.
Old `/join`, `/get-started` addresses forward, keeping `?ref=`. `/public/academies/:slug` kept for apps in people's hands, and answers for the workspace only.
Owner and staff are told of applications. `lib/notify.ts` can now reach the owner, who has no tenant. New suite `registration.test.ts`.

### PLAT-004: Course sales (1 Nov 2026)

Migration `course_orders`. Order numbers `ORD-YYYY-NNNNNN`, sale prices, coupons (`lib/coupons.ts`), whole-order refunds (`lib/courseRefunds.ts`) with the affiliate
reversal as a hook, `/superadmin/sales/*`, web Orders, Coupons and Payment events pages, coupon field at checkout. New suite `sales.test.ts`.

**Decisions.** Refunds are whole orders only: the plan names no CV rule for a part refund. A part refund made in the gateway dashboard is flagged for review and changes
nothing. A coupon cannot take an order below Rs 1. A refund expires the enrolment rather than adding a `refunded` status (docs/16 §3.2 said otherwise): every learning
route already refuses `expired`, and buying again reopens it. Chargebacks are not automated yet: reverse by hand until MLM-007.

### PLAT-006: Public website (1 Nov 2026)

Pages: home with the brief's sections, `/courses`, `/courses/:slug`, `/categories`, `/become-an-instructor`, `/affiliate-program`, `/about`, `/faq`, `/contact`, rewritten Terms, Refund and Privacy. Super Admin Website page edits the headline, featured courses, testimonials and questions (`SiteContent`). The affiliate page reads the active plan's terms and carries a no-guarantee disclosure, and a test scans the site's words for income claims. `/features`, `/solutions`, `/how-it-works`, `/pricing` forward. ProductMock and PhoneMock moved to `.retired`. Course pages carry a title, canonical link and Course structured data.

### PLAT-003: Workspaces (1 Nov 2026)

Help leads to the contact form, whose messages reach the Inbox. Instructors get Course sales: enrolments and orders of their own courses, counts only (D-PLAT-10).

### PLAT-008: Verification (1 Nov 2026)

E2E rewritten for the new doors. Results are in the final report of the session; rehearsal on a production copy not possible here.

### Audit and fixes (1 Nov 2026)

Four independent audits (money and security, web, brief coverage, mobile). Fixed: catch-up matching paying extra caps (stored `MlmProgramState` mark; past days see only that day's volume), reversals ignoring holds, clawback above what was received, reversals following the current tree instead of the ledger, lost reversals (repair job), double pay on rejecting an exported withdrawal, late opt-ins never activating, oversized holds blocking the queue (holds can split), per-tick scheduler cost, deploy.sh calling removed scripts. Added: Network, Ranks, member sections, member picker, carry adjustment, audit prefix filter, member orders, link legs, reviews, broadcast, instructor reports, receipts, dynamic sitemap, redirects. Removed fake counts and fake certificate and resource UI. E2E `workspaces.spec.ts` opens every sidebar page.

Open: mobile is not compiled (no toolchain); see `docs/16-PLATFORM-CONVERSION.md` §8 for choices made.

## Known Issues / follow-ups

- Open orders made on an academy's own Razorpay account cannot be settled through the platform gateway unless the same account is entered
  there. Paid orders are unaffected. Check for open orders before rollout.
- The public site's copy is still the SaaS copy apart from the pricing removal: PLAT-006.

- Three API suites fail for reasons outside this track (recorded in `.claude/mlm/progress.md`): `reports.test.ts`
  (31st-of-month boundary), `checkout.test.ts` (needs `git ls-files`), `notificationDelivery.test.ts` (slow drain).
  `checkout.test.ts` is deleted by PLAT-001 with the module it tested.
- Flutter is not installed on this machine; PLAT-007 is code-only until it is.
- The brief says "ShubhLMS"; the product is ZuviloAI since 31 Oct 2026 (D-PLAT-14) — confirm with the owner.
