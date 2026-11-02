-- SAAS-002 · Feature catalogue & limits (subscriptions.md §4, §42).
--
-- The catalogue of features and limits a plan can grant, mirrored from packages/domain/src/entitlement.ts
-- so that every grant is a foreign key, and the per-version grants themselves as rows. Like the version
-- they belong to, grants are append-only: triggers refuse any UPDATE or DELETE, and a version fixes how
-- many grants it has (featureCount, limitCount) when it is written, so nothing can be added to its
-- allowance afterwards either. A version written before this migration declares 0 of each and so grants
-- nothing — a gap in the data can only ever refuse, never allow.
--
-- PlanVersion gains its two counts by ALTER TABLE ADD COLUMN. Prisma's own diff would rebuild the table,
-- which silently drops its immutability triggers and CHECK constraints; adding columns keeps them, and is
-- not an UPDATE, so the triggers do not fire.

-- AlterTable
ALTER TABLE "PlanVersion" ADD COLUMN "featureCount" INTEGER NOT NULL DEFAULT 0 CHECK (typeof("featureCount") = 'integer' AND "featureCount" >= 0);
ALTER TABLE "PlanVersion" ADD COLUMN "limitCount" INTEGER NOT NULL DEFAULT 0 CHECK (typeof("limitCount") = 'integer' AND "limitCount" >= 0);

-- CreateTable
CREATE TABLE "Feature" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "group" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "displayOrder" INTEGER NOT NULL
);

-- CreateTable
CREATE TABLE "LimitDefinition" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "label" TEXT NOT NULL,
    "unit" TEXT NOT NULL,
    "period" TEXT NOT NULL,
    "displayOrder" INTEGER NOT NULL,
    CONSTRAINT "LimitDefinition_unit_check" CHECK ("unit" IN ('count', 'bytes')),
    CONSTRAINT "LimitDefinition_period_check" CHECK ("period" IN ('total', 'month'))
);

-- CreateTable
CREATE TABLE "PlanFeature" (
    "planVersionId" TEXT NOT NULL,
    "featureKey" TEXT NOT NULL,

    PRIMARY KEY ("planVersionId", "featureKey"),
    CONSTRAINT "PlanFeature_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "PlanVersion" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanFeature_featureKey_fkey" FOREIGN KEY ("featureKey") REFERENCES "Feature" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "PlanLimit" (
    "planVersionId" TEXT NOT NULL,
    "limitKey" TEXT NOT NULL,
    "value" BIGINT,

    PRIMARY KEY ("planVersionId", "limitKey"),
    CONSTRAINT "PlanLimit_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "PlanVersion" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanLimit_limitKey_fkey" FOREIGN KEY ("limitKey") REFERENCES "LimitDefinition" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "PlanLimit_value_check" CHECK ("value" IS NULL OR (typeof("value") = 'integer' AND "value" >= 1))
);

-- CreateIndex
CREATE INDEX "PlanFeature_featureKey_idx" ON "PlanFeature"("featureKey");

-- CreateIndex
CREATE INDEX "PlanLimit_limitKey_idx" ON "PlanLimit"("limitKey");

-- The catalogue, exactly as packages/domain/src/entitlement.ts writes it (src/lib/plans.test.ts checks). The id is
-- the catalogue key itself: every foreign key in this schema names its target's id.
INSERT INTO "Feature" ("id", "group", "label", "description", "displayOrder") VALUES
    ('courses.manage', 'teaching', 'Course management', 'Courses, chapters and lessons with the full editor.', 1),
    ('assessments.manage', 'teaching', 'Assessments', 'Quizzes and assignments with grading and review queues.', 2),
    ('live_classes', 'teaching', 'Live classes', 'Scheduling, registration, attendance and recordings.', 3),
    ('certificates.manage', 'teaching', 'Certificates', 'Templates, issuing and public verification.', 4),
    ('reports.basic', 'insight', 'Reports', 'The dashboard and the course, learner and enrolment reports.', 5),
    ('reports.advanced', 'insight', 'Advanced reports', 'Instructor and completion reporting beyond the basic reports.', 6),
    ('analytics.advanced', 'insight', 'Advanced analytics', 'Cohort funnels, retention and exports.', 7),
    ('custom_branding', 'service', 'Custom branding', 'Academy colours, cover art and certificate marks.', 8),
    ('priority_support', 'service', 'Priority support', 'Named contact with a four-hour first response.', 9);

INSERT INTO "LimitDefinition" ("id", "label", "unit", "period", "displayOrder") VALUES
    ('learners.max', 'Learners', 'count', 'total', 1),
    ('instructors.max', 'Instructors', 'count', 'total', 2),
    ('courses.max', 'Courses', 'count', 'total', 3),
    ('storage.bytes', 'Media storage', 'bytes', 'total', 4),
    ('live_classes.max', 'Live classes a month', 'count', 'month', 5),
    ('admin_accounts.max', 'Admin accounts', 'count', 'total', 6);

-- Grants are append-only, like the version they belong to.
CREATE TRIGGER "PlanFeature_no_update" BEFORE UPDATE ON "PlanFeature"
BEGIN
    SELECT RAISE(ABORT, 'PlanFeature rows are immutable: add a new plan version instead');
END;

CREATE TRIGGER "PlanFeature_no_delete" BEFORE DELETE ON "PlanFeature"
BEGIN
    SELECT RAISE(ABORT, 'PlanFeature rows are immutable and are never deleted');
END;

CREATE TRIGGER "PlanLimit_no_update" BEFORE UPDATE ON "PlanLimit"
BEGIN
    SELECT RAISE(ABORT, 'PlanLimit rows are immutable: add a new plan version instead');
END;

CREATE TRIGGER "PlanLimit_no_delete" BEFORE DELETE ON "PlanLimit"
BEGIN
    SELECT RAISE(ABORT, 'PlanLimit rows are immutable and are never deleted');
END;

-- A version's allowance is sealed at the size it declared: no grant beyond featureCount / limitCount.
CREATE TRIGGER "PlanFeature_sealed" BEFORE INSERT ON "PlanFeature"
WHEN (SELECT count(*) FROM "PlanFeature" WHERE "planVersionId" = NEW."planVersionId")
     >= (SELECT "featureCount" FROM "PlanVersion" WHERE "id" = NEW."planVersionId")
BEGIN
    SELECT RAISE(ABORT, 'This plan version already grants every feature it declared');
END;

CREATE TRIGGER "PlanLimit_sealed" BEFORE INSERT ON "PlanLimit"
WHEN (SELECT count(*) FROM "PlanLimit" WHERE "planVersionId" = NEW."planVersionId")
     >= (SELECT "limitCount" FROM "PlanVersion" WHERE "id" = NEW."planVersionId")
BEGIN
    SELECT RAISE(ABORT, 'This plan version already sets every limit it declared');
END;

-- The catalogue can grow by migration; an entry that is granted cannot disappear (RESTRICT), and none is
-- ever deleted.
CREATE TRIGGER "Feature_no_delete" BEFORE DELETE ON "Feature"
BEGIN
    SELECT RAISE(ABORT, 'Catalogue features are never deleted');
END;

CREATE TRIGGER "LimitDefinition_no_delete" BEFORE DELETE ON "LimitDefinition"
BEGIN
    SELECT RAISE(ABORT, 'Catalogue limits are never deleted');
END;
