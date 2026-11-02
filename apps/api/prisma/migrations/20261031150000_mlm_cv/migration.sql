-- MLM-003 · Orders and commissionable volume (docs/15 §4.4, §6.4). Academy-owned. A verified course purchase becomes an
-- MlmOrder; when eligible, one immutable MlmCvLedger row per ancestor credits that ancestor's leg, and MlmLegBalance
-- keeps each affiliate's running pools (rebuildable from the ledger). A reversal writes the same credits negated.

-- CreateTable
CREATE TABLE "MlmOrder" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "purchaseId" TEXT NOT NULL,
    "buyerAffiliateId" TEXT,
    "sponsorAffiliateIdAtSale" TEXT,
    "planVersionId" TEXT NOT NULL,
    "netAmount" BIGINT NOT NULL,
    "cv" BIGINT NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "status" TEXT NOT NULL DEFAULT 'pending',
    "paidAt" DATETIME NOT NULL,
    "eligibleAt" DATETIME,
    "reversedAt" DATETIME,
    "reversalReason" TEXT,
    "creditedAncestors" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmOrder_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmOrder_purchaseId_fkey" FOREIGN KEY ("purchaseId") REFERENCES "CoursePurchase" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmOrder_buyerAffiliateId_fkey" FOREIGN KEY ("buyerAffiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmOrder_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "MlmPlanVersion" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmOrder_status_check" CHECK ("status" IN ('pending', 'eligible', 'reversed')),
    CONSTRAINT "MlmOrder_amounts_check" CHECK (typeof("netAmount") = 'integer' AND "netAmount" >= 0 AND typeof("cv") = 'integer' AND "cv" >= 0),
    CONSTRAINT "MlmOrder_reversal_check" CHECK (("status" = 'reversed') = ("reversedAt" IS NOT NULL) AND ("reversalReason" IS NULL OR "reversalReason" IN ('refund', 'chargeback', 'manual')))
);

-- CreateTable
CREATE TABLE "MlmCvLedger" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "affiliateId" TEXT NOT NULL,
    "leg" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmCvLedger_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmCvLedger_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmCvLedger_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "MlmOrder" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmCvLedger_leg_check" CHECK ("leg" IN ('A', 'B')),
    CONSTRAINT "MlmCvLedger_kind_check" CHECK ("kind" IN ('sale', 'reversal')),
    CONSTRAINT "MlmCvLedger_sign_check" CHECK (typeof("amount") = 'integer' AND (("kind" = 'sale' AND "amount" > 0) OR ("kind" = 'reversal' AND "amount" < 0)))
);

-- CreateTable
CREATE TABLE "MlmLegBalance" (
    "affiliateId" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "lifetimeA" BIGINT NOT NULL DEFAULT 0,
    "lifetimeB" BIGINT NOT NULL DEFAULT 0,
    "unmatchedA" BIGINT NOT NULL DEFAULT 0,
    "unmatchedB" BIGINT NOT NULL DEFAULT 0,
    "matchedLifetime" BIGINT NOT NULL DEFAULT 0,
    "lastMatchingRunDate" TEXT,
    "version" INTEGER NOT NULL DEFAULT 0,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmLegBalance_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmLegBalance_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmLegBalance_nonnegative_check" CHECK ("lifetimeA" >= 0 AND "lifetimeB" >= 0 AND "unmatchedA" >= 0 AND "unmatchedB" >= 0 AND "matchedLifetime" >= 0)
);

-- CreateIndex
CREATE UNIQUE INDEX "MlmOrder_purchaseId_key" ON "MlmOrder"("purchaseId");
CREATE INDEX "MlmOrder_tenantId_idx" ON "MlmOrder"("tenantId");
CREATE INDEX "MlmOrder_tenantId_status_idx" ON "MlmOrder"("tenantId", "status");
CREATE INDEX "MlmOrder_buyerAffiliateId_idx" ON "MlmOrder"("buyerAffiliateId");
CREATE INDEX "MlmOrder_paidAt_idx" ON "MlmOrder"("paidAt");
CREATE UNIQUE INDEX "MlmCvLedger_orderId_affiliateId_kind_key" ON "MlmCvLedger"("orderId", "affiliateId", "kind");
CREATE INDEX "MlmCvLedger_tenantId_idx" ON "MlmCvLedger"("tenantId");
CREATE INDEX "MlmCvLedger_affiliateId_createdAt_idx" ON "MlmCvLedger"("affiliateId", "createdAt");
CREATE INDEX "MlmLegBalance_tenantId_idx" ON "MlmLegBalance"("tenantId");

-- The ledger is immutable.
CREATE TRIGGER "MlmCvLedger_no_update" BEFORE UPDATE ON "MlmCvLedger"
BEGIN
    SELECT RAISE(ABORT, 'The CV ledger is immutable');
END;
CREATE TRIGGER "MlmCvLedger_no_delete" BEFORE DELETE ON "MlmCvLedger"
BEGIN
    SELECT RAISE(ABORT, 'The CV ledger is never deleted');
END;

-- An order's terms are fixed; a reversal is final.
CREATE TRIGGER "MlmOrder_terms_fixed" BEFORE UPDATE OF "tenantId", "purchaseId", "buyerAffiliateId", "planVersionId", "netAmount", "cv", "currency", "paidAt" ON "MlmOrder"
WHEN NEW."tenantId" IS NOT OLD."tenantId" OR NEW."purchaseId" IS NOT OLD."purchaseId" OR NEW."buyerAffiliateId" IS NOT OLD."buyerAffiliateId"
  OR NEW."planVersionId" IS NOT OLD."planVersionId" OR NEW."netAmount" IS NOT OLD."netAmount" OR NEW."cv" IS NOT OLD."cv"
  OR NEW."currency" IS NOT OLD."currency" OR NEW."paidAt" IS NOT OLD."paidAt"
BEGIN
    SELECT RAISE(ABORT, 'An affiliate order''s terms cannot change');
END;
CREATE TRIGGER "MlmOrder_reversed_is_final" BEFORE UPDATE OF "status" ON "MlmOrder"
WHEN OLD."status" = 'reversed' AND NEW."status" <> 'reversed'
BEGIN
    SELECT RAISE(ABORT, 'A reversed affiliate order stays reversed');
END;
CREATE TRIGGER "MlmOrder_no_delete" BEFORE DELETE ON "MlmOrder"
BEGIN
    SELECT RAISE(ABORT, 'An affiliate order is never deleted');
END;
