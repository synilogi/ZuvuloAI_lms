-- Tenant foundation (SAAS-000).
--
-- Adds the Tenant table and a tenantId to every academy-owned table, and makes the academy that
-- existed before tenancy Tenant #1. Every existing row is assigned to it; nothing is deleted or
-- rewritten apart from gaining that column. Platform-level rows keep tenantId NULL: super admin
-- accounts and what belongs to them (their reset tokens, notification settings, notifications and
-- email). Help Centre content and the platform audit log get no tenantId at all (decision D5).
--
-- All or nothing. Prisma does not wrap a SQLite migration in a transaction, so this one opens its
-- own, following SQLite's procedure for rebuilding tables: foreign keys are switched off *before* the
-- transaction (the pragma cannot change inside one, and with keys on, DROP TABLE would fire ON DELETE
-- CASCADE and delete child rows), every rebuild runs inside it, and they are switched back on after
-- it commits. The script checks its own backfill before COMMIT: a broken invariant fails the check,
-- the transaction never commits, and the database is left exactly as it was before the migration.

PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
BEGIN;

-- CreateTable
CREATE TABLE "Tenant" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "ownerUserId" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Tenant_ownerUserId_fkey" FOREIGN KEY ("ownerUserId") REFERENCES "User" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- Tenant #1: the academy that existed before tenancy.
INSERT INTO "Tenant" ("id", "name", "slug", "status", "createdAt", "updatedAt")
VALUES ('tenant-1', 'ZuviloAI', 'default', 'active', CAST(strftime('%s', 'now') AS INTEGER) * 1000, CAST(strftime('%s', 'now') AS INTEGER) * 1000);

CREATE TABLE "new_User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "descriptor" TEXT NOT NULL DEFAULT '',
    "instructorId" TEXT,
    "deactivatedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "User_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "Instructor" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "User_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_User" ("tenantId", "createdAt", "deactivatedAt", "descriptor", "email", "id", "instructorId", "name", "passwordHash", "role", "updatedAt") SELECT CASE WHEN "role" = 'superadmin' THEN NULL ELSE 'tenant-1' END, "createdAt", "deactivatedAt", "descriptor", "email", "id", "instructorId", "name", "passwordHash", "role", "updatedAt" FROM "User";
DROP TABLE "User";
ALTER TABLE "new_User" RENAME TO "User";
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");
CREATE INDEX "User_instructorId_idx" ON "User"("instructorId");
CREATE INDEX "User_tenantId_idx" ON "User"("tenantId");
CREATE TABLE "new_PasswordResetToken" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" DATETIME NOT NULL,
    "usedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PasswordResetToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "PasswordResetToken_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_PasswordResetToken" ("tenantId", "createdAt", "expiresAt", "id", "tokenHash", "usedAt", "userId") SELECT (SELECT CASE WHEN u."role" = 'superadmin' THEN NULL ELSE 'tenant-1' END FROM "User" u WHERE u."id" = "PasswordResetToken"."userId"), "createdAt", "expiresAt", "id", "tokenHash", "usedAt", "userId" FROM "PasswordResetToken";
DROP TABLE "PasswordResetToken";
ALTER TABLE "new_PasswordResetToken" RENAME TO "PasswordResetToken";
CREATE UNIQUE INDEX "PasswordResetToken_tokenHash_key" ON "PasswordResetToken"("tokenHash");
CREATE INDEX "PasswordResetToken_userId_idx" ON "PasswordResetToken"("userId");
CREATE INDEX "PasswordResetToken_tenantId_idx" ON "PasswordResetToken"("tenantId");
CREATE TABLE "new_AdminPermission" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "grantedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "grantedBy" TEXT,
    CONSTRAINT "AdminPermission_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "AdminPermission_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_AdminPermission" ("tenantId", "grantedAt", "grantedBy", "id", "key", "userId") SELECT 'tenant-1', "grantedAt", "grantedBy", "id", "key", "userId" FROM "AdminPermission";
DROP TABLE "AdminPermission";
ALTER TABLE "new_AdminPermission" RENAME TO "AdminPermission";
CREATE INDEX "AdminPermission_userId_idx" ON "AdminPermission"("userId");
CREATE INDEX "AdminPermission_tenantId_idx" ON "AdminPermission"("tenantId");
CREATE UNIQUE INDEX "AdminPermission_userId_key_key" ON "AdminPermission"("userId", "key");
CREATE TABLE "new_EmailOutbox" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT,
    "toEmail" TEXT NOT NULL,
    "toName" TEXT,
    "subject" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "templateKey" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'queued',
    "error" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sentAt" DATETIME,
    CONSTRAINT "EmailOutbox_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_EmailOutbox" ("tenantId", "createdAt", "error", "id", "sentAt", "status", "subject", "templateKey", "text", "toEmail", "toName") SELECT CASE WHEN EXISTS (SELECT 1 FROM "User" u WHERE u."email" = "EmailOutbox"."toEmail" AND u."role" = 'superadmin') THEN NULL ELSE 'tenant-1' END, "createdAt", "error", "id", "sentAt", "status", "subject", "templateKey", "text", "toEmail", "toName" FROM "EmailOutbox";
