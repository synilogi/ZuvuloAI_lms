# 07 — Frontend Integration

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

The UI is finished and approved. Backend integration changes frontend code only where the data flow
requires it. The single seam is `apps/web/src/services/`:

```
services/contracts.ts        the interfaces every screen calls (Services, 34 groups as of Oct 2026: the 22 LMS groups
                             plus signup, invitations, site, branding, support, sandbox, admin, platform, subscriptions,
                             tenantBilling, paymentGateways, courseSales, account)
services/index.ts            picks httpServices when VITE_API_MODE=http, else mockServices
services/http/client.ts      fetch wrapper: bearer token, JSON, status → ServiceError
services/http/<group>.ts     one file per service group, one method per route
services/mock/*              the original in-memory demo — untouched, still the default
providers/SessionProvider    real token session in http mode (login/register/logout, /auth/me)
lib/apiMode.ts               API_MODE constant, safe to import anywhere
```

Screens never import fixtures; they call `services.<group>.<method>()` and track the request with
`useAsync(key, fn)` which gives them loading / success / error states the UI already renders.

## Per-screen wiring status

✅ calls the real API and renders correctly · 🟨 wired but the API returns simplified data for part of the
screen (listed) · ⬜ still mock-only / not wired

| Area | Screens | Status | Notes |
| --- | --- | --- | --- |
| Marketing & auth | `/welcome`, `/login`, `/register`, `/reset-password/:token`, `/privacy`, `/terms`, `/signed-out` | ✅ | Login/register/forgot/reset real; `?next=` return after sign-in; `RequireSession` guard. |
| Company website | `/`, `/welcome`, `/features`, `/solutions`, `/how-it-works`, `/pricing`, `/about`, `/faq`, `/contact`, `/get-started` | ✅ | Sells the LMS to the organisation that will run it — see "The public website" below. Plans and prices from `GET /public/plans`. |
| Shared links / verify / support | `/courses/:slug`, `/courses/:id/enroll`, `/join/:slug`, `/invite/:token`, `/verify/:id`, `/support/*` | ✅ | Pages an LMS's own people arrive at by a link. `/courses` (the old public catalogue) only forwards. |
| Shell | sidebar, header, bell, account menu, command palette | ✅ | Bell keyed on the signed-in account (F0). "View as (demo)" is mock-only. `useWorkspace` uses the signed-in instructor id (F1). |
| Dashboard | `/admin`, `/teach` | 🟨 | KPIs/trends real; `events` are placeholders, `liveAttendance` 0, attention limited (F15). |
| Courses | list, editor, overview, curriculum, preview | ✅ | Settings-driven rules and validation (F5). |
| Categories | list + panels | ✅ | |
| Chapters / lessons | curriculum, chapter overview, lesson list, lesson editor | ✅ | Linked quiz/assignment mirrored; real uploads through `MediaDrop` (F5). |
| Quizzes | list, builder, settings, preview, results | ✅ | |
| Assignments | list, review queue, editor, preview, submissions, review | ✅ | |
| Students | list, profile tabs, dialogs | ✅ | Real figures; messages create notifications/emails (F3). |
| Instructors | list, editor, profile tabs | ✅ | Real figures; invitations email a set-password link (F4). |
| Learner home & my learning | `/home`, `/my-learning/*`, `/explore` | ✅ | |
| Course & lesson player | `/learn/:courseId`, `/learn/:courseId/lessons/:id` | ✅ | Locks, threshold, server-scored quizzes (answers + duration sent), drafts, live data, certificate record (F6–F9). |
| Coursework | `/assignments`, `/assignments/:id`, `/assessments` | ✅ | Drafts persisted, deadlines, late policy (F6/F8). |
| Learner certificates | `/certificates`, `/certificates/:id` | ✅ | |
| Admin certificates | list, detail, templates, editor | ✅ | |
| Live classes | staff list/editor/detail, learner list/detail | ✅ | |
| Calendar | month/week/list, panel, editor | ✅ | Relative assignment deadlines are per learner and do not appear as academy rows (by design). |
| Notifications | centre, detail, preferences (3 roles) | ✅ | SMS is a stored preference only (no transport). |
| Reports | overview, courses, course, learners, instructors, enrolments | 🟨 | Many figures 0/null/[] (F14). |
| Settings | six sections | ✅ | |
| Help centre | hub, category, article (3 roles + public) | ✅ | Article feedback is client-side only (by design). |
| Platform subscriptions | `/superadmin/subscriptions/*` (overview, plans, plan editor and detail, subscribers, subscriber detail, billing, invoice) | ✅ | SAAS-015. Reads `/superadmin/billing-views/*`, where every figure is computed on the server. Changes go through the billing endpoints. The demo note shows in mock mode only. |
| Academy billing | `/admin/billing` | ✅ | SAAS-015, §24. Shows plan, status, cycle, renewal, usage against limits, features, invoices, payments and the plans on sale. An upgrade gets a quote and a downgrade gets a date. Gated by `settings.view`; changes need `settings.edit`. **First purchase** (SAAS-009 extension): with no live subscription, each plan offers *Choose monthly / annual*, which opens the checkout for a first-purchase invoice. `lib/billingActions.ts` decides which actions appear and words the outcome. |
| Design system | `/design-system/*` (hidden) | 🟨 | Specimen pages use the legacy `learner`/`admin`/`enrollment` services, which return simplified data. Not a product screen. |

