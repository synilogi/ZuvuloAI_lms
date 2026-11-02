# Module — Students

Status: **COMPLETED** (phase F3) · Depends on: Roles & permissions (F2), Enrollments

## 1. Purpose
Staff-facing roster of learners with profile, courses, progress and activity, plus admin actions
(enroll, change enrollment status, remove enrollment, suspend/reinstate, message).

## 2. Existing UI
`/admin/students`, `/teach/students` (list with search/filters/sort), `/:base/students/:id`
(profile header + tabs: Overview, Courses, Progress, Activity), dialogs: Enroll in course, Message,
Suspend/Reinstate. Files: `apps/web/src/pages/lms/students/*`.

## 3. UI Data Requirements
`StudentSummary` rows (status derived, active courses, progress %, last active); `StudentProfile`
(student, rank, enrollments with course title/progress/status, stats: studyMinutes, completedLessons,
quizAverage, certificates); `StudentProgress` (per course: lessons, quizzes with courseTitle, assignments,
studyWeeks[]); `ActivityItem[]` feed (`kind`, `title`, `at`, `courseId`).

## 4. Database
`Student` (userId unique FK, phone, city, joinedAt, lastActiveAt, suspended, rankId FK) ·
`Enrollment` (studentId+courseId unique, status, source, progress, enrolledAt, completedAt,
lastLessonId, lastActiveAt) · `LessonProgress` (studentId+lessonId unique, secondsWatched, completedAt,
lastAccessedAt — F0) · `QuizAttempt`, `Submission`, `IssuedCertificate`.

## 5. API
| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/students` | admin, instructor | instructor sees only learners enrolled in their courses (F2) |
| GET | `/students/:id` | admin, instructor (scoped) | profile |
| GET | `/students/:id/progress` | admin, instructor (scoped) | per-course progress detail |
| GET | `/students/:id/activity` | admin, instructor (scoped) | activity feed |
| POST | `/students/message` | admin, instructor (scoped) | `{ ids, subject, body, channels: ('app'|'email')[] }` → `{ sent }`; one `course` notification and/or outbox email per in-scope learner via `notify()` |
| POST | `/students/:id/enroll` | admin, instructor (own course) | `{ courseId, source }` |
| PATCH | `/students/enrollments/:enrollmentId` | admin, instructor (own course) | `{ status }` |
| DELETE | `/students/enrollments/:enrollmentId` | admin | removes progress, decrements `enrolledCount` |
| POST | `/students/:id/suspend` | admin | `{ suspended: boolean }` |

## 6. Business Rules
`deriveStudentStatus` (suspended › inactive ≥ 45 quiet days › at-risk ≥ `settings.learning.atRiskDays`
with open work › active). Study minutes (`lib/study.ts`): a completed lesson counts its full duration, an
in-progress lesson its fraction × duration. Study weeks = the last 12 weeks, oldest first, bucketed by
completion / last-access time; the last is labelled "This week". `lastLessonTitle` = the lesson in
progress, else the first published lesson not yet completed ("Up next"). `avgScore` = mean of graded
submissions as % of each assignment's maximum. For an instructor, every figure covers only the courses
they teach.

## 7. Permissions
Admin: everything. Instructor: read only learners enrolled in a course they teach; enroll/status only for
their own courses. Students: no access (403).

## 8. Backend Status
✅ list / profile / enroll / status / remove / suspend · ✅ instructor scope, figures scoped to the instructor's courses (F2/F3) · ✅ studyMinutes, studyWeeks, lastLessonTitle, quiz courseTitle, avgScore (F3) · ✅ message → notifications + outbox (F3).

## 9. Frontend Integration
`services/http/students.ts` — all screens wired; no frontend changes expected in F3.

## 10. Testing
`permissions.test.ts` (scope, 403/404 cases) and `routes/students.test.ts` — profile figures (study minutes,
next lesson, quiet days, lessons done/total), progress (quiz course titles, 12 study weeks), instructor
scoping of enrollments, message → notification + outbox, out-of-scope ids dropped, channel preferences
honoured, validation 400.

## 11. Completion
- [x] Routes exist and screens render
- [x] Real study time, weeks, last lesson, quiz course titles
- [x] Message → notifications
- [x] Instructor scoping (F2)
- [x] Tests

## 12. Adding learners, invitations and join links (October 2026)

- `POST /students` (admin, `learners.enroll`, relabelled "Add and enrol learners"): creates a learner in the academy with a
  random password and a 7-day `learner-invite` set-password link; `POST /students/:id/resend-invite` sends it again. The
  seat is taken under the usage guard (`learners.max`) and refused in restricted mode (SAAS-028, `lib/learners.ts`).
- **Invitations** (`/invitations`, 5 Oct 2026): an Admin invites one learner by email; the `/invite/<token>` link registers a
  new learner (after the emailed code) or signs an existing account into the Admin's workspace; revocable; only the token's
  hash is stored. An academy whose enrolment policy is `invite` takes learners by invitation only.
- **Join link** (`/join/:slug`) and **course links** (`/courses/:courseId/enroll`): public learner sign-up into the named
  academy, under its policy, after the emailed code (`PendingAccount`).
- Every door is listed in `04-AUTHENTICATION-AUTHORIZATION.md` › Registration doors; endpoints in `05-API-SPECIFICATION.md`
  (`/public`, `/invitations`); tests `learnerJoin.test.ts`, `invitations.test.ts`, `emailVerification.test.ts`,
  `e2e/learners.spec.ts`, `e2e/invitations.spec.ts`.
