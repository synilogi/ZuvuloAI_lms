# 08 — Testing Plan

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

**E2E since the conversion:** `billing`, `payments`, `multiadmin` and `onboarding` specs are in `.retired/apps/web/e2e`. `website`, `signup`, `learners`, `support` were rewritten, and `affiliate.spec.ts` drives a sale through matching, KYC, withdrawal, payout and refund.

## Layers

| Layer | Tool | Location | Runs with |
| --- | --- | --- | --- |
| Domain rules (unit) | Vitest | `packages/domain/src/domain.test.ts` | `npm test` |
| Mock services (unit) | Vitest | `apps/web/src/services/mock/*.test.ts` | `npm test` |
| API integration | Vitest + supertest against the real Express app and a dedicated seeded SQLite file (`apps/api/prisma/test.db`) | `apps/api/src/**/*.test.ts` | `npm test` (`pretest` migrates + seeds `test.db`) |
| Frontend + API end to end | Playwright (Chromium) driving the built frontend in `http` mode against a running API | `apps/web/e2e/*.spec.ts` | `npm run e2e` |
| Static | TypeScript, ESLint, Prettier | all workspaces | `npm run typecheck`, `npm run lint`, `npm run format:check` |

## What every API module test covers

1. **Happy path** for each route (status code and response shape keys the UI reads).
2. **Permission** — anonymous → 401; wrong role → 403; instructor outside their scope → 403/404;
   learner touching another learner's record → 403/404.
3. **Validation** — a domain validator refusal → 409 with `issues`; malformed body → 400.
4. **Error cases** — unknown id → 404; conflicts (duplicate email/title, full class, deleting a
   lesson-delivered quiz) → 409.
5. **Business rules** listed in `06-BUSINESS-RULES.md` for that module.

## Current coverage (29 Oct 2026)

| Suite | Where | Size | Last recorded run |
| --- | --- | --- | --- |
| Domain rules | `packages/domain/src/*.test.ts` (academy, assessment integrity, billing details, delivery, domain, entitlement, lifecycle, money, permission, plan change, quiz rules, quiz session, subscription, tax) | 14 files | 148 tests, 3 Oct 2026 |
| Web services, formatting, command registry, guards, screens | `apps/web/src/**/*.test.ts(x)` | 72 files | 392 tests, 3 Oct 2026 |
| API integration | `apps/api/src/routes/*.test.ts` and `src/lib/*.test.ts`: every module's happy path, permissions, validation and rules; `routeAudit.test.ts` (every mounted route: 401 anonymous, role refusals before the body is read); `securityAudit.test.ts`, `tenancy.test.ts`, `mediaSecurity.test.ts` (cross-academy probes); `hardening.test.ts` (malformed bodies and queries); `auditCoverage.test.ts` (every route named by a test); billing: `billingApi`, `billingViews`, `checkout`, `firstPurchase`, `invoicesPayments`, `billingJobs`, `webhooks`, `paymentGateways`, `sandboxGateway`, `trialsGrace`, `planChanges`, `usage`; October: `invitations`, `emailVerification`, `instructorRequests`, `learnerJoin`, `signup`, `quizSessions`, `liveRoom`, `liveSecurity`, `courseCover`, `coursePurchases`, `branding`, `deleteAccount`, `deploy-webhook`, `seedGuard`, `testOtp`, `mailSmtp` | 82 files | 797 tests, 3 Oct 2026; later suites green per `14-LAUNCH-CHECKLIST.md` |
| End to end (Playwright, real API on `prisma/e2e.db`) | `apps/web/e2e/`: `admin`, `billing`, `branding`, `courseCreation`, `coursePurchase`, `instructor`, `invitations`, `journeys`, `learners`, `liveClasses`, `multiadmin`, `onboarding`, `payments`, `quizzes`, `signup`, `student`, `support`, `website` | 18 specs | 28/28 on 3 Oct 2026; `journeys` and `courseCreation` added 23 Oct |
| Mobile, host | `apps/mobile/test/` (`architecture/`, `unit/`, `contract/`, `data/`, `features/`, `golden/`, `app/`) | 177 files | 2,030 pass, 3 Oct 2026 (one pre-existing `no_secrets_test` failure from Firebase keys) |
| Mobile, device | `apps/mobile/integration_test/` against `tool/contract_server.sh` | 25 tests | auth 5/5, entitlements 3/3, 3 Oct 2026 |
| Mobile, live UI | `tool/live_e2e.sh` (`tool/live_e2e/scenarios/`: auth, navigation, learner, staff, multi-admin, flows) | smoke tier 70 scenarios + deep tier | 70/70 smoke, 1 Oct 2026 |

The counts above are the last ones recorded in the build records; they were not re-run for this revision of the plan.

## E2E workflows

What the committed specs drive against the real, built frontend and the real API (`apps/web/scripts/run-e2e.mjs` reseeds
`e2e.db`, starts the API, builds and previews the frontend, runs the suite, tears both down):

- **Student** (`student`, `quizzes`, `coursePurchase`): register → `/home` → Explore → enrol → lesson → quiz session → certificate; buy a paid course through the sandbox gateway and land enrolled.
- **Instructor** (`instructor`, `courseCreation`, `liveClasses`): sign in → `/teach` → create and publish a course → grade a submission → roster; schedule, start and end a live class.
- **Admin** (`admin`, `learners`, `invitations`, `support`, `billing`, `payments`): dashboard, roster, reports, settings; add a learner and invite one; raise a support request; start a trial, pay an invoice (sandbox success, failure, cancellation), see the return state.
- **Journeys** (`journeys`): instructor request → admin approves → course built and published → learner joins with the code, completes a lesson, takes a quiz, submits an assignment → instructor grades → live class booked.
- **Platform** (`onboarding`, `signup`, `multiadmin`, `branding`, `website`): the company site and pricing; `/get-started` with the emailed code; two Admins with disjoint rosters, cross-admin probes refused, suspension and reactivation; the Super Admin replaces the logo and favicon.

Not yet exercised end to end: push delivery, the live room's video itself (the room is started and joined; the media session is Jitsi's), a real Razorpay payment (SAAS-016 needs a staging host), the mobile app against production.

## Milestone gates

Full suite (`npm run typecheck && npm run lint && npm test && npm run build`) runs after every module
phase; a phase is not marked COMPLETED with a failing test.
