-- SAAS-005 · Trials and grace (subscriptions.md §7, §8).
--
-- A trial's dates are fixed when it starts: nothing can move them afterwards, so no clock — the server's
-- own included — can extend one. A grace period's window is written only by the grace_started transition,
-- whose lifecycle event carries the exact end it sets, so the window cannot be extended by a direct write
-- either. The past-due episode records when it began and why.
--
-- Columns are added with ALTER TABLE ADD COLUMN, so the table and its SAAS-004 triggers are kept as they are.

-- AlterTable
ALTER TABLE "Subscription" ADD COLUMN "pastDueAt" DATETIME;
ALTER TABLE "Subscription" ADD COLUMN "pastDueReason" TEXT;
ALTER TABLE "Subscription" ADD COLUMN "gracePeriodStartAt" DATETIME
    CHECK (("gracePeriodStartAt" IS NULL) = ("gracePeriodEndAt" IS NULL) AND ("gracePeriodEndAt" IS NULL OR "gracePeriodEndAt" >= "gracePeriodStartAt"));

-- The state machine gained grace_started (past_due → past_due): the allowed pairs are re-issued, 18 now.
DROP TRIGGER "SubscriptionEvent_transition";
CREATE TRIGGER "SubscriptionEvent_transition" BEFORE INSERT ON "SubscriptionEvent"
WHEN NEW."transition" <> 'create' AND (
    NEW."fromStatus" IS NOT (SELECT "status" FROM "Subscription" WHERE "id" = NEW."subscriptionId")
    OR NOT ((NEW."fromStatus" = 'trialing' AND NEW."toStatus" = 'active') OR
         (NEW."fromStatus" = 'active' AND NEW."toStatus" = 'active') OR
         (NEW."fromStatus" = 'past_due' AND NEW."toStatus" = 'active') OR
         (NEW."fromStatus" = 'trialing' AND NEW."toStatus" = 'past_due') OR
         (NEW."fromStatus" = 'active' AND NEW."toStatus" = 'past_due') OR
         (NEW."fromStatus" = 'past_due' AND NEW."toStatus" = 'past_due') OR
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

-- A trial's start and end are fixed when the subscription is created.
CREATE TRIGGER "Subscription_trial_fixed" BEFORE UPDATE OF "trialStartAt", "trialEndAt" ON "Subscription"
WHEN NEW."trialStartAt" IS NOT OLD."trialStartAt" OR NEW."trialEndAt" IS NOT OLD."trialEndAt"
BEGIN
    SELECT RAISE(ABORT, 'A trial''s dates are fixed when it starts');
END;

-- A grace window is opened only by a grace_started event naming exactly its end (milliseconds, as Prisma
-- stores a DateTime). Closing it — on recovery — is allowed.
CREATE TRIGGER "Subscription_grace_by_transition" BEFORE UPDATE OF "gracePeriodStartAt", "gracePeriodEndAt" ON "Subscription"
WHEN NEW."gracePeriodEndAt" IS NOT NULL
 AND (NEW."gracePeriodEndAt" IS NOT OLD."gracePeriodEndAt" OR NEW."gracePeriodStartAt" IS NOT OLD."gracePeriodStartAt")
 AND NOT EXISTS (
    SELECT 1 FROM "SubscriptionEvent" e
    WHERE e."id" = (SELECT max("id") FROM "SubscriptionEvent" WHERE "subscriptionId" = NEW."id")
      AND e."transition" = 'grace_started'
      AND json_extract(e."metaJson", '$.graceEndsAtMs') = NEW."gracePeriodEndAt"
)
BEGIN
    SELECT RAISE(ABORT, 'A grace period is set only by the grace_started transition');
END;
