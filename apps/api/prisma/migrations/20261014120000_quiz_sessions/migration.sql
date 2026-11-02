-- A2: server-authoritative quiz sessions (packages/domain/src/quizSession.ts).
--
-- Adds QuizSession: a learner's attempt from the moment the server starts it, with the deadline the server fixed,
-- the answers it accepted before that deadline, and the questions and settings (pass mark) as they stood at the start.
--
-- Adds QuizAttempt.sessionId (nullable, unique): the session a scored attempt finished. Every attempt made before
-- this migration keeps sessionId NULL and is counted, reviewed and scored exactly as before. SQLite adds a foreign
-- key column by rebuilding the table: every row is copied as it is (INSERT ... SELECT), then the indexes are
-- recreated. QuizAttempt has no triggers to restore.

-- CreateTable
CREATE TABLE "QuizSession" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT NOT NULL,
    "quizId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "attemptNo" INTEGER NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'active',
    "startedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deadlineAt" DATETIME,
    "questionsJson" TEXT NOT NULL,
    "settingsJson" TEXT NOT NULL DEFAULT '{}',
    "orderJson" TEXT NOT NULL DEFAULT '{}',
    "answersJson" TEXT NOT NULL DEFAULT '{}',
    "answersSeq" INTEGER NOT NULL DEFAULT 0,
    "answersSavedAt" DATETIME,
    "startKey" TEXT,
    "finishedAt" DATETIME,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "QuizSession_quizId_fkey" FOREIGN KEY ("quizId") REFERENCES "Quiz" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "QuizSession_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "QuizSession_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
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
    "sessionId" TEXT,
    CONSTRAINT "QuizAttempt_quizId_fkey" FOREIGN KEY ("quizId") REFERENCES "Quiz" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "QuizAttempt_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "Student" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "QuizAttempt_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "QuizSession" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "QuizAttempt_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_QuizAttempt" ("answersJson", "createdAt", "durationSec", "id", "passed", "percent", "quizId", "resultJson", "studentId", "tenantId") SELECT "answersJson", "createdAt", "durationSec", "id", "passed", "percent", "quizId", "resultJson", "studentId", "tenantId" FROM "QuizAttempt";
DROP TABLE "QuizAttempt";
ALTER TABLE "new_QuizAttempt" RENAME TO "QuizAttempt";
CREATE UNIQUE INDEX "QuizAttempt_sessionId_key" ON "QuizAttempt"("sessionId");
CREATE INDEX "QuizAttempt_quizId_idx" ON "QuizAttempt"("quizId");
CREATE INDEX "QuizAttempt_studentId_idx" ON "QuizAttempt"("studentId");
CREATE INDEX "QuizAttempt_tenantId_idx" ON "QuizAttempt"("tenantId");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE INDEX "QuizSession_studentId_quizId_idx" ON "QuizSession"("studentId", "quizId");

-- CreateIndex
CREATE INDEX "QuizSession_status_deadlineAt_idx" ON "QuizSession"("status", "deadlineAt");

-- CreateIndex
CREATE INDEX "QuizSession_tenantId_idx" ON "QuizSession"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "QuizSession_quizId_studentId_attemptNo_key" ON "QuizSession"("quizId", "studentId", "attemptNo");

