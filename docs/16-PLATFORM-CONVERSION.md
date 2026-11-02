# 16 — Platform conversion: from multi-tenant SaaS to one centralized learning platform

**Status:** built 1 Nov 2026 except Flutter (no toolchain here) and the rollout rehearsal (needs a copy of production). Nothing is deployed.
Progress record: `.claude/platform/progress.md`. The affiliate program keeps its own record (`.claude/mlm/progress.md`)
and specification (`15-MLM-AFFILIATE-ARCHITECTURE.md`); this conversion changes where that program lives, not its rules.

**The brief, in one paragraph.** ZuviloAI stops being software that schools subscribe to and becomes one learning
platform run by the company: students register directly and buy courses, instructors apply and are approved, the
Super Admin controls courses, people, orders, payments and the 2-leg affiliate program. No academy registers, no
academy pays a subscription, no academy configures its own gateway or branding. The brief named the product
"ShubhLMS"; the product was renamed ZuviloAI (zuviloai.com) on 31 Oct 2026 and carries the new logo, so this
conversion keeps the ZuviloAI name and brand throughout (an assumption to correct if the owner wants the old name back).

## Contents

1. Phase 1 — what exists and what depends on the SaaS model
2. Phase 2 — the centralized architecture
3. The migration plan (database, code, data, rollout)
4. Module breakdown PLAT-000 … PLAT-008 (the build order the brief asks for)
5. Decisions and configurable rules (D-PLAT-01 … D-PLAT-14)
6. What is deliberately kept, and what is retired
7. Testing and verification

---

## 1. Phase 1 — what exists and what depends on the SaaS model

The audit covered `apps/api` (routes, lib, schema, migrations, seeds, environment), `apps/web` (routes, navigation,
pages, services, shell, e2e), `apps/mobile` (Flutter) and `packages/domain`. Numbers are from the code on 1 Nov 2026.

### 1.1 The shape of the system today

- **81 Prisma models, 45 migrations, SQLite.** Every academy-owned table carries `tenantId` → `Tenant` (`onDelete:
  Restrict`). `lib/tenancy.ts` lists 50 tenant-owned models, 9 tenant-or-platform models (`User`, sessions,
  notifications, outbox, inquiries, push) and 22 platform models. A Prisma extension confines every query on a
  scoped model to the request's academy, stamps creates, refuses a query with no context, and checks that every
  foreign key points into the same academy. `User.tenantId` is null only for `superadmin`; `User.email` is unique
  across the whole database (decision D2).
- **One tenant in every known database.** The development database holds exactly one tenant (`tenant-1`, slug
  `default`), 45 learners, 2 instructors, 1 admin, 7 courses, 1 course purchase and no subscription. Production
  (zuviloai.com) was opened as a SaaS, so the migration plan assumes other academies *may* exist there and never
  deletes them (§3.3).
- **Roles:** `student`, `instructor`, `admin`, `superadmin` (strings; `packages/domain/src/identity.ts`).
  `requireRole(...)` lets `admin` through every role guard; `requireSuperAdmin` is an exact match with no bypass; the
  24-key permission catalogue (`packages/domain/src/permission.ts`, `AdminPermission` rows) governs the `admin` role
  only. Outside `/superadmin`, a super admin's request runs in the `DEFAULT_TENANT_SLUG` academy.
- **Course sales exist** (24 Oct 2026): `CoursePurchase` (paise, status created/paid/failed/expired, provider order
  and payment ids, one open order per learner and course), `CoursePaymentEvent` (webhook idempotency), enrolment
  opened on the gateway's own confirmation (browser confirm, signed webhook, status check or the `checkout-recovery`
  job), MLM hooks on settlement. The gateway is **per academy** (`AcademyPaymentConfig` / `AcademyGatewayCredential`,
  webhook `/webhooks/academies/:tenantId/razorpay/courses`). Prices are per course in whole rupees, all-inclusive,
  `pricing` free / paid / unset. No coupons, no discounts, no course refunds, no order numbers, no reviews model
  (`rating` / `ratingCount` are display columns).
- **A platform gateway already exists** (`PaymentGatewayConfig` / `PaymentGatewayCredential`, Razorpay adapter,
  AES-256-GCM credential vault, test / activate flow, `/superadmin/payment-gateways`), used today only to sell plans
  to academies. The sandbox gateway (`PAYMENT_SANDBOX=on`, never in production) drives checkout in the browser.
