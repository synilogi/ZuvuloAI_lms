# Module — Quizzes

Status: **COMPLETED** (phase F7) · Depends on: Lessons, Learning progress

## 1. Purpose
Quiz authoring (questions, settings, preview) and results for staff; attempts for learners through the
lesson player.

## 2. Existing UI
`/:base/quizzes` (list), builder `/:base/quizzes/:id` (Questions, Settings, Preview, Results tabs),
`QuizTaker` in the player. Files: `pages/lms/quizzes/*`.

## 3. UI Data Requirements
`QuizSummary { id, title, courseTitle, chapterTitle, questionCount, attempts, passRate, status }`;
`Quiz` (questions typed single/multiple/true-false/short, settings: passMark, attempts, timeLimit,
shuffle, showAnswers); `QuizStats { attempts, passRate, averagePercent, medianMinutes, perQuestion[]
with commonWrongOptionId, recentAttempts[] }`.

## 4. Database
`Quiz` (courseId FK, chapterId?, lessonId unique nullable, title, instructions, status, questionsJson,
settingsJson, timestamps) · `QuizAttempt` (quizId FK, studentId FK, answersJson, resultJson, percent,
passed, durationSec?, createdAt; indexes quizId, studentId).

## 5. API
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/quizzes` | admin, instructor (own courses) |
| GET | `/quizzes/:id` · `/quizzes/:id/stats` | same |
| POST | `/quizzes` · PATCH `/quizzes/:id` | same — schema-validated (400), `lessonId` link rules (409), `validateQuiz` on publish (409); a quiz cannot move to another course |
| POST | `/quizzes/:id/duplicate` | same |
| DELETE | `/quizzes/:id` | same — 409 while a lesson delivers it |

## 6. Business Rules
`validateQuiz`; `scoreAttempt` on the server (F6); attempt limits + retake wait (F6); delivered quizzes
cannot be deleted (F5); list `chapterTitle` from the quiz's chapter or its lesson's chapter; stats from
stored attempts: pass rate, average, ten score bands, per-question correct rate, the most-picked wrong
option among incorrect attempts (`commonWrongOptionId`), median minutes from `durationSec` (the quiz taker
measures from start to submit).

## 7. Permissions
Staff of the quiz's course. Learners never call `/quizzes/*`.

## 8. Backend Status
✅ CRUD, scope, link rules, delete guard · ✅ validation, chapterTitle, medianMinutes, commonWrongOptionId from stored answers/durations (F7).

## 9. Frontend Integration
`services/http/quizzes.ts`; wired.

## 10. Testing
`routes/quizzes.test.ts` — chapterTitle on the list, validation 400, course move 409, stats after a real attempt (median minutes, common wrong option, correct rate); link/delete rules in `catalog.test.ts`; scope in `permissions.test.ts`.

## 11. Completion
- [x] CRUD
- [x] Attempt storage + real stats
- [x] Delete guard, scope, tests

## 12. Quiz sessions (14 Oct 2026)

`settings.timeLimit` is now enforced. A learner's attempt is a `QuizSession` the server starts (`POST
/learning/courses/:courseId/lessons/:lessonId/quiz-session`): starting consumes an attempt after the attempt limit and retake
wait are checked against every attempt used, and the deadline is the server's clock plus the time limit. The answer sheet is
saved as the learner goes (`PUT …/quiz-session/:sessionId/answers` with a sequence number that only grows; a late or
out-of-order save changes nothing). `POST …/quiz-session/:sessionId/submit` finishes it once: a final sheet counts before the
deadline, only what was saved counts in the grace after it, and the scheduler closes and scores an expired session on what was
saved. Finishing writes the `QuizAttempt` exactly as `quiz-attempt` did, so stats, `showResults` cuts and completion rules are
unchanged. Rules: `packages/domain/src/quizSession.ts`; server: `apps/api/src/lib/quizSessions.ts`; tests:
`quizSession.test.ts`, `quizSessions.test.ts`; endpoints: `05-API-SPECIFICATION.md` › Learning. The web lesson player and the
Flutter app both drive quizzes through sessions.
