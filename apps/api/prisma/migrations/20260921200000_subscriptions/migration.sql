-- SAAS-004 · Subscriptions and their lifecycle (subscriptions.md §5, §6, §19, §35, §37, §38).
--
-- Subscription is academy-owned (tenantId, RESTRICT) and holds the plan version it was sold, so its price
-- and allowance survive any plan edit. SubscriptionEvent is its append-only lifecycle log.
--
-- The state machine lives in packages/domain/src/lifecycle.ts, and the database holds the same table, so
-- that no code path, raw SQL included, can move a status any other way:
--   - a subscription is created only as 'trialing' or 'active';
--   - a status change is refused unless the latest lifecycle event records exactly that change, and an
--     event is refused unless it starts from the subscription's current status and is an allowed pair;
--   - the plan version, amount, currency and cycle change only with a matching 'change_plan' event;
--   - lifecycle events are never updated or deleted, and subscriptions are never deleted;
--   - an academy has at most one live subscription (duplicate-subscription protection, §35).
-- src/lib/subscriptions.test.ts checks every status pair against the domain's table.

-- CreateTable
CREATE TABLE "Subscription" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "planVersionId" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "billingCycle" TEXT NOT NULL,
    "currency" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "trialStartAt" DATETIME,
    "trialEndAt" DATETIME,
    "currentPeriodStartAt" DATETIME NOT NULL,
    "currentPeriodEndAt" DATETIME NOT NULL,
    "cancelAtPeriodEnd" BOOLEAN NOT NULL DEFAULT false,
    "cancelRequestedAt" DATETIME,
    "canceledAt" DATETIME,
    "cancellationReason" TEXT,
    "pausedAt" DATETIME,
    "resumesAt" DATETIME,
    "gracePeriodEndAt" DATETIME,
    "provider" TEXT,
    "providerCustomerId" TEXT,
    "providerSubscriptionId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Subscription_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Subscription_planId_fkey" FOREIGN KEY ("planId") REFERENCES "Plan" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Subscription_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "PlanVersion" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Subscription_status_check" CHECK ("status" IN ('trialing', 'active', 'past_due', 'paused', 'canceling', 'canceled', 'expired')),
    CONSTRAINT "Subscription_billingCycle_check" CHECK ("billingCycle" IN ('monthly', 'annual')),
    CONSTRAINT "Subscription_currency_check" CHECK ("currency" GLOB '[A-Z][A-Z][A-Z]'),
    CONSTRAINT "Subscription_amount_check" CHECK (typeof("amount") = 'integer' AND "amount" >= 0),
    CONSTRAINT "Subscription_period_check" CHECK ("currentPeriodEndAt" > "currentPeriodStartAt"),
    CONSTRAINT "Subscription_trial_check" CHECK (("trialStartAt" IS NULL) = ("trialEndAt" IS NULL) AND ("trialEndAt" IS NULL OR "trialEndAt" > "trialStartAt"))
);

-- CreateTable
CREATE TABLE "SubscriptionEvent" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "tenantId" TEXT NOT NULL,
    "subscriptionId" TEXT NOT NULL,
    "event" TEXT NOT NULL,
    "transition" TEXT NOT NULL,
    "fromStatus" TEXT,
    "toStatus" TEXT NOT NULL,
    "actorType" TEXT NOT NULL,
    "actorId" TEXT,
    "source" TEXT,
    "metaJson" TEXT NOT NULL DEFAULT '{}',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "SubscriptionEvent_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "SubscriptionEvent_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "Subscription" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "SubscriptionEvent_actorType_check" CHECK ("actorType" IN ('user', 'system', 'provider')),
    CONSTRAINT "SubscriptionEvent_actor_check" CHECK ("actorType" <> 'user' OR "actorId" IS NOT NULL)
);

-- CreateIndex
CREATE INDEX "Subscription_tenantId_status_idx" ON "Subscription"("tenantId", "status");

