-- SAAS-009 · Every academy-owned table indexes its tenantId, so every scoped query has an index to use.

-- CreateIndex
CREATE INDEX "PaymentOrder_tenantId_createdAt_idx" ON "PaymentOrder"("tenantId", "createdAt");
