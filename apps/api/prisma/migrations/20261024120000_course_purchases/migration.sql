-- Paid courses (course purchases). Additive only: no table is rebuilt, no row is deleted.
--
-- Course.pricing says whether a course is free, paid, or not yet decided. A course priced before pricing existed got
-- its price from the academy default without an admin choosing it, so it starts as "unset": nobody can enrol
-- themselves or buy it until an admin chooses free or paid. A course with no price is free, as it is today. Existing
-- enrolments are not touched.

-- CreateTable
CREATE TABLE "AcademyPaymentConfig" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "provider" TEXT NOT NULL DEFAULT 'razorpay',
    "environment" TEXT NOT NULL DEFAULT 'test',
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "updatedById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AcademyPaymentConfig_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "AcademyGatewayCredential" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "environment" TEXT NOT NULL,
    "cipher" TEXT NOT NULL,
    "keyId" TEXT NOT NULL,
    "hint" TEXT NOT NULL DEFAULT '{}',
    "updatedById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AcademyGatewayCredential_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "CoursePurchase" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'INR',
    "listPrice" INTEGER NOT NULL,
    "provider" TEXT NOT NULL,
    "environment" TEXT NOT NULL,
    "providerOrderId" TEXT NOT NULL,
    "providerPaymentId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'created',
    "failureCode" TEXT,
    "failureMessage" TEXT,
    "reviewReason" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "paidAt" DATETIME,
    "expiresAt" DATETIME NOT NULL,
    CONSTRAINT "CoursePurchase_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CoursePurchase_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CoursePurchase_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "CoursePaymentEvent" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "eventId" TEXT NOT NULL,
    "eventType" TEXT NOT NULL,
    "payloadHash" TEXT NOT NULL,
    "receivedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" DATETIME,
    CONSTRAINT "CoursePaymentEvent_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

ALTER TABLE "Course" ADD COLUMN "pricing" TEXT NOT NULL DEFAULT 'unset';
UPDATE "Course" SET "pricing" = 'free' WHERE "priceAmount" IS NULL OR "priceAmount" <= 0;

ALTER TABLE "Enrollment" ADD COLUMN "purchaseId" TEXT REFERENCES "CoursePurchase" ("id") ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE UNIQUE INDEX "Enrollment_purchaseId_key" ON "Enrollment"("purchaseId");

-- CreateIndex
CREATE UNIQUE INDEX "AcademyPaymentConfig_tenantId_key" ON "AcademyPaymentConfig"("tenantId");

-- CreateIndex
CREATE INDEX "AcademyGatewayCredential_tenantId_idx" ON "AcademyGatewayCredential"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "AcademyGatewayCredential_tenantId_provider_environment_key" ON "AcademyGatewayCredential"("tenantId", "provider", "environment");

-- CreateIndex
CREATE INDEX "CoursePurchase_tenantId_idx" ON "CoursePurchase"("tenantId");

-- CreateIndex
CREATE INDEX "CoursePurchase_studentId_courseId_idx" ON "CoursePurchase"("studentId", "courseId");

-- CreateIndex
CREATE INDEX "CoursePurchase_courseId_idx" ON "CoursePurchase"("courseId");

-- CreateIndex
CREATE INDEX "CoursePurchase_status_createdAt_idx" ON "CoursePurchase"("status", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "CoursePurchase_provider_providerOrderId_key" ON "CoursePurchase"("provider", "providerOrderId");

-- CreateIndex
CREATE UNIQUE INDEX "CoursePurchase_provider_providerPaymentId_key" ON "CoursePurchase"("provider", "providerPaymentId");

-- CreateIndex
CREATE INDEX "CoursePaymentEvent_tenantId_idx" ON "CoursePaymentEvent"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "CoursePaymentEvent_tenantId_provider_eventId_key" ON "CoursePaymentEvent"("tenantId", "provider", "eventId");

-- One open order per learner and course: two checkouts at once reuse one order instead of making two.
CREATE UNIQUE INDEX "CoursePurchase_one_open_per_learner_course" ON "CoursePurchase"("studentId", "courseId") WHERE "status" = 'created';

-- What a purchase charges, for whom, for what and through which order never changes once written.
CREATE TRIGGER "CoursePurchase_terms_fixed"
BEFORE UPDATE OF "tenantId", "studentId", "courseId", "amount", "currency", "listPrice", "provider", "environment", "providerOrderId" ON "CoursePurchase"
WHEN NEW."tenantId" IS NOT OLD."tenantId" OR NEW."studentId" IS NOT OLD."studentId" OR NEW."courseId" IS NOT OLD."courseId"
  OR NEW."amount" IS NOT OLD."amount" OR NEW."currency" IS NOT OLD."currency" OR NEW."listPrice" IS NOT OLD."listPrice"
  OR NEW."provider" IS NOT OLD."provider" OR NEW."environment" IS NOT OLD."environment" OR NEW."providerOrderId" IS NOT OLD."providerOrderId"
BEGIN
  SELECT RAISE(ABORT, 'A course purchase''s terms cannot change.');
END;

-- A paid purchase stays paid, and a payment once recorded on a purchase stays the one recorded.
CREATE TRIGGER "CoursePurchase_paid_is_final"
BEFORE UPDATE OF "status", "providerPaymentId" ON "CoursePurchase"
WHEN (OLD."status" = 'paid' AND NEW."status" IS NOT 'paid')
  OR (OLD."providerPaymentId" IS NOT NULL AND NEW."providerPaymentId" IS NOT OLD."providerPaymentId")
BEGIN
  SELECT RAISE(ABORT, 'A paid course purchase cannot be changed.');
END;

-- An enrolment opened by a purchase points at a paid purchase of the same learner, course and academy.
CREATE TRIGGER "Enrollment_purchase_paid_insert"
BEFORE INSERT ON "Enrollment"
WHEN NEW."purchaseId" IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM "CoursePurchase" p WHERE p."id" = NEW."purchaseId" AND p."status" = 'paid'
    AND p."studentId" = NEW."studentId" AND p."courseId" = NEW."courseId" AND p."tenantId" = NEW."tenantId")
BEGIN
  SELECT RAISE(ABORT, 'An enrolment can only be opened by a paid purchase of that course by that learner.');
END;

CREATE TRIGGER "Enrollment_purchase_paid_update"
BEFORE UPDATE OF "purchaseId" ON "Enrollment"
WHEN NEW."purchaseId" IS NOT NULL AND NOT EXISTS (
  SELECT 1 FROM "CoursePurchase" p WHERE p."id" = NEW."purchaseId" AND p."status" = 'paid'
    AND p."studentId" = NEW."studentId" AND p."courseId" = NEW."courseId" AND p."tenantId" = NEW."tenantId")
BEGIN
  SELECT RAISE(ABORT, 'An enrolment can only be opened by a paid purchase of that course by that learner.');
END;

-- A learner never enrols themselves in a paid course: they buy it, or staff add them.
CREATE TRIGGER "Enrollment_paid_course_not_self"
BEFORE INSERT ON "Enrollment"
WHEN NEW."source" = 'self' AND EXISTS (SELECT 1 FROM "Course" c WHERE c."id" = NEW."courseId" AND c."pricing" = 'paid')
BEGIN
  SELECT RAISE(ABORT, 'A paid course is enrolled by purchase.');
END;
