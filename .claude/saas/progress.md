# SyniastroLMS SaaS Progress

SAAS PHASE STATUS: IN PROGRESS — SAAS-000 to SAAS-015, SAAS-018 to SAAS-031 completed (SAAS-030/031 uncommitted); SAAS-016 blocked on a staging deployment with the Razorpay webhook configured; SAAS-017 blocked on VyaparGateway's API contract (see Blocked). Everything else in §53 is verified (final audit under SAAS-024).

This file is the record of the SaaS phase (`.claude/saas/modules.json`, scope `FULL_STACK`). The UI
build's record is `.claude/progress.md`; the F-series backend tracker is `docs/00-PROJECT-STATUS.md`.

## Decisions

Recorded 21 Sep 2026, from the product owner, resolving the SAAS-000 blocker. Every later module
inherits these; changing one is a migration, not an edit. The options weighed for each are in the
blocker record, commit `78b65de`.

| | Decision | What it means in the code |
| --- | --- | --- |
| **D1** | **One academy per person.** | `User.tenantId` (required). `Role` and `requireRole` stay exactly as they are — no membership table, no per-tenant role. |
| **D2** | **Email is unique across the platform.** | `User.email` stays `@unique`. Login is email + password on one host, with no academy picker. |
| **D3** | **The academy comes from the authenticated server context.** | `tenantId` is read from the user's row at sign-in and carried in the token, and the server re-checks it. A `tenantId` in a body, query or header is never trusted. |
| **D4** | **Globally unique:** certificate credential IDs; media file names/keys. **Tenant-scoped:** course slugs; category and course names. | `IssuedCertificate.credentialId` and `MediaAsset.storageName` keep `@unique` (public `/verify/:credentialId` has no tenant context). `Course.slug` becomes `@@unique([tenantId, slug])`; the F5 duplicate-name checks are scoped to the tenant. |
| **D5** | **Help Centre is shared by the platform. Levels, ranks and settings belong to an academy.** | `HelpCategory` / `HelpArticle` get no `tenantId`. `Level`, `Rank` and `Settings` do. The single `Settings` row (`id = 1`) moves into Tenant #1. |
| **D6** | **Stay on SQLite.** | No database engine change in SAAS-000. PostgreSQL is decided at SAAS-011. |

### Pricing decisions for SAAS-006 (product owner, 21 Sep 2026)

Given in answer to the SAAS-006 blocker. Like D1–D6, changing one is a migration, not an edit.

| | Decision | Rule |
| --- | --- | --- |
| **D7** | **Upgrades are prorated.** | During an active billing period, the unused value of the current plan and the remaining-period value of the new plan are both calculated, and only the difference is charged. The renewal date is unchanged. The new plan is not activated until that payment is confirmed. |
| **D8** | **Monthly → annual uses the same prorated credit.** | The unused value of the current monthly period is credited against the annual price. After the payment is confirmed, the annual period starts on the plan change's effective date and renews one year later. The complete pricing and subscription history is kept. |
| **D9** | **A pause extends the period.** | The renewal/end date moves out by the actual paused duration, at most 30 days per pause. Pause dates are calculated by the server; no client-supplied renewal date is accepted. Pause and resume are recorded in the subscription's history. |
| **D10** | **Downgrades wait for the period boundary.** | A downgrade takes effect at the next billing-period boundary, with no refund or credit for the current period. The current entitlements stay until the period ends and the new plan's begin with the next one. Existing data is never deleted when usage exceeds the new limits. |

### Gateway decision (product owner, 23 Sep 2026)

| | Decision | What it means in the code |
| --- | --- | --- |
| **D11** | **More than one payment gateway, chosen at runtime.** Razorpay and VyaparGateway to start, with room for more. The Super Admin configures them and selects the active one. | This supersedes §13's single-gateway rule and SAAS-009's "one adapter". Implemented as SAAS-017: a provider registry and factory; credentials encrypted in the database; one active gateway; and the gateway recorded on each invoice, order and payment always used for it. |

### Billing completion decisions (3 Oct 2026, made under the product owner's instruction to "implement whatever is best")

| | Decision | What it means in the code |
| --- | --- | --- |
| **D12** | **A renewal invoice lives only as long as the period it renews into.** | Cancelling, pausing, expiring or extending voids the open renewal invoice in the same transaction; checkout refuses one the subscription can no longer renew into (`renewsInto`). |
| **D13** | **An overdue academy can always pay its way back.** | Invoice generation covers `past_due`. A recovery paid after the whole next period is over starts a fresh period from the payment, instead of leaving the academy overdue again. |
| **D14** | **Paying during a trial never forfeits trial days.** | The first paid period starts when the trial would have ended (`paidPeriodStart`). |
| **D15** | **No ₹0 price on an offered cycle.** | Free access is a Super Admin trial or complimentary days (`extend`, 1–90 days, active subscriptions only), never a price the gateway cannot charge. |
| **D16** | **Money received outside the gateway is recorded by a Super Admin.** | `POST /superadmin/invoices/:id/record-payment`, provider `offline`, reference unique; refunds of it settle at once. |
| **D17** | **Enforcement needs dunning terms.** | With `ENTITLEMENT_ENFORCEMENT=on`, the API refuses to start without `SUBSCRIPTION_RETRY_DAYS` and `SUBSCRIPTION_GRACE_DAYS`. |
| **D18** | **Only the platform lifts a pause it imposed.** | An academy admin may withdraw their own cancellation, never end a pause. |
| **D19** | **A refund does not touch the subscription.** | Cancelling is a separate, explicit Super Admin action; the refund dialog says so. |
| **D20** | **Billing events notify the academy's admins.** | `lib/billingNotices.ts`: every lifecycle move and renewal invoice, as `system` notices (app + email); an admin is not told about their own cancellation. |

### Onboarding and plan-aware workspace decisions (3 Oct 2026, product owner)

| | Decision | What it means in the code |
| --- | --- | --- |
| **D21** | **A new academy self-serves its free trial.** | `POST /tenant/billing/trial`: the academy's own admin may start one thing directly — the plan's free trial, once per academy. Paid subscriptions still start only through checkout or the Super Admin. |
| **D22** | **Modules outside the plan are shown locked, with an upgrade path.** | `GET /academy/plan` for every admin and instructor; `moduleAccess` (domain) decides open / read-only / locked, the same rule the routes enforce. |
| **D23** | **Demo data is development-only.** | `seed:platform` (plans, GST rule, Help Centre; never deletes) runs on every deploy; `seed:demo` refuses `NODE_ENV=production`; E2E runs on its own `prisma/e2e.db`. |
| **D24** | **An admin always names their academy.** | `POST /superadmin/admins` requires `tenantId`; new customers get a new academy (`POST /superadmin/tenants`), which starts empty. |
| **D25** | **Enforcement is on for new deployments.** | `deploy/api.env.example` sets `ENTITLEMENT_ENFORCEMENT=on` with retry 3 / grace 7 days; `off` remains the emergency rollback. |

### Multi-admin SaaS decisions (3 Oct 2026, product owner brief "commercial multi-tenant SaaS")

