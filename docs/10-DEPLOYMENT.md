# 10 — Deployment

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

**Conversion rollout, in order, on a copy of production first:** back up with `npm run db:backup`; run `npx prisma migrate deploy`; run `npm run platform:convert` (a dry run) and read it; run it with `--apply`, which archives other academies and renames the workspace without deleting anything. `PAYMENT_CREDENTIALS_KEY` must be set before affiliates can submit KYC: without it the KYC form answers 503, and losing it makes sealed PAN and account numbers unreadable, so back it up apart from the database. Before rollout, check for open orders on academy Razorpay accounts: new sales use the platform gateway only.

Status: deployed. The scripts in `deploy/` provision the server and ship a release; the exact
commands are below.

## Components

| Component | Runtime | Port | Notes |
| --- | --- | --- | --- |
| `apps/api` | Node ≥ 20 | 4000 | Express; SQLite file on a persistent volume; uploads directory on a persistent volume |
| `apps/web` | static files | 80/443 | Vite build output served by nginx (or any static host) with SPA fallback and `/api` proxied to the API |

## Environment

### `apps/api/.env`

| Variable | Required | Example | Purpose |
| --- | --- | --- | --- |
| `DATABASE_URL` | yes | `file:./data/prod.db` | SQLite path (Prisma) |
| `JWT_SECRET` | yes | long random string | token signing — the API refuses to start in production with the dev default (F1) |
| `JWT_EXPIRES_IN` | no | `7d` | |
| `PORT` | no | `4000` | |
| `CORS_ORIGIN` | yes | `https://lms.example.com` | the web app's origin |
| `NODE_ENV` | yes | `production` | |
| `UPLOAD_DIR` | no | `./data/uploads` | uploaded media; must be on a persistent volume |
| `APP_URL` | yes | `https://lms.example.com` | base of links in emails (falls back to `CORS_ORIGIN`) |
| `LIVE_REMINDERS` | no | `off` disables the in-process scheduler (reminders, digests, billing, delivery, pruning). Several instances may leave it on: each job runs under a lease (SAAS-022) |
| `MAIL_TRANSPORT` | yes in production | `outbox` (default) / `log` / `smtp` | every email is stored in `EmailOutbox` (deduplicated for 10 minutes). `outbox` never sends; `log` prints it and the delivery worker marks it sent; `smtp` delivers through `SMTP_*` (SAAS-026). The worker retries with backoff (1, 5, 30, 120, 720 min) and records `sent`/`failed` (SAAS-021). Without a delivering transport, registration codes, password resets and invitations never arrive — the API warns at boot |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` / `MAIL_FROM` | with `smtp` | `smtp.example.com` / `587` (465 = TLS) / … / `ZuviloAI <noreply@example.com>` | the relay and the platform's sending address; the API refuses to start with `smtp` and no `SMTP_HOST` or `MAIL_FROM`. `SMTP_PASS` is a secret |
| `PAYMENT_SANDBOX` | **never in production** | `on` / unset | development and E2E only (SAAS-030): while no real gateway is active, checkout goes to the sandbox's test page and outcomes arrive as signed webhooks. The API refuses to start with it when `NODE_ENV=production`; every `/sandbox` route is 404 while it is off |
| `SALES_NOTIFY_EMAIL` | no | `sales@example.com` | the website's demo, sales and support requests are emailed here as they arrive; they are always in the Super Admin's inbox too (SAAS-027) |
| `SIGNUP_EMAIL_VERIFICATION` | no | `on` (default) / `off` | self-serve registration emails a 6-digit code (15 min, 5 attempts) before the academy is created (SAAS-026, D27). `off` only where no email can be delivered yet |
| `JITSI_DOMAIN` | no | `meet.jit.si` | the built-in live room's public Jitsi server when JaaS is not configured — **trial only**: a host must sign in to Jitsi to moderate, learners otherwise wait in its lobby, embedded calls are time-limited, nothing is recorded |
| `JAAS_APP_ID` / `JAAS_KID` / `JAAS_PRIVATE_KEY` (or `JAAS_PRIVATE_KEY_FILE`) | **yes, for live classes in production** | `vpaas-magic-cookie-…` / key id / RS256 PEM | 8x8 Jitsi as a Service: every join is a token the API signs, so the host moderates and learners don't. The private key is a secret |
| `JAAS_WEBHOOK_SECRET` | to keep recordings | from the JaaS console | verifies `POST /api/webhooks/jaas` (`RECORDING_UPLOADED`); without it nothing is recorded |
| `LIVE_RECORDING_DAYS` | no | `30` | how long a kept recording stays available to learners |
| `PUSH_PROVIDER` | no | `fcm` or empty | push hints for in-app notifications; empty = none queued or sent |
| `FCM_SERVICE_ACCOUNT` | with `fcm` | Firebase service-account JSON, raw or base64 | a secret: never commit or log it. The FCM HTTP v1 provider signs its own access tokens from it |
| `TRUST_PROXY` | behind a proxy | `1` | number of proxy hops so rate limiting sees the client ip |
| `RATE_LIMIT_MAX` / `RATE_LIMIT_AUTH_MAX` / `RATE_LIMIT_WINDOW_MS` | no | `1000` / `30` / `900000` | per-ip limits |
| `DEFAULT_TENANT_SLUG` | no | `default` | the academy visitors who are not signed in see — public catalog, sign-up, certificate pages. The tenant migration creates the existing academy with slug `default` |
| `TENANT_ENFORCEMENT` | no | `on` (default) / `off` | tenant isolation. `off` is a development-only rollback switch: **a production API refuses to start with it** (multi-admin SaaS) — see **Tenancy** below |
| `SUBSCRIPTION_GRACE_DAYS` | before enforcement | *(none)* | days of access an overdue academy keeps after payment retries are exhausted (0–90). Unset: no grace period can start, so an overdue academy keeps its access. Each grace period's end is fixed when it starts. |
| `SUBSCRIPTION_RETRY_DAYS` | before enforcement | *(none)* | days an overdue academy has to pay before retries count as exhausted and its grace period starts (1–30; SAAS-012). Unset: retries never run out, and an overdue academy stays past due with its access. |
| `SUBSCRIPTION_INVOICE_LEAD_DAYS` | no | `7` (default) | days before a period ends that its renewal invoice is issued (0–31) |
| `SUBSCRIPTION_REPEAT_TRIALS` | no | `off` (default) / `on` | whether an academy that has had a free trial may start another |
| *(tax rules)* | before charging | *(none)* | not an environment variable: tax rules are data, set by a super admin through `lib/billing.ts` `setTaxRule` (an endpoint arrives with SAAS-013). With no rule for an academy's country, it is charged no tax. |
| `ENTITLEMENT_ENFORCEMENT` | no | production: `on` unless set `off`; elsewhere `off` unless set `on` | `off` in production is the emergency rollback and is warned about at boot. subscription, plan-feature and usage-limit enforcement (SAAS-003, SAAS-025). `deploy/api.env.example` sets it `on` for a new deployment: a new academy starts its free trial (self-serve) or buys a plan before it can build, and staff see the modules outside the plan as locked. On a server that already has academies, put each on a plan or trial first: with it on, an academy with no plan gets `402 SUBSCRIPTION_REQUIRED` on every gated write and feature route — including public sign-up on the academy the host serves. Requires `SUBSCRIPTION_GRACE_DAYS` and `SUBSCRIPTION_RETRY_DAYS` (the API refuses to start without them). The development `.env` has it on |
| `PAYMENT_CREDENTIALS_KEY` | to take payments online | *(secret: `openssl rand -hex 32`)* | encrypts payment-gateway credentials at rest (SAAS-017): 32 bytes, as 64 hex characters or base64. The API refuses to start with a malformed one. Keep it with the other deployment secrets. With a different key, stored credentials cannot be read and must be entered again. Unset: gateways cannot be configured, and invoices are paid by hand. |
| *(payment gateways)* | to take payments online | *(none)* | not environment variables. A Super Admin configures them at `/superadmin/payment-gateways`: Razorpay's key id, key secret and webhook secret, test or live, enabled, and which gateway is active. `PAYMENT_PROVIDER` and `RAZORPAY_*` are ignored: a deployment that had them runs `npm run gateways:import-env -w @syniastrolms/api` once, then removes them. |
| `PLATFORM_REPLY_TO` | no | `support@example.com` | reply-to on email the platform sends as itself (a super admin's reset link) |
| `DEPLOY_WEBHOOK_SECRET` | no | long random string | enables `POST /api/deploy/webhook` (GitHub push → `deploy.sh`); unset means the route 404s |
| `DEPLOY_BRANCH` | with the above | `claude/zen-bardeen-iaetts` | must match `BRANCH` — pushes to any other branch are ignored, not deployed |

### `apps/web/.env`

| Variable | Value |
| --- | --- |
| `VITE_API_MODE` | `http` |
| `VITE_API_BASE_URL` | the API's public URL (e.g. `https://lms.example.com/api`) |

