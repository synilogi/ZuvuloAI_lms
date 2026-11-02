-- A course's uploaded cover image. Additive: existing courses keep a null cover and go on drawing their motif.
ALTER TABLE "Course" ADD COLUMN "coverImageId" TEXT REFERENCES "MediaAsset" ("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateIndex
CREATE INDEX "Course_coverImageId_idx" ON "Course"("coverImageId");
