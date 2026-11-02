# UI redesign — screen checklist

Every route, screen, sheet and dialog in `apps/mobile`, and where each stands in the mobile redesign
(tokens in `lib/core/theme/tokens.dart`, the shared `CommonAppBar`, the 90 % white page).

- **Code**: `done` means the screen has had its own pass. Legacy sizes, headings, hand-rolled containers
  and spacing were replaced by the shared system: header cards, item cards, fact strips, KPI tiles,
  filled fields and token sizes.
- **Device**: what was actually seen on the USB Infinix X6525 (360 × 806 dp). Captured with
  `tool/ui_tour/run.sh` (a `flutter drive` tour that opens each screen with real seeded data from a
  scratch API and screenshots it), plus manual checks. L = light, D = dark, 1.3 = 130 % text. Blank
  means it was not seen on the phone.

Roles: **S** student · **I** instructor · **A** academy admin · **P** public (signed out).

## Staff redesign (2026-10-22)

The instructor and admin screens were brought to the learner app's look, calmer: hue only on icon tiles
and card strips, plain cards, no gradients.

- **Navigation.** Both shells follow the learner's order: Home · Courses · Live · Review · More for an
  instructor, and Home · Courses · People · Live · More for an admin, whose Review heads More. More is
  grouped under Teaching, Academy and Account. The first tab always stays in the bar, and its page explains
  missing grants. Staff forms name themselves in the app bar ("Schedule a class", "Edit the instructor").
- **Shared pieces.**
  - `ListToolbar`, `FiltersButton` and `showFilterSheet`: search, a Filters button counting the filters
    that are on, and the view chips. Secondary selects such as sort, course or instructor live in the sheet.
  - `PagerRow`.
  - `StripCard`: the learner live card's tinted strip, used for list items.
  - `StatSummaryCard`: up to three tappable headline figures.
  - `QuickActionTile(hue:)`.
- **Dashboard.**
  - It leads with three figures: review queue, classes ahead and learners for an instructor; learners,
    courses and classes ahead for the academy view.
  - Then the next live class, "Needs you" as one list, quick actions, the top three courses, the figures,
    and recent activity.
  - The enrolment and completion trend charts are shown in the academy view only.
- **Lists:** courses, live, calendar, review, assignment submissions, students, quizzes, instructors,
  certificates and the learners report.
- **Detail pages and forms:** course, curriculum, lesson, class, event, submission, student, quiz,
  instructor, certificate and invoice. Each has a strip or header card and hued section headers. The
  forms are grouped into sections.

All of this is presentation only. Device: Infinix X6525 tours (`tool/ui_tour`, push-installed, see below):
I L 79 shots, A L 81, A D 81, and S L 64 as a regression check. No layout problems on any staff stop. The
tour now also opens the More sheet (`more-sheet`), and prints the app's own stack frames for any problem.

Found and fixed on the way:
- The calendar's type chips painted under its Filters button.
- A video lesson's last position was lost on leaving the lesson. The player's dispose reported it through
  a widget ref that was already gone.
- The assignment submissions list could not leave its first page.

Not on the phone: 200 % text, which widget tests cover for each list, and the instructor's review rows,
because the scratch data has no submissions.

## App frame and shared states

| Screen / state | Route or file | Roles | Code | Device |
| --- | --- | --- | --- | --- |
| Role shell (app bar, bottom bar, More sheet, rail) | `app/routing/shells/app_shell.dart` | S I A | done | S I A · L D 1.3 · landscape (rail) |
| Home header (avatar, greeting, descriptor) | shell, first tab | S I A | done | S I A · L D 1.3 |
| Offline banner, plan banner | `shared/widgets/states`, `shared/entitlements` | S I A | done | A plan banner · L |
| Loading skeletons, empty, error, not-found, permission, feature-off | `shared/widgets/states` | all | done | error state (privacy, see note 2) · L |
| Plan gate (module not in plan) | `staff_billing/.../plan_gate_screen.dart` | I A | done | A L D (scratch API with plan enforcement on) |
| Config error app | `app/config_error_app.dart` | — | done | not seen: needs a broken build config (covered by tests) |
| Coming soon / not found screens | `app_shell.dart` | all | done | not found S L |

