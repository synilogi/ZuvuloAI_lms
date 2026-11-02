-- CreateTable
CREATE TABLE "MediaAsset" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "ownerUserId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "originalName" TEXT NOT NULL,
    "mime" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "storageName" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "MediaAsset_storageName_key" ON "MediaAsset"("storageName");

-- CreateIndex
CREATE INDEX "MediaAsset_ownerUserId_idx" ON "MediaAsset"("ownerUserId");
