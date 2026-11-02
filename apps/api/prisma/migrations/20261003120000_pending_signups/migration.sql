-- CreateTable
CREATE TABLE "PendingSignup" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "email" TEXT NOT NULL,
    "adminName" TEXT NOT NULL,
    "academyName" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "codeHash" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "expiresAt" DATETIME NOT NULL,
    "lastSentAt" DATETIME NOT NULL,
    "consumedAt" DATETIME,
    "createdAcademyId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE INDEX "PendingSignup_email_idx" ON "PendingSignup"("email");

-- CreateIndex
CREATE INDEX "PendingSignup_expiresAt_idx" ON "PendingSignup"("expiresAt");

