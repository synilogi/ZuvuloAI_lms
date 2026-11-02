# Module — Enrollments

Status: **COMPLETED** (phase F6) · Depends on: Courses, Students

## 1. Purpose
Who is in which course, how they got there (self, admin, cohort, scholarship), their status (active,
paused, completed, expired) and access length.

## 2. Existing UI
Student profile Courses tab + Enroll dialog (staff); learner `Enroll` button on `/explore` and the public
course page; `/my-learning` lists. No dedicated enrollments screen.

## 3. UI Data Requirements
`Enrollment { id, studentId, courseId, status, source, progress, enrolledAt, completedAt, lastLessonId,
lastActiveAt, expiresAt? }`; learner course cards read `progress`, `status`, `next lesson`.

## 4. Database
`Enrollment` (studentId FK, courseId FK, unique (studentId, courseId), status, source, progress,
enrolledAt, completedAt, lastLessonId, lastActiveAt, expiresAt — F6; indexes on courseId, studentId).

## 5. API
Staff: `/students/:id/enroll`, `/students/enrollments/:id` (PATCH/DELETE). Learner:
`POST /learning/courses/:courseId/enroll` (self). Reports and dashboard aggregate the table.

## 6. Business Rules
- One enrollment per student and course (unique index → 409).
- Self-enrolment: only `settings.general.enrollment = open` lets learners enrol themselves (published,
  non-private courses; suspended accounts refused); `approval` and `invite` answer 409 with an explanation
  and staff enrol learners through the Students module. (The domain has no `pending` status, so an
  approval queue is not modelled — a product decision recorded in REMAINING ITEMS.)
- `expiresAt` = enrolledAt + `settings.general.accessMonths` (null = lifetime); an active enrollment past
  `expiresAt` flips to `expired` lazily on read; expired learners see lessons as `unavailable` and cannot
  complete, attempt quizzes or submit.
- `enrolledCount` on the course tracks active rows; removal deletes progress in a transaction.
- Completing the course sets `completedAt`, status `completed`, and triggers certificate eligibility (F9).

## 7. Permissions
Admin: any. Instructor: enrollments in their own courses. Student: only their own via `/learning`.

## 8. Backend Status
✅ create / status / remove / self-enrol · ✅ instructor scope on staff enrollment routes (F2) · ✅ enrolment policy, access months → `expiresAt`, lazy expiry, suspended check (F6).

## 9. Frontend Integration
Through `students.ts` and `learning.ts`; no UI change (the UI already renders every status string).

## 10. Testing
`routes/learning.test.ts` (policy open/approval/invite, expiry from settings, names/level), `permissions.test.ts` (drafts hidden), `students.test.ts` (staff routes).

## 11. Completion
- [x] CRUD paths
- [x] Policy + access length + expiry
- [x] Tests