DROP TABLE "EmailOutbox";
ALTER TABLE "new_EmailOutbox" RENAME TO "EmailOutbox";
CREATE INDEX "EmailOutbox_status_createdAt_idx" ON "EmailOutbox"("status", "createdAt");
CREATE INDEX "EmailOutbox_toEmail_idx" ON "EmailOutbox"("toEmail");
CREATE INDEX "EmailOutbox_tenantId_idx" ON "EmailOutbox"("tenantId");
CREATE TABLE "new_MediaAsset" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "ownerUserId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "originalName" TEXT NOT NULL,
    "mime" TEXT NOT NULL,
    "sizeBytes" INTEGER NOT NULL,
    "storageName" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MediaAsset_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_MediaAsset" ("tenantId", "createdAt", "id", "kind", "mime", "originalName", "ownerUserId", "sizeBytes", "storageName") SELECT 'tenant-1', "createdAt", "id", "kind", "mime", "originalName", "ownerUserId", "sizeBytes", "storageName" FROM "MediaAsset";
DROP TABLE "MediaAsset";
ALTER TABLE "new_MediaAsset" RENAME TO "MediaAsset";
CREATE UNIQUE INDEX "MediaAsset_storageName_key" ON "MediaAsset"("storageName");
CREATE INDEX "MediaAsset_ownerUserId_idx" ON "MediaAsset"("ownerUserId");
CREATE INDEX "MediaAsset_tenantId_idx" ON "MediaAsset"("tenantId");
CREATE TABLE "new_Level" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "summary" TEXT,
    CONSTRAINT "Level_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Level" ("tenantId", "id", "name", "order", "summary") SELECT 'tenant-1', "id", "name", "order", "summary" FROM "Level";
DROP TABLE "Level";
ALTER TABLE "new_Level" RENAME TO "Level";
CREATE INDEX "Level_tenantId_idx" ON "Level"("tenantId");
CREATE TABLE "new_Category" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "status" TEXT NOT NULL,
    "glyph" TEXT NOT NULL,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Category_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Category" ("tenantId", "description", "glyph", "id", "name", "order", "status", "updatedAt") SELECT 'tenant-1', "description", "glyph", "id", "name", "order", "status", "updatedAt" FROM "Category";
