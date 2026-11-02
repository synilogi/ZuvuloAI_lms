-- SAAS-022: job leases. Additive only: one new platform table.

-- CreateTable
CREATE TABLE "JobLease" (
    "job" TEXT NOT NULL PRIMARY KEY,
    "holder" TEXT NOT NULL,
    "acquiredAt" DATETIME NOT NULL,
    "expiresAt" DATETIME NOT NULL,
    "lastRunAt" DATETIME,
    "lastOutcome" TEXT,
    "lastHolder" TEXT
);

