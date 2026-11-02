-- MLM-000 · The affiliate program's plan (docs/15-MLM-AFFILIATE-ARCHITECTURE.md §4.2).
--
-- Platform-level: the plan is the company's, so none of these tables carries a tenantId. The academy whose learners
-- are the affiliates is named by `programTenantId` on the version. A version's terms are data; the engines read the
-- active version and record which one they computed under. Rules:
--   - at most one version is `active` at a time (trigger);
--   - a version moves draft → active → retired and never back (trigger);
--   - a version's ranks and cap bands can change only while it is a draft (triggers), so a commission or rank that
--     names an active or retired version always finds the terms it was computed under;
--   - amounts are 64-bit integers in minor units (paise): group CV targets reach ₹500 crore.
-- This migration creates tables only; the plan itself is seeded by `npm run seed:mlm-plan` as a draft.

-- CreateTable
CREATE TABLE "MlmPlanVersion" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "version" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "programTenantId" TEXT NOT NULL,
    "eligibleCourseIdsJson" TEXT NOT NULL DEFAULT '[]',
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "cvBasisPoints" INTEGER NOT NULL DEFAULT 10000,
    "matchingRateBps" INTEGER NOT NULL DEFAULT 1000,
    "payoutCeilingBps" INTEGER NOT NULL DEFAULT 2500,
    "normalPayoutBps" INTEGER NOT NULL DEFAULT 1500,
    "matchingRunHourIst" INTEGER NOT NULL DEFAULT 2,
    "cvEligibilityDelayDays" INTEGER NOT NULL DEFAULT 0,
    "capOverflowPolicy" TEXT NOT NULL DEFAULT 'flush',
    "carryForwardPolicy" TEXT NOT NULL DEFAULT 'indefinite',
    "carryExpiryDays" INTEGER,
    "spilloverRule" TEXT NOT NULL DEFAULT 'extreme-outer',
    "withdrawalMinAmount" BIGINT NOT NULL DEFAULT 0,
    "withdrawalRequiresKyc" BOOLEAN NOT NULL DEFAULT true,
    "tdsBps" INTEGER NOT NULL DEFAULT 0,
    "liabilityPeriod" TEXT NOT NULL DEFAULT 'month',
    "note" TEXT NOT NULL DEFAULT '',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "activatedAt" DATETIME,
    "retiredAt" DATETIME,
    CONSTRAINT "MlmPlanVersion_programTenantId_fkey" FOREIGN KEY ("programTenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmPlanVersion_version_check" CHECK (typeof("version") = 'integer' AND "version" >= 1),
    CONSTRAINT "MlmPlanVersion_status_check" CHECK ("status" IN ('draft', 'active', 'retired')),
    CONSTRAINT "MlmPlanVersion_currency_check" CHECK ("currency" GLOB '[A-Z][A-Z][A-Z]'),
    CONSTRAINT "MlmPlanVersion_cvBasisPoints_check" CHECK (typeof("cvBasisPoints") = 'integer' AND "cvBasisPoints" BETWEEN 1 AND 10000),
    CONSTRAINT "MlmPlanVersion_matchingRateBps_check" CHECK (typeof("matchingRateBps") = 'integer' AND "matchingRateBps" BETWEEN 1 AND 5000),
    CONSTRAINT "MlmPlanVersion_payoutCeilingBps_check" CHECK (typeof("payoutCeilingBps") = 'integer' AND "payoutCeilingBps" BETWEEN 1 AND 10000),
    CONSTRAINT "MlmPlanVersion_normalPayoutBps_check" CHECK (typeof("normalPayoutBps") = 'integer' AND "normalPayoutBps" BETWEEN 0 AND 10000),
    CONSTRAINT "MlmPlanVersion_matchingRunHourIst_check" CHECK (typeof("matchingRunHourIst") = 'integer' AND "matchingRunHourIst" BETWEEN 0 AND 23),
    CONSTRAINT "MlmPlanVersion_cvEligibilityDelayDays_check" CHECK (typeof("cvEligibilityDelayDays") = 'integer' AND "cvEligibilityDelayDays" BETWEEN 0 AND 90),
    CONSTRAINT "MlmPlanVersion_capOverflowPolicy_check" CHECK ("capOverflowPolicy" IN ('flush', 'carry')),
    CONSTRAINT "MlmPlanVersion_carryForwardPolicy_check" CHECK ("carryForwardPolicy" IN ('indefinite', 'expire-days')),
    CONSTRAINT "MlmPlanVersion_carryExpiryDays_check" CHECK ("carryExpiryDays" IS NULL OR (typeof("carryExpiryDays") = 'integer' AND "carryExpiryDays" BETWEEN 1 AND 365)),
    CONSTRAINT "MlmPlanVersion_spilloverRule_check" CHECK ("spilloverRule" IN ('extreme-outer', 'breadth-first')),
    CONSTRAINT "MlmPlanVersion_withdrawalMinAmount_check" CHECK (typeof("withdrawalMinAmount") = 'integer' AND "withdrawalMinAmount" >= 0),
    CONSTRAINT "MlmPlanVersion_tdsBps_check" CHECK (typeof("tdsBps") = 'integer' AND "tdsBps" BETWEEN 0 AND 5000),
    CONSTRAINT "MlmPlanVersion_liabilityPeriod_check" CHECK ("liabilityPeriod" IN ('month')),
    CONSTRAINT "MlmPlanVersion_activatedAt_check" CHECK (("status" = 'draft') = ("activatedAt" IS NULL)),
    CONSTRAINT "MlmPlanVersion_retiredAt_check" CHECK (("status" = 'retired') = ("retiredAt" IS NOT NULL))
);

