# SyniastroLMS Flutter Application — Master Specification

**Scope:** `FLUTTER_MOBILE` · **App path:** `apps/mobile` · **Registry:** `.claude/flutter/modules.json` ·
**Workflow:** `.claude/flutter/workflow.md` · **Recovery state:** `.claude/flutter/progress.md`

This is the specification for a new, production Flutter client of SyniastroLMS. The existing backend
(`apps/api`) is the source of truth: the app consumes its real HTTP contracts and never replaces,
modifies or re-implements it.

**Sources this specification was built from** (read 22 Sep 2026, backend at `6339c9a` plus the uncommitted
SAAS-017 work then in the tree):

- LMS product requirements: `.claude/ui/*.md` (LMS-001 … LMS-016, LMS-019 subscriptions)
- SaaS requirements: `.claude/saas/subscriptions.md`, `.claude/saas/modules.json`, `.claude/saas/progress.md`
  (decisions D1–D11)
- Backend documentation: `docs/00`–`docs/11`, `docs/modules/*.md`
- Backend code: `apps/api/src/app.ts`, `lib/*.ts`, every file in `routes/`, `packages/domain/src/*.ts`
- The web client's integration seams (`apps/web/src/services/http/*`, `lib/razorpayCheckout.ts`) and its
  "Celestial Ink" design tokens (`apps/web/src/styles/tokens.css`)

**Markers used throughout** — each is also listed in §28 so nothing is lost:

| Marker | Meaning | What the workflow does |
| --- | --- | --- |
| **Needs clarification** | A product/business decision the documents do not make | Build the specified part; hide the unclear part behind an honest unavailable state; block only if the module cannot ship without it |
| **API contract required** | The backend has the capability but its contract is not readable/confirmed | Confirm from the route code first; if still unclear, block that item |
| **Backend capability required** | The app needs something the backend does not provide | Never fake it. Hide the feature; record it; block only if the module has nothing else to deliver |

---

## 1. Project Overview

SyniastroLMS is a multi-academy (SaaS) learning platform for Vedic-astrology schools. Each academy
(tenant) runs its own courses, instructors and learners on a subscription plan sold by the platform.

The backend is Express + Prisma (SQLite) with JWT bearer auth, tenant isolation at the query boundary,
per-admin permission keys, plan entitlements and limits, subscriptions with a state machine, invoices,
payments through a provider abstraction (Razorpay today; VyaparGateway being added), webhooks, and an
in-process scheduler. A React web app is the full-featured client for every role.

The Flutter application is a **new mobile client** focused on what people do on a phone:

- **Learners** — the complete learning experience: discover, enrol, learn, take quizzes, hand in work,
  join live classes, earn certificates, stay notified.
- **Instructors** — the teaching day: dashboard, grading, live classes, their learners, calendar,
  notifications, and publishing decisions.
- **Academy admins** — running the academy on the move: dashboard, people, enrolments, certificates,
  reports, and the academy's subscription.

Heavy authoring (course/lesson/quiz/template builders), academy configuration and all platform (Super
Admin) administration stay on the web (§2).

**Quality bar:** production. Every screen is backed by the real API, has loading/empty/error/offline
states, is accessible, works in light and dark, and is covered by tests. There is no demo mode and no
mock business data in the app.

---

## 2. Flutter Application Scope

### 2.1 In scope

| Experience | In the app | Module(s) |
| --- | --- | --- |
| Public (signed out) | Welcome, sign in, learner registration, forgot password, public catalog + course detail with free previews, certificate verification, help centre, privacy/terms | 004, 008 |
| Learner | Home, My Learning, Explore, enrol, course learning, lesson player (video, reading, document, practice, live), notes, bookmarks, quizzes, assignments, certificates, rank ladder, live classes, notifications, profile | 009–017 |
| Instructor | Dashboard, courses (read + publish/unpublish/archive/restore), curriculum (read), grading, quizzes overview, own learners (profile, enrol, message), live classes (schedule, edit, cancel, remind), calendar, notifications | 016–024 |
| Academy admin | Everything an instructor has at academy scope, plus suspend/restore learners, instructor directory/invite/status, certificate issue/revoke/restore, reports, subscription & billing | 016–027 |

### 2.2 Stays on the web (not in the app)

| Area | Why | Marker |
| --- | --- | --- |
| **Super Admin / platform** (`/superadmin/*`: tenants, admins, users, audit, observability, system, plans, subscribers, invoices, payments, refunds, tax rules, webhooks, **payment-gateway configuration**) | Platform operations, financial controls and gateway secrets are desk work; entering gateway credentials on a phone is a security risk. The docs place it in the web Super Admin shell. A `superadmin` who signs in to the app is told to use the web (FLUTTER-004). | Needs clarification (if a read-only platform glance is wanted later) |
| Course, chapter and lesson **authoring** (create/edit/reorder/duplicate/delete, content editors, uploads of lesson video) | LMS-002/004/005 specify multi-section editors designed for the web; video authoring on a phone is impractical | Needs clarification (is light mobile editing wanted?) |
| Quiz builder, assignment editor | Same | Needs clarification |
| Categories management | Admin taxonomy work (LMS-003) | — |
| Certificate template design | LMS-011 template/style editor | — |
| Academy settings (six sections, LMS-016) | Configuration, not daily operation | Needs clarification (read-only view on mobile?) |
| Tenant billing profile editing | Legal/billing address entry | Needs clarification |

### 2.3 Platform targets

| Target | Decision |
| --- | --- |
| Android phones | **In scope.** minSdk 24 (Android 7.0), targetSdk = latest installed stable (36). |
| Android tablets | **Adaptive support** (≥ 600dp two-pane where it helps: course + curriculum, review queue + submission, notifications list + detail). Not a separate design. |
| iOS | Code stays iOS-ready (no Android-only APIs without an iOS path), but iOS builds, signing and App Store release are **Needs clarification**. |
| Flutter web / desktop | Out of scope (the React app serves the web). |
| Orientation | Portrait everywhere; **landscape additionally** for the video player (fullscreen), the certificate preview, document viewer and — on tablets — every screen. |

---

## 3. User Roles

From `packages/domain/src/identity.ts` (`Role = 'student' | 'instructor' | 'admin' | 'superadmin'`) and
`docs/04`, `docs/11`:

| Role | Backend meaning | In the app |
| --- | --- | --- |
| `student` (learner) | Belongs to one academy (D1). Registers publicly into the host's default academy. Token carries `studentId`. Can be `suspended` (403 on login, `/auth/me` and every `/learning/*` route). | Learner experience |
| `instructor` | Belongs to one academy; invited by an admin. Token carries `instructorId`. Sees only courses they teach (server-derived scope; out-of-scope ids answer **404**). Passes `requireStaffPermission` on role alone. `inactive` instructors cannot sign in. | Instructor experience |
| `admin` (academy admin / "Tenant Admin") | Runs one academy. Passes every `requireRole`, but **each action also needs its permission key** (24 keys, live from the database, returned in `user.permissions`). Can be deactivated (`deactivatedAt`). | Admin experience |
| `superadmin` (platform) | Belongs to no academy; only `/superadmin/*` serves them; refused on academy routes. | Not served — "use the web" state |
| Visitor | Anonymous; requests run for the academy `DEFAULT_TENANT_SLUG` names | Public experience |

**Role is display and routing only in the app.** It comes from `GET /auth/me`, never from local state
that the user could edit, and the server re-checks it on every request.

---

## 4. Role-to-App Experience Matrix

✅ full · 👁 read-only · 🔒 own scope (server-enforced) · 🌐 web only · — not applicable

| Area | Visitor | Learner | Instructor | Admin | Super Admin |
| --- | --- | --- | --- | --- | --- |
| Sign in / register / forgot password | ✅ (register = learner only) | ✅ | ✅ (no register) | ✅ (no register) | sign-in refused → web |
| Public catalog, course detail, previews | ✅ | ✅ | ✅ | ✅ | — |
| Certificate verification | ✅ | ✅ | ✅ | ✅ | — |
| Help centre | ✅ (`audience=all`) | ✅ (`student`) | ✅ (`instructor`) | ✅ (`admin`) | — |
| Learner home, My Learning, Explore, enrol | — | 🔒 | — | — | — |
| Lesson player, notes, bookmarks | — | 🔒 | — | — | — |
| Quizzes (take) / Assignments (hand in) | — | 🔒 | — | — | — |
| Certificates wallet, rank ladder | — | 🔒 | — | — | — |
| Live classes (learner: register, join) | — | 🔒 | — | — | — |
| Notifications + preferences | — | 🔒 | 🔒 | 🔒 | — |
| Profile & app settings | — | ✅ | ✅ | ✅ | — |
| Staff dashboard | — | — | 🔒 | ✅ (`reports.view`) | — |
| Courses list/detail/stats, curriculum | — | — | 🔒 👁 | ✅ 👁 (`catalog.view`) | — |
| Publish / unpublish / archive / restore | — | — | 🔒 (review rule may refuse) | ✅ (`catalog.publish` / `catalog.archive`) | — |
| Course/lesson/quiz authoring | — | — | 🌐 | 🌐 | — |
| Grading & review queue | — | — | 🔒 | ✅ (`assessment.view` / `assessment.grade`) | — |
| Quizzes overview & stats | — | — | 🔒 👁 | ✅ 👁 (`assessment.view`) | — |
| Students roster/profile, enrol, message | — | — | 🔒 | ✅ (`learners.view` / `.enroll` / `.message`) | — |
| Suspend / restore learner | — | — | — | ✅ (`learners.suspend`) | — |
| Live classes (schedule, edit, cancel, remind) | — | — | 🔒 | ✅ (`live.manage` / `live.notify`) | — |
| Calendar | — | — | 🔒 | ✅ | — |
| Instructors directory & profile | — | — | 👁 (`instructors.view`) | ✅ (`.manage` / `.status`) | — |
| Certificates register / issue | — | — | 🔒 (issue) | ✅ (`certificates.issue`) | — |
| Revoke / restore certificate | — | — | — | ✅ (`certificates.revoke`) | — |
| Reports | — | — | 🔒 (no instructor report) | ✅ (`reports.view`, `reports.instructors.view`) | — |
| Academy subscription & billing | — | — | — | ✅ (`settings.view`; changes `settings.edit`) | — |
| Categories, templates, settings, platform | — | — | 🌐 | 🌐 | 🌐 |

---

## 5. Navigation Architecture

### 5.1 Router

`go_router` with one `GoRouter` built from a `routerProvider` that listens to the session state
(`refreshListenable`). A single `redirect` decides, in order:

