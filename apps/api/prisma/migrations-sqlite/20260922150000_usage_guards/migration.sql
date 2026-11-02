-- SAAS-011 · The guard row every limit-consuming write takes first, so a limit check cannot be raced (lib/usage.ts).
-- It holds no figure — usage is counted live — and only its touchedAt ever changes.

-- CreateTable
CREATE TABLE "UsageGuard" (
    "tenantId" TEXT NOT NULL,
    "limitKey" TEXT NOT NULL,
    "touchedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY ("tenantId", "limitKey"),
    CONSTRAINT "UsageGuard_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

