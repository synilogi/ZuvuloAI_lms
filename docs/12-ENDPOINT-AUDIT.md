# 12 — Endpoint and Billing Audit

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

`routes/routeAudit.test.ts` is the live audit: every route is proved to refuse an anonymous caller and a learner unless it is on its public or learner list, and the new routes are covered by it.

**Date:** 23 September 2026 (SAAS-024). **Scope:** every route the API mounts (237), the billing lifecycle, the
database. This is the record; `apps/api/src/routes/routeAudit.test.ts` is the part that keeps holding, because it
walks the routers on every test run and audits routes added later without anyone listing them.

## How each route was checked

| Check | How | Result |
| --- | --- | --- |
| Authentication | `routeAudit.test.ts`: every non-public route called anonymously | 220 routes answer 401; the 17 public routes are an explicit list (sign-in, sign-up, reset, logout, catalogue, Help Centre, certificate verification, health, webhooks) |
| Authorization | the same test, as a learner on every staff, academy-admin and platform route; as an instructor on every academy-admin and platform route; as an academy admin on every platform route | refused (401/403/404) before the body is read — no route reached |
| Validation | every body and query is parsed with Zod (`parseBody`/`parseQuery`); the settings body with the domain validator; the webhook body raw for its signature. A sweep calls every GET route with array- and object-shaped query parameters | no 5xx. **Fixed:** six list routes (`/help/articles`, `/assignments`, `/quizzes`, `/categories`, `/courses/:courseId/lessons`, `/instructors`) answered 500 — one of them public; their queries are now validated |
| Tenant scope | the tenancy extension scopes every query on an academy-owned model; `tenancy.test.ts`, `securityAudit.test.ts`, `mediaSecurity.test.ts` and the QA pass probe cross-academy ids on every resource | another academy's record is 404, as one that does not exist |
| Errors | `errorHandler` / `stableCodes`; `hardening.test.ts` sweeps malformed bodies; billing refusals carry documented codes (`billingApi.test.ts`) | no stack, SQL or provider text in a body |
| A covering test | each route below names a test file that calls it | **Fixed:** 15 routes had none (duplicate chapter/lesson/quiz/assignment, bookmark, notification restore/clear, the Help Centre, tax-rule retire, a tenant's billing profile) — `auditCoverage.test.ts` |

## Routes

Class: **public** (no session), **signed-in** (any role, own records), **staff** (instructor and admin, instructor
scope applies), **academy admin**, **platform** (Super Admin). *Anonymous* and *learner* are the statuses observed
when called without a session and as a learner (— = not applicable).

| Route | Class | Anonymous | Learner | Covered by |
| --- | --- | --- | --- | --- |
| `POST /webhooks/:provider/subscription` | public | — | — | firstPurchase.test.ts |
| `GET /health` | public | — | — | foundation.test.ts |
| `POST /auth/register` | public | — | — | app.test.ts |
| `POST /auth/login` | public | — | — | app.test.ts |
| `GET /auth/me` | signed-in | 401 | — | app.test.ts |
| `POST /auth/forgot-password` | public | — | — | auditObservability.test.ts |
| `GET /auth/reset-password/:token` | public | — | — | auth.test.ts |
| `POST /auth/reset-password` | public | — | — | auth.test.ts |
| `POST /auth/logout` | public | — | — | notificationDelivery.test.ts |
| `POST /auth/logout-all` | signed-in | 401 | — | notificationDelivery.test.ts |
| `GET /auth/sessions` | signed-in | 401 | — | sessions.test.ts |
| `DELETE /auth/sessions/:id` | signed-in | 401 | — | sessions.test.ts |
| `POST /auth/change-password` | signed-in | 401 | — | sessions.test.ts |
| `PATCH /auth/me` | signed-in | 401 | — | app.test.ts |
| `GET /catalog/levels` | public | — | — | permissions.test.ts |
| `GET /catalog/categories` | public | — | — | permissions.test.ts |
| `GET /catalog/instructors` | public | — | — | catalog.test.ts |
| `GET /catalog/courses` | public | — | — | app.test.ts |
| `GET /catalog/courses/:slug` | public | — | — | app.test.ts |
| `GET /courses` | staff | 401 | 403 | app.test.ts |
| `GET /courses/:id` | staff | 401 | 403 | app.test.ts |
| `GET /courses/:id/stats` | staff | 401 | 403 | permissions.test.ts |
| `POST /courses` | staff | 401 | 403 | app.test.ts |
| `PATCH /courses/:id` | staff | 401 | 403 | app.test.ts |
| `POST /courses/:id/publish` | staff | 401 | 403 | permissions.test.ts |
| `POST /courses/:id/unpublish` | staff | 401 | 403 | sharedPermissions.test.ts |
| `POST /courses/:id/archive` | staff | 401 | 403 | permissions.test.ts |
| `POST /courses/:id/restore` | staff | 401 | 403 | entitlements.test.ts |
| `POST /courses/:id/reorder-chapters` | staff | 401 | 403 | hardening.test.ts |
| `GET /categories` | staff | 401 | 403 | permissions.test.ts |
| `GET /categories/:id` | staff | 401 | 403 | permissions.test.ts |
| `POST /categories` | academy admin | 401 | 403 | permissions.test.ts |
| `PATCH /categories/:id` | academy admin | 401 | 403 | permissions.test.ts |
| `DELETE /categories/:id` | academy admin | 401 | 403 | permissions.test.ts |
| `GET /courses/:courseId/chapters/stats` | staff | 401 | 403 | permissions.test.ts |
| `POST /courses/:courseId/chapters` | staff | 401 | 403 | permissions.test.ts |
| `PATCH /courses/:courseId/chapters/:chapterId` | staff | 401 | 403 | catalog.test.ts |
| `POST /courses/:courseId/chapters/:chapterId/duplicate` | staff | 401 | 403 | auditCoverage.test.ts |
| `DELETE /courses/:courseId/chapters/:chapterId` | staff | 401 | 403 | sharedPermissions.test.ts |
| `POST /courses/:courseId/chapters/:chapterId/move` | staff | 401 | 403 | catalog.test.ts |
| `GET /courses/:courseId/lessons` | staff | 401 | 403 | permissions.test.ts |
| `GET /courses/:courseId/lessons/:lessonId` | staff | 401 | 403 | permissions.test.ts |
| `POST /courses/:courseId/lessons` | staff | 401 | 403 | permissions.test.ts |
| `PATCH /courses/:courseId/lessons/:lessonId` | staff | 401 | 403 | catalog.test.ts |
| `POST /courses/:courseId/lessons/:lessonId/move` | staff | 401 | 403 | catalog.test.ts |
| `POST /courses/:courseId/lessons/:lessonId/duplicate` | staff | 401 | 403 | auditCoverage.test.ts |
| `DELETE /courses/:courseId/lessons/:lessonId` | staff | 401 | 403 | catalog.test.ts |
| `GET /students` | staff | 401 | 403 | app.test.ts |
| `GET /students/:id` | staff | 401 | 403 | app.test.ts |
| `GET /students/:id/progress` | staff | 401 | 403 | permissions.test.ts |
| `GET /students/:id/activity` | staff | 401 | 403 | validation.test.ts |
| `POST /students/message` | staff | 401 | 403 | notifications.test.ts |
| `POST /students/:id/enroll` | staff | 401 | 403 | permissions.test.ts |
| `PATCH /students/enrollments/:enrollmentId` | staff | 401 | 403 | hardening.test.ts |
| `DELETE /students/enrollments/:enrollmentId` | staff | 401 | 403 | hardening.test.ts |
| `POST /students/:id/suspend` | academy admin | 401 | 403 | adminPermissions.test.ts |
| `GET /instructors` | staff | 401 | 403 | permissions.test.ts |
| `GET /instructors/:id` | staff | 401 | 403 | permissions.test.ts |
| `POST /instructors` | academy admin | 401 | 403 | permissions.test.ts |
| `PATCH /instructors/:id` | academy admin | 401 | 403 | permissions.test.ts |
| `POST /instructors/:id/status` | academy admin | 401 | 403 | adminPermissions.test.ts |
| `POST /instructors/:id/resend-invite` | academy admin | 401 | 403 | adminPermissions.test.ts |
| `GET /learning/home` | signed-in | 401 | — | app.test.ts |
| `GET /learning/courses` | signed-in | 401 | — | permissions.test.ts |
| `GET /learning/courses/:courseId` | signed-in | 401 | — | permissions.test.ts |
| `GET /learning/courses/:courseId/lessons/:lessonId` | signed-in | 401 | — | permissions.test.ts |
| `POST /learning/courses/:courseId/lessons/:lessonId/complete` | signed-in | 401 | — | permissions.test.ts |
| `PUT /learning/courses/:courseId/lessons/:lessonId/position` | signed-in | 401 | — | certificates.test.ts |
| `PUT /learning/courses/:courseId/lessons/:lessonId/note` | signed-in | 401 | — | permissions.test.ts |
| `POST /learning/courses/:courseId/lessons/:lessonId/bookmark` | signed-in | 401 | — | auditCoverage.test.ts |
| `POST /learning/courses/:courseId/save` | signed-in | 401 | — | suspension.test.ts |
| `POST /learning/courses/:courseId/enroll` | signed-in | 401 | — | permissions.test.ts |
| `GET /learning/assignments` | signed-in | 401 | — | permissions.test.ts |
| `GET /learning/assignments/:assignmentId` | signed-in | 401 | — | permissions.test.ts |
| `PUT /learning/assignments/:assignmentId/draft` | signed-in | 401 | — | assessmentIntegrity.test.ts |
| `POST /learning/assignments/:assignmentId/submit` | signed-in | 401 | — | permissions.test.ts |
| `GET /learning/assessments` | signed-in | 401 | — | assessmentIntegrity.test.ts |
| `POST /learning/courses/:courseId/lessons/:lessonId/quiz-attempt` | signed-in | 401 | — | permissions.test.ts |
| `GET /learning/courses/:courseId/lessons/:lessonId/quiz-attempts` | signed-in | 401 | — | assessmentIntegrity.test.ts |
| `GET /learning/certificates` | signed-in | 401 | — | permissions.test.ts |
| `GET /learning/certificates/:id` | signed-in | 401 | — | permissions.test.ts |
| `POST /learning/certificates/:id/claim` | signed-in | 401 | — | permissions.test.ts |
| `GET /learning/rank-ladder` | signed-in | 401 | — | suspension.test.ts |
| `GET /learning/activity` | signed-in | 401 | — | suspension.test.ts |
| `GET /quizzes` | staff | 401 | 403 | permissions.test.ts |
| `GET /quizzes/:id` | staff | 401 | 403 | permissions.test.ts |
| `GET /quizzes/:id/stats` | staff | 401 | 403 | quizzes.test.ts |
| `POST /quizzes` | staff | 401 | 403 | permissions.test.ts |
| `PATCH /quizzes/:id` | staff | 401 | 403 | permissions.test.ts |
| `POST /quizzes/:id/duplicate` | staff | 401 | 403 | auditCoverage.test.ts |
| `DELETE /quizzes/:id` | staff | 401 | 403 | permissions.test.ts |
| `GET /assignments` | staff | 401 | 403 | permissions.test.ts |
| `GET /assignments/review` | staff | 401 | 403 | sharedPermissions.test.ts |
| `GET /assignments/submissions` | staff | 401 | 403 | permissions.test.ts |
| `GET /assignments/:id` | staff | 401 | 403 | permissions.test.ts |
| `POST /assignments` | staff | 401 | 403 | permissions.test.ts |
| `PATCH /assignments/:id` | staff | 401 | 403 | permissions.test.ts |
| `POST /assignments/:id/duplicate` | staff | 401 | 403 | auditCoverage.test.ts |
| `DELETE /assignments/:id` | staff | 401 | 403 | permissions.test.ts |
| `GET /assignments/:id/submissions` | staff | 401 | 403 | permissions.test.ts |
| `GET /assignments/submissions/:submissionId` | staff | 401 | 403 | permissions.test.ts |
| `POST /assignments/submissions/:submissionId/review` | staff | 401 | 403 | assignments.test.ts |
| `POST /assignments/:id/remind` | staff | 401 | 403 | assignments.test.ts |
| `GET /certificates` | staff | 401 | 403 | permissions.test.ts |
| `GET /certificates/templates` | staff | 401 | 403 | adminPermissions.test.ts |
| `GET /certificates/templates/:id` | staff | 401 | 403 | adminPermissions.test.ts |
| `POST /certificates/templates` | academy admin | 401 | 403 | adminPermissions.test.ts |
| `POST /certificates/templates/:id/default` | academy admin | 401 | 403 | adminPermissions.test.ts |
| `GET /certificates/verify/:credentialId` | public | — | — | certificates.test.ts |
| `GET /certificates/:id` | staff | 401 | 403 | permissions.test.ts |
| `POST /certificates/:id/issue` | staff | 401 | 403 | permissions.test.ts |
| `POST /certificates/:id/revoke` | academy admin | 401 | 403 | adminPermissions.test.ts |
| `POST /certificates/:id/restore` | academy admin | 401 | 403 | adminPermissions.test.ts |
| `GET /live` | staff | 401 | 403 | permissions.test.ts |
| `GET /live/learner` | signed-in | 401 | — | suspension.test.ts |
| `GET /live/:id` | staff | 401 | 403 | permissions.test.ts |
| `POST /live` | staff | 401 | 403 | permissions.test.ts |
| `PATCH /live/:id` | staff | 401 | 403 | permissions.test.ts |
| `POST /live/:id/cancel` | staff | 401 | 403 | live.test.ts |
| `POST /live/:id/remind` | staff | 401 | 403 | live.test.ts |
| `PATCH /live/:id/reminders` | staff | 401 | 403 | sharedPermissions.test.ts |
| `POST /live/:id/register` | signed-in | 401 | — | permissions.test.ts |
| `GET /calendar` | staff | 401 | 403 | foundation.test.ts |
| `GET /calendar/:id` | staff | 401 | 403 | foundation.test.ts |
| `POST /calendar` | staff | 401 | 403 | foundation.test.ts |
| `PATCH /calendar/:id` | staff | 401 | 403 | foundation.test.ts |
| `DELETE /calendar/:id` | staff | 401 | 403 | foundation.test.ts |
| `POST /calendar/:id/done` | staff | 401 | 403 | foundation.test.ts |
| `GET /notifications` | signed-in | 401 | — | foundation.test.ts |
| `POST /notifications/devices` | signed-in | 401 | — | notificationDelivery.test.ts |
| `GET /notifications/devices` | signed-in | 401 | — | notificationDelivery.test.ts |
| `DELETE /notifications/devices/:deviceId` | signed-in | 401 | — | notificationDelivery.test.ts |
| `GET /notifications/:id` | signed-in | 401 | — | foundation.test.ts |
| `POST /notifications/read` | signed-in | 401 | — | suspension.test.ts |
| `POST /notifications/read-all` | signed-in | 401 | — | suspension.test.ts |
| `POST /notifications/remove` | signed-in | 401 | — | foundation.test.ts |
| `POST /notifications/restore` | signed-in | 401 | — | auditCoverage.test.ts |
| `POST /notifications/clear` | signed-in | 401 | — | auditCoverage.test.ts |
| `GET /notifications/settings/me` | signed-in | 401 | — | foundation.test.ts |
| `PUT /notifications/settings/me` | signed-in | 401 | — | foundation.test.ts |
| `GET /settings` | staff | 401 | 403 | foundation.test.ts |
| `PUT /settings/:section` | academy admin | 401 | 403 | foundation.test.ts |
| `GET /help/categories` | public | — | — | auditCoverage.test.ts |
| `GET /help/articles` | public | — | — | auditCoverage.test.ts |
| `GET /help/articles/:slug` | public | — | — | auditCoverage.test.ts |
| `GET /reports/overview` | staff | 401 | 403 | permissions.test.ts |
| `GET /reports/courses` | staff | 401 | 403 | permissions.test.ts |
| `GET /reports/courses/:courseId` | staff | 401 | 403 | permissions.test.ts |
| `GET /reports/learners` | staff | 401 | 403 | validation.test.ts |
| `GET /reports/instructors` | academy admin | 401 | 403 | permissions.test.ts |
| `GET /reports/enrolments` | staff | 401 | 403 | reports.test.ts |
| `GET /dashboard` | staff | 401 | 403 | permissions.test.ts |
| `POST /media/upload` | signed-in | 401 | — | usage.test.ts |
| `GET /media/:id` | signed-in | 401 | — | usage.test.ts |
| `GET /superadmin/plans` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/plans` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/plans/:id` | platform | 401 | 403 | billingApi.test.ts |
| `PATCH /superadmin/plans/:id` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/plans/:id/publish` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/plans/:id/archive` | platform | 401 | 403 | academies.test.ts |
| `POST /superadmin/plans/:id/restore` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/subscriptions` | platform | 401 | 403 | academies.test.ts |
| `POST /superadmin/subscriptions` | platform | 401 | 403 | academies.test.ts |
| `GET /superadmin/subscriptions/:id` | platform | 401 | 403 | academies.test.ts |
| `POST /superadmin/subscriptions/:id/cancel` | platform | 401 | 403 | academies.test.ts |
| `POST /superadmin/subscriptions/:id/plan-change` | platform | 401 | 403 | billingViews.test.ts |
| `POST /superadmin/subscriptions/:id/pause` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/subscriptions/:id/resume` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/subscriptions/:id/extend` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/invoices` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/invoices/:id` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/invoices/:id/void` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/invoices/:id/record-payment` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/payments` | platform | 401 | 403 | auditObservability.test.ts |
| `GET /superadmin/payments/:id` | platform | 401 | 403 | auditObservability.test.ts |
| `POST /superadmin/payments/:id/refund` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/webhooks` | platform | 401 | 403 | webhooks.test.ts |
| `GET /superadmin/payment-gateways` | platform | 401 | 403 | paymentGateways.test.ts |
| `POST /superadmin/payment-gateways/deactivate` | platform | 401 | 403 | usage.test.ts |
| `GET /superadmin/payment-gateways/:provider` | platform | 401 | 403 | paymentGateways.test.ts |
| `POST /superadmin/payment-gateways/:provider/config` | platform | 401 | 403 | paymentGateways.test.ts |
| `PATCH /superadmin/payment-gateways/:provider` | platform | 401 | 403 | paymentGateways.test.ts |
| `POST /superadmin/payment-gateways/:provider/test` | platform | 401 | 403 | paymentGateways.test.ts |
| `POST /superadmin/payment-gateways/:provider/activate` | platform | 401 | 403 | usage.test.ts |
| `GET /superadmin/tax-rules` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/tax-rules` | platform | 401 | 403 | billingApi.test.ts |
| `POST /superadmin/tax-rules/:id/retire` | platform | 401 | 403 | auditCoverage.test.ts |
| `GET /superadmin/tenants/:id/billing-profile` | platform | 401 | 403 | auditCoverage.test.ts |
| `PUT /superadmin/tenants/:id/billing-profile` | platform | 401 | 403 | auditCoverage.test.ts |
| `GET /superadmin/billing-views/overview` | platform | 401 | 403 | billingViews.test.ts |
| `GET /superadmin/billing-views/plans` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/billing-views/plans/:id` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/billing-views/subscribers` | platform | 401 | 403 | billingViews.test.ts |
| `GET /superadmin/billing-views/subscriptions/:id` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/billing-views/payments` | platform | 401 | 403 | auditObservability.test.ts |
| `GET /superadmin/billing-views/invoices/:id` | platform | 401 | 403 | billingApi.test.ts |
| `GET /superadmin/tenants` | platform | 401 | 403 | academies.test.ts |
| `POST /superadmin/tenants` | platform | 401 | 403 | academies.test.ts |
| `GET /superadmin/tenants/:id` | platform | 401 | 403 | academies.test.ts |
| `PATCH /superadmin/tenants/:id` | platform | 401 | 403 | academies.test.ts |
| `POST /superadmin/tenants/:id/suspend` | platform | 401 | 403 | academies.test.ts |
| `POST /superadmin/tenants/:id/reactivate` | platform | 401 | 403 | usage.test.ts |
| `POST /superadmin/tenants/:id/archive` | platform | 401 | 403 | academies.test.ts |
| `GET /superadmin/tenants/:id/users` | platform | 401 | 403 | academies.test.ts |
| `GET /superadmin/tenants/:id/subscription` | platform | 401 | 403 | academies.test.ts |
| `GET /superadmin/tenants/:id/usage` | platform | 401 | 403 | academies.test.ts |
| `GET /superadmin/overview` | platform | 401 | 403 | billingViews.test.ts |
| `GET /superadmin/admins` | platform | 401 | 403 | entitlements.test.ts |
| `POST /superadmin/admins` | platform | 401 | 403 | entitlements.test.ts, superadminAdmins.test.ts (academy required) |
| `PATCH /superadmin/admins/:id` | platform | 401 | 403 | entitlements.test.ts |
| `POST /superadmin/admins/:id/deactivate` | platform | 401 | 403 | usage.test.ts |
| `POST /superadmin/admins/:id/reactivate` | platform | 401 | 403 | usage.test.ts |
| `GET /superadmin/users` | platform | 401 | 403 | academies.test.ts |
| `GET /superadmin/admins/:id/permissions` | platform | 401 | 403 | superadminPermissions.test.ts |
| `POST /superadmin/admins/:id/permissions` | platform | 401 | 403 | sharedPermissions.test.ts |
| `DELETE /superadmin/admins/:id/permissions/:key` | platform | 401 | 403 | securityAudit.test.ts |
| `GET /superadmin/audit` | platform | 401 | 403 | auditObservability.test.ts |
| `GET /superadmin/observability` | platform | 401 | 403 | auditObservability.test.ts |
| `GET /superadmin/system` | platform | 401 | 403 | jobLease.test.ts |
| `GET /tenant/subscription` | academy admin | 401 | 403 | academies.test.ts |
| `GET /tenant/billing` | academy admin | 401 | 403 | academies.test.ts |
| `GET /tenant/billing/invoices/:id` | academy admin | 401 | 403 | billingApi.test.ts |
| `POST /tenant/billing/checkout` | academy admin | 401 | 403 | checkout.test.ts |
| `POST /tenant/billing/trial` | academy admin | 401 | 403 | onboarding.test.ts |
| `GET /academy/plan` | admin, instructor | 401 | 403 (student) | onboarding.test.ts |
| `POST /tenant/billing/purchase` | academy admin | 401 | 403 | firstPurchase.test.ts |
| `POST /tenant/billing/checkout/confirm` | academy admin | 401 | 403 | checkout.test.ts |
| `GET /tenant/subscription/usage` | academy admin | 401 | 403 | academies.test.ts |
| `GET /tenant/subscription/entitlements` | academy admin | 401 | 403 | billingApi.test.ts |
| `GET /tenant/plans` | academy admin | 401 | 403 | billingApi.test.ts |
| `POST /tenant/subscription/upgrade` | academy admin | 401 | 403 | billingApi.test.ts |
| `POST /tenant/subscription/preview` | academy admin | 401 | 403 | billingApi.test.ts |
| `POST /tenant/subscription/change` | academy admin | 401 | 403 | billingApi.test.ts |
| `POST /tenant/subscription/downgrade` | academy admin | 401 | 403 | billingApi.test.ts |
| `POST /tenant/subscription/plan-changes/:id/cancel` | academy admin | 401 | 403 | billingApi.test.ts |
| `POST /tenant/subscription/cancel` | academy admin | 401 | 403 | billingApi.test.ts |
| `POST /tenant/subscription/resume` | academy admin | 401 | 403 | billingApi.test.ts |
| `GET /tenant/invoices` | academy admin | 401 | 403 | billingApi.test.ts |
| `GET /tenant/invoices/:id` | academy admin | 401 | 403 | billingApi.test.ts |
| `GET /tenant/payments` | academy admin | 401 | 403 | billingApi.test.ts |
| `GET /tenant/billing-profile` | academy admin | 401 | 403 | billingApi.test.ts |
| `PUT /tenant/billing-profile` | academy admin | 401 | 403 | billingApi.test.ts |

## Billing lifecycle — test matrix

| Scenario | Test |
| --- | --- |
| First purchase | `firstPurchase.test.ts` › prices the chosen plan on the server, invoices it once, and opens a checkout for exactly that invoice |
| Success | `firstPurchase.test.ts` › starts the subscription only on the provider's verified payment; `webhooks.test.ts` › reads the payment back from the provider, records it, settles the invoice and applies the upgrade |
| Failure | `checkout.test.ts` › records a failed renewal, leaves the invoice open, moves the subscription past due — and recovers on the next payment; `auditObservability.test.ts` › a failed payment… |
| Duplicate webhook | `webhooks.test.ts` › answers a redelivery as a duplicate and repeats nothing; holds when the deliveries arrive at the same moment; agrees with the browser; `securityAudit.test.ts` › rejects a forged webhook, and changes state once for a duplicate |
| Wrong amount | `paymentGateways.test.ts` › rejects a wrong amount or a failed payment without applying it; `auditObservability.test.ts` › money that does not settle its invoice; `securityAudit.test.ts` › prices every charge on the server, whatever the client sends |
| Wrong currency | `auditObservability.test.ts` › a payment of the invoice's total in another currency, which settles nothing (added in SAAS-024); `checkout.test.ts` (a client-sent `currency: 'USD'` is ignored) |
| Renewal | `checkout.test.ts` › renews an active subscription for the next period when its renewal invoice is paid; `billingJobs.test.ts` › issues the next period's invoice ahead of the boundary, once; `invoicesPayments.test.ts` › never bills the same renewal period twice |
| Failed renewal | `webhooks.test.ts` › records a failed renewal and moves the subscription past due |
| Retry | `trialsGrace.test.ts` › past_due → retry succeeds → active; `billingJobs.test.ts` › finds a payment the academy made but nobody confirmed, records it, and recovers the subscription |
| Grace | `trialsGrace.test.ts` › reads the length from SUBSCRIPTION_GRACE_DAYS; `billingJobs.test.ts` › moves an unpaid subscription past due at the end of its period, keeping its access |
| Recovery | `checkout.test.ts` › …and recovers on the next payment; `trialsGrace.test.ts` › past_due → retry succeeds → active |
| Expiry | `billingJobs.test.ts` › ends a subscription whose grace ran out with nothing paid; expires a trial once its end has passed |
| Upgrade | `planChanges.test.ts` › charges only the difference for the rest of the period; does not activate the new plan until the payment is confirmed — and then keeps the renewal date |
| Downgrade | `billingJobs.test.ts` › applies a downgrade at the boundary first; invoices the next period at a scheduled downgrade's price; `billingApi.test.ts` › schedules a downgrade, cancels at period end and resumes |
| Pause | `planChanges.test.ts` › extends the period by the time actually paused; `billingJobs.test.ts` › resumes a pause on its planned date |
| Cancel | `billingJobs.test.ts` › ends a cancelling subscription when its paid period ends; `subscriptions.test.ts` › converts a trial, falls due, recovers, cancels at period end, resumes, pauses and cancels |
| Refund | `invoicesPayments.test.ts` › refunds part, then the rest, as separate events, never touching the payment; `securityAudit.test.ts` › lets only a super admin refund, with a reason |
| Gateway switch | `paymentGateways.test.ts` › switches to live for new payments only; moves only new invoices: invoice A stays on the old gateway, invoice B uses the new one |
| Stale renewal invoice | `billingJobs.test.ts` › a renewal invoice follows the subscription: voided by a cancellation or pause, refused at checkout once the subscription is over, reissued when it renews again |
| Past due with nothing to pay | `billingJobs.test.ts` › is issued to an academy that fell past due before it had a billing address, and paying it recovers the subscription |
| Late recovery, early trial payment | `subscriptions.test.ts` › starts a fresh period for a recovery paid after the whole next period was over; a conversion starts one when the trial ends |
| Offline payment | `billingApi.test.ts` › records a bank transfer against an open renewal, which renews the subscription, once per reference; refunds a payment received by hand at once |
| Complimentary days | `billingApi.test.ts` › gives complimentary days: the period ends later, an unpaid renewal for the old end is replaced |
| Concurrent refunds | `invoicesPayments.test.ts` › lets only one of two refunds requested at the same moment through |
| Billing notices | `billingApi.test.ts` › billing notices reach the academy's admins |
| Billing in the browser | `apps/web/e2e/billing.spec.ts` › start a subscription, pay its renewal by bank transfer, add complimentary days; the admin previews an upgrade, cancels and keeps the subscription |
| Historical payment after a switch | `paymentGateways.test.ts` › uses the original payment's gateway, never the active one; refuses, changing nothing, when the original gateway can no longer be used |

## Database

| Check | Result |
| --- | --- |
| Tenant indexes | every table with a `tenantId` column has an index on it (checked against `test.db`) |
| Delete behaviour | no cascade reaches into a financial table; `Tenant` is `ON DELETE RESTRICT` for every academy-owned table; triggers make plan versions, subscriptions' transitions, lifecycle events and plan changes immutable, and refuse deletes |
| Integrity | `PRAGMA integrity_check` and `foreign_key_check` clean; `npm run tenants:verify` clean on `dev.db` (read-only) and the QA database |
| Migrations | all additive (phase E: `academy_lifecycle`, `user_sessions`, `notification_delivery` — `ALTER TABLE ADD COLUMN`, no table rebuild — and `job_leases`); `prisma migrate diff` from the migrations to the schema: no difference |
| Races | two found and fixed in SAAS-020 (the usage guard's upsert inside a transaction; the lazy settings row). The single-statement upserts on learner progress, notes and bookmarks were probed with 12 simultaneous first writes, three times: no conflict |
