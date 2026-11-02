-- Course sales on the platform (docs/16 §2.4): order numbers, sale prices, coupons and refunds. Additive only.

CREATE TABLE "OrderSequence" (
    "year" INTEGER NOT NULL PRIMARY KEY,
    "last" INTEGER NOT NULL DEFAULT 0
);

ALTER TABLE "Course" ADD COLUMN "salePrice" INTEGER;

ALTER TABLE "CoursePurchase" ADD COLUMN "orderNumber" TEXT;
ALTER TABLE "CoursePurchase" ADD COLUMN "discountAmount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "CoursePurchase" ADD COLUMN "couponId" TEXT;
ALTER TABLE "CoursePurchase" ADD COLUMN "couponCode" TEXT;
ALTER TABLE "CoursePurchase" ADD COLUMN "refundedAt" DATETIME;

-- Existing orders get their numbers in the order they were made, year by year. Dates are stored as milliseconds by
-- Prisma; a text date from a hand-written row is read as it stands.
UPDATE "CoursePurchase" SET "orderNumber" = 'ORD-' || (
  CASE typeof("createdAt") WHEN 'text' THEN strftime('%Y', "createdAt") ELSE strftime('%Y', "createdAt" / 1000, 'unixepoch') END
) || '-' || printf('%06d', (
  SELECT COUNT(*) FROM "CoursePurchase" AS p
  WHERE (CASE typeof(p."createdAt") WHEN 'text' THEN strftime('%Y', p."createdAt") ELSE strftime('%Y', p."createdAt" / 1000, 'unixepoch') END)
      = (CASE typeof("CoursePurchase"."createdAt") WHEN 'text' THEN strftime('%Y', "CoursePurchase"."createdAt") ELSE strftime('%Y', "CoursePurchase"."createdAt" / 1000, 'unixepoch') END)
    AND (p."createdAt" < "CoursePurchase"."createdAt" OR (p."createdAt" = "CoursePurchase"."createdAt" AND p."id" <= "CoursePurchase"."id"))
));

INSERT INTO "OrderSequence" ("year", "last")
SELECT CAST(substr("orderNumber", 5, 4) AS INTEGER), COUNT(*) FROM "CoursePurchase" GROUP BY substr("orderNumber", 5, 4);

CREATE UNIQUE INDEX "CoursePurchase_orderNumber_key" ON "CoursePurchase"("orderNumber");

-- A number, a discount and a coupon are fixed once the order has them.
CREATE TRIGGER "CoursePurchase_order_terms_fixed" BEFORE UPDATE ON "CoursePurchase"
WHEN (OLD."orderNumber" IS NOT NULL AND NEW."orderNumber" IS NOT OLD."orderNumber")
  OR NEW."discountAmount" <> OLD."discountAmount"
  OR NEW."couponId" IS NOT OLD."couponId"
  OR NEW."couponCode" IS NOT OLD."couponCode"
BEGIN
  SELECT RAISE(ABORT, 'An order''s number and discount are fixed when it is made.');
END;

CREATE TABLE "Coupon" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" TEXT NOT NULL DEFAULT '',
    "kind" TEXT NOT NULL CHECK ("kind" IN ('percent', 'fixed')),
    "percentBps" INTEGER,
    "amountOff" INTEGER,
    "startsAt" DATETIME,
    "endsAt" DATETIME,
    "maxUses" INTEGER,
    "perLearnerLimit" INTEGER NOT NULL DEFAULT 1,
    "courseId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'active' CHECK ("status" IN ('active', 'disabled')),
    "usedCount" INTEGER NOT NULL DEFAULT 0,
    "createdById" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Coupon_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Coupon_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (("kind" = 'percent' AND "percentBps" BETWEEN 1 AND 10000 AND "amountOff" IS NULL) OR ("kind" = 'fixed' AND "amountOff" > 0 AND "percentBps" IS NULL))
);
CREATE UNIQUE INDEX "Coupon_tenantId_code_key" ON "Coupon"("tenantId", "code");

