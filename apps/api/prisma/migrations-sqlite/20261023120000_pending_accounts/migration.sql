-- Learners and instructors who register themselves verify their email before any account exists.

-- AlterTable
ALTER TABLE "PendingSignup" ADD COLUMN "sendCount" INTEGER NOT NULL DEFAULT 1;

-- CreateTable
CREATE TABLE "PendingAccount" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "title" TEXT,
    "passwordHash" TEXT NOT NULL,
    "codeHash" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "sendCount" INTEGER NOT NULL DEFAULT 1,
    "expiresAt" DATETIME NOT NULL,
    "lastSentAt" DATETIME NOT NULL,
    "consumedAt" DATETIME,
    "invitationId" TEXT,
    "courseId" TEXT,
    "createdUserId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PendingAccount_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "PendingAccount_tenantId_email_idx" ON "PendingAccount"("tenantId", "email");

-- CreateIndex
CREATE INDEX "PendingAccount_email_idx" ON "PendingAccount"("email");

-- CreateIndex
CREATE INDEX "PendingAccount_expiresAt_idx" ON "PendingAccount"("expiresAt");

-- A self-registration is for a learner or an instructor — never an admin — and keeps its academy, role and address.
CREATE TRIGGER "PendingAccount_role" BEFORE INSERT ON "PendingAccount"
WHEN NEW."role" NOT IN ('student', 'instructor')
BEGIN
  SELECT RAISE(ABORT, 'A self-registration is for a learner or an instructor.');
END;

CREATE TRIGGER "PendingAccount_fixed_scope" BEFORE UPDATE OF "tenantId", "role", "email" ON "PendingAccount"
WHEN NEW."tenantId" IS NOT OLD."tenantId" OR NEW."role" IS NOT OLD."role" OR NEW."email" IS NOT OLD."email"
BEGIN
  SELECT RAISE(ABORT, 'A self-registration keeps its academy, role and address.');
END;
