# ZuviloAI MLM Affiliate Program — Progress

MLM PHASE STATUS: MLM-000 to MLM-008 completed by 1 Nov 2026; MLM-010 (Flutter) blocked on a toolchain.

The build record of the affiliate program (specification: `docs/15-MLM-AFFILIATE-ARCHITECTURE.md`, approved with its §12
defaults on 31 Oct 2026; business plan: `docs/specs/AI-Course-2-Leg-MLM-Plan-50-50-Corrected.pdf`). The SaaS record is
`.claude/saas/progress.md`, the Flutter record `.claude/flutter/progress.md`; neither is edited from here.

## Session Checkpoint

```
Module:            all but MLM-010
Completed:         MLM-000 to MLM-008 (31 Oct to 1 Nov 2026); the MLM-009 route audit and E2E are in `routeAudit.test.ts` and `apps/web/e2e/affiliate.spec.ts`
Not done:          the load check on a 50,000-node tree; MLM-010 (no Flutter toolchain on this machine)
```

## Completed

### MLM-004 to MLM-008 — Earnings (1 Nov 2026)

Engine `lib/mlm/earnings.ts` (matching, ceiling, ranks, rewards, reversals), `lib/mlm/wallet.ts` (wallets, KYC, withdrawals, payouts, reports), rules in `packages/domain/src/mlm/earnings.ts`, routes `routes/superadminMlmEarnings.ts` and `routes/affiliate.ts`, migration `mlm_earnings`, jobs `mlm-ranks`, `mlm-matching`, `mlm-ceiling`, `mlm-wallet-reconcile`. Web: Overview, Matching, Ranks & rewards, Wallets, Withdrawals, Identity checks for the Super Admin; Earnings, Wallet, Identity check for the member. Suites `earnings.test.ts` (domain) and `mlmEarnings.test.ts` (API). Browser-driven on the dev database: a sandbox purchase activated a member, who withdrew through approval, batch, payment and close.

**Decisions.** The ceiling counts the sales of the month the money settles in, so early in a month matching can wait on hold until that month's sales make room: that is §6.7 as written, and worth the owner's attention. Catch-up after downtime runs each missed day in order, for at most 30 days. See `16-PLATFORM-CONVERSION.md` §8 for deviations.

### MLM-003 — Orders & CV (31 Oct 2026)

