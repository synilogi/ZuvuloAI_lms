-- MLM-002 · Binary placement history (docs/15 §4.3). Every placement and move of an affiliate, append-only, so the
-- tree's shape at any moment can be reconstructed and a manual move names who made it and why.

-- CreateTable
CREATE TABLE "MlmPlacementHistory" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "affiliateId" TEXT NOT NULL,
    "fromParentId" TEXT,
    "fromLeg" TEXT,
    "toParentId" TEXT,
    "toLeg" TEXT,
    "reason" TEXT NOT NULL,
    "actorType" TEXT NOT NULL DEFAULT 'system',
    "actorId" TEXT,
    "note" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MlmPlacementHistory_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmPlacementHistory_affiliateId_fkey" FOREIGN KEY ("affiliateId") REFERENCES "Affiliate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "MlmPlacementHistory_reason_check" CHECK ("reason" IN ('sponsor-direct', 'spillover', 'manual', 'root')),
    CONSTRAINT "MlmPlacementHistory_actorType_check" CHECK ("actorType" IN ('system', 'user')),
    CONSTRAINT "MlmPlacementHistory_fromLeg_check" CHECK ("fromLeg" IS NULL OR "fromLeg" IN ('A', 'B')),
    CONSTRAINT "MlmPlacementHistory_toLeg_check" CHECK ("toLeg" IS NULL OR "toLeg" IN ('A', 'B')),
    CONSTRAINT "MlmPlacementHistory_from_pair_check" CHECK (("fromParentId" IS NULL) = ("fromLeg" IS NULL)),
    CONSTRAINT "MlmPlacementHistory_to_pair_check" CHECK (("toParentId" IS NULL) = ("toLeg" IS NULL))
);

-- CreateIndex
CREATE INDEX "MlmPlacementHistory_tenantId_idx" ON "MlmPlacementHistory"("tenantId");
CREATE INDEX "MlmPlacementHistory_tenantId_createdAt_idx" ON "MlmPlacementHistory"("tenantId", "createdAt");
CREATE INDEX "MlmPlacementHistory_affiliateId_idx" ON "MlmPlacementHistory"("affiliateId");

-- Append-only.
CREATE TRIGGER "MlmPlacementHistory_no_update" BEFORE UPDATE ON "MlmPlacementHistory"
BEGIN
    SELECT RAISE(ABORT, 'Placement history is immutable');
END;
CREATE TRIGGER "MlmPlacementHistory_no_delete" BEFORE DELETE ON "MlmPlacementHistory"
BEGIN
    SELECT RAISE(ABORT, 'Placement history is never deleted');
END;
