-- CreateTable
CREATE TABLE "AdminPermission" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "grantedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "grantedBy" TEXT,
    CONSTRAINT "AdminPermission_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "AdminPermission_userId_idx" ON "AdminPermission"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "AdminPermission_userId_key_key" ON "AdminPermission"("userId", "key");
