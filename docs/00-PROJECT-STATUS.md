# 00 — Project Status (execution tracker)

This file is the single source of truth for what is done, what is in progress and what is next.
It is updated after every meaningful implementation step. Module detail lives in `docs/modules/*.md`.

**Project:** ZuviloAI — one centralized learning platform that sells its own courses, with a 2-leg affiliate program.
**Stack:** React 18 + Vite (`apps/web`) · Express + Prisma/SQLite + JWT (`apps/api`) · shared domain rules (`packages/domain`) · Flutter (`apps/mobile`).
**Mode:** the frontend runs against the real API when `VITE_API_MODE=http`; `mock` (the original in-memory demo) remains available and untouched.

**PROJECT STATUS: COMPLETED** (F0–F19, 18 Sep 2026) — every module in the table below is `COMPLETED`; deployed and live at `zuviloai.com`.

**Since then (as of 29 Oct 2026):** the SaaS track SAAS-000…031 is built (SAAS-016 and SAAS-017 blocked on a human; see the table
below), the Flutter app is built and device-verified (see *Mobile app*), and October brought invitations, email-verified
registration, quiz sessions, the built-in live room, course sales, platform branding and the launch hardening (see *Added after
the SaaS record*). Production launch items are tracked in `14-LAUNCH-CHECKLIST.md`. Schema: 81 models, 45 migrations.

## Platform conversion (1 Nov 2026)

The multi-tenant SaaS became one platform. The account is `16-PLATFORM-CONVERSION.md`, and the build record is `.claude/platform/progress.md`.

| Module | State |
| --- | --- |
| PLAT-000 to PLAT-002 (audit, backend core, registration) | `COMPLETED` |
| PLAT-003 (workspaces, website management, support) | `COMPLETED` |
| PLAT-004 (course sales, coupons, refunds) | `COMPLETED` |
| PLAT-005 (MLM-004 to MLM-008 earnings) | `COMPLETED` |
| PLAT-006 (public website) | `COMPLETED` |
| PLAT-007 (Flutter) | `BLOCKED`: no Flutter toolchain on this machine, so only small navigation edits were made, unverified. MLM-010 not built |
| PLAT-008 (verification) | See `.claude/platform/progress.md`. The rollout rehearsal on a copy of production needs that copy |

Nothing has been deployed to production.

## Status legend

`NOT_STARTED` · `IN_PROGRESS` · `BLOCKED` · `TESTING` · `COMPLETED`

A module is `COMPLETED` only when its database, backend, API, frontend integration and tests all meet the checklist in `02-MODULE-MASTER-LIST.md`.

## Module status

| Module | UI | Backend | API | Integration | Testing | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Foundation & security base | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Authentication | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Roles & permissions | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Students | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Instructors | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Categories | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Courses | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Curriculum (chapters) | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Lessons & media | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Enrollments | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Learning progress | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Quizzes | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Assignments | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Certificates | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Live classes | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Calendar | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Notifications | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Settings | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Reports | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Dashboard | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Help centre | ✅ | ✅ | ✅ | ✅ | ✅ | COMPLETED |
| Security hardening | — | ✅ | ✅ | — | ✅ | COMPLETED |
| Testing (suite) | — | — | — | — | ✅ | COMPLETED |
| Deployment / production readiness | — | ✅ | ✅ | ✅ | ✅ | COMPLETED |

✅ done · 🟨 exists but incomplete (see the module file for exactly what is missing) · ⬜ not started · — not applicable

**Not in this project** (no UI, no data, no requirement — see `02-MODULE-MASTER-LIST.md`): orders, payments, coupons, course reviews/ratings submission, standalone user management.

## Audit summary (17 Sep 2026)

What exists and works (verified in the browser against the real API): auth (register/login/me), every service group in `apps/web/src/services/contracts.ts` has a real route file and HTTP client, seed data, 119 passing tests.

What the audit found missing or wrong — the roadmap below fixes all of it:

1. **Trusting the client.** Instructor scope comes from a query-string `scopeInstructorId` instead of the token; quiz attempts accept a client-computed `percent`/`passed`; the frontend's `useWorkspace` uses the *mock* persona's instructor id even in `http` mode.
2. **Ownership checks (IDOR).** Learner certificate claim/detail, notification read/remove/settings, calendar update/delete, learner assignment detail/submit and lesson content are fetched by id without checking the caller owns/is enrolled in them.
3. **Wrong foreign keys.** Notifications, notification settings and calendar reminders are keyed on `Student.id`, but the UI sends `User.id` — and instructors/admins have no `Student` row, so in `http` mode their notification centre and reminders cannot work.
4. **Business rules not enforced.** Course completion never creates a certificate; academy settings (completion threshold, course-completion rule, chapter gating, quiz attempt limits, late policy, enrollment policy, access length, max instructors, review-before-publish, certificate auto-issue/min score/public verification) are stored but ignored; chapter/quiz locking is not computed; assignment drafts are not persisted; notifications are never generated by events.
5. **Thin analytics.** Reports, instructor and student profiles, learner home and the dashboard return hard-coded `0`, `null` or `[]` for many fields the UI renders (previous-period figures, pass rates, trends, cohorts, study time, recent lessons, upcoming items, activity feeds).
6. **No migrations, uploads, hardening, or deployment config.** Schema is applied with `db push`; uploads are simulated in the browser; no helmet/rate limiting/body validation; no Dockerfile/nginx/PM2; API tests cover auth only.

## Roadmap (dependency order)

| # | Phase | Depends on | Status |
| --- | --- | --- | --- |
| F0 | Foundation: schema fixes (User-keyed notifications/calendar, drafts, lesson access time), Prisma migrations baseline, error mapping, request validation, security middleware, seeded test DB + test helpers | — | COMPLETED |
| F1 | Authentication: forgot/reset password with outbox, 401 handling, route guard, real instructor scope in `useWorkspace` | F0 | COMPLETED |
| F2 | Roles & permissions: server-derived instructor scope everywhere, learner ownership checks, permission tests | F1 | COMPLETED |
| F3 | Students: complete profile/progress figures, message → notifications | F2 | COMPLETED |
| F4 | Instructors: real performance figures, activity, invitation email | F2 | COMPLETED |
| F5 | Categories · Courses · Curriculum · Lessons · Media: body validation, lesson↔quiz/assignment mirroring, real upload endpoint, max-instructors / review-before-publish rules | F2 | COMPLETED |
| F6 | Enrollments & Learning progress: policy & access length, chapter/quiz gating, completion threshold & rules, recent/upcoming/week, drafts, server-side quiz scoring & attempt limits, certificate eligibility | F5 | COMPLETED |
| F7 | Quizzes: attempt storage, stats, list metadata | F6 | COMPLETED |
| F8 | Assignments: missing count, late policy, review → notifications, resubmission | F6 | COMPLETED |
| F9 | Certificates: creation on completion, credential id from settings, hours/score, working-towards records, ownership | F6 | COMPLETED |
| F10 | Live classes: register/remind → notifications, learner scoping | F6 | COMPLETED |
| F11 | Calendar: real deadlines/learners due, ownership, quiz/milestone details | F10 | COMPLETED |
| F12 | Notifications: event engine + channel preferences + email outbox | F8, F9, F10 | COMPLETED |
| F13 | Settings: enforced across modules, `updatedBy` names | F12 | COMPLETED |
| F14 | Reports: real previous-period, pass rates, trends, segments, cohorts | F13 | COMPLETED |
| F15 | Dashboard: real events, attention items, attendance | F14 | COMPLETED |
| F16 | Security hardening pass + `09-SECURITY.md` checklist verified | F15 | COMPLETED |
| F17 | Testing: per-module API/permission/validation suites, E2E workflow script | F16 | COMPLETED |
| F18 | Deployment: production build served by the API, CloudPanel/PM2 scripts, env docs, live at zuviloai.com | F17 | COMPLETED |
| F19 | Final audit (TODOs, mock data, dead code, console errors) + final docs | F18 | COMPLETED |