-- CreateIndex
CREATE INDEX "Subscription_planVersionId_idx" ON "Subscription"("planVersionId");

-- CreateIndex
CREATE INDEX "Subscription_status_currentPeriodEndAt_idx" ON "Subscription"("status", "currentPeriodEndAt");

-- CreateIndex
CREATE UNIQUE INDEX "Subscription_provider_providerSubscriptionId_key" ON "Subscription"("provider", "providerSubscriptionId");

-- CreateIndex
CREATE INDEX "SubscriptionEvent_tenantId_createdAt_idx" ON "SubscriptionEvent"("tenantId", "createdAt");

-- CreateIndex
CREATE INDEX "SubscriptionEvent_subscriptionId_id_idx" ON "SubscriptionEvent"("subscriptionId", "id");

-- At most one live subscription per academy. A cancelled or expired one stays as history beside it.
CREATE UNIQUE INDEX "Subscription_one_live_per_tenant" ON "Subscription"("tenantId") WHERE "status" NOT IN ('canceled', 'expired');

-- A subscription starts as a trial or active, never in a later status.
CREATE TRIGGER "Subscription_initial_status" BEFORE INSERT ON "Subscription"
WHEN NEW."status" NOT IN ('trialing', 'active')
BEGIN
    SELECT RAISE(ABORT, 'A subscription starts as trialing or active');
END;

-- The version sold must be a version of the plan named.
CREATE TRIGGER "Subscription_version_of_plan_insert" BEFORE INSERT ON "Subscription"
WHEN (SELECT "planId" FROM "PlanVersion" WHERE "id" = NEW."planVersionId") IS NOT NEW."planId"
BEGIN
    SELECT RAISE(ABORT, 'The plan version does not belong to the plan');
END;

CREATE TRIGGER "Subscription_version_of_plan_update" BEFORE UPDATE OF "planId", "planVersionId" ON "Subscription"
WHEN (SELECT "planId" FROM "PlanVersion" WHERE "id" = NEW."planVersionId") IS NOT NEW."planId"
BEGIN
    SELECT RAISE(ABORT, 'The plan version does not belong to the plan');
END;

-- A status moves only through a transition the lifecycle log has just recorded.
CREATE TRIGGER "Subscription_status_by_transition" BEFORE UPDATE OF "status" ON "Subscription"
WHEN NEW."status" <> OLD."status" AND NOT EXISTS (
    SELECT 1 FROM "SubscriptionEvent" e
    WHERE e."id" = (SELECT max("id") FROM "SubscriptionEvent" WHERE "subscriptionId" = NEW."id")
      AND e."fromStatus" = OLD."status" AND e."toStatus" = NEW."status"
)
BEGIN
    SELECT RAISE(ABORT, 'A subscription status changes only through a recorded transition');
END;

-- What a subscription is sold — its plan version, amount, currency and cycle — changes only with a
-- change_plan event that names exactly the new terms.
CREATE TRIGGER "Subscription_terms_by_transition" BEFORE UPDATE OF "planId", "planVersionId", "amount", "currency", "billingCycle" ON "Subscription"
WHEN (NEW."planVersionId" IS NOT OLD."planVersionId" OR NEW."amount" IS NOT OLD."amount" OR NEW."currency" IS NOT OLD."currency" OR NEW."billingCycle" IS NOT OLD."billingCycle")
 AND NOT EXISTS (
    SELECT 1 FROM "SubscriptionEvent" e
    WHERE e."id" = (SELECT max("id") FROM "SubscriptionEvent" WHERE "subscriptionId" = NEW."id")
      AND e."transition" = 'change_plan'
      AND json_extract(e."metaJson", '$.to.planVersionId') = NEW."planVersionId"
      AND json_extract(e."metaJson", '$.to.amount') = NEW."amount"
      AND json_extract(e."metaJson", '$.to.currency') = NEW."currency"
      AND json_extract(e."metaJson", '$.to.billingCycle') = NEW."billingCycle"
)
BEGIN
    SELECT RAISE(ABORT, 'A subscription''s plan and price change only through a recorded plan change');
