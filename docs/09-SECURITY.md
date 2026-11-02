# 09 — Security

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

**Added by the conversion:** PAN and bank account are sealed with AES-256-GCM (`lib/credentialVault.ts`, `PAYMENT_CREDENTIALS_KEY`) and shown as last digits only; only the payout bank file opens the account number, for the Super Admin, and each export is audited. Payout CSV cells are neutralised against spreadsheet formulas. Ledgers (`MlmCvLedger`, `MlmWalletEntry`, `MlmMatchingRun`, `MlmRankHistory`) refuse edits and deletes by trigger, and a commission's amount can never change.

Status: ✅ in place · 🟨 partial · ⬜ planned (phase)

## Checklist

| Area | Control | Status |
| --- | --- | --- |
| Authentication | bcrypt (cost 10) password hashes; JWT HS256 with expiry; bearer transport | ✅ |
| | Refuse to boot in production with the default `JWT_SECRET` | ✅ (F1: `assertProductionSecrets`) |
| | Rate limit `/auth/*` (login, register, forgot/reset) | ✅ (F0: `RATE_LIMIT_AUTH_MAX`) |
| | Password reset tokens stored hashed, single-use, expiring | ✅ (F1: SHA-256, 1 hour, newer request invalidates older) |
| Tenant isolation | Every query on an academy-owned model confined to the caller's academy at the query boundary (Prisma extension, `lib/tenancy.ts`) | ✅ (SAAS-000) |
| | Academy taken from the account's row, never from the client; stale token claim → 401 | ✅ (SAAS-000: `lib/requestContext.ts`) |
| | Foreign keys a write names checked to belong to the same academy | ✅ (SAAS-000) |
| | A query with no academy context refused, not run across every academy (fail closed) | ✅ (SAAS-000) |
| | Platform-wide reads confined to named exceptions: Super Admin router, scheduler, sign-in/registration email, reset token, credential ID | ✅ (SAAS-000) |
| | Data verified before an isolated API serves it (`npm run tenants:verify`, deploy gate) | ✅ (SAAS-000) |
| | No account enumeration on forgot-password | ✅ (F1) |
| Authorization | `requireAuth` / `requireRole` on every non-public route | ✅ |
| | Instructor scope derived from the token, never from the client | ✅ (F2) |
| | Learner ownership checks on learning, notifications, calendar, certificates | ✅ (F2) |
| | Admin-only actions (suspend, revoke, templates, settings, instructors, categories) | ✅ |
| IDOR | Every id in a path is checked against the caller's scope | ✅ (F2, `permissions.test.ts`) |
| Injection | Prisma parameterised queries everywhere; no raw SQL | ✅ |
| XSS | The API returns JSON only; React escapes output; help/lesson markdown is rendered by a safe renderer that never injects HTML (`ArticleBody`) | ✅ |
| Mass assignment | Route handlers copy known fields explicitly; `zod` schemas strip unknown keys; public registration can no longer pick a role (fixed in F0) | ✅ |
| Input validation | Domain validators (`validate*`) for business shapes | ✅ |
| | Request bodies validated (`zod`, unknown keys stripped, 400 not 500) | ✅ (every router with a write route) |
| | Query parameters validated: fixed sets refused when unknown, ids and free text bounded | ✅ (F16: `validation.test.ts`) |
| | Page size capped at 500, page number must be a positive integer | ✅ (F16: `paging`; `?pageSize=100000` used to return whole tables) |
| Client-trusted values | Quiz score/passed, completion, enrollment status, prices, roles | ✅ (quiz answers scored on the server; completion derives from stored progress; roles/ownership from the token) |
| Error handling | Central `errorHandler`; 500s hide details; stack traces only in server logs | ✅ |
| | Prisma known errors mapped (P2025 → 404, P2002/P2003 → 409, validation → 400) | ✅ (F0) |
| HTTP hardening | `helmet` headers, `express-rate-limit` (global + auth), JSON body limit 1 MB, `x-powered-by` off, JSON 404 for unknown routes | ✅ (F0) |
| CORS | Single allowed origin from `CORS_ORIGIN` | ✅ |
| Uploads | Allow-listed MIME types and extensions, per-kind size limits, the file's first bytes checked against its type (SAAS-023), random storage names, served with a quote-free `Content-Disposition`/nosniff to signed-in accounts only, never executed | ✅ (F5, SAAS-023) |
| Media reads | A file is read only where its reader may open it (`lib/mediaAccess.ts`): the uploader; an academy admin; an instructor for staff material and for hand-ins to courses they teach; a learner for material in a published lesson of a course they are enrolled in, a free-preview lesson, or a published assignment's attachments. Otherwise 404, as for no file; another academy's file is never found; no delete or overwrite endpoint exists | ✅ (SAAS-023) |
| Secrets | `.env` git-ignored; `.env.example` has no real values; token never logged | ✅ |
| Sensitive data | `passwordHash` never serialised (`toProfile`); notification/settings routes return only the caller's data | ✅ (F0) |
| Open redirect | `?next=` after sign-in is followed only when it is a same-site path | ✅ (F16: `lib/safeNext.ts`, unit-tested) |
| Dependencies | `npm audit` reviewed; nothing exploitable ships | 🟨 (F16: 7 advisories, all reviewed — see below) |
| Logging | Request errors logged server-side without bodies | ✅ |

