# SaaS Subscription, Plans, Billing & Entitlements — Full-Stack Specification

## 0. How this phase runs

This is **not** the UI-only workflow. `.claude/workflow.md`, `.claude/project.md` and
`.claude/modules.json` (`scope: UI_ONLY`) govern the LMS UI build, which is finished. This phase has
its own module list at `.claude/saas/modules.json` (`scope: FULL_STACK`) and explicitly permits what
the UI workflow forbids: backend code, database migrations, tenant architecture, authentication and
authorization changes, payment-provider integration, webhooks and background jobs.

**Starting point.** `LMS-019` shipped a UI-only prototype of these screens at
`/superadmin/subscriptions` (see `.claude/ui/subscriptions.md` and the LMS-019 entry in
`.claude/progress.md`). Its plans, subscribers, invoices and actions are in-memory fixtures served by
`services/mock/subscriptions.ts` in both API modes, because no endpoint exists. That prototype is the
target design for the screens; this document is the system behind them. Phase G replaces the mock
service with the real API and the screens should not need redesigning.

**Working rules for this phase**

1. Read `docs/01-PROJECT-ARCHITECTURE.md`, `docs/03-DATABASE-SPECIFICATION.md`,
   `docs/04-AUTHENTICATION-AUTHORIZATION.md`, `docs/05-API-SPECIFICATION.md`,
   `docs/09-SECURITY.md` and `docs/11-SUPERADMIN-FLOW.md` before writing code. This system sits on
   top of all of them.
2. One module at a time, in dependency order, from `.claude/saas/modules.json`.
3. Every module must pass `npm run typecheck`, `npm run lint`, `npm test`, `npm run build` and
   `npm run format:check`, plus the API's own test suite, before it is marked completed.
4. Migrations are backward-safe. Enforcement ships behind a flag and is turned on deliberately
   (§50), never as a side effect of a migration.
5. Financial history is append-only. Nothing in this phase may delete a payment, an invoice, a
   webhook event or a lifecycle record.
6. A module is completed only when its database, backend, API, frontend integration, tests and audit
   entries are all in place — the same bar as `docs/02-MODULE-MASTER-LIST.md`.

---

## 1. Purpose

Build the real SaaS Subscription, Plans, Billing, Entitlements and Usage Enforcement system for
SyniastroLMS.

The final system must support:

- multiple academies/tenants
- subscription plans
- plan pricing and billing cycles
- trials
- active subscriptions
- upgrades and downgrades
- cancellation and reactivation
- grace periods
- payment attempts
- payment gateway integration through a provider abstraction
- invoices and payment records
- webhooks
- feature entitlements
- usage limits
- subscription enforcement
- tenant isolation
- subscription lifecycle history
- auditability
- Super Admin platform management
- Tenant Admin subscription visibility
- reliable handling of retries, duplicate webhooks and failed payments

**The frontend UI must never be the source of truth.**

## 2. Critical scope rule

The current LMS UI workflow is UI-only. This specification is for a separate full-stack SaaS phase.

Do not implement this specification inside the existing `UI_ONLY` workflow. A full-stack phase must
explicitly permit backend, database, tenant architecture, authentication/authorization changes,
payment integration and webhooks. §0 above is that permission, for this phase only.

## 3. SaaS mental model

```text
Platform
  |
  +-- Plans
  +-- Billing Configuration
  +-- Super Admin
          |
          v
      Tenants / Academies
          |
          +-- Tenant Admin
          +-- Instructors
          +-- Students
          +-- Courses
          +-- Subscription
                 |
                 v
                Plan
                 |
                 +-- Features
                 +-- Limits
```

A subscription belongs to a tenant/academy, **not** to an individual student or instructor.

## 4. Core entities

### Tenant

Represents one customer academy/organization.

Suggested fields: `id`, `name`, `slug`, `status`, owner/admin reference, `createdAt`, `updatedAt`.

Statuses: `active`, `suspended`, `archived`.

Tenant isolation must be enforced at the backend/database query boundary. A request must never read
or mutate another tenant's records by changing an ID in the URL.

### Plan