**Built.**
- Domain `packages/domain/src/mlm/cv.ts`: `cvOfSale` (basis points of the net sale, rounded half-up in integers),
  `creditsAlongPath` (every ancestor on the buyer's path, each in the leg the next node hangs under), `eligibleAtFor`,
  the order / ledger / figures / carry-forward view types.
- Schema (migration `20261031150000_mlm_cv`): `MlmOrder` (one per verified purchase; money, course, buyer and plan
  fixed by trigger; `reversed` final; never deleted), `MlmCvLedger` (one row per order × ancestor × kind, sign checked,
  never updated or deleted), `MlmLegBalance` (per affiliate: lifetime and unmatched per leg, matched lifetime, last run
  date, `version` for the matching job). Tenancy lists updated (59 academy-owned tables).
- `lib/purchaseHooks.ts`: a registry course sales never import from. *Paid hooks* run inside the settlement transaction
  of `markPaid` (`lib/coursePurchases.ts`, both "opened" branches); *settled hooks* run after it commits. A hook that
  throws is reported (`job.failed`) and skipped — a taken payment is never rolled back by the program.
- `lib/mlm/cv.ts`: `recordMlmOrder` (paid hook: the active plan, the program LMS, an eligible course → `MlmOrder`
  pending; `activateAffiliate` for a buyer in the program; signal `mlm.order.recorded`), `creditSettledPurchase`
  (settled hook: with delay 0, `makeEligible` in its own transaction), `creditAncestors` (ledger rows + pool upserts,
  sign ±1), `makeEligible` (waits for a sponsored buyer with no position yet), `settleEligibleOrders` (scheduler job
  `mlm-cv-eligibility`, every tick per academy), `reverseMlmOrder` (negates once; audit `mlm.order.reversed`, signal
  `mlm.reversal`), reads `listOrders`, `orderDetail`, `listCvLedger`, `legFigures`, `affiliateFigures`,
  `listCarryForward`, `cvLedgerCsv`.
- Routes: `/affiliate/figures`, `/affiliate/cv`; `/superadmin/affiliates/products` (GET/PUT), `/orders[/:id]`,
  `/orders/:id/reverse`, `/cv`, `/cv/export.csv`, `/carry-forward`.
- Web: contracts + HTTP + mock for the two services (`services/mock/affiliateCv.ts` derives demo sales from the demo
  tree); Super Admin `ProductsPage`, `OrdersPage` (status counts, search, detail drawer, reverse dialog with reason and
  note), `LedgersPage` (CV ledger with leg/kind filters and CSV export; carry-forward pools); the learner's
  `AffiliateVolumePage` (figures tiles + own ledger) and the same tiles on the affiliate home; tabs and nav entries.

**Tests.** Domain `mlm/cv.test.ts` (3); API `routes/mlmCv.test.ts` (5: in-hook credit along a three-node path,
reversal once with the audit row, outsider and unplaced buyers + the job, the Super Admin's views and CSV, the products
guard); `mlmAffiliates.test.ts` made order-independent of it (both suites share the active plan). Web
`services/mock/affiliate.test.ts` (+1), `services/mock/affiliatesPlatform.test.ts` (+3), navigation test. Web suite
555 green; build green. Browser drive against the real API with `PAYMENT_SANDBOX=on`: Rohit (seeded learner) opted in
under Ananya's code, bought the eligible course through the sandbox checkout — order `eligible`, ₹1,499 CV credited to
Ananya's leg A, Rohit `active`; his home shows the figures tiles and the Volume tab; the Super Admin's Courses and
Orders pages render against the API with no console errors.

**Decisions taken while building.**
- CV is credited *after* the settlement commits, not inside it: the tenancy extension checks foreign keys against
  committed rows, so ledger rows naming the new order cannot be written in the same transaction. The order itself and
  the buyer's activation are written inside it (they reference committed rows), so a paid purchase and its order can
  never disagree; the credit follows within the same request, and the eligibility job is the net underneath.
- An order by a buyer outside the program becomes `eligible` at once with `creditedAncestors` 0: there is nothing to
  wait for, and the sale is still counted in the program's figures.
- `netAmount` is the amount paid (the all-inclusive price); no fee or tax is deducted before CV — D-MLM-11 stays open
  and the basis points on the plan are the lever.
- Reversal by hand only (Super Admin): the gateway's refund and chargeback webhooks are MLM-007's work.

### MLM-002 — Genealogy (31 Oct 2026)

**Built.**
- Domain `packages/domain/src/mlm/genealogy.ts`: `findFreePosition` (extreme-outer / breadth-first over a `childOf`
  reader), `pathUnder`, `wouldCycle`, `rebasedPath`, `legUnderRoot`, the tree/team/member/placement/sponsor view types.
- Schema: `MlmPlacementHistory` (academy-owned, append-only by trigger; migration `20261031140000_mlm_placement`).
- Service `lib/mlm/placement.ts` (writer of placement fields and history): `placeAffiliate` (sponsor's preferred leg, else
  deeper by the active plan's spillover rule; the unique (parent, leg) index is the final guard, a loser searches again;
  a sponsorless opt-in is a root), `placePendingAffiliates` (the scheduler's `mlm-placement` job, every tick per academy —
  also the backfill for MLM-001 rows), `manualPlacement` (cycle → `PLACEMENT_CYCLE`, filled → `POSITION_TAKEN`, a node
  with a team → `PLACEMENT_INVALID` unless `moveSubtree`, which rebases every descendant's path; audited and signalled),
  `changeSponsor`, `setAffiliateStatus` (suspend/reactivate/terminate; activation never by hand).
- Reads `lib/mlm/tree.ts`: `subtree` (≤ 6 levels), `ancestors`, `team` (flat page with counts by leg/status), `directReferrals`,
  `listMembers`/`memberDetail` (platform-wide, optional academy), `placementHistory`, `listSponsors`, `networkCsv`.
- Placement happens at registration and at opt-in (`affiliates.ts`), never failing either: the job catches up.
- Routes: `/affiliate/tree?root&depth`, `/affiliate/team`, `/affiliate/referrals`; `/superadmin/affiliates/members[/:id]`
  (+ `PATCH` status, `/tree`, `/ancestors`, `/team`, `POST /placement`, `PATCH /sponsor`), `/placements`, `/sponsors`,
  `/network/export.csv`.
- Web: `BinaryTree` component (HTML/CSS, drill-down, open positions drawn); learner pages `/affiliate/tree`, `/affiliate/team`
  with an affiliate sub-navigation; Super Admin `MembersPage`, `MemberPage` (facts, ancestors, tree, move / change sponsor /
  suspend / close dialogs, CSV export), `PlacementsPage`, `SponsorsPage`; tabs Members · Sponsors · Placements · Plan; the
  affiliates nav group lands on Members. Mocks share a fixed nine-person demo tree (`services/mock/affiliateTree.ts`).

**Tests.** Domain `mlm/genealogy.test.ts` (4); API `routes/mlmPlacement.test.ts` (6: rule placement and spillover,
tree/team/referrals reads with scope, the catch-up job, member directory and CSV, every manual-move refusal and a leaf
and a subtree move, sponsor and status changes); tenancy counts (56); web mock tests (5 new). Full API and web suites
green, build green, browser drive of every new page clean.

**Decisions taken while building.**
- A learner who opts in without a sponsor is a root (a forest is allowed); the company-root option of D-MLM-06 is not used.
- A referral's own `preferredLeg` is where *their* referrals go; where they are placed follows the sponsor's preference.
- A subtree move rebases paths only; CV compensation for moved volume is MLM-003's concern (the ledger does not exist yet).

### MLM-001 — Affiliates & registration (31 Oct 2026)

**Built.**
- Domain `packages/domain/src/mlm/affiliate.ts`: check-digited 8-character codes from an unambiguous alphabet
  (`affiliateCodeFrom`, `isAffiliateCode`, `normaliseAffiliateCode`), link builders (`referralLinkFor`, `joinLinkFor`),
  the `AffiliateMe`, `ReferralInfo`, `AffiliateActivation` view types.
- Schema: `Affiliate` (academy-owned; sponsor and placement as separate self-relations; `pathIdsJson`/`depth` for the
  genealogy module; `code` unique platform-wide; two positions per parent by unique index; triggers: identity fixed,
  termination final, sponsor/parent in the same academy, never deleted); `PendingAccount.referralCode/preferredLeg`.
  Migration `20261031130000_mlm_affiliates`.
- Service `apps/api/src/lib/mlm/affiliates.ts`: `prepareReferral` (resolved before the account exists, so a bad code
  refuses the registration; lenient only for a verified registration whose sponsor vanished meanwhile) and
  `attachAffiliate` (right after the account's transaction: the tenancy extension checks foreign keys against committed
  rows), `sponsorByCode`/`sponsorFor` (same academy only), `resolveReferral`, `affiliateMe`, `enrolAffiliate`,
  `setPreferredLeg`, `affiliateActivation` (eligible courses × the learner's purchases/enrolments), `activateAffiliate`
  (for the CV module's settlement hook), `referralQrSvg` (`qrcode` package, new API dependency).
- Every registration door carries the referral: `createLearner` (and so `registerLearner`, `registerLearnerAt`,
  `acceptWithNewAccount`, `joinFromCourseLink`), `pendingAccounts` (stored on the row, applied at confirmation), the
  `joinSchema` of `/public/academies/:slug/register`, `/public/invitations/:token/register`,
  `/public/courses/:courseId/enroll` and `registerSchema` of `/auth/register` (`referralCode?`, `preferredLeg?`).
- Routes: `/affiliate` (`GET` → `{ affiliate | null }`, `POST /enrol`, `PATCH /preferred-leg`, `GET /activation`;
  learners only — the role guard's admin bypass is refused explicitly), `GET /public/affiliates/ref/:code` and
  `…/qr.svg`. Error codes `REFERRAL_INVALID`, `NOT_AN_AFFILIATE`, `AFFILIATE_NOT_ACTIVE`.
- Web: `AffiliateService` (36th group; HTTP + mock with a fixture sponsor), learner nav group "Earn" → `/affiliate`
  (`AffiliateHomePage`: opt-in form; code, link, QR, share; sponsor/placement/status; preferred leg; activation card
  linking to `/learn/:courseId`), `/ref/:code` (`RefPage` → `/join/:slug?ref=CODE`), the join page reads `?ref`/`?leg`,
  shows "Invited by …" and sends them with the registration.

**Tests.** Domain `mlm/affiliate.test.ts` (5); API `routes/mlmAffiliates.test.ts` (8: opt-in, refusals, preferred leg,
activation, referral resolve + QR, registration through the join door and the host sign-up with a code, bad code
refused before any email, plain registration stays outside); `tenancy.test.ts` counts (55), `routeAudit` lists; web
`services/mock/affiliate.test.ts` (2), navigation and workspace tests updated. Full API and web suites green; build
green; browser drive against the real API: opt-in → home with QR → sign-out → `/ref/<code>` → join page prefilled.

**Decisions taken while building.**
- Placement is not written at registration yet: MLM-001 records the sponsor and leaves `placementParentId` null;
  MLM-002 places at registration from then on and places the nodes created meanwhile on its first run (D-MLM-04 holds).
- `GET /affiliate` answers `{ affiliate: null }` (200) for a learner outside the program, so the home page's probe is
  not a browser-logged error.
- The affiliate row is created immediately after the account's transaction rather than inside it: the tenancy
  extension checks foreign keys against committed rows. The referral is validated before the account exists, so the
  only failure left is a code collision, which is retried.

### MLM-000 — Plan foundation (31 Oct 2026)

**Built.**
- Domain `packages/domain/src/mlm/plan.ts`: every plan term as data (`MlmPlanTermsInput`/`MlmPlanTerms`), cap bands, rank
  tiers, `validateMlmPlanTerms` (bounds, 50:50 even group CV, ascending ranks, unique names/keys, bands referenced, reward
  shapes), `mlmActivationIssues` (an eligible course), `capBandForRank`, `legCvOf`, `bpsOf`, `defaultMlmPlanTerms` (the
  PDF's version 1: 18 ranks, six cap bands, 10% matching, 25% ceiling, 15% normal, ₹500 minimum withdrawal, KYC required,
  cap overflow flushed, carry-forward indefinite, extreme-outer spillover; D-MLM-10 band mapping for unnamed ranks).
- Schema: `MlmPlanVersion`, `MlmRankTier`, `MlmCapBand` (platform-owned; migration `20261031120000_mlm_plan`): CHECKs on
  every bound, one active version (triggers), forward-only status, terms/ranks/bands sealed once a version leaves draft,
  the course list alone editable on an active version (D-MLM-05), a used version never deleted. 64-bit amounts.
- Service `apps/api/src/lib/mlm/plan.ts` (the only writer): list/get/active, create draft (from terms, from a version,
  from the active one, or from the PDF bound to the default LMS), update a draft, set courses, activate (retires the
  previous in the same transaction), retire, delete a draft; platform-writer guard; audit `mlm.plan.*` in-transaction.
- Routes `/superadmin/affiliates/plan*` (`routes/superadminMlm.ts`, inside the Super Admin router).
- Seed `npm run seed:mlm-plan`: version 1 as a draft when no version exists; never activates.
- Web: `PlatformAffiliateService` (`affiliatesPlatform`, 35th group) with HTTP and mock implementations; nav group
  "Affiliates" → `/superadmin/affiliates/plan`; `AffiliatePlanPage` (running version, versions table, selected version's
  terms, bands and rank table; new draft, activate, retire, delete) and `AffiliatePlanEditorPage` (every term, course
  checklist, editable bands and ranks, domain validation with per-field issues, unsaved-changes guard).

**Tests.** `packages/domain/src/mlm/plan.test.ts` (13), `apps/api/src/lib/mlm/plan.test.ts` (9, incl. raw-SQL trigger
checks), `apps/api/src/routes/superadminMlm.test.ts` (5), web `services/mock/affiliatesPlatform.test.ts` (3),
`pages/superadmin/affiliates/affiliateMeta.test.ts` (3); `navigation.test.ts` and `commands/registry.test.ts` updated for
the new section. Full API and web suites green.

**Decisions taken while building.**
- A cash reward may be "up to" an amount with no fixed floor (Legacy Ambassador): `rewardAmount: 0, rewardCapAmount`.
- Drafts must already be valid terms (as plans are); only the eligible-course list may be empty until activation.
- `programTenantId` is a column from day one (per-academy programs later), with a relation to `Tenant`.
- Amount columns are `BigInt` in Prisma (group CV reaches ₹500 crore); the service converts with a safe-integer check.

## Blocked

None.

## Known Issues / follow-ups

- Two API suites fail for reasons outside the program, checked in isolation on 31 Oct 2026: `reports.test.ts`
  ("the newest intake has not had 30 days yet") is a date-boundary case on the 31st of a month; `checkout.test.ts`'s
  two secret-scan tests need `git ls-files` and this working copy has no `.git`; `notificationDelivery.test.ts`'s
  1,200-message drain exceeds its 20 s budget on this machine (an email-worker throughput test, untouched by MLM-003).
- The dev database's seeded academy is still named "ShubhLMS" (seeded before the rename); `seed:demo` rewrites it.
- The plan page lists versions with the program LMS by id only; a name joins once members (MLM-001) bring the academy.