## Threat notes specific to this product

- **Grades and certificates are valuable** — only staff routes can write reviews/certificates; learners can
  only *claim* a certificate the server already marked pending for them (F9 enforces ownership).
- **Instructor lateral access** — an instructor cannot read another instructor's courses, learners, submissions,
  quizzes, assignments, certificates, live classes, calendar rows or reports (F2; 404 so ids cannot be probed).
- **Public verification** — returns only what a certificate prints (name, course, dates, status); no
  email or account details.
- **Paid content** — lesson bodies (video files, articles, documents, quiz questions, assignment briefs)
  are returned only to enrolled learners and staff of the course; the public catalog and non-enrolled
  learners get the outline plus published free-preview lessons (F2).
- **Limits cannot be raced** (SAAS-011). A limit check and the write it guards are one transaction that first
  locks the academy's guard row, so parallel requests cannot all see the same stale usage (tested with eight
  concurrent course creations and five concurrent sign-ups).
- **The §47 security list has one test each** (`routes/securityAudit.test.ts`, SAAS-016), attempted over
  HTTP:
  - cross-tenant access and forged tenant ids (body, query, headers);
  - unauthorised plan changes (staff below admin, an admin without `settings.edit`, another academy's change,
    the platform's endpoints) and unauthorised refunds;
  - forged and duplicate webhooks;
  - expired-subscription bypass (402 under enforcement, and access restored by the rollback);
  - a client setting its own price, plan or entitlement.
- **Payments go through one adapter, and only the provider's word counts** (SAAS-009).
  - The LMS reaches Razorpay only through `lib/razorpay.ts`, over HTTPS, with no SDK. A source test
    enforces this.
  - Gateway credentials are configured by the Super Admin and stored only encrypted (SAAS-017):
    - AES-256-GCM under `PAYMENT_CREDENTIALS_KEY`, a deployment secret that is never in the database, in
      source or in a response;
    - a value sealed under another key, or altered, is refused, not decrypted;
    - no API response, log line or audit entry carries a credential. The panel sees a masked hint and which
      secrets are set; a secret is write-only, and a blank one on save keeps the stored value;
    - test and live credentials are stored apart. A Razorpay key is refused in the wrong environment's slot, and
      each order is served by the credentials of the environment that created it;
    - `RAZORPAY_*` in the environment is ignored.
  - Only the publishable key id reaches the browser. A test scans every tracked file for the configured values.
  - The backend chooses the gateway (SAAS-017). A new invoice goes through the active gateway. Everything that
    exists goes through the gateway recorded on it: another checkout, a confirmation, a webhook, a refund. That
    holds whichever gateway is active now, and the database holds an invoice to its gateway. Nothing in a
    request names a gateway, an amount or an academy.
  - A checkout's amount is the invoice's, checked against the invoice by the database.
  - A browser's "payment succeeded" activates nothing. The checkout signature (HMAC-SHA256 under the key
    secret) must verify, and the payment is then read from Razorpay server to server. Only that answer is
    recorded, once.
  - Webhook signatures are verified the same way, and every webhook is refused while no secret is set.
  - Webhooks are idempotent (SAAS-010):
    - one receipt per provider event id;
    - a replay of the same body under a new id is ignored by its hash;
    - two deliveries racing each other never process together;
    - every step after recording is safe to repeat, so a retry finishes the work without doing any of it
      twice (tested with duplicates, concurrent deliveries, replays and interrupted attempts).
  - Card data never passes through the LMS: Razorpay's frame collects it, and only the network and last four
    digits come back.
