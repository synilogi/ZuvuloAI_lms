# 03 — Database Specification

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

**Added by the conversion (all additive; nothing dropped):** `20261101120000_platform_workspace` (`User.phone`, `Instructor.linksJson`, `PendingAccount.phone`, `profileJson`), `20261101130000_course_orders` (`OrderSequence`, `Course.salePrice`, purchase `orderNumber`, `discountAmount`, `couponId`, `couponCode`, `refundedAt`, `Coupon`, `CouponRedemption`, `CoursePurchaseRefund`), `20261101140000_site_content` (`SiteContent`), `20261101150000_mlm_earnings` (`MlmMatchingRun`, `MlmRankHistory`, `MlmReward`, `MlmCommission`, `MlmWallet`, `MlmWalletEntry`, `MlmKyc`, `MlmPayoutBatch`, `MlmWithdrawal`, with immutability triggers), `20261101180000_course_reviews` (`CourseReview`). The retired SaaS tables stay until a separate, approved drop.

**Engine:** SQLite via Prisma ORM (`apps/api/prisma/schema.prisma`). Chosen because the project has no
external services to run; the schema is portable to PostgreSQL/MySQL by changing the `datasource`
provider (see `10-DEPLOYMENT.md`).

**Migrations:** applied with `prisma migrate` from `apps/api/prisma/migrations/` (baseline created in
Foundation phase F0; before that the schema was applied with `prisma db push`). 45 migrations as of 31 Oct 2026, the
last `20261031150000_mlm_cv`; the schema holds 81 models. The sections below cover the LMS core and the
SaaS billing tables; the tables added since are in *Tables added after the sections above*.

**Conventions**

- Ids are `cuid()` strings. Every entity that the UI shows a date for has `DateTime` columns; Prisma
  `@updatedAt` is used where the UI shows "updated".
- Enumerations from `packages/domain` (`CourseStatus`, `LessonType`, `ReviewStatus`, …) are stored as
  `String` columns; the domain types are the source of truth for allowed values and the API validates
  them at the boundary.
- Nested/variable shapes that the domain package already types (lesson content per type, quiz questions,
  rubrics, settings sections, agendas, signatories, notification facts/actions) are stored as JSON text
  columns named `*Json` and parsed by `apps/api/src/lib/json.ts`.
- Foreign keys use `onDelete: Cascade` for owned children (chapters → lessons, course → enrollments, …)
  and no cascade for references (course → level/category/template).

## Tenancy (SAAS-000)

`Tenant` (`id`, `name`, `slug` unique, `status` `active`/`suspended`/`archived` — enforced on every request since
SAAS-019, `statusReason?`, `statusChangedAt?`, `ownerUserId?`) is one
academy. Every academy-owned table carries `tenantId` → `Tenant.id` (`ON DELETE RESTRICT`, so removing an
academy can never cascade its data away) with an index led by `tenantId`:

- **required** on 28 tables: `MediaAsset`, `Level`, `Category`, `CategoryLevel`, `Instructor`, `Course`,
  `CourseInstructor`, `Chapter`, `Lesson`, `Student`, `Enrollment`, `LessonProgress`, `LessonNote`,
  `LessonBookmark`, `SavedCourse`, `Rank`, `Quiz`, `QuizAttempt`, `CourseAssignment`, `AssignmentDraft`,
  `Submission`, `CertificateTemplate`, `IssuedCertificate`, `LiveClass`, `LiveRegistration`,
  `CalendarEvent`, `Settings`, `AdminPermission`;
- **nullable** on 5, where NULL means a platform row (a super admin and what belongs to one): `User`,
  `PasswordResetToken`, `NotificationSettings`, `AppNotification`, `EmailOutbox`;
- **absent** on the platform's own tables: `Tenant`, `HelpCategory`, `HelpArticle` (the Help Centre is
  shared, D5) and `AuditLog`.

Uniqueness: `User.email`, `Instructor.email`, `IssuedCertificate.credentialId` and
`MediaAsset.storageName` stay unique across the platform (D2, D4); `Course.slug` is unique per academy
(`@@unique([tenantId, slug])`), as are category and course names (checked in code). `Settings` is keyed by
`tenantId` — one row per academy, where it used to be the singleton `id = 1`. The rules the data must obey
are checked by `npm run tenants:verify` (`src/lib/tenantAudit.ts`).

## Plans (SAAS-001)

Platform tables, with no `tenantId`. `src/lib/plans.ts` is the only writer.

| Model | Key fields | Constraints |
| --- | --- | --- |
| `Plan` | `code` (unique, capitals), `name`, `description`, `status` (`draft`/`active`/`archived`), `displayOrder`, `createdAt`, `updatedAt`, `archivedAt?` | CHECK on status, code shape, and `archivedAt` set exactly when archived; trigger `Plan_code_fixed` refuses a code change once the plan has left draft; index (`status`,`displayOrder`) |
| `PlanVersion` | `planId`, `version` (1, 2, …), `currency` (ISO 4217), `monthlyPrice?`, `annualPrice?`, `trialDays`, `createdAt` | **append-only** — triggers `PlanVersion_no_update` / `PlanVersion_no_delete` refuse any UPDATE or DELETE; `@@unique([planId, version])`; FK to `Plan` `ON DELETE RESTRICT`; CHECKs that each price is NULL (cycle not sold) or a non-negative SQLite **integer**, that at least one cycle is priced, and that `trialDays` is 0–90 |

