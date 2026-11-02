# QA Progress — live testing & bug fixing

**Run:** 23 September 2026 · branch `sunil_workspace` · QA lead: Claude (autonomous QA pass)

## Environment

- [x] Backend running — `apps/api` via `tsx src/index.ts` on **:4300** (an unrelated API instance was already on :4100 and was left alone)
- [x] Database connected — disposable **`apps/api/prisma/qa.db`** (git-ignored); `dev.db` was only read, never written
- [x] Admin Panel running — `apps/web` (Vite, `VITE_API_MODE=http`) on **:5180**
- [x] Browser automation available — Playwright + Chromium 1243 (repo `node_modules`)

Node v24.5.0 · npm workspaces · Express 4 + Prisma 6 (SQLite) + JWT HS256 · React 18 + Vite 7 · Vitest + supertest.

QA data: seeded academy `tenant-1` = **TEST_TENANT_A**; fixture academy `tenant-qa-b` = **TEST_TENANT_B**
(tenant row, one level and `student-b@test.local` inserted directly, because no API provisions an
academy). Super Admin `superadmin@test.local` (via `npm run superadmin:create`); Tenant B admin created
through `POST /superadmin/admins`, and its category, course, chapter and instructor through the API.

## Authentication

- [x] Super Admin login
- [x] Admin login (Tenant A and Tenant B)
- [x] Invalid login (wrong password and unknown email give the same 401 message; missing fields 400)
- [x] Protected route (no token, malformed, non-Bearer, expired, wrong secret, `alg=none`, escalated role claim, forged tenant claim, deleted user: all 401)
- [x] Logout (client-side token removal; `/superadmin` then redirects to `/login`)
- [x] Register (role and tenantId in the body are ignored), duplicate 409, weak password 400
- [x] Forgot/reset password (same answer for known and unknown email; invalid token refused)

## Super Admin

- [x] Dashboard (overview, system, observability, audit, billing views)
- [x] Tenant management — **read-only by design**: `GET /superadmin/tenants` lists academies. No API or UI exists to create, update, activate or deactivate a tenant (see Gaps)
- [x] Admin CRUD (create in a chosen tenant, rename, deactivate, reactivate, permissions grant/revoke) + negative cases
- [x] Authorization (anon 401; admin, instructor and student 403 on all 11 SA endpoints; SA refused on academy routes)

## Tenant

- [x] Tenant A isolation
- [x] Tenant B isolation
- [x] Cross-tenant attack tests — 50+ IDOR probes (GET/PATCH/DELETE/POST on courses, chapters, lessons, categories, instructors, students, enrolments, quizzes, assignments, submissions, certificates, templates, live, media, invoices, reports), lists, search, filters, pagination, forged `x-tenant-id`/`?tenantId`/body `tenantId`, learner catalogue/slug/enrol
- [x] Admin permissions (revoked key → 403 `PERMISSION_DENIED`, restored → 200)

## Admin Panel

- [x] Login (incl. `?next=` return, client validation, server error)
- [x] Dashboard
- [x] CRUD modules — category create / duplicate / empty-validation / edit / hard delete with DB checks; Super Admin admin create / duplicate / deactivate / reactivate; settings persist across reload
- [x] Validation
- [x] Error handling (cross-tenant URL shows "Course not found"; dirty-form guard)
- [x] Browser console — 0 errors across 70 pages × 5 roles (after BUG-003 fix)
- [x] Network errors — no 5xx and no unexpected 4xx

## Regression

- [x] Unit tests (domain 119, web 258)
- [x] Integration tests (API 608)
- [x] E2E tests — live Playwright workflows 31/31 and crawl of 70 routes (no committed E2E suite exists in `apps/web`; `apps/lms-react/e2e` belongs to an untracked WIP app)
- [x] Full test suite — `npm test` green; `typecheck`, `lint` and `build` green; `format:check` fails only on 9 files in untracked `apps/lms-react/` (pre-existing, not touched)

## Results

| Suite | Checks | Pass | Fail |
| --- | --- | --- | --- |
| Live API harness (health, auth, SA, CRUD, isolation, sessions) | 199 | 199 | 0 |
| Live browser workflows | 31 | 31 | 0 |
| Browser crawl (routes × roles) | 70 pages | 70 | 0 |
| Repo test suite | 985 | 985 | 0 |
| DB checks (integrity, FK, tenancy, migrations; dev.db read-only and qa.db) | 8 | 8 | 0 |

---

## BUG-001