A platform-level commercial offering.

Suggested fields: `id`, `name`, `code`, `description`, `status`, `displayOrder`, `monthlyPrice`,
`annualPrice`, `currency`, `trialDays`, limits, feature entitlements, `createdAt`, `updatedAt`,
`archivedAt`.

Statuses: `draft`, `active`, `archived`.

Plan codes must be unique. Archived plans remain available for historical subscriptions but cannot
be selected for new subscriptions.

### Plan versioning

Plan changes must not silently rewrite historical subscriptions.

Prefer immutable/versioned commercial configuration. At minimum, historical subscription, invoice
and payment records must preserve the applicable price and terms.

### Features and entitlements

Do not hard-code plan access throughout the application. Create a central entitlement catalogue, for
example:

- `courses.manage`
- `assessments.manage`
- `certificates.manage`
- `live_classes`
- `reports.basic`
- `reports.advanced`
- `analytics.advanced`
- `custom_branding`
- `priority_support`

Each plan grants or denies features. Never scatter plan-name checks such as
`if plan === "Professional"` throughout the application.

### Usage limits

Centralize limits such as:

- `learners.max`
- `instructors.max`
- `courses.max`
- `storage.bytes`
- `live_classes.max`
- `admin_accounts.max`

Track configured limit, current usage and remaining capacity.

## 5. Subscription model

Suggested fields: `id`, `tenantId`, `planId`, plan version/reference where applicable, `status`,
`billingCycle`, `currency`, `amount`, `trialStartAt`, `trialEndAt`, `currentPeriodStartAt`,
`currentPeriodEndAt`, `cancelAtPeriodEnd`, `canceledAt`, `cancellationReason`, `gracePeriodEndAt`,
`provider`, `providerCustomerId`, `providerSubscriptionId`, `createdAt`, `updatedAt`.

Statuses: `trialing`, `active`, `past_due`, `paused`, `canceling`, `canceled`, `expired`.

Arbitrary status updates must not be allowed. State transitions must be enforced by backend business
rules.

## 6. Subscription state machine

```text
trialing
  |
  +-- payment success --> active
  +-- trial expires ---> expired / past_due

active
  |
  +-- payment success --> active
  +-- payment failure -> past_due
  +-- cancel request --> canceling
  +-- pause ----------> paused

past_due
  |
  +-- payment success --> active
  +-- retries/grace exhausted --> expired/restricted

canceling
  |
  +-- resume ----------> active
  +-- period ends -----> canceled

paused
  |
  +-- resume ----------> active
```

Exact business transitions must be documented before production.

## 7. Trial

Trial configuration belongs to the plan. Store `trialStartAt`, `trialEndAt` and trial status.

Trial expiry must be backend controlled. **Never trust the frontend clock.**

Prevent unlimited repeated trials for the same tenant unless explicitly allowed.

## 8. Grace period

A payment failure should not automatically destroy access unless that is the defined business rule.

```text
Payment failed
  -> past_due
  -> retry
  -> success: active
  -> retries exhausted: grace period
  -> grace expired: restricted/expired
```

Grace duration must be configurable, and timestamps and reasons must be stored.

## 9. Billing cycles

Initially support `monthly` and `annual`. The architecture should allow future cycles.

All billing calculations are server-side.

## 10. Upgrade

The implementation must explicitly define: immediate vs next-cycle upgrade, proration, effective
date, payment requirement, entitlement activation.

A safe initial model is **immediate activation only after successful payment confirmation**.

Never update entitlements based only on a frontend success callback.

## 11. Downgrade

Downgrades can create usage-limit conflicts:

```text
Current usage: 1,200 learners
New plan limit: 500
```

Do not delete existing data automatically. Recommended behavior:

- downgrade becomes effective according to the defined policy, usually next billing period
- existing data remains
- new usage that exceeds the new limit is restricted
- the tenant is informed of the conflict

## 12. Cancellation and reactivation

Support: cancel immediately, cancel at period end, resume before effective cancellation when
allowed.

Record: actor, timestamp, reason, effective date.

A fully canceled subscription should normally be replaced by a new subscription rather than mutating
financial history.

