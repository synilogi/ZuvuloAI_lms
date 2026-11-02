# 05 — API Specification

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

**Current surface added by the conversion (🔓 public, 🔐 signed in, 👑 Super Admin):**

| Method and path | Purpose |
| --- | --- |
| 🔓 `POST /public/register` · `POST /public/instructor-applications` | Registration and instructor application, each confirmed by `POST /public/verifications/verify` |
| 🔓 `GET /public/site` · `GET /public/affiliate-program` | The website's editable words; the active plan's published terms |
| 🔓 `GET /catalog/*` | The public catalogue (unchanged) |
| 🔐 `POST /learning/courses/:courseId/quote` · `POST …/purchase` with `couponCode` | The price with a coupon; the checkout |
| 🔓 `POST /webhooks/:provider/courses` | Signed gateway events, one per event id. `payment.dispute.lost` reverses the sale's volume and flags the order |
| 👑 `/superadmin/sales/orders`, `/orders/export.csv`, `/orders/:id`, `/orders/:id/refund`, `/coupons`, `/coupons/:id`, `/events`, `/site` | Orders, refunds, coupons, payment events, website document |
| 🔐 `GET /reports/course-sales` (staff) | Enrolments and orders per course. Counts only; an instructor sees their own |
| 🔓 `GET /catalog/courses/:slug/reviews` · 🔐 `GET`, `PUT /learning/courses/:courseId/review` · `GET /reports/reviews` (staff) · `POST /reports/reviews/:id/hide`, `/show` (admin with `catalog.publish`, owner) | Course reviews: one per learner and course, enrolled learners only (active or completed). The public reads first name, rating and comment; staff read by `courseScopeWhere`; `Course.rating` and `ratingCount` follow the published reviews |
| 👑 `POST /superadmin/notifications/broadcast` · `GET /notifications/audience-count?audience=` · `GET /notifications/broadcasts` | One `system` message to `all`, `students`, `instructors` or `staff`, sent in batches, audited with the counts; the history is read from the audit log |
| 🔐 `GET /reports/overview`, `/courses`, `/courses/:courseId` (instructor) | Instructor performance at `/teach/reports`: the existing report routes, scoped to the instructor's courses from the token |
| 🔐 `GET /learning/purchases/:purchaseId` | Now carries `paymentReference` once paid, for the printable receipt at `/purchases/:id` (a payment record, not a tax invoice) |
| 🔐 `GET /affiliate/earnings`, `/matching`, `/commissions`, `/ranks`, `/rewards`, `/wallet`, `/withdrawals`; `GET`, `PUT /affiliate/kyc`; `POST /affiliate/withdrawals`, `/withdrawals/:id/cancel` | The member's own records |
| 👑 `/superadmin/affiliates/dashboard`, `/matching/runs`, `/matching/run`, `/commissions`, `/commissions/:id/release`, `/write-off`, `/ranks`, `/ranks/history`, `/members/:id/rank/recalculate`, `/rewards`, `/rewards/:id/approve`, `/fund`, `/pay`, `/reject`, `/wallets`, `/wallets/:affiliateId`, `/adjust`, `/kyc`, `/kyc/:affiliateId/verify`, `/reject`, `/withdrawals`, `/withdrawals/:id/approve`, `/reject`, `/paid`, `/payouts`, `/payouts/:id/export.csv`, `/payouts/:id/close`, `/reports/liability`, `/reports/export.csv` | The program's money |

`/tenant/*`, `/academy/plan` and `/superadmin/academies`, `/plans`, `/subscriptions`, `/invoices` are retired. `/public/academies/:slug*` answers for the workspace slug only, for apps already installed.

Base URL: `http://localhost:4000` (`VITE_API_BASE_URL`). JSON in and out. Authentication is a bearer JWT
(see `04-AUTHENTICATION-AUTHORIZATION.md`). Every response shape is the TypeScript type named in
`apps/web/src/services/contracts.ts`; the HTTP client that calls each route is in
`apps/web/src/services/http/<group>.ts`.

## Conventions

- **Errors:** `{ message: string, issues?: Issue[] }` with HTTP status `400` (bad input — malformed JSON or a
  request-schema failure, `issues: { path, message }[]`), `401` (sign in), `403` (not allowed), `404` (not
  found, including Prisma "record not found"), `409` (conflict / a domain validator refused / unique or
  foreign-key violation), `413` (body over 1 MB), `429` (rate limited), `500` (details only in the server
  log). The frontend maps 404 → `not-found`, 400/401/403/409 → `conflict`, network failure → `network`.
  For 409 `issues` is the array the matching `packages/domain` validator returned (`{ field, message }`);
  the client folds either shape into the message.
- **Error codes** (SAAS-003, subscriptions.md §34). Where a client must tell refusals apart, the body also carries
  a stable `code`:
  - `PERMISSION_DENIED` (403): the account lacks a permission (`requirePermission`).
  - `FEATURE_NOT_INCLUDED` (403): the academy's plan does not include the feature.
  - `SUBSCRIPTION_REQUIRED` (402): the academy is on no plan.
  - `PLAN_UNAVAILABLE` (409): the plan cannot be sold.

  The remaining §34 codes (`SUBSCRIPTION_PAST_DUE`, `SUBSCRIPTION_EXPIRED`, `LIMIT_REACHED`, `PAYMENT_REQUIRED`,
  `PAYMENT_FAILED`, `INVALID_SUBSCRIPTION_STATE`) are defined in `lib/errors.ts` for the modules that raise them.
  A role refusal (`requireRole`) carries no code on academy routes. The web client maps 402 to `unknown` and keeps the message.
- **Billing endpoints always carry a code** (SAAS-013). On `/superadmin/*` and `/tenant/*`, `stableCodes` gives every
  refusal one of `BILLING_ERROR_CODES` (including `SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED`, SAAS-017):
  - the §34 codes above;
  - `UNAUTHENTICATED` (401), `PERMISSION_DENIED` (403, a role refusal included), `VALIDATION_FAILED` (400),
    `NOT_FOUND` (404) and `CONFLICT` (409);
  - `INTERNAL_ERROR` (500).

  A database outcome is answered in plain words ("That already exists."), and no provider, SQL or stack detail ever
  reaches a body.
- **Request validation:** bodies and queries are parsed with `zod` schemas via `parseBody` / `parseQuery`
  (`apps/api/src/lib/validate.ts`); unknown fields are dropped, so mass assignment is impossible.
- **Hardening:** `helmet` headers, a global rate limit (`RATE_LIMIT_MAX` per `RATE_LIMIT_WINDOW_MS`) and a
  stricter one on credential attempts (`POST /auth/*`; `GET /auth/me` and the reset-link check are exempt);
  unknown routes return `404 { message }`.
- **Lists:** query parameters mirror the `*Query` types (`search`, `status`, `sort`, `page`, `pageSize`,
  filters). Paged lists return `{ rows, total, counts }`.
- **Scope:** instructors are confined to the courses they teach — derived from the token, never from the
  query. Admins may narrow lists with `instructorId`. Ids outside the caller's scope answer 404.
- **Tenancy (SAAS-000):** every request runs for one academy — the signed-in account's (read from its
  row on each request; the token's `tenantId` claim is checked against it), or, for a visitor who is not
  signed in, the academy `DEFAULT_TENANT_SLUG` names. A `tenantId` in a body, query or header is never
  read (the one exception: `POST /superadmin/admins` takes the academy the new admin is *for*). Another
  academy's ids answer 404 exactly like missing ones; a body naming another academy's rows answers 404.
  A correctly signed token that names no account, or whose academy claim no longer matches, answers 401.
- Guards: 🔓 public · 🔐 any signed-in user · 👩‍🏫 instructor or admin · 👑 admin only.

## Auth — `/auth`