## Authentication and public

| Screen | Route | Roles | Code | Device |
| --- | --- | --- | --- | --- |
| Splash | `/splash` | P | done | seen briefly at launch |
| Welcome (onboarding) | `/welcome` | P | done | L D 1.3 |
| Sign in (incl. error banner, keyboard open) | `/login` | P | done | L D 1.3 · error + keyboard (manual) |
| Account type | `/register` | P | done | L (manual) |
| Learner registration | `/register?…` | P | done | L D 1.3 |
| Academy sign-up + email verification code | `/register` (academy) | P | done | type chooser, form, filled form, code step · L |
| Instructor sign-up | `/register` (instructor) | P | done | form L (manual); success screen not seen |
| Forgot password | `/forgot-password` | P | done | L D 1.3 |
| Reset password | `/reset-password/:token` | P | done | L (real emailed token from the scratch outbox) |
| Invitation | `/invite/:token` | P | done | L (real invitation token) |
| Course enrolment link | `/enrol/:courseId` | P S | done | L (signed out) |
| Unsupported role | `/unsupported-role` | superadmin | done | L (the seeded Super Admin) |
| Public catalogue | `/catalog` | P | done | L D |
| Public course detail | `/catalog/:slug` | P | done | L D |
| Free preview lesson | `/catalog/:slug/preview/:lessonId` | P | done | L (empty state: the seed attaches no video file) |
| Verify a certificate (form) | `/verify` | P | done | L D |
| Verify result | `/verify/:id` | P | done | L |
| Help hub, category, article | `/help…` | P S I A | done | L D |
| Privacy, terms | `/legal/*` | all | done | L (privacy, served by a local web build) |

## Learner

| Screen | Route | Code | Device |
| --- | --- | --- | --- |
| Home | `/home` | done | L D 1.3 |
| My learning (in progress, completed, saved) | `/my-learning/:tab` | done | L D 1.3 |
| Explore | `/explore` | done | L D 1.3 |
| Course overview | `/learn/:courseId` | done | L D |
| Lesson player — reading lesson | `/learn/:c/lessons/:l` | done | L D |
| Lesson player — video, practice, quiz, assignment lessons | same | done | L (video shows its empty state: no file in the seed) |
| Lesson player — PDF/document and live lessons | same | done | not seen: the seed has no lesson of either type ⁵ |
| Quiz taker | `assessments/.../quiz_taker.dart` | done | L (an attempt on the scratch API) |
| Assignments, assignment detail | `/assignments…` | done | L D 1.3 |
| Assessments | `/assessments` | done | L D (nothing open to start in the seed) |
| Live classes, live class detail | `/live…` | done | L D 1.3 |
| Certificates, certificate detail | `/certificates…` | done | L D 1.3 |
| Rank ladder | `/ranks` | done | L D |
| Notifications, detail, preferences | `/notifications…` | done | L D |
| Profile | `/profile` | done | L D 1.3 |
| App settings | `/profile/settings` | done | L D |
| Delete account | `/profile/delete-account` | done | L D |
| Video player, PDF viewer | `features/media` | done | not seen: the seed attaches no video or document file ⁵ |

## Instructor and academy admin