- **Registration doors** all confirm a 6-digit emailed code through `PendingAccount` (learner join by slug, host
  registration, invitation, course link, instructor request) or `PendingSignup` (academy self-registration). The code
  is HMAC-hashed, 15 minutes, 5 attempts. There is no SMS OTP and no phone column on `User` (`Student.phone` and
  `Instructor.phone` exist). MLM `?ref=` / `preferredLeg` ride on `PendingAccount`.
- **The MLM program** (MLM-000 … 003 built) is bound to a *program academy* (`MlmPlanVersion.programTenantId`,
  default the `DEFAULT_TENANT_SLUG` academy); its affiliate and ledger rows are tenant-owned. Nothing in it reads
  subscriptions, plans or invoices.

### 1.2 SaaS-only code (to retire)

**API routers (9) and their mounts** — `signup.ts` (`/signup/*`: academy self-registration), `tenant.ts` (`/tenant/*`:
23 endpoints — subscription, billing, checkout, trial, plan changes, invoices, payments, billing profile, support),
`academyPlan.ts` (`GET /academy/plan`), `courseSales.ts`'s `courseSalesRouter` (`/tenant/course-sales/*`: the
academy's own Razorpay keys and sales list), `billingPlatform.ts` (plans, subscriptions, invoices, payments,
refunds, webhooks receipts, payment gateways, tax rules, billing profiles — all under `/superadmin`),
`billingViews.ts` (`/superadmin/billing-views/*`), `superadminAcademies.ts` (`/superadmin/tenants/*`: provision,
suspend, archive, users, subscription, usage), `publicSite.ts`'s plan and academy routes (`GET /public/plans`,
`GET /public/academies/:slug`, `POST /public/academies/:slug/register`, `POST /public/academies/:slug/instructor-requests`),
`webhooks.ts`'s `POST /webhooks/:provider/subscription`.

**API lib (18 files)** — `academies.ts` (provisioning, lifecycle; also holds the LMS bootstrap data `STARTER_LEVELS`,
`STARTER_RANKS` and the default certificate template, which must survive), `signup.ts`, `subscriptions.ts` (827 lines),
`planChanges.ts`, `plans.ts`, `billing.ts`, `billingConfig.ts`, `billingJobs.ts`, `billingNotices.ts`,
`billingViews.ts`, `invoices.ts`, `payments.ts`, `checkout.ts`, `webhooks.ts` (subscription webhooks and retry),
`entitlements.ts`, `usage.ts`, `academyPayments.ts` (per-academy course gateway), `inquiries.ts`'s academy support
requests (`createAcademySupportRequest`, `listAcademySupportRequests`), `tenantAudit.ts` (`tenants:verify`).

**Plan gates inside LMS routes (about 40 call sites)** — `requireFeature` on courses (4), chapters (4), lessons (4),
quizzes (3), assignments (3), certificates (3), live (2), reports (6), settings appearance (1); `requireUnrestricted`
on categories (3); `withinLimit` on courses (2), media storage (1), live classes (2), instructors (2 + the request
approval), every learner creation path (`lib/learners.ts`), admin accounts (2 in `superadmin.ts`).

**Environment** — `ENTITLEMENT_ENFORCEMENT`, `SUBSCRIPTION_GRACE_DAYS`, `SUBSCRIPTION_RETRY_DAYS`,
`SUBSCRIPTION_INVOICE_LEAD_DAYS`, `SUBSCRIPTION_REPEAT_TRIALS`, `BILLING_JOBS`, `SALES_NOTIFY_EMAIL`,
`DEMO_ACADEMY_*`, `TEST_ACADEMY_PLAN`. (`DEFAULT_TENANT_SLUG` and `TENANT_ENFORCEMENT` stay — §2.1.)

**Scheduler** — `runAcademyBillingJobs` (trial expiry, renewal invoices, period boundary, dunning, grace,
cancellation, pause, usage reconciliation) and the platform webhook retry; `forEachTenant` walks every active tenant.

**Seeds and scripts** — `PLATFORM_PLANS` / `DEMO_PLANS` and the GST tax rule in `platformSeed.ts`, the demo
`BillingProfile`, `seed:demo-academy`, `tenants:verify`, `enforcement:check`, `gateways:import-env` (keep: it imports
the platform gateway), `test-academy-plan.ts`, `prepare-test-db.ts`'s `TEST_ACADEMY_PLAN`.

