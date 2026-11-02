-- SAAS-006 · Plan changes and period dates (decisions D7–D10; docs/06 › Plan changes).
--
-- PlanChange holds an upgrade quote (credit and charge fixed when issued, waiting for a confirmed
-- payment) or a downgrade scheduled for the period boundary. Its figures are integers of paise and are
-- never updated; only its status moves, along the allowed paths, and it is marked applied only in the
-- same transaction as the subscription's change_plan event that names it. One open change per
-- subscription; never deleted.
--
-- Subscription period dates now move only with a lifecycle event recording exactly the new dates — a
-- renewal, a resume from a pause (D9) or a cycle upgrade (D8) — so no write can shift a renewal date.

-- CreateTable
CREATE TABLE "PlanChange" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "subscriptionId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "fromPlanVersionId" TEXT NOT NULL,
    "fromCycle" TEXT NOT NULL,
    "fromAmount" INTEGER NOT NULL,
    "toPlanId" TEXT NOT NULL,
    "toPlanVersionId" TEXT NOT NULL,
    "toCycle" TEXT NOT NULL,
    "toAmount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL,
    "credit" INTEGER NOT NULL DEFAULT 0,
    "charge" INTEGER NOT NULL DEFAULT 0,
    "forfeited" INTEGER NOT NULL DEFAULT 0,
    "periodStartAt" DATETIME NOT NULL,
    "periodEndAt" DATETIME NOT NULL,
    "quotedAt" DATETIME NOT NULL,
    "conflictsJson" TEXT NOT NULL DEFAULT '[]',
    "requestedById" TEXT,
    "appliedAt" DATETIME,
    "closedAt" DATETIME,
    "closedReason" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PlanChange_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanChange_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "Subscription" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanChange_toPlanId_fkey" FOREIGN KEY ("toPlanId") REFERENCES "Plan" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanChange_toPlanVersionId_fkey" FOREIGN KEY ("toPlanVersionId") REFERENCES "PlanVersion" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanChange_fromPlanVersionId_fkey" FOREIGN KEY ("fromPlanVersionId") REFERENCES "PlanVersion" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanChange_kind_check" CHECK ("kind" IN ('upgrade', 'cycle_upgrade', 'downgrade', 'scheduled_change')),
    CONSTRAINT "PlanChange_status_check" CHECK ("status" IN ('pending_payment', 'scheduled', 'applied', 'canceled', 'void', 'expired')),
    CONSTRAINT "PlanChange_cycle_check" CHECK ("fromCycle" IN ('monthly', 'annual') AND "toCycle" IN ('monthly', 'annual')),
    CONSTRAINT "PlanChange_currency_check" CHECK ("currency" GLOB '[A-Z][A-Z][A-Z]'),
    CONSTRAINT "PlanChange_money_check" CHECK (
        typeof("fromAmount") = 'integer' AND "fromAmount" >= 0 AND typeof("toAmount") = 'integer' AND "toAmount" >= 0 AND
        typeof("credit") = 'integer' AND "credit" >= 0 AND typeof("charge") = 'integer' AND "charge" >= 0 AND
        typeof("forfeited") = 'integer' AND "forfeited" >= 0
    ),
    CONSTRAINT "PlanChange_period_check" CHECK ("periodEndAt" > "periodStartAt")
);

-- CreateIndex
CREATE INDEX "PlanChange_tenantId_createdAt_idx" ON "PlanChange"("tenantId", "createdAt");

-- CreateIndex
CREATE INDEX "PlanChange_subscriptionId_status_idx" ON "PlanChange"("subscriptionId", "status");

-- One open change (awaiting payment or scheduled) per subscription.
CREATE UNIQUE INDEX "PlanChange_one_open_per_subscription" ON "PlanChange"("subscriptionId") WHERE "status" IN ('pending_payment', 'scheduled');

-- An immediate change starts awaiting payment; a deferred one starts scheduled, and moves no money.
CREATE TRIGGER "PlanChange_initial" BEFORE INSERT ON "PlanChange"
WHEN NOT (
    (NEW."kind" IN ('upgrade', 'cycle_upgrade') AND NEW."status" = 'pending_payment')
    OR (NEW."kind" IN ('downgrade', 'scheduled_change') AND NEW."status" = 'scheduled' AND NEW."credit" = 0 AND NEW."charge" = 0 AND NEW."forfeited" = 0)
)
BEGIN
    SELECT RAISE(ABORT, 'A plan change starts awaiting payment (upgrades) or scheduled (everything else)');
END;

-- The new version belongs to the new plan, and the change to its subscription's academy.
CREATE TRIGGER "PlanChange_consistent" BEFORE INSERT ON "PlanChange"
WHEN (SELECT "planId" FROM "PlanVersion" WHERE "id" = NEW."toPlanVersionId") IS NOT NEW."toPlanId"
  OR NEW."tenantId" IS NOT (SELECT "tenantId" FROM "Subscription" WHERE "id" = NEW."subscriptionId")
