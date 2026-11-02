# ZuviloAI — Codebase guide

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

How the frontend and the API are organised, and the conventions every module follows.
The visual source of truth is `ZuviloAI App Shell.html`; the living reference is the `/design-system` route.

## Documentation system

`docs/` is the execution source of truth for backend and integration work and must never drift from the
code. Start at `docs/00-PROJECT-STATUS.md` (module status, roadmap, test status, change log), then the
numbered files `02`–`10` (module master list, database, auth, API, business rules, frontend integration,
testing, security, deployment). Every module has a detail file in `docs/modules/`. This file describes
code organisation and conventions only.

## Workspace layout

```
apps/
  web/                     React 18 + Vite + TypeScript frontend
  api/                     Express + Prisma (SQLite) + JWT auth — the real backend
packages/
  domain/                  LMS types and business rules shared by web and api
docs/                      this guide
```

## `apps/api` — the backend

A real, database-backed implementation of every service in `apps/web/src/services/contracts.ts`, reusing
`packages/domain` for validation and business rules exactly as this guide always intended.

- `prisma/schema.prisma` — the schema. Structural, queryable fields (ids, status, dates, foreign keys) are
  real columns; nested or type-varying shapes the domain package already types (lesson content, quiz
  questions, rubrics, settings sections, …) are stored as JSON text columns and parsed at the boundary —
  the same pattern the old mock services used in memory, now persisted.
- `prisma/seed.ts` — seeds a small, coherent academy (courses with real curriculum, instructors, students
  with enrollments and progress, a quiz attempt, a submission to review, issued certificates, live classes,
  help content), plus a year of history — 36 alumni whose enrolments, lesson progress, attempts, reviewed
  hand-ins and attended live classes are spread across the past twelve months, so reports have a previous
  period, monthly cohorts and a settled completion rate to show — and prints three ready-to-use accounts
  (admin / instructor / student).
- `src/routes/*` — one router per resource, mirroring the service groups in `contracts.ts`. Each reuses the
  matching domain validator (`publishChecklist`, `validateAssignment`, `validateQuiz`, `scoreAttempt`,
  `deriveStudentStatus`, `reviewScore`, `deriveLiveClassPhase`, `validateCalendarEvent`,
  `validateNotificationSettings`, `validateSettings`, `validateTemplate`, `validateInstructor`,
  `lessonPublishIssues`, …) rather than re-implementing the rule.
- `src/routes/billingPlatform.ts` — the Super Admin's billing endpoints, mounted inside `superadminRouter`;
  `src/routes/tenant.ts` — the academy admin's `/tenant` endpoints. Both are thin over the billing services and end
  with `stableCodes` (`lib/errors.ts`)
- `src/lib/tenancy.ts` — tenant isolation: which models belong to an academy, the context a piece of work
  runs in (`runInTenant` / `runAsPlatform`), and the Prisma extension that confines every query on an
  academy-owned model to it, stamps creates and checks foreign keys. `src/lib/db.ts` exports the extended
  `db`, plus `forTenant` / `asPlatform` bound clients for scripts and tests
- `src/lib/requestContext.ts` — the middleware that runs each request for the signed-in account's academy
  (or the one `DEFAULT_TENANT_SLUG` names), and the platform context for the Super Admin router
- `src/lib/scheduler.ts` — runs the every-minute jobs once per academy, inside its own context
- `src/lib/tenantAudit.ts` — the data checks behind `npm run tenants:verify`
- `src/lib/clock.ts` — the server's clock, the only one billing reads (`now()`; tests move it with `setClock`)
- `src/lib/billingConfig.ts` — billing terms from the environment: `graceDays()` (`SUBSCRIPTION_GRACE_DAYS`,
  no default) and `repeatTrialsAllowed()` (`SUBSCRIPTION_REPEAT_TRIALS`)
- `src/lib/subscriptions.ts` — subscriptions: the only writer of `Subscription` / `SubscriptionEvent`.
  `createSubscription` (platform or verified provider only; price from the plan version), and one function per
  named transition (`recordPaymentSucceeded`, `recordPaymentFailed`, `expireTrial`, `requestCancellation`,
  `cancelNow`, `resumeSubscription`, `pauseSubscription`, `endCancelledPeriod`, `startGracePeriod`, `expireGrace`), each writing
  its lifecycle event first. `subscriptionPlanFor` is the entitlement service's plan source
- `src/lib/invoices.ts` — `issueInvoice` (renewal, plan change or new subscription, from `lib/billing.ts`'s payable
  amount), `voidInvoice`, `getInvoice` and `listInvoices`. The only writer of `Invoice` and `InvoiceSequence`
