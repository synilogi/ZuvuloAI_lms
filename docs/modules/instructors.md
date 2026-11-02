# Module — Instructors

Status: **COMPLETED** (phase F4) · Depends on: Roles & permissions (F2)

## 1. Purpose
Admin management of teaching staff: invite, edit profile, activate/deactivate, resend invitation; per
instructor courses and performance figures.

## 2. Existing UI
`/admin/instructors` (list), `/admin/instructors/new`, `/admin/instructors/:id/edit`,
`/admin/instructors/:id` (Overview, Courses, Performance tabs). Files: `pages/lms/instructors/*`.

## 3. UI Data Requirements
`InstructorSummary` (courses, learners, rating, status); `InstructorProfile` (instructor, courses with
`levelTitle`, `lessons`, `activeLearners`, `completion`; performance: `academyRating`,
`academyCompletion`, `enrollmentsByMonth[]`, `activity[]`, `cities[]`).

## 4. Database
`Instructor` (name, title, yearsTeaching, email unique, bio, expertiseJson, status invited|active|inactive,
joinedAt, city, languagesJson, phone, photoJson) linked from `User.instructorId` (one sign-in account per
profile, created with the profile) · `CourseInstructor` (courseId, instructorId; the first instructor is
the lead).

## 5. API
| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/instructors` | admin, instructor (read) | |
| GET | `/instructors/:id` | admin, instructor (self or read) | profile + performance |
| POST | `/instructors` | admin | `validateInstructor`; 409 if any account uses the email; creates the profile + a User account (random password); status `invited` also queues an `instructor-invite` email with a 7-day set-password link |
| PATCH | `/instructors/:id` | admin | profile fields; the linked account's name/email/descriptor follow; 409 on an email clash |
| POST | `/instructors/:id/status` | admin | `{ status }` — `inactive` blocks sign-in (403) |
| POST | `/instructors/:id/resend-invite` | admin | issues a fresh set-password link (creates the account if a seeded profile has none) |

## 6. Business Rules
`validateInstructor` (name, valid email, title, ≥ 1 expertise). Ratings are enrollment-weighted means of
published courses (own vs academy). Completion = completed ÷ non-paused enrollments (per course, own,
academy). `activeLearners` = active enrollments touched in the last 14 days. Review turnaround =
median hours from submission to grading, `reviewsOnTime` = share within 48 h. Attendance = attended ÷
registrations with a recorded outcome over delivered classes (null until recorded). `enrollmentsByMonth` =
eight months ending this month. Activity = course published/updated, reviews grouped by day (21 days),
live classes hosted/scheduled/cancelled, invitation — newest first, 12 items.

## 7. Permissions
Admin writes; instructors may read the list and their own profile (the teach shell shows the instructor's
own name). Students: 403.

## 8. Backend Status
✅ list (with completion) / profile (all figures real) / invite with account + email / patch keeps the account in sync / status (inactive blocks sign-in) / resend.

## 9. Frontend Integration
`services/http/instructors.ts`; no frontend changes planned.

## 10. Testing
`routes/instructors.test.ts` — profile figures for the seeded lead instructor; invite creates the account and a
working set-password link, resend issues another; duplicate email 409; edit syncs the account email;
deactivation blocks sign-in. Role guards in `permissions.test.ts`.

## 11. Completion
- [x] CRUD + status + resend
- [x] Real performance / course figures
- [x] Invitation email (outbox)
- [x] Tests
