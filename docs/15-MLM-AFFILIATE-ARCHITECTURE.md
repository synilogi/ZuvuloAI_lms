# 15 — 2-Leg MLM Affiliate Program: architecture and gap analysis

**Status:** approved with the §12 defaults on 31 Oct 2026. MLM-000 to MLM-008 built by 1 Nov 2026, MLM-010 (Flutter) not built. Deviations: `16-PLATFORM-CONVERSION.md` §8. Progress: `.claude/mlm/progress.md`. Where this file says "academy", read "the workspace" (docs/16).

**Business specification:** *AI Course 2-Leg MLM Plan — Corrected 50:50 Balance Edition* (9 pages), kept at
[`docs/specs/AI-Course-2-Leg-MLM-Plan-50-50-Corrected.pdf`](specs/AI-Course-2-Leg-MLM-Plan-50-50-Corrected.pdf).
Its figures are reproduced in §6 so this file stands alone. Where the PDF is silent, the rule is a **configurable
setting with a stated default**, listed in §12, never an invented constant.

**Brief:** integrate a platform-level binary (A/Left, B/Right) affiliate program into ZuviloAI without breaking the
LMS or the SaaS subscription layer: registration by referral, binary genealogy with spillover, verified-sale CV,
10% matching on the weaker leg with rank-based daily caps and carry-forward, 18 ranks with exact 50:50 balance,
wallet, KYC, withdrawals and payouts, a 25% company payout ceiling, Super Admin management, an affiliate
workspace on web and in the Flutter app.

---

## Contents

