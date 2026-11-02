-- SAAS-020: server-side sessions. Additive only: a new table and one nullable column on User, so every
-- token issued before this migration keeps working until it expires.
ALTER TABLE "User" ADD COLUMN "tokensValidAfter" DATETIME;

CREATE TABLE "UserSession" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT,
    "userId" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" DATETIME NOT NULL,
    "revokedAt" DATETIME,
    "revokedReason" TEXT,
    "userAgent" TEXT,
    CONSTRAINT "UserSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "UserSession_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX "UserSession_userId_idx" ON "UserSession"("userId");
CREATE INDEX "UserSession_tenantId_idx" ON "UserSession"("tenantId");
CREATE INDEX "UserSession_expiresAt_idx" ON "UserSession"("expiresAt");