A plan's commercial terms live only in its versions: a change to currency, a price, the cycles sold or the
trial adds version N+1, and the highest version is what new subscriptions are sold. Anything that records a
sale (subscriptions, invoices — SAAS-004, SAAS-008) will hold a `PlanVersion.id`, so it keeps its terms
whatever the plan becomes. **Money is an integer in the currency's minor unit** — 399900 is ₹3,999 — here and
in every financial table that follows (`packages/domain/src/money.ts`). The migration creates the tables
only; the seed adds the demo catalogue.

## Entitlement catalogue and grants (SAAS-002)

| Model | Key fields | Constraints |
| --- | --- | --- |
| `Feature` | `id` (the catalogue key, e.g. `courses.manage`), `group`, `label`, `description`, `displayOrder` | written by migration from `packages/domain/src/entitlement.ts`; never deleted (trigger) |
| `LimitDefinition` | `id` (e.g. `learners.max`), `label`, `unit` (`count`/`bytes`), `period` (`total`/`month`), `displayOrder` | as above; CHECK on unit and period |
| `PlanFeature` | `planVersionId`, `featureKey` → `Feature.id` | PK (`planVersionId`,`featureKey`); append-only (triggers); FKs `RESTRICT` |
| `PlanLimit` | `planVersionId`, `limitKey` → `LimitDefinition.id`, `value` BIGINT? (NULL = unlimited; bytes for storage) | PK (`planVersionId`,`limitKey`); CHECK integer ≥ 1; append-only (triggers) |

`PlanVersion` gained `featureCount` and `limitCount`: how many grants the version declares, fixed with the
version. The `PlanFeature_sealed` / `PlanLimit_sealed` triggers refuse any grant beyond that count, so a
version's allowance cannot be added to after it is written. Nor can it be changed or removed. A limit a
version does not set grants 0, never "unlimited". A version written before SAAS-002 declares 0 of each and
grants nothing; editing the plan adds a version that carries an allowance.

## Subscriptions (SAAS-004)

Both tables are academy-owned: required `tenantId`, a RESTRICT foreign key, and an index. The academy-owned
count is now 35 (`TENANT_OWNED_MODELS`). `src/lib/subscriptions.ts` is the only writer.

| Model | Key fields | Constraints |
| --- | --- | --- |
| `Subscription` | `tenantId`, `planId`, `planVersionId`, `status`, `billingCycle`, `currency`, `amount` (minor units, from the version), `trialStartAt?`/`trialEndAt?`, `currentPeriodStartAt`/`currentPeriodEndAt`, `cancelAtPeriodEnd`, `cancelRequestedAt?`, `canceledAt?`, `cancellationReason?`, `pausedAt?`, `resumesAt?`, `gracePeriodEndAt?`, `provider?`, `providerCustomerId?`, `providerSubscriptionId?` | CHECKs on status (7), cycle, currency, integer amount ≥ 0, period order and trial pairing; `@@unique([provider, providerSubscriptionId])`; **partial unique index `Subscription_one_live_per_tenant`**: one live subscription per academy; indexes (`tenantId`,`status`), `planVersionId`, (`status`,`currentPeriodEndAt`) |
| `SubscriptionEvent` | `id` (autoincrement, orders the log), `tenantId`, `subscriptionId`, `event` (§19 name), `transition`, `fromStatus?`, `toStatus`, `actorType` (`user`/`system`/`provider`), `actorId?`, `source?`, `metaJson`, `createdAt` | append-only; CHECK on actor; indexes (`tenantId`,`createdAt`), (`subscriptionId`,`id`) |

Triggers carry the state machine into the database, so no code path, raw SQL included, can move a
subscription any other way:
- `Subscription_initial_status`: a subscription is created only as `trialing` or `active`.
- `Subscription_status_by_transition`: a status change is refused unless the latest `SubscriptionEvent`
  records exactly that from → to. An old event cannot be replayed.
- `SubscriptionEvent_create` / `_transition` / `_same_tenant`: the first event is the creation; every later
  event starts from the current status and is one of the 17 allowed status pairs; and an event belongs to its
  subscription's academy.
- `Subscription_terms_by_transition`: the plan version, amount, currency and cycle change only with a
  `change_plan` event naming exactly the new terms.
- `Subscription_version_of_plan_*`: the version must belong to the plan.
- `Subscription_no_delete`, `SubscriptionEvent_no_update` / `_no_delete`: nothing here is ever deleted or
  rewritten.

SAAS-005 added `pastDueAt`, `pastDueReason` and `gracePeriodStartAt`, with a CHECK that the grace window is
whole and ordered, and two triggers:
- `Subscription_trial_fixed`: a trial's dates never change once written.
- `Subscription_grace_by_transition`: a grace window is opened only by a `grace_started` event naming its
  exact end.

It also re-issued `SubscriptionEvent_transition` with the new `past_due → past_due` pair, 18 in all.