**Schema (28 SaaS-only models, no LMS model references any of them)** — `Tenant` (kept as the workspace row),
`Plan`, `PlanVersion`, `Feature`, `LimitDefinition`, `PlanFeature`, `PlanLimit`, `UsageGuard`, `TaxRule`,
`TaxRuleComponent`, `BillingProfile`, `Subscription`, `PlanChange`, `SubscriptionEvent`, `InvoiceSequence`, `Invoice`,
`Payment`, `PaymentOrder`, `WebhookEvent`, `PaymentGatewayConfig` (kept: the platform gateway),
`PaymentGatewayCredential` (kept), `Refund`, `PaymentMethod`, `PendingSignup`, `AcademyPaymentConfig`,
`AcademyGatewayCredential`, and the per-academy `Settings.appearanceJson` section. `Invitation` and `PendingAccount`
are LMS doors and stay. 21 migrations carry SaaS triggers (append-only plans, subscription transitions, invoice and
payment immutability, gateway sealing); none of them touches an LMS table.

**Web** — routes `/get-started` (the tenant wizard; `/register` redirects to it), `/join`, `/join/:slug`, `/pricing`,
`/admin/billing`, `/admin/welcome`, `/admin/support`, `/admin/settings/payments` (academy keys), `/admin/settings/appearance`,
`/superadmin/academies[/new|/:tenantId]`, `/superadmin/subscriptions/*` (11 routes), `/superadmin/payment-gateways`
(kept, re-pointed at course sales); pages `pages/signup/*`, `pages/billing/*` (except the sandbox page),
`pages/onboarding/*`, `pages/settings/CoursePaymentsSettings.tsx`, `AppearanceSettingsPage`,
`pages/superadmin/academies/*`, `pages/superadmin/subscriptions/*`, `pages/help/SupportPage.tsx`; plan machinery
`components/plan/*`, `hooks/useAcademyPlan.ts`, `hooks/useTenantBilling.ts`, `lib/planAccess.ts`,
`lib/billingStates.ts`, `lib/billingActions.ts`, `shell/BillingBanner.tsx`, `shell/AcademyStorageMeter.tsx`, the
`PlanGate` / `PlanAction` wrappers in the router and 12 pages, the `module:` plan marks on navigation entries, the
`BILLING_REFUSAL_EVENT` 402 handling in `services/http/client.ts`; service groups `signup` (tenant half),
`subscriptions`, `tenantBilling`, `courseSales` (academy half), `support`, the academy half of `platform`; the SaaS
copy of every marketing page (`siteContent.tsx`, `LandingPage.tsx`, `SitePages.tsx`, `PricingPage.tsx`,
`MarketingChrome.tsx`, `LoginPage.tsx`, `TermsPage.tsx`, `RefundPolicyPage.tsx`, `PrivacyPage.tsx`,
`ProductMock.tsx`); the join link on the Students page; `lmsLabel` in general settings.

**E2E specs that exist only for the SaaS** — `billing`, `onboarding`, `payments`, `signup`, `multiadmin`, `support`,
most of `website`; `invitations` (last test), `learners` (join by slug), `journeys` / `coursePurchase` / `quizzes` /
`student` enter through `/join/default` and need the new door.

**Mobile** — `features/staff_billing/*` (billing, choose plan, plan gate), `shared/entitlements/*` (`GET /academy/plan`,
banners, capability gate), `onboardingRedirect`, `academy_signup_screen.dart` and the "Admin registers academy" choice,
the `workspace` field and join-link entry on registration, `/join/<slug>` deep links, suspended / closed LMS handling.
Flutter is not installed on the build machine; mobile changes are made in code and verified by the host test suite
when a Flutter toolchain is available (§7).

### 1.3 Reusable, kept as is

Every LMS-core module (catalogue, curriculum, lessons and media, people, enrolments, progress, quizzes and quiz
sessions, assignments, certificates, live classes and the live room, calendar, notifications and delivery, reports,
dashboard, help centre, settings except appearance), sessions and account self-service, the audit log, job leases,
the email worker, push, the platform branding (logo and favicon), the platform gateway and credential vault, the
sandbox gateway, the course purchase flow (re-pointed at the platform gateway), invitations and course links, email
verification (`PendingAccount`, `verificationCode.ts`), instructor requests (approve / reject), the MLM modules,
the Flutter learner and staff features, and the whole design system.

