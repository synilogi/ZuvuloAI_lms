-- SAAS-008 · Invoices, payments, refunds and payment methods (subscriptions.md §14–16, §29, §37, §38).
--
-- Financial history is append-only. An invoice is fixed at issue — only its status moves, open → paid
-- (with a paid payment for its exact total) or open → void. A payment is written pending, paid or failed;
-- a pending one settles once; a paid or failed one is never updated. A refund is its own row and can
-- never take more than was paid. Nothing here is ever deleted, and there is no column a card number could
-- be stored in — a payment method is a provider reference and masked display data.

-- CreateTable
CREATE TABLE "InvoiceSequence" (
    "series" TEXT NOT NULL PRIMARY KEY,
    "next" INTEGER NOT NULL,
    CONSTRAINT "InvoiceSequence_next_check" CHECK (typeof("next") = 'integer' AND "next" >= 1)
);

-- CreateTable
CREATE TABLE "Invoice" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "purpose" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "subscriptionId" TEXT,
    "planChangeId" TEXT,
    "currency" TEXT NOT NULL,
    "subtotal" INTEGER NOT NULL,
    "taxTotal" INTEGER NOT NULL,
    "total" INTEGER NOT NULL,
    "inclusive" BOOLEAN NOT NULL,
    "taxRuleId" TEXT,
    "linesJson" TEXT NOT NULL,
    "taxLinesJson" TEXT NOT NULL,
    "billedToJson" TEXT NOT NULL,
    "periodStartAt" DATETIME,
    "periodEndAt" DATETIME,
    "issuedAt" DATETIME NOT NULL,
    "dueAt" DATETIME NOT NULL,
    "paidAt" DATETIME,
    "voidedAt" DATETIME,
    "voidReason" TEXT,
    "provider" TEXT,
    "providerInvoiceId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Invoice_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Invoice_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "Subscription" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Invoice_planChangeId_fkey" FOREIGN KEY ("planChangeId") REFERENCES "PlanChange" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Invoice_purpose_check" CHECK ("purpose" IN ('new_subscription', 'renewal', 'plan_change')),
    CONSTRAINT "Invoice_status_check" CHECK ("status" IN ('open', 'paid', 'void')),
    CONSTRAINT "Invoice_currency_check" CHECK ("currency" GLOB '[A-Z][A-Z][A-Z]'),
    CONSTRAINT "Invoice_money_check" CHECK (typeof("subtotal") = 'integer' AND "subtotal" >= 0 AND typeof("taxTotal") = 'integer' AND "taxTotal" >= 0 AND typeof("total") = 'integer' AND "total" = "subtotal" + "taxTotal"),
    CONSTRAINT "Invoice_number_check" CHECK ("number" GLOB 'INV-[0-9][0-9][0-9][0-9]-[0-9]*')
);

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "invoiceId" TEXT,
    "subscriptionId" TEXT,
    "provider" TEXT NOT NULL,
    "providerPaymentId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "failureCode" TEXT,
    "failureMessage" TEXT,
    "methodKind" TEXT,
    "methodBrand" TEXT,
    "methodLast4" TEXT,
    "paidAt" DATETIME,
    "failedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Payment_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Payment_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "Invoice" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Payment_subscriptionId_fkey" FOREIGN KEY ("subscriptionId") REFERENCES "Subscription" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Payment_status_check" CHECK ("status" IN ('pending', 'paid', 'failed')),
    CONSTRAINT "Payment_amount_check" CHECK (typeof("amount") = 'integer' AND "amount" >= 0),
    CONSTRAINT "Payment_currency_check" CHECK ("currency" GLOB '[A-Z][A-Z][A-Z]'),
    CONSTRAINT "Payment_last4_check" CHECK ("methodLast4" IS NULL OR "methodLast4" GLOB '[0-9][0-9][0-9][0-9]'),
    CONSTRAINT "Payment_settled_check" CHECK (("status" = 'paid') = ("paidAt" IS NOT NULL) AND ("status" = 'failed') = ("failedAt" IS NOT NULL))
);