- `src/lib/payments.ts` — `recordPayment` (provider only, idempotent, settles an invoice only for its exact total),
  `refundPayment` (super admin, with a reason) and `settleRefund`, `savePaymentMethod` (masked), and the lists. The
  only writer of `Payment`, `Refund` and `PaymentMethod`
- `src/lib/billing.ts` — billing profiles, tax rules (`setTaxRule` retires the rule it replaces; `taxRuleFor`
  looks up by region, then country), and what an academy pays: `payableForNewSubscription`, `payableForRenewal`
  and `payableForPlanChange`. None of them takes an amount
- `src/lib/planChanges.ts` — plan changes (D7–D10): `requestPlanChange` (quote or schedule),
  `confirmPlanChangePayment` (provider only; applies the upgrade), `applyDueScheduledChange` (scheduler, at the
  period boundary), `cancelPlanChange` and `listPlanChanges`. The only writer of `PlanChange`
- `src/lib/usage.ts` — `withinLimit(check, write)`: runs a limit-consuming write in one transaction that first
  takes the academy's `UsageGuard` row, then counts live and compares with the plan. Used by every route that adds
  to a limit, behind `ENTITLEMENT_ENFORCEMENT`
- `src/lib/entitlements.ts` — the entitlement service, the only reader of plan data for an academy:
  `getTenantEntitlements`, `hasFeature`, `getLimit`, `getUsage` (live counts per limit) and `canConsume`, plus
  the `requireFeature` route guard that runs after the permission guard (`ENTITLEMENT_ENFORCEMENT`). Which
  plan version an academy is on comes from `setTenantPlanSource`, which the subscription module installs
- `src/lib/plans.ts` — platform plans: the only writer of `Plan` / `PlanVersion`. Edits that change a price
  add a version instead of rewriting one; status moves only through publish / archive / restore; every write
  is refused outside the platform context and audited (`plan.*`). A version carries its allowance as
  `PlanFeature` / `PlanLimit` rows, sealed at the size it declared. `planForNewSubscription` refuses a draft
  or archived plan with `PLAN_UNAVAILABLE`; `resolvePlanVersion` reads any version for the records sold on it
- `src/lib/auth.ts` — bcrypt password hashing, JWT issuing/verification, `requireAuth` / `requireRole`
  middleware.
- `src/lib/errors.ts` — `ApiError` plus `notFound` / `conflict` / `badRequest`; the error middleware turns
  these into the HTTP status codes the frontend's `ServiceError` codes expect (404 → `not-found`,
  400/401/403/409 → `conflict`, else → `unknown`).
- `src/app.ts` exports the configured Express app (no listener) so `src/app.test.ts` can drive it directly
  with `supertest`; `src/index.ts` just calls `.listen()`.

Run it:

```bash
cd apps/api
cp .env.example .env
npm run prisma:push   # creates dev.db from the schema
npm run seed          # seeds the demo academy
npm run dev           # http://localhost:4000
```

The frontend talks to it when `apps/web/.env` sets `VITE_API_MODE=http` (see `apps/web/src/services/http/`
below) — otherwise it keeps using the in-memory mock services, unchanged.

### `apps/web/src/services/http/`

The HTTP implementation of `Services`, one file per service group, all built on a shared `client.ts` (bearer
token from `localStorage`, JSON in/out, HTTP status → `ServiceError` code). `services/index.ts` selects
`httpServices` instead of `mockServices` when `VITE_API_MODE=http`. `SessionProvider` runs a real,
token-backed session in that mode (login/register/logout call the API; `/auth/me` restores the session on
reload) instead of the mock's persona switcher — see `providers/SessionProvider.tsx` and
`lib/apiMode.ts`.

npm workspaces link `@syniastrolms/domain` into the web app. The domain package ships TypeScript source and has no build step.

| Command | What it does |
| --- | --- |
| `npm run dev` | Start the web app (Vite) |
| `npm run build` | Typecheck and production build of the web app |
| `npm run typecheck` | Typecheck every workspace |
| `npm test` | Vitest in every workspace |
| `npm run lint` | ESLint across the repo |
| `npm run format` | Prettier across the repo |

## `packages/domain` — the contract

Pure TypeScript: no React, no browser APIs. Anything the API will also need lives here.