SAAS-006 added `PlanChange`, which is academy-owned; the academy-owned count is now 36. It holds:
- the kind, and a status of `pending_payment`, `scheduled`, `applied`, `canceled`, `void` or `expired`;
- the from and to version, cycle and amount, and the currency;
- `credit`, `charge` and `forfeited`, as integers ≥ 0;
- the period it was priced against, and `quotedAt`;
- `conflictsJson`, the requester, and the applied and closed details.

Its guards:
- CHECKs on every set and every amount.
- `PlanChange_one_open_per_subscription`, a partial unique index.
- `PlanChange_initial`: upgrades start `pending_payment`; everything else starts `scheduled` and moves no money.
- `PlanChange_consistent`: the version belongs to the plan, in the subscription's academy.
- `PlanChange_quote_fixed`: the figures are never altered.
- `PlanChange_status_path`: the status only moves forward.
- `PlanChange_applied_with_event`: a change is `applied` only alongside the `change_plan` event naming it.
- `PlanChange_no_delete`.

`Subscription_period_by_transition` lets `currentPeriodStartAt` and `currentPeriodEndAt` change only when the
latest lifecycle event records exactly the new dates, in milliseconds. Those events are renewals, resumes from a
pause and cycle upgrades.

Prisma does not model a partial index, so the schema does not show `Subscription_one_live_per_tenant`.
`prisma migrate diff` ignores it and reports no drift.

## Tax and billing profiles (SAAS-007)

| Model | Key fields | Constraints |
| --- | --- | --- |
| `TaxRule` (platform) | `name`, `country` (ISO alpha-2), `region?`, `inclusive`, `componentCount`, `createdAt`, `retiredAt?` | partial unique index `TaxRule_one_active_per_place`: one active rule per (country, region). Trigger `TaxRule_fixed`: nothing but a single retirement ever changes. No delete. |
| `TaxRuleComponent` (platform) | `ruleId`, `code`, `label`, `rateBps`, `position` | CHECK: `rateBps` is an integer from 0 to 10000. Sealed at the rule's `componentCount`. Never updated or deleted. |
| `BillingProfile` (academy) | `tenantId` (unique), `legalName`, `email`, address lines, `city`, `region?`, `postalCode`, `country`, `taxRegistration?` | CHECK on the country's shape. Invoices copy what they print, so an address change rewrites no invoice. |

No tax rate is inserted by a migration. They are configured data; the seed adds a demo rule for India.

## Invoices and payments (SAAS-008)

Academy-owned: `Invoice`, `Payment`, `Refund`, `PaymentMethod` (the academy-owned count is now 41). Platform:
`InvoiceSequence`.

| Model | What it holds | Guards |
| --- | --- | --- |
| `Invoice` | `number` (unique, `INV-YYYY-NNNNNN`), purpose, status (`open`/`paid`/`void`), subscription/plan change, currency, `subtotal`, `taxTotal`, `total`, `inclusive`, tax rule, `linesJson`, `taxLinesJson`, `billedToJson` (the billing profile at issue), period, `issuedAt`, `dueAt`, `paidAt`, `voidedAt`, `voidReason`, provider reference | CHECK `total = subtotal + taxTotal`, integers. `Invoice_fixed`: nothing issued is altered. `Invoice_insert_open`. `Invoice_status_path`: open → paid or void, once. `Invoice_paid_by_payment`: paid only with a paid payment of exactly its total. No delete. Partial unique indexes: one live invoice per plan change, and per renewal period. |
| `Payment` | invoice, subscription, `provider` + `providerPaymentId` (unique), `amount`, `currency`, status (`pending`/`paid`/`failed`), failure code and message, masked method (`methodKind`, `methodBrand`, `methodLast4`), `paidAt`, `failedAt` | `Payment_fixed`: amount and references never change. `Payment_settles_once`: pending → paid or failed, then never updated. `Payment_same_tenant`. No delete. CHECK `last4` is four digits. |
| `Refund` | payment, `amount`, currency, `reason`, status (`pending`/`succeeded`/`failed`), provider reference, requester, `settledAt` | `Refund_within_payment`: against a paid payment, same currency and academy, and the non-failed refunds never exceed it. `Refund_fixed`: settles once. No delete. |
| `PaymentMethod` | `provider` + `providerMethodRef` (unique), kind, brand, `last4`, expiry month and year, `isDefault`, `removedAt` | CHECKs: `last4` is four digits; the brand holds no digit run. `PaymentMethod_fixed`. No delete. **No column for a card number or security code** (a test scans every table). |
| `InvoiceSequence` | `series` (`INV-2026`), `next` | only counts up; never deleted |

A payment's refunded state is read from its refunds. A paid payment row is never rewritten to say it was refunded.

## Checkout orders (SAAS-009)

`PaymentOrder` is academy-owned; the count is now 43. It records the provider order an open invoice is paid
through, from migration `20260922190000_payment_orders`:
- fields: `provider` + `providerOrderId` (unique), `amount`, `currency`, `status` (`created` or `paid`),
  `providerPaymentId`, `paidAt`;
- `PaymentOrder_matches_invoice`: made only for an open invoice of the same academy, at exactly its total and
  currency;
- `PaymentOrder_settles_once`: fixed once made, it moves from `created` to `paid` once, naming the payment;
- `PaymentOrder_no_delete`: never deleted.

## First purchase (SAAS-009, extended)