-- CreateTable
CREATE TABLE "Refund" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerRefundId" TEXT,
    "requestedById" TEXT,
    "failureMessage" TEXT,
    "settledAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Refund_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Refund_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Refund_status_check" CHECK ("status" IN ('pending', 'succeeded', 'failed')),
    CONSTRAINT "Refund_amount_check" CHECK (typeof("amount") = 'integer' AND "amount" >= 1),
    CONSTRAINT "Refund_reason_check" CHECK (length(trim("reason")) >= 3)
);

-- CreateTable
CREATE TABLE "PaymentMethod" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerMethodRef" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "brand" TEXT NOT NULL,
    "last4" TEXT,
    "expMonth" INTEGER,
    "expYear" INTEGER,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "removedAt" DATETIME,
    CONSTRAINT "PaymentMethod_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PaymentMethod_kind_check" CHECK ("kind" IN ('card', 'upi', 'netbanking', 'mandate', 'invoice')),
    CONSTRAINT "PaymentMethod_last4_check" CHECK ("last4" IS NULL OR "last4" GLOB '[0-9][0-9][0-9][0-9]'),
    CONSTRAINT "PaymentMethod_expiry_check" CHECK (("expMonth" IS NULL OR "expMonth" BETWEEN 1 AND 12) AND ("expYear" IS NULL OR "expYear" BETWEEN 2000 AND 2100)),
    CONSTRAINT "PaymentMethod_brand_check" CHECK (length("brand") BETWEEN 1 AND 40 AND "brand" NOT GLOB '*[0-9][0-9][0-9][0-9][0-9][0-9]*')
);

-- CreateIndex
CREATE UNIQUE INDEX "Invoice_number_key" ON "Invoice"("number");

-- CreateIndex
CREATE INDEX "Invoice_tenantId_issuedAt_idx" ON "Invoice"("tenantId", "issuedAt");

-- CreateIndex
CREATE INDEX "Invoice_subscriptionId_idx" ON "Invoice"("subscriptionId");

-- CreateIndex
CREATE INDEX "Invoice_status_idx" ON "Invoice"("status");

-- CreateIndex
CREATE UNIQUE INDEX "Invoice_provider_providerInvoiceId_key" ON "Invoice"("provider", "providerInvoiceId");

-- CreateIndex
CREATE INDEX "Payment_tenantId_createdAt_idx" ON "Payment"("tenantId", "createdAt");

-- CreateIndex
CREATE INDEX "Payment_invoiceId_idx" ON "Payment"("invoiceId");

-- CreateIndex
CREATE UNIQUE INDEX "Payment_provider_providerPaymentId_key" ON "Payment"("provider", "providerPaymentId");

-- CreateIndex
CREATE INDEX "Refund_tenantId_createdAt_idx" ON "Refund"("tenantId", "createdAt");

-- CreateIndex
CREATE INDEX "Refund_paymentId_idx" ON "Refund"("paymentId");

-- CreateIndex
CREATE UNIQUE INDEX "Refund_provider_providerRefundId_key" ON "Refund"("provider", "providerRefundId");

-- CreateIndex
CREATE INDEX "PaymentMethod_tenantId_idx" ON "PaymentMethod"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "PaymentMethod_provider_providerMethodRef_key" ON "PaymentMethod"("provider", "providerMethodRef");

-- ─── Invoices ───

CREATE TRIGGER "Invoice_fixed" BEFORE UPDATE ON "Invoice"
WHEN NEW."number" IS NOT OLD."number" OR NEW."tenantId" IS NOT OLD."tenantId" OR NEW."purpose" IS NOT OLD."purpose"
  OR NEW."subscriptionId" IS NOT OLD."subscriptionId" OR NEW."planChangeId" IS NOT OLD."planChangeId" OR NEW."currency" IS NOT OLD."currency"
  OR NEW."subtotal" IS NOT OLD."subtotal" OR NEW."taxTotal" IS NOT OLD."taxTotal" OR NEW."total" IS NOT OLD."total"
  OR NEW."inclusive" IS NOT OLD."inclusive" OR NEW."taxRuleId" IS NOT OLD."taxRuleId" OR NEW."linesJson" IS NOT OLD."linesJson"
  OR NEW."taxLinesJson" IS NOT OLD."taxLinesJson" OR NEW."billedToJson" IS NOT OLD."billedToJson"
  OR NEW."periodStartAt" IS NOT OLD."periodStartAt" OR NEW."periodEndAt" IS NOT OLD."periodEndAt"
  OR NEW."issuedAt" IS NOT OLD."issuedAt" OR NEW."dueAt" IS NOT OLD."dueAt" OR NEW."createdAt" IS NOT OLD."createdAt"
  OR (OLD."provider" IS NOT NULL AND NEW."provider" IS NOT OLD."provider")
  OR (OLD."providerInvoiceId" IS NOT NULL AND NEW."providerInvoiceId" IS NOT OLD."providerInvoiceId")