-- CreateTable
CREATE TABLE "MlmCapBand" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "planVersionId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "dailyCap" BIGINT NOT NULL,
    "order" INTEGER NOT NULL,
    CONSTRAINT "MlmCapBand_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "MlmPlanVersion" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "MlmCapBand_dailyCap_check" CHECK (typeof("dailyCap") = 'integer' AND "dailyCap" >= 1),
    CONSTRAINT "MlmCapBand_order_check" CHECK (typeof("order") = 'integer' AND "order" >= 1)
);

-- CreateTable
CREATE TABLE "MlmRankTier" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "planVersionId" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "groupCv" BIGINT NOT NULL,
    "rewardKind" TEXT NOT NULL,
    "rewardAmount" BIGINT NOT NULL DEFAULT 0,
    "rewardCapAmount" BIGINT,
    "capBandKey" TEXT NOT NULL,
    "vestingDays" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "MlmRankTier_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "MlmPlanVersion" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "MlmRankTier_order_check" CHECK (typeof("order") = 'integer' AND "order" >= 1),
    CONSTRAINT "MlmRankTier_groupCv_check" CHECK (typeof("groupCv") = 'integer' AND "groupCv" >= 2 AND "groupCv" % 2 = 0),
    CONSTRAINT "MlmRankTier_rewardKind_check" CHECK ("rewardKind" IN ('recognition', 'certificate', 'cash')),
    CONSTRAINT "MlmRankTier_rewardAmount_check" CHECK (typeof("rewardAmount") = 'integer' AND "rewardAmount" >= 0),
    CONSTRAINT "MlmRankTier_rewardCapAmount_check" CHECK ("rewardCapAmount" IS NULL OR (typeof("rewardCapAmount") = 'integer' AND "rewardCapAmount" >= 1)),
    CONSTRAINT "MlmRankTier_vestingDays_check" CHECK (typeof("vestingDays") = 'integer' AND "vestingDays" BETWEEN 0 AND 3650)
);

-- CreateIndex
CREATE UNIQUE INDEX "MlmPlanVersion_version_key" ON "MlmPlanVersion"("version");
CREATE INDEX "MlmPlanVersion_status_idx" ON "MlmPlanVersion"("status");
CREATE INDEX "MlmPlanVersion_programTenantId_idx" ON "MlmPlanVersion"("programTenantId");
CREATE UNIQUE INDEX "MlmCapBand_planVersionId_key_key" ON "MlmCapBand"("planVersionId", "key");
CREATE UNIQUE INDEX "MlmCapBand_planVersionId_order_key" ON "MlmCapBand"("planVersionId", "order");
CREATE UNIQUE INDEX "MlmRankTier_planVersionId_order_key" ON "MlmRankTier"("planVersionId", "order");
CREATE UNIQUE INDEX "MlmRankTier_planVersionId_name_key" ON "MlmRankTier"("planVersionId", "name");

-- One active version at a time.
CREATE TRIGGER "MlmPlanVersion_one_active" BEFORE UPDATE OF "status" ON "MlmPlanVersion"
WHEN NEW."status" = 'active' AND OLD."status" <> 'active'
  AND EXISTS (SELECT 1 FROM "MlmPlanVersion" WHERE "status" = 'active' AND "id" <> NEW."id")
BEGIN
    SELECT RAISE(ABORT, 'Another affiliate plan version is already active');
END;
CREATE TRIGGER "MlmPlanVersion_one_active_insert" BEFORE INSERT ON "MlmPlanVersion"
WHEN NEW."status" = 'active' AND EXISTS (SELECT 1 FROM "MlmPlanVersion" WHERE "status" = 'active')
BEGIN
    SELECT RAISE(ABORT, 'Another affiliate plan version is already active');
END;

-- Status moves forward only: draft → active → retired.
CREATE TRIGGER "MlmPlanVersion_status_forward" BEFORE UPDATE OF "status" ON "MlmPlanVersion"
WHEN NOT ((OLD."status" = 'draft' AND NEW."status" = 'active') OR (OLD."status" = 'active' AND NEW."status" = 'retired') OR NEW."status" = OLD."status")
BEGIN
    SELECT RAISE(ABORT, 'An affiliate plan version moves draft → active → retired and never back');
END;

