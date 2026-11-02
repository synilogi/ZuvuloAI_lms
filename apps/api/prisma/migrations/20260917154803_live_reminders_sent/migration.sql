-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_LiveClass" (
    "id" TEXT NOT NULL PRIMARY KEY,
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
    CONSTRAINT "LiveClass_instructorId_fkey" FOREIGN KEY ("instructorId") REFERENCES "Instructor" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_LiveClass" ("agendaJson", "cancelReason", "cancelled", "capacity", "chapterId", "courseId", "description", "durationMin", "id", "instructorId", "meetingJson", "recordingJson", "remindersJson", "startsAt", "title", "visibility") SELECT "agendaJson", "cancelReason", "cancelled", "capacity", "chapterId", "courseId", "description", "durationMin", "id", "instructorId", "meetingJson", "recordingJson", "remindersJson", "startsAt", "title", "visibility" FROM "LiveClass";
DROP TABLE "LiveClass";
ALTER TABLE "new_LiveClass" RENAME TO "LiveClass";
CREATE INDEX "LiveClass_courseId_idx" ON "LiveClass"("courseId");
CREATE INDEX "LiveClass_instructorId_idx" ON "LiveClass"("instructorId");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