BEGIN
    SELECT RAISE(ABORT, 'An issued invoice is never altered');
END;

CREATE TRIGGER "Invoice_insert_open" BEFORE INSERT ON "Invoice"
WHEN NEW."status" <> 'open' OR NEW."paidAt" IS NOT NULL OR NEW."voidedAt" IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'An invoice is issued open');
END;

CREATE TRIGGER "Invoice_status_path" BEFORE UPDATE OF "status", "paidAt", "voidedAt", "voidReason" ON "Invoice"
WHEN (NEW."status" IS NOT OLD."status" AND NOT (OLD."status" = 'open' AND NEW."status" IN ('paid', 'void')))
  OR (OLD."status" <> 'open' AND (NEW."paidAt" IS NOT OLD."paidAt" OR NEW."voidedAt" IS NOT OLD."voidedAt" OR NEW."voidReason" IS NOT OLD."voidReason"))
  OR (NEW."status" = 'paid' AND NEW."paidAt" IS NULL)
  OR (NEW."status" = 'void' AND (NEW."voidedAt" IS NULL OR NEW."voidReason" IS NULL))
BEGIN
    SELECT RAISE(ABORT, 'An invoice moves once: open to paid, or open to void');
END;

-- Paid only when a paid payment for exactly its total, in its currency, stands against it.
CREATE TRIGGER "Invoice_paid_by_payment" BEFORE UPDATE OF "status" ON "Invoice"
WHEN NEW."status" = 'paid' AND OLD."status" = 'open' AND NOT EXISTS (
    SELECT 1 FROM "Payment" p WHERE p."invoiceId" = NEW."id" AND p."status" = 'paid' AND p."amount" = NEW."total" AND p."currency" = NEW."currency"
)
BEGIN
    SELECT RAISE(ABORT, 'An invoice is paid only by a paid payment of its total');
END;

CREATE TRIGGER "Invoice_no_delete" BEFORE DELETE ON "Invoice"
BEGIN
    SELECT RAISE(ABORT, 'Invoices are never deleted');
END;

-- ─── Payments ───

-- What a payment was, and whose it was, never changes.
CREATE TRIGGER "Payment_fixed" BEFORE UPDATE ON "Payment"
WHEN NEW."amount" IS NOT OLD."amount" OR NEW."currency" IS NOT OLD."currency" OR NEW."provider" IS NOT OLD."provider"
  OR NEW."providerPaymentId" IS NOT OLD."providerPaymentId" OR NEW."tenantId" IS NOT OLD."tenantId"
  OR NEW."invoiceId" IS NOT OLD."invoiceId" OR NEW."subscriptionId" IS NOT OLD."subscriptionId" OR NEW."createdAt" IS NOT OLD."createdAt"
BEGIN
    SELECT RAISE(ABORT, 'A payment''s amount and references are never altered');
END;

-- A pending payment settles once; a paid or failed payment is history and is never updated.
CREATE TRIGGER "Payment_settles_once" BEFORE UPDATE ON "Payment"
WHEN OLD."status" <> 'pending' OR NEW."status" NOT IN ('paid', 'failed')
BEGIN
    SELECT RAISE(ABORT, 'A settled payment is never updated');
END;

CREATE TRIGGER "Payment_no_delete" BEFORE DELETE ON "Payment"
BEGIN
    SELECT RAISE(ABORT, 'Payments are never deleted');
END;

