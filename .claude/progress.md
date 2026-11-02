# SyniastroLMS UI Progress

> **Backend completion work is tracked in `docs/00-PROJECT-STATUS.md`** (roadmap F0–F19, module status,
> test status). This file remains the historical record of the UI build and the redesign.

PROJECT STATUS: COMPLETED (functional scope + real backend); VISUAL REDESIGN IN PROGRESS

## Overall Status
COMPLETED — all 20 modules (LMS-000 to LMS-019) are built, verified and committed, and both final audits below are done. LMS-017 (Marketing & Auth Pages), LMS-018 (Knowledge Base) and LMS-019 (Subscription & Plan Management) were added after the first final audit; the second final audit, run once LMS-019 landed, covers the whole application again.

The client has since asked for a genuine visual re-skin of the finished product (new palette, type and shape language — not a repaint), while keeping every route, module and interaction exactly as built. See **UI Redesign** below for the design direction and phase log; this is layered on top of the completed functional scope above, which is unchanged.

A real backend was then requested and built — see **Backend** below. It is additive: the mock-mode product described in every module above is untouched and still the default (`VITE_API_MODE=mock`); the backend is a second, real implementation of the same `Services` contract, selected with `VITE_API_MODE=http`.

## Current Module
None — every module in the pack, including the three post-audit additions, is completed. The redesign and the backend below are tracked separately.

## Backend
Started 17 Sep 2026, requested after the UI (and the redesign in progress) were already in place, using the seams the UI was always built with — `packages/domain` ("anything the API will also need") and `services/contracts.ts` (the interface the mock always stood in for).

**What it is:** `apps/api` — Express + TypeScript, Prisma ORM against SQLite (zero external services to run), bcrypt password hashing, JWT auth. Reuses `packages/domain`'s validators and business rules directly (`publishChecklist`, `validateAssignment`/`validateReview`/`reviewScore`, `validateQuiz`/`scoreAttempt`, `deriveStudentStatus`, `deriveLiveClassPhase`/`validateLiveClass`, `validateCalendarEvent`, `validateNotificationSettings`, `validateSettings`, `validateTemplate`, `validateInstructor`, `lessonPublishIssues`) rather than re-implementing any rule — exactly as `docs/01-PROJECT-ARCHITECTURE.md` always said the API would.

**Schema:** one Prisma model per real entity (User, Instructor, Level, Category, Course, Chapter, Lesson, Student, Enrollment, LessonProgress/Note/Bookmark, Rank, Quiz/QuizAttempt, CourseAssignment/Submission, CertificateTemplate/IssuedCertificate, LiveClass/LiveRegistration, CalendarEvent, AppNotification/NotificationSettings, Settings, HelpCategory/HelpArticle). Structural, queryable fields are real columns; nested/type-varying shapes the domain package already types (lesson content per type, quiz questions, rubrics, settings sections, …) are JSON text columns, parsed at the boundary — the same pattern the mock used in memory, now persisted.

**Every one of the 22 service groups in `contracts.ts` has a real route file and a real HTTP client:** catalog, dashboard, courses, categories, chapters, lessons, quizzes, assignments (incl. submissions/review), students, instructors, learning (the full learner experience — home, course, lesson player, completion, notes, bookmarks, assignments, assessments, certificates), certificates (incl. templates and public verification), live classes, calendar (incl. derived live/assignment events), notifications, settings, help, reports (real SQL/Prisma aggregation, not canned numbers), plus the three smaller legacy interfaces (`learner`, `enrollment`, `admin`) used only by hidden `/design-system` specimen pages.

**Frontend wiring:** `apps/web/src/services/http/*` implements the full `Services` interface against the API; `services/index.ts` picks it over the mock when `VITE_API_MODE=http`. `SessionProvider` now runs a real, token-backed session in that mode (`login`/`register`/`logout`, `/auth/me` restores on reload) instead of the mock's persona switcher, extracted behind `lib/apiMode.ts` so pulling `API_MODE` into a module doesn't drag browser-only code into places that don't want it (this broke `commands/registry.test.ts` once — fixed by moving the constant out of `SessionProvider.tsx`). `LoginPage`/`RegisterPage` call the real endpoints and show real errors (wrong password, duplicate email) in `http` mode, and fall back to the existing demo `switchRole` flow unchanged in `mock` mode. The "View as (demo)" account-menu section and its command-palette entries are now mock-mode-only, since a real account's role isn't something to switch.

**Seed data:** `apps/api/prisma/seed.ts` builds a small, coherent academy — 3 levels, 3 categories, 3 instructors, 6 courses with real hand-written curriculum (chapters, lessons of every type, an assessment quiz per chapter, an assignment), a 3-rank ladder, 3 certificate templates, 8 students with enrollments/progress/a graded submission/a quiz attempt/issued certificates, 2 live classes, 2 help articles, academy settings — and prints three ready accounts (admin, instructor, student), password `syniastrolms123` for all.

**Known, documented simplifications** (real code, deliberately smaller scope than the mock's richest edge cases — not stubs): `LearnerService.listCertificates()` returns `[]` (the eligibility-criteria "working towards" view isn't modelled, only issued/pending certificates are); report `series` are populated on the Overview tab only, `[]` on the others; learner `StudentActivity` doesn't yet synthesise `chapter-completed` or `rank-achieved` events; messaging, uploads, live video/meetings, and email/SMS delivery are acknowledged but not actually sent — the same simulated-and-said-so posture the mock always had, per Known Issues below.

**Verification**
- typecheck, lint, format — clean across all three workspaces (`api`, `web`, `domain`)
- `apps/api`: 7 integration tests (`src/app.test.ts`, supertest against the real Express app + a dedicated `test.db`) covering register/login/duplicate-email/wrong-password/unauthenticated-401/role-guard-403, plus the existing 81 web + 31 domain tests unaffected — 119 tests total, all passing
- Manual API verification via curl: auth (register/login/me/wrong-password), catalog, admin dashboard KPIs, course publish, assignment review queue, reports overview, help centre — all against the real seeded database
- Browser (Chromium headless) against the real API (`VITE_API_MODE=http`): admin login → dashboard with real KPIs/chart/attention items; 16 admin pages (courses, categories, students, instructors, certificates incl. templates, all 5 report tabs, live, calendar, notifications, settings, help) with zero console errors; learner login → home → my-learning/explore/assignments/assessments/certificates/live/calendar/notifications, then a real course → a real quiz lesson showing the seeded "passed 83%" attempt and correct curriculum-sidebar completion state; new-account registration end to end — zero console errors throughout
- Found and fixed one real bug this way: the reports Overview endpoint's `series` used a `{date, value}` shape instead of the `ReportPoint {from, to, value}` the frontend's chart code expects, crashing that page — fixed and re-verified
- `mock` mode re-verified unchanged after the `SessionProvider`/`Header`/command-registry edits: full typecheck/lint/`npm test` pass, including `commands/registry.test.ts`, which the `API_MODE` refactor above was needed to keep passing

**Limitations:** SQLite (not Postgres/MySQL) — fine for this deployment size, a real production rollout would want to swap the Prisma `datasource` provider; no refresh-token rotation (a JWT is valid for its full 7-day expiry); no rate limiting; the "instructor" role's data scoping (`scopeInstructorId`) is enforced by the routes that accept it but not yet by a blanket "instructors can only see their own courses" guard at the middleware level.

## UI Redesign — "Celestial Ink"
Started 17 Sep 2026, requested after the project above was already complete.

**Direction:** the shipped product used a cool mint-green SaaS palette (oklch green accent), an all-grotesque-sans type pairing (Bricolage Grotesque + Public Sans) and a soft, heavily-rounded, floaty-shadow shape language — competent but generic, and not specific to an astrology school. The new direction, "Celestial Ink", replaces it everywhere the token layer reaches:
- **Colour:** warm parchment/ivory neutrals (was cool grey-green) with a deep indigo/violet working accent (was emerald green); antique gold (the existing `--warn` tone) is reserved for what's earned — ratings, at-risk/soon badges, certain certificate templates — rather than introduced as a new hue. `--info` moved to a clearly distinct blue so it never reads as the brand colour; `--danger` warmed slightly to sit in the same family. Dark mode is a true midnight indigo, not a dark grey.
- **Type:** display/numerals moved from a grotesque sans (Bricolage Grotesque) to an editorial serif (Fraunces Variable) for real typographic contrast against the sans body; body/UI moved from Public Sans to Plus Jakarta Sans. Both self-hosted via `@fontsource`, same as before.
- **Shape:** the radius scale was tightened a step at every size (e.g. `--r-lg` 16px → 14px, `--r-xl` 22px → 18px) for a less "bubbly" feel, and shadows were re-tinted with the ink colour and made a little more diffused/less pastel.
- **Shell:** the brand mark became a circle with a soft halo ring (echoing the rank-ring/certificate-seal motif the product already uses elsewhere), and the active-nav indicator changed from a filled pill to a left accent rule over a lighter tint — a structural change to the shell, not just a recolour.

**What this touched:** `apps/web/src/styles/tokens.css` (the single source of truth for colour, radius, shadow, type — Part A), `apps/web/src/main.tsx` (font imports), `apps/web/package.json` (swapped `@fontsource/bricolage-grotesque` + `@fontsource/public-sans` for `@fontsource-variable/fraunces` + `@fontsource/plus-jakarta-sans`), `apps/web/public/favicon.svg`, `apps/web/index.html` (`theme-color`), `apps/web/src/shell/AppShell.module.css` (brand mark, active nav item). Because every component in the product reads these tokens rather than hardcoding colour/radius/shadow/font (confirmed by grepping for stray hex values and old hue `162` — none found outside two intentional spots), the change cascades to essentially every screen without per-page edits.

**Content fixes made for consistency:** the Appearance settings' seeded "current" brand accent was `emerald` (the old colour) — changed to `indigo` so Settings no longer claims a colour the live app doesn't show; the settings page's "Indigo" swatch preview value was retuned to match the real `--accent` exactly; the design system's Typography section text named the old font pairing — corrected to name Fraunces / Plus Jakarta Sans.

**Verification**
- typecheck, lint, 112 tests (31 domain, 81 web), build, `format:check` — pass
- Browser (Chromium headless, dev server): `/welcome`, `/login` (incl. validation-error state), `/admin` dashboard, `/admin/courses`, `/admin/courses/new`, a course's `/curriculum`, `/admin/certificates` templates (all three template colours), `/home` (learner), a lesson player, `/explore` — reviewed at 1440px, `/admin` also in dark mode and at 390px mobile. No console errors on any of them; no leftover old-palette or old-font references found by search.

**Not yet done (next phases, same initiative):** this pass is the design-system + shell layer only. Individual pages still use their original layout/composition (card arrangement, section order, information density) — they now render in the new palette/type/shape but haven't each had a bespoke layout pass. A thorough per-module visual QA (every module in Completed Modules above, at desktop/tablet/mobile, light and dark) and any page-level composition changes the new direction calls for are the natural next phase.

## Completed Modules

### LMS-016 — LMS Settings
Completed 15 Sep 2026.

**Screens / routes**
- `/admin/settings` → `/admin/settings/general` — LMS General
- `/admin/settings/courses` — Course settings
- `/admin/settings/learning` — Learning settings
- `/admin/settings/certificates` — Certificate settings, with a certificate preview
- `/admin/settings/notifications` — Academy notification settings
- `/admin/settings/appearance` — Appearance and branding, with a learner-home preview

**Navigation:** the sidebar’s Settings item opens into its sections, as the shell’s Settings does; the page lists the sections with a line on what each holds, and below 1024px that list becomes a section picker. The account menu’s Academy settings opens General (admins only).

**Every section:** a form with its own draft; a save bar that reads “Last changed 44 days ago by Kavita Menon”, “Unsaved changes” or “Saved”, with Discard and Save changes (Ctrl/⌘ + S also saves); validation on save with an error summary linking to each field and messages under the fields; server-side checks repeated on save; a leave guard when switching sections or pages with changes; a success toast; the save bar sits at the bottom of the screen on phones.

