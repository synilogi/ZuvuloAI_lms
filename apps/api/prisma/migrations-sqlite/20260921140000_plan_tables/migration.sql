-- SAAS-001 · Plan tables & versioning (subscriptions.md §4, §26, §37).
--
-- Plans are platform-level and carry no tenantId. A plan's commercial terms live in PlanVersion rows,
-- which are append-only: the triggers below refuse any UPDATE or DELETE, so a price edit can only add
-- a version, and whatever points at an older version keeps the terms it was sold on. A Plan cannot be
-- deleted while it has a version (ON DELETE RESTRICT), and every plan is created with one.
--
-- Amounts are integers in the currency's minor unit (paise for INR). SQLite would otherwise store
-- 3999.5 in an INTEGER column as a REAL, so the CHECKs test the stored type, not just the value.
--
-- This migration only creates tables: it inserts no plan, because prices are business configuration
-- and not schema. Nothing existing is changed.

-- CreateTable
CREATE TABLE "Plan" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "displayOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "archivedAt" DATETIME,
    CONSTRAINT "Plan_status_check" CHECK ("status" IN ('draft', 'active', 'archived')),
    CONSTRAINT "Plan_code_check" CHECK ("code" = upper("code") AND length("code") BETWEEN 2 AND 24),
    CONSTRAINT "Plan_archivedAt_check" CHECK (("status" = 'archived') = ("archivedAt" IS NOT NULL))
);

-- CreateTable
CREATE TABLE "PlanVersion" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "planId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "currency" TEXT NOT NULL,
    "monthlyPrice" INTEGER,
    "annualPrice" INTEGER,
    "trialDays" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PlanVersion_planId_fkey" FOREIGN KEY ("planId") REFERENCES "Plan" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanVersion_version_check" CHECK (typeof("version") = 'integer' AND "version" >= 1),
    CONSTRAINT "PlanVersion_currency_check" CHECK ("currency" GLOB '[A-Z][A-Z][A-Z]'),
    CONSTRAINT "PlanVersion_monthlyPrice_check" CHECK ("monthlyPrice" IS NULL OR (typeof("monthlyPrice") = 'integer' AND "monthlyPrice" >= 0)),
    CONSTRAINT "PlanVersion_annualPrice_check" CHECK ("annualPrice" IS NULL OR (typeof("annualPrice") = 'integer' AND "annualPrice" >= 0)),
    CONSTRAINT "PlanVersion_cycle_check" CHECK ("monthlyPrice" IS NOT NULL OR "annualPrice" IS NOT NULL),
    CONSTRAINT "PlanVersion_trialDays_check" CHECK (typeof("trialDays") = 'integer' AND "trialDays" BETWEEN 0 AND 90)
);

-- CreateIndex
CREATE UNIQUE INDEX "Plan_code_key" ON "Plan"("code");

-- CreateIndex
CREATE INDEX "Plan_status_displayOrder_idx" ON "Plan"("status", "displayOrder");

-- CreateIndex
CREATE UNIQUE INDEX "PlanVersion_planId_version_key" ON "PlanVersion"("planId", "version");

-- Commercial terms are append-only.
CREATE TRIGGER "PlanVersion_no_update" BEFORE UPDATE ON "PlanVersion"
BEGIN
    SELECT RAISE(ABORT, 'PlanVersion rows are immutable: add a new version instead');
END;

CREATE TRIGGER "PlanVersion_no_delete" BEFORE DELETE ON "PlanVersion"
BEGIN
    SELECT RAISE(ABORT, 'PlanVersion rows are immutable and are never deleted');
END;

-- A plan's code is what billing keys on, so it is fixed once the plan has been offered.
CREATE TRIGGER "Plan_code_fixed" BEFORE UPDATE OF "code" ON "Plan"
WHEN OLD."status" <> 'draft' AND NEW."code" <> OLD."code"
BEGIN
    SELECT RAISE(ABORT, 'A plan code cannot change once the plan has left draft');
END;
