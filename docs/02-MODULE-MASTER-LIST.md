# 02 — Module Master List

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

Modules are derived from what the application actually contains: the `Services` interface in
`apps/web/src/services/contracts.ts` (22 service groups the UI calls), the routes in
`apps/web/src/app/router.tsx`, the Prisma schema in `apps/api/prisma/schema.prisma`, and the API routers
in `apps/api/src/routes/`. Each module has a detail file in `docs/modules/`.

## Completion checklist (applies to every module)

**Database** — schema, migration, relationships, indexes/constraints. **Backend** — models, services/route
handlers, validation, authorization, business rules. **API** — CRUD, search, filtering, sorting,
pagination, special actions (where applicable). **Frontend** — the existing UI connected through the
`http` service implementation, mock data replaced, loading/error/empty states working. **Testing** —
API tests incl. permission, validation and error cases.

## Modules

| Module | Purpose | UI screens | Roles | Depends on | Doc |
| --- | --- | --- | --- | --- | --- |
| Authentication | Accounts, sign in/up, password reset, session | `/login`, `/register`, forgot-password modal, sign-out, profile dialog | all | Foundation | `modules/authentication.md` |
| Roles & permissions | Who may do what; instructor scoping; learner ownership | (cross-cutting) | all | Authentication | `04-AUTHENTICATION-AUTHORIZATION.md` |
| Students | Learner roster and profiles for staff | `/admin/students`, `/teach/students`, `/:base/students/:id` (+ courses, progress, activity tabs) | admin, instructor | Auth, Enrollments | `modules/students.md` |
| Instructors | Teaching staff management | `/admin/instructors`, `/new`, `/:id/edit`, `/:id` (+ courses, performance) | admin (instructor read) | Auth | `modules/instructors.md` |
| Categories | Course taxonomy | `/admin/categories` (+ panels) | admin | — | `modules/categories.md` |
| Courses | Course lifecycle | `/:base/courses`, `/new`, `/:id/edit`, `/:id`, `/:id/preview` | admin, instructor | Categories, Instructors | `modules/courses.md` |
| Curriculum | Chapters inside a course | `/:base/courses/:id/curriculum`, chapter panels, `/chapters/:id` | admin, instructor | Courses | `modules/curriculum.md` |
| Lessons & media | Lessons of every type, uploads | `/:base/courses/:id/lessons`, lesson editor (content/settings/preview) | admin, instructor | Curriculum | `modules/lessons.md` |
| Enrollments | Who is in which course, status, source, access | student Courses tab, enroll dialog, learner Enroll, Explore | admin, instructor, student | Courses, Students | `modules/enrollments.md` |
| Learning progress | The learner's experience | `/home`, `/my-learning/*`, `/explore`, `/learn/:courseId`, lesson player, `/assignments`, `/assessments` | student | Enrollments, Lessons | `modules/progress.md` |
| Quizzes | Quiz authoring and attempts | `/:base/quizzes`, builder (questions/settings/preview/results) | admin, instructor (student attempts) | Lessons | `modules/quizzes.md` |
| Assignments | Authoring, submissions, review | `/:base/assignments`, review queue, editor, submissions, review page; learner hand-in | admin, instructor, student | Lessons, Enrollments | `modules/assignments.md` |
| Certificates | Templates, issuing, verification | `/admin/certificates`, templates, editor; `/certificates` (learner); `/verify` | admin, instructor, student, public | Progress | `modules/certificates.md` |
| Live classes | Scheduling and attending live sessions | `/:base/live`, editor, detail; `/live`, `/live/:id` | admin, instructor, student | Courses | `modules/live-classes.md` |
| Calendar | Unified schedule and reminders | `/:base/calendar`, event panel, event editor | admin, instructor | Live, Assignments, Quizzes | `modules/calendar.md` |
| Notifications | In-app notifications and preferences | `/notifications`, `/:id`, `/preferences` (all three roles), header bell | all | Foundation | `modules/notifications.md` |
| Settings | Academy-wide settings | `/admin/settings/*` (six sections) | admin | — | `modules/settings.md` |
| Reports | Analytics | `/admin/reports/*` (overview, courses, course, learners, instructors, enrolments) | admin, instructor | everything | `modules/reports.md` |
| Dashboard | Landing overview for staff | `/admin`, `/teach` | admin, instructor | everything | `modules/dashboard.md` |
| Help centre | Knowledge base | `/help`, `/support` (+ category, article) | all, public | — | `modules/help-centre.md` |
| Self-registration & invitations *(Oct 2026)* | Admin sign-up with an emailed code; learner join links, invitations and course links; instructor requests; a `PendingAccount` until the code is confirmed | `/get-started`, `/join`, `/join/:slug`, `/join/:slug/teach`, `/invite/:token`, `/courses/:courseId/enroll`, admin "Add student" and invitations | public, admin | Auth, Students, Instructors | `04-AUTHENTICATION-AUTHORIZATION.md` › Registration doors; `05-API-SPECIFICATION.md` (`/signup`, `/public`, `/invitations`) |
| Course sales *(24 Oct 2026)* | A learner buys a paid course; the money settles to the academy's own Razorpay account; the enrolment opens on the gateway's confirmation | `/courses/:courseId/enroll`, `/purchases`; the academy's payment settings | student, admin | Courses, Enrollments, Payment gateways | `05-API-SPECIFICATION.md` › Course sales; `03-DATABASE-SPECIFICATION.md` › Course sales |
| Live room *(15 Oct 2026)* | Built-in video room (Jitsi Meet or 8x8 JaaS): host starts and ends, learners join with signed tokens, attendance settles, recordings kept | live class detail, `/live/:id` | admin, instructor, student | Live classes | `modules/live-classes.md` › Built-in live room |
| Quiz sessions *(14 Oct 2026)* | Server-held timed attempts: start consumes an attempt, the deadline is the server's, the sheet is saved as the learner goes, expiry is scored by a job | lesson player (quiz) | student | Quizzes, Learning progress | `modules/quizzes.md` › Quiz sessions; `05-API-SPECIFICATION.md` › Learning |
| Subscriptions & billing (SaaS) | Tenants, plans, entitlements, usage limits, subscriptions, invoices, payments, refunds, gateways | `/admin/billing`, `/admin/welcome`, `/superadmin/subscriptions/*`, `/superadmin/payment-gateways` | admin, superadmin | everything | `.claude/saas/subscriptions.md`, `05-API-SPECIFICATION.md` › Billing, `11-SUPERADMIN-FLOW.md` |
| Platform (Super Admin) | Admins (clients) and academies, admin users and permissions, users, audit, observability, system and job leases, branding, inquiries | `/superadmin/*` | superadmin | — | `11-SUPERADMIN-FLOW.md`, `05-API-SPECIFICATION.md` |
| Website & support | The company site and pricing, contact sales, academy support requests | `/`, `/features`, `/solutions`, `/pricing`, `/how-it-works`, `/about`, `/faq`, `/contact`, `/privacy`, `/terms`, `/refunds`, `/admin/support` | public, admin | — | `.claude/saas/progress.md` (SAAS-027, SAAS-029) |