---

## 2. Phase 2 — the centralized architecture

### 2.1 One workspace, tenancy kept as an invariant (D-PLAT-01)

The platform runs inside **one workspace**: the `Tenant` row whose slug is `DEFAULT_TENANT_SLUG` (`tenant-1`,
`default`, renamed "ZuviloAI" by the conversion migration). `tenantId` columns, the same-academy triggers and the
Prisma tenancy extension stay exactly as they are. Reasons:

- 59 tables and 21 migrations depend on `tenantId`; rewriting them is the one change that could lose production data
  for no product benefit. Fail-closed scoping becomes defence in depth: a bug can still never read across rows that
  do not belong to the workspace.
- Every existing migration stays valid, so `prisma migrate deploy` on production is additive only.
- `programTenantId` on the MLM plan, `MlmOrder`, `Affiliate` and the CV ledgers keep working unchanged.

What changes in the request layer (`lib/requestContext.ts`):

- Every request runs in the workspace: anonymous visitors, learners, instructors, admins. A signed-in account whose
  `tenantId` is not the workspace is refused with `WORKSPACE_CLOSED` (their rows are preserved; §3.3).
- The super admin runs LMS routes in the workspace too (as today), and the `/superadmin` router keeps the platform
  context for platform tables. `requireRole` and `requirePermission` let `superadmin` through everywhere: the owner
  manages courses, people and settings with the same routes staff use (D-PLAT-03).
- `academyClosed` (suspended / archived academies) goes; the workspace cannot be suspended.
- `workspace` on `POST /auth/register` is accepted and ignored for one release (Flutter compatibility), then dropped.

`TENANT_ENFORCEMENT` keeps its meaning (the scoping switch) and its production refusal of `off`.

### 2.2 Roles (D-PLAT-03)

| Role | Meaning after the conversion | Workspace |
| --- | --- | --- |
| `superadmin` | The platform owner. Every `/superadmin` module plus the whole LMS management surface. | platform context on `/superadmin`, the workspace elsewhere |
| `admin` | A **staff account** the Super Admin creates ("Admin users & permissions"), limited by the existing 24-key catalogue. Lives in the workspace. | the workspace |
| `instructor` | Applies on the website, approved by the Super Admin or a staff admin with `instructors.manage`; manages assigned courses. | the workspace |
| `student` | Registers directly; buys courses; may opt into the affiliate program. | the workspace |

The `AdminPermission` catalogue is unchanged. New platform modules (orders, coupons, affiliates, website content,
platform settings) are Super Admin only in this conversion; a later change can add keys for staff.

### 2.3 What replaces what

| SaaS concept | Centralized platform |
| --- | --- |
| Academy registers (`/get-started`, `PendingSignup`) | **Removed.** Students register at `/register`; instructors apply at `/teach/apply`. |
| Learner joins an academy (`/join/:slug`) | `/register` (one door; `?ref=` and `?leg=` still carried) |
| Instructor request (`/join/:slug/teach`) | `/teach/apply` with profile and professional details → `pending` instructor → approval |
| Academy pays a subscription (plans, entitlements, limits, invoices, dunning) | **Removed.** No feature is gated by a plan; no limit is counted. |
| Academy's own Razorpay (`AcademyPaymentConfig`) | The **platform gateway** (`PaymentGatewayConfig`, already encrypted and tested) sells courses. Webhook `POST /webhooks/razorpay/courses` (old academy path kept as an alias for one release). |
| Academy appearance (`Settings.appearance`) | **Removed.** Platform logo and favicon (`/superadmin/branding`) are the brand. |
| Academy general settings (`academyName`, enrolment policy, access months …) | **Platform settings**, the same `Settings` row, edited by the Super Admin under Platform Settings. `lmsLabel` goes. |
| Super Admin "Admins & LMSs" (tenants) | **Removed.** "Admin users & permissions" stays (staff accounts in the workspace). |
| Academy support requests → Super Admin inbox | Website contact form and learner / instructor support requests → the same inbox ("Support management"). |
| Public plans and pricing page | **Removed** (`/pricing` → `/explore`). Courses carry the prices. |
| SaaS marketing site | Learning-platform site (§2.6). |
| Flutter `workspace` / join links / billing / plan gates | Direct registration; no workspace; no plan UI. |

