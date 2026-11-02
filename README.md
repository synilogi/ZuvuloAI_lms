# ZuviloAI

One centralized learning platform that sells its own courses. Students register and buy directly, instructors apply and are approved, and the Super Admin controls courses, people, orders, payments and a 2-leg affiliate program. The conversion from the earlier multi-tenant SaaS is described in [`docs/16-PLATFORM-CONVERSION.md`](docs/16-PLATFORM-CONVERSION.md).

| | |
| --- | --- |
| **Web app** | React 18 + Vite 7 + TypeScript (`apps/web`): the public website and catalogue, registration, and the learner, instructor, admin and Super Admin workspaces |
| **API** | Express 4 + Prisma 6 (SQLite) + JWT (`apps/api`): 81 models, 45 migrations, one process that also serves the built web app under `/api` |
| **Shared rules** | Pure TypeScript domain package (`packages/domain`), imported as source by the API and the web app |
| **Mobile app** | Flutter 3.38 (`apps/mobile`): learner, instructor and admin experiences on Android, built and verified on a device; store release pending. See [Mobile app](#mobile-app-flutter) |
| **Production** | `https://zuviloai.com`, a CloudPanel host running the API under PM2 |
| **Status** | Functional scope complete and live. Launch blockers (email DNS, company identity, Razorpay staging run, Play listing) are tracked in [`docs/14-LAUNCH-CHECKLIST.md`](docs/14-LAUNCH-CHECKLIST.md) |

---

## Contents

- [What's in the product](#whats-in-the-product)
- [Repository layout](#repository-layout)
- [Quick start](#quick-start)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Security model](#security-model)
- [Platform: sales and the affiliate program](#platform-sales-and-the-affiliate-program)
- [Testing and quality gates](#testing-and-quality-gates)
- [Deployment](#deployment)
- [Mobile app (Flutter)](#mobile-app-flutter)
- [Development workflows](#development-workflows)
- [Documentation map](#documentation-map)
- [Known limitations](#known-limitations)
- [Contributing](#contributing)

---

## What's in the product

| Role | Workspace | What they do |
| --- | --- | --- |
| **Visitor** | `/`, `/courses`, `/courses/:slug`, `/categories`, `/become-an-instructor`, `/affiliate-program`, `/about`, `/faq`, `/contact`, `/support`, `/verify`, `/privacy`, `/terms`, `/refunds` | Browse the catalogue, read a course's outline and price, verify a certificate, read the affiliate program's published terms |
| **New learner or instructor** | `/register`, `/ref/:code`, `/teach/apply`, `/invite/:token`, `/courses/:courseId/enroll` | Register with a mobile number and an emailed code, with a sponsor's link or without; apply to teach and wait for approval |
| **Learner** (`student`) | `/home`, `/my-learning`, `/explore`, `/learn/:courseId`, `/assignments`, `/assessments`, `/certificates`, `/live`, `/purchases`, `/affiliate/*` | Buy and take courses, keep certificates and orders; in the affiliate program, see the team, volume, earnings, wallet, identity check and orders |
| **Instructor** | `/teach` | Teach assigned courses: curriculum, lessons, quizzes, assignments and grading, learners, live classes, course sales (counts only) |
| **Staff admin** (`admin`) | `/admin` | Run the catalogue and people within the permissions the Super Admin grants |
| **Super Admin** (`superadmin`) | `/superadmin`, `/admin` | Run everything: courses, people, orders, refunds, coupons, payment gateways, the affiliate program and its money, the website's words, the inbox, audit trail, system health |

Feature areas: authentication, sessions and password reset · self-serve registration with email verification ·
invitations, join links and instructor requests · roles and permissions · categories · courses with cover images ·
chapters · lessons and media uploads · enrolments · learning progress with gating and completion rules · quizzes
with server-held timed sessions · assignments with rubrics and reviews · certificates with public verification ·
live classes with a built-in video room and recordings · calendar · notifications with channel preferences, an
email outbox, SMTP delivery and push hints · platform settings · reports · dashboards · help centre
· course orders, coupons and refunds · payment gateways · a 2-leg affiliate program with wallets, KYC and payouts · public website and catalogue · webhooks · background jobs · platform branding ·
account deletion.

---

## Repository layout

```
apps/
  api/                 Express API: src/routes/ (one router per resource), src/lib/ (services), prisma/ (schema,
                       migrations, seeds), scripts/ (operator scripts). Has its own README.md
  web/                 React SPA: pages/, components/, shell/, services/ (36 service groups: contracts + http + mock),
                       styles/, e2e/ (Playwright)
  mobile/              Flutter app: lib/features/ (26 feature folders), test/, integration_test/, tool/ (verify,
                       contract server, live E2E, UI tour), store/ (Play listing). Has its own README.md
  lms-react/           An untracked, unfinished second React app (REACT-000/001). No package.json, so it is not a
                       workspace and nothing imports it. Leave it alone
packages/
  domain/              Shared LMS types and business rules (no build step; consumed as TS source)
docs/                  Backend and integration source of truth: 00 status … 14 launch checklist, modules/*
deploy/                Server bootstrap, deploy script, daily backup script, PM2 config, production env template
brand/                 The ZuviloAI logo and the script that cuts every web and mobile brand asset from it
.claude/               Autonomous development workflows (UI, SaaS, Flutter) and their records
.vscode/launch.json    Flutter run configurations for the USB test phone
ZuviloAI App Shell.html   The original visual authority for the web shell
shared.json            A generated route inventory from the endpoint audit; nothing reads it
```

npm workspaces: `apps/*` and `packages/*` (a folder is a workspace only if it has a `package.json`, so
`apps/mobile` and `apps/lms-react` are not).

---

## Quick start

**Requirements:** Node ≥ 20, npm ≥ 10. Flutter 3.38 stable (Dart 3.10) and JDK 17 only for the mobile app.

```bash
git clone <repo> zuviloai && cd zuviloai
npm install
```

### Web app alone (in-memory demo data)

```bash
npm run dev                  # http://localhost:5173 (mock services, no API needed)
```

`VITE_API_MODE=mock` (the default) runs the whole UI against in-memory services. Add `?scenario=empty`,
`?scenario=error` or `?scenario=slow` to any mock-backed page to review its states.

### Full stack (real API)

```bash
# 1. API
cd apps/api
cp .env.example .env                        # development defaults work as-is
npm run prisma:generate                     # Prisma client
npm run prisma:deploy                       # apply migrations to prisma/dev.db (never resets data)
npm run seed:demo                           # demo content (development only, on a database with no orders); deletes what it replaces
npm run seed:platform                       # the workspace and the Help Centre; never deletes
npm run seed:education                      # optional: sample school + exam catalogue (docs/13-SAMPLE-CATALOGUE.md)
npm run permissions:backfill                # grant admins the permission catalogue (idempotent)
npm run dev                                 # http://localhost:4000  (GET /health → {"ok":true})

# 2. Web, in another terminal
cd apps/web
cp .env.example .env                        # then set VITE_API_MODE=http
cd ../.. && npm run dev                     # http://localhost:5173 against the real API
```

The demo seed prints three accounts (admin, instructor, student), all with the password `syniastrolms123`.
To create a platform Super Admin (never done by the seed):

```bash
SUPERADMIN_EMAIL=you@example.com SUPERADMIN_PASSWORD='<strong password>' \
  npm run superadmin:create -w @syniastrolms/api
```

Self-registration emails a 6-digit code. In development leave `MAIL_TRANSPORT=outbox` and read the code from
the `EmailOutbox` table, or set `MAIL_TRANSPORT=log` to print it; `TEST_OTP_EMAIL`/`TEST_OTP_CODE` give the
listed test addresses a static code (development only, refused on any live host). To drive checkout end to end
without Razorpay, set `PAYMENT_SANDBOX=on` (refused in production).

> `npm run seed:demo` replaces the database's content with the demo. It refuses to run with
> `NODE_ENV=production`, with a `zuviloai.com` `APP_URL`/`CORS_ORIGIN`, or against any database not named
> `dev.db`, `test.db` or `e2e.db` (`prisma/seedGuard.ts`). Production starts from `npm run seed:platform`, which
> `deploy/deploy.sh` runs on every deploy. `npm run e2e` uses its own `prisma/e2e.db`.

### Mobile app

```bash
cd apps/mobile
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json
tool/verify.sh                              # format, analyze, tests, dev debug APK
```

The app talks to a real API. `tool/contract_server.sh` runs `apps/api` on a scratch database for integration
tests and fixture capture. Details, flavours, signing and the Play listing are in
[`apps/mobile/README.md`](apps/mobile/README.md).

---

## Configuration

### `apps/api/.env`

The full reference, with defaults and production guidance, is in
[`docs/10-DEPLOYMENT.md`](docs/10-DEPLOYMENT.md) and [`apps/api/.env.example`](apps/api/.env.example).

| Variable | Purpose |
| --- | --- |
| `DATABASE_URL` | SQLite file (`file:./dev.db`) |
| `JWT_SECRET`, `JWT_EXPIRES_IN` | Token signing and lifetime (default `7d`). Production refuses the dev default or a secret under 32 characters |
| `PORT`, `CORS_ORIGIN`, `APP_URL` | Listener, the single allowed browser origin, and the base URL for email links |
| `TRUST_PROXY`, `RATE_LIMIT_MAX`, `RATE_LIMIT_AUTH_MAX`, `RATE_LIMIT_ACCOUNT_MAX`, `RATE_LIMIT_EMAIL_MAX`, `RATE_LIMIT_WINDOW_MS` | Proxy hops and the per-IP, per-account (failed sign-ins) and per-address (registration codes) limits |
| `UPLOAD_DIR` | Media, branding and live recordings (put it on a persistent volume in production) |
| `MAIL_TRANSPORT`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM`, `PLATFORM_REPLY_TO`, `SALES_NOTIFY_EMAIL` | `outbox` (store only), `log` (store and print) or `smtp` (deliver through a relay). Registration codes, resets and invitations never arrive without a delivering transport |
| `SIGNUP_EMAIL_VERIFICATION` | `on` (default): every self-registration confirms an emailed code first. `off` only where nothing can deliver email |
| `TEST_OTP_EMAIL`, `TEST_OTP_CODE` | A static fallback code for listed test addresses. Development and test only; the API refuses to start with them on any live host |
| `PUSH_PROVIDER`, `FCM_SERVICE_ACCOUNT` | `fcm` with a Firebase service account enables push hints to registered devices |
| `LIVE_REMINDERS` | `off` disables the in-process scheduler (reminders, digests, delivery, the affiliate program's jobs, leases) |
| `JITSI_DOMAIN`, `JAAS_APP_ID`, `JAAS_KID`, `JAAS_PRIVATE_KEY(_FILE)`, `JAAS_WEBHOOK_SECRET`, `LIVE_RECORDING_DAYS`, `LIVE_ROOM_PUBLIC_JITSI` | The built-in live room. Production needs 8x8 JaaS; the public Jitsi server is for trying it out and is refused in production unless explicitly allowed |
| `DEFAULT_TENANT_SLUG` | The one workspace everyone runs in (`default`). Accounts of any other tenant are refused with `WORKSPACE_CLOSED` |
| `TENANT_ENFORCEMENT` | Tenant isolation, on unless `off`. Production refuses to start with `off` |
| `PAYMENT_CREDENTIALS_KEY` | Encrypts gateway credentials and affiliates' PAN and bank account. Without it gateways cannot be configured and KYC answers 503. Back it up apart from the database: losing it makes those values unreadable |
| `PAYMENT_SANDBOX` | `on` enables the sandbox gateway while no real gateway is active. Refused in production |
| `DEPLOY_WEBHOOK_SECRET`, `DEPLOY_BRANCH` | Enable `POST /api/deploy/webhook` (GitHub push → `deploy.sh`). Unset, the route 404s |
| `ANDROID_APP_LINK_SHA256`, `ANDROID_APP_LINK_PACKAGES` | Serve `/.well-known/assetlinks.json` so Android opens join, reset, certificate and course links in the app |
| `WEB_DIST` | Production only: path of the built web app, which switches on SPA serving with the API under `/api` |

### `apps/web/.env`

| Variable | Value |
| --- | --- |
| `VITE_API_MODE` | `mock` (default) or `http` |
| `VITE_API_BASE_URL` | API origin: `http://localhost:4000` locally, `https://<host>/api` in production |

### `apps/mobile/config/*.json`

Public values only (`ENV_NAME`, `API_BASE_URL`, `WEB_BASE_URL`, `BILLING_CHECKOUT_ENABLED`,
`COURSE_CHECKOUT_ENABLED`, `PUSH_ENABLED`, `CRASH_REPORTING_ENABLED`), one file per flavour, enforced by a test.
Plan and course checkout stay off in the app on `zuviloai.com`: purchases are made on the website.

**Never commit secrets.** `.env` files, `key.properties` and service accounts are git-ignored; the `.env.example`
files hold no real values.

---

## Architecture

### Request path

```
Client ──HTTPS──> helmet · CORS · rate limit
                    ├> /webhooks/* (raw body, signature-verified: course payments, JaaS recordings)
                    ├> /deploy/webhook (raw body, GitHub signature)
                    └> JSON body (1 MB) · attachAuth (JWT naming a server session) · tenantContext
                         ├> /auth · /signup · /public/* · /sandbox · /catalog · /help   (own rate limits; public or own records)
                         └> router: requireAuth → requireRole → requirePermission
                                     → (tenant scope, automatic) → requireFeature / withinLimit
                                     → handler → domain rules → Prisma (tenant-scoped)
```

Mounted routers: `/auth`, `/signup`, `/public`, `/sandbox`, `/catalog`, `/courses` (with `/:courseId/chapters`
and `/:courseId/lessons`), `/categories`, `/students`, `/invitations`, `/instructors`, `/learning` (learning and
course purchases), `/quizzes`, `/assignments`, `/certificates`, `/live`, `/calendar`, `/notifications`,
`/settings`, `/help`, `/reports`, `/dashboard`, `/media`, `/superadmin` (with `/tenants`, `/inquiries`,
`/branding`, `/sales`, `/affiliates`), `/affiliate`, `/public`, `/catalog`, `/webhooks`, `/deploy/webhook`, `/health`.

- **Authentication:** `Authorization: Bearer <JWT>` (HS256) whose `sid` must name an open `UserSession`. No
  cookies. Logout, logout-all, a password change or reset end sessions at once. An invalid token makes the
  request anonymous, so protected routes answer `401`.
- **One workspace:** every request runs in the tenant named by `DEFAULT_TENANT_SLUG` (docs/16, D-PLAT-01). Tenancy stays as an
  internal invariant: a Prisma extension confines every query on scoped models, stamps creates and checks foreign keys. Nothing
  a client sends can select a tenant.
- **Authorization order (fixed):** authenticated → role → permission → workspace → operation. `superadmin` passes role and
  permission guards; `requireSuperAdmin` has no bypass.
- **Errors:** `{ message, issues?, code? }`. Stable `code`s cover `PERMISSION_DENIED`, `PAYMENT_REQUIRED`, `PAYMENT_FAILED`,
  `WORKSPACE_CLOSED`, `INVITATION_REQUIRED`, `INVITE_INVALID` and `LIVE_ROOM_NOT_CONFIGURED`.
- **Validation:** `zod` on every body and query. Unknown keys are dropped, so mass assignment is impossible.

### Code organisation

- `apps/api/src/routes/*`: one router per resource. Handlers stay thin, and business rules come from
  `packages/domain` validators. `routeAudit.test.ts` walks every mounted route for authentication and role
  refusals.
- `apps/api/src/lib/*`: services. Each named module is the *only* writer of its tables: `coursePurchases.ts`, `coupons.ts`, `courseRefunds.ts`, `mlm/earnings.ts`, `mlm/wallet.ts`, `mlm/cv.ts`, `tenancy.ts`,
  `audit.ts`, `observe.ts`, `signup.ts`, `pendingAccounts.ts`, `invitations.ts`, `instructorRequests.ts`,
  `quizSessions.ts`, `liveRoom.ts`, `liveSessions.ts`, `coursePurchases.ts`,
  `branding.ts`, `appLinks.ts` and others.
- `apps/web/src/services/contracts.ts`: the 36 service groups every screen calls. `services/http/*` implements
  them against the API and `services/mock/*` in memory. Screens never import fixtures.
- `packages/domain/src/*`: catalogue, progress, quiz rules and sessions, assignment scoring, certificates,
  live-class phases, calendar, notifications, settings, permissions, course sales, the affiliate plan and earnings rules,
  money (integer minor units), tax, plan changes, signup, inquiries, branding, all unit-tested.
- `apps/mobile/lib/*`: `core/` (config, auth, network, theme, links, push, media), `features/*` (one folder per
  module, each with `data/`, `application/`, `presentation/`), `app/` (bootstrap, routing, shells). Architecture
  tests forbid Dio in widgets, cross-feature imports, hard-coded colours, secrets, plan-name checks and literal
  UI strings.

Conventions (tokens, CSS Modules, density, container queries, status registry, routes, forms, dialogs) are in
[`docs/01-PROJECT-ARCHITECTURE.md`](docs/01-PROJECT-ARCHITECTURE.md). The endpoint reference is
[`docs/05-API-SPECIFICATION.md`](docs/05-API-SPECIFICATION.md).

### Design system: "Celestial Ink"

Warm parchment neutrals with a deep indigo/violet accent; antique gold is reserved for things a learner earns.
Display text is Fraunces and UI text is Plus Jakarta Sans; dark mode is a true midnight indigo. Tokens live in
`apps/web/src/styles/tokens.css`, the living reference is the hidden `/design-system` route, and the Flutter app
ports the same tokens (`lib/core/theme/tokens.dart`). The Super Admin can replace the platform logo and favicon
at `/superadmin/branding`.

---

## Security model

The checklist is in [`docs/09-SECURITY.md`](docs/09-SECURITY.md). The highlights:

- bcrypt password hashes. Password reset tokens are hashed, single-use, expire after 1 hour, are budgeted per
  address, and the flow never reveals whether an account exists. Sign-in is throttled per IP and per account.
- Every self-registration confirms a 6-digit emailed code before any account exists. Codes are HMAC-hashed,
  expire in 15 minutes, and allow 5 attempts and 5 sends.
- Instructor scope and learner ownership are derived from the token. Out-of-scope ids answer `404`.
- Tenant isolation is enforced at the query boundary and fails closed. Production refuses to start with isolation off.
- The client never controls price, amount, coupon arithmetic, commission, wallet balances, quiz scores, quiz deadlines,
  completion or roles.
- PAN and bank account are sealed with AES-256-GCM and shown as last digits. Only the payout bank file opens the account
  number, for the Super Admin, and each export is audited. CSV cells are neutralised against spreadsheet formulas.
- Payments go only through the provider abstraction. A browser "success" activates nothing: the signature is
  verified and the payment is read from the gateway server to server. Webhooks are signature-verified and
  idempotent. A gateway in test mode takes no payment on a production process.
- Financial history is append-only, enforced by database triggers. No card data is stored anywhere.
- Every sensitive mutation is audited in the same transaction, and the trail is immutable. All logging is
  redacted, and a test sweeps the logs for secrets.
- Uploads are allow-listed by MIME type and extension, checked against their bytes, size-limited, stored under
  random names and served only where the reader may open them.
- The demo seed refuses to run against anything that looks like production.

---

## Platform: sales and the affiliate program

The public website's marketplace (bundles, mentors, blog, site management) is in [`docs/17-WEBSITE-MARKETPLACE.md`](docs/17-WEBSITE-MARKETPLACE.md).

How the live site is built, watched and shipped is in [`docs/19-OPERATIONS.md`](docs/19-OPERATIONS.md).

The database is MySQL 8.4: see [`docs/18-MYSQL.md`](docs/18-MYSQL.md) for how to run it and test against it. Older mentions of SQLite and `dev.db` in these docs describe the time before that move.

The conversion from multi-tenant SaaS is told in [`docs/16-PLATFORM-CONVERSION.md`](docs/16-PLATFORM-CONVERSION.md), and the
affiliate program in [`docs/15-MLM-AFFILIATE-ARCHITECTURE.md`](docs/15-MLM-AFFILIATE-ARCHITECTURE.md). Retired SaaS code is kept in `.retired/`.

- **Course sales:** one server-priced order per checkout (`ORD-YYYY-NNNNNN`), through the gateway configured at
  `/superadmin/payment-gateways`. The enrolment opens only on the gateway's confirmation. Webhook: `POST /api/webhooks/:provider/courses`.
- **Coupons and refunds:** integer paise, never below ₹1. Refunds cover the whole order, expire the enrolment and reverse the sale's volume.
- **Affiliate program:** sponsor links, A and B legs, spillover, CV per verified sale, once-daily matching with rank caps, exact 50:50
  ranks, rewards, a monthly payout ceiling with holds, wallets, KYC, withdrawals and payout batches. Every plan term is data, on versioned
  plans. Ledgers refuse edits by trigger, and a nightly check compares balances with them. Nothing on the site promises income.
- **Website:** the Super Admin edits the headline, featured courses, testimonials and questions at `/superadmin/website`.

---

## Testing and quality gates

Run these from the repository root. All of them must be green before a change lands:

```bash
npm run typecheck                    # every workspace
npm run lint                         # ESLint, zero warnings
npm test                             # domain + web + API (the API's pretest rebuilds prisma/test.db)
npm run build                        # web production build
npm run format:check                 # Prettier
npm run e2e                          # Playwright against the real API on prisma/e2e.db
```

| Suite | Tool | Where | Size |
| --- | --- | --- | --- |
| Domain rules | Vitest | `packages/domain/src/*.test.ts` | 14 files |
| Web services and UI logic | Vitest | `apps/web/src/**/*.test.ts` | 72 files |
| API integration: permissions, validation, tenancy, billing, webhooks, security audit, route audit | Vitest + supertest against a seeded `test.db` | `apps/api/src/**/*.test.ts` | 82 files |
| End to end | Playwright | `apps/web/e2e/*.spec.ts` | 18 specs: admin, billing, branding, course creation, course purchase, instructor, invitations, journeys, learners, live classes, multi-admin, onboarding, payments, quizzes, signup, student, support, website |
| Mobile | `flutter test`, `flutter test integration_test` on a device, `tool/live_e2e.sh` | `apps/mobile/test/`, `integration_test/`, `tool/live_e2e/` | 177 host test files, 25 integration tests, a live UI scenario layer |

Last recorded full runs (3 Oct 2026): API 797, web 392, domain 148 tests and 28/28 E2E; mobile 2,030 host
tests. Later work added suites (see `docs/00-PROJECT-STATUS.md`). The test plan is
[`docs/08-TESTING-PLAN.md`](docs/08-TESTING-PLAN.md).

---

## Deployment

Production runs on a CloudPanel host with the API under PM2. One Node process serves the SPA and the API
under `/api`. The runbook is [`docs/10-DEPLOYMENT.md`](docs/10-DEPLOYMENT.md), the launch checklist is
[`docs/14-LAUNCH-CHECKLIST.md`](docs/14-LAUNCH-CHECKLIST.md), and the scripts are in [`deploy/`](deploy/):

| Script | Purpose |
| --- | --- |
| `deploy/bootstrap.sh` | One-time server setup per site: layout, `deploy.conf`, deploy key, clone, `.env` with generated `JWT_SECRET` and `DEPLOY_WEBHOOK_SECRET`, PM2 resurrect cron |
| `deploy/deploy.sh` | Each deploy: fetch → `npm ci` (only when the lockfile changed) → web build → `prisma generate` → **database backup** → `migrate deploy` → `seed:platform` → atomic symlink swap → App Links file → PM2 reload → health checks. One run at a time per site |
| `deploy/backup.sh` | Daily cron: a consistent database copy plus an archive of uploads into `data/backups/daily`, newest 14 kept |
| `deploy/ecosystem.config.cjs` | PM2 process definition (one instance; `tsx` runs the TypeScript source) |
| `deploy/api.env.example` | The production `apps/api/.env` template |

Operational notes:

- **Continuous deploy:** a GitHub push webhook at `POST /api/deploy/webhook` runs `deploy.sh` for the
  configured branch. Deploys can also be run by hand over SSH.
- **Backups:** `deploy.sh` takes one before every migration and `backup.sh` daily; copy `data/backups` off the
  server. Migrations are forward-only. `.env` is in no backup, so keep its secrets elsewhere.
- **Never run `npm run seed` / `seed:demo` in production.** It deletes content and refuses on any host
  that looks like production.
- **Webhooks:** Razorpay at `https://<host>/api/webhooks/razorpay/courses` with its secret entered in the
  Super Admin gateway settings; JaaS recordings at `/api/webhooks/jaas`.
- **Observability:** failures are redacted JSON lines keyed `observability` in the PM2 log, and the Super
  Admin reads them at `GET /api/superadmin/observability`; `GET /api/superadmin/system` shows job leases.
  `GET /api/health` also checks the database.

---

## Mobile app (Flutter)

A production Flutter client in `apps/mobile`, **built and verified on a device, awaiting store release**. It
consumes the existing API and never changes the backend.

- **Scope:** the full learner experience (home, explore, enrolment and course purchase, lesson player, quizzes,
  assignments, certificates and ranks, live classes in the built-in room, notifications, profile), instructor
  operations (dashboard, courses and curriculum, grading, quizzes overview, students, live classes, calendar)
  and staff operations (instructors, certificates, reports). The Super Admin, heavy authoring, the affiliate program
  and platform configuration stay on the web. Course checkout is disabled in the app on
  `zuviloai.com`; purchases happen on the website.
- **Stack:** Flutter 3.38 / Dart 3.10, Riverpod 3, go_router, dio, freezed/json_serializable (generated files
  committed), flutter_secure_storage, Firebase (messaging for push; Crashlytics and Analytics present but off in
  prod), razorpay_flutter, jitsi_meet_flutter_sdk, webview_flutter, pdfrx, video_player. Android first
  (`com.shubhlms.mobile`, minSdk 26, targetSdk 36, flavours dev/staging/prod); iOS folders exist but are not
  built.
- **Version:** `1.1.1+5` (`pubspec.yaml`). Release signing reads a git-ignored `android/key.properties`; the Play
  upload key is registered. Store upload is a human action: `apps/mobile/store/PLAY_CONSOLE.md` holds the
  listing answers.
- **Deep links:** `zuviloai.com` join, invite, reset-password, verify, course and learn links open in the app
  once `/.well-known/assetlinks.json` carries the Play signing certificate (`ANDROID_APP_LINK_SHA256`).
- **Workflow record:** [`.claude/flutter/modules.md`](.claude/flutter/modules.md) (architecture and 32 module
  specifications), [`.claude/flutter/modules.json`](.claude/flutter/modules.json) (registry),
  [`.claude/flutter/progress.md`](.claude/flutter/progress.md) (last updated 3 Oct 2026). FLUTTER-000…027, 029
  and 031 are complete; FLUTTER-028 push delivery was blocked on a Firebase project and FLUTTER-030 Final
  Hardening & Release on the owner's release decisions. Firebase, the live room, course purchases, the
  email-code sign-up step and the staff UI redesign (`apps/mobile/docs/ui-redesign-checklist.md`) landed after
  that record and are not yet written up in it.
- **Build it further:** run `/continue-flutter` in Claude Code.

---

## Development workflows

The `.claude/` folder contains autonomous, resumable development workflows. Each has its own module list,
and none edits another's files.

| Workflow | Command | Scope | State |
| --- | --- | --- | --- |
| Web UI build | `/continue` | `.claude/modules.json` (UI only) | Completed (`.claude/progress.md`) |
| SaaS phase | `/continue-saas` | `.claude/saas/modules.json` (full stack) | SAAS-000…015 and 018…031 done; SAAS-016 blocked on a staging deployment with the Razorpay webhook; SAAS-017 blocked on the VyaparGateway contract |
| Flutter mobile app | `/continue-flutter` | `.claude/flutter/modules.json` (`apps/mobile` only) | Built; FLUTTER-028 part B and FLUTTER-030 wait on the owner (Firebase credentials, signing, store) |

Backend and integration status, including the work done outside these workflows in October 2026, is tracked in
[`docs/00-PROJECT-STATUS.md`](docs/00-PROJECT-STATUS.md). A QA pass record is `.claude/qa-progress.md`.

---

## Documentation map

| File | Contents |
| --- | --- |
| [`docs/00-PROJECT-STATUS.md`](docs/00-PROJECT-STATUS.md) | Module status, roadmap, SaaS track, October additions, mobile status, test status, change log |
| [`docs/01-PROJECT-ARCHITECTURE.md`](docs/01-PROJECT-ARCHITECTURE.md) | Code organisation and conventions |
| [`docs/02-MODULE-MASTER-LIST.md`](docs/02-MODULE-MASTER-LIST.md) | Modules, completion checklist, what is out of scope |
| [`docs/03-DATABASE-SPECIFICATION.md`](docs/03-DATABASE-SPECIFICATION.md) | Schema and constraints |
| [`docs/04-AUTHENTICATION-AUTHORIZATION.md`](docs/04-AUTHENTICATION-AUTHORIZATION.md) | Auth, sessions, registration doors, roles, permissions, tenant context, entitlements |
| [`docs/05-API-SPECIFICATION.md`](docs/05-API-SPECIFICATION.md) | Every endpoint |
| [`docs/06-BUSINESS-RULES.md`](docs/06-BUSINESS-RULES.md) | Rules and the enforcement matrix |
| [`docs/07-FRONTEND-INTEGRATION.md`](docs/07-FRONTEND-INTEGRATION.md) | The web client's service seam and per-screen wiring |
| [`docs/08-TESTING-PLAN.md`](docs/08-TESTING-PLAN.md) | Test layers, suites and end-to-end journeys |
| [`docs/09-SECURITY.md`](docs/09-SECURITY.md) | Security checklist, threat notes, open items |
| [`docs/10-DEPLOYMENT.md`](docs/10-DEPLOYMENT.md) | Environment, server, deploy, continuous deploy, rollout, backups, operations |
| [`docs/11-SUPERADMIN-FLOW.md`](docs/11-SUPERADMIN-FLOW.md) | The platform role, as designed and as built |
| [`docs/12-ENDPOINT-AUDIT.md`](docs/12-ENDPOINT-AUDIT.md) | The endpoint and billing audit (SAAS-024) |
| [`docs/13-SAMPLE-CATALOGUE.md`](docs/13-SAMPLE-CATALOGUE.md) | The sample education catalogue seed and the course-data reset script |
| [`docs/14-LAUNCH-CHECKLIST.md`](docs/14-LAUNCH-CHECKLIST.md) | Production launch: blockers, deploy order, marketing launch, DNS, the October audits |
| [`docs/15-MLM-AFFILIATE-ARCHITECTURE.md`](docs/15-MLM-AFFILIATE-ARCHITECTURE.md) | Proposed 2-leg MLM affiliate program: gap analysis, schema, endpoints, rules, pages, mobile, tests (awaiting approval) |
| `docs/modules/*.md` | Per-module detail |
| [`apps/api/README.md`](apps/api/README.md) | The backend's map |
| [`apps/mobile/README.md`](apps/mobile/README.md), [`apps/mobile/store/PLAY_CONSOLE.md`](apps/mobile/store/PLAY_CONSOLE.md) | Building, testing, signing and listing the mobile app |
| `.claude/saas/subscriptions.md`, `.claude/saas/progress.md`, `.claude/flutter/modules.md`, `.claude/flutter/progress.md` | The SaaS specification and record; the Flutter specification and record |

---

## Known limitations

- **JWTs:** no refresh tokens; a token lives `JWT_EXPIRES_IN` (default 7 days) and is kept in `localStorage`
  on the web, which is why a Content-Security-Policy is an open launch item.
- **No MFA** for any role, including the Super Admin.
- **Email:** delivery needs an SMTP relay (`MAIL_TRANSPORT=smtp`) and authenticated DNS for `MAIL_FROM`; until
  then codes, resets and invitations stay in the outbox. Notification emails carry no unsubscribe header. SMS is
  a stored preference only.
- **Media:** no transcoding or HLS; files are served as uploaded. Fragmented MP4 reports no duration on Android.
- **Live classes:** the built-in room needs 8x8 JaaS in production; the public Jitsi server is for trials only.
  External meeting links still work.
- **Invoices and certificates:** JSON only, with no PDF generation; invoices carry no seller GSTIN yet.
- **Refunds:** whole orders only. A part refund made in the Razorpay dashboard flags the order and does not revoke the
  learner's access.
- **Database:** SQLite, a single API instance with an in-process scheduler. Scaling out means PostgreSQL and
  `LIVE_REMINDERS=off` on the extra instances.
- **Staging:** none exists. SAAS-016 (a Razorpay test-mode rehearsal reachable by webhooks) is blocked on one.
- **Backups:** `backup.sh` keeps copies on the same server; off-server copies and a rehearsed restore are open.
- **Mobile:** store release, push delivery credentials and crash reporting await the owner; the staging flavour
  points at production because no staging host exists.

---

## Contributing

1. Work on a branch. The branch each site deploys is set in its `deploy.conf`; the launch checklist's working
   branch is `sunil_workspace`.
2. Keep `docs/` in step with the code, since it is the source of truth for backend work. `docs/00` carries the
   status and change log; `docs/05` the endpoints; `docs/14` the launch items.
3. Match the surrounding code: its tokens, naming, error shapes and test style. Add tests with every change.
4. Run the quality gates above before opening a pull request. For the mobile app, `tool/verify.sh`.
5. Never commit secrets, never add a plan-name check, and never trust a client-supplied price, tenant, status,
   deadline or price.