END;

CREATE TRIGGER "Subscription_no_delete" BEFORE DELETE ON "Subscription"
BEGIN
    SELECT RAISE(ABORT, 'Subscriptions are never deleted');
END;

-- The first event records the creation, in the status the subscription was created in.
CREATE TRIGGER "SubscriptionEvent_create" BEFORE INSERT ON "SubscriptionEvent"
WHEN NEW."transition" = 'create' AND (
    NEW."fromStatus" IS NOT NULL
    OR NEW."toStatus" IS NOT (SELECT "status" FROM "Subscription" WHERE "id" = NEW."subscriptionId")
    OR EXISTS (SELECT 1 FROM "SubscriptionEvent" WHERE "subscriptionId" = NEW."subscriptionId")
)
BEGIN
    SELECT RAISE(ABORT, 'A subscription is created once, in the status it starts in');
END;

-- Every later event starts from the current status and is one of the allowed moves (lifecycle.ts).
CREATE TRIGGER "SubscriptionEvent_transition" BEFORE INSERT ON "SubscriptionEvent"
WHEN NEW."transition" <> 'create' AND (
    NEW."fromStatus" IS NOT (SELECT "status" FROM "Subscription" WHERE "id" = NEW."subscriptionId")
    OR NOT ((NEW."fromStatus" = 'trialing' AND NEW."toStatus" = 'active') OR
         (NEW."fromStatus" = 'active' AND NEW."toStatus" = 'active') OR
         (NEW."fromStatus" = 'past_due' AND NEW."toStatus" = 'active') OR
         (NEW."fromStatus" = 'trialing' AND NEW."toStatus" = 'past_due') OR
         (NEW."fromStatus" = 'active' AND NEW."toStatus" = 'past_due') OR
         (NEW."fromStatus" = 'trialing' AND NEW."toStatus" = 'expired') OR
         (NEW."fromStatus" = 'active' AND NEW."toStatus" = 'canceling') OR
         (NEW."fromStatus" = 'trialing' AND NEW."toStatus" = 'canceled') OR
         (NEW."fromStatus" = 'active' AND NEW."toStatus" = 'canceled') OR
         (NEW."fromStatus" = 'past_due' AND NEW."toStatus" = 'canceled') OR
         (NEW."fromStatus" = 'paused' AND NEW."toStatus" = 'canceled') OR
         (NEW."fromStatus" = 'canceling' AND NEW."toStatus" = 'canceled') OR
         (NEW."fromStatus" = 'canceling' AND NEW."toStatus" = 'active') OR
         (NEW."fromStatus" = 'paused' AND NEW."toStatus" = 'active') OR
         (NEW."fromStatus" = 'active' AND NEW."toStatus" = 'paused') OR
         (NEW."fromStatus" = 'past_due' AND NEW."toStatus" = 'expired') OR
         (NEW."fromStatus" = 'trialing' AND NEW."toStatus" = 'trialing'))
)
BEGIN
    SELECT RAISE(ABORT, 'That is not an allowed subscription transition');
END;

-- An event belongs to the subscription's own academy.
CREATE TRIGGER "SubscriptionEvent_same_tenant" BEFORE INSERT ON "SubscriptionEvent"
WHEN NEW."tenantId" IS NOT (SELECT "tenantId" FROM "Subscription" WHERE "id" = NEW."subscriptionId")
BEGIN
    SELECT RAISE(ABORT, 'A lifecycle event belongs to its subscription''s academy');
END;

CREATE TRIGGER "SubscriptionEvent_no_update" BEFORE UPDATE ON "SubscriptionEvent"
BEGIN
    SELECT RAISE(ABORT, 'Lifecycle events are immutable');
END;

CREATE TRIGGER "SubscriptionEvent_no_delete" BEFORE DELETE ON "SubscriptionEvent"
BEGIN
    SELECT RAISE(ABORT, 'Lifecycle events are never deleted');
END;
