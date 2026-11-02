# Module — Notifications

Status: **COMPLETED** (phase F12) · Depends on: Foundation; consumers: every module that emits events

## 1. Purpose
In-app notification centre for all roles, per-user preferences (channels, quiet hours, pause), an event
engine that creates notifications from product events, and an email outbox.

## 2. Existing UI
`/notifications` (centre with filters, archive), `/notifications/:id` (detail), `/notifications/preferences`
(learner, instructor, admin variants), header bell with unread count. Files: `pages/lms/notifications/*`.

## 3. UI Data Requirements
`Notification { id, category, title, body, at, read, archived, important, link?, channels[] }`;
`NotificationSettings` (per category `{ app, email, sms }`, quietHours, pausedUntil, digest).

## 4. Database
`AppNotification` (recipientId → User, category, title, summary, bodyJson, createdAt, readAt, important,
actor, factsJson, actionJson, secondaryActionJson; index (recipientId, createdAt)) ·
`NotificationSettings` (userId → User, categoriesJson, emailDigest, quietHoursJson, pausedUntil,
smsNumber, lastDigestAt) · `EmailOutbox` (toEmail, toName, subject, text, templateKey, status, error,
createdAt, sentAt) · tracking columns `Submission.overdueNotifiedAt`, `Student.nudgedAt`,
`LiveClass.remindersSentJson`, `CalendarEvent.notifiedAt`.

## 5. API
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/notifications` · `/notifications/:id` | any role — caller's own only; the detail's `channels` reflect the caller's preferences for that category |
| POST | `/read` · `/read-all` · `/remove` · `/restore` · `/clear` | own only (ids filtered by recipient) |
| GET/PUT | `/notifications/settings/me` | caller — `validateNotificationSettings` |

## 6. Business Rules
`lib/notify.ts` — `notify({ recipientUserId, category, title, summary, body?, important?, actor?, facts?,
action?, channels?, switch? })`: the academy switch named by `switch` (`settings.notifications.learner.*`
/ `staff.*`) can turn a kind of message off for everyone; the recipient's per-category `app`/`email`
preferences apply; `pausedUntil` blocks everything except `important`; `system` is always delivered in
the app and by email; with `emailDigest` daily/weekly the email waits for the digest job instead of
going out at once. No SMS transport exists — the `sms` preference and number are stored for the UI only.
Quiet hours are stored for the UI; nothing server-side pushes or texts outside them.

Scheduled jobs (`lib/notificationJobs.ts`, every minute from `index.ts`; each is idempotent): daily /
weekly digest emails after 08:00 IST (Mondays for weekly) listing the notifications since the last digest;
review-overdue notices to instructors once per submission waiting > 48 h (`staff.reviewOverdue`); a
daily enrolment summary to admins and each course's instructors (`staff.dailyEnrolments`); inactivity
nudges to learners quiet for `atRiskDays` with an active course, at most weekly (`learner.inactivityNudge`);
assignment due reminders `learner.assignmentReminderDays` before a fixed deadline, once per learner.
`learner.liveReminderMinutes` are the default reminders of a new live class.

Event catalogue: enrolment confirmation (self and staff; `learner.enrolmentConfirmation`), live class
scheduled / cancelled / reminders, submission received → instructors (`staff.newSubmission`), review
graded / returned → learner, assignment reminders (manual and scheduled) → owing learners, certificate
claimable / issued (`learner.certificateIssued`) / revoked, course ready for review → admins and course
published → its instructors (`staff.courseReview`), staff messages, calendar reminders, review overdue
(`staff.reviewOverdue`), daily enrolments (`staff.dailyEnrolments`), inactivity nudges
(`learner.inactivityNudge`), inactive courses archived → admins. Instructor invitations and password
resets are emails only (outbox) — they precede a sign-in. `LOCKED_CHANNELS` for `system`.

## 7. Permissions
Everyone reads/writes only their own rows; settings route takes no recipient id from the client.

## 8. Backend Status
✅ centre routes · ✅ User keying + ownership filtering + body validation (F0) · ✅ engine with academy switches, preferences, digests, scheduled jobs, real `channels` (F12).

## 9. Frontend Integration
`services/http/notifications.ts` — settings methods switch to `/settings/me` (F0); bell uses `user.id`.

## 10. Testing
`routes/notifications.test.ts` — enrolment confirmation obeys the academy switch, detail channels follow
preferences, daily digest holds emails and sends one digest, overdue reviews once, course review request
to admins, inactivity nudges once a week, due reminders once, daily enrolment summary once.
`foundation.test.ts` — ownership; `students.test.ts` — channel preferences and outbox.

## 11. Completion
- [x] Centre routes
- [x] Ownership (F0, `foundation.test.ts`)
- [x] Engine + outbox
- [x] Module tests