BEGIN
    SELECT RAISE(ABORT, 'A plan change must name a version of its plan, in its subscription''s academy');
END;

-- The quote is history: nothing but its status and closing details ever changes.
CREATE TRIGGER "PlanChange_quote_fixed" BEFORE UPDATE OF
    "tenantId", "subscriptionId", "kind", "fromPlanVersionId", "fromCycle", "fromAmount", "toPlanId", "toPlanVersionId",
    "toCycle", "toAmount", "currency", "credit", "charge", "forfeited", "periodStartAt", "periodEndAt", "quotedAt",
    "conflictsJson", "requestedById", "createdAt" ON "PlanChange"
WHEN NEW."kind" IS NOT OLD."kind" OR NEW."fromAmount" IS NOT OLD."fromAmount" OR NEW."toAmount" IS NOT OLD."toAmount"
  OR NEW."credit" IS NOT OLD."credit" OR NEW."charge" IS NOT OLD."charge" OR NEW."forfeited" IS NOT OLD."forfeited"
  OR NEW."fromPlanVersionId" IS NOT OLD."fromPlanVersionId" OR NEW."toPlanVersionId" IS NOT OLD."toPlanVersionId"
  OR NEW."toPlanId" IS NOT OLD."toPlanId" OR NEW."fromCycle" IS NOT OLD."fromCycle" OR NEW."toCycle" IS NOT OLD."toCycle"
  OR NEW."currency" IS NOT OLD."currency" OR NEW."periodStartAt" IS NOT OLD."periodStartAt" OR NEW."periodEndAt" IS NOT OLD."periodEndAt"
  OR NEW."quotedAt" IS NOT OLD."quotedAt" OR NEW."subscriptionId" IS NOT OLD."subscriptionId" OR NEW."tenantId" IS NOT OLD."tenantId"
  OR NEW."conflictsJson" IS NOT OLD."conflictsJson" OR NEW."requestedById" IS NOT OLD."requestedById" OR NEW."createdAt" IS NOT OLD."createdAt"
BEGIN
    SELECT RAISE(ABORT, 'A plan change quote is never altered');
END;

-- Status moves only forward: an open change is applied, cancelled, voided or (a quote) expired, once.
CREATE TRIGGER "PlanChange_status_path" BEFORE UPDATE OF "status" ON "PlanChange"
WHEN NEW."status" IS NOT OLD."status" AND NOT (
    (OLD."status" = 'pending_payment' AND NEW."status" IN ('applied', 'canceled', 'void', 'expired'))
    OR (OLD."status" = 'scheduled' AND NEW."status" IN ('applied', 'canceled', 'void'))
)
BEGIN
    SELECT RAISE(ABORT, 'A plan change cannot move to that status');
END;

-- Applied only together with the subscription's change_plan event that names this change.
CREATE TRIGGER "PlanChange_applied_with_event" BEFORE UPDATE OF "status" ON "PlanChange"
WHEN NEW."status" = 'applied' AND OLD."status" <> 'applied' AND NOT EXISTS (
    SELECT 1 FROM "SubscriptionEvent" e
    WHERE e."id" = (SELECT max("id") FROM "SubscriptionEvent" WHERE "subscriptionId" = NEW."subscriptionId")
      AND e."transition" = 'change_plan'
      AND json_extract(e."metaJson", '$.planChangeId') = NEW."id"
)
BEGIN
    SELECT RAISE(ABORT, 'A plan change is applied only by the subscription''s change_plan transition');
END;

CREATE TRIGGER "PlanChange_no_delete" BEFORE DELETE ON "PlanChange"
BEGIN
    SELECT RAISE(ABORT, 'Plan changes are never deleted');
END;

-- A subscription's period dates move only with a lifecycle event recording exactly the new dates.
CREATE TRIGGER "Subscription_period_by_transition" BEFORE UPDATE OF "currentPeriodStartAt", "currentPeriodEndAt" ON "Subscription"
WHEN (NEW."currentPeriodStartAt" IS NOT OLD."currentPeriodStartAt" OR NEW."currentPeriodEndAt" IS NOT OLD."currentPeriodEndAt")
 AND NOT EXISTS (
    SELECT 1 FROM "SubscriptionEvent" e
    WHERE e."id" = (SELECT max("id") FROM "SubscriptionEvent" WHERE "subscriptionId" = NEW."id")
      AND json_extract(e."metaJson", '$.period.startMs') = NEW."currentPeriodStartAt"
      AND json_extract(e."metaJson", '$.period.endMs') = NEW."currentPeriodEndAt"
)
BEGIN
    SELECT RAISE(ABORT, 'A subscription''s period dates change only through a recorded transition');
END;
