-- Course reviews (docs/16, D-PLAT-11). Additive: no existing table changes, and `Course.rating` / `ratingCount` keep
-- what they hold until a course's first review replaces them.
CREATE TABLE "CourseReview" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL CHECK ("rating" BETWEEN 1 AND 5),
    "comment" TEXT NOT NULL DEFAULT '' CHECK (length("comment") <= 2000),
    "status" TEXT NOT NULL DEFAULT 'published' CHECK ("status" IN ('published', 'hidden')),
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "CourseReview_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CourseReview_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CourseReview_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "CourseReview_studentId_courseId_key" ON "CourseReview"("studentId", "courseId");
CREATE INDEX "CourseReview_courseId_status_idx" ON "CourseReview"("courseId", "status");
CREATE INDEX "CourseReview_tenantId_idx" ON "CourseReview"("tenantId");
