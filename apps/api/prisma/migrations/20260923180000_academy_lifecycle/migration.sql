-- SAAS-019: academy lifecycle. Additive only: two nullable columns on Tenant, so every existing academy
-- keeps its status ('active') and nothing is rewritten.
ALTER TABLE "Tenant" ADD COLUMN "statusReason" TEXT;
ALTER TABLE "Tenant" ADD COLUMN "statusChangedAt" DATETIME;
