# Module — Learning progress

Status: **COMPLETED** (phase F6) · Depends on: Enrollments, Lessons, Quizzes, Assignments

## 1. Purpose
The learner's experience: home, my learning, explore, the course player (chapters, lessons, locks),
lesson completion, positions, notes, bookmarks, saved courses, coursework lists, quiz attempts,
certificate list, rank ladder and activity.

## 2. Existing UI
`/home`, `/my-learning` (in-progress, completed, saved), `/explore`, `/learn/:courseId`,
`/learn/:courseId/lessons/:lessonId` (player with video/reading/document/quiz/assignment/live panels),
`/assignments`, `/assignments/:id`, `/assessments`, `/certificates`, rank ladder widget.
Files: `pages/learner/*`, `components/lms/quiz/QuizTaker.tsx`, `components/lms/player/*`.

## 3. UI Data Requirements
`LearnerHome { continue, recent[], upcoming[], week[], stats, rank }`; `LearnerCourse` (course +
`instructorNames`, `levelTitle`, `progress`, `chapters[]` with `locked`, `lessons[]` with
`state locked|available|done`, `next`, `certificate?`); `LearnerLesson` (content + `progress`, `note`,
`bookmarked`, `threshold`, `quiz?`, `assignment?`, `live?`); `AssessmentRow[]`; `AttemptResult`.

## 4. Database
`LessonProgress` (studentId, lessonId unique pair, secondsWatched, completedAt, lastAccessedAt — F0),
`LessonNote`, `LessonBookmark`, `SavedCourse`, `QuizAttempt`, `Submission`, `AssignmentDraft` (F0:
studentId, assignmentId unique pair, bodyJson, updatedAt).

## 5. API (`/learning`, role student — staff may preview with `?as=` never; staff use course preview)
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/home` | courses (active first), saved, `recent` (last 5 accessed lessons), `upcoming` (live classes, deadlines, ready quizzes in 14 days with flags), `week` (7 study days) |
| GET | `/courses` | enrolled + saved with progress |
| GET | `/courses/:courseId` | player tree with locks (F6) |
| GET | `/courses/:courseId/lessons/:lessonId` | `LessonView` + `threshold`; `access` open/locked/not-enrolled/unavailable (expired, unpublished); records the visit |
| POST | `.../complete` | applies the lesson's completion rule (409 with the reason otherwise); returns `CompletionResult` |
| PUT | `.../position` | `{ positionSec, fraction }`; keeps the furthest fraction; auto-completes `watched` lessons at the threshold |
| PUT | `.../note` · POST `.../bookmark` · POST `/courses/:courseId/save` | |
| POST | `/courses/:courseId/enroll` | policy + expiry, see enrollments; returns `LearnerCourse` with names/level |
| GET | `/assignments` · `/assignments/:assignmentId` · PUT `/draft` · POST `/submit` | enrolled only; drafts persisted (`AssignmentDraft`) and cleared on submit; `dueAt` fixed or relative to when the chapter opened for the learner; 409 on empty work, repeat submission, closed assignment or a passed deadline that does not accept late work; hand-in completes a `submitted` lesson |
| GET | `/assessments` | quiz rows with best attempt |
| POST | `.../quiz-attempt` | `{ answers, durationSec? }` → scored on the server; `null` when failed, `CompletionResult` when passed; 409 when locked, out of attempts or waiting for a retake |
| GET | `/certificates` · `/certificates/:id` · POST `/claim` | ownership (F9) |
| GET | `/rank-ladder` · `/activity` | |

## 6. Business Rules
`lib/learning.ts`: `courseProgress` (duration weighted); chapter gating (`settings.learning.chapterGate`):
a chapter opens when the previous chapter's published non-assignment lessons are done, a chapter quiz when
its other lessons are done; `completionThreshold` auto-completes a `watched` lesson from `PUT position` and
`POST complete` needs at least threshold − 10 % stored; `opened` lessons complete on request; `passed`
lessons only through a passing quiz attempt; `submitted`: assignment lessons on hand-in, practice
exercises with ≥ 20 characters of notes or a hand-in; course completion per `courseCompletion`
(`all-lessons` = every non-assignment lesson incl. quizzes, `lessons-and-assessments` = everything,
`percentage` = `completionPercent` of lessons plus every quiz) → `Enrollment.completedAt` and the
certificates hook. Quiz attempts are scored with `scoreAttempt` from the submitted `answers` (client
scores ignored), stored with answers/result/duration; until passed, attempts are limited to the quiz's
`settings.attempts` (0 = unlimited, falling back to `settings.learning.quizAttempts`) with
`retakeWaitHours` between them; after a pass, retakes are practice and the best score is kept. Every open
visit records `lastAccessedAt`, `Enrollment.lastLessonId/lastActiveAt` and `Student.lastActiveAt`.

## 7. Permissions
Student only, always scoped to `req.auth.studentId`; every course/lesson/assignment/certificate id is
verified against the learner's enrollments before returning content.

## 8. Backend Status
✅ all routes · ✅ ownership (F2) · ✅ gating, thresholds, completion rules, course completion, drafts, server-side scoring + attempt limits, home feed, live lesson data, expiry (F6) · 🟨 `working` certificates list and certificate creation on completion (F9).

## 9. Frontend Integration
`services/http/learning.ts`; `QuizTaker.onSubmit` now passes the answers, the player sends them with
`recordQuizAttempt` and shows a toast when the server refuses an attempt; drafts flow through the existing
`saveAssignmentDraft`/`draft` contract. No other screen changes.

## 10. Testing
`routes/learning.test.ts` — policy/expiry, chapter and quiz locks with reasons, threshold refusal and
auto-completion, recent/week on home, per-rule completion refusals, server-side scoring ignoring client
scores, attempt limits, chapter unlock after a pass, drafts persisted/cleared, course completion under
`all-lessons`. Browser check: course page, locked lesson, player completion, quiz attempt, home, drafts.

## 11. Completion
- [x] Routes
- [x] Gating + rules + scoring + drafts + home data
- [x] Ownership checks
- [x] Tests