### Next phase — SaaS subscriptions (separate track)

The subscription screens shipped as a UI-only prototype (`LMS-019`); the real system — tenants,
plans, entitlements, billing, webhooks and usage enforcement — is specified in
`.claude/saas/subscriptions.md` and broken into 17 modules in `.claude/saas/modules.json`
(`scope: FULL_STACK`, SAAS-000 → SAAS-016). It is deliberately outside the F-series above and
outside the UI-only workflow: it changes the tenant model, authorization and the payment path, so it
starts only when that scope is explicitly permitted.

That scope was permitted and the track has started (record: `.claude/saas/progress.md`):

| Module | Name | Status |
| --- | --- | --- |
| SAAS-000 | Tenant Foundation — `Tenant` table, `tenantId` on every academy-owned table, backfill to Tenant #1, fail-closed query scoping, tenant context from the account, `npm run tenants:verify` | COMPLETED (21 Sep 2026) |
| SAAS-001 | Plan Tables & Versioning — `Plan` (unique code, draft/active/archived) with commercial terms in append-only `PlanVersion` rows (database triggers), `src/lib/plans.ts`, every amount in integer paise (`packages/domain/src/money.ts`) | COMPLETED (21 Sep 2026) |
| SAAS-002 | Feature Catalogue & Limits — the §4 catalogue in `packages/domain/src/entitlement.ts` mirrored to `Feature` / `LimitDefinition`, per-version `PlanFeature` / `PlanLimit` grants sealed by triggers, the §42 enforcement matrix as checked data, a lint rule against plan-name checks | COMPLETED (21 Sep 2026) |
| SAAS-003 | Entitlement Service — `src/lib/entitlements.ts` (`getTenantEntitlements`, `hasFeature`, `getLimit`, `getUsage`, `canConsume`), `requireFeature` after the permission guard on authoring and report routes behind `ENTITLEMENT_ENFORCEMENT`, stable error codes (`PERMISSION_DENIED` vs `FEATURE_NOT_INCLUDED` / `SUBSCRIPTION_REQUIRED`) | COMPLETED (21 Sep 2026) |
| SAAS-004 | Subscription Model & State Machine — academy-owned `Subscription` (holds the plan version and its price) and the append-only `SubscriptionEvent` log; the seven statuses and named transitions in `packages/domain/src/lifecycle.ts`, enforced by the service and by database triggers; one live subscription per academy; the subscription is the entitlement service's plan source | COMPLETED (21 Sep 2026) |
| SAAS-005 | Trials & Grace Period — the server's clock as the only clock (no service takes a time), trial dates fixed by trigger, one trial per academy unless `SUBSCRIPTION_REPEAT_TRIALS=on`, a grace period after retries are exhausted whose length is `SUBSCRIPTION_GRACE_DAYS` and whose window only its transition can write | COMPLETED (21 Sep 2026) |
| SAAS-006 | Upgrade, Downgrade, Cancellation & Reactivation — decisions D7–D10: prorated upgrades and monthly → annual credit in integer paise, applied only on a confirmed provider payment; downgrades at the period boundary with limit conflicts reported and no data removed; server-computed pauses of at most 30 days that extend the period; cancel/resume records; append-only `PlanChange` quotes; period dates writable only by a recorded transition | COMPLETED (21 Sep 2026) |
| SAAS-007 | Money, Tax & Currency — the integer tax calculator (`packages/domain/src/tax.ts`, basis points, inclusive or exclusive, several components) and `divideRounded`; tax rules as append-only platform data by country and region; academy billing profiles; server-only payable amounts (`src/lib/billing.ts`); a second currency needs no schema change | COMPLETED (22 Sep 2026) |
| SAAS-008 | Payment Records & Invoices — invoices issued from the server's payable amount with unique `INV-YYYY-NNNNNN` numbers, fixed at issue; payments immutable once settled, recorded only from provider events and idempotent; refunds as separate rows capped at what was paid; payment methods as provider references with masked display data; no card-data column anywhere | COMPLETED (22 Sep 2026) |
| SAAS-009 | Payment Provider Abstraction — `PaymentProvider` interface with one adapter, Razorpay (REST over HTTPS, no SDK, keys from the environment); §43 checkout that prices from the invoice and activates only on the provider's own account of the payment; §44 failure to past due; refunds through the provider. **Extended 23 Sep 2026:** an academy's self-service first purchase (`POST /tenant/billing/purchase`), creating the subscription only from the provider-confirmed payment of its first-purchase invoice | COMPLETED (22 Sep 2026; extended 23 Sep) |
| SAAS-010 | Webhooks & Idempotency — `POST /webhooks/:provider/subscription`: raw-body signature check (unsigned → 401, nothing stored), payload validation, one `WebhookEvent` per provider event (a duplicate repeats nothing, a replayed body is ignored, racing deliveries never process together), state moved by the owning services with every step safe to retry; Super Admin receipt list | COMPLETED (22 Sep 2026) |
| SAAS-011 | Usage Tracking & Enforcement — every limit live-counted inside a transaction that first takes the academy's `UsageGuard` row, so concurrent requests cannot overshoot; limit gates on sign-up, instructors, courses (create and restore), staff uploads, live classes (per month) and admins; restricted mode per a written policy (keep and edit what exists, add nothing) — all behind `ENTITLEMENT_ENFORCEMENT` | COMPLETED (22 Sep 2026) |
| SAAS-012 | Background Jobs — the eight §30 jobs (plus pause expiry) on the existing every-minute scheduler, each academy's in its own context: trial expiry, renewal invoices at the next period's price, the period boundary (downgrade, then renew or past due), past-due recovery and grace, grace expiry, scheduled cancellation, usage report, webhook retry. Each idempotent, retryable and observable. | COMPLETED (22 Sep 2026) |
| SAAS-013 | Platform & Tenant APIs — Super Admin plans, subscriptions, invoices, payments, refunds and tax rules; Tenant Admin `/tenant` subscription, usage, entitlements, plans, upgrade and downgrade quotes, cancel and resume, invoices, payments, billing profile; every refusal carries a documented code with no provider or database detail | COMPLETED (22 Sep 2026) |
| SAAS-014 | Audit & Observability — every §36 action written in the same transaction as its change, naming a person, the scheduler (`system`, with the job) or the provider (`provider`); the audit trail append-only in the database; redacted signal lines for payment, refund, webhook, job and request failures, subscription state changes, entitlement refusals and limits, with a Super Admin failure window; a log sweep test finds no secret, card number, password or token | COMPLETED (22 Sep 2026) |
| SAAS-015 | Frontend Integration — the platform subscription screens read the billing API's own read models (`/superadmin/billing-views/*`, figures computed and history replayed on the server) and change through the billing endpoints; the academy admin's `/admin/billing` page (§24); every §34 refusal shown as a state; the demo note only in mock mode | COMPLETED (22 Sep 2026) |
| SAAS-016 | Hardening, migration verification and rollout — §47 security suite; migrations verified from empty and in place; production-mode rehearsal against Razorpay test mode (real payments, a real failure, recovery, webhook retries); SaaS screens crawled clean; `BILLING_JOBS` rollout switch; staged rollout plan | BLOCKED — needs a staging deployment and the Razorpay webhook configured on it; see `.claude/saas/progress.md` › Blocked |
| SAAS-017 | Multi-gateway payments & runtime gateway configuration — gateways configured by the Super Admin at `/superadmin/payment-gateways`, credentials AES-256-GCM-encrypted in `PaymentGatewayConfig` under the deployment's `PAYMENT_CREDENTIALS_KEY` (nothing in env or source); a registry and factory with one active gateway for new invoices and the recorded gateway for every existing invoice, order, webhook and refund, held by the database; Razorpay adapter from stored credentials with a no-charge credential test; see `docs/modules/payment-gateways.md` | BLOCKED — VyaparGateway's API contract is not published; see `.claude/saas/progress.md` › Blocked |
| SAAS-018 | Learner Assessment Integrity — no learner response carries a quiz's answer key; `GET /learning/…/quiz-attempts` returns reviews cut to `showResults`; hand-ins must fit the assignment's format and word limit and name only the learner's own uploads. Quiz time limits need an exam-mode product decision | COMPLETED (23 Sep 2026) |
| SAAS-019 | Academy Lifecycle & Provisioning — transactional provisioning (tenant, owner admin, settings, starter levels and ranks, default certificate template); Super Admin create, read, update, suspend, reactivate, archive, users, subscription, usage; academy status enforced on every request and at sign-in | COMPLETED (23 Sep 2026) |
| SAAS-020 | Sessions — server-side sessions named in the token; logout, logout-all, session list and revoke; change password and reset end sessions; profile (name) update. Also fixed two concurrency bugs (usage guard, lazy settings) | COMPLETED (23 Sep 2026) |
| SAAS-021 | Notification Delivery — email worker behind a transport abstraction (claims, backoff, final status, 10-minute dedup); device tokens bound to sessions; push hints via FCM HTTP v1 when configured, honouring preferences and quiet hours. Live SMTP and FCM need credentials | COMPLETED (23 Sep 2026) |
| SAAS-022 | Job Leases — every scheduled job under a database lease, so several processes never run one job at once; lease state on `GET /superadmin/system` | COMPLETED (23 Sep 2026) |
| SAAS-023 | Media Security — file reads follow what the reader may open (enrolment, teaching scope); content-signature checks on upload; safe download header | COMPLETED (23 Sep 2026) |
| SAAS-024 | Backend Audit & Documentation — `routeAudit.test.ts` audits every mounted route (authentication, role refusals, malformed queries); six 500s on malformed queries fixed; 15 untested routes covered; billing test matrix; `docs/12-ENDPOINT-AUDIT.md`; `apps/api/README.md` | COMPLETED (23 Sep 2026) |
| SAAS-025 | Entitlement Enforcement Readiness & Enablement — instructor activation takes a seat under the usage guard; restricted mode keeps only last-plan features; explicit category policy (`requireUnrestricted`); feature delivery kinds (`route`/`service`/`planned`); permission ⟂ plan proven; full API suite green with enforcement on; enforcement enabled in development | COMPLETED (23 Sep 2026) |
| SAAS-026 | Self-Serve Admin Registration & Public Plans — `PendingSignup`; `POST /signup/start\|resend\|verify` with a 6-digit emailed code (D27); `GET /public/plans`; `MAIL_TRANSPORT=smtp`; the `/get-started` wizard and `/admin/welcome` | COMPLETED (3 Oct 2026) |
| SAAS-027 | SaaS Marketing Website & Contact Sales — `Inquiry`, `POST /public/inquiries`, Super Admin inbox (`/superadmin/inquiries`); the company site: home, features, solutions, pricing, how it works, about, FAQ, contact, privacy, terms | COMPLETED (3 Oct 2026) |
| SAAS-028 | Admin-Created Learners & Academy Join Links — `lib/learners.ts` behind `POST /auth/register`, `POST /public/academies/:slug/register` and `POST /students`; `GET /public/academies/:slug`; `/join` and `/join/:slug` | COMPLETED (3 Oct 2026) |
| SAAS-029 | Client-Centric Super Admin & Support Inbox — `POST/GET /tenant/support`, `/admin/support`; Super Admin presents academies as Admins (clients) | COMPLETED (3 Oct 2026) |
| SAAS-030 | Sandbox Payment Gateway — `PAYMENT_SANDBOX=on` while no real gateway is active, refused in production; drives checkout success, failure and cancellation in browser E2E | COMPLETED (3 Oct 2026) |
| SAAS-031 | Multi-Admin Live E2E & Isolation QA — admin-first wording (D30), `POST /auth/register { workspace }` (D32), isolation and enforcement cannot be switched off by accident in production (D31), suspended/closed accounts told why (D33); `e2e/multiadmin.spec.ts` | COMPLETED (3 Oct 2026) |