## The public website

ZuviloAI is software an organisation subscribes to for an LMS of its own. The public website sells that
subscription to the person who will be the LMS's Admin. **It lists no courses and sells none** — courses
live inside each customer's LMS, behind sign-in, scoped to that customer by the server.

**The look** (1 Nov 2026) is the ZuviloAi brand: ink, warm paper and the logo's one orange. The site's
colours are set as the ordinary tokens on the chrome (`Marketing.module.css` › `.chrome`, with a dark
set under `data-theme="dark"`), so buttons, links, chips, plan cards and forms take the brand without
knowing it: primary buttons are ink on paper and orange on ink, links and marks are the orange, every
card is paper with a hairline. Headings are the bold sans; one word of a heading may be set in the serif
italic (`<em>`), in orange. The home hero and the closing banners are ink, edge to edge, with the logo's
circuit strands drawn faintly behind the copy (`LandingPage.tsx` › `Circuit`).

**The home page** (`/`, `/welcome` — `pages/marketing/LandingPage.tsx`), in order: ink hero with the admin
dashboard and the student app · the module strip (what one LMS runs) · who it is for · benefits of a
workspace of your own, numbered · product tour (`#product`: Courses, People, Assessments, Reports, Plan &
billing) · what else is included · how each LMS is kept separate · how it works · plans from the server ·
FAQ · closing call to action. The header links Product (the tour), Features, How it works, Pricing, FAQ
and Contact, with Sign in and Get started.

- The product pictures (`ProductMock.tsx`) are the admin panel redrawn in markup with sample data. They
  are one image to assistive technology and make no claim; change them when the real screens change.
- "Start free trial" is said only when a plan on sale has a trial (`trialEnabled` and `trialDays` from
  `GET /public/plans`); otherwise the button reads "Get started".
- No customer counts, logos, ratings or testimonials: there are none to show yet.

**Course addresses, and why each is as it is**

| Address | Now | Why |
| --- | --- | --- |
| `/courses` | Forwards: a signed-in learner to `/explore`, staff to their workspace, a visitor to `/welcome` | It was a public catalogue — a course marketplace the business does not run. Old links still land somewhere sensible. |
| `/courses/:slug` | Kept, in a slim frame (brand, Sign in, legal links) with no catalogue links | It is what an Admin's "Copy course link" produces and what the mobile app deep-links, so it is an LMS's own page, reached only by its link. Nothing on the website links to it. |
| `/courses/:id/enroll` | Unchanged | A course's enrolment link: joins the course's LMS and enrols (SAAS-028). |
| `/join`, `/join/:slug`, `/invite/:token` | Unchanged | How an LMS's learners join it. |
| `/explore`, `/learn/*`, `/admin/courses/*`, `/teach/courses/*` | Unchanged | The catalogue and course management inside each LMS, behind sign-in. |

The API is unchanged: `GET /catalog/*` still answers without a session for the LMS the host serves
(`DEFAULT_TENANT_SLUG`), because `/courses/:slug` and the mobile app read it. Closing it to signed-in
callers is a backend decision, not part of the website.

## Integration rules followed

- Loading / error / empty states: every screen already has them via `useAsync`; the http client throws
  `ServiceError` with the same `code` values the mock used, so no screen changes were needed for errors.
- Ids: in http mode ids are database cuids, not the mock's slug-like ids; screens always use ids from
  responses, never hard-coded ones.
- `user.id` is the **User** id. Notification, calendar and settings routes must key on it (F0).
- The quiz taker computes a result locally for immediate feedback; in http mode the answers are also sent
  so the server scores authoritatively (F6). The UI shows the server's result.
- Uploads: `MediaDrop` calls `services.media.upload(file, onProgress)` — real multipart upload in http
  mode, simulated progress in mock mode (F5). Screens keep the same `MediaFile` shape (`url` added).
- Removing mock data: product screens contain none. The remaining mock-data imports are
  `SessionProvider` (mock mode personas), `useWorkspace` (mock instructor id in mock mode only), the command
  registry's course search (F5 switches it to the catalog service in http mode) and the design-system pages.
- Subscription refusals (§34, SAAS-015). A refusal carrying one of the nine codes becomes a state, not a raw
  message. `lib/billingStates.ts` names each state's title, meaning and where an admin resolves it. The client:
  - puts the code on `ServiceError.reason` and shows the error in the state's words, so a toast, a dialog and a
    page all say the same;
  - maps a 402 to `forbidden`;
  - fires `syniastrolms:billing-refusal`.

  The shell then shows an academy-wide state (no plan, overdue, expired) once, above the page, with a link to
  Billing for an admin.
- Session loss: any 401 with a stored token clears it and fires `syniastrolms:unauthorized`; the provider
  drops to signed-out and `RequireSession` redirects to `/login?next=<current path>`.