## 13. Payment provider architecture

Use a provider abstraction instead of coupling the LMS directly to one gateway.

```text
PaymentProvider
  +-- createCustomer()
  +-- createSubscription()
  +-- cancelSubscription()
  +-- pauseSubscription()
  +-- resumeSubscription()
  +-- changePlan()
  +-- createPayment()
  +-- refundPayment()
  +-- verifyWebhook()
```

Possible adapters: `RazorpayProvider`, `StripeProvider`. Select the actual provider based on
deployment/business requirements. Do not integrate multiple gateways without a product requirement.

## 14. Payment records

Payment records are **immutable historical records**.

Suggested fields: `id`, `tenantId`, `subscriptionId`, `provider`, `providerPaymentId`, `amount`,
`currency`, `status`, `failureCode`, `failureMessage`, `paidAt`, `refundedAt`, `createdAt`.

Statuses: `pending`, `paid`, `failed`, `refunded`, `partially_refunded`.

Never overwrite a successful payment to represent a later event.

## 15. Invoices

Suggested fields: `id`, `tenantId`, `subscriptionId`, `invoiceNumber`, `billingPeriodStart`,
`billingPeriodEnd`, `subtotal`, `tax`, `total`, `currency`, `status`, `issuedAt`, `paidAt`, `dueAt`,
`providerInvoiceId`.

Invoice numbers must be unique. Historical invoices must not change when a plan changes.

## 16. Payment methods

**Never store raw card details.** Store only provider-safe references and masked display metadata,
such as `Visa •••• 4242` or `UPI`.

## 17. Webhooks

Webhook processing is mandatory for reliable subscription state. Typical events:

- payment succeeded / failed
- subscription created / updated / canceled
- invoice created / paid / failed
- refund created

Provider event names vary. Processing must:

1. verify the provider signature
2. validate the payload
3. identify the event
4. enforce idempotency
5. persist the receipt
6. update internal state transactionally
7. record audit/event information
8. return the correct response

**Never trust an unsigned webhook.**

## 18. Webhook idempotency

Persist webhook events with: `provider`, `providerEventId`, `eventType`, `receivedAt`, `processedAt`,
`status`, payload/reference.

Unique constraint: `provider + providerEventId`.

If an event has already been processed, do not repeat side effects.

## 19. Subscription lifecycle events

Record: `subscription.created`, `subscription.trial.started`, `subscription.activated`,
`subscription.plan_changed`, `subscription.payment.succeeded`, `subscription.payment.failed`,
`subscription.past_due`, `subscription.paused`, `subscription.resumed`,
`subscription.cancel.requested`, `subscription.canceled`, `subscription.expired`.

Store tenant, subscription, actor/source, event, timestamp and metadata/reference.

## 20. Tenant isolation

Every tenant-owned resource must have a tenant boundary: courses, lessons, students, instructors,
enrollments, certificates, subscriptions, invoices, payments, usage.

Tenant identity must come from authenticated server context, **not** an arbitrary client-supplied
`tenantId`. Super Admin is the controlled platform-level exception.

## 21. Subscription enforcement

Subscription state must eventually control access:

```text
Subscription expired
  -> tenant enters restricted mode
  -> existing data remains according to policy
  -> new learner creation blocked
  -> upgrade prompt shown
```

Do not blindly block all access. Define policies for read, create, update, publishing, live classes,
advanced reports, storage, and learner/instructor creation.

## 22. Entitlement service

Create a central service:

```text
getTenantEntitlements(tenantId)
hasFeature(tenantId, featureKey)
getLimit(tenantId, limitKey)
getUsage(tenantId, limitKey)
canConsume(tenantId, limitKey, amount)
```

All modules should use this service. Do not independently inspect subscription tables in every
controller.

## 23. Usage tracking

Track measurable usage: learners, instructors, courses, storage, admin accounts, live sessions.

Define whether each metric is live-calculated, cached, counter-based or periodically reconciled.

Concurrent operations must not allow a tenant to exceed a hard limit because two requests checked the
same stale usage.

## 24. Tenant Admin experience