Migration `20260923090000_first_purchase` adds columns in place, so every trigger stays:

| Column | Meaning |
| --- | --- |
| `Invoice.planVersionId`, `Invoice.billingCycle` | what a first-purchase (`new_subscription`) invoice sells, fixed at issue |
| `Subscription.sourceInvoiceId` (unique) | the paid first-purchase invoice a self-service subscription was created from; null when the platform started it |

Guards:
- `Invoice_sale_on_insert`: a first-purchase invoice names a real plan version and a cycle, and no other invoice
  names either.
- `Invoice_sale_fixed`: what an invoice sold never changes.
- `Invoice_one_open_first_purchase`: at most one open first-purchase invoice per academy (a partial unique index).
- `Subscription_from_invoice`: a subscription carrying `sourceInvoiceId` is created only from a **paid**
  first-purchase invoice of its own academy, for exactly its plan version, cycle and currency, and starts
  active.
- `Subscription_source_fixed`: the source invoice never changes.

The unique `sourceInvoiceId` means an invoice can start at most one subscription. `Subscription_one_live_per_tenant`
still allows one live subscription per academy.


## Platform branding (`PlatformBrandAsset`)

The platform's own logo and favicon, uploaded by the Super Admin. Platform-owned: no `tenantId`, listed in
`PLATFORM_MODELS` (`lib/tenancy.ts`), and unrelated to an academy's `Settings.appearanceJson`.

| Column | Notes |
|---|---|
| `kind` | Primary key: `logo` or `favicon` (`CHECK`). At most one row per kind; **no row means the built-in ZuviloAI asset**. |
| `storageName` | Unique. The file's name under `UPLOAD_DIR/branding`, chosen by the server (`<kind>-<uuid>.<ext>`), new for every upload. |
| `originalName` | The uploaded file's name, cleaned. Shown to the Super Admin; never used on disk. |
| `mime`, `sizeBytes`, `width`, `height` | What the server found in the file's bytes. |
| `updatedById`, `createdAt`, `updatedAt` | Who saved it and when. |

Migration `20261010120000_platform_branding` (additive: one new table, nothing else read or changed). Restoring the
default deletes the row and the file. `UPLOAD_DIR` must be on persistent storage, as for media.

## Payment gateways (SAAS-017)

There are two platform-owned tables, from migrations `20260923120000_payment_gateways` and
`20260923150000_gateway_credentials_per_environment`.

`PaymentGatewayConfig` holds one row per gateway:

| Column | Meaning |
| --- | --- |
| `provider` (unique) | the registry id: `razorpay` or `vyapargateway` (CHECK) |
| `enabled`, `isActive` | whether it may be used, and whether new payments go through it |
| `environment` | `test` or `live`: whose credentials new payments through it use |
| `version`, `updatedById` | bumped on every change; who made it |

`PaymentGatewayCredential` holds one row per (provider, environment), so test and live are kept apart:

| Column | Meaning |
| --- | --- |
| `provider`, `environment` (unique together) | whose credentials, for which environment; fixed once made |
| `cipher`, `keyId` | the credentials, AES-256-GCM under `PAYMENT_CREDENTIALS_KEY`, and that key's fingerprint (never the key) |
| `hint` | what is safe to show: the key ID's last four, which secrets are set |
| `configuredAt`, `updatedById` | when and by whom the credentials were last saved; a save replaces the row in place |

Guards:
- `CHECK` and `PaymentGatewayConfig_active_ready_*`: only an enabled gateway with credentials for its
  environment can be active, and the active gateway cannot switch to an environment that has none.
- `PaymentGatewayConfig_one_active`: at most one active gateway. None is allowed, on purpose: online payment
  is then off.
- `PaymentGatewayConfig_no_delete` and `PaymentGatewayCredential_no_delete`: a gateway is disabled and
  credentials are replaced, never deleted.

Every invoice, order, payment, refund and webhook receipt carries `provider`.
- `Invoice.provider` is set at the invoice's first checkout, to the active gateway. `Invoice_fixed` lets it be
  set only once, from null.
- `PaymentOrder_invoice_gateway` refuses an order through any other gateway.
- `PaymentOrder.environment` records which credentials created the order, and
  `PaymentOrder_environment_fixed` keeps it fixed. It is confirmed, reconciled and refunded with those
  credentials, whichever environment the gateway uses later.

Backfill:
- An existing invoice is pinned only where its own checkout orders prove the gateway, meaning they name exactly
  one distinct provider.
- An existing order keeps `environment` null, because which keys made it was never recorded. Such an order is
  resolved with the gateway's current environment. The gateway refuses an id from the other environment, so
  nothing is recorded wrongly.
- Stored credentials moved unchanged into the slot of the environment they were saved for.

## Webhook receipts (SAAS-010)

`WebhookEvent` is platform-owned: a webhook arrives with no academy and is matched to one by the checkout it
settles. Migration `20260922210000_webhook_events` creates one row per provider event, unique on
`provider` + `providerEventId`:
- what it keeps: `eventType`, `payloadHash` (SHA-256 of the signed body), `referenceJson` (the payment, order
  or refund ids named), `status` (`received`, `processed`, `ignored` or `failed`), `attempts`, `note`,
  `receivedAt`, `processedAt`;