- **Every sensitive mutation is audited, and the trail cannot be rewritten** (SAAS-014).
  - Each §36 action is written in the same transaction as the change: plans, subscriptions, plan changes,
    invoices, payments, refunds, entitlements and limits.
  - Each entry names who did it. A person is named from the token. What no person did names itself: `system` with
    the job, or `provider` with the provider. Such an entry never borrows a person.
  - The database refuses to change or delete an entry.
- **Nothing sensitive reaches the log** (SAAS-014).
  - All runtime logging goes through `lib/observe.ts`, which redacts every field before it is written or kept.
    - A value under a key like password, token, secret, signature, authorization, card number or CVV is dropped.
    - Card numbers, JWTs, bearer credentials, provider keys, `name=secret` pairs and one-time link tokens are
      masked wherever they appear in text.
  - Faults log the path without its query string.
  - In production the mail log prints only the envelope, never a reset link.
  - Tests enforce this:
    - A log sweep runs sign-in, password reset, payment, webhook and job failures and a server fault, and
      finds none of the secrets it used.
    - A source scan allows `console` only in the logger, the mail log and the start-up line.
- **Financial history is append-only** (SAAS-008).
  - Invoices are fixed at issue.
  - A settled payment, a refund and an invoice are never updated or deleted, by database triggers.
  - Refunds are capped at the payment in the database.
  - No table has a column that could hold a card number or security code (tested), payment methods keep only a
    provider reference and four digits, and the billing code logs nothing (tested through a full flow).
- **Subscription status and price cannot be written** (SAAS-004).
  - A status moves only through a named transition that writes its lifecycle event first. The database refuses
    a status change the latest event does not describe, a price or plan change without a matching plan-change
    event, and any delete.
  - A person can never declare a payment: only a verified provider event or the scheduler can. And only the
    platform or a provider can create a subscription, at the price the plan version sets.
  - One live subscription per academy is a unique index, not a check that can race.
- **Plan prices are platform configuration with history** (SAAS-001) — only the platform context writes
  plans, and a signed-in writer must be a super admin; an academy's context is refused whatever route
  calls the service. A plan's terms are append-only `PlanVersion` rows guarded by database triggers, so no
  code path, raw query included, can rewrite the price a past sale was made at. The amount a new
  subscription is charged is read from the plan's current version (`planForNewSubscription`), never from
  the request, and every amount is an integer count of paise, checked by the database as well as the domain.

## Dependency advisories (reviewed 18 Sep 2026)

`npm audit` reports 7 advisories in 3 packages. None is exploitable in what is served:

