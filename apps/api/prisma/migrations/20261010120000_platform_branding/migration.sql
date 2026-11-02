-- The platform's own logo and favicon, replaced by the Super Admin. Additive: with no row, every client shows the
-- built-in ZuviloAI asset, exactly as before. No academy row is read or changed.

-- CreateTable
CREATE TABLE "PlatformBrandAsset" (
    "kind" TEXT NOT NULL PRIMARY KEY CHECK ("kind" IN ('logo', 'favicon')),
    "storageName" TEXT NOT NULL,
    "originalName" TEXT NOT NULL,
    "mime" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL CHECK ("sizeBytes" > 0),
    "width" INTEGER NOT NULL CHECK ("width" > 0),
    "height" INTEGER NOT NULL CHECK ("height" > 0),
    "updatedById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "PlatformBrandAsset_storageName_key" ON "PlatformBrandAsset"("storageName");