-- What a coupon takes off is its identity: a different discount is a different coupon, so past orders stay explicable.
CREATE TRIGGER "Coupon_terms_fixed" BEFORE UPDATE ON "Coupon"
WHEN NEW."tenantId" <> OLD."tenantId" OR NEW."code" <> OLD."code" OR NEW."kind" <> OLD."kind"
  OR NEW."percentBps" IS NOT OLD."percentBps" OR NEW."amountOff" IS NOT OLD."amountOff"
BEGIN
  SELECT RAISE(ABORT, 'A coupon''s code and discount are fixed. Disable it and make another.');
END;
CREATE TRIGGER "Coupon_no_delete" BEFORE DELETE ON "Coupon"
BEGIN
  SELECT RAISE(ABORT, 'A coupon is disabled, never deleted.');
END;

CREATE TABLE "CouponRedemption" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "couponId" TEXT NOT NULL,
    "purchaseId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "discountAmount" INTEGER NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "CouponRedemption_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CouponRedemption_couponId_fkey" FOREIGN KEY ("couponId") REFERENCES "Coupon" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CouponRedemption_purchaseId_fkey" FOREIGN KEY ("purchaseId") REFERENCES "CoursePurchase" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "CouponRedemption_purchaseId_key" ON "CouponRedemption"("purchaseId");
CREATE INDEX "CouponRedemption_tenantId_idx" ON "CouponRedemption"("tenantId");
CREATE INDEX "CouponRedemption_couponId_studentId_idx" ON "CouponRedemption"("couponId", "studentId");
CREATE TRIGGER "CouponRedemption_no_update" BEFORE UPDATE ON "CouponRedemption"
BEGIN
  SELECT RAISE(ABORT, 'A coupon redemption is never changed.');
END;
CREATE TRIGGER "CouponRedemption_no_delete" BEFORE DELETE ON "CouponRedemption"
BEGIN
  SELECT RAISE(ABORT, 'A coupon redemption is never deleted.');
END;

CREATE TABLE "CoursePurchaseRefund" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "purchaseId" TEXT NOT NULL,
    "amount" INTEGER NOT NULL CHECK ("amount" > 0),
    "reason" TEXT NOT NULL,
    "note" TEXT,
    "requestedById" TEXT,
    "provider" TEXT NOT NULL,
    "providerRefundId" TEXT,
    "status" TEXT NOT NULL CHECK ("status" IN ('requested', 'pending', 'succeeded', 'failed')),
    "failureMessage" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "settledAt" DATETIME,
    CONSTRAINT "CoursePurchaseRefund_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "CoursePurchaseRefund_purchaseId_fkey" FOREIGN KEY ("purchaseId") REFERENCES "CoursePurchase" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE INDEX "CoursePurchaseRefund_tenantId_idx" ON "CoursePurchaseRefund"("tenantId");
CREATE INDEX "CoursePurchaseRefund_purchaseId_idx" ON "CoursePurchaseRefund"("purchaseId");
CREATE UNIQUE INDEX "CoursePurchaseRefund_provider_providerRefundId_key" ON "CoursePurchaseRefund"("provider", "providerRefundId");
-- A purchase has one refund under way or done; only a failed one leaves room for another try.
CREATE UNIQUE INDEX "CoursePurchaseRefund_one_live" ON "CoursePurchaseRefund"("purchaseId") WHERE "status" <> 'failed';
CREATE TRIGGER "CoursePurchaseRefund_fixed" BEFORE UPDATE ON "CoursePurchaseRefund"
WHEN NEW."amount" <> OLD."amount" OR NEW."purchaseId" <> OLD."purchaseId" OR NEW."tenantId" <> OLD."tenantId" OR OLD."status" = 'succeeded'
BEGIN
  SELECT RAISE(ABORT, 'A refund''s amount is fixed, and a settled refund is final.');
END;
CREATE TRIGGER "CoursePurchaseRefund_no_delete" BEFORE DELETE ON "CoursePurchaseRefund"
BEGIN
  SELECT RAISE(ABORT, 'A refund is never deleted.');
END;