| Screen | Route | Roles | Code | Device |
| --- | --- | --- | --- | --- |
| Dashboard (hero, attention, shortcuts, KPIs, trends) | `/staff` | I A | done | I L D · A L D 1.3 |
| Get started (choose plan / trial) | `/staff/get-started` | A | done | A L (and as the restricted admin's landing page) |
| Courses list, course detail | `/staff/courses…` | I A | done | I L · A L D |
| Curriculum, staff lesson view | `/staff/courses/:id/…` | I A | done | I D · A L |
| Review queue, submission review | `/staff/review`, `/staff/submissions/:id` | I A | done | I L · A L D |
| Assignment submissions list | `/staff/assignments/:id/submissions` | I A | done | I D · A L |
| Quizzes, quiz detail | `/staff/quizzes…` | I A | done | I L · A L D |
| Students / people, student detail | `/staff/students…` | I A | done | I L · A L D |
| Message sheet | `staff_students/.../message_sheet.dart` | I A | done | A L 1.3 (selection bar fixed) |
| Live classes, class detail, new form | `/staff/live…` | I A | done | I L D · A L D 1.3 |
| Live edit form | `/staff/live/:id/edit` | I A | done | A L 1.3 |
| Calendar, new form | `/staff/calendar…` | I A | done | I L · A L D |
| Calendar event detail, edit form | `/staff/calendar/:id…` | I A | done | A L 1.3 (an event created on the scratch API) |
| Instructors, instructor detail, invite form | `/staff/instructors…` | A (I view) | done | I L · A L D |
| Instructor edit form | `/staff/instructors/:id/edit` | A | done | A L 1.3 |
| Certificates register, certificate detail | `/staff/certificates…` | I A | done | I L · A L D |
| Reports overview, courses, course, learners, instructors, enrolments | `/staff/reports…` | I A | done | I L · A L D |
| Billing, plans | `/staff/billing…` | A | done ¹ | L D |
| Invoice, plan change / checkout sheets | `/staff/billing/invoices/:id`, sheets | A | done ¹ | invoice not-found state L (the seed has no invoices); sheets not seen ¹ |
| Notifications, preferences | `/staff/notifications…` | I A | done | L D |
| Profile, settings | `/staff/profile…` | I A | done | L D |
| Help | `/staff/help` | I A | done | L D |

## Dialogs and sheets

| Where | File | Code | Device |
| --- | --- | --- | --- |
| Shared dialog, bottom sheet, select sheet, filter sheet | `shared/widgets/overlays`, `inputs/app_select_sheet.dart` | done | More sheet L |
| Sign out, staff deletion, about | `profile_screen.dart` | done | sign-out dialog S L |
| Live reminders, notification actions | `live_screen.dart`, `notifications_screen.dart` | done | notification menu S L; live reminders not opened |
| Lesson player sheets (curriculum) | `lesson_player_screen.dart` | done | L |
| Assignment submit confirm | `assignment_detail_screen.dart` | done | not reachable: the seeded assignments are already handed in or past their window |
| Staff course, student, live, certificate, report sheets | staff features | done | unpublish, cancel-class, suspend dialogs and report filters A L |
| Billing sheets | `checkout_parts.dart`, `billing_screen.dart` | done ¹ | not opened: online payment is off on the scratch API, so no plan change can start |

## Notes

1. `billing_screen.dart`, `checkout_parts.dart` and `staff_billing_screen_test.dart` hold another
   session's uncommitted billing fix and were not edited by the redesign. They take the new design
   through the shared plan cards, header cards and sheets they use.
2. Privacy and terms render the website's own policy pages; the tour served them from a local web
   build (port 5173 through adb reverse). Without it the phone shows the redesigned error state.
3. Reached through the tour with a real academy sign-up on the scratch API.
4. Real tokens were taken from the scratch API's mail outbox.
5. Not reachable with the seeded data; the shared lesson widgets they use are covered by widget tests.
6. Sign-in error banner also seen through the tour (`login-error`), as well as by hand.

## States checked on the phone

Loading (skeletons during tours) · empty ("Nothing on this day", saved list) · error (sign-in refusal,
privacy) · long content (scrolled ends of every toured page) · keyboard open (sign in) · 360 dp width ·
landscape (shell and rail) · 130 % text (learner and auth) · dark mode (public, student, admin).
Fixed from these checks: the people list's selection bar (full width), KPI labels breaking mid-word at
130 % (icon now above the label), sub-page app bar titles, the invite form opening in red, value lists
centred in cards. Not on the phone: disabled-only states beyond forms, 200 % text (covered by widget tests), landscape
beyond the shell.
