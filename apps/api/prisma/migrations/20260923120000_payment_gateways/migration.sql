-- SAAS-017 · Multi-gateway payments and runtime gateway configuration (decision D11).
--
-- The gateways the platform can take payments through, configured by the Super Admin. Credentials are stored
-- only encrypted; the key is a deployment secret, never here. At most one gateway is active, and only an
-- enabled, configured one. An invoice keeps the gateway its first checkout used, and every checkout order for
-- it goes through that same gateway — switching the active gateway affects only new invoices.

-- CreateTable
CREATE TABLE "PaymentGatewayConfig" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "provider" TEXT NOT NULL CHECK ("provider" IN ('razorpay', 'vyapargateway')),
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "isActive" BOOLEAN NOT NULL DEFAULT false,
    "environment" TEXT NOT NULL DEFAULT 'test' CHECK ("environment" IN ('test', 'live')),
    "credentialsCipher" TEXT,
    "credentialsKeyId" TEXT,
    "credentialHint" TEXT NOT NULL DEFAULT '{}',
    "version" INTEGER NOT NULL DEFAULT 1 CHECK (typeof("version") = 'integer' AND "version" >= 1),
    "configuredAt" DATETIME,
    "updatedById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Credentials and the key that sealed them come together, or not at all.
    CHECK (("credentialsCipher" IS NULL) = ("credentialsKeyId" IS NULL)),
    -- Only an enabled, configured gateway can be the active one.
    CHECK ("isActive" = 0 OR ("enabled" = 1 AND "credentialsCipher" IS NOT NULL))
);

-- CreateIndex
CREATE UNIQUE INDEX "PaymentGatewayConfig_provider_key" ON "PaymentGatewayConfig"("provider");

-- Exactly one active gateway at most.
CREATE UNIQUE INDEX "PaymentGatewayConfig_one_active" ON "PaymentGatewayConfig"("isActive") WHERE "isActive" = 1;

-- A gateway row is never deleted: payments made through it must keep resolving it.
CREATE TRIGGER "PaymentGatewayConfig_no_delete" BEFORE DELETE ON "PaymentGatewayConfig"
BEGIN
    SELECT RAISE(ABORT, 'PaymentGatewayConfig: a gateway is disabled, never deleted');
END;

-- Every checkout order for an invoice goes through the gateway the invoice is pinned to.
CREATE TRIGGER "PaymentOrder_invoice_gateway" BEFORE INSERT ON "PaymentOrder"
WHEN EXISTS (SELECT 1 FROM "Invoice" i WHERE i."id" = NEW."invoiceId" AND i."provider" IS NOT NULL AND i."provider" <> NEW."provider")
BEGIN
    SELECT RAISE(ABORT, 'PaymentOrder: an invoice is paid through the gateway it was started with');
END;

-- Backfill: an existing invoice is pinned to a gateway only where its own checkout orders prove which one —
-- exactly one distinct provider among them. An invoice with no checkout order has not chosen a gateway and
-- stays unpinned (it pins at its first checkout); an invoice whose orders name more than one provider would
-- stay unpinned for a human decision (none exist: before SAAS-017 there was one gateway). Invoice_fixed
-- allows setting provider exactly once, from NULL.
UPDATE "Invoice"
SET "provider" = (SELECT o."provider" FROM "PaymentOrder" o WHERE o."invoiceId" = "Invoice"."id" LIMIT 1)
WHERE "provider" IS NULL
  AND (SELECT COUNT(DISTINCT o."provider") FROM "PaymentOrder" o WHERE o."invoiceId" = "Invoice"."id") = 1;
