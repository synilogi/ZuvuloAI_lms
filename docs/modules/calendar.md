# Module — Calendar

Status: **COMPLETED** (phase F11) · Depends on: Live classes, Assignments, Quizzes

## 1. Purpose
Unified staff schedule: derived live classes and assignment deadlines plus user-created events
(reminders, quiz windows, milestones, chapter releases) with done state.

## 2. Existing UI
`/:base/calendar` (month/week/list), event panel, event editor. Files: `pages/lms/calendar/*`.

## 3. UI Data Requirements
`CalendarEvent { id, type live|assignment|quiz|milestone|reminder|chapter-release, title, startsAt,
durationMinutes, courseId/courseTitle, details (audienceSize, learnersDue, quizId, milestone, chapterId),
done, ownerId, derived }`.

## 4. Database
`CalendarEvent` (ownerId → User, type, title, description, timing, startsAt, durationMin, courseId,
chapterId, instructorId, quizId, milestone, audience, notifyMin, notifiedAt, done, cancelled; indexes
courseId, startsAt, ownerId). Live classes and fixed assignment deadlines are derived at read time
(`live-<id>`, `assignment-<id>`).

## 5. API
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/calendar?from&to&types&courseId&instructorId` | admin, instructor — own events + derived rows for own courses; live rows carry `phase`, deadline rows `due { learners, submitted }` |
| GET | `/calendar/:id` | same — live: `instructorTitle`, `phase`, `live { registered, capacity, attended }`, `audienceSize`; deadline: `due`, `learnersDue` (first 8 with hand-in status), `chapterTitle`; own events: `chapterTitle`, `instructorTitle`, `audienceSize`, `quiz` details |
| POST | `/calendar` · PATCH `/:id` · DELETE `/:id` · POST `/:id/done` | owner or admin; schema-validated (400), `validateCalendarEvent` (409); course must be in scope (404); editing re-arms the reminder |

## 6. Business Rules
`validateCalendarEvent`; derived rows are read-only; `due.learners` = enrolled (not paused) learners of the
course, `due.submitted` = distinct learners who handed in; `audienceSize` = the course's learners, or
every active learner for academy-wide events (none for private reminders). Relative assignment deadlines
are per learner (they count from when the chapter opened for that learner), so only fixed deadlines
appear on the staff calendar. Reminders: `notifyMin` minutes before an event the owner is notified, and
the course's learners too when `audience` is `learners` — sent once by the scheduler
(`lib/calendarEvents.ts`, `notifiedAt`), re-armed when the event is edited.

## 7. Permissions
Owner (User id from the token) or admin; instructors see only their courses' derived rows.

## 8. Backend Status
✅ CRUD + derived rows · ✅ User keying + owner-only mutations + staff-only access (F0) · ✅ instructor scoping (F2) · ✅ validation, real due/learnersDue/audienceSize/phase/titles, scheduled reminders (F11).

## 9. Frontend Integration
`services/http/calendar.ts`; wired.

## 10. Testing
`routes/calendar.test.ts` — deadline rows with learners/submitted, `learnersDue` detail, live phase/title/audience, validation 400, audience size, reminder sent once to owner + learners, out-of-scope course 404. Ownership in `foundation.test.ts`.

## 11. Completion
- [x] Routes
- [x] Ownership (F0)
- [x] Real details
- [x] Module tests