1. [Existing functionality mapping](#1-existing-functionality-mapping)
2. [Scope, tenancy and placement in the product](#2-scope-tenancy-and-placement-in-the-product)
3. [Module architecture](#3-module-architecture)
4. [Database schema changes](#4-database-schema-changes)
5. [API endpoint specification](#5-api-endpoint-specification)
6. [Business logic and calculation rules](#6-business-logic-and-calculation-rules)
7. [Frontend pages and components](#7-frontend-pages-and-components)
8. [Mobile implementation plan](#8-mobile-implementation-plan)
9. [Background jobs, audit and observability](#9-background-jobs-audit-and-observability)
10. [Testing plan](#10-testing-plan)
11. [Implementation sequence](#11-implementation-sequence)
12. [Open decisions and configurable rules](#12-open-decisions-and-configurable-rules)
13. [Risks and compliance notes](#13-risks-and-compliance-notes)

---

## 1. Existing functionality mapping

What the brief needs, what the codebase already has, and the gap. "Reuse" means the new module calls the
existing code unchanged; "extend" means an additive change to it; "new" means nothing exists.

| Requirement | Exists today | Where | Gap |
| --- | --- | --- | --- |
| Verified course purchase, enrolment on gateway confirmation | ✅ Course sales (24 Oct 2026): server-priced order, confirm/webhook/status/recovery, `settle` opens the enrolment once in a transaction | `apps/api/src/lib/coursePurchases.ts`, `academyPayments.ts`, `routes/courseSales.ts`, `CoursePurchase`, `CoursePaymentEvent` | **Extend:** `settle` emits an in-transaction hook the affiliate module subscribes to (`course_purchase.paid` → `MlmOrder`). No change to pricing, gateway or enrolment logic |
| Payment reaches the company's account | ✅ The program academy's own Razorpay (course sales settle to the academy's gateway, never the platform's) | `AcademyPaymentConfig`, `AcademyGatewayCredential` | None. The program academy *is* the company's LMS (`DEFAULT_TENANT_SLUG`, "the platform's own LMS" in `14-LAUNCH-CHECKLIST.md`), so its gateway is the company's |
| Refund / chargeback reversal | 🟨 A payment already `refunded` at the provider never settles; a refund after settlement is manual and does not revoke access (`14` A18) | `coursePurchases.ts` › `settle` | **New:** a `refund.processed` / chargeback event for a course payment → `MlmOrder` reversed → negative CV and commission rows (§6.8). Needs the academy webhook to handle refund events (it handles payment events only today) |
| Webhook idempotency | ✅ `CoursePaymentEvent` unique per (academy, provider, event id); `WebhookEvent` for platform gateways | `routes/webhooks.ts`, `lib/coursePurchases.ts` | Reuse. Reversal events ride the same table |
| Referral-based registration with OTP | ✅ Every registration door confirms a 6-digit emailed code (`PendingAccount`); join links `/join/:slug`; invitations | `lib/pendingAccounts.ts`, `lib/learners.ts`, `lib/verificationCode.ts`, `routes/publicSite.ts` | **Extend:** a `?ref=<code>` referral parameter carried through the pending row and applied at account creation; `preferredLeg` on the row. "OTP" is the existing email code; SMS OTP does not exist (§12 D-MLM-09) |
| Unique affiliate id, sponsor, placement, A/B selection | ❌ | — | **New** (`Affiliate`, `MlmPlacementHistory`, `lib/mlm/placement.ts`) |
| Binary genealogy, unlimited depth, spillover, manual placement, tree | ❌ | — | **New.** Adjacency (parent + leg) with a materialised ancestor path for O(1) ancestor reads (§4.2) |
| CV, matching, carry-forward, caps, commissions | ❌ | — | **New** (`lib/mlm/cv.ts`, `matching.ts`; domain math in `packages/domain/src/mlm/`) |
| Ranks and rewards | 🟨 Learner *ranks* exist (`Rank` ladder, `/learning/rank-ladder`) but are a learning-progress gamification, unrelated | `Rank`, `Student.rankId` | **New**, separate tables (`MlmRankTier`, `MlmRankHistory`, `MlmReward`). The learner rank ladder is untouched; wording in UI distinguishes "affiliate rank" |
| Wallet, immutable financial ledgers | 🟨 Pattern exists: append-only `Payment`, `Refund`, `SubscriptionEvent`, `CoursePurchase` sealed by SQLite triggers; integer paise everywhere | `packages/domain/src/money.ts`, migrations with `CREATE TRIGGER … RAISE(ABORT)` | **New** tables, same pattern (§4.5) |
| KYC and bank verification | ❌ (billing profiles are addresses only) | `BillingProfile` | **New** (`MlmKyc`); sensitive fields encrypted with the existing vault | 
| Encrypted secrets at rest | ✅ AES-256-GCM under `PAYMENT_CREDENTIALS_KEY` | `lib/credentialVault.ts` | Reuse for PAN and bank account numbers |
| Withdrawals, approval workflow, payout references | ❌ | — | **New** (`MlmWithdrawal`, `MlmPayoutBatch`). Payout execution is a human action with a reference (bank/UPI); no payout API integration in scope (§12 D-MLM-11) |
| 25% payout ceiling | ❌ | — | **New** (`lib/mlm/ceiling.ts`, `MlmLiabilityPeriod`) |
| Plan settings, versioned, no hard-coding | ✅ Pattern: `Plan` + append-only `PlanVersion` with sealed grants; a lint rule forbids plan-name checks | `lib/plans.ts`, `eslint.config.js` | **New** `MlmPlanVersion` + `MlmRankTier` on the same pattern; commissions record the version they were computed under |
| Super Admin section, nav, pages | ✅ Platform workspace, `requireSuperAdmin` router, `platformContext`, nav groups, list/detail page patterns, read models (`billingViews`) | `routes/superadmin.ts`, `shell/navigation.tsx`, `pages/superadmin/*` | **Extend:** one nav group "Affiliates" with the pages in §7.1; a `superadminMlmRouter` mounted at `/superadmin/affiliates` |
| Permission checks | ✅ Role guards, 24-key academy catalogue, Super Admin is a role not a key | `lib/permissions.ts`, `packages/domain/src/permission.ts` | **Extend:** affiliate routes are learner-own-records (`requireAuth` + ownership), platform routes `requireSuperAdmin`. No new academy permission keys needed in v1 (academy admins do not manage the program; §12 D-MLM-03) |
| Tenant isolation | ✅ Prisma extension scopes tenant-owned models; platform models listed in `TENANT_OWNED_MODELS`/`PLATFORM_MODELS`; `tenants:verify` deploy gate; classification test (47 tables) | `lib/tenancy.ts`, `tenancy.test.ts` | **Extend:** classify every new table (§4.1); extend `verify-tenancy.ts` |
| Transactions for financial and placement writes | ✅ `db.$transaction` with row locks (`UsageGuard`, enrolment-row lock in quiz sessions) | `lib/usage.ts`, `lib/quizSessions.ts` | Reuse the pattern: a per-affiliate `MlmLegBalance` row is the lock for placement under a node and for its matching run |
| Background jobs, leases, idempotency | ✅ Every-minute scheduler, `JobLease`, `watchJob`, per-tenant iteration | `lib/scheduler.ts`, `lib/jobLease.ts` | **Extend:** `mlm-cv-eligibility`, `mlm-matching`, `mlm-ranks`, `mlm-reward-vesting`, `mlm-ceiling`, `mlm-reversal-sweep` |
| Audit logs | ✅ Immutable `AuditLog` with `user`/`system`/`provider` actors, filtered Super Admin page | `lib/audit.ts`, `/superadmin/audit` | **Extend:** `mlm.*` actions; "MLM Audit Logs" is the existing page filtered on the `mlm.` prefix |
| Observability | ✅ Redacted signals, Super Admin window | `lib/observe.ts` | **Extend:** `mlm.commission.failed`, `mlm.ceiling.hold`, `mlm.reversal`, `mlm.placement.manual` |
| Email / push notifications | ✅ `notify()` with channels, outbox, SMTP, FCM hints | `lib/notify.ts` | Reuse for activation, commission credited, rank achieved, withdrawal status. New notification categories |
| QR code | ❌ | — | **New dependency:** `qrcode` (web, generates SVG client-side) and `qr_flutter` (mobile). Or a server-side SVG endpoint with no dependency (§12 D-MLM-12) |
| Flutter app | ✅ Feature-module architecture, Riverpod, go_router, Dio, freezed DTOs, architecture tests, l10n (3,225 strings) | `apps/mobile/lib/features/*` | **New** feature `affiliate/` (§8). Course checkout is off in the app on `zuviloai.com`, so activation purchase hands off to the web (§12 D-MLM-13) |
| Learner workspace | ✅ Learner nav, `/purchases`, `/certificates` pages | `shell/navigation.tsx` › `student` | **Extend:** an "Affiliate" nav item visible only to users who are affiliates (or whose academy runs the program) |
| Reports and finance exports | 🟨 Billing views compute figures server-side; CSV export does not exist anywhere | `lib/billingViews.ts` | **New** read models under `lib/mlm/views.ts`; CSV export endpoints for network, ledgers, payouts |

**Nothing in the brief conflicts with existing functionality.** Academy subscription billing (plans, invoices,
the platform gateway) and affiliate compensation are different tables, different gateways and different
services; the only shared seam is the `CoursePurchase` settlement hook.

---

## 2. Scope, tenancy and placement in the product

**One program, one academy.** The affiliate program is a platform feature managed by the Super Admin, and its
affiliates are learners of **one academy**: the *program academy*, a setting on the plan (`programTenantId`,
default the `DEFAULT_TENANT_SLUG` academy, the company's own LMS). The AI course is an ordinary priced course in
that academy, named in the plan's `eligibleCourseIds`. That gives, without changing a line of tenancy code:

- affiliates are `User`/`Student` rows of the program academy, created by the existing registration doors;
- the eligible purchase is an existing course sale, paid into the program academy's own Razorpay account
  (the company's), through code that is already verified and idempotent;
- every affiliate ledger row carries the program academy's `tenantId` and is scoped by the Prisma extension
  like any academy-owned row, so a learner of another academy can never read or be placed in the network;
- the Super Admin reads across in platform context, as for every other platform surface.

Other academies are unaffected: they see no affiliate UI, and their course sales never create CV. A later
"program per academy" (each Admin running their own MLM on their own courses) would need only
`programTenantId` to become per-row, which is why it is a column from the start. It is **out of scope** for v1
(§12 D-MLM-02).

**What stays separate.** SaaS plan billing (`Subscription`, `Invoice`, `Payment`, platform gateways) is never
read or written by the affiliate module. The learner rank ladder (`Rank`) is unrelated to affiliate ranks.

**Who does what.**

| Role | In the program |
| --- | --- |
| Super Admin | Owns the plan (versions, ranks, caps, ceiling), approves rewards and withdrawals, verifies KYC, places manually, reverses, exports, reads every ledger |
| Affiliate (a learner of the program academy who activated) | Shares a referral link, sees their tree and figures, requests withdrawals, submits KYC |
| Academy admin of the program academy | No affiliate management in v1 (D-MLM-03); they run the course as today |
| Admins of other academies | Nothing changes |

---

## 3. Module architecture

Following the repo's layout: thin routers, services that are the only writers of their tables, pure rules in
the domain package, the web client behind the service seam, and one Flutter feature module.

```
packages/domain/src/mlm/
  plan.ts          MlmPlanTerms, MlmRankTier, cap bands; validation of a plan version (18 ranks ascending, 50:50 legs sum, bands cover ranks)
  codes.ts         affiliate code format and check digit; referral slug rules
  genealogy.ts     pure placement rules: spillover position search order, cycle/duplicate checks on a path, depth
  cv.ts            CV from a sale (basis points of net amount), eligibility window, reversal arithmetic
  matching.ts      matchedCv(availableA, availableB), income(matchedCv, rateBps), applyCap(income, band), carryForward(policy, …)
  ranks.ts         qualifiedTier(groupCvA, groupCvB, tiers): exact 50:50 — each leg ≥ tier.legCv; next-rank progress
  ceiling.ts       period liability, headroom, FIFO release of held commissions
  wallet.ts        balance arithmetic from entries; withdrawal eligibility (min amount, KYC, holds)
  index.ts         re-exported from packages/domain/src/index.ts

apps/api/src/lib/mlm/
  plan.ts          MlmPlanVersion + MlmRankTier: create draft, validate, activate (one active), read active terms (cached per request)
  registration.ts  referral resolution (`?ref=`), affiliate row at account creation (pending), activation on the eligible purchase
  placement.ts     spillover search, manual placement, cycle checks, path maintenance, placement history (transaction + parent row lock)
  tree.ts          tree reads: subtree page, ancestors, direct referrals, counts, CSV export
  cv.ts            MlmOrder from a settled purchase; eligibility job; credit every ancestor's leg (CvLedger + LegBalance); reversal
  matching.ts      the daily run per affiliate: idempotent MatchingRun, Commission rows, carry, cap, ceiling hold
  ranks.ts         rank evaluation after every CV change (or daily), RankHistory, Reward creation
  rewards.ts       approve / fund / vest / pay / reject a reward
  wallet.ts        WalletEntry writes (only writer), balances, reversals, clawback
  kyc.ts           submit, verify, reject; encryption of PAN / account number via credentialVault
  withdrawals.ts   request, approve, reject, mark paid with reference, payout batches, CSV
  ceiling.ts       per-period liability, holds and releases
  views.ts         read models for dashboards and reports (Super Admin and affiliate)
  audit.ts         MLM_AUDIT_ACTIONS and helpers; every write names its actor (user | system job | provider)

apps/api/src/routes/
  affiliate.ts            /affiliate/*          the signed-in affiliate's own records (requireAuth, ownership)
  superadminMlm.ts        /superadmin/affiliates/*   mounted inside superadminRouter (requireSuperAdmin, platformContext)
  publicSite.ts (extend)  /public/affiliates/ref/:code  resolve a referral code for the join page; QR SVG

apps/web/src/
  services/contracts.ts   AffiliateService (own), PlatformAffiliateService (Super Admin): two new groups (34 → 36)
  services/http/affiliate.ts, platformAffiliates.ts; services/mock/… with fixtures
  pages/affiliate/*       the affiliate workspace (§7.2)
  pages/superadmin/affiliates/*  the management section (§7.1)
  components/mlm/*        BinaryTree (SVG, virtualised by depth), LegMeter, RankProgress, LedgerTable, CodeBadge, QrCode

apps/mobile/lib/features/affiliate/   data/ (DTOs, api) · application/ (controllers) · presentation/ (screens, widgets)
```

**Writers.** `lib/mlm/wallet.ts` is the only writer of `MlmWalletEntry`; `cv.ts` of `MlmCvLedger` and
`MlmLegBalance`; `matching.ts` of `MlmMatchingRun` and matching `MlmCommission` rows; `placement.ts` of
`Affiliate.placement*` and `MlmPlacementHistory`. Routes never touch Prisma directly.

**The one seam into existing code.** `coursePurchases.ts › settle` already emits `observe('course_purchase.paid')`
after its transaction. The affiliate module needs the order **inside** the same transaction so a paid purchase
and its `MlmOrder` cannot disagree. Change: `settle` accepts an optional `onPaid(tx, purchase)` hook registered
at boot by `lib/mlm/cv.ts` (a one-line registration, no import of MLM code into course sales). When the
purchase's course is not in `eligibleCourseIds`, or the academy is not the program academy, the hook returns
without writing. Everything else about course sales is untouched.

---

## 4. Database schema changes

All money and CV are **integer paise** (`packages/domain/src/money.ts`). Ids are `cuid()`. JSON columns are
`*Json` text. One migration per implementation module (§11), additive only; nothing existing is altered except
one nullable column on `PendingAccount` (`referralCode`) and `preferredLeg`.

### 4.1 Tenancy classification

| Classification | Tables |
| --- | --- |
| **Platform** (no `tenantId`; added to `PLATFORM_MODELS`) | `MlmPlanVersion`, `MlmRankTier`, `MlmCapBand`, `MlmLiabilityPeriod` |
| **Tenant-owned** (`tenantId` = the program academy, stamped and scoped by the extension; added to `TENANT_OWNED_MODELS` and the `Tenant` relation list) | `Affiliate`, `MlmPlacementHistory`, `MlmOrder`, `MlmCvLedger`, `MlmLegBalance`, `MlmMatchingRun`, `MlmCommission`, `MlmRankHistory`, `MlmReward`, `MlmWalletEntry`, `MlmWallet`, `MlmKyc`, `MlmWithdrawal`, `MlmPayoutBatch` |

`scripts/verify-tenancy.ts` and `tenancy.test.ts`'s classification count both grow by these tables.

### 4.2 Plan and configuration (platform)

| Model | Purpose | Key fields |
| --- | --- | --- |
| `MlmPlanVersion` | Append-only terms. One `active` at a time; a change is a new version. Every commission, run and rank record names the version it was computed under | `version` (1, 2, …, unique), `status` (`draft`/`active`/`retired`), `programTenantId`, `eligibleCourseIdsJson`, `currency`, `cvBasisPoints` (CV as bps of the net sale amount; default 10000), `matchingRateBps` (1000), `payoutCeilingBps` (2500), `normalPayoutBps` (1500, reporting only), `matchingCycle` (`daily`), `matchingRunHourIst`, `cvEligibilityDelayDays` (0), `capOverflowPolicy` (`flush`/`carry`), `carryForwardPolicy` (`indefinite`/`expire-days`), `carryExpiryDays?`, `spilloverRule` (`extreme-outer`/`breadth-first`), `rankDemotion` (`never`), `rewardApproval` (`manual`), `withdrawalMinAmount`, `withdrawalRequiresKyc` (true), `tdsBps` (0), `liabilityPeriod` (`month`), `activatedAt?`, `activatedBy?`, `createdAt`, `noteJson` |
| `MlmRankTier` | The 18 ranks of a version; sealed once the version is active (trigger) | `planVersionId`, `order` (1–18), `name`, `groupCv`, `legCv` (= groupCv / 2), `rewardKind` (`recognition`/`certificate`/`cash`), `rewardAmount` (paise, 0 for non-cash), `rewardCapAmount?` (for "up to"), `capBandKey`, `vestingDays`, `fundedRule?` |
| `MlmCapBand` | Daily matching caps per band of a version | `planVersionId`, `key`, `label`, `dailyCap` (paise), `order` |
| `MlmLiabilityPeriod` | The company ceiling per period | `planVersionId`, `periodKey` (`2026-11`), `grossEligibleSales`, `fieldPayoutAccrued`, `ceilingAmount`, `heldAmount`, `releasedAmount`, `closedAt?` |

### 4.3 Affiliates and genealogy (tenant-owned)

| Model | Purpose | Key fields |
| --- | --- | --- |
| `Affiliate` | One per user; the node of the binary tree | `userId` (unique), `studentId`, `code` (unique, human-readable, check-digited, e.g. `SL7K3M9Q`), `status` (`pending`/`active`/`suspended`/`terminated`), `sponsorId?` (→ `Affiliate`), `placementParentId?` (→ `Affiliate`), `placementLeg?` (`A`/`B`), `pathIds` (materialised ancestor id list, root → parent; JSON text), `depth`, `preferredLeg` (`A`/`B`, where the affiliate's own referrals go), `activatedAt?`, `activationOrderId?`, `kycStatus` (denormalised), `currentRankOrder` (0 = none), `createdAt` |
| `MlmPlacementHistory` | Append-only record of every placement and move | `affiliateId`, `fromParentId?`, `fromLeg?`, `toParentId`, `toLeg`, `reason` (`spillover`/`sponsor-direct`/`manual`), `actorType`, `actorId?`, `note?`, `createdAt` |

Constraints: `@@unique([placementParentId, placementLeg])` (two positions per node, enforced by the database,
not just the code); a trigger refuses `placementParentId = id`; `pathIds` must not contain the affiliate's own id
(checked in the service and by a test that walks the whole tree). The materialised path makes "credit every
ancestor" and "is X in Y's downline" a single read; it is rebuilt for a subtree on a manual move.

### 4.4 Sales, CV, matching, ranks (tenant-owned)

| Model | Purpose | Key fields |
| --- | --- | --- |
| `MlmOrder` | A verified sale that generates CV | `purchaseId` (→ `CoursePurchase`, unique), `buyerAffiliateId?`, `sponsorAffiliateIdAtSale?`, `planVersionId`, `netAmount`, `cv`, `status` (`pending`/`eligible`/`reversed`), `eligibleAt?`, `reversedAt?`, `reversalReason?` (`refund`/`chargeback`/`manual`), `createdAt` |
| `MlmCvLedger` | **Immutable.** One row per (order, ancestor): the CV credited to that ancestor's A or B leg; a reversal is a negative row | `affiliateId` (the ancestor credited), `leg`, `orderId`, `kind` (`sale`/`reversal`), `amount` (signed), `createdAt`; `@@unique([orderId, affiliateId, kind])` |
| `MlmLegBalance` | Materialised per affiliate; the lock row for its matching run and for placing under it; rebuildable from the ledger | `affiliateId` (unique), `lifetimeA`, `lifetimeB` (eligible CV ever, for ranks), `unmatchedA`, `unmatchedB` (carry-forward pools), `matchedLifetime`, `lastMatchingRunDate?`, `version` (optimistic counter) |
| `MlmMatchingRun` | **Idempotent per (affiliate, day).** What one run saw and paid | `affiliateId`, `runDate` (`YYYY-MM-DD` IST), `planVersionId`, `rankOrderAtRun`, `capBandKey`, `availableA`, `availableB`, `matchedCv`, `grossIncome`, `dailyCap`, `cappedIncome`, `flushedCv`, `carryAAfter`, `carryBAfter`, `heldByCeiling`, `status` (`paid`/`held`/`zero`), `createdAt`; `@@unique([affiliateId, runDate])` |
| `MlmCommission` | **Immutable.** Every earning or reversal | `affiliateId`, `kind` (`matching`/`rank_reward`/`reversal`/`adjustment`), `amount` (signed), `status` (`pending`/`approved`/`held`/`paid_to_wallet`/`reversed`), `runId?`, `rewardId?`, `orderId?`, `planVersionId`, `holdReason?` (`ceiling`), `createdAt`, `settledAt?` |
| `MlmRankHistory` | Append-only | `affiliateId`, `tierOrder`, `tierName`, `achievedAt`, `lifetimeA`, `lifetimeB`, `planVersionId` |
| `MlmReward` | A milestone reward from a rank | `affiliateId`, `rankHistoryId` (unique), `tierOrder`, `kind`, `amount`, `status` (`qualified`/`approved`/`vesting`/`funded`/`paid`/`rejected`), `vestsAt?`, `approvedBy?`, `approvedAt?`, `fundedAt?`, `paidCommissionId?`, `note?` |

### 4.5 Wallet, KYC, withdrawals (tenant-owned)

| Model | Purpose | Key fields |
| --- | --- | --- |
| `MlmWalletEntry` | **Immutable ledger**, the source of truth for every balance | `affiliateId`, `type` (`matching_credit`/`reward_credit`/`reversal_debit`/`withdrawal_hold`/`withdrawal_paid`/`withdrawal_released`/`tds_debit`/`adjustment`), `amount` (signed), `commissionId?`, `withdrawalId?`, `actorType`, `actorId?`, `createdAt` |
| `MlmWallet` | Materialised balances (rebuildable) | `affiliateId` (unique), `pending` (commissions not yet settled), `available`, `held` (withdrawals in flight), `paid`, `reversed`, `version` |
| `MlmKyc` | One per affiliate | `affiliateId` (unique), `legalName`, `panEncrypted`, `panLast4`, `bankAccountEncrypted`, `bankAccountLast4`, `ifsc`, `accountHolder`, `upiId?`, `documentIdsJson` (→ `MediaAsset`, uploaded by the affiliate), `status` (`none`/`submitted`/`verified`/`rejected`), `submittedAt?`, `reviewedBy?`, `reviewedAt?`, `rejectReason?` |
| `MlmWithdrawal` | A request against the available balance | `affiliateId`, `amount`, `tdsAmount`, `netAmount`, `status` (`requested`/`approved`/`processing`/`paid`/`rejected`/`cancelled`), `bankSnapshotJson` (masked), `payoutBatchId?`, `payoutReference?`, `requestedAt`, `decidedBy?`, `decidedAt?`, `paidAt?`, `reason?` |
| `MlmPayoutBatch` | Groups approved withdrawals for one bank run | `reference`, `createdBy`, `createdAt`, `count`, `total`, `exportedAt?`, `closedAt?` |

**Triggers** (same SQLite style as `CoursePurchase_terms_fixed`): `MlmCvLedger`, `MlmCommission`,
`MlmWalletEntry`, `MlmPlacementHistory`, `MlmRankHistory` refuse `UPDATE` and `DELETE`; `MlmRankTier` and
`MlmCapBand` refuse changes once their version is active; `MlmWithdrawal` refuses leaving `paid`; `MlmOrder`
refuses leaving `reversed`.

### 4.6 Changes to existing tables

| Table | Change |
| --- | --- |
| `PendingAccount` | `referralCode?`, `preferredLeg?` — carried from the join link to account creation |
| `Student` | relation `affiliate Affiliate?` |
| `Tenant` | relation rows for the new tenant-owned tables |
| `AuditLog` | none; new `mlm.*` action strings |
| `CoursePurchase` | none; the `settle` hook reads it |

---

## 5. API endpoint specification

Conventions as in `05-API-SPECIFICATION.md`: Zod on every body and query, `{ message, issues?, code? }`
errors, stable codes. New codes: `AFFILIATE_NOT_ACTIVE`, `REFERRAL_INVALID`, `PLACEMENT_INVALID`,
`PLACEMENT_CYCLE`, `POSITION_TAKEN`, `KYC_REQUIRED`, `INSUFFICIENT_BALANCE`, `PLAN_NOT_ACTIVE`,
`CEILING_HOLD`.

### 5.1 Public (🔓, on the sign-up rate limit)

| Method & path | Purpose |
| --- | --- |
| `GET /public/affiliates/ref/:code` | Resolve a referral code → `{ sponsor: { name, code }, academy: { name, slug }, course: { id, title, price } }` or 404 `REFERRAL_INVALID`. Used by `/ref/:code` and the join page |
| `GET /public/affiliates/ref/:code/qr.svg` | The referral link as an SVG QR (server-side, no dependency) — see D-MLM-12 |
| existing `POST /public/academies/:slug/register` | **Extended:** accepts `referralCode?` and `preferredLeg?`; stored on the `PendingAccount`; the `Affiliate` row (status `pending`) is created with the account when the code is confirmed |
| existing `POST /auth/register` | **Extended** the same way, for the app |

### 5.2 Affiliate (🔐, the signed-in affiliate's own records; `AFFILIATE_NOT_ACTIVE` where activation is required)

| Method & path | Body | Returns |
| --- | --- | --- |
| `GET /affiliate` | — | `AffiliateMe`: code, status, sponsor (name, code), placement (parent code, leg), preferred leg, activation order, rank, KYC status, referral link, join link |
| `POST /affiliate/enrol` | `{ referralCode?, preferredLeg? }` | Opts an existing learner of the program academy in as a `pending` affiliate (for learners who registered before the program). 409 if already an affiliate |
| `PATCH /affiliate/preferred-leg` | `{ leg }` | Where the affiliate's future direct referrals are placed |
| `GET /affiliate/activation` | — | The eligible course and the affiliate's purchase state; `checkout` from the existing `POST /learning/courses/:courseId/purchase` |
| `GET /affiliate/dashboard` | — | `AffiliateDashboard` (§7.2 figures), one read |
| `GET /affiliate/tree?root&depth&page` | — | Subtree from `root` (own id or a downline id, else 404), up to `depth` ≤ 6 per page; nodes carry code, name initials, leg, rank, active, legs' CV |
| `GET /affiliate/team?leg&status&search&page` | — | Flat downline list with counts (direct referrals, total, per leg) |
| `GET /affiliate/referrals` | — | Direct referrals (sponsored), their status and placement |
| `GET /affiliate/cv?leg&from&to&page` | — | CV ledger rows |
| `GET /affiliate/matching?from&to&page` | — | Matching runs and the commissions they produced |
| `GET /affiliate/commissions?kind&status&page` | — | Commission rows |
| `GET /affiliate/ranks` | — | Current rank, history, next-rank progress (`legA`, `legB`, `required`, `shortfall` per leg) |
| `GET /affiliate/rewards` | — | Rewards and their state |
| `GET /affiliate/wallet` | — | Balances and the entry ledger (paged) |
| `GET /affiliate/kyc` · `PUT /affiliate/kyc` | `{ legalName, pan, bankAccount, ifsc, accountHolder, upiId?, documentIds }` | Submit or resubmit; documents are the affiliate's own uploads (`POST /media/upload`); PAN and account are encrypted and masked on read |
| `GET /affiliate/withdrawals` · `POST /affiliate/withdrawals` | `{ amount }` | Request against `available` (min amount, KYC verified, no open request); the amount moves to `held` in the same transaction |
| `POST /affiliate/withdrawals/:id/cancel` | — | Only while `requested` |
| `GET /affiliate/orders` | — | The affiliate's eligible purchase(s) (from course sales) |

### 5.3 Super Admin (👑, `/superadmin/affiliates/*`, platform context; every write audited)

| Method & path | Purpose |
| --- | --- |
| `GET /dashboard` | Totals: affiliates by status, sales and CV this period, matching paid, rewards, wallet liabilities, ceiling headroom, pending approvals (KYC, rewards, withdrawals), job health |
| `GET /members?status&rank&kyc&search&page` · `GET /members/:id` · `PATCH /members/:id` (`status`, note) | Affiliate members; suspend/terminate (earning stops; the tree position stays) |
| `GET /members/:id/tree?depth` · `GET /members/:id/ancestors` | Network from any node |
| `GET /network/export.csv?root` | Genealogy export |
| `GET /sponsors?search&page` | Sponsor view: direct referral counts, activation rates |
| `PATCH /members/:id/sponsor` (`{ sponsorId, reason }`) | Correct a sponsor (audited; CV attribution unchanged for past orders) |
| `GET /placements?page` · `POST /members/:id/placement` (`{ parentId, leg, reason }`) | Placement history; manual placement/move with cycle, duplicate and position checks (`PLACEMENT_CYCLE`, `POSITION_TAKEN`); subtree paths rebuilt; audited `mlm.placement.manual` |
| `GET /products` · `PUT /products` (`{ eligibleCourseIds }`) | Which courses of the program academy generate CV (a new plan version is required when CV terms change; this list alone is editable on the active version — D-MLM-05) |
| `GET /orders?status&from&to&search&page` · `GET /orders/:id` · `POST /orders/:id/reverse` (`{ reason }`) | Affiliate orders (joined to course purchases); manual reversal for a refund made in the Razorpay dashboard |
| `GET /cv?affiliateId&leg&from&to&page` · `GET /cv/export.csv` | CV ledger |
| `GET /matching/runs?date&affiliateId&status&page` · `POST /matching/run` (`{ date? }`) | Runs; trigger today's run by hand (idempotent) |
| `GET /commissions?kind&status&page` · `POST /commissions/:id/approve` · `POST /commissions/:id/hold` · `POST /commissions/:id/release` | Commission management (approval is automatic by default; manual review is a plan setting — D-MLM-07) |
| `GET /carry-forward?page` · `POST /members/:id/carry-forward/adjust` (`{ leg, amount, reason }`) | Carry-forward pools; signed adjustment with a reason. The CV ledger needs an order to point at, so this writes an audited balance update to the leg's `MlmLegBalance` (the audit row holds the figures before and after, and is its record) rather than a ledger row. Lifetime CV and rank do not move; a change below zero is refused |
| `GET /ranks` · `GET /ranks/history?affiliateId&page` · `POST /members/:id/rank/recalculate` | Rank definitions of the active version; history; re-evaluate one affiliate |
| `GET /rewards?status&page` · `POST /rewards/:id/approve` · `POST /rewards/:id/fund` · `POST /rewards/:id/pay` · `POST /rewards/:id/reject` | Reward workflow: qualified → approved → vesting (until `vestsAt`) → funded → paid (a commission + wallet credit) |
| `GET /wallets?search&page` · `GET /wallets/:affiliateId` · `POST /wallets/:affiliateId/adjust` (`{ amount, reason }`) | Wallets; signed adjustment with reason, audited |
| `GET /withdrawals?status&page` · `POST /withdrawals/:id/approve` · `POST /withdrawals/:id/reject` (`{ reason }`) · `POST /withdrawals/:id/paid` (`{ reference, paidAt }`) | Withdrawal workflow |
| `GET /payouts` · `POST /payouts` (`{ withdrawalIds }`) · `GET /payouts/:id/export.csv` · `POST /payouts/:id/close` | Payout batches and the bank file |
| `GET /kyc?status&page` · `GET /kyc/:affiliateId` · `POST /kyc/:affiliateId/verify` · `POST /kyc/:affiliateId/reject` (`{ reason }`) | KYC review; documents streamed through the existing media access rules |
| `GET /reports/financial?period` · `GET /reports/liability?period` · `GET /reports/export.csv?report&period` | Company reports: gross eligible sales, field payout (matching, rewards), payout ratio vs 15% normal and 25% ceiling, holds and releases, wallet liability, paid out, reversals |
| `GET /plan` · `GET /plan/versions` · `POST /plan/versions` (draft from the active one) · `PUT /plan/versions/:id` (while draft) · `POST /plan/versions/:id/activate` | MLM Plan Settings, versioned; activation validates (18 ranks ascending, each `legCv = groupCv / 2`, every rank has a cap band, rates within bounds) |
| `GET /audit?page` | The platform audit log filtered to `mlm.*` |

### 5.4 Webhooks and existing endpoints touched

| Endpoint | Change |
| --- | --- |
| `POST /webhooks/academies/:tenantId/razorpay/courses` | **Extend:** handle `refund.processed` and chargeback/dispute events for a course payment → `MlmOrder` reversal (§6.8). Idempotent via `CoursePaymentEvent` |
| `POST /learning/courses/:courseId/purchase` | None. Activation is an ordinary purchase; the `settle` hook does the rest |
| `GET /learning/courses/:courseId` | None |

---

## 6. Business logic and calculation rules

Every figure below is a default in `MlmPlanVersion`; the PDF's numbers are the seed of version 1. All arithmetic
is integer paise with `divideRounded` (banker's rounding is **not** used; half-up as the rest of billing).

### 6.1 Plan snapshot (PDF p.2)

| Term | Value | Setting |
| --- | --- | --- |
| Course price | ₹10,000 | the course's own price in the program academy |
| Legs | A/Left, B/Right, unlimited depth | fixed |
| Income heads | matching income + rank/reward only | fixed (no direct-referral bonus, no level income) |
| Matching | 10% of matched CV; the weaker eligible leg determines matched CV | `matchingRateBps = 1000` |
| Rank balance | each rank needs 50% of its group CV from A and 50% from B | `legCv = groupCv / 2`, both legs independently |
| Carry forward | unused eligible strong-leg CV carries forward; no routine month-end flush | `carryForwardPolicy = indefinite` |
| Top matching cap | ₹65,000/day in the top band | cap bands (§6.4) |
| Reward logic | rank target + exact 50:50 + verified sales + qualification/funded rules | §6.6 |

### 6.2 Affiliate lifecycle

```
registered (PendingAccount with referralCode) ──code confirmed──> Affiliate.pending (placed in the tree at once, D-MLM-04)
Affiliate.pending ──eligible purchase paid (settle hook)──> Affiliate.active (activatedAt, activationOrderId)
active ──Super Admin──> suspended (earns nothing; CV still flows through the node to its ancestors) ──> active
active | suspended ──Super Admin──> terminated (final; position stays, so the tree is never re-shaped)
```

- An affiliate's own purchase generates CV for its **ancestors**, never for itself.
- An affiliate earns matching only while `active`; a pending or suspended node still passes CV upward
  (otherwise a suspension would silently punish everyone above it). Configurable: `passThroughWhenSuspended`
  (default true).
- A learner who registered without a referral code can opt in later (`POST /affiliate/enrol`) naming a sponsor;
  without one, the Super Admin assigns a sponsor or the node joins under a configured company root
  (`rootAffiliateId`, D-MLM-06).

### 6.3 Binary placement and spillover (PDF p.3)

- Sponsor and placement are **separate** relations, both recorded (`sponsorId`, `placementParentId` + leg).
- Every node has two positions. A sponsor's direct referral is placed on the sponsor's `preferredLeg`
  (chosen at sign-up as "A/B placement selection", changeable later). If that position is taken, the referral
  **spills over** deeper in that leg under the published rule. The PDF's example (X → Rahul A, Rohit B; Rohan
  chosen for A → placed under Rahul in A) is consistent with both common rules, so the rule is a setting:
  - `extreme-outer` (default): follow the chosen leg to its outermost free position (A → keep going left; B →
    keep going right). Deterministic, cheap (one walk down the leg), what most binary plans publish.
  - `breadth-first`: the first free position in the chosen leg by level order.
- **A link's requested leg.** A sponsor's share link can name a leg (`/ref/:code?leg=A|B`). That is `requestedLeg`,
  held on the pending registration until the code is confirmed and then on the affiliate. It goes first:
  placement uses `requestedLeg ?? sponsor.preferredLeg`, so the scheduler's catch-up places the member on the same
  leg. It is separate from the member's own `preferredLeg`, which steers *their* future referrals.
- Placement happens in one transaction holding the sponsor's `MlmLegBalance` row lock (so two referrals of one
  sponsor arriving together cannot take the same position) and relies on the database's
  `@@unique([placementParentId, placementLeg])` as the final guard (`POSITION_TAKEN` on a race, retried once).
- Validity checks before any write: parent exists and is in the program; parent is not the node itself; the
  parent's `pathIds` does not contain the node (`PLACEMENT_CYCLE`); the node has no existing position unless
  this is an authorised manual move; both legs under the chosen leg follow the rule.
- Manual placement (Super Admin, with reason) is allowed only while the node has **no downline** by default
  (`manualMoveWithDownline = false`), because moving a subtree changes every ancestor's leg CV history. With the
  setting on, a move rebuilds `pathIds` for the subtree and writes compensating CV ledger rows (negative under
  the old ancestors, positive under the new) so lifetime figures stay truthful; all audited.

### 6.4 CV generation (PDF pp.2, 9)

- Only a **verified sale** of an eligible course creates CV: the `settle` hook runs inside the purchase
  transaction when `status` becomes `paid`, writing `MlmOrder { status: pending, cv }`.
- `cv = netAmount × cvBasisPoints / 10000`, rounded half-up, where `netAmount` is the purchase amount in paise
  (all-inclusive price; D-MLM-08 on GST).
- The order becomes `eligible` after `cvEligibilityDelayDays` (default 0 → the same job tick). On eligibility,
  `cv.ts` credits **every ancestor** on the buyer's placement path: for each ancestor, the leg is the child of
  that ancestor which lies on the path (`A` or `B`); one immutable `MlmCvLedger` row per ancestor and
  `MlmLegBalance.lifetimeX += cv`, `unmatchedX += cv`, all in one transaction, idempotent on
  `(orderId, affiliateId, 'sale')`.
- The buyer's own node gets no CV. The sponsor is recorded on the order (`sponsorAffiliateIdAtSale`) for
  attribution reports, but CV follows **placement**, as the PDF's genealogy section requires.

### 6.5 Matching income, caps and carry-forward (PDF pp.4–5)

Run once per day per active affiliate (job `mlm-matching`, after `matchingRunHourIst`; manual trigger allowed;
unique per `(affiliateId, runDate)` so a repeated run is a no-op):

```
availableA = unmatchedA;  availableB = unmatchedB          (carry-forward pools already include today's eligible CV)
matchedCv  = min(availableA, availableB)                     (the weaker leg)
grossIncome = matchedCv × matchingRateBps / 10000            (₹30 lakh matched → ₹3 lakh)
dailyCap    = capBand(rankOrderAtRun).dailyCap
cappedIncome = min(grossIncome, dailyCap)
if cappedIncome < grossIncome:
    overflowCv = (grossIncome − cappedIncome) × 10000 / matchingRateBps
    capOverflowPolicy = flush  → flushedCv = overflowCv, removed from both legs' pools   (default; D-MLM-10)
    capOverflowPolicy = carry  → overflowCv stays in both pools for a later day
unmatchedA −= matchedCv − (carried overflow);  unmatchedB −= likewise   (the strong leg keeps its excess: carry forward)
commission(kind=matching, amount=cappedIncome, status=pending) → ceiling check (§6.7) → approved → wallet credit
```

- Cap bands of version 1 (PDF p.5): Starter/Achiever ₹5,000 · Star/Bronze ₹10,000 · Silver/Gold ₹20,000 ·
  Platinum/Sapphire ₹35,000 · Ruby/Diamond ₹50,000 · Crown/Ambassador+ ₹65,000 per day. The PDF names bands by
  rank pairs that do not list every rank (Associate, Pearl, Emerald, Blue/Royal Diamond are unnamed); version 1
  maps each rank to the band of its nearest named rank below it, and the mapping is editable (`capBandKey` per
  tier; D-MLM-10).
- An affiliate with no rank yet (below Associate) uses the first band.
- Example from the PDF: A = ₹40 lakh, B = ₹30 lakh → matched ₹30 lakh → ₹3 lakh gross; at the Crown band
  (₹65,000/day) it pays ₹65,000 today and, under `flush`, the rest of the matched volume is flushed; A keeps
  ₹10 lakh carried forward either way.
- `carryForwardPolicy = expire-days` would age pools; the default never expires ("no routine month-end flush").

### 6.6 Ranks and rewards (PDF p.6) — exact 50:50

Rank evaluation runs after each eligibility credit (and nightly as a safety net). A rank is reached when, on
**lifetime eligible CV** (`lifetimeA`, `lifetimeB`, which reversals reduce), **both** `lifetimeA ≥ tier.legCv`
**and** `lifetimeB ≥ tier.legCv`. Excess on one leg never counts toward the other: that is the "exact 50:50"
rule as the PDF defines it ("total Group CV must be split equally: 50% A Leg + 50% B Leg"). The highest tier
satisfied becomes the rank; `MlmRankHistory` records each new tier once; ranks are never lost (`rankDemotion =
never`, D-MLM-11).

Version 1 tiers (₹; L = lakh, Cr = crore):

| # | Rank | Group CV | A leg | B leg | Reward |
| --- | --- | --- | --- | --- | --- |
| 1 | Associate | 20K | 10K | 10K | Recognition |
| 2 | Achiever | 1L | 50K | 50K | Certificate |
| 3 | Star | 3L | 1.5L | 1.5L | ₹5K |
| 4 | Bronze | 7.5L | 3.75L | 3.75L | ₹15K |
| 5 | Silver | 15L | 7.5L | 7.5L | ₹30K |
| 6 | Gold | 30L | 15L | 15L | ₹60K |
| 7 | Platinum | 60L | 30L | 30L | ₹1.25L |
| 8 | Pearl | 1.2Cr | 60L | 60L | ₹2.5L |
| 9 | Sapphire | 2.5Cr | 1.25Cr | 1.25Cr | ₹5L |
| 10 | Ruby | 5Cr | 2.5Cr | 2.5Cr | ₹10L |
| 11 | Emerald | 10Cr | 5Cr | 5Cr | ₹20L |
| 12 | Diamond | 20Cr | 10Cr | 10Cr | ₹35L |
| 13 | Blue Diamond | 35Cr | 17.5Cr | 17.5Cr | ₹60L |
| 14 | Royal Diamond | 50Cr | 25Cr | 25Cr | ₹1Cr |
| 15 | Crown Diamond | 75Cr | 37.5Cr | 37.5Cr | ₹1.5Cr |
| 16 | Ambassador | 100Cr | 50Cr | 50Cr | ₹2Cr |
| 17 | Global Ambassador | 200Cr | 100Cr | 100Cr | ₹4Cr |
| 18 | Legacy Ambassador | 500Cr | 250Cr | 250Cr | Up to ₹10Cr (`rewardCapAmount`) |

Reward workflow (PDF p.9, "reward funding / vesting"): a new rank creates `MlmReward { qualified }`. Cash
rewards need the Super Admin's **approval**, then **vest** for `tier.vestingDays` (default 0 for Star–Gold, 90
for Platinum and above; editable), then are marked **funded** (a human confirmation that the money is set
aside), then **paid**: one `MlmCommission { rank_reward }` and a wallet credit, subject to the ceiling (§6.7).
Recognition and certificate rewards are marked paid on approval and can issue an existing LMS certificate
template (optional link, D-MLM-14). The "up to" tier records the actual amount the Super Admin approves.

### 6.7 Company payout ceiling (PDF pp.7–9)

The company model plans 15% normal field payout and a **25% hard ceiling** of gross sales. The ceiling is
enforced per `liabilityPeriod` (default calendar month, IST):

```
period.grossEligibleSales  = Σ cv-generating net sales with eligibleAt in the period
period.ceilingAmount       = grossEligibleSales × payoutCeilingBps / 10000
period.fieldPayoutAccrued  = Σ matching + rank_reward commissions approved in the period (reversals subtract)
headroom                   = ceilingAmount − fieldPayoutAccrued
```

When a new commission would exceed headroom, the excess is written as a commission with `status: held,
holdReason: ceiling` (the affiliate sees "held by payout policy"), the period's `heldAmount` grows, and
`observe('mlm.ceiling.hold')` fires. Held commissions are released **FIFO** by `mlm-ceiling` when later sales in
the same or a later period create headroom (`releaseHeldAcrossPeriods = true` by default), each release audited.
Nothing is ever silently cancelled; the Super Admin can also release or write off a hold by hand with a reason.
The 15% normal figure is reported against actuals on the financial report; it triggers nothing.

### 6.8 Refunds, chargebacks and reversals (PDF p.9)

- A refund or chargeback of an eligible purchase (webhook event, or the Super Admin's manual reversal after a
  dashboard refund) sets `MlmOrder.status = reversed` and writes, for every ancestor, a negative `MlmCvLedger`
  row (`kind: reversal`) that reduces `lifetimeX` and `unmatchedX` (the pool may go to zero but not below;
  the remainder is recorded as `overMatchedCv` on the order).
- Matching already paid on that CV: a `reversal` commission for the proportional income
  (`overMatchedCv × rate`), and a `reversal_debit` wallet entry, which may take `available` negative; future
  credits clear it first (clawback). Configurable `clawbackPolicy` (`wallet` default; `none`).
- Ranks are not demoted; the reward of a rank reached only because of the reversed CV is `rejected` if still
  unpaid, and flagged for review if paid.
- The learner's course access is not revoked by the module (unchanged from today, `14` A18); the Super Admin
  sees the reversal on the order and can suspend the affiliate.

### 6.9 Wallet and withdrawals

- Balances are sums of `MlmWalletEntry`; `MlmWallet` is a cache verified by a nightly reconciliation that
  raises `mlm.wallet.mismatch` if any sum differs.
- A withdrawal needs: `status = active`, KYC `verified` (`withdrawalRequiresKyc`), `amount ≥
  withdrawalMinAmount` (default ₹500), `amount ≤ available`, no open request. It moves the amount to `held`
  in the same transaction (`withdrawal_hold`); approval keeps it held; `paid` writes `withdrawal_paid` with the
  bank reference; rejection or cancellation writes `withdrawal_released`.
- `tdsBps` (default 0) deducts TDS at payout as a `tds_debit` entry when set; the rate is the company's tax
  decision (§13), not the module's.

### 6.10 Idempotency and concurrency guarantees

| Operation | Guarantee |
| --- | --- |
| Order from a purchase | `MlmOrder.purchaseId` unique; the hook runs inside the purchase transaction |
| CV credit | `(orderId, affiliateId, kind)` unique; a re-run inserts nothing |
| Placement | parent-row lock + `(placementParentId, placementLeg)` unique |
| Matching | `(affiliateId, runDate)` unique; run inside a transaction holding the affiliate's `MlmLegBalance` row |
| Reward | one per `rankHistoryId` |
| Withdrawal | one open per affiliate; balances moved in the same transaction as the request |
| Webhook reversal | `CoursePaymentEvent` unique per event id |
| Jobs | `JobLease` per job name; per-affiliate work is independent, so a crash mid-run resumes safely |

---

## 7. Frontend pages and components

### 7.1 Super Admin — "Affiliates" nav group (`/superadmin/affiliates/*`)

The brief's 19 modules map to 15 pages (closely related modules share a page with tabs, as the subscriptions
section does today):

| Brief module | Page | Route |
| --- | --- | --- |
| 1 Affiliate Dashboard | `AffiliateDashboardPage` — KPIs, period liability vs ceiling, pending queues, job health | `/superadmin/affiliates` |
| 2 Affiliate Members | `MembersPage` (list, filters, export) · `MemberPage` (profile, status, sponsor, placement, legs, rank, wallet, KYC, orders tabs) | `/superadmin/affiliates/members`, `/:id` |
| 3 Binary Network Management | `NetworkPage` — tree from any node, search, export | `/superadmin/affiliates/network` |
| 4 Sponsor Management | `SponsorsPage` — referral counts, change sponsor dialog | `/superadmin/affiliates/sponsors` |
| 5 Placement Management | `PlacementsPage` — history, manual placement dialog with live validation | `/superadmin/affiliates/placements` |
| 6 Affiliate Product Management | `ProductsPage` — eligible courses of the program academy | `/superadmin/affiliates/products` |
| 7 Affiliate Orders & Sales | `OrdersPage` · reversal dialog | `/superadmin/affiliates/orders` |
| 8 CV Management · 10 Carry Forward | `LedgersPage` with tabs *CV ledger* and *Carry-forward pools* | `/superadmin/affiliates/ledgers` |
| 9 Matching Commission Management | `MatchingPage` — runs by date, commissions, hold/release, run-now | `/superadmin/affiliates/matching` |
| 11 Rank Management · 12 Reward Management | `RanksPage` (tiers of the active version, history) · `RewardsPage` (approval queue, vesting, funding) | `/superadmin/affiliates/ranks`, `/rewards` |
| 13 Affiliate Wallet | `WalletsPage` · wallet detail with ledger and adjustment | `/superadmin/affiliates/wallets`, `/:affiliateId` |
| 14 Withdrawal Management · 15 Payout Management | `WithdrawalsPage` (queue, approve/reject/paid) · `PayoutsPage` (batches, CSV) | `/superadmin/affiliates/withdrawals`, `/payouts` |
| 16 KYC Management | `KycPage` — queue, document viewer, verify/reject | `/superadmin/affiliates/kyc` |
| 17 Company Financial Reports | `ReportsPage` — period selector, payout ratio, liabilities, exports | `/superadmin/affiliates/reports` |
| 18 MLM Plan Settings | `PlanSettingsPage` — versions, draft editor (terms, 18 tiers, bands, policies), activate | `/superadmin/affiliates/plan`, `/plan/versions/:id` |
| 19 MLM Audit Logs | the existing `PlatformAuditPage` with a preset `mlm.` filter, linked from the group | `/superadmin/audit?prefix=mlm.` |

Patterns reused: `Platform.module.css` tables, dialogs from `AdminDialogs.tsx`, `platformMeta.tsx` for status
registry entries, `PlanGate`-style empty states, the command palette registry for the new routes.

### 7.2 Affiliate workspace (learner role, `/affiliate/*`)

A nav item "Affiliate" in the learner workspace, shown when the signed-in learner belongs to the program academy
(hidden for everyone else). Pages:

| Page | Route | Content |
| --- | --- | --- |
| `AffiliateHomePage` | `/affiliate` | Activation state (buy the course → existing checkout), referral link + QR + share, the dashboard figures: total team, direct referrals, A and B leg CV, eligible group CV, matched CV, carry-forward per leg, matching income, current rank and next-rank progress (both legs), reward income, wallet balance |
| `AffiliateTreePage` | `/affiliate/tree` | Binary tree (SVG, 4–6 levels per view, drill-down, search by code) |
| `AffiliateTeamPage` | `/affiliate/team` | Direct referrals and downline list with leg and status filters |
| `AffiliateEarningsPage` | `/affiliate/earnings` | Tabs: matching runs, commissions, rewards, ranks history |
| `AffiliateWalletPage` | `/affiliate/wallet` | Balances, ledger, request withdrawal, withdrawal history |
| `AffiliateKycPage` | `/affiliate/kyc` | Submit/resubmit KYC with document uploads (existing `MediaDrop`) |
| `AffiliateOrdersPage` | `/affiliate/orders` | The eligible purchase(s); links to the existing `/purchases` |
| Join with referral | `/ref/:code` → `/join/:slug?ref=CODE&leg=A` | The public join page shows "Invited by …" and the leg choice; the code is carried into the existing sign-up |

Components in `components/mlm/`: `BinaryTree`, `TreeNode`, `LegMeter` (A vs B with the 50:50 line),
`RankProgress`, `LedgerTable`, `MoneyStat`, `ReferralCard` (link, copy, QR, share), `CodeBadge`,
`WithdrawalDialog`, `KycForm`.

Service seam: `AffiliateService` (own records) and `PlatformAffiliateService` (Super Admin) in `contracts.ts`,
HTTP and mock implementations, fixtures with a 30-node demo tree so mock mode renders every state.

---

## 8. Mobile implementation plan

New feature module `apps/mobile/lib/features/affiliate/`, following the `staff_billing` layout:

```
data/dto/affiliate.dart (+ .freezed/.g)     AffiliateMe, Dashboard, TreeNode, Commission, Reward, Wallet, Kyc, Withdrawal
data/affiliate_api.dart                      Dio calls to /affiliate/*; /public/affiliates/ref/:code
application/affiliate_controller.dart        Riverpod: me, dashboard, tree paging, wallet, kyc, withdrawals
presentation/screens/
  affiliate_home_screen.dart                 figures, activation card, referral card (share_plus; QR via qr_flutter)
  tree_screen.dart                           horizontally scrollable binary tree, 3 levels per view, drill-down
  team_screen.dart · earnings_screen.dart · ranks_screen.dart · wallet_screen.dart · kyc_screen.dart · withdraw_screen.dart
presentation/widgets/                        leg_meter.dart, rank_progress.dart, ledger_list.dart, tree_node.dart
affiliate.dart                               barrel
```

- **Routes:** `/affiliate`, `/affiliate/tree`, `/affiliate/team`, `/affiliate/earnings`, `/affiliate/ranks`,
  `/affiliate/wallet`, `/affiliate/kyc`, `/affiliate/withdraw` in `routes.dart`; a learner-shell destination
  "Affiliate" shown only when `AffiliateMe` resolves (the API answers 404 for non-program learners, which the
  controller maps to "not available"). `web_path_mapper.dart` maps `/ref/:code` deep links to the register flow
  with the code pre-filled (Android intent filter `/ref/`).
- **Registration:** the existing register screen gains the referral code (pre-filled from a link, editable) and
  the A/B preference; the request carries `referralCode` and `preferredLeg`; the email-code step is unchanged.
- **Activation:** `COURSE_CHECKOUT_ENABLED` is `false` on `zuviloai.com`, so the activation card opens the web
  checkout in the browser (`url_launcher`) and polls `GET /affiliate/activation` on return — the same hand-off
  the plan checkout uses (D-MLM-13). Where the owner later allows in-app course checkout, the existing
  `razorpay_flutter` path applies unchanged.
- **KYC uploads:** the existing media upload path (`file_picker`, `POST /media/upload`), document kind.
- **Architecture tests** apply as they stand (no Dio in widgets, no literal strings → ~120 new l10n keys, no
  hard-coded colours). Goldens for the home, tree and wallet screens; unit tests for the controllers; contract
  tests against fixtures captured from the contract server; integration tests `affiliate_test.dart` on the
  device; a live-E2E scenario file `scenarios/affiliate.py`.
- **Push:** the new notification categories (commission credited, rank achieved, withdrawal paid) ride the
  existing hint mechanism; nothing new on the device side.

---

## 9. Background jobs, audit and observability

Added to `lib/scheduler.ts` under their own leases, each idempotent and `watchJob`-wrapped, run for the program
academy's context:

| Job | Cadence | Work |
| --- | --- | --- |
| `mlm-cv-eligibility` | every tick | `MlmOrder.pending` whose delay has passed → `eligible` and credit ancestors |
| `mlm-ranks` | after eligibility, and nightly | evaluate affiliates whose balances changed since their last evaluation |
| `mlm-matching` | once per day after `matchingRunHourIst`; catches up missed days in order | the run of §6.5 for every active affiliate with non-zero pools |
| `mlm-ceiling` | after matching, and when a period closes | holds and FIFO releases |
| `mlm-reward-vesting` | nightly | `vesting` rewards whose `vestsAt` passed → ready to fund |
| `mlm-wallet-reconcile` | nightly | recompute `MlmWallet` and `MlmLegBalance` from ledgers; signal on mismatch |

Audit actions (`lib/mlm/audit.ts`, written in the same transaction as the change): `mlm.plan.activated`,
`mlm.affiliate.activated`, `mlm.affiliate.status_changed`, `mlm.sponsor.changed`, `mlm.placement.manual`,
`mlm.order.reversed`, `mlm.carry.adjusted`, `mlm.commission.held`, `mlm.commission.released`,
`mlm.reward.approved|funded|paid|rejected`, `mlm.wallet.adjusted`, `mlm.kyc.verified|rejected`,
`mlm.withdrawal.approved|rejected|paid`, `mlm.payout.created|closed`. System jobs write with
`{ type: 'system', job }`; provider-driven reversals with `{ type: 'provider', provider: 'razorpay' }`.

Signals added to `observe.ts`: `mlm.commission.failed`, `mlm.ceiling.hold`, `mlm.reversal`,
`mlm.placement.manual`, `mlm.wallet.mismatch`, `mlm.job.behind` (a matching day not yet run). The Super Admin
dashboard shows each job's last outcome from `JobLease`, as `/superadmin/system` does.

---

## 10. Testing plan

Same layers as `08-TESTING-PLAN.md`; every module in §11 lands with its tests green before the next starts.

| Layer | What |
| --- | --- |
| Domain (Vitest, `packages/domain/src/mlm/*.test.ts`) | matching math at boundaries (equal legs, zero leg, cap exactly reached, overflow flush vs carry); rank qualification (excess on one leg does not qualify; both legs at exactly `legCv` do); 50:50 validation of a version; spillover position search on sample trees; cycle detection; ceiling headroom and FIFO release; wallet arithmetic; code check digit |
| API (Vitest + supertest, seeded `test.db`) | `mlmPlan.test.ts` (versions, validation, activation, sealed tiers); `affiliateRegistration.test.ts` (referral through the email code, pending → active on a sandbox-gateway purchase, invalid code, opt-in); `mlmPlacement.test.ts` (spillover determinism, both positions taken, manual move refusals: cycle, taken, downline present, race via concurrent requests); `mlmCv.test.ts` (ancestor credits, idempotent re-run, non-eligible course writes nothing, other academy writes nothing); `mlmMatching.test.ts` (daily run, cap bands by rank, carry-forward across days, idempotent re-run, catch-up); `mlmRanks.test.ts` (progression through tiers, history once, rewards created, vesting dates); `mlmCeiling.test.ts` (hold and release across periods); `mlmReversal.test.ts` (refund webhook → negative CV, clawback, reward rejection); `mlmWallet.test.ts` (withdrawal rules, KYC gate, hold/paid/released, TDS); `mlmSuperadmin.test.ts` (every management route, exports); `routeAudit.test.ts` picks up every new route automatically (401 anonymous, learner refused on platform routes, affiliate of another academy 404); `tenancy.test.ts` classification count and cross-academy probes; `securityAudit.test.ts` sweep for PAN/account numbers in logs and responses (`redact` extended) |
| Web (Vitest) | mock services and fixtures; `BinaryTree` layout maths; `RankProgress`; formatting of paise; navigation visibility rules |
| E2E (Playwright, sandbox gateway) | `affiliate.spec.ts`: sponsor signs up with a code → shares link → two referrals join via `/ref/:code` with A and B → each buys the course through the sandbox → CV appears on the sponsor's legs → run matching by hand as Super Admin → commission in wallet → KYC submitted and verified → withdrawal requested, approved, paid → ledger and audit show every step; `affiliateAdmin.spec.ts`: plan version draft → activate; manual placement refusal and success; reversal of a purchase |
| Mobile | unit (controllers, DTOs), goldens, contract fixtures, `integration_test/affiliate_test.dart`, live-E2E scenario |
| Quality gates | `typecheck`, `lint` (the plan-name lint rule extended to forbid rank-name comparisons), `test`, `build`, `format:check`, `e2e`, `tool/verify.sh` |
| Load check | a script seeds a 50,000-node tree on a scratch database and times the matching run and a 6-level tree read (targets: run < 5 min on the production VPS, tree page < 300 ms) — SQLite's single writer is the known constraint (§13) |

---

## 11. Implementation sequence

Sequential modules, each with migration, service, routes, web, tests; the app follows once the API is stable.
Records go to `.claude/mlm/progress.md` on the same pattern as the SaaS track.

| # | Module | Delivers |
| --- | --- | --- |
| MLM-000 | Plan foundation | domain `mlm/plan.ts`, `MlmPlanVersion`/`MlmRankTier`/`MlmCapBand`, seed of version 1 from the PDF, Super Admin plan pages, tenancy classification |
| MLM-001 | Affiliates & registration | `Affiliate`, referral code, `?ref=` through the registration doors, opt-in, `/affiliate` (me), `/ref/:code`, QR |
| MLM-002 | Genealogy | placement, spillover, manual placement, history, tree and team reads, network pages (SA and affiliate) |
| MLM-003 | Orders & CV | **Built 31 Oct 2026.** Settlement hooks (`lib/purchaseHooks.ts`), `MlmOrder`, eligibility job, CV ledger and leg balances, courses/orders/ledgers pages, the learner's figures and volume page |
| MLM-004 | Matching | daily run, caps, carry-forward, commissions, matching pages, affiliate earnings |
| MLM-005 | Ranks & rewards | evaluation, history, rewards workflow, rank/reward pages, rank progress UI |
| MLM-006 | Wallet, KYC, withdrawals, payouts | ledgers, balances, KYC with encryption, withdrawal workflow, payout batches and CSV, pages on both sides |
| MLM-007 | Ceiling & reversals | liability periods, holds and releases, refund/chargeback reversal, clawback, reports page |
| MLM-008 | Dashboards & reports | SA dashboard, affiliate home, financial reports and exports, notifications, audit filter |
| MLM-009 | Hardening & E2E | route audit, security sweep, load check, E2E specs, docs (`05`, `03`, `06`, `09`, `00`) |
| MLM-010 | Flutter | the feature module of §8, device-verified; contract fixtures; live-E2E scenario |

---

## 12. Open decisions and configurable rules

Each is a setting on `MlmPlanVersion` (or a product decision) with the default the implementation will use
unless told otherwise. Approving this document approves the defaults; changing one later is a new plan version,
not a code change.

| Ref | Question | Default |
| --- | --- | --- |
| D-MLM-01 | Program academy and eligible course(s) | the `default` academy; the ₹10,000 AI course, named by the Super Admin on the Products page |
| D-MLM-02 | One platform-wide program, or a program per academy? | one program (v1); the schema keeps `programTenantId` so per-academy can follow |
| D-MLM-03 | May the program academy's own admins manage affiliates? | no; Super Admin only in v1 |
| D-MLM-04 | When is a referral placed in the tree: at registration (pending) or at activation? | at registration, so the sponsor sees pending referrals and positions are not reshuffled on activation |
| D-MLM-05 | Can the eligible-course list change without a new plan version? | yes (it is a product list, not a compensation term); every other term needs a version |
| D-MLM-06 | Where does a learner with no sponsor go? | under a company root affiliate the Super Admin designates; or they are simply not affiliates until they opt in with a code |
| D-MLM-07 | Are matching commissions approved automatically? | yes, on the daily run, unless held by the ceiling; a `manual` mode exists |
| D-MLM-08 | Is CV the all-inclusive price (₹10,000) or the price net of GST? | the all-inclusive purchase amount (what the PDF's examples use); `cvBasisPoints` can set CV below 100% |
| D-MLM-09 | "OTP verification" | the existing 6-digit emailed code; SMS OTP needs an SMS provider that does not exist today |
| D-MLM-10 | Matched volume above the daily cap: flushed or carried? And the cap band of the ranks the PDF does not name | flushed (`capOverflowPolicy = flush`); unnamed ranks take the band of the nearest named rank below (Associate → Starter band; Pearl → Platinum/Sapphire; Emerald → Ruby/Diamond; Blue/Royal/Crown Diamond → Ruby/Diamond until Crown; Crown Diamond and above → top band) |
| D-MLM-11 | Rank demotion after reversals | never; rewards of a rank reached only by reversed CV are rejected if unpaid |
| D-MLM-12 | QR code generation | server-side SVG (no new dependency); `qr_flutter` on mobile |
| D-MLM-13 | Activation purchase in the app | hand off to the web checkout while in-app course checkout is off by store-policy decision |
| D-MLM-14 | Certificate-type rewards | a recognition record; optionally issue an LMS certificate template chosen on the tier |
| D-MLM-15 | Withdrawal minimum, TDS, KYC requirement | ₹500; `tdsBps = 0` until the company decides; KYC verified required |
| D-MLM-16 | Payout execution | manual bank/UPI transfer by the company with the reference entered; no payout API |
| D-MLM-17 | Liability period for the 25% ceiling and cross-period release | calendar month (IST); held amounts release FIFO in later periods |
| D-MLM-18 | Suspended node passes CV upward? | yes |
| D-MLM-19 | Manual move of a node with a downline | refused unless the setting allows it (then compensating ledger rows) |

---

## 13. Risks and compliance notes

- **Legal review before launch (PDF p.9).** India's Consumer Protection (Direct Selling) Rules, 2021 and the
  Prize Chits and Money Circulation Schemes (Banning) Act, 1978 govern what may be paid for. The plan pays only
  on verified course sales and caps field payout at 25%, which is the right shape, but the compensation terms,
  GST on the course and on commissions, TDS, and the affiliate agreement need a professional review. The module
  makes every term configurable so that review can change numbers without code.
- **Database engine.** SQLite's single writer is adequate for the matching run (sequential, per affiliate) and
  for tens of thousands of nodes; the load check in §10 is the gate. The scaling path is the one already recorded
  (PostgreSQL, `LIVE_REMINDERS=off` on extra instances); the module uses nothing SQLite-specific beyond the
  trigger syntax, which has a PostgreSQL equivalent.
- **Tree depth.** The materialised `pathIds` bounds ancestor reads but grows with depth; at 10,000 levels it is
  still a few hundred KB per row at the bottom. A depth limit is not a plan rule, so none is imposed; the load
  check measures it.
- **Money already paid cannot be un-paid.** Reversals after withdrawal become negative wallet balances
  (clawback), which the company may never recover; the ceiling hold and vesting windows exist to limit this.
- **Sensitive data.** PAN and bank account numbers are encrypted under `PAYMENT_CREDENTIALS_KEY`, masked on every
  read, excluded from logs by the redaction sweep, and never exported to CSV in full.
- **Nothing touches production until deployed by hand**: all migrations are additive; the demo seed's guard is
  unchanged; the MLM seed (`seed:mlm-plan`) writes only the plan version and refuses to run if one is active.
