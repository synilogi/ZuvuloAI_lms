# ZuviloAI API

The backend of ZuviloAI: one platform selling its own courses, with a 2-leg affiliate program, run by a Super Admin. Where this file still describes academies, plans or subscriptions, `docs/16-PLATFORM-CONVERSION.md` is the current account.

**Stack:** Express 4, Prisma 6 on SQLite, JWT (HS256), Zod, Vitest and supertest. The shared rules live in
`packages/domain` and are imported as TypeScript source.

This file is the backend's map. The full references are in `docs/`: the endpoints in
[`05-API-SPECIFICATION.md`](../../docs/05-API-SPECIFICATION.md), authorization in
[`04-AUTHENTICATION-AUTHORIZATION.md`](../../docs/04-AUTHENTICATION-AUTHORIZATION.md), the schema in
[`03-DATABASE-SPECIFICATION.md`](../../docs/03-DATABASE-SPECIFICATION.md), security in
[`09-SECURITY.md`](../../docs/09-SECURITY.md) and operations in [`10-DEPLOYMENT.md`](../../docs/10-DEPLOYMENT.md).
The build record for the SaaS layer is [`.claude/saas/progress.md`](../../.claude/saas/progress.md).

---

## Run it

```bash
cp .env.example .env            # development defaults work as-is
npm run prisma:generate
npm run prisma:deploy           # apply migrations to prisma/dev.db (never resets data)
npm run seed:demo               # demo content; development only, on a database with no orders
npm run seed:platform           # the workspace and the Help Centre; safe anywhere, never deletes
npm run seed:education          # sample school + competitive-exam catalogue into an academy; never deletes (docs/13-SAMPLE-CATALOGUE.md)
npm run permissions:backfill    # grant academy admins the permission catalogue (idempotent)
SUPERADMIN_EMAIL=you@example.com SUPERADMIN_PASSWORD='…' npm run superadmin:create
npm run dev                     # http://localhost:4000, GET /health → {"ok":true}
```

| Script | What it does |
| --- | --- |
| `npm test` | Rebuilds `prisma/test.db` (migrate + seed + backfill), then runs every suite |
| `npm run typecheck` | `tsc --noEmit` |
| `npm run gateways:import-env` | One-off move of Razorpay keys from the environment into the encrypted store |
| `npm run db:backup` | A consistent `VACUUM INTO` copy of the database under `DB_BACKUP_DIR`, newest `DB_BACKUP_KEEP` kept; `deploy.sh` runs it before every migration and `deploy/backup.sh` daily |
| `npm run mail:test -- you@example.com` | Sends one message through the configured transport to prove SMTP delivery |
| `npm run seed:education` · `npm run data:clear-courses` | The sample school and exam catalogue; the course-data reset (dry run by default). `docs/13-SAMPLE-CATALOGUE.md` |
| `npm run platform:convert` | One-time conversion report; add `--apply` to archive other academies and rename the workspace; deletes nothing |
| `npm run courses:audit-access` | Read-only audit of who can reach which course |
| `npm run app-links:publish` | Writes `/.well-known/assetlinks.json` from `ANDROID_APP_LINK_SHA256`; `deploy.sh` runs it |
| `npm run platform:update-copy` | Refreshes the platform's seeded copy (Help Centre and the like) |

---

## Request path

```
helmet · CORS (one origin) · global rate limit
  └ /webhooks/:provider/courses   raw body, signature-verified, idempotent — no session
  └ /webhooks/jaas   raw body, signed by JaaS
  └ /deploy/webhook                    raw body, GitHub signature → deploy.sh (404 unless DEPLOY_WEBHOOK_SECRET is set)
  └ JSON body (1 MB) · attachAuth (Bearer JWT) · tenantContext
      └ /auth · /signup · /public/* (join links, invitations, course links, verifications, plans, inquiries, branding) — own rate limits
      └ router: requireAuth → requireRole → requirePermission → (tenant scope) → requireFeature / withinLimit → handler
```

`tenantContext` (`src/lib/requestContext.ts`) reads the signed-in account's row on every request, in one query:

