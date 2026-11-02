-- The public website's marketplace (docs/17): site images, posts, course bundles and their orders.
-- Additive: new tables and one nullable column. No existing row changes.
CREATE TABLE "SiteImage" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "mediaId" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "SiteImage_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "SiteImage_mediaId_fkey" FOREIGN KEY ("mediaId") REFERENCES "MediaAsset" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "SiteImage_mediaId_key" ON "SiteImage"("mediaId");
CREATE INDEX "SiteImage_tenantId_idx" ON "SiteImage"("tenantId");

CREATE TABLE "BlogPost" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "kind" TEXT NOT NULL DEFAULT 'article',
    "title" TEXT NOT NULL,
    "excerpt" TEXT NOT NULL DEFAULT '',
    "body" TEXT NOT NULL DEFAULT '',
    "coverUrl" TEXT NOT NULL DEFAULT '',
    "externalUrl" TEXT NOT NULL DEFAULT '',
    "eventAt" DATETIME,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "publishAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "BlogPost_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "BlogPost_tenantId_slug_key" ON "BlogPost"("tenantId", "slug");
CREATE INDEX "BlogPost_status_publishAt_idx" ON "BlogPost"("status", "publishAt");

CREATE TABLE "CourseBundle" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "summary" TEXT NOT NULL DEFAULT '',
    "description" TEXT NOT NULL DEFAULT '',
    "coverUrl" TEXT NOT NULL DEFAULT '',
    "price" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "publishAt" DATETIME,
    "order" INTEGER NOT NULL DEFAULT 0,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "CourseBundle_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "CourseBundle_tenantId_slug_key" ON "CourseBundle"("tenantId", "slug");

CREATE TABLE "CourseBundleCourse" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "bundleId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "CourseBundleCourse_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CourseBundleCourse_bundleId_fkey" FOREIGN KEY ("bundleId") REFERENCES "CourseBundle" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CourseBundleCourse_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "CourseBundleCourse_bundleId_courseId_key" ON "CourseBundleCourse"("bundleId", "courseId");
CREATE INDEX "CourseBundleCourse_tenantId_idx" ON "CourseBundleCourse"("tenantId");
CREATE INDEX "CourseBundleCourse_courseId_idx" ON "CourseBundleCourse"("courseId");

CREATE TABLE "BundlePurchase" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "bundleId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "price" INTEGER NOT NULL,
    "termsJson" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "environment" TEXT NOT NULL,
    "providerOrderId" TEXT NOT NULL,
    "providerPaymentId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'created',
    "failureCode" TEXT,
    "failureMessage" TEXT,
    "reviewReason" TEXT,
    "orderNumber" TEXT,
    "refundStatus" TEXT,
    "providerRefundId" TEXT,
    "refundedAt" DATETIME,
    "chargebackAt" DATETIME,
    "paidAt" DATETIME,
    "expiresAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "BundlePurchase_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "BundlePurchase_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "BundlePurchase_bundleId_fkey" FOREIGN KEY ("bundleId") REFERENCES "CourseBundle" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "BundlePurchase_orderNumber_key" ON "BundlePurchase"("orderNumber");
CREATE UNIQUE INDEX "BundlePurchase_provider_providerOrderId_key" ON "BundlePurchase"("provider", "providerOrderId");
CREATE UNIQUE INDEX "BundlePurchase_provider_providerPaymentId_key" ON "BundlePurchase"("provider", "providerPaymentId");
CREATE INDEX "BundlePurchase_tenantId_idx" ON "BundlePurchase"("tenantId");
CREATE INDEX "BundlePurchase_studentId_bundleId_idx" ON "BundlePurchase"("studentId", "bundleId");
CREATE INDEX "BundlePurchase_status_createdAt_idx" ON "BundlePurchase"("status", "createdAt");
-- A learner has one open order for a bundle, and an order's money terms never change.
CREATE UNIQUE INDEX "BundlePurchase_one_open_per_learner_bundle" ON "BundlePurchase"("studentId", "bundleId") WHERE "status" = 'created';
CREATE TRIGGER "BundlePurchase_terms_fixed"
BEFORE UPDATE ON "BundlePurchase"
WHEN NEW."amount" <> OLD."amount" OR NEW."currency" <> OLD."currency" OR NEW."studentId" <> OLD."studentId" OR NEW."bundleId" <> OLD."bundleId"
  OR NEW."termsJson" <> OLD."termsJson" OR NEW."providerOrderId" <> OLD."providerOrderId"
BEGIN
  SELECT RAISE(ABORT, 'A bundle order''s terms are fixed when it is made.');
END;
CREATE TRIGGER "BundlePurchase_paid_is_final"
BEFORE UPDATE ON "BundlePurchase"
WHEN OLD."status" = 'paid' AND (NEW."status" <> 'paid' OR NEW."providerPaymentId" IS NOT OLD."providerPaymentId")
BEGIN
  SELECT RAISE(ABORT, 'A paid bundle order stays paid, by that payment.');
END;

-- This course's share of a bundle order.
ALTER TABLE "CoursePurchase" ADD COLUMN "bundlePurchaseId" TEXT REFERENCES "BundlePurchase" ("id") ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX "CoursePurchase_bundlePurchaseId_idx" ON "CoursePurchase"("bundlePurchaseId");