## Added after the SaaS record (October 2026)

Built outside the numbered workflows under the owner's direction, with migrations in `apps/api/prisma/migrations/`.
Each is in the code and in `05-API-SPECIFICATION.md`; the audit that reviewed them is `14-LAUNCH-CHECKLIST.md`.

| When · migration | What | Where |
| --- | --- | --- |
| early Oct (no migration) | Account deletion: `POST /auth/delete-account` (the signed-in person, with their password) and the web's `/delete-account` page, which the Play listing requires | `routes/auth.ts`, `deleteAccount.test.ts` |
| 5 Oct · `20261005120000_invitations` | Learner invitations: an Admin invites one learner by email; `/invite/:token` registers or signs in into that Admin's workspace; revocable; only the token's hash is stored | `routes/invitations.ts`, `lib/invitations.ts`, `routes/publicSite.ts`, `invitations.test.ts` |
| 9 Oct · `20261009120000_course_cover_image` | Course cover images as uploaded media (`Course.coverImageId` → `MediaAsset`) | `routes/courses.ts`, `courseCover.test.ts` |
| 10 Oct · `20261010120000_platform_branding` | Platform logo and favicon uploaded by the Super Admin (`PlatformBrandAsset`), served at `/public/branding`; the built-in asset when none is stored | `routes/branding.ts`, `lib/branding.ts`, `/superadmin/branding` |
| 14 Oct · `20261014120000_quiz_sessions` | Quiz sessions: the server starts an attempt (consuming it), holds its deadline (`timeLimit`) and answer sheet, and finishes it on submit, in the grace after the deadline, or by the scheduler once expired. Closes the "quiz time limits not enforced" gap left by SAAS-018 | `lib/quizSessions.ts`, `packages/domain/src/quizSession.ts`, `/learning/…/quiz-session`, `quizSessions.test.ts` |
| 15 Oct · `20261015120000_live_room_sessions` | Built-in live room (Jitsi Meet for trials, 8x8 JaaS in production): the host starts, learners join with signed tokens, the host ends and attendance settles; JaaS recordings are kept under `UPLOAD_DIR/live-recordings` for `LIVE_RECORDING_DAYS` | `lib/liveRoom.ts`, `lib/liveSessions.ts`, `routes/live.ts`, `POST /webhooks/jaas`; `modules/live-classes.md` |
| 23 Oct · `20261023120000_pending_accounts` | Email verification for every self-registration door (join link, invitation, course link, host sign-up, request to teach): a `PendingAccount` holds the hashed password and code; nothing that can sign in exists until the code is confirmed. Instructor requests (`/join/:slug/teach`) create a `pending` instructor an admin approves (D34). An academy whose enrolment policy is `invite` takes learners by invitation only | `lib/pendingAccounts.ts`, `lib/instructorRequests.ts`, `lib/verificationCode.ts`, `/public/verifications/*`, `emailVerification.test.ts`, `instructorRequests.test.ts` |
| 23 Oct (no migration) | Launch hardening: GitHub push → `deploy.sh` webhook, `/health` checks the database, graceful shutdown, `deploy/backup.sh`, a database backup before every migration, Android App Links at `/.well-known/assetlinks.json`, `robots.txt` and `sitemap.xml`, the `/refunds` page and company identity on the site, the demo seed refusing production (`prisma/seedGuard.ts`), test-mode gateways taking no production payment | `routes/deploy-webhook.ts`, `lib/appLinks.ts`, `apps/api/src/web.ts`, `deploy/`; `14-LAUNCH-CHECKLIST.md` |
| 24 Oct · `20261024120000_course_purchases` | Course sales: a learner buys a paid course and the money settles to the academy's own Razorpay account (`AcademyPaymentConfig`, `AcademyGatewayCredential`, encrypted under `PAYMENT_CREDENTIALS_KEY`). `CoursePurchase` opens the enrolment once, on the gateway's own confirmation (browser confirm, signed webhook `POST /webhooks/academies/:tenantId/razorpay/courses`, status check or the `checkout-recovery` job). Prices are all-inclusive; a course with no admin-chosen price is not for sale | `lib/coursePurchases.ts`, `lib/academyPayments.ts`, `routes/courseSales.ts`, `/tenant/course-sales/*`, `coursePurchases.test.ts`, `e2e/coursePurchase.spec.ts` |
| 28 Oct | Per-account sign-in throttle (`RATE_LIMIT_ACCOUNT_MAX`); payment edge cases (a refund with no definite answer stays `pending`; the renewal job no longer marks past due what a payment renewed meanwhile; a declined early renewal does not start dunning early); email hygiene (codes and links sent before any backlog, bodies blanked 7 days after delivery) | `14-LAUNCH-CHECKLIST.md` A14, A18, A19 |