## The servers

One CloudPanel box hosts both sites. The app runs as each site's CloudPanel *site user*, with no
root anywhere in the deploy path, and the same `deploy/` scripts serve both: they derive the site
from their own location and read the per-site values from `<site>/deploy.conf` and `apps/api/.env`.

| | Test | Live |
| --- | --- | --- |
| Public URL | `https://astrologylms.synilogictech.in` | `https://zuviloai.com` |
| Host | `82.25.115.114` (Ubuntu 24.04, CloudPanel) | same box |
| Site user · group | `claude3` · `astrologylms` | `zuviloai` · `zuviloai` (new site; bootstrap it) |
| Site dir | `/home/astrologylms/htdocs/astrologylms.synilogictech.in` | `/home/zuviloai/htdocs/zuviloai.com` |
| Edge / TLS | Cloudflare proxied; origin holds a self-signed cert (*Full* mode) | direct DNS; Let's Encrypt on the origin, managed by CloudPanel |
| Vhost | every path → `127.0.0.1:3700` | every path → `127.0.0.1:4110` |
| Proxy hops (`TRUST_PROXY`) | 2 (Cloudflare, nginx) | 1 (nginx) |
| PM2 process | `astrologylms-api` | `zuviloai.com-api` |
| Branch (`deploy.conf`) | `claude/zen-bardeen-iaetts` | `production` |