### 2.4 Course sales on the platform (D-PLAT-07)

Built on the existing `CoursePurchase` flow, which already verifies with the gateway, is idempotent on webhooks and
opens the enrolment exactly once:

- **Gateway:** `lib/academyPayments.ts`'s `saleProvider()` is replaced by the platform gateway (`lib/paymentGateways.ts`
  `activeProvider`, sandbox when none is active outside production). The Super Admin configures Razorpay once at
  Platform Settings → Payments (the existing gateway page).
- **Order ids:** every purchase gets an `orderNumber` `ORD-YYYY-NNNNNN` from a sequence row (same pattern as the
  retired invoice numbers), shown on receipts, lists and exports.
- **Coupons and discounts:** `Coupon` (code, percent or fixed amount in paise, currency, starts / ends, max uses, per
  learner limit, course restriction, status) and `CouponRedemption` (one per purchase, immutable); a course may carry
  a `salePrice` below its list price. `CoursePurchase` records `listAmount`, `discountAmount`, `couponId` and `amount`
  (what was charged, fixed by trigger). CV for the affiliate program is computed on the amount paid (D-MLM-08).
- **Free courses:** unchanged (`pricing: free`, self-enrolment; the database refuses a free self-enrolment into a paid
  course).
- **Refunds:** `CoursePurchaseRefund` (amount ≤ paid, reason, who, provider refund id, status requested / settled /
  failed), executed through the provider's refund API with the Super Admin's confirmation; a settled refund closes
  the enrolment (`refunded`) and runs the MLM reversal hook (`reverseMlmOrder`, reason `refund`). Chargebacks arrive on
  the webhook and follow the same path.
- **Transaction history:** `/superadmin/sales/orders`, `/superadmin/sales/payments` (every gateway event),
  `/superadmin/sales/coupons`; the learner's `/purchases` with receipts.
- **Failures:** unchanged (declined, cancelled, expired orders; the recovery job).

### 2.5 Registration and verification (D-PLAT-06)

- **Student:** name, email, mobile number, password → emailed 6-digit code → account. `User.phone` is added (nullable;
  no uniqueness, so existing rows are untouched) and copied to `Student.phone`. "OTP" is the existing emailed code;
  an SMS channel is a configuration point (`OTP_CHANNEL=email|sms`) that refuses `sms` until an SMS provider exists
  (D-PLAT-09).
- **Instructor:** `/teach/apply` — name, email, phone, password, headline, bio, expertise areas, years of experience,
  links; code verification; a `pending` instructor the Super Admin approves or rejects (existing `instructorRequests`).
- **Affiliate:** `/ref/:code` → `/register?ref=&leg=`; the eligible purchase activates (MLM-003).
- `/join`, `/join/:slug`, `/join/:slug/teach`, `/get-started`, `/signup/*`, `/public/academies/*` are removed; the
  web router answers the old addresses with a redirect to the new door so shared links keep working.

### 2.6 The public website (Phase 8)

Navigation: Home · Explore courses · Categories · Become an instructor · Affiliate program · About · Contact · Sign in ·
Sign up. New public endpoints: `GET /public/courses` (search, category, level, price band, sort, page),
`GET /public/courses/:slug` (curriculum, preview lessons, instructors, outcomes, price and sale price),
`GET /public/categories`, `GET /public/instructors/:id`, `GET /public/site` (home page content the Super Admin edits:
featured courses, testimonials, FAQ — "Website management"). Pages: home (hero, explore CTA, featured courses,
categories, why learn here, how it works, become an instructor, affiliate program, testimonials, benefits, FAQ, final
CTA, footer), explore (search, filters, price, cards with instructors and ratings where present), course detail,
instructor profile, affiliate program (no income claims), become an instructor, about, contact, legal pages rewritten
for a course marketplace. The 1 Nov brand system (ink, paper, orange) stays.

### 2.7 Mobile (Phase 9)

Remove the workspace field, join links, academy sign-up, billing and entitlement features; register with name, email,
phone, password and the code; keep the catalogue, course learning, purchases (checkout flag unchanged — store policy),
staff features; add the affiliate module per `15-MLM-AFFILIATE-ARCHITECTURE.md` §8 when MLM-010 is reached.

---

## 3. The migration plan

