-- CreateTable
CREATE TABLE "Invitation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'student',
    "tokenHash" TEXT NOT NULL,
    "email" TEXT,
    "createdById" TEXT,
    "expiresAt" DATETIME NOT NULL,
    "usedAt" DATETIME,
    "usedByUserId" TEXT,
    "revokedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Invitation_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "Invitation_tokenHash_key" ON "Invitation"("tokenHash");

-- CreateIndex
CREATE INDEX "Invitation_tenantId_createdAt_idx" ON "Invitation"("tenantId", "createdAt");


-- An invitation is for a learner, and stays in the workspace it was made for.
CREATE TRIGGER "Invitation_role_student" BEFORE INSERT ON "Invitation"
WHEN NEW."role" <> 'student'
BEGIN
  SELECT RAISE(ABORT, 'An invitation is for a learner.');
END;

CREATE TRIGGER "Invitation_fixed_scope" BEFORE UPDATE OF "tenantId", "role", "tokenHash", "email" ON "Invitation"
WHEN NEW."tenantId" IS NOT OLD."tenantId" OR NEW."role" IS NOT OLD."role" OR NEW."tokenHash" IS NOT OLD."tokenHash" OR NEW."email" IS NOT OLD."email"
BEGIN
  SELECT RAISE(ABORT, 'An invitation keeps its workspace, role, token and address.');
END;