- **General:** academy name, display label, support email, learner language; default course visibility (public, unlisted, private), how learners enrol (open, on approval, invite only), access length; new-lesson defaults — length, when a lesson counts as finished, discussion, downloads, free first-lesson preview.
- **Courses:** default format, how chapters open (all at once, in order, on dates), default price, instructors per course, review before publishing, archiving untouched courses, ratings (and after how many) and enrolment counts in the catalog.
- **Learning:** when a video or reading counts as finished, when a course is finished (every lesson, lessons and assessments, a share of lessons), passing each chapter’s quiz to open the next, quiz attempts and retake wait, late assignments (accept, penalty, don’t accept) and the penalty, quiet days before a learner is at risk, and what learners can choose for themselves.
- **Certificates:** award certificates on or off (the preview greys out and explains), issue automatically or after an admin checks, minimum final score, validity, default template, which details print, credential prefix (capital letters only), public verification — the preview is the real certificate document and follows every change.
- **Notifications:** sender name and reply-to, text messages; to learners — enrolment confirmation, live class reminders, deadline reminders, weekly summary, inactivity nudge, certificate issued; to staff — new submissions, reviews past 48 hours, daily enrolments, courses waiting for review; a note that people still choose for themselves, linking to notification preferences.
- **Appearance:** brand name, accent colour (emerald, saffron, indigo, plum) as labelled swatches, welcome message with a character count, learner theme (match the device, light, dark), spacing, course cover art — the learner-home preview shows the brand mark, greeting, welcome, a course card with progress and the resume button in the chosen colour, theme and spacing.

**States:** loading skeleton, settings failing to load with Try again, unsaved changes, validation, saving, saved, save refused with the reason.

**Foundation added:** domain `LmsSettings` and its sections, `validateSettings`, `SettingsRecord`; `services.settings` (get, save a section); nested Settings navigation.

**Verification**
- typecheck, lint, 112 tests (31 domain, 81 web incl. settings service), build — pass
- Browser: general, appearance and certificates at 1440; learning, appearance and certificates at 390 — no console errors, no horizontal overflow
- Flows: /admin/settings opens General with Save disabled; a one-letter label and “help@” → Unsaved changes → error summary with both; switching to Learning asks first → Keep editing; fixed → Ctrl+S → “General settings saved”, Saved, Save disabled; Learning with 40% of lessons and an empty penalty refused → Discard; General keeps “My learning”; credential prefix typed “as1d” becomes “ASD”; turning certificates off greys the preview; saffron, dark and a new brand name show in the preview → saved; account menu → Academy settings; error scenario; the mobile section picker opens Appearance; the phone save bar enables on a change
- Fixed during review: the certificate switch sat tight against the next heading; the preview course cover kept the admin’s accent instead of the chosen one

**Limitations:** settings are stored in the demo’s memory until reload and don’t yet change how other screens behave — branding and rules are previewed, not applied across the app.

### LMS-015 — LMS Reports
Completed 15 Sep 2026.

**Screens / routes**
- `/admin/reports` — Reports overview
- `/admin/reports/courses` — Course performance
- `/admin/reports/courses/:courseId` — One course’s report
- `/admin/reports/learners` — Learner progress
- `/admin/reports/instructors` — Instructor performance
- `/admin/reports/enrolments` — Enrolment and completion

**Controls:** tabs between reports that keep the filters; period (last 30 days, 90 days, 6 months, 12 months), category, course (narrowed by category and instructor), instructor, and learner group on the learner and enrolment reports (all, new, active, at risk, inactive, finished a course); Reset filters. Filters live in the URL, so a report can be bookmarked or shared as it looks. Every report states its dates and compares with the same length of time before.

**Overview:** a hairline KPI band — enrolments (with completions), completion rate, active learners, average progress — each with a sparkline and change; an over-time trend with a measure switch (enrolments, completions, active learners) per day, week or four weeks, with the total and the peak; learning activity — quiz attempts, pass rate, average score; assignments handed in, passed, on time, median review time against the 48-hour promise; lessons completed, lessons per active learner, live class attendance; where learners are (progress distribution); enrolments and completion by category; the five courses with the most enrolments.

**Course performance:** completion rate and average progress by course as ranked bars; a sortable table — course with category and instructors, enrolments with the change, completion, average progress, quiz and assignment pass rates, rating, trend — with CSV export. **One course:** its KPIs, a funnel from enrolling to started, halfway and finished, chapters reached, enrolments over time, and quiz and assignment tables linking to results and submissions.

**Learner progress:** learners studying, active now, at risk and average progress; progress distribution; the groups with counts, which narrow the report when chosen; a learner table with status, courses and finished, average progress, assignment average and last active — searchable, sortable, paged, exportable, linking to each learner.

**Instructor performance:** reviews returned, median review time, share within 48 hours and live attendance; completion rate by instructor; review load; an instructor table with learners, completion, rating, reviews, review time, live classes and attendance, exportable, linking to each profile.

**Enrolment and completion:** enrolments, completions, completion rate and the share who enrolled themselves; enrolment and completion charts; how learners enrolled (self, cohort place, admin, scholarship) with completion by route; categories with change; how quickly each monthly intake finishes — within 30, 60 and 90 days and to date — shaded in one hue, with CSV export.

**States:** loading skeletons and a dimmed report while filters change, error with retry, no report data, nothing matching the filters with Reset filters, no learners matching a search, courses without quizzes or assignments.

**Responsive:** KPI bands fold to two columns; course, learner and instructor tables become lists with expandable detail; plain tables and the intake table scroll inside their panels; charts keep their read-outs; filters sit two to a row.

**Foundation added:** domain `ReportRange`, `LearnerSegment`, `reportWindow`, `reportBuckets`, `percentOf`, `median`; `services.reports` (overview, courses, course, learners, instructors, enrolments) aggregating the enrolment, submission, quiz and live-class records — each enrolment treated as a study span so any period can be measured and compared; `BarList` chart for ranked single-hue bars with values written beside them; CSV export built in the browser.

**Verification**
- typecheck, lint, 109 tests (30 domain, 79 web incl. reports service), build — pass
- Browser: overview, courses, one course, learners, instructors and enrolments at 1440; overview, courses, learners, enrolments and one course at 390 — no console errors, no horizontal overflow
- Flows: 90 days 2,710 enrolments → 30 days 930 with range in the URL; measure switch to completions per day; instructor filter carried to the Courses tab (4 courses) → CSV downloaded; Remedies category with that instructor → “Nothing matches these filters” → Reset filters → 13 courses; course drill-down with one page heading and its own period → back keeps the period; learner group “At risk” sets the filter and only at-risk learners show; search with no match → Show all learners; page 2; six monthly intakes; seven instructors; empty and error scenarios
- Fixed during review: the course table squeezed course names — merged pass rates and dropped the active column; the top-courses table fell into its mobile layout beside another panel; learning activity figures left half the width empty; the course drill-down showed two page headings; the learner table opened on finished, inactive learners; two buttons were both called “Clear search”; the at-risk comparison was always zero

**Limitations:** figures are computed from the in-memory demo records — quiz attempts per period are estimated from each course’s activity, and progress at past dates assumes steady study between enrolling and the last visit.

### LMS-014 — LMS Notifications
Completed 15 Sep 2026.

**Screens / routes**
- `/notifications`, `/teach/notifications`, `/admin/notifications` — Notification centre
- `…/notifications/:notificationId` — Notification detail
- `…/notifications/preferences` — Notification preferences
- Header bell (desktop popover, mobile link) in every workspace

**Centre:** All / Unread with the unread count, a type filter with counts (course updates, assignments, quizzes, live classes, certificates, enrolments, account and system), notifications grouped by Today, Yesterday, Earlier this week and Earlier. Each shows its category icon and label, title, a two-line summary and the time (“22 min ago”, “Yesterday, 9:00 AM”, full date on hover); unread ones are tinted with a bar and dot and read in bold, important ones carry a badge. Row actions: mark as read / unread, and a menu to remove (with Undo in the toast) or open that type’s settings. Mark all as read (for the chosen type), Clear all with a confirmation that says how many and how many are unread, Show older.

**Detail:** back to notifications, category, title, date and time with the relative time and who it’s from; the summary, body and facts (scores, due dates, places, credential IDs); actions to the real page — join the class, read the feedback, claim the certificate, open the review queue, review certificates. Opening a notification reads it; mark as unread and remove are at hand. “Why you got this” lists the channels for that type with a link straight to its row in preferences; up to three more of the same type.

**Preferences:** pause for an hour, until 8 AM tomorrow or for a week (important notifications still come through) with Resume now; groups per role — learners: Learning, Progress, Account; instructors: Teaching, Your courses, Account; admins: Academy, Teaching, System — each type with a description in that person’s terms and switches for in the app, email and text message (account and security notices locked on, with the reason); email as they happen, daily or weekly; quiet hours for text messages with the number they go to. Unsaved changes marker, Discard, Save, validation (quiet hours with the same start and end), leave guard, sticky actions on mobile; a link from a notification scrolls to and highlights its type.

**Bell:** the unread dot and count in the button’s label, the newest five with unread emphasis, Mark all read, See all notifications and Preferences; it updates as soon as anything is read or removed anywhere. The account menu gains Notification preferences, and My certificates now opens the learner’s certificates.

**States:** loading skeleton rows, error with retry, no notifications (with a link to preferences), all caught up, nothing of a type, notification not found; preferences loading and error.

**Responsive:** a single-column list on phones with actions in the row menu; preferences stack each type with labelled switches; the detail reads at 720px.

**Foundation added:** domain `AppNotification`, `NotificationSettings`, categories and channels, locked channels and `validateNotificationSettings`; notifications for the learner, instructor and admin personas that point at real records (the learner’s assignments, live classes and certificates; the instructor’s review queue counted from submissions; certificates ready to issue and review backlogs counted from the records; quiz pass rates from quiz statistics); `services.notifications` (list, get, read / unread, mark all, remove, restore, clear, settings); a notifications-changed signal shared by the bell and pages. Navigation no longer lets a workspace’s overview claim pages outside the navigation, so breadcrumbs and the sidebar don’t point at Dashboard from notifications.

**Verification**
- typecheck, lint, 102 tests (27 domain, 75 web incl. notification service), build — pass
- Browser: centre, detail and preferences at 1440 and 390, bell popover, admin and instructor centres — no console errors, no horizontal overflow
- Flows: bell shows 6 unread → opening a notification from the bell reads it (5); Unread shows 6, unread live classes 2, all live classes 3; mark one read updates the bell; remove → Undo puts it back; Mark all as read → “5 notifications marked as read”, button disabled, Unread shows “You’re all caught up”; clear account and system notifications → confirmation with the count → empty type state; detail Mark as unread; “Change assignments settings” lands on and highlights the Assignments row; switch changed → Unsaved changes; account email locked; pause until 8 AM shows the resume message; quiet hours 07:00–07:00 refused → fixed → saved; leaving with changes asks first; empty, error and not-found scenarios; the mobile bell opens the centre
- Fixed during review: the student centre showed “SyniastroLMS” as a breadcrumb and the admin centre was filed under Dashboard; the clear confirmation read “Clear all account and system?”

**Limitations:** nothing is delivered by email or text message, and pauses and quiet hours only change what the preferences say; notifications and their read state last until the page is reloaded.

### LMS-013 — LMS Calendar
Completed 15 Sep 2026.

**Screens / routes**
- `/admin/calendar`, `/teach/calendar` — Calendar (month, week, list)
- `/admin/calendar/:eventId` (and `/teach/…`) — Event detail, opened over the calendar
- `/admin/calendar/new`, `/admin/calendar/:eventId/edit` (and `/teach/…`) — Add / edit event

