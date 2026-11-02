-- MLM-001 · Affiliates (docs/15 §4.3). Academy-owned: an affiliate is a learner of the program academy. The sponsor
-- (who referred them) and the binary placement (where they sit in the tree) are separate relations, both on this row;
-- placement is written by the genealogy module (MLM-002). The referral code is unique across the platform because a
-- link carries it alone. A pending registration remembers the referral so the account is made with it.

-- AlterTable
ALTER TABLE "PendingAccount" ADD COLUMN "referralCode" TEXT;
ALTER TABLE "PendingAccount" ADD COLUMN "preferredLeg" TEXT;

-- CreateTable
CREATE TABLE "Affiliate" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "sponsorId" TEXT,
    "placementParentId" TEXT,
    "placementLeg" TEXT,
    "pathIdsJson" TEXT NOT NULL DEFAULT '[]',
    "depth" INTEGER NOT NULL DEFAULT 0,
    "preferredLeg" TEXT NOT NULL DEFAULT 'A',
    "activatedAt" DATETIME,
    "activationPurchaseId" TEXT,
    "kycStatus" TEXT NOT NULL DEFAULT 'none',
    "currentRankOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Affiliate_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Affiliate_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Affiliate_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Affiliate_sponsorId_fkey" FOREIGN KEY ("sponsorId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Affiliate_placementParentId_fkey" FOREIGN KEY ("placementParentId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Affiliate_status_check" CHECK ("status" IN ('pending', 'active', 'suspended', 'terminated')),
    CONSTRAINT "Affiliate_code_check" CHECK (length("code") = 8 AND "code" = upper("code")),
    CONSTRAINT "Affiliate_placementLeg_check" CHECK ("placementLeg" IS NULL OR "placementLeg" IN ('A', 'B')),
    CONSTRAINT "Affiliate_placement_pair_check" CHECK (("placementParentId" IS NULL) = ("placementLeg" IS NULL)),
    CONSTRAINT "Affiliate_preferredLeg_check" CHECK ("preferredLeg" IN ('A', 'B')),
    CONSTRAINT "Affiliate_depth_check" CHECK (typeof("depth") = 'integer' AND "depth" >= 0),
    CONSTRAINT "Affiliate_self_check" CHECK ("placementParentId" IS NOT "id" AND "sponsorId" IS NOT "id"),
    CONSTRAINT "Affiliate_kycStatus_check" CHECK ("kycStatus" IN ('none', 'submitted', 'verified', 'rejected')),
    CONSTRAINT "Affiliate_rank_check" CHECK (typeof("currentRankOrder") = 'integer' AND "currentRankOrder" >= 0),
    CONSTRAINT "Affiliate_activated_check" CHECK ("status" <> 'pending' OR "activatedAt" IS NULL)
);

-- CreateIndex
CREATE UNIQUE INDEX "Affiliate_userId_key" ON "Affiliate"("userId");
CREATE UNIQUE INDEX "Affiliate_studentId_key" ON "Affiliate"("studentId");
CREATE UNIQUE INDEX "Affiliate_code_key" ON "Affiliate"("code");
-- Two positions per node, enforced by the database and not only by the placement code.
CREATE UNIQUE INDEX "Affiliate_placementParentId_placementLeg_key" ON "Affiliate"("placementParentId", "placementLeg");
CREATE INDEX "Affiliate_tenantId_idx" ON "Affiliate"("tenantId");
CREATE INDEX "Affiliate_tenantId_status_idx" ON "Affiliate"("tenantId", "status");
CREATE INDEX "Affiliate_sponsorId_idx" ON "Affiliate"("sponsorId");
CREATE INDEX "Affiliate_placementParentId_idx" ON "Affiliate"("placementParentId");

-- An affiliate belongs to one person and one academy for good; the code is the credential on every link ever shared.
CREATE TRIGGER "Affiliate_identity_fixed" BEFORE UPDATE OF "tenantId", "userId", "studentId", "code" ON "Affiliate"
WHEN NEW."tenantId" IS NOT OLD."tenantId" OR NEW."userId" IS NOT OLD."userId" OR NEW."studentId" IS NOT OLD."studentId" OR NEW."code" IS NOT OLD."code"
BEGIN
    SELECT RAISE(ABORT, 'An affiliate''s academy, person and code cannot change');
END;

-- Termination is final (§6.2): the position stays so the tree is never re-shaped.
CREATE TRIGGER "Affiliate_terminated_is_final" BEFORE UPDATE OF "status" ON "Affiliate"
WHEN OLD."status" = 'terminated' AND NEW."status" <> 'terminated'
BEGIN
    SELECT RAISE(ABORT, 'A terminated affiliate cannot be reinstated');
END;

-- A sponsor or parent must be in the same academy: a tree never crosses an isolation boundary.
CREATE TRIGGER "Affiliate_same_academy_insert" BEFORE INSERT ON "Affiliate"
WHEN (NEW."sponsorId" IS NOT NULL AND (SELECT "tenantId" FROM "Affiliate" WHERE "id" = NEW."sponsorId") IS NOT NEW."tenantId")
  OR (NEW."placementParentId" IS NOT NULL AND (SELECT "tenantId" FROM "Affiliate" WHERE "id" = NEW."placementParentId") IS NOT NEW."tenantId")
BEGIN
    SELECT RAISE(ABORT, 'An affiliate''s sponsor and placement parent must be in the same academy');
END;
CREATE TRIGGER "Affiliate_same_academy_update" BEFORE UPDATE OF "sponsorId", "placementParentId" ON "Affiliate"
WHEN (NEW."sponsorId" IS NOT NULL AND (SELECT "tenantId" FROM "Affiliate" WHERE "id" = NEW."sponsorId") IS NOT NEW."tenantId")
  OR (NEW."placementParentId" IS NOT NULL AND (SELECT "tenantId" FROM "Affiliate" WHERE "id" = NEW."placementParentId") IS NOT NEW."tenantId")
BEGIN
    SELECT RAISE(ABORT, 'An affiliate''s sponsor and placement parent must be in the same academy');
END;

-- Affiliates are never deleted: ledgers and the tree name them.
CREATE TRIGGER "Affiliate_no_delete" BEFORE DELETE ON "Affiliate"
BEGIN
    SELECT RAISE(ABORT, 'An affiliate is never deleted; terminate it instead');
END;
