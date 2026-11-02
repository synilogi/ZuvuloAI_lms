-- The affiliate program's earnings (docs/15 MLM-004 to MLM-007): matching, commissions, ranks, rewards, wallets, KYC,
-- withdrawals and payout batches. Additive: no existing table changes. Ledgers refuse edits and deletes by trigger.

CREATE TABLE "MlmMatchingRun" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "affiliateId" TEXT NOT NULL,
    "runDate" TEXT NOT NULL,
    "planVersionId" TEXT NOT NULL,
    "rankOrderAtRun" INTEGER NOT NULL,
    "capBandKey" TEXT NOT NULL,
    "availableA" BIGINT NOT NULL,
    "availableB" BIGINT NOT NULL,
    "matchedCv" BIGINT NOT NULL,
    "grossIncome" BIGINT NOT NULL,
    "dailyCap" BIGINT NOT NULL,
    "cappedIncome" BIGINT NOT NULL,
    "flushedCv" BIGINT NOT NULL,
    "carryAAfter" BIGINT NOT NULL,
    "carryBAfter" BIGINT NOT NULL,
    "heldByCeiling" BIGINT NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmMatchingRun_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmMatchingRun_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "MlmMatchingRun_affiliateId_runDate_key" ON "MlmMatchingRun"("affiliateId", "runDate");
CREATE INDEX "MlmMatchingRun_tenantId_runDate_idx" ON "MlmMatchingRun"("tenantId", "runDate");

CREATE TABLE "MlmRankHistory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "affiliateId" TEXT NOT NULL,
    "tierOrder" INTEGER NOT NULL,
    "tierName" TEXT NOT NULL,
    "lifetimeA" BIGINT NOT NULL,
    "lifetimeB" BIGINT NOT NULL,
    "planVersionId" TEXT NOT NULL,
    "achievedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmRankHistory_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmRankHistory_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "MlmRankHistory_affiliateId_tierOrder_key" ON "MlmRankHistory"("affiliateId", "tierOrder");
CREATE INDEX "MlmRankHistory_tenantId_achievedAt_idx" ON "MlmRankHistory"("tenantId", "achievedAt");

CREATE TABLE "MlmReward" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "affiliateId" TEXT NOT NULL,
    "rankHistoryId" TEXT NOT NULL,
    "tierOrder" INTEGER NOT NULL,
    "tierName" TEXT NOT NULL,
    "groupCv" BIGINT NOT NULL,
    "kind" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "capAmount" BIGINT,
    "vestingDays" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'qualified',
    "vestsAt" DATETIME,
    "note" TEXT,
    "needsReview" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmReward_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmReward_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "MlmReward_rankHistoryId_key" ON "MlmReward"("rankHistoryId");
CREATE INDEX "MlmReward_tenantId_status_idx" ON "MlmReward"("tenantId", "status");
CREATE INDEX "MlmReward_affiliateId_idx" ON "MlmReward"("affiliateId");

CREATE TABLE "MlmCommission" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "affiliateId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "status" TEXT NOT NULL,
    "holdReason" TEXT,
    "period" TEXT,
    "heldPeriod" TEXT,
    "runId" TEXT,
    "rewardId" TEXT,
    "orderId" TEXT,
    "planVersionId" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "settledAt" DATETIME,
    CONSTRAINT "MlmCommission_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmCommission_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX "MlmCommission_tenantId_status_createdAt_idx" ON "MlmCommission"("tenantId", "status", "createdAt");
CREATE INDEX "MlmCommission_tenantId_period_idx" ON "MlmCommission"("tenantId", "period");
CREATE INDEX "MlmCommission_affiliateId_createdAt_idx" ON "MlmCommission"("affiliateId", "createdAt");
-- One reversal per order and member, so a repeated reversal cannot claw back twice.
CREATE UNIQUE INDEX "MlmCommission_one_reversal" ON "MlmCommission"("orderId", "affiliateId") WHERE "kind" = 'reversal';