- **Tenant.** The request runs for the account's academy. A tenant id sent by the client is never read.
- **Session.** The token's `sid` must name an open `UserSession`.
- **Account state.** A deactivated admin, an inactive instructor or a suspended learner is refused by every guard.
- **Academy state.** A member of a suspended or archived academy is refused with `ACADEMY_SUSPENDED` / `ACADEMY_ARCHIVED`.

Visitors who aren't signed in run for the `DEFAULT_TENANT_SLUG` academy.

Errors are `{ message, issues?, code? }`. Stack traces, SQL and library text never reach a client. The billing and
Super Admin surfaces always carry a stable `code`.

---

## Tenancy

Every academy-owned table carries `tenantId`. A Prisma extension (`src/lib/tenancy.ts`) scopes every query to
the current academy, stamps creates, and checks that each foreign key a write names belongs to the same
academy. A query with no context is refused.

The platform context is the one exception: the Super Admin router, the scheduler, operator scripts, and lookups
that are platform-wide by decision (sign-in by email, reset tokens, credential ids). Each names its reason.

**Academies (SAAS-019)** are provisioned by the Super Admin (`POST /superadmin/tenants`) in one transaction:

- the tenant;
- its owner admin, holding every permission;
- settings named after the academy;
- the starter level and rank ladders;
- a default certificate template.

Lifecycle: active → suspended → reactivated, or archived. Archiving needs the subscription to have ended first.
The default academy can be neither suspended nor archived. No status deletes data.

## Identity and authorization

**Roles** are `student`, `instructor`, `admin` (academy) and `superadmin` (platform). `superadmin` is a separate
role, never a stronger admin.

**Academy admins** hold permission keys from the 24-key catalogue in `packages/domain`. `requirePermission` reads
them from the database on every request.

**Sessions (SAAS-020).** Sign-in creates a session and a 7-day token that names it.

- `POST /auth/logout`, `logout-all`, `DELETE /auth/sessions/:id`, a password change and a password reset end tokens at once.
- `PATCH /auth/me` updates the display name.
- There are no refresh tokens.
- Tokens issued before sessions existed stay valid until they expire, unless logout-all, a password change or a reset ended them.

**Scope.** Instructors are confined to the courses they teach and learners to their own records. An out-of-scope
id answers 404.

`src/routes/routeAudit.test.ts` walks every mounted route and checks four things:

- every non-public route refuses an anonymous caller (401);
- every staff, admin and platform route refuses a learner before reading the body;
- admin-only and platform routes refuse an instructor;
- platform routes refuse an academy admin.

## LMS

These modules each have a router in `src/routes/`, with scope checks and tests:

- categories, courses, chapters and lessons, publishing
- media
- students, instructors, enrolments
- learning progress with gating and completion rules
- quizzes, assignments and reviews
- certificates with public verification
- live classes, calendar
- notifications, settings, reports, dashboard, the Help Centre

Learner-facing rules:

- **Quizzes (SAAS-018).** The server scores every attempt. A learner never receives the answer key.
  `GET /learning/…/quiz-attempts` returns reviews cut to the quiz's `showResults`.
- **Hand-ins.** They must fit the assignment's format and word limit, and may name only the learner's own uploads.
- **Media (SAAS-023).** A file is read only where the reader may open it: enrolled for lesson and assignment
  files, the teaching scope for hand-ins. An upload's bytes must match its type.

## Subscriptions and billing

Money is integer minor units (paise). Prices, tax, plan, status and entitlements are always computed on the
server.

- **Plans.** Plans are immutable versions carrying their features and limits as data. A subscription stays on the
  version it bought. Nothing compares a plan's name. The Super Admin creates, versions, publishes, archives and
  restores plans.
- **Subscriptions.** Seven states (`trialing`, `active`, `past_due`, `paused`, `canceling`, `canceled`, `expired`),
  changed only through named transitions. Each transition writes an immutable lifecycle event, and database
  triggers enforce this.
- **First purchase.** The academy admin chooses a plan. The server prices it, taxes it and invoices it once, then
  opens a checkout on the active gateway. The subscription starts only on the provider's verified payment.
- **Renewal.** The renewal invoice is issued ahead of the period's end. A verified payment extends the period.
  One invoice per period.
