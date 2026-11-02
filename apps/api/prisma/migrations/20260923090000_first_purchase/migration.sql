-- SAAS-009 (extended) · An academy's first subscription, bought through checkout (subscriptions.md §43).
--
-- A first-purchase invoice (purpose `new_subscription`) names the plan version and cycle it sells. The
-- subscription created when it is paid carries that invoice's id — once, by a unique index — and the
-- database checks it is created only from a paid first-purchase invoice of the same academy, for exactly
-- the version and cycle that were paid for. Columns are added in place, so every existing trigger stays.

-- AlterTable
ALTER TABLE "Invoice" ADD COLUMN "billingCycle" TEXT;
ALTER TABLE "Invoice" ADD COLUMN "planVersionId" TEXT;

-- AlterTable
ALTER TABLE "Subscription" ADD COLUMN "sourceInvoiceId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Subscription_sourceInvoiceId_key" ON "Subscription"("sourceInvoiceId");

-- One first purchase open at a time per academy: a second choice replaces the first, never adds to it.
CREATE UNIQUE INDEX "Invoice_one_open_first_purchase" ON "Invoice"("tenantId") WHERE "purpose" = 'new_subscription' AND "status" = 'open';

-- A first-purchase invoice names a real plan version and a cycle; no other invoice names either.
CREATE TRIGGER "Invoice_sale_on_insert" BEFORE INSERT ON "Invoice"
WHEN (NEW."purpose" = 'new_subscription' AND (
        NEW."planVersionId" IS NULL
        OR NEW."billingCycle" IS NULL OR NEW."billingCycle" NOT IN ('monthly', 'annual')
        OR NOT EXISTS (SELECT 1 FROM "PlanVersion" v WHERE v."id" = NEW."planVersionId")
     ))
  OR (NEW."purpose" <> 'new_subscription' AND (NEW."planVersionId" IS NOT NULL OR NEW."billingCycle" IS NOT NULL))
BEGIN
    SELECT RAISE(ABORT, 'A first-purchase invoice names the plan version and cycle it sells; no other invoice does');
END;

-- What an invoice sold never changes.
CREATE TRIGGER "Invoice_sale_fixed" BEFORE UPDATE OF "planVersionId", "billingCycle" ON "Invoice"
WHEN NEW."planVersionId" IS NOT OLD."planVersionId" OR NEW."billingCycle" IS NOT OLD."billingCycle"
BEGIN
    SELECT RAISE(ABORT, 'An issued invoice is never altered');
END;

-- A subscription bought through checkout comes from a paid first-purchase invoice of its own academy, and
-- is exactly what that invoice sold: its plan version and cycle, starting active.
CREATE TRIGGER "Subscription_from_invoice" BEFORE INSERT ON "Subscription"
WHEN NEW."sourceInvoiceId" IS NOT NULL AND (
    NEW."status" <> 'active'
    OR NOT EXISTS (
        SELECT 1 FROM "Invoice" i
        WHERE i."id" = NEW."sourceInvoiceId"
          AND i."tenantId" = NEW."tenantId"
          AND i."purpose" = 'new_subscription'
          AND i."status" = 'paid'
          AND i."planVersionId" = NEW."planVersionId"
          AND i."billingCycle" = NEW."billingCycle"
          AND i."currency" = NEW."currency"
    )
)
BEGIN
    SELECT RAISE(ABORT, 'A purchased subscription is created only from its paid first-purchase invoice, for exactly what it sold');
END;

-- The invoice a subscription came from never changes.
CREATE TRIGGER "Subscription_source_fixed" BEFORE UPDATE OF "sourceInvoiceId" ON "Subscription"
WHEN NEW."sourceInvoiceId" IS NOT OLD."sourceInvoiceId"
BEGIN
    SELECT RAISE(ABORT, 'The invoice a subscription came from never changes');
END;