## Mobile app (Flutter) — status

`apps/mobile` is built: FLUTTER-000…027, 029 and 031 are complete (record: `.claude/flutter/progress.md`, last updated
3 Oct 2026). FLUTTER-028 part B (push delivery) was blocked on a Firebase project (C8), and FLUTTER-030 Final Hardening &
Release waits on it and on the owner's release decisions (application id, signing, crash reporting, store upload).
Since that record the tree gained Firebase (core, messaging, crashlytics, analytics, auth, database, storage),
`razorpay_flutter`, `jitsi_meet_flutter_sdk`, `webview_flutter`, `flutter_local_notifications`, the live room, course
purchases (checkout kept off in the app on `zuviloai.com`), the email-code registration step, the staff UI redesign
(`apps/mobile/docs/ui-redesign-checklist.md`, 22 Oct) and version `1.1.1+5`; the progress record has not been brought up to
date with that work. Store upload is a human action (`apps/mobile/store/PLAY_CONSOLE.md`); the Play upload key is
registered. Release-gating items are `14-LAUNCH-CHECKLIST.md` A9 and B2.

## Environment requirements (current)

- Node ≥ 20, npm workspaces. Flutter 3.38 / Dart 3.10 and JDK 17 for `apps/mobile`.
- `apps/api/.env`: the full table with defaults is in `10-DEPLOYMENT.md` and `apps/api/.env.example`. Production must set
  `DATABASE_URL`, `JWT_SECRET` (≥ 32 random chars; the API refuses to start otherwise), `CORS_ORIGIN`, `APP_URL`,
  `NODE_ENV=production`, `UPLOAD_DIR`, `TRUST_PROXY`, `WEB_DIST`, `PAYMENT_CREDENTIALS_KEY`, `SUBSCRIPTION_RETRY_DAYS` and
  `SUBSCRIPTION_GRACE_DAYS` (required while `ENTITLEMENT_ENFORCEMENT` is on, which it is by default in production), and
  `MAIL_TRANSPORT=smtp` with `SMTP_*`/`MAIL_FROM` before opening registration. Optional: `PUSH_PROVIDER`/`FCM_SERVICE_ACCOUNT`,
  `JAAS_*` (the live room in production), `DEPLOY_WEBHOOK_SECRET`/`DEPLOY_BRANCH`, `ANDROID_APP_LINK_SHA256`,
  `PAYMENT_SANDBOX` (never in production), `TEST_OTP_*` (development only).
- Database: `npm run prisma:deploy` (never resets), then `npm run seed:platform` anywhere and `npm run seed:demo` in
  development only. `npm test` rebuilds `prisma/test.db`; `npm run e2e` uses `prisma/e2e.db`.
- `apps/web/.env`: `VITE_API_MODE=http`, `VITE_API_BASE_URL`.
- `apps/mobile/config/*.json`: public values only, one per flavour; `BILLING_CHECKOUT_ENABLED` and `COURSE_CHECKOUT_ENABLED`
  are `false` for any config that reaches `zuviloai.com`, pinned by a test.