### 3.1 Principles

1. **Additive migrations only.** No table or column is dropped in this conversion. Retired tables are documented as
   retired in `03-DATABASE-SPECIFICATION.md` and dropped by a later, separately approved migration after a verified
   backup (`deploy/backup.sh` runs before every migration already).
2. **No destructive seed on production.** `seed:demo` keeps refusing `NODE_ENV=production`; `seed:platform` no longer
   seeds plans or tax rules (Help Centre only); a new `platform:convert` script (§3.3) is idempotent and dry-run first.
3. **Backward-compatible contracts for one release.** `POST /auth/register { workspace }` accepted and ignored;
   `/webhooks/academies/:tenantId/razorpay/courses` answers as an alias of `/webhooks/razorpay/courses` so a webhook
   already registered at Razorpay keeps delivering; old web addresses redirect.
4. **Every step gated.** Typecheck, lint, format, domain / API / web suites, build, browser drive — per module, as the
   MLM track does.

### 3.2 Database migrations (in order)

| Migration | What |
| --- | --- |
| `platform_workspace` | Renames `tenant-1` to "ZuviloAI" where it still says "ShubhLMS"; adds `User.phone`; adds `Instructor.headline`, `expertiseJson`, `experienceYears`, `linksJson` (nullable; the application form); adds `PendingAccount.phone` and `PendingAccount.profileJson`. |
| `course_orders` | `CoursePurchase.orderNumber` (unique, backfilled `ORD-2026-000001…` in creation order), `OrderSequence`; `Course.salePrice`; `CoursePurchase.listAmount`, `discountAmount`, `couponId`; `Coupon`, `CouponRedemption` with append-only triggers; the `terms_fixed` trigger extended to the new columns. |
| `course_refunds` | `CoursePurchaseRefund` (append-only, amount ≤ paid, one settled per purchase unless partial), `Enrollment.status` gains `refunded`. |
| `site_content` | `SiteContent` (singleton JSON document the Super Admin edits: featured course ids, testimonials, FAQ, hero copy) with an audit trail. |
| (later, separate approval) `retire_saas_tables` | Drops the 24 retired tables after backup. Not part of this conversion. |

### 3.3 Data on production

`npm run platform:convert` (dry run by default, `--apply` to write):

1. Verifies exactly one tenant carries `DEFAULT_TENANT_SLUG` and prints it.
2. Lists every other tenant with its counts (users, courses, enrolments, purchases). With `--apply` it sets them
   `archived` with `statusReason = 'platform-conversion'`; their accounts are refused at sign-in with
   `WORKSPACE_CLOSED` and told so. Nothing is deleted or moved.
3. Prints open subscriptions, unpaid invoices and pending plan changes, if any, for the owner's records (they are
   read-only history from here on).
4. Backfills `orderNumber` on existing purchases if the migration did not (it does), and reports gateway state: whether
   a platform gateway is active, and whether the workspace had an `AcademyPaymentConfig` whose credentials should be
   re-entered as the platform gateway (credentials are never copied automatically: they were sealed per academy).

A documented, hand-run `platform:adopt-account <email>` moves one account from an archived academy into the workspace
only if the owner asks for it (email is globally unique, so a move is a `tenantId` update on the user, student and
their enrolment-free rows; rows with course references are not moved).

### 3.4 Code removal and adaptation order (Phase 3 → 4)

1. Request context and guards (§2.1, §2.2); the super admin through LMS routes; `WORKSPACE_CLOSED`.
2. Unmount and delete the SaaS routers and libs (§1.2); remove the ~40 plan gates; delete the billing jobs from the
   scheduler; retire the env variables and boot checks; strip plans / tax from `seed:platform`; delete the SaaS tests
   and the SaaS entries in `routeAudit.test.ts`.
3. Re-point course sales at the platform gateway; new webhook path with the alias.
4. Registration doors (§2.5).
5. Web: remove the plan machinery, SaaS pages, routes and navigation; merge the Super Admin sidebar; adapt the
   Students page, dashboard and settings; remove SaaS service groups and mocks; keep the design system.
6. Docs `00`, `02`, `03`, `04`, `05`, `06`, `07`, `09`, `10`, `11`, `12`, `14`, `README.md` brought in line as each
   module lands.

### 3.5 Rollout