Tenant Admin should see: current plan, subscription status, billing cycle, renewal date, usage,
enabled features, invoices, payment history, upgrade options.

Tenant Admin must not manage platform plans or another tenant.

## 25. Super Admin experience

Super Admin can manage platform-level: plans, plan pricing, plan limits, plan features, plan status,
subscriber/tenant subscriptions, billing records, payment state, lifecycle history.

Sensitive financial actions such as forced cancellation or refund require explicit business rules and
audit logging.

## 26. Money handling

Represent monetary values in the smallest currency unit where appropriate. For INR:

```text
₹3,999
stored as
399900 paise
```

Do not use floating-point arithmetic for financial totals. The client must never control the final
payable amount.

> Migration note: the LMS-019 prototype stores whole rupees as plain numbers
> (`packages/domain/src/subscription.ts`). Converting to the smallest unit is part of Phase B/D and
> must be done in one deliberate migration, not gradually.

## 27. Tax

Keep tax separate from base pricing. Potential data: tax type, tax percentage, tax amount,
tax-inclusive flag, billing address, tax registration/GST information where applicable.

Do not hard-code country-specific tax rules into generic subscription logic.

## 28. Currency

Currency belongs to the price/subscription/invoice context. Initial deployment may use INR, but the
data model should not make future currencies impossible.

## 29. Refunds

Represent refunds as separate financial events. Support full refund and, where provider/business
rules permit, partial refund. **Never delete the original payment.**

## 30. Background jobs

Subscription systems require reliable time-based processing:

- `trial-expiry-check`
- `subscription-renewal-check`
- `past-due-retry`
- `grace-period-expiry`
- `scheduled-cancellation`
- `usage-reconciliation`
- `webhook-retry`
- `invoice-generation`

Jobs must be idempotent, retryable, observable and safe to run more than once.

## 31. Notifications

Subscription events may trigger: trial ending soon, payment successful, payment failed, past due,
renewal upcoming, cancellation scheduled, canceled, plan changed, limit approaching.

Notifications must originate from backend events rather than frontend clicks alone. Reuse the
existing notification engine (phase F12) rather than building a second one.

## 32. API design

Platform APIs:

```text
GET    /superadmin/plans
POST   /superadmin/plans
GET    /superadmin/plans/:id
PATCH  /superadmin/plans/:id
POST   /superadmin/plans/:id/archive
POST   /superadmin/plans/:id/restore

GET    /superadmin/subscriptions
GET    /superadmin/subscriptions/:id

GET    /superadmin/payments
GET    /superadmin/invoices
```

Tenant APIs:

```text
GET    /tenant/subscription
GET    /tenant/subscription/usage
GET    /tenant/subscription/entitlements
GET    /tenant/invoices
GET    /tenant/payments

POST   /tenant/subscription/upgrade
POST   /tenant/subscription/downgrade
POST   /tenant/subscription/cancel
POST   /tenant/subscription/resume
```

Webhook:

```text
POST /webhooks/:provider/subscription
```

Use existing route conventions where they differ — see `docs/05-API-SPECIFICATION.md`.

## 33. Authorization order

Keep role/permission authorization separate from subscription entitlement:

```text
Authenticated
  -> role/permission check
  -> tenant isolation check
  -> subscription/entitlement check
  -> business operation
```

Subscription status must never replace authorization.

## 34. Error model

Use stable machine-readable errors: `SUBSCRIPTION_REQUIRED`, `SUBSCRIPTION_PAST_DUE`,
`SUBSCRIPTION_EXPIRED`, `FEATURE_NOT_INCLUDED`, `LIMIT_REACHED`, `PAYMENT_REQUIRED`,
`PAYMENT_FAILED`, `PLAN_UNAVAILABLE`, `INVALID_SUBSCRIPTION_STATE`.

Do not expose provider or database internals.

## 35. Security requirements

Mandatory: tenant isolation · server-side authorization · webhook signature verification · webhook
idempotency · no raw card storage · no client-controlled pricing · no client-controlled tenant
identity · no client-controlled subscription status · no client-controlled entitlement grants · audit
sensitive mutations · server-side monetary validation · duplicate-subscription protection · refund
authorization · webhook replay protection.