| | Decision | What it means in the code |
| --- | --- | --- |
| **D26** | **Product hierarchy is Super Admin → Admins (clients) → their instructors and learners.** | The `Tenant` (academy) stays the technical isolation boundary; every customer admin owns exactly one (D1). Screens present a client as its admin and academy, never "tenant". |
| **D27** | **Anyone may register as an Admin; the email is verified first.** | `POST /signup/start` stores a pending signup (hashed code, hashed password); `/signup/verify` provisions the academy through `lib/academies` only for a correct code (6 digits, 15 min, 5 attempts, single use). `SIGNUP_EMAIL_VERIFICATION=off` skips the code only where no email delivery exists (never the default). |
| **D28** | **Registration never grants a paid plan.** | A new academy starts with no subscription; it starts its free trial (D21) or pays through checkout, activated only by a verified payment (§43). |
| **D29** | **Learners join a named academy.** | `/join/:slug` (public academy join page) and admin-created learners. `/auth/register` keeps its contract (the host's default academy) for the Flutter app. On the company site, `/register` is the Admin "Get started". |

## Multi-admin SaaS gap analysis (3 Oct 2026)

Audited against the brief: Super Admin → many independent Admins → their users; SaaS website; self-serve
registration → plan → checkout → activation; isolation; live E2E.

**Already built (kept, not rebuilt):**
- Tenancy: `Tenant` + `tenantId` on every academy table, Prisma tenancy extension, tenant from the signed-in row
  (D3), `tenancy.test.ts` / `securityAudit.test.ts` cross-tenant probes, suspended/archived academies closed (SAAS-019).
- Plans/versions, features, limits, entitlements, usage limits, enforcement on (SAAS-001–003, 011, 025).
- Subscriptions state machine, trials, grace, upgrade/downgrade/cancel/resume/pause, expiry, invoices, payments,
  refunds, tax, Razorpay through the provider abstraction, verified + idempotent webhooks, background jobs, audit.
- Super Admin: overview, Academies (create academy + first admin), Admins, Users, plans, subscribers, billing,
  MRR/revenue, tax, webhooks, gateways, audit, system. Admin: plan-aware workspace, welcome/choose plan, self-serve
  trial, billing page with checkout, invoices, payment history.
- Instructors created by admins with invite email; sessions, logout, revocation.

**Missing (now SAAS-026 … SAAS-031):**
1. No self-serve Admin registration — only the Super Admin can create an Admin. No email/OTP verification. → SAAS-026
2. No public plan catalogue; the pricing shown publicly is none. → SAAS-026
3. Public website is one astrology academy's storefront, not a SaaS company site; no Pricing, Features, Solutions,
   How it works, About, FAQ, Contact sales. Contact requests have nowhere to go. → SAAS-027
4. Admins cannot add a student; public learner sign-up always joins the host's default academy, so a second
   Admin's learners cannot join it. → SAAS-028
5. Super Admin presents "academies" rather than clients/admins; no support inbox. → SAAS-029
6. Payment success/failure/cancel cannot be driven in a browser (Razorpay hosted checkout). → SAAS-030 sandbox
   gateway, refused in production.
7. Live E2E of the whole multi-admin journey and cross-admin probes in the browser. → SAAS-031

**Still blocked from before (human-required):** SAAS-016 (staging server with Razorpay webhook), SAAS-017
(VyaparGateway API contract). Real email delivery needs a provider (affects OTP in production — D27).

### Multi-admin architecture decisions (3 Oct 2026, owner: "Super Admin → Admins → each Admin's own LMS data")

| | Decision | What it means in the code |
| --- | --- | --- |
| **D30** | **"Admin" is the customer in every screen; the tenant stays internal.** | Super Admin nav: **Admins** (customer list: admin first, then their LMS) and **Admin users** (every admin account). Website/signup say "LMS"/"Admin", not academy hierarchy. `Tenant`/`tenantId` unchanged as the isolation key. |
| **D31** | **Isolation and plans cannot be switched off by accident in production.** | `TENANT_ENFORCEMENT=off` refuses to boot in production; plan enforcement is ON in production unless explicitly `off` (warned at boot). |
| **D32** | **Learners join a named Admin.** | `/join/:slug`, admin "Add student", and `POST /auth/register { workspace }` for apps; without `workspace` it keeps the host default (Flutter compatibility). |
| **D33** | **A suspended/closed Admin account is told why.** | API code `ACADEMY_SUSPENDED/ARCHIVED` → the web ends the session and shows "This account is suspended/closed" on sign-in. |

## In Progress

None. (Work after commit 1edb117 — SAAS-030, SAAS-031 and the multi-admin fixes — is UNCOMMITTED in the working tree, by the owner's instruction "do not commit".)

## Blocked

### SAAS-017 — Multi-Gateway Payments & Runtime Gateway Configuration
Blocked 23 Sep 2026. Everything except the VyaparGateway adapter is implemented and verified. The module is not
complete, because one doneWhen item needs a contract that is not published: "VyaparGateway is implemented from
its actual API contract, with verified webhooks".

**Why it is blocked (VyaparGateway API contract)**

What was tried:
- `vyapargateway.com/docs` answers `{"detail":"Not Found"}`, and its Swagger UI is disabled.
- The developers page shows `POST /api/v1/create_order` with `amount`, `client_txn_id`, `customer_name`,
  `customer_email`, `customer_mobile` and `redirect_url`. Webhooks carry `x-vyapargateway-signature`
  (HMAC-SHA256), checked against a timestamp within 5 minutes.
- A blog page shows a different API:
  - `POST /v1/intents` `{amount, currency, order_id}`, returning `{id, qr_payload}`;
  - `GET /api/intents/{id}/status`, returning `{status, utr}`, where status is `pending`, `paid` or `expired`;
  - signature and timestamp headers.
- Neither page gives the response fields, the authentication header, refunds, or what exactly is signed (the
  body, or the timestamp and the body).
- There is no npm or PyPI SDK. The site says endpoint specs are in the merchant dashboard.

Inventing those fields was ruled out by the brief ("Do NOT invent request/response fields").

**What a human must supply:** from a VyaparGateway merchant account:
- the API reference or OpenAPI spec (create order or intent, status, refund, authentication);
- test-mode credentials;
- the webhook signature scheme and its event payloads.

With those, the adapter is one file (`lib/vyapargateway.ts`) and one registry entry. Then add
`redirectUrl` checkout support, which the web dispatcher already follows. See `docs/modules/payment-gateways.md`
› Adding a gateway.

**What SAAS-017 delivered** (uncommitted work committed with this block)

Schema: migration `20260923120000_payment_gateways`.
- `PaymentGatewayConfig` (platform-owned) has CHECKs on the provider and environment, credentials and key
  fingerprint set together, and "active only if enabled and configured".
- `PaymentGatewayConfig_one_active` is a partial unique index; `PaymentGatewayConfig_no_delete` is a trigger.
- `PaymentOrder_invoice_gateway` refuses an order through another gateway than the invoice's.
- Backfill pins an invoice only where its orders name exactly one provider.
- Verified on a scratch database built with the pre-SAAS-017 migrations plus old rows:
  - an invoice with a Razorpay order was pinned to `razorpay`;
  - an invoice with no order stayed NULL;
  - an invoice with orders from two providers stayed NULL, for a person to decide;
  - a later cross-gateway order was refused.
- `dev.db` was backed up (it had no invoices or payments), then migrated with `prisma migrate deploy`. The
  clean test database migrates from empty on every `npm test`.

Code:
- `lib/credentialVault.ts`: AES-256-GCM under `PAYMENT_CREDENTIALS_KEY`. Stores the key's fingerprint, never
  the key. Refuses a wrong key or a tampered value.
- `lib/paymentGateways.ts`: the registry (Razorpay implemented, VyaparGateway `implemented: false`) and the
  factory:
  - `activeProvider` serves new payments, and `providerFor` / `findProvider` serve recorded ones;
  - adapters are cached by row version;
  - list, configure (a blank secret keeps the stored one), enable and disable, activate, deactivate
    ("no gateway" on purpose), and test;
  - every change is audited;
  - `assertPaymentConfig` refuses a malformed key and logs leftover `RAZORPAY_*` by name only.
- `lib/paymentProvider.ts`: interface only now. Adds `CheckoutParams.redirectUrl`, optional `keyId`,
  `testCredentials` and `webhookEventIdHeader`. The env factory is gone; the test seam is
  `setPaymentProvider` / `setPaymentProviders`.
- `lib/razorpay.ts`:
  - built from decrypted database credentials, and the env registration is removed;
  - `testCredentials` is `GET /v1/orders?count=1`, which charges nothing; the key prefix must match the
    environment, and the webhook secret must be present;
  - the webhook secret is separate from the key secret.
- `lib/checkout.ts`:
  - an invoice pins to the active gateway at its first checkout, and further checkouts use the pinned gateway;
  - a confirmation finds the order within the academy and uses the order's gateway;
  - a refund uses the payment's gateway, and is refused with a 409 before any row is written if that gateway
    cannot be used;
  - audits `payment.provider_selected`, `payment.created`, `payment.verified` and `payment.refund_attempted`.
- `lib/webhooks.ts`: routed by the URL's gateway, verified with that gateway's secret. Audits
  `webhook.accepted` and `webhook.rejected`. The retry job goes gateway by gateway.
- `lib/billingJobs.ts`: past-due reconciliation asks each order's own gateway. `lib/billingViews.ts`:
  `checkoutAvailable` follows the active gateway.
- Routes (Super Admin, inside `requireSuperAdmin`):
  - `GET /superadmin/payment-gateways` and `GET /superadmin/payment-gateways/:provider`;
  - `POST /superadmin/payment-gateways/:provider/config`, `/:provider/test` and `/:provider/activate`;
  - `PATCH /superadmin/payment-gateways/:provider`;
  - `POST /superadmin/payment-gateways/deactivate`.
- `scripts/import-gateway-env.ts` (`npm run gateways:import-env`) moves `RAZORPAY_*` into the encrypted store
  and activates Razorpay.
- Web:
  - `PaymentGatewayService` contract, with HTTP and mock versions (the mock enforces the same rules);
  - `/superadmin/payment-gateways` page, with a nav entry and a Subscriptions tab; secrets are write-only
    password inputs and are shown only masked;
  - `lib/gatewayCheckout.ts` dispatcher that follows `checkout.provider` / `redirectUrl` and never chooses;
  - `CheckoutStart.keyId` is optional in `packages/domain`.
- Docs: `docs/modules/payment-gateways.md` (new); `docs/00`, `03`, `05`, `09` and `10`; `.env.example` and
  `deploy/api.env.example` now name only `PAYMENT_CREDENTIALS_KEY`.

**Evidence per doneWhen item**
1. Only the abstraction and factory: grep finds `api.razorpay.com` only in `lib/razorpay.ts`, and
   `new RazorpayProvider` only in the factory and the test fake. Checkout, webhooks, jobs, views and refunds
   import `paymentGateways.js`, not an adapter.
2. Encrypted, and no secret anywhere: `routes/paymentGateways.test.ts` checks the ciphertext, the hint, the
   responses, the list, the audit entries and the captured log for every secret. The checkout test scans
   tracked files for configured values, now including `PAYMENT_CREDENTIALS_KEY`.
3. One active gateway: the database test is refused on a second active row, an unconfigured active row, an
   unknown provider, a delete, and disabling the active gateway via raw SQL. The API returns 409 on activate
   while disabled or unconfigured, on disabling the active gateway, and on VyaparGateway.
4. Switching: invoice A stays on `fakepay` after the switch (reused order, confirmation, pinned provider), and
   invoice B goes to `fakepay2`. A signature from the other gateway is refused. B's webhook and its duplicate
   produce one payment. A pinned gateway that is gone gives a 409 with no new order. Refunds use the original
   gateway, and one that cannot be used gives a 409 with no Refund row.
5. Razorpay from the database: the real adapter is built from stored credentials. A checkout opens a stubbed
   Razorpay order priced from the invoice. A webhook signed with the key secret gets 401; one signed with the
   webhook secret gets 200. Secret rotation keeps the other secret.
6. **VyaparGateway: blocked** (above).
7. Super Admin actions are audited: `gateway.configured`, `credentials_updated`, `enabled`, `disabled`,
   `active_changed` (to and from null) and `test_attempted`. An academy admin or instructor gets 403 and an
   anonymous caller gets 401.
8. No behaviour change: the full API suite passes, 600/600, including checkout, webhooks, first purchase,
   refunds, billing jobs and the security audit. The one changed expectation: another academy's invoice at
   checkout is now 404 even with no gateway (before, 409). The invoice is looked up before a gateway is
   required, which is stricter.

**Verification (23 Sep 2026)**
- `npm run typecheck`, `npm run lint`, `npm run build`: pass.
- `npm test`: api 600/600, web 245/245, domain 119/119. `npm test -w @syniastrolms/api`: 600/600.
- `npm run format:check` fails only on 9 files in the **untracked `apps/lms-react/`**, which is not SaaS work
  and is not touched here. Every SaaS file passes Prettier.
- `prisma validate` passes, and the migration is verified from empty and in place.
- Scans:
  - no `rzp_test_` / `rzp_live_` key in non-test source;
  - no Razorpay host outside the adapter;
  - the web sends only ids to checkout and purchase: no provider, amount, tax, tenant or status.

**Operator note:** add `PAYMENT_CREDENTIALS_KEY` to `apps/api/.env` (`openssl rand -hex 32`). Then run
`npm run gateways:import-env -w @syniastrolms/api` to move the current Razorpay test keys into the panel. Then
remove `PAYMENT_PROVIDER` and `RAZORPAY_*` from `.env`. Until then, online checkout is off locally.

**Revision, 23 Sep 2026: gateway configuration from the panel** (after the product owner reviewed the screen)

Root cause of the disabled Configure button: the page disabled it whenever the server reported no
`PAYMENT_CREDENTIALS_KEY`, and the local `apps/api/.env` had none. The server answered only a generic 409.
The key is the server's encryption master key and belongs in the environment. Gateway credentials must be
enterable from the panel.

Changes:
- **Configure is never disabled.**
  - Without the key the form still opens, with a "Secure credential storage is not configured on the server"
    notice.
  - A save is refused with 503 `SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED`, a new stable code in
    `BILLING_ERROR_CODES`. The refusal is audited as `gateway.configuration_failed`.
  - A generated key was added to the local, gitignored `apps/api/.env`.
- **Test and live credentials are stored separately.** Migration `20260923150000_gateway_credentials_per_environment`
  adds:
  - the `PaymentGatewayCredential` table, one row per (provider, environment), replaced in place and never
    deleted;
  - `PaymentGatewayConfig.environment`, which picks the slot new payments use;
  - triggers so the active gateway must have credentials for its environment;
  - `PaymentOrder.environment`, fixed once set.

  Each order is confirmed, reconciled and refunded with the credentials of the environment that created it.
  Test and live webhooks each verify with their own secret. A Razorpay key is refused in the wrong slot.
  Existing credentials moved to their slot (verified on seeded data). Old orders keep `environment` null, which
  is not guessed.
- **VyaparGateway credentials can be stored**, using only its publicly confirmed fields (API credential, webhook
  secret), encrypted. It can be enabled, but not activated or tested, until its merchant contract is supplied.
  The blocker below is unchanged.
- **Audit:**
  - `gateway.credentials_replaced` (renamed from `credentials_updated`);
  - `gateway.activated` and `gateway.deactivated` (replacing `active_changed`);
  - new: `gateway.environment_changed`, `gateway.configuration_failed`;
  - the test result carries `checked`, so "nothing was checked" is never shown as success.
- **API:**
  - `PATCH /:provider` takes `{enabled?, environment?}`, and `POST /:provider/test` takes `{environment?}`;
  - the list returns `active`, and each row returns `credentials.test` / `credentials.live`, `canActivate`,
    `activationBlockedReason` and `testSupported`.
- **Web:** the page is redesigned:
  - an online-payments status panel with an active-gateway selector;
  - identical cards for both gateways, each with Test/Live credential slots and an environment switch;
  - a configure dialog with Test/Live radios, show/hide on secrets, validation, an unsaved-changes warning,
    loading, success and error states;
  - secrets are never prefilled ("Leave blank to keep the existing secret").

Evidence:
- `routes/paymentGateways.test.ts` has 26 tests. They cover:
  - the missing key;
  - invalid credentials;
  - encryption and server-side decryption;
  - replacement;
  - test/live separation, including a test order confirmed with the test keys after switching to live;
  - VyaparGateway configuration;
  - the activation rules and their database guards;
  - switching gateways and refunds;
  - audit.
- API 605/605, web 256/256, domain 119/119.
- `typecheck`, `lint` and `build` pass. `format:check` fails only on the untracked `apps/lms-react/`.
- End to end, with a real page, a scratch API and a scratch database copy:
  - without the key: 4/4. Configure works, and the save shows the server's message;
  - with the key: 12/12. Razorpay test keys were saved through the dialog, shown masked, and checked against
    Razorpay's test API with a read that charges nothing; Razorpay was enabled and set active; the API
    reported it active; no secret appeared in the page, the API response or the server log; VyaparGateway was
    configurable but could not be set active.
- The secret scan now also exempts the mobile app's Dart secret-scanning test fixture.

### SAAS-016 — Hardening, Migration Verification & Rollout
Blocked 22 Sep 2026, after all the work that can be done without a deployed server was done and committed
(claim `8a6566f`, work `2349eff`). **One §53 item is not yet true: "production deployment is tested".**
Everything else is verified; see the final audit below.

**What stopped it.** "Deployment is tested, including webhook retries and payment failures" needs the system
running where Razorpay can reach it, and the workflow reserves two steps for a human:

1. **Deploy to a staging server** (or the production server, stage 3 of the rollout plan, with test keys). This
   is an outward-facing action on infrastructure I have no authority over; `deploy/deploy.sh` does it as the
   site user. The deploy needs nothing new: the migrations only add; `deploy.sh` already runs
   `prisma migrate deploy`, `tenants:verify` and the permission backfill; and with no payment variables set,
   checkout is simply unavailable.
2. **Configure the Razorpay webhook** on that server. In the Razorpay test dashboard (Settings → Webhooks):
   - URL: `https://<host>/api/webhooks/razorpay/subscription`;
   - a secret you choose, set as `RAZORPAY_WEBHOOK_SECRET` in the server's `apps/api/.env`, alongside
     `PAYMENT_PROVIDER=razorpay` and the test key id and secret;
   - events: `payment.authorized`, `payment.captured`, `payment.failed`, `order.paid`, `refund.processed`
     and `refund.failed`.

   This secret is a credential only the account owner can create. It is still empty locally, and production
   refuses to start without it (verified).

**Then, on that server** (stage 2 in `docs/10` › SaaS rollout):
- a test-card payment;
- a failed payment (Razorpay's test "Failure", or an OTP left to time out);
- a webhook redelivered from Razorpay's dashboard, which should be answered `duplicate`;
- a check of `/api/superadmin/webhooks` and `/api/superadmin/observability`.

Re-run `/continue-saas` after that and I will record the evidence and complete SAAS-016.

**Tried, and what already stands in for it locally** (all against Razorpay's real **test** API):
- A **production-mode rehearsal**: the real API with `NODE_ENV=production`, the built web app, the real test
  keys and a webhook secret generated for the run, on a freshly migrated, seeded and backfilled database.
  13/13, then 5+7+5 in three parts:
  - production refuses to start without the webhook secret;
  - a checkout opened a real order for the invoice's own total (₹2,950 = ₹2,500 + 18% GST);
  - forged confirmations and webhooks were refused;
  - a signed webhook for a payment Razorpay does not know was answered 500, retried by the in-process
    scheduler (3 attempts, reason recorded) and shown to the Super Admin.
- **A real card payment** through Razorpay's hosted test checkout (driven headlessly: test Mastercard ••••
  5449, OTP), confirmed by our server with Razorpay.
  - It settled the invoice and applied the upgrade.
  - Confirming it again changed nothing, and a one-character signature change was refused.
  - Its webhook arriving after the browser repeated nothing.
- **A real failed payment**: Razorpay itself failed a renewal payment (`BAD_REQUEST_ERROR`,
  `payment_cancelled`) when the OTP timed out.
  - Its signed webhook recorded the failure with Razorpay's own message and moved the subscription to
    `past_due` (§44).
  - A real retry on the same order was confirmed and **recovered** the subscription: active, renewal 22 Oct →
    22 Nov.
  - The history keeps all three attempts, and the audit trail holds every event under the provider:
    `payment.succeeded`, `payment.failed`, `invoice.paid`, `invoice.failed`, `subscription.plan_changed`,
    `subscription.past_due`, `subscription.recovered`, `entitlement.changed`.
  - No server log of the runs carries the key secret, the webhook secret, a password or a token.

**What SAAS-016 delivered** (committed in `2349eff`)
- `routes/securityAudit.test.ts`: the §47 security list, one test each, over HTTP (9 tests).
- `BILLING_JOBS=off`: a reversible switch that pauses the billing jobs (tested off, then on).
- The staged rollout plan in `docs/10` (development → staging → internal academy → limited → full), with the
  switch for each stage, the go/no-go signals and the rollback. The §49 checklist is mapped item by item.
- Billing placeholders in `deploy/api.env.example` (names only, all off).
- A pre-existing prototype figure fixed, because it contradicted real billing data: the admin sidebar's
  "148 GB of 240 GB" storage meter now shows the academy's real storage against its plan, or nothing
  (verified: "0 GB of 10 GB").

**Final audit** (workflow §10, against subscriptions.md §53), each with evidence

| §53 item | Status | Evidence |
| --- | --- | --- |
| Tenants are isolated | ✅ | Tenancy extension, and 43 academy-owned tables with a required, indexed `tenantId` (tenancy suite). `tenants:verify` clean on `dev.db` (659 rows) and on a fresh database (464). Security suite: another academy's invoice/order/plan change is 404; forged tenant ids in body, query or header are ignored. |
| Plans are database-backed | ✅ | `Plan`/`PlanVersion` plus features and limits (SAAS-001/002). Versions are immutable (triggers). |
| Features and limits are centrally defined | ✅ | `FEATURES`/`LIMITS` catalogues in `packages/domain/src/entitlement.ts`, mirrored in `Feature`/`LimitDefinition`. A lint rule forbids plan-name checks. |
| Subscriptions are database-backed | ✅ | `Subscription` and the append-only `SubscriptionEvent` (SAAS-004). |
| Lifecycle transitions are enforced | ✅ | The named transitions only. Database triggers refuse any status, price or period change the latest event does not describe. |
| Trials are server-side | ✅ | Trial dates are set by the server clock; `trial-expiry-check` job (SAAS-005/012). |
| Cancellation is server-side | ✅ | `request_cancel`/`cancel_now`/`period_ended`; `scheduled-cancellation` job. |
| Upgrade and downgrade rules are defined | ✅ | D7–D10 (Decisions), `docs/06`, `planChange.ts`, and renewal at the next period's terms (SAAS-012). |
| The payment provider goes through an abstraction | ✅ | `PaymentProvider`, with one adapter (`lib/razorpay.ts`). A source test finds no gateway call or SDK outside it (SAAS-009). |
| Payment records are immutable | ✅ | Triggers: a settled payment, a refund and an invoice are never updated or deleted. `PaymentOrder` settles once. |
| Invoices are persisted | ✅ | `Invoice` with unique numbers; the figures are fixed at issue; one invoice per plan change or renewal period (database). |
| Webhooks are verified | ✅ | HMAC over the raw body; unsigned or tampered gets 401 and nothing is stored (SAAS-010; also live, locally). |
| Webhook processing is idempotent | ✅ | One receipt per event id. Replays are caught by hash; racing deliveries never process together; retries finish once. |
| Usage limits are enforced server-side | ✅ | `withinLimit` under a row lock (SAAS-011), behind `ENTITLEMENT_ENFORCEMENT` (off by design until rollout stage 5). |
| Entitlements are enforced server-side | ✅ | `requireFeature` on every matrix route (coverage test); expired academy gets 402 under enforcement (security suite). |
| Tenant isolation tests pass | ✅ | Tenancy, billing views, checkout and security suites. |
| Payment failure tests pass | ✅ | Checkout, webhooks and jobs suites, plus the real failed payment above. |
| Duplicate webhook tests pass | ✅ | Webhook suite: redelivery, 3 concurrent deliveries, replay; the security suite. |
| Audit logging exists | ✅ | Every §36 action, naming a person, the system or the provider; append-only (SAAS-014). Verified end to end in the rehearsal. |
| Existing LMS regression tests pass | ✅ | 560 API, 211 web and 119 domain tests all pass. The original 239 (54 domain, 185 web) are among them; the only ones edited are listed in the note below. Crawl below. |
| Super Admin platform access works | ✅ | The Super Admin crawl was clean on 16 pages, including 10 subscription screens with real data. Its routes refuse every other role (403/401, tested). |
| Tenant Admin subscription access works | ✅ | `/admin/billing` is crawled clean, and the rehearsal paid, failed and recovered through it. It is gated by `settings.view`, and changes need `settings.edit` (tested). |
| Secrets are protected | ✅ | `.env` is untracked, and a scan finds none of the configured values in the repository. Logs are redacted and swept (SAAS-014). Only the publishable key id reaches the browser. Production refuses a half-configured provider. |
| Production deployment is tested | ❌ **blocked** | Rehearsed in production mode against Razorpay's real test API with real payments (above). Not yet deployed to a server where Razorpay delivers webhooks. This needs the two human steps above. |

Note on the regression row: the tests edited during the SaaS phase are only those for behaviour the phase
deliberately replaced. That is the subscription prototype's mock (plan changes now follow D7–D10, pauses D9),
the admin navigation list (the added Billing entry) and the scheduler assertion (the added billing schedule).
Every LMS workflow test runs unchanged.

**The other audit points (workflow §10)**

| Point | Result |
| --- | --- |
| Cross-tenant leaks | none. See isolation above; the Super Admin read models are platform-only (tested). |
| Money as floats | none. No `parseFloat`, `toFixed` or float multiplication in the billing code. Amounts are integer paise, with BigInt proration and basis-point tax. |
| Plan-name checks that should be entitlements | none. The `no-restricted-syntax` rule (`eslint.config.js`) fails the lint on `plan.code === …`, `planName === …` and switches on plan codes or names; lint is clean. |
| Endpoints bypassing the entitlement service | none. The entitlement suite checks every feature in `ENFORCEMENT_MATRIX` is gated on its route. Route files may not read plan or subscription tables (lint). |
| Unindexed tenant columns | none. The tenancy suite checks that every `tenantId` is indexed. It caught `PaymentOrder` (fixed with a follow-on index migration in SAAS-009). |
| Destructive cascades | none on financial data. Every tenant and billing relation is `Restrict`; the cascades in the schema are LMS content from before this phase. Paid payments, invoices, webhook receipts, lifecycle events and audit entries cannot be deleted (triggers). |
| Secrets in logs | none (SAAS-014 sweep, and all three rehearsal server logs checked). |
| TODOs | none in `apps/*/src` or `packages/domain/src`. |
| Dead code | none found in the SaaS code. The adapter's recurring-subscription and customer calls are implemented and tested on purpose, for a later mandate rollout (SAAS-009 decision). |
| Console errors | none on any SaaS screen: HTTP-mode crawl of 10 subscription pages and `/admin/billing` at 1440 and 390, 0 problems. The demo build crawl covered 450 pages across student, instructor and admin, with 0 problems. |

**Migration verification.**
- All 23 migrations apply to an empty database, and `prisma migrate diff` (migrations → schema) is empty, as is
  fresh database → schema.
- The database has 60 triggers. Seed and backfill run on it, and `tenants:verify` is clean.
- In place, `dev.db` was migrated step by step through every migration, with a backup before each module that
  added one.

**Found, not fixed (pre-existing, outside the SaaS specification).** The HTTP-mode crawl of the LMS workspaces
found five defects, all dating from the initial commit (17 Sep), before this phase:
1. The instructor dashboard's quick action "Add a lesson" links to a demo course slug
   (`/teach/courses/foundations-vedic/lessons/new`): a 404 against the API
   (`pages/dashboard/DashboardSections.tsx:370`).
2. The new-certificate-template page loads a demo template id (`tpl-classic`): a 404 in http mode
   (`pages/certificates/TemplatesPage.tsx:158`).
3. An admin opening the public catalog `/courses` triggers a learner-only call (`GET /learning/courses` 400),
   and the page has no `h1`.
4. A submission link on the assignments pages opens a not-found page, for both admin and instructor.
5. A student is linked to a live class that answers 403.

They are not SaaS regressions, and fixing them would change LMS screens outside this phase's scope. They
should be picked up in the UI build's workflow.

## Resolved blockers

### SAAS-009 — Payment Provider Abstraction (resolved 22 Sep 2026: Razorpay, test-mode credentials supplied)
Blocked 22 Sep 2026, before any code, and not claimed. No half-built work exists.

**What it would build.**
- A `PaymentProvider` interface: `createCustomer`, `createSubscription`, `cancelSubscription`,
  `pauseSubscription`, `resumeSubscription`, `changePlan`, `createPayment`, `refundPayment`, `verifyWebhook`.
- **One** adapter behind it.
- The §43 payment flow end to end (a frontend success callback never activates anything) and the §44
  failed-payment flow.
- Credentials from secrets only.

**What stopped it**
1. **Which gateway.** The module says "one adapter chosen from the business requirement — do not integrate two
   gateways without one". §13 names Razorpay and Stripe and says to "select the actual provider based on
   deployment/business requirements". The workflow lists "which payment provider" as its first example of a
   genuine blocker.
2. **Credentials.** A real adapter is written and tested against the gateway's API and its webhook signatures.
   That needs a merchant account's **test-mode** key id and secret and a webhook signing secret, given as
   environment variables and never committed. None exists in this environment.

**Tried.** Read §13 and §43–45 and the module notes. Nothing names a gateway. A fake-only adapter would not meet
"one adapter chosen from the business requirement", and writing a real one without its account and credentials
would be unverifiable, so neither was built.

**Already in place for it.** The provider-actor entry points exist and are tested:
- `recordPayment` (idempotent);
- `confirmPlanChangePayment`;
- `recordPaymentSucceeded` and `recordPaymentFailed`;
- `settleRefund` and `savePaymentMethod`.

The adapter and SAAS-010's webhook handler will call them. Every payable amount comes from `lib/billing.ts`.

**What a human must decide and supply**

| | Option | Notes |
| --- | --- | --- |
| **Gateway** | **Razorpay** *(recommended for this product)* | INR-first, UPI and Indian cards, RBI e-mandates for recurring charges, a Subscriptions API, and GST-oriented invoicing. The prototype's methods (card, UPI, net banking, mandate) and the demo data (INR, GST) point this way. |
| | **Stripe** | Strong global APIs and Billing. India availability for recurring card mandates and UPI is more limited; the natural choice if the academies will mostly be billed outside India. |
| **Credentials** | Test-mode key id and secret, and a webhook signing secret, for the chosen gateway | Set as `PAYMENT_PROVIDER`, `<GATEWAY>_KEY_ID`, `<GATEWAY>_KEY_SECRET` and `<GATEWAY>_WEBHOOK_SECRET` in the environment (documented in `.env.example` and `docs/10` as part of the module). Never committed. Live keys only at rollout (SAAS-016). |

Reply with the gateway, make the test credentials available in `apps/api/.env` (not the repository), and re-run
`/continue-saas`.

**Re-checked 22 Sep 2026** after SAAS-011, SAAS-013, SAAS-014 and SAAS-015 were completed. Still no gateway
decision, and no `PAYMENT_PROVIDER` or gateway key names in `apps/api/.env` (names checked, not values). Every
remaining module waits on this one: SAAS-010 needs SAAS-009, SAAS-012 needs SAAS-010, and SAAS-016 needs
SAAS-012.


- **SAAS-006** — blocked 21 Sep 2026 (`c5643ad`) on the upgrade charging and pause policy. Resolved the same
  day by D7–D10 above.

- **SAAS-000** — blocked and resolved 21 Sep 2026. It was blocked because the Super Admin migration
  base was uncommitted and the tenancy model was undecided. The baseline commit `417eb15` and
  decisions D1–D6 above resolved it.

## Completed

### SAAS-000 — Tenant Foundation
Started and completed 21 Sep 2026. Built on the Super Admin baseline `417eb15`, after decisions D1–D6.

**What was built**

- **Schema.** A `Tenant` table (`id`, `name`, `slug` unique, `status`, `ownerUserId?`, timestamps).
  `tenantId` on **every** academy-owned table — all 33 were checked, not a subset: required on 28,
  nullable on the 5 that also hold platform rows (a super admin and what belongs to one). Every
  `tenantId` is a foreign key to `Tenant.id` with `ON DELETE RESTRICT` (removing an academy can never
  cascade its data away) and is the leading column of an index. `Course.slug` became unique per academy;
  `Settings` became one row per academy, keyed by `tenantId`. Platform tables (`Tenant`, `HelpCategory`,
  `HelpArticle`, `AuditLog`) carry none.
- **Migration** `20260921120000_tenant_foundation`. It creates Tenant #1 (`tenant-1`, slug `default`)
  and backfills every row of the 33 tables. Super admins and their rows stay NULL; everyone else gets
  Tenant #1. The owner is set to the oldest academy admin. It is **all or nothing**: Prisma does not wrap
  SQLite migrations in a transaction (proved below), so the migration opens its own, following SQLite's
  table-rebuild procedure. It checks its own backfill before `COMMIT` and aborts on any broken invariant.
- **The query boundary** (`src/lib/tenancy.ts`). A Prisma extension on the one shared client covers
  every query on an academy-owned model:
  - reads and filtered writes gain `tenantId` in their `where`
  - creates are stamped, nested creates included
  - every foreign key a write names is checked to be in the same academy (derived from the schema, so
    a new relation is covered automatically)
  - a filter or write naming another academy is refused
  - a query with no context at all is refused (fail closed)
  - accounts must obey D1 in any context
- **Authentication context** (`src/lib/requestContext.ts`). The token gains a `tenantId` claim (D3),
  but the academy is read from the account's own row on every request; the claim is only checked
  against it. A token naming no account, a different role or a stale academy counts as no session (401).
  Visitors who are not signed in run for the academy `DEFAULT_TENANT_SLUG` names. `requireRole` is
  unchanged.
- **Platform-wide by decision**, each wrapped in a named `runAsPlatform` and each tested:
  - the Super Admin router (after `requireSuperAdmin`)
  - sign-in and registration by email, and instructor-email uniqueness (D2)
  - reset tokens (the unguessable token is the credential)
  - credential-ID uniqueness and public verification (D4). Verification then runs inside the
    certificate's own academy.
  - the scheduler's list of academies
  - operator scripts
- **Super Admin.** `GET /superadmin/tenants`; directory rows carry their `tenant`; `POST
  /superadmin/admins` takes the academy the new admin is for (default: the host's). Grants take their
  academy from the admin's own row.
- **Scheduler** (`src/lib/scheduler.ts`). The every-minute jobs run once per academy, inside its own
  context, reading that academy's settings. One academy's failure no longer stops the others.
- **Seed and tests.** The seed writes into Tenant #1 through a bound client and clears data
  platform-wide. Tests state their context the same way production code does (`src/test/db.ts`).
- **Verification tool.** `npm run tenants:verify` (`src/lib/tenantAudit.ts`) reads every academy-owned
  row and every relation between them. It is wired into `deploy.sh` after `migrate deploy`, and the web
  build now runs before the migration.

**Policy decisions recorded here (workflow §4)**

- An academy account's academy comes from its row; the token claim is a check, never the source.
- Anonymous requests run for the academy the host serves (`DEFAULT_TENANT_SLUG`), which is server
  configuration, never client input.
- A super admin outside its own router is treated as a visitor. Academy routes still refuse it by role.
- `TENANT_ENFORCEMENT` defaults to **on**. `off` is the rollback switch: it stamps writes and filters
  nothing, and is only safe with one academy. The gate that switches enforcement on "after the
  backfill is verified" is mechanical: the migration verifies itself, and `tenants:verify` runs before
  the restart. It doesn't depend on someone remembering to flip a flag.
- Tenant `status` (suspended/archived) is recorded but not enforced. What a suspended academy can
  still do is restricted-mode policy, which belongs to SAAS-011.

**doneWhen, with evidence**

| Item | Evidence |
| --- | --- |
| Every tenant-owned table has a tenant FK and a tenant-scoped index | `tenancy.test.ts › tenant schema` reads the migrated database with `PRAGMA table_info` / `foreign_key_list` / `index_list` / `index_info`: all 33 tables have `tenantId`, NOT NULL on the 28 required ones, a foreign key to `Tenant(id)` `ON DELETE RESTRICT`, and an index led by `tenantId`. A classification test fails if a model is ever added without being classified. |
| Changing an id in a URL cannot read or mutate another tenant's record | `tenancy.test.ts › cross-tenant isolation: ids in URLs`. Another academy's course, category, student, certificate, instructor and media all answer 404, from both academies' admins. PATCH, archive, delete and suspend of another academy's records answer 404 and leave the rows byte-identical. Lists, the catalog, a learner's course access, settings, and an academy-wide `updateMany` stay inside the academy. **ids in bodies**: pointing a new or updated record at another academy's rows, or enrolling across academies, answers 404 and writes nothing. |
| Existing records all carry a valid tenant relationship before enforcement is switched on | The migration's in-transaction checks, plus `tenants:verify` (33 tables, 45 relations): clean on the migrated copy of the test database (1,632 rows), on the migrated copy of `dev.db` (650 rows), on a fresh database, and on the test database after the full 280-test suite with two academies (1,651 rows). It catches a raw-SQL cross-academy row (test). `deploy.sh` runs it before the restart. |
| Cross-tenant access tests pass | `tenancy.test.ts`: 45 tests, all passing, inside the full API run (280 of 280, twice, on fresh databases). |

**The eleven items asked for before completion**

1. **Tenant schema.** As above; `prisma validate` passes. The full migration chain reproduces
   `schema.prisma` (`migrate diff --from-migrations … --exit-code` → no difference, exit 0).
2. **Migration.** 33 table rebuilds, Tenant #1, owner, and in-transaction invariant checks. Proven
   atomic: a deliberately broken copy failed with `P3018 / CHECK constraint failed` and left the database
   identical, with the same tables and columns, the same row counts, no `Tenant` table and zero FK
   violations. The first version was not atomic, because Prisma runs SQLite migrations outside a
   transaction; the same experiment left it half-migrated. That is why it now opens its own transaction.
3. **Backfill.** On the migrated test-state copy: 36 tables and 1,722 rows unchanged; 33 tables gained
   `tenantId`; admins 13, instructors 4 and students 92 are in `tenant-1`; the 12 super admins are NULL;
   0 FK violations; the settings row is in `tenant-1`. On `dev.db`: 665 rows unchanged, and a super
   admin's real reset token and email correctly became NULL.
4. **Foreign keys and indexes.** The `tenant schema` tests above; `PRAGMA foreign_key_check` finds 0
   violations on every migrated copy.
5. **Authentication tenant context.**
   - tokens carry each account's own academy, and a super admin's carries none
   - a forged academy claim gets 401
   - a `tenantId` in the body, query or `X-Tenant-Id` header is ignored
   - registration lands in the host's academy
   - an email already used in another academy is refused (409)
6. **Tenant-scoped queries.**
   - a query with no context throws `TenantContextError`
   - each academy counts only its own rows
   - writes naming another academy, or moving a row to one, are refused
   - nested creates are stamped
   - a cross-academy foreign key answers 404
   - D1 is enforced both ways
   - `TENANT_ENFORCEMENT=off` stamps and does not filter, and switching back on restores the refusal
7. **Super Admin cross-tenant access.** `GET /superadmin/tenants` lists both academies with counts.
   `/superadmin/users` shows every academy's accounts with their `tenant`, and super admins with none.
   An admin created for Tenant B holds B-only grants and sees only B's courses. An unknown academy
   answers 404. Academy admins get 403 on the platform surface.
8. **Cross-tenant isolation tests.** Item 2 of the doneWhen table above, plus password reset (the token
   and email land in the account's academy, or NULL for a super admin) and credential IDs (another
   academy taking the next number makes Tenant #1 skip it). Verification works across academies under
   each academy's own switch. Jobs run per academy without touching another: counts are unchanged, and
   every row a job wrote is in its own academy.
9. **Existing LMS regression tests.** All 233 existing API tests pass. They changed only to state their
   context, read platform rows through `platformDb`, accept the `tenantId` claim, expect 401 where a
   token names no account, and in two page-size fixes for order dependence. No assertion about academy
   behaviour was weakened. Web 185 and domain 54 pass unchanged. Typecheck, lint, build and
   format:check pass.
10. **Clean migration from a fresh database.** All 10 migrations apply; Tenant #1 exists; 33 tables have
    `tenantId`; `tenants:verify` is clean; there is no drift.
11. **Migration from the current database state.** Copies of both real starting points migrated cleanly:
    the test-state database with super admins, and `dev.db`. That's all rows preserved, the invariants
    held, and `tenants:verify` clean.

**Deliberate behaviour changes**

- A correctly signed token that names no account, a different role, or a stale academy gets **401**. It
  used to reach the handler, so a removed admin's unexpired token would still have passed
  `requireRole('admin')`. Two tests were updated to say so.
- Anonymous visitors see the academy `DEFAULT_TENANT_SLUG` names.
- Each job runs once per academy, and one academy's failure no longer stops the others.

**Found and fixed along the way (separate commit `85bc2d1`)**

All six PATCH routes filled in every defaulted field they weren't sent, because zod applies
`.default()` under `.partial()`. A title-only course edit deleted the course's instructors and cleared
its texts and tags, and a name-only category edit deleted its levels. This predates tenancy. The fix,
with regression tests, was committed on its own and verified standalone in a separate worktree (235 of
235).

**Known limitations**

- **The first tenancy deploy has a short write-failure window.** Between `migrate deploy` and the
  restart, the old process can still read, but its writes to academy tables fail. The web build was
  moved before the migration to shrink the window to seconds. Take a backup and deploy in a quiet
  period (`docs/10-DEPLOYMENT.md` › Tenancy).
- **No way to create an academy yet** apart from the migration, the seed and tests. Onboarding comes
  with later modules.
- **A new academy starts with no default certificate template.** Its certificate settings can't be saved
  until one is chosen (a validation rule that predates tenancy). Onboarding should provision one.
- **Tenant `status` isn't enforced** (SAAS-011).
- **No frontend change in this module.** The API adds `tenant` to Super Admin directory rows and a
  tenants list, and the screens pick them up in SAAS-015.
- **Reference-check edge case.** The check reads committed rows, so an academy-context interactive
  transaction that creates a parent and then its child would get a false 404. No such transaction
  exists today; the only interactive transactions run as the platform.
- **Your local `dev.db` isn't migrated.** Only copies were migrated. Run
  `npm run prisma:deploy -w @syniastrolms/api` when you're ready. `tenants:verify` against it now
  explains exactly that.
- **One flaky test.** `superadminAdmins.test.ts › takes a repeated call safely` failed once in five runs
  and passed alone every time. It's a pre-existing Super Admin test and is recorded here, not changed.
- **A stale comment** in `apps/web/src/lib/roleHome.ts` still says the Super Admin workspace isn't built.
  It was out of scope and left as is.

**Files**

New: `prisma/migrations/20260921120000_tenant_foundation/`, `src/lib/tenancy.ts`,
`src/lib/requestContext.ts`, `src/lib/scheduler.ts`, `src/lib/tenantAudit.ts`,
`scripts/verify-tenancy.ts`, `src/test/db.ts`, `src/routes/tenancy.test.ts`.

Changed:
- **Schema, seed and wiring:** `prisma/schema.prisma`, `prisma/seed.ts`, `src/app.ts`, `src/index.ts`,
  `src/lib/{db,auth,audit,permissions,provisionSuperAdmin,settings,certificates,mail,passwordReset}.ts`
- **Routes:** `auth`, `superadmin`, `certificates`, `settings`, `instructors`, and every route that
  creates academy rows (`...tenant()`)
- **Tests:** the existing test files (context only)
- **Config, deploy and docs:** `package.json` (`tenants:verify`), `.env.example`, `deploy/deploy.sh`,
  `docs/01`, `03`, `04`, `05`, `09`, `10`

### SAAS-001 — Plan Tables & Versioning
Started and completed 21 Sep 2026 (claim `d34fa74`).

**What was built**

- **Schema** (migration `20260921140000_plan_tables`). Both are platform tables with no `tenantId`, listed
  in `PLATFORM_MODELS`.
  - `Plan` holds who the plan is: unique `code`, `name`, `description`, `status` draft/active/archived,
    `displayOrder`, `archivedAt`.
  - `PlanVersion` holds what the plan costs: `version` (unique per plan), `currency`, `monthlyPrice?` and
    `annualPrice?` in minor units (NULL means that cycle is not sold), and `trialDays`.
  - **Database guards.**
    - Triggers refuse any UPDATE or DELETE of a version, and any change to a plan's code once the plan has
      left draft.
    - The foreign key to `Plan` is RESTRICT, so a plan with a version cannot be deleted.
    - CHECK constraints require each price to be NULL or a non-negative SQLite *integer*. SQLite would
      otherwise store `3999.5` in an INTEGER column.
    - Further CHECKs require at least one cycle to be priced, `trialDays` to be 0–90, and `archivedAt` to
      be set exactly when the plan is archived.
  - The migration only creates tables and inserts no plan: prices are business configuration.
- **Domain** (`packages/domain`).
  - A new `money.ts`: money is an integer count of the currency's minor unit. `parseMajorAmount` reads
    typed text exactly, with no float multiply, and refuses more decimals than the currency has.
    `formatMoney` shows every paisa and never rounds one away. Also `majorToMinor`, `minorToMajor`,
    `isMinorAmount`, and `isCurrencyCode` (checked against the runtime's ISO 4217 list).
  - `subscription.ts` moved to paise in one step: every price, charge, invoice line and recurring figure.
  - `validatePlan` is now `validatePlanTerms` plus `validatePlanAllowance`. Prices must be whole minor
    units, the currency must be real, and the price ceiling is expressed in the currency's own units.
- **API** — `src/lib/plans.ts` is the only writer of plans.
  - Operations: `createPlan` (always a draft, version 1), `updatePlan`, `publishPlan`, `archivePlan`,
    `restorePlan`, `getPlan`, `listPlans`, `listPlanVersions`, `resolvePlanVersion` and
    `planForNewSubscription`.
  - `updatePlan` edits the name, description and order in place. A change to any commercial term adds
    version N+1, and an edit that changes nothing writes nothing.
  - `planForNewSubscription` throws `PlanUnavailableError` (`PLAN_UNAVAILABLE`, 409).
  - It validates with the domain's own `validatePlanTerms`, the same function the editor runs, so the two
    are in sync by construction rather than by copying.
  - Every write is refused outside the platform context (403), so a Tenant Admin route can never reach it.
    A signed-in caller must also be a super admin.
  - Each write records `plan.created`, `plan.updated` (with the changed fields and the old and new
    version and terms), `plan.published`, `plan.archived` or `plan.restored` in the same transaction.
  - Transitions filter on the current status, so two concurrent archives cannot both succeed.
  - `recordAuditLog` now takes `Pick<Request, 'auth'>` (a widening).
- **Seed.** The LMS-019 six-plan catalogue, in paise: STARTER, GROWTH, PRO and ENTERPRISE active, SCHOLAR a
  draft, PRO-2025 archived. The seed never clears plans; it only adds a plan whose code is missing.
- **Frontend.** The prototype's fixtures, the mock's maths, the tests and all display now use paise. There
  is no redesign.
  - `money()` and `moneyCompact()` delegate to the domain.
  - The plan editor's price fields are a `PriceInput` that shows rupees and hands the form exact paise.
  - The screens still read the mock service. Moving them to the real API is SAAS-015; the
    `/superadmin/plans` endpoints are SAAS-013.

**Policy decisions** (this module's; later modules inherit them)

- **P1 · Versioning.**
  - Currency, the price of each cycle, which cycles are sold and the trial length are commercial terms;
    changing any of them adds a version.
  - Name, description and display order are presentation and are edited in place. An invoice will copy the
    plan name at issue (SAAS-008).
  - New sales use the highest version. A record of a sale holds a `PlanVersion.id`.
- **P2 · Status.** Moves only through named transitions: publish (draft→active), archive (draft or
  active→archived) and restore (archived→active). An edit never changes status; a `status` in an edit is
  ignored. This matches the LMS-019 prototype's archive and restore rules. A restored plan sells its
  current version.
- **P3 · Plan code.** Unique, stored trimmed and in capitals, and **fixed once the plan leaves draft**,
  because billing and provider products will key on it. This is enforced in the service and by a trigger.
  The prototype editor still lets you edit the code of any plan; SAAS-015 should disable the field for a
  non-draft plan.
- **P4 · Money.** Every platform-billing amount is an integer in the currency's minor unit.
  - Rounding happens only where a division is stated: tax (`Math.round` to a whole paisa) and monthly
    value (annual ÷ 12, rounded to a paisa).
  - Currency digits come from ISO 4217 via `Intl`, so a second currency needs no schema or code change.
- **P5 · Selectable plans.** Only an `active` plan, on a cycle it prices, can be sold. Draft and archived
  plans are refused with `PLAN_UNAVAILABLE`, and existing sales read their version regardless of plan
  status.

**doneWhen — evidence**

1. **Plan codes are unique at the database level.**
   - `Plan_code_key` is a unique index. `plans.test.ts` › *refuses a second row with the same code, whoever
     writes it* gets P2002 on a raw client insert.
   - Through the service a duplicate is refused as a 409 in any case or padding.
   - The database also refuses a lower-case code (`Plan_code_check`).
2. **An archived plan cannot be chosen for a new subscription, but existing ones keep it.**
   - *refuses an archived plan, and keeps every version it ever had readable*: after `archivePlan`,
     `planForNewSubscription` throws `PLAN_UNAVAILABLE` (409). `resolvePlanVersion` on the version held
     before archiving still returns ₹3,999 / ₹39,990 / INR / 14 days, and the version count is unchanged.
   - Also tested: draft, unsold cycle and unknown plan are refused; a restored plan sells again; status
     moves only through transitions; two concurrent archives let exactly one through.
3. **Editing a plan's price leaves every historical record's terms untouched.**
   - *adds a version for a price change…*: v1's row is `toEqual` to its state before the edit; v2 carries
     the new price and the unchanged terms; new sales get the new price; the history lists both.
   - *is enforced by the database, not only by the service*: UPDATE and DELETE through Prisma and through
     raw SQL are all refused ("PlanVersion rows are immutable"), and the plan itself cannot be deleted.
   - Also tested: every term creates a version while a name-only edit doesn't; a no-op edit writes no
     version and no audit row; `(planId, version)` is unique.
4. **Amounts are integers in the smallest currency unit throughout.**
   - Service: 3999.5, −1, NaN and `ZZZ` are refused with the domain's messages.
   - Storage: `typeof()` of the stored prices is `integer`; raw inserts of 3999.5, −100 and no cycle hit
     the CHECK constraints.
   - The domain has 17 new money and validation tests, including `parseMajorAmount('1.15') === 115`,
     where the float product would be 114.99…
   - The fixtures and mock hold paise, and the web tests assert paise.
   - Scope: this covers platform-billing amounts. `Course.priceAmount` is an academy's own course price,
     with no payment flow in this phase (§51 marketplace billing is out of scope). It stays whole rupees and
     is documented in `docs/03`.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` (the existing chunk-size warning only) and
  `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 304/304, web 186/186, domain 70/70 |
  | `npm test -w @syniastrolms/api` | 304/304, on three of four runs |

  The fourth run failed `students.test.ts` › *shows an instructor only the learner's enrollments…*, a timing
  race on data other files write to the shared database, and passed on the three reruns. Nothing in this
  module touches students or courses. It is recorded, not changed, like the flaky Super Admin test SAAS-000
  logged.
- Security (§47):
  - Covered here: a write from an academy context is refused (403 on create, edit and archive); a
    non-super-admin caller is refused; the price sold is taken from the version, not the request.
  - Tenant isolation is unchanged: `tenants:verify` is clean, and the model-classification test counts 33
    academy tables plus the two new platform tables.
  - Forged and duplicate webhooks, refunds and client-supplied payment amounts have no surface yet.
- Migrations:
  - A fresh database applies all 11 migrations with no drift, has three triggers, and verifies clean.
  - A copy of the current `dev.db` migrated cleanly: all 37 tables and 668 rows preserved, integrity and
    foreign-key checks clean, `tenants:verify` clean, no drift.
  - Seeding twice leaves the same 6 plans with the same version ids.
- Browser, headless Chrome against a throwaway API and web in http mode, signed in as a super admin: all
  eight subscription screens at 1440 and 390, with 0 console errors, 0 failed requests, 0 horizontal
  overflow and one h1 each.
  - Prices render as before (₹3,999, ₹39,990, ₹2,49,990).
  - The editor shows `3999`; typing `4499.5` previews ₹4,499.50; `4499.555` is refused with "to at most 2
    decimal places".
  - The invoice dialog shows 18% GST as ₹16,198.20.
- Regression: the API suite covers the Super Admin, Admin, Instructor and Student flows (304 pass). No
  route, auth or tenancy behaviour changed.

**Visible change**

Derived figures now show their paise instead of rounding to whole rupees: MRR ₹9,993.34, tax ₹16,198.20.
The prototype rounded them away; P4 keeps them.

**Known limitations**

- **No HTTP surface yet.** The service is exercised by tests and the seed; its endpoints come in SAAS-013,
  and the screens still read the mock (SAAS-015).
- **Prisma reports a trigger's abort as "Foreign key constraint violated".** The write is still refused;
  raw SQL shows the trigger's real message. SAAS-013 should map a refused version write to a clear 409
  rather than let that text through.
- **Your `dev.db` is not migrated to `plan_tables`.** Only a copy was. Nothing running reads plans yet. Run
  `npm run prisma:deploy -w @syniastrolms/api` to catch up; it creates two empty tables. Plans appear after
  seeding, or once SAAS-013 lets a super admin create them.
- **`PLAN_UNAVAILABLE` is carried** on `PlanUnavailableError.code`, but the error handler does not emit
  codes yet (SAAS-013, §34).
- **Plan audit events have no system or provider actor** yet (SAAS-014). Seed writes carry no caller, so
  they are not audited.

**Files**

New:
- `apps/api/prisma/migrations/20260921140000_plan_tables/`
- `apps/api/src/lib/plans.ts`, `plans.test.ts`
- `packages/domain/src/money.ts`, `money.test.ts`

Changed:
- **API:** `prisma/schema.prisma`, `prisma/seed.ts`, `src/lib/tenancy.ts` (`PLATFORM_MODELS`),
  `src/lib/audit.ts`
- **Domain:** `packages/domain/src/{index,subscription,subscription.test}.ts`
- **Web:** `apps/web/src/pages/superadmin/subscriptions/{PlanEditorPage.tsx,subscriptionMeta.tsx,subscriptionMeta.test.ts}`,
  `apps/web/src/services/mock/{subscriptions.ts,subscriptions.test.ts,fixtures/subscriptions.ts}`
- **Docs:** `docs/00`, `01`, `03`, `09`

### SAAS-002 — Feature Catalogue & Limits
Started and completed 21 Sep 2026 (claim `3cdad4d`).

**What was built**

- **Catalogue** — `packages/domain/src/entitlement.ts`, the single source.
  - The nine §4 features (`FEATURES`, `FeatureKey`, grouped for the editor).
  - The six §4 limits (`LIMITS`, `LimitKey`) with unit (count or bytes) and period (total or month).
  - `PlanLimits`, where `null` means unlimited, and `limitOf`, which answers **0** for a limit that is not
    set.
  - `BYTES_PER_GB`.
  - `ENFORCEMENT_MATRIX`: the §42 table as typed data.
- **Schema** (migration `20260921160000_plan_entitlements`).
  - `Feature` and `LimitDefinition` hold the catalogue, inserted by the migration exactly as the domain
    writes it and never deleted.
  - `PlanFeature` and `PlanLimit` hold per-version grants, with foreign keys to the version and the
    catalogue, all RESTRICT. `PlanLimit.value` is BIGINT because storage is counted in bytes (150 GB is
    161,061,273,600), with a CHECK for an integer ≥ 1 or NULL.
  - `PlanVersion` gains `featureCount` and `limitCount`, added by `ALTER TABLE ADD COLUMN`. Prisma's own
    diff would rebuild the table and silently drop its SAAS-001 triggers and CHECKs; that is written
    down in the migration.
  - Triggers: grants cannot be updated or deleted, and the `_sealed` triggers refuse a grant beyond the
    count the version declared. A version's allowance is therefore fixed the moment it is written.
  - The catalogue tables key on `id`, which holds the catalogue key itself, so the SAAS-000 invariant
    that every foreign key names its target's `id` still holds unchanged.
- **API** (`src/lib/plans.ts`).
  - A plan's input and its version now carry `features` and `limits`, validated by the domain's
    `validatePlanAllowance` beside `validatePlanTerms`.
  - A version and its whole allowance are written in one nested create, and the counts seal it.
  - A change to a feature or limit is a commercial change and adds a version. The same set in another
    order is not a change.
  - The audit trail records the allowance before and after.
  - The four new tables are `PLATFORM_MODELS`.
- **Seed.** The six demo plans carry the prototype's limits (storage in bytes) and its features, mapped
  onto the catalogue. A plan seeded under SAAS-001, whose version grants nothing, gets version 2 with its
  allowance. That is the only way to add one; version 1 is left as it was.
- **Frontend.** The prototype now uses the catalogue keys: fixtures, the mock, the plan editor (storage
  entered in GB, held in bytes), the plan detail and subscriber pages, and their tests. The design is
  unchanged.
- **Lint.** ESLint `no-restricted-syntax` refuses comparing a plan's `code`/`name` (or a `planCode` /
  `planName`) with a literal, and a `switch` on one. It is part of `npm run lint`.

**Policy decisions**

- **P6 · Unset limits deny.** A limit a version does not set grants 0. `null` is the only way to say
  unlimited. A version written before SAAS-002 therefore grants nothing: the data can only ever refuse
  by accident, never allow.
- **P7 · An allowance is a commercial term.** Features and limits are versioned exactly like prices
  (extends P1), so a subscription sold on a version keeps the allowance it was sold, however the plan
  changes later.
- **P8 · Catalogue reconciliation.**
  - The catalogue is the nine §4 features and six §4 limits (the module notes list the same).
  - §42's example keys `learners.enabled`, `instructors.enabled` and `courses.enabled` are not in §4.
    Learners and instructors are gated by limit alone, and courses by `courses.manage`.
  - The prototype's `notifications` feature has no §4 key and is dropped. Notifications are core: account
    email such as password resets can't depend on a plan.
  - For the demo data, the prototype's `advanced-analytics` became `analytics.advanced` plus
    `reports.advanced`. That mapping is demo data only.
- **P9 · Limit periods.** `live_classes.max` counts a calendar month, as the prototype labelled it. Every
  other limit is a ceiling on what exists at once. SAAS-011 decides how each one is counted (§23).
- **P10 · Storage** is held in bytes, and entered and shown in GB, where 1 GB is 1024³ bytes.

**doneWhen — evidence**

1. **No `plan === "..."` comparison exists anywhere in the application.**
   - The lint rule is in `eslint.config.js`. A probe file with `plan.code === 'PRO'`,
     `'Growth' !== current.plan.name`, `planName == 'Enterprise'` and `switch (plan.code)` produced 4
     errors, and the plan-to-plan comparison it contained passed. The probe was deleted afterwards.
   - `npm run lint` over the whole repository is clean.
   - A grep for any plan code or name compared as a literal found one test assertion,
     `r.planName === 'Growth'`. It was rewritten to compare with the fixture plan's own name, and the rule
     was widened to member access (`row.planName`) so it would have caught it.
2. **The enforcement matrix is written down and every permission key in it is real.**
   - `ENFORCEMENT_MATRIX` is typed with `PermissionKey`, so a key that isn't real doesn't compile.
   - `entitlement.test.ts` checks every permission is in `PERMISSION_KEYS` and every feature and limit is
     in the catalogue. It also checks that every catalogue feature and limit is covered, and that a rule
     with no permission says why.
   - The matrix is written out in `docs/06-BUSINESS-RULES.md` › Enforcement matrix.
3. **A plan's features and limits are rows, not code.**
   - `plans.test.ts` › *writes a version's allowance as PlanFeature and PlanLimit rows* reads the rows back
     from the tables.
   - *holds the catalogue in the database exactly as the domain writes it* compares the `Feature` and
     `LimitDefinition` tables with the domain catalogue.
   - *versions a change of feature or limit…*: v2 and v3 are new rows, and v1's allowance is unchanged.
   - *seals a version's allowance*: raw INSERT, UPDATE and DELETE on grants, and deleting a catalogue
     entry, are all refused with the triggers' messages.
   - *refuses a feature or limit the catalogue does not have — in the service and in the database*
     covers unknown keys (FK) and a value of 0 (CHECK).
   - *reads a version written before SAAS-002 as granting nothing*.
   - In the browser, Growth's detail shows 750 learners, 150 GB and its five features from the rows;
     Enterprise shows Unlimited, 2 TB and all nine.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 311/311, web 186/186, domain 80/80 |
  | `npm test -w @syniastrolms/api` | 311/311 |

- Migrations:

  | Starting point | Result |
  | --- | --- |
  | Fresh database | 12 migrations; 9 features, 6 limits, 11 triggers; no drift |
  | Copy of the current `dev.db` | both plan migrations applied; 668 rows in 37 tables preserved; FK and integrity clean; `tenants:verify` clean |
  | Database seeded under SAAS-001 | migrated, then re-seeded: each plan gained v2 with its allowance, v1 untouched; a further seed changed nothing (12 versions) |

- Browser (headless Chrome, http mode, super admin), every subscription screen at 1440 and 390: 0
  console errors, 0 failed requests, no overflow, one h1 each. The editor shows storage as `150` (GB) and
  learners as `750`, and has the `custom_branding` switch.
- Security:
  - Grants are written only through the platform-only plan service.
  - No grant can be added, changed or removed after its version is written.
  - Unknown keys are refused by foreign key, and an unset limit denies.
  - `tenants:verify` is clean. The tenancy suite passes, including the model-classification and
    foreign-key-shape tests.

**Known limitations**

- **Nothing reads the grants yet.** The entitlement service is SAAS-003, and limit enforcement is SAAS-011.
- **The lint rule is heuristic.** It catches plan `code`/`name` literals in comparisons and `switch`es, but
  not an indirection such as `const pro = 'PRO'; plan.code === pro`. SAAS-003's rule that no controller
  reads plan tables is the structural guard.
- **The catalogue is held twice.** The domain constant and the migration-inserted tables are kept equal by
  a test, not by generation. Adding a feature means changing both: an edit to `entitlement.ts` plus a
  migration.
- **Your `dev.db` is not migrated** to either plan migration. `npm run prisma:deploy -w @syniastrolms/api`
  creates the empty plan tables and the catalogue.

**Files**

New:
- `apps/api/prisma/migrations/20260921160000_plan_entitlements/`
- `packages/domain/src/entitlement.ts`, `entitlement.test.ts`

Changed:
- **API:** `prisma/schema.prisma`, `prisma/seed.ts`, `src/lib/plans.ts`, `src/lib/plans.test.ts`,
  `src/lib/tenancy.ts`
- **Domain:** `packages/domain/src/{index,subscription,subscription.test}.ts`
- **Web:** `apps/web/src/pages/superadmin/subscriptions/{PlanEditorPage,PlanDetailPage,SubscriberDetailPage,subscriptionMeta}.tsx`,
  `subscriptionMeta.test.ts`, `apps/web/src/services/mock/{fixtures/subscriptions,subscriptions.test}.ts`
- **Config and docs:** `eslint.config.js`, `docs/00`, `01`, `03`, `06`

### SAAS-003 — Entitlement Service
Started and completed 21 Sep 2026. The claim (`b2ea379`) was committed late, after the implementation had
begun. That skips workflow §3; no other module was in progress, so nothing was raced.

**What was built**

- **Service** — `apps/api/src/lib/entitlements.ts`, the one reader of plan data for an academy.
  - `getTenantEntitlements(tenantId)`: the plan version, features and a value for every limit.
  - `hasFeature` and `getLimit`: a number, `null` for unlimited, 0 for none.
  - `getUsage(tenantId, limit)`: live counts, always run inside that academy's own context whatever it is
    called from.
  - `canConsume(tenantId, limit, n)` returns `{ allowed, limit, usage, remaining }`.
  - Which plan version an academy is on comes from `setTenantPlanSource`: the seam SAAS-004's subscription
    fills. Until then every academy reads as being on no plan.
- **Guard.** `requireFeature(feature, when?)` is placed straight after each route's permission guard, so the
  order is authenticated → role → permission → (tenant context, set for the whole request) → entitlement →
  handler.
  - It does nothing unless `ENTITLEMENT_ENFORCEMENT=on`, which is off by default (§50).
  - It covers courses (create, edit, publish, reorder), chapters and lessons (create, edit, duplicate, move),
    quizzes and assignments (create, edit, duplicate), certificates (issue, templates), live classes
    (schedule, edit), the basic reports and the instructor report (advanced), and the appearance settings
    (`custom_branding`).
- **Error model** (`lib/errors.ts`).
  - `ApiError` carries an optional stable `code`, which the handler adds to the body. `ErrorCode` lists
    every §34 code plus `PERMISSION_DENIED`.
  - `requirePermission` refuses with `403 PERMISSION_DENIED`. The entitlement refusals are
    `403 FEATURE_NOT_INCLUDED` and `402 SUBSCRIPTION_REQUIRED` (`EntitlementError`).
  - `PlanUnavailableError` now reaches the body as `PLAN_UNAVAILABLE`.
  - `requireRole` is unchanged, and its refusal carries no code.
- **Lint.** A second `no-restricted-syntax` block for `apps/api/src/routes/**` (tests excluded) refuses any
  access to `plan`, `planVersion`, `planFeature`, `planLimit`, `feature`, `limitDefinition` or
  `subscription*`.
- **Matrix correction (SAAS-002).**
  - "Upload media" was listed under `catalog.edit` + `courses.manage`. The route lets any signed-in account
    upload (assignment hand-ins included), so the row is now limit-only (`storage.bytes`).
  - New rows: changing and publishing a course, certificate templates, and the instructor report
    (`reports.instructors.view` → `reports.advanced`).
- **Catalogue wording.** Migration `20260921180000_entitlement_wording` updates the `reports.basic`
  description, which no longer mentions the dashboard, to match the domain.
- **No frontend change.** With enforcement off, no screen can meet the new codes. The web client maps 402 to
  `unknown` and keeps the message; SAAS-015 renders the codes as states.

**Policy decisions**

- **P11 · Gates govern adding and changing, never withdrawing or serving.**
  - No feature gate blocks unpublishing, archiving or restoring a course; deleting a chapter, lesson, quiz or
    assignment; revoking or restoring a certificate; or cancelling a live class.
  - Nor does one block live registration, reminders, hand-ins or grading.
  - The dashboard is never gated.
  - A plan that loses a feature leaves what exists usable. SAAS-011's restricted mode builds on this.
- **P12 · No plan means nothing.** With enforcement on, an academy on no plan is refused `402
  SUBSCRIPTION_REQUIRED` on every gated route. That is why enforcement stays off until every academy has a
  subscription (SAAS-004 and on).
- **P13 · Usage definitions** (the live strategy SAAS-011 starts from):

  | Limit | What counts |
  | --- | --- |
  | learners | every `Student` |
  | instructors | every `Instructor` not `inactive` (invited ones count, since they can accept) |
  | courses | every `Course` not `archived` |
  | storage | the sum of `MediaAsset.sizeBytes` |
  | live classes | classes starting in the current **UTC** calendar month, cancelled ones excepted |
  | admin accounts | `User`s with role admin and no `deactivatedAt` |

- **P14 · Status codes.** 402 when there is no plan, since the fix is to subscribe; 403 when the plan is too
  small.

**doneWhen — evidence**

1. **No controller queries subscription or plan tables directly.**
   - The lint rule is scoped to `apps/api/src/routes/**`. A probe route file reading `db.plan`,
     `db.planVersion` and `db.planLimit` produced 3 errors, and was deleted.
   - `npm run lint` over the repository is clean.
   - Only `lib/plans.ts` and `lib/entitlements.ts` touch the tables. (There are no subscription tables yet;
     the rule already covers `subscription*`.)
2. **Permission-denied and entitlement-denied are distinguishable in the error model.**
   - `entitlements.test.ts`: a missing permission gives `403 code: PERMISSION_DENIED`; a missing feature
     gives `403 code: FEATURE_NOT_INCLUDED` with the plan's name in the message; no plan gives `402 code:
     SUBSCRIPTION_REQUIRED`.
   - The codes are documented in `docs/05` › Conventions.
3. **Unit tests cover both-pass, permission-only and entitlement-only cases.** These run on a probe route
   composed like a real one:
   - Both pass gives 200, for an admin and for an instructor.
   - Permission missing and plan allowing gives `PERMISSION_DENIED`.
   - Permission held and feature missing gives `FEATURE_NOT_INCLUDED`, for an admin and for an instructor.
   - Both missing gives `PERMISSION_DENIED` (checked first).
   - No plan gives 402, and enforcement off gives 200.
   - On the real routes:
     - `POST /courses` without `courses.manage` is refused and writes no course.
     - Basic reports pass while `/reports/instructors` needs `reports.advanced`.
     - Only `PUT /settings/appearance` needs `custom_branding`.
     - The dashboard, archiving a course and a learner's courses stay open.
     - Every catalogue feature that has a route is gated on one (`GATED_FEATURES`).
   - Service tests:
     - An academy on no plan is granted nothing.
     - Grants are read from the version.
     - An academy keeps its entitlements after its plan is archived.
     - Exact usage per limit, on a private academy with known rows.
     - Usage never crosses academies, from platform, own or other context.
     - `canConsume` handles under, at and over the limit, unlimited, and no plan.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 328/328, web 186/186, domain 80/80 |
  | `npm test -w @syniastrolms/api` | 328/328 |

- Regression: the whole existing API suite passes with enforcement at its default, off. Every route behaves
  as before, and the only change to an existing body is the added `code` on permission refusals.
- Migrations:

  | Starting point | Result |
  | --- | --- |
  | Fresh database | 13 migrations, no drift |
  | Database seeded under SAAS-001/002 | only the wording migration applied; 12 plan versions untouched |
  | Copy of the current `dev.db` | all 3 plan migrations applied; FK and integrity clean; `tenants:verify` clean |

**Known limitations**

- **Nothing puts an academy on a plan yet.** Enforcement must stay off until SAAS-004 installs the
  subscription as the plan source.
- **No limit is enforced on a route.** `canConsume` exists but is not atomic; SAAS-011 wires the limits
  concurrency-safely.
- **`analytics.advanced` and `priority_support` gate nothing.** No analytics route exists, and support is a
  service level.
- **The routes lint rule is name-based.** It would miss a table reached through an alias (`const t =
  db.plan`), but the service boundary and review cover that.
- **Each gated request reads the plan version** (three small queries). SAAS-011 may cache.
- **The live-class month is UTC**, not the academy's timezone; SAAS-011 may revisit.

**Files**

New:
- `apps/api/src/lib/entitlements.ts`, `entitlements.test.ts`
- `apps/api/prisma/migrations/20260921180000_entitlement_wording/`

Changed:
- **API:** `src/lib/{errors,permissions,plans}.ts`, and routes `courses`, `chapters`, `lessons`, `quizzes`,
  `assignments`, `certificates`, `live`, `reports`, `settings`
- **Domain:** `packages/domain/src/entitlement.ts` (matrix, wording)
- **Config and docs:** `eslint.config.js`, `apps/api/.env.example`, `docs/00`, `01`, `04`, `05`, `06`, `10`

### SAAS-004 — Subscription Model & State Machine
Started and completed 21 Sep 2026 (claim `6ab67e0`, committed before any code).

**What was built**

- **Domain** (`packages/domain/src/lifecycle.ts`).
  - The seven §5 statuses and `TRANSITIONS`: ten named transitions, each with the statuses it may start
    from, the one it ends in, who may cause it (person, system or provider) and its §19 event.
  - `nextStatus`, `lifecycleEventFor`, `ALLOWED_STATUS_PAIRS` (17 pairs), `ENTITLED_STATES`, `TERMINAL_STATES`
    and `INITIAL_STATES`.
  - `addBillingPeriod`: calendar months and years, clamped to a month's last day.
- **Schema** (migration `20260921200000_subscriptions`).
  - `Subscription` is academy-owned. It holds `planId` and `planVersionId`, with the amount and currency
    copied from the version.
  - `SubscriptionEvent` is the append-only lifecycle log.
  - CHECKs and a partial unique index allow one live subscription per academy.
  - Triggers enforce the machine in the database. Only `trialing` or `active` can be inserted. A status
    change needs a latest event describing exactly that pair. An event must start from the current status,
    be an allowed pair and share the subscription's academy. Plan, amount, currency and cycle change only
    with a matching `change_plan` event. Nothing is updated in the log or deleted anywhere.
  - Both tables are `TENANT_OWNED_MODELS`, bringing the count to 35. `tenants:verify` covers them, and the
    event → subscription relation is checked automatically.
- **Service** (`src/lib/subscriptions.ts`).
  - `createSubscription`: only the platform (a super admin) or a verified provider event may create one. The
    plan must be on sale (`PLAN_UNAVAILABLE`), a trial needs a plan with one, and a second live subscription
    is refused (`INVALID_SUBSCRIPTION_STATE`). The price always comes from the version.
  - One function per transition: `recordPaymentSucceeded`, `recordPaymentFailed`, `expireTrial`,
    `requestCancellation`, `cancelNow`, `resumeSubscription`, `pauseSubscription`, `endCancelledPeriod` and
    `expireGrace`.
  - Each writes its event first and then the status, filtered on the old status, in one transaction. Person
    actions are also written to the platform audit trail (`subscription.created`, `.cancel_requested`,
    `.canceled`, `.resumed`, `.paused`).
  - Creation writes the subscription and its first event in one nested create. That is the reference-check
    limitation SAAS-000 recorded: an academy-context transaction cannot see its own uncommitted parent.
  - Reads: `getSubscription`, `liveSubscription`, `listLifecycle`, and `subscriptionPlanFor`, which is now the
    entitlement service's default plan source.
- **Entitlements.**
  - The source returns `{ planVersionId, status }`, and `TenantEntitlements` gains `status`.
  - `paused` refuses with `402 SUBSCRIPTION_REQUIRED`, "paused"; `canceled` and `expired` refuse with `402
    SUBSCRIPTION_EXPIRED`; an academy with no subscription at all refuses with `402 SUBSCRIPTION_REQUIRED`.

**Policy decisions** (the exact transitions §6 asks for are the table in `docs/06` › Subscription lifecycle)

- **P15 · Terminal means terminal.** `canceled` and `expired` have no way out. A returning academy gets a new
  subscription beside the old one (§12).
- **P16 · Who creates.** Only the platform or a verified provider event creates a subscription. `active`
  without a payment is the platform recording an agreement billed outside the provider (the prototype's
  "invoice" method). Academy self-service arrives with checkout (SAAS-006/013), after the trial rules
  (SAAS-005).
- **P17 · Who may act.** A person is a super admin as the platform, or that academy's own admin inside it. A
  person can never declare a payment.
- **P18 · Continuous periods.** A conversion starts the first paid period at the payment. A renewal and a
  recovery from `past_due` carry on from the last period's end, so overdue days are not free and periods
  never gap. Resuming leaves the period as it was; whether a pause should extend it is SAAS-006's decision.
- **P19 · Entitlement by status.** `trialing`, `active`, `past_due` (grace keeps access, §8) and `canceling`
  (paid to the period's end) serve the plan. `paused`, `canceled` and `expired` serve nothing.
- **P20 · Cancel from a trial** is immediate only. `request_cancel` needs a paid period to run out.
- **P21 · Event naming.** The log uses one row per transition and names it by what happened (see
  `lifecycleEventFor`). `subscription.created` is the audit trail's name for the creation, and the payment
  events proper are SAAS-008's.

**doneWhen — evidence**

1. **A status can only change through a named transition, never by direct write.**
   - The service: *refuses a move the machine does not allow, and writes nothing for it*; *lets each move be
     caused only by who the machine names*; *lets exactly one of two concurrent moves through*.
   - The database: *refuses a status written directly* (raw and Prisma); *refuses a status that does not match
     the latest event, so an old event cannot be replayed*; *refuses a subscription created in a later
     status*; *refuses a price, plan or cycle change without a matching plan-change event*.
2. **Every transition writes a lifecycle event.**
   - *converts a trial, falls due, recovers, cancels at period end, resumes, pauses and cancels*: nine moves,
     with the log growing by exactly one row each, carrying the right §19 event and status.
   - The actor is recorded per row (user id, `system` + job, `provider` + reference).
   - *keeps the lifecycle log append-only*: UPDATE and DELETE on the log, and DELETE of a subscription, are
     refused.
3. **Unit tests cover every edge of the state machine, including refused transitions.**
   - `lifecycle.test.ts` › *allows exactly the documented edges*: all 19 edges, plus every other status ×
     transition combination (51) refused. Also: terminal statuses never move, every status is reachable, and
     the database pair set matches.
   - `subscriptions.test.ts` › *allows exactly the status pairs the domain allows*: all 49 (from → to) pairs
     tried against the triggers from a subscription really in each status, inside rolled-back transactions,
     with the result matching `ALLOWED_STATUS_PAIRS` exactly.
   - Also covered: every live status → `cancel_now`, and the time guards on trial expiry, period end and grace
     expiry.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 354/354, web 186/186, domain 91/91 |
  | `npm test -w @syniastrolms/api` | 354/354 on three of four runs |

  The fourth run failed `superadmin.test.ts` › *refuses an anonymous caller and an unusable token*. It then
  passed that run's rerun, three more full runs and four runs alone. Nothing in this module is on that path
  (anonymous requests to `/superadmin` are refused by `requireAuth`). It is recorded as a flake beside the
  two already logged.
- Security (§47):
  - Cross-tenant: another academy cannot find the subscription (404), and an event must share its
    subscription's academy (trigger).
  - A client-supplied `amount` or `currency` is ignored.
  - The price cannot be rewritten after the fact.
  - An academy admin cannot create an active subscription.
  - A person cannot record a payment.
  - Duplicate subscriptions are refused by the service and by the unique index.
  - Tenant isolation is unchanged: the tenancy suite passes at 35 tables.
- Migrations:

  | Starting point | Result |
  | --- | --- |
  | Fresh database | 14 migrations, 22 triggers, the partial index, no drift, `tenants:verify` clean |
  | Database seeded under SAAS-001/002 | only this migration applied; plans untouched |
  | Copy of the current `dev.db` | 4 migrations applied, 668 rows preserved, FK and integrity clean, `tenants:verify` clean |

**Known limitations**

- **No academy has a subscription yet.** Enforcement stays off until one does. Putting Tenant #1 on a plan is
  a rollout decision (which plan, on what terms), for SAAS-016.
- **No HTTP surface** (SAAS-013) **and no screens** (SAAS-015).
- **Out of scope here:** `change_plan` is in the machine and the triggers, but its rules are SAAS-006's.
  Trial repetition and grace length are SAAS-005's. The jobs that fire time-driven transitions are
  SAAS-012's.
- **The prototype's status names** (`trial`, `past-due`) are still separate from the server's. SAAS-015 maps
  them.
- **Provider references are unique** per (`provider`, `providerSubscriptionId`). `providerCustomerId` is not
  unique here; it belongs to the billing profile (SAAS-009).

**Files**

New:
- `packages/domain/src/lifecycle.ts`, `lifecycle.test.ts`
- `apps/api/src/lib/subscriptions.ts`, `subscriptions.test.ts`
- `apps/api/prisma/migrations/20260921200000_subscriptions/`

Changed:
- **API:** `prisma/schema.prisma`, `src/lib/{entitlements,entitlements.test,tenancy}.ts`,
  `src/routes/tenancy.test.ts` (35 academy tables)
- **Domain:** `packages/domain/src/index.ts`
- **Docs:** `docs/00`, `01`, `03`, `06`, `09`

### SAAS-005 — Trials & Grace Period
Started and completed 21 Sep 2026 (claim `0e7fd80`, committed before any code).

**What was built**

- **The server's clock** (`src/lib/clock.ts`).
  - `now()` is the only clock billing reads.
  - Every subscription function dropped its `now` option. No caller can hand the service a time, so nothing a
    request carries can move a trial or a grace period.
  - Tests move the clock with `setClock`. The entitlement service's usage counting reads it too.
- **Billing configuration** (`src/lib/billingConfig.ts`), from the environment on every use:
  - `graceDays()` reads `SUBSCRIPTION_GRACE_DAYS`: 0–90, **no default**, and a `BillingConfigError` when unset
    or invalid.
  - `repeatTrialsAllowed()` reads `SUBSCRIPTION_REPEAT_TRIALS=on`.
- **Trials.**
  - The length is the plan version's `trialDays`; the start and end come from the server's clock.
  - `createSubscription` refuses a trial for an academy that has had one on any subscription
    (`INVALID_SUBSCRIPTION_STATE`), unless repeats are switched on.
  - The trigger `Subscription_trial_fixed` refuses any change to a trial's dates once written.
- **Grace.**
  - `recordPaymentFailed` stores `pastDueAt` and `pastDueReason`.
  - A new transition, `grace_started` (past_due → past_due; provider or system), is written by
    `startGracePeriod`. It sets `gracePeriodStartAt` and `gracePeriodEndAt = now + graceDays()`, once per
    overdue episode, with the reason and length in the event.
  - The trigger `Subscription_grace_by_transition` lets a grace window be written only by a `grace_started`
    event naming its exact end, in milliseconds as Prisma stores it. A CHECK keeps the window whole and
    ordered.
  - `recordPaymentSucceeded` closes the episode and clears the window.
  - `expireGrace` expires the subscription only once the window has passed on the server's clock.
  - The machine now has 18 status pairs. The migration re-issues the event trigger with the new pair, and the
    49-pair database test covers it.
- **Migration** `20260921220000_trials_grace`: three columns added with `ALTER TABLE ADD COLUMN`, which keeps
  the SAAS-004 triggers, plus three triggers.
- **Test infrastructure: the flaky tests, found and fixed.** Supertest's per-request server bound every
  interface on a random port, and its client connected to 127.0.0.1. This machine has many programs holding
  ports on 127.0.0.1 specifically: Java, Android Studio, the VS Code helper, MySQL and others. When the port
  the OS gave the test server matched one of theirs, macOS allowed both bindings, and the request went to the
  other program. That produced "Expected HTTP/" parse errors, `400 {}`, an unrelated 404, a 401 or a hang.
  - Diagnosis took several steps. A hypothesis that the concurrency tests were responsible was tested (four
    runs with them skipped, still flaky) and dropped. So was a keep-alive theory (six runs with keep-alive
    off, still flaky). Temporary 404 logging showed every 404 was expected. The decisive evidence was a
    parse error meaning a non-HTTP reply.
  - The fix: `src/test/setup.ts` (vitest `setupFiles`) keeps the dual-stack bind and sends supertest's
    requests over `[::1]`. Only our server can hold that address on its port.
  - Before the fix, 4 of 6 full runs failed, each in a different test. After it, 8 of 8 passed, then 2 more
    in verification.
  - This is the root cause of every flake recorded since SAAS-000. It lived in the test harness, not the
    application.

**Policy decisions** (both are the specification's own rules; nothing invented)

- **P22 · One trial per academy.** §7 and the module note say repeat trials are prevented unless explicitly
  allowed. The allowance is the platform switch `SUBSCRIPTION_REPEAT_TRIALS=on`. A paid start is always open.
- **P23 · Grace length is configuration with no default.** Until `SUBSCRIPTION_GRACE_DAYS` is set, no grace
  can start and an overdue academy keeps its access, as §8 says: a failed payment does not destroy access
  unless a rule says so. It must be set before enforcement is switched on (`docs/10`). Each window's end is
  fixed when it starts.
- **P24 · Grace follows retries.** Grace starts when retries are exhausted (§8), not at the first failure.
  Retries themselves are the provider's and SAAS-012's.

**doneWhen — evidence**

1. **Changing the client clock cannot extend a trial.**
   - Structurally, no subscription function accepts a time.
   - `trialsGrace.test.ts`:
     - *sets a trial from the plan and the server's clock, whatever the request says*: an input carrying
       `now: 2027`, `trialEndAt: 2030` and `trialDays: 90` still gets exactly 14 days from the server clock.
     - *expires the trial by the server's clock alone, at exactly its end*: refused at −1 ms, done at the end.
     - *fixes a trial's dates in the database*: raw and Prisma updates are refused.
2. **A tenant cannot start a second trial unless the rule allows it.**
   - *refuses a second trial after the first expired, converted or was cancelled*; a paid start stays open.
   - *gives a first trial to every academy, one each*.
   - *allows a repeat trial only when the platform switches it on*, and a value such as `yes` doesn't count.
3. **Grace duration is configuration, not a constant in code.**
   - *reads the length from SUBSCRIPTION_GRACE_DAYS, and has no default*: 7 and 0 are accepted; unset, empty,
     `seven`, −1, 91 and 2.5 are refused.
   - *follows the configuration, and fixes each grace period's end when it starts*: 3 days and 10 days,
     unchanged after a later config change.
   - *starts no grace while no length is configured — and the academy keeps its access*: no event is written
     and the features are still served.
   - *opens a grace window only through the transition, once per overdue episode*: a raw extension is refused,
     as are a second start, a person, and a subscription that is not overdue.
4. **Trial-expiry and grace-expiry unit tests pass.**
   - The trial boundary tests above.
   - *past_due → retries exhausted → grace → expired, only once the grace has run out*: refused one second
     before; `402 SUBSCRIPTION_EXPIRED` afterwards, with access kept throughout grace.
   - *past_due → retry succeeds → active, with the episode closed*, with the history and a new episode after.
   - The SAAS-004 grace test now goes through `startGracePeriod`.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 367/367, web 186/186, domain 91/91 |
  | `npm test -w @syniastrolms/api` | 367/367 (plus the 8 clean runs after the harness fix) |

- Migrations:

  | Starting point | Result |
  | --- | --- |
  | Fresh database | 15 migrations, 24 triggers, no drift |
  | Database migrated to SAAS-004 | only this migration applied |
  | Copy of the current `dev.db` | 5 migrations applied, FK and integrity clean, `tenants:verify` clean |

- Security: a client-supplied time or trial length is ignored; a trial and a grace window cannot be
  extended by any write; a person cannot start grace or declare a payment.

**Known limitations**

- **Nothing calls the time-driven transitions on a schedule yet** (`expireTrial`, `startGracePeriod`,
  `expireGrace`, `endCancelledPeriod`). That is SAAS-012.
- **Retry counting is not modelled here.** "Retries exhausted" is the provider's or the job's signal.
- **Repeat-trial prevention is per academy.** It is not per person or per payment method, so a person could
  open a second academy for a second trial. The specification asks for per-tenant prevention.

**Files**

New:
- `apps/api/src/lib/{clock,billingConfig}.ts`, `trialsGrace.test.ts`
- `apps/api/src/test/setup.ts`
- `apps/api/prisma/migrations/20260921220000_trials_grace/`

Changed:
- **API:** `prisma/schema.prisma`, `src/lib/{subscriptions,subscriptions.test,entitlements}.ts`,
  `vitest.config.ts`, `.env.example`
- **Domain:** `packages/domain/src/{lifecycle,lifecycle.test}.ts`
- **Docs:** `docs/00`, `01`, `03`, `06`, `10`

### SAAS-006 — Upgrade, Downgrade, Cancellation & Reactivation
Blocked 21 Sep 2026 (`c5643ad`) and unblocked the same day by decisions D7–D10. Claimed in `f06f438`; the policy
was written into `docs/06` and committed on its own (`405b9e7`) before any code.

**Before starting.** The local `dev.db` was 5 migrations behind. It was backed up, then brought current with
`npm run prisma:deploy -w @syniastrolms/api`: all 668 rows kept, integrity and foreign keys clean, no drift,
`tenants:verify` clean. At the end, this module's migration was applied to it the same way (see Verification).

**What was built**

- **Domain** (`packages/domain/src/planChange.ts`).
  - `prorate(amount, part, whole)`: integer paise, the product formed in BigInt, rounded half up, the share
    clamped to [0, whole].
  - `classifyPlanChange`: upgrade, cycle upgrade, downgrade or scheduled change.
  - `quoteImmediateChange`: credit, new value, charge (never below zero) and forfeited credit.
  - `pauseEnd` (1–30 whole days) and `pauseExtensionMs` (the actual paused time, capped at the planned
    resume and at 30 days). `MAX_PAUSE_DAYS` = 30.
- **Schema** (migration `20260922090000_plan_changes`).
  - `PlanChange`: an academy-owned, append-only quote or schedule; see docs/03 for its triggers.
  - `Subscription_period_by_transition`: period dates move only with a lifecycle event that records exactly
    the new dates.
- **API** (`src/lib/planChanges.ts`, the only writer of `PlanChange`).
  - `requestPlanChange` (a person): refused during a trial, in any status but active, while another change is
    open, for a plan not on sale, across currencies, or with nothing to change.
    - An upgrade or monthly → annual gets a `pending_payment` quote priced now against the current period.
    - Anything else is `scheduled`, carrying no money and the academy's limit conflicts.
    - The request is audited as `subscription.plan_change_requested`.
  - `confirmPlanChangePayment` (**provider only**) applies the upgrade through `change_plan` and marks the quote
    applied in the same transaction.
    - Same cycle: the renewal date is unchanged. Monthly → annual: a year from the effective date.
    - A quote whose period ended is marked `expired`; one whose subscription changed since is `void`. Both must
      be quoted again.
  - `applyDueScheduledChange` (**scheduler only**, and only at or after the period end) applies a downgrade.
  - `cancelPlanChange` and `listPlanChanges` (the history).
- **Subscriptions** (`src/lib/subscriptions.ts`).
  - `pauseSubscription(actor, id, { days })`: the server sets `pausedAt` and `resumesAt`; 31, 0, 2.5 and −3
    are refused (400).
  - `resumeSubscription` from a pause extends `currentPeriodEndAt` by the actual paused time. The scheduler may
    resume only once `resumesAt` has passed, and may never withdraw a cancellation.
  - Resume, pause and cancel events carry the reason and `effectiveAt`.
  - Renewal and resume events carry the period in milliseconds for the new trigger.
  - Ending a subscription voids its open plan change.
  - Lifecycle events are dated by the server's clock.
  - `transition()` gained a same-transaction hook.

**Policy** — D7–D10 as given, plus these consequences, written in docs/06 before the code:
- **Rounding:** each prorated figure is rounded half up to a whole paisa.
- **Negative charges:** a charge is never below zero. Credit a monthly → annual change cannot use is recorded as
  `forfeited` and never paid out (D10: no refunds or credits).
- **Annual → monthly and same-price switches** apply at the boundary (D10's rule).
- **No plan change during a trial:** nothing has been paid to prorate. This is SAAS-006's own choice, since
  D7–D10 do not cover trials. You may want to revisit it.
- **Quote expiry:** a quote's figures are fixed when issued and it expires with its period.
- **One open change at a time.**
- **Currency:** a change across currencies is refused. Multi-currency settlement is out of scope (§51).

**doneWhen — evidence**

1. **The upgrade policy is documented before it is coded.** Commit `405b9e7` (docs/06 › Plan changes) comes
   before any SAAS-006 code: `git log --oneline f06f438..` shows it first.
2. **A downgrade with usage over the new limit keeps the data and restricts new usage.**
   - `planChanges.test.ts` › *waits for the boundary, keeps the current plan until then, refunds nothing, and
     reports the limit conflict*: conflicts `[{ learners.max, usage 2, newLimit 1 }]`; Pro's features until 1
     October; applied at the boundary and not a second before; renewal at ₹1,499.
   - *keeps the data over the new limit and restricts new usage*: all 3 learners are still there, and
     `canConsume(learners)` answers `{ allowed: false, limit: 1, usage: 3 }` while courses are unaffected.
3. **Cancel/resume records actor, timestamp, reason and effective date.**
   - *records the actor, time, reason and effective date of each*: request-cancel is effective 1 October,
     resume and cancel-now immediately. Each carries the user id, the server time and the reason, plus the
     subscription's `cancelRequestedAt`, `canceledAt` and `cancellationReason`.
   - *never lets the scheduler withdraw a cancellation*.
4. **Upgrade and downgrade unit tests pass, including the limit-conflict case.** Domain 16 new tests;
   `planChanges.test.ts` 26:

   | Area | Evidence |
   | --- | --- |
   | Prorated upgrade | ₹3,999 → ₹8,999 halfway: credit ₹1,999.50, charge **₹2,500**. No activation before payment (Starter features until confirmed). Renewal date unchanged, then renews at ₹8,999. |
   | Request prices ignored | `charge: 1`, `credit: 9,999,999` and `amount: 5` in the request are ignored |
   | Confirmation | only the provider; two concurrent confirmations → exactly one applies |
   | Stale quotes | expired at the period end; voided when a pause moved the period |
   | Monthly → annual | credit ₹1,999.50 against ₹39,990, charge ₹37,990.50; the year runs 16 Sep 06:30 → 2027-09-16 06:30. On another plan: the whole month credited at the start. |
   | History | 11/30 of ₹8,999 credited on a second change; both changes and both `change_plan` events kept |
   | Boundary changes | annual → monthly scheduled for 2027-09-01; same price → `scheduled_change` |
   | Refusals | trial, past due, no change, archived plan, another currency, period ended, another academy (404), instructor or provider as requester (403) |
   | One open change | enforced by the service and by the unique index |
   | Void on end | an open change is voided when the subscription ends |
   | Database guards | a quote altered, marked applied without its event, moved backwards or deleted; a downgrade inserted with money; a renewal date moved directly — all refused |
   | Pauses | resumed early +3 days; resumed late by the scheduler capped at the planned 10; 30 allowed and 31 refused; a resume long after caps at +30; client dates ignored |

   Domain arithmetic: exact BigInt at 2⁵³, half-up rounding cases, every figure an integer, early and late in the
   period, forfeited credit.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 393/393, web 186/186, domain 107/107 |
  | `npm test -w @syniastrolms/api` | 393/393, three runs out of three |

- Regression: the whole existing API suite passes, covering the Super Admin, Admin, Instructor and Student
  flows. No route or screen changed in this module, so there was no browser pass.
- Migrations:

  | Starting point | Result |
  | --- | --- |
  | Fresh database | 16 migrations, 31 triggers, no drift, `tenants:verify` clean (36 tables) |
  | **Live `dev.db`** | backed up, `npm run prisma:deploy`: this migration applied, "Database schema is up to date", all 683 rows in 45 tables kept, integrity and FK clean, no drift, `tenants:verify` clean; your :4000 server answers `/health` 200 |

- Enforcement: **not enabled.** `ENTITLEMENT_ENFORCEMENT` stays off by default, and no academy has a
  subscription.

**Known limitations**

- **No payment is taken yet.** `confirmPlanChangePayment` is what a verified provider event will call (SAAS-009
  and SAAS-010), and the quote's `charge` is the amount that payment must be for (SAAS-008 records it).
- **No job calls the time-driven moves yet** (`applyDueScheduledChange`, the scheduler's resume). That is
  SAAS-012, which must apply a due scheduled change *before* raising the renewal charge.
- **Limits are not yet enforced on routes.** The "restricted" in doneWhen 2 is `canConsume` refusing;
  SAAS-011 wires it into the routes.
- **No API endpoints** (SAAS-013) **and no screens** (SAAS-015).

**Files**

New:
- `packages/domain/src/planChange.ts`, `planChange.test.ts`
- `apps/api/src/lib/planChanges.ts`, `planChanges.test.ts`
- `apps/api/prisma/migrations/20260922090000_plan_changes/`

Changed:
- **API:** `prisma/schema.prisma`, `src/lib/{subscriptions,subscriptions.test,tenancy}.ts`,
  `src/routes/tenancy.test.ts` (36 tables)
- **Domain:** `packages/domain/src/index.ts`
- **Docs:** `docs/00`, `01`, `03`, `06` (policy, committed first)

### SAAS-007 — Money, Tax & Currency
Started and completed 22 Sep 2026 (claim `9deebe7`, committed before any code).

**What was built**

- **Domain.**
  - `divideRounded(n, d)` in `money.ts`: money division in BigInt, half up, safe-integer checked.
  - `tax.ts` › `calculateTax(amount, currency, components, inclusive)`: rates in integer basis points, several
    components, exclusive (rounded per component) or inclusive (net = gross ÷ (1 + Σrates), the last component
    taking the rounding paisa, so net + tax is exactly the gross).
  - The last floating-point money arithmetic is gone: `monthlyValue` (annual ÷ 12) now uses `divideRounded`,
    and the prototype's `invoiceTax` uses `calculateTax`.
- **Schema** (migration `20260922110000_tax_billing`).
  - `TaxRule` and `TaxRuleComponent` are platform data: one active rule per country and region (partial
    unique index), fixed once written apart from a single retirement, components sealed at the declared
    count, never deleted, and rates CHECK-ed as integers from 0 to 10000.
  - `BillingProfile` is academy-owned, one per academy; the academy-owned count is now 37.
  - The migration inserts no rate.
- **API** (`src/lib/billing.ts`).
  - Billing profiles, validated and normalised. The country must be a real ISO country: groupings like EU and
    UN, and ISO's user-assigned codes, are refused. A registration is kept as issued, with no one country's
    format enforced. Set by a super admin as the platform or the academy's own admin, and audited
    (`billing.profile_updated`).
  - Tax rules: `setTaxRule` retires the active rule for the same place in the same transaction (audited
    `tax.rule_set`), `retireTaxRule` (`tax.rule_retired`), `listTaxRules`, and `taxRuleFor` (region, then
    country, then none). Only a super admin working as the platform may set them.
  - Payable amounts: `payableForNewSubscription` (the plan version's price), `payableForRenewal` (the
    subscription's stored amount) and `payableForPlanChange` (the quote's charge), each taxed at the billing
    address. **None takes an amount.** An academy without a billing address is refused (409).
- **Seed:** a demo GST rule for India at 18%, exclusive, as the prototype's invoices show, plus Tenant #1's
  demo billing address. Both are added only if missing (checked by seeding twice).

**Policy decisions** (none sets a tax rate; rates are the operator's data)

- **P25 · Tax comes from data.** A rule per country or region; a region's rule wins; no rule means no tax. No
  country is named in code (§27).
- **P26 · Rounding.** Half up to a whole minor unit, per component. An inclusive price is split so the
  components add up exactly.
- **P27 · Rules are history.** A rate change is a new rule, never an edit.
- **P28 · No address, no charge.** The tax cannot be decided without the buyer's address.
- **P29 · Currency.** Currency belongs to each price. A plan change across currencies stays refused (SAAS-006;
  §51 multi-currency settlement is out of scope).

**doneWhen — evidence**

1. **No float arithmetic reaches a stored total.**
   - Every division of money is integer: `prorate` (SAAS-006), `divideRounded` and `calculateTax`. The two
     places that divided money as floats were replaced.
   - `billing.test.ts` › *guards every stored amount with an integer CHECK in the database*: reads the live
     schema and finds `typeof(…) = 'integer'` on every amount column (plan prices, subscription amount, the
     five plan-change amounts, tax rates).
   - *refuses a fractional amount wherever one would be stored*: a raw `amount = 3999.5` and a plan priced at
     3999.5 paise are both refused.
   - *calculates tax in integers where a float would drift*: 18% of 1,000,000,000,001 paise is exactly
     180,000,000,000.
   - Domain: 4,000+ amounts checked, every figure an integer and gross = net + tax.
2. **A client-supplied amount is ignored and the server figure is used.**
   - *prices a new subscription from the plan version…*: `amount: 1`, `total: 1`, `tax: 0`, `rateBps: 0` and
     `currency: 'USD'` are all ignored; the result is ₹3,999 + ₹719.82 = ₹4,718.82.
   - *prices a renewal from the subscription's stored amount*.
   - *prices a plan change from the charge fixed on its quote*: the ₹2,500 upgrade becomes ₹2,950 with GST.
   - Structurally, the payable functions have no amount parameter; the earlier guarantees still hold (plan
     prices from versions, subscription amounts copied by the server).
3. **Tax calculation unit tests pass.**
   - Domain `tax.test.ts` (11): exclusive, per-component rounding, inclusive round trips over many prices, the
     rounding paisa, no tax, JPY and USD, and rejects fractions, negatives and rates over 100%.
   - API: no rule means no tax; a region's split CGST+SGST (₹359.91 + ₹359.91) against the country's IGST
     (₹719.82); an inclusive 23% VAT (₹1,230 = ₹1,000 + ₹230); replacement retires the old rule; the database
     guards; malformed rules and the wrong operator refused.
4. **Adding a second currency needs no schema change.**
   - *sells, subscribes and taxes in dollars and yen with the tables as they are*: a USD plan ($49.99 + 5% =
     $52.49) and a JPY plan (¥50,000 + 10% = ¥55,000, no minor unit) are priced, sold and renewed on the
     existing tables. No migration was involved; currency digits come from ISO 4217 via `Intl`.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 410/410, web 186/186, domain 117/117 |
  | `npm test -w @syniastrolms/api` | 410/410, two runs out of two |

- Regression: the existing suite passes throughout. The prototype's invoice figures are unchanged, since the
  web tests assert them.
- Migrations:

  | Starting point | Result |
  | --- | --- |
  | Fresh database | 17 migrations, 36 triggers, no rules inserted, no drift, `tenants:verify` clean |
  | **Live `dev.db`** | backed up, `prisma:deploy`: this migration applied, "up to date", all 683 rows kept, integrity and FK clean, no drift, `tenants:verify` clean, :4000 healthy |

- Enforcement: not enabled.

**Known limitations**

- **No payment, invoice or payment record yet** (SAAS-008 stores what `Payable` calculates). **No endpoint**
  sets a rule or a profile yet (SAAS-013).
- **No reverse charge, exemption or seller-registration logic.** A rule is a list of rates. Place-of-supply
  rules beyond a region match are left for a tax specification (§51).
- **Your live `dev.db` has no tax rule or billing profile.** The seed adds the demo ones; production must
  configure its own before charging.

**Files**

New:
- `packages/domain/src/tax.ts`, `tax.test.ts`
- `apps/api/src/lib/billing.ts`, `billing.test.ts`
- `apps/api/prisma/migrations/20260922110000_tax_billing/`

Changed:
- **Domain:** `packages/domain/src/{money,subscription,index}.ts`
- **API:** `prisma/schema.prisma`, `prisma/seed.ts`, `src/lib/tenancy.ts`, `src/routes/tenancy.test.ts` (37
  tables)
- **Docs:** `docs/00`, `01`, `03`, `06`, `10`

### SAAS-008 — Payment Records & Invoices
Started and completed 22 Sep 2026 (claim `db6ff56`, committed before any code).

**What was built**

- **Schema** (migration `20260922130000_invoices_payments`).
  - Academy-owned `Invoice`, `Payment`, `Refund` and `PaymentMethod`; platform `InvoiceSequence`. The
    academy-owned count is now 41.
  - Integer CHECKs on every amount, and `total = subtotal + taxTotal`.
  - Triggers:
    - An invoice is fixed at issue, is issued open, moves once (open → paid or void), and is paid only with a
      paid payment of exactly its total.
    - A payment's amount and references never change, it settles once (pending → paid or failed), and a paid or
      failed payment is never updated.
    - A refund is against a paid payment, never over what's left, and settles once.
    - A payment method is never rewritten, and the invoice counter only goes up.
    - Nothing is deleted.
  - Partial unique indexes: one live invoice per plan change, and one per renewal period.
  - No column that could hold a card number: `last4` is CHECK-ed to four digits and the brand to hold no digit
    run.
- **API.**
  - `src/lib/invoices.ts`: `issueInvoice` for a renewal (the next period), a plan change (the quote's charge) or
    a new subscription. It is priced by `lib/billing.ts`, numbered `INV-YYYY-NNNNNN` from the series inside the
    transaction, with the billing profile copied in. Plus `voidInvoice` (super admin, reason, audited),
    `getInvoice` and `listInvoices`.
  - `src/lib/payments.ts`:
    - `recordPayment`: provider only, idempotent on (provider, providerPaymentId). Money is always recorded as
      reported, but the invoice settles only on an exact match.
    - `refundPayment`: super admin, with a reason, full by default or partial, audited
      `payment.refund_requested`.
    - `settleRefund` (provider).
    - `savePaymentMethod` (provider, masked only; "Visa •••• 4242").
    - `listPayments`, with refund state derived from the refunds, and `listPaymentMethods`.

**Policy decisions**

- **P30 · Invoice numbers.** One platform-wide series per calendar year (UTC), `INV-2026-000001` upward (the
  prototype's shape), never reused. An invoice is due on issue.
- **P31 · A payment is truth, an invoice is a claim.** A reported payment is always recorded. It settles an
  invoice only when it matches the invoice's total, currency and open status; a mismatch stays visible on an
  open invoice.
- **P32 · Refund state is derived.** §14 lists `refunded` and `partially_refunded` as payment statuses, and also
  says never to overwrite a successful payment. Both hold: the stored row stays `paid`, and the record reads
  refunded or partially refunded from its succeeded refunds.
- **P33 · Refunds** are a super admin's decision each time, with a reason, audited, and capped at what is left.
  When to refund is a person's call; the system only enforces the limits (§25).
- **P34 · Who.** Payments, refund settlement and saved methods come from provider events only. Invoices are
  issued by the platform (scheduler, provider flow or super admin). An academy admin issues nothing.

**doneWhen — evidence**

1. **No code path updates or deletes a paid payment.**
   - Service: `recordPayment` returns the existing record untouched for any report on a settled payment, even a
     later "failed" (*records the same provider payment once, however often it is reported*).
   - `refundPayment` writes a Refund row only.
   - No update or delete of a payment exists anywhere in the code; the only update settles a pending one.
   - Database: *a settled payment cannot be updated or deleted*: status, amount, failure message and last4 on a
     paid payment, a failed payment turned paid, and a delete are all refused.
   - *settles a pending payment once, and then never again*.
2. **Invoice numbers are unique at the database level.**
   - The `Invoice.number` unique index, plus a CHECK on its shape.
   - *numbers invoices in one ascending series, even when issued at once*: six issued concurrently, all distinct
     and consecutive.
   - *refuses a duplicate number and a counter that goes back*: a raw duplicate insert gives UNIQUE, and moving
     the sequence back is refused.
3. **No raw card data exists anywhere in the schema or logs.**
   - *has no column a card number, security code or full expiry could be kept in*: scans every table's columns.
   - *keeps only masked display data*: `cardNumber` and `cvv` in the input are not stored. A 16-digit `last4`,
     a digit-run brand, a card-number reference and a non-digit last4 are refused (400), and a raw insert is
     refused by the CHECK.
   - *writes nothing card-like — nothing at all — to the logs through a whole billing flow*: method, invoice,
     payment, refund and a rejected card-number attempt with every console method spied produce zero output.
4. **A refund leaves the original payment row intact.**
   - *refunds part, then the rest, as separate events, never touching the payment*: the raw payment row is equal
     before and after two refunds, and the record reads partially refunded, then refunded.
   - *never refunds more than was paid — in the service and in the database*: pending refunds count too, and a
     raw over-refund is refused by the trigger.
   - *refuses a refund on an unpaid payment, without a reason, or from anyone but a super admin*.

Also covered:
- **Server figures:** the invoice is ₹3,999 + 5% VAT = ₹4,198.95, and the plan-change invoice is ₹2,500 + ₹125.
- **History:** *keeps its figures and address through a price change and a change of address*.
- **Double billing:** one invoice per renewal period and per plan change, and voiding allows a re-issue.
- **Other refusals:** a short payment leaves the invoice open; only a provider records payments.
- **Isolation:** another academy gets a 404 and sees no lists.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 432/432, web 186/186, domain 117/117 |
  | `npm test -w @syniastrolms/api` | 432/432, two runs out of two |

- Migrations:

  | Starting point | Result |
  | --- | --- |
  | Fresh database | 18 migrations, 52 triggers, no drift, `tenants:verify` clean |
  | **Live `dev.db`** | backed up and deployed: all 683 rows kept, integrity and FK clean, no drift, up to date, `tenants:verify` clean, :4000 healthy |

- Enforcement: not enabled.

**Known limitations**

- **No provider is connected** (SAAS-009) **and no webhook exists** (SAAS-010). The provider-actor functions are
  what those will call once an event is verified. A payment does not yet move the subscription: SAAS-010 joins
  `recordPayment` to `recordPaymentSucceeded` and `confirmPlanChangePayment`.
- **Nothing issues invoices on a schedule yet** (SAAS-012).
- **One invoice series for the platform.** A jurisdiction that needs a separate series per registration or
  financial year would need another series key. `InvoiceSequence.series` already allows it.
- **No endpoints** (SAAS-013) **and no screens** (SAAS-015).

**Files**

New:
- `apps/api/src/lib/{invoices,payments}.ts`, `invoicesPayments.test.ts`
- `apps/api/prisma/migrations/20260922130000_invoices_payments/`

Changed:
- **API:** `prisma/schema.prisma`, `src/lib/tenancy.ts`, `src/routes/tenancy.test.ts` (41 tables)
- **Docs:** `docs/00`, `01`, `03`, `06`, `09`

### SAAS-011 — Usage Tracking & Enforcement
Started and completed 22 Sep 2026 (claim `acfe457`, committed before any code). Selected by workflow §2 while
SAAS-009 is blocked: it depends only on SAAS-003 and SAAS-004, and nothing in it touches the payment gateway.

**What was built**

- **Domain** (`packages/domain/src/entitlement.ts`).
  - `USAGE_STRATEGY`: the written decision per metric (§23).
  - `RESTRICTED_MODE_POLICY`: the written per-operation policy (§21).
- **Schema** (migration `20260922150000_usage_guards`). `UsageGuard` is academy-owned (tenant and limit as the
  key); the academy-owned count is now 42.
- **API.**
  - `src/lib/usage.ts` › `withinLimit(check, write)` runs a write in one transaction that first upserts the
    academy's guard row for the limit (taking the database's lock), then counts usage live inside the same
    transaction, compares it with the plan's limit and writes. It refuses `403 LIMIT_REACHED` over the limit,
    and `402 SUBSCRIPTION_EXPIRED/REQUIRED` in restricted mode unless the write is one the policy keeps open.
  - Usage counts now name the academy explicitly, so they are correct in any context. `live_classes.max` counts
    the month of the class.
  - `requireFeature(feature, { when, restricted })` lets a route say what it is under restricted mode:
    - `update` and `read` stay open (course, curriculum, quiz, assignment and live-class edits, the basic
      reports, the default template);
    - `serve_learners` stays open (issuing earned certificates);
    - everything else is closed.
  - `requireUnrestricted` and `notServed` were added. `isRestricted` reads the state.
  - Limit gates:
    - `POST /auth/register` (learners);
    - `POST /instructors`;
    - `POST /courses` and `POST /courses/:id/restore`;
    - `POST /media/upload` (staff by size; a learner's hand-in counts but is never refused);
    - `POST /live` and `PATCH /live/:id` (moving into another month);
    - `POST /superadmin/admins` and `…/reactivate` (the platform is never restricted).
  - Everything is off unless `ENTITLEMENT_ENFORCEMENT=on`.

**Policy decisions** (both required by the specification; see `docs/06` › Usage limits and restricted mode)

- **P35 · Every metric is live.** Each is counted inside the guarded transaction from tenant-indexed columns,
  so there is no counter, nothing drifts and nothing needs reconciling. SAAS-012's `usage-reconciliation` job
  therefore has nothing to correct and will only report.
- **P36 · Restricted mode keeps what exists and adds nothing.**
  - Kept: reads, edits to existing content, withdrawing it, and serving learners (including their hand-in
    uploads).
  - Refused: creating, publishing, scheduling live classes, staff uploads, advanced reports, branding, and new
    learners or instructors.
  - It applies to paused, cancelled, expired and never-subscribed academies. The platform is never restricted.
- **P37 · Learner hand-ins are never refused on storage.** They serve existing learners, so they count toward
  storage but are not blocked by the limit or restricted mode. Only staff uploads are.
- **P38 · D6 revisited: stay on SQLite.** Concurrency safety came from the guard row, which works the same on
  SQLite (single writer) and PostgreSQL (row lock). No engine change was needed; revisit if write volume ever
  demands it.

**doneWhen — evidence**

1. **A concurrency test cannot exceed a hard limit.**
   - `usage.test.ts` › *lets exactly the room left through when eight courses are created at once*: limit 3,
     one existing, 8 parallel `POST /courses`. Exactly 2 are created and 6 get `LIMIT_REACHED`; the database
     holds 3.
   - *holds for sign-ups too*: 5 parallel registrations for 2 seats; exactly 2 succeed.
   - Stable across three runs of the file and every full run.
2. **Each metric's calculation strategy is written down.**
   - `USAGE_STRATEGY` covers all six limits, with a domain test that every limit has one.
   - The table is in `docs/06` › Usage limits and restricted mode.
3. **Restricted mode blocks creation without destroying access to existing data.** On a subscription cancelled
   with `cancelNow`:
   - *keeps every read, and everything learners do*: seven admin reads, the learner's courses and a learner
     upload all succeed.
   - *keeps editing and withdrawing what exists*: course PATCH and archive.
   - *refuses anything new, with the renew prompt, and removes nothing*: course create, publish, live
     scheduling, staff upload, add instructor, instructor report and branding all get `402
     SUBSCRIPTION_EXPIRED` with the renew message. Course and learner counts are unchanged.
   - *refuses new sign-ups to a restricted academy*.
   - *leaves the platform able to act for a restricted academy*.
4. **Usage enforcement integration tests pass.** `usage.test.ts` has 14 tests, including one per limit on its
   real route:
   - courses, with archive freeing a place and restore needing room;
   - instructors;
   - storage by bytes, with the learner hand-in exemption;
   - live classes per month, including a move into a full month;
   - admins, create and reactivate, with the audit trail still naming the super admin;
   - enforcement off changes nothing.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 446/446, web 186/186, domain 119/119 |
  | `npm test -w @syniastrolms/api` | 446/446, two runs out of two |

- Regression: every existing route test passes with enforcement at its default, off. The wrapped writes run in a
  transaction but behave as before; no screen changed.
- Migrations:

  | Starting point | Result |
  | --- | --- |
  | Fresh database | 19 migrations, no drift, `tenants:verify` clean |
  | **Live `dev.db`** | backed up and deployed: rows kept, integrity and FK clean, no drift, `tenants:verify` clean, :4000 healthy |

**Known limitations**

- **Enforcement is still off.** It needs every academy on a subscription first (SAAS-016 rollout).
- **Limit refusals are codes, not screens.** An upgrade prompt is SAAS-015's.
- **Staff creating learners directly** has no route yet, so none is guarded. Sign-up is the only way a learner
  is created.
- **Resuming a paused subscription** with more content than its plan allows is not refused; the limits apply to
  the next write.

**Files**

New:
- `apps/api/src/lib/usage.ts`, `usage.test.ts`
- `apps/api/prisma/migrations/20260922150000_usage_guards/`

Changed:
- **Domain:** `packages/domain/src/{entitlement,entitlement.test}.ts`
- **API:** `src/lib/{entitlements,tenancy}.ts`, `prisma/schema.prisma`, and routes `auth`, `instructors`,
  `courses`, `media`, `live`, `superadmin`, `chapters`, `lessons`, `quizzes`, `assignments`, `certificates`,
  `reports`, `settings`; `src/routes/tenancy.test.ts` (42 tables)
- **Docs:** `docs/00`, `01`, `03`, `06`, `09`

### SAAS-013 — Platform & Tenant APIs
Started and completed 22 Sep 2026 (claim `35d28a0`, committed before any code).

**What was built**

- **Super Admin** (`src/routes/billingPlatform.ts`, mounted inside the guarded `superadminRouter`).
  - Plans: list, create, read with versions, edit, publish, archive, restore.
  - Subscriptions: list with filters, start (trial or agreement), read with lifecycle, plan changes and
    invoices, cancel now or at period end, pause, resume.
  - Invoices: list, read, void. Payments: list, read with refunds, refund.
  - Tax rules: list, set, retire. Academy billing profiles: read and set.
- **Tenant Admin** (`src/routes/tenant.ts`, `/tenant`).
  - Subscription (with `restricted` and any open plan change), usage per limit, entitlements, and the plans on
    sale (read-only).
  - Upgrade, which returns the quote and the taxed payable amount, and downgrade (scheduled); withdraw a plan
    change; cancel; resume.
  - Invoices, payments and the billing profile.
  - Order: admin → `settings.view` or `settings.edit` → own academy → operation. There is no entitlement gate,
    so a restricted academy can still renew.
- **Error model.**
  - `stableCodes` (`lib/errors.ts`) ends both routers and the whole Super Admin router, so every refusal carries
    one of `BILLING_ERROR_CODES`: the §34 codes plus `UNAUTHENTICATED`, `PERMISSION_DENIED`,
    `VALIDATION_FAILED`, `NOT_FOUND`, `CONFLICT` and `INTERNAL_ERROR`.
  - Prisma outcomes are answered in plain words; nothing internal reaches a body.
- **Library reads for the routes:** `listSubscriptions`, `currentSubscription`, `listAllInvoices`,
  `listAllPayments` and `usageSummary`. `requestPlanChange` takes `expect`, so the upgrade endpoint refuses what
  is really a downgrade before writing anything.
- **Lint.** The routes rule now matches only database clients (`db`, `tx`, `client`, `platformDb`…), which
  ended false positives on record fields. A probe still flagged all three table reads.
- **Docs:** `docs/05` has both endpoint tables and the code list.

**Policy decisions**

- **P39 · Billing permissions.** Tenant billing uses the existing `settings.view` (read) and `settings.edit`
  (change) rather than new keys. New keys would need a grant for every existing admin, and the Phase 9 backfill
  would re-grant narrowed ones.
- **P40 · Billing is reachable in restricted mode.** A restricted academy must be able to renew, so `/tenant`
  has no entitlement gate.
- **P41 · An upgrade needs the billing address first.** The quote's charge is taxed, so the upgrade is refused
  (409) before any quote is written.

**doneWhen — evidence**

1. **A Tenant Admin request for another tenant's subscription is refused.**
   - `billingApi.test.ts` › *cannot name another academy*: another academy's invoice gets `404 NOT_FOUND`, its
     plan change `404 NOT_FOUND`, and the admin's own views show only its own.
   - *cannot reach the platform's endpoints, or manage a plan*: five Super Admin paths each get `403
     PERMISSION_DENIED`.
   - *needs the settings permissions*: without `settings.edit` a cancel gets `PERMISSION_DENIED`, and a learner
     gets `PERMISSION_DENIED`.
2. **Every error is one of the documented codes.** *answers every refusal across both surfaces with a documented
   code*: 17 failing requests, covering unauthenticated, a bad token, a malformed plan, a duplicate code, a
   fractional price, an unknown plan, a double publish, a second live subscription, an unknown subscription, a
   31+-day pause, an unknown country, an unknown payment, an unknown plan to upgrade to, a non-upgrade, resume
   with nothing to resume, a bad billing profile and an unknown invoice. Every body's `code` is in
   `BILLING_ERROR_CODES`.
3. **No provider or database detail appears in an error body.** *never lets a provider or database detail into
   an error body*: four concurrent tax rules for the same country, so the losers hit the database's unique index.
   The bodies contain none of prisma, sqlite, constraint, unique, SQL, a stack or a file path; each carries a
   documented code; and one rule stands.
4. **Subscription API integration tests pass.** 11 tests over HTTP:
   - Plans: create, then an edit into version 2, then publish, archive and restore.
   - Subscriptions: start, list, pause, resume and cancel, with the lifecycle recorded.
   - Money: invoice ₹4,198.95 incl. 5% VAT, payment, refund (reason required), void refused on a paid invoice.
   - Tenant views: subscription, usage, entitlements, plans, invoices, payments, profile.
   - Upgrade: the quote ₹2,500 + ₹125 VAT = ₹2,625, a client `charge`/`amount` ignored, and the plan unchanged
     until payment.
   - A downgrade scheduled, then cancel and resume, recorded with the admin as actor.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 457/457, web 186/186, domain 119/119 |
  | `npm test -w @syniastrolms/api` | 457/457, two runs out of two |

- Regression: every existing Super Admin, admin, instructor and student test passes. The existing Super Admin
  error bodies gained a `code` field, which is additive.
- No migration in this module, so `dev.db` needs nothing.

**Known limitations**

- **An upgrade cannot be paid yet.** Checkout and the provider's confirmation are SAAS-009/010.
- **No screen calls these endpoints yet** (SAAS-015).

**Files**

New:
- `apps/api/src/routes/{billingPlatform,tenant,billingApi.test}.ts`

Changed:
- **API:** `src/app.ts`, `src/routes/superadmin.ts`, `src/lib/{errors,subscriptions,invoices,payments,usage,planChanges}.ts`
- **Config and docs:** `eslint.config.js`, `docs/00`, `01`, `05`

### SAAS-014 — Audit & Observability
Started and completed 22 Sep 2026 (claim `3cecaa5`, committed before any code). Spec: subscriptions.md §36, §48.

**What was built**

- **Audit sources** (`lib/audit.ts`, migration `20260922170000_audit_sources`).
  - `recordAuditLog` takes a person (a request, or a lifecycle actor of type `user`), or a source:
    `{ type: 'system', job }` or `{ type: 'provider', provider, reference? }`.
  - A source is written as itself: `actorType`, `source`, no `actorId`, `actorRole` `system` or `provider`,
    and the provider's reference in the metadata. Before this, scheduler and provider moves reached only the
    lifecycle log and never the audit trail.
  - Database triggers enforce the entry's shape and make the trail append-only. The one update allowed is the
    foreign key clearing `actorId` when the account is removed.
  - **Bug fixed:** the person is now looked up across the platform. Before, a super admin's
    `subscription.created` entry, written inside the academy's transaction, lost its actor (no `actorId`, empty
    email). The new tests caught it.
- **Vocabulary** (`BILLING_AUDIT_ACTIONS`). Every action §36 names is written, in the same transaction as its
  change.
  - Plans: `plan.created`, `plan.updated`, `plan.published`, `plan.archived`, `plan.restored`. A new version
    also writes `entitlement.changed` (features added and removed) and `limit.changed` (each limit from → to).
    An edit to the price alone writes neither.
  - Subscriptions: `subscription.created`. Every transition, whoever made it: `activated`, `renewed`,
    `recovered`, `past_due`, `grace_started`, `trial_expired`, `expired`, `plan_changed`, `cancel_requested`,
    `canceled`, `resumed`, `paused`.
  - Plan changes: `plan_change_requested` and `plan_change_canceled`, plus `plan_change_closed` when a quote
    expires or is voided.
  - Tenant entitlements: `entitlement.changed` (target `tenant`) whenever an academy enters or leaves an
    entitled status or moves plan version. This includes pause and resume: a paused academy is not entitled.
  - Money:
    - `invoice.created` (by anyone, the scheduler included), `invoice.paid`, `invoice.failed` (a failed attempt;
      the invoice stays open) and `invoice.voided`;
    - `payment.succeeded`, `payment.failed`, `payment.refund_requested`, `payment.refunded` and
      `payment.refund_failed`.
- **Observability** (`lib/observe.ts`).
  - `observe(signal, fields)` writes one JSON line and keeps warnings and errors in a 200-entry window.
    - Signals: `payment.failed`, `payment.unmatched`, `refund.failed`, `webhook.failed`, `job.failed`,
      `subscription.state_changed`, `entitlement.denied`, `limit.reached`, `request.failed`.
  - Wired in:
    - payments and refunds;
    - every subscription transition and creation;
    - the scheduler (`watchJob`: each academy's failure is named and the run goes on) and its outer loop in
      `index.ts`;
    - the error handler. It reports a 500 as `request.failed` (path without query, error redacted, replacing
      the old `console.error`) and a §34 entitlement or limit refusal as `entitlement.denied` or
      `limit.reached`.
  - `GET /superadmin/observability` shows the window. The audit list gains `actorType`, `action`, `targetType`
    and `targetId` filters, and `actor.type` and `actor.source`.
  - Signals are silent under the test runner unless a test installs a sink.
- **Redaction.** `redact` and `redactText` run on every field before it is written or kept.
  - Sensitive keys are dropped: password, token, secret, signature, authorization, cookie, API key, card number,
    CVV, hash.
  - In text, these are masked: card numbers (13–19 digits, grouped or not), JWTs, bearer and basic credentials,
    Stripe and Razorpay keys, `whsec_` secrets, `name=secret` pairs, and one-time tokens in reset links and
    `?token=` queries.
- **Mail log.** In production `MAIL_TRANSPORT=log` prints only the envelope (to, subject, template), never the
  body. The body carries the reset link. Development still prints it.
- **Docs:** `docs/00`, `03` (audit trail), `05` (audit filters, observability), `09` (two security bullets) and
  `10` (operating: signal lines and where to look).

**Policy decisions**

- **Signals and the audit trail stay separate.** The trail records what changed and who changed it, is
  durable and cannot be rewritten. Signals are what an operator acts on: failures and refusals, which change no
  data.
- **The failure window is in memory.** It restarts with the process, and the log is the durable record. A
  persisted operations table would be new state without a stated need, so it can come with SAAS-016 if
  operations wants one.
- **Webhook failures: the reporting function exists, and nothing calls it yet.** `webhookFailed(provider,
  reason, fields)` is written and tested, signature redaction included. No webhook endpoint exists because
  SAAS-010 waits on the gateway decision. Its handler must report every refusal (bad signature, unknown event,
  handler error) through this function. This is recorded here for SAAS-010.
- **A paused subscription writes `entitlement.changed`.** `paused` is not in `ENTITLED_STATES`, so a pause
  withdraws the plan's grants and a resume restores them. Nothing about pausing changed; the trail now shows it.

**doneWhen evidence**

1. **Every sensitive mutation writes an audit entry naming its actor or source.**
   `auditObservability.test.ts` › "the audit trail names who did it":
   - A plan's life under the super admin: 8 entries in order, including `entitlement.changed` and
     `limit.changed` with their exact changes.
   - A trial expiring under `system`/`audit-tests`, with no person on the entry.
   - Invoice, payment and refund flows under `provider`/`testpay`, with the provider's reference kept.
   - A subscription's full history (pause, resume, provider upgrade, withdrawn downgrade, scheduler downgrade,
     cancel request), each entry under the right actor type.
   - "writes every action §36 names": all 18 are present.
   - The database refuses a changed entry, a deleted one, and a system event with no source. An entry survives
     the removal of its account.
2. **A log sweep finds no secret, card number, password or token.** With `console.*`, `process.stdout` and
   `process.stderr` all captured and signal lines switched on, the sweep:
   - signs in over HTTP (keeping the token), makes one wrong-password attempt, and requests a password reset
     under production;
   - records a declined card whose message quotes the number, and a webhook failure carrying a signature and a
     basic credential;
   - runs a job that fails quoting `webhook_secret=whsec_…`, and a direct signal with a password field and a
     JWT.

   The log contains the payment, webhook and job lines and the mail envelope. It contains none of the 11
   secrets used, and no 13–19 digit run. A source scan finds `console` in no runtime file besides the three
   allowed ones.
3. **Failures in payments, webhooks and jobs are all visible.** "failures are visible":
   - Payments: `payment.failed` is emitted with the card number in its message masked, alongside
     `payment.unmatched`. Both show in `GET /superadmin/observability`, and the failed payment in
     `GET /superadmin/payments?status=failed`.
   - Webhooks: `webhook.failed` is emitted with its signature redacted, and shows in the window.
   - Jobs: `job.failed` is emitted with the error redacted and the error rethrown. The scheduler test now asserts
     a named `job.failed` for the broken academy while the others still run.
   - Also tested: subscription state changes, entitlement and limit refusals, and a 500 whose body and signal
     carry nothing sensitive.
   - The window is Super Admin only (admin 403, anonymous 401).

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 478/478, web 186/186, domain 119/119 |
  | `npm test -w @syniastrolms/api` | 478/478 |

- `dev.db`:
  - Backed up (outside the repo), then brought current with `prisma:deploy`, which applied
    `20260922170000_audit_sources`.
  - Its 11 existing audit rows are kept, all `user`. The three triggers are present.
  - `prisma migrate diff` against the schema is empty. `tenants:verify` is clean: 42 tables, 659 rows,
    52 relations.
  - The API starts on it, and admin sign-in returns a token.
- Regression: every existing Super Admin, admin, instructor and student test passes. The one test changed is
  the scheduler's failure test, which now asserts the `job.failed` signal instead of a `console.error` call.

**Files**

New:
- `apps/api/src/lib/{observe,auditObservability.test}.ts`
- `apps/api/prisma/migrations/20260922170000_audit_sources/`

Changed:
- **API:** `prisma/schema.prisma`, `src/index.ts`, `src/lib/{audit,errors,invoices,mail,payments,planChanges,plans,scheduler,subscriptions}.ts`, `src/routes/{superadmin,tenancy.test}.ts`
- **Docs:** `docs/00`, `03`, `05`, `09`, `10`

### SAAS-015 — Frontend Integration
Started and completed 22 Sep 2026 (claim `123b8a0`, committed before any code). Spec: subscriptions.md §24,
§25, §34.

**What was built**

- **Shared read models** (`packages/domain/src/billingViews.ts`).
  - The Super Admin screens' shapes (`SubscriptionOverview`, `PlanRow`/`PlanDetail`, `SubscriberListResult`,
    `SubscriptionDetail`, `PaymentListResult`) moved out of the web contract. The API builds them and the web
    re-exports them, so both sides share one definition.
  - New for the academy admin: `TenantBilling`, `UsageLine`, `OpenPlanChange`, `TenantPayment` and
    `PlanChangeQuote`, plus `SUBSCRIPTION_STATUS_OF` (the API's states in the screens' words).
  - Domain changes:
    - `Invoice.amounts` holds the server's fixed subtotal, tax and total. `invoiceSubtotal`, `invoiceTax` and
      `invoiceTotal` return these when present, so a screen never recalculates an issued invoice.
    - `PaymentStatus` gains `void`, and `PaymentMethod` gains `mandate`.
    - `ChangePlanInput` loses `effective`: when a change applies is the rules' decision (D7–D10), not the
      client's.
- **API read models** (`lib/billingViews.ts`, `routes/billingViews.ts` at `/superadmin/billing-views`).
  - Views: overview, plans with subscriber counts and MRR, plan detail with a six-month trend, subscribers with
    filters, counts taken before the status filter and paging, one subscription's detail, and invoices with
    outcomes and totals (looked up by id or by number).
  - History is replayed from the lifecycle log: status, plan and price at each month's end, and joins, moves
    and leaves per month. The current month is the live book, so the headline figures always equal the
    subscriber list's.
  - A subscription's detail shows its own plan version, and its history in words: every lifecycle event and
    every plan-change quote, schedule and closure, each naming its actor (a person, the scheduler or the
    provider).
- **API actions.**
  - `POST /superadmin/subscriptions/:id/plan-change`: the rules decide timing; a client `effective` or
    `charge` is ignored (tested).
  - `GET /tenant/billing` and `GET /tenant/billing/invoices/:id`: the academy's own view. It runs inside its
    own context, so another academy's invoice is not found.
  - `POST /tenant/subscription/change`: the server says whether it is an upgrade (with a quote and the payable
    amount) or a downgrade (with its date).
    - Without a billing address, an upgrade is refused before anything is written. `UnexpectedUpgradeError`
      replaces a message match.
- **Web HTTP services.**
  - `services/http/subscriptions.ts` implements the whole `SubscriptionService` against the views and the
    billing endpoints.
    - Plans: a create goes in as a draft, then publish, archive or restore by the named steps. A duplicate
      takes the first free `CODE-n`.
    - Cancel sends `immediately`.
    - Reactivate withdraws a pending cancellation, or starts a new subscription for one that is over.
  - `services/http/tenantBilling.ts` implements the new `TenantBillingService`.
  - `httpServices` no longer imports the mock; the "same records in both modes" wiring is gone.
- **Mock mode (the demo)** keeps working and follows the same rules:
  - an upgrade is quoted with the domain's proration and waits for a payment;
  - a downgrade is scheduled for the period end;
  - a pause runs 1–30 days, and resuming moves the renewal date by the time actually paused;
  - reactivating a cancellation keeps its period.

  New `services/mock/tenantBilling.ts` serves the demo academy.
- **Screens.**
  - `PrototypeNote` renders in mock mode only, worded for demo data. The overview's hard-coded note is now a
    `PrototypeNote`. Notes that were untrue against the API ("nothing enforces limits", "prototype") are
    rewritten.
  - The change-plan dialog has no effective-date choice. It explains the outcome: an upgrade is prorated and
    applied once paid, with the renewal date unchanged; a downgrade applies at the period end with nothing
    refunded.
  - Pause offers 7, 14, 21 or 30 days. The resume and reactivate copy is corrected.
  - The invoice dialog shows the server's amounts, loads through an injectable `load`, and has no platform
    link on the academy page.
- **Academy admin page** `/admin/billing` (`pages/billing/AcademyBillingPage.tsx`).
  - It shows plan, status, cycle, renewal, amount, usage against every limit, features, invoices, payments
    and the plans on sale.
  - Asking for another plan confirms first, then shows the server's quote or date. An open change can be
    withdrawn.
  - Banners cover past due, trial, cancelling, paused and restricted.
  - While enforcement is off, the page says nothing is blocked instead of warning of a block (see the policy
    decisions).
  - Access: a nav item "Billing" (Insight group); `ADMIN_PAGE_PERMISSIONS` maps `/admin/billing` to
    `settings.view`; changes need `settings.edit`.
- **§34 as states.**
  - `lib/billingStates.ts` gives each of the nine codes a title, a meaning, a tone, where it is resolved, and
    whether it affects the whole academy.
  - The HTTP client reads the body's `code` onto `ServiceError.reason` and shows the error in the state's own
    words. It keeps the server's sentence only where the request's reason matters (`PLAN_UNAVAILABLE`,
    `INVALID_SUBSCRIPTION_STATE`), maps 402 to `forbidden`, and fires `syniastrolms:billing-refusal`.
  - `shell/BillingBanner.tsx` shows academy-wide refusals once, above the page, with a link to Billing for an
    admin. `PlatformError` titles a refusal by its state.
- **Docs:** `docs/00`, `05` (view, plan-change and tenant endpoints) and `07` (two screen rows; the §34 rule).

**Policy decisions**

- **The screens' aggregates are computed on the server.** The web contract's overview KPIs, per-plan
  MRR and list counts have no source but stored records, so the API builds them. The client never computes a
  figure it shows as fact. This follows the rule that the client never controls price or status.
- **History is replayed from the lifecycle log, not modelled.** In mock mode the history is still modelled,
  and the note says so.
- **Reactivating a closed subscription starts a new one.** A canceled or expired subscription is history
  (terminal state), so it gets a new agreement on the same plan and cycle, at the plan's current price
  (P16). A pending cancellation is withdrawn instead.
- **The academy page is honest about enforcement.** `ENTITLEMENT_ENFORCEMENT` is off, so no limit, feature
  or missing plan blocks anyone. `TenantBilling.enforced` carries this. Found on `dev.db`: the seeded academy
  has no subscription, and the page would otherwise have said nothing could be added.
- **Checkout is not offered.** `checkoutAvailable` is `false` until SAAS-009/010. An upgrade is quoted and
  waits for a payment the platform records; the page says so.

**doneWhen evidence**

1. **No screen reads a mock subscription fixture.**
   - A source scan over `apps/web/src`, everything outside `services/mock/` included, finds no import of
     `mock/subscriptions`, `mock/tenantBilling` or `mock/fixtures/subscriptions`.
   - `httpServices.subscriptions` and `httpServices.tenantBilling` are the HTTP implementations (tested).
2. **Mock mode still works for the demo, with the prototype note only where data really is invented.**
   - The mock subscription and demo billing suites pass: 24 and 4 tests.
   - `PrototypeNote` returns null unless `API_MODE === 'mock'`. Every note is worded for demo data, and the
     overview's hard-coded note now goes through it.
   - The build passes.
3. **Tenant Admin sees their own subscription and cannot reach the platform screens.**
   - API: `GET /tenant/billing` returns the admin's own academy.
     - Another academy's invoice is 404 by id and by number.
     - An instructor gets 403.
     - An admin gets 403 on every `/superadmin/billing-views/*`.
     - On `dev.db`, the seeded admin gets its own academy and 403 on the platform views.
   - Web: `workspaceRedirect` sends an admin from every `/superadmin/subscriptions*` path to `/admin`. The
     nav shows Billing, and `pagePermission('/admin/billing')` is `settings.view`.
4. **Every §34 error code renders as a real state, not a raw message.** For each of the nine codes, a test
   returns it from the API with a raw server message and checks that:
   - the `ServiceError` carries the code as `reason`;
   - the message starts with the state's title and drops the raw text (except the two request-specific codes);
   - `billingStateOf` returns the state;
   - the refusal event fires.

   Another code (`CONFLICT`) keeps its message and fires nothing. Every screen shows `error.message` through a
   toast, `ConfirmDialog` or `PlatformError`, so every refusal reads as its state. `PlatformError` and the
   academy page title a refusal by its state.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 490/490, web 211/211, domain 119/119 |
  | `npm test -w @syniastrolms/api` | 490/490 |

- New tests: API `routes/billingViews.test.ts` (12); web `services/http/subscriptions.test.ts` (21) and
  `services/mock/tenantBilling.test.ts` (4).
- Updated tests: the mock subscription suite (plan changes follow D7–D10, pause D9), navigation, admin
  permissions and workspace access.
- The API views were exercised against `dev.db`.
- No migration, so `dev.db` needs nothing.
- Regression: every existing Super Admin, admin, instructor and student test passes.

**Known limitations**

- **Upgrades cannot be paid online**, and there is no provider checkout: SAAS-009/010.
- **No render tests:** the web app has no DOM test setup. Screens are verified through their services, the
  shared state map and the build.
- **Views load the whole book into memory** (`loadBook`). This is right for today's platform size; SAAS-016
  should revisit it if subscriptions reach the thousands.

**Files**

New:
- **Domain:** `packages/domain/src/billingViews.ts`
- **API:** `src/lib/billingViews.ts`, `src/routes/billingViews{,.test}.ts`
- **Web:** `src/lib/billingStates.ts`, `src/services/http/{subscriptions,tenantBilling,subscriptions.test}.ts`,
  `src/services/mock/tenantBilling{,.test}.ts`, `src/pages/billing/AcademyBillingPage.tsx`,
  `src/shell/BillingBanner.tsx`

Changed:
- **Domain:** `index.ts`, `subscription.ts`
- **API:** `src/lib/planChanges.ts`, `src/routes/{billingPlatform,superadmin,tenant}.ts`
- **Web:**
  - Services and access: `services/{contracts.ts,http/client.ts,http/httpServices.ts,mock/mockServices.ts,mock/subscriptions{,.test}.ts}`, `app/router.tsx`, `shell/{AppShell,navigation}.tsx`, `lib/adminPermissions.ts`
  - Screens: `pages/superadmin/{platformMeta.tsx,subscriptions/*}`
  - Tests: `shell/navigation.test.ts`, `lib/{adminPermissions,workspaceAccess}.test.ts`
- **Docs:** `docs/00`, `05`, `07`

### SAAS-009 — Payment Provider Abstraction
Started and completed 22 Sep 2026 (claim `5dcacaf`, committed before any code). Spec: subscriptions.md §13, §43,
§44, §45.

The blocker was resolved by the product owner: Razorpay, with test-mode credentials supplied in `apps/api/.env`
(git-ignored). The credentials were verified with one read-only call (HTTP 200).

**What was built**

- **The abstraction** (`lib/paymentProvider.ts`).
  - The §13 `PaymentProvider` interface, plus the three calls a verified checkout needs (`fetchPayment`,
    `capturePayment`, `verifyCheckout`) and `checkoutParams`: `createCustomer`, `createSubscription`,
    `cancelSubscription`, `pauseSubscription`, `resumeSubscription`, `changePlan`, `createPayment`,
    `refundPayment`, `verifyWebhook`.
  - `paymentProvider()` / `requireProvider()` and a test seam `setPaymentProvider`.
  - `ProviderError` (502, `PAYMENT_FAILED`, our own words) and `PaymentUnavailableError` (409,
    `PAYMENT_REQUIRED`).
  - `assertPaymentConfig`, run at start-up. It refuses an unknown provider, a missing key, and a production
    start without a webhook secret. It names settings, never values.
- **The one adapter** (`lib/razorpay.ts`): Razorpay's REST API over HTTPS with Basic auth, a 15-second
  timeout, and no SDK.
  - Orders are created for exactly the server's amount in paise, and refused if Razorpay echoes a different
    one. Notes are capped as Razorpay requires.
  - Payments are read back with `expand[]=card`. Only the network and last four digits are kept, or "UPI"
    (no address), or the bank's name. Wallets and EMI keep no method.
  - Razorpay's statuses are mapped; an unknown one is refused.
  - Authorized payments are captured for the exact amount.
  - Refunds map `processed/pending/failed`. Recurring plans and subscriptions are created, changed, paused,
    resumed and cancelled.
  - Checkout (`order|payment` under the key secret) and webhook (the body under the webhook secret) signatures
    are verified with HMAC-SHA256, compared in constant time. With no webhook secret, every webhook is
    refused.
  - Razorpay's error text is logged, redacted, through `observe` and never returned.
- **The §43 flow** (`lib/checkout.ts`).
  - `startCheckout` takes an open invoice, or an upgrade quote (invoiced first by the `system` checkout job,
    once per quote). The amount is the invoice's total, and an open order is reused. It opens a
    `PaymentOrder`.
  - `confirmCheckout` verifies the checkout signature, then `settleProviderPayment` reads the payment from
    the provider, checks it belongs to the order, and captures it if it is only authorized. Only then does it
    record the payment (`recordPayment`, idempotent) under a `provider` actor carrying the payment reference.
  - A settled invoice moves the subscription:
    - an upgrade: `confirmPlanChangePayment`;
    - a trial or past-due subscription: `recordPaymentSucceeded`;
    - an active subscription whose renewal invoice is for the next period: renewed.
  - If the move is no longer allowed, it is reported (`payment.unmatched`) rather than forced.
  - The webhook handler (SAAS-010) will call the same `settleProviderPayment`.
- **The §44 flow.** A failed payment is recorded with its code and reason and the invoice stays open. A failed
  renewal moves an active subscription to `past_due`, with the reason, under the provider. A later payment on
  the same order recovers it. Retries, grace and expiry are SAAS-012's jobs (the transitions exist since
  SAAS-005).
- **Refunds** (`refundThroughProvider`). The refund is recorded, then asked of the provider when it took the
  payment; its answer settles the refund, and a refusal is recorded as failed. A payment the provider did not
  take keeps its refund pending. The Super Admin refund endpoint uses it.
- **Schema.** `PaymentOrder` (academy-owned; the count is now 43) comes from migration
  `20260922190000_payment_orders`, plus `…190100_payment_orders_tenant_index`. Database triggers enforce:
  - an order is for an open invoice of the same academy, at exactly its total and currency;
  - it is fixed once made and moves from `created` to `paid` once, naming the payment;
  - it is never deleted.
- **API.** `POST /tenant/billing/checkout` and `POST /tenant/billing/checkout/confirm` (admin, `settings.edit`).
  `/tenant/billing` now reports `checkoutAvailable` from the configuration.
- **Web.**
  - The academy billing page gains **Pay** on open or failed invoices and on an upgrade waiting for payment.
    It opens Razorpay Checkout with only the server's order and publishable key id
    (`lib/razorpayCheckout.ts`), passes Razorpay's answer back unchanged, and shows the server's outcome.
  - Demo mode offers no checkout.
- **Tests never reach the gateway.** `vitest.config.ts` pins the provider variables empty. Suites that need a
  provider install a fake.
- **Docs:** `apps/api/.env.example` (the variables, with no values), `docs/00`, `03`, `05`, `09` and `10`.

**Policy decisions**

- **Every charge is an invoice paid through an order.** The platform's own lifecycle stays the source of truth
  (SAAS-004–006): its renewal, grace and expiry rules are enforced in its database. Razorpay's recurring
  Subscriptions API is implemented in the adapter and tested, but not switched on. Moving renewals to
  auto-debit mandates is a rollout decision (SAAS-016), and would feed the same `settleProviderPayment`.
- **A checkout is confirmed from the provider's side.** The browser's handler result is checked by signature,
  then the payment is read from Razorpay server to server. This is Razorpay's documented verification, and
  it means a checkout can be confirmed even before webhooks are configured. Webhooks (SAAS-010) become the
  asynchronous path into the same idempotent function.
- **No customer records are stored yet.** Orders need none. `createCustomer` exists for the mandate path.
- **`RAZORPAY_WEBHOOK_SECRET` is empty.** This is not a blocker for this module: signature verification is
  implemented and tested with a test secret, and with none set every webhook is refused. Production refuses
  to start without it. You choose the value when adding the webhook in the Razorpay dashboard (needed before
  SAAS-010 can be exercised against real events).

**doneWhen evidence**

1. **The LMS contains no direct gateway SDK call outside the adapter.**
   - `checkout.test.ts` › "calls the Razorpay API from lib/razorpay.ts only": every tracked source file except
     the adapter is free of `api.razorpay.com` and of `razorpay`/`stripe` imports.
   - No package manifest depends on a gateway SDK. The adapter itself uses none.
   - The browser loads Razorpay's hosted checkout script and nothing else.
2. **Activating a subscription requires a verified provider event, not a browser callback.**
   "activates nothing on the browser's word":
   - A forged confirmation gets 400.
   - A correctly signed checkout whose payment the provider reports `pending` records nothing.
   - The plan, the lifecycle log and the payments are all unchanged.

   "records the provider's payment … once": the provider reports the payment authorized; it is captured,
   recorded and applied, with `change_plan` under `provider/fakepay` carrying the payment reference.
   Confirming again changes nothing: 1 payment, 1 change.

   A payment from another order gets 400. Another academy's invoice or order is 404.
3. **The failed-payment path records the failure and moves to past_due.** "records a failed renewal":
   - The payment is stored `failed` with its code and reason, and the invoice stays open.
   - The subscription is `past_due` with the reason, via `payment_failed` under the provider.
   - The same failure reported again adds nothing. The next payment recovers it to `active` for the next
     period.
4. **No secret is committed.**
   - `apps/api/.env` is git-ignored and untracked (tested).
   - A test reads the configured `RAZORPAY_*` values and finds none of them in any tracked file, and no
     `rzp_live_`/`sk_live_` key outside the redaction tests' made-up samples.
   - `.env.example` documents the names only.
   - The key secret never leaves the server: `checkoutParams` carries the key id only (tested).

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 521/521, web 211/211, domain 119/119 |
  | `npm test -w @syniastrolms/api` | 521/521 |

- New tests: `lib/razorpay.test.ts` (17, adapter over stubbed HTTP) and `routes/checkout.test.ts` (14, the flows
  against a fake provider, isolation, database guards, refunds, source and secret scans). The web service
  test is extended for checkout.
- **Live smoke test against Razorpay test mode** (the real adapter, one script, then deleted):
  - A ₹1 order was created, with the amount echoed exactly.
  - The checkout parameters carry the test key id only.
  - Reading a payment that does not exist came back as `ProviderError 502 PAYMENT_FAILED` "The payment provider
    refused the request." (Razorpay's own answer was 400 `BAD_REQUEST_ERROR`, kept out of the message).
  - A forged checkout signature was rejected.
- `dev.db`:
  - `20260922190000_payment_orders` was applied by a `prisma migrate deploy` run **without a backup first**,
    which was my mistake. The migration only adds an empty table, and afterwards the data was unchanged:
    659 academy rows, as before; `tenants:verify` clean.
  - The follow-on index migration was applied after a backup (kept outside the repo).
  - Schema diff empty; 43 tables.
- Regression: every existing Super Admin, admin, instructor and student test passes.

**Known limitations**

- **Webhooks** (the asynchronous confirmation path, retries on missed callbacks) are SAAS-010. Until then an
  academy that closes the window after paying, without the confirm call reaching the server, stays unpaid
  until someone confirms it.
- **No renewal invoices are issued automatically** before SAAS-012, so the Pay button appears for invoices a
  super admin or the scheduler has issued, and for upgrade quotes.
- **No browser test of Razorpay's window:** the web app has no DOM test setup.

**Files**

New:
- **API:** `src/lib/{paymentProvider,razorpay,razorpay.test,checkout}.ts`, `src/routes/checkout.test.ts`, the two
  migrations
- **Web:** `src/lib/razorpayCheckout.ts`

Changed:
- **API:** `prisma/schema.prisma`, `.env.example`, `vitest.config.ts`, `src/index.ts`, `src/lib/{billingViews,tenancy}.ts`, `src/routes/{billingPlatform,tenant,tenancy.test}.ts`
- **Domain:** `billingViews.ts`
- **Web:** `services/{contracts.ts,http/tenantBilling.ts,http/subscriptions.test.ts,mock/tenantBilling.ts}`, `pages/billing/AcademyBillingPage.tsx`
- **Docs:** `docs/00`, `03`, `05`, `09`, `10`

### SAAS-010 — Webhooks & Idempotency
Started and completed 22 Sep 2026 (claim `1850abd`, committed before any code). Spec: subscriptions.md §17, §18,
§19.

**What was built**

- **`POST /webhooks/:provider/subscription`** (`routes/webhooks.ts`, `lib/webhooks.ts`). It is mounted before the
  JSON parser, so the body arrives raw; there is no session and no academy context. The §17 steps, in order:
  1. **Verify** the signature over the exact bytes (`X-Razorpay-Signature`, HMAC-SHA256 under the webhook
     secret). Unsigned, mis-signed or tampered deliveries get **401**, are stored nowhere, and emit a
     `webhook.failed` signal.
  2. **Validate and identify.** The adapter's new `parseWebhook` maps Razorpay's shape to a provider-neutral
     event of ids and status only. No event id, not JSON, or not an event gets **400**.
  3. **Idempotency:** one `WebhookEvent` per (provider, providerEventId), unique in the database.
     - A processed or ignored event answers **200 `duplicate`** and repeats nothing.
     - A delivery racing one in flight answers **409**, so the provider comes back later. Two never process
       together.
     - A failed event, or one left in `received` for over two minutes (a crashed attempt), is taken over by a
       compare-and-set on `attempts`.
     - **Replay:** the same signed body under a new event id is caught by its SHA-256 and stored as ignored.
  4. **Persist the receipt:** type, hash, the ids named, status, attempts and note. Never the body, which carries
     the payer's email and phone.
  5. **Update state** through the owning services:
     - payment events → `settleProviderPayment`, which reads the payment back from the provider and records it
       exactly as at checkout;
     - refund events → `settleRefund`, matched by the refund the platform asked for (our id in the refund's
       notes) and checked against its payment;
     - anything else is ignored.
  6. **Record who did it:** the provider, on the lifecycle log and the audit trail (SAAS-014).
  7. **Answer** 200, or **500** when processing failed (receipt `failed`, redacted note) so the provider
     retries.
- **Retries finish the work, exactly once** (`lib/checkout.ts`). Everything after the payment is recorded now
  runs on every attempt and is idempotent:
  - an applied plan change stays applied;
  - a renewal happens only while the paid period is still the next one (the renewal moves it past);
  - a failed renewal moves a subscription past due only while its invoice is still unpaid, so an old failure
    redelivered after payment moves nothing;
  - the checkout order settles only from `created`.

  A crash between recording the payment and moving the subscription is completed by the next delivery.
- **Schema:** `WebhookEvent` (platform model), migration `20260922210000_webhook_events`.
  - CHECKs on status, event-id length, hash length and attempts.
  - `WebhookEvent_receipt`: what arrived is fixed, processed/ignored is final, and attempts only grow.
  - `WebhookEvent_no_delete`.
- **Super Admin:** `GET /superadmin/webhooks?status`: receipts with status, attempts, note and ids, never a body.
- **Tests:** the fake provider moved to `src/test/fakeProvider.ts`. Its webhook verification and parsing are the
  real Razorpay code under a test secret.
- **Docs:** `docs/00`, `03`, `05` (the endpoint and its answers), `09` and `10` (Razorpay dashboard set-up: URL,
  secret, events).

**Policy decisions**

- **Even a signed webhook is not the account of the payment.** Its payment id is read back from the provider
  before anything is recorded, the same as a checkout confirmation. Webhook and browser therefore reach one
  function, and either order changes state once (tested).
- **Refunds are matched by our own id** (`notes.refundId`, set when the refund was asked for) and checked
  against the payment the provider names. A refund the platform never asked for is ignored.
- **State changes stay in the owning services' transactions:** payment and invoice together, and each
  subscription move with its lifecycle event. They are made safe across transactions by idempotency, not
  by one wide transaction around a provider call. A network round trip inside a database transaction would
  hold SQLite's write lock for its whole length.
- **`RAZORPAY_WEBHOOK_SECRET` is still empty**, so on this machine every webhook is refused (verified live). You
  choose the value when adding the webhook in the dashboard (`docs/10`). Production will not start without
  it.

**doneWhen evidence** (`routes/webhooks.test.ts`, 15 tests, through the real route, with raw bodies signed as
Razorpay signs them)

1. **A forged or unsigned webhook is rejected.** These each get 401 with no receipt stored, and nothing changes:
   - no signature;
   - a signature under the wrong secret;
   - a body altered after signing (payment id swapped).

   Another provider gets 404. Signed non-events get 400. Live against `dev.db` with the real configuration: a
   forged delivery gets 401, with a `webhook.failed` signal in the log and 0 receipts stored.
2. **The same providerEventId delivered twice causes exactly one state change.**
   - Redelivery: 200 `duplicate`, with 1 payment, 1 `change_plan` and 1 receipt.
   - Three simultaneous deliveries: one 200, two 409, then a later redelivery answers `duplicate`. Still 1
     payment and 1 change.
   - A webhook plus the browser's confirmation for the same payment: one change.
3. **Webhook state updates are transactional.**
   - Provider unreachable: 500, the receipt `failed` (attempt 1), no payment. The retry gives 200 `processed`
     (attempt 2) with exactly one change.
   - A move interrupted after the payment and invoice were committed together is finished by the next
     delivery, without a second payment.
   - A crashed receipt left in `received` is taken over.
   - The receipt's fields are refused an edit, a finished event cannot reopen, and deletes are refused.
4. **Forged-webhook, duplicate-webhook and replay tests pass.**
   - Forged and duplicate: as above.
   - Replay: the same body under a new event id is stored as ignored ("A replay of event …"), with no second
     change.
   - A failed-payment webhook redelivered after the academy paid does not undo the recovery.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 536/536, web 211/211, domain 119/119 |
  | `npm test -w @syniastrolms/api` | 536/536 |

- `dev.db`: backed up first (outside the repo), then migrated. Schema diff empty; `tenants:verify` clean. The API
  started on it: webhook 401 and 404 as above, and `checkoutAvailable` true with the real Razorpay configuration.
- Regression: every existing Super Admin, admin, instructor and student test passes. The checkout suite (14) is
  unchanged in behaviour after the idempotency rework.

**Known limitations**

- **Not yet exercised against events from Razorpay itself.** That needs the webhook secret and a publicly
  reachable URL (the deployed API).
- **No auto-retry of a missed webhook** beyond the provider's own retries: webhook-retry is SAAS-012's job.

**Files**

New:
- **API:** `src/lib/webhooks.ts`, `src/routes/{webhooks,webhooks.test}.ts`, `src/test/fakeProvider.ts`, the migration

Changed:
- **API:** `prisma/schema.prisma`, `src/app.ts`, `src/lib/{checkout,paymentProvider,razorpay,tenancy}.ts`, `src/routes/{billingPlatform,checkout.test}.ts`
- **Docs:** `docs/00`, `03`, `05`, `09`, `10`

### SAAS-012 — Background Jobs
Started and completed 22 Sep 2026 (claim `d818178`, committed before any code). Spec: subscriptions.md §30, with
§7, §8, §44 and D9–D10 for what the jobs decide.

**What was built** (`lib/billingJobs.ts`, wired into `lib/scheduler.ts`)

- **On the existing scheduler.** The every-minute tick in `index.ts` now runs `runNotificationSchedule` (the
  F10–F12 jobs, unchanged) and then `runBillingSchedule`:
  - `forEachTenant(runAcademyBillingJobs, 'billing')`: each academy's jobs inside its own context, with
    `watchJob` per academy;
  - then `webhook-retry` once for the platform.

  There is no new mechanism.
- **The jobs**, in tick order, so none leaves work for one that already ran. Every change is made as `system`
  naming the job:
  1. `trial-expiry-check`: trials whose end has passed → `expireTrial`.
  2. `pause-expiry`: pauses whose planned end has come → `resumeSubscription`, which moves the renewal by the
     time paused (D9).
  3. `scheduled-cancellation`: cancelling subscriptions whose period has ended → `endCancelledPeriod`.
  4. `invoice-generation`: active or trialing subscriptions (not cancelling) within
     `SUBSCRIPTION_INVOICE_LEAD_DAYS` (default 7) of the boundary → one renewal invoice for the next period,
     at the next period's price.
     - An open invoice whose price no longer matches is voided (`supersedeRenewalInvoice`, system) and
       reissued; one with any live payment never is.
     - An academy with no billing address is skipped.
  5. `subscription-renewal-check`: active subscriptions at or past their boundary.
     - A scheduled downgrade applies first (D10).
     - Then, if the next period's invoice is paid → `recordPaymentSucceeded`; if not → `recordPaymentFailed`
       with the invoice number as the reason (§44). Access continues (§8).
  6. `past-due-retry`: first asks the provider for the payments on the open invoices' checkout orders
     (`listOrderPayments`, new on the interface and in the adapter) and settles any made but never
     confirmed, which recovers the subscription. Then, after `SUBSCRIPTION_RETRY_DAYS` without payment →
     `startGracePeriod`.
  7. `grace-period-expiry`: a grace period that has ended → `expireGrace`.
  8. `usage-reconciliation`: usage is live (SAAS-011), so this only reports each limit an academy is over as a
     `limit.reached` signal, and writes nothing.
  9. `webhook-retry` (platform): failed receipts, or ones left `received` over two minutes, fewer than 10
     attempts → rebuilt from the kept ids and dispatched again (`retryFailedWebhooks`), each taken by
     compare-and-set.
- **Renewal pricing fixed (D10).** `nextPeriodTerms(sub)` returns a scheduled downgrade's plan version, cycle
  and price when it takes effect at this boundary. `payableForRenewal` and the renewal invoice's description
  and period now use it; before, a renewal after a scheduled downgrade was invoiced at the old price.
- **Early renewal with a pending downgrade.** Paying the renewal invoice before the boundary no longer renews
  on the old plan and strands the downgrade: the paid invoice waits, and `subscription-renewal-check` renews
  at the boundary, after the change applies.
- **Configuration** (`lib/billingConfig.ts`):
  - `SUBSCRIPTION_RETRY_DAYS` (1–30, no default, like the grace period: unset means retries never run out);
  - `SUBSCRIPTION_INVOICE_LEAD_DAYS` (0–30, default 7: it moves no money);
  - `graceConfigured()`.

  Documented in `.env.example` and `docs/10`.
- **Docs:** `docs/00`, `06` (billing over time, the rules the jobs apply) and `10` (the jobs and their order,
  the two variables, and running a single scheduler).

**Policy decisions**

- **Collection is checkout-based, so "retry" means finding a payment, not charging again.** There is no stored
  mandate to charge (SAAS-009's decision), so past-due-retry reconciles with the provider. If the academy
  never pays, the retry window runs out and grace starts. Auto-debit, if chosen at rollout, would add the
  charge here.
- **No default retry window,** as SAAS-005 decided for the grace period: a failed payment does not lead to
  losing access unless the platform sets the rule (§8).
- **The job order is part of idempotency.** A tick straight after a tick finds nothing to do (tested across
  two academies and the whole book).

**doneWhen evidence**

1. **Running each job twice in a row changes nothing the second time.** `lib/billingJobs.test.ts` (15 tests) runs
   every job through a `twice` helper. The second run must report `changed: 0`, and a snapshot of the academy
   must be identical: subscriptions, lifecycle event count, invoices, payments, plan changes, and the
   system audit entries naming the academy. Covered:
   - trial expiry (and not a second early);
   - invoice issue (1 invoice; the lead time is honoured; no billing address → skipped);
   - price-changed replacement (void, then a new one at ₹1,000, once);
   - boundary unpaid → past due;
   - boundary with an early payment and a downgrade → change, then renewal on the new plan to 1 Nov;
   - past-due recovery by a payment found at the provider;
   - grace start at exactly the retry window, and nothing forced while unconfigured;
   - grace expiry, scheduled cancellation, pause expiry (renewal to 6 Oct);
   - usage report (two `limit.reached` signals, no change);
   - webhook retry (the invoice paid, 1 payment, 0 on the second run).

   At the scheduler level: one `runBillingSchedule` tick processes two academies, and a second tick has
   `changed: 0` everywhere with identical snapshots.
2. **Job failures are observable.** A provider failing during past-due-retry gives `failed: 1`, and a
   `job.failed` signal naming the job, academy and subscription, with the secret quoted in the error redacted.
   The other subscriptions carry on. The existing per-academy `watchJob` (SAAS-014) wraps each academy's run,
   and webhook-retry failures emit `webhook.failed`.
3. **The scheduler is the existing one, not a new mechanism.** The tick is still `index.ts` →
   `runScheduledJobs`, and the billing jobs go through the same `forEachTenant`. The tenancy test asserts both
   schedules use `forEachTenant`.

**Verification**

- `npm run typecheck`, `npm run lint`, `npm run build` and `npm run format:check` all pass.
- Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 551/551, web 211/211, domain 119/119 |
  | `npm test -w @syniastrolms/api` | 551/551 |

- `dev.db`: backed up first. `runBillingSchedule` ran twice on it: 1 academy, 8 jobs each, 0 changed and
  0 failed on both ticks, webhook-retry 0, and no error signals. It has no subscriptions, so this is correct.
  `tenants:verify` clean. No migration in this module.
- Regression: every existing Super Admin, admin, instructor and student test passes, including the
  notification scheduler's.

**Known limitations**

- **No per-job schedule:** every job runs every minute. They are cheap indexed queries per academy; SAAS-016
  should revisit this if the book grows large.
- **Single instance only:** the scheduler must run on one instance (documented); idempotency makes an overlap
  harmless but wasteful.

**Files**

New:
- **API:** `src/lib/billingJobs{,.test}.ts`

Changed:
- **API:** `.env.example`, `src/lib/{billing,billingConfig,checkout,invoices,paymentProvider,razorpay,scheduler,subscriptions,webhooks}.ts`, `src/test/fakeProvider.ts`, `src/routes/tenancy.test.ts`
- **Docs:** `docs/00`, `06`, `10`

### SAAS-009 — extension: an academy's self-service first purchase
23 Sep 2026, at the product owner's request ("reopen/extend SAAS-009 and the necessary SAAS-015 frontend
integration; do not create a new module"). This closes the gap found on review: an academy with no live
subscription could see the plans but not buy one. `createSubscription` refused academy users ("through
checkout"), but no checkout for a first subscription existed, and a paid invoice with no subscription attached
moved nothing.

**The flow.** Academy admin → `/admin/billing`, with no live subscription → plans on sale → *Choose monthly /
annual* → `POST /tenant/billing/purchase { planId, cycle }`. Then:
1. The server checks the academy has no live subscription (`INVALID_SUBSCRIPTION_STATE`), a billing address
   exists, and the plan is on sale on that cycle (`PLAN_UNAVAILABLE`, via `planForNewSubscription`).
2. It prices the plan's current version with its tax (`payableForNewSubscription`, SAAS-007) and issues one
   first-purchase invoice (`issueInvoice`, SAAS-008) recording that `planVersionId` and `billingCycle`.
   - The same choice again reuses the invoice and its checkout.
   - Another choice voids the unpaid one (`supersedeUnpaidInvoice`, as `system`) and issues a new one, unless a
     payment on it is under way.
3. The ordinary checkout runs (`startCheckout`): a Razorpay order for the invoice's total.
4. The browser's result goes to `/tenant/billing/checkout/confirm` (signature, then the payment read from
   Razorpay), or the webhook arrives. Both go through `settleProviderPayment` → `recordPayment` (idempotent)
   → the invoice settles.
5. `activateFirstPurchase` calls `createSubscription(provider, { fromInvoice })`, the SAAS-004 lifecycle's own
   creation. That keeps the one-live-subscription check and index, the `create` lifecycle event, the audit
   entries and the entitlement change.
   - The subscription starts **active** on the invoice's plan version, cycle and that version's price, even if
     the plan was repriced in between.
   - It records `sourceInvoiceId`.
   - Features and limits follow at once. Enforcement stays behind `ENTITLEMENT_ENFORCEMENT`, unchanged.

**The guards**
- **Database** (migration `20260923090000_first_purchase`, columns added in place so every trigger stays):
  - `Invoice_sale_on_insert`: a first-purchase invoice names a real version and a cycle; no other invoice does.
  - `Invoice_sale_fixed`: what an invoice sold never changes.
  - `Invoice_one_open_first_purchase`: one open first purchase per academy.
  - Unique `Subscription.sourceInvoiceId`: one subscription per invoice.
  - `Subscription_from_invoice`: a purchased subscription only from a **paid** first-purchase invoice of its own
    academy, exactly as sold, starting active.
  - `Subscription_source_fixed`.
- **Idempotency:** a second confirmation, a webhook, a redelivered webhook, or the browser and webhook at once
  give one payment, one settlement and one subscription. The unique index settles the race, and the loser
  finds the subscription.
- **No activation from anything but a verified, exact payment:** failed, pending, short and excess payments
  settle nothing (`payment.unmatched` is emitted for wrong amounts), and the invoice stays open to pay again.
- **No second live subscription:** if the platform started one while the payment was under way, none is added.
  The payment stays recorded against the paid invoice, `payment.unmatched` is emitted, and the platform
  refunds or applies it.
- **The client sends only `planId` and `cycle`:** price, tax, total, status, entitlements and `tenantId` in
  the body are ignored (tested). The academy is the signed-in account's.
- **Permissions stay separate from entitlements:** the route needs `settings.edit` (admins only), and payment
  needs a configured provider (`PAYMENT_REQUIRED`).
- **Unchanged:** trials (a trial is live, and converts through its own invoice; self-service starts no trial),
  upgrade and downgrade, renewals, jobs and webhooks.

**Web**
- `lib/billingActions.ts`:
  - `planActionMode` decides whether the plan list offers `purchase` (no live subscription, checkout on, may
    change billing), `change` (live, nothing waiting) or `none`;
  - `describeCheckoutOutcome` words success, already-recorded, failure and pending.
- The billing page shows *Choose monthly / annual* only in purchase mode. It confirms with "Continue to
  payment", then runs the same checkout as invoices and upgrades.
- `TenantBillingService.startFirstPurchase` has an HTTP implementation and a mock (the demo takes no payment).

**Evidence**
- `routes/firstPurchase.test.ts`: 15 tests over HTTP, covering all 13 cases asked for:
  - server price ₹2,000 + 23% = ₹2,460, whatever the body said;
  - invoice exactly once (reuse, and replacement with one open);
  - the checkout order for the invoice;
  - activation only on the verified payment, on the paid-for version after a reprice, and by the webhook alone;
  - duplicates, including concurrent ones;
  - failed, pending, short and excess payments;
  - an existing live or trial subscription refused, and a platform subscription started meanwhile winning;
  - an ended subscription buying again;
  - cross-tenant refusal, permissions, no provider, and the database guards.
- `web/src/lib/billingActions.test.ts` (7) and the HTTP contract test: the request carries only
  `{ planId, cycle }`.
- **Live**, on a production-mode API against Razorpay's test API with a real test-card payment, 9/9:
  - no subscription → a real order for ₹4,718.82 (₹3,999 + 18% GST) → nothing active before payment;
  - a real payment, verified, starts it active on the plan with its features and limits;
  - a second confirmation and the webhook change nothing;
  - a second purchase is refused;
  - the logs are clean.
- **Migration:**
  - `dev.db` was backed up and migrated: 649 rows before and after, tenancy clean, schema diff empty.
  - All 24 migrations apply from empty with no drift.
  - Note: `dev.db` had changed through the running app since SAAS-012 (not by this work): 14 audit entries,
    one admin's permissions (48 → 36), a plan created with its version, features and limits, a lesson
    progress and a quiz attempt.
- **Existing tests adjusted:**
  - one SAAS-008 raw-insert test, which checks duplicate invoice numbers, now inserts a `renewal` duplicate, so
    the number is the only rule broken; the new trigger refused the old `new_subscription` row first;
  - the admins-list test now reads every page, since the test database holds more than 100 admins.
- **Verification:** typecheck, lint, build and format all pass. Tests:

  | Suite | Result |
  | --- | --- |
  | `npm test` | API 575/575, web 218/218, domain 119/119 |
  | `npm test -w @syniastrolms/api` | 575/575 |

**Files**
- **API:**
  - `prisma/schema.prisma`, `prisma/migrations/20260923090000_first_purchase/`
  - `src/lib/{billing,billingJobs,billingViews,checkout,invoices,subscriptions}.ts`
  - `src/routes/tenant.ts`, `src/routes/firstPurchase.test.ts`
  - `src/lib/invoicesPayments.test.ts`, `src/routes/superadmin.test.ts`
- **Web:**
  - `src/lib/billingActions{,.test}.ts`
  - `src/services/{contracts.ts,http/tenantBilling.ts,http/subscriptions.test.ts,mock/tenantBilling.ts}`
  - `src/pages/billing/AcademyBillingPage.tsx`
- **Docs:** `docs/00`, `03`, `05`, `06`, `07`

**Remaining blocker:** unchanged, SAAS-016. Real Razorpay webhooks to a deployed server need the deployment
and the webhook secret. First purchase works without webhooks (verified confirmation) and with them (tested).

### SAAS-018 — Learner Assessment Integrity (completed 23 Sep 2026)

Phase E (SAAS-018 to SAAS-024) was added on 23 Sep 2026 from the backend audit after the QA pass: the gaps the
original list never covered. None depends on the blocked SAAS-016 or SAAS-017. It is backend work; `apps/mobile`
is being built by a concurrent session and is not touched.

**What was wrong.** `GET /learning/courses/:courseId/lessons/:lessonId` sent every question with its `correct`,
`acceptedAnswers` and `explanation`, so a learner could read the answers before attempting (confirmed live, and
recorded by the Flutter plan §28.4). The web quiz scored attempts in the browser from that key. Two more defects
surfaced on the way: a hand-in's files were never checked (any id, any name, any size was stored) and the web
discarded the uploaded file's id, storing a made-up `f-<time>` one so a reviewer could never open it; and the quiz
builder's "Nothing yet" results option sent `hidden`, which the API's schema (`nothing`) refused with 400.

**Built.**
- `packages/domain/src/quiz.ts`: `LearnerQuizQuestion` / `LearnerQuiz` and `learnerQuestion()` — the answerable
  fields picked by name, so a field added later is withheld by default; `AttemptReview` and `reviewAttempt()`,
  which cut an attempt to `showResults`; `resultsVisibilityOf()` reading `hidden` and the older `nothing` alike.
- `packages/domain/src/assignment.ts`: `countWords`, `MAX_SUBMISSION_FILES` (3) and `validateSubmission()`.
- `apps/api/src/routes/learning.ts`: the lesson player sends the learner-safe quiz; new
  `GET …/lessons/:lessonId/quiz-attempts` (own attempts, newest first, each an `AttemptReview`); submit enforces
  format and word limit; draft and submit resolve every file against the learner's own document/image uploads and
  store the stored file's name and size (409 otherwise).
- `apps/api/src/routes/quizzes.ts`: `showResults` accepts `hidden` (and `nothing`), stored as `hidden`.
- Web, changed only where the backend contract required it: `QuizTaker` renders an `AttemptReview` — the server's
  for a learner, one computed locally by the same `reviewAttempt` for an author's preview (which holds the key);
  instant "Check answer" needs the key and so exists only in the author preview. `LessonPlayerPage` submits answers
  only and shows the server's review. `AssignmentWork` submits the uploaded file's real id. The contracts, HTTP
  and mock services follow (`recordQuizAttempt(courseId, lessonId, answers, durationSec)`, `listQuizAttempts`).
- `docs/05-API-SPECIFICATION.md` updated.

**Contract for other clients (Flutter).** The lesson view's `quiz` is already what the Flutter plan modelled
(`LearnerQuiz`, §28 item 12). `POST …/quiz-attempt` is unchanged in shape (`null` / `CompletionResult`).
Per-question results (Flutter B7) are now available from `GET …/quiz-attempts`. A hand-in's files must be ids
returned by `POST /media/upload`.

**Policy decisions.**
- `showResults`: `score-and-answers` reveals the correct answers after each attempt (the author's choice, as the
  web did before); `score-only` gives the score only; `hidden` says only that the attempt was received and
  whether it passed — which completion reveals anyway.
- Word limits apply to written and chart work; a file hand-in's note is not limited.
- **Quiz time limit — needs a product decision, not built.** The lesson endpoint delivers the questions when the
  lesson opens, before the learner presses Start. A server timer from delivery would either penalise a learner
  who only opened the lesson or be reset by reopening it; real enforcement needs an "exam mode" — questions sent
  only by an explicit start call, and a rule for abandoned attempts (counted as failed, or not). Both change the
  client contract and the learner-facing rules, so they are for the product owner to decide. `durationSec`
  remains client-reported and is used for reporting only.

**doneWhen, with evidence.**
- No learner response carries the key before an attempt — `assessmentIntegrity.test.ts` › "walks every learner
  surface" (home, courses, course, every lesson of the course, assessments, assignments, attempts, public
  catalogue list and detail) with an explanation added to every question so a leak would show; live probe
  before the fix found `correct` and `acceptedAnswers` on the lesson player, after the fix none; browser run: no
  `/learning` response carried a key field.
- Reviews cut to `showResults` — the three "an attempt is reviewed only as the quiz allows" tests (including
  `nothing`), domain `assessmentIntegrity.test.ts`; another learner sees no attempts; not enrolled → 403.
- Assignment format, word limit and file ownership — "a hand-in fits its assignment" (51 words over a 50 limit
  refused; files on a written assignment and a missing chart refused; another learner's upload, a made-up id and
  a file without an id refused on draft and submit; own upload accepted with the stored name and size).
- Staff still get the full quiz — "keeps the full quiz for staff".
- Time limit — recorded above as a product decision, not claimed.
- Browser (real API, qa.db): a learner passes a quiz through the UI and sees the server's review (100%, three
  correct answers), zero console errors; a learner uploads a PDF to a file assignment and the stored submission
  names the learner's own media row; the author's quiz preview still scores locally.

**Tests changed, and why.** `learning.test.ts`, `quizzes.test.ts` and `certificates.test.ts` read the answer key
from the learner's lesson response to pass quizzes — they depended on the vulnerability. They now read it from
the quiz row, as its author knows it. `learning.test.ts`'s hand-in test now picks a written assignment, because
it submitted text to whichever assignment came first.

**Verification.** typecheck ✓ · lint ✓ · `npm test` ✓ (API 619, web 258, domain 127) · build ✓ ·
format:check — clean for every tracked file; it reports 9 files in the untracked `apps/lms-react/` work in
progress, which is not this workflow's. One full-suite run hit the known supertest port-collision flake
(`Expected HTTP/`, `src/test/setup.ts`); the file passed 3/3 alone and the full API suite passed on rerun.

### SAAS-019 — Academy Lifecycle & Provisioning (completed 23 Sep 2026)

**What was missing.** Academies existed only through the tenancy migration and test fixtures. No endpoint created,
updated, suspended or archived one; `Tenant.status` was set and enforced nowhere; and an academy created by hand had
no levels, ranks, settings or certificate template — no course could be created in it, and nothing in the app can
create levels or ranks.

**Built.**
- Migration `20260923180000_academy_lifecycle` (additive): `Tenant.statusReason`, `Tenant.statusChangedAt`.
- `packages/domain/src/academy.ts`: `AcademyStatus`, `academyTransition()`, `validateAcademySlug()` (3–40 chars,
  lowercase words and single hyphens, reserved names refused), `academySlugFrom()`, `ACADEMY_CLOSED_MESSAGE`.
- `apps/api/src/lib/academies.ts`: `provisionAcademy()` — one transaction creating the tenant; its first admin with
  the permission catalogue, recorded as owner; three starter levels; three starter ranks; a default certificate
  template signed by the admin; settings named after the academy (support/reply-to address = the admin's, default
  template set); and the `academy.created` audit entry. Plus `getAcademy`, `listAcademies`, `updateAcademy`,
  `changeAcademyStatus`.
- `apps/api/src/routes/superadminAcademies.ts`, mounted at `/superadmin/tenants` (replacing the read-only list,
  whose fields it keeps): list with search/status/paging, create, read, update, suspend, reactivate, archive, and
  the academy's users, subscription and usage.
- Enforcement: `lib/requestContext.ts` reads the academy's status with the account on every request and refuses a
  member of a suspended or archived academy (403 `ACADEMY_SUSPENDED` / `ACADEMY_ARCHIVED`); `POST /auth/login`
  refuses them after the password check; `forEachTenant` walks active academies only for notifications, active and
  suspended for billing. New error codes added to `ErrorCode` and `BILLING_ERROR_CODES`.
- `lib/settings.ts`: `newSettingsRow()` shared by provisioning and the lazy first read.
- Docs: `docs/05` (academy endpoints), `docs/04` (closed accounts and closed academies), `docs/03` (Tenant columns).

**Policy decisions.**
- Transitions: active → suspended; active or suspended → archived; suspended or archived → active. A reason is
  required to suspend or archive and is audited; reactivating clears it.
- The academy `DEFAULT_TENANT_SLUG` names serves the public site: it cannot be suspended or archived, and keeps its
  slug.
- Archiving is closing: it is refused while a subscription is live — the billing contract is ended first,
  deliberately, through the billing flows. Suspension does not touch billing: a suspended academy's subscription
  keeps renewing and dunning unless the platform pauses or cancels it.
- Provisioning starts no subscription. An academy begins without a plan (restricted when enforcement is on) and
  subscribes through a Super Admin trial or its own first purchase — each with its own transaction.
- Starter levels (Beginner / Intermediate / Advanced) and ranks (I–III, 0/2/4 completed courses) are the product's
  structural ladders, defined once in `lib/academies.ts`; demo content (categories, courses, people) is not copied.
- Deactivation keeps every row: suspended and archived academies lose access, never data.

**doneWhen, with evidence** (`routes/academies.test.ts`, 12 tests, and a live run against the QA server).
- Atomic provisioning — "rolls everything back when a step fails part-way": a failure injected after the tenant,
  admin, levels, ranks and template are written leaves no tenant, no user and no audit entry, and the same request
  then succeeds.
- A provisioned academy works at once — "lets the new admin sign in and build a course straight away": sign-in with
  24 permissions, category and course created in the new academy, nothing of Tenant #1 visible; live: TEST_TENANT_C
  provisioned, its admin read its categories.
- View, update, suspend, reactivate, archive, users, subscription, usage — "reading and updating academies" (3
  tests) and the lifecycle tests; 404 for an unknown academy on every read.
- Enforced with stable codes, data kept — "closes a suspended academy to all its members at once": the same token is
  refused on `/auth/me`, `/courses`, `/categories`, `/settings`, `/tenant/billing`, `/catalog/courses`,
  `/notifications` and a write, all `ACADEMY_SUSPENDED`; sign-in refused with the code, a wrong password still 401;
  Tenant #1 unaffected; the category and account still there; archived → `ACADEMY_ARCHIVED`. Live: suspend →
  `ACADEMY_SUSPENDED` on a route and at sign-in, Tenant #1 still 200, reactivate → 200.
- Audited; slugs validated and unique; default academy protected — audit sequence `academy.created →
  academy.suspended → academy.reactivated`, `academy.updated` on rename; invalid/reserved slug 400, taken slug and
  email 409; default academy suspend/archive/slug change 409.
- Existing tests unchanged — tenancy, billing and Super Admin suites pass; `verify-tenancy` passes on the QA
  database with the provisioned academy.

**Verification.** typecheck ✓ · lint ✓ · `npm test` ✓ (API 631, web 258, domain 131) · build ✓ · format:check
clean for tracked files (the 9 warnings are the untracked `apps/lms-react/`). `prisma validate` ✓ and
`migrate diff` from the migrations to the schema: no difference.

**Known limitations.** No web screen for academy management yet: this is backend work, the web client is not
this session's to extend beyond contract changes, and the Super Admin screens in `apps/web` do not list academies.
Existing databases need `prisma migrate deploy` for the two new columns (additive; the deploy script already runs it).

### SAAS-020 — Sessions: Logout, Revocation & Account Self-Service (completed 23 Sep 2026)

**What was missing** (Flutter B1, B3; docs/11 §24). No logout endpoint and no way to revoke a token: a copied token
worked for up to 7 days whatever its owner did. A signed-in account could not change its password or its name.

**Built.**
- Migration `20260923200000_user_sessions` (additive): `UserSession` (academy-or-platform model, indexed on user,
  academy and expiry) and `User.tokensValidAfter`.
- `apps/api/src/lib/sessions.ts`: `startSession` (row + token with `sid`), `revokeSession`, `revokeAllSessions`
  (also sets `tokensValidAfter`), `openSessions`, `pruneSessions` (30 days after expiry), `sessionStands`.
- `lib/requestContext.ts`: the per-request account read also reads the token's session in the same query; an ended
  session is no session (401 everywhere). Tokens without `sid` pass unless `tokensValidAfter` is later than their
  issue second.
- `routes/auth.ts`: login and register start sessions; `POST /auth/logout`, `POST /auth/logout-all`,
  `GET /auth/sessions`, `DELETE /auth/sessions/:id`, `POST /auth/change-password`, `PATCH /auth/me`; a password
  reset ends every session.
- Scheduler: `session-prune` each tick (idempotent, indexed).
- Docs: `docs/05` (auth table and a sessions note), `docs/04`, README known limitations.

**Fixed on the way — two real concurrency bugs** (surfaced when the test harness began sending simultaneous
requests truly at once, see below; both deterministic under load, 5/5):
- `withinLimit` took the academy's guard with Prisma `upsert`, which on SQLite reads before inserting: two first
  requests for an academy and limit could both insert, and one failed with a unique-key 409 instead of being
  counted. The row is now ensured before the transaction (a concurrent creator's unique-key refusal is accepted as
  "it exists") and taken inside it with an `update`.
- `loadRecord` (settings) created an academy's settings row on first read: two first reads raced and one answered
  409. It now reads the winner's row on a unique-key conflict.

**Test harness.** `src/test/setup.ts` now binds each test server to 127.0.0.1 itself, so the operating system hands
out only ports nobody holds there, and sends the request once listening. The previous mitigation (bind every
interface, connect over ::1) still collided with programs holding ::1 ports — the concurrent Flutter session's Dart
VM services — and failed a random test with `Expected HTTP/` in two consecutive full runs.

**Policy decisions.**
- Tokens issued before this change stay valid until they expire (web and mobile keep their sessions); logout-all,
  a password change and a reset end them through `tokensValidAfter`.
- Logout is allowed to a closed account (it only ends its own session); every other new endpoint uses
  `requireAuth`.
- Changing the password needs the current one, ends every session including the caller's, and returns a fresh
  token for this device.
- Deactivation, instructor inactivity and suspension do not end sessions: the account is refused on every request
  while closed, and reopening it lets the same token work again — the existing contract (hardening tests).
- The profile endpoint changes the name only; an instructor's public profile follows.
- No refresh tokens (B2): they change the client contract; the 7-day lifetime stands.

**doneWhen, with evidence** (`routes/sessions.test.ts`, 12 tests, plus a live run).
- Logout ends only the calling token; logout-all ends every session — "ends only this session on logout, on every
  route at once" (phone logged out, laptop still in; `/auth/me`, `/learning/home`, `/notifications` all 401);
  "ends every session, and every token from before sessions, on logout-all". Live: login → `/auth/me` 200 →
  logout `{revoked:1}` → `/auth/me` 401.
- Change/reset revoke other sessions; the current password is required — "needs the current password…" (wrong 403,
  weak 400, same 409; both old tokens 401, fresh token 200, old password refused) and "ends every session when the
  password is reset".
- Profile update is name only — "changes the display name only" (email, role, tenantId in the body ignored) and
  "keeps an instructor's public profile in step".
- A revoked session is 401 everywhere; a made-up `sid` is 401 — "refuses a token naming a session that does not
  exist"; per-session revoke is owner-only (another account's id → 404).
- Pre-existing tokens still work — "keeps a token from before sessions working until something ends it".
- Rate limits — "the new account endpoints sit behind the sign-in rate limit" (third attempt 429).
- Browser: the full route crawl signed in all five roles with session tokens — only the expected cross-tenant 404s.

**Tests changed, and why.** `adminPermissions.test.ts` pins the exact token claims: `sid` is added (no permission
is a claim, which is what it guards). `tenancy.test.ts` pins the academy-scoped model count and the audited table
count: 43 → 44 for `UserSession`.

**Verification.** typecheck ✓ · lint ✓ · `npm test` ✓ (API 643, web 258, domain 131) and a second clean API run ·
build ✓ · format:check clean for tracked files · `prisma validate` ✓, migrations match the schema.

### SAAS-021 — Notification Delivery: Email Worker, Device Tokens & Push (completed 23 Sep 2026)

**What was missing.** Email was written to `EmailOutbox` and nothing ever delivered, retried or finished it; the
same message could be queued twice; quiet hours were stored and applied nowhere; there was no device registration
and no push transport (Flutter B4).

**Built.**
- Migration `20260923220000_notification_delivery` (additive; `ALTER TABLE ADD COLUMN` rather than the table
  rebuild Prisma proposed, so no outbox row is copied or dropped): `EmailOutbox.attempts/nextAttemptAt/
  lastAttemptAt/dedupKey/providerMessageId`; `DeviceToken`; `PushDelivery` (one per notification).
- `packages/domain/src/notification.ts`: `quietHoursEnd()` (IST, across midnight), `DELIVERY_BACKOFF_MIN`
  (1, 5, 30, 120, 720 minutes) and `nextDeliveryAttempt()`.
- `apps/api/src/lib/mail.ts`: `queueEmail` skips a message identical in address, subject and body queued in the
  last 10 minutes (hash in `dedupKey`).
- `apps/api/src/lib/mailDelivery.ts`: `MailTransport` (`outbox` stores only — the default, worker idle; `log` for
  development) and `deliverQueuedEmail`: claims each row with a conditional update, sends, records `sent` with the
  transport's reference or retries on the backoff and ends `failed` with a redacted reason after six attempts;
  reclaims rows left `sending` for 10 minutes; drains batch after batch within a 20-second tick budget.
- `apps/api/src/lib/push.ts`: `PushProvider`, `FcmProvider` (FCM HTTP v1 as Google documents it: an RS256
  service-account JWT for an OAuth token, cached; one data-only `messages:send` per device; `UNREGISTERED` /
  `INVALID_ARGUMENT` reported as a dead token), `queuePush` and `deliverQueuedPushes` with the same claim, backoff,
  stale-reclaim and budget as email.
- `notify()` queues a push for each in-app notification (never for digest-only), held to the end of quiet hours
  unless important. Devices: `POST/GET /notifications/devices`, `DELETE /notifications/devices/:id`. Sessions:
  logout removes that session's devices; logout-all and a password change remove them all.
- Scheduler: `email-delivery` and `push-delivery` each tick. Env: `PUSH_PROVIDER`, `FCM_SERVICE_ACCOUNT`
  (`apps/api/.env.example`, `deploy/api.env.example`, `docs/10`). `docs/05` documents devices and the payload.

**Policy decisions.**
- A push is a hint, never content: `{ notificationId, category }`, data-only. The app fetches the notification as
  the signed-in account, so a token that reaches the wrong device reveals nothing.
- Push follows the category's in-app channel, the pause, and quiet hours (IST, the product's clock); important
  notifications ignore quiet hours; a notification read before its push goes is skipped.
- A device token belongs to one account at a time — registering it again moves it (the device changed hands).
- Email dedup: same address + subject + body within 10 minutes. Password-reset and invitation links differ each
  time, so they are never merged.
- No mail dependency was added: `package-lock.json` carries the owner's uncommitted changes, and the provider
  (SMTP host or email API) is a product and credentials decision.

**doneWhen, with evidence** (`routes/notificationDelivery.test.ts`, 14 tests; domain `delivery.test.ts`, 3; live).
- Worker delivers with retries, backoff, final status and attempt count — "sends what is queued…", "retries a
  failure on the backoff, and gives up…" (1-minute first wait; not before it is due; `failed` after 6 attempts;
  the error never carries the reset link), "never sends one message twice when two workers run at once, and takes
  back one abandoned mid-send". Live on the QA server (`MAIL_TRANSPORT=log`, scheduler on): a forgot-password email
  was `sent` after one attempt within a tick and the whole outbox (32 messages) drained, no job errors.
- Dedup — "does not queue the same message to the same address twice within the window".
- Devices — "registers a device… without echoing the token", "moves a token… lets only the owner remove it",
  "refuses a malformed registration and an anonymous one", "removes a session's devices when it signs out, and
  every device on logout-all". Live: `POST /notifications/devices` → 201, `current: true`.
- Push respects preferences and quiet hours, records its outcome, carries only id and category — "sends only the
  notification's id and category, once", "respects the recipient's channel choice, and holds a push through quiet
  hours unless it is important", "removes a token the provider no longer accepts, retries a failure, and skips a
  notification already read"; FCM protocol — "the FCM provider speaks HTTP v1 as documented" (JWT verified with the
  public key; URL, bearer token and data-only body; access token reused; dead token reported).
- No provider → nothing queued, nothing sent — "queues and sends nothing without a provider"; the outbox untouched
  under the default transport — "leaves the outbox alone when the transport only stores".

**Blocked outside this module (credentials, not code):**
- **Real email delivery** needs a provider decision (SMTP host or an email API) and its credentials; the transport is
  one `MailTransport` implementation in `lib/mailDelivery.ts`.
- **A live FCM push** needs a Firebase project and its service account (Flutter plan C8). Set `PUSH_PROVIDER=fcm` and
  `FCM_SERVICE_ACCOUNT`; the provider is implemented and tested against the documented protocol only.

**Tests changed, and why.** `tenancy.test.ts`: academy-scoped model count and audited table count 44 → 46 for
`DeviceToken` and `PushDelivery`.

**Verification.** typecheck ✓ · lint ✓ · `npm test` ✓ (API 657, web 258, domain 134) · build ✓ · format:check clean
for tracked files · `prisma validate` ✓, migrations match the schema.

### SAAS-022 — Job Leases & Multi-Instance Safety (completed 23 Sep 2026)

**What was missing.** The in-process scheduler runs every minute in every API process. With two processes, every
job — notifications, billing, pruning, delivery — would run twice at the same moment.

**Built.**
- Migration `20260923230000_job_leases` (additive): `JobLease` (platform table: job, holder, acquiredAt, expiresAt,
  last run, outcome and holder).
- `apps/api/src/lib/jobLease.ts`: `acquireLease` (atomic — a create, else a conditional update that succeeds only
  when the lease is expired or already the caller's), `releaseLease` (holder only; records the outcome),
  `withLease`, `leaseStatus`; the holder is `host:pid:boot-id`; time-to-live 5 minutes.
- `lib/scheduler.ts`: `runScheduledJobs` runs each job (`scheduled-notifications`, `billing`, `session-prune`,
  `email-delivery`, `push-delivery`) under its own lease; a job another process holds is skipped this tick.
- `GET /superadmin/system` gains `jobs`: each lease, whether it is held, by whom, until when, and the last run's
  time, outcome and holder.
- Docs: `docs/10` (background jobs), `docs/11` (system endpoint).

**Policy decisions.** Time-to-live 5 minutes — longer than any job's 20-second delivery budget and the billing
walk; a lease that expires under a job that runs long only lets idempotent work repeat, never double. Leases are
per job, so two processes can share a tick's work.

**doneWhen, with evidence** (`lib/jobLease.test.ts`, 7 tests, and live runs).
- Never the same job at once — "goes to exactly one of several processes asking at once" (5 holders, 1 lease);
  "runs the job in one process while another finds it held" (peak concurrency 1). Live: three separate OS processes
  raced for one lease on the QA database — exactly one ran it.
- A dead holder's lease expires and is taken over — "is taken over once its holder has died and it has expired —
  not before".
- Visible in `GET /superadmin/system` — "shows every lease…" (all five jobs `ok`, this process as last holder).
  Live: the QA server's system page listed all five jobs with `lastOutcome: ok`.
- Existing job tests unchanged — `runBillingSchedule` and `runNotificationSchedule` are unwrapped; the tick skips a
  job held elsewhere and runs the rest ("skips a job another process holds").

**Verification.** typecheck ✓ · lint ✓ · `npm test` ✓ (API 664, web 258, domain 134) · build ✓ · format:check
clean for tracked files · migrations match the schema. SQLite remains a single database writer; the leases make
the scheduler safe to run in several processes, not the database multi-writer.

### SAAS-023 — Media Security (completed 23 Sep 2026)

**Audit findings.**
1. `GET /media/:id` let every signed-in account of the academy read anything staff uploaded, so a free-registered
   learner holding a paid course's video id could stream it. **Fixed.**
2. Any instructor could read any learner's hand-in, including for courses they do not teach. **Fixed.**
3. Uploads were accepted on the client's declared MIME type and extension: a renamed executable was stored as a
   "PDF". **Fixed** with a content-signature check.
4. `safeFileName` kept `"`, which could malform the `Content-Disposition` header (CR/LF were already stripped, so no
   header injection). **Fixed**, and the header now carries an RFC 5987 `filename*`.
5. Unchanged, and already correct: authentication on every media route; per-kind size limits; random storage names;
   no static serving of the upload directory; `nosniff` and `private` caching; tenant scoping (another academy's
   file is never found); learners cannot upload video; staff uploads count against storage. There is no delete or
   replace endpoint, so there is no delete authorization to get wrong.

**Built.**
- `apps/api/src/lib/mediaAccess.ts` — `canReadMedia`: the uploader; an admin; an instructor for staff material and
  for hand-ins (submissions or drafts) to assignments of courses they teach; a learner for staff material in a
  published lesson of a course they are enrolled in (not expired), a published free-preview lesson, or the
  attachments of a non-draft assignment of such a course. Grants are cached for 60 seconds (video streams as many
  range requests); refusals are not cached, so a learner who has just enrolled is never held to an earlier no.
- `apps/api/src/lib/media.ts` — `matchesSignature` (PDF, PNG, JPEG, WebP, MP4/MOV, WebM), `contentDisposition`,
  and a quote-free `safeFileName`. `routes/media.ts` checks the first 16 bytes after the size check and deletes a
  refused file at once.
- Docs: `docs/05` (media), `docs/09` (uploads and media reads).

**Policy decisions.** Files are placed in exactly three kinds of places (lesson content, assignment attachments,
hand-ins), so access follows those. Chapter gating is not applied to files: a learner enrolled in a course can open
the files of its published lessons, as the lesson list already tells them what exists. Losing enrolment ends access
within 60 seconds.

**doneWhen, with evidence.**
- Every media endpoint has authorization, validation and cross-tenant tests — `routes/mediaSecurity.test.ts` (6):
  signatures, a program renamed `.pdf` refused with nothing stored, a clean stored name and header, assignment
  attachments by enrolment and draft status, another academy's file 404 for admin, instructor and learner (401
  anonymous), and no delete/put/patch route; `routes/hardening.test.ts`: learner video 403, staff MP4 201, image
  bytes named `.mp4` 400, disallowed type 400, anonymous 401.
- A learner reads only material they may open, or their own uploads — "opens course material to the learners
  enrolled in its course — and a free preview to every learner" (not enrolled 404 → enrolled 200; preview 404 →
  200 once marked preview; a file placed nowhere is staff-only); "keeps one learner's hand-in away from another
  learner" (another learner 404; the instructor 404 until it is handed in to their course, then 200; an instructor
  of another course 404).
- Never served from a guessable public path — files stream only through the authenticated `GET /media/:id` from
  random storage names; `web.ts` statically serves the built web app only.

**Tests changed, and why.** `hardening.test.ts` › "leaves course material readable by every signed-in account"
asserted the old, too-open rule; it is replaced by the enrolment rule above. Its hand-in test now hands the file in
before the instructor may read it, and its staff-video upload uses real MP4 bytes (it used PNG bytes named `.mp4`,
which the signature check refuses — and the test now also asserts that refusal).

**Verification.** typecheck ✓ · lint ✓ · `npm test` ✓ (API 670, web 258, domain 134) · build ✓ · format:check
clean for tracked files.

### SAAS-024 — Backend Audit & Documentation (completed 23 Sep 2026)

**Endpoint audit.** `apps/api/src/routes/routeAudit.test.ts` walks every router the app mounts (237 routes) on
every run, so a route added later is audited without anyone listing it:
- every non-public route refuses an anonymous caller with 401. The 17 public routes are an explicit list;
- every staff, academy-admin and platform route refuses a learner before reading the body;
- every academy-admin and platform route refuses an instructor;
- every platform route refuses an academy admin (403);
- no GET route answers a malformed query string (arrays and objects where strings are expected) with a 5xx.

The per-route table (class, observed anonymous and learner status, covering test) is `docs/12-ENDPOINT-AUDIT.md`.

**Found and fixed.**
- Six list routes answered 500 to an array-shaped query parameter: `/help/articles` (public), `/assignments`,
  `/quizzes`, `/categories`, `/courses/:courseId/lessons` and `/instructors`. They read `req.query` through a type
  cast; they now parse it with Zod like every other route. The sweep caught the reverted `/categories` fix.
- 15 routes had no test of their own: duplicate chapter, lesson, quiz and assignment; lesson bookmark;
  notification restore and clear; the three Help Centre routes; tax-rule retire; a tenant's billing profile read
  and write. They are covered in `auditCoverage.test.ts`.
- The wrong-currency case of the billing matrix had no test: a payment of the invoice's total in another currency
  settles nothing and is flagged as unreconciled money (`auditObservability.test.ts`). The code was already correct.
- `learning.test.ts`'s hand-in test depended on another suite's leftover rows (from my SAAS-018 change); it now
  creates its own written assignment.

**Billing matrix.** Every scenario in the brief maps to named tests (`docs/12-ENDPOINT-AUDIT.md`): first
purchase, success, failure, duplicate webhook, wrong amount, wrong currency, renewal, failed renewal, retry,
grace, recovery, expiry, upgrade, downgrade, pause, cancel, refund, gateway switch, and a historical payment after
a switch.

**Database.**
- Every `tenantId` column is indexed.
- No cascade reaches into a financial table, and triggers keep plan versions, transitions, events and plan
  changes immutable.
- Integrity and foreign-key checks are clean, and `tenants:verify` is clean on `dev.db` (read-only) and the QA
  database.
- Phase E migrations are all additive and match the schema.
- The learner-progress upserts showed no conflict under 12 simultaneous first writes.

**Documentation.**
- New: `apps/api/README.md` (the backend's map) and `docs/12-ENDPOINT-AUDIT.md`.
- Updated: `docs/00-PROJECT-STATUS.md` (phase E rows) and `docs/10` (scheduler guidance for several instances).
- `docs/03`, `04`, `05`, `09`, `10` and `11` were updated by each module as it landed.
- The root `README.md` is updated but not committed, because it also holds the owner's own uncommitted edits.

**Verification.** `prisma validate` ✓ · typecheck ✓ · lint ✓ · `npm test` ✓ (API 684, web 258, domain 134) ·
build ✓ · format:check clean for tracked files (the 9 warnings are the untracked `apps/lms-react/`).

## Final audit — phase E (23 Sep 2026), against §53

| §53 item | State | Evidence |
| --- | --- | --- |
| Tenants isolated | ✓ | tenancy extension; `tenancy.test.ts`, `securityAudit.test.ts`, `mediaSecurity.test.ts`, QA pass (50+ cross-tenant probes); academy status enforced (SAAS-019) |
| Plans, subscriptions, invoices, payments database-backed | ✓ | SAAS-001, 004, 008 |
| Features and limits centrally defined, enforced server-side | ✓ | `packages/domain/src/entitlement.ts`; `requireFeature`, `withinLimit` (race fixed in SAAS-020) |
| Lifecycle, trials, cancellation enforced server-side | ✓ | named transitions and triggers; `subscriptions.test.ts`, `billingJobs.test.ts` |
| Upgrade and downgrade rules written down | ✓ | D7–D10 in Decisions |
| Provider reached only through the abstraction | ✓ | `PaymentProvider` + registry; Razorpay implemented; VyaparGateway **blocked** (SAAS-017) |
| Payment records immutable; invoices persisted | ✓ | SAAS-008; triggers |
| Webhooks verified and idempotent | ✓ | `webhooks.test.ts` |
| Tenant isolation, payment failure, duplicate webhook tests | ✓ | billing matrix in `docs/12` |
| Audit logging | ✓ | SAAS-014; academy lifecycle audited (SAAS-019) |
| Existing LMS regression tests pass | ✓ | full suite green |
| Super Admin platform access and Tenant Admin subscription access | ✓ | `routeAudit.test.ts`; `billingApi.test.ts` |
| Secrets protected | ✓ | encrypted gateway credentials; log sweep test; FCM service account env-only, never logged |
| Production deployment tested | ✗ **blocked** | SAAS-016: needs a staging server with the Razorpay webhook configured |

Also checked, as §10 asks: no money is handled as a float (integer paise throughout); nothing compares a plan's
name (lint rule); no endpoint bypasses the entitlement service; every tenant column is indexed; there are no
destructive cascades; no secrets are logged; no TODOs are left in the phase E code; the browser console was clean
on every screen touched.

**Beyond §53, recorded for the owner:**
- Quiz time limits need an exam-mode product decision (SAAS-018).
- Real email delivery needs a provider and credentials (SAAS-021).
- A live FCM push needs a Firebase service account (SAAS-021).
- Refresh tokens are not implemented; tokens last 7 days (SAAS-020).

### SAAS-025 — Entitlement Enforcement Readiness & Enablement (completed 23 Sep 2026)

**Why.** The access-control audit found layers 1–3 (authentication, tenant, permission) always enforced, and
layers 4–6 (subscription, entitlement, usage) coded but off (`ENTITLEMENT_ENFORCEMENT` unset), with gaps to close
before switching them on.

**Fixed.**
1. **Instructor limit bypass.** `POST /instructors/:id/status` and `PATCH /instructors/:id` could move an
   instructor out of `inactive` with no limit check, so creating instructors inactive and activating them passed
   `instructors.max`. Leaving `inactive` now takes a seat through `withinLimit` (guard, live count and write in one
   transaction); edits that take no seat stay plain updates, so restricted-mode editing is unchanged.
2. **Restricted mode could exceed a paid tier.** A never-subscribed academy could read basic reports (and edit
   live classes, issue certificates…) that a subscribed Starter academy is refused. Restricted mode now keeps open
   only features the academy's **last plan** included: `subscriptionPlanFor` reports `lastPlanVersionId`,
   `getTenantEntitlements` returns `lastFeatures`, and `assertFeature` requires the feature there.
3. **Category writes had no explicit policy.** They now use `requireUnrestricted`: `create` (refused without a plan),
   `update` and `withdraw` (open). This is also the first use of `requireUnrestricted`, which was dead code.
4. **Features no route gates were indistinguishable from built ones.** `FeatureMeta.enforcement` (`route`,
   `service`, `planned`), a `Feature.enforcement` column (migration `20260923240000_feature_enforcement`),
   and `/tenant/billing` › `features[].enforcement`.

**Policy decisions — derived from the documented policy, for the product owner's review.**
- **Categories** are catalogue structure in no plan feature (the matrix and `courses.manage` cover courses,
  chapters and lessons). Permission alone, plus restricted mode by its own rule ("nothing new is added").
- **Restricted mode.** The policy said both "reads of reports on the basic tier stay open" and "keeps what it had,
  adds nothing". Under the second, an academy that never subscribed had no `reports.basic` to keep. Rule: an
  operation the policy keeps open is allowed on a feature-gated route only for a feature the last plan included. A
  never-subscribed academy keeps every ungated read, edit and learner path, and no plan feature. It is never more
  privileged than the lowest paid tier.
- **`analytics.advanced`** was already documented "not built" — now marked `planned`; no route was invented.
- **`priority_support`** was already documented "a service level" — now marked `service`; no gate was invented.
- **A plan never grants or restores a permission** (unchanged design, now proven end to end with a paid purchase).
- **Provisioning starts no subscription** (SAAS-019, unchanged). With enforcement on, a new academy builds nothing
  until it subscribes — through its own first purchase, or a Super Admin trial (`POST /superadmin/subscriptions`).

**Academies and environment.**
- `dev.db`: one academy (`tenant-1`), **active** on GROWTH ("Professional"), bought by its admin through Razorpay
  test checkout after the billing-details fix — no subscription was created by hand.
  - Under that plan: 4 active instructors over a limit of 3, and 2 of 2 admins. Nothing existing is taken away;
    adding or activating another is refused.
  - Certificates and branding are not in the plan.
- Development `apps/api/.env` (git-ignored): `ENTITLEMENT_ENFORCEMENT=on`, `SUBSCRIPTION_GRACE_DAYS=7`,
  `SUBSCRIPTION_RETRY_DAYS=3` — the values `.env.example` documents. Production templates are unchanged (off, per
  the staged rollout in `docs/10`). `dev.db` backed up to `dev.db.backup-before-saas025` before migrating.
- Test DB: opt-in `TEST_ACADEMY_PLAN=<code>` (`scripts/test-academy-plan.ts`, test database only) puts the seeded
  academy on a plan, so the whole suite can run enforced as a real deployment would.

**doneWhen, with evidence** (`routes/accessControl.test.ts`, 22 tests; each fix's tests fail on the old code).
- Instructor activation checked transactionally, concurrency-safe — the four "activating an instructor takes a
  seat" tests: room → allowed; at the limit → `LIMIT_REACHED`; created inactive → allowed; deactivate frees a seat;
  reactivate with room → allowed; an edit to `active` at the limit refused; 4 concurrent activations with room for 1
  → exactly 1 allowed; no plan → `SUBSCRIPTION_REQUIRED`.
- Categories explicit — "categories follow the restricted-mode policy explicitly" (3 tests).
- Restricted mode never exceeds a lower tier — 3 tests: a never-subscribed academy's reports → 402 while Starter →
  403; after a plan with reports ends → 200, after one without → 402; editing under an ended plan that had
  `courses.manage` → 200, creating → 402; never subscribed editing → 402, reading → 200.
- analytics/priority support represented — "the feature catalogue says how each feature is delivered" (every
  `route` feature gated, `planned`/`service` gated nowhere; `/tenant/billing` reports it). Live on `dev.db`.
- `requireUnrestricted` used — category routes.
- Permission and plan independent — tests A–F, and "keeps a revoked permission revoked through a paid first purchase,
  until it is granted on its own":
  - revoked → purchase via the fake gateway → subscription `active`;
  - the `AdminPermission` rows are unchanged and `/auth/me` still lacks `live.manage`;
  - `POST /live` → 403 `PERMISSION_DENIED`;
  - after the grant → `/auth/me` includes it and `POST /live` → 201.
- The access matrix and every state pass enforced — "answers every row as the layers say" (course/live create with
  and without permission and feature, report, expired, paused, no subscription), sign-up with room and when full,
  and every subscription state: trialing, active, past_due, past_due in grace, canceling → allowed; paused → 402
  `SUBSCRIPTION_REQUIRED`; expired, canceled → 402 `SUBSCRIPTION_EXPIRED`; none → 402 `SUBSCRIPTION_REQUIRED`.
- Enforcement enabled for development — `.env` above; live on `dev.db`: `enforced: true`, reports 200,
  certificates and branding 403 `FEATURE_NOT_INCLUDED`.

**Full regression.**
- Enforcement off: API 707, web 258, domain 135.
- **Enforcement on:** the entire API suite, 707/707, with the seeded academy on ENTERPRISE (`TEST_ACADEMY_PLAN`).
- typecheck, lint, build and format:check are clean for tracked files; `prisma validate` passes and the migrations
  match the schema.

**Tests changed, and why.**
- `plans.test.ts`: the database catalogue now has `enforcement`, so the mirror comparison includes it.
- `entitlements.test.ts`: "never subscribed" uses a fresh academy rather than assuming the seeded one has no plan.
- `billingViews.test.ts`: `enforced` matches the switch rather than a hard-coded `false`.
- `academies.test.ts`: provisioned academies are given the documented Super Admin trial before building, plus a new
  test pinning that under enforcement they build nothing until subscribed; the audit-sequence assertion is limited
  to `academy.*` events (the trial writes its own).
- `auditCoverage.test.ts`: removes the duplicates it creates. It was shifting the seeded course's chapters, which
  failed `learning.test.ts` in some file orders.

**Known.** Enforcement is on in development only. Production follows the staged rollout: put every academy on a
plan, set the grace and retry terms, then switch it on.


### SAAS-026 — Self-Serve Admin Registration & Public Plans (completed 3 Oct 2026)

**Built.**
- Schema: `PendingSignup` (platform-owned; migration `20261003120000_pending_signups`): hashed password, HMAC code
  bound to the row, attempts, expiry, resend time, `consumedAt`, `createdAcademyId`.
- `lib/signup.ts`: start (email unique platform-wide, address free, a new start replaces the pending one), resend
  (60 s cooldown, new code, attempts reset), verify (5 attempts counted conditionally, 15 min, single use by a
  conditional claim; provisioning released if the address/email was taken meanwhile). The code email is delivered
  at once (`deliverQueuedEmail`), not on the next tick.
- `lib/academies.ts`: `provisionAcademy` shared with `provisionSelfRegisteredAcademy` (pre-hashed password; audit
  `academy.self_registered` attributed to the new owner; permissions granted by the owner).
- Routes: `POST /signup/start|resend|verify` (own rate limiter), `GET /public/plans` (plans on sale + home tax rule).
- Email: `MAIL_TRANSPORT=smtp` (nodemailer; `SMTP_HOST/PORT/USER/PASS`, `MAIL_FROM`), refused at boot without host or
  sender; boot warning when registration needs codes and nothing delivers.
- Domain: `signup.ts` (PublicPlanCatalogue, SignupInput/Pending/Created, isSignupCode).
- Web: `/get-started` wizard (choose plan with monthly/annual → organisation & account with derived address → code
  with resend countdown → `/admin/welcome?plan&cycle`, where the chosen plan is first and marked "Your choice";
  trial or Buy now there). `PlanOfferCard` shared by the welcome page and the wizard. `useSession().adopt`.
  `/register` → `/get-started`; learner sign-up moved to `/join` (D29). Mock signup service (code 123456).
- Fixed on the way: the wizard's "already signed in" redirect raced the hand-off and dropped the plan (found by
  the live E2E); duplicate issue text in API error messages (web client).

**Decisions:** D26–D29 (above).

**doneWhen, with evidence.**
- Public plans, no private data — `signup.test.ts` › "lists the plans on sale…" (draft excluded, integer prices, GST 18% exclusive).
- start validates and emails a hashed code — "creates nothing until the emailed code is confirmed…" (no user/tenant/login before; hashes only).
- verify provisions only on a correct, unexpired code, limited, once — wrong code / locked after 5 (429, even with the right code), expired (410), replay (404), 3 concurrent confirmations → exactly one academy, code bound to its own registration.
- resend cooldown — 429 inside 60 s; old code dead after resend.
- No subscription, paid plan only via verified payment — subscription count 0 after verify; body's role/tenantId/planId/status ignored.
- Rate limits + audit — `/signup` limiter; `academy.self_registered` row with the owner as actor.
- Web wizard — `getStartedFlow.test.ts` (11), `Welcome.test.tsx` chosen-plan test; **live Playwright `e2e/signup.spec.ts` 3/3**: register → wrong code refused → right code → plan page with Growth marked → trial → own empty academy; taken address refused before a code is sent.
- Isolation — two self-registered admins: neither sees the other's people; platform routes 403.
- SMTP transport — `mailSmtp.test.ts` (selection, boot refusal, unreachable relay fails for retry).

**Verification.** typecheck, lint, `npm test` (web 381, domain 148), API 765, build, format:check — all green.
Full E2E (13 existing + 3 new) green; `run-e2e.mjs` now passes extra args to Playwright.

**Known / human-required.** Production needs an SMTP relay (`MAIL_TRANSPORT=smtp` + credentials) before
self-serve registration can be opened; `deploy/api.env.example` keeps `outbox` with the SMTP block commented, and
the bootstrap and boot log say so. `dev.db` has not been migrated yet (done with a backup before the next live smoke).

### SAAS-027 — SaaS Marketing Website & Contact Sales (completed 3 Oct 2026)

**Built.**
- Schema: `Inquiry` (tenant-or-platform: a website request has no academy; an academy admin's support request — SAAS-029 —
  carries theirs), migration `20261003130000_inquiries` with a no-delete trigger; tenancy classification (47 tables).
- API: `POST /public/inquiries` (validated, honeypot, own rate limit, `SALES_NOTIFY_EMAIL`), `GET/PATCH
  /superadmin/inquiries` (filters, counts, status + private note, audited `inquiry.updated`).
- Domain: `inquiry.ts` (kinds, statuses, labels, PublicInquiryInput, Inquiry, InquiryListResult).
- Web, company site: new header (Product, Solutions, Pricing, How it works, FAQ; Sign in, Get started; working phone
  menu) and footer; Home (`/` for visitors and `/welcome`), `/features`, `/solutions`, `/pricing` (live plans,
  monthly/annual with the computed saving, tax line from the server's rule, comparison table, billing FAQ, CTA into
  Get started with plan + cycle), `/how-it-works`, `/about`, `/faq`, `/contact?topic=demo|sales|support`; SaaS
  Privacy (academies as customers, billing data, contact data) and Terms (plans, trials, billing, D7–D10, restricted
  mode, isolation, suspension). The old landing's invented testimonials and statistics are gone; every claim describes
  what the product does.
- Web, platform: `/superadmin/inquiries` Inbox (status tabs with counts, type filter, search, side panel to move a
  request and note it), nav item "Inbox".
- Fixed on the way: contact form overflowed a phone by 14 px (grid column min-content) — found by the live overflow check.

**doneWhen, with evidence.**
- Chrome links every page; Get started → wizard — `e2e/website.spec.ts` page crawl (12 pages × desktop and phone: one h1,
  no console error, no sideways scroll) and the phone-menu test.
- Pricing reads /public/plans, toggle, limits, error state — website spec "pricing shows the plans on sale…" (₹3,999
  monthly → ₹39,990 annual, GST line, drafts/archived absent, Get started carries plan+cycle); `site.test.ts` (CTA,
  saving, comparison); `PlansError` state with retry.
- POST /public/inquiries stored, validated, rate-limited; Super Admin lists/updates; audited — `inquiries.test.ts` (6:
  stored with no academy, validation, honeypot not stored, body cannot set academy/status/note, list/filter/counts,
  status moves with closedAt and 3 audit rows, platform-only 401/403, delete refused); website spec "a demo request
  reaches the platform team’s inbox and is moved along" (live).
- Privacy/Terms describe the SaaS model — pages rewritten/extended (above).
- Responsive, accessible, console clean — the crawl above; FAQ as `details/summary`; comparison table with row/col headers.

**Verification.** typecheck, lint, `npm test` (web 389, domain 148), API 771, build, format:check — all green.

**Human-required.** Legal review of the Privacy and Terms copy; real addresses for help@/privacy@/legal@syniastrolms.in
and a `SALES_NOTIFY_EMAIL`.

### SAAS-028 — Admin-Created Learners & Academy Join Links (completed 3 Oct 2026)

**Built.**
- `lib/learners.ts`: one way to create a learner (academy of the request, `learners.max` via `withinLimit`, restricted
  mode, platform-unique email) behind three doors — `POST /auth/register` (unchanged contract, host academy, Flutter),
  `POST /public/academies/:slug/register` (the join link), `POST /students` (admin; random password + 7-day
  `learner-invite` link; audited `learner.created`). `POST /students/:id/resend-invite`.
- `GET /public/academies/:slug` → `{ name, slug, open }` (archived = not found; suspended = closed, register 403).
  Join routes on the sign-up rate limit.
- `GET /academy/plan` now carries `academy: { name, slug }` (additive; Flutter DTOs ignore unknown keys).
- Permission `learners.enroll` relabelled "Add and enrol learners" (no new key, so existing admins keep the ability).
- Web: `/join` (enter the academy's address or paste its link) and `/join/:slug` (academy-named sign-up; not-found,
  closed and loading states; plan refusals shown to the learner in plain words); Students page: "Add student"
  (`PlanAction` with learner capacity → dialog), "Copy join link", the link shown under the header, new empty-state copy.

**Decision applied:** D29.

**doneWhen, with evidence** (`learnerJoin.test.ts`, 9 tests).
- POST /students in own academy only, limit, invite, permission, audit — "creates the learner in the admin’s own academy…"
  (body tenantId/role ignored, audit row, invite link sets a password, sign-in works); "needs the learners.enroll
  permission" (403 PERMISSION_DENIED after the grant is revoked); "stops at the plan’s learner limit…" (402
  SUBSCRIPTION_REQUIRED with no plan, 1/1 then 403 LIMIT_REACHED, the join link refused the same way).
- Public join for active academies only; slug selects, never authorises — "names the academy, and signs a learner up
  into that academy only" (tenantId of the new user = that academy; body tenantId/role ignored; seeded academy never
  sees them); "is not found for an unknown or archived academy, and closed for a suspended one".
- Admin UI — live `e2e/learners.spec.ts` (add student with validation → toast → in roster; join via pasted link →
  /join/default → /home; unknown academy message). `student.spec.ts` moved to `/join/default` and passes.
- Cross-academy — "never reaches another academy’s learners" (B: resend-invite/get/suspend on A's learner → 404, B's list empty).
- Flutter's `/auth/register` — "still joins the academy this host serves".

**Verification.** typecheck, lint, `npm test` (web 392, domain 148), API 780, build, format:check — all green.

### SAAS-029 — Client-Centric Super Admin & Support Inbox (completed 3 Oct 2026)

**Built.**
- API: `POST/GET /tenant/support` (any academy admin; academy and person from the session; audited
  `inquiry.created`; team note withheld from the academy); `/superadmin/overview` gains `clients` (by status,
  self-registered count) and `inbox` (new, in progress); client search also matches the owner admin's name/email.
- Web: Super Admin "Academies" presented as **Clients** (nav, title, "Client" column = owner admin name + email first,
  then the academy; "New client"; search by admin); overview "Clients" group (clients, self-registered, inbox new →
  links); admin `/admin/support` page (new request + the academy's requests with status) reached from the Help
  Centre's "Contact platform support" (admins only; learners/instructors keep the email).

**doneWhen, with evidence.**
- Clients presented as admin + academy with plan, status, usage — Academies list columns; `supportRequests.test.ts`
  "finds a client by its admin…"; live `e2e/support.spec.ts` (Clients heading and Client column).
- Admin support request carries the academy from context; Super Admin inbox lists/resolves — "lands in the inbox with
  their academy and their own name — whatever the body says" (forged tenantId/email/status ignored); live spec (admin
  sends → platform inbox shows "academy admin" + Support request).
- Admin sees only own requests; forged tenantId ignored — "shows an academy its own requests only, without the team’s
  private note"; "is for academy admins only…" (instructor/student/superadmin 403, anonymous 401).

**Verification.** typecheck, lint, `npm test` (web 392, domain 148), API 784, build, format:check — all green.
Onboarding E2E updated for "New client" and passing.

**Known.** Learners and instructors still see the platform's help email on the Help Centre; pointing them at their
academy's own support address needs that address exposed to them (settings are admin-only today).

### SAAS-030 — Sandbox Payment Gateway (non-production) (completed 3 Oct 2026)

**Why.** Razorpay's checkout is a third-party widget a browser test cannot drive, so payment success, failure and
cancellation had never been exercised end to end in a browser.

**Built.**
- `lib/sandboxGateway.ts`: `SandboxProvider implements PaymentProvider` — orders and payments on "the gateway's side"
  (process memory), HMAC-signed checkout completions and webhooks under secrets derived from the server secret,
  `checkoutParams` with `redirectUrl = APP_URL/sandbox-checkout/:orderId` (the hosted-page path the web dispatcher
  already follows), refunds and capture. `PAYMENT_SANDBOX=on` enables it **only while no real gateway is active** and
  never in production: `sandboxEnabled()` is false when `NODE_ENV=production`, and `assertSandboxConfig` refuses to
  boot with it there.
- Gateway factory: `activeProvider` falls back to the sandbox only when enabled and nothing is active; `providerFor`,
  `webhookVerifiers` and `gatewaysWithCredentials` know it. No DB change (the gateway tables' CHECKs are untouched).
- `/sandbox` routes (404 while off): read an order; pay/decline → the signed webhook is delivered to
  `/webhooks/sandbox/subscription` (the real route) before answering.
- Web: `/sandbox-checkout/:orderId` test page (pay, decline, cancel) → back to `/admin/billing?checkout=paid|failed|cancelled`;
  the billing page reports it and re-reads billing (what the server recorded). `run-e2e.mjs` runs the API with
  `PAYMENT_SANDBOX=on` and `APP_URL` = the preview server.

**doneWhen, with evidence.**
- Adapter + refused in production — `sandboxGateway.test.ts` "switched off…" (routes, webhook endpoint 404,
  checkoutAvailable false) and "is refused in production, whatever the switch says".
- Outcomes reach the subscription only through verified webhook; duplicates idempotent — "pays: the signed webhook
  activates the subscription, once" (GST from the server, invoice paid, one payment, duplicate event and re-sent event
  change nothing, paying a paid order refused); "is declined…" (no subscription, no paid payment, retry on the same
  invoice succeeds); "is abandoned…"; "believes no forged or tampered webhook, and no forged browser completion"
  (bad signature 401, tampered body 401, made-up and signed-but-unpaid completions refused); "never lets one academy
  settle another’s order".
- Live: `e2e/payments.spec.ts` — register → Buy Growth → billing details → decline (nothing changes) → cancel
  (nothing changes) → pay → "Payment received", plan active → sign out/in → modules open.

**Verification.** typecheck, lint, `npm test` (web 392, domain 148), API 791, build, format:check — all green.

### SAAS-031 — Multi-Admin Live E2E & Isolation QA, with the multi-admin fixes (completed 3 Oct 2026, UNCOMMITTED)

**Fixes made under the owner's architecture brief.**
1. Admin-first UI (D30): Super Admin "Admins"/"Admin users", "New admin", columns Admin + LMS, overview "Admins"; website
   home/FAQ/how-it-works and Get started ("Launch your LMS", "LMS address"); join pages ("Join your learning space").
2. Tenant-aware learner sign-up (D32): `POST /auth/register` accepts `workspace`; `lib/learners.ts` `workspaceAt`/`registerLearnerAt`
   shared with the join link.
3. Enforcement safety (D31): `entitlementEnforcement(env)`, `assertBillingConfig` (terms needed when enforced by default),
   `assertTenancyConfig`; boot warning for production `off`.
4. Signup plan persisted: `PendingSignup.planId/cycle` (migration `20261003140000_pending_signup_plan`), `choice` in start/verify,
   `/tenant/billing.signupChoice` (welcome page falls back to it).
5. Signup survives refresh: `GET /signup/:signupId` + session-stored id; the wizard resumes at the code step.
6. Payment return: `?checkout=paid|failed|cancelled` on the billing page (sandbox / hosted gateways).
7. Suspended/closed accounts (D33).
8. Restricted mode and storage: already enforced (media upload `withinLimit storage.bytes`, restricted refusal; `usage.test.ts`) — verified, no change.
9. Super Admin vs Admin authorization: already separate (`requireSuperAdmin` router; `/tenant/*` refuses superadmin — tested).

**Evidence.** API: `enforcementConfig.test.ts` (3), `signup.test.ts` +2 (choice kept/dropped, status endpoint, signupChoice),
`learnerJoin.test.ts` +1 (`workspace` register). Live `e2e/multiadmin.spec.ts` (3): SA creates Admin A and B → each starts a
trial, adds a student (UI) and an instructor → rosters disjoint → A gets 404 on B's student/instructor (GET, suspend,
PATCH), 403 on platform routes, forged tenantId ignored → SA ends A's subscription → A refused (402), B unaffected → SA
suspends B → B's open session lands on "This account is suspended", sign-in refused, A unaffected → reactivated B has its data.
Full suites: API 797, web 392, domain 148, build, lint, format; **E2E 28/28**.

**Remaining / human-required.** SMTP credentials before opening registration; Razorpay staging webhook (SAAS-016);
VyaparGateway contract (SAAS-017); legal review of Privacy/Terms; Flutter app should send `workspace` on register and
use the new Admin wording; `dev.db` not migrated (needs `prisma migrate deploy` — additive — with a backup, owner's call);
internal names (`academy` in code, routes `/superadmin/academies`, settings "Academy name") kept to avoid churn.