**Calendar:** Today, previous and next, and the period (“September 2026”, “14 – 20 Sep 2026”); Month / Week / List; filter chips for live classes, assignments, quizzes, milestones and reminders — each with its count, icon and colour, pressed or not — plus course and instructor filters. The instructor workspace sees their courses and their own reminders. Filters, view and date live in the URL.
- **Month:** Monday-first grid with today marked, up to three events per day (or two and “n more”), timed events with their time when the cell is wide enough, all-day milestones as filled bars, cancelled and done events struck through; a panel for the selected day with every event and “Add an event on this day”. Arrow keys move between days, Home / End to the week’s edges, Page Up / Down by month.
- **Week:** days across a 6 AM–midnight time grid that opens at the week’s first event, an all-day row, overlapping events side by side, deadlines as short markers, a line at the current time.
- **List:** days with events as cards, today always shown, earlier days this month folded behind one button.

**Events:** live classes come from the live schedule (with their phase); assignment deadlines for cohort courses (chapter opening plus the allowed days) and fixed dates, with how many learners are due and have handed in; quiz windows (a closing deadline) and sittings (a set time); course milestones — cohort starts, chapter opens, enrolment closes, cohort wraps up, course launch; reminders, private or sent to a course’s learners.

**Event detail:** a drawer on desktop and a bottom sheet on phones, with its own URL. Status (live now, starting soon, cancelled, done, due or closing soon), when with the relative time, length, course and chapter, instructor, who’s included, notification, notes; places taken or attendance for live classes; a hand-in meter and the learners still due for deadlines; questions, time limit, attempts and pass mark for quizzes, with a warning when the quiz is a draft. Actions follow the type: open or edit the class, open submissions or the assignment, open the quiz or course, mark a reminder done, edit, delete with confirmation. Derived events explain where they’re changed.

**Add / edit event:** reminder, course milestone or quiz window; title and notes; just me or learners of a course; course, milestone kind, chapter and quiz (choosing the quiz fills the title and chapter); by a deadline or sit it together; date, time or start and end, all day for reminders; notification. Validation for a missing course, quiz, milestone kind or chapter, times that have passed and lengths outside 5 minutes–12 hours; error summary, leave guard, sticky actions on mobile. Past events and events from other pages can’t be edited here and say why.

**States:** loading skeleton and a dimmed view while the period changes, error with retry, nothing scheduled, every type hidden or filters matching nothing (with Show everything), a selected day with no events.

**Responsive:** phones open on the list; the month shows coloured dots per day with the day’s agenda below; the week is offered from tablet up and scrolls inside its frame; the day panel moves under the grid below 1000px of calendar width.

**Foundation added:** domain `CalendarEvent`, `CalendarEventInput`, `validateCalendarEvent`, `calendarEventEnd`, `istDate`; cohort plans for cohort courses (fortnightly chapter openings, next intake and enrolment close) shared by milestones, quiz windows and deadlines; seeded reminders for the admin and instructor personas; `services.calendar` (list with counts, get, create, update, remove, set done); IST calendar arithmetic and overlap layout helpers with tests.

**Verification**
- typecheck, lint, 98 tests (26 domain, 72 web incl. calendar service and date helpers), build — pass
- Browser: month 1440 / 820 / 390, week 1440 / 1024 / 820 and dark theme, list 1440 / 390, event panel 1440 and bottom sheet 390, editor 1440 / 1024 / 390, teaching workspace — no console errors, no horizontal overflow
- Flows: arrow keys and Page Down move the selected day and month; hiding each type → “Every event type is hidden.” → Show everything; chip → panel URL → Escape closes; add reminder refuses no title, learners without a course and a past time → added → panel on its date → marked done → edited → deleted; chapter milestone without a chapter refused; choosing a quiz fills its title; a sitting that ends before it starts refused; editing a live class from the calendar refused with a link; the instructor sees only their reminders; empty and error scenarios
- Fixed during review: the course and instructor filters stacked; short week blocks clipped their text; the week opened with the first hour label cut; screen-reader labels escaped the week frame and widened the page at tablet width; the event panel repeated its type; the learners list led with people who had already handed in

**Limitations:** notifications and reminders to learners aren’t delivered; events added in the calendar last until the page is reloaded.

### LMS-012 — Live Class UI
Completed 15 Sep 2026.

**Screens / routes**
- `/admin/live`, `/teach/live` — Live class schedule (upcoming, live now, history, cancelled)
- `/admin/live/new`, `/admin/live/:liveId/edit` (and `/teach/…`) — Schedule and edit a class
- `/admin/live/:liveId`, `/teach/live/:liveId` — Class detail
- `/live`, `/live/:liveId` — The learner's live classes and class page

**Schedule:** upcoming classes on a timeline grouped by day — date, time range and length, title, instructor and course, places taken with a meter, status (scheduled, starting soon, live, ended, recording expired, cancelled) and the one action that fits (get ready, rejoin as host, open); a history table with attendance and recording; cancelled classes with their reason; view tabs with counts, search, course and instructor filters, pagination; the instructor workspace sees only their courses; cards on mobile; empty, no-match, loading and error states.

**Schedule / edit:** title, description, course and chapter, instructor, date with start and end times (length derived), the academy room or an outside meeting link, capacity, who can join (enrolled learners, an invited cohort, any signed-in learner), agenda items with minutes, and reminders; validation for past start times, lengths outside 15 minutes–4 hours, capacity below registrations, links without https and agendas longer than the class; error summary, sticky actions on mobile, leave guard; classes that have started can't be edited.

**Class detail:** when, length, room, who can join, places and attendance; description and agenda with clock times; registered learners (with attended / missed after the class); instructor; reminder schedule switches and send-a-reminder-now (disabled until someone registers); recording with views and a viewer; previous and next session in the course; cancel with a required reason; host room check with camera and microphone toggles.

**Learner:** a live-now hero with Join now, coming-up classes with register / cancel registration and places left, recordings to watch; the class page shows the date, time, what the phase means (starts in, learners in the room, recording available until) and the one action — join, register or watch.

**Foundation added:** domain `LiveClass` gains description, agenda, visibility, meeting, reminders, attendance and cancel reason, plus `LiveClassInput` and `validateLiveClass`; seven past sessions per live course join the academy schedule so history, attendance and recordings agree everywhere; `services.live` (list, get, create, update, cancel, reminders, learner view, register); the shared page header puts the back link on its own line.

**Verification**
- typecheck, lint, 85 tests (22 domain, 63 web incl. live service), build — pass
- Browser: schedule 1440 / 390, detail 1440 / 390, editor 1440, learner 1440 / 390, learner class upcoming / live / ended 390 and 1280 — no console errors, no horizontal overflow
- Flows: schedule refuses a past date and short class (4 issues) → outside link without https refused → scheduled → detail; reminder switch saved; cancel refuses a missing reason → cancelled; host room check → in the room; history → attendance → recording viewer; instructor edit of an ended class refused; learner registers → toast → cancels registration
- Fixed during review: IST printed twice on the detail page; the learner class page repeated the title and offered a Remind me button that did nothing; send-a-reminder worked with nobody registered; agenda and duration errors fired together for a too-short class; recordings were described as lasting 45 days while the course classes kept them for a month

**Limitations:** no video, audio or meeting connection — joining, hosting, reminders and recordings are simulated.

### LMS-011 — Certificate UI
Completed 15 Sep 2026.

**Screens / routes**
- `/admin/certificates` — Certificate list (Issued)
- `/admin/certificates/:certificateId` — Certificate detail and preview
- `/admin/certificates/templates` — Template and style previews
- `/admin/certificates/templates/:templateId`, `/admin/certificates/templates/new` — Template editor
- `/certificates`, `/certificates/:certificateId` — The learner's certificates
- `/verify`, `/verify/:credentialId` — Certificate verification

**Certificate list:** certificate and course, learner with email, issue date (or when they completed), credential ID, status (issued, ready to issue, revoked) and verification (verifiable with how many checks, shown as revoked, not public yet), Review / Open; status tabs with counts, search by learner, email or credential ID, course filter, pagination; a notice when certificates are ready to issue; cards on mobile; empty, no-match, loading and error states.

**Certificate detail:** the certificate itself — SyniastroLMS branding, heading, learner name, statement, course and level, completion date, study hours and final score where the template shows them, two signatures or a date of issue, a seal and the credential ID — with Preview or Revoked watermarks; View (full size), Download (format choice and a simulated preparation) and Share (verification link with copy, email) — download and share are available once issued; learner, record, verification and template panels; Issue, Revoke (reason required, explains what the learner and verifiers will see) and Restore.

**Templates:** each template previewed with sample details, its default badge, courses and issued count, Edit and Make default; the editor sets name, layout (classic, modern, minimal), colour (emerald, saffron, indigo), heading and statement, study hours and score, up to two signatories and the courses that print on it, with a live preview beside the form, an error summary, a note when courses move from another template, sticky actions on mobile and a leave guard.

**Learner:** a certificate ready to claim with its preview, earned certificates with View / Download / Share, courses in progress with their certificate requirements, and a certificate page with its details and verification link; unavailable certificates explain themselves.

**Verification:** enter a credential ID; genuine certificates show who, what and when; revoked ones show why; unknown IDs say so.