- what it never keeps: the body, which carries the payer's email and phone;
- `WebhookEvent_receipt`: what arrived never changes; a processed or ignored event is final; attempts only
  grow;
- `WebhookEvent_no_delete`: never deleted.

## Audit trail (SAAS-014)

`AuditLog` (platform-owned) records who did what. Migration `20260922170000_audit_sources` adds two columns in
place, so existing rows stay (all were people's, and take `user`):

| Column | Meaning |
| --- | --- |
| `actorType` | `user` (a person: `actorId`, `actorEmail`, `actorRole`), `system` (a scheduled job) or `provider` (the payment provider). Default `user`. |
| `source` | the job or provider a `system` or `provider` event names; null for a person |

Triggers:

- `AuditLog_actor_shape`: a person has no `source`; a system or provider event has a non-blank `source` and no
  `actorId`; `actorType` is one of the three.
- `AuditLog_append_only_update` and `AuditLog_append_only_delete`: an entry is never changed or deleted. The one
  update allowed is the foreign key clearing `actorId` when the account is removed (`ON DELETE SET NULL`); the
  entry keeps the email and role it was written with.

Index `AuditLog_action_idx` serves the Super Admin's filter by action.

## Usage guards (SAAS-011)

`UsageGuard` is academy-owned (`tenantId`, `limitKey` as the primary key, `touchedAt`); the academy-owned count is
now 42.

Every write that adds to a limit first upserts the row for its academy and limit, inside its transaction. That
write holds the database's lock (SQLite's single writer, or a row lock on PostgreSQL) until the transaction ends,
so the live count and check that follow cannot be raced. The row stores no figure.

**D6, revisited as planned.** This needed no database engine change, so SQLite stays. The guard works the same
on PostgreSQL if the engine changes later.

`Course.priceAmount` is an academy's own course price and predates this phase. It is still whole rupees
and is not part of platform billing.

## Entities

### Identity

| Model | Purpose | Key fields | Relations |
| --- | --- | --- | --- |
| `User` | Account and role | `email` (unique), `passwordHash`, `name`, `role` (`student`/`instructor`/`admin`), `descriptor`, `instructorId?` | 1–1 `Student`, →`Instructor` |
| `Student` | Learner profile | `userId` (unique), `city`, `phone?`, `joinedAt`, `lastActiveAt`, `suspended`, `suspendReason?`, `rankId?` | →`User`, →`Rank`, many enrollments/progress/notes/bookmarks/saved/attempts/submissions/registrations/certificates |
| `Instructor` | Teaching profile | `email` (unique), `name`, `title`, `bio`, `expertiseJson`, `languagesJson`, `status` (`active`/`invited`/`inactive`), `joinedAt`, `city`, `phone?`, `yearsTeaching?`, `photoJson?` | many `CourseInstructor`, `LiveClass`, `User` accounts |
| `Rank` | Learner standing ladder | `title`, `order`, `descriptor`, `criteriaJson` | many `Student` |

### Catalog

| Model | Key fields | Relations / indexes |
| --- | --- | --- |
| `Level` | `name`, `order`, `summary?` | many `Course`, `CategoryLevel` |
| `Category` | `name`, `description`, `order`, `status`, `glyph`, `updatedAt` | many `Course`; `CategoryLevel` join to levels |
| `CategoryLevel` | composite id (`categoryId`,`levelId`) | join |
| `Course` | `slug` (unique), `title`, `subtitle`, `description`, `levelId`, `categoryId`, `format`, `language`, `coverMotif`, `liveSessions`, `estimatedWeeks?`, `certificateTitle?`, `priceAmount?`, `priceCurrency`, `enrolledCount`, `status`, `visibility`, `outcomesJson`, `tagsJson`, `createdAt`, `updatedAt`, `publishedAt?`, `rating?`, `ratingCount?`, `certificateTemplateId?` | indexes on `categoryId`, `levelId`, `status`; →`Level`, →`Category`, →`CertificateTemplate?`; many `CourseInstructor`, `Chapter`, `Enrollment`, `Quiz`, `CourseAssignment`, `LiveClass`, `CalendarEvent`, `IssuedCertificate` |
| `CourseInstructor` | composite id (`courseId`,`instructorId`) | join; first row = lead instructor |
| `Chapter` | `courseId`, `title`, `summary?`, `objective?`, `estimatedMin?`, `status`, `position` | index `courseId`; cascade from course; many `Lesson` |
| `Lesson` | `chapterId`, `courseId`, `title`, `type`, `durationMin`, `isPreview`, `status`, `updatedAt`, `description?`, `objectivesJson`, `contentJson`, `settingsJson`, `position` | indexes `chapterId`, `courseId`; cascade from chapter; 1–1 `Quiz?`, `CourseAssignment?`; many progress/notes/bookmarks |

### Learning

