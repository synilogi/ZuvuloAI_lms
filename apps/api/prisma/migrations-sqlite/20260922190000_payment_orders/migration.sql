-- SAAS-009 · Payment Provider Abstraction (subscriptions.md §43).
--
-- A checkout is a provider order for one open invoice. Its amount and currency are the invoice's, checked
-- here against the invoice itself, so no order can ask the provider for a figure the server did not
-- issue. It settles once, and only to `paid`; it is never deleted.

-- CreateTable
CREATE TABLE "PaymentOrder" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "invoiceId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerOrderId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL CHECK (typeof("amount") = 'integer' AND "amount" > 0),
    "currency" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'created' CHECK ("status" IN ('created', 'paid')),
    "providerPaymentId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "paidAt" DATETIME,
    CONSTRAINT "PaymentOrder_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PaymentOrder_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "Invoice" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "PaymentOrder_invoiceId_idx" ON "PaymentOrder"("invoiceId");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentOrder_provider_providerOrderId_key" ON "PaymentOrder"("provider", "providerOrderId");

-- An order is for an open invoice of its own academy, for exactly the invoice's total in its currency.
CREATE TRIGGER "PaymentOrder_matches_invoice"
BEFORE INSERT ON "PaymentOrder"
FOR EACH ROW
WHEN NOT EXISTS (
  SELECT 1 FROM "Invoice" i
  WHERE i."id" = NEW."invoiceId"
    AND i."tenantId" = NEW."tenantId"
    AND i."status" = 'open'
    AND i."total" = NEW."amount"
    AND i."currency" = NEW."currency"
) OR NEW."status" <> 'created' OR NEW."providerPaymentId" IS NOT NULL OR NEW."paidAt" IS NOT NULL
BEGIN
  SELECT RAISE(ABORT, 'PaymentOrder: an order is created for an open invoice of its academy, at exactly its total and currency');
END;

-- What an order is for never changes, and it settles once: created → paid, with the payment that paid it.
CREATE TRIGGER "PaymentOrder_settles_once"
BEFORE UPDATE ON "PaymentOrder"
FOR EACH ROW
WHEN NEW."id" <> OLD."id"
  OR NEW."tenantId" <> OLD."tenantId"
  OR NEW."invoiceId" <> OLD."invoiceId"
  OR NEW."provider" <> OLD."provider"
  OR NEW."providerOrderId" <> OLD."providerOrderId"
  OR NEW."amount" <> OLD."amount"
  OR NEW."currency" <> OLD."currency"
  OR NEW."createdAt" <> OLD."createdAt"
  OR OLD."status" <> 'created'
  OR NEW."status" <> 'paid'
  OR NEW."providerPaymentId" IS NULL
  OR NEW."paidAt" IS NULL
BEGIN
  SELECT RAISE(ABORT, 'PaymentOrder: fixed once made, and settles once — created to paid');
END;

CREATE TRIGGER "PaymentOrder_no_delete"
BEFORE DELETE ON "PaymentOrder"
FOR EACH ROW
BEGIN
  SELECT RAISE(ABORT, 'PaymentOrder: never deleted');
END;