Inside a site dir: `app/` (git checkout), `web/` → symlink to `releases/web-<stamp>`, `data/`
(`prod.db` and `uploads/` — the only state), `deploy.conf` (`BRANCH`, `PM2_NAME`; untracked).
Logs are `~/logs/api.{out,error}.log` for the site user.

Because each vhost forwards everything to one port, the API process also serves the SPA
(`apps/api/src/web.ts`): the API is mounted under `/api`, `/assets/*` is cached for a year, and
any other path returns `index.html` for the client-side router. `WEB_DIST` switches this on; it
is unset in development, where Vite serves the web app and the API stays at `/`.

### Proxy hops and the visitor's address

Neither CloudPanel's nginx nor Cloudflare restores the real client address, so `TRUST_PROXY`
must equal the number of hops — measured on the box with a throwaway listener on the site's
port and a request carrying a forged `X-Forwarded-For: 9.9.9.9`:

```
test:  x-forwarded-for: 9.9.9.9, <the visitor>, <cloudflare edge>   → TRUST_PROXY=2
live:  x-forwarded-for: 9.9.9.9, <the visitor>                      → TRUST_PROXY=1
```

Express takes that many addresses from the right, so the forged value is ignored and the per-ip
rate limits key on the visitor. On the test site a request sent straight to the origin IP with
a spoofed `Host` header carries only one hop, so the sender could forge their address; to
close that, allow ports 80/443 only from [Cloudflare's ranges](https://www.cloudflare.com/ips/)
in CloudPanel → Security → Firewall. The live site is not proxied, so it has no such gap.

## Files

Everything lives in `deploy/`:

| File | Runs | Purpose |
| --- | --- | --- |
| `bootstrap.sh` | server, once per site, as the site user | Takes `SITE`, `PUBLIC`, `PORT`, `BRANCH`, `TRUST_PROXY` from the environment. Directory layout, `deploy.conf`, GitHub deploy key, clone, `apps/api/.env` from the template with generated `JWT_SECRET` and `DEPLOY_WEBHOOK_SECRET`, `@reboot pm2 resurrect` cron. Self-contained and re-runnable. |
| `deploy.sh` | server, each deploy | `git fetch` → `reset --hard origin/$BRANCH` → `npm ci` (when the lockfile moved) → `prisma generate` → `migrate deploy` → web build → symlink swap → PM2 reload → `/api/health` and vhost check. |
| `ecosystem.config.cjs` | — | The PM2 process definition; name from `deploy.conf`. |
| `api.env.example` | — | The `apps/api/.env` template with `__PLACEHOLDER__`s that `bootstrap.sh` fills. |

`BRANCH=… deploy.sh` overrides the branch for one run; `SKIP_FETCH=1` ships the current checkout.

## First-time setup (per site)

The repository is private, so each site authenticates to GitHub with its own read-only deploy
key. `bootstrap.sh` generates the key, prints it and stops; register it and run the script
again, at which point it clones and finishes. The values below are the live site's; the test
site uses `claude3`, its own `SITE`, `PORT=3700`, `TRUST_PROXY=2` and its branch.

```bash
# 1. from your machine — the script is standalone, the repo is not on the box yet
scp deploy/bootstrap.sh zuviloai@<host>:~/
ssh zuviloai@<host> 'SITE=/home/zuviloai/htdocs/zuviloai.com PUBLIC=https://zuviloai.com   PORT=4110 BRANCH=production TRUST_PROXY=1 ./bootstrap.sh'    # prints the deploy key, then stops

# 2. register the printed key as a READ-ONLY deploy key
#    https://github.com/SynilogicTeam/astrologylms/settings/keys/new — "Allow write access" unchecked

# 3. on the server, same command again — clones, writes .env and deploy.conf, sets the reboot cron
# 4. first deploy
/home/zuviloai/htdocs/zuviloai.com/app/deploy/deploy.sh

# 5. the platform's Super Admin (password from the environment, never stored in a file)
cd /home/zuviloai/htdocs/zuviloai.com/app/apps/api && \
  SUPERADMIN_EMAIL=you@example.com SUPERADMIN_PASSWORD='<strong password>' npm run superadmin:create
```

`deploy.sh` runs `npm run seed:platform` on every deploy: the plan catalogue, the GST rule and the Help
Centre, added only where missing — never edited or deleted. Academies are created by the Super Admin
(Subscriptions › Academies › New academy), each starting empty with its first admin, who starts the free
trial or buys a plan from the academy's Billing page.

**A demo academy for testing on a real server** — `npm run seed:demo-academy` (`scripts/seed-demo-academy.ts`)
creates a *new* academy (`DEMO_ACADEMY_SLUG`, default `demo-academy`) with sample courses, instructors,
students, a year of enrolments, quizzes, assignments, certificates and live classes, on a free trial of
`DEMO_ACADEMY_PLAN` (default `PRO`). It only adds: it refuses if the address, the email domain
(`DEMO_EMAIL_DOMAIN`, default the reserved `demo.syniastrolms.test`) or the certificate prefix is in use,
and never touches another academy. The password is `DEMO_ACADEMY_PASSWORD` or a generated one printed once.
Archive the academy from Super Admin › Academies when testing is over.

The demo academy (`npm run seed:demo`) is for development only. It **deletes every academy row** before
inserting the demo data, and refuses to run with `NODE_ENV=production`.

Without the deploy key the clone step cannot run; the first deploy can instead be seeded from a
machine that has the code, by pushing straight into the site's checkout over ssh:

```bash
ssh zuviloai@<host> 'git init -q -b production /home/zuviloai/htdocs/zuviloai.com/app   && cd /home/zuviloai/htdocs/zuviloai.com/app && git config receive.denyCurrentBranch updateInstead'
git push zuviloai@<host>:/home/zuviloai/htdocs/zuviloai.com/app production
ssh zuviloai@<host> 'SKIP_FETCH=1 /home/zuviloai/htdocs/zuviloai.com/app/deploy/deploy.sh'
```

## Routine deploy

Push to the site's branch; with the webhook configured (next section) that is the whole deploy.
By hand:

```bash
ssh zuviloai@<host> /home/zuviloai/htdocs/zuviloai.com/app/deploy/deploy.sh      # live
ssh claude3@82.25.115.114 /home/astrologylms/htdocs/astrologylms.synilogictech.in/app/deploy/deploy.sh   # test
```

Promotion is a branch operation: the test site follows `claude/zen-bardeen-iaetts`, the live
site follows `production`. What has been verified on test is moved to live by merging (or
fast-forwarding) `production` to that commit and pushing.

`deploy.sh` uses `git reset --hard origin/$BRANCH` rather than `git pull`: the server's
checkout is disposable and must match the branch exactly, with no chance of a merge commit
or a conflict stopping a deploy. `reset --hard` leaves untracked and ignored files alone,
which is how `apps/api/.env` survives — so never add `git clean` to that script.

`npm ci` is skipped when `package-lock.json` has not moved, since it is by far the slowest
step. The web build is published by an atomic symlink swap, so the API never serves a
half-copied directory; the API restarts, which is a sub-second gap. `data/` is never touched.

## Tenancy

The API isolates academies (SAAS-000, `.claude/saas/progress.md`). Three things about deploying it:

**The first deploy that includes it runs the `tenant_foundation` migration.** It adds a `Tenant`
table, makes the existing academy Tenant #1 (`tenant-1`, slug `default`) and gives every
academy-owned table a required `tenantId`, assigning every existing row to Tenant #1. It rebuilds 33
tables, so **take a backup first** (see **Backups**). The migration is all-or-nothing: Prisma does
not wrap SQLite migrations in a transaction, so this one opens its own and checks its backfill before
it commits. If a check fails the database is left exactly as it was, and `migrate deploy` stops with
`P3018`. To retry after fixing the cause:

```bash
cd apps/api && npx prisma migrate resolve --rolled-back 20260921120000_tenant_foundation
```

**`deploy.sh` verifies the data before restarting.** After migrating it runs
`npm run tenants:verify`, which reads every academy-owned row and every relation between them
and fails if a row names no academy, an account breaks the platform/academy rule, or a relation
joins two academies. It changes nothing and can be run at any time. The web app is now built
*before* the migration, so the old process runs against the new schema only for the few seconds
between migrating and restarting — it keeps reading, but its writes to academy tables fail in that
window (it does not know `tenantId`). Deploy in a quiet period.

**`TENANT_ENFORCEMENT=off` is the rollback switch.** It keeps stamping new rows with their academy
but stops filtering reads and allows work with no academy context. It is only safe while the
platform has one academy. Before switching back on, run `npm run tenants:verify`.
## Continuous deploy (GitHub webhook)

A push to a site's branch on GitHub deploys it, no SSH needed. GitHub POSTs to
`POST /api/deploy/webhook`; `apps/api/src/routes/deploy-webhook.ts` checks the `X-Hub-Signature-256`
HMAC over the raw body against `DEPLOY_WEBHOOK_SECRET` (either of GitHub's encodings — the form
default or JSON), answers `200` to the creation-time `ping`, `204` for any other branch or event,
`404` if the secret is unset, and otherwise answers `202` and starts `deploy.sh`, logging to the
site user's `~/deploy-webhook.log`.

Three things learned on the first live run, all now handled:

- **The script must outlive the process that started it.** PM2 tree-kills the old API process's
  descendants on `pm2 reload`, and `deploy.sh` *is* a descendant of the API that spawned it — so
  the first webhook-driven run died in the middle of its own reload step. It is launched through
  `setsid -f`, which re-parents it to init first. The cost: its exit code is not observable from
  the API; its outcome is in `~/deploy-webhook.log`.
- **GitHub fires before the commit is always fetchable.** The first run fetched the previous tip
  and reported success. The webhook passes the pushed commit as `DEPLOY_EXPECT_SHA`, and
  `deploy.sh` re-fetches for up to a minute until `origin/$BRANCH` is at it (then deploys the
  current tip with a message rather than failing).
- **One deploy at a time.** `deploy.sh` takes `flock` on `<site>/deploy.lock`; a second run — a
  manual one alongside the webhook's — exits at once saying so.

Setup, per site (GitHub-side; the deploy box and this assistant have no GitHub credentials):

1. **Deploy key** (read-only) — printed by `bootstrap.sh` — at
   `https://github.com/SynilogicTeam/astrologylms/settings/keys/new`. Check with
   `ssh <user>@82.25.115.114 'ssh -T git@github.com'` → "successfully authenticated".
2. **Webhook** at `https://github.com/SynilogicTeam/astrologylms/settings/hooks/new`: Payload URL
   `https://<site>/api/deploy/webhook`, secret = `DEPLOY_WEBHOOK_SECRET` from the site's
   `apps/api/.env`, "Just the push event". The content type may be either option.
3. `DEPLOY_BRANCH` in `.env` must equal `BRANCH` in `deploy.conf` (`bootstrap.sh` writes both).

Register the key before the webhook: a webhook that fires first runs `deploy.sh`, which fails at
`git fetch`. Manual deploys (`ssh … deploy.sh`) keep working unchanged.

Current wiring: `production` → `zuviloai.com` (live); `claude/zen-bardeen-iaetts` →
`astrologylms.synilogictech.in` (test). Promotion is merging or fast-forwarding `production`.

## Operating

```bash
pm2 status                                   # is the API up (as claude3)
pm2 logs astrologylms-api                    # application log
curl -fsS localhost:3700/api/health          # behind the vhost
tail -f /home/astrologylms/logs/nginx/error.log
```

**Failures (SAAS-014).** Anything an operator must act on is one JSON line in the application log, keyed
`observability`:
- `payment.failed` and `payment.unmatched` (money taken that does not settle its invoice);
- `refund.failed`, `webhook.failed`, `job.failed` and `request.failed` (a 500);
- `subscription.state_changed`, `entitlement.denied` and `limit.reached`.

Every line is redacted before it is written. Find failures with
`pm2 logs astrologylms-api | grep '"level":"error"'`. The Super Admin reads the latest warnings and errors, with
counts since start-up, at `GET /api/superadmin/observability`. The window lives in memory and restarts with the
process; the log is the durable record. Who changed what is in the audit trail (`GET /api/superadmin/audit`).

**Billing jobs (SAAS-012).** These run on the same every-minute scheduler as the notification jobs, so
`LIVE_REMINDERS=off` stops both. Each academy's jobs run inside its own context, in this order:
- `trial-expiry-check`, `pause-expiry` and `scheduled-cancellation`;
- `invoice-generation`, then `subscription-renewal-check`;
- `past-due-retry`, `grace-period-expiry` and `usage-reconciliation`.

`webhook-retry` then runs once for the platform. Every job is idempotent, so an overlapping or repeated tick
changes nothing twice. A failure is a `job.failed` signal naming the job and the subscription, and the next
tick retries it. Run several API instances only with the scheduler switched off on all but one.

**Razorpay webhooks (SAAS-010).** In the Razorpay dashboard (Settings → Webhooks):
- add `https://<your API host>/api/webhooks/razorpay/subscription`;
- choose a secret and enter the same value as Razorpay's webhook secret at `/superadmin/payment-gateways`
  (it is separate from the key secret);
- enable `payment.authorized`, `payment.captured`, `payment.failed`, `order.paid`, `refund.processed` and
  `refund.failed`.

Receipts and failures are listed at `GET /api/superadmin/webhooks`. A failed one shows as a
`webhook.failed` signal, and Razorpay retries it.

Rolling back means pointing the server at an earlier commit:

```bash
cd /home/astrologylms/htdocs/astrologylms.synilogictech.in/app && git reset --hard <sha> && SKIP_FETCH=1 ./deploy/deploy.sh
```

`SKIP_FETCH=1` ships whatever is checked out instead of resetting to the branch tip; the next
plain `deploy.sh` moves back to the tip, so revert on the branch for anything lasting. A
migration that has already run is not undone by either; write a forward migration instead.

The first deploy was seeded the same way: the checkout was pushed straight into the server
over ssh (`git push claude3@82.25.115.114:<site>/app <branch>` into a repo with
`receive.denyCurrentBranch=updateInstead`) before the GitHub deploy key was registered, then
`SKIP_FETCH=1 deploy.sh`. Every deploy since fetches from GitHub.

CloudPanel notes: the vhost, TLS and nginx are CloudPanel's — edit them in the panel, not on
disk. There is a stray root-owned `astrologylms/` folder inside the site directory holding an
unrelated `astro-divyam` checkout; it is not used by anything here and can be deleted as root.

## SaaS rollout (SAAS-016)

The subscription system ships switched off. Each stage turns on one thing, and each is reversible with the
same switch. None of the switches deletes data: turning one off restores the behaviour of the stage before.

| Stage | Switches | What happens | Go on when | Roll back |
| --- | --- | --- | --- | --- |
| **1. Development** | all off; test keys optional | local only | the full test pass is green (`npm test`) | — |
| **2. Staging** | `PAYMENT_CREDENTIALS_KEY` set; Razorpay configured and active in the gateway panel with **test** keys and a webhook secret; webhook URL added in Razorpay's test dashboard; `BILLING_JOBS=on` | a copy of production data, migrated (`deploy.sh` runs `prisma migrate deploy` and `tenants:verify`) | a test-card payment and a failed payment (Razorpay's test "Failure" button) both land correctly; a webhook redelivered from the dashboard is answered `duplicate`; a webhook failure shows in `/api/superadmin/webhooks` and the retry job clears it | turn off online payment in the gateway panel |
| **3. Internal academy** | production, **test** keys; one academy of our own put on a plan by a super admin | checkout, invoices, renewals and dunning on real infrastructure, with no customer money | one full renewal cycle, including a missed payment → past due → paid → active | turn off online payment in the gateway panel; the academy keeps its data |
| **4. Limited academies** | **live** keys and a live webhook secret; `SUBSCRIPTION_RETRY_DAYS` and `SUBSCRIPTION_GRACE_DAYS` set; selected academies on plans | real payments for a few academies; enforcement still **off**, so no one is blocked | a clean month: no `payment.unmatched`, no unexplained `job.failed`, all invoices reconciled with Razorpay's dashboard | `BILLING_JOBS=off` pauses renewals and dunning; turning off online payment in the gateway panel stops new checkouts |
| **5. Full rollout** | every academy on a plan; then `ENTITLEMENT_ENFORCEMENT=on` | plans' features and limits are enforced; an academy with no plan or an expired one is restricted (keeps and edits what it has, adds nothing) | — | `ENTITLEMENT_ENFORCEMENT=off` lets every request through as before, immediately (tested) |