| Package | Severity | Reached by | Decision |
| --- | --- | --- | --- |
| `@vitest/mocker` (via `vitest`) | moderate | Test runner only — a `devDependency`, never bundled or served | Left. The fix is `vitest@5`, a major upgrade of the test runner for a path-traversal issue that only affects running tests on untrusted code. Revisit at F18. |
| `deepmerge-ts` (via `@prisma/config` → `prisma`) | high | The Prisma **CLI**, a `devDependency` used for migrations and seeding. `@prisma/client`, which the API actually runs, does not depend on it | Left. Stack exhaustion while merging a recursive config object; the config is ours, not user input. Revisit at F18. |
| `react-router` (via `react-router-dom`) | moderate | Ships to the browser | Two issues. The SSR hydration one (`deserializeErrors`) does not apply — this app has no SSR. The open redirect via a backslash in `<Link>`/`useNavigate` **did** apply to the one place the app navigates to a value from the address bar, the `?next=` handed to sign-in; that is now validated by `lib/safeNext.ts` regardless of the router version. Upgrading to `react-router@7` is a major change across every route and belongs in its own piece of work. |

The `?next=` guard is worth stating plainly, because the original check looked right and was not:
it required a leading `/` and refused `//`, but allowed `/\`. A browser reads `/\example.test` as
`//example.test`, so signing in would have carried the visitor off the site. The replacement accepts a
path on this site and nothing else — no backslashes, no control characters, no protocol-relative form
in either spelling.

## Hardening since the checklist (October 2026)

In place, each with a test (details in `14-LAUNCH-CHECKLIST.md` and `06-BUSINESS-RULES.md`):

- ✅ Email verification before any self-registered account exists; codes HMAC-hashed, 15-minute expiry, 5 attempts and 5 sends, an attempt spent before comparison, per-address send limits (`RATE_LIMIT_EMAIL_MAX`).
- ✅ Per-account sign-in throttle (`RATE_LIMIT_ACCOUNT_MAX`) beside the per-IP one; equal timing for an unknown email and a wrong password; reset links budgeted per address and single-use under concurrency.
- ✅ The static test OTP refused wherever the live site is named, whatever `NODE_ENV` says; the demo seed refused on anything that looks like production (`prisma/seedGuard.ts`).
- ✅ Production refuses to boot with `TENANT_ENFORCEMENT=off`; plan enforcement on by default there; boot warnings for a non-https `APP_URL` and for registration without a delivering mail transport.
- ✅ A gateway in test mode takes no production payment; a `refunded` payment never settles; late authorizations are not captured; webhook replays for course payments are no-ops (`CoursePaymentEvent`).
- ✅ Invitation tokens and session ids stored hashed or server-side only; invitations scoped to the inviting Admin's workspace and used once.
- ✅ Quiz deadlines and answer sheets held by the server; a client cannot extend or reorder them.
- ✅ Live-room joins require enrolment, register the learner while there is room (or the course's staff with `live.manage`); JaaS joins are server-signed so only the host moderates; the public Jitsi server is refused in production unless explicitly allowed.
- ✅ Uploads checked against their bytes (content signature), branding files judged in memory before they are stored, recordings served only to the academy's learners with a two-hour grant for browsers.
- ✅ Deploy webhook signed with `X-Hub-Signature-256` and spawning `deploy.sh` with a clean environment; `/health` checks the database.

Open (owner's decision or work; `14-LAUNCH-CHECKLIST.md` A13–A16, A19):

- ⬜ **Content-Security-Policy** for the web app. The 7-day token lives in `localStorage`, so any XSS steals it.
- ⬜ **MFA** for the Super Admin (none exists for any role).
- ⬜ **Verify on the server** that `TRUST_PROXY`, `NODE_ENV`, `APP_URL`, `MAIL_FROM` are right and that no `APP_ENV`/`TEST_OTP_*`/`SIGNUP_EMAIL_VERIFICATION=off` is set.
- ⬜ **Off-server backups and a rehearsed restore**; `.env` (JWT and gateway keys) is in no backup.
- ⬜ Duplicate `Referrer-Policy`/`X-XSS-Protection` headers added by the CloudPanel vhost on top of the API's.
- ⬜ Notification emails carry no `List-Unsubscribe`; per-academy Reply-To is in the body, not a header.