DROP TABLE "Category";
ALTER TABLE "new_Category" RENAME TO "Category";
CREATE INDEX "Category_tenantId_idx" ON "Category"("tenantId");
CREATE TABLE "new_CategoryLevel" (
    "categoryId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "levelId" TEXT NOT NULL,

    PRIMARY KEY ("categoryId", "levelId"),
    CONSTRAINT "CategoryLevel_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CategoryLevel_levelId_fkey" FOREIGN KEY ("levelId") REFERENCES "Level" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CategoryLevel_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_CategoryLevel" ("tenantId", "categoryId", "levelId") SELECT 'tenant-1', "categoryId", "levelId" FROM "CategoryLevel";
DROP TABLE "CategoryLevel";
ALTER TABLE "new_CategoryLevel" RENAME TO "CategoryLevel";
CREATE INDEX "CategoryLevel_tenantId_idx" ON "CategoryLevel"("tenantId");
CREATE TABLE "new_Instructor" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "yearsTeaching" INTEGER,
    "email" TEXT NOT NULL,
    "bio" TEXT NOT NULL DEFAULT '',
    "expertiseJson" TEXT NOT NULL DEFAULT '[]',
    "status" TEXT NOT NULL,
    "joinedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "city" TEXT NOT NULL DEFAULT '',
    "languagesJson" TEXT NOT NULL DEFAULT '[]',
    "phone" TEXT,
    "photoJson" TEXT,
    CONSTRAINT "Instructor_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Instructor" ("tenantId", "bio", "city", "email", "expertiseJson", "id", "joinedAt", "languagesJson", "name", "phone", "photoJson", "status", "title", "yearsTeaching") SELECT 'tenant-1', "bio", "city", "email", "expertiseJson", "id", "joinedAt", "languagesJson", "name", "phone", "photoJson", "status", "title", "yearsTeaching" FROM "Instructor";
DROP TABLE "Instructor";
ALTER TABLE "new_Instructor" RENAME TO "Instructor";
CREATE UNIQUE INDEX "Instructor_email_key" ON "Instructor"("email");
CREATE INDEX "Instructor_tenantId_idx" ON "Instructor"("tenantId");
CREATE TABLE "new_Course" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "subtitle" TEXT NOT NULL DEFAULT '',
    "description" TEXT NOT NULL DEFAULT '',
    "levelId" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "format" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'en-IN',
    "coverMotif" TEXT NOT NULL,
    "liveSessions" INTEGER NOT NULL DEFAULT 0,
    "estimatedWeeks" INTEGER,
    "certificateTitle" TEXT,
    "priceAmount" INTEGER,
    "priceCurrency" TEXT NOT NULL DEFAULT 'INR',
    "enrolledCount" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "visibility" TEXT NOT NULL DEFAULT 'public',
    "outcomesJson" TEXT NOT NULL DEFAULT '[]',
    "tagsJson" TEXT NOT NULL DEFAULT '[]',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "publishedAt" DATETIME,
    "rating" REAL,
    "ratingCount" INTEGER,
    "certificateTemplateId" TEXT,
    CONSTRAINT "Course_levelId_fkey" FOREIGN KEY ("levelId") REFERENCES "Level" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Course_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Course_certificateTemplateId_fkey" FOREIGN KEY ("certificateTemplateId") REFERENCES "CertificateTemplate" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Course_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Course" ("tenantId", "categoryId", "certificateTemplateId", "certificateTitle", "coverMotif", "createdAt", "description", "enrolledCount", "estimatedWeeks", "format", "id", "language", "levelId", "liveSessions", "outcomesJson", "priceAmount", "priceCurrency", "publishedAt", "rating", "ratingCount", "slug", "status", "subtitle", "tagsJson", "title", "updatedAt", "visibility") SELECT 'tenant-1', "categoryId", "certificateTemplateId", "certificateTitle", "coverMotif", "createdAt", "description", "enrolledCount", "estimatedWeeks", "format", "id", "language", "levelId", "liveSessions", "outcomesJson", "priceAmount", "priceCurrency", "publishedAt", "rating", "ratingCount", "slug", "status", "subtitle", "tagsJson", "title", "updatedAt", "visibility" FROM "Course";
DROP TABLE "Course";
ALTER TABLE "new_Course" RENAME TO "Course";
CREATE INDEX "Course_categoryId_idx" ON "Course"("categoryId");
CREATE INDEX "Course_levelId_idx" ON "Course"("levelId");
CREATE INDEX "Course_status_idx" ON "Course"("status");
CREATE UNIQUE INDEX "Course_tenantId_slug_key" ON "Course"("tenantId", "slug");
CREATE TABLE "new_CourseInstructor" (
    "courseId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "instructorId" TEXT NOT NULL,

    PRIMARY KEY ("courseId", "instructorId"),
    CONSTRAINT "CourseInstructor_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CourseInstructor_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "Instructor" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CourseInstructor_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_CourseInstructor" ("tenantId", "courseId", "instructorId") SELECT 'tenant-1', "courseId", "instructorId" FROM "CourseInstructor";
DROP TABLE "CourseInstructor";
ALTER TABLE "new_CourseInstructor" RENAME TO "CourseInstructor";
CREATE INDEX "CourseInstructor_tenantId_idx" ON "CourseInstructor"("tenantId");
CREATE TABLE "new_Chapter" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "summary" TEXT,
    "objective" TEXT,
    "estimatedMin" INTEGER,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "position" INTEGER NOT NULL,
    CONSTRAINT "Chapter_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Chapter_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Chapter" ("tenantId", "courseId", "estimatedMin", "id", "objective", "position", "status", "summary", "title") SELECT 'tenant-1', "courseId", "estimatedMin", "id", "objective", "position", "status", "summary", "title" FROM "Chapter";
DROP TABLE "Chapter";
ALTER TABLE "new_Chapter" RENAME TO "Chapter";
CREATE INDEX "Chapter_courseId_idx" ON "Chapter"("courseId");
CREATE INDEX "Chapter_tenantId_idx" ON "Chapter"("tenantId");
CREATE TABLE "new_Lesson" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "chapterId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "durationMin" INTEGER NOT NULL DEFAULT 0,
    "isPreview" BOOLEAN NOT NULL DEFAULT false,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "updatedAt" DATETIME NOT NULL,
    "description" TEXT,
    "objectivesJson" TEXT NOT NULL DEFAULT '[]',
    "contentJson" TEXT NOT NULL DEFAULT '{}',
    "settingsJson" TEXT NOT NULL DEFAULT '{}',
    "position" INTEGER NOT NULL,
    CONSTRAINT "Lesson_chapterId_fkey" FOREIGN KEY ("chapterId") REFERENCES "Chapter" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Lesson_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Lesson" ("tenantId", "chapterId", "contentJson", "courseId", "description", "durationMin", "id", "isPreview", "objectivesJson", "position", "settingsJson", "status", "title", "type", "updatedAt") SELECT 'tenant-1', "chapterId", "contentJson", "courseId", "description", "durationMin", "id", "isPreview", "objectivesJson", "position", "settingsJson", "status", "title", "type", "updatedAt" FROM "Lesson";
DROP TABLE "Lesson";
ALTER TABLE "new_Lesson" RENAME TO "Lesson";
CREATE INDEX "Lesson_chapterId_idx" ON "Lesson"("chapterId");
CREATE INDEX "Lesson_courseId_idx" ON "Lesson"("courseId");
CREATE INDEX "Lesson_tenantId_idx" ON "Lesson"("tenantId");
CREATE TABLE "new_Student" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "phone" TEXT,
    "city" TEXT NOT NULL DEFAULT '',
    "joinedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastActiveAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "suspended" BOOLEAN NOT NULL DEFAULT false,
    "suspendReason" TEXT,
    "rankId" TEXT,
    "nudgedAt" DATETIME,
    CONSTRAINT "Student_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Student_rankId_fkey" FOREIGN KEY ("rankId") REFERENCES "Rank" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Student_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Student" ("tenantId", "city", "id", "joinedAt", "lastActiveAt", "nudgedAt", "phone", "rankId", "suspendReason", "suspended", "userId") SELECT 'tenant-1', "city", "id", "joinedAt", "lastActiveAt", "nudgedAt", "phone", "rankId", "suspendReason", "suspended", "userId" FROM "Student";
DROP TABLE "Student";
ALTER TABLE "new_Student" RENAME TO "Student";
CREATE UNIQUE INDEX "Student_userId_key" ON "Student"("userId");
CREATE INDEX "Student_rankId_idx" ON "Student"("rankId");
CREATE INDEX "Student_tenantId_idx" ON "Student"("tenantId");
CREATE TABLE "new_Enrollment" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "enrolledAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" TEXT NOT NULL DEFAULT 'active',
    "progress" INTEGER NOT NULL DEFAULT 0,
    "source" TEXT NOT NULL DEFAULT 'self',
    "lastActiveAt" DATETIME,
    "completedAt" DATETIME,
    "expiresAt" DATETIME,
    "lastLessonId" TEXT,
    CONSTRAINT "Enrollment_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Enrollment_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Enrollment_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Enrollment" ("tenantId", "completedAt", "courseId", "enrolledAt", "expiresAt", "id", "lastActiveAt", "lastLessonId", "progress", "source", "status", "studentId") SELECT 'tenant-1', "completedAt", "courseId", "enrolledAt", "expiresAt", "id", "lastActiveAt", "lastLessonId", "progress", "source", "status", "studentId" FROM "Enrollment";
DROP TABLE "Enrollment";
ALTER TABLE "new_Enrollment" RENAME TO "Enrollment";
CREATE INDEX "Enrollment_courseId_idx" ON "Enrollment"("courseId");
CREATE INDEX "Enrollment_tenantId_idx" ON "Enrollment"("tenantId");
CREATE UNIQUE INDEX "Enrollment_studentId_courseId_key" ON "Enrollment"("studentId", "courseId");
CREATE TABLE "new_LessonProgress" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "lessonId" TEXT NOT NULL,
    "state" TEXT NOT NULL DEFAULT 'not-started',
    "fraction" REAL,
    "positionSec" INTEGER,
    "completedAt" DATETIME,
    "lastAccessedAt" DATETIME,
    CONSTRAINT "LessonProgress_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LessonProgress_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "Lesson" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LessonProgress_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_LessonProgress" ("tenantId", "completedAt", "fraction", "id", "lastAccessedAt", "lessonId", "positionSec", "state", "studentId") SELECT 'tenant-1', "completedAt", "fraction", "id", "lastAccessedAt", "lessonId", "positionSec", "state", "studentId" FROM "LessonProgress";
DROP TABLE "LessonProgress";
ALTER TABLE "new_LessonProgress" RENAME TO "LessonProgress";
CREATE INDEX "LessonProgress_lessonId_idx" ON "LessonProgress"("lessonId");
CREATE INDEX "LessonProgress_tenantId_idx" ON "LessonProgress"("tenantId");
CREATE UNIQUE INDEX "LessonProgress_studentId_lessonId_key" ON "LessonProgress"("studentId", "lessonId");
CREATE TABLE "new_LessonNote" (
    "studentId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "lessonId" TEXT NOT NULL,
    "text" TEXT NOT NULL DEFAULT '',
    "savedAt" DATETIME NOT NULL,

    PRIMARY KEY ("studentId", "lessonId"),
    CONSTRAINT "LessonNote_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LessonNote_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "Lesson" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LessonNote_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_LessonNote" ("tenantId", "lessonId", "savedAt", "studentId", "text") SELECT 'tenant-1', "lessonId", "savedAt", "studentId", "text" FROM "LessonNote";
DROP TABLE "LessonNote";
ALTER TABLE "new_LessonNote" RENAME TO "LessonNote";
CREATE INDEX "LessonNote_tenantId_idx" ON "LessonNote"("tenantId");
CREATE TABLE "new_LessonBookmark" (
    "studentId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "lessonId" TEXT NOT NULL,

    PRIMARY KEY ("studentId", "lessonId"),
    CONSTRAINT "LessonBookmark_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LessonBookmark_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "Lesson" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LessonBookmark_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_LessonBookmark" ("tenantId", "lessonId", "studentId") SELECT 'tenant-1', "lessonId", "studentId" FROM "LessonBookmark";
DROP TABLE "LessonBookmark";
ALTER TABLE "new_LessonBookmark" RENAME TO "LessonBookmark";
CREATE INDEX "LessonBookmark_tenantId_idx" ON "LessonBookmark"("tenantId");
CREATE TABLE "new_SavedCourse" (
    "studentId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "savedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY ("studentId", "courseId"),
    CONSTRAINT "SavedCourse_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "SavedCourse_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_SavedCourse" ("tenantId", "courseId", "savedAt", "studentId") SELECT 'tenant-1', "courseId", "savedAt", "studentId" FROM "SavedCourse";
DROP TABLE "SavedCourse";
ALTER TABLE "new_SavedCourse" RENAME TO "SavedCourse";
CREATE INDEX "SavedCourse_tenantId_idx" ON "SavedCourse"("tenantId");
CREATE TABLE "new_Rank" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "order" INTEGER NOT NULL,
    "descriptor" TEXT NOT NULL,
    "criteriaJson" TEXT NOT NULL DEFAULT '[]',
    CONSTRAINT "Rank_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Rank" ("tenantId", "criteriaJson", "descriptor", "id", "order", "title") SELECT 'tenant-1', "criteriaJson", "descriptor", "id", "order", "title" FROM "Rank";
DROP TABLE "Rank";
ALTER TABLE "new_Rank" RENAME TO "Rank";
CREATE INDEX "Rank_tenantId_idx" ON "Rank"("tenantId");
CREATE TABLE "new_Quiz" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "chapterId" TEXT,
    "lessonId" TEXT,
    "title" TEXT NOT NULL,
    "instructions" TEXT NOT NULL DEFAULT '',
    "status" TEXT NOT NULL DEFAULT 'draft',
    "questionsJson" TEXT NOT NULL DEFAULT '[]',
    "settingsJson" TEXT NOT NULL DEFAULT '{}',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Quiz_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Quiz_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "Lesson" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Quiz_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Quiz" ("tenantId", "chapterId", "courseId", "createdAt", "id", "instructions", "lessonId", "questionsJson", "settingsJson", "status", "title", "updatedAt") SELECT 'tenant-1', "chapterId", "courseId", "createdAt", "id", "instructions", "lessonId", "questionsJson", "settingsJson", "status", "title", "updatedAt" FROM "Quiz";
DROP TABLE "Quiz";
ALTER TABLE "new_Quiz" RENAME TO "Quiz";
CREATE UNIQUE INDEX "Quiz_lessonId_key" ON "Quiz"("lessonId");
CREATE INDEX "Quiz_courseId_idx" ON "Quiz"("courseId");
CREATE INDEX "Quiz_tenantId_idx" ON "Quiz"("tenantId");
CREATE TABLE "new_QuizAttempt" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "quizId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "answersJson" TEXT NOT NULL DEFAULT '{}',
    "resultJson" TEXT NOT NULL DEFAULT '{}',
    "percent" INTEGER NOT NULL DEFAULT 0,
    "passed" BOOLEAN NOT NULL DEFAULT false,
    "durationSec" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "QuizAttempt_quizId_fkey" FOREIGN KEY ("quizId") REFERENCES "Quiz" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "QuizAttempt_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "QuizAttempt_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_QuizAttempt" ("tenantId", "answersJson", "createdAt", "durationSec", "id", "passed", "percent", "quizId", "resultJson", "studentId") SELECT 'tenant-1', "answersJson", "createdAt", "durationSec", "id", "passed", "percent", "quizId", "resultJson", "studentId" FROM "QuizAttempt";
DROP TABLE "QuizAttempt";
ALTER TABLE "new_QuizAttempt" RENAME TO "QuizAttempt";
CREATE INDEX "QuizAttempt_quizId_idx" ON "QuizAttempt"("quizId");
CREATE INDEX "QuizAttempt_studentId_idx" ON "QuizAttempt"("studentId");
CREATE INDEX "QuizAttempt_tenantId_idx" ON "QuizAttempt"("tenantId");
CREATE TABLE "new_CourseAssignment" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "chapterId" TEXT,
    "lessonId" TEXT,
    "title" TEXT NOT NULL,
    "instructions" TEXT NOT NULL DEFAULT '',
    "attachmentsJson" TEXT NOT NULL DEFAULT '[]',
    "format" TEXT NOT NULL DEFAULT 'text',
    "wordLimit" INTEGER,
    "dueJson" TEXT NOT NULL DEFAULT '{"kind":"none"}',
    "acceptsLate" BOOLEAN NOT NULL DEFAULT true,
    "latePenalty" INTEGER NOT NULL DEFAULT 0,
    "rubricJson" TEXT NOT NULL DEFAULT '[]',
    "maxScore" INTEGER NOT NULL DEFAULT 100,
    "passMark" INTEGER NOT NULL DEFAULT 60,
    "status" TEXT NOT NULL DEFAULT 'draft',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "CourseAssignment_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CourseAssignment_lessonId_fkey" FOREIGN KEY ("lessonId") REFERENCES "Lesson" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "CourseAssignment_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_CourseAssignment" ("tenantId", "acceptsLate", "attachmentsJson", "chapterId", "courseId", "createdAt", "dueJson", "format", "id", "instructions", "latePenalty", "lessonId", "maxScore", "passMark", "rubricJson", "status", "title", "updatedAt", "wordLimit") SELECT 'tenant-1', "acceptsLate", "attachmentsJson", "chapterId", "courseId", "createdAt", "dueJson", "format", "id", "instructions", "latePenalty", "lessonId", "maxScore", "passMark", "rubricJson", "status", "title", "updatedAt", "wordLimit" FROM "CourseAssignment";
DROP TABLE "CourseAssignment";
ALTER TABLE "new_CourseAssignment" RENAME TO "CourseAssignment";
CREATE UNIQUE INDEX "CourseAssignment_lessonId_key" ON "CourseAssignment"("lessonId");
CREATE INDEX "CourseAssignment_courseId_idx" ON "CourseAssignment"("courseId");
CREATE INDEX "CourseAssignment_tenantId_idx" ON "CourseAssignment"("tenantId");
CREATE TABLE "new_AssignmentDraft" (
    "studentId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "assignmentId" TEXT NOT NULL,
    "text" TEXT NOT NULL DEFAULT '',
    "filesJson" TEXT NOT NULL DEFAULT '[]',
    "chartJson" TEXT,
    "savedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY ("studentId", "assignmentId"),
    CONSTRAINT "AssignmentDraft_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "AssignmentDraft_assignmentId_fkey" FOREIGN KEY ("assignmentId") REFERENCES "CourseAssignment" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "AssignmentDraft_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_AssignmentDraft" ("tenantId", "assignmentId", "chartJson", "filesJson", "savedAt", "studentId", "text") SELECT 'tenant-1', "assignmentId", "chartJson", "filesJson", "savedAt", "studentId", "text" FROM "AssignmentDraft";
DROP TABLE "AssignmentDraft";
ALTER TABLE "new_AssignmentDraft" RENAME TO "AssignmentDraft";
CREATE INDEX "AssignmentDraft_tenantId_idx" ON "AssignmentDraft"("tenantId");
CREATE TABLE "new_Submission" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "assignmentId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "attempt" INTEGER NOT NULL DEFAULT 1,
    "submittedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "late" BOOLEAN NOT NULL DEFAULT false,
    "text" TEXT,
    "filesJson" TEXT NOT NULL DEFAULT '[]',
    "chartJson" TEXT,
    "reviewStatus" TEXT NOT NULL DEFAULT 'waiting',
    "reviewerId" TEXT,
    "scoresJson" TEXT NOT NULL DEFAULT '{}',
    "points" REAL,
    "score" REAL,
    "feedback" TEXT NOT NULL DEFAULT '',
    "privateNote" TEXT,
    "reviewUpdatedAt" DATETIME,
    "overdueNotifiedAt" DATETIME,
    CONSTRAINT "Submission_assignmentId_fkey" FOREIGN KEY ("assignmentId") REFERENCES "CourseAssignment" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Submission_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Submission_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Submission" ("tenantId", "assignmentId", "attempt", "chartJson", "feedback", "filesJson", "id", "late", "overdueNotifiedAt", "points", "privateNote", "reviewStatus", "reviewUpdatedAt", "reviewerId", "score", "scoresJson", "studentId", "submittedAt", "text") SELECT 'tenant-1', "assignmentId", "attempt", "chartJson", "feedback", "filesJson", "id", "late", "overdueNotifiedAt", "points", "privateNote", "reviewStatus", "reviewUpdatedAt", "reviewerId", "score", "scoresJson", "studentId", "submittedAt", "text" FROM "Submission";
DROP TABLE "Submission";
ALTER TABLE "new_Submission" RENAME TO "Submission";
CREATE INDEX "Submission_assignmentId_idx" ON "Submission"("assignmentId");
CREATE INDEX "Submission_studentId_idx" ON "Submission"("studentId");
CREATE INDEX "Submission_tenantId_idx" ON "Submission"("tenantId");
CREATE TABLE "new_CertificateTemplate" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "style" TEXT NOT NULL,
    "accent" TEXT NOT NULL,
    "heading" TEXT NOT NULL,
    "statement" TEXT NOT NULL,
    "signatoriesJson" TEXT NOT NULL DEFAULT '[]',
    "showScore" BOOLEAN NOT NULL DEFAULT true,
    "showHours" BOOLEAN NOT NULL DEFAULT true,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "CertificateTemplate_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_CertificateTemplate" ("tenantId", "accent", "heading", "id", "isDefault", "name", "showHours", "showScore", "signatoriesJson", "statement", "style", "updatedAt") SELECT 'tenant-1', "accent", "heading", "id", "isDefault", "name", "showHours", "showScore", "signatoriesJson", "statement", "style", "updatedAt" FROM "CertificateTemplate";
DROP TABLE "CertificateTemplate";
ALTER TABLE "new_CertificateTemplate" RENAME TO "CertificateTemplate";
CREATE INDEX "CertificateTemplate_tenantId_idx" ON "CertificateTemplate"("tenantId");
CREATE TABLE "new_IssuedCertificate" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "credentialId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "templateId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'pending',
    "completedAt" DATETIME NOT NULL,
    "issuedAt" DATETIME,
    "revokedAt" DATETIME,
    "revokedReason" TEXT,
    "finalScore" REAL,
    "hours" REAL NOT NULL DEFAULT 0,
    "verifications" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "IssuedCertificate_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "IssuedCertificate_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "IssuedCertificate_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES "CertificateTemplate" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "IssuedCertificate_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_IssuedCertificate" ("tenantId", "completedAt", "courseId", "credentialId", "finalScore", "hours", "id", "issuedAt", "revokedAt", "revokedReason", "status", "studentId", "templateId", "title", "verifications") SELECT 'tenant-1', "completedAt", "courseId", "credentialId", "finalScore", "hours", "id", "issuedAt", "revokedAt", "revokedReason", "status", "studentId", "templateId", "title", "verifications" FROM "IssuedCertificate";
DROP TABLE "IssuedCertificate";
ALTER TABLE "new_IssuedCertificate" RENAME TO "IssuedCertificate";
CREATE UNIQUE INDEX "IssuedCertificate_credentialId_key" ON "IssuedCertificate"("credentialId");
CREATE INDEX "IssuedCertificate_studentId_idx" ON "IssuedCertificate"("studentId");
CREATE INDEX "IssuedCertificate_courseId_idx" ON "IssuedCertificate"("courseId");
CREATE INDEX "IssuedCertificate_tenantId_idx" ON "IssuedCertificate"("tenantId");
CREATE TABLE "new_LiveClass" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "instructorId" TEXT NOT NULL,
    "startsAt" DATETIME NOT NULL,
    "durationMin" INTEGER NOT NULL,
    "capacity" INTEGER,
    "cancelled" BOOLEAN NOT NULL DEFAULT false,
    "cancelReason" TEXT,
    "recordingJson" TEXT,
    "description" TEXT,
    "agendaJson" TEXT NOT NULL DEFAULT '[]',
    "visibility" TEXT NOT NULL DEFAULT 'enrolled',
    "meetingJson" TEXT NOT NULL DEFAULT '{"kind":"room"}',
    "remindersJson" TEXT NOT NULL DEFAULT '[]',
    "remindersSentJson" TEXT NOT NULL DEFAULT '[]',
    "chapterId" TEXT,
    CONSTRAINT "LiveClass_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LiveClass_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "Instructor" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "LiveClass_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_LiveClass" ("tenantId", "agendaJson", "cancelReason", "cancelled", "capacity", "chapterId", "courseId", "description", "durationMin", "id", "instructorId", "meetingJson", "recordingJson", "remindersJson", "remindersSentJson", "startsAt", "title", "visibility") SELECT 'tenant-1', "agendaJson", "cancelReason", "cancelled", "capacity", "chapterId", "courseId", "description", "durationMin", "id", "instructorId", "meetingJson", "recordingJson", "remindersJson", "remindersSentJson", "startsAt", "title", "visibility" FROM "LiveClass";
DROP TABLE "LiveClass";
ALTER TABLE "new_LiveClass" RENAME TO "LiveClass";
CREATE INDEX "LiveClass_courseId_idx" ON "LiveClass"("courseId");
CREATE INDEX "LiveClass_instructorId_idx" ON "LiveClass"("instructorId");
CREATE INDEX "LiveClass_tenantId_idx" ON "LiveClass"("tenantId");
CREATE TABLE "new_LiveRegistration" (
    "liveClassId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "registeredAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "attended" BOOLEAN,

    PRIMARY KEY ("liveClassId", "studentId"),
    CONSTRAINT "LiveRegistration_liveClassId_fkey" FOREIGN KEY ("liveClassId") REFERENCES "LiveClass" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LiveRegistration_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "LiveRegistration_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_LiveRegistration" ("tenantId", "attended", "liveClassId", "registeredAt", "studentId") SELECT 'tenant-1', "attended", "liveClassId", "registeredAt", "studentId" FROM "LiveRegistration";
DROP TABLE "LiveRegistration";
ALTER TABLE "new_LiveRegistration" RENAME TO "LiveRegistration";
CREATE INDEX "LiveRegistration_tenantId_idx" ON "LiveRegistration"("tenantId");
CREATE TABLE "new_CalendarEvent" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "timing" TEXT NOT NULL,
    "startsAt" DATETIME NOT NULL,
    "durationMin" INTEGER,
    "courseId" TEXT,
    "chapterId" TEXT,
    "instructorId" TEXT,
    "quizId" TEXT,
    "milestone" TEXT,
    "audience" TEXT,
    "ownerId" TEXT,
    "notifyMin" INTEGER,
    "notifiedAt" DATETIME,
    "done" BOOLEAN NOT NULL DEFAULT false,
    "cancelled" BOOLEAN NOT NULL DEFAULT false,
    "sourceJson" TEXT,
    CONSTRAINT "CalendarEvent_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "Course" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CalendarEvent_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "Instructor" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "CalendarEvent_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "CalendarEvent_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_CalendarEvent" ("tenantId", "audience", "cancelled", "chapterId", "courseId", "description", "done", "durationMin", "id", "instructorId", "milestone", "notifiedAt", "notifyMin", "ownerId", "quizId", "sourceJson", "startsAt", "timing", "title", "type") SELECT 'tenant-1', "audience", "cancelled", "chapterId", "courseId", "description", "done", "durationMin", "id", "instructorId", "milestone", "notifiedAt", "notifyMin", "ownerId", "quizId", "sourceJson", "startsAt", "timing", "title", "type" FROM "CalendarEvent";
DROP TABLE "CalendarEvent";
ALTER TABLE "new_CalendarEvent" RENAME TO "CalendarEvent";
CREATE INDEX "CalendarEvent_courseId_idx" ON "CalendarEvent"("courseId");
CREATE INDEX "CalendarEvent_startsAt_idx" ON "CalendarEvent"("startsAt");
CREATE INDEX "CalendarEvent_ownerId_idx" ON "CalendarEvent"("ownerId");
CREATE INDEX "CalendarEvent_tenantId_idx" ON "CalendarEvent"("tenantId");
CREATE TABLE "new_AppNotification" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT,
    "recipientId" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "bodyJson" TEXT NOT NULL DEFAULT '[]',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "readAt" DATETIME,
    "important" BOOLEAN NOT NULL DEFAULT false,
    "actor" TEXT,
    "factsJson" TEXT,
    "actionJson" TEXT,
    "secondaryActionJson" TEXT,
    CONSTRAINT "AppNotification_recipientId_fkey" FOREIGN KEY ("recipientId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "AppNotification_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_AppNotification" ("tenantId", "actionJson", "actor", "bodyJson", "category", "createdAt", "factsJson", "id", "important", "readAt", "recipientId", "secondaryActionJson", "summary", "title") SELECT (SELECT CASE WHEN u."role" = 'superadmin' THEN NULL ELSE 'tenant-1' END FROM "User" u WHERE u."id" = "AppNotification"."recipientId"), "actionJson", "actor", "bodyJson", "category", "createdAt", "factsJson", "id", "important", "readAt", "recipientId", "secondaryActionJson", "summary", "title" FROM "AppNotification";
DROP TABLE "AppNotification";
ALTER TABLE "new_AppNotification" RENAME TO "AppNotification";
CREATE INDEX "AppNotification_recipientId_createdAt_idx" ON "AppNotification"("recipientId", "createdAt");
CREATE INDEX "AppNotification_tenantId_idx" ON "AppNotification"("tenantId");
CREATE TABLE "new_NotificationSettings" (
    "userId" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT,
    "categoriesJson" TEXT NOT NULL DEFAULT '[]',
    "emailDigest" TEXT NOT NULL DEFAULT 'instant',
    "quietHoursJson" TEXT NOT NULL DEFAULT '{"enabled":false,"from":"22:00","to":"07:00"}',
    "pausedUntil" DATETIME,
    "smsNumber" TEXT NOT NULL DEFAULT '',
    "lastDigestAt" DATETIME,
    CONSTRAINT "NotificationSettings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "NotificationSettings_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_NotificationSettings" ("tenantId", "categoriesJson", "emailDigest", "lastDigestAt", "pausedUntil", "quietHoursJson", "smsNumber", "userId") SELECT (SELECT CASE WHEN u."role" = 'superadmin' THEN NULL ELSE 'tenant-1' END FROM "User" u WHERE u."id" = "NotificationSettings"."userId"), "categoriesJson", "emailDigest", "lastDigestAt", "pausedUntil", "quietHoursJson", "smsNumber", "userId" FROM "NotificationSettings";
DROP TABLE "NotificationSettings";
ALTER TABLE "new_NotificationSettings" RENAME TO "NotificationSettings";
CREATE INDEX "NotificationSettings_tenantId_idx" ON "NotificationSettings"("tenantId");
CREATE TABLE "new_Settings" (
    "tenantId" TEXT NOT NULL PRIMARY KEY,
    "generalJson" TEXT NOT NULL,
    "coursesJson" TEXT NOT NULL,
    "learningJson" TEXT NOT NULL,
    "certificatesJson" TEXT NOT NULL,
    "notificationsJson" TEXT NOT NULL,
    "appearanceJson" TEXT NOT NULL,
    "updatedAtJson" TEXT NOT NULL,
    "updatedByJson" TEXT NOT NULL,
    CONSTRAINT "Settings_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Settings" ("tenantId", "appearanceJson", "certificatesJson", "coursesJson", "generalJson", "learningJson", "notificationsJson", "updatedAtJson", "updatedByJson") SELECT 'tenant-1', "appearanceJson", "certificatesJson", "coursesJson", "generalJson", "learningJson", "notificationsJson", "updatedAtJson", "updatedByJson" FROM "Settings";
DROP TABLE "Settings";
ALTER TABLE "new_Settings" RENAME TO "Settings";

-- CreateIndex
CREATE UNIQUE INDEX "Tenant_slug_key" ON "Tenant"("slug");
-- CreateIndex
CREATE INDEX "Tenant_status_idx" ON "Tenant"("status");

-- The academy's owner: its longest-standing admin, when it has one.
UPDATE "Tenant" SET "ownerUserId" = (SELECT "id" FROM "User" WHERE "role" = 'admin' ORDER BY "createdAt" ASC, "id" ASC LIMIT 1)
WHERE "id" = 'tenant-1';

-- Verify the backfill. SQLite only raises inside triggers, so each check inserts 1 (holds) or 0 (broken)
-- into a table that accepts only 1 — a broken invariant fails this statement and the whole migration.
CREATE TEMP TABLE "_tenant_backfill_check" ("ok" INTEGER NOT NULL CHECK ("ok" = 1));
-- A user belongs to an academy exactly when it is not a super admin.
INSERT INTO "_tenant_backfill_check" ("ok") SELECT CASE WHEN EXISTS (
  SELECT 1 FROM "User" WHERE ("role" = 'superadmin') = ("tenantId" IS NOT NULL)
) THEN 0 ELSE 1 END;
-- Rows that hang off a user sit in that user's academy.
INSERT INTO "_tenant_backfill_check" ("ok") SELECT CASE WHEN EXISTS (
  SELECT 1 FROM "PasswordResetToken" t JOIN "User" u ON u."id" = t."userId" WHERE t."tenantId" IS NOT u."tenantId"
  UNION ALL SELECT 1 FROM "NotificationSettings" t JOIN "User" u ON u."id" = t."userId" WHERE t."tenantId" IS NOT u."tenantId"
  UNION ALL SELECT 1 FROM "AppNotification" t JOIN "User" u ON u."id" = t."recipientId" WHERE t."tenantId" IS NOT u."tenantId"
) THEN 0 ELSE 1 END;
-- Every tenantId names a tenant that exists.
INSERT INTO "_tenant_backfill_check" ("ok") SELECT CASE WHEN EXISTS (
  SELECT 1 FROM "AdminPermission" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "AppNotification" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "AssignmentDraft" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "CalendarEvent" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Category" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "CategoryLevel" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "CertificateTemplate" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Chapter" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Course" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "CourseAssignment" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "CourseInstructor" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "EmailOutbox" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Enrollment" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Instructor" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "IssuedCertificate" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Lesson" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "LessonBookmark" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "LessonNote" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "LessonProgress" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Level" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "LiveClass" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "LiveRegistration" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "MediaAsset" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "NotificationSettings" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "PasswordResetToken" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Quiz" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "QuizAttempt" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Rank" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "SavedCourse" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Settings" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Student" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "Submission" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
  UNION ALL SELECT 1 FROM "User" WHERE "tenantId" IS NOT NULL AND "tenantId" NOT IN (SELECT "id" FROM "Tenant")
) THEN 0 ELSE 1 END;
DROP TABLE "_tenant_backfill_check";
COMMIT;
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