-- Terms are fixed once a version has left draft: the engines rely on reading what a commission was computed under.
CREATE TRIGGER "MlmPlanVersion_terms_fixed" BEFORE UPDATE OF
  "version", "programTenantId", "eligibleCourseIdsJson", "currency", "cvBasisPoints", "matchingRateBps", "payoutCeilingBps",
  "normalPayoutBps", "matchingRunHourIst", "cvEligibilityDelayDays", "capOverflowPolicy", "carryForwardPolicy", "carryExpiryDays",
  "spilloverRule", "withdrawalMinAmount", "withdrawalRequiresKyc", "tdsBps", "liabilityPeriod" ON "MlmPlanVersion"
WHEN OLD."status" <> 'draft' AND NOT (
  NEW."version" IS OLD."version" AND NEW."programTenantId" IS OLD."programTenantId" AND NEW."currency" IS OLD."currency"
  AND NEW."cvBasisPoints" IS OLD."cvBasisPoints" AND NEW."matchingRateBps" IS OLD."matchingRateBps"
  AND NEW."payoutCeilingBps" IS OLD."payoutCeilingBps" AND NEW."normalPayoutBps" IS OLD."normalPayoutBps"
  AND NEW."matchingRunHourIst" IS OLD."matchingRunHourIst" AND NEW."cvEligibilityDelayDays" IS OLD."cvEligibilityDelayDays"
  AND NEW."capOverflowPolicy" IS OLD."capOverflowPolicy" AND NEW."carryForwardPolicy" IS OLD."carryForwardPolicy"
  AND NEW."carryExpiryDays" IS OLD."carryExpiryDays" AND NEW."spilloverRule" IS OLD."spilloverRule"
  AND NEW."withdrawalMinAmount" IS OLD."withdrawalMinAmount" AND NEW."withdrawalRequiresKyc" IS OLD."withdrawalRequiresKyc"
  AND NEW."tdsBps" IS OLD."tdsBps" AND NEW."liabilityPeriod" IS OLD."liabilityPeriod"
  -- The eligible-course list alone may change on an active version (D-MLM-05): it is a product list, not a compensation term.
  AND (OLD."status" = 'active' OR NEW."eligibleCourseIdsJson" IS OLD."eligibleCourseIdsJson")
)
BEGIN
    SELECT RAISE(ABORT, 'The terms of an affiliate plan version cannot change once it has left draft: add a new version');
END;

-- Ranks and cap bands are sealed with their version.
CREATE TRIGGER "MlmRankTier_sealed_update" BEFORE UPDATE ON "MlmRankTier"
WHEN (SELECT "status" FROM "MlmPlanVersion" WHERE "id" = OLD."planVersionId") <> 'draft'
BEGIN
    SELECT RAISE(ABORT, 'The ranks of an affiliate plan version cannot change once it has left draft');
END;
CREATE TRIGGER "MlmRankTier_sealed_delete" BEFORE DELETE ON "MlmRankTier"
WHEN (SELECT "status" FROM "MlmPlanVersion" WHERE "id" = OLD."planVersionId") <> 'draft'
BEGIN
    SELECT RAISE(ABORT, 'The ranks of an affiliate plan version cannot change once it has left draft');
END;
CREATE TRIGGER "MlmRankTier_sealed_insert" BEFORE INSERT ON "MlmRankTier"
WHEN (SELECT "status" FROM "MlmPlanVersion" WHERE "id" = NEW."planVersionId") <> 'draft'
BEGIN
    SELECT RAISE(ABORT, 'The ranks of an affiliate plan version cannot change once it has left draft');
END;
CREATE TRIGGER "MlmCapBand_sealed_update" BEFORE UPDATE ON "MlmCapBand"
WHEN (SELECT "status" FROM "MlmPlanVersion" WHERE "id" = OLD."planVersionId") <> 'draft'
BEGIN
    SELECT RAISE(ABORT, 'The cap bands of an affiliate plan version cannot change once it has left draft');
END;
CREATE TRIGGER "MlmCapBand_sealed_delete" BEFORE DELETE ON "MlmCapBand"
WHEN (SELECT "status" FROM "MlmPlanVersion" WHERE "id" = OLD."planVersionId") <> 'draft'
BEGIN
    SELECT RAISE(ABORT, 'The cap bands of an affiliate plan version cannot change once it has left draft');
END;
CREATE TRIGGER "MlmCapBand_sealed_insert" BEFORE INSERT ON "MlmCapBand"
WHEN (SELECT "status" FROM "MlmPlanVersion" WHERE "id" = NEW."planVersionId") <> 'draft'
BEGIN
    SELECT RAISE(ABORT, 'The cap bands of an affiliate plan version cannot change once it has left draft');
END;

-- A version is never deleted: something may have been computed under it.
CREATE TRIGGER "MlmPlanVersion_no_delete" BEFORE DELETE ON "MlmPlanVersion"
WHEN OLD."status" <> 'draft'
BEGIN
    SELECT RAISE(ABORT, 'An affiliate plan version that has been active is never deleted');
END;