1. Backup. 2. `prisma migrate deploy` (additive). 3. `platform:convert` dry run, then `--apply`. 4. Deploy the build.
5. Enter the Razorpay keys as the platform gateway, test, activate; register the new webhook URL at Razorpay (the
old one keeps working meanwhile). 6. `seed:platform` (Help Centre). 7. Smoke: register a learner, buy a course in test
mode, apply as an instructor, approve, open the affiliate page.

---

## 4. Module breakdown (the brief's phase order)

| Module | Brief phase | Scope | Status |
| --- | --- | --- | --- |
| PLAT-000 | 1–2 | This document; `.claude/platform/progress.md` | **done 1 Nov 2026** |
| PLAT-001 | 3 | Backend core: one workspace, roles, SaaS routers / libs / gates / jobs / env / seeds removed, `platform_workspace` migration, `platform:convert`, docs | **done 1 Nov 2026** |
| PLAT-002 | 4 | Registration and permissions: `/register` with phone and code, `/teach/apply` with the application profile, `?ref=`, redirects from the old doors, Flutter-compatible `auth/register`, staff admin accounts in the workspace | **done 1 Nov 2026** |
| PLAT-003 | 5 | Workspaces: the merged Super Admin panel (18 modules mapped to pages), platform settings, website management, support, instructor and student panels without plan gates, UI pass (cards, forms, states) | **done 1 Nov 2026** |
| PLAT-004 | 6 | Course sales on the platform gateway: gateway, webhook, order numbers, coupons and discounts, refunds with MLM reversal, Super Admin sales pages, learner receipts | **done 1 Nov 2026** |
| PLAT-005 | 7 | Affiliate program continued inside the workspace: MLM-004 … MLM-009 as specified in `15` | **done 1 Nov 2026** (MLM-004 to MLM-008; deviations in §8) |
| PLAT-006 | 8 | Public website and public catalogue endpoints (§2.6) | **done 1 Nov 2026** |
| PLAT-007 | 9 | Flutter (§2.7) | **blocked**: no Flutter toolchain here; navigation edits only, unverified; MLM-010 not built |
| PLAT-008 | 10 | Functional, security and production verification; E2E rewritten for the new doors; the rollout runbook executed on a copy of production | **partly**: see `.claude/platform/progress.md`; rehearsal needs a copy of production |

Each module ends with the gates in §7 and an entry in `.claude/platform/progress.md`.

---

## 5. Decisions and configurable rules

| | Decision | Default / configuration |
| --- | --- | --- |
| D-PLAT-01 | Tenancy stays as an internal invariant; one workspace | `DEFAULT_TENANT_SLUG` names it (`default`) |
| D-PLAT-02 | Other academies' data on production | archived, never deleted or moved automatically (`platform:convert`) |
| D-PLAT-03 | `superadmin` passes every role and permission guard; `admin` = staff with the 24-key catalogue | — |
| D-PLAT-04 | Plans, entitlements, limits, subscriptions, invoices retired from the code; tables kept until a separate drop | — |
| D-PLAT-05 | Platform settings = the workspace `Settings` row; appearance retired | enrolment policy default `open` |
| D-PLAT-06 | One registration door per role; emailed code is the verification | `SIGNUP_EMAIL_VERIFICATION` as today |
| D-PLAT-07 | Course sales through the platform gateway with order numbers, coupons, sale prices, refunds | gateway on `/superadmin/payment-gateways` |
| D-PLAT-08 | Coupon arithmetic in integer paise, half-up, never below zero; a coupon applies before CV is computed | `Coupon` rows |
| D-PLAT-09 | SMS OTP | `OTP_CHANNEL=email` until an SMS provider is configured; `sms` refused at boot without one |
| D-PLAT-10 | Instructor compensation ("earnings where applicable") | **not specified** — no revenue share is invented; the instructor panel shows enrolments and sales of their courses, not money owed; a payout policy setting is reserved for later |
| D-PLAT-11 | Reviews and ratings | `CourseReview`, one per learner and course. `Course.rating` and `ratingCount` follow the published reviews; a course with no review keeps the value it holds, and its first review replaces it. `courses.showRatings` and `minRatings` still decide what the public sees |
| D-PLAT-12 | Refund policy | manual, Super Admin only, through the provider; the public refund page states the policy the owner sets in Platform Settings |
| D-PLAT-13 | Website content | `SiteContent` edited by the Super Admin; no guaranteed-income claims on the affiliate page (checked by test) |
| D-PLAT-14 | Brand | ZuviloAI, the 31 Oct logo and the 1 Nov website brand system |

