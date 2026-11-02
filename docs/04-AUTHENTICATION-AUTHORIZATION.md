# 04 — Authentication & Authorization

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

**Current rules:** `superadmin` passes `requireRole` and `requirePermission`, and `requireSuperAdmin` has no bypass. `admin` is staff limited by the 24-key catalogue. An account of an archived workspace gets 403 `WORKSPACE_CLOSED` at login, after the password check, and on every route. Learners register at `POST /public/register` with a mobile number and an emailed code. Instructors apply at `POST /public/instructor-applications` and sign in after approval.

## Authentication (current implementation)

- **Accounts:** `User` rows with `bcryptjs` password hashes (cost 10). Public registration always creates
  a `student` with a `Student` profile; instructor accounts are created when an admin invites an
  instructor; the admin account comes from the seed.
- **Tokens:** JWT (`jsonwebtoken`, HS256) signed with `JWT_SECRET`, expiring after `JWT_EXPIRES_IN`
  (default 7d). Payload: `{ sub: userId, role, studentId?, instructorId?, tenantId?, sid }`.
- **Sessions (SAAS-020):** `sid` names a `UserSession` row created at sign-in; the per-request account read
  checks it, so `POST /auth/logout`, `logout-all`, `DELETE /auth/sessions/:id`, a password change and a
  password reset end tokens immediately. Tokens from before sessions (no `sid`) are ended by
  `User.tokensValidAfter`. No refresh tokens; long-expired sessions are pruned by the scheduler after 30 days.
- **Transport:** `Authorization: Bearer <token>`. `attachAuth` middleware decodes it into `req.auth` on
  every request (invalid/expired tokens are ignored — the request continues anonymous); `requireAuth`
  rejects with 401; `requireRole(...roles)` rejects with 403 (admins pass every `requireRole`).
- **Endpoints:** `POST /auth/register`, `POST /auth/login`, `GET /auth/me` (see `05-API-SPECIFICATION.md`).
- **Frontend:** `apps/web/src/services/http/auth.ts` stores the token in `localStorage`
  (`syniastrolms:token`); `SessionProvider` (http mode) calls `/auth/me` on load, exposes
  `login`/`register`/`logout`, `isAuthenticated`, `authLoading`. The mock mode keeps the demo persona
  switcher.

### Gaps (to be closed in F1)

| Gap | Fix |
| --- | --- |
| ~~Forgot-password modal only shows a toast~~ | Done in F1: `POST /auth/forgot-password` stores a SHA-256-hashed, single-use, 1-hour `PasswordResetToken` (older links invalidated) and queues the email; `GET /auth/reset-password/:token` reports validity; `POST /auth/reset-password` consumes it; `/reset-password/:token` page completes the flow |
| ~~A 401 from the API is reported as a generic "conflict"~~ | Done in F1: the HTTP client clears the token and fires `syniastrolms:unauthorized`; the session provider drops to signed-out and the guard sends the visitor to `/login?next=` |
| ~~Unauthenticated visitors can render shell routes~~ | Done in F1: `RequireSession` (in `app/router.tsx`, wraps `AppShell`) redirects to `/login?next=` in http mode; non-admins on `/admin/*`, students on `/teach/*` and staff on learner routes are sent to their own home |
| ~~`JWT_SECRET` may be left at its dev default in production~~ | Done in F1: `assertProductionSecrets()` at boot refuses the dev default, an empty value or fewer than 32 characters |
| ~~Login/register have no rate limiting~~ | Done in F0: `express-rate-limit` on `/auth/*` (`RATE_LIMIT_AUTH_MAX`, default 30 per 15 min) plus a global limiter |
| ~~Public registration accepted a `role` from the body~~ | Done in F0: registration always creates a learner; the body is parsed with a strict schema |

## Tenant context (SAAS-000)

A person belongs to one academy (`User.tenantId`), except a super admin, who belongs to none; email
is unique across the platform, so sign-in needs no academy picker. At sign-in the token gains a
`tenantId` claim, but it is only a claim: `lib/requestContext.ts` reads the account's own row on every
request and runs the rest of the request for that academy. A token naming no account, a different
role or a stale academy is treated as no session (401). Visitors who are not signed in run for the
academy `DEFAULT_TENANT_SLUG` names. The Super Admin router alone runs across every academy, after
`requireSuperAdmin`. `requireRole` is unchanged, and the order is fixed: authenticated → role/permission
→ tenant → entitlement → operation.

