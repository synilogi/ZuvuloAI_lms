-- SAAS-007 · Tax rules and billing profiles (subscriptions.md §26–28).
--
-- TaxRule / TaxRuleComponent are platform data: which tax a buyer pays is decided by the rule for their
-- country (or region), never by code, and no rate is inserted here — the operator configures them. A
-- rule's components are fixed once written; a rate change retires the rule and adds a new one, so every
-- tax charged can be traced to the rule it used. Rates are integer basis points. One active rule per
-- country and region.
--
-- BillingProfile is an academy's billing identity: address, country and tax registration.

-- CreateTable
CREATE TABLE "TaxRule" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "country" TEXT NOT NULL,
    "region" TEXT,
    "inclusive" BOOLEAN NOT NULL DEFAULT false,
    "componentCount" INTEGER NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "retiredAt" DATETIME,
    CONSTRAINT "TaxRule_country_check" CHECK ("country" GLOB '[A-Z][A-Z]'),
    CONSTRAINT "TaxRule_count_check" CHECK (typeof("componentCount") = 'integer' AND "componentCount" BETWEEN 1 AND 5)
);

-- CreateTable
CREATE TABLE "TaxRuleComponent" (
    "ruleId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "rateBps" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,

    PRIMARY KEY ("ruleId", "code"),
    CONSTRAINT "TaxRuleComponent_ruleId_fkey" FOREIGN KEY ("ruleId") REFERENCES "TaxRule" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "TaxRuleComponent_rate_check" CHECK (typeof("rateBps") = 'integer' AND "rateBps" BETWEEN 0 AND 10000),
    CONSTRAINT "TaxRuleComponent_code_check" CHECK (length("code") BETWEEN 1 AND 16)
);

-- CreateTable
CREATE TABLE "BillingProfile" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "legalName" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "addressLine1" TEXT NOT NULL,
    "addressLine2" TEXT,
    "city" TEXT NOT NULL,
    "region" TEXT,
    "postalCode" TEXT NOT NULL,
    "country" TEXT NOT NULL,
    "taxRegistration" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "BillingProfile_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "BillingProfile_country_check" CHECK ("country" GLOB '[A-Z][A-Z]')
);

-- CreateIndex
CREATE INDEX "TaxRule_country_region_idx" ON "TaxRule"("country", "region");

-- CreateIndex
CREATE UNIQUE INDEX "BillingProfile_tenantId_key" ON "BillingProfile"("tenantId");

-- One active rule per country and region (a whole-country rule has no region).
CREATE UNIQUE INDEX "TaxRule_one_active_per_place" ON "TaxRule"("country", IFNULL("region", '')) WHERE "retiredAt" IS NULL;

-- A rule is fixed once written: only its retirement can be recorded, once.
CREATE TRIGGER "TaxRule_fixed" BEFORE UPDATE ON "TaxRule"
WHEN NEW."name" IS NOT OLD."name" OR NEW."country" IS NOT OLD."country" OR NEW."region" IS NOT OLD."region"
  OR NEW."inclusive" IS NOT OLD."inclusive" OR NEW."componentCount" IS NOT OLD."componentCount" OR NEW."createdAt" IS NOT OLD."createdAt"
  OR (OLD."retiredAt" IS NOT NULL AND NEW."retiredAt" IS NOT OLD."retiredAt")
BEGIN
    SELECT RAISE(ABORT, 'A tax rule is never altered: retire it and add a new one');
END;

CREATE TRIGGER "TaxRule_no_delete" BEFORE DELETE ON "TaxRule"
BEGIN
    SELECT RAISE(ABORT, 'Tax rules are never deleted');
END;

-- Components are written with the rule, up to the count it declares, and never changed.
CREATE TRIGGER "TaxRuleComponent_sealed" BEFORE INSERT ON "TaxRuleComponent"
WHEN (SELECT count(*) FROM "TaxRuleComponent" WHERE "ruleId" = NEW."ruleId") >= (SELECT "componentCount" FROM "TaxRule" WHERE "id" = NEW."ruleId")
BEGIN
    SELECT RAISE(ABORT, 'This tax rule already has every component it declared');
END;

CREATE TRIGGER "TaxRuleComponent_no_update" BEFORE UPDATE ON "TaxRuleComponent"
BEGIN
    SELECT RAISE(ABORT, 'Tax rule components are never altered');
END;

CREATE TRIGGER "TaxRuleComponent_no_delete" BEFORE DELETE ON "TaxRuleComponent"
BEGIN
    SELECT RAISE(ABORT, 'Tax rule components are never deleted');
END;