- `catalog.ts` — Level → Category → Course → Chapter → Lesson, plus course status, visibility and the publish checklist. Taxonomy is data; nothing assumes a fixed number of levels or categories.
- `status.ts` — the 14 canonical LMS states (`LMS_STATUSES`).
- `progress.ts`, `live-class.ts`, `assignment.ts`, `assessment.ts`, `quiz.ts`, `certificate.ts`, `rank.ts`, `taxonomy.ts` — derivations and validation such as duration-weighted progress, live-class phase from the clock, quiz and assignment rules, certificate eligibility and the rank ladder. Each is unit-tested.
- `calendar.ts` — calendar events (timed, moment, all-day) and what an added event needs.
- `notification.ts` — notifications, categories, channels and preference rules (account notices stay on).
- `reports.ts` — report periods, chart buckets and learner segments.
- `settings.ts` — the LMS settings sections and their validation.
- `people.ts` — students, enrollments and the engagement rule (active, at risk, inactive).
- `analytics.ts` — KPI change rules (counts in percent, rates in points) and the dashboard snapshot shape.
- `help.ts` — help centre categories and articles (audience, tags, read time).
- `entitlement.ts` — the entitlement catalogue: the §4 features (`FEATURES`, `FeatureKey`) and limits (`LIMITS`, `LimitKey`, `PlanLimits` with `null` = unlimited, `limitOf` answering 0 for an unset limit), and `ENFORCEMENT_MATRIX` — the §42 permission × feature × limit table the entitlement service reads. The API mirrors the catalogue into `Feature` / `LimitDefinition`. An ESLint `no-restricted-syntax` rule refuses a comparison of a plan's name or code with a literal anywhere in the repo.
- `lifecycle.ts` — the subscription state machine: the seven server statuses, `TRANSITIONS` (from, to, who may cause it, the §19 event), `nextStatus`, `lifecycleEventFor`, `ALLOWED_STATUS_PAIRS` (what the database's triggers allow), `ENTITLED_STATES`, and `addBillingPeriod` (calendar months and years, clamped to the month's last day).
- `planChange.ts` — plan change and pause arithmetic in integer paise: `prorate` (BigInt, half up), `classifyPlanChange`, `quoteImmediateChange`, `pauseEnd` and `pauseExtensionMs`, with `MAX_PAUSE_DAYS` = 30.
- `tax.ts` — `calculateTax(amount, currency, components, inclusive)` in integers: rates in basis points, rounded half up per component, and an inclusive price split so that net + tax is exactly the price.
- `entitlement.ts` also holds `USAGE_STRATEGY` (how each limit is measured) and `RESTRICTED_MODE_POLICY` (what an academy served no plan may still do).
- `money.ts` — money as an integer count of the currency's minor unit (paise): `parseMajorAmount` (exact, from typed text), `formatMoney`, `majorToMinor`, `minorToMajor`, `isMinorAmount`, and currency digits from the runtime's ISO 4217 data.
- `subscription.ts` — the platform's subscription layer, every amount in minor units: plans (price, cycles, trial, limits, features) with `validatePlan` — whose `validatePlanTerms` half the API runs on every plan it saves — subscriptions and their states, invoices and their arithmetic, and the recurring-value rules (`isBilling`, `monthlyValue`, `planChangeEffect`). Configuration only — nothing here gates academy access.

## `apps/web/src`

```
app/            App providers and router
styles/         tokens.css · density.css · base.css · typography.css (global)
design/         tokens.ts — breakpoints, z-index, motion for code
components/
  ui/           Shell primitives: Button, Field, Badge, Menu, SegmentedControl, DataTable, Feedback…
  overlays/     Modal, Drawer, BottomSheet, AdaptivePanel, ConfirmDialog, ToastProvider
  forms/        FormSection, ChoiceCards, Switch, TagInput, ListInput, ErrorSummary
  lms/          Learning components: status, progress, journey, timeline, rank, course, coursework, quiz,
                schedule, certificate, notification, content (ArticleBody), activity, actions,
                shared (WorkRow, Rating)
  page/         PageHeader, SectionHeader, RouteTabs — page headings and sub-page tabs
  data/         KpiStrip, Delta, Figure — headline numbers and their change
  charts/       TrendChart, ColumnChart, Sparkline, BarList — one measure, one hue, keyboard read-out
shell/          AppShell, Sidebar, headers, bottom nav, role navigation, notification bell, help and profile
                dialogs, PageCrumbs
commands/       Command registry (role- and context-aware) and CommandPalette
providers/      Preferences (theme, sidebar, reduced motion), Session (mock role)
services/       contracts.ts (interfaces) · index.ts (selects implementation) · mock/ (fixtures, generators,
                simulation, analytics, mock services)
hooks/          useViewport, useAsync, useWorkspace, useFocusTrap, useDismiss, useScrollSpy, useNow…
lib/            cx, format (IST dates, durations, INR), print (send one open dialog to paper)
pages/          dashboard/ · courses/ · categories/ · quizzes/ · assignments/ · students/ · instructors/ · learn/
                (home, explore, my learning, course, lesson player, coursework) · certificates/ · live/ · calendar/ ·
                notifications/ · reports/ · settings/ · help/ (hub, category, article) · marketing/ (landing, login,
                register, privacy, terms) · superadmin/subscriptions/ (platform plans, subscribers, billing) ·
                design-system/ · NotFoundPage · SignedOutPage
```