**Foundation added:** domain `IssuedCertificate`, `CertificateTemplate`, `validateTemplate`; certificate records for every completed enrollment in a course that awards one (about a third of the last ten days' completions wait to be issued; a few are revoked), three templates; `services.certificates` (list, get, issue, revoke, restore, templates, save, default, verify) and learner certificate methods (list, get, claim); the student profile and activity read the same records; `CertificateDocument` sized in container units; breadcrumbs drop page crumbs that repeat navigation.

**Verification**
- typecheck, lint, 79 tests (20 domain, 59 web incl. certificate service), build — pass
- Browser: list 1440 / 390, detail pending and revoked 1440, templates 1440, template editor 1440, learner 1440 / 390, verification 390 — no console errors, no horizontal overflow
- Flows: ready-to-issue notice → filter → review → issue; share link; download prepared; revoke refuses a missing reason → revoked with reason → public page shows revoked; template signatory validation → course moved → saved; learner claims Panchang Essentials → two earned; working towards Foundations; credential SA-JY-2026-04817 verifies as genuine
- Fixed during review: 165 certificates waited to be issued (now 54); the template editor produced a duplicate breadcrumb; the preview watermark overpowered the text

**Limitations:** no files are generated — download prepares nothing real, and verification runs against the in-memory records.

### LMS-010 — Learning Experience
Completed 15 Sep 2026.

**Screens / routes** (the learner, Ananya Rao)
- `/home` — Learner home (the student's landing page)
- `/my-learning/in-progress`, `/my-learning/completed`, `/my-learning/saved` — My learning (`/my-learning` opens In progress)
- `/learn/:courseId` — Course learning overview
- `/learn/:courseId/lessons/:lessonId` — Lesson player
- `/assignments`, `/assignments/:assignmentId` — Learner assignments and hand-in
- `/assessments` — Learner quizzes and assessments
- The sidebar's "Resume lesson" opens the lesson in progress; course and lesson pages sit under My learning in navigation and breadcrumbs

**Home:** greeting with where the learner is, a resume panel (lesson, chapter, time left, video position) with one primary action, courses with progress and the next lesson, recently accessed lessons with their state, coming up (live classes with live-now / starting-soon, assignments due or overdue, quizzes ready), study rhythm for the week and saved courses; an empty state for a learner with no courses.

**My learning:** in progress, completed and saved tabs with counts; course cards with cover, level and instructor, progress, lessons done, last active or completion date, the next lesson and Resume / Continue / Start / Review / Certificate; saved cards with Enroll (price), View course and remove; empty states per tab.

**Course overview:** hero with cover, instructors, subtitle, Resume / Start / Enroll and Save for later, progress ring with lessons done and time left; your path (chapters with progress and what unlocks each); curriculum with completion states that opens lessons; certificate requirements; open assignments; upcoming live classes; outcomes.

**Lesson player:** course progress, bookmark and lessons trigger in a top bar; chapter and lesson context, type and duration; content by type — video with simulated real-time playback, play / pause, ±10 s, scrub bar showing watched and played, speed, captions and chapter markers, resuming where the learner paused and saving position; article and practice with reading time; PDF with page strip and a paged reader; quiz with the learner QuizTaker (passing completes the lesson, failing explains the pass mark, best score kept); assignment with brief, rubric, due date, draft, upload or response or birth chart, submit, waiting and graded feedback states; live session with join, recording and reminder. Objectives, resources, autosaving notes, previous / next, completion per rule (watched to 90%, exercise working written, submitted, passed, opened) with the reason shown when it isn't available yet, chapter and course completion celebrations, curriculum beside the lesson on wide screens and in a sheet on phones with sticky Back / Complete / Next.

**States:** loading skeletons, locked lesson with the reason and a way back, not enrolled, unavailable (draft) lesson, unknown lesson, completed lesson, free preview, errors with retry.

**Assignments and assessments:** to do / submitted / graded assignment tabs using the coursework status rows, and an assignment page with the full hand-in and feedback; assessments grouped into ready, opens later and passed, opening the quiz lesson.

**Foundation added:** `services.learning` (home, courses, course, lesson, completion, position, notes, bookmarks, saved, enroll, assignments with drafts and submission, assessments, quiz attempts) with chapter-order and quiz locks; completing lessons updates the learner's enrollment, submissions enter the instructor review queue and enrolling updates course counts; `also` paths on navigation items; quiz points shown to one decimal; the quiz taker keeps its width inside flex layouts.

**Verification**
- typecheck, lint, 74 tests (20 domain, 54 web incl. learning service), build — pass
- Browser: home 1440 / 390, course 1440, player 1440 / 390 (with curriculum sheet), assignment submitted, quiz result, empty home — no console errors, no horizontal overflow
- Flows: student lands on /home with a live-now class; Resume lesson opens 3.5; video blocks completion until watched → scrub → complete; notes autosave; bookmark; practice needs working written → complete; assignment refuses an empty submit → upload → submitted and lesson completed; chapter quiz unlocks → taken → below pass mark explained; locked chapter explains which chapter to finish; saved course → enroll → first lesson; graded assignment shows feedback; assessments grouped
- Fixed during review: quiz results collapsed to one word per line inside the lesson; the player kept a stale state after submitting; coming-up badges said "Soon" for a live class and "Due soon" for overdue work; course pages showed "SyniastroLMS" as their section

**Limitations:** video playback, the PDF reader, joining live rooms and uploads are simulated; progress lives in memory until the page reloads.

### LMS-009 — Instructor UI
Completed 15 Sep 2026.

**Screens / routes** (academy admin)
- `/admin/instructors` — Instructor list
- `/admin/instructors/new` — Add instructor (sends an invitation)
- `/admin/instructors/:instructorId/edit` — Edit instructor
- `/admin/instructors/:instructorId` — Instructor profile (Overview)
- `/admin/instructors/:instructorId/courses` — Instructor courses
- `/admin/instructors/:instructorId/performance` — Instructor performance

**Instructor list:** avatar, name and professional title, expertise tags, courses (with published count), unique students, performance (weighted rating with count and a completion meter), reviews waiting and overdue, status (active, invited, inactive), edit and a menu (view profile, edit, resend invitation, deactivate / withdraw invitation / reactivate); status tabs with counts, search across name, title and expertise, expertise filter and sort (name, students, rating, newest) in the URL; cards on mobile; loading, empty, no-match and error states.

**Add / edit:** display image placeholder with simulated upload, replace and remove; full name, title, email (format and uniqueness), phone, city, years teaching; bio with character count (required once active); expertise and teaching languages with suggestions; assigned courses with co-instructors named and the only instructor on a course locked in; access status (invited, active, inactive); error summary, live readiness checklist beside the form, sticky actions on mobile and a leave guard. Saving an invited instructor sends the invitation and opens their profile.

**Profile:** header with title, status, contact, years teaching and joined date; Edit, Resend invitation and a status menu; figures for courses, students reached (new in 30 days), rating, completion against the academy and reviews waiting with the share returned inside 48 hours. Overview: bio, expertise, languages, course portfolio cards, student reach (learning now, completed, top cities) and recent activity (publishing, updates, reviews, live classes). Courses: role, co-instructors, learners, rating, completion, updated and status. Performance: rating and completion compared with the academy, median review time and on-time share, live classes delivered with attendance and upcoming, monthly new enrollments, and a by-course comparison — or an explanation when there is nothing yet.

**Foundation added:** domain `InstructorInput`, `validateInstructor`, optional `phone` and `photo`; `services.instructors` (list, get, create, update, setStatus, resendInvite) deriving reach, ratings, completion, review turnaround, live teaching and activity from courses, enrollments, submissions and the schedule; course instructor lists stay in step with assignments; deactivating the only instructor of a published course is refused; reviewers now let a steady share of reviews run past 48 hours.

**Verification**
- typecheck, lint, 68 tests (20 domain incl. instructor rules, 48 web incl. instructor service), build — pass
- Browser: list 1440 / 390, add form 1440, edit form 390, profile overview 1440 / 390, performance 1440 — no console errors, no horizontal overflow
- Flows: expertise filter and sort in the URL; no-match state; empty form lists four issues; taken email refused; image upload simulated; course assigned; invitation sent → profile shows Invited → resend; edit bio → leave guard → set Active → saved; deactivating Aditya (only instructor on KP Fundamentals) explains why it can't; courses tab; Kiran (invited) shows no performance yet; unknown instructor shows "Instructor not found"
- Fixed during review: every reviewer showed 100% of reviews inside 48 hours; the completion comparison read "1 pts"

**Limitations:** invitations and photo uploads are simulated; the display image shows initials.

### LMS-008 — Student UI
Completed 15 Sep 2026.

**Screens / routes**
- `/admin/students` — Student list (academy-wide); `/teach/students` — Learners in the instructor's courses
- `/:base/students/:studentId` — Student profile (Overview)
- `/:base/students/:studentId/courses` — Enrollments
- `/:base/students/:studentId/progress` — Progress
- `/:base/students/:studentId/activity` — Activity
- The dashboard's at-risk attention item opens the list filtered to at-risk learners in both workspaces

**Student list:** avatar, name and email, most recent course with "+ n more", average progress meter, last active, status (active, at risk, inactive, suspended), message and a menu (view profile, message, enroll, suspend or restore — admin only for the last two); status tabs with counts, search by name, email or ID, course filter, sort (recently active, name, progress, newest), all in the URL; row selection with a bulk message bar; pagination over 3,412 students; cards on mobile; loading, empty, search-empty ("No students match", with an at-risk-specific message) and error states.

**Profile header:** avatar, rank eyebrow, name, status, email, city, joined date and ID; Message (becomes "Send a nudge" for at-risk learners, prefilled with their course and next lesson), Enroll and a menu to suspend or restore access; summary figures for courses (completed and in progress), average progress, study time with last activity, certificates and assignment average.

**Overview:** at-risk and suspended notices, courses in progress first with chapters done, progress and the next lesson, recent activity, rank with its descriptor and date, certificates with credential IDs (or what they are working towards).

**Courses:** every enrollment with level and instructors, enrolled date and place type, progress with lessons and chapters done, last active, certificate state and status; pause / resume and remove from course (with a progress-loss acknowledgement) for admins; enroll action and empty state.

**Progress:** course switcher, a chapter-segmented progress ring with each chapter's meter and lessons done, 12 weeks of study time (this week drawn as still accruing), quiz results against pass marks and assignment results linking to their reviews.

**Activity:** day-grouped timeline of enrollments, lessons, chapters, quizzes, live classes, submissions (with review state) and certificates; filter by type (with counts) and course; "Show earlier activity".

**Dialogs:** message one or many learners (subject, message, email / in-app, validation), enroll in a published course they aren't in (place type, validation, duplicate protection), suspend with an acknowledgement or restore.

**Foundation added:** `services.students` (list, get, progress, activity, message, enroll, setEnrollmentStatus, removeEnrollment, setSuspended) deriving lesson-level progress, study time, quiz results, certificates and a rank from each enrollment; `enrolled` activity kind and exported `ACTIVITY_KIND` labels; the demo learner keeps exactly the courses and submissions her own screens describe.

**Verification**
- typecheck, lint, 62 tests (18 domain, 44 web incl. student service), build — pass
- Browser: list 1440 / 390, profile overview 1440 / 390, progress 1440 / 390, activity 1440 — no console errors, no horizontal overflow
- Flows: dashboard at-risk item → at-risk tab; search with no match → clear; course filter and sort in the URL (318 Jaimini learners); select two → message validation → send; at-risk profile → nudge prefilled → send; enroll validation → enroll → pause → remove; activity filtered to submissions; suspend requires acknowledgement → Suspended; instructor sees Learners without the suspended tab and can't open a learner outside their courses
- Fixed during review: the progress layout queried its own width, so the ring never sat beside the chapters; study-week labels used ICU's "Sept"

**Limitations:** messages, reminders and enrollment emails are simulated; lesson-level progress is derived from each enrollment's percentage.

### LMS-007 — Assignment UI
Completed 15 Sep 2026.

**Screens / routes** (under `/admin` and `/teach`)
- `/assignments` — Assignment list
- `/assignments/review` — Review queue across every assignment in scope (tab of the same page)
- `/assignments/new?course=:courseId` — New assignment
- `/assignments/:assignmentId` — Assignment editor (Details tab)
- `/assignments/:assignmentId/preview` — Assignment preview as learners see it
- `/assignments/:assignmentId/submissions` — Submission list for one assignment
- `/assignments/:assignmentId/submissions/:submissionId` — Submission detail and grading
- Assignment lessons link to their assignment ("Edit assignment", "Submissions"); the dashboard's review actions and attention item open the queue

**Assignment list:** title with course and chapter, format and due policy, submitted and not yet submitted counts, to review with overdue, average score against the pass mark, status, Review / Edit and a menu with preview, submissions, duplicate and delete (disabled with a reason for lesson-delivered assignments; acknowledgement when submissions exist); status tabs, search and course filter in the URL; cards on mobile; empty, no-results, error and loading states.

**Review queue:** figures for to review, past the 48-hour window and courses waiting; oldest-first list of learner, assignment, submitted time, time waiting and review status with a Review action; course filter, learner search, sort, pagination; cards on mobile; "All caught up" empty state.

**Editor — Details:** title, course and chapter (locked when a lesson delivers it), instructions with word count and formatting hints, resources for learners (simulated upload, up to five), what learners hand in (file upload, written response, birth chart) with optional word limit, grading with a rubric editor (criteria with description and points, reorder, add, remove, total as maximum score; starting templates per format) or a plain maximum score, pass mark with a meter, due date (after the lesson unlocks, fixed date and time, or none), late work and penalty, status (published, draft, closed) with a live "ready to publish" list; a warning when changing the rubric after reviews exist.

**Editor — Preview and Submissions:** the learner page with facts, rendered instructions, resources, rubric and a working hand-in area (upload, response with word count against the limit, birth details) that confirms nothing is sent; the submission list filtered to review / graded / returned / not submitted / all, with reminders to learners who haven't handed in (individually or the page), score, late marker and pagination.

**Submission review:** learner and assignment header with review status, submitted time, late marker, attempt and previous / next in the queue; the response (text, files, or birth details with interpretation) with word count; the brief and resources in a disclosure; the learner's progress and details; a grading panel with per-criterion scores and quick 0 / half / full buttons, running total with late penalty and pass indicator, feedback with suggested phrases, a private note, Save draft, Request resubmission and Submit review; validation that names each unscored criterion; a success state with "Next to review"; a graded summary that can be edited; a leave guard that offers to save a draft; sticky actions on mobile.

**Foundation added:** domain `CourseAssignment`, `Submission`, `Review`, `RubricCriterion`, `DuePolicy`, `assignmentMaxScore`, `reviewScore`, `reviewOverdue`, `validateAssignment`, `validateReview`; `services.assignments` (list, get, create, update, duplicate, remove, submissions, submission, review, remind, summary) over 14,000 generated submissions whose open queue matches the dashboard (28 academy-wide, 14 for the demo instructor); live sidebar badge and review meter; shared `MediaDrop` / `FileCard` upload components; windowed pagination; formatted tab counts; breadcrumbs keep short names whole.

**Verification**
- typecheck, lint, 57 tests (18 domain incl. rubric scoring, late penalty and review rules; 39 web incl. assignment service), build — pass
- Browser: list 1440 / 768, queue 1440 / 390, editor 1440 / 390, review 1440 / 390, preview 360, instructor dashboard — no console errors, no page overflow
- Flows: queue → review → validation lists unscored criteria → quick scores → phrase → submit → graded summary, badge 28 → 27 → next to review; leave guard → save draft and leave; request resubmission needs feedback → returned; not submitted filter → remind 20 learners; new assignment → publish blocked → fill → birth chart swaps the rubric template → add criterion (25 points) → preview → publish; unknown submission shows "Submission not found"
- Fixed during review: queue showed "submitted" and "waiting" as the same relative time; counts over 9,999 unformatted; tall grading panel could hide its actions while sticky; pagination rendered a button for every page

**Limitations:** uploads, reminders and feedback delivery are simulated; generated responses are sample text; a returned submission has no resubmission until learners can submit (LMS-010).

### LMS-006 — Quiz UI
Completed 15 Sep 2026.

**Screens / routes** (under `/admin` and `/teach`)
- `/quizzes` — Quiz list (new "Quizzes" item under Catalog / Teach)
- `/quizzes/new?course=:courseId` — New quiz
- `/quizzes/:quizId` — Quiz builder and question editor (Questions tab)
- `/quizzes/:quizId/settings` — Quiz settings
- `/quizzes/:quizId/preview` — Learner preview
- `/quizzes/:quizId/results` — Results preview
- Quiz lessons link to their quiz from the lesson editor

**Quiz list:** title with course and chapter, questions and points, pass mark, attempts, pass-rate meter, status, updated, Edit and a menu with preview, results, duplicate and delete (disabled, with a reason, for quizzes delivered by a lesson); status tabs with counts; search and course filter in the URL; cards on mobile; empty, no-results, error and loading states.

**Builder — Questions:** title, instructions, course and chapter (locked when a lesson delivers the quiz), question count and total points, ordered question rail with type, points and issue markers (a compact "Question" selector on phones), add question by type, and an editor per question: type switch that keeps what was written, prompt, answers with correct marking (one or several), true/false statement, accepted short answers, points, required, explanation, move, duplicate and delete with undo.

**Builder — Settings:** pass mark, attempts (or unlimited), optional time limit, shuffle questions and answers, and what learners see afterwards (score and answers, score only, nothing).

**Preview:** the learner quiz with the current, unsaved questions: intro with rules, one question at a time with progress meter, question dots, timer, "Check answer" feedback with the explanation, submit, and a result that respects the results setting.

**Results:** attempts, learners, pass rate, average score and median time; score distribution chart with the pass band; questions ordered hardest first with correct rate and the most-chosen wrong answer.

**States and guards:** empty quiz with a start-by-type choice, validation summary that jumps to the first unfinished question, publish blocked by the shared domain rule, "Unsaved changes" / "Saved …", leave-without-saving dialog and beforeunload warning, sticky Save on mobile, load error with retry.

**Foundation added:** domain `quiz.ts` (`Quiz`, `QuizQuestion`, `QuizSettings`, `validateQuiz`, `scoreAttempt` with partial credit and normalised short answers); `services.quizzes` (list, get, stats, create, update, duplicate, remove) with a question bank per topic and quizzes for all 14 assessment lessons; `QuizTaker` learner component for reuse in the learning experience; segmented tracks fade at an edge that has more tabs to scroll to.

**Verification**
- typecheck, lint, 48 tests (15 domain incl. quiz validation and scoring, 33 web incl. quiz service), build — pass
- Browser: list 1440, builder 1440 / 768 / 390, preview and results 1440, preview 360, instructor list 768, error state — no console errors, no horizontal overflow
- Flows: convert single → short → single keeps answers; add true/false → save blocked → summary names question → fix → saved; settings (time limit, score only) → preview with timer, check answer, submit hides answers; results; leave guard; start an empty quiz; create a new quiz
- Fixed during review: header crumbs truncated short ancestors ("Qu…") by a fraction of a pixel; Results tab hidden off-screen on phones; duplicated true/false questions lost their option ids; score bands didn't add up to the attempts

**Limitations:** attempts and results are generated; nothing a learner answers in preview is stored.

### LMS-005 — Lesson Management
Completed 15 Sep 2026.

**Screens / routes** (under `/admin` and `/teach`)
- `/courses/:courseId/lessons` — Lesson list (new "Lessons" tab on the course)
- `/courses/:courseId/lessons/new?chapter=:chapterId` — Add lesson
- `/courses/:courseId/lessons/:lessonId` — Edit lesson / Lesson editor (Content tab)
- `/courses/:courseId/lessons/:lessonId/settings` — Lesson settings
- `/courses/:courseId/lessons/:lessonId/preview` — Lesson preview
- "Add lesson" is also offered inside each expanded chapter in the curriculum

**Lesson types:** video, article, PDF, quiz, assignment, live session and practice — each with its own content editor and learner preview.

**Lesson list:** grouped under chapter headings in course order (number, title with free-preview marker, type, duration, status, updated, Edit and a menu with preview, duplicate, move to chapter, publish / move to draft, delete); switches to a flat list with a Chapter column for other sorts; type tabs with counts; search; chapter, status and sort filters in the URL; compact grouped cards on mobile; empty course ("add a chapter first"), empty chapter list, no-results, error and loading states.

**Editor — Content:** curriculum context above the title (Chapter 03 · Understanding the Twelve Houses · Lesson 3.5), large title field, type picker, and a content panel per type: video with simulated upload (progress, cancel, processing), player frame, replace/remove, captions and chapter markers; article with formatting toolbar, word count, reading time and "use reading time as duration"; PDF with simulated upload and download switch; quiz attempts, pass mark and time limit with a link to the quiz builder; assignment brief, submission type, due-after days and maximum score; live session date, length and recording. Side panels for description, duration, objectives, free preview, visibility and a live "ready to publish" list.

**Editor — Settings:** completion rule offered by type (opened, watched to the end, submitted, passed), require previous lesson, discussion, downloadable resources, chapter and position, and delete.

**Editor — Preview:** the learner lesson with the current, unsaved content — video player, reading canvas, PDF card, quiz, assignment or live panel, objectives and lesson navigation — at desktop or phone width.

**States and guards:** error summary that returns to the Content tab, publish blocked until the type's content exists (shared domain rule), inline save errors, "Unsaved changes" / "Saved …" state, leave-without-saving dialog and beforeunload warning (switching tabs is allowed), sticky Save / Publish bar on mobile.

**Foundation added:** domain `LessonContent`, `LessonSettings`, `LessonInput`, `lessonPublishIssues`, `readingMinutes`, `defaultCompletion`; `services.lessons` (list, get, create, update, move, duplicate, remove) with generated content for catalog lessons (including written articles); `--media-ground` / `--media-ink` tokens for video; narrow-panel ListInput hides reorder arrows.

**Verification**
- typecheck, lint, 40 tests (13 domain incl. lesson publish rules, 27 web incl. lesson service), build — pass
- Browser: list 1440 and 390, video editor 1440, article editor and preview at desktop and phone width, editor 390 — no console errors, no horizontal overflow
- Flows: type filter; flat sort shows Chapter column; new article → publish blocked → toolbar heading → write → reading-time duration → preview → settings → publish → redirected to the saved lesson; remove a video → save blocked → simulated upload → leave guard → save; move a lesson to chapter 7
- Fixed during review: the article area shrank when it lost focus, moving buttons beneath the pointer

**Limitations:** uploads, captions and video processing are simulated; nothing leaves the browser. Quiz questions and assignment reviews are built in LMS-006 and LMS-007.

### LMS-004 — Chapter Management
Completed 15 Sep 2026.

**Screens / routes** (under `/admin` and `/teach`)
- `/courses/:courseId/curriculum` — Course curriculum / chapter list
- `/courses/:courseId/curriculum/chapters/new` — Add chapter (panel over the curriculum)
- `/courses/:courseId/curriculum/chapters/:chapterId/edit` — Edit chapter (panel)
- `/courses/:courseId/chapters/:chapterId` — Chapter overview
- Reorder mode, move-to-position dialog, delete confirmation

**Chapter list:** Course → Chapter → Lesson legend; each chapter shows its number, title, summary, lesson count, duration (lessons, or "~" estimate), learner completion ring and percentage (share of enrolled learners who finished it; "—" for drafts and empty chapters), status, Edit and a menu (overview, edit, duplicate, move to position, publish / move to draft, delete); lessons expand in place with type, free-preview and draft markers, the chapter objective and a link to the overview; expand/collapse all; empty curriculum invites the first chapter; on narrow screens it becomes an accordion tree with completion and status under the title.

**Add / edit:** title (unique within the course), short description, learning objective, estimated duration, visibility (published or draft — new and lesson-less chapters must stay drafts), and position; error summary, inline server errors, discard guard.

**Reorder / move:** drag by the handle or use up/down arrows with screen-reader announcements, then Save order; or "Move to position…" from the menu with a radio list of positions.

**Duplicate and delete:** duplicates copy the chapter and its lessons as drafts directly after the original, with a toast action to edit the copy. Delete lists what goes with it; published chapters with learners require an acknowledgement; a published course cannot lose its last published chapter.

**Chapter overview:** large chapter numeral, status, summary and duration; the objective as a pull quote ("By the end of this chapter, learners can…"); lessons, duration, started and finished figures; lessons by type; per-lesson completion bars that flag steep drops; previous/next chapter; edit, duplicate, move and delete.

**Foundation added:** `services.chapters` (stats, create, update, duplicate, remove, move) with chapter and lesson completion derived from learner progress against cumulative lesson minutes; `Chapter.estimatedMin`, `ChapterInput`, `chapterDisplayMin`; `lessonTypeCount`; `RouteTabs` `also` prefixes; breadcrumbs collapse to "…" beyond two ancestors.

**Verification**
- typecheck, lint, 34 tests (11 domain, 23 web incl. chapter insert, duplicate, delete guard and completion ordering), build — pass
- Browser: curriculum 1440 and 390 (tree), chapter overview 1440, add-chapter panel — no console errors or warnings, no horizontal overflow at 390
- Flows: add with validation → added at position 3; duplicate → draft copy after original; publish disabled for a chapter without lessons; move to last position; delete draft copy; delete of a published chapter requires acknowledgement; keyboard reorder saved; edit from overview; next-chapter navigation; breadcrumb Home › … › course › Curriculum › Chapter 2

**Limitations:** lessons inside chapters are managed in LMS-005.

### LMS-003 — Course Categories
Completed 15 Sep 2026.

**Screens / routes** (admin)
- `/admin/categories` — Category list
- `/admin/categories/new` — Create category (panel over the list)
- `/admin/categories/:id/edit` — Edit category (panel)
- `/admin/categories/:id` — Category details (panel), with delete confirmation

**List:** header with count and Add category; All / Active / Hidden tabs with counts; search; sort by display order, name, most courses or recently updated (kept in the URL); table with order, emblem, name, two-line description, course count with published count, status, updated time and actions — inline Edit plus a menu with View, Edit, Move up / Move down and Delete; compact cards on mobile; empty, no-results and error states; skeleton rows.

**Create / edit:** live preview of emblem, name and description; name (unique, 40 characters), short description (160), emblem choice from eight fine-line glyphs, levels, status with explanation, and display order that shifts the others; error summary, inline server errors (duplicate names), "Discard your changes?" when closing with edits, beforeunload warning; drawer on desktop, bottom sheet on mobile.

**Details:** large emblem, status, description, courses / published / learners figures, levels, the courses in the category with cover, learners and status (linking to course details), position and updated date; Edit and Delete in the footer.

**Delete:** consequences listed; when courses use the category, a destination category must be chosen before "Move courses and delete" is enabled; learners keep enrollments; orders close up.

**Foundation added:** `services.categories` (list, get, create, update, remove with move) keeping display order contiguous; `CategoryGlyph` emblems; `CategoryInput`; route pattern for panels over a list (child paths with `element: null` and `useMatch`); design-system specimen for visual choices.

**Verification**
- typecheck, lint, 30 tests (11 domain, 19 web incl. category ordering and delete rules), build — pass
- Browser: 1440 list, 1280 details panel, 390 cards and bottom-sheet form, 768 empty, 320 no overflow; no console errors or warnings
- Flows: search empty → clear; create with validation → duplicate name error → create at position 2 → details; move down via menu; delete with courses blocked until a destination is chosen → courses moved; edit → Escape → discard prompt → closed

**Limitations:** emblem artwork is chosen from the eight glyphs; custom icon upload is out of UI-only scope.

### LMS-002 — Course Management
Completed 15 Sep 2026.

**Screens / routes** (each under `/admin` and `/teach`; the teaching workspace is limited to the instructor's courses and cannot archive)
- `/courses` — Course list
- `/courses/new` — Create course
- `/courses/:courseId/edit` — Edit course
- `/courses/:courseId` — Course details (Overview tab)
- `/courses/:courseId/curriculum` — Curriculum overview
- `/courses/:courseId/preview` — Course preview as a learner
- Publish, move-to-drafts, archive and restore confirmations (dialogs from the list menu and the details header)

**Course list:** header with count and Add course; status tabs with live counts; search (title, subtitle, tags); category, instructor and sort filters; list/grid switch; state kept in the URL; table with cover, level · category, instructors, chapters · lessons · duration, learners, status, updated and an actions menu (view, edit, preview, copy link, publish/unpublish, archive/restore); grid cards; mobile uses compact cards and a filter sheet; pagination; empty, no-results (clear filters) and error (retry) states; skeletons while loading.

**Create / edit:** sections for identity (live slug), cover (generated artwork choice), description, classification (category, level, format, language, estimated weeks, live sessions), instructors, learning outcomes (ordered list editor), tags (with suggestions) and visibility & certificate. Validates on submit then live, error summary with focus links, server errors inline (duplicate titles), sticky summary with live cover/title, save state and publishing readiness, section index on wide screens, sticky save bar on mobile, "Leave without saving?" guard and beforeunload warning.

**Details:** header with cover, level · category, status, visibility, updated time, Preview / Edit / Publish and overflow menu; enrollment snapshot (figures, 12-week trend, progress distribution, recent enrollments) or a publish prompt for drafts; about, outcomes, tags; curriculum summary with lesson-type counts and chapter list; publishing checklist, details and instructors in the aside.

**Curriculum:** chapter outline with summaries, draft badges, lesson counts and durations; lessons expand in place with type, free-preview and draft markers; expand/collapse all; reorder mode with move buttons, screen-reader announcements and Save order.

**Preview:** the learner course page (hero, about, outcomes, curriculum with free-preview behaviour, instructor bios, price panel) with enrollment switched off, a preview bar stating visibility, and desktop/mobile width.

**Foundation added**
- `services.courses` (list, get, stats, create, update, publish, unpublish, archive, restore, reorderChapters) on in-memory fixtures; publish enforces `publishChecklist`; duplicate titles conflict; analytics cache invalidates on change
- Components: forms (`FormSection`, `ChoiceCards`, `Switch`, `TagInput`, `ListInput`, `ErrorSummary`), `ConfirmDialog`, `RouteTabs`, `CourseStatusBadge` / `VisibilityLabel`; shell `usePageCrumbs` for deep breadcrumbs; `Field` keeps a control's own id; global `[hidden]` rule
- Domain: `CourseInput`, `estimatedWeeks`
- Sidebar "New course" and the command palette open the course editor; course search results open course details for staff
- Design system: "Forms and decisions" section

**Verification**
- typecheck, lint, 27 tests (11 domain, 16 web incl. course service rules), build — pass
- Browser: list 1440/1024/768/390 (table, grid, cards, empty, error), details published and draft 1440/1280/390/320, curriculum 1280/390, editor 1440/390, preview desktop and mobile frame — no console errors, no horizontal overflow
- Flows: status tabs, search empty → clear, category filter in URL, grid switch; create with validation → error summary focus → fill → unsaved-changes guard → create → details; publish blocked by checklist; archive requires acknowledgement → archived; chapter reorder saved with announcement; teaching workspace hides other instructors' courses

**Limitations**
- Cover artwork is chosen from the generated motifs; custom image upload is not part of the UI-only scope
- Chapter and lesson editing arrive in LMS-004 and LMS-005; the curriculum tab is read-and-reorder today

### LMS-001 — LMS Dashboard
Completed 15 Sep 2026.

**Screens / routes**
- `/admin` — LMS Dashboard for the academy admin
- `/teach` — the same composition scoped to the signed-in instructor ("Teaching overview")
- `/` now lands each role in its workspace (admin → `/admin`, instructor → `/teach`; student → design system until LMS-010)
- Every page backed by mock services can be previewed with `?scenario=empty | error | slow`

**Dashboard composition**
- Header: date eyebrow, title, a contextual summary written from live data, primary "Add course" and secondary "Schedule live class" (instructor: "Review submissions")
- KPI band (typographic, hairline dividers): active courses, total students, instructors (instructor: reviews waiting), completion rate — each with sparkline, change and a line of context
- Course performance: enrollments/completions switch, four-week figure with change, 12-week trend chart, top-five course table that recomposes to a list in narrow containers
- Needs attention: overdue reviews, at-risk learners, nearly-full live classes, stale drafts, missing captions — severity by icon, tone and words
- Live this week with live/starting-soon/upcoming states and seat meters
- Student learning activity: four engagement figures and a 28-day column chart with today hatched as partial
- Quick actions, recent activity feed, top courses by four-week enrollments
- Mobile follows priority order (attention → quick actions → live → figures → analysis); 700px+ pairs the rail sections; 900px+ splits main column and rail

**States:** layout-shaped loading skeleton; empty academy onboarding (3 steps; instructor variant has 2); error with retry; per-section empty copy (nothing to triage, no live classes, no activity, no rankings)

**Foundation added**
- Domain: `Chapter` replaces `CourseModule` everywhere (UI says "chapter", matching the pack specs); course status, visibility, outcomes, tags and `publishChecklist`; categories with description, status and glyph; instructor profiles; `people.ts` (students, enrollments, `deriveStudentStatus`); `analytics.ts` (`kpiChange`, dashboard snapshot); lesson type `document` (PDF)
- Mock academy: 16 courses (11 published, 3 draft, 2 archived) with full chapter outlines, 8 categories (one hidden), 9 instructors (one invited, one inactive), 3,412 generated students with 11,026 enrollments that add up to each course's learner count, academy live schedule and staff activity
- `services.dashboard.getSnapshot(scope)`; mock simulation moved to `services/mock/simulation.ts` with URL scenarios
- Components: `PageHeader`, `SectionHeader` (components/page), `KpiStrip`, `Delta`, `Figure` (components/data), `TrendChart`, `ColumnChart`, `Sparkline` (components/charts); `DataTable` columns gain `listOnly`
- `useWorkspace()` for `/admin` vs `/teach` base paths and data scope
- Navigation: admin — Dashboard; Catalog (Courses › All courses/Categories, Quizzes, Assignments, Live classes, Certificates › Issued/Templates); People (Students, Instructors); Insight (Reports, Calendar, Settings). Instructor — Overview; Teach (My courses, Quizzes, Assignments, Live classes); People (Learners, Calendar)
- Design system: new "Headers, figures and charts" section in Components

**Files:** `pages/dashboard/*`, `components/{page,data,charts}/*`, `hooks/useWorkspace.ts`, `services/mock/{analytics,simulation,random}.ts`, `services/mock/fixtures/{catalog,people,schedule,fixtures.test}.ts`, `packages/domain/src/{catalog,people,analytics}.ts`

**Verification**
- typecheck, lint (0 warnings), 23 tests (11 domain, 12 web incl. mock-data integrity), production build — pass
- Browser (Edge headless): 320, 390, 768, 1024, 1280, 1440, 1920 light; 1280 dark — no console errors, no horizontal overflow
- Interactions: measure switch updates figure and chart; chart keyboard read-out (← →) with live region; attention item navigates to its destination; `/teach` scope; error → Try again re-requests; empty and slow scenarios render onboarding and skeleton

**Limitations**
- Review-queue counts are fixed per course until LMS-007 introduces submissions
- Links to screens built by later modules resolve to the placeholder until those modules land

### LMS-000 — LMS Foundation & Design System
Completed 15 Sep 2026.

**Screens / routes**
- `/design-system` (Foundations), `/design-system/components`, `/design-system/learning`, `/design-system/states`, `/design-system/responsive`
- `/design-system/specimen/:id` — composition studies used by the responsive device previews (course overview, lesson canvas, learner table, rank & activity)
- Every other navigation destination resolves to a placeholder naming the module that builds it

**Foundation**
- Monorepo: `apps/web` (React 18, Vite, TypeScript, React Router) and `packages/domain` (types and rules for the future API)
- Tokens: shell token layer unchanged, plus LMS extensions (semantic aliases, track, hatch, scrim, type scale, motion, layout, z-index)
- Density modes: immersive, balanced, dense (`data-density`)
- App shell rebuilt from the App Shell HTML: sidebar (264/76), header, mobile header, bottom nav, drawer, full-screen search; role-based navigation for student, instructor and admin; tablets default to the collapsed rail
- Command palette: role- and context-aware commands plus lesson and course search
- Services: interfaces in `services/contracts.ts`, mock implementation with latency and failure simulation

**Components**
- UI: Button, IconButton, LinkButton, Field, Input, Select, Textarea, SearchInput, Badge, CountBadge, Kbd, IconChip, Avatar, AvatarGroup, Tooltip, Menu, SegmentedControl, Checkbox, Pagination, DataTable, InlineMessage, Skeleton, StateMessage, Spinner
- Overlays: Modal, Drawer, BottomSheet, AdaptivePanel, ToastProvider
- LMS (38): status (StatusBadge, StatusLabel, StatusNode), progress (ProgressRing, Meter, LessonSegments, VideoProgress, ScoreMeter, MilestoneTrack), LearningJourney, ProgressTimeline, RankProgression, RankEmblem, RankMeter, CourseCover, CourseIdentity, CourseLevel, CourseMeta, CourseInstructor, CourseCurriculum, LessonRow, LessonStatus, LessonDuration, LiveClassStatus, AssignmentStatus, AssessmentStatus, CertificateStatus, CertificateSeal, StudyRhythm, ActivityFeed, LearningActivity, EnrollmentAction, ContinueLearningAction, StickyActionBar, WorkRow, WorkList, DateBlock

**Verification**
- `npm run typecheck` — pass (web, web Vite config, domain)
- `npm run lint` — pass, 0 warnings
- `npm test` — 14 tests pass (domain rules, formatting, command registry)
- `npm run build` — pass
- Browser (Edge, headless): no console errors on any chapter; screenshots reviewed at 320, 375, 390, 768, 1280 and 1440, in light and dark
- No horizontal overflow at 320px on any chapter or composition study
- Interactions exercised: command palette (keyboard, search), enrollment confirm → success, drawer vs bottom sheet, mobile search sheet and menu drawer, role switching, data table search/sort/bulk select, failed load → retry, scroll-spy index

## Final Audit
Completed 15 Sep 2026, after LMS-016.

**Placeholders removed**
- The student **Explore** destination was the last “built in a later module” page. It is now a real catalog at `/explore`: every public, published course with a category strip, level switch, search, category, format and sort; course cards with level, category, lead instructor, rating, learners, length and format; price with Save for later, or Continue with progress for courses already enrolled; linking to the learner course page, which already handles enrolling and free previews; no-match and empty states.
- **Community** had no module, specification or data behind it, so it was taken out of the student navigation rather than left as a placeholder (see Design Decisions).
- The catch-all page no longer promises future modules: unknown addresses show “This page isn’t on the map” with a way back to the nearest section.
- The account menu’s placeholder toasts are gone: **Profile** opens a profile dialog (name, email, role, links to notification preferences and certificates), **Keyboard shortcuts** and the header **Help** button open a shortcuts and help dialog (command menu, sidebar, save, Esc, calendar keys, support email), and **Sign out** confirms and leads to a signed-out screen with Sign in again.

**Duplicates consolidated**
- `Rating` existed twice (dashboard and instructors); one shared `components/lms/shared/Rating` now serves the dashboard, instructors, reports and Explore.
- `ArticleBody`, the markdown renderer, lived inside the lesson editor’s preview but was imported by assignments and the learner player; it is now `components/lms/content/ArticleBody`.

**Code health**
- Prettier applied across `apps/web/src` and `packages/domain/src` (`npm run format:check` passes).
- typecheck, lint (no warnings), 112 tests (31 domain, 81 web), production build — pass.
- `docs/01-PROJECT-ARCHITECTURE.md` updated for the new domain files, components, pages and the not-found route.

**Browser audit**
- 54 routes across the three roles — every management area and its detail pages, learner home, Explore, course, lesson player, coursework, live, certificates, verification, notifications, calendar, reports, settings, design system, signed out and an unknown address — at 1440px and at 390px: no console errors, no horizontal overflow, exactly one page heading each, no unnamed buttons, links or form controls, and the not-found page only where expected.
- Internal links: 481 distinct internal links found on those pages (477 at 1440, 425 at 390) reduce to 142 destinations per role and URL shape; one of each was opened with its role — all 142 load without a not-found page, a load error or a script error.
- Per-module interaction scripts (keyboard, dialogs, validation, leave guards, empty, error and loading scenarios) were run as each module was completed; see each module’s Verification.

## Post-Audit Additions
Requested by the client after the final audit, to have a full front door and a self-serve help centre to demo. Both are UI only, like every other module.

### LMS-017 — Marketing & Auth Pages
Completed 15 Sep 2026.

**Screens / routes** (top-level, outside the app shell, like the existing `signed-out` route)
- `/welcome` — public landing page
- `/login` — sign in
- `/register` — create account
- `/privacy` — privacy policy
- `/terms` — terms of service

**Landing (`/welcome`):** sticky header (Courses, Verify a certificate, Help Centre; Sign in, Get started) over a hero with a stat row (16 courses across 8 tracks, 9 instructors, 48-hr review window); a featured-courses grid using real catalog titles with `CourseCover` and `Rating`; a three-workspace explainer (learner / instructor / admin); a three-step “how a course finishes” list; testimonials from a learner, an instructor and an admin; a closing CTA banner; and a footer with Product, Support and Legal columns plus a copyright line.

**Sign in / Create account:** a shared split layout (`AuthChrome`) — a value-prop panel beside the form, panel hidden below 768px with the brand mark moving above the form instead. Both forms validate inline with an `ErrorSummary` that lists what to fix and links focus to each field, and a password visibility toggle. Sign in adds a “Continue as” `ChoiceCards` picker (Learner / Instructor / Academy admin) that reuses the app’s existing demo `switchRole` mechanism, then hands off into that workspace with a signed-in toast naming the persona. A forgot-password link opens a modal that validates the email and shows a success toast — no email is actually sent. Register always creates a learner account, requires agreeing to the Terms and Privacy Policy (opened in a new tab so the form isn’t lost), and lands on `/home` with a welcome toast.

**Legal:** `/privacy` and `/terms` are long-form reading pages in the same site chrome, with realistic sections (what’s collected, who can see what, retention, acceptable use, and so on) and a note that this is a demo build.

**Also changed:** `SignedOutPage`’s “Sign in again” now points at `/login` instead of `/`, so signing out and back in goes through the new sign-in screen.

**States:** empty/invalid submit (both forms), forgot-password success, sign-in success per role, register success.

**Verification**
- typecheck, lint, 112 tests (31 domain, 81 web), build, `npm run format` — pass
- Browser (Edge, headless): landing, login, register, privacy and terms at 1440 and (landing, login, register) at 390 — no console errors; login and register interaction-tested (empty submit shows validation, valid submit signs in/registers and navigates, forgot-password modal submits and closes)
- Found and fixed during review: `.legal p, .legal li` in `Marketing.module.css` was scoped to the whole `<article>`, so its specificity (0,1,1) beat the single-class `.muted` and `.legalNote` rules (0,1,0) and rendered the “Last updated” caption and the demo-note callout in body-text black instead of muted grey; rescoped to `.legal section p, .legal section li` so it only touches the reading body
- Link crawl from all five new pages plus `/signed-out`: 9 distinct internal links discovered, all resolve without a not-found page or console error

### LMS-018 — Knowledge Base
Completed 15 Sep 2026.

**Screens / routes:** a Help Centre shared by all three roles, following the notifications/calendar pattern of one route set mounted three times — `/help` (learner), `/teach/help` (instructor), `/admin/help` (admin), each with `/:categoryId` and `/article/:slug` children.

**Hub:** search, six topic tiles (Getting started, Courses & lessons, Assignments & quizzes, Live classes & calendar, Certificates & reports, Academy settings) each with an article count, and a popular-articles list. **Category page:** icon, description, an in-category search and its article list. **Article page:** a breadcrumb back to its category, read time and last-updated date, a small safe-markdown renderer for the body, a “Was this article helpful?” Yes / Not really control with a thank-you state, and up to three related articles from the same category.

**Content:** 24 hand-written articles across the 6 categories above, each tagged for learners, instructors, admins or everyone via a non-gating `AudienceBadge` — nothing is hidden by role, since a client walkthrough should let anyone read anything.

**Navigation:** a new Support nav group (Help Centre) for students, and a Help Centre item added to the existing instructor People group and admin Insight group; wired into the header’s help dialog and the account menu’s profile dialog, both of which now link to the Help Centre first.

**Foundation added:** domain `help.ts` (`HelpCategory`, `HelpArticle`); `HelpService` contract (`listCategories`, `listArticles`, `getArticle`) and its mock implementation with the same latency/scenario simulation as every other service.

**States:** loading, empty search, article not found.

**Verification**
- typecheck, lint, 112 tests, build — pass
- Browser (Edge, headless): hub, category and article pages at 1440 — no console errors

### LMS-019 — Subscription & Plan Management
Completed 21 Sep 2026. Specification: `.claude/ui/subscriptions.md`.

A prototype of the platform's future billing layer, inside the existing Super Admin workspace. It is UI only in the strictest sense in this project: there is no payment gateway, no recurring billing, no invoice backend and no enforcement. Changing a plan or cancelling a subscription moves an in-memory record and writes a line into that subscription's history; nothing about a learner's, instructor's or academy admin's access changes.

**Routes** (all under the platform workspace, added as siblings of `/superadmin/audit` and `/superadmin/system`)
- `/superadmin/subscriptions` — Overview
- `/superadmin/subscriptions/plans` — Plans, `…/plans/new`, `…/plans/:planId`, `…/plans/:planId/edit`
- `/superadmin/subscriptions/subscribers` — Subscribers, `…/subscribers/:subscriptionId`
- `/superadmin/subscriptions/billing` — Payment history

The four areas are tabs of one page (`RouteTabs`), the pattern already used by Certificates and Reports.

**Overview.** A `KpiStrip` of six figures — active subscriptions, in trial, past due, canceling, MRR and ARR — each with its change against the month before. A “Closing soon” panel lists the trials and grace periods that run out first, soonest first, with days remaining. Two charts, one measure each, following the project's chart rule: MRR over twelve months (`TrendChart`) and new subscriptions a month (`ColumnChart`) with a quiet legend carrying the twelve-month upgrade, downgrade and cancellation totals. Below them, subscribers by plan (`BarList`, with each plan's monthly worth) and a breakdown of where every subscription stands, each state linking to the filtered subscriber list.

**Plans.** Status tabs (All / Active / Draft / Archived) with counts, search over name, code and description, and sort by display order, price, subscribers or recent change. Desktop table — plan, cycles, price with code, active subscribers with monthly worth, trial, status, updated — and a row menu (edit, duplicate as draft, archive/restore); cards below 768px. **Create / edit** covers identity (name, description, unique plan code), pricing (which cycles are sold and what each costs, with the annual saving worked out), trial, limits (learners, instructors, courses, storage, live classes a month, admin accounts — each with an Unlimited switch that disables the field rather than zeroing it), grouped feature switches, and visibility as three `ChoiceCards` with a readiness checklist beside them. Validation runs through `validatePlan` in the domain package, reported by `ErrorSummary` with links that move focus to the field; a leave guard and a sticky mobile action bar match the other editors. **Plan detail** shows pricing and trial, subscribers by state (each linking to the filtered list), limits, the features in and out of the plan, a six-month subscription trend and the academies on it, with Edit, Duplicate, and Archive/Restore behind a confirmation that spells out that existing subscriptions keep their price.

**Subscribers.** Status tabs for all seven states with counts taken before the status filter, so the numbers do not move as you switch. Search over academy name, billing email and subscription ID; filters for plan, billing cycle, payment status and a renewal-date window; sort by renewal, start, name or amount. Everything reaches the URL, so a filtered list can be linked to. Pagination at 20 a page. Below 768px the table becomes cards and the filters move into a bottom sheet with a count on the button. **Subscriber detail** leads with the state's own notice — days left in a trial, what is owed with the retry and grace dates when past due, the end date when cancelling, the resume date when paused — then subscription facts, billing (with the payment method masked to a brand and four digits), that subscription's invoices, the academy, and a history rail of everything that has happened to it. Five actions, each a confirmation that states the consequence first: **Change plan** (current against new, side by side, with the cycle the new plan is actually sold on, the price difference, and immediate or end-of-period), **Pause** (30/60/90/180 days, naming the resume date), **Resume**, **Cancel** (a reason of at least five characters, chosen or typed, immediate or end-of-period) and **Reactivate**.

**Billing.** Every charge the prototype says was raised: date, customer, subscription, amount with currency and tax, status, invoice number and masked method. Status tabs (paid / pending / failed / refunded), search over academy, invoice number and subscription ID, a plan filter, and collected / outstanding / refunded totals for everything that matches — not just the page. The invoice number opens a **sheet**: number, issue and paid dates, billing address, subscription, plan, period, line items, subtotal, 18% tax and total. **Download** writes the line items to a CSV using the same `downloadCsv` helper the reports already use — a real file, not a simulated one. **Print** sends only the sheet to paper.

**Printing.** `lib/print.ts` marks the document for the length of the print job and `styles/base.css` gained a `@media print` block that hides the app behind the dialog, the scrim and anything marked `data-print-hide`. `components/overlays/Overlay.tsx` gained two attributes to make that possible (`data-overlay` on the frame, `data-overlay-scrim` on the scrim, `data-print-hide` on the close buttons) — the only change to a shared component in this module, and a general capability rather than a subscription-specific one.

**Foundation added**
- `packages/domain/src/subscription.ts` — plans (status, cycles, limits with `null` for unlimited, the feature catalogue), `validatePlan`, subscriptions and their seven states, subscription events, invoices with `invoiceSubtotal` / `invoiceTax` / `invoiceTotal`, and the recurring-value rules: `isBilling`, `monthlyValue` (an annual subscription spread over twelve, a trial worth nothing), `annualSavingPercent`, `planChangeEffect`, `daysUntil`.
- `services/contracts.ts` — `SubscriptionService` with the plan, subscriber, action and billing calls, plus the row, query and result shapes.
- `services/mock/subscriptions.ts` and `services/mock/fixtures/subscriptions.ts` — six plans (Starter, Growth, Professional, Enterprise, a Scholar draft and an archived Professional (2025)), 38 academies written out by hand so the mix of states is deliberate, their histories, and ~100 invoices across paid, pending, failed and refunded. Seeded from a fixed clock, so the overview's totals are computed from the same records the lists serve and the two never disagree.

**Files**
- New: `packages/domain/src/subscription.ts` + `subscription.test.ts`; `apps/web/src/services/mock/subscriptions.ts` + `subscriptions.test.ts`; `apps/web/src/services/mock/fixtures/subscriptions.ts`; `apps/web/src/lib/print.ts`; `apps/web/src/pages/superadmin/subscriptions/` (`SubscriptionsOverviewPage`, `PlansPage`, `PlanEditorPage`, `PlanDetailPage`, `SubscribersPage`, `SubscriberDetailPage`, `SubscriptionActions`, `InvoiceDialog`, `subscriptionMeta` + its test, `Subscriptions.module.css`).
- Changed: `packages/domain/src/index.ts`; `services/contracts.ts`, `services/mock/mockServices.ts`, `services/http/httpServices.ts`; `app/router.tsx`; `shell/navigation.tsx` (a Subscriptions item with four children in the platform Operations group) and its test; `commands/registry.test.ts` (the command palette picks the new destination up on its own); `components/overlays/Overlay.tsx` and `styles/base.css` (printing one dialog); `docs/01-PROJECT-ARCHITECTURE.md`.

**States.** Loading skeletons on the KPI band, every table, the charts and both detail pages; empty (no plans, no subscribers, no payment history, no plan has a subscriber, nothing sold yet); nothing matching the filters, with a way to clear them; error with Retry on every surface; plan and subscription not found. `?scenario=empty`, `?scenario=error` and `?scenario=slow` work here as everywhere else.

**Verification**
- `npm run typecheck`, `npm run lint` (0 warnings), `npm test` (239 tests: 54 domain, 185 web — 18 new domain rules, 24 new mock-service, 13 new formatting/masking), `npm run build`, `npm run format` — all pass.
- Browser (Chrome, headless) at 1440, 820 and 390: 20 routes each — the four tabs, both editors, three subscriber states (active, past due, trial), plan and subscription not found, four filtered views, and the empty and error scenarios. No console errors, no failed requests, no horizontal overflow at any width, exactly one page heading on every real page, and no unnamed control.
- Interactions exercised end to end: plan search / tabs / sort reaching the URL; archive with its consequence; duplicate landing in the editor on a draft copy; empty submit raising the error summary and taking focus; a duplicate plan code refused before saving; a valid plan saving and navigating; the leave guard; Unlimited replacing a limit rather than zeroing it; subscriber tabs, plan filter and pagination in the URL; the no-match state and Clear filters; pause → resume with the history written; change plan refusing the same plan, then showing the difference and applying; cancel requiring a reason, recording it, and being reversed by reactivate; the past-due and trial notices; the invoice sheet's totals and Escape; the failed tab and its totals; focus moving into a dialog and Escape returning; the mobile filter sheet; cards opening their record at 390px; and the sticky save bar staying in reach on a phone.
- Checked deliberately: no number long enough to be a card reaches the invoice sheet, and every payment method renders as a brand plus four digits (or as a mandate with no digits at all).

## In Progress
None

## Blocked
None

## Design Decisions
- Existing SyniastroLMS App Shell is the visual source of truth.
- Premium astrology education product feel.
- UI only with realistic mock data.
- Modules are completed sequentially according to dependencies.
- Learning states are shown with label, icon and node shape; tone only reinforces.
- Astrological geometry appears only as fine line: generated course covers, rank orbits, certificate seal.
- Learning components use container queries so they adapt inside panels, sheets and device frames.
- The brand mark keeps the shell's lowercase-initial pattern ("s", for SyniastroLMS).
- Courses are divided into chapters (the pack's term); the earlier "module" wording was renamed throughout, including the domain model.
- Management screens are shared by `/admin` (whole academy) and `/teach` (instructor scope) through `useWorkspace()`.
- Summaries are typographic figure bands with hairlines, not stat cards; charts show one measure in one hue with keyboard read-out and a table for assistive tech.
- Mock data is generated from a fixed seed so counts agree across screens; aggregates are computed from the same records.
- Student navigation has no Community area: nothing in the module pack specifies discussions, so the item was removed instead of shipping a placeholder. Add it back with its own module if the academy wants forums.
- Explore (the learner catalog) was built during the final audit because it was a navigation destination; enrolment itself stays on the course page.
- Settings, notification preferences and branding are stored and previewed but do not yet reconfigure other screens; wiring them up belongs with the backend.

## Known Issues / Limitations
- Demo clock is fixed at 15 Sep 2026, 6:52 PM IST, so live-class and due-date states are stable.
- Role switching ("View as") is a demo affordance until authentication exists.
- `VITE_API_MODE=http` is reserved; every mode uses mock services today.
- Mock data lives in memory: changes made in the UI last until the page is reloaded.
- No real email, text messages, uploads, video, meetings, payments or file generation — each is simulated in the UI and says so where it matters.
- Signing out shows the signed-out screen; there is no authentication, so Sign in again returns to the demo workspace via the new sign-in screen.
- Sign in and Create account do not check a real account: any well-formed email/password signs in, and Sign in's "Continue as" picker (not a real credential check) decides which workspace you land in. Forgot password validates the email but never sends one.
- **Subscriptions are a prototype, not billing.** No gateway, no recurring charge, no refund, no invoice document, no tenant isolation. A plan's limits and features are configuration that is stored and shown; nothing in the academy is gated by them, and no subscription state changes what a learner, instructor or academy admin can reach. Download writes a CSV of the line items rather than a PDF.
- **The subscription service is the same in both API modes.** Unlike every other screen, there is no `/subscriptions` endpoint to talk to, so `httpServices` deliberately serves the same in-memory records as mock mode rather than showing an empty page. Every subscription screen says so in a standing note.
- **Reaching the platform workspace in the demo build.** The mock build ships three academy personas and no Super Admin, so `/superadmin/...` has no navigation entry there and is opened by typing the address; it then renders inside whichever persona's shell is active. In `http` mode it is reached normally, by signing in as a super admin. This is how the rest of the platform workspace already behaves — subscriptions did not change it.
- A record that no longer exists (a deleted plan, an unknown subscription) shows the area's error state with a way back rather than a page heading, matching every other detail page in the application.
- The public course catalog (`/courses`) reuses the signed-in Explore page, so it still shows the demo learner's own progress ("Continue", "38% done") on courses that persona is enrolled in — there is no separate anonymous-visitor data set, consistent with every other mock-data screen.

## Post-Audit Fixes
- **Design System hidden from navigation** (16 Sep 2026): removed the internal Design System group from all three sidebars and from the header's help dialog, so it doesn't surface during a client walkthrough. `/design-system` itself is untouched.
- **Courses, Verify and Help Centre made public** (16 Sep 2026): the marketing site's Courses, Verify a certificate and Help Centre links used to open the same in-app routes as the signed-in workspace, dropping a visitor straight into the app shell (sidebar, account menu) as if they were already signed in. Added public top-level routes — `/courses` (reuses the Explore catalog), `/verify` (moved out of the app shell; it was always meant for anyone with a credential ID) and `/support` (reuses the Help Centre pages, with `useHelpBase()` taught to recognise the new prefix) — each wrapped in the marketing site's header/footer instead of the sidebar. The in-app `/explore`, `/help` and `/teach|admin/help` used by signed-in navigation are unchanged. The two internal "open the verification page" links (learner's own certificate, admin's certificate detail) now open in a new tab, since `/verify` no longer keeps the viewer inside the app shell.

## Second Final Audit
Run 21 Sep 2026, after LMS-019 — the last module — completed the pack. Every route in the application, in all four workspaces, at 1440px and 390px.

**What was checked.** Console errors, failed requests, horizontal overflow, page-heading count, controls with no accessible name, and whether any address quietly resolved to the not-found page — across 62 routes × 2 widths × 4 role groups. Then every internal link those pages carried was opened once. Alongside it: typecheck, lint, tests, production build, formatting, a sweep for TODOs and unfinished placeholders, and a check for components sharing a name.

**Found and fixed**

- **The academy admin workspace was unreachable in the demo build.** The permission layer added with the Super Admin workspace reads `user.permissions`, and the demo `admin` persona carried none — so `/admin` and 18 pages under it showed “You don’t have access to this” and the sidebar lost most of its groups. The demo build has no permission store behind it and this persona exists to show that workspace, so she now holds the whole catalogue (`personas.admin.permissions = PERMISSION_KEYS`). A real installation still grants keys one at a time from the platform workspace.
- **Password fields had no accessible name.** `Field` takes its `htmlFor` from the id of the element it is given, but sign in, create account, reset password and the platform's admin dialogs wrap the input in a row so a visibility toggle can sit beside it — so the label pointed at a wrapper that had no id, and the input was left unnamed. `Field` now looks one level in for the control's id and stops stamping a duplicate id on the wrapper. Five screens gained a correctly labelled password field, and nothing else changed.
- **The public catalog overflowed on a phone.** `/courses` was 510px wide inside a 390px viewport. The marketing chrome lays its pages out in a flex column, and the app's page containers centre themselves with `margin: 0 auto` — an auto cross-axis margin cancels a flex item's stretch, so the catalog shrank to fit its own content and pushed the site sideways. `.main > *` now fills the line, which is how the same page already behaved inside the app shell's block-level main; each page's own `max-width` still caps and centres it on a wide screen.
- **Two different components were both called `CategoryGlyph`** — the course-category line art in `components/lms/course/` and the help-centre icon chip in `pages/help/helpMeta.tsx`. The help one is now `HelpCategoryGlyph`.
- **Two stale comments** claimed destinations resolve to “a placeholder naming the module that builds them” (`router.tsx`) — untrue since the first final audit.

**Result**

- typecheck, lint (0 warnings), 239 tests (54 domain, 185 web), production build, `format:check` — all pass.
- Crawl: 0 problems. No console errors, no failed requests, no horizontal overflow at 390px, exactly one page heading per page, no unnamed control, and no address resolving to the not-found page where one was not expected.
- 524 distinct internal link destinations discovered across the four workspaces and opened.
- No TODO, FIXME or “coming soon” anywhere in `apps/web/src` or `packages/domain/src`, and no two exported components sharing a name.

**Left alone deliberately.** A record that no longer exists (a deleted plan, an unknown subscription, a missing certificate) shows the area's error state with a way back rather than a page heading. That is how every detail page in the application has always behaved, so it was left consistent rather than changed in one module.

## Last Verification
15 Sep 2026 — Final audit: typecheck, lint, 112 tests, build, formatting, 54-route crawl at 1440 and 390, and internal link check all passing.
15 Sep 2026 — Post-audit additions (LMS-017, LMS-018): typecheck, lint, 112 tests, build, formatting — pass; landing/login/register/privacy/terms and the Help Centre hub/category/article pages reviewed in-browser at 1440 (landing/login/register also at 390) with no console errors; login and register interaction-tested end to end; link crawl from the new pages found and confirmed 9 working destinations.
16 Sep 2026 — Post-audit fixes (Design System hidden, public Courses/Verify/Help Centre): typecheck, lint, 81+31 tests, build, formatting — pass; `/courses`, `/verify` (including a real credential ID), `/support` and its category/article pages reviewed in-browser with no console errors and no app-shell sidebar; confirmed the in-app `/explore` still renders inside the shell unchanged for signed-in navigation.
21 Sep 2026 — LMS-019 (Subscription & Plan Management): typecheck, lint, 239 tests (54 domain, 185 web), build and formatting all pass; 20 subscription routes reviewed in Chrome at 1440, 820 and 390 with no console errors, no horizontal overflow and no unnamed controls; 23 interaction flows (plan create/edit/duplicate/archive, change plan, pause, resume, cancel, reactivate, invoice sheet, filters, pagination, leave guard, mobile filter sheet and cards) exercised end to end.
21 Sep 2026 — Second final audit, after LMS-019: typecheck, lint, 239 tests, build and formatting pass; 62 routes across all four workspaces crawled at 1440 and 390 with zero problems; 524 internal link destinations opened; the admin-permission, password-label, catalog-overflow and duplicate-name findings fixed and re-verified.