---

## 6. Kept and retired, in one table

| Kept (unchanged) | Kept (adapted) | Retired from the code (tables kept) |
| --- | --- | --- |
| Tenancy extension, triggers, every LMS model and route, sessions, audit, outbox, push, job leases, media security, help centre, platform branding, the sandbox gateway, the gateway vault, invitations, course links, email verification, instructor requests, MLM modules, design system, mobile learner / staff features | request context, role guards, course purchases (platform gateway), settings (platform), Students page (no join link), dashboard (no plan), Super Admin navigation (merged), auth/register, pending accounts (phone, profile), publicSite (catalogue), inquiries (support only), scheduler (no billing), seeds (no plans) | signup, tenant, academyPlan, courseSales (academy half), billingPlatform, billingViews, superadminAcademies, subscription webhooks; academies (provisioning), subscriptions, planChanges, plans, billing*, invoices, payments, checkout, webhooks (subscription), entitlements, usage, academyPayments, tenantAudit; the web plan machinery and SaaS pages; the mobile billing and entitlement features |

---

## 7. Testing and verification

Per module: `npm run typecheck`, `npm run lint`, `npx prettier --check`, `packages/domain` tests, the full API suite,
the full web suite, `npm run build`, and a browser drive against the real API with the sandbox gateway. PLAT-008
rewrites the E2E specs for the new doors (register, apply, approve, buy, refund, affiliate), re-runs
`routeAudit.test.ts` (every mounted route: authentication, role refusals, malformed queries), the `09-SECURITY.md`
checklist against the running server, and rehearses §3.5 on a copy of the production database. Flutter host tests run
when a toolchain is present; until then the mobile changes are reviewed against the API contract fixtures.

---

## 8. What was built differently from this plan

- **Refunds.** A refund expires the enrolment rather than adding a `refunded` status, because every learning route already refuses `expired` and buying again reopens it. The purchase keeps `status: 'paid'` with `refundedAt`. Refund rows and their amounts sit in `CoursePurchaseRefund` inside the `course_orders` migration, so there is no separate `course_refunds` migration.
- **Columns.** `listAmount` was dropped: `listPrice`, `discountAmount` and `amount` already give the figures. `couponId` is a plain string, so the tenancy check can run inside the settlement transaction.
- **Instructor profile.** `Instructor.headline`, `expertiseJson` and `experienceYears` were not added: the application's profile is kept on `PendingAccount.profileJson` and copied to the existing fields on approval.
- **Commissions.** "Immutable" means the money: amount, kind and member never change, and a row is never deleted (triggers). A held commission can move once, to the wallet or to written off, because a hold has to end somehow. Earning rows are split when a payment only partly fits under the ceiling.
- **Plain ids.** `MlmReward.rankHistoryId` and `MlmWithdrawal.payoutBatchId` are unique or plain ids without a foreign key, because the tenancy check reads committed rows and these are written in one transaction.
- **Not built from `15`.** The `manual` commission approval mode and `clawbackPolicy = none` have no plan term yet; automatic approval and wallet clawback are the only behaviour. A hand hold on an already-paid commission does not exist, since paid money reverses through a sale's reversal or a wallet correction. Certificate rewards are a recognition record and issue no certificate template (D-MLM-14's option).
- **Testimonials.** The section stays hidden until the Super Admin adds a real quote. None are invented.
- **Support.** The signed-in help page leads to the contact form with the support topic, and messages land in the Super Admin's inbox with replies by email. There is no in-app ticket thread.
- **`SALES_NOTIFY_EMAIL`** stays: it emails contact-form messages to the team as they arrive, which the inbox alone does not do. §1.2 listed it as retired.
- **`/public/academies/*`** stays until a new mobile release no longer uses it. It answers for the workspace slug only.
- **`carryForwardPolicy = expire-days`** cannot be chosen: nothing in the engine ages pools, so offering it would be a setting that does nothing.
- **Moves.** A position that verified sales already count through cannot be moved, because the CV stays on the ancestors who received it. This replaces D-MLM-19's compensating rows.
- **Clawback** uses the member's effective rate (income over matched volume) rather than §6.8's plain rate, takes holds first, and never exceeds what they received.