1. Session `unknown` (restoring) → `/splash`.
2. Signed out → allow public routes; any other target → `/welcome?next=<target>` (the `next` is kept
   only if it matches the app's own route table — no open redirect, mirroring `lib/safeNext.ts`).
3. Signed in as `superadmin` → `/unsupported-role`.
4. Signed in → a public auth route (`/login`, `/register`) goes to the role's home; a route belonging to
   another role's shell goes to the role's home (UX only — the server refuses anyway).

### 5.2 Shells and bottom navigation

`StatefulShellRoute.indexedStack` per role, preserving each tab's stack. Phones: `NavigationBar`
(Material 3) with 4–5 destinations. Tablets (≥ 600dp): `NavigationRail`; ≥ 1024dp: extended rail.

| Role | Tabs (left → right) | Overflow ("More" sheet) |
| --- | --- | --- |
| Learner | Home · Courses (My Learning) · Live · Tests · Profile — five tabs, no "More" | None. Tests holds Tests \| Assignments; Courses opens Explore; Profile lists Certificates, Rank ladder, Notifications (also header bell), Help |
| Instructor | Dashboard · Review · Courses · Live · More | Students, Quizzes, Calendar, Notifications, Help, Profile |
| Admin | Dashboard · People · Courses · Review · More | Live, Calendar, Quizzes, Instructors, Certificates, Reports, Billing, Notifications, Help, Profile |

Every shell has an app bar with the page title and a **notification bell** with the unread count
(FLUTTER-016). Admin "People" is a segmented page: Students | Instructors.

### 5.3 Route table

Paths are the app's own; they mirror the web's where sensible so notification/dashboard links map
cleanly (§5.4).

```
Public
  /splash                          /welcome
  /login                           /register
  /forgot-password                 /reset-password/:token        (app link target, FLUTTER-028)
  /catalog                         /catalog/:slug
  /catalog/:slug/preview/:lessonId /verify   /verify/:credentialId
  /help  /help/:categoryId  /help/article/:slug
  /legal/privacy  /legal/terms     /unsupported-role

Learner (shell)
  /home   /my-learning/:tab (in-progress|completed|saved)   /explore
  /learn/:courseId                 /learn/:courseId/lessons/:lessonId
  /assignments  /assignments/:assignmentId   /assessments
  /live  /live/:liveId             /certificates  /certificates/:certificateId   /ranks
  /notifications  /notifications/preferences  /notifications/:notificationId
  /profile  /profile/settings

Staff (shell; instructor and admin share screens, scope comes from the server)
  /staff  (dashboard)
  /staff/courses  /staff/courses/:courseId  /staff/courses/:courseId/curriculum
  /staff/courses/:courseId/lessons/:lessonId            (read-only lesson view)
  /staff/review  /staff/assignments/:assignmentId/submissions
  /staff/submissions/:submissionId
  /staff/quizzes  /staff/quizzes/:quizId
  /staff/students  /staff/students/:studentId (tabs: overview|courses|progress|activity)
  /staff/live  /staff/live/new  /staff/live/:liveId  /staff/live/:liveId/edit
  /staff/calendar  /staff/calendar/new  /staff/calendar/:eventId  /staff/calendar/:eventId/edit
  /staff/notifications ... (same three as learner)
  /staff/profile ...

Admin only (inside the staff shell)
  /staff/instructors  /staff/instructors/:instructorId (tabs: overview|courses|performance)
  /staff/instructors/invite
  /staff/certificates  /staff/certificates/:certificateId
  /staff/reports  /staff/reports/courses  /staff/reports/courses/:courseId
  /staff/reports/learners  /staff/reports/instructors  /staff/reports/enrolments
  /staff/billing  /staff/billing/invoices/:invoiceId  /staff/billing/plans
```

Typed routes: each route has a `const` path and a typed builder (`AppRoutes.lesson(courseId, lessonId)`);
no string concatenation in feature code.

### 5.4 Mapping backend web paths to app routes

The backend returns **web** paths in `AppNotification.action.to`, dashboard `attention[].to`,
`events[].to`, learner `upcoming[].to`. `lib/app/routing/web_path_mapper.dart` maps them:

| Web path pattern | App route |
| --- | --- |
| `/learn/:c/lessons/:l`, `/learn/:c` | same |
| `/live/:id` (learner) · `/admin/live/:id`, `/teach/live/:id` | `/live/:id` · `/staff/live/:id` |
| `/assignments/:id` (learner) | `/assignments/:id` |
| `/admin|teach/assignments/:a/submissions/:s` | `/staff/submissions/:s` |
| `/admin|teach/assignments(?review)` | `/staff/review` |
| `/certificates/:id` · `/admin/certificates/:id` | `/certificates/:id` · `/staff/certificates/:id` |
| `/admin|teach/courses/:id(/…)` | `/staff/courses/:id` |
| `/admin|teach/students/:id(/…)` | `/staff/students/:id` |
| `/admin/billing` | `/staff/billing` |
| `/notifications(/…)`, `/verify/:id`, `/courses/:slug` | the app equivalents |
| anything else | no navigation; the item stays readable where it is (never open an unknown path in a WebView) |

The mapper is pure and exhaustively unit-tested with every path the backend emits (grep
`to:` / `action:` in `apps/api/src`).

### 5.5 Back behaviour and state restoration

Android back pops within a tab, then returns to the first tab, then exits. Unsaved-changes guards
(`PopScope`) on assignment drafts, grading, live-class and event forms ask "Leave without saving?".
Scroll position and tab selection survive tab switches (indexed stack).

---

## 6. Authentication Architecture

Backend facts (`routes/auth.ts`, `lib/auth.ts`, `lib/requestContext.ts`):

- `POST /auth/login {email, password}` → `{token, user}`; `POST /auth/register {name, email, password}` →
  `201 {token, user}` (always a learner, default academy); `GET /auth/me` → `{user}`.
- JWT HS256, **7-day lifetime, no refresh token, no logout endpoint, no server-side revocation.**
- An invalid/expired token is ignored (request becomes anonymous) → protected routes answer **401
  `{message: "Sign in required"}`** (no `code`, except on `/tenant` where it is `UNAUTHENTICATED`).
- Refusals at login / `/auth/me`: 401 wrong credentials (same for unknown email); 403 deactivated
  account; 403 suspended learner; 403 inactive instructor.
- Forgot password → always `{ok:true}`; the email links to the **web** `APP_URL/reset-password/<token>`;
  `GET /auth/reset-password/:token` → `{valid}`; `POST /auth/reset-password {token, password}`.
- `UserProfile = {id, name, email, role, descriptor, instructorId?, permissions?}`; `permissions` is
  present on login and `/auth/me` (`[]` for non-admins), **absent on register**.

App design:

| Concern | Design |
| --- | --- |
| Token storage | `flutter_secure_storage` (Android Keystore-backed `EncryptedSharedPreferences`; iOS Keychain `first_unlock_this_device`). Never SharedPreferences, never logs. Stored with the environment id so a staging token is never sent to production. |
| Session model | `SessionState = unknown | signedOut(reason?) | signedIn(UserProfile)` in a `sessionControllerProvider`. The token lives only in `TokenStore`; the UI never sees it. |
| Restore on launch | Read token → `GET /auth/me`. 200 → signedIn. 401 → clear, signedOut(expired). 403 → clear, signedOut(deactivated / suspended with the server's message). **Network failure → keep the token and show the offline splash with Retry** (never sign someone out because they are offline). |
| Register | After `201`, call `GET /auth/me` once to load `permissions` and the canonical profile before entering the shell. |
| Expiry / 401 anywhere | The auth interceptor, on a 401 from any request that carried a token, clears the token once (single-flight), cancels in-flight requests, and moves to `signedOut(expired)`; the router shows sign-in with "Your session ended. Sign in again." and keeps `next`. No refresh attempt exists to make. |
| Deactivation / suspension mid-session | A 403 whose message is the deactivated/suspended text on `/auth/me` or `/learning/*` (learner suspension) → signedOut with that message. A deactivated admin hits `403 PERMISSION_DENIED` "This account has been deactivated." → same. |
| Sign out | Client-only: delete token, clear image/HTTP caches, in-memory repositories (invalidate all providers), notification badge, and any temp files; return to `/welcome`. The UI says nothing about "revoking" — the backend cannot. **Backend capability required:** token revocation / logout endpoint (known limitation, docs/11 §24). |
| Super Admin | A `superadmin` login succeeds on the API; the app then discards the token and shows `/unsupported-role` ("Platform administration is available on the web"). |
| Forgot / reset password | In-app request screen. The email opens the web reset page today. When App Links are verified (FLUTTER-028) the same URL opens `/reset-password/:token` in the app, which checks `valid` then posts the new password. |
| Rate limiting | `/auth` POSTs: 30 per 15 min per IP; a 429 shows "Too many sign-in attempts. Try again later." and disables the button briefly. |
| Biometric unlock | Not specified — **Needs clarification**. Not built. |

---

## 7. Authorization Architecture

Layers, in the backend's fixed order (`docs/04`, `subscriptions.md` §33) — and the app's mirror of each:

```
Authenticated        → session state (§6)
  → Role             → which shell and routes exist (routing only)
  → Permission       → capability gates from user.permissions (admins) / role (instructors)
  → Tenant           → never handled by the app; implied by the account (§8)
  → Entitlement      → refusal states + admin prefetch (§9)
  → Operation        → the API call; its refusal is always handled
```

**Capabilities, not role checks, in feature code.** `lib/core/auth/capabilities.dart` defines an enum of
app capabilities, each mapped to the guard the backend applies:

| Capability (examples) | Backend guard | Instructor | Admin |
| --- | --- | --- | --- |
| `viewCourses`, `publishCourse`, `archiveCourse` | `requireStaffPermission(catalog.view / catalog.publish / catalog.archive)` | role passes | needs key |
| `viewAssessments`, `gradeSubmissions` | `requireStaffPermission(assessment.view / assessment.grade)` | role passes | needs key |
| `viewLearners`, `enrollLearners`, `messageLearners` | `requireStaffPermission(learners.*)` | role passes | needs key |
| `suspendLearners` | `requirePermission(learners.suspend)` | ✗ | needs key |
| `viewInstructors` / `manageInstructors` / `setInstructorStatus` | `instructors.view` (staff) / `instructors.manage`, `instructors.status` (admin) | view only | needs key |
| `issueCertificates` / `revokeCertificates` | `certificates.issue` (staff) / `certificates.revoke` (admin) | issue only | needs key |
| `manageLive`, `notifyLive` | `live.manage`, `live.notify` (staff) | role passes | needs key |
| `viewReports` / `viewInstructorReport` | `reports.view` (staff) / `reports.instructors.view` (admin) | reports only | needs key |
| `viewBilling` / `changeBilling` | `/tenant`: `requireRole('admin')` + `settings.view` / `settings.edit` | ✗ | needs key |

`can(capability)` evaluates from the signed-in `UserProfile` only; a missing `permissions` field means
**none**, never all. The table is verified against the route files in FLUTTER-006 and re-audited in
FLUTTER-030.

Rules:

- A hidden or disabled control is UX. Every screen still handles the server's `403`/`404` for the same
  action (e.g. a permission revoked since sign-in). Permissions are re-read from `/auth/me` on app resume
  (throttled to once per 5 min) because the backend applies revocations on the next call.
- Out-of-scope ids answer **404**, not 403 (instructor lateral access, learner ownership). The app shows
  "not found" — it never tries to distinguish "exists but not yours".
- No `if (role == 'admin')` in feature code outside the router and the capability table.
- **Never** a plan-name check (`plan == 'Professional'`) anywhere — mirrored from the backend's ESLint rule
  by a custom test that scans `lib/` for comparisons against plan codes/names.

---

## 8. Tenant Context

Backend facts (D1–D3, `lib/requestContext.ts`): a person belongs to exactly one academy; the academy
comes from the account's row on every request; **no header, query or body can select an academy**;
anonymous requests run for the academy `DEFAULT_TENANT_SLUG` names; ids from another academy answer 404.

App rules:

1. The app **never sends a `tenantId`** (or academy slug) anywhere, never stores one, and never models
   one in a request. The `tenantId` claim inside the JWT is not decoded or used.
2. Signed-in data is always the user's academy. Nothing to switch, no academy picker (D2: email unique
   platform-wide).
3. Signed-out screens (catalog, register, verify) show the **host's default academy**. One build targets
   one API host.
4. Everything cached in memory or on disk is scoped to the signed-in user and purged on sign-out or user
   change, so one person's academy data never shows to the next.

**Needs clarification — multi-academy distribution.** Should one app serve every academy (then public
screens show only the default academy, and a learner can only self-register into it), or should academies
get white-label builds (per-academy base URL/branding)? The architecture supports both (base URL and
brand are build config), but public academy selection would need a **Backend capability** (a public
academy lookup and per-academy registration), which does not exist.

**Needs clarification / Backend capability required — academy branding.** Academies have `appearance`
settings (brand name, accent), but no endpoint exposes them to learners (`GET /settings` is staff-only).
The app ships the platform's Celestial Ink theme; per-academy theming needs a learner-readable branding
endpoint.

---

## 9. Subscription / Entitlement Integration

Backend facts (`lib/entitlements.ts`, `lib/usage.ts`, `docs/06` enforcement matrix):

- Enforcement is a server switch (`ENTITLEMENT_ENFORCEMENT`, off by default). While off, the app never
  sees entitlement refusals. `TenantBilling.enforced` tells an admin which mode is live.
- Refusals: `402 SUBSCRIPTION_REQUIRED` (no plan / paused), `402 SUBSCRIPTION_EXPIRED` (canceled/expired),
  `403 FEATURE_NOT_INCLUDED`, `403 LIMIT_REACHED`, all `{message, code}` — **no machine field names the
  feature or limit**; only the English message does.
- Gates govern *adding and changing*; reading, withdrawing (unpublish/archive/revoke) and serving existing
  learners are never blocked. The dashboard is never gated. Restricted mode allows read/update/withdraw/
  serve_learners.
- Features: `courses.manage`, `assessments.manage`, `certificates.manage`, `live_classes`,
  `reports.basic`, `reports.advanced`, `analytics.advanced`, `custom_branding`, `priority_support`.
  Limits: `learners.max`, `instructors.max`, `courses.max`, `storage.bytes`, `live_classes.max`
  (per UTC month), `admin_accounts.max`; `null` = unlimited.
- Readable only by an academy admin with `settings.view`: `GET /tenant/billing`,
  `/tenant/subscription`, `/tenant/subscription/usage`, `/tenant/subscription/entitlements`.

App design:

1. **Reactive first.** Every feature handles the four codes through one mapper
   (`EntitlementRefusal` → shared `SubscriptionStateView` / inline banner) with copy per code, the server's
   message shown as the detail, and — for admins with `viewBilling` — a "Review plan" action to
   `/staff/billing`. Learners and instructors see "Your academy's plan doesn't include this. Contact your
   academy." (never billing details).
2. **Admin prefetch (UX only).** For admins with `viewBilling`, `academyPlanProvider` loads
   `/tenant/subscription/entitlements` + `/tenant/subscription/usage` on shell entry and on resume
   (cached ≤ 5 min). It drives: an academy-wide banner when `restricted` is true (no plan, paused, expired,
   past-due wording from `TenantBilling.subscription.status`), a "feature not in plan" hint on the
   relevant create buttons, and limit meters (e.g. "Live classes this month 8 / 10"). The server still
   decides every call.
3. **No local rules.** The app never computes whether a feature is included from a plan's name or price,
   never infers limits, never hides existing data because of plan state, and never caches entitlements
   across sign-outs.
4. **Instructors** cannot read `/tenant/*`; they get reactive refusals only. **Backend capability required
   (optional enhancement):** expose the served features to all staff (e.g. on `/auth/me`) so instructor UIs
   can pre-mark unavailable actions.
5. Subscription statuses arrive in two spellings: snake_case on `/tenant/subscription*`
   (`trialing, active, past_due, paused, canceling, canceled, expired`) and hyphenated UI values on
   `/tenant/billing` (`trial, active, past-due, canceling, canceled, paused, expired`). Each endpoint's
   model uses its own enum; one `SubscriptionStatusView` maps both to labels/tones.

---

## 10. API Architecture

### 10.1 Layering

```
Widget (ConsumerWidget) ── watches ──> Controller (Riverpod Notifier / AsyncNotifier)
Controller ── calls ──> Repository (feature/data)          returns Result<T, AppFailure>
Repository ── calls ──> Feature API service (feature/data)  returns DTOs, throws ApiException
API service ── uses ──> ApiClient (core/network, Dio)       one instance, interceptors
ApiClient ── HTTPS ──> SyniastroLMS API
```

- Widgets never import Dio, `ApiClient`, API services or repositories directly — only providers of
  controllers. Enforced by an import-boundary test (`test/architecture/imports_test.dart`) that parses
  `lib/` imports.
- A feature exposes a public barrel (`features/<f>/<f>.dart`) with its routes, and — only when another
  feature genuinely needs it — a domain model. Cross-feature calls go through `lib/shared` contracts.

### 10.2 `ApiClient`

- Base URL from the environment: dev `http://10.0.2.2:4100` (local contract server) or `http://<LAN>:4000`,
  staging/production `https://<host>/api` (the production API is mounted under `/api` by `web.ts`).
- Timeouts: connect 10 s, send 30 s (uploads: none + progress), receive 30 s.
- Interceptors, in order: `RequestIdInterceptor` (adds `X-Request-Id` for log correlation — server
  ignores unknown headers), `AuthInterceptor` (adds `Authorization: Bearer`; single-flight 401 handling
  §6), `RetryInterceptor` (GET/HEAD/idempotent PUT only; network errors, 502/503/504; 2 retries with
  jittered backoff; never POST), `ErrorInterceptor` (→ `ApiException`), `LogInterceptor` (redacted, debug
  builds only).
- JSON only; `Accept: application/json`. Responses of `204` and bare-number bodies
  (`/notifications/read-all`, `/notifications/clear`) and literal `null` (failed quiz attempt) are handled
  explicitly by the calling service, never by a generic "parse object" path.
- Cancellation: every request takes a `CancelToken` tied to the provider's lifecycle (`ref.onDispose`).

### 10.3 Error decoding

Body `{message, issues?, code?}` →

| HTTP | `code` | `AppFailure` |
| --- | --- | --- |
| — | — (no response) | `NetworkFailure(offline | timeout | dns | tls)` |
| 400 | `VALIDATION_FAILED`/none | `ValidationFailure(issues: [{path, message}])` — mapped to form fields by `path` |
| 401 | `UNAUTHENTICATED`/none | `UnauthenticatedFailure` (triggers §6) |
| 402 | `SUBSCRIPTION_REQUIRED` / `SUBSCRIPTION_EXPIRED` | `EntitlementFailure(kind)` |
| 403 | `PERMISSION_DENIED` | `PermissionFailure` |
| 403 | `FEATURE_NOT_INCLUDED` / `LIMIT_REACHED` | `EntitlementFailure(kind)` |
| 403 | none | `ForbiddenFailure(message)` (role refusals, suspended, deactivated, review-before-publish) |
| 404 | any | `NotFoundFailure` |
| 409 | `PLAN_UNAVAILABLE` / `PAYMENT_REQUIRED` / `INVALID_SUBSCRIPTION_STATE` / `CONFLICT` / none | `ConflictFailure(code, message, issues: [{field, message}])` — domain checklist issues (publish checklist, lesson issues, validator issues) rendered as a list |
| 413 | any | `PayloadTooLargeFailure` |
| 429 | none | `RateLimitedFailure` |
| 502 | `PAYMENT_FAILED` | `PaymentFailure` |
| 5xx | any | `ServerFailure` (generic copy; message not shown if it is the generic one) |
| — | parse error | `ContractFailure` (logged with the endpoint, reported to crash reporting without the body) |

The server's `message` is written for people and may be shown as the detail line; the app's own copy is
the title. Unknown `code` values fall back by HTTP status.

### 10.4 Models

- `freezed` + `json_serializable`, one file per endpoint group under `features/<f>/data/dto/`. Field names
  are the backend's (camelCase). Enums use `@JsonEnum` with an `unknown` fallback
  (`unknownEnumValue: X.unknown`) so a new server value never crashes the app.
- Dates: ISO strings parsed to `DateTime` (UTC) by a shared converter; displayed per §21.
- Money: `int` minor units + ISO currency; never `double` (§11).
- DTO → domain mapping in the repository when the screen needs a different shape; otherwise DTOs are the
  models (no ceremony for its own sake).
- **Only fields the backend returns are modelled**, verified against the route code at implementation
  time. Request models contain **only** fields the route's zod schema reads.

### 10.5 Results and pagination

`sealed class Result<T, F>` (`Ok`/`Err`) from repositories. Paged lists (`{rows, total, counts}`, `page`,
`pageSize` ≤ 500) use a shared `PagedController<T>` with infinite scroll (page size 20), pull-to-refresh,
and `counts` feeding filter-chip badges. Lists the backend returns unpaged are rendered with lazy
`ListView.builder` and client-side search only where the server has no `search` param.

---

## 11. Payment Architecture

Backend facts (`lib/checkout.ts`, `lib/paymentProvider.ts`, `routes/tenant.ts`, D11, SAAS-017):

- Only an **academy admin** pays (for the academy's platform plan). **Learners never pay**: enrolment is
  direct; there is no course checkout (`docs/02`). No learner payment UI exists in the app.
- Start: `POST /tenant/billing/purchase {planId, cycle}` (first subscription) or
  `POST /tenant/billing/checkout {invoiceId} | {planChangeId}`. **No amount is ever sent**; unknown keys
  are dropped by the server.
- Response `CheckoutStart = { checkout: CheckoutParams, invoice: {id, number, total, currency} }` where
  `CheckoutParams = { provider, keyId?, orderId, amount, currency, redirectUrl? }` (`keyId` required in the
  committed domain type; optional + `redirectUrl` in the SAAS-017 work in progress). The backend chooses
  the provider; an invoice stays pinned to the gateway of its first checkout.
- Confirm: `POST /tenant/billing/checkout/confirm {orderId, paymentId, signature}` → `CheckoutOutcome
  {status: pending|authorized|paid|failed|refunded, settled, applied, message}`. The server verifies the
  signature and reads the payment from the provider itself. A webhook can also settle it. **There is no
  payment-status endpoint**; the client re-reads `GET /tenant/billing`.

App design — **provider-agnostic launcher**:

```
BillingController ──> BillingRepository.startCheckout(...) ──> CheckoutStart
        │
        └─> CheckoutLauncherRegistry.launcherFor(checkout)      // chosen by checkout.provider + shape
               ├─ RazorpayCheckoutLauncher   (provider == 'razorpay' && keyId != null)
               ├─ HostedPageCheckoutLauncher (redirectUrl != null; https only; Custom Tab)
               └─ UnsupportedCheckoutLauncher (anything else → "Complete this payment on the web")
        launcher.launch(checkout) ──> ProviderResult (success{orderId, paymentId, signature} | cancelled | failed{reason})
        │
        └─> success: BillingRepository.confirm(...) → CheckoutOutcome → re-read /tenant/billing
            pending/authorized: poll /tenant/billing every 5 s up to 60 s, then "We'll update this when the
            payment is confirmed" (no activation is ever inferred client-side)
```

Rules:

1. The app never decides the gateway, the amount, tax, price, currency, plan price, tenant, status or
   entitlement. It displays `invoice.total`/`currency` the server returned and passes the server's
   `orderId`/`amount`/`keyId` to the SDK unchanged.
2. No gateway secret, webhook secret or credential ever exists in the app; `keyId` (publishable) arrives
   per checkout and is held only for that checkout.
3. A provider "success" callback **never** changes UI state to "active"; only the server's
   `CheckoutOutcome`/re-read does.
4. VyaparGateway: **API contract required** (the backend itself records its contract as unpublished; no
   adapter exists). Until the backend exposes a checkout shape for it, it falls to
   `UnsupportedCheckoutLauncher`. The redirect/hosted flow also needs a **Backend capability**: a
   return/confirm path for redirect gateways (the confirm endpoint is Razorpay-shaped).
5. **Needs clarification — app-store payment policy.** Buying a SaaS plan inside a mobile app may be
   subject to Google Play (and App Store) billing rules. Until the product owner confirms in-app checkout
   is permitted, the build flag `BILLING_CHECKOUT_ENABLED=false` (default) ships billing **read-only**:
   plan, status, renewal, usage, features, invoices and payments, with no purchase/upgrade/pay controls.
   The launcher and its tests are still built; `razorpay_flutter` is added only when the flag is approved.
6. Invoices are JSON only — **Backend capability required** for a PDF/download. The app renders the
   invoice itself (read-only) and offers no download.

---

## 12. Notification Architecture

Backend facts (`routes/notifications.ts`, `lib/notify.ts`): in-app notifications per user with
categories `course, assignment, quiz, live, certificate, enrollment, system`; list
(`unreadOnly`, `category`, `limit ≤ 200`) with `unread` and per-category `counts`; detail (opening marks
read); mark read/unread by ids; read-all; remove + restore (undo); clear; per-user settings (channels per
category app/email/sms, email digest, quiet hours, pause). Email is an outbox; **SMS has no transport**;
**there is no push transport and no device-registration endpoint; no WebSocket/SSE.**

App design:

- **In-app centre** (FLUTTER-016) for every role, polling-based: unread count refreshed on app resume, on
  shell entry, after any notification mutation, and every 60 s while the app is foregrounded (paused in
  background). Pull-to-refresh on the list.
- Detail uses `action`/`secondaryAction` → §5.4 mapper.
- Preferences edit exactly the server's settings shape; the `system` category's app+email channels are
  locked (server rule) and shown as such; SMS shown as "SMS isn't available yet" if `smsEnabled` is off —
  never as a working channel.
- **Push (FLUTTER-028): Backend capability required** — a device-token registration/unregistration
  endpoint and a push transport (FCM) on the server. When provided: `firebase_messaging`, token registered
  after sign-in and removed on sign-out, payload treated as a *hint* (id + category only); the app fetches
  the notification from the API before showing anything; unknown/malformed payloads are dropped;
  Android 13+ runtime permission asked in context (after the first meaningful notification, not at
  launch). Firebase project/credentials: **Needs clarification** (credential).

---

## 13. Media Architecture

Backend facts (`routes/media.ts`, `lib/media.ts`):

- Upload `POST /media/upload`, multipart, one field `file` → `201 {id, name, sizeMb, url: "/media/<id>",
  mime, kind}`. Allow-list (MIME **and** extension): video mp4/webm/mov ≤ 500 MB (staff only),
  PDF ≤ 25 MB, PNG/JPG/WebP ≤ 5 MB. Learners: PDF and images only.
- Serve `GET /media/:id` — **Bearer required**; no signed or public URLs; `Range` supported (206);
  `Cache-Control: private, max-age=3600`; learners' own uploads readable only by them and staff (else 404).
- No HLS/DASH/transcoding; files are served as uploaded. Lesson media is `MediaFile {name, sizeMb, id?,
  url?, mime?}` inside lesson content.

App design (FLUTTER-007):

| Need | Approach |
| --- | --- |
| URL resolution | `MediaUrlResolver`: relative `/media/<id>` → `<apiBase>/media/<id>`; refuses absolute URLs to other hosts |
| Images (instructor photos, attachments) | `cached_network_image` with `httpHeaders: {Authorization}` from `TokenStore`; cache manager keyed per user; purged on sign-out |
| Video | `video_player` with `httpHeaders` (range requests streamed by ExoPlayer/AVPlayer); custom controls from the design system (play/pause, ±10 s, scrubber with chapter markers from `content.video.markers`, speed 0.75–2×, captions toggle only if `captions` true and a caption track exists — **API contract required** for caption files: none is modelled), fullscreen landscape; position reported per §14/FLUTTER-011 |
| PDF | Downloaded with the bearer header to the app's temp dir, rendered in-app (`pdfrx`); deleted on close and on sign-out; no external "open with" unless the lesson's `downloadable` is true — and even then only a share of the local file after an explicit tap (**Needs clarification** whether downloads may leave the app) |
| Upload | `file_picker` → client pre-check of extension, MIME (via `mime` lookup) and size against the server table (UX only; the server re-checks) → `ApiClient.upload` with progress and cancel → `MediaFile` |
| Large video on cellular | Show a one-time "You're on mobile data" notice before playing video > 50 MB (UX only) |
| Screen capture | Paid content protection (`FLAG_SECURE`) — **Needs clarification** (not enabled by default: it also blocks accessibility tools and screenshots of certificates) |

---

## 14. Live Class Architecture

Backend facts (`routes/live.ts`, `packages/domain/src/live-class.ts`):

- Learner list `GET /live/learner` → `{live, upcoming (with registered), recordings}` for enrolled courses;
  register is a **toggle** `POST /live/:id/register` → `{registered, spotsLeft}` (999 = unlimited).
- `meeting: {kind: 'room' | 'external', link?}`. `'room'` has **no implementation** on the server (no
  provider, token or URL). `'external'` carries an `https://` link. The API schema names it `url` but the
  domain validator requires `link` — **API contract required**: FLUTTER-023 must confirm which field staff
  writes must send (read path is `link`).
- Phases via `deriveLiveClassPhase`: `upcoming → starting-soon (T-15 min) → live → ended |
  recording-expired`, `cancelled` anytime. `canJoin` = starting-soon or live — computed client-side in the
  web; the server does not enforce a join window.
- No attendance write, no recording write, no real-time channel.

App design:

- **Phase is derived for display** with the same rule as `packages/domain` (`JOIN_WINDOW_MIN = 15`), using
  the **server's timestamps** and the device clock. This is presentation, not authorization; ported as a
  pure function with tests mirroring the domain's cases. A 30 s ticker re-evaluates phase on visible
  live screens.
- **Join** opens `meeting.link` externally (`url_launcher`, `LaunchMode.externalApplication`) only if it
  is `https`. Kind `room` or no link → "The join link isn't available yet — your instructor will share it"
  (**Backend capability required** for an in-academy room). No in-app WebView for meetings.
- "Add to calendar" is not specified — not built.
- Staff: schedule/edit (full-object `PATCH`), cancel with reason, remind, reminder offsets — FLUTTER-023.

---

## 15. Local Storage

| Data | Store | Why |
| --- | --- | --- |
| JWT | `flutter_secure_storage` | Secret |
| Environment id bound to the token | `flutter_secure_storage` | Prevents cross-environment token use |
| Theme mode, text-scale preview choice, reduced motion, last selected tabs/filters, "seen mobile-data notice", onboarding seen | `shared_preferences` | Non-sensitive UX preferences |
| API responses | **In memory only** (Riverpod providers with `keepAlive` + TTL where useful) | No offline database is required by any LMS document; avoids persisting academy data, grades or personal data |
| Images | `cached_network_image` disk cache, per-user key, purged on sign-out | Performance |
| Downloaded PDFs / picked upload files | App temp dir; deleted after use and on sign-out | Viewing/uploading only |
| Unsent text (assignment draft, note, grading feedback) | In memory with a visible "Not saved" state and retry; the server persists drafts/notes | Server is the durable store |

Nothing sensitive in `shared_preferences`. No `GetStorage`. No SQLite/Isar/Hive unless a future
requirement (offline downloads) is clarified.

---

## 16. Error Handling

- **Typed failures** (§10.3) flow to controllers as `Result`; controllers expose `AsyncValue`/sealed UI
  states; widgets render them with the shared state views (§22.6).
- **Per surface:** full-page error (retry) when the primary data fails; inline error rows for secondary
  sections (a dashboard card that failed does not blank the page); snackbar for failed mutations with the
  form/dialog kept open and the server's issues shown in place (never lose the user's input).
- **Validation:** client-side for required/format/length exactly as the route's zod schema states (UX);
  server `issues` mapped to fields by `path`/`field`; an error summary at the top of long forms focusing
  the first invalid field.
- **Global:** `FlutterError.onError`, `PlatformDispatcher.instance.onError` and a guarded zone send to
  `CrashReporter` (redacted), show a friendly error boundary for a crashed route with "Go home", and never
  show stack traces to users.
- **Contract errors** (a response fails to parse) are logged with endpoint and field path, reported
  without the body, and shown as a generic error — then fixed by correcting the model against the backend.
- Copy tone: plain, specific, calm ("We couldn't load your courses. Check your connection and try again."),
  matching the web product's voice.

---

## 17. Network Handling

| Situation | Behaviour |
| --- | --- |
| No connectivity | `connectivity_plus` is a hint only; the real signal is a failed request. Offline banner in the shell; screens keep showing already-loaded data with "You're offline — showing what was loaded"; mutations disabled with explanation; auto-retry of the visible screen's load when connectivity returns |
| Timeout / slow network | Skeletons appear after 150 ms; after 8 s a "Still working…" line; timeouts → `NetworkFailure(timeout)` with Retry |
| API unavailable (5xx / 502–504) | Idempotent GETs retried twice with backoff; then full-page error with Retry; the splash's session restore distinguishes "server down" from "signed out" |
| Token expiry | §6 single-flight 401 handling |
| Rate limited (429) | Message + disable action briefly; no automatic retry of POSTs |
| Lesson position (PUT, idempotent) | Throttled to one report per 15 s while playing + on pause/exit; last value retried on reconnect |
| Uploads | Progress, cancel, resumable = not supported by the server; on failure "Upload failed — try again" keeps the picked file |
| Double submission | Every mutation button enters a busy state and ignores re-taps until the request settles |
| Server clock vs device clock | Server timestamps are authoritative for deadlines/phases; if the device clock differs from the `Date` response header by > 5 min, a debug log notes it (no user-facing time logic depends on the device clock for authorization) |

---

## 18. Security

| Control | Implementation |
| --- | --- |
| Token storage | Secure storage only (§15); never in logs, crash reports, analytics, screenshots of debug overlays, or `toString()` of any object |
| No secrets in source | No API secrets exist for the app. Build-time config (`--dart-define-from-file`) holds only public values (base URL, env name, feature flags). `config/*.json` for staging/prod are committed only with public values; a test scans `lib/`, `assets/`, `config/` and `android/` for key-like patterns (`rzp_`, `sk_`, `-----BEGIN`, `secret`) |
| Logging | `AppLogger` redacts keys matching password/token/secret/signature/authorization/card/cvv and masks JWT/bearer patterns in text (mirrors backend `lib/observe.ts`); release builds log warnings+ only and never bodies |
| Transport | HTTPS required outside dev (`android:usesCleartextTraffic=false`; a debug-only `network_security_config` allows `10.0.2.2`/LAN); default system trust. **Certificate pinning: Needs clarification** (Cloudflare fronts production; pinning Cloudflare edge certs is brittle — recommended *not* to pin, documented) |
| Sensitive responses | Not persisted (§15). Assignment files and learner uploads are shown only via authenticated requests; temp files deleted |
| Quiz integrity | **Backend finding:** `GET /learning/.../lessons/:id` sends the quiz answer key (`correct`, `acceptedAnswers`) to learners. The app's learner quiz model **does not map those fields**, never scores locally and never displays correctness before the server responds. Recorded as a backend security issue (§28) — the app cannot fix it |
| Payment | §11: provider-agnostic, no client amounts, no secrets, server confirmation only |
| Uploads | Client pre-validation mirrors the server allow-list; files read from the picker only; no executable types; the server re-validates |
| Authorization guards | UX only (§7); every refusal handled |
| Tenant | Never sent (§8) |
| Deep links | Verified App Links only (`autoVerify`), host-allow-listed; parameters validated (id charset/length ≤ 64 like the API's id schema); a reset token is never logged; no custom scheme carries secrets |
| WebView | None planned. External content (meeting links, help links) opens in the system browser/Custom Tab; `https` only |
| Notification payloads | Treated as untrusted hints; routed only through the §5.4 mapper after an API fetch |
| Session cleanup | Sign-out purges token, caches, temp files, providers, badge; user change detected by `user.id` |
| Screenshots/app switcher | Not blocked by default (**Needs clarification**, §13) |
| Release hardening | R8/minify on, Dart `--obfuscate --split-debug-info` (symbols kept privately for crash symbolication), `android:allowBackup=false`, `debuggable=false`, exported components minimal |
| Dependencies | Every package justified (§25); `flutter pub outdated` reviewed at hardening; no packages with unclear licences |

---

## 19. Accessibility

Target: WCAG 2.2 AA-equivalent on mobile.

- Semantics: every interactive widget has a label (icon buttons via `tooltip`/`Semantics`), headings
  marked (`Semantics(header: true)`), images decorative (`excludeSemantics`) unless meaningful, status
  never by colour alone (every status badge has text + icon, mirroring the web's `statusRegistry`).
- Touch targets ≥ 48×48 dp (`materialTapTargetSize.padded`); spacing between targets ≥ 8 dp.
- Text scaling: layouts verified at 100 %, 130 %, 200 % (Android max); no fixed-height text containers;
  truncation only with an accessible full value (tooltip/expand).
- Contrast: token pairs verified ≥ 4.5:1 for text, ≥ 3:1 for UI (checked by a unit test over the token
  table in light and dark).
- Motion: respect `MediaQuery.disableAnimations` / the in-app reduced-motion switch; no essential meaning in
  animation.
- Screen readers: TalkBack pass on every signature screen (FLUTTER-029/030); focus order logical; dialogs
  announce titles; live regions for timers (quiz), upload progress and toasts.
- Video: captions toggle when captions exist; controls reachable without gestures.
- Forms: labels always visible (no placeholder-only labels), errors announced and linked to fields.

---

## 20. Responsive / Adaptive UI

Breakpoints (logical width): **compact < 600**, **medium 600–1023**, **expanded ≥ 1024**
(`lib/core/layout/breakpoints.dart`, `AdaptiveScaffold`-style helper written in-house — no package).

| Screen | Compact (phone) | Medium/expanded (tablet) | Landscape |
| --- | --- | --- | --- |
| Course learning + lesson player | Content first; curriculum in a bottom sheet | Content + curriculum side panel (360 dp) | Video fullscreen; others same as portrait |
| Review queue → submission | List → push detail | List + detail two-pane | Tablet only |
| Notifications | List → push detail | List + detail | Tablet only |
| Dashboard / reports | Single column, priority order | Two-column grid | Tablet only |
| Certificate preview | Scaled to width, pinch-zoom | Centered | Supported (landscape-safe layout, LMS-011) |
| Document (PDF) viewer | Full screen | Full screen | Supported |
| Forms (live class, event, grading) | Single column, sticky bottom action bar | Centered max 720 dp | Tablet only |
| Everything else on phones | Portrait locked | — | — |

Text never overflows at 200 % text scale; wide tables become cards (LMS docs: "tables become cards on
mobile"); charts keep a readable minimum height and offer a list read-out.

---

## 21. Localization Readiness

- `flutter_localizations` + `gen-l10n` (ARB) from FLUTTER-002. All user-facing strings in
  `lib/l10n/app_en.arb`; no string literals in widgets (a test scans for `Text('…')` with literal
  English outside tests/debug).
- Initial locale **en-IN**. The academy setting `general.language` allows `hi-IN`: Hindi translation is
  **Needs clarification** (content and budget); the structure supports it with no code change.
- Formatting: `intl` `DateFormat`/`NumberFormat` with the active locale; money via
  `NumberFormat.currency(locale: 'en_IN', name: currency)` over **minor units ÷ 10^digits**, never
  arithmetic on totals; Indian digit grouping.
- Time zone: the web displays **IST**. The app displays dates in IST (fixed +05:30, no DST — no
  timezone package needed) and marks "IST" when the device's zone differs. Calendar `from`/`to` queries
  are IST dates as the server reads them. **Needs clarification:** should learners outside India see their
  local time? (one switch in `DateDisplay` if so).
- Plurals/ICU messages for counts ("3 lessons"); RTL-safe layouts (directional padding) for the future.

---

## 22. Theme Architecture & UI/UX System

### 22.1 Design direction — "Celestial Ink" on mobile

The web product's approved identity, carried over (not reinvented): warm parchment neutrals, a deep
indigo/violet working accent, antique gold reserved for what is **earned** (ratings, ranks, certificates,
"soon" badges), an editorial serif for display and numerals against a clean humanist sans for UI, a
tightened radius scale, ink-tinted soft shadows, and a true midnight-indigo dark mode. The brand mark is a
circle with a soft halo ring — echoed in progress rings, rank rings and the certificate seal.

Mobile expression: calm, content-first screens; one primary action per screen; generous reading measure
for lessons (max 68 characters); progress made visible and rewarding (rings, streak-free study-week bars,
chapter completion moments) without gamified noise.

### 22.2 Color tokens (sRGB; revised by the mobile redesign, Oct 2026)

The brand accent, the semantic tones and the dark theme are the web's (converted from its OKLCH
`tokens.css`). The light neutrals were cooled from the web's warm paper to a lavender-white so the app
reads as a native mobile app, not a printed page. Source of truth: `lib/core/theme/tokens.dart`, checked by
`test/core/theme/tokens_test.dart`.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `ground` / `groundGlow` | `#F4F1FB` / `#E9E3FA` | `#0E0C19` / `#1A1530` | Opaque canvas painted once beneath every route (`AppBackdrop`); the glow fades in from the top |
| `bg` | `#E6FFFFFF` (white at 90 %) | `#0E0C19` | Every scaffold's background (`scaffoldBackgroundColor`), over `ground`. Renders as `#FEFEFF` |
| `surface` | `#FFFFFF` | `#181624` | Cards, sheets, bottom bar |
| `surface2` | `#F5F3FA` | `#232131` | Filled inputs and search, chips, grouped rows |
| `surface3` | `#EAE7F2` | `#302E3F` | Pressed, skeleton base, disabled buttons |
| `text` | `#1B1828` | `#EDE7DE` | Primary text |
| `muted` | `#5A5869` | `#ABA498` | Secondary text |
| `faint` | `#858395` | `#787165` | Decorative icons, a filled field's resting indicator (≥ 3:1) |
| `border` | `#E6E2EE` | `#343143` | Hairlines (cards carry no outline in light mode — they are lifted by `e1`) |
| `accent` | `#5E3FAF` | `#AA98FA` | Primary actions, active nav, links, hero cards |
| `accentHover` / `accentPress` | `#4E2D99` / `#3E1F7F` | `#BBABFF` / `#9885E6` | States; `accentHover` ends the hero gradient |
| `accentSoft` / `accentInk` | `#EFEBFF` / `#4B3090` | `#2E2849` / `#D0C8FF` | Selected chips, icon tiles, tinted badges |
| `onAccent` | `#FFFFFF` | `#0D0A17` | Text on accent |
| `info` / `infoSoft` / `infoInk` | `#0081AF` / `#E3F3FC` / `#005073` | — / `#0E3242` / `#94D5F6` | Informational |
| `warn` (gold) / `warnSoft` / `warnInk` | `#DCA416` / `#FFF2D6` / `#804C00` | — / `#423007` / `#EFD18F` | Earned, due soon, at risk |
| `danger` / `dangerSoft` / `dangerInk` | `#CD3349` / `#FFECEC` / `#961733` | — / `#4B1D20` / `#FFB6B8` | Errors, destructive |
| `success` | = `accent` family | = `accent` family | Completed states use the accent (web convention), with a check icon |

Tokens live in a `ThemeExtension<AppColors>`; Material `ColorScheme` is derived from them. **No hex
values in feature code.** A contrast test (§19) covers every text/background pair, measuring the page as
it renders (`bg` over `ground`).

### 22.3 Typography

Fonts bundled as assets (SIL OFL, no runtime fetching). The interface uses **Plus Jakarta Sans**
throughout; **Fraunces** is kept for documents only (the certificate's names, `editorial`).

| Style | Font | Size/line (sp) | Weight | Use |
| --- | --- | --- | --- | --- |
| `displayL` | Plus Jakarta | 26/32 | 700 | Auth and onboarding titles |
| `displayM` | Plus Jakarta | 22/28 | 700 | Detail-page titles (a course) |
| `titleL` | Plus Jakarta | 18/24 | 700 | App bar titles, header cards, dialogs |
| `titleM` | Plus Jakarta | 16/22 | 700 | Section headers, card titles |
| `titleS` | Plus Jakarta | 15/20 | 600 | List item titles |
| `bodyL` | Plus Jakarta | 16/24 | 400 | Lesson reading text |
| `bodyM` | Plus Jakarta | 14/20 | 400 | Default body |
| `bodyS` | Plus Jakarta | 13/18 | 500 | Metadata |
| `label` | Plus Jakarta | 14/20 | 600 | Buttons, chips, tabs |
| `caption` | Plus Jakarta | 12/16 | 500 | Timestamps, helper text, facts |
| `micro` | Plus Jakarta | 11/14 | 600 | Navigation labels, cover badges |
| `numeral` | Plus Jakarta | 24/30, tabular | 700 | KPIs, scores, progress % |
| `editorial` | Fraunces | 28/34 | 600 | Certificate learner and course names only |

### 22.4 Spacing, radius, sizes, elevation, motion

- Spacing (4-pt): `s1 4 · s2 8 · s3 12 · s4 16 · s5 24 · s6 32 · s7 48 · s8 64`. Screen gutters 16
  (compact) / 24 (medium+). Section gap 24; card padding 16; header gap 4. Form max width 720, auth
  column 480.
- Radius: `xs 6 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · pill 999`. Cards `lg`, hero cards `xl`,
  sheets and dialogs `xxl`, inputs and icon tiles `md`, chips and search `pill`.
- Sizes (`Sizes`): app bar 56 (64 with a second line), bottom bar 64, buttons `sm 36 · md 44 · lg 50`,
  fields and search 48, list rows 52, icon tiles 36. Every control keeps a 48 dp touch target.
- Icons (`IconSizes`): `xs 14 · sm 16 · md 20 (default) · lg 22 (app bar, navigation) · xl 28 ·
  hero 40`. Avatars (`AvatarSizes`): `sm 32 · md 40 · lg 56 · xl 80`.
- Elevation: ink-tinted soft shadows — `e1` cards, `e2` hero cards and sheets, `e3` dialogs, `up` for
  bars docked to the bottom; dark mode uses outlines and surface steps instead.
- Motion: 120 ms (micro), 200 ms (standard), 320 ms (page/sheet); `Curves.easeOutCubic` in,
  `easeInCubic` out; shared-axis page transitions; progress rings animate once on first view; everything
  disabled under reduced motion.
- Haptics: light impact on toggle/complete/claim, none on navigation.

### 22.5 Component library (`lib/shared/widgets/`)

Built once in FLUTTER-001, used everywhere:

| Group | Components |
| --- | --- |
| Actions | `AppButton` (primary / secondary / tertiary / destructive; sizes md/lg; busy state; icon), `AppIconButton` (labelled), `StickyActionBar` (bottom primary action for long forms), `AppFab` (sparingly) |
| Inputs | `AppTextField` (label, helper, error, counter, obscure toggle), `AppSearchField`, `AppDropdown`/`AppSelectSheet`, `AppSwitchRow`, `AppCheckboxRow`, `AppRadioGroup`, `AppDateTimeField` (IST), `AppFilePickerTile` (with progress), `AppChoiceChips` / `FilterChipBar` with counts |
| Containers | `AppCard`, `SectionHeader` (title + action), `AppListTile` (leading/trailing/meta), `GroupedList`, `KeyValueTable` (mobile-safe "table"), `AppDivider` |
| Status & data | `StatusBadge` (label + icon + tone, never colour alone — ported from the web's status registry: draft, published, archived, pending, issued, revoked, upcoming, starting-soon, live, ended, cancelled, graded, returned, overdue, at-risk…), `ProgressRing` (halo motif), `ProgressBar`, `KpiTile` (value, previous-period delta with arrow + text), `Sparkline` / `TrendChart` / `BarList` (hand-built with `CustomPainter`, one measure one hue, with an accessible list read-out), `AvatarInitials` + `AuthImage` |
| Overlays | `AppDialog` (title, consequences first, acknowledgement checkbox for destructive, error kept in dialog), `ConfirmDialog`, `AppBottomSheet` (drag handle, `xl` radius), `FilterSheet`, `AppSnackbar` (success/info/error, optional Undo) |
| States (§22.6) | `SkeletonBox`/`SkeletonList`/`SkeletonCard` (shimmer off under reduced motion), `EmptyState`, `ErrorState`, `OfflineBanner`, `PermissionDeniedView`, `FeatureUnavailableView`, `SubscriptionStateView`, `NotFoundView`, `UnavailableLessonView` |
| Learning | `CourseCover` (the four `coverMotif` illustrations — orbits, houses, nakshatra, ecliptic — drawn as vector art in the Celestial Ink palette), `LessonTypeIcon`, `CurriculumTree` (chapter → lesson with lock/state nodes), `LessonNavBar` (prev / complete / next), `QuizQuestionCard`, `RubricScorer`, `CertificateCanvas`, `RankRing`, `StudyWeekBars`, `CountdownChip` |

A hidden **component gallery** route (`/dev/gallery`, dev flavor only) renders every component in
every state, light and dark, for review and golden tests.

Added by the mobile redesign (Oct 2026), all in `lib/shared/widgets/`: `CommonAppBar` (the one app
bar — titles, a second line, back or a custom leading, actions, a bottom strip, system-bar style) and
`AppBackdrop` (the page ground); `IconTile` (a tinted icon square); `DetailHeader` (the head card of every
detail page) and `ItemCard` (its list-sized sibling) with `MetaItem` facts; `FactStrip` and `InfoChips`
(course facts); `ToneMark` (a state's large mark); `SearchLauncher` (a search field that opens the screen
that owns the search); `CoverBadge` (a pill over a cover). `KpiTile` takes an icon and tone, and
`QuickActionTile` is a round shortcut.

### 22.6 Standard states

| State | Pattern | Copy example |
| --- | --- | --- |
| Loading | Skeletons shaped like the content (never a lone spinner on a page); inline spinner only inside buttons | — |
| Empty | Illustration (small constellation line-art), title, one sentence, one action | "No courses yet — Explore the catalogue to start learning." |
| Search/filter empty | No illustration; "No matches" + Clear filters | "No students match these filters." |
| Error | Icon, title, calm sentence, Retry; server detail shown small when useful | "We couldn't load this lesson." |
| Offline | Banner at top of shell + cached content | "You're offline. Showing what was loaded." |
| Permission denied | Lock icon; "You don't have access to this." + "Ask your academy admin." | — |
| Feature unavailable (plan) | Sparkle-off icon; "Not included in your academy's plan." Admin: "Review plan" | — |
| Subscription restricted | Banner for admins; per-action message for others | "Your academy's subscription has ended. Existing content stays available." |
| Not found / out of scope | "This isn't available." + Back | — |
| Locked lesson | Lock node + server's `lockedReason` | "Pass the Chapter 1 quiz to unlock this chapter." |

### 22.7 Signature screen compositions (UX intent for implementers)

**Learner Home** — built around the next action. Greeting in the app bar, then **Continue learning** hero
card (course cover motif, lesson title, progress ring, big "Resume" button), **Next live class** (or **Live
now**) — the schedule's own card with its Join / Save my seat action, falling back to the home feed's entry
when the schedule cannot be read — **To do** (assignments and quizzes from the feed, at most three rows,
server flags as badges), **Your courses** (left out when the only course is already in Continue), **This
week** study bars, **Recently viewed** (at most three), and discovery last (Saved, Explore courses). Every
section is left out when it has no data. Priority order on small screens exactly as listed.

**Lesson player** — content-first. Video: 16:9 player pinned at top, then title (`titleL`), lesson number
"2.3 · 12 min", description, resources; bottom `LessonNavBar` with Previous · **Mark complete** (or the
server's rule hint "Watch 80% to complete") · Next. Reading: comfortable measure, `bodyL`, sticky slim
progress line at top. Curriculum opens as a bottom sheet (phone) or side panel (tablet) with lock/check
nodes. Completing a chapter shows a brief halo animation and "Chapter complete"; course completion shows
the certificate moment.

**Quiz taker** — one question per screen with a segmented progress bar, question count "4 of 10",
large tappable options (radio/checkbox cards), optional timer chip (display only), review screen before
submit, submit confirmation, then the **server's** outcome: pass (celebration + next lesson) or not yet
(attempts left / retake wait from the server's message).

**Instructor Review** — queue with counts (To review · Overdue · Graded · Returned), cards showing
learner, assignment, course, submitted time, late badge; submission detail with the learner's work first,
then a sticky rubric scorer sheet with criterion steppers, total, feedback box, and **Return** / **Grade**
actions with confirmation; "Next submission" after saving.

**Staff Dashboard** — needs-attention first (severity-ordered cards linking into the app), quick actions,
upcoming live, then KPIs (value + previous-period delta in words, e.g. "+12 % vs previous 90 days"),
engagement, recent activity feed.

**Certificate** — a landscape-safe canvas rendered from template data (heading, statement, learner name
in Fraunces, course, completion date, credential id, signatories, accent from the template's
`accent` mapped to token families), gold seal with halo; actions: Share verification link, View
verification page.

### 22.8 Theme mechanics

`AppTheme.light()` / `AppTheme.dark()` build `ThemeData` (Material 3) from tokens + `ThemeExtension`s
(`AppColors`, `AppSpacing`, `AppRadii`, `AppShadows`, `AppTypography`). Theme mode: system (default) |
light | dark from app settings. Per-academy accent is a future hook (§8).

---

## 23. Testing Strategy

| Layer | Tool | What | Where |
| --- | --- | --- | --- |
| Unit | `flutter_test`, `mocktail` | Pure logic: web-path mapper, phase derivation, money/date formatting, capability table, error decoder, redaction, validators | `test/unit/**` |
| Model/contract | `flutter_test` | Every DTO parses its **recorded real fixture** (§7.3 of the workflow) and round-trips; unknown enum values fall back | `test/contract/**` |
| API service | `flutter_test` + a fake `HttpClientAdapter` for Dio | Request method/path/body/query exactly as the backend expects; forbidden fields never sent (tenantId, amount, role, score…); error decoding per status/code | `test/data/**` |
| Repository | `mocktail` | `Result` mapping, caching, invalidation | `test/data/**` |
| Controller | `ProviderContainer` overrides | State transitions: loading → data/empty/error, mutations, optimistic updates and rollback | `test/features/**` |
| Widget | `flutter_test` | Every screen in loading, empty, error, offline, denied/unavailable and populated states; semantics labels; 200 % text scale; dark mode | `test/features/**` |
| Navigation | `flutter_test` + real `GoRouter` | Redirects per session state, role guards, deep-link parsing, back behaviour | `test/app/**` |
| Golden | `flutter_test` (`matchesGoldenFile`) | Design-system components and signature screens, light + dark, compact + medium | `test/golden/**` (generated on the CI platform only) |
| Architecture | `flutter_test` | Import boundaries (no Dio in widgets, no cross-feature internals), no hard-coded colors, no secret patterns, no plan-name comparisons, no literal UI strings | `test/architecture/**` |
| Integration | `integration_test` on an Android emulator | Real journeys against the **local contract server** (real API, scratch DB) | `integration_test/**` |

Coverage target: ≥ 80 % lines on `lib/core` and `lib/features/*/data|application`; widget tests for every
screen. Tests never hit production or shared databases. No test is weakened to pass.

---

## 24. Build / Release Strategy

- **Flavors:** `dev`, `staging`, `prod` (Android `productFlavors`; entry points `lib/main_dev.dart`,
  `main_staging.dart`, `main_prod.dart`), application id `…mobile` + suffix `.dev`/`.staging`
  (decided 2026-10-10: `com.shubhlms.mobile`, replacing the placeholder `in.synilogictech.syniastrolms.mobile`).
- **Config:** `--dart-define-from-file=config/<flavor>.json` with public values only: `API_BASE_URL`,
  `ENV_NAME`, `WEB_BASE_URL` (for "open on the web" and verify links), `BILLING_CHECKOUT_ENABLED`,
  `CRASH_REPORTING_ENABLED`. Read once into an immutable `AppConfig`.
- **Versioning:** `pubspec.yaml` `version: x.y.z+build`; build number from CI.
- **Signing:** release keystore and passwords are **credentials — Needs clarification** (never
  committed; `key.properties` git-ignored; CI secret). Until provided, release builds are verified
  unsigned/debug-signed locally only.
- **Release build:** `flutter build appbundle --release --flavor prod -t lib/main_prod.dart --obfuscate
  --split-debug-info=build/symbols` (+ `apk` for testing). R8 on.
- **CI (recommended, not created by this workflow):** format → analyze → test → integration (emulator) →
  build. **Needs clarification:** CI provider.
- **Distribution:** Play Console internal testing → closed → production. Store listing, privacy policy URL
  and data-safety form: **Needs clarification** (human-owned, outward-facing — never done by the workflow).
- **Crash reporting vendor:** Firebase Crashlytics or Sentry — **Needs clarification** (account/DSN).
  `CrashReporter` interface with a no-op implementation until chosen.

---

## 25. Technology Stack & Dependencies

Flutter **3.38.x stable** / Dart **3.10.x** (installed on this machine: 3.38.10 / 3.10.9). Android SDK
platforms 28–36 installed.

### 25.1 Key decisions

| Concern | Decision | Why (and what was rejected) |
| --- | --- | --- |
| State management + DI | **Riverpod** (`flutter_riverpod`, no code generation) | Compile-safe providers, first-class async (`AsyncValue`), scoped overrides make every layer testable, disposal ties request cancellation to screen lifetime, and providers double as DI. **GetX rejected**: global mutable service locator and implicit context, routing/DI/state bundled in one package (harder to test and to replace), weak compile-time safety, and it encourages widget-level business logic — the opposite of the required layering. Bloc was viable but adds boilerplate without extra safety for this app. |
| Routing & deep links | **go_router** | Official, declarative, redirect-based guards, `StatefulShellRoute` for per-tab stacks, built-in deep-link handling (no extra deep-link package). |
| HTTP | **dio** | Interceptors (auth, retry, error, logging), cancellation, multipart with upload progress, adapter-level faking for tests. `http` would need all of that hand-built. |
| Models | **freezed** + **json_serializable** (+ `build_runner`, dev) | Immutable models, `copyWith`, sealed unions for states/failures, generated JSON with enum fallbacks. |
| Secure storage | **flutter_secure_storage** | Keystore/Keychain-backed token storage. |
| Preferences | **shared_preferences** | Non-sensitive UX settings only. GetStorage rejected (unmaintained risk, no benefit). |
| Offline DB | **None** | No LMS requirement for offline data (§15). |

### 25.2 Approved dependencies

Only these may be added, each in the module named. Anything else: append a row here with a reason
first (workflow §6.8).

| Package | Module | Reason |
| --- | --- | --- |
| `flutter_riverpod` | 000 | State + DI (§25.1) |
| `go_router` | 000 | Routing, guards, deep links |
| `dio` | 000 | HTTP client |
| `freezed_annotation`, `json_annotation` | 000 | Model annotations |
| `flutter_secure_storage` | 000 | Token storage |
| `shared_preferences` | 000 | UX preferences |
| `intl`, `flutter_localizations` (SDK) | 000 | Localization, date/number/currency formatting |
| `connectivity_plus` | 000 | Connectivity hint for the offline banner |
| `package_info_plus` | 000 | Version/build in About and crash context |
| `url_launcher` | 000 | External meeting links, web handoffs, help links |
| `phosphor_flutter` | 001 | Same icon family as the web (Phosphor, duotone) — visual consistency |
| `cached_network_image` | 007 | Authenticated image loading + disk cache |
| `video_player` | 007 | Video playback with auth headers and range streaming |
| `pdfrx` | 007 | In-app PDF rendering (MIT, PDFium) — no external viewer needed |
| `file_picker` | 007 | Picking PDFs/images for uploads |
| `mime` | 007 | MIME lookup for client-side pre-validation |
| `path_provider` | 007 | Temp dir for PDFs/uploads |
| `flutter_cache_manager` | 007 | The store behind `cached_network_image`; declared directly so the image cache can be keyed per signed-in person and emptied on sign-out (§8.4). Added 23 Sep 2026 (FLUTTER-007) |
| `path` | 007 | Joining temporary-file paths for downloaded PDFs; already present transitively via `path_provider`. Added 23 Sep 2026 (FLUTTER-007) |
| `share_plus` | 014 | Share certificate verification link |
| `wakelock_plus` | 011 | Keep screen on during video playback only |
| `razorpay_flutter` | 027 | **Only if** in-app checkout is approved (§11.5) |
| `firebase_core`, `firebase_messaging` | 028 | **Only when** the backend push capability and Firebase credentials exist |
| Crash SDK (Crashlytics **or** Sentry) | 030 | **Only when** the vendor is chosen |
| **Dev:** `build_runner`, `freezed`, `json_serializable`, `mocktail`, `flutter_lints`, `integration_test` (SDK), `flutter_test` (SDK) | 000 | Codegen, testing, lints |

Deliberately **not** added: GetX, any markdown package (the article format is a tiny safe subset —
`##`, `>`, `-`, `1.`, `**b**`, `_i_`, `[link](https)` — rendered by an in-house widget mirroring the web's
`ArticleBody`), chart packages (hand-built painters match the web's "one measure, one hue" charts),
Google Fonts runtime fetching (fonts bundled), logger packages (in-house redacting logger), permission
packages (only Android 13 notification permission via `firebase_messaging` when push exists).

---

## 26. Project Structure

Feature-first, layered inside each feature; shared kernel in `core` and `shared`. Adjusted to the actual
LMS modules (the suggested generic `data/` top level is kept per feature instead, so features stay
decoupled).

```
apps/mobile/
  pubspec.yaml  analysis_options.yaml  l10n.yaml  config/{dev,staging,prod}.json
  assets/fonts/ (Fraunces, PlusJakartaSans)  assets/illustrations/
  android/  ios/
  lib/
    main_dev.dart  main_staging.dart  main_prod.dart   → bootstrap(AppConfig)
    app/
      app.dart                      MaterialApp.router, theme, l10n
      bootstrap.dart                zones, error hooks, ProviderScope
      routing/  app_router.dart  routes.dart  redirect.dart  web_path_mapper.dart  shells/
    core/
      config/      app_config.dart  environment.dart
      network/     api_client.dart  interceptors/  api_exception.dart  error_decoder.dart  paging.dart
      auth/        token_store.dart  session_controller.dart  capabilities.dart
      errors/      app_failure.dart  result.dart
      storage/     preferences.dart
      logging/     app_logger.dart  redactor.dart  crash_reporter.dart
      connectivity/ connectivity_service.dart
      media/       media_url_resolver.dart  auth_headers.dart
      format/      money.dart  dates_ist.dart  durations.dart
      layout/      breakpoints.dart  adaptive.dart
      theme/       tokens.dart  app_theme.dart  extensions/  typography.dart
    shared/
      widgets/     actions/ inputs/ containers/ status/ overlays/ states/ learning/ charts/
      entitlements/ entitlement_refusal.dart  academy_plan_provider.dart
      domain/      shared value types used by >1 feature (e.g. LiveClass, Course summary)
    features/
      auth/  public_catalog/  verify/  help/
      learner_home/  explore/  course_learning/  lesson_player/  quizzes/  assignments/
      certificates/  ranks/  live_learner/
      notifications/  profile/
      staff_dashboard/  staff_courses/  review/  staff_quizzes/  students/  live_staff/  calendar/
      instructors/  staff_certificates/  reports/  billing/
      push/          (FLUTTER-028)
        each: data/ (dto/, <f>_api.dart, <f>_repository.dart)
              application/ (controllers, states)
              presentation/ (screens/, widgets/)
              <f>.dart (public barrel: routes + exports)
    l10n/ app_en.arb
  test/  unit/ contract/ data/ features/ app/ golden/ architecture/ fixtures/
  integration_test/
```

Rules: a feature may import `core`, `shared` and another feature's **barrel** only; never another
feature's `data/` or `application/`. Shared domain types move to `shared/domain` only when a second
feature needs them.

---

## 27. Module Dependency Graph

```
000 Bootstrap
 ├─ 001 Design System ─────────────┐
 └─ 002 Core Infra ─ 003 API Client┤
                        │          │
                        └──────────┴─ 004 Auth ─ 005 Shell/Routing ─ 006 Authorization/Entitlement
                                   007 Media (003, 001)   │                │
                                         │                008 Public (005, 007)
                                         │                                 │
            ┌────────────────────────────┴───────────────┬────────────────┼──────────────┬───────────────┐
      009 Learner Home (006, 007)                   016 Notifications  017 Profile   018 Staff Dashboard
        ├─ 010 Explore ─ 011 Lesson Player              (006)            (006)           (006)
        │                 ├─ 012 Quizzes                  │                               ├─ 019 Courses
        │                 └─ 013 Assignments              │                               │   ├─ 020 Review (019, 007)
        ├─ 014 Certificates                               │                               │   ├─ 021 Quizzes overview
        └─ 015 Live (learner)                             │                               │   └─ 023 Live (staff) ─ 024 Calendar
                                                          │                               ├─ 022 Students ─ 025 Instructors & Certificates
                                                          │                               └─ 026 Reports
                                                          ├─ 027 Billing (006, 016)
                                                          └─ 028 Push & Deep Links (016, 005)

029 Integration suite ← 008, 012, 013, 014, 015, 017, 020, 021, 024, 025, 026, 027
030 Final Hardening & Release ← 029, 028
```

Linear priority order (what the workflow runs when nothing is blocked):
000 → 001 → 002 → 003 → 004 → 005 → 006 → 007 → 008 → 009 → 010 → 011 → 012 → 013 → 014 → 015 → 016 →
017 → 018 → 019 → 020 → 021 → 022 → 023 → 024 → 025 → 026 → 027 → 028 → 029 → 030.

Expected blockers and their blast radius: **028** (push needs a backend endpoint + Firebase credentials —
deep links may also need the web host to serve `assetlinks.json`) blocks only **030**. **027**'s in-app
checkout is flag-gated, so the module completes read-only without waiting. **030** will stop for signing
keys, crash-reporting credentials and store approval (human actions).

---

## 28. Backend Contract Findings & Open Questions

Everything the modules below mark, in one register. The workflow appends answers here (never deletes).

### 28.1 Needs clarification (product decisions)

| # | Question | Default until answered | Affects |
| --- | --- | --- | --- |
| C1 | One shared app for all academies, or white-label builds per academy? | One app per API host; public screens show the default academy | §8, 008, 024 |
| C2 | Is light mobile **authoring** wanted (course/lesson/quiz/assignment edits)? | Web only; mobile has read + lifecycle actions | 019, 021 |
| C3 | Should admins see academy **settings** (read-only) or categories/templates on mobile? | No | §2.2 |
| C4 | Is in-app **SaaS plan checkout** allowed under Play/App Store billing policy? | `BILLING_CHECKOUT_ENABLED=false`: billing read-only | §11, 027 |
| C5 | iOS in scope? App Store account? | Android only; code iOS-ready | §2.3, 030 |
| C6 | Final application id / app name / icon / store listing / privacy policy URL | `…syniastrolms.mobile` placeholder in dev; decided before 030 | 000, 030 |
| C7 | Crash reporting vendor (Crashlytics or Sentry) and account | No-op reporter | 002, 030 |
| C8 | Firebase project for push | Push not built | 028 |
| C9 | Offline downloads of lessons/PDFs? Downloads leaving the app? | Streaming only; no offline copies | 007, 011 |
| C10 | Screenshot protection (`FLAG_SECURE`) on paid content? | Off | §13 |
| C11 | Hindi (`hi-IN`) translation? | English (en-IN) only; l10n-ready | §21 |
| C12 | Display times in IST for everyone, or the device's zone? | IST, labelled when device differs | §21 |
| C13 | Certificate pinning? | Not pinned (Cloudflare edge) | §18 |
| C14 | Biometric app lock? | Not built | §6 |
| C15 | A read-only Super Admin glance on mobile? | Not served | §2.2 |
| C16 | CI provider and release signing ownership | Local verification only | §24 |

### 28.2 API contract required

| # | Item | Where it matters |
| --- | --- | --- |
| A1 | Live class `meeting` field on writes: schema says `url`, validator requires `link` | 023 |
| A2 | `Course.price.amount` unit (whole rupees vs paise) — confirm from seed data and the web formatter before displaying | 008, 010 |
| A3 | VyaparGateway checkout shape (no published contract; no adapter) | 027 |
| A4 | Caption files for video (`captions: true` exists; no caption asset is modelled) | 011 |
| A5 | Quiz `showResults` API enum `'nothing'` vs domain `'hidden'` (read both) | 012, 021 |

### 28.3 Backend capability required

| # | Capability | Impact without it |
| --- | --- | --- |
| B1 | Logout / token revocation | Sign-out is local only; a copied token stays valid ≤ 7 days |
| B2 | Refresh tokens | Users re-sign-in every 7 days |
| B3 | Profile update and change password for signed-in users | Profile is read-only; password change via "forgot password" email |
| B4 | Push: device-token registration + push transport | No push notifications; in-app polling only |
| B5 | Learner-readable academy branding | Platform theme for everyone |
| B6 | Public academy lookup / per-academy registration | Self-registration only into the default academy |
| B7 | Quiz attempt result (`AttemptResult`) returned to the learner; attempt history | Learner sees pass/fail and best score only, no per-question review |
| B8 | Invoice PDF / download | Invoice shown read-only in-app |
| B9 | Payment status endpoint / redirect-gateway return path | Poll `/tenant/billing`; hosted-page gateways unsupported |
| B10 | Served features for instructors (e.g. on `/auth/me`) | Instructors see plan refusals reactively only |
| B11 | Enrolment request/approval flow (`approval`/`invite` policies refuse self-enrol with 409, no request endpoint) | Learner sees "Ask your academy to enrol you" |
| B12 | Live `room` meetings | Only external meeting links can be joined |
| B13 | Verified App Links need `/.well-known/assetlinks.json` served on the academy domain (web hosting change) | Links open the web; app handles them only once hosted |

### 28.4 Backend findings recorded for the backend owners (not fixed by this workflow)

1. **Quiz answer key exposed to learners** on the lesson endpoint before answering (`correct`,
   `acceptedAnswers`). The app ignores those fields; the server should strip them.
2. **Quiz time limit not enforced server-side** (`durationSec` is client-reported). The app shows a timer
   and auto-submits at the limit as UX only.
3. **Assignment `format`/`wordLimit` not enforced** on submit; file ids not checked for ownership.
4. **Tenant `status` (suspended/archived) not enforced** on requests.
5. Role-only endpoints (calendar, notifications, `/certificates` list, `/live` list) still honour a
   deactivated admin's unexpired token (docs/11 §24 known limitation).

---

## 29. Module-by-Module Specifications

Each module uses the same headings. "States" follow §22.6 unless a module says otherwise; "Offline"
follows §17. Every module's tests are in addition to the architecture tests that always run.

<a id="flutter-000"></a>
### FLUTTER-000 — Workspace Bootstrap & Tooling

| | |
| --- | --- |
| **Purpose** | Create a clean, verifiable Flutter project inside the monorepo that every later module builds on. |
| **Roles** | — (developer-facing) |
| **Dependencies** | none |
| **Entry points / routes** | `lib/main_dev.dart`, `main_staging.dart`, `main_prod.dart`; a single placeholder route rendering the app name (replaced in 005). |
| **API** | none (reads nothing) |
| **Permissions / entitlements / tenant** | — |

**Work**
1. `flutter create --org <placeholder from C6> --project-name syniastrolms_mobile --platforms android,ios apps/mobile` (iOS folder kept for readiness; not built).
2. Android: `minSdk 24`, `targetSdk`/`compileSdk` 36, Java 17, Kotlin DSL as generated; `productFlavors` dev/staging/prod with `applicationIdSuffix` `.dev`/`.staging`, app name per flavor; `android:allowBackup="false"`, `usesCleartextTraffic="false"` with a **debug-only** `network_security_config` permitting `10.0.2.2` and localhost; INTERNET permission only.
3. `config/dev.json`, `config/staging.json`, `config/prod.json` (public values only: `API_BASE_URL`, `WEB_BASE_URL`, `ENV_NAME`, `BILLING_CHECKOUT_ENABLED=false`, `CRASH_REPORTING_ENABLED=false`). Staging/prod base URLs: production is `https://shubhlms.com/api` (from `deploy/api.env.example`); staging **Needs clarification** (no staging host exists — SAAS-016 is blocked on one), so staging config points at production with `ENV_NAME=staging` commented as a placeholder and is not used for release.
4. Add the §25.2 "000" dependencies and dev dependencies; `flutter pub get`; commit `pubspec.lock`.
5. `analysis_options.yaml`: `flutter_lints` + strict mode (`strict-casts`, `strict-inference`, `strict-raw-types`), rules: `always_declare_return_types`, `avoid_print`, `prefer_final_locals`, `require_trailing_commas`, `unawaited_futures`, `use_build_context_synchronously`, `directives_ordering`; exclude generated `*.g.dart`/`*.freezed.dart`.
6. `build.yaml` for json_serializable (`explicit_to_json: true`, `field_rename: none`, `checked: true`).
7. Test scaffolding: `test/` tree per §26, one smoke test, `integration_test/app_test.dart` smoke test, `test/architecture/` with the import-boundary, no-hex-color, no-secret-pattern, no-plan-name and no-literal-UI-string tests (initially passing on an empty app).
8. `apps/mobile/README.md` (developer setup: flavors, run commands, local contract server, verification commands) and `apps/mobile/tool/verify.sh` running the §7.1 workflow commands in order.
9. Prove the monorepo is unaffected: from the repo root `npm run lint`, `npm run format:check`, `npm run typecheck` behave exactly as before this module (compare with a run before creating the folder). If `eslint .` or prettier now scan `apps/mobile`, apply the narrowest ignore (workflow §0.4) and record it.
10. Record in progress.md `## Verification commands` the exact commands for this project.

**Validation / states / offline** — n/a.

**Security** — no secrets anywhere; `.gitignore` in `apps/mobile` covers `build/`, `.dart_tool/`, `android/key.properties`, `*.jks`, `*.keystore`, `android/local.properties`, `ios/Flutter/*.xcconfig` secrets, `coverage/`.

**Acceptance criteria**
- `flutter analyze` clean; `dart format` clean; `flutter test` passes; `flutter build apk --debug --flavor dev -t lib/main_dev.dart` succeeds and the APK launches on an emulator showing the placeholder.
- Three flavors build with distinct application ids.
- Root `npm run lint`/`format:check`/`typecheck` results unchanged.
- No file outside `apps/mobile/` and `.claude/flutter/` changed (except a recorded ignore entry, if needed).

**Testing requirements** — smoke widget test; architecture tests; integration smoke test (run if an emulator is available, else recorded per workflow §7.3).

---

<a id="flutter-001"></a>
### FLUTTER-001 — Design System & Theme

| | |
| --- | --- |
| **Purpose** | Implement the Celestial Ink design system (§22) and every shared component and state view, so features compose screens without inventing UI. |
| **Roles** | all |
| **Dependencies** | FLUTTER-000 |
| **Entry points / routes** | `/dev/gallery` (dev flavor only; not linked in prod) |
| **API** | none |
| **Permissions / entitlements / tenant** | — (the permission/feature/subscription *views* are built here; their wiring is 006) |

**UI components** — everything in §22.5, plus `AppTheme.light/dark`, token `ThemeExtension`s, bundled fonts (download the OFL font files once from the official Fraunces / Plus Jakarta Sans repositories, record source + licence in `assets/fonts/LICENSES.md`), Phosphor icons wrapper `AppIcons` (duotone default, semantic names), the four `CourseCover` motif painters, `ProgressRing` with halo, charts (`Sparkline`, `TrendChart`, `ColumnChart`, `BarList`) with accessible read-outs, `CertificateCanvas` shell (content wired in 014), `StatusBadge` registry covering every status string listed in §22.5 (ported from `apps/web/src/components/lms/status/statusRegistry.tsx` — label, icon, tone).

**User actions** — gallery: toggle light/dark, text scale 100/130/200 %, reduced motion, compact/medium width.

**Validation** — `AppTextField` supports validators, error text, counters; `ErrorSummary` lists issues and focuses fields.

**States** — all §22.6 views, each with an example in the gallery.

**Security** — n/a. **Offline** — n/a.

**Acceptance criteria**
- Token table matches §22.2 exactly (unit test); every text/background pair ≥ 4.5:1, UI ≥ 3:1 (contrast test).
- No hex literal outside `core/theme/tokens.dart` (architecture test).
- Every component has a gallery entry and a widget test covering its states, semantics label, 200 % text scale (no overflow), and dark mode.
- Golden tests for buttons, inputs, cards, status badges, state views, course covers, progress ring, KPI tile, dialog and bottom sheet — light and dark, compact width.
- Touch targets ≥ 48 dp (test helper `expectMinTapTarget`).

**Testing requirements** — widget + golden + contrast + architecture tests.

---

<a id="flutter-002"></a>
### FLUTTER-002 — Core Infrastructure

| | |
| --- | --- |
| **Purpose** | The non-UI foundation every feature uses: config, logging, failures, results, connectivity, crash reporting, formatting, localization, preferences. |
| **Roles** | all |
| **Dependencies** | FLUTTER-000 |
| **API** | none |

**Work** — `AppConfig` (immutable, from `String.fromEnvironment`/`dart-define-from-file`, validated at boot: https required outside dev); `AppLogger` + `Redactor` (§18); `AppFailure` sealed hierarchy (§10.3) and `Result<T, F>`; `ConnectivityService` (stream of online/offline hints); `CrashReporter` interface + `NoopCrashReporter` (C7) and the global error hooks in `bootstrap.dart` (§16); `Money.format(minor, currency)` using currency digits (INR = 2) and en-IN grouping; `DatesIst` (UTC → IST fixed offset, relative times "in 3 hours", "2 days ago", day boundaries for agenda grouping); durations ("1 h 20 min"); `Preferences` wrapper over `shared_preferences` (typed keys, theme mode, reduced motion, last tabs); gen-l10n set up with `app_en.arb` and the first strings; `ErrorBoundary` widget for crashed routes.

**Validation** — config validation fails fast with a readable message in dev.

**Security** — redaction covers password/token/secret/signature/authorization/card/cvv keys, JWT (`eyJ…\.…\.…`), `Bearer …`, `rzp_(test|live)_…` patterns, 13–19 digit card-like numbers, and reset-link tokens (`/reset-password/<hex>`).

**Acceptance criteria**
- Redactor unit tests prove each pattern is masked and normal text is untouched.
- `Money.format(399900, 'INR')` → `₹3,999.00`; zero-decimal and unknown-currency cases handled; never uses `double` arithmetic on totals (only for the final display division by 10^digits via `Decimal`-safe integer math).
- IST conversions correct at day boundaries (e.g. 2026-09-22T18:30:00Z = 23 Sep 00:00 IST).
- Uncaught errors reach `CrashReporter` with redacted context (test with a fake reporter).
- l10n: `flutter gen-l10n` runs in the build; one localized string rendered in a widget test.

**Testing requirements** — unit tests for every utility; widget test for `ErrorBoundary`.

---

<a id="flutter-003"></a>
### FLUTTER-003 — API Client & Contract Layer

| | |
| --- | --- |
| **Purpose** | One centralized, typed HTTP layer (§10) and the tooling to prove models against the real backend. |
| **Roles** | all |
| **Dependencies** | FLUTTER-002 |
| **API** | `GET /health` → `{ok: true}` (reachability check used by the splash to distinguish "server down" from "signed out") |

**Work**
- `ApiClient` (Dio) with the §10.2 interceptors, base URL from `AppConfig`, `get/post/put/patch/delete` helpers returning decoded JSON or handling `204`, `upload(path, file, onProgress, cancelToken)` for multipart field `file`.
- `ErrorDecoder` implementing the §10.3 table exactly, including `issues` in both shapes (`{path, message}` 400 and `{field, message}` 409), bare-number and literal-`null` bodies passed through untouched to the caller.
- `TokenStore` interface (implemented in 004) injected into `AuthInterceptor`; single-flight 401 callback hook.
- `Paged<T>` DTO (`rows`, `total`, `counts`) + `PagedController<T>`.
- JSON converters: ISO date ↔ `DateTime` (UTC), enum-with-unknown helpers.
- **Local contract server** procedure (workflow §7.3) scripted as `apps/mobile/tool/contract_server.sh start|stop|seed` writing only to the session scratch dir, and `tool/capture_fixture.sh <method> <path> <role> <out>` that signs in as a seeded role, calls the endpoint and writes scrubbed JSON under `test/fixtures/`.

**Request/response models** — `ApiErrorBody {message, issues?, code?}`, `ValidationIssue {path?, field?, message}`, `Paged<T>`.

**Validation** — ids sent in paths are validated `1–64` chars, URL-encoded.

**Loading/empty/error/offline** — n/a (infrastructure); failures surface as `AppFailure`.

**Security** — bearer only on requests to the configured API host (never to other hosts, e.g. meeting links); logs redacted; no body logging in release; request ids random, not user-derived.

**Acceptance criteria**
- Unit tests for every row of the §10.3 table using a fake Dio adapter.
- Retry only for idempotent methods and retryable statuses (tests prove POST is never retried).
- A 401 on three concurrent requests triggers the session-expired callback exactly once.
- Upload reports progress and honours cancel (fake adapter).
- Fixture capture script produces valid JSON against the running local contract server (`/health`, `/catalog/levels`) — recorded in progress.md.

**Testing requirements** — unit tests (decoder, interceptors, paging), contract test parsing captured `/catalog/levels`.

---

<a id="flutter-004"></a>
### FLUTTER-004 — Secure Session & Authentication

| | |
| --- | --- |
| **Purpose** | Sign in, register (learner), forgot/reset password, session restore and sign-out, exactly per §6. |
| **Roles** | visitor, learner, instructor, admin; superadmin refused |
| **Dependencies** | FLUTTER-001, FLUTTER-003 |
| **Entry points** | App launch (splash), Welcome → Sign in / Create account, 401 anywhere, deep link `/reset-password/:token` (wired in 028) |
| **Routes / screens** | `/splash` (brand halo, restore), `/welcome` (value proposition, Sign in, Create account, Browse courses), `/login`, `/register`, `/forgot-password`, `/reset-password/:token`, `/unsupported-role` |
| **Sources** | `routes/auth.ts`, `lib/auth.ts`, `lib/requestContext.ts`, `docs/04`, `modules/authentication.md` |

**Navigation** — splash → role home or welcome; login success → `next` (validated) or role home; register success → learner home; forgot → confirmation → back to login.

**UI components** — `AppTextField` (email keyboard, autofill hints `email`/`password`/`newPassword`/`name`), password visibility toggle, `AppButton` busy states, inline error summary, server message banner.

**User actions** — sign in; create account; request reset link; set new password (with confirm field — UX only); retry session restore; sign out (from 017, uses this module's controller).

**API requirements**

| Method & path | Request | Response | Errors to handle |
| --- | --- | --- | --- |
| `POST /auth/login` | `LoginRequest {email (trim, lowercase, ≤254), password (1–128)}` | `AuthResponse {token, user: UserProfile}` | 401 incorrect (same copy for unknown email), 403 deactivated / suspended / inactive instructor (show server message), 400 issues, 429 |
| `POST /auth/register` | `RegisterRequest {name 2–120, email ≤254, password 8–128}` | `201 AuthResponse` (no `permissions`) | 409 duplicate email, 400 issues, 403 `LIMIT_REACHED` (academy full: "This academy isn't accepting new learners right now."), 429 |
| `GET /auth/me` | — | `{user: UserProfile}` | 401, 403 deactivated/suspended, 404 account not found |
| `POST /auth/forgot-password` | `{email}` | `{ok: true}` | 400 malformed email, 429 |
| `GET /auth/reset-password/:token` | — | `{valid: bool}` | — |
| `POST /auth/reset-password` | `{token (1–128), password (8–128)}` | `{ok: true}` | 409 invalid/expired ("Request a new link"), 400 |
| `GET /health` | — | `{ok}` | network |

**Models** — `UserProfile {id, name, email, role: UserRole(student|instructor|admin|superadmin|unknown), descriptor, instructorId?, permissions: List<PermissionKey> (default [])}`; `PermissionKey` enum of the 24 keys with `unknown` fallback; `SessionState` sealed.

**Permissions / entitlements / tenant** — none sent; registration always creates a learner in the host's default academy (§8, C1). Never send `role`.

**Validation (client UX, mirrors zod)** — email format; password ≥ 8 on register/reset (≥ 1 on login); name 2–120; confirm-password match (client-only). Server issues mapped by `path`.

**States** — splash restoring; offline splash ("Can't reach SyniastroLMS" + Retry, token kept); login busy; errors inline; forgot-password always shows the same confirmation ("If an account exists for that email, we've sent a link").

**Offline** — sign-in/register disabled with "You're offline"; restore keeps the token.

**Security** — token only via `SecureTokenStore` (implements 003's interface) with the environment id; password fields `obscureText`, `enableSuggestions: false`, `autocorrect: false`; no credentials logged; the `superadmin` token is deleted immediately; reset token never logged or persisted; sign-out purges per §6.

**Acceptance criteria**
- Seeded admin, instructor and student each sign in against the local contract server and land in their shell placeholder; `superadmin` lands on `/unsupported-role` with no token stored.
- Killing and relaunching the app restores the session via `/auth/me`; with the server stopped, the offline splash shows and the token survives.
- An expired/invalid token (tampered in secure storage in a test) produces the "session ended" sign-in with `next` preserved.
- A suspended learner (suspend via the local server as admin) is signed out on next launch with the server's message.
- Register → learner home, and `/auth/me` is called to load permissions.
- Forgot password shows the non-enumerating confirmation for known and unknown emails.
- No token/password appears in any log line during these flows (log-capture test).

**Testing requirements** — controller tests for every transition; API service tests (paths, bodies, no `role` field sent); widget tests for all screens and states; navigation tests (redirects by session state); integration test: register → sign out → sign in → relaunch restore.

---

<a id="flutter-005"></a>
### FLUTTER-005 — App Shell, Routing & Role Navigation

| | |
| --- | --- |
| **Purpose** | The navigational skeleton: router, redirects, role shells, bottom navigation/rail, route table, web-path mapping (§5). |
| **Roles** | all |
| **Dependencies** | FLUTTER-004 |
| **Routes** | the full §5.3 table registered; screens not yet built show a neutral "Coming in a later update" placeholder **only in dev flavor**; prod flavor hides unbuilt destinations (tracked in progress.md, removed as modules land) |

**UI components** — `LearnerShell`, `StaffShell` (instructor/admin variants by capability), app bar with bell slot, "More" sheet, `NavigationBar`/`NavigationRail` adaptive switch, not-found screen, offline banner slot.

**User actions** — switch tabs (stack preserved), open More, Android back per §5.5.

**API** — none new (session from 004).

**Permissions** — admin-only destinations (Instructors, Certificates, Reports, Billing) shown by capability (006 fills the capability checks; this module uses a temporary role-based stub removed in 006).

**Validation** — `next` and deep-link targets validated against the route table (`isKnownAppRoute`).

**States** — not-found; unsupported role; offline banner placeholder.

**Security** — no open redirects; unknown paths never navigated.

**Acceptance criteria**
- Redirect matrix test: {unknown, signedOut, learner, instructor, admin, superadmin} × {public, learner, staff, admin-only routes} → expected destination.
- Tab stacks preserved across switches; back behaviour per §5.5 (widget tests).
- `WebPathMapper` maps every web path string emitted by the backend (list them by grepping `apps/api/src` for `to:`/`action:` and dashboard attention/event builders) — unit tests per pattern, unknown → null.
- Phone shows NavigationBar; ≥ 600 dp shows NavigationRail (widget test at two sizes).

**Testing requirements** — navigation tests, mapper unit tests, widget tests of shells at compact/medium.

---

<a id="flutter-006"></a>
### FLUTTER-006 — Authorization, Permissions & Entitlement States

| | |
| --- | --- |
| **Purpose** | Capability gating (§7) and the plan/subscription refusal experience (§9), shared by every feature. |
| **Roles** | instructor, admin (learners get the refusal views only) |
| **Dependencies** | FLUTTER-005 |
| **Sources** | `lib/permissions.ts`, `packages/domain/src/permission.ts`, `lib/entitlements.ts`, `lib/usage.ts`, `docs/06` enforcement matrix, `routes/tenant.ts` |

**Work**
- `Capability` enum + table (§7) verified route-by-route against `requirePermission` / `requireStaffPermission` usage in `apps/api/src/routes/*.ts` (record the verification in progress.md).
- `capabilitiesProvider` from the session; `CapabilityGate` widget (hide | disable-with-reason).
- Re-read `/auth/me` on resume (throttled 5 min) to pick up permission changes.
- `EntitlementRefusal` mapping for `SUBSCRIPTION_REQUIRED`, `SUBSCRIPTION_EXPIRED`, `FEATURE_NOT_INCLUDED`, `LIMIT_REACHED` (+ 402 without code) into `SubscriptionStateView`, `FeatureUnavailableView`, inline banners and snackbar copy — role-aware (§9.1).
- `academyPlanProvider` (admins with `viewBilling`): `GET /tenant/subscription/entitlements`, `GET /tenant/subscription/usage` — drives the academy-wide restricted banner and limit hints.

**API requirements**

| Method & path | Response model | Notes |
| --- | --- | --- |
| `GET /auth/me` | `UserProfile` | permission refresh |
| `GET /tenant/subscription/entitlements` | `TenantEntitlements {status: SubscriptionState?, planVersionId?, plan?: {id, code, name}, features: List<FeatureKey>, limits: Map<LimitKey, int?>}` (ignore `tenantId`) | admin + `settings.view`; 403 otherwise → silently skip prefetch |
| `GET /tenant/subscription/usage` | `{status, restricted, plan?, lines: [{limit, label, used, allowed?, remaining?, counts}]}` | same |

**Entitlements** — displayed, never computed. `FeatureKey`/`LimitKey` enums with `unknown`.

**States** — permission denied view; feature unavailable view; subscription restricted banner (admin) / message (others); limit reached dialog.

**Security** — no plan-name comparisons (architecture test); missing permissions = none.

**Acceptance criteria**
- Capability table unit-tested for instructor (role passes staff keys, never admin-only keys) and admin (exactly the granted keys; empty = nothing).
- Against the local contract server as admin: revoke a permission via `DELETE /superadmin/admins/:id/permissions/:key` **using the seeded super admin only if the seed provides one; otherwise simulate with a fixture** — the gated control disappears after resume refresh, and a direct call's 403 renders `PermissionDeniedView`.
- Each refusal code renders its view with role-appropriate copy (widget tests from recorded/constructed bodies of the exact server shape).
- With `ENTITLEMENT_ENFORCEMENT` off (default), no banner appears; with the local server started `ENTITLEMENT_ENFORCEMENT=on` and the seeded academy on no plan, the admin sees the restricted banner and a gated create action shows the subscription state (integration check, recorded).

**Testing requirements** — unit (capabilities, refusal mapping), widget (views, banner), repository (entitlements/usage parsing from fixtures), integration (enforcement on/off run).

---

<a id="flutter-007"></a>
### FLUTTER-007 — Media Foundation

| | |
| --- | --- |
| **Purpose** | Authenticated images, video, PDF and uploads (§13), reused by lessons, assignments, grading and profiles. |
| **Roles** | all signed-in (learners: PDF/image upload only) |
| **Dependencies** | FLUTTER-003, FLUTTER-001 |
| **Sources** | `routes/media.ts`, `lib/media.ts`, `packages/domain/src/catalog.ts` (`MediaFile`, `LessonContent`) |

**Work** — `MediaUrlResolver`; `AuthImage` (cached_network_image + headers, per-user cache manager, placeholder/skeleton, error fallback initials/motif); `AppVideoPlayer` (video_player with headers, design-system controls, markers, speed, fullscreen landscape, `onPosition(sec, fraction)` stream throttled 15 s + on pause/exit, wakelock while playing, cellular notice); `PdfViewerScreen` (download with headers to temp → pdfrx; page indicator; delete on close); `MediaUploader` (file_picker → pre-validate → upload with progress/cancel → `MediaFile`); `MediaCache.purge()` hooked into sign-out.

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `POST /media/upload` | multipart, field `file` | `201 UploadedMedia {id, name, sizeMb, url, mime, kind: video|document|image}` | 400 type, 403 learner video, 413 size, 403 `LIMIT_REACHED` (`storage.bytes`) |
| `GET /media/:id` | Bearer header | bytes (206 ranges for video) | 401, 404 |

**Validation (UX pre-check, mirrors server)** — video `mp4|webm|mov` ≤ 500 MB (staff only), `pdf` ≤ 25 MB, `png|jpg|jpeg|webp` ≤ 5 MB; extension and MIME must agree.

**States** — image loading skeleton / error fallback; video buffering, error ("This video couldn't be played"), ended; PDF downloading progress, error; upload progress, failed (retry keeps file), cancelled.

**Offline** — cached images shown; video/PDF show offline state with retry.

**Security** — headers only for the API host; temp files deleted; no external intents unless `downloadable` and C9 allow; cache purge on sign-out (test).

**Acceptance criteria**
- Against the local contract server: a seeded lesson video streams and seeks (range requests observed in server log or by seeking past buffered point); a seeded PDF opens; an image upload as a learner succeeds and a video upload as a learner is refused with the server's 403 message.
- Oversized/wrong-type files are refused before upload with the same wording as the server.
- After sign-out, the image cache directory for that user is empty and temp files are gone.

**Testing requirements** — unit (resolver, validators), widget (player controls states, uploader states), integration (upload + playback on emulator).

---

<a id="flutter-008"></a>
### FLUTTER-008 — Public Experience

| | |
| --- | --- |
| **Purpose** | What visitors can do before signing in: browse the academy's public catalogue, preview free lessons, verify a certificate, read help. |
| **Roles** | visitor (and signed-in users reach catalog/verify/help from their shells) |
| **Dependencies** | FLUTTER-005, FLUTTER-007 |
| **Entry points** | Welcome → Browse courses; Welcome → Verify a certificate; Help links; deep links `/courses/:slug`, `/verify/:credentialId` (028) |
| **Routes / screens** | `/catalog` (level + category filters, course cards), `/catalog/:slug` (hero with cover motif, subtitle, level, format, language, duration/weeks, outcomes, curriculum outline with preview badges, instructors, price display, rating only if the server includes it), `/catalog/:slug/preview/:lessonId` (preview lesson using 007 players; reading/video/document only), `/verify` (credential id input), `/verify/:credentialId` (result), `/help`, `/help/:categoryId`, `/help/article/:slug`, `/legal/privacy`, `/legal/terms` |
| **Sources** | `routes/catalog.ts`, `routes/help.ts`, `routes/certificates.ts` (verify), `.claude/ui/courses.md`, `.claude/ui/certificates.md`, `docs/modules/help-centre.md` |

**UI components** — `CourseCover`, course card (cover, title, level, lessons count, instructor names, price chip), `FilterChipBar`, curriculum outline (`CurriculumTree` read-only), `InstructorRow` (`AuthImage` falls back to initials when no token — instructor photos require auth, so visitors see initials), certificate verification card (valid/revoked/expired badge, name, course, level, dates, `validUntil`), article renderer (safe subset §25.2), "Sign in to enrol" CTA.

**User actions** — filter by level/category; open course; play a free preview; tap Enrol → sign in/register with `next=/learn/:courseId` after sign-in (learner) ; enter credential id; open help articles; share course link (web URL `WEB_BASE_URL/courses/:slug`).

**API requirements**

| Method & path | Response | Notes |
| --- | --- | --- |
| `GET /catalog/levels` | `Level[] {id, name, order, summary?}` | |
| `GET /catalog/categories` | `Category[] {id, name, description, levelIds, order, status, glyph, updatedAt}` | hide `status == hidden` client-side (server does not filter) |
| `GET /catalog/courses?levelId&categoryId` | `Course[]` (published + public) | unpaged; client-side text search |
| `GET /catalog/courses/:slug` | `Course` (lesson `content` empty except published previews) | 404 → not found |
| `GET /catalog/instructors` | `Instructor[]` (use `name`, `title`, `bio`, `expertise`; ignore `email`/`phone` in UI) | for instructor rows |
| `GET /certificates/verify/:credentialId` | `{certificate, student:{name, city}, courseTitle, levelTitle, template, validUntil?, expired}` (ignore `student.email` — never displayed) | 404 → "No certificate found for this ID" (covers unknown, pending, verification disabled) |
| `GET /help/categories?audience` | `[{category: {id, name, description, icon, order}, articleCount}]` | audience = `all` for visitors, role for signed-in |
| `GET /help/articles?search&categoryId&audience` | `[{article, categoryName}]` | |
| `GET /help/articles/:slug?audience` | `{article, categoryName, related}` | |

**Models** — `Course`, `Chapter`, `Lesson`, `LessonContent` (video/article/document/quiz/assignment/live blocks), `LessonSettings`, `Price {amount, currency}` (**A2**: confirm unit before formatting), `Level`, `Category`, `Instructor`, `HelpCategory`, `HelpArticle`, `VerifiedCertificate`.

**Permissions / tenant** — public; runs for the host's default academy (§8).

**Validation** — credential id trimmed, 1–64 chars, uppercase normalised only for display (send as typed).

**States** — catalog skeleton, empty ("No courses published yet"), filter empty, error; course not found; preview unavailable (non-preview lesson → "Enrol to watch this lesson"); verify: idle, checking, valid, revoked, expired, not found; help empty/search empty.

**Offline** — standard §17.

**Security** — no auth header on public calls when signed out; certificate result never shows email; help links open externally only if `https`.

**Acceptance criteria**
- Catalog lists exactly the seeded published public courses; filters narrow as the server does.
- A preview lesson plays for a visitor; a non-preview lesson shows the enrol prompt and no content is requested.
- A seeded issued certificate verifies; a random id shows not-found; revoked (revoke via admin on the local server) shows revoked.
- Help hub/category/article render from the server; article formatting matches the supported subset.
- Enrol tap as visitor → register/sign-in → returns to the course's learner view (validated `next`).

**Testing requirements** — contract tests (fixtures for every endpoint), repository tests, widget tests (all states), navigation test (`next` round trip), integration (visitor browse → preview → verify).

---
<a id="flutter-009"></a>
### FLUTTER-009 — Learner Home & My Learning

| | |
| --- | --- |
| **Purpose** | The learner's daily starting point (LMS-010 "My Learning"): continue where they left off and see what's coming. |
| **Roles** | learner |
| **Dependencies** | FLUTTER-006, FLUTTER-007 |
| **Entry points** | Learner shell Home and My Learning tabs; post-sign-in landing |
| **Routes / screens** | `/home`, `/my-learning/:tab` (`in-progress`, `completed`, `saved`) |
| **Sources** | `routes/learning.ts` (`/home`, `/courses`, `/activity`), `.claude/ui/learning-experience.md`, `docs/modules/progress.md` |

**Navigation** — Continue card → `/learn/:courseId/lessons/:lessonId` (the server's `next`, else the course); course row → `/learn/:courseId`; upcoming item → mapped `to` (§5.4); recent lesson → lesson; saved → course learning overview; empty state → Explore.

**UI components** — greeting header, Continue-learning hero card (`CourseCover`, `ProgressRing`, lesson title, "Resume"), Coming-up chips with `flag` badges (`live-now`, `starting-soon`, `overdue`, `due-soon`), course list rows with `ProgressBar` and `remainingMin`, `StudyWeekBars` (7 days of minutes), recently viewed list, segmented tabs for My Learning.

**User actions** — resume; open course; open upcoming item; pull to refresh; switch My Learning tab; unsave (saved tab, via 010's toggle).

**API requirements**

| Method & path | Response model |
| --- | --- |
| `GET /learning/home` | `LearnerHome {firstName, courses: LearnerCourse[], saved: SavedCourse[], recent: RecentLesson[] (≤5), upcoming: UpcomingItem[] (≤6), week: StudyDay[] (7)}` |
| `GET /learning/courses` | `{courses: LearnerCourse[], saved: SavedCourse[]}` |

`LearnerCourse {course: Course, enrollment: Enrollment, progress: ProgressSummary {completed, total, percent, remainingMin, state}, snapshot: CourseProgressSnapshot, next?: NextLesson, instructorNames, levelTitle, lastActiveAt?}`; `Enrollment {id, studentId, courseId, enrolledAt, status (active|completed|paused|expired), progress, source, lastActiveAt?, completedAt?, lastLessonId?, expiresAt?}`; `UpcomingItem {id, kind (live|assignment|quiz), title, context, at, to, flag?}`.

**Permissions / tenant** — learner-only endpoints; admin/instructor never reach them (router), and a 400 "Only learners have a learning workspace." is mapped to not-found defensively.

**Validation** — n/a.

**States** — skeleton home; empty (no enrolments: "Your learning starts here" → Explore); completed tab empty; paused/expired enrolment rows show status badge and the server state (expired: "Access ended on …"); error; suspended (403) → signed-out per §6.

**Offline** — shows last loaded home with banner.

**Security** — nothing cached across users.

**Acceptance criteria**
- For the seeded student, Home shows their real courses, progress %, next lesson, upcoming items and 7-day study minutes matching `/learning/home`.
- Resume opens exactly the server's `next` lesson.
- In-progress/completed/saved tabs partition courses by the server's `enrollment.status`/`saved` data (no client progress maths beyond display).
- Priority order on phone matches §22.7; tablet uses two columns.

**Testing requirements** — contract tests (home, courses fixtures), controller tests, widget tests (populated/empty/error/offline, 200 % text), navigation tests for each tap target.

---

<a id="flutter-010"></a>
### FLUTTER-010 — Explore & Enrollment

| | |
| --- | --- |
| **Purpose** | Let a signed-in learner discover the academy's courses, see a course's learning overview, save it, and enrol. |
| **Roles** | learner |
| **Dependencies** | FLUTTER-009 |
| **Routes / screens** | `/explore` (catalogue for learners: levels/categories filter, search), `/learn/:courseId` (overview state when not enrolled: about, outcomes, curriculum with previews, instructors, live sessions count, weeks, certificate title, price display, Enrol / Save) |
| **Sources** | `routes/learning.ts` (`/courses/:courseId`, `/save`, `/enroll`), `routes/catalog.ts`, `docs/modules/enrollments.md`, `.claude/ui/courses.md` (preview) |

**UI components** — course cards (reuse 008), course overview hero, `CurriculumTree` (locks shown as "Enrol to unlock"), instructor rows, `StickyActionBar` with **Enrol** (primary) and Save (icon toggle).

**User actions** — search/filter; open course; save/unsave; enrol (with a confirm sheet stating access length when `enrollment.expiresAt` will be set — text from server data after enrol, not predicted); open preview lesson.

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /catalog/courses`, `/catalog/levels`, `/catalog/categories` | — | as 008 | |
| `GET /learning/courses/:courseId` | — | `LearnerCourseDetail` = `LearnerCourse` + `{enrolled, live: LiveClass[], assignments: [...], certificate?: CertificateRecord, saved}` | 404 unpublished/not enrolled |
| `POST /learning/courses/:courseId/save` | — | `{saved: bool}` (toggle) | 404 |
| `POST /learning/courses/:courseId/enroll` | — (no body) | `LearnerCourse` (idempotent) | 404 private/unpublished; 409 enrolment policy `approval`/`invite` → "Your academy enrols learners on request. Ask your academy to add you." (**B11**); 409 suspended |

**Validation** — none client-side (no body).

**States** — explore skeleton/empty/filter-empty/error; overview loading; enrolled overview (becomes the learning view in 011); enrol busy; enrol refused (policy) with the server message; saved toggle optimistic with rollback on failure.

**Offline** — enrol/save disabled with reason.

**Security** — never sends price, source or status; the server decides `source: self`.

**Acceptance criteria**
- Enrolling in a seeded open course moves it into Home/My Learning without restart (providers invalidated).
- Saving toggles and survives refresh (server-backed).
- With the academy's enrolment policy set to `approval` on the local server, enrol shows the policy message and no enrolment appears.
- Price shown only as display, formatted per **A2** decision recorded in progress.md.

**Testing requirements** — service tests (no body on enrol/save), controller tests (optimistic save rollback), widget tests, integration (explore → enrol → appears on home).

---

<a id="flutter-011"></a>
### FLUTTER-011 — Course Learning & Lesson Player

| | |
| --- | --- |
| **Purpose** | The heart of the app (LMS-010): learn a course lesson by lesson with the server's gating and completion rules. |
| **Roles** | learner |
| **Dependencies** | FLUTTER-010 |
| **Routes / screens** | `/learn/:courseId` (enrolled: progress header, next-lesson card, curriculum with lock/state nodes, live classes, assignments, certificate progress), `/learn/:courseId/lessons/:lessonId` (player) |
| **Sources** | `routes/learning.ts` (lesson GET, complete, position, note, bookmark), `lib/learning.ts`, `packages/domain/src/progress.ts`, `.claude/ui/learning-experience.md`, `.claude/ui/lessons.md` (types) |

**Lesson types (what the player shows)**
- `video`: `AppVideoPlayer` (007) with markers; reports position; `watched` rule completes automatically server-side at `threshold` — the app shows "Watch {threshold}% to complete".
- `reading`: article renderer, `bodyL`, reading progress line.
- `document`: PDF viewer (007); `downloadable` respected per C9.
- `practice`: instructions + **Notes** as the working area ("Write your working" — the server requires ≥ 20 characters of notes for this rule; the app shows the server's message on refusal).
- `live`: the linked `LiveClass` card with phase (014 Live Class Architecture) and Join when available.
- `assessment`: hands off to the quiz taker (012) in place.
- `assignment`: the linked assignment summary with "Open assignment" (013).

**UI components** — `LessonNavBar` (Previous · Complete/rule hint · Next with `next.locked`), curriculum bottom sheet / side panel, lesson header (number "c.l", position "3 of 18", duration, type icon), notes editor sheet (autosave with debounce 1.5 s + explicit Save, "Saved" timestamp), bookmark toggle, completion moments (chapter complete, course complete → certificate prompt), locked view with `lockedReason`, not-enrolled view (preview only), unavailable view, expired-access view.

**User actions** — play/read/view; mark complete; previous/next; open curriculum and jump (locked lessons show reason, not navigable); write/save note; bookmark; join live; open quiz/assignment.

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /learning/courses/:courseId` | — | `LearnerCourseDetail` (010) | 404 |
| `GET /learning/courses/:courseId/lessons/:lessonId` | — (records the visit) | `LessonView {course, enrolled, snapshot, progress, chapterIndex, lessonIndex, lesson, number, position:{index,total}, state, lessonProgress?, access: open|locked|not-enrolled|unavailable, lockedReason?, previous?, next?:{id,title,locked}, quiz?, quizBest?, assignment?, live?, instructorNames, note, bookmarked, threshold}` | 404 |
| `POST …/lessons/:lessonId/complete` | — | `CompleteResult {snapshot, progress, chapterCompleted?, courseCompleted, nextLessonId?}` | 403 not enrolled; 409 rule messages (pass quiz / submit assignment / write working / watch N% / locked / expired) → shown verbatim as the hint |
| `PUT …/lessons/:lessonId/position` | `{positionSec (0–1e7), fraction (0–1)}` | `204` | 403, 404 |
| `PUT …/lessons/:lessonId/note` | `{text ≤ 20000}` | `{savedAt}` | 403, 404 |
| `POST …/lessons/:lessonId/bookmark` | — | `{bookmarked}` (toggle) | 403, 404 |

**Models** — `LessonView`, `CompleteResult`, `CourseProgressSnapshot {courseId, lessons: Map<id, {state: locked|not-started|in-progress|completed, fraction?, positionSec?, completedAt?}>, lastLessonId?, lastActiveAt?}`, `LessonProgress`. The embedded `quiz` model is the **learner-safe** quiz model of 012 (no `correct`/`acceptedAnswers`).

**Permissions / tenant** — enrollment and locks are server decisions; the app never unlocks locally, never marks complete locally before the server's `CompleteResult`, and resumes video at the server's `positionSec`.

**Validation** — note length ≤ 20000 (counter).

**States** — loading skeleton per type; locked (reason); not enrolled (preview only); unavailable; expired enrolment; completed (check + "Completed on …"); complete refused (server hint); note saving/saved/failed; video error; offline (content already loaded stays readable; complete/position/note queued as retry-once with visible state).

**Offline** — position reports retried on reconnect; complete requires connectivity.

**Security** — lesson bodies are only what the server returns (it strips content when not open); no caching of lesson content beyond memory; PDFs deleted after viewing.

**Acceptance criteria**
- Every seeded lesson type renders; locks match the server's snapshot; a locked lesson cannot be opened from the curriculum.
- Watching a seeded video past `threshold` completes it via the server (observe snapshot change after refresh) without a manual complete.
- Complete on a `passed`-rule lesson before passing shows the server's message.
- Notes save and reload; bookmark toggles persist.
- Chapter completion and course completion moments appear only when `CompleteResult` says so.
- Phone: curriculum in sheet; tablet: side panel; landscape video fullscreen works and restores.

**Testing requirements** — contract tests (lesson view fixtures for each type), controller tests (complete flow, refusal, position throttling), widget tests per lesson type and state, integration (open course → play video → complete → next lesson unlocked).

---

<a id="flutter-012"></a>
### FLUTTER-012 — Learner Quizzes & Assessments

| | |
| --- | --- |
| **Purpose** | Take chapter quizzes with server scoring (LMS-006 learner-facing), and see all assessments. |
| **Roles** | learner |
| **Dependencies** | FLUTTER-011 |
| **Routes / screens** | `/assessments` (list), quiz taker inside `/learn/:courseId/lessons/:lessonId` for `assessment` lessons (intro → questions → review → submit → outcome) |
| **Sources** | `routes/learning.ts` (`/assessments`, `quiz-attempt`), `packages/domain/src/quiz.ts`, `.claude/ui/quizzes.md` (preview/results) |

**UI components** — assessment rows (course, title, questions, duration, pass mark, attempts used/allowed, state badge `available|failed|locked|passed`, best score), quiz intro card (instructions, questions, time limit, pass mark, attempts left), `QuizQuestionCard` for `single` (radio cards), `multiple` (checkbox cards), `true-false` (two large options), `short` (text field ≤ 2000), segmented progress, question navigator sheet, optional countdown chip (display; auto-submit at zero — UX only, §28.4.2), review screen (answered/unanswered), submit confirm dialog, outcome screen.

**User actions** — start; answer; navigate questions; review; submit; retry (if the server allows); continue to next lesson.

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /learning/assessments` | — | `AssessmentRow[] {id, lessonId, courseId, courseTitle, title, questions, durationMin, passMark, attemptsAllowed, attemptsUsed, state, lockedReason?, score?}` | |
| quiz data | from the lesson view (`quiz`, `quizBest`) | `LearnerQuiz {id, title, instructions, questions: [{id, type, prompt, points, options:[{id,text}]}], settings: {passMark?, attempts?, timeLimitMin?, shuffleQuestions?, shuffleOptions?, showResults?}}` — **`correct` and `acceptedAnswers` are deliberately not modelled** | |
| `POST …/lessons/:lessonId/quiz-attempt` | `{answers: Map<questionId, String | List<String>>, durationSec?: int 0–86400}` | **literal `null` = not passed**; object = passed → `CompleteResult` | 403 not enrolled; 409 locked / all attempts used / retake wait / expired (message shown); 404 quiz unavailable |

**Outcome logic (display only)** — `null` → "Not passed this time" + attempts/wait from a refreshed `/learning/assessments` row and `quizBest` from a refreshed lesson view; object → "Passed" + `chapterCompleted`/`courseCompleted` moments. Per-question feedback: **not available (B7)** — the outcome screen says "Detailed results aren't available yet".

**Validation** — required questions are not specified by the backend quiz model for learners; the review screen warns about unanswered questions but allows submit (server scores).

**States** — assessments skeleton/empty/error; quiz locked (reason); attempts exhausted; retake wait; submitting; outcome pass/fail; offline (submit disabled; answers kept in memory).

**Offline** — answers kept in memory until connectivity returns; never auto-submits offline.

**Security** — no local scoring; answer key never parsed or displayed; `durationSec` measured honestly from start.

**Acceptance criteria**
- The seeded quiz lesson can be taken; a deliberately wrong attempt returns `null` and shows "not passed" with attempts left as the server reports; a correct attempt (answers taken from the seed file, not from the API payload) passes and unlocks the next chapter per the server snapshot.
- A test proves the learner quiz DTO drops `correct`/`acceptedAnswers` even when present in JSON.
- Timer display auto-submits at zero (widget test with fake clock).
- All four question types render and are operable with TalkBack labels.

**Testing requirements** — contract (lesson-with-quiz fixture, assessments fixture), service (answers shape; null handling), controller (flows), widget (types, review, outcomes), integration (fail then pass).

---

<a id="flutter-013"></a>
### FLUTTER-013 — Learner Assignments

| | |
| --- | --- |
| **Purpose** | Hand in coursework (LMS-007 learner side): drafts, files, birth-chart details, submission, feedback. |
| **Roles** | learner |
| **Dependencies** | FLUTTER-011 (and 007 through it) |
| **Routes / screens** | `/assignments` (list grouped by state/due), `/assignments/:assignmentId` (brief, attachments, rubric, due/late policy, work area, submission + review) |
| **Sources** | `routes/learning.ts` (assignments, draft, submit), `packages/domain/src/assignment.ts`, `.claude/ui/assignments.md` |

**UI components** — assignment rows (title, course, `dueAt` relative + IST, state badge `not-started|draft|overdue|submitted|under-review|graded|closed`), brief (article renderer), attachment list (`MediaFile` via `AuthImage`/PDF viewer), rubric table (criterion, points), work area by `format`: text editor with word count (display; `wordLimit` shown as guidance — server does not enforce, §28.4.3), file list with `MediaUploader` (PDF/images), **Birth chart** form (`label, date, time, place, lagna, moonSign, nakshatra`), draft status ("Saved 2 min ago"), `StickyActionBar` Submit, review panel (status, score/points of `maxScore`, per-criterion scores, feedback).

**User actions** — write; attach/remove files; fill chart; save draft (autosave debounce 3 s + on leave); submit (confirm dialog stating late penalty when the server's `acceptsLate`/`latePenalty` apply); resubmit when returned.

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /learning/assignments` | — | `LearnerAssignment[]` (sorted by due) | |
| `GET /learning/assignments/:id` | — | `LearnerAssignment {assignment:{id, courseId, chapterId?, lessonId?, title, instructions, attachments, format, wordLimit?, due, acceptsLate, latePenalty, rubric, maxScore, passMark, status, createdAt, updatedAt}, courseTitle, chapterTitle?, lessonId?, state, dueAt?, submission?, draft?}` | 404, 403 not enrolled |
| `PUT /learning/assignments/:id/draft` | `AssignmentWork {text ≤ 50000, files: [{id?, name ≤ 200, sizeMb, url?, mime?}] ≤ 20, chart?: BirthDetails}` | `{savedAt}` | 404, 403 |
| `POST /learning/assignments/:id/submit` | `AssignmentWork` | `LearnerAssignment` | 409 empty / already submitted / closed / deadline passed (reject policy) / expired |
| `POST /media/upload` | multipart | `UploadedMedia` → `files[]` | as 007 |

**Quirk** — a `returned` submission appears with state `draft`; show "Returned for changes" when `submission.review.status == returned`.

**Validation (UX)** — at least one of text, files or chart before submit (server rule); ≤ 20 files; chart fields required together when the format is `chart`.

**States** — list skeleton/empty ("No assignments yet")/error; detail loading; draft saving/saved/failed; upload progress; submitting; submitted/under review; graded (score + feedback); returned; closed; overdue (late policy shown); offline (draft kept in memory, "Not saved").

**Offline** — draft changes held in memory and saved on reconnect; submit disabled.

**Security** — only the caller's own work; uploaded files readable by the learner and staff only (server); no local persistence of drafts.

**Acceptance criteria**
- Seeded assignment: draft text + an uploaded PDF + chart save and reload from the server; submit succeeds; state becomes submitted.
- Grading it as the seeded instructor on the local server (or via 020 later) shows score and feedback on refresh.
- Submitting an empty assignment is prevented client-side and the server's 409 is handled if bypassed.
- Returned submission can be resubmitted.

**Testing requirements** — contract (list/detail fixtures incl. graded and returned), service (body shape; no studentId), controller (autosave debounce, submit), widget (formats and states), integration (draft → upload → submit).

---

<a id="flutter-014"></a>
### FLUTTER-014 — Learner Certificates & Ranks

| | |
| --- | --- |
| **Purpose** | Celebrate achievement (LMS-011 learner side): certificate wallet, premium certificate view, claim, share; the rank ladder. |
| **Roles** | learner |
| **Dependencies** | FLUTTER-009 |
| **Routes / screens** | `/certificates` (Issued · Pending · Working towards), `/certificates/:certificateId` (certificate canvas + details), `/ranks` |
| **Sources** | `routes/learning.ts` (certificates, claim, rank-ladder), `lib/certificates.ts`, `routes/certificates.ts` (verify), `.claude/ui/certificates.md` |

**UI components** — wallet cards (course, title, credential id, issued date, status badge), working-towards cards with criteria meters (`current/required unit`), `CertificateCanvas` (template `heading`, `statement`, learner name, course, level, completion date, credential id, `hours` if `showHours`, `finalScore` if `showScore`, signatories, `accent` → token family: `indigo`→accent, `saffron`/`emerald` → gold/earned and a deep green derived for the certificate only — defined in 001 as `certificateAccents`), seal with halo, actions: **Claim** (pending), **Share verification link**, **Open verification page**; rank ladder (ranks with `RankRing`, current standing, criteria progress).

**User actions** — view; claim pending; share `WEB_BASE_URL + verifyUrl`; rotate to landscape for the canvas; open verification (in-app `/verify/:credentialId`).

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /learning/certificates` | — | `{issued: CertDetail[], pending: CertDetail[], working: CertificateRecord[]}` | |
| `GET /learning/certificates/:id` | — | `CertDetail {certificate:{id, credentialId, courseId, title, templateId, status, completedAt, issuedAt?, finalScore?, hours, verifications}, student:{name, city}, courseTitle, levelTitle, template:{name, style, accent, heading, statement, signatories, showScore, showHours}, verifyUrl}` | 404 |
| `POST /learning/certificates/:id/claim` | — | `CertDetail` (issued) | 404 / 409 |
| `GET /learning/rank-ladder` | — | `{ranks:[{id, title, order, descriptor, criteria}], standing:{rankId, achieved, progress}}` | |

**Note** — `working` may be empty (docs/01 known simplification). No PDF/image download exists (server returns data only); "Download" is **not** offered (**B8-like**; recorded).

**Validation** — n/a.

**States** — wallet skeleton/empty ("Complete a course to earn your first certificate")/error; pending claimable; claim busy/success (celebration, haptic); revoked (badge + reason if present); canvas render error fallback to details list.

**Offline** — cached wallet; claim disabled.

**Security** — share only the public verification URL (no email, no ids beyond the credential id).

**Acceptance criteria**
- Seeded issued certificates render on the canvas with the right template fields; pending → claim → issued.
- Share sheet contains `WEB_BASE_URL/verify/<credentialId>`.
- Canvas legible on a 360 dp phone portrait (scaled) and landscape; golden tests light/dark.
- Rank ladder shows the seeded standing.

**Testing requirements** — contract, controller (claim), widget + golden (canvas), integration (claim flow if a pending certificate can be produced by completing a seeded course on the local server; otherwise record why).

---

<a id="flutter-015"></a>
### FLUTTER-015 — Learner Live Classes

| | |
| --- | --- |
| **Purpose** | Learner schedule and join experience for live sessions (LMS-012 learner side). |
| **Roles** | learner |
| **Dependencies** | FLUTTER-009 |
| **Routes / screens** | `/live` (Live now · Upcoming · Recordings), `/live/:liveId` (detail) |
| **Sources** | `routes/live.ts` (`/live/learner`, `/:id/register`), `packages/domain/src/live-class.ts`, §14, `.claude/ui/live-classes.md` |

**UI components** — live-now banner card (pulsing dot respecting reduced motion), upcoming cards (course, title, instructor, IST date/time, duration, `CountdownChip`, registered badge, spots left), detail (description, agenda items with minutes, instructor, capacity, reminders note), **Join** button (enabled only in `starting-soon`/`live` and with an `https` external link), **Register/Unregister** toggle.

**User actions** — register/unregister; join (external app/browser); open course.

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /live/learner` | — | `{live: LearnerLiveRow[], upcoming: LearnerLiveRow[] (+registered), recordings: LearnerLiveRow[]}`; row = `{liveClass: LiveClass, phase, courseTitle, instructorName}` | 400 non-learner (router prevents) |
| `POST /live/:id/register` | — | `{registered: bool, spotsLeft: int}` (999 = unlimited → hide) | 403 not enrolled; 409 cancelled/ended/full |
| detail data | from the `/live/learner` row (no learner detail endpoint exists) — or from the lesson view's `live` | | |

**Models** — `LiveClass {id, courseId, title, instructorId, startsAt, durationMin, capacity?, registered?, attending?, cancelled?, recording?, description?, agenda?, visibility?, meeting?: {kind, link?}, reminders?, attended?, cancelReason?, chapterId?}`; `LivePhase` (upcoming|starting-soon|live|ended|recording-expired|cancelled|unknown).

**Phase** — displayed from the server's `phase`, re-derived client-side every 30 s on visible screens with the ported pure function (§14) so "Join" enables at T-15 without a refetch.

**Validation** — join only `https` links (**B12** for `room`).

**States** — skeleton; empty ("No live classes scheduled"); live now; starting soon; registered; full; cancelled (reason); ended; recording listed — playback **not available** (no recording write/playback path; display "Recording" info only if `recording` present, **Needs clarification** on playback); error; offline.

**Offline** — join still opens the link if already loaded (the meeting is external); register disabled.

**Security** — external launch only; no WebView; link host shown in a confirmation the first time ("Opens meet.example.com").

**Acceptance criteria**
- Seeded live classes appear in the right buckets; register toggles and `spotsLeft` updates.
- With a class scheduled on the local server 10 min ahead, Join becomes enabled without refresh (fake clock in widget test; real check recorded).
- `room`/missing link shows the unavailable message.

**Testing requirements** — unit (phase function mirrored against domain test cases), contract, widget (all phases), integration (register toggle).

---

<a id="flutter-016"></a>
### FLUTTER-016 — Notifications Centre & Preferences

| | |
| --- | --- |
| **Purpose** | In-app notifications for every role (LMS-014) and per-category preferences. |
| **Roles** | learner, instructor, admin |
| **Dependencies** | FLUTTER-006 |
| **Routes / screens** | `/notifications` and `/staff/notifications` (All · Unread · category filter), `…/:notificationId` (detail), `…/preferences` |
| **Sources** | `routes/notifications.ts`, `packages/domain/src/notification.ts`, `lib/notify.ts`, `.claude/ui/notifications.md`, §12 |

**UI components** — bell with badge (in shells), list rows (category icon, title, summary, relative time, unread dot, important marker), category `FilterChipBar` with `counts`, swipe to mark read/unread and remove (with Undo snackbar), overflow: Mark all read, Clear (confirm with count); detail (title, body paragraphs, facts key-value, actor, primary/secondary action buttons mapped via §5.4, related list); preferences (per category: App / Email / SMS switches; locked `system`; email digest segmented `instant|daily|weekly|off`; quiet hours toggle + from/to time pickers; pause until date/time; SMS number field shown only if the server returns `smsNumber` and SMS is enabled).

**User actions** — open; mark read/unread; mark all read (optionally per category); remove + undo (restore); clear (confirm); change preferences and save (unsaved-changes guard).

**API requirements**

| Method & path | Request | Response |
| --- | --- | --- |
| `GET /notifications?unreadOnly&category&limit` | limit 50 (page by increasing limit up to 200 — the endpoint has no page param) | `{rows: AppNotification[], total, unread, counts: {course, assignment, quiz, live, certificate, enrollment, system}}` |
| `GET /notifications/:id` | — (marks read) | `{notification, related: AppNotification[], channels: {app, email, sms}}` |
| `POST /notifications/read` | `{ids: [..≤500], read: bool}` | `204` |
| `POST /notifications/read-all` | `{category?}` | bare number |
| `POST /notifications/remove` | `{ids}` | `204` |
| `POST /notifications/restore` | `{notifications: [full removed objects ≤100]}` | `204` (undo) |
| `POST /notifications/clear` | `{category?, unreadOnly?}` | bare number |
| `GET /notifications/settings/me` | — | `NotificationSettings {categories:[{category, channels:{app,email,sms}}], emailDigest, quietHours:{enabled, from, to}, pausedUntil?, smsNumber}` |
| `PUT /notifications/settings/me` | same shape (≤ 20 categories; `from`/`to` "HH:MM") | same without `smsNumber`; 409 issues (e.g. quiet hours equal) |

`AppNotification {id, category, title, summary, body: String[], createdAt, readAt?, important?, actor?, facts?: [{label, value}], action?: {label, to}, secondaryAction?}` (ignore `recipientId`).

**Polling** — unread count per §12 (60 s foreground, on resume, after mutations).

**Validation** — quiet hours from ≠ to (server rule; shown on 409 too); pause in the future.

**States** — skeleton; empty ("You're all caught up"); filter empty; error; detail not found; saving preferences; saved; validation issues.

**Offline** — list cached; mutations disabled.

**Security** — only the caller's notifications (server); action links never opened as raw URLs.

**Acceptance criteria**
- Seeded notifications for each role render; unread badge equals `unread`.
- Remove → Undo restores the exact notification (server restore).
- Mark all read sets badge to 0 using the bare-number response.
- Preferences round-trip; the `system` category cannot be switched off (UI locked and server-confirmed).
- Every `action.to` in the seed maps to an app route or is shown without navigation.

**Testing requirements** — contract (list/detail/settings), service (bare-number and 204 handling), controller (undo, polling timer with fake async), widget (all states), integration (read → badge decrement).

---

<a id="flutter-017"></a>
### FLUTTER-017 — Profile, Account & App Settings

| | |
| --- | --- |
| **Purpose** | Who I am, how the app behaves, help, and signing out. |
| **Roles** | learner, instructor, admin |
| **Dependencies** | FLUTTER-006 |
| **Routes / screens** | `/profile` (and `/staff/profile`): identity card (name, email, role label, `descriptor`), learner extras (rank from `/learning/rank-ladder` standing, activity feed from `/learning/activity`), links: Notification preferences, Help centre, Privacy, Terms, About; `/profile/settings`: theme (system/light/dark), reduced motion, text-size preview (uses system scale; explains how to change it), clear image cache; Sign out (confirm) |
| **Sources** | `routes/auth.ts` (`/auth/me`), `routes/learning.ts` (`/activity`, `/rank-ladder`), `routes/help.ts` |

**User actions** — view profile; change app settings (local); open help with the role's `audience`; request a password reset email for my own address ("Change password" → forgot-password flow prefilled — the only way the backend offers, **B3**); sign out.

**API requirements** — `GET /auth/me`; `GET /learning/activity` (`{week, events: LearningEvent[{id, kind, title, context?, at}]}`), learner only; `GET /learning/rank-ladder`, learner only; `POST /auth/forgot-password`; help endpoints (008).

**Backend capability required** — B3 (edit name/email, change password in-session); B1 (server sign-out). The UI shows no edit controls rather than disabled fakes; the About screen lists nothing about these.

**Validation** — n/a.

**States** — profile skeleton/error; activity empty; sign-out confirm and busy.

**Offline** — profile from session; settings local; sign-out works offline (local purge).

**Security** — sign-out purge verified (token, caches, providers, temp files); "Clear image cache" is local only.

**Acceptance criteria**
- Profile reflects `/auth/me`; the role label and descriptor match the web.
- Theme and reduced-motion changes apply instantly and persist across restarts.
- Sign out returns to Welcome and a subsequent protected request carries no token (test).
- Help hub filters by the signed-in role's audience.

**Testing requirements** — controller (settings persistence, sign-out purge), widget, navigation (sign-out redirect), integration (sign out → sign in as another role shows none of the previous user's data).

---
<a id="flutter-018"></a>
### FLUTTER-018 — Staff Dashboard

| | |
| --- | --- |
| **Purpose** | The instructor's and admin's command centre on a phone (LMS-001): what needs attention now, then how things are going. |
| **Roles** | instructor (own scope), admin (`reports.view`) |
| **Dependencies** | FLUTTER-006 |
| **Routes / screens** | `/staff` |
| **Sources** | `routes/dashboard.ts`, `packages/domain/src/analytics.ts`, `.claude/ui/dashboard.md`, `docs/modules/dashboard.md` |

**UI components** — needs-attention cards (severity tone + icon + text, `count`, tap → mapped `to`), quick actions (Review queue, Schedule live class, Message learners, Add enrolment — each gated by capability), upcoming live list, KPI tiles (`courses`, `students`, `third` = active instructors (academy) / submissions waiting (instructor), `completionRate`) with previous-period delta in words and sparkline from `series`, enrolments/completions 12-week `TrendChart`, engagement (lessons completed, quiz attempts, submissions, live attendance — this week vs last), activity feed (`events`, ≤ 12, actor + summary + relative time), course performance list (enrolled, active, completion, avg progress, weekly sparkline). Admin: segmented Academy | Instructor scope with instructor picker (`instructorId`, admin only).

**User actions** — pull to refresh; open attention item/event/course; quick actions; switch scope (admin).

**API requirements**

| Method & path | Query | Response |
| --- | --- | --- |
| `GET /dashboard` | `scope?` (`academy`|`instructor`), `instructorId?` (admin only; never sent by instructors) | `DashboardSnapshot {scope, generatedAt, kpis: {courses, students, third, completionRate}: Kpi {value, previous, series, unit?}, enrollments: TrendPoint[], completions: TrendPoint[], courses: CoursePerformance[], activity: ActivityDay[28], engagement: {...Kpi}, upcomingLive: LiveClass[], attention: AttentionItem[{id, kind, title, detail, count?, severity, to}], events: AdminEvent[{id, kind, actor, summary, context?, courseId?, at, to?}]}` |
| `GET /instructors` (admin scope picker) | — | rows (name, id) |

**Permissions / entitlements** — `reports.view` (staff permission). The dashboard is never plan-gated (docs/04).

**KPI copy rule** — counts change in percent, rates in points (`packages/domain/src/analytics.ts`) — port the pure `kpiChange` rule with tests; never recompute the KPI values.

**States** — skeleton per section; no-data (new academy) state per section; partial failure = section error rows; permission denied (admin without `reports.view`); offline.

**Acceptance criteria**
- Seeded admin and instructor dashboards show the same figures as `GET /dashboard` for their scope; the instructor never sends `instructorId`.
- Every attention/event `to` in the seed maps to a working app route or is non-navigable.
- Phone priority order: attention → quick actions → live → KPIs → analysis (LMS-001 / progress.md); tablet two columns.

**Testing requirements** — contract, unit (`kpiChange`), controller, widget (sections, states, 200 %), navigation (attention links).

---

<a id="flutter-019"></a>
### FLUTTER-019 — Staff Courses & Curriculum

| | |
| --- | --- |
| **Purpose** | See and steer the course catalogue (LMS-002/004/005 read side) and take the consequential lifecycle decisions on the go. |
| **Roles** | instructor (courses they teach), admin (`catalog.view`, `catalog.publish`, `catalog.archive`) |
| **Dependencies** | FLUTTER-018 |
| **Routes / screens** | `/staff/courses` (status tabs All/Draft/Published/Archived with counts, search, category filter, admin instructor filter, sort), `/staff/courses/:courseId` (overview: cover, metadata, instructors, outcomes, stats, curriculum summary, lifecycle actions), `/staff/courses/:courseId/curriculum` (chapters → lessons with type, duration, status, preview flag, per-chapter completion/started rates), `/staff/courses/:courseId/lessons/:lessonId` (read-only lesson view reusing 011's renderers with staff context) |
| **Sources** | `routes/courses.ts`, `routes/chapters.ts` (stats), `routes/lessons.ts` (GETs), `.claude/ui/courses.md`, `.claude/ui/chapters.md`, `.claude/ui/lessons.md` |

**User actions** — search/filter/sort/paginate; open course; view stats; view curriculum; **Publish** (confirm: consequences first; on 409 show the checklist `issues` as a list; instructors under review-before-publish get 403 "sent for review" message from the server), **Unpublish**, **Archive** (confirm with acknowledgement), **Restore**; "Edit on the web" link opens `WEB_BASE_URL/<admin|teach>/courses/:id/edit` externally (C2).

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /courses` | `search ≤200, categoryId, instructorId (admin), status (draft|published|archived|all), sort (title|learners|created|updated), page, pageSize` | `{rows: Course[], total, counts: {all, draft, published, archived}}` | 403 |
| `GET /courses/:id` | — | `Course` | 404 |
| `GET /courses/:id/stats` | — | `{enrolled, active, completionRate, avgProgress, weekly[12], progressBuckets[5], recent[≤8], upcomingLive, certificatesIssued, reviewsWaiting, totalMinutes}` | 404 |
| `GET /courses/:courseId/chapters/stats` | — | `{enrolled, chapters: {id: {completionRate, startedRate}}, lessons: {id: percent}}` | |
| `GET /courses/:courseId/lessons?chapterId&type&status&search&sort` | — | `{rows: [{lesson, chapterId, chapterTitle, chapterIndex, lessonIndex}], counts}` | |
| `GET /courses/:courseId/lessons/:lessonId` | — | `{lesson, chapterId, chapterTitle, chapterIndex, lessonIndex, chapter, previous?, next?}` | 404 |
| `POST /courses/:id/publish` | — | `Course` | 409 checklist `issues`; 403 review required; 403/402 entitlement |
| `POST /courses/:id/unpublish` | — | `Course` | |
| `POST /courses/:id/archive` | — | `Course` | |
| `POST /courses/:id/restore` | — | `Course` | 403 `LIMIT_REACHED` (`courses.max`) |
| `GET /categories` | (admin/instructor `catalog.view`) | `{rows: [{category, courseCount, …}], counts}` | for the category filter |

**Permissions / entitlements** — publish needs `catalog.publish` (+ `courses.manage` feature); archive/restore `catalog.archive`; unpublish/archive never plan-gated; restore consumes `courses.max`.

**Validation** — n/a (no forms).

**States** — list skeleton/empty ("No courses yet — create one on the web")/filter-empty/error; detail loading/not found (out-of-scope → 404); action busy; checklist refusal dialog; entitlement refusals (006).

**Offline** — cached lists; actions disabled.

**Acceptance criteria**
- The seeded instructor sees only their courses (server-scoped) and gets not-found for another instructor's course id.
- Publishing an incomplete draft shows the server checklist; publishing a complete one flips the status and updates list counts.
- Archive requires acknowledgement; restore works; each action updates list + detail without restart.
- "Edit on the web" opens the right URL for the role (`/admin` vs `/teach`).

**Testing requirements** — contract (list/detail/stats/lessons), service (query building; no instructorId for instructors), controller (paging, actions, invalidation), widget (states, dialogs), integration (publish refusal + success as admin).

---

<a id="flutter-020"></a>
### FLUTTER-020 — Staff Assignment Review & Grading

| | |
| --- | --- |
| **Purpose** | Grade hand-ins from a phone (LMS-007 staff side) — the instructor's most frequent mobile task. |
| **Roles** | instructor (own courses), admin (`assessment.view`, `assessment.grade`, `learners.message` for reminders) |
| **Dependencies** | FLUTTER-019, FLUTTER-007 |
| **Routes / screens** | `/staff/review` (queue: counts To review · Overdue by course, submissions list with filter tabs `to-review|graded|returned|missing`, search, sort oldest/newest/score), `/staff/assignments/:assignmentId/submissions` (per-assignment list incl. missing learners + "Remind missing"), `/staff/submissions/:submissionId` (review) |
| **Sources** | `routes/assignments.ts` (review, submissions, submission detail, review POST, remind), `packages/domain/src/assignment.ts` (`validateReview`, `reviewScore`), `.claude/ui/assignments.md` |

**UI components** — submission cards (learner avatar/initials, name, assignment, course, submitted time, late badge, attempt #, status), review screen: brief summary (collapsible), learner work (text with `bodyL`, files via `AuthImage`/PDF viewer, birth chart card), `RubricScorer` sheet (per criterion stepper/slider 0–points, running total, or single `points` when no rubric), feedback editor (≤ 10000), private note (≤ 5000, "Only staff see this"), decision buttons **Save draft** · **Return for changes** · **Grade** (confirm shows total and pass/fail vs `passMark` as the server will compute — display computed by the server's response, preview labelled "estimated"), queue navigation (previous/next from `queue`).

**User actions** — filter/search; open submission; score; write feedback; save draft review; return; grade; go to next; remind missing learners (all or selected).

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /assignments/review` | — | `{toReview, overdue, byCourse: [{courseId, toReview, overdue}]}` | |
| `GET /assignments/submissions` | `assignmentId?, courseId?, filter?, search?, sort?, page, pageSize` | `{rows: [{id, submission?, student:{id,name,email,city}, assignmentId, assignmentTitle, courseTitle, maxScore, overdue}], total, counts}` | |
| `GET /assignments/:id/submissions` | same query | same | |
| `GET /assignments/submissions/:submissionId` | — | `{submission, assignment, courseTitle, chapterTitle?, student:{id,name,email,city,progress,enrolledAt}, queue:{position,total,previousId?,nextId?}}` | 404 |
| `POST /assignments/submissions/:submissionId/review` | `{decision: draft|graded|returned, scores?: Map<criterionId, num>, points?: num, feedback? ≤10000, privateNote? ≤5000}` | `Submission` | 409 `issues` (validateReview) |
| `POST /assignments/:id/remind` | `{studentIds?: [..≤500]}` | `{sent}` | |
| `GET /assignments?courseId&status&search` | — | rows (for the per-assignment picker) | |

**Validation (UX mirrors `validateReview`)** — each criterion 0..points; feedback required when returning (confirm against the domain validator in implementation and record); server issues shown per criterion.

**States** — queue skeleton/empty ("Nothing to review — nice work")/error; submission loading/not found; saving; graded success → auto-advance prompt; returned; missing learners list; offline (review text kept in memory, submit disabled); unsaved-changes guard.

**Security** — `privateNote` never shown to learners (server strips); student email shown only to staff.

**Acceptance criteria**
- Seeded waiting submission: open, score, feedback, Grade → counts decrease; learner (013) sees the grade.
- Return for changes → learner can resubmit.
- Draft review persists and reloads.
- Tablet two-pane (queue + review).

**Testing requirements** — contract, service (decision payloads), unit (score preview helper), controller (queue navigation, guard), widget (review sheet states, 200 % text), integration (grade end-to-end with 013).

---

<a id="flutter-021"></a>
### FLUTTER-021 — Staff Quizzes Overview

| | |
| --- | --- |
| **Purpose** | Understand quiz performance (LMS-006 results preview) without the builder. |
| **Roles** | instructor, admin (`assessment.view`) |
| **Dependencies** | FLUTTER-019 |
| **Routes / screens** | `/staff/quizzes` (search, course filter, status tabs with counts; rows: title, course, chapter, points, attempts, pass rate, avg score), `/staff/quizzes/:quizId` (settings summary, questions list read-only with type and points — correct answers shown to staff, stats: attempts, learners, pass rate, avg score, median minutes, score distribution, per-question correct rate and common wrong option) |
| **Sources** | `routes/quizzes.ts` (GETs), `.claude/ui/quizzes.md` |

**User actions** — browse; open quiz; "Edit on the web" (C2).

**API requirements** — `GET /quizzes?search&courseId&status` → `{rows: [{quiz, courseTitle, chapterTitle?, points, attempts, passRate?, avgScore?}], counts}`; `GET /quizzes/:id` → `Quiz` (staff model incl. `correct`; `showResults` read as `score-only|score-and-answers|nothing|hidden` — **A5**); `GET /quizzes/:id/stats` → `{attempts, learners, passRate, avgScore, medianMinutes, distribution, questions: [{questionId, correctRate, commonWrongOptionId?}]}`.

**States** — skeleton/empty/filter-empty/error; stats with no attempts ("No attempts yet").

**Acceptance criteria** — seeded quiz shows stats matching the endpoint; the staff quiz model is a separate DTO from the learner one (architecture test: learner feature cannot import it).

**Testing requirements** — contract, widget (charts + read-out), unit (distribution formatting).

---

<a id="flutter-022"></a>
### FLUTTER-022 — Staff Students

| | |
| --- | --- |
| **Purpose** | Know and support learners (LMS-008): roster, profile, progress, activity, enrolments, messages; admins also suspend/restore. |
| **Roles** | instructor (learners in their courses), admin (`learners.view`, `learners.enroll`, `learners.message`, `learners.suspend`) |
| **Dependencies** | FLUTTER-018 |
| **Routes / screens** | `/staff/students` (search, course filter, status tabs all/active/at-risk/inactive/suspended with counts, sort name/progress/joined/last active, multi-select → Message), `/staff/students/:studentId` tabs: Overview (identity, status, quiet days, rank, summary: enrolled, active, completed, avg progress, study minutes, submissions, avg score, certificates) · Courses (enrolments with progress, chapters/lessons done, last lesson; actions pause/resume/remove) · Progress (per course chapters %, quizzes, assignments) · Activity (events, filter by kind/course) |
| **Sources** | `routes/students.ts`, `packages/domain/src/people.ts`, `.claude/ui/students.md` |

**User actions** — search/filter/sort/paginate; open student; **Enrol in a course** (course picker from `/courses` within scope, source default `admin`); pause/resume enrolment; remove enrolment (destructive confirm); **Message** selected learners (subject 1–200, body 10–5000, channels app/email ≥ 1); admin: **Suspend/Restore** (reason ≤ 500, confirm consequences: "They can't sign in or learn until restored").

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /students` | `search, courseId, status, sort, page, pageSize` | `{rows: [{student, status, courses:[{id,title,progress,status}], progress}], total, counts}` | |
| `GET /students/:id` | — | `StudentProfile {student, status, quietDays, rank, enrollments:[…], certificates:[…], summary}` | 404 out of scope |
| `GET /students/:id/progress` | — | `{courses, quizzes, assignments, studyWeeks}` | |
| `GET /students/:id/activity` | `kind?, courseId?, limit (≤500, default 200)` | `{events, total, counts}` | |
| `POST /students/message` | `{ids ≤500, subject, body, channels}` | `{sent}` (out-of-scope ids dropped silently — show "Sent to N") | 400 |
| `POST /students/:id/enroll` | `{courseId, source?}` | `201|200 Enrollment` | 404 |
| `PATCH /students/enrollments/:enrollmentId` | `{status: active|paused}` | `Enrollment` | |
| `DELETE /students/enrollments/:enrollmentId` | — | `204` | |
| `POST /students/:id/suspend` | `{suspended: bool, reason? ≤500}` | `Student` | 403 (admin + `learners.suspend` only) |

**Validation** — message form per schema; reason ≤ 500.

**States** — roster skeleton/empty/filter-empty/error; profile tabs each with their own loading/error; action busy/success/failure; suspended badge.

**Offline** — cached; actions disabled.

**Security** — learner email/phone visible to staff only; never cached to disk.

**Acceptance criteria**
- Instructor roster equals the server's scoped list; an out-of-scope student id → not found.
- Enrol → the course appears on the profile and in that learner's app (013/009) after refresh.
- Message to two seeded learners → notifications appear for them (016).
- Admin suspend → the learner is signed out on next request; restore reverses.

**Testing requirements** — contract, service, controller (multi-select, actions), widget (tabs, dialogs), integration (enrol + message).

---

<a id="flutter-023"></a>
### FLUTTER-023 — Staff Live Classes

| | |
| --- | --- |
| **Purpose** | Run live teaching (LMS-012 staff side): schedule, edit, remind, cancel, start. |
| **Roles** | instructor (own courses), admin (`live.manage`, `live.notify`) |
| **Dependencies** | FLUTTER-019 |
| **Routes / screens** | `/staff/live` (Upcoming · Live · History · Cancelled with counts, search, course filter, admin instructor filter), `/staff/live/:liveId` (detail: phase, course, instructor, time, duration, capacity, registered, attendees list, agenda, reminders, meeting link, previous/next), `/staff/live/new`, `/staff/live/:liveId/edit` (form) |
| **Sources** | `routes/live.ts`, `packages/domain/src/live-class.ts` (`validateLiveClass`), `.claude/ui/live-classes.md`, §14 |

**Form fields (full object; PATCH needs everything)** — course (picker in scope), title, instructor (admin: picker; instructor: self), date + start time (IST) → `startsAt` ISO, duration (15–240 min, validator), capacity (optional), description, agenda items (title + minutes), visibility (`enrolled|cohort|public`), meeting (kind `external` with an `https` link; `room` hidden until **B12**), reminders (minutes-before chips, ≤ 10), chapter (optional).

**User actions** — create; edit (refused once started/cancelled — show server message); **Start/Join** (open meeting link); **Send reminder now**; set reminder offsets; **Cancel** (reason ≥ 3, confirm: "Registered learners will be notified").

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /live` | `view?, search?, courseId?, instructorId? (admin), page, pageSize` | `{rows: [{liveClass, phase, courseTitle, instructorName}], total, counts}` | |
| `GET /live/:id` | — | `{liveClass, phase, courseTitle, instructorName, instructorTitle, attendees:[{id,name,city,attended?}], attendeeTotal, recordingViews?, previous?, next?}` | 404 |
| `POST /live` | `LiveClassInput {courseId, title, instructorId, startsAt, durationMin, capacity?, description?, agenda?, visibility?, meeting?, reminders?, chapterId?}` | `201 LiveClass` | 409 `issues`; 402/403 `live_classes` feature; 403 `LIMIT_REACHED` (`live_classes.max` for that month) |
| `PATCH /live/:id` | full `LiveClassInput` | `LiveClass` | 409 started/cancelled |
| `POST /live/:id/cancel` | `{reason 3–1000}` | `LiveClass` | |
| `POST /live/:id/remind` | — | `{sent}` | |
| `PATCH /live/:id/reminders` | `{reminders: int[] ≤10}` | `LiveClass` | |

**A1** — before building the form, confirm whether writes must send `meeting.link` (validator) or `meeting.url` (schema) by a request against the local server; record the finding in §28 and progress.md.

**Validation (UX)** — duration 15–240; start in the future for new classes; https link; reminders unique positive.

**States** — list skeleton/empty/error; form unsaved guard; saving; validation issues (field-mapped); cancelled detail; ended; entitlement/limit refusals.

**Acceptance criteria**
- Create a class for a seeded course → enrolled learners get a notification (016) and see it in 015.
- Edit, remind (reports `sent`), cancel (registered learners notified) work against the local server.
- A limit refusal renders the limit state (enforcement-on run recorded).

**Testing requirements** — contract, service (full-object PATCH), controller (form state), widget (form validation, phases), integration (create → learner sees it).

---

<a id="flutter-024"></a>
### FLUTTER-024 — Staff Calendar

| | |
| --- | --- |
| **Purpose** | A unified teaching schedule (LMS-013), agenda-first on phones. |
| **Roles** | instructor (own courses, own reminders), admin |
| **Dependencies** | FLUTTER-023 |
| **Routes / screens** | `/staff/calendar` (week strip + day agenda; month grid on tablets; type filter chips live/assignment/quiz/milestone/reminder with counts; course filter), `/staff/calendar/:eventId` (detail by type), `/staff/calendar/new`, `/staff/calendar/:eventId/edit` |
| **Sources** | `routes/calendar.ts`, `packages/domain/src/calendar.ts` (`validateCalendarEvent`), `.claude/ui/calendar.md` |

**Event detail** — type badge, course, instructor, date/time (IST) or all-day/moment, duration, description, live phase + join, deadline `due.learners/submitted` + learners due list, quiz summary, audience size, `editable` controls, mark done (reminders).

**Form** — type (`reminder|milestone|quiz` for own events; `live`/`assignment` rows are generated and not editable here), title, description, timing `timed|moment|all-day`, startsAt, duration, course, chapter, quiz, milestone kind, audience `me|learners`, notify minutes.

**API requirements**

| Method & path | Request | Response |
| --- | --- | --- |
| `GET /calendar` | `from, to` (YYYY-MM-DD, **IST**), `types?`, `courseId?`, `instructorId?` (admin) | `{rows: [{event, courseTitle?, instructorName?, phase?, due?}], counts, total}` |
| `GET /calendar/:id` | — | detail (`editable`, `live?`, `due?`, `learnersDue?`, `quiz?`, `audienceSize?`) |
| `POST /calendar` | `{input: CalendarEventInput}` | `201 CalendarEvent` |
| `PATCH /calendar/:id` | the event object (not wrapped) | `CalendarEvent` |
| `DELETE /calendar/:id` | — | `204` |
| `POST /calendar/:id/done` | `{done}` | `CalendarEvent` |

Generated ids `live-<id>` / `assignment-<id>` route to the live detail (023) / submissions list (020) instead of the edit form.

**Validation** — mirror `validateCalendarEvent` messages as UX; server 409 issues field-mapped.

**States** — agenda skeleton; "No events this day"; range empty; error; not editable; offline.

**Acceptance criteria** — agenda for the seeded week matches the server rows; create/edit/delete a personal reminder; IST boundaries correct for events near midnight.

**Testing requirements** — unit (range → IST dates), contract, widget (agenda/month), integration (create reminder).

---

<a id="flutter-025"></a>
### FLUTTER-025 — Admin Instructors & Certificates

| | |
| --- | --- |
| **Purpose** | Academy-admin people and credential operations (LMS-009, LMS-011 management) that are practical on mobile. |
| **Roles** | admin (`instructors.view|manage|status`, `certificates.issue|revoke`); instructors: read-only instructor directory (`instructors.view`) and certificate issue for their courses |
| **Dependencies** | FLUTTER-022 |
| **Routes / screens** | `/staff/instructors` (search, status tabs all/active/invited/inactive, expertise filter, sort), `/staff/instructors/:instructorId` tabs Overview (bio, expertise, languages, city, reach, activity) · Courses · Performance (rating vs academy, completion vs academy, review median hours, on-time %, live delivered/upcoming, attendance, enrolments by month), `/staff/instructors/invite` (full instructor form), `/staff/certificates` (search, course filter, status tabs issued/pending/revoked), `/staff/certificates/:certificateId` (canvas from 014 + staff actions) |
| **Sources** | `routes/instructors.ts`, `routes/certificates.ts`, `.claude/ui/instructors.md`, `.claude/ui/certificates.md` |

**User actions** — invite instructor (name, title, email, bio, expertise tags, status `invited`, city, languages, courses, phone?, yearsTeaching?; photo upload **not** offered — form sends no photo change), edit (full object PATCH — prefill every field), change status (active/inactive, confirm), resend invite; certificates: **Issue** pending, **Revoke** (reason ≥ 3, destructive confirm), **Restore**.

**API requirements**

| Method & path | Request | Response | Errors |
| --- | --- | --- | --- |
| `GET /instructors` | `search, status, expertise, sort` | `{rows: [{instructor, courses, students, rating?, ratingCount, completion?, toReview, overdue}], counts, expertise}` | |
| `GET /instructors/:id` | — | `{instructor, courses, reach, performance, activity}` | 404 |
| `POST /instructors` | full `InstructorInput` | `201 Instructor` | 409 email; 403 `LIMIT_REACHED` (`instructors.max`) |
| `PATCH /instructors/:id` | full `InstructorInput` | `Instructor` | |
| `POST /instructors/:id/status` | `{status}` | `Instructor` | |
| `POST /instructors/:id/resend-invite` | — | `{sentTo}` | |
| `GET /certificates` | `search, courseId, status, page, pageSize` | `{rows: [{certificate, studentName, studentEmail, courseTitle}], total, counts}` | |
| `GET /certificates/:id` | — | detail (as verify shape + student) | 404 |
| `POST /certificates/:id/issue` | — | `IssuedCertificate` | 409 not pending; entitlement `certificates.manage` |
| `POST /certificates/:id/revoke` | `{reason 3–1000}` | `IssuedCertificate` | |
| `POST /certificates/:id/restore` | — | `IssuedCertificate` | 409 not revoked |

**Validation** — instructor form mirrors `validateInstructor` + zod (email, required fields); reason length.

**States** — standard; invite success ("Invitation sent to …"); limit reached; revoked badge with reason.

**Acceptance criteria** — invite a new instructor on the local server (outbox shows the invite email row); status change blocks their sign-in; issue a pending certificate → learner sees it issued; revoke → public verification shows revoked.

**Testing requirements** — contract, service (full-object PATCH), widget, integration (issue/revoke round trip with 014/008).

---

<a id="flutter-026"></a>
### FLUTTER-026 — Admin Reports

| | |
| --- | --- |
| **Purpose** | Readable analytics on a phone (LMS-015): headline figures, trends and ranked summaries — not spreadsheets. |
| **Roles** | admin (`reports.view`; instructors report needs `reports.instructors.view`), instructor (own scope, no instructor report) |
| **Dependencies** | FLUTTER-018 |
| **Routes / screens** | `/staff/reports` (overview), `/staff/reports/courses`, `/staff/reports/courses/:courseId`, `/staff/reports/learners`, `/staff/reports/instructors` (admin), `/staff/reports/enrolments` |
| **Sources** | `routes/reports.ts`, `lib/reports.ts`, `packages/domain/src/reports.ts`, `.claude/ui/reports.md` |

**Controls** — period `30d|90d|6m|12m` (default 90d), segment (learners), category, course, instructor (admin) in a `FilterSheet`; the active filters summarised under the title.

**Content** — KPI tiles with previous-period deltas; `TrendChart` for series; progress bands and funnels as `BarList`; tables → ranked cards (top N with "Show all" paging for learners); every chart has a list read-out; figures formatted, never recomputed.

**API requirements** — `GET /reports/overview`, `/reports/courses`, `/reports/courses/:courseId` (404 for drafts), `/reports/learners` (+ `search, sortKey (name|courses|progress|assignments|lastActive), sortDirection, page, pageSize`), `/reports/instructors` (admin + `reports.instructors.view` + `reports.advanced`), `/reports/enrolments`; shared query `range, segment, categoryId, courseId, instructorId`. Response shapes as listed in the backend route (`window`, `courseCount` always present). Model each tab's DTO field-for-field from the route when implementing.

**Entitlements** — `reports.basic` (overview, courses, learners, enrolments), `reports.advanced` (instructors): refusals → `FeatureUnavailableView`.

**States** — skeleton per tab; no data; filtered no results; error; feature unavailable; permission denied.

**Acceptance criteria** — each tab's figures equal the endpoint's for the seeded data at 90d and 12m; learner table sorting/paging round-trips `sortKey`/`sortDirection` (not an object — the web's past bug); charts readable at 360 dp and at 200 % text scale (read-out used).

**Testing requirements** — contract per tab, service (query serialization), widget (charts + read-outs, states), golden (overview light/dark).

---

<a id="flutter-027"></a>
### FLUTTER-027 — Academy Billing & Provider-Agnostic Checkout

| | |
| --- | --- |
| **Purpose** | Give the academy admin clear visibility of the subscription (SaaS §24) and, if approved (C4), pay through whatever gateway the backend selects (§11). |
| **Roles** | admin (`settings.view`; changes `settings.edit`) |
| **Dependencies** | FLUTTER-006, FLUTTER-016 |
| **Routes / screens** | `/staff/billing` (plan card: plan name, status badge, cycle, renewal/period end, trial days left or grace/past-due notices; usage meters per limit with used/allowed/remaining — unlimited shown as "Unlimited"; features included/not included; open plan change; invoices list; payments list), `/staff/billing/invoices/:invoiceId` (number, period, lines, subtotal, tax lines, total, status, issued/due/paid dates, billed-to), `/staff/billing/plans` (plans on sale: monthly/annual prices, trial, limits, features) |
| **Sources** | `routes/tenant.ts`, `lib/checkout.ts`, `lib/paymentProvider.ts` (incl. SAAS-017 WIP), `packages/domain/src/billingViews.ts`, `subscription.ts`, `money.ts`, `.claude/saas/subscriptions.md` §24/§43, `docs/07` (billing states), `apps/web/src/lib/billingActions.ts` (which actions appear — port as UX logic reading server state only) |

**Read-only part (always built)**

| Method & path | Response |
| --- | --- |
| `GET /tenant/billing` | `TenantBilling {academy:{id, name}, subscription?, plan?, restricted, enforced, openChange?, usage: UsageLine[], features: [{key, label, included}], invoices: Invoice[], payments: TenantPayment[], plans: Plan[], checkoutAvailable}` (UI status spelling) |
| `GET /tenant/billing/invoices/:idOrNumber` | `Invoice` view (`amounts {subtotal, tax, total}`) |
| `GET /tenant/plans` | `{rows: PlanRecord[], total}` (fallback detail for the plans screen) |

**Checkout part (built behind `BILLING_CHECKOUT_ENABLED`; default false)**

| Method & path | Request (only these fields) | Response | Errors |
| --- | --- | --- | --- |
| `POST /tenant/billing/purchase` | `{planId, cycle: monthly|annual}` | `201 CheckoutStart` | 409 `PAYMENT_REQUIRED` (no gateway), `INVALID_SUBSCRIPTION_STATE` (already subscribed), `CONFLICT` (billing address missing → "Add your billing address on the web"), `PLAN_UNAVAILABLE`, `CONFLICT` (payment under way) |
| `POST /tenant/billing/checkout` | `{invoiceId}` **or** `{planChangeId}` | `201 CheckoutStart` | 409 paid/void, `INVALID_SUBSCRIPTION_STATE`, `PAYMENT_REQUIRED`; 502 `PAYMENT_FAILED` |
| `POST /tenant/billing/checkout/confirm` | `{orderId, paymentId, signature}` (from the provider SDK result, unchanged) | `CheckoutOutcome {status, settled, applied, message}` | 400 bad signature / wrong payment; 404; 409 |
| `POST /tenant/subscription/change` | `{planId, cycle}` | `201 {change: OpenPlanChange, payable?}` (upgrade → then checkout with `planChangeId`; downgrade → scheduled date shown) | 409 |
| `POST /tenant/subscription/plan-changes/:id/cancel` | `{reason?}` | `PlanChangeRecord` | |
| `POST /tenant/subscription/cancel` | `{immediately?: false, reason 3–500}` | `SubscriptionRecord` | 409 |
| `POST /tenant/subscription/resume` | `{reason?}` | `SubscriptionRecord` | 409 |

`CheckoutStart {checkout: {provider, keyId?, orderId, amount, currency, redirectUrl?}, invoice: {id, number, total, currency}}`.

**Flow** — §11 diagram: launcher registry by `provider` + shape; Razorpay launcher (only when the flag is approved and `razorpay_flutter` added) passes `keyId`, `orderId`, `amount`, `currency`, academy name/email prefill from `TenantBilling` — nothing computed; success → confirm → show `message` → re-read `/tenant/billing`; `pending|authorized` → poll re-read 5 s × 12; cancel/failure → "Payment not completed" and nothing changes; unknown provider or `redirectUrl` without a return path → "Complete this payment on the web" (**B9**, **A3**).

**Money display** — every amount `int` minor units + currency via `Money.format`; totals shown as the server's figures; no arithmetic beyond formatting (the annual-saving line is shown only if the server provides it — otherwise omitted).

**Permissions** — actions require `changeBilling` (`settings.edit`); read requires `viewBilling`; instructors/learners never see the route.

**States** — skeleton; no subscription ("Your academy isn't on a plan yet"); trial (days left from server dates); past due / grace (dates); canceling (ends on …, Resume); paused (resumes on …); expired (restricted notice); checkout unavailable (`checkoutAvailable=false`: "Online payment isn't available yet"); enforcement off note for admins (`enforced=false`: "Plan limits aren't enforced yet" — wording **Needs clarification**, default: not shown); error; offline.

**Security** — no client amount/price/tenant/status/entitlement ever sent (service tests assert request bodies contain only the listed keys); no secrets; `keyId` held only for the active checkout; SDK callback never flips UI to active.

**Acceptance criteria**
- Read-only screens match `GET /tenant/billing` for the seeded academy (on a plan, and with no plan — create both states on the local server).
- Request-body tests prove only `{planId, cycle}`, `{invoiceId}`/`{planChangeId}`, `{orderId, paymentId, signature}` are ever sent.
- Launcher registry unit tests: razorpay+keyId → Razorpay launcher; redirectUrl → hosted launcher (https only) or unsupported; unknown provider → unsupported; missing fields → unsupported.
- With the flag false (default), no purchase/upgrade/pay control exists in the widget tree (test).
- If C4 is approved and Razorpay test keys are configured on the local server, a real test-mode payment completes and the plan becomes active only after confirm/re-read (recorded); otherwise this item is recorded as pending C4 and the module completes read-only.

**Testing requirements** — contract (TenantBilling for each status, invoice, CheckoutStart, CheckoutOutcome), service (request body whitelist), unit (launcher registry, billing action visibility), controller (confirm + polling with fake timers), widget (all states), integration (read-only; checkout only if C4 approved).

---
<a id="flutter-028"></a>
### FLUTTER-028 — Push Notifications & Deep Links

| | |
| --- | --- |
| **Purpose** | Open the right screen from links outside the app, and — once the backend supports it — deliver push notifications. |
| **Roles** | all |
| **Dependencies** | FLUTTER-016, FLUTTER-005 |
| **Sources** | §5, §12, §18, `routes/auth.ts` (reset link), `routes/certificates.ts` (verify URL), `routes/notifications.ts` |

**Part A — Deep links (buildable now)**
- Android App Links: intent filters with `android:autoVerify="true"` for the production host (`shubhlms.com`) paths `/reset-password/*`, `/verify/*`, `/courses/*`, `/learn/*`, `/notifications/*`; Flutter deep linking enabled; go_router parses and validates (§18: host allow-list, id charset/length).
- Mapping: `/reset-password/:token` → 004's reset screen; `/verify/:id` → 008; `/courses/:slug` → `/catalog/:slug`; `/learn/…`, `/notifications/:id` → §5.4 (sign-in first with `next`).
- **B13**: verification requires `https://<host>/.well-known/assetlinks.json` with the app's signing-cert SHA-256. Serving it is a web-hosting change outside this workflow. The module generates the file content (per flavor/signing key) into `apps/mobile/android/assetlinks/` and records the exact deployment step for a human. Until hosted, links open the browser (the web handles them) — acceptable fallback.
- Verification locally: `adb shell am start -a android.intent.action.VIEW -d "https://<host>/verify/<id>"` routes into the app when verification is overridden in dev (`adb shell pm set-app-links --package … 0 all` + `pm verify-app-links`) — recorded.

**Part B — Push (Backend capability required: B4; credential: C8)**
- Needs: a device registration endpoint (register/unregister token per user and platform), a push transport on the server that sends *id + category only*, and a Firebase project (`google-services.json` — a credential, never committed to a public place without approval).
- When available: `firebase_core` + `firebase_messaging`; permission request in context (Android 13+); token registered after sign-in, unregistered on sign-out; foreground → refresh badge + in-app banner; tap → fetch `/notifications/:id` → §5.4; malformed/unknown payloads dropped; no payload content displayed without the API fetch.
- **If B4/C8 are missing when this module runs: complete Part A, then mark the module `blocked` with `blockedReason` naming B4 and C8** (only FLUTTER-030 depends on it).

**States** — link to unknown path → not found; link while signed out → sign in → target; invalid token → "This reset link is invalid or has expired".

**Security** — verified links only; no custom scheme for tokens; reset token never logged; push payload untrusted.

**Acceptance criteria**
- Part A: each supported URL, launched via `adb`, opens the right screen (signed in and signed out); malformed ids are rejected; `assetlinks.json` generated with the correct package names and fingerprints for the available keys (debug now; release when C6/C16 signing exists).
- Part B: only when unblocked — token registration round-trip and a test push routed via the API.

**Testing requirements** — unit (URL → route parsing, validation), navigation tests, integration (adb-launched links on the emulator).

---

<a id="flutter-029"></a>
### FLUTTER-029 — Integration & End-to-End Test Suite

| | |
| --- | --- |
| **Purpose** | Prove the whole app against the real backend on a device, across modules, before hardening. |
| **Roles** | all |
| **Dependencies** | FLUTTER-008, 012, 013, 014, 015, 017, 020, 021, 024, 025, 026, 027 |
| **Sources** | `docs/08-TESTING-PLAN.md` E2E workflows (the flows that exist in the product) |

**Environment** — local contract server (workflow §7.3) with a fresh seeded scratch DB per run, Android emulator (API 34 or 36, phone profile; plus one tablet profile run), `flutter test integration_test -d <emulator> --flavor dev`.

**Journeys (from docs/08, adapted to the mobile scope)**
1. **Learner:** register → home → Explore → open course → enrol → lesson 1 (video) → watch past threshold → auto-complete → next → chapter quiz fail (null) → pass → chapter 2 unlocks → assignment draft + PDF upload → submit → (instructor grades, journey 2) → graded feedback visible → course completes → certificate pending/claim → share link → verify page.
2. **Instructor:** sign in → dashboard → review queue → grade the learner's submission → schedule a live class → learner sees it (switch account) → register → instructor cancels → learner notified.
3. **Admin:** sign in → dashboard attention link → students → enrol a learner → message → learner receives notification → instructors → invite → certificates issue/revoke → reports tabs → billing read-only.
4. **Session & safety:** token expiry (server restarted with a different `JWT_SECRET` → next call 401 → sign-in with `next`), suspended learner mid-session, offline (airplane mode via `adb shell cmd connectivity airplane-mode enable`) → banner → recovery, deep links (028 A), permission revoked mid-session (admin) → denied view, entitlement enforcement on (server restarted with `ENTITLEMENT_ENFORCEMENT=on`, academy without a plan) → restricted states.
5. **Accessibility smoke:** each journey's main screens pass `meetsGuideline(androidTapTargetGuideline)`, `labeledTapTargetGuideline`, `textContrastGuideline` in widget tests and a recorded TalkBack walk-through of journey 1.

**Also** — golden test suite completed for signature screens (§22.7) light/dark, compact/medium; the fixture set re-captured from the current backend and every contract test green.

**Acceptance criteria** — all journeys pass twice consecutively on a clean database (no flakiness); failures fixed at root cause (workflow §7.2); results, device profiles and durations recorded in progress.md.

**Testing requirements** — this module *is* the tests; it may fix bugs in any feature it exposes (normal §7 loop), recording each fix.

---

<a id="flutter-030"></a>
### FLUTTER-030 — Final Hardening & Release

| | |
| --- | --- |
| **Purpose** | Make the app production-ready and prove it with audits; prepare (not perform) the release. |
| **Roles** | all |
| **Dependencies** | FLUTTER-029, FLUTTER-028 |

**Verification (all must pass)**
- `dart format` check, `flutter analyze --fatal-infos --fatal-warnings`, full `flutter test --coverage` (coverage targets §23), full integration suite (029) on phone + tablet emulators.
- `flutter build apk --debug` for each flavor; `flutter build appbundle --release --flavor prod -t lib/main_prod.dart --obfuscate --split-debug-info=build/symbols` and a release APK installed and smoke-tested on the emulator (signed with the release key if provided — C16 — otherwise debug-signed and recorded as such).

**Audits (each recorded with evidence in progress.md)**

| Audit | Checks |
| --- | --- |
| Authentication | Token only in secure storage; restore/expiry/deactivation/suspension paths; sign-out purge; superadmin refusal; no credential in logs (log sweep over a full journey) |
| Authorization | Capability table re-verified against every route guard in `apps/api/src/routes`; every gated action handles 403/404; no role checks outside router/capabilities |
| Tenant | No `tenantId`/slug anywhere in requests (grep + service tests); caches per user; user switch leaves no residue |
| Entitlement | Every refusal code rendered; no plan-name comparisons; no local limit logic; enforcement on/off runs |
| Payment | Request bodies whitelisted; no amounts/secrets; launcher registry; flag default false; SDK absent unless C4 approved |
| API contract | Every DTO re-parsed against freshly captured fixtures from the current backend; unknown-enum fallbacks; no unused/extra request fields |
| Navigation | Redirect matrix, back behaviour, every web path mapping, not-found handling |
| Deep links | All supported URLs, malformed inputs, signed-out flow; `assetlinks.json` ready + human deployment step documented |
| Notifications | Polling cadence and pause in background; action mapping; preferences; push status (blocked or verified) |
| Security | Secret-pattern scan (source, assets, config, built APK strings via `strings`/`apkanalyzer`); cleartext disabled in release; `allowBackup=false`; exported components; R8 + obfuscation on; debug gallery absent from prod; dependency review (`flutter pub outdated`, licences) |
| Crash handling | Global hooks; error boundary; crash reporter wired (vendor per C7 or recorded blocked) with redaction |
| Performance | Cold start < 2.5 s on the emulator profile, no jank in lists (profile mode frame chart for home, lesson player, review queue), image cache bounds, no memory growth across 20 lesson navigations |
| Accessibility | TalkBack pass on signature screens, 200 % text scale on every screen (widget sweep), contrast, touch targets, reduced motion |
| Responsive / device | Phone small (360×640), phone large, tablet 10", landscape where §20 says; no overflow warnings |
| Production configuration | `config/prod.json` values, app name/icon/id (C6), version/build number, signing (C16), Play data-safety inputs listed (not submitted) |

**Release readiness checklist** — every item above true, or recorded as blocked on a named human decision/credential. Store upload, keystore creation and publishing are **human actions**: the module prepares artefacts and instructions, then stops (workflow §10.5).

**Acceptance criteria** — all verification green; every audit recorded with evidence; the only open items are listed human-owned decisions/credentials; progress.md `PROJECT STATUS` set to `COMPLETED` only if nothing but store submission remains, otherwise `RELEASE BLOCKED ON: …`.

**Testing requirements** — everything above; no test weakened; the full suite run twice.