## 36. Audit requirements

Audit at minimum: `plan.created`, `plan.updated`, `plan.archived`, `plan.restored`,
`subscription.created`, `subscription.plan_changed`, `subscription.cancel_requested`,
`subscription.canceled`, `subscription.resumed`, `subscription.paused`, `payment.succeeded`,
`payment.failed`, `payment.refunded`, `invoice.created`, `invoice.paid`, `invoice.failed`,
`entitlement.changed`, `limit.changed`.

System-generated events should identify themselves as system/provider events. Extend the existing
audit log (`apps/api/src/lib/audit.ts`) rather than starting a second one.

## 37. Database integrity

Important constraints: unique plan code · unique tenant slug · unique provider customer reference
where appropriate · unique provider subscription reference · unique provider payment reference ·
unique provider webhook event · valid foreign keys · tenant-scoped indexes · timestamps.

Do not use destructive cascades that can erase financial history accidentally.

## 38. Historical data

Financial history must survive plan edits, plan archival, tenant suspension, subscription
cancellation and user removal.

Do not delete paid payments, invoices, webhook events or subscription lifecycle history.

## 39. Existing LMS migration

The current single-academy LMS must be migrated safely:

```text
Existing Academy
  -> initial Tenant
  -> existing users assigned
  -> existing courses assigned
  -> existing records assigned
```

Do not enable tenant enforcement before existing records have valid tenant relationships.

## 40. Existing role architecture

Current roles remain conceptually `Super Admin`, `Admin`, `Instructor`, `Student`. Future SaaS
structure:

```text
Super Admin  -> Platform
Tenant Admin -> Academy
Instructor   -> Academy
Student      -> Academy
```

Do not rename the existing `admin` role to `tenantAdmin` without an explicit migration plan. The role
is used by `packages/domain/src/identity.ts`, the API's scope layer and the web app's navigation and
permission gating.

## 41. Permissions integration

Subscription entitlements do not replace the existing granular Admin permission system.

```text
Admin permission: courses.edit       = true
Tenant entitlement: courses.manage   = false
Final result: DENIED
```

Both permission and entitlement must pass. The permission catalogue is
`packages/domain/src/permission.ts`.

## 42. Plan enforcement matrix

Before implementation, create a source-of-truth matrix:

| Capability | Permission | Plan entitlement | Limit |
| --- | --- | --- | --- |
| Create learner | `learners.enroll` | `learners.enabled` | `learners.max` |
| Create instructor | `instructors.manage` | `instructors.enabled` | `instructors.max` |
| Create course | `catalog.edit` | `courses.enabled` | `courses.max` |
| Live class | `live.manage` | `live_classes` | `live_classes.max` |
| Advanced reports | `reports.view` | `reports.advanced` | — |
| Branding | `settings.edit` | `custom_branding` | — |

Verify every permission key against `packages/domain/src/permission.ts` before relying on this table.

## 43. Payment flow

```text
Tenant selects plan
  -> backend validates plan
  -> backend calculates payable amount
  -> payment provider order/subscription created
  -> frontend opens provider checkout
  -> payment completed
  -> provider webhook
  -> webhook verified
  -> payment recorded
  -> subscription activated
  -> entitlements updated
  -> tenant access updated
```

**A frontend success callback alone must never activate a subscription.**

## 44. Failed payment flow

```text
Renewal
  -> payment attempt
  -> failed
  -> record failure
  -> past_due
  -> retry
  -> success: active
  -> retries exhausted
  -> grace period
  -> restricted/expired
```

## 45. Plan change flow

```text
Current Plan
  -> select New Plan
  -> backend validates
  -> calculate price difference
  -> create required payment/change
  -> provider confirmation
  -> webhook
  -> update subscription
  -> update entitlements
  -> audit/history
```

## 46. Migration strategy

Recommended order, each backward-safe where possible:

1. Tenant foundation
2. Plan tables
3. Feature catalogue
4. Plan entitlements
5. Subscription table
6. Subscription lifecycle events
7. Payment records
8. Invoice records
9. Webhook events
10. Usage tracking
11. Audit extensions
12. Provider references

## 47. Testing

**Unit:** subscription state transitions · price calculations · entitlement checks · limit checks ·
trial expiry · grace period · cancellation · upgrade · downgrade · tax calculation · refund
calculation · webhook idempotency.

**Integration:** tenant isolation · subscription APIs · payment records · webhook processing ·
entitlement enforcement · usage enforcement.

**Security:** cross-tenant access · forged tenant IDs · unauthorized plan changes · unauthorized
refunds · forged webhook · duplicate webhook · expired-subscription bypass · client-modified price ·
client-modified plan · client-modified entitlement.

**Regression:** existing Super Admin, Admin, Instructor and Student workflows must continue to work,
including the 239 tests and the route crawl recorded in `.claude/progress.md`.

## 48. Observability

Track: payment failures · webhook failures · subscription state changes · job failures · entitlement
failures · limit violations.

Never log: payment secrets · webhook secrets · raw card information · passwords · authentication
tokens.

## 49. Deployment

Before production: configure provider credentials through secrets · configure the webhook URL ·
configure the webhook signing secret · enable HTTPS · enable background job processing · configure
backups · test migrations · test webhook retries · test payment failures · test recovery scenarios.

**Never commit secrets.** See `docs/10-DEPLOYMENT.md` and `deploy/`.

## 50. Rollout

```text
Development
  -> Staging
  -> Internal tenant
  -> Limited production tenants
  -> Full rollout
```

Use feature flags for enforcement rollout where appropriate.

## 51. Explicitly out of scope

Do not silently add: marketplace billing · affiliate commissions · reseller billing · complex
usage-based metering beyond defined limits · multi-currency settlement · revenue recognition ·
accounting integrations · GST filing automation · chargeback management · tax filing · financing ·
coupons · referral programs · wallet system.

Each requires a separate specification.

## 52. Implementation phases

| Phase | Name | Covers |
| --- | --- | --- |
| A | SaaS tenant foundation | tenant model, tenant context, tenant isolation, existing-academy migration |
| B | Plan & entitlement engine | plans, plan versions, feature catalogue, limits, entitlement service |
| C | Subscription engine | subscription model, state machine, trials, grace period, cancellation, upgrade/downgrade |
| D | Billing engine | payment records, invoices, provider abstraction, payment flow |
| E | Webhooks | endpoint, signature verification, idempotency, lifecycle synchronization |
| F | Usage enforcement | usage calculation/counters, concurrency-safe limits, feature enforcement, restricted mode |
| G | Frontend integration | replace the mock subscription services with real APIs |
| H | Hardening | security audit, tenant isolation audit, payment audit, webhook replay tests, failure recovery, migration verification, production readiness |

`.claude/saas/modules.json` breaks these phases into the modules that are actually worked on, in
dependency order.

## 53. Definition of done

The real subscription system is complete only when:

- tenants are isolated
- plans are database-backed
- features are centrally defined
- limits are centrally defined
- subscriptions are database-backed
- lifecycle transitions are enforced
- trials are server-side
- cancellation is server-side
- upgrade/downgrade rules are defined
- the payment provider is integrated through an abstraction
- payment records are immutable
- invoices are persisted
- webhooks are verified
- webhook processing is idempotent
- usage limits are enforced server-side
- entitlements are enforced server-side
- tenant isolation tests pass
- payment failure tests pass
- duplicate webhook tests pass
- audit logging exists
- existing LMS regression tests pass
- Super Admin platform access works
- Tenant Admin subscription access works
- secrets are protected
- production deployment is tested

## 54. Final architecture principle

The subscription system is not just a collection of billing screens. The platform control chain is:

```text
Plan
  ↓
Entitlements + Limits
  ↓
Subscription
  ↓
Tenant
  ↓
Authorization + Entitlement + Usage checks
  ↓
LMS functionality
```

The frontend is the presentation layer. The backend, database, payment-provider events, entitlement
service and tenant isolation are authoritative.
