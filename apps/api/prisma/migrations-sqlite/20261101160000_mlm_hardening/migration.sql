-- Corrections from the 1 Nov 2026 audit. Additive: nothing is dropped except one trigger, replaced below.

-- What a program's jobs have finished, per workspace: the last matching day that completed, and the last nightly check.
CREATE TABLE "MlmProgramState" (
    "tenantId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    PRIMARY KEY ("tenantId", "key"),
    CONSTRAINT "MlmProgramState_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- A lost dispute, recorded so a reversal that failed the first time can be retried.
ALTER TABLE "CoursePurchase" ADD COLUMN "chargebackAt" DATETIME;

-- A hold can now be divided: the row closes as 'split' and two held rows carry its exact amount on, so a release or a clawback
-- can take part of it without any commission's money ever changing.
ALTER TABLE "MlmCommission" ADD COLUMN "splitFromId" TEXT;
DROP TRIGGER "MlmCommission_money_fixed";
CREATE TRIGGER "MlmCommission_money_fixed" BEFORE UPDATE ON "MlmCommission"
WHEN OLD."status" <> 'held' OR NEW."status" NOT IN ('paid_to_wallet', 'written_off', 'split') OR NEW."amount" <> OLD."amount" OR NEW."kind" <> OLD."kind" OR NEW."affiliateId" <> OLD."affiliateId"
BEGIN SELECT RAISE(ABORT, 'A commission is fixed: only a held one can be released, split or written off.'); END;