CREATE TRIGGER "Payment_same_tenant" BEFORE INSERT ON "Payment"
WHEN NEW."invoiceId" IS NOT NULL AND NEW."tenantId" IS NOT (SELECT "tenantId" FROM "Invoice" WHERE "id" = NEW."invoiceId")
BEGIN
    SELECT RAISE(ABORT, 'A payment belongs to its invoice''s academy');
END;

-- ─── Refunds ───

-- Against a paid payment, in its currency, and never more in total than it.
CREATE TRIGGER "Refund_within_payment" BEFORE INSERT ON "Refund"
WHEN NEW."status" <> 'pending'
  OR (SELECT "status" FROM "Payment" WHERE "id" = NEW."paymentId") IS NOT 'paid'
  OR (SELECT "currency" FROM "Payment" WHERE "id" = NEW."paymentId") IS NOT NEW."currency"
  OR (SELECT "tenantId" FROM "Payment" WHERE "id" = NEW."paymentId") IS NOT NEW."tenantId"
  OR NEW."amount" + IFNULL((SELECT sum("amount") FROM "Refund" WHERE "paymentId" = NEW."paymentId" AND "status" <> 'failed'), 0)
     > (SELECT "amount" FROM "Payment" WHERE "id" = NEW."paymentId")
BEGIN
    SELECT RAISE(ABORT, 'A refund is against a paid payment and never more than is left of it');
END;

CREATE TRIGGER "Refund_fixed" BEFORE UPDATE ON "Refund"
WHEN NEW."amount" IS NOT OLD."amount" OR NEW."currency" IS NOT OLD."currency" OR NEW."paymentId" IS NOT OLD."paymentId"
  OR NEW."tenantId" IS NOT OLD."tenantId" OR NEW."reason" IS NOT OLD."reason" OR NEW."createdAt" IS NOT OLD."createdAt"
  OR NEW."requestedById" IS NOT OLD."requestedById"
  OR OLD."status" <> 'pending' OR NEW."status" NOT IN ('succeeded', 'failed')
  OR (OLD."providerRefundId" IS NOT NULL AND NEW."providerRefundId" IS NOT OLD."providerRefundId")
BEGIN
    SELECT RAISE(ABORT, 'A refund settles once and is otherwise never altered');
END;

CREATE TRIGGER "Refund_no_delete" BEFORE DELETE ON "Refund"
BEGIN
    SELECT RAISE(ABORT, 'Refunds are never deleted');
END;

-- ─── Payment methods ───

CREATE TRIGGER "PaymentMethod_fixed" BEFORE UPDATE ON "PaymentMethod"
WHEN NEW."provider" IS NOT OLD."provider" OR NEW."providerMethodRef" IS NOT OLD."providerMethodRef" OR NEW."kind" IS NOT OLD."kind"
  OR NEW."brand" IS NOT OLD."brand" OR NEW."last4" IS NOT OLD."last4" OR NEW."tenantId" IS NOT OLD."tenantId"
BEGIN
    SELECT RAISE(ABORT, 'A payment method is replaced, never rewritten');
END;

CREATE TRIGGER "PaymentMethod_no_delete" BEFORE DELETE ON "PaymentMethod"
BEGIN
    SELECT RAISE(ABORT, 'Payment methods are removed, never deleted');
END;

-- The invoice counter only ever goes up.
CREATE TRIGGER "InvoiceSequence_up" BEFORE UPDATE ON "InvoiceSequence"
WHEN NEW."next" <= OLD."next" OR NEW."series" IS NOT OLD."series"
BEGIN
    SELECT RAISE(ABORT, 'An invoice number is never reused');
END;

CREATE TRIGGER "InvoiceSequence_no_delete" BEFORE DELETE ON "InvoiceSequence"
BEGIN
    SELECT RAISE(ABORT, 'An invoice series is never deleted');
END;

-- No double billing: one live invoice per plan change, and one per renewal period of a subscription.
CREATE UNIQUE INDEX "Invoice_one_per_plan_change" ON "Invoice"("planChangeId") WHERE "planChangeId" IS NOT NULL AND "status" <> 'void';
CREATE UNIQUE INDEX "Invoice_one_per_renewal_period" ON "Invoice"("subscriptionId", "periodStartAt") WHERE "purpose" = 'renewal' AND "status" <> 'void';
