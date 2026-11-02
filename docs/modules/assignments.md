# Module — Assignments

Status: **COMPLETED** (phase F8) · Depends on: Lessons, Enrollments, Learning progress

## 1. Purpose
Assignment authoring, submissions, review queue and grading for staff; hand-in for learners.

## 2. Existing UI
`/:base/assignments` (list), `/review` (queue), editor `/:id`, `/:id/submissions`,
`/submissions/:submissionId` (review page); learner `/assignments`, `/assignments/:id` (brief, draft,
submit, feedback). Files: `pages/lms/assignments/*`, `pages/learner/assignments/*`.

## 3. UI Data Requirements
`AssignmentSummary { id, title, courseTitle, chapterTitle, dueLabel, submitted, toReview, missing, status }`;
`Assignment` (instructions, rubric, maxScore, passMark, due fixed|relative, wordLimit, attachments);
`Submission` (studentName, submittedAt, late, attempt, status submitted|graded|returned, review?);
`ReviewQueue` (by course: toReview, overdue); learner `AssignmentDetail` + `draft`.

## 4. Database
`CourseAssignment` (courseId FK, lessonId FK nullable, title, status, instructionsJson, rubricJson,
maxScore, passMark, dueJson, wordLimit, attachmentsJson, timestamps) · `Submission` (assignmentId FK,
studentId FK, attempt, bodyJson, submittedAt, late, status, reviewJson, reviewedAt, reviewerUserId;
index (assignmentId, studentId)) · `AssignmentDraft` (F0).

## 5. API
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/assignments` · `/review` · `/submissions` | admin, instructor (own courses) |
| GET | `/assignments/:id` · `/:id/submissions` · `/submissions/:submissionId` | same |
| POST | `/assignments` · PATCH `/:id` · POST `/:id/duplicate` · DELETE `/:id` | same; schema-validated (400); `acceptsLate`/`latePenalty` default from the academy's late policy; `validateAssignment` on publish; delete guarded while a lesson delivers it |
| GET | `/assignments/submissions?filter=missing` | rows without a submission for every enrolled learner who has not handed in (`counts.missing`) |
| POST | `/submissions/:submissionId/review` | same — `validateReview`; `reviewScore` with the penalty only under the `penalty` policy; notifies the learner (graded: score/pass mark; returned: feedback); a graded pass completes a lesson whose rule is `passed` |
| POST | `/assignments/:id/remind` | same — reminders (app/email) only to learners who still owe the work; `{ studentIds }` narrows |
| learner | `/learning/assignments/*` | student, enrolled |

## 6. Business Rules
Late = handed in after `dueAt` (fixed, or relative to when the chapter opened for the learner — F6);
`settings.learning.latePolicy`: `reject` refuses late hand-ins, `penalty` deducts the assignment's
`latePenalty` % at grading (defaulting from `settings.learning.latePenalty`), `accept` deducts nothing;
grading validation; returned → the learner resubmits as attempt + 1; graded ≥ passMark completes a
lesson whose completion rule is `passed` (hand-in completes `submitted` lessons — F6); `missing` = enrolled
(not paused) learners without a submission on a published assignment; hand-in → notification to the
course's instructors; review → notification to the learner; reminders → notifications to owing learners.

## 7. Permissions
Staff of the course; learners only their own submissions and only for enrolled courses.

## 8. Backend Status
✅ CRUD, review, queue, submissions, remind · ✅ scope + learner ownership (F2) · ✅ link rules + delete guard (F5) · ✅ drafts, relative deadlines (F6) · ✅ validation, late policy, missing learners, chapterTitle, notifications, graded-pass completion (F8).

## 9. Frontend Integration
`services/http/assignments.ts`, `learning.ts`; wired.

## 10. Testing
`routes/assignments.test.ts` — defaults from the late policy, submit → instructor notification,
chapterTitle, returned → resubmit (attempt 2) → graded notification with score, review of a superseded
submission 409, validation 400, penalty/accept/reject policies, missing rows + counts, reminders only to
owing learners. Link rules in `catalog.test.ts`, drafts in `learning.test.ts`, scope in `permissions.test.ts`.

## 11. Completion
- [x] CRUD + review
- [x] Late policy, drafts, notifications, counts
- [x] Guards, scope, tests