The same per-request read enforces two states (QA pass and SAAS-019):
- **Closed accounts.** A deactivated admin, an inactive instructor or a suspended learner keeps its
  identity but every guard (`requireAuth`, `requireRole`, `requireSuperAdmin`, `requirePermission`)
  refuses it with 403 and the message sign-in uses — on the token it already holds.
- **Closed academies.** When the account's academy is `suspended` or `archived`, every request is
  refused with 403 `ACADEMY_SUSPENDED` / `ACADEMY_ARCHIVED`, and so is sign-in (after the password
  check, so the state is told only to members). The academy's data is untouched; notification jobs
  skip it; a suspended academy's subscription keeps its billing lifecycle.

## Entitlement (SAAS-003)

What an academy's plan allows is a separate layer after authorization, never a replacement for it (subscriptions.md
§33, §41). A route composes `requireAuth, requireRole(…), requirePermission(…), requireFeature(feature)`:
- A caller without the permission is refused `403 PERMISSION_DENIED` before the plan is consulted.
- A caller whose academy's plan lacks the feature is refused `403 FEATURE_NOT_INCLUDED`, or `402
  SUBSCRIPTION_REQUIRED` when the academy is on no plan.

This holds for instructors too: they pass permissions on their role, but the academy's plan still applies to them.

`src/lib/entitlements.ts` is the only reader of plan data. An ESLint rule keeps route files away from the plan
and subscription tables. Enforcement is off unless `ENTITLEMENT_ENFORCEMENT=on`.

Which routes are gated is in `docs/06-BUSINESS-RULES.md` › Enforcement matrix. Gates govern **adding and
changing**. They never block an academy withdrawing its own content (unpublish, archive, delete, revoke) or
serving the learners it has (registration, hand-ins, grading, reminders). The dashboard is never gated.

**The full order, with enforcement on (SAAS-025):** authentication → tenant (the account's academy, and its
status) → role → permission → subscription and entitlement (`requireFeature`, or `requireUnrestricted` where no
feature governs the route) → usage limit (`withinLimit`, in the write's own transaction) → operation.
- **A plan never grants or restores a permission, and a permission never bypasses a plan.** Buying a plan writes
  no `AdminPermission` row; a revoked key stays revoked through a purchase (`accessControl.test.ts`).
- **Subscription states:** `trialing`, `active`, `past_due` (grace included) and `canceling` are served their
  plan; `paused` answers `402 SUBSCRIPTION_REQUIRED`; `expired` and `canceled` answer `402 SUBSCRIPTION_EXPIRED`;
  no subscription answers `402 SUBSCRIPTION_REQUIRED`.
- **Restricted mode** (served no plan) keeps what the academy had and adds nothing: an operation the policy keeps
  open — reading, editing, withdrawing, serving learners — goes ahead on a feature-gated route only if the
  academy's **last plan included that feature**. An academy that never subscribed keeps every ungated read, edit
  and learner path, but no plan feature — so it is never more privileged than the lowest paid tier.
- **Categories** are catalogue structure in no plan feature: permission alone, plus restricted mode (a new
  category is refused without a plan; editing and deleting stay open).
- **Instructors:** leaving `inactive` takes a seat (`instructors.max`), through the status route or an edit, under
  the same transactional guard as adding one.
- **Features not gated by a route:** `analytics.advanced` is `planned` (sold, not built) and `priority_support` is a
  `service` level. `Feature.enforcement` and `/tenant/billing` › `features[].enforcement` say so.

## Roles

| Role | Description | Workspace |
| --- | --- | --- |
| `student` | A learner | `/home` and the learner routes |
| `instructor` | Teaches courses; sees only their own courses, learners, submissions, live classes, calendar and reports | `/teach` |
| `admin` | Runs the academy; everything | `/admin` |

## Permission matrix

✅ allowed · 🔒 allowed only within own scope (instructor: courses they teach; student: own records) · ✗ denied · 🌐 public

| Operation | student | instructor | admin | public |
| --- | --- | --- | --- | --- |
| Register / login / me | ✅ | ✅ | ✅ | 🌐 (register, login) |
| Browse catalog (`/catalog/*`) | ✅ | ✅ | ✅ | 🌐 |
| Verify a certificate | ✅ | ✅ | ✅ | 🌐 |
| Help centre | ✅ | ✅ | ✅ | 🌐 |
| Dashboard snapshot | ✗ | 🔒 | ✅ | ✗ |
| Courses list/create/update/publish/archive | ✗ | 🔒 | ✅ | ✗ |
| Categories create/update/delete | ✗ | ✗ | ✅ | ✗ |
| Chapters / lessons manage | ✗ | 🔒 | ✅ | ✗ |
| Media upload | ✗ | ✅ | ✅ | ✗ |
| Quizzes / assignments manage | ✗ | 🔒 | ✅ | ✗ |
| Submissions review | ✗ | 🔒 | ✅ | ✗ |
| Students list/profile/progress/activity | ✗ | 🔒 (own learners) | ✅ | ✗ |
| Student enroll / pause / remove enrollment | ✗ | 🔒 | ✅ | ✗ |
| Student suspend / restore | ✗ | ✗ | ✅ | ✗ |
| Instructors list/profile | ✗ | ✅ (read) | ✅ | ✗ |
| Instructors create/update/status/invite | ✗ | ✗ | ✅ | ✗ |
| Certificates list/detail/issue | ✗ | 🔒 | ✅ | ✗ |
| Certificates revoke/restore, templates | ✗ | ✗ | ✅ | ✗ |
| Live classes manage | ✗ | 🔒 | ✅ | ✗ |
| Live classes learner view / register | 🔒 | ✗ | ✗ | ✗ |
| Calendar list/detail | ✗ | 🔒 | ✅ | ✗ |
| Calendar create/update/delete | ✗ | 🔒 (own reminders, own courses) | ✅ | ✗ |
| Learning (home, courses, lessons, notes, bookmarks, enroll, assignments, assessments, certificates) | 🔒 | ✗ | ✗ | ✗ |
| Notifications (own) | 🔒 | 🔒 | 🔒 | ✗ |
| Notification settings (own) | 🔒 | 🔒 | 🔒 | ✗ |
| Reports | ✗ | 🔒 (instructors report: ✗) | ✅ | ✗ |
| Settings read | ✅ | ✅ | ✅ | ✗ |
| Settings save | ✗ | ✗ | ✅ | ✗ |

### How scope is enforced (target — F2)

- **Instructor scope is derived server-side** from `req.auth.instructorId`. Any `scopeInstructorId`
  supplied by the client is ignored for instructors and only honoured for admins (who may look at any
  instructor's slice). Routes: courses, chapters, lessons, quizzes, assignments, submissions, students,
  live, calendar, certificates, reports, dashboard.
- **Learner ownership** uses `req.auth.studentId`/`req.auth.sub`: learning routes only touch the caller's
  enrollments, progress, drafts, attempts, submissions, certificates; notification and calendar routes check
  `recipientId`/`ownerId` against the caller; lesson content is only returned when enrolled or previewable.
- **Never trusted from the client:** role, ownership ids, prices, quiz scores/passed, completion state,
  enrollment status, certificate status.

Current state (F2 complete): every route applies the rules above through `apps/api/src/lib/scope.ts`:

| Helper | Used by |
| --- | --- |
| `instructorScope(req)` → `undefined` (admin) or the instructor id | list queries, reports, dashboard, calendar |
| `courseScopeWhere(req)` / `scopedCourseIds(req)` | course, quiz, assignment, submission, certificate, live lists |
| `assertCourseAccess(req, courseId)` (404 when out of scope) | course routes, chapters/lessons routers (mounted check), create quiz/assignment/live, enroll |
| `assertQuizAccess` / `assertAssignmentAccess` / `assertSubmissionAccess` / `assertLiveAccess` / `assertCertificateAccess` | every `/:id` staff route |
| `assertStudentAccess` / `studentScopeWhere` | students list/profile/progress/activity |
| `requireStudent`, `requireEnrollment`, `requireLessonAccess` | learning routes, live registration |
| `requireUser` | notifications, calendar ownership |

Client-sent `scopeInstructorId`, `instructorId`, `recipientId`, `ownerId`, `viewerId` are ignored for
instructors and learners (admins may still filter by `instructorId`). Instructors cannot remove themselves
from a course; learners never receive lesson bodies of courses they are not enrolled in (free previews
excepted), cannot see drafts, and can only claim certificates already marked `pending` for them.
Covered by `apps/api/src/permissions.test.ts`.

## Registration doors and pending accounts (October 2026)

Who may create an account, and through which door:

| Door | Route | Creates | Verified by |
| --- | --- | --- | --- |
| Admin sign-up (`/get-started`) | `POST /signup/start` → `/signup/verify` (SAAS-026) | a new academy and its owner admin, through `lib/academies.ts` | a 6-digit emailed code held in `PendingSignup` |
| Join link (`/join/:slug`) | `POST /public/academies/:slug/register` (SAAS-028) | a learner in that academy | a code held in `PendingAccount` |
| Invitation (`/invite/:token`) | `POST /public/invitations/:token/register`, or `/sign-in` for an existing account | a learner in the inviting Admin's workspace; the token (stored hashed) is the credential | a code, or the existing account's password |
| Course link (`/courses/:courseId/enroll`) | `POST /public/courses/:courseId/enroll` | a learner, enrolled under the academy's policy | a code |
| Host sign-up (apps) | `POST /auth/register { workspace? }` (D32) | a learner in the named workspace, or the host's default academy | a code |
| Request to teach (`/join/:slug/teach`) | `POST /public/academies/:slug/instructor-requests` (D34) | an instructor account whose profile is `pending`; sign-in and every request refuse it until an academy admin approves | a code, then the admin's approval |
| Admin adds a learner | `POST /students` (`learners.enroll`); `POST /students/:id/resend-invite` | a learner with a 7-day `learner-invite` set-password link | the link |
| Admin invites an instructor | `POST /instructors` | an instructor with a 7-day `instructor-invite` link | the link |
| Super Admin | `POST /superadmin/tenants`, `POST /superadmin/admins` | an academy with its owner admin; an admin in an academy | — |

Rules every door shares (`lib/learners.ts`, `lib/pendingAccounts.ts`): the academy is the link's, never the body's; the
email is unique platform-wide; a seat under `learners.max` is taken under the usage guard only when the account is created,
and every rule is checked again at that moment because the academy, the invitation or the address may have changed while
the code was waiting; an academy whose enrolment policy is `invite` refuses the join link, course links and host sign-up
with 403 `INVITATION_REQUIRED` while invitations still work. Codes are HMAC-hashed, expire in 15 minutes, allow 5 attempts
and 5 sends, spend an attempt before they are compared (so concurrent guesses cannot exceed the limit), and are
rate-limited per address (`RATE_LIMIT_EMAIL_MAX`) as well as per client. `SIGNUP_EMAIL_VERIFICATION=off` skips the code
only on a deployment with no email delivery, never by default; `TEST_OTP_EMAIL`/`TEST_OTP_CODE` give listed test
addresses a static code in development only and are refused wherever the live site is named.

**Account deletion:** `POST /auth/delete-account` with the person's password, reached from `/delete-account`.

**Sign-in throttles:** per IP (`RATE_LIMIT_AUTH_MAX`) and, since 28 Oct 2026, per account (`RATE_LIMIT_ACCOUNT_MAX`,
default 10 failures per window) on `/auth/login` and invitation sign-in. Sign-in takes as long for an unknown email as for a
wrong password. A suspended or archived academy's members, a deactivated admin, an inactive or `pending` instructor and a
suspended learner are refused on every request and at sign-in.

**Affiliate referrals (MLM-001).** Every learner door above accepts `referralCode?` and `preferredLeg?`. The code is resolved
before anything exists (`lib/mlm/affiliates.ts › prepareReferral`): it must be well-formed, name a sponsor in the same
academy who is not terminated, else `404 REFERRAL_INVALID` and no email is sent. The affiliate row is created right after
the account's transaction (`attachAffiliate`); a verified registration whose sponsor was terminated in the meantime is
still created, without the program. `/affiliate/*` is a learner's surface: the role guard's admin bypass is refused there.