## Conventions

**Tokens.** `styles/tokens.css` Part A is the shell's token layer, carried over unchanged. Part B is the LMS extension and only aliases or derives from Part A. Do not add hex values in components — use tokens.

**Styling.** CSS Modules per component. Inline `style` is only for data-driven values (a meter width, a ring size). Keyframes are global in `base.css`; reference them from modules as `animation: global(om-fade) …`, otherwise CSS Modules renames them and the animation silently does nothing.

**Density.** Wrap a region in `data-density="immersive" | "balanced" | "dense"`. Components read `--d-*` variables, so there is no per-screen fork of a component.

**Container queries.** Learning components respond to their container, not the viewport, so they adapt inside side panels, sheets and device frames. A component must never query itself: the outer element sets `container-type`, and an inner element carries the layout.

**Status.** Show state through `components/lms/status` (`StatusBadge`, `StatusLabel`, `StatusNode`). Each state has a label, icon, tone and node shape in `statusRegistry.tsx`. Never communicate a state with color alone.

**Icons.** Phosphor, duotone by default through `IconContext` in `App.tsx`. Icons are `aria-hidden` unless labelled.

**Responsive.** The shell switches composition at 768px. Below that, use `AdaptivePanel` instead of `Drawer`, `StickyActionBar` for a primary action that follows the reader, and `DataTable` column `mobile` hints for list recomposition. Touch targets are at least 44px.

**Data.** Screens call `services.*` (the interfaces in `services/contracts.ts`) and track the request with `useAsync(key, fn)`. Never import fixtures directly into product screens — only the design system does that.

**Routes.** Add product routes in `app/router.tsx` and their destinations in `shell/navigation.tsx`. Addresses the app doesn’t know fall through to `NotFoundPage`, which links back to the nearest section. Pages with no shell chrome — signed out, and the marketing/auth pages (`welcome`, `login`, `register`, `privacy`, `terms`) — are top-level siblings of the app-shell layout route rather than children of it; a static top-level segment never competes with the shell's nested catch-all.

**Workspaces.** Management screens are written once and mounted under `/admin` (the whole academy) and `/teach` (the signed-in instructor). Pages read `useWorkspace()` for the base path and the data scope — never hard-code `/admin` in a link.

**Mock data.** `services/mock/fixtures` holds hand-written catalog content and a seeded generator for the roster (`people.ts`): about 3,400 students whose enrollments add up exactly to each course's `enrolledCount`. `fixtures.test.ts` guards that integrity. Aggregates (`mock/analytics.ts`) are computed from the same records, so every screen agrees.

**Breadcrumbs.** The shell builds Home › section › navigation item on its own. Pages below an item (a course, its curriculum, an editor) add their trail with `usePageCrumbs([{ label, to }, { label }])`.

**Forms.** Group fields in `FormSection`s, validate on submit, then live. Show an `ErrorSummary` whose links focus each field (give controls stable ids — `Field` keeps a child's own id). Guard unsaved changes with `useBlocker` and a "Leave without saving?" dialog.

**Decisions.** Publishing, archiving and other consequential actions go through `ConfirmDialog`: consequences first, an acknowledgement for destructive actions, and the error kept in the dialog if the call fails.

**Previewing states.** Any page backed by mock services can be opened as `?scenario=empty`, `?scenario=error` or `?scenario=slow` to review its empty, error and loading states.

**Terminology.** Courses are divided into **chapters**, and chapters into lessons. Lesson types are video, article (`reading`), PDF (`document`), live session, practice, assignment and quiz (`assessment`).

## Backend status

Done — see `apps/api` above. `switchRole`, the "View as (demo)" menu and its command-palette entries are
mock-mode-only now (gated on `API_MODE` from `lib/apiMode.ts`); a real account's role comes from `/auth/me`.

**Known simplifications**, kept honest rather than faked: `LearnerService.listCertificates()` (the
eligibility-criteria view, distinct from the issued-certificate list) returns `[]` — no `CertificateRecord`
progress tracking is modelled; `StudentActivity` doesn't yet include `chapter-completed` or `rank-achieved` events; messaging,
uploads, live video and email/SMS delivery remain simulated (acknowledged, not sent), same as the mock always
was.