- Production only: `WEB_DIST` makes the API process serve the built web app with the API under `/api` (the host's vhost
  forwards every path to one port); `TRUST_PROXY` measured, not assumed. Full runbook in `10-DEPLOYMENT.md`.

## Test status (current)

Suites in the tree (29 Oct 2026):

| Suite | Where | Size |
| --- | --- | --- |
| Domain rules | `packages/domain/src/*.test.ts` | 14 files |
| Web services and UI logic | `apps/web/src/**/*.test.ts` | 72 files |
| API integration (routes and lib; `routeAudit.test.ts` walks every mounted route) | `apps/api/src/**/*.test.ts` | 82 files |
| End to end | `apps/web/e2e/*.spec.ts` (`npm run e2e`, own `prisma/e2e.db`) | 18 specs |
| Mobile | `apps/mobile/test/` (host), `integration_test/` (device), `tool/live_e2e/` (live UI scenarios) | 177 host test files, 25 integration tests |

Last recorded full runs:

- 3 Oct 2026 (SAAS-031): API 797 · web 392 · domain 148 · E2E 28/28 · typecheck, lint, build, format green.
- 3 Oct 2026 (FLUTTER-031): 2,030 host tests pass, plus one pre-existing `no_secrets_test` failure caused by Firebase keys
  in `firebase_options.dart`/`google-services.json`; device integration auth 5/5, entitlements 3/3; live layer C scenarios pass.
- 23 Oct 2026 (launch audit): new API tests and `e2e/journeys.spec.ts`, `e2e/courseCreation.spec.ts` added; suites reported
  green in `14-LAUNCH-CHECKLIST.md`.

Counts were not re-run for the 29 Oct documentation refresh (that checkout had no `node_modules`).

### Earlier records

Environment requirements (F19, 18 Sep 2026):