Other switches:
- `TENANT_ENFORCEMENT=off` is the tenancy rollback (**Tenancy** above). It is independent of billing.
- `LIVE_REMINDERS=off` stops the whole scheduler, billing jobs included.
- `BILLING_JOBS=off` pauses only the billing jobs: nothing expires, renews or falls past due. Notifications
  carry on. Turning it back on resumes from where the clock stands (tested).

Before production (§49), each item and where it is covered:

| Item | Status |
| --- | --- |
| Provider credentials through secrets | `apps/api/.env` on the server only (git-ignored; a test scans the repository for the configured values). |
| Webhook URL and signing secret | Razorpay dashboard (**Razorpay webhooks** above). The API will not start in production with a provider but no webhook secret. |
| HTTPS | Cloudflare and CloudPanel (**The production server** above). |
| Background jobs | the in-process scheduler (`ecosystem.config.cjs`). Every job runs under a database lease (`JobLease`, SAAS-022), so more than one process may run the scheduler without a job running twice; a dead holder's lease expires after 5 minutes. `GET /superadmin/system` › `jobs` shows each lease and how the job last ended. SQLite still means one database writer. |
| Backups | **Backups** below. Take one before the first SaaS deploy; the migrations only add tables, columns and triggers. |
| Migrations | all 23 apply to an empty database with no drift, and apply in place to an existing one (`dev.db`, `tenants:verify` clean). |
| Webhook retries, payment failures, recovery | covered by the test suites (webhooks, checkout, jobs). On a deployed server, exercised at stage 2. |