| Model | Key fields | Relations / constraints |
| --- | --- | --- |
| `Enrollment` | `studentId`, `courseId`, `enrolledAt`, `status` (`active`/`completed`/`paused`/`expired`), `progress` (0–100), `source`, `lastActiveAt?`, `completedAt?`, `expiresAt?` *(F0)*, `lastLessonId?` | unique (`studentId`,`courseId`); index `courseId` |
| `LessonProgress` | `studentId`, `lessonId`, `state` (`not-started`/`in-progress`/`completed`; `locked` is derived, never stored), `fraction?`, `positionSec?`, `completedAt?`, `lastAccessedAt` *(F0)* | unique (`studentId`,`lessonId`) |
| `LessonNote` | composite id (`studentId`,`lessonId`), `text`, `savedAt` | |
| `LessonBookmark` | composite id (`studentId`,`lessonId`) | |
| `SavedCourse` | composite id (`studentId`,`courseId`), `savedAt` | |
| `Quiz` | `courseId`, `chapterId?`, `lessonId?` (unique), `title`, `instructions`, `status`, `questionsJson`, `settingsJson`, `createdAt`, `updatedAt` | index `courseId`; many `QuizAttempt` |
| `QuizAttempt` | `quizId`, `studentId`, `answersJson`, `resultJson`, `percent`, `passed`, `createdAt`, `durationSec?` *(F0)* | indexes `quizId`, `studentId` |
| `CourseAssignment` | `courseId`, `chapterId?`, `lessonId?` (unique), `title`, `instructions`, `attachmentsJson`, `format`, `wordLimit?`, `dueJson`, `acceptsLate`, `latePenalty`, `rubricJson`, `maxScore`, `passMark`, `status`, timestamps | index `courseId`; many `Submission` |
| `Submission` | `assignmentId`, `studentId`, `attempt`, `submittedAt`, `late`, `text?`, `filesJson`, `chartJson?`, `reviewStatus`, `reviewerId?`, `scoresJson`, `points?`, `score?`, `feedback`, `privateNote?`, `reviewUpdatedAt?` | indexes `assignmentId`, `studentId` |
| `AssignmentDraft` *(F0)* | composite id (`studentId`,`assignmentId`), `text`, `filesJson`, `chartJson?`, `savedAt` | |

### Certificates

| Model | Key fields | Relations |
| --- | --- | --- |
| `CertificateTemplate` | `name`, `style`, `accent`, `heading`, `statement`, `signatoriesJson`, `showScore`, `showHours`, `isDefault`, `updatedAt` | many `IssuedCertificate`, `Course` |
| `IssuedCertificate` | `credentialId` (unique), `studentId`, `courseId`, `title`, `templateId`, `status` (`pending`/`issued`/`revoked`), `completedAt`, `issuedAt?`, `revokedAt?`, `revokedReason?`, `finalScore?`, `hours`, `verifications` | indexes `studentId`, `courseId` |

### Live classes & calendar

| Model | Key fields | Relations |
| --- | --- | --- |
| `LiveClass` | `courseId`, `title`, `instructorId`, `startsAt`, `durationMin`, `capacity?`, `cancelled`, `cancelReason?`, `recordingJson?`, `description?`, `agendaJson`, `visibility`, `meetingJson`, `remindersJson`, `chapterId?` | indexes `courseId`, `instructorId`; many `LiveRegistration` |
| `LiveRegistration` | composite id (`liveClassId`,`studentId`), `registeredAt`, `attended?` | |
| `CalendarEvent` | `type`, `title`, `description?`, `timing`, `startsAt`, `durationMin?`, `courseId?`, `chapterId?`, `instructorId?`, `quizId?`, `milestone?`, `audience?`, `ownerId?` (**User id**, cascade), `notifyMin?`, `done`, `cancelled`, `sourceJson?` | indexes `courseId`, `startsAt`, `ownerId` |

Live classes and assignment deadlines are **derived** calendar rows (ids `live-<id>` / `assignment-<id>`), not stored.

### Notifications & settings

| Model | Key fields | Notes |
| --- | --- | --- |
| `AppNotification` | `recipientId` (**User id**, cascade), `category`, `title`, `summary`, `bodyJson`, `createdAt`, `readAt?`, `important`, `actor?`, `factsJson?`, `actionJson?`, `secondaryActionJson?` | index (`recipientId`,`createdAt`) |
| `NotificationSettings` | id = `userId` (**User id**, cascade), `categoriesJson`, `emailDigest`, `quietHoursJson`, `pausedUntil?`, `smsNumber` | |
| `Settings` | singleton `id = 1`; one `*Json` column per section (`general`, `courses`, `learning`, `certificates`, `notifications`, `appearance`), `updatedAtJson`, `updatedByJson` | |
| `PasswordResetToken` | `userId` (User, cascade), `tokenHash` (unique, SHA-256), `expiresAt` (1 h forgot-password, 7 d invitation), `usedAt?`, `createdAt` | index `userId` |
| `EmailOutbox` | `toEmail`, `toName?`, `subject`, `text`, `templateKey`, `status` (`queued`/`sent`/`failed`), `error?`, `createdAt`, `sentAt?` | indexes (`status`,`createdAt`), `toEmail` |
| `MediaAsset` | `ownerUserId`, `kind` (`video`/`document`/`image`), `originalName`, `mime`, `sizeBytes`, `storageName` (unique), `createdAt` | index `ownerUserId`; files under `UPLOAD_DIR` |

### Help centre

| Model | Key fields |
| --- | --- |
| `HelpCategory` | `name`, `description`, `icon`, `order` |
| `HelpArticle` | `slug` (unique), `categoryId`, `title`, `summary`, `body`, `audience`, `tagsJson`, `readMinutes`, `updatedAt`, `popular` |