## Explicitly not part of this project

Checked against the UI, the domain package and the routes — none of these exist anywhere in the
application, so no backend is built for them and no module file is created:

- **Coupons, carts and discount codes** — there are none. Money moves in exactly two places: an academy pays
  the platform for its plan (SaaS billing, `/tenant/billing/*`, SAAS-008/009) and, since 24 Oct 2026, a learner
  pays an academy for one paid course (course sales, `POST /learning/courses/:courseId/purchase`). Both are
  single-invoice or single-order checkouts through the gateway abstraction, and refunds are manual. Free
  enrolment (self, admin, cohort, scholarship, invitation) remains the default; a course with no admin-chosen
  price is not for sale.
- **Course reviews / ratings submission** — `rating` / `ratingCount` are display aggregates on a course;
  there is no review form. "Reviews" in this product means assignment *reviews* (grading).
- **Standalone user management** — accounts come from the Students, Instructors, Super Admin (academies and
  admins) and self-registration flows. There is no generic user CRUD; the Super Admin's `GET /superadmin/users`
  is a read-only list, and `POST /auth/delete-account` lets a person delete their own account.

## Module dependency graph

```
Foundation ─► Authentication ─► Roles & permissions
                                   ├─► Instructors ─┐
                                   ├─► Categories ──┼─► Courses ─► Curriculum ─► Lessons & media
                                   └─► Students ────┘                                │
                                                     Enrollments ◄───────────────────┘
                                                        │
                                                        ▼
                                                 Learning progress ─► Quizzes / Assignments / Certificates / Live
                                                                              │
                                                                              ▼
                                            Calendar ─► Notifications ─► Settings (enforced) ─► Reports ─► Dashboard
```