- **Failure.** A failed payment moves the subscription to `past_due`. Payment retries run for
  `SUBSCRIPTION_RETRY_DAYS`, then grace for `SUBSCRIPTION_GRACE_DAYS`, ending in recovery or expiry. Access and data
  retention are separate: expiry deletes nothing.
- **Plan changes** (decisions D7–D10):
  - upgrades are prorated, keep the renewal date, and activate on confirmed payment;
  - monthly → annual credits the unused month;
  - a pause extends the period by the time actually paused, at most 30 days;
  - downgrades take effect at the next boundary, with no refund.
- **Refunds.** Only the Super Admin can refund. Refunds are capped at the amount paid, are separate immutable rows,
  and always go through the original payment's gateway.
- **Entitlements and usage.** `requireFeature` and `withinLimit` apply after authorization. Limits are counted live
  under a per-academy guard row, so concurrent requests cannot pass a hard limit. Enforcement stays behind
  `ENTITLEMENT_ENFORCEMENT` until every academy is on a plan.

## Payment gateways and webhooks

- **Provider-neutral.** Business logic reaches a gateway only through `PaymentProvider` (`src/lib/paymentProvider.ts`)
  and the registry in `src/lib/paymentGateways.ts`.
- **Configuration.** The Super Admin configures, tests, enables and activates gateways at
  `/superadmin/payment-gateways`. Credentials are encrypted in the database with `PAYMENT_CREDENTIALS_KEY`, and are
  never returned or logged.
- **One active gateway.** Switching it affects new payments only. An invoice keeps the gateway of its first
  checkout, and confirmations, webhooks and refunds use the gateway recorded on the order or payment.
- **Razorpay** is implemented: orders, verification, capture, refunds and signed webhooks.
- **VyaparGateway** is registered but not implemented: its API contract isn't published (SAAS-017 is blocked).
- **Webhooks** (`POST /webhooks/:provider/subscription`):
  - every delivery is signature-verified, and the payment is read back from the provider;
  - amount and currency must match the invoice, or the money is flagged as unreconciled;
  - deliveries are idempotent on `provider + providerEventId`;
  - a failure answers 500 so the provider retries;
  - a browser redirect never activates anything.

## Notifications and delivery (SAAS-021)

Every notification goes through `notify()`, which applies the recipient's channels, pause, digest and the
academy's switches.

- **Email** goes to `EmailOutbox`, deduplicated for 10 minutes, and is delivered by a worker behind `MailTransport`.
  The worker claims each row, retries with backoff, and records `sent` or `failed`.