- Node ≥ 20, npm workspaces.
- `apps/api/.env`: `DATABASE_URL` (SQLite file), `JWT_SECRET` (≥ 32 random chars in production — the API refuses to start otherwise), `JWT_EXPIRES_IN`, `PORT`, `CORS_ORIGIN`, optional `APP_URL` (links in emails), `MAIL_TRANSPORT` (`outbox` | `log`), `UPLOAD_DIR` (default `apps/api/uploads`), `TRUST_PROXY`, `RATE_LIMIT_MAX`, `RATE_LIMIT_AUTH_MAX`, `RATE_LIMIT_WINDOW_MS` (see `apps/api/.env.example`).
- Database: `npx prisma migrate deploy` (or `npm run prisma:migrate` in development) then `npm run seed`.
- `apps/web/.env`: `VITE_API_MODE=http`, `VITE_API_BASE_URL`.
- Production only: `WEB_DIST` makes the API process serve the built web app with the API under `/api` (the host's vhost forwards every path to one port); `PORT=3700`, `TRUST_PROXY=2` behind Cloudflare + CloudPanel nginx. Full runbook in `10-DEPLOYMENT.md`.

Test status (F19, 18 Sep 2026):

- `packages/domain`: 31 unit tests — pass.
- `apps/web`: 84 tests (mock services, formatting, command registry, the `?next=` guard) — pass.
- `apps/web` E2E: 5 Playwright specs against the real API (`npm run e2e`) — pass; run 6 times across F17/F19, 5 clean and one single-test timing flake (the roster table's skeleton row racing its real rows), fixed by asserting row count with `expect(...).not.toHaveCount(0)` instead of a one-shot `.count()` read.
- `apps/api`: 112 integration tests (auth incl. forgot/reset, catalog, role guard, foundation, permissions, students, instructors, catalog rules + media, learning, quizzes, assignments, certificates, live classes, calendar, notifications, settings, reports, dashboard, query validation, serving the web app under `/api`, help centre) — pass against a seeded `test.db` rebuilt by `pretest`.
- Browser check (Playwright, http mode): route guard, `?next=` return, workspace redirects, admin notifications, forgot → outbox → reset → sign-in — all pass, no console errors.
- Production check (Playwright against https://zuviloai.com, 18 Sep 2026): admin, instructor and student sign-in, dashboards, reports and the lesson player render seeded data with no console errors and no failed or 4xx/5xx requests.

## Change log

- 17 Sep 2026 — Documentation system created from the code audit; roadmap F0–F19 defined.
- 17 Sep 2026 — **F0 complete.** Prisma migrations baseline (`20260917144129_init`); notifications, notification settings and calendar events keyed on `User.id` (staff can use them); `AssignmentDraft`, `LessonProgress.lastAccessedAt`, `Enrollment.expiresAt`, `QuizAttempt.durationSec` columns; `zod` request validation helpers; Prisma/body-parser error mapping; `helmet` + rate limiting + 1 MB body limit; scope helpers (`lib/scope.ts`); public registration can no longer choose a role; seeded `test.db` rebuilt by `pretest` with shared test helpers; web HTTP clients stop sending recipient/owner ids.
- 17 Sep 2026 — **F1 complete.** `POST /auth/forgot-password` (hashed single-use 1-hour tokens, older links invalidated, identical response for unknown emails), `GET /auth/reset-password/:token`, `POST /auth/reset-password`; `EmailOutbox` table + `queueEmail` (`MAIL_TRANSPORT=outbox|log`); production refuses the dev `JWT_SECRET`; web: 401 clears the token and drops to signed-out, `RequireSession` guard (`/login?next=`, workspace redirects), `/reset-password/:token` page, forgot modal calls the API, `useWorkspace` uses the signed-in instructor id.
- 17 Sep 2026 — **F2 complete.** Instructor scope comes from the token everywhere (`lib/scope.ts`: `courseScopeWhere`, `assertCourseAccess`, `assertQuizAccess`, `assertAssignmentAccess`, `assertSubmissionAccess`, `assertLiveAccess`, `assertCertificateAccess`, `assertStudentAccess`, `studentScopeWhere`); chapters/lessons routers check the course at mount; out-of-scope ids answer 404; instructors cannot remove themselves from their courses; reports/dashboard ignore query overrides for instructors; `GET /courses/:id`, `/quizzes/:id`, `/assignments/:id`, `/live/:id`, `/certificates/:id`, `/settings` are staff-only. Learners: lesson bodies stripped unless enrolled (free previews kept) — also in the public catalog; drafts invisible; complete/position/note/bookmark/quiz-attempt/assignments/drafts/submit require enrollment; certificates and claims are owner-only and claim needs `pending`; live registration needs enrollment. 12 permission tests; browser sweep of every staff and learner screen passes.
- 17 Sep 2026 — **F3 complete.** `lib/notify.ts` (`notify`, `notifyMany`: in-app row + outbox email, honouring per-category channel preferences, pause and the locked `system` category) and `lib/study.ts` (study minutes, 12 study weeks, next lesson). Student profile/progress/activity now carry real `studyMinutes`, `studyWeeks`, `lastLessonTitle`, quiz `courseTitle`, `avgScore` as % of max, published-only lesson counts, and are limited to the instructor's courses; `POST /students/message` sends real notifications/emails to in-scope learners. 5 student tests.
- 17 Sep 2026 — **F4 complete.** Instructor list carries completion; the profile computes course level/lessons/active learners/completion, reach incl. new-this-month and cities, own vs academy rating and completion, review median hours / on-time share, live delivered/upcoming/attendance, eight months of enrollments and a real activity feed. Every instructor profile has a sign-in account; invitations and resends queue an `instructor-invite` email with a 7-day set-password link (`lib/passwordReset.ts` shared with forgot-password); edits keep the account in sync; `inactive` instructors cannot sign in. 4 instructor tests.
- 17 Sep 2026 — **F5 complete.** `zod` schemas on categories/courses/chapters/lessons (400, unknown keys dropped); unique category names and course titles (409); `settings.courses.maxInstructors` (409), `requireReview` (403 for instructors), defaults for format/visibility/language, lesson duration and first-lesson preview; `lib/lessonLinks.ts` mirrors the delivering quiz/assignment into `content.quiz`/`content.assignment` on every read; quizzes/assignments accept `lessonId` (type + uniqueness checks), cannot be deleted while delivered, and are released when the lesson changes type or is deleted; `MediaAsset` + `POST /media/upload` (multer, MIME/extension allow-list, per-kind size limits, random names) + `GET /media/:id` streaming; web `services.media.upload` (XHR progress) behind `MediaDrop`, `?lesson=` links from the lesson editor into the quiz/assignment editors, command palette searches the real catalog. 8 catalog tests; browser check of a real upload, lesson-linked quiz and palette search.
- 17 Sep 2026 — **F6 complete.** `lib/learning.ts` (rules from settings, chapter/quiz gating with reasons, next lesson, course-completion rule, access expiry) and a rewritten `routes/learning.ts`: enrolment policy + `expiresAt` + lazy expiry, home feed (recent, upcoming with flags, 7 study days), instructor names/level everywhere, lesson visits recorded, `threshold` on the lesson view, per-rule completion (`watched` via threshold, `passed` via quiz, `submitted` via hand-in / practice notes), server-side quiz scoring from `answers` with attempt limits and retake wait, assignment drafts persisted and relative deadlines from chapter opening, live lesson data, certificates hook on completion. Web: quiz answers sent with attempts, server refusals shown. 7 learning tests; browser check of the learner flow.
- 17 Sep 2026 — **F7 complete.** Quiz bodies schema-validated; list rows carry `chapterTitle`; stats compute median minutes from stored `durationSec` (the quiz taker now reports how long an attempt took) and `commonWrongOptionId` from stored answers; quizzes cannot change course. 2 quiz tests.
- 17 Sep 2026 — **F8 complete.** Assignment and review bodies schema-validated; `acceptsLate`/`latePenalty` default from the academy's late policy; `reject` blocks late hand-ins, `penalty` deducts at grading, `accept` does not; list rows carry `chapterTitle` and a real `missing` count; the submissions list serves `filter=missing` rows; hand-ins notify the course's instructors, reviews notify the learner, reminders reach only learners who still owe the work; a graded pass completes a `passed`-rule lesson. 3 assignment tests.
- 17 Sep 2026 — **F9 complete.** `lib/certificates.ts`: certificates are created when a course completes (enabled, no duplicate, final score ≥ `minScore`), pending or auto-issued, with credential ids `<prefix>-<code>-<year>-<seq>`, hours from lesson minutes, final score from best quiz and graded assignment percentages, template from the course/setting/default; learners are notified on claimable/issued/revoked; working-towards records on the wallet and course page; verification hides pending certificates and respects `publicVerification`; issue/restore state guards; default template syncs the setting. 4 certificate tests.
- 17 Sep 2026 — **F10 complete.** Live-class bodies schema-validated; scheduling notifies enrolled learners, cancelling notifies registered learners, manual reminders report real deliveries; started/cancelled classes cannot be edited, cancelled/ended ones cannot be cancelled or registered for; `remindersSentJson` + `sendDueReminders` scheduler (every minute from `index.ts`, `LIVE_REMINDERS=off` to disable) sends each configured reminder offset once. 2 live tests.
- 17 Sep 2026 — **F11 complete.** Calendar bodies schema-validated and course-scoped; deadline rows carry real `due.learners`/`submitted` and the detail lists `learnersDue`; live rows carry `phase`, the detail `instructorTitle`, attendance and `audienceSize`; own events get `chapterTitle`, `instructorTitle`, `audienceSize`; `notifyMin` reminders go to the owner (and the course's learners for `learners` audience) once via the scheduler (`notifiedAt`), re-armed on edit. 2 calendar tests.
- 17 Sep 2026 — **F12 complete.** `notify()` honours the academy's `settings.notifications` switches (`switch`), per-category preferences, pause, and daily/weekly email digests (`lastDigestAt`); the detail reports real channels; new events: enrolment confirmations (self + staff), course ready-for-review → admins and published → instructors, default live reminders from settings; scheduled jobs (`lib/notificationJobs.ts`): digests, review-overdue notices (`overdueNotifiedAt`), daily enrolment summaries, inactivity nudges (`nudgedAt`), assignment due reminders. 5 notification tests.
- 17 Sep 2026 — **F13 complete.** Every settings field traced to its consumer (table in `modules/settings.md`): `atRiskDays` feeds learner statuses, lesson defaults (duration, completion, comments, downloads, preview) and the default price apply on create, the public catalog hides ratings below `minRatings`/when `showRatings` is off, `archiveInactiveMonths` drives a daily archiving job, `studyReminders` gates nudges, emails carry the sender identity, verification reports `validUntil`; `PUT /settings/:section` validates the section and records the admin's name. 4 settings tests.
- 18 Sep 2026 — **F14 complete.** `lib/reports.ts` holds the arithmetic every report tab shares: each enrolment becomes a study span, so a period and the equal period before it are measured the same way and every `Kpi.previous` is a real earlier reading rather than `0`. Progress at a past moment is rebuilt from `LessonProgress` timestamps (duration-weighted, as `courseProgress()` defines it) instead of the current `Enrollment.progress`; completion rate judges only enrolments that have had 60 days to finish; learner statuses use `deriveStudentStatus`'s rule with the academy's `atRiskDays`. Every tab now reports from records — overview KPIs, series and sparklines, quiz/assignment/engagement figures and live attendance; per-course category, instructors, active learners, quiz and assignment pass rates and an enrolment trend; the course tab's funnel, per-chapter reach, quizzes and assignments; the learner tab's segments, statuses, progress bands, search, sort and paging; per-instructor reach, completion, rating, review turnaround and attendance; and the enrolment tab's source split, categories and six monthly cohorts. The seed gained a year of history — 36 alumni with enrolments, lesson progress, attempts, reviewed hand-ins spread across the past twelve months, and six past live classes with attendance — because a report with no past cannot show a previous period, a cohort or a settled completion rate. Web: `services/http/reports.ts` sends `sort` as `sortKey`/`sortDirection`; as an object it serialised to `[object Object]` and the learner tab's sorting never reached the API. 10 report tests; every report screen checked in the browser at 1440 and 390 against the real API.
- 18 Sep 2026 — **F15 complete.** The staff dashboard reads every figure from records. Its four headline KPIs are read again at eight month-ends from the timestamps that made them true — a course counts as live from `publishedAt` until it was archived, a submission counts as waiting if it was handed in and not yet answered — so `previous` is a real earlier reading instead of the current one repeated. Engagement became a weekly count of lessons completed, quiz attempts, hand-ins and live-class attendances, each with the week before it, matching the screen's "This week" band; daily activity comes from lesson progress. Needs-attention now raises all five kinds the module defines: overdue reviews naming the course holding most of them, learners at risk by the academy's `atRiskDays`, a class at 90% of capacity, a draft untouched for six weeks, and published videos without captions. Recent activity became a real feed across seven kinds — enrolments with how the learner arrived, courses published, hand-ins, reviews, certificates earned, live classes scheduled and instructors joining — named after the people involved, replacing the placeholder "A learner enrolled in a course". Course performance covers published courses ordered by size, with the 60-day completion rule and eight weeks of enrolments. Seeded instructors now carry real joining dates, so the instructor KPI no longer reports the whole teaching staff as having arrived this month. Web: `useNow()` was anchored to the mock academy's fixed demo date in every mode, so in `http` mode every relative time on every screen was three days out and today's events read "in 3 days"; it now uses the real clock when `API_MODE` is `http` and keeps the demo anchor for the mock. 7 dashboard tests; admin and instructor dashboards checked in the browser at 1440 and 390 against the real API.
- 18 Sep 2026 — **F16 complete.** Every row of `09-SECURITY.md` checked against the running server, not just the code: helmet headers, no `x-powered-by`, a JSON 404, one allowed CORS origin, auth rate limiting (429 on the 30th attempt), and no `passwordHash` in any response. Two real gaps closed. **Query parameters were never validated** — only bodies were — so `?range=bogus` reached a lookup table and answered 500, `?segment=nonsense` was quietly honoured, `?page=abc` returned an empty list instead of a complaint, and `?pageSize=100000` handed back whole tables. Query strings are now parsed with `zod` across reports, dashboard, students, courses, live, certificates and submissions: a value outside a fixed set is a 400, ids and free text are bounded, and a page may be at most 500 rows (the largest any screen asks for). **An open redirect on sign-in**: `?next=` was checked with a rule that required a leading `/` and refused `//` but allowed `/\`, which a browser reads as `//` — so a crafted link would have carried a visitor off the site after signing in. The check now lives in `lib/safeNext.ts`, accepts a path on this site and nothing else, and is unit-tested; it was also driven in a real browser with protocol-relative, backslash and absolute values, all of which stay on the site. `npm audit`'s 7 advisories were each traced to what reaches production and recorded with a decision in `09-SECURITY.md`: the vitest and Prisma-CLI ones are development-only, and the react-router one is the open redirect above, now guarded regardless of the router version. 4 query-validation tests and 3 `safeNext` tests.
- 18 Sep 2026 — **F17 complete.** `apps/web/e2e/*.spec.ts` (Playwright) drives the real, built frontend against the real API for one student, one instructor and one admin flow — register/browse/enrol, sign in/grade a submission/view the roster, sign in/check the dashboard, roster and reports/save and reload a settings section — each a real write or read against the real seeded data, not a mock. `apps/web/scripts/run-e2e.mjs` (`npm run e2e`) reseeds the database, starts the API, builds and previews the frontend, runs the suite, and tears both servers down; it always reseeds because the instructor spec grades the seed's one waiting submission, which is not idempotent otherwise. Writing tests that select controls the way a screen reader would (`getByLabel`) surfaced two real bugs, not test artifacts: `components/ui/Field/Field.tsx` never associated its label with the real `<input>` on the three password fields with a show/hide toggle and the certificate share dialog's copy-link field, because each wraps the control in a `<div>` and Field only wires id/aria-describedby/aria-invalid onto a direct child — a screen reader announced the placeholder mask instead of "Password" or "Verification link"; `Field` now accepts an explicit `id` for this case, and `lib/fieldProps.ts` gives the four call sites the same wiring. And the dashboard's (F15) submission/review events linked to `/assignments/submissions/:id`, missing the `:assignmentId` segment the router requires, so every such link in "Recent activity" 404'd — `dashboard.test.ts` now asserts the correct shape. `08-TESTING-PLAN.md` records what the three specs cover and, as plainly, what they do not (quizzes, course publishing, certificates, live classes and notifications are not yet exercised end to end).
- 18 Sep 2026 — **F19 complete — final audit.** No TODOs/FIXMEs left in `apps/api/src` or `apps/web/src`; no stray `console.log`/`debugger` outside the two intentional ones (server boot line, `MAIL_TRANSPORT=log`). A route sweep of all three roles (54 routes, real ids) found no console errors, no failed requests and no broken pages — one apparent 404 (an instructor opening a learner outside their scope) turned out to be the intended, gracefully designed "Learner not found" state, not a bug. Three real defects found and fixed:
  - **Mock data unconditionally shown to real users.** `shell/AppShell.tsx`'s sidebar rank meter rendered the mock persona's fixed `rankStanding` fixture for every signed-in student in every mode, including `http` — a real learner's real rank progress was replaced by a stranger's hardcoded numbers. It now calls the real, already-built `GET /learning/rank-ladder` (`services.learner.getRankLadder()`, previously wired up and never called from a page) via `useAsync`, with a skeleton while it loads. Verified in the browser: two different real students now show different, real standings.
  - **A command-palette action that created nothing.** `shell/QuickCreateModal.tsx`'s "New course" / "Add chapter" / "New lesson" / "Schedule live class" all showed a "saved" toast and closed without ever calling the API — a straightforward instance of rule 13, "avoid dead buttons and fake functionality." Its `'course'` kind was additionally unreachable dead code (every real trigger bypasses it and navigates straight to the real course editor already). Rewritten as an honest, fast on-ramp: it fetches the caller's real courses, then hands off to the real curriculum panel, lesson editor or live-class scheduler — which own the actual validation and the actual write — rather than duplicating four creation flows inline. Verified via the command palette as a real instructor: real courses load, "Continue" lands on the genuine `/curriculum/chapters/new` route, no console errors.
  - **Two more fake-success toasts**, found by a systematic sweep of every `toast({ kind: 'success' })` call site for one that fires without a preceding real API call: the certificate "Prepare download" dialog claimed a specific `.pdf`/`.png` file had been produced when nothing was ever generated — now honest that this demo has no file renderer, and offers the one real capability a browser already has, `window.print()` → *Save as PDF*; and a live lesson's "remind me" button claimed a reminder was scheduled without calling anything — now calls the real, already-used-elsewhere `services.live.register()`, which is exactly what "we'll remind you" already means on the live classes list.
  - `help.ts` had no test file despite being a complete, real router (a gap the module doc had already flagged) — `help.test.ts` added: audience filtering, search, an unknown slug, related articles. 4 tests.
  - `README.md` rewritten to lead with current status and `docs/` as the source of truth, and to describe deployment and `npm run e2e` — the original UI-only quick-start moved to a "History" section rather than being presented as how to start today.
  - No orphaned files (every page, component, hook, lib and API route file is imported somewhere) and no duplicate component filenames.
- 18 Sep 2026 — **F18 complete.** Production is a CloudPanel host where the app runs as the site user with no root, and CloudPanel's Node.js vhost forwards *every* path of the domain to one port — so the API process now serves the built web app when `WEB_DIST` is set (`apps/api/src/web.ts`: API under `/api`, hashed assets cached a year, any other path answers `index.html`, boot refuses to start without a build). Two proxy hops were measured rather than assumed: a forged `X-Forwarded-For` arrives as `<forged>, <visitor>, <cloudflare edge>`, so `TRUST_PROXY=2` keys rate limits on the visitor. `deploy/bootstrap.sh` (site layout, read-only GitHub deploy key, clone, `.env` with a generated `JWT_SECRET`, `@reboot pm2 resurrect`) and `deploy/deploy.sh` (reset to the branch tip, `npm ci` gated by an install stamp, `prisma migrate deploy`, web build published by symlink swap, PM2 reload, `/api/health` and vhost check) replace the Docker/nginx plan; `.gitattributes` pins the scripts to LF because a CRLF shebang fails on Linux. The first deploy was seeded by `git push` over ssh into the server checkout (`SKIP_FETCH=1`) while the GitHub deploy key awaited registration; the demo academy is seeded and every role was driven in a real browser against the live site. 5 web-serving tests. Open items recorded in `10-DEPLOYMENT.md`: restrict the origin to Cloudflare's ranges in the CloudPanel firewall; the sign-in page's mock-era copy ("nothing you enter here is stored") is now wrong.
- 3 Oct 2026 — **SAAS-026…031.** Self-serve Admin registration with emailed codes and SMTP delivery, public plans, the company website and the contact/support inbox, admin-created learners and `/join/:slug`, the client-centric Super Admin, the sandbox gateway, the multi-admin live E2E and its fixes (decisions D21–D33). Record: `.claude/saas/progress.md`.
- 3 Oct 2026 — **FLUTTER-031.** Multi-admin sign-up (`workspace`), suspended/closed LMS handling, per-person session scoping in the app. Record: `.claude/flutter/progress.md`.
- 5–24 Oct 2026 — Invitations, course cover images, platform branding, quiz sessions, the built-in live room with recordings, pending-account email verification and instructor requests, course sales through the academy's own gateway. See *Added after the SaaS record*.
- 23 Oct 2026 — **Launch audit** (`14-LAUNCH-CHECKLIST.md`): company identity on the site, refund policy drafted, deploy webhook and daily backups, `/health` with a database check, the demo seed refusing production, email-code limits that hold under concurrency, the static test OTP refused on the live host, test-mode gateways taking no production payment, late-authorization handling, journey and course-creation E2E. Open: email DNS, GSTIN/CIN, a Razorpay staging run, the Play listing, CSP, MFA, off-server backups.
- 28 Oct 2026 — Per-account sign-in throttle; payment edge cases (pending refunds, renewal races, early-renewal declines); email hygiene.
- 29 Oct 2026 — **Documentation refresh.** `README.md`, this file, `02`, `03`, `04`, `05`, `06`, `07`, `08`, `09`, `10`, `14`, the quizzes/courses/students module docs and `apps/api/README.md` brought in line with the code: 73 models, 41 migrations, 34 web service groups, the October features, and the mobile app as built rather than planned.
- 31 Oct 2026 — **MLM affiliate program: architecture and gap analysis** (`15-MLM-AFFILIATE-ARCHITECTURE.md`, spec in `docs/specs/`). Proposal only; implementation (MLM-000…010) starts after the open decisions D-MLM-01…19 are approved.
- 31 Oct 2026 — **Rename: ShubhLMS → ZuviloAI, zuviloai.com** across code, docs, deploy and mobile (Android package id and the source logo file kept; see `README.md`). **MLM-000 Plan foundation** built: `MlmPlanVersion`/`MlmRankTier`/`MlmCapBand`, `lib/mlm/plan.ts`, `/superadmin/affiliates/plan*`, `seed:mlm-plan`, the Super Admin plan pages. Record: `.claude/mlm/progress.md`.
- 31 Oct 2026 — **MLM-001 Affiliates & registration** built: `Affiliate` table, check-digited referral codes, `?ref=`/`preferredLeg` through every registration door, `/affiliate` (me, enrol, preferred leg, activation), `/public/affiliates/ref/:code` (+ QR), the learner's affiliate home and `/ref/:code` landing. Record: `.claude/mlm/progress.md`.
- 31 Oct 2026 — **MLM-002 Genealogy** built: placement by the plan's spillover rule at registration and opt-in, the `mlm-placement` catch-up job, `MlmPlacementHistory`, manual moves and sponsor/status changes, tree/team/referral reads, the Super Admin's members, sponsors and placements pages and the learner's tree and team pages. Record: `.claude/mlm/progress.md`.
- 31 Oct 2026 — **MLM-003 Orders & CV** built: `MlmOrder`/`MlmCvLedger`/`MlmLegBalance`, the purchase-settlement hooks (`lib/purchaseHooks.ts`), `lib/mlm/cv.ts` (orders, in-tree credits, eligibility job `mlm-cv-eligibility`, reversals), the Super Admin's courses, orders and ledgers pages, the learner's figures and volume page. Record: `.claude/mlm/progress.md`.
- 31 Oct 2026 — **New logo.** `brand/zuviloai-logo.png` (the face, circuit strands and star; black "Zuvilo", orange "Ai") replaces the ShubhLMS artwork; `brand/make_assets.py` re-measured for it and re-run, with a white cut of the symbol for dark surfaces (`logo-mark-dark.png`, `logo_mark_dark.png`); the Android launcher icons regenerated.
- 1 Nov 2026 — **Public website redesigned** in the ZuviloAi brand (ink, paper, orange; serif italic for one word of a heading): the site's colour tokens on the chrome, an ink hero with the product, the module strip, numbered benefits, ruled grids and timelines, ink footer and banners; the sign-in panel follows. Pages, routes, copy and the e2e headings unchanged (`docs/07` › The public website).