CREATE TABLE "MlmWallet" (
    "affiliateId" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "available" BIGINT NOT NULL DEFAULT 0,
    "held" BIGINT NOT NULL DEFAULT 0,
    "paid" BIGINT NOT NULL DEFAULT 0,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmWallet_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmWallet_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX "MlmWallet_tenantId_idx" ON "MlmWallet"("tenantId");

CREATE TABLE "MlmWalletEntry" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "affiliateId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "availableDelta" BIGINT NOT NULL DEFAULT 0,
    "heldDelta" BIGINT NOT NULL DEFAULT 0,
    "paidDelta" BIGINT NOT NULL DEFAULT 0,
    "commissionId" TEXT,
    "withdrawalId" TEXT,
    "note" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmWalletEntry_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmWalletEntry_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX "MlmWalletEntry_tenantId_idx" ON "MlmWalletEntry"("tenantId");
CREATE INDEX "MlmWalletEntry_affiliateId_createdAt_idx" ON "MlmWalletEntry"("affiliateId", "createdAt");
-- A commission reaches a wallet once; a withdrawal writes each of its entry types once.
CREATE UNIQUE INDEX "MlmWalletEntry_one_per_commission" ON "MlmWalletEntry"("commissionId") WHERE "commissionId" IS NOT NULL;
CREATE UNIQUE INDEX "MlmWalletEntry_one_per_withdrawal_type" ON "MlmWalletEntry"("withdrawalId", "type") WHERE "withdrawalId" IS NOT NULL;

CREATE TABLE "MlmKyc" (
    "affiliateId" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'submitted',
    "legalName" TEXT NOT NULL,
    "sealed" TEXT NOT NULL,
    "sealedKeyId" TEXT NOT NULL,
    "panLast4" TEXT NOT NULL,
    "bankAccountLast4" TEXT NOT NULL,
    "ifsc" TEXT NOT NULL,
    "accountHolder" TEXT NOT NULL,
    "upiId" TEXT,
    "documentIdsJson" TEXT NOT NULL DEFAULT '[]',
    "rejectionReason" TEXT,
    "submittedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt" DATETIME,
    CONSTRAINT "MlmKyc_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmKyc_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX "MlmKyc_tenantId_status_idx" ON "MlmKyc"("tenantId", "status");

CREATE TABLE "MlmPayoutBatch" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "reference" TEXT NOT NULL,
    "count" INTEGER NOT NULL,
    "total" BIGINT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "exportedAt" DATETIME,
    "closedAt" DATETIME,
    CONSTRAINT "MlmPayoutBatch_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "MlmPayoutBatch_reference_key" ON "MlmPayoutBatch"("reference");
CREATE INDEX "MlmPayoutBatch_tenantId_idx" ON "MlmPayoutBatch"("tenantId");

CREATE TABLE "MlmWithdrawal" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "affiliateId" TEXT NOT NULL,
    "amount" BIGINT NOT NULL,
    "tdsAmount" BIGINT NOT NULL DEFAULT 0,
    "netAmount" BIGINT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'requested',
    "bankSnapshotJson" TEXT NOT NULL,
    "sealed" TEXT NOT NULL,
    "sealedKeyId" TEXT NOT NULL,
    "payoutBatchId" TEXT,
    "reference" TEXT,
    "rejectionReason" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "decidedAt" DATETIME,
    "paidAt" DATETIME,
    CONSTRAINT "MlmWithdrawal_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmWithdrawal_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX "MlmWithdrawal_tenantId_status_idx" ON "MlmWithdrawal"("tenantId", "status");
CREATE INDEX "MlmWithdrawal_affiliateId_idx" ON "MlmWithdrawal"("affiliateId");
-- One open request per member.
CREATE UNIQUE INDEX "MlmWithdrawal_one_open" ON "MlmWithdrawal"("affiliateId") WHERE "status" IN ('requested', 'approved', 'processing');

-- Immutable ledgers.
CREATE TRIGGER "MlmMatchingRun_no_update" BEFORE UPDATE ON "MlmMatchingRun" BEGIN SELECT RAISE(ABORT, 'A matching run is never changed.'); END;
CREATE TRIGGER "MlmMatchingRun_no_delete" BEFORE DELETE ON "MlmMatchingRun" BEGIN SELECT RAISE(ABORT, 'A matching run is never deleted.'); END;
CREATE TRIGGER "MlmRankHistory_no_update" BEFORE UPDATE ON "MlmRankHistory" BEGIN SELECT RAISE(ABORT, 'Rank history is never changed.'); END;
CREATE TRIGGER "MlmRankHistory_no_delete" BEFORE DELETE ON "MlmRankHistory" BEGIN SELECT RAISE(ABORT, 'Rank history is never deleted.'); END;
CREATE TRIGGER "MlmWalletEntry_no_update" BEFORE UPDATE ON "MlmWalletEntry" BEGIN SELECT RAISE(ABORT, 'A wallet entry is never changed.'); END;
CREATE TRIGGER "MlmWalletEntry_no_delete" BEFORE DELETE ON "MlmWalletEntry" BEGIN SELECT RAISE(ABORT, 'A wallet entry is never deleted.'); END;
CREATE TRIGGER "MlmCommission_no_delete" BEFORE DELETE ON "MlmCommission" BEGIN SELECT RAISE(ABORT, 'A commission is never deleted.'); END;
-- A commission's money never changes. Only a held one moves on: released to a wallet, or written off.
CREATE TRIGGER "MlmCommission_money_fixed" BEFORE UPDATE ON "MlmCommission"
WHEN OLD."status" <> 'held' OR NEW."status" NOT IN ('paid_to_wallet', 'written_off') OR NEW."amount" <> OLD."amount" OR NEW."kind" <> OLD."kind" OR NEW."affiliateId" <> OLD."affiliateId"
BEGIN SELECT RAISE(ABORT, 'A commission is fixed: only a held one can be released or written off.'); END;
CREATE TRIGGER "MlmWithdrawal_paid_final" BEFORE UPDATE OF "status" ON "MlmWithdrawal"
WHEN OLD."status" = 'paid' AND NEW."status" <> 'paid'
BEGIN SELECT RAISE(ABORT, 'A paid withdrawal stays paid.'); END;
CREATE TRIGGER "MlmWithdrawal_no_delete" BEFORE DELETE ON "MlmWithdrawal" BEGIN SELECT RAISE(ABORT, 'A withdrawal is never deleted.'); END;