- **The bundled transports** are `outbox` (store only, the default), `log`, and `smtp` (nodemailer through `SMTP_HOST`,
  `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `MAIL_FROM`; SAAS-026). Without a delivering transport, registration codes, resets
  and invitations never arrive, and the API warns at boot. Codes and links are sent before any backlog of notifications,
  and their bodies are blanked 7 days after delivery.
- **Push.** Devices register at `POST /notifications/devices`, bound to their session. Each in-app notification
  queues a data-only hint `{ notificationId, category }`. The hint is held through quiet hours (IST) unless the
  notification is important, and sent through FCM HTTP v1 when `PUSH_PROVIDER=fcm`.

## Background jobs

`src/lib/scheduler.ts` runs every minute unless `LIVE_REMINDERS=off`:

- notifications per active academy;
- billing per active or suspended academy;
- session pruning;
- email and push delivery;
- webhook retry.

Every job is idempotent, and each runs under a database lease (`JobLease`, SAAS-022), so several processes never
run one job at once. `GET /superadmin/system` › `jobs` shows each lease and each job's last outcome.

## Audit and observability

Sensitive mutations write an immutable `AuditLog` entry in the same transaction. Failures are emitted as redacted
JSON signals, which the Super Admin reads at `GET /superadmin/observability`. A test sweeps the logs for secrets.

## Registration doors (October 2026)

Every self-registration confirms a 6-digit emailed code before an account exists: an Admin at `/signup/*` (`PendingSignup`,
SAAS-026); a learner through a join link (`POST /public/academies/:slug/register`), an invitation
(`/public/invitations/:token/*`, `/invitations` for the Admin), a course link (`/public/courses/:courseId/enroll`) or the
host sign-up (`POST /auth/register { workspace? }`); an instructor asking to teach
(`/public/academies/:slug/instructor-requests`, `pending` until an admin approves). The pending row (`PendingAccount`) fixes
the academy, role and address by trigger; `lib/pendingAccounts.ts` creates the account through the same path the door always
used, re-checking every rule. Admins add learners with `POST /students` (a 7-day set-password link). The full table is in
`docs/04-AUTHENTICATION-AUTHORIZATION.md` › Registration doors.

## Quiz sessions, the live room and course sales (October 2026)

- **Quiz sessions** (`lib/quizSessions.ts`, `/learning/…/quiz-session`): the server starts an attempt, holds its deadline
  (`timeLimit`) and answer sheet, and finishes it once — on submit, in the grace after the deadline, or by the scheduler when
  expired. Quiz time limits are therefore enforced.
- **Built-in live room** (`lib/liveRoom.ts`, `lib/liveSessions.ts`; `docs/modules/live-classes.md`): `POST /live/:id/start`,
  `join`, `end`; Jitsi Meet for trials, 8x8 JaaS in production with server-signed joins; recordings posted to
  `POST /webhooks/jaas` and kept for `LIVE_RECORDING_DAYS`. A production process without JaaS answers
  `503 LIVE_ROOM_NOT_CONFIGURED`.
- **Course sales** (`lib/coursePurchases.ts`, `lib/academyPayments.ts`, `routes/courseSales.ts`): a learner buys a priced
  course; the academy's own Razorpay credentials (encrypted, per environment, `/tenant/course-sales/*`) take the money; the
  enrolment opens once, on the gateway's confirmation (browser confirm, the academy's signed webhook, a status check or the
  `checkout-recovery` job). Separate from plan billing, which always uses the platform's gateway.
- **Platform branding** (`lib/branding.ts`): the Super Admin's uploaded logo and favicon, served at `/public/branding`.

## Environment

The full table is in [`docs/10-DEPLOYMENT.md`](../../docs/10-DEPLOYMENT.md); `.env.example` documents each
variable. The ones production must set:

- `DATABASE_URL`
- `JWT_SECRET` (32+ characters; the server refuses to start without it)
- `CORS_ORIGIN`, `APP_URL`, `NODE_ENV=production`
- `UPLOAD_DIR` on a persistent volume
- `TRUST_PROXY` behind a proxy

And, when used:

- `PAYMENT_CREDENTIALS_KEY`
- `SUBSCRIPTION_GRACE_DAYS` and `SUBSCRIPTION_RETRY_DAYS` before `ENTITLEMENT_ENFORCEMENT=on`
- `PUSH_PROVIDER` and `FCM_SERVICE_ACCOUNT`

Never commit secrets.

## Production

`deploy/deploy.sh` runs, in order: `npm ci`, `prisma generate`, `migrate deploy` (forward-only and additive),
`tenants:verify`, the web build, the release switch, the PM2 reload and the health checks.
Back up the database and `uploads/` before a deploy that includes migrations. Never run `seed` in production.

## Known limitations

- **SQLite** means one database writer and one API instance (the scheduler is in-process, under job leases).
- **Email.** Delivery needs an SMTP relay (`MAIL_TRANSPORT=smtp`) and authenticated DNS for `MAIL_FROM`; no email-API
  transport is bundled. Notification emails carry no `List-Unsubscribe`.
- **Push.** FCM needs a Firebase service account.
- **Live room.** Production needs 8x8 JaaS credentials; the public Jitsi server is for trials only.
- **VyaparGateway** awaits its API contract (SAAS-017).
- **Staging.** A deployment reachable by Razorpay's webhooks has not been tested yet (SAAS-016).
- **Refunds** are manual; a course refund made in an academy's Razorpay dashboard does not revoke access.
- **Refresh tokens** aren't implemented; tokens last 7 days. No MFA for any role.
- **Media** has no transcoding. Invoices and certificates are JSON only; invoices carry no seller GSTIN yet.