## Backups

The SQLite file, the uploads directory (media, branding, live recordings) and `apps/api/.env` are the whole of the
state. Two scripts take copies; neither covers `.env`, so keep its secrets (`JWT_SECRET`, `PAYMENT_CREDENTIALS_KEY`,
`DEPLOY_WEBHOOK_SECRET`, SMTP and JaaS keys) with the deployment's other secrets.

- **Before every migration**, `deploy.sh` runs `npm run db:backup` (`apps/api/scripts/backup-db.ts`): a consistent
  `VACUUM INTO` copy under `<site>/data/backups/prod-<stamp>.db`, owner-only, newest `DB_BACKUP_KEEP` (default 14)
  kept. A failed backup stops the deploy before anything has changed.
- **Daily**, `deploy/backup.sh` from cron: the same database copy plus `uploads-<stamp>.tar.gz`, into
  `<site>/data/backups/daily`, newest 14 of each kept (`BACKUP_KEEP`), in its own folder so the pre-migration copies
  never push the daily ones out.

```bash
crontab -e   →   15 2 * * * /bin/bash <site>/app/deploy/backup.sh >> ~/backup.log 2>&1
```

Both hold personal data and password hashes: they are owner-only, never go under the web root or into git, and belong
off the server too. Copy `<site>/data/backups` elsewhere regularly; an off-server copy and a rehearsed restore are open
launch items (`14-LAUNCH-CHECKLIST.md` A16). To restore, stop the API, copy the chosen `.db` over `data/prod.db`, check
out the matching commit and redeploy with `SKIP_FETCH=1`; migrations are forward-only, and the restored file already
has its schema.

## Scaling note

SQLite is appropriate for a single-node deployment of this size. To move to PostgreSQL: change the
Prisma `provider`, regenerate migrations, and switch `String` JSON columns to `Json` if desired — no
route code depends on SQLite specifics.