| Method & path | Guard | Body / query | Returns |
| --- | --- | --- | --- |
| `POST /auth/register` | 🔓 | `{ name ≥ 2, email, password ≥ 8 }` — always a learner | `201 { token, user: UserProfile }` · 400 issues · 409 duplicate |
| `POST /auth/login` | 🔓 | `{ email, password }` | `{ token, user }` · 401 on bad credentials · 403 for a deactivated account, inactive instructor, suspended learner, or a suspended/archived academy (`code: ACADEMY_SUSPENDED \| ACADEMY_ARCHIVED`) |
| `GET /auth/me` | 🔐 | — | `{ user }` |
| `PATCH /auth/me` | 🔐 | `{ name ≥ 2 }` — email, role and academy are not fields here | `{ user }` (an instructor's public profile takes the same name) |
| `POST /auth/logout` | token | — | `{ revoked: 0 \| 1 }` — ends this token's session; `0` for a token from before sessions (use logout-all) · 401 without a valid session |
| `POST /auth/logout-all` | 🔐 | — | `{ revoked: n }` — ends every session of the account and every pre-session token |
| `GET /auth/sessions` | 🔐 | — | `{ sessions: { id, createdAt, expiresAt, userAgent?, current }[] }` (open sessions, newest first) |
| `DELETE /auth/sessions/:id` | 🔐 | — | 204 · 404 when it is not an open session of this account |
| `POST /auth/delete-account` | 🔐 | `{ password }` | Deletes the signed-in person's own account (403 on a wrong password); every session ends. The web's `/delete-account` page, required by the Play listing |
| `POST /auth/change-password` | 🔐 | `{ currentPassword, newPassword ≥ 8 }` | `{ token, user }` — every session ends, this device gets the fresh token · 403 wrong current password · 409 same password |
| `POST /auth/forgot-password` | 🔓 | `{ email }` | `{ ok: true }` always (no account enumeration); queues a `password-reset` email with `APP_URL/reset-password/<token>` |
| `GET /auth/reset-password/:token` | 🔓 | — | `{ valid: boolean }` |
| `POST /auth/reset-password` | 🔓 | `{ token, password ≥ 8 }` | `{ ok: true }` · 400 issues · 409 if the token is invalid, used or expired. Ends every session of the account |

**Sessions (SAAS-020).** Every token issued by `login`, `register` or `change-password` carries `sid`, a
`UserSession` the server checks on each request; an ended session is a 401 on every route. Tokens issued before
sessions existed (no `sid`) remain valid until they expire, unless `logout-all`, a password change or a reset
ended them. There are no refresh tokens: a token lives `JWT_EXPIRES_IN` (default 7 days). Deactivating or
suspending an account does not end its sessions — it is refused on every request while closed, and the same
token works again if it is reopened. Every `POST /auth/*` counts against the sign-in rate limit.

## Self-serve registration — `/signup` (🔓, SAAS-026)

| Method & path | Guard | Body / query | Returns |
| --- | --- | --- | --- |
| `POST /signup/start` | 🔓 | `{ academyName ≥ 2, slug?, name ≥ 2, email, password ≥ 8, acceptTerms: true }` — nothing chooses a role, academy, plan or status | `202 { status: 'verify', signupId, email, expiresAt, resendAvailableAt }` — a 6-digit code is emailed (`signup-verification`) · `201 { status: 'created', token, user }` when `SIGNUP_EMAIL_VERIFICATION=off` · 400 issues (`slug` invalid or reserved) · 409 email already has an account / address taken |
| `POST /signup/resend` | 🔓 | `{ signupId }` | `{ signupId, email, expiresAt, resendAvailableAt }` — a new code; the old one stops working and attempts reset · 429 within 60 s of the last · 404 no longer open |
| `POST /signup/verify` | 🔓 | `{ signupId, code: 6 digits }` | `201 { status: 'created', token, user }` — the academy is provisioned (levels, ranks, certificate template, settings) with the registrant as its owner admin holding every permission, **no subscription** (D28), audited `academy.self_registered` · 400 wrong code (attempts left in the message) · 410 expired · 429 after 5 wrong codes · 404 already used or replaced · 409 the address or email was taken meanwhile |

The code is stored as an HMAC bound to its registration, works once, for 15 minutes. `/signup` has its own
rate limiter at the sign-in budget (`RATE_LIMIT_AUTH_MAX`).

## Public website — `/public` (🔓, SAAS-026)

`GET /public/plans` → `{ plans: Plan[], tax: { name, inclusive, rateBps } | null }` — the plans on sale (drafts and
archived plans never), at their current version's prices in minor units; `tax` is the home market's rule, which
checkout applies from the billing address.

**Academy join links (SAAS-028, D29).** `GET /public/academies/:slug` → `{ name, slug, open }` (404 unknown or archived;
`open: false` while suspended) · `POST /public/academies/:slug/register` `{ name ≥ 2, email, password ≥ 8 }` →
`201 { token, user }` — a learner of that academy only, counted against its `learners.max`; 403 `ACADEMY_SUSPENDED`
while suspended · 409 email in use. The slug chooses which academy's door the visitor is at, like a host name; it
grants nothing else. On the sign-up rate limit. `POST /auth/register` is unchanged (the host's academy).
`invitationOnly: true` when the academy's enrolment policy is `invite`: its join link, course links and the host's
sign-up then refuse learners with 403 `INVITATION_REQUIRED` (invitations still work; instructors may still ask to teach).

**Email verification for learners and instructors (2026-10-23).** With `SIGNUP_EMAIL_VERIFICATION` on (the default),
every self-registration door — `POST /auth/register`, `POST /public/academies/:slug/register`,
`POST /public/academies/:slug/instructor-requests`, `POST /public/invitations/:token/register` and
`POST /public/courses/:courseId/enroll` — checks its rules as before and then answers
`202 { status: 'verify', verificationId, email, role: 'student'|'instructor', lms, expiresAt, resendAvailableAt }`
instead of creating the account. Nothing that can sign in exists and no seat is taken until the code is confirmed. The
registration is held as a `PendingAccount` in the academy the link named (code and password hashed; a trigger keeps its
academy, role and address fixed).

| Endpoint | Body | Answer |
| --- | --- | --- |
| `GET /public/verifications/:id` | — | the `verify` body above · 404 `VERIFICATION_FAILED` once used, replaced or pruned |
| `POST /public/verifications/resend` | `{ verificationId }` | the `verify` body with a new code and expiry · 429 before `resendAvailableAt`, and after 5 codes in all |
| `POST /public/verifications/verify` | `{ verificationId, code: 6 digits }` | learner: `201 { status: 'created', token, user, enrolled?, enrolment? }` (course links enrol under the LMS's policy) · instructor: `202 { status: 'pending', message }` (the request reaches the academy's admins; nobody is signed in) · 400 wrong code (tries left in `issues[code]`) · 410 expired · 429 after 5 wrong codes · 404 closed · and any refusal the door's rules give at that moment (409 email taken, 404 `INVITE_INVALID`, `LIMIT_REACHED`, `ACADEMY_SUSPENDED`, `INVITATION_REQUIRED`) |

Codes last 15 minutes. Registrations whose code expired over a day ago are pruned by the scheduler (and so are unconfirmed
academy signups). Every POST that sends a code is also limited per email address, from any client
(`RATE_LIMIT_EMAIL_MAX`, default 10 an hour), on top of the per-client sign-up budget.

`POST /public/inquiries` → `201 { received: true }` — the contact form (SAAS-027): `{ kind: demo|sales|support, name ≥ 2,
email, organisation?, phone? (digits, spaces, + ( ) -), size?, message ≥ 10 }`. Stored with no academy for the Super
Admin's inbox, and emailed to `SALES_NOTIFY_EMAIL` when set. A filled `website` field (the honeypot) is answered the
same way and not stored. Its own rate limit (a third of `RATE_LIMIT_AUTH_MAX`, at least 5, per window).

**Inbox (👑):** `GET /superadmin/inquiries?status&kind&search&page&pageSize` → `{ rows: Inquiry[], total, page, pageSize,
counts: { new, in_progress, closed } }` newest first · `PATCH /superadmin/inquiries/:id { status?, note? }` → `Inquiry`,
audited `inquiry.updated`. A request is never deleted (database trigger).

### Platform branding — the logo and favicon

One logo and one favicon for the whole platform: the website, the sign-in screens and the workspace chrome. Not an
academy's appearance (`PUT /settings/appearance`), which is separate and untouched by anything here. The built-in
ZuviloAI assets ship inside the web and mobile apps, so `null` below always means "the built-in one".

- `GET /public/branding` (🔓) → `{ logo: BrandAsset | null, favicon: BrandAsset | null }`, `BrandAsset` =
  `{ url, mime, width, height }`. `url` is a path on the API. `Cache-Control: no-cache`, so a change shows on the next
  page load. A saved asset whose file is missing is reported as `null`.
- `GET /public/branding/assets/:name` (🔓) → the saved file, as the type found in its bytes, `nosniff`,
  `Cache-Control: public, max-age=31536000, immutable` — the name is new for every upload. Only a file a current row
  names is served (the name is looked up, never joined to a path); anything else is 404.
- `GET /superadmin/branding` (👑) → `{ logo, favicon }`, each `null` or `BrandAsset & { name, sizeBytes, updatedAt,
  updatedBy? }`.
- `PUT /superadmin/branding` (👑, `multipart/form-data`) — fields `logo` and/or `favicon`, one file each. What is sent
  replaces what was saved; a kind not sent is left alone. → the same shape as the GET. `400 VALIDATION_FAILED` with
  `issues: [{ field: 'logo' | 'favicon', message }]` when a file is refused — and then nothing is saved, the other
  file included; `413` over 1 MB. Audited `branding.updated`.
- `DELETE /superadmin/branding` and `DELETE /superadmin/branding/:kind` (`logo` | `favicon`) (👑) → back to the
  built-in asset; the row and the file are removed. Audited `branding.restored`.

A file is judged in this order (`packages/domain/src/branding.ts`, `apps/api/src/lib/branding.ts`), in memory, before
anything is written: extension **and** declared type on the allow-list → size → its bytes are a whole image of the
format its name says (PNG chunks walked to `IEND` with nothing after; JPEG to its frame header and `EOI`; WebP's RIFF
length; every ICO entry inside the file) → dimensions and proportions. SVG is not accepted.

| | Formats | Max size | Dimensions | Width ÷ height |
|---|---|---|---|---|
| `logo` | PNG, JPG, WebP | 1 MB | 128 × 64 to 2400 × 1200 | 1 to 6 |
| `favicon` | PNG, ICO | 256 KB | 48 × 48 to 1024 × 1024 | square (±3%) |

Every `/superadmin/branding` route sits behind `requireSuperAdmin`, applied to the whole Super Admin router before the
upload is read: an academy admin, instructor or learner is answered `403 PERMISSION_DENIED`, a visitor `401`.

## Catalog — `/catalog` (🔓)

`GET /levels` → `Level[]` · `GET /categories` → `Category[]` · `GET /instructors` → `Instructor[]` ·
`GET /courses?levelId&categoryId` → published, public `Course[]` · `GET /courses/:slug` → `Course`.

## Courses — `/courses`

| Method & path | Guard | Notes |
| --- | --- | --- |
| `GET /courses` | 👩‍🏫 | `CourseQuery` → `CourseListResult` (counts per status before the status filter) |
| `GET /courses/:id` | 🔐 | `Course` with chapters and lessons |
| `GET /courses/:id/stats` | 👩‍🏫 | `CourseStats` (enrolled, active, completion, 12-week trend, buckets, recent, live, certificates, reviews waiting) |
| `POST /courses` | 👩‍🏫 | `CourseInput` → `201 Course` (slug generated, unique) |
| `PATCH /courses/:id` | 👩‍🏫 | `Partial<CourseInput>` |
| `POST /courses/:id/publish` | 👩‍🏫 | 409 with the `publishChecklist` when not ready |
| `POST /courses/:id/unpublish` · `/archive` · `/restore` | 👩‍🏫 | status transitions |
| `POST /courses/:id/reorder-chapters` | 👩‍🏫 | `{ chapterIds }` |

## Categories — `/categories`

`GET /` 👩‍🏫 `CategoryQuery` → `{ rows: CategoryRow[], counts }` · `GET /:id` 👩‍🏫 → `CategoryDetail` ·
`POST /` 👑 `CategoryInput` · `PATCH /:id` 👑 · `DELETE /:id?moveCoursesTo=` 👑 → `{ moved }` (409 when
courses still use it and no destination is given).

## Chapters — `/courses/:courseId/chapters` (👩‍🏫)

`GET /stats` → `CurriculumStats` · `POST /` `{ input: ChapterInput, position? }` → `201 Chapter` ·
`PATCH /:chapterId` · `POST /:chapterId/duplicate` (copy + lessons as drafts, inserted after) ·
`DELETE /:chapterId` → `{ lessonsRemoved }` · `POST /:chapterId/move` `{ position }` → `Chapter[]`.

## Lessons — `/courses/:courseId/lessons`

`GET /` 👩‍🏫 `LessonQuery` → `{ rows: LessonRow[], counts }` · `GET /:lessonId` 🔐 → `LessonDetail` ·
`POST /` 👩‍🏫 `{ chapterId, input: LessonInput, position? }` (409 via `lessonPublishIssues` when publishing
incomplete content) · `PATCH /:lessonId` 👩‍🏫 · `POST /:lessonId/move` `{ chapterId, position }` →
`LessonDetail` · `POST /:lessonId/duplicate` · `DELETE /:lessonId` → 204.

## Media — `/media` *(F5)*

`POST /media` 👩‍🏫 multipart `file` → `201 MediaFile { name, sizeMb, url }` (type/size allow-list) ·
`GET /media/:id` 🔓 streams the file.

## Students — `/students`

| Method & path | Guard | Returns |
| --- | --- | --- |
| `GET /students` | 👩‍🏫 | `StudentQuery` → `StudentListResult` (status derived with `deriveStudentStatus`) |
| `GET /students/:id` | 👩‍🏫 | `StudentProfile` |
| `GET /students/:id/progress` | 👩‍🏫 | `StudentProgress` |
| `GET /students/:id/activity` | 👩‍🏫 | `StudentActivityQuery` → `StudentActivity` |
| `POST /students/message` | 👩‍🏫 | `{ ids, subject, body, channels }` → `{ sent }` |
| `POST /students/:id/enroll` | 👩‍🏫 | `{ courseId, source }` → `Enrollment` |
| `PATCH /students/enrollments/:enrollmentId` | 👩‍🏫 | `{ status: 'active' \| 'paused' }` |
| `DELETE /students/enrollments/:enrollmentId` | 👩‍🏫 | 204 |
| `POST /students/:id/suspend` | 👑 | `{ suspended, reason? }` → `Student` |
| `POST /students` | 👑 `learners.enroll` | `{ name ≥ 2, email }` → `201 Student` — joins the admin's own academy, counted against `learners.max` (402/403 under enforcement), emails a `learner-invite` link to choose a password (7 days); audited `learner.created` · 409 email in use anywhere (D2) (SAAS-028) |
| `POST /students/:id/resend-invite` | 👑 `learners.enroll` | `{ sentTo }` · 404 for another academy's learner |

## Instructors — `/instructors`

`GET /` 👩‍🏫 `InstructorQuery` → `{ rows: InstructorRow[], counts, expertise }` · `GET /:id` 👩‍🏫 →
`InstructorProfile` · `POST /` 👑 `InstructorInput` (409 via `validateInstructor`; creates the login
account when invited) · `PATCH /:id` 👑 · `POST /:id/status` 👑 `{ status }` · `POST /:id/resend-invite`
👑 → `{ sentTo }`.

## Learning (the signed-in learner) — `/learning` (🔐, learner only)

| Method & path | Returns |
| --- | --- |
| `GET /home` | `LearningHome` |
| `GET /courses` | `{ courses: LearnerCourse[], saved }` |
| `GET /courses/:courseId` | `LearnerCourse & { enrolled, live, assignments, certificate?, saved }` |
| `GET /courses/:courseId/lessons/:lessonId` | `LessonView` (access: open/locked/not-enrolled/unavailable). Its `quiz` is a `LearnerQuiz`: each question is `{ id, type, prompt, options[{id,text}], points, required }` — never `correct`, `acceptedAnswers` or `explanation` (SAAS-018) |
| `POST …/lessons/:lessonId/complete` | `CompletionResult` |
| `PUT …/lessons/:lessonId/position` `{ positionSec, fraction }` | 204 |
| `PUT …/lessons/:lessonId/note` `{ text }` | `{ savedAt }` |
| `POST …/lessons/:lessonId/bookmark` | `{ bookmarked }` |
| `POST /courses/:courseId/save` | `{ saved }` |
| `POST /courses/:courseId/enroll` | `LearnerCourse` |
| `GET /assignments` · `GET /assignments/:id` | `LearnerAssignment[]` / `LearnerAssignment` |
| `PUT /assignments/:id/draft` | `{ savedAt }`. Every file must be the learner's own upload (`POST /media/upload`, a document or image) named by its `id`; 409 otherwise. Name and size are read from the stored file |
| `POST /assignments/:id/submit` `{ text?, files, chart? }` | `LearnerAssignment`. 409 unless the work fits the assignment's format (`text`: a written answer, no files; `file`: 1–3 own uploads, optional note; `chart`: birth details and interpretation, no files) and its `wordLimit` (text and chart) — `validateSubmission` in `packages/domain` |
| `GET /assessments` | `(Assessment & { lessonId?, courseTitle })[]` |
| `POST …/lessons/:lessonId/quiz-attempt` `{ answers, durationSec? }` | `CompletionResult \| null` (F6: scored server-side from `answers`; any client `percent`/`passed` is ignored). `null` = not passed, or passed with nothing newly completed |
| `POST …/lessons/:lessonId/quiz-session` `{ startKey? }` | Starts the learner's timed attempt (14 Oct 2026, `lib/quizSessions.ts`): under the enrolment-row lock, an open session is returned again (200), or the attempt limit and retake wait are checked against every attempt used and a new session is written (201), which consumes the attempt. Its deadline is the server's clock plus the quiz's `timeLimit`. Returns the session view (questions without keys, in the session's order, the remaining seconds, the saved sheet) |
| `GET …/lessons/:lessonId/quiz-session` | `{ session \| null, questions }` — the open session, with its questions while `active` |
| `PUT …/quiz-session/:sessionId/answers` `{ answers, seq }` | Saves the whole answer sheet: only while the session is open, before the deadline by the server's clock, and with a `seq` higher than the last stored, so a late or out-of-order save changes nothing. Returns the session view |
| `POST …/quiz-session/:sessionId/submit` `{ answers?, seq? }` | Finishes the session once (a conditional update; racing submissions read the same result). Before the deadline a final sheet counts; in the grace after it only what was saved; later, or when the scheduler finds it, the session is `expired` and scored on what was saved. Writes the `QuizAttempt` and returns the result like `quiz-attempt` |
| `GET …/lessons/:lessonId/quiz-attempts` | `{ attempts: AttemptReview[] }`, newest first, the learner's own only (403 if not enrolled). Each is cut to the quiz's `showResults`: `score-and-answers` → score, per-question `{ state, points, answer, correct \| acceptedAnswers, explanation? }`; `score-only` → `percent, points, max, passMark, passed`; `hidden` → `{ attemptId, submittedAt, showResults, passed }` (SAAS-018) |
| `GET /certificates` · `GET /certificates/:id` · `POST /certificates/:id/claim` | `{ issued, pending, working }` / `CertificateDetail` |
| `GET /rank-ladder` | `{ ranks, standing }` |
| `GET /activity` | `{ week, events }` |

## Quizzes — `/quizzes`

`GET /` 👩‍🏫 `QuizQuery` → `{ rows: QuizRow[], counts }` · `GET /:id` 🔐 · `GET /:id/stats` 👩‍🏫 →
`QuizStats` · `POST /` 👩‍🏫 `QuizInput` (409 via `validateQuiz` when publishing) · `PATCH /:id` 👩‍🏫 ·
`POST /:id/duplicate` · `DELETE /:id` (409 when a lesson delivers it — F7). `settings.showResults` is
`score-and-answers` | `score-only` | `hidden`; the older value `nothing` is accepted and stored as `hidden`.
These staff routes return the full quiz, key included; learners reach quizzes only through `/learning`.

## Assignments — `/assignments`

| Method & path | Guard | Notes |
| --- | --- | --- |
| `GET /assignments` | 👩‍🏫 | `AssignmentQuery` → `{ rows: AssignmentRow[], counts }` |
| `GET /assignments/review` | 👩‍🏫 | `ReviewSummary` (to review, overdue, by course) |
| `GET /assignments/submissions` | 👩‍🏫 | `SubmissionQuery` → `SubmissionListResult` |
| `GET /assignments/:id` | 🔐 | `CourseAssignment` |
| `POST /assignments` · `PATCH /:id` | 👩‍🏫 | `AssignmentInput` (409 via `validateAssignment` when publishing) |
| `POST /:id/duplicate` · `DELETE /:id` | 👩‍🏫 | |
| `GET /:id/submissions` | 👩‍🏫 | as `/submissions` for one assignment |
| `GET /submissions/:submissionId` | 👩‍🏫 | `SubmissionDetail` with queue position |
| `POST /submissions/:submissionId/review` | 👩‍🏫 | `ReviewInput` → `Submission` (409 via `validateReview`; score via `reviewScore`) |
| `POST /:id/remind` | 👩‍🏫 | `{ studentIds }` → `{ sent }` |

## Certificates — `/certificates`

`GET /` 👩‍🏫 `CertificateQuery` → `{ rows: CertificateRow[], total, counts }` · `GET /templates` 👩‍🏫 →
`TemplateSummary[]` · `GET /templates/:id` 👩‍🏫 · `POST /templates` 👑 `{ id: string|null, input }` (409 via
`validateTemplate`; assigns `courseIds`) · `POST /templates/:id/default` 👑 · `GET /verify/:credentialId`
🔓 → `CertificateDetail` (increments `verifications`) · `GET /:id` 🔐 · `POST /:id/issue` 👩‍🏫 ·
`POST /:id/revoke` 👑 `{ reason }` · `POST /:id/restore` 👑.

## Live classes — `/live`

`GET /` 👩‍🏫 `LiveQuery` → `{ rows: LiveRow[], total, counts }` · `GET /learner` 🔐 (learner) →
`LearnerLive` · `GET /:id` 🔐 → `LiveDetail` · `POST /` 👩‍🏫 `LiveClassInput` (409 via `validateLiveClass`)
· `PATCH /:id` 👩‍🏫 · `POST /:id/cancel` `{ reason }` · `POST /:id/remind` → `{ sent }` ·
`PATCH /:id/reminders` `{ reminders }` · `POST /:id/register` 🔐 (learner, toggles) → `{ registered, spotsLeft }`.

**Built-in live room (15 Oct 2026; `modules/live-classes.md` › Built-in live room).** For a class whose `meeting.kind` is `room`:
`POST /:id/start` 👩‍🏫 (`live.manage`; from 15 minutes before the start until the scheduled end) opens the room, stamps
`startedAt`/`roomName` once, tells learners it is live and returns the host's join (moderator); starting an open room again is
rejoining · `POST /:id/join` 🔐 (an enrolled learner, registered on join when there is room, 409 when the class is full; or the course's staff, an admin with `live.manage`) → the room, server and a signed token
(JaaS) or `{ kind: 'external', link }` for an outside meeting · `POST /:id/end` 👩‍🏫 closes the room and settles attendance
(the scheduler closes a room left open) · `GET /:id/recording` (the kept recording, streamed with ranges, for the app with its
token) · `POST /:id/recording/link` → a two-hour link to the same file for a browser `<video>` · `GET /live/recording-files/:grant`
(the file behind such a link). With no video service configured a production process answers `503 LIVE_ROOM_NOT_CONFIGURED`.

## Calendar — `/calendar` (🔐 staff)

`GET /?from&to&types[]&courseId&instructorId&scopeInstructorId` → `{ rows: CalendarRow[], counts, total }`
(stored events + derived live/assignment rows; personal reminders are the caller's own) · `GET /:id` →
`CalendarDetail` · `POST /` `{ input: CalendarEventInput }` (owner = caller; 409 via
`validateCalendarEvent`) · `PATCH /:id` · `DELETE /:id` · `POST /:id/done` `{ done }` — the three
mutations are allowed only to the event's owner or an admin (404 otherwise). Learners get 403.

## Notifications — `/notifications` (🔐, own records)

The recipient is always the signed-in account (`req.auth.sub`); ids sent by the client are ignored and
every mutation is filtered by recipient. `GET /?unreadOnly&category&limit` → `NotificationPage` ·
`GET /:id` → `NotificationDetail` (marks read; 404 for another account's notification) · `POST /read`
`{ ids, read }` · `POST /read-all` `{ category? }` → count · `POST /remove` `{ ids }` · `POST /restore`
`{ notifications }` · `POST /clear` `{ category?, unreadOnly? }` → count · `GET /settings/me` ·
`PUT /settings/me` (400 on shape, 409 via `validateNotificationSettings`).

**Devices for push (SAAS-021).** `POST /devices` `{ token (20–4096 chars), platform: android|ios|web }` → 201
`Device { id, platform, tokenEnd, current, createdAt, lastSeenAt }` — bound to the calling session; a token
registered again from another account moves to it. `GET /devices` → `{ devices: Device[] }` (the token itself is
never echoed). `DELETE /devices/:id` → 204, 404 for another account's device. Signing out removes that session's
devices; logout-all and a password change remove them all.

**Push payload.** A data-only message `{ notificationId, category }` — the app fetches `GET /notifications/:id`
before showing anything. A push is queued for each in-app notification when `PUSH_PROVIDER` is set and the
recipient has a device; it follows the category's in-app (`app`) channel and pause, waits out quiet hours (read
in IST) unless the notification is important, is skipped once the notification is read, and is retried with
backoff. Tokens the provider reports as unregistered are removed.

## Media — `/media` (🔐)

`POST /upload` multipart field `file` → `201 MediaFile { id, name, sizeMb, url: '/media/<id>', mime, kind }` ·
400 disallowed type/extension, or contents that do not match the type (SAAS-023) · 403 video from a learner ·
413 over the kind's limit (500 MB video, 25 MB document, 5 MB image) ·
`GET /:id` streams the file (`Content-Disposition: inline; filename="…"; filename*=UTF-8''…`, nosniff, Range) to
a reader who may open it — the uploader, an admin, an instructor for staff material or hand-ins to courses they
teach, a learner for material in a lesson or published assignment of a course they are enrolled in or a published
free-preview lesson; anyone else gets 404. There is no delete or replace endpoint.

## Settings — `/settings`

`GET /` 🔐 → `SettingsRecord` · `PUT /:section` 👑 body = that section's value (409 via `validateSettings`).

## Help — `/help` (🔓)

`GET /categories?audience` → `HelpCategoryRow[]` · `GET /articles?search&categoryId&audience` →
`HelpArticleRow[]` · `GET /articles/:slug?audience` → `HelpArticleDetail` (404 `not-found`).

## Reports — `/reports` (👩‍🏫; instructors report 👑)

Query = `ReportFilters` (`range`, `categoryId`, `courseId`, `instructorId`, `segment`) plus `search`,
`page`, `pageSize` for learners. `GET /overview` → `ReportOverview` · `GET /courses` →
`ReportContext & { rows }` · `GET /courses/:courseId` → `CourseReport` · `GET /learners` → `LearnerReport` ·
`GET /instructors` → `InstructorReport` · `GET /enrolments` → `EnrolmentReport`.

## Dashboard — `/dashboard` (👩‍🏫)

`GET /?scope=academy|instructor&instructorId` → `DashboardSnapshot`.

## Super Admin — tenancy additions

- **Academies (SAAS-019)** — all under the Super Admin guard and platform context:
  - `GET /superadmin/tenants?search&status&page&pageSize` → `{ rows: Academy[], total, page, pageSize }`. Unpaged
    by default (page size 500). `Academy` = `{ id, name, slug, status, statusReason?, statusChangedAt?, owner?,
    ownerUserId?, accounts, courses, learners, instructors, isDefault, createdAt, updatedAt }` — the fields the
    list always had are kept.
  - `POST /superadmin/tenants` `{ name, slug, admin: { name, email, password } }` → 201 `Academy`. Provisions in
    one transaction: the tenant, its first admin (every permission; the academy's owner), settings named after
    it, the starter level and rank ladders and a default certificate template. 400 for an invalid or reserved
    slug, 409 for a taken slug or email. No subscription is started (use a trial or the first purchase).
  - `GET /superadmin/tenants/:id` → `Academy` · `PATCH /superadmin/tenants/:id` `{ name?, slug? }` (the academy
    `DEFAULT_TENANT_SLUG` names keeps its slug, 409).
  - `POST /superadmin/tenants/:id/suspend` `{ reason }` · `POST …/archive` `{ reason }` · `POST …/reactivate` →
    `Academy`. Transitions: active → suspended; active/suspended → archived; suspended/archived → active; anything
    else 409. The default academy cannot be suspended or archived (409); archiving needs no live subscription
    (409 — cancel it first). Every change is audited (`academy.created|updated|suspended|archived|reactivated`).
  - `GET /superadmin/tenants/:id/users?search&role&page&pageSize` · `GET …/subscription` (the academy's billing
    view, as its own admin sees it) · `GET …/usage` (`usageSummary`).
  - A member of a suspended or archived academy is refused on every request and at sign-in with 403 and
    `code: ACADEMY_SUSPENDED | ACADEMY_ARCHIVED`. All data is kept.
- Directory rows (`/superadmin/users`, `/superadmin/admins`) carry `tenant: { id, name, slug }`; a super admin has none.
- `POST /superadmin/admins` requires `tenantId` — the academy the new admin runs (400 without it; 404 for an unknown one). There is no default: an admin silently placed in the host's first academy would run another customer's academy. A new customer's academy and its first admin are created together by `POST /superadmin/tenants`, which starts it empty.

## Health and operations

`GET /health` 🔓 → `{ ok: true }`; since 23 Oct 2026 it also checks the database, so a broken file answers 503.

`POST /deploy/webhook` 🔓 — GitHub push → `deploy/deploy.sh` for the configured branch; raw body, `X-Hub-Signature-256`
checked against `DEPLOY_WEBHOOK_SECRET`; 404 unless the secret is set (`routes/deploy-webhook.ts`, `10-DEPLOYMENT.md`).

`GET /.well-known/assetlinks.json` 🔓 — Android App Links, built from `ANDROID_APP_LINK_SHA256` and `ANDROID_APP_LINK_PACKAGES`
when `WEB_DIST` is set (`lib/appLinks.ts`); 404 when unset. `robots.txt` and `sitemap.xml` are served by `apps/api/src/web.ts`.

## Sandbox gateway (`/sandbox`, development and E2E only; SAAS-030)

Every route is 404 unless `PAYMENT_SANDBOX=on` and `NODE_ENV` is not `production`. While on and no real gateway is
active, checkouts open with `provider: 'sandbox'` and `redirectUrl: APP_URL/sandbox-checkout/<orderId>`.
`GET /sandbox/orders/:orderId` → `{ orderId, amount, currency, receipt, status }` · `POST /sandbox/orders/:orderId/pay
{ outcome: success|failure }` → `{ paymentId, status: paid|failed, webhookDelivered }` — the sandbox records the
payment on its side and delivers an HMAC-signed `payment.captured` / `payment.failed` webhook to
`POST /webhooks/sandbox/subscription`, which is verified and settled exactly like any gateway's. No session: like a
gateway's page, an order is reached by its unguessable id, and nothing on the platform changes except through the
webhook.

## Provider webhooks (SAAS-010)

`POST /webhooks/:provider/subscription` 🔓 is signed by the provider; there is no session. Each gateway has its
own URL. It is answered while that gateway's credentials are stored, whether or not it is the active one. A
gateway that is not configured here gets 404 (SAAS-017). For Razorpay the headers are `X-Razorpay-Signature`
(HMAC-SHA256 of the exact body under the webhook secret stored for Razorpay, which is not its key secret) and
`X-Razorpay-Event-Id`. It is mounted before the JSON parser, so the signature is checked over the raw bytes.

| Answer | When |
| --- | --- |
| `401` | missing or wrong signature, or no webhook secret configured. Nothing is stored. |
| `400` | signed, but not an event: no event id, not JSON, or not the provider's shape |
| `404` | no provider configured, or another provider named |
| `200 { received, outcome }` | processed, ignored (not an event the platform acts on, or a replay), or `duplicate: true` for an event already handled |
| `409` | the same event is being processed by another delivery right now. The provider retries later. |
| `500` | processing failed. The receipt is `failed` and the provider's retry finishes the work once. |

Handled events:
- payment events (`payment.authorized`, `payment.captured`, `payment.failed`, `order.paid`) for a checkout order
  the platform opened. The payment is read back from the provider, then recorded exactly as at checkout.
- refund events (`refund.processed`, `refund.failed`), matched to the refund the platform asked for.

`GET /superadmin/webhooks?status&page&pageSize` 👑 lists receipts: provider, event id, type, status, attempts,
note and the ids the event named. It never shows a body.

## Other webhooks (October 2026)

- `POST /webhooks/jaas` 🔓 — 8x8 JaaS `RECORDING_UPLOADED`, signed with `JAAS_WEBHOOK_SECRET`; the recording is downloaded
  and kept under `UPLOAD_DIR/live-recordings` for `LIVE_RECORDING_DAYS` (`lib/liveSessions.ts`).
- `POST /webhooks/academies/:tenantId/razorpay/courses` 🔓 — an academy's own Razorpay webhook for course sales, verified
  with that academy's stored webhook secret; one `CoursePaymentEvent` per (academy, provider, event id), so a redelivery
  changes nothing; the payment is read back from the gateway before a purchase settles (`lib/coursePurchases.ts`).

## Billing — Super Admin (`/superadmin/…`, 👑; SAAS-013)

These sit behind the Super Admin guard and run as the platform. Money is always in integer minor units, and no
endpoint takes a price the server calculates.

| Method & path | What it does |
| --- | --- |
| `GET /superadmin/plans?status` | plans with their current terms |
| `POST /superadmin/plans` | create a draft plan (terms and allowance) |
| `GET /superadmin/plans/:id` | a plan and its version history |
| `PATCH /superadmin/plans/:id` | edit. A change of terms or allowance adds a version. |
| `POST /superadmin/plans/:id/publish` · `/archive` · `/restore` | the named transitions |
| `GET /superadmin/subscriptions?status&tenantId&page&pageSize` | every academy's subscriptions |
| `POST /superadmin/subscriptions` | `{ tenantId, planId, cycle, start: trial\|active }`. The price is the plan's. |
| `GET /superadmin/subscriptions/:id` | the subscription with its lifecycle, plan changes, invoices and payments |
| `POST /superadmin/subscriptions/:id/cancel` | `{ immediately?, reason }` |
| `POST /superadmin/subscriptions/:id/pause` | `{ days: 1–30, reason? }` |
| `POST /superadmin/subscriptions/:id/resume` | `{ reason? }` |
| `POST /superadmin/subscriptions/:id/extend` | `{ days: 1–90, reason }`. Complimentary days: an active subscription's period ends later, at no charge; an unpaid renewal invoice for the old end is voided and reissued for the new one. Refused once the next period is paid. |
| `GET /superadmin/invoices?status&tenantId…` · `GET /superadmin/invoices/:id` | invoices |
| `POST /superadmin/invoices/:id/void` | `{ reason }`; open invoices only |
| `POST /superadmin/invoices/:id/record-payment` | `{ method: bank_transfer\|cheque\|cash\|upi\|other, reference, note? }`. Money received outside the gateway, for the open invoice's full total, under provider `offline` with the reference as its id (never counted twice). The invoice then renews, recovers, starts or upgrades the subscription. A refund of such a payment is settled at once. |
| `GET /superadmin/payments?status&tenantId…` · `GET /superadmin/payments/:id` | payments, each with its refunds |
| `POST /superadmin/payments/:id/refund` | `{ amount?, reason }`; the full refundable amount unless given. Asked of the payment provider when it took the payment, and settled by its answer; a refusal is recorded as a failed refund (SAAS-009). |
| `GET /superadmin/tax-rules?includeRetired` | tax rules |
| `POST /superadmin/tax-rules` | set a rule; replaces the active one for that place |
| `POST /superadmin/tax-rules/:id/retire` | retire a rule |
| `GET` · `PUT /superadmin/tenants/:id/billing-profile` | an academy's billing details |
| `POST /superadmin/subscriptions/:id/plan-change` | `{ planId, cycle }`. The rules decide when it applies: an upgrade is quoted and waits for payment (D7, D8); a downgrade is scheduled for the period end (D10). Returns the plan change. |
| `GET /superadmin/billing-views/overview` | the screens' `SubscriptionOverview` (SAAS-015). Past months are replayed from the lifecycle log; the current month is the live book. |
| `GET /superadmin/billing-views/plans?search&status&sort` · `/plans/:id` | `PlanListResult` (with subscriber counts and MRR) · `PlanDetail` (six-month trend, by status) |
| `GET /superadmin/billing-views/subscribers?search&planId&status&cycle&payment&from&to&sort&page&pageSize` | `SubscriberListResult`; `counts` are taken before the status filter |
| `GET /superadmin/billing-views/subscriptions/:id` | `SubscriptionDetail`: the subscription, its own plan version, its history in words, its invoices |
| `GET /superadmin/billing-views/payments?search&status&planId&page&pageSize` · `/invoices/:idOrNumber` | invoices with what came of them (`pending`, `failed`, `paid`, `refunded`, `void`) and the totals across matches · one invoice, with the server's `amounts` |
| `GET /superadmin/audit?actorType&action&targetType&targetId&page&pageSize` | the audit trail, newest first (SAAS-014). `actorType` is `user`, `system` or `provider`; each entry's `actor` is `{ type, id?, email, role, source? }`. |
| `GET /superadmin/observability?signal&limit` | failure window (SAAS-014): `{ since, counts, failures }`. `counts` covers every signal since the process started. `failures` lists the latest warnings and errors, newest first and already redacted. |

## Payment gateways — Super Admin (`/superadmin/payment-gateways`, 👑; SAAS-017)

The backend alone decides the gateway and environment:
- a new invoice's first checkout goes through the active gateway, in that gateway's current environment;
- every later step uses the gateway recorded on the invoice and the environment recorded on the order.

A response carries only what the panel may show:
- `provider`, `label`, `implemented`, `fieldsProvisional`, `enabled`, `environment`, `isActive`;
- `configured` and `needsReentry` for the current environment;
- `credentials.test` and `credentials.live`, each `{configured, needsReentry, hint, secretsSet, configuredAt}`;
- `canActivate`, `activationBlockedReason`, `testSupported`, `fields`, `updatedAt`.

It never carries a credential.

| Method | Path | Body | Does |
| --- | --- | --- | --- |
| GET | `/superadmin/payment-gateways` | — | `{ rows, vaultConfigured, active }` |
| GET | `/superadmin/payment-gateways/:provider` | — | one gateway |
| POST | `/superadmin/payment-gateways/:provider/config` | `{ environment, credentials: {field: value} }` | Saves that environment's credentials, encrypted, replacing what it had (rotation); the other environment is untouched. A blank secret keeps the stored one; every field must end up set. **503 `SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED`** when the server has no `PAYMENT_CREDENTIALS_KEY`. 400 for a missing field, a Razorpay key ID whose prefix is not the environment's, or a webhook secret equal to the API secret |
| PATCH | `/superadmin/payment-gateways/:provider` | `{ enabled?, environment? }` | Enables or disables it, and switches which environment's credentials new payments use. 409 when disabling the active gateway, or when switching to an environment with no credentials |
| POST | `/superadmin/payment-gateways/:provider/test` | `{ environment? }` | Returns `{ ok, checked, environment, detail }`: checks the stored credentials with the gateway, server to server, moving no money. For Razorpay that is `GET /v1/orders?count=1`. `checked: false` means nothing could be checked (no adapter, nothing configured); it is never reported as success |
| POST | `/superadmin/payment-gateways/:provider/activate` | — | Makes it the gateway for new payments. 409 with the reason unless it is implemented, enabled, and has credentials for its environment |
| POST | `/superadmin/payment-gateways/deactivate` | — | Returns `{ deactivated }`. Turns online payment off on purpose |

An unknown `:provider` is 404.

Audit actions: `gateway.configured`, `gateway.credentials_replaced`, `gateway.configuration_failed`,
`gateway.enabled`, `gateway.disabled`, `gateway.environment_changed`, `gateway.activated`,
`gateway.deactivated` and `gateway.test_attempted`. An entry names the gateway, the environment and which
fields changed, never a value.

## Invitations — `/invitations` (👩‍🏫 admin, `learners.enroll`; 5 Oct 2026)

An Admin's learner invitations, always in the Admin's own workspace (`lib/invitations.ts`).

| Method & path | Body | Returns |
| --- | --- | --- |
| `GET /invitations` | — | the workspace's invitations with status (`pending`, `accepted`, `revoked`, `expired`) |
| `POST /invitations` | `{ email? }` | `201` the invitation and its `/invite/<token>` link; the token is shown once and stored as a hash |
| `POST /invitations/:id/revoke` | — | the invitation, revoked; the link stops working |

The public side is under `/public/invitations/:token` (above): `GET` describes the invitation, `register` creates the
learner (after the emailed code), `sign-in` attaches an existing account.

## Course sales (24 Oct 2026)

A learner buys a paid course from their academy; the money settles to the academy's own Razorpay account, never the
platform's (`lib/coursePurchases.ts`, `lib/academyPayments.ts`). The price is the course's, all-inclusive, in whole rupees;
a course with no admin-chosen price is not for sale. Nothing in a body can set an amount.

| Method & path | Who | Body | Returns |
| --- | --- | --- | --- |
| `POST /learning/courses/:courseId/purchase` | 🔐 learner | — | `201` the purchase and the gateway's checkout parameters: one order for exactly the server's price; a second request while that order is open gets the same order. 409 when the learner already has the course, the course is not for sale, or the academy has no enabled gateway |
| `POST /learning/purchases/:purchaseId/confirm` | 🔐 learner | `{ paymentId, signature }` | The browser's return: the signature must be the gateway's, and the payment is read from the gateway server to server before anything settles |
| `GET /learning/purchases/:purchaseId` | 🔐 learner | — | the purchase's status (`created`, `paid`, `failed`, `expired`); checks the gateway when still open |
| `GET /learning/purchases` | 🔐 learner | — | `{ rows }` the learner's own purchases (the web's `/purchases`) |
| `GET /tenant/course-sales/settings` | admin (`settings.view`) | — | the academy's payment configuration: gateway, environment, enabled, which environments hold credentials, masked |
| `PUT /tenant/course-sales/settings` | admin (`settings.edit`) | `{ enabled, environment }` | updates it; enabling needs credentials for that environment |
| `PUT /tenant/course-sales/credentials/:environment` | admin (`settings.edit`) | `{ keyId, keySecret, webhookSecret }` | stores the academy's Razorpay credentials for `test` or `live`, encrypted; never returned |
| `POST /tenant/course-sales/credentials/:environment/test` | admin (`settings.edit`) | — | a no-charge credential check against the gateway |
| `GET /tenant/course-sales/purchases?courseId` | admin | — | the academy's course purchases, optionally for one course |

A purchase settles — marked `paid` and the enrolment opened, in one transaction, once — on whichever arrives first: the
browser confirm, the academy's signed webhook (`POST /webhooks/academies/:tenantId/razorpay/courses`), a status check, or the
scheduler's `checkout-recovery` job, and each believes only what the gateway itself reports. Refunds are manual, in the
academy's own Razorpay dashboard, and do not revoke access (`14-LAUNCH-CHECKLIST.md` A18). Course checkout is disabled in
the mobile app on `zuviloai.com` (`COURSE_CHECKOUT_ENABLED=false`).

## Affiliate program — Super Admin (`/superadmin/affiliates/…`, 👑; MLM-000)

The affiliate program's management surface (`15-MLM-AFFILIATE-ARCHITECTURE.md`), inside the Super Admin router. MLM-000
brings the plan; later modules add members, network, orders, ledgers, matching, ranks, rewards, wallets, withdrawals,
payouts, KYC and reports under the same prefix. Every term is validated by the domain's `validateMlmPlanTerms`; a refusal
is `400` with `issues[].field` naming the term (`tiers.3.groupCv`). Amounts are integer paise, rates basis points.

| Method & path | Body | Returns |
| --- | --- | --- |
| `GET /plan` | — | `MlmPlanOverview`: `active` (the version the engines run under, or null) and `versions` (summaries, newest first) |
| `GET /plan/versions` | — | `{ rows, total }` |
| `POST /plan/versions` | full `MlmPlanTermsInput`, or `{ fromVersionId? , programTenantId? }` | `201` a new **draft**: from the terms, from the named version, from the active one, or from the published plan (PDF version 1) bound to the LMS named or the default one |
| `GET /plan/versions/:id` | — | `MlmPlanTerms` |
| `PUT /plan/versions/:id` | `MlmPlanTermsInput` | Replaces a draft's terms, ranks and bands · `409` once the version has left draft |
| `PUT /plan/versions/:id/courses` | `{ eligibleCourseIds }` | The one change an active version allows (D-MLM-05); courses must be the program LMS's; `400` when it would leave an active version with none |
| `POST /plan/versions/:id/activate` | — | draft → active; the previous active version is retired in the same transaction · `400` without an eligible course · `409` from any other status |
| `POST /plan/versions/:id/retire` | — | active → retired; no version is active until another is activated |
| `DELETE /plan/versions/:id` | — | `204` for a draft · `409` for anything that has been active (kept for what was computed under it) |
| `GET /plan/courses?tenantId` | — | `{ rows: MlmProgramCourse[] }` — the LMS's courses, `priceAmount` only where the course is `paid` |

Audited: `mlm.plan.created`, `mlm.plan.updated`, `mlm.plan.courses_changed`, `mlm.plan.activated`, `mlm.plan.retired` (target `mlm_plan`).

### Members, network, placements and sponsors (👑, MLM-002)

| Method & path | Body | Returns |
| --- | --- | --- |
| `GET /superadmin/affiliates/members?tenantId&status&search&page&pageSize` | — | `{ rows: AffiliateMemberRow[], total, page, pageSize, counts }` across academies unless one is named |
| `GET /superadmin/affiliates/members/:id` | — | `AffiliateMemberRow` (sponsor, placement, team size, direct referrals, rank, KYC) |
| `PATCH /superadmin/affiliates/members/:id` | `{ status: 'active' \| 'suspended' \| 'terminated', note? }` | suspend, reactivate or terminate (final; the position stays). `409` to activate a pending affiliate by hand: the eligible purchase does that |
| `GET …/members/:id/tree?depth` · `GET …/members/:id/ancestors` · `GET …/members/:id/team?…` | — | as the affiliate's own reads, from any node |
| `POST …/members/:id/placement` | `{ parentId, leg, reason, moveSubtree? }` | a manual placement or move; `409 PLACEMENT_CYCLE` (under itself or its own team), `409 POSITION_TAKEN`, `409 PLACEMENT_INVALID` (a node with a team, unless `moveSubtree`, which rebases every descendant's path). History row + audit `mlm.placement.manual` |
| `PATCH …/members/:id/sponsor` | `{ sponsorId \| null, reason }` | corrects who referred them; past attribution and placement unchanged. Audited `mlm.sponsor.changed` |
| `GET /superadmin/affiliates/placements?affiliateId&tenantId&page` | — | `{ rows: PlacementHistoryRow[], … }` — every placement and move, newest first |
| `GET /superadmin/affiliates/sponsors?tenantId&search&page` | — | sponsors with `directReferrals` and `activeReferrals` |
| `GET /superadmin/affiliates/network/export.csv?root` | — | the genealogy under a node as CSV |

### Products, orders, the CV ledger and carry-forward (👑, MLM-003)

| Method & path | Body | Returns |
| --- | --- | --- |
| `GET /superadmin/affiliates/products` | — | `{ active: { id, version, programTenantId, eligibleCourseIds } \| null, courses: MlmProgramCourse[] }` — the active version's eligible courses against the program LMS's catalogue |
| `PUT /superadmin/affiliates/products` | `{ eligibleCourseIds }` | the same change as `PUT /plan/versions/:id/courses` on the active version; `404` with no active version, `400` when it would leave none. Audited `mlm.plan.courses_changed` |
| `GET /superadmin/affiliates/orders?tenantId&status&search&from&to&page&pageSize` | — | `{ rows: MlmOrderRow[], total, page, pageSize, counts }` — every verified sale of an eligible course, newest first; `search` matches the buyer's name, email or code |
| `GET /superadmin/affiliates/orders/:id` | — | `MlmOrderRow`: buyer (with `affiliateCode` when in the program), `sponsorCodeAtSale`, course, `netAmount`, `cv`, `status` (`pending`/`eligible`/`reversed`), `planVersion`, `paidAt`, `eligibleAt`, `reversedAt`/`reversalReason`, `creditedAncestors` |
| `POST /superadmin/affiliates/orders/:id/reverse` | `{ reason: 'refund' \| 'chargeback' \| 'manual', note? }` | negates the order's credits once (a `reversal` ledger row per `sale` row; pools never below zero) and marks it reversed · `409` when already reversed. Audited `mlm.order.reversed`; signal `mlm.reversal` (warn) |
| `GET /superadmin/affiliates/cv?affiliateId&tenantId&leg&kind&from&to&page&pageSize` | — | `{ rows: MlmCvLedgerRow[], … }` — the immutable ledger, newest first |
| `GET /superadmin/affiliates/cv/export.csv?…` | — | the same ledger as CSV (same filters) |
| `GET /superadmin/affiliates/carry-forward?tenantId&search&page&pageSize` | — | `{ rows: MlmCarryForwardRow[], … }` — per affiliate `lifetimeA/B`, `unmatchedA/B`, `matchedLifetime`, `lastMatchingRunDate`, largest pools first |

**How a sale becomes CV** (`lib/mlm/cv.ts`, `lib/purchaseHooks.ts`). When a course purchase settles (`markPaid` in `lib/coursePurchases.ts`, whichever of the confirm call, the webhook or the reconciler gets there first), the settlement transaction runs the registered *paid hooks*: the CV module records an `MlmOrder` for a purchase of an eligible course under the active plan (`netAmount` = the amount paid, `cv` = `cvBasisPoints` of it) and activates the buyer's affiliate row if they have one (`activatedAt`, `activationPurchaseId`). A hook that throws is reported (`job.failed`) and skipped, never allowed to undo a payment the gateway has taken. Once the transaction has committed, the *settled hooks* run: with `cvEligibilityDelayDays` 0 the order is made eligible at once — a `sale` row in `MlmCvLedger` for every ancestor on the buyer's placement path, in the leg the buyer hangs under (`creditsAlongPath` in the domain), and the `MlmLegBalance` pools updated in the same transaction. A buyer with a sponsor but no position yet is left `pending` until the placement job has run; a buyer outside the program credits nobody. The scheduler's `mlm-cv-eligibility` job (every tick, per academy) makes eligible every pending order whose delay has passed. Nothing in the ledger is ever updated or deleted (triggers); a reversal is a new negative row.


## Affiliate program — the learner's own (`/affiliate/…`, 🔐 learner only; MLM-001)

A learner's surface: the role guard's admin bypass is refused here. Every read is of the caller's own row.

| Method & path | Body | Returns |
| --- | --- | --- |
| `GET /affiliate` | — | `{ affiliate: AffiliateMe \| null }` — null for a learner who has not joined (a probe, not an error) |
| `POST /affiliate/enrol` | `{ referralCode?, preferredLeg? }` | `201 AffiliateMe`: a learner already in the academy opts in, with a sponsor's code (same academy, not terminated: else `404 REFERRAL_INVALID`) or none · `409` when already in |
| `PATCH /affiliate/preferred-leg` | `{ leg: 'A' \| 'B' }` | `AffiliateMe` — where the affiliate's own referrals are placed |
| `GET /affiliate/activation` | — | `AffiliateActivation`: `status`, `programActive`, the eligible courses with `purchase` (`none`/`pending`/`paid`/`enrolled`) · `404 NOT_AN_AFFILIATE` |

`AffiliateMe` carries `code`, `status` (`pending`/`active`/`suspended`/`terminated`), `preferredLeg`, `sponsor { name, code }`, `placement { parentCode, leg, depth }` (null until placed), `referralLink` (`<site>/ref/<code>`), `joinLink` (`<site>/join/<slug>?ref=<code>`), `qrUrl`, `academy`, `programActive`.

### The network (MLM-002)

| Method & path | Returns |
| --- | --- |
| `GET /affiliate/tree?root&depth` | `TreeNodeView`: the caller's subtree (or a downline member's, by `root`; a stranger is 404), `depth` 1–6 (default 3); beyond it `children` is null and `hasChildren` says what is there |
| `GET /affiliate/team?leg&status&search&page&pageSize` | `TeamPage`: everyone under the caller, flat, with `summary { directReferrals, total, byLeg, active, pending }` |
| `GET /affiliate/referrals` | `{ rows: TeamRow[] }` — the people the caller referred, wherever they were placed |

### Volume (MLM-003)

| Method & path | Returns |
| --- | --- |
| `GET /affiliate/figures` | `AffiliateFigures`: `lifetimeA/B`, `unmatchedA/B` (what is waiting), `matchedLifetime`, `lastMatchingRunDate`, `eligibleOrders`, `matchable` (the weaker leg's unmatched CV), `currency` |
| `GET /affiliate/cv?leg&kind&page&pageSize` | `{ rows: MlmCvLedgerRow[], total, page, pageSize }` — the caller's own ledger, newest first |

Placement (`lib/mlm/placement.ts`): a referral is placed as soon as it exists, on the sponsor's preferred leg or deeper in it by the active plan's `spilloverRule`; a sponsorless opt-in is a root. Two referrals arriving together cannot take one position (unique parent+leg; the loser searches again). The scheduler's `mlm-placement` job places anyone left unplaced.

### Referral links (🔓)

| Method & path | Returns |
| --- | --- |
| `GET /public/affiliates/ref/:code` | `ReferralInfo`: `sponsor { name, code }`, `academy { name, slug, open, invitationOnly }`, `program { active, course }`, `joinLink` · `404 REFERRAL_INVALID` for a malformed, unknown or terminated code (case and hyphens forgiven) |
| `GET /public/affiliates/ref/:code/qr.svg` | the referral link as an SVG QR (`image/svg+xml`, cached a day) |

**Registration doors carry the referral.** `POST /public/academies/:slug/register`, `POST /public/invitations/:token/register`, `POST /public/courses/:courseId/enroll` and `POST /auth/register` accept `referralCode?` and `preferredLeg?`. The code is checked when the door opens (`404 REFERRAL_INVALID` before any email goes out) and the affiliate row is created with the account — pending, sponsor set, placement left to the genealogy module. Without a code the learner is not an affiliate (D-MLM-06).

## Support — Tenant Admin (`/tenant/support`, any academy admin; SAAS-029)

`POST /tenant/support { subject ≥ 3, message ≥ 10 }` → `201 Inquiry` (kind `support`) — the academy and the person come
from the session (D3), never the body; lands in the Super Admin's inbox with `academy`; audited `inquiry.created`;
emailed to `SALES_NOTIFY_EMAIL` when set · `GET /tenant/support` → `{ rows: Inquiry[] }` — this academy's requests,
newest first, without the team's private `note`.

`GET /superadmin/overview` also answers `clients: { total, active, suspended, archived, selfRegistered }` and
`inbox: { new, inProgress }`; `GET /superadmin/tenants?search=` also matches the owner admin's name and email.

## Billing — Tenant Admin (`/tenant/…`, academy admin; SAAS-013)

The academy is always the signed-in admin's own: no route takes an academy id. Reads need `settings.view` and
changes `settings.edit`. There is no entitlement gate, so a restricted academy can still reach its subscription to
renew.

| Method & path | What it does |
| --- | --- |
| `GET /tenant/billing` | everything the billing page shows, in one read: `TenantBilling` (`packages/domain/src/billingViews.ts`), including `enforced` and `checkoutAvailable` |
| `GET /tenant/billing/invoices/:idOrNumber` | one of the academy's invoices, as shown; another academy's is not found |
| `POST /tenant/billing/trial` | `{ planId, cycle }` → `201 { subscription }`. Self-serve onboarding: an academy with no live subscription starts the plan's **free trial** itself — once per academy (unless `SUBSCRIPTION_REPEAT_TRIALS=on`), on a plan that offers one, with no payment or billing address. `409 PLAN_UNAVAILABLE` (no trial on that plan) or `INVALID_SUBSCRIPTION_STATE` (subscribed, or the trial is used). `GET /tenant/billing` says whether it is on offer (`trialAvailable`). Needs `settings.edit`. |
| `GET /academy/plan` | Any admin or instructor of the academy: `AcademyPlan` (`packages/domain/src/entitlement.ts`) — `enforced`, `status`, `restricted`, `plan`, `features`, `lastFeatures`, `trialEndsAt?`, `renewsAt?`. What the workspace shows each module as (`moduleAccess`: open, read-only, locked). No prices, invoices or payments. Students 403. |
| `POST /tenant/billing/purchase` | `{ planId, cycle }` → `{ checkout, invoice }`. The academy's **first subscription** (SAAS-009, extended). Only an academy with no live subscription: never subscribed, or its last one cancelled or expired. A trial is live and converts through its own invoice. The server prices the plan's current version with its tax, and issues one first-purchase invoice that records that version and cycle. The same choice again reuses it; another choice replaces it, unless a payment on it is under way. It then opens the checkout. Nothing else in the body is read. The subscription starts **only** when the provider confirms the payment, through the confirm endpoint or the webhook, once, on the version paid for. Answers `409 INVALID_SUBSCRIPTION_STATE` (already subscribed), `PLAN_UNAVAILABLE`, `PAYMENT_REQUIRED` (no provider), or `CONFLICT` (no billing address). |
| `POST /tenant/billing/checkout` | `{ invoiceId }` or `{ planChangeId }` → `{ checkout, invoice }` (SAAS-009). Opens the provider's checkout for an open invoice, or for an upgrade quote, which is invoiced first. The amount is the invoice's; the body cannot set one. An open checkout is reused. `409 PAYMENT_REQUIRED` when no provider is configured. |
| `POST /tenant/billing/checkout/confirm` | `{ orderId, paymentId, signature }` → `{ status, settled, applied, message }`. The signature must be the provider's, and the payment is then read from the provider. Only that answer is recorded, idempotently. It settles the invoice and moves the subscription: a trial converts, a period renews, a past-due subscription recovers, an upgrade applies. A failed renewal falls past due (§44). Another academy's order is not found. |
| `POST /tenant/subscription/preview` | `{ planId, cycle }` → what asking for that change would do, writing nothing: `kind`, `when` (`on_payment`\|`period_end`), `appliesAt`, `credit`, `charge`, `payable` with tax (or null), `needsBillingAddress`, and limit `conflicts`. Needs `settings.view`. |
| `POST /tenant/subscription/change` | `{ planId, cycle }`. The server says what it is: `{ change, payable }` for an upgrade, or `{ change }` with its date for a downgrade. An upgrade without a billing address is refused before anything is written. |
| `GET /tenant/subscription` | `{ subscription, plan, status, restricted, openPlanChange }` |
| `GET /tenant/subscription/usage` | per-limit `{ used, allowed, remaining, counts }`, plus `restricted` |
| `GET /tenant/subscription/entitlements` | features and limits served |
| `GET /tenant/plans` | plans on sale (read-only) |
| `POST /tenant/subscription/upgrade` | `{ planId, cycle }` → `{ planChange, payable }`. Activates only on a verified payment. |
| `POST /tenant/subscription/downgrade` | `{ planId, cycle }` → scheduled for the period end |
| `POST /tenant/subscription/plan-changes/:id/cancel` | withdraw an open change |
| `POST /tenant/subscription/cancel` | `{ immediately?, reason }` |
| `POST /tenant/subscription/resume` | `{ reason? }` |
| `GET /tenant/invoices` · `GET /tenant/invoices/:id` · `GET /tenant/payments` | the academy's own records |
| `GET` · `PUT /tenant/billing-profile` | the academy's billing details |