## Tables added after the sections above (SAAS-019 … October 2026)

Field lists are in `apps/api/prisma/schema.prisma`, where each of these models carries a doc comment. What matters
here is who owns the row and what the table is for.

### Identity, sessions and delivery

| Model | Owner | Purpose |
| --- | --- | --- |
| `User` (changed) | academy (`tenantId`, required) | `role` now includes `superadmin` (platform; `tenantId` still points at Tenant #1), `deactivatedAt?` for admins |
| `AdminPermission` | academy | One row per (admin, permission key) from the 24-key catalogue; read on every request by `requirePermission` |
| `UserSession` (SAAS-020) | academy | A sign-in. The JWT's `sid` must name an open row; logout, logout-all, a password change or reset close them |
| `DeviceToken` (SAAS-021) | academy | A push-capable device bound to the session that registered it (`POST /notifications/devices`) |
| `PushDelivery` (SAAS-021) | academy | One push hint per in-app notification (`{ notificationId, category }` only), held through quiet hours unless important, sent via FCM when configured |
| `JobLease` (SAAS-022) | platform | One row per scheduled job; a process must hold the lease to run it, so several processes never run one job at once. Shown on `GET /superadmin/system` |
| `PasswordResetToken` (changed) | academy | Also carries the 7-day `instructor-invite` and `learner-invite` set-password links |

### Self-registration, invitations and inquiries

| Model | Owner | Purpose |
| --- | --- | --- |
| `PendingSignup` (SAAS-026) | platform | An Admin registering at `/get-started`: hashed password, HMAC-hashed 6-digit code bound to the row, attempts, expiry, resend time, `consumedAt`, `createdAcademyId`, and the chosen `planId`/`cycle` (SAAS-031). Consumed once; provisioning goes through `lib/academies.ts` |
| `PendingAccount` (23 Oct 2026) | academy (fixed by the server; a trigger keeps academy, role and address from changing) | A learner or instructor who registered through a join link, invitation, course link, host sign-up or request to teach, waiting for their emailed code. Hashed password and code; nothing that can sign in exists until the code is confirmed |
| `Invitation` (5 Oct 2026) | academy | An Admin's invitation for one learner (`/invite/<token>`). Only the SHA-256 of the token is stored; scoped to the Admin's workspace and role, expires, used once, revocable |
| `Instructor` (changed) | academy | `status` gains `pending` for a self-registered instructor awaiting an admin's approval; sign-in and every request refuse a pending profile |
| `Inquiry` (SAAS-027/029) | tenant-or-platform (`tenantId` null for a website request) | A demo, sales or support request from the website, or an academy admin's support request; kind, status, the team's private note (never shown to the academy). No-delete trigger |

### Learning additions

| Model | Owner | Purpose |
| --- | --- | --- |
| `Course` (changed) | academy | `coverImageId?` → `MediaAsset` (9 Oct 2026), set null on delete; `priceAmount` is whole rupees, all-inclusive |
| `QuizSession` (14 Oct 2026) | academy | A learner's attempt from the moment the server starts it: starting consumes an attempt; the deadline is the server's clock plus the quiz's `timeLimit`; the answer sheet is stored with a sequence number that only grows; finishing (submitted, or expired and closed by the scheduler) writes the `QuizAttempt` once |
| `LiveClass` (changed, 15 Oct 2026) | academy | `startedAt?`/`endedAt?` (the built-in room's session), `roomName?` (unique, unguessable), `recordingJson?` (the kept recording: only `durationMin`, `availableUntil` and `status` leave the API) |

### Course sales (24 Oct 2026)

| Model | Owner | Purpose |
| --- | --- | --- |
| `AcademyPaymentConfig` | academy (one row) | The academy's own online payments for course sales: gateway, environment (test/live), enabled. The money settles to the academy's account, never the platform's |
| `AcademyGatewayCredential` | academy, per environment | The academy's gateway key id, key secret and webhook secret, encrypted under `PAYMENT_CREDENTIALS_KEY` like the platform's; replaced in place, never returned or logged |
| `CoursePurchase` | academy | A learner's purchase of one paid course: one gateway order priced by the server; `created` until the gateway confirms, `paid` opens the enrolment once, `failed`/`expired` open nothing. Amount, currency, learner, course and order are immutable (trigger) |
| `CoursePaymentEvent` | academy | A course-payment webhook already received, unique per (academy, provider, event id), so a redelivery or replay changes nothing |

### Platform

| Model | Owner | Purpose |
| --- | --- | --- |
| `PlatformBrandAsset` (10 Oct 2026) | platform | The uploaded logo or favicon (at most one row per kind); see *Platform branding* above |
| `Settings` (changed) | academy (one row per academy, SAAS-000) | No longer a singleton; `appearanceJson` holds the academy's own look, separate from platform branding |

## Affiliate program (MLM-000, 31 Oct 2026)

Platform-owned (no `tenantId`); the program's academy is `MlmPlanVersion.programTenantId` → `Tenant`. Migration
`20261031120000_mlm_plan`. Amount columns are 64-bit integers in paise.

| Model | Purpose |
| --- | --- |
| `MlmPlanVersion` | One version of the plan: every compensation term as a column (`cvBasisPoints`, `matchingRateBps`, `payoutCeilingBps`, `normalPayoutBps`, run hour, eligibility delay, cap-overflow and carry-forward policies, spillover rule, withdrawal minimum and KYC gate, TDS, liability period), `eligibleCourseIdsJson`, `status` (`draft`/`active`/`retired`), `version` (unique, ascending). Triggers: one active version; status forward only; terms sealed once out of draft (the course list alone may change while active); a used version is never deleted |
| `MlmRankTier` | A version's rank: `order`, `name`, `groupCv` (even; half per leg), `rewardKind`, `rewardAmount`, `rewardCapAmount?`, `capBandKey`, `vestingDays`. Sealed with its version |
| `MlmCapBand` | A version's daily matching cap band: `key`, `label`, `dailyCap`, `order`. Sealed with its version |

Academy-owned (MLM-001, migration `20261031130000_mlm_affiliates`):

| Model | Purpose |
| --- | --- |
| `Affiliate` | A learner of the program academy in the program: `userId`/`studentId` (unique), `code` (unique across the platform; the referral credential), `status`, `sponsorId` (who referred them) and, separately, `placementParentId` + `placementLeg` (where they sit; unique per parent and leg), `pathIdsJson`/`depth` (ancestor path, written by the genealogy module), `preferredLeg`, `activatedAt`/`activationPurchaseId`, `kycStatus`, `currentRankOrder`. Triggers: academy, person and code fixed; termination final; sponsor and parent in the same academy; never deleted |
| `PendingAccount` (changed) | `referralCode?`, `preferredLeg?`: the referral a registrant arrived with, applied when the code is confirmed |
| `MlmPlacementHistory` (MLM-002, migration `20261031140000_mlm_placement`) | Every placement and move of an affiliate, append-only (triggers): `fromParentId`/`fromLeg`, `toParentId`/`toLeg`, `reason` (`sponsor-direct`/`spillover`/`manual`/`root`), `actorType`/`actorId`, `note` |
| `MlmOrder` (MLM-003, migration `20261031150000_mlm_cv`) | One per verified `CoursePurchase` of an eligible course (`purchaseId` unique): `buyerStudentId`, `buyerAffiliateId?`, `sponsorCodeAtSale?`, `courseId`, `planVersionId`, `netAmount`/`cv` (BigInt paise), `currency`, `status` (`pending` → `eligible` → `reversed`; `reversed` final), `paidAt`, `eligibleAt?`, `reversedAt?`/`reversalReason?`, `creditedAncestors`. Triggers: the money, course, buyer and plan fixed; a reversed order final; never deleted |
| `MlmCvLedger` (MLM-003) | The immutable CV ledger: one row per (order, ancestor, kind) — `affiliateId`, `orderId`, `leg`, `kind` (`sale` positive, `reversal` negative; CHECK on the sign), `amount` (BigInt). Triggers: never updated, never deleted |
| `MlmLegBalance` (MLM-003) | One row per affiliate (`affiliateId` PK): `lifetimeA/B` (every eligible sale, for ranks), `unmatchedA/B` (the carry-forward pools the matching run draws on), `matchedLifetime`, `lastMatchingRunDate?`, `version` (optimistic lock for the matching job). Every change is the sum of ledger rows |

## Planned schema changes (F0) — status

| Change | Reason | Status |
| --- | --- | --- |
| `AppNotification.recipientId`, `NotificationSettings.userId`, `CalendarEvent.ownerId` → reference `User` | The UI sends `user.id`; staff have no `Student` row | DONE (F0, migration `20260917144129_init`) |
| `LessonProgress.lastAccessedAt` | Learner home "recently accessed" and last-lesson tracking | DONE (F0 column; written from F6) |
| `AssignmentDraft` | Drafts are currently acknowledged but not stored | DONE (F0 table; used from F6) |
| `PasswordResetToken`, `EmailOutbox` | Forgot/reset password, outgoing mail | DONE (F1, migration `20260917144916_password_reset_and_email_outbox`) |
| `MediaAsset` + `MediaFile.url` | Real uploads | DONE (F5, migration `20260917151716_media_assets`) |
| `QuizAttempt.durationSec` | Median time in quiz results | DONE (F0 column; written from F6/F7) |
| `Enrollment.expiresAt` | Access length (`settings.general.accessMonths`) | DONE (F0 column; written from F6) |
| `User.updatedAt` | Standard timestamp | DONE (F0) |
| Migrations baseline | Reproducible deploys | DONE — `prisma migrate deploy` applies `apps/api/prisma/migrations/`; `npm test` rebuilds `test.db` from them |

## Seed data

`apps/api/prisma/seed.ts` clears every table and creates: 3 levels, 3 ranks, 3 categories, 3
instructors (2 with accounts), 1 admin, 8 students (all with accounts, password `syniastrolms123`), 6
published courses with hand-written chapters/lessons (video, reading, practice, assessment, assignment),
an assessment quiz per chapter, an assignment per assignment lesson, enrollments with progress, quiz
attempts, a waiting and a graded submission, 3 issued/pending certificates, 3 templates, 2 live classes,
2 help categories/articles, academy settings and 2 notifications.
