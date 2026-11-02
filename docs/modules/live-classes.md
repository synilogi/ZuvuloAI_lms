# Module — Live classes

Status: **COMPLETED** (phase F10) · Depends on: Courses, Enrollments

## 1. Purpose
Scheduling live sessions (in-app or external link), registrations, reminders, cancellation, recordings;
learner registration and attendance.

## 2. Existing UI
`/:base/live` (list by phase), editor `/:base/live/new`, `/:base/live/:id/edit`, detail `/:base/live/:id`;
learner `/live`, `/live/:id`. Files: `pages/lms/live/*`, `pages/learner/live/*`.

## 3. UI Data Requirements
`LiveClass` (title, courseId/courseTitle, instructorId/instructorName/instructorTitle, startsAt,
durationMinutes, capacity, registered, phase, meeting { kind, url }, agenda[], recording?,
reminders { day, hour }, recordingViews); learner rows add `registered`.

## 4. Database
`LiveClass` (courseId FK, instructorId FK, title, description, startsAt, durationMin, capacity,
cancelled, cancelReason, recordingJson, agendaJson, visibility, meetingJson, remindersJson,
remindersSentJson, chapterId, **startedAt, endedAt, roomName** (unique); indexes courseId, instructorId) ·
`LiveRegistration` (liveClassId+studentId, registeredAt, attended?, **joinedAt**). The room columns arrive in
migration `20261015120000_live_room_sessions` — additive: existing classes keep null start/end/room.

## 5. API
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/live` · `/live/:id` | admin, instructor (own) |
| GET | `/live/learner` | student — classes of enrolled courses |
| POST | `/live` | staff of the course — schema-validated (400), `validateLiveClass` (409), host must exist; notifies enrolled learners |
| PATCH | `/live/:id` | staff — 409 once started or cancelled; a new start time re-arms reminders |
| POST | `/live/:id/cancel` | staff — reason ≥ 3 chars; 409 if already cancelled or ended; notifies registered learners |
| POST | `/live/:id/remind` | staff — sends a reminder to registered learners now; `{ sent }` = delivered |
| PATCH | `/live/:id/reminders` | staff — `{ reminders: minutesBefore[] }` |
| POST | `/live/:id/register` | learner enrolled in the course — toggles; 409 when full, cancelled or ended |
| POST | `/live/:id/start` | staff with `live.manage` — opens the built-in room (from 15 min before the start until the scheduled end), stamps `startedAt`/`roomName` once, tells learners it is live; returns the host's room join (moderator). Starting an open room again is rejoining |
| POST | `/live/:id/join` | learner (a place is taken if there is one; `joinedAt` = attendance) or staff (rejoin as host); 409 before the host starts or once ended; an outside meeting answers `{ kind: 'external', link }` |
| POST | `/live/:id/end` | staff — closes the room (`endedAt`); learners who held a place and never came are marked absent |
| GET | `/live/:id/recording` | the kept recording, streamed with ranges (app, with its token) |
| POST | `/live/:id/recording/link` | a two-hour link to the same file for a browser `<video>` |
| GET | `/live/recording-files/:grant` | the file behind such a link |
| POST | `/webhooks/jaas` | JaaS `RECORDING_UPLOADED`, signed with `JAAS_WEBHOOK_SECRET`; the file is downloaded and kept for `LIVE_RECORDING_DAYS` |

## 6. Business Rules
`validateLiveClass`, `deriveLiveClassPhase`, capacity, started/cancelled classes read-only, registration
only for enrolled learners before the class ends. Events (`lib/liveEvents.ts`): scheduled → every learner
enrolled in the course; cancelled → registered learners (important); reminders → registered learners,
either on demand or by the scheduler in `index.ts`, which every minute sends each reminder offset
(`reminders`, minutes before start) whose moment has come exactly once (`remindersSentJson`); reminders
within an hour are marked important and within 15 minutes say "Join the class". `LIVE_REMINDERS=off`
disables the scheduler.

### Built-in live room
A class whose `meeting.kind` is `room` runs on the academy's own video room (`lib/liveRoom.ts`), not an outside
link. The browser (`pages/live/JitsiRoom.tsx`, Jitsi's iframe API) and the app (`core/platform/live_room.dart`,
`jitsi_meet_flutter_sdk`) connect straight to the provider with what `start`/`join` return; nothing streams through
the API.
- **Phase follows the host**, not the clock: `starting-soon` while learners wait, `live` from `startedAt` until
  `endedAt` (or the scheduled end plus `ROOM_OVERRUN_MIN`), then over. `endedAt` is trusted as sent, whatever the
  viewer's clock says, so a device running behind never offers Join to a closed class.
- **Screens follow the room**: while a room waits for its host or is in session, the web and app read the schedule
  again every 15 s (`hostWaitPoll`), so Join appears when the host starts and goes when they end early.
- **Attendance**: joining stamps `joinedAt`; ending marks registered no-shows absent. The scheduler's
  `closeStaleRooms` closes a room left open past its slot and overrun, as if the host had ended it then.
- **Providers**: with no keys, the public `JITSI_DOMAIN` (meet.jit.si) — *trial only*: nobody is moderator unless
  they sign in to Jitsi, so learners wait in its lobby, embedded calls are time-limited and nothing is recorded.
  **Production needs JaaS** (8x8 Jitsi as a Service): `JAAS_APP_ID`, `JAAS_KID`, `JAAS_PRIVATE_KEY(_FILE)` — every
  join is a token this server signs, the host moderates, learners don't; add `JAAS_WEBHOOK_SECRET` to keep
  recordings.
- A class that is over and was never recorded reads **"Ended"**; "Recording expired" only when a kept recording
  has passed its date.

## 7. Permissions
Staff of the course; learners enrolled in the course.

## 8. Backend Status
✅ CRUD/cancel/remind/register · ✅ scope + enrolled-only registration (F2) · ✅ validation, started/cancelled locks, scheduled/cancelled/reminder notifications, reminder scheduler (F10) · ✅ built-in room: start/join/end, attendance, stale-room closing, JaaS tokens, recordings kept from the JaaS webhook. `recordingViews` is read from the recording data (no viewing event exists in the product).

## 9. Frontend Integration
`services/http/live.ts`; wired.

## 10. Testing
`routes/liveRoom.test.ts` — start window, first start stamps once, learner join takes a place and marks present,
staff rejoin as host, end marks no-shows absent, JaaS token signing, recording webhook signature and keeping.
App: `test/features/live/*` (waits for the host, early end without a refresh, "Ended" without a recording).
Verified on a device on 2026-10-16: host start → learner Join opens the Jitsi SDK → attendance → host end clears
Join within one poll; web host start embeds the room and End class settles attendance.
`routes/live.test.ts` — validation 400, scheduling notifies enrolled learners, capacity (registered → full 409), manual reminder count, cancel notifies + freezes (edit/cancel/register 409), edit after start 409, scheduled reminders sent once at the right moment. Enrolment requirement in `permissions.test.ts`.

## 11. Completion
- [x] Routes
- [x] Rules + notifications
- [x] Tests