**Title:** Deactivated admin, inactive instructor or suspended learner keeps a working session on its existing token
**Severity:** P1 (authorization bypass after account closure; learner PII readable by a removed instructor)
**Module:** Auth / request context
**Environment:** local QA API :4300, qa.db
**Steps to reproduce:** sign in as an instructor → admin sets the instructor to `inactive` → with the same token call `GET /auth/me`, `GET /students`, `GET /courses`, `POST /courses`. Or: SA deactivates an admin → the admin's token calls `GET /certificates`, `/live`, `/notifications`, `/settings`, `POST /media/upload`. Or: suspend a learner → `GET /notifications`, `POST /media/upload`.
**Expected:** every authenticated route refuses the closed account (sign-in already does).
**Actual:** 200 on all of them. Only `requirePermission` (admins) and `requireStudent` (learning routes) checked account state; an inactive instructor passed everything, `/auth/me` included (evidence captured before the fix).
**Root cause:** `lib/requestContext.ts` re-reads the account on every request but checked only role, tenant and existence. `requireAuth`, `requireRole` and `requireSuperAdmin` never looked at `deactivatedAt`, `Instructor.status` or `Student.suspended`, and `requireStaffPermission` passes instructors on role alone.
**Files changed:** `apps/api/src/lib/requestContext.ts`, `apps/api/src/lib/auth.ts`, `apps/api/src/lib/permissions.ts`
**Fix:** the context read also selects the three account states and sets `req.accountClosed` (same messages sign-in uses). `requireAuth`, `requireRole`, `requireSuperAdmin` and `requirePermission` refuse with 403 when it is set. No extra query.
**Test used to verify:** new tests in `routes/instructors.test.ts` ("closes the session a deactivated instructor already holds"), `routes/hardening.test.ts` (role-only routes and upload), `routes/suspension.test.ts` (outside the learning workspace). All three fail on the old code and pass on the new. Live harness sections "Deactivated admin session", "Inactive instructor session" and "Suspended learner session"; browser: the deactivated admin's open tab drops to sign-in.
**Regression tests:** full `npm test` (985/985)
**Status:** Fixed & verified

## BUG-002

**Title:** Nested course routes answer 200 (empty) for another academy's or a non-existent course id when called by an admin
**Severity:** P3 (no data leaked, since every query is tenant-scoped, but it breaks the documented "out-of-scope ids answer 404" rule)
**Module:** Courses / chapters / lessons scope
**Steps to reproduce:** as the Tenant B admin, `GET /courses/<tenantA-course>/lessons` or `/chapters/stats`
**Expected:** 404 · **Actual:** 200 `{rows:[]}` / `{enrolled:0,…}`
**Root cause:** `assertCourseAccess` returns true for any id when the caller is an admin (no instructor scope) and never checked that the course exists in the academy.
**Files changed:** `apps/api/src/lib/scope.ts`
**Fix:** for admins, also confirm the course exists (tenant-scoped `findUnique`), so the answer is 404 exactly as for instructors.
**Test used to verify:** new test in `routes/tenancy.test.ts` (fails before, passes after); live harness isolation section.
**Regression tests:** full `npm test`
**Status:** Fixed & verified

## BUG-003

**Title:** Login shows a stale server error next to the email validation error (React duplicate-key warning)
**Severity:** P3
**Module:** Web / LoginPage
**Steps to reproduce:** submit wrong credentials → change the email to an invalid value → submit
**Expected:** only "Enter a valid email address." · **Actual:** the stale "Incorrect email or password" is shown as well, and React logs "two children with the same key `login-email`".
**Root cause:** the server error stayed in `allIssues` under the same field id once client validation failed again.
**Files changed:** `apps/web/src/pages/marketing/LoginPage.tsx`
**Fix:** include the server error only while the fields pass client validation.
**Test used to verify:** browser workflow "no page errors (anon/admin flow)" — fails before, passes after.
**Status:** Fixed & verified

## BUG-004

**Title:** A transient API failure at page load signs the user out (valid token deleted)
**Severity:** P2
**Module:** Web / SessionProvider
**Steps to reproduce:** signed in → reload while the API is unreachable, returns 5xx or 429, or while a navigation aborts the in-flight `/auth/me` (e.g. PM2 reload during `deploy.sh`)
**Expected:** keep the token; only the API refusing the session ends it · **Actual:** token removed, redirected to `/login`, must sign in again.
**Root cause:** `HttpSessionProvider` called `httpAuth.logout()` on any `/auth/me` rejection.
**Files changed:** `apps/web/src/services/http/auth.ts` (`sessionRefused`), `apps/web/src/providers/SessionProvider.tsx`, new `apps/web/src/services/http/auth.test.ts`
**Fix:** sign out only when the failure is a refusal. `network` and `unknown` (5xx/429) errors keep the token. A 401 is still cleared by the HTTP client, and a 403 (deactivated/suspended) still signs out.
**Test used to verify:** Playwright with `/auth/me` aborted and with 503 (token lost before, kept after); unit test `auth.test.ts`.
**Status:** Fixed & verified

---

## Gaps (not bugs — features that do not exist; nothing was invented)

- **No tenant lifecycle:** no API or UI creates, updates, suspends or archives an academy. `Tenant.status` (`active|suspended|archived`) exists in the schema but nothing sets or enforces it. A new academy also has no Levels, and no API can create one, so it could not create courses without provisioning.
- **Super Admin "Add admin" dialog has no academy picker:** the API accepts `tenantId`, but the UI always creates the admin in the default academy.
- **No refresh tokens or server-side token revocation** (documented design; closed accounts are now refused per request — BUG-001).
- JWT is kept in `localStorage` (documented design, so an XSS would expose it; CSP is set by helmet).
