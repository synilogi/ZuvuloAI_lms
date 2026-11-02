# 06 — Business Rules

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

**Current rules added by the conversion:**

- **Coupons.** Arithmetic in integer paise. A coupon never takes a charge below ₹1. Each learner can use a coupon once, and a use counts when the order is paid.
- **Refunds.** Whole orders only, because the plan names no CV rule for a part refund. A refund expires the enrolment and reverses the sale's CV. A part refund made in the gateway's dashboard flags the order and changes nothing else.
- **Matching (docs/15 §6.5).** Once per member and IST day, on the weaker leg at the plan's rate, up to the rank's daily cap. Volume above the cap is flushed or carried by plan policy, and the stronger leg's excess always carries forward. A suspended member is not paid, and their volume stays.
- **Ranks (§6.6).** Half the group CV on each leg, with no credit across legs. Ranks are never lost. Each rank reached creates one reward.
- **Rewards.** Qualified, approved, vesting, funded, paid: each is a person's decision, in that order. A cash reward's payment goes under the ceiling.
- **Ceiling (§6.7).** Field payout for an IST month cannot pass the plan's share of that month's eligible sales. The excess is held, never dropped, and is released oldest first when later sales make room, or by the Super Admin with a reason.
- **Reversals (§6.8).** Volume still unmatched comes out of the pool. Volume already matched claws back its income from the wallet, which may go negative, up to what the member actually received. Unpaid rewards the volume no longer supports are rejected, and paid ones are flagged.
- **Withdrawals (§6.9).** Active member, verified KYC, at least the plan's minimum, within the available balance, one open at a time. The amount is held in the same transaction. Payment is by hand with a bank reference; there is no payout API.

Rules live in `packages/domain` (pure functions, unit-tested) and are applied by the API. Each rule lists
where it is implemented and whether the API enforces it today.

Status: ✅ enforced by the API · 🟨 partially · ⬜ not yet enforced (planned phase in brackets)

## Courses & curriculum

| Rule                                                                                                                                                                                      | Where                                                    | Status |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ------ |
| A course can be published only when `publishChecklist` is fully met (title+subtitle, description ≥ 40 chars, ≥ 1 instructor, ≥ 3 outcomes, a published chapter with lessons, ≥ 5 lessons) | `catalog.publishChecklist` · `POST /courses/:id/publish` | ✅     |
| Slugs are generated from the title and unique                                                                                                                                             | `catalog.slugify` · courses route                        | ✅     |
| Archived → restore returns to draft; unpublish returns to draft                                                                                                                           | courses route                                            | ✅     |
| Course titles must be unique                                                                                                                                                              | courses route                                            | ✅     |
| A course has at most `settings.courses.maxInstructors` instructors                                                                                                                        | courses route                                            | ✅     |
| When `settings.courses.requireReview` is on, instructors cannot publish — admins are asked to review                                                                                      | courses route                                            | ✅     |
| A lesson can be published only when `lessonPublishIssues` is empty (video file, article ≥ 80 chars, PDF file, assignment brief ≥ 20 chars, live session scheduled, duration ≥ 1)          | `catalog.lessonPublishIssues` · lessons route            | ✅     |
| A quiz/assignment delivered by a lesson cannot be deleted; delete the lesson or change its type first                                                                                     | quizzes/assignments routes                               | ✅     |
| A lesson's `content.quiz` / `content.assignment` mirrors the linked quiz/assignment (question count, pass mark, attempts, brief, max score)                                               | `lib/lessonLinks.ts`                                     | ✅     |
| Chapter positions stay contiguous after insert/move/delete/duplicate                                                                                                                      | chapters route                                           | ✅     |

## Enrollments

| Rule                                                                                                                                            | Where                        | Status |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------- | ------ |
| One enrollment per (student, course); `enrolledCount` tracks enrollments                                                                        | DB unique + routes           | ✅     |
| Self-enrolment respects `settings.general.enrollment` (`open` / `approval` / `invite` — the latter two refuse with an explanation; staff enrol) | `learning` enroll            | ✅     |
| Access ends after `settings.general.accessMonths` (`expiresAt`, status `expired` on read)                                                       | `lib/learning.ts`            | ✅     |
| Learner status: `suspended` overrides; ≥ 45 quiet days → `inactive`; ≥ `settings.learning.atRiskDays` quiet days with open work → `at-risk`     | `people.deriveStudentStatus` | ✅     |
| Removing an enrollment removes progress and drops `enrolledCount`                                                                               | routes                       | ✅     |

## Learning progress

| Rule                                                                                                                                                                                                                                   | Where                                | Status |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ------ |
| Course progress is duration-weighted across published lessons (`courseProgress`)                                                                                                                                                       | `progress.ts`                        | ✅     |
| Chapters open in order: a chapter unlocks when the previous chapter's published, non-assignment lessons are done; a chapter's quiz unlocks when its other lessons are done (`settings.learning.chapterGate`)                           | `lib/learning.ts` `applyLocks`       | ✅     |
| A video counts as done at `settings.learning.completionThreshold` % (auto from `PUT position`; `complete` needs threshold − 10 %)                                                                                                      | `learning` position/complete         | ✅     |
| Completion rule per lesson type: video → watched, reading/document/live → opened, practice/assignment → submitted (practice: notes ≥ 20 chars or a hand-in), assessment → passed (`defaultCompletion`, overridable in lesson settings) | `learning` complete                  | ✅     |
| A course completes per `settings.learning.courseCompletion` (`all-lessons` / `lessons-and-assessments` / `percentage` of lessons)                                                                                                      | `lib/learning.ts` `isCourseComplete` | ✅     |
| `lastLessonId` / `lastActiveAt` / `LessonProgress.lastAccessedAt` update on every open lesson visit                                                                                                                                    | learning route                       | ✅     |
| Quiz attempts are scored server-side with `scoreAttempt` (partial credit on multiple choice, normalised short answers); passing completes an assessment lesson; the best score is kept                                                 | `learning` quiz-attempt              | ✅     |
| Until passed, attempts are limited to the quiz's `settings.attempts` (0 = unlimited; `settings.learning.quizAttempts` when unset) with `settings.learning.retakeWaitHours` between attempts; after a pass retakes are practice         | `learning` quiz-attempt              | ✅     |

## Assignments & reviews

| Rule                                                                                                                                                                                                                  | Where                                | Status |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | ------ |
| Publishing needs `validateAssignment` (title, course, instructions ≥ 40 chars, rubric criteria named with points or maxScore > 0, pass mark within max, future fixed due date, relative due ≥ 1 day, word limit ≥ 50) | `assignment.validateAssignment`      | ✅     |
| Late = submitted after the due date; relative deadlines count from when the chapter opened for the learner (first activity in it, else enrolment)                                                                     | `learning` `dueAtFor`                | ✅     |
| Late policy: `settings.learning.latePolicy` — `reject` refuses late hand-ins, `penalty` deducts the assignment's `latePenalty` % (default from settings) at grading, `accept` deducts nothing                         | learning submit · assignments review | ✅     |
| Grading needs `validateReview` (every rubric criterion scored within its points, or points within max; feedback ≥ 3 words; returning needs ≥ 8 words)                                                                 | `assignment.validateReview`          | ✅     |
| Final score = raw − late penalty (`reviewScore`), never below 0                                                                                                                                                       | `assignment.reviewScore`             | ✅     |
| A review is overdue after 48 hours (`REVIEW_WINDOW_HOURS`)                                                                                                                                                            | `assignment.reviewOverdue`           | ✅     |
| Returned submissions can be resubmitted (attempt + 1)                                                                                                                                                                 | route                                | ✅     |
| `submitted` completes on hand-in; graded ≥ pass mark completes an assignment lesson whose completion rule is `passed`                                                                                                 | learning submit · assignments review | ✅     |

## Certificates

| Rule                                                                                                                                                                                                           | Where                                  | Status |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ------ |
| Completing a course creates a `pending` certificate when `settings.certificates.enabled` and the final score ≥ `minScore`; `autoIssue` issues it immediately; the learner is notified                          | `lib/certificates.ts`                  | ✅     |
| Credential ids are `<prefix>-<course code>-<year>-<5 digits>`, prefix from `settings.certificates.credentialPrefix`                                                                                            | `lib/certificates.ts`                  | ✅     |
| Hours = published lesson minutes / 60; final score = mean of best quiz percentages and graded assignment percentages                                                                                           | `lib/certificates.ts`                  | ✅     |
| Template = the course's template, else `settings.certificates.defaultTemplateId`, else the default template                                                                                                    | `lib/certificates.ts`                  | ✅     |
| Revoking needs a reason and notifies the learner; revoked certificates verify as revoked; pending ones never verify; public verification counts checks and respects `settings.certificates.publicVerification` | certificates routes                    | ✅     |
| "Working towards" shows the learner's criteria (progress %, assignments passed, final score) for active enrollments                                                                                            | `lib/certificates.ts` `workingTowards` | ✅     |

## Live classes & calendar

| Rule                                                                                                                                                                                                                       | Where                                     | Status |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- | ------ |
| Scheduling needs `validateLiveClass` (title, course, instructor, future start, 15–240 min, capacity ≥ registrations, https link for outside meetings, agenda ≤ duration)                                                   | `live-class.validateLiveClass`            | ✅     |
| Phase from the clock (`deriveLiveClassPhase`): upcoming → starting-soon (15 min) → live → ended/recording-expired; cancelled                                                                                               | `live-class.ts`                           | ✅     |
| Started or cancelled classes cannot be edited; ended or cancelled ones cannot be cancelled or registered for                                                                                                               | live routes                               | ✅     |
| Registration needs an enrolment in the course; refused when full; toggling unregisters                                                                                                                                     | route                                     | ✅     |
| Scheduling notifies enrolled learners; cancelling notifies registered learners; reminders (manual, or scheduled per `reminders` offsets) reach registered learners once                                                    | `lib/liveEvents.ts`                       | ✅     |
| Calendar events added in the app need `validateCalendarEvent` (no live/assignment types, title, course for quiz/milestone/learner reminders, quiz id, milestone kind, chapter for chapter-release, future date, 5–720 min) | `calendar.validateCalendarEvent`          | ✅     |
| Live classes and fixed assignment deadlines appear as derived, read-only calendar rows                                                                                                                                     | route                                     | ✅     |
| Only the owner (or an admin) can edit/delete/complete an event; `notifyMin` reminders reach the owner and, for `learners` audience, the course's learners once                                                             | calendar routes · `lib/calendarEvents.ts` | ✅     |

## Notifications

| Rule                                                                                                                                                                                                                                                                                                                                | Where                                       | Status |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ------ |
| Account/security (`system`) notices stay on in the app and by email (`LOCKED_CHANNELS`)                                                                                                                                                                                                                                             | `notification.validateNotificationSettings` | ✅     |
| Quiet hours need different start/end                                                                                                                                                                                                                                                                                                | same                                        | ✅     |
| Events generate notifications (see `modules/notifications.md` for the catalogue and scheduled jobs); each respects the recipient's per-category `app`/`email` channel, `pausedUntil` (important still arrives), their email digest, and the academy's `settings.notifications` switches; emails go to the outbox (no SMS transport) | `lib/notify.ts`, `lib/notificationJobs.ts`  | ✅     |

## Reports & dashboard

| Rule                                                                                                                                       | Where                   | Status                                      |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------- | ------------------------------------------- |
| Every report compares a period with the equal period before (`reportWindow`, `reportBuckets`)                                              | `reports.ts`            | 🟨 (previous-period figures partly 0) (F14) |
| KPI change: counts in %, rates in points (`kpiChange`)                                                                                     | `analytics.kpiChange`   | ✅ (client)                                 |
| Completion rate = completed / non-paused enrollments (`completionRate`)                                                                    | `people.completionRate` | ✅                                          |
| Attention items: overdue reviews (high), at-risk learners, nearly full classes (≥ 90 %), stale drafts (> 6 weeks), videos without captions | dashboard               | 🟨 (F15)                                    |

## Settings

| Rule                                                                                                                      | Where                       | Status |
| ------------------------------------------------------------------------------------------------------------------------- | --------------------------- | ------ |
| Each section is validated by `validateSettings` before saving                                                             | `settings.validateSettings` | ✅     |
| `updatedBy` records who saved (by name)                                                                                   | route                       | ✅     |
| Saved settings change behaviour across the modules listed above — see the field → consumer table in `modules/settings.md` | —                           | ✅     |

## Plans and entitlements (SaaS)

| Rule                                                                                                                                         | Where                                                     | Status          |
| -------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | --------------- |
| Every platform-billing amount is an integer in the currency's minor unit (paise); no float reaches a stored figure                           | `money.ts`, database CHECKs                               | ✅ SAAS-001     |
| A plan's code is unique, stored in capitals, and fixed once the plan leaves draft                                                            | `subscription.validatePlanTerms`, `lib/plans.ts`, trigger | ✅ SAAS-001     |
| A price, cycle, trial, feature or limit change adds a plan version; earlier versions never change                                            | `lib/plans.ts`, triggers                                  | ✅ SAAS-001/002 |
| Only an active plan, on a cycle it prices, can be sold (`PLAN_UNAVAILABLE` otherwise)                                                        | `plans.planForNewSubscription`                            | ✅ SAAS-001     |
| A plan grants catalogue features and sets every catalogue limit (`null` = unlimited, at least 1 otherwise); a limit it does not set grants 0 | `entitlement.ts`, `subscription.validatePlanAllowance`    | ✅ SAAS-002     |
| Nothing is gated on a plan's name or code — only on what it grants                                                                           | ESLint `no-restricted-syntax`                             | ✅ SAAS-002     |

### Enforcement matrix (§42)

The source of truth is `ENFORCEMENT_MATRIX` in `packages/domain/src/entitlement.ts`. Its tests check that every
key names a real permission, feature and limit, that every feature and limit is covered, and that every
feature with a route is gated on one. Permission and
entitlement must **both** pass (§41). The gates are enforced by SAAS-003 (entitlements) and SAAS-011 (limits).

| Capability                                     | Permission                                   | Plan feature          | Limit                                 | Gated routes (SAAS-003)                                                         |
| ---------------------------------------------- | -------------------------------------------- | --------------------- | ------------------------------------- | ------------------------------------------------------------------------------- |
| Enrol a learner                                | `learners.enroll`                            | —                     | `learners.max`                        | limit: SAAS-011                                                                 |
| Add an instructor                              | `instructors.manage`                         | —                     | `instructors.max`                     | limit: SAAS-011                                                                 |
| Activate an inactive instructor                | `instructors.status` / `instructors.manage`  | —                     | `instructors.max`                     | limit: `POST /instructors/:id/status`, `PATCH /instructors/:id` (SAAS-025)     |
| Create a course                                | `catalog.edit`                               | `courses.manage`      | `courses.max`                         | `POST /courses`                                                                 |
| Create a category                              | `catalog.categories.manage`                  | — (catalogue structure) | —                                   | restricted mode refuses it: `POST /categories` (SAAS-025)                       |
| Change or delete a category                    | `catalog.categories.manage`                  | —                     | —                                     | open in restricted mode: `PATCH`, `DELETE /categories/:id` (SAAS-025)           |
| Change a course or its curriculum              | `catalog.edit`                               | `courses.manage`      | —                                     | `PATCH /courses/:id`, reorder; chapter and lesson create, edit, duplicate, move |
| Publish a course                               | `catalog.publish`                            | `courses.manage`      | —                                     | `POST /courses/:id/publish`                                                     |
| Upload media                                   | — (any signed-in account)                    | —                     | `storage.bytes`                       | limit: SAAS-011                                                                 |
| Create or change a quiz or assignment          | `assessment.edit`                            | `assessments.manage`  | —                                     | quiz and assignment create, edit, duplicate                                     |
| Issue a certificate                            | `certificates.issue`                         | `certificates.manage` | —                                     | `POST /certificates/:id/issue`                                                  |
| Manage certificate templates                   | `certificates.templates.manage`              | `certificates.manage` | —                                     | template create, set default                                                    |
| Schedule or change a live class                | `live.manage`                                | `live_classes`        | `live_classes.max` (a calendar month) | `POST /live`, `PATCH /live/:id`                                                 |
| Read the course, learner and enrolment reports | `reports.view`                               | `reports.basic`       | —                                     | `/reports/overview`, `/courses`, `/courses/:id`, `/learners`, `/enrolments`     |
| Read the instructor report                     | `reports.instructors.view`                   | `reports.advanced`    | —                                     | `/reports/instructors`                                                          |
| Use advanced analytics                         | `reports.view`                               | `analytics.advanced`  | —                                     | none — **planned**, not built (`Feature.enforcement = planned`)                 |
| Brand the academy                              | `settings.edit`                              | `custom_branding`     | —                                     | `PUT /settings/appearance` only                                                 |
| Add an academy admin                           | — (platform route `POST /superadmin/admins`) | —                     | `admin_accounts.max`                  | limit: SAAS-011                                                                 |
| Priority support                               | — (a service level, not a route)             | `priority_support`    | —                                     | none — a **service** level (`Feature.enforcement = service`)                    |

**Restricted mode** (an academy served no plan — never subscribed, paused, cancelled or expired) keeps what it had
and adds nothing (`RESTRICTED_MODE_POLICY`). On a feature-gated route, an operation the policy keeps open — read,
update, withdraw, serve learners — goes ahead only if the academy's **last plan included the feature** (SAAS-025).
A never-subscribed academy therefore gets no plan feature: it can never exceed the lowest paid tier.

Never gated, whatever the plan:

- the dashboard;
- withdrawing content: unpublish, archive and restore a course; delete a chapter, lesson, quiz or assignment;
  revoke and restore a certificate; cancel a live class;
- serving learners the academy already has: live-class registration, reminders, hand-ins, grading.

A plan that no longer includes a feature leaves what exists usable (SAAS-003, P11).

This departs from the example table in §42 in two places:

- Learners and instructors carry no feature flag. The §4 catalogue defines none, and every academy has both.
- Courses are gated by `courses.manage`, the §4 key, rather than the example's `courses.enabled`.

## Subscription lifecycle (SAAS-004)

The source of truth is `TRANSITIONS` in `packages/domain/src/lifecycle.ts`. The database's triggers hold the
same 18 status pairs, and a test tries all 49 pairs against them. A status changes only through one of these
named transitions, and each one writes a lifecycle event in the same transaction.

| Transition          | From                                                    | To                     | Caused by                                    | Event (§19)                                                                                  |
| ------------------- | ------------------------------------------------------- | ---------------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------- |
| create              | —                                                       | `trialing` or `active` | platform (super admin), provider             | `subscription.trial.started` / `subscription.activated`                                      |
| `payment_succeeded` | `trialing`, `active`, `past_due`                        | `active`               | provider, system                             | `subscription.activated` (conversion, recovery) / `subscription.payment.succeeded` (renewal) |
| `payment_failed`    | `trialing`, `active`                                    | `past_due`             | provider, system                             | `subscription.past_due`                                                                      |
| `grace_started`     | `past_due`                                              | (unchanged)            | provider, system, once retries are exhausted | `subscription.past_due`                                                                      |
| `trial_expired`     | `trialing`                                              | `expired`              | system, once `trialEndAt` has passed         | `subscription.expired`                                                                       |
| `request_cancel`    | `active`                                                | `canceling`            | a person                                     | `subscription.cancel.requested`                                                              |
| `cancel_now`        | `trialing`, `active`, `past_due`, `paused`, `canceling` | `canceled`             | a person, provider                           | `subscription.canceled`                                                                      |
| `resume`            | `canceling`, `paused`                                   | `active`               | a person, system                             | `subscription.resumed`                                                                       |
| `pause`             | `active`                                                | `paused`               | a person                                     | `subscription.paused`                                                                        |
| `period_ended`      | `canceling`                                             | `canceled`             | system, once the period has ended            | `subscription.canceled`                                                                      |
| `grace_expired`     | `past_due`                                              | `expired`              | system, once `gracePeriodEndAt` has passed   | `subscription.expired`                                                                       |
| `change_plan`       | `trialing`, `active`                                    | (unchanged)            | a person, provider, system                   | `subscription.plan_changed` (SAAS-006)                                                       |

Rules:

- **Terminal.** `canceled` and `expired` are terminal. An academy that wants to start again gets a new
  subscription; the old one stays as history (§12).
- **One live subscription.** An academy has at most one subscription that is neither cancelled nor expired.
- **A person** is a super admin working as the platform, or the academy's own admin inside it. Nobody else.
  Only the platform or a verified provider event creates a subscription; an academy admin cannot write one into
  being.
- **The price** is copied from the plan version by the server and is never read from a request.
- **Periods are continuous.**
  - A conversion starts the first paid period at the payment.
  - A renewal and a recovery from `past_due` carry on from the end of the last period.
  - A monthly period is one calendar month; 31 January is followed by the last day of February.
- **Time-driven transitions** (trial expiry, period end, grace expiry) run only once their moment has passed on
  the **server's** clock.
- **What a status grants.** A subscription in `trialing`, `active`, `past_due` or `canceling` serves its plan
  version's entitlements.
  - `paused` grants nothing: `402 SUBSCRIPTION_REQUIRED`, "paused".
  - `canceled` and `expired` grant nothing: `402 SUBSCRIPTION_EXPIRED`.
  - An academy that has never subscribed gets `402 SUBSCRIPTION_REQUIRED`.

### Trials and grace (SAAS-005)

**Trials**

- A trial's length comes from the plan version's `trialDays`. Its start and end come from the **server's clock**
  (`src/lib/clock.ts`) and nothing else: no service function takes a time from its caller.
- A trial's dates are fixed in the database once written (trigger `Subscription_trial_fixed`).
- An academy gets **one free trial**, on any subscription, ended ones included. A second is refused
  (`INVALID_SUBSCRIPTION_STATE`) unless `SUBSCRIPTION_REPEAT_TRIALS=on`. A paid start is always open.

**The overdue path** (§8)

1. A failed charge makes the subscription `past_due`. `pastDueAt` and `pastDueReason` are stored, and access
   continues.
2. Payment retries run (the provider and SAAS-012).
3. If a retry succeeds, the subscription is `active` again. The overdue episode and any grace window are
   cleared, and the next period carries on from the last one's end.
4. If retries are exhausted, `grace_started` opens a window from now to now + `SUBSCRIPTION_GRACE_DAYS`, once
   per episode. The end is fixed into the row, so a later configuration change does not move it, and only the
   transition can write it (trigger `Subscription_grace_by_transition`).
5. With no grace length configured, no grace starts and the academy keeps its access.
6. Once the window has passed on the server's clock, `grace_expired` makes the subscription `expired`, with
   `402 SUBSCRIPTION_EXPIRED` from then on.

### Plan changes, pauses and cancellation (SAAS-006)

Written before the code, from the product owner's decisions D7–D10 (`.claude/saas/progress.md`). Every
figure is an integer number of paise, calculated by the server. Nothing in a request can set a price, a credit,
a charge or a date.

**Which kind of change it is.** The current per-period amount is compared with the new plan version's price on
the target cycle.

| Change                                               | Kind                                      | When it takes effect                       | Money                                                                    |
| ---------------------------------------------------- | ----------------------------------------- | ------------------------------------------ | ------------------------------------------------------------------------ |
| Same cycle, new price **higher**                     | upgrade (D7)                              | immediately, once the payment is confirmed | charge = new plan's remaining-period value − current plan's unused value |
| Monthly → annual                                     | cycle upgrade (D8)                        | immediately, once the payment is confirmed | charge = annual price − unused value of the current month                |
| Same cycle, new price **lower**                      | downgrade (D10)                           | at the next billing-period boundary        | none: no refund, no credit                                               |
| Annual → monthly                                     | downgrade (D10 applied to a cycle change) | at the next boundary                       | none                                                                     |
| Same cycle, **same** price, another plan             | scheduled change                          | at the next boundary                       | none                                                                     |
| The version the subscription already has, same cycle | refused: nothing to change                | —                                          | —                                                                        |

**Proration** (D7, D8)

- The current period runs from `currentPeriodStartAt` to `currentPeriodEndAt`. At the moment of the quote, the
  remaining share is _remaining ms ÷ period ms_.
- Unused value = current amount × remaining ÷ period. Remaining-period value = new amount × remaining ÷ period.
- Each is rounded **half up to a whole paisa**, calculated as integers (BigInt) with no floating point.
- The charge is the difference, never below zero. If the credit on a cycle change exceeds the annual price, the
  charge is 0 and the rest of the credit is recorded as forfeited, never paid out (D10 allows no refunds).
- Example: ₹3,999/month to ₹8,999/month exactly halfway through the month. Credit ₹1,999.50, new value
  ₹4,499.50, charge **₹2,500**.

**A quote, then a confirmed payment** (D7, §10, §43)

- An upgrade is a `PlanChange` quote: from and to versions and amounts, credit, charge, currency, and the
  period it was priced against. Its figures are fixed when issued and are never updated (database triggers).
- The quote stays `pending_payment` until a **verified provider payment** confirms it. A person or a browser
  cannot confirm one. Only then does the subscription move to the new version (`change_plan`) and the new
  entitlements switch on.
- Same cycle: the renewal date is unchanged. Monthly → annual: the annual period starts at the confirmation
  (the effective date) and renews a year later.
- A quote can be confirmed only while its period is still running. Once the period has ended it expires, and
  the change must be quoted again against the new period.

**Downgrades** (D10)

- A downgrade is a `PlanChange` in `scheduled` status. The subscription keeps its current version, and so its
  current entitlements, until the period ends.
- At the boundary the change is applied first. The renewal then charges the new plan's price.
- The limits the academy already exceeds on the new plan are worked out and stored on the change, then shown
  to the tenant. Nothing is deleted. Existing rows stay; new usage past a limit is refused by the entitlement
  service's `canConsume` (enforced on routes by SAAS-011).

**One open change at a time.** A subscription has at most one `pending_payment` or `scheduled` change. Cancel it
to make another. When a subscription ends, its open change is voided.

**Who.**

- A change is requested by a super admin (platform) or the academy's own admin.
- Only the provider confirms an upgrade payment.
- The scheduler applies a due downgrade.
- A plan change is refused during a trial: nothing has been paid, so there is nothing to prorate. Convert first.
  (SAAS-006 decision; the D-rules do not cover trials.)
- A plan change is refused while past due, paused or cancelling (the state machine).

**Pause** (D9)

- A pause is asked for as a whole number of days, 1–**30**. The server sets `pausedAt` = now and `resumesAt` =
  now + days; no date is taken from the request.
- On resume the period end moves out by the **actual** paused time: from `pausedAt` to the resume, or to
  `resumesAt` if the resume comes later, so never more than 30 days.
- A person may resume early. The scheduler resumes a pause only once `resumesAt` has passed.
- Pause and resume are lifecycle events, carrying the dates and the extension.

**Cancel and resume.** Every request records the actor, the time, the reason (when given) and the effective
date, in the lifecycle event and on the subscription:

- cancel at period end: effective at the period end;
- cancel now: effective immediately;
- resuming a cancellation: effective immediately.

A fully cancelled subscription is replaced by a new one, never revived (§12).

**Period dates are the server's alone.** A trigger refuses any change to `currentPeriodStartAt` or
`currentPeriodEndAt` unless the latest lifecycle event records exactly those dates. That event is a renewal, a
resume from a pause, or a cycle upgrade.

### Money, tax and currency (SAAS-007)

- **Integers only.** Every amount is an integer of the currency's minor unit, and every tax rate an integer of
  basis points (1800 is 18%). Every division of money is `divideRounded` (BigInt, half up), including an annual
  subscription's monthly value. Every stored amount column carries an integer `CHECK`.
- **Tax is separate from the price.**
  - A plan's price is its price. Tax comes from the **rule** for the academy's billing address: that region's
    rule, else its country's, else none.
  - A rule lists its components (one GST, or a CGST and an SGST, or a VAT) and whether prices include them.
  - Exclusive: each component is `price × rate`, rounded per component, added on top.
  - Inclusive: the net is `price ÷ (1 + Σrates)`, and the last component takes any rounding paisa, so net + tax
    is exactly the price.
  - No country is named in code.
- **Rules are history.** A rate change retires the rule and adds a new one, so tax already charged can always
  be traced to the rule it used.
- **The payable amount is the server's.** What an academy pays for a new subscription, a renewal or a plan
  change is the stored price (plan version, subscription amount or plan-change charge), taxed at its billing
  address. No function takes an amount. An academy without a billing address cannot be charged (409).
- **Currency** travels with each price: a plan version, a subscription, a plan change. A second currency is a
  plan priced in it: tax rates are currency-free, and digits come from ISO 4217. Changing a subscription's
  currency through a plan change is refused (§51).

### Invoices, payments and refunds (SAAS-008)

- **Invoices** are issued by the platform (scheduler, provider flow or a super admin) from the server's payable
  amount: a renewal (the next period), a plan change (the quote's charge) or a new subscription.
  - Numbers run `INV-YYYY-NNNNNN` in one platform-wide series per calendar year (UTC) and are never reused.
  - An invoice is open and due on issue.
  - One line describes what is bought; the tax lines come from the rule. The billing address is copied in, so a
    later plan, price or address change rewrites nothing.
  - An academy without a billing address is not invoiced. A renewal period or a plan change is never invoiced
    twice unless the first invoice was voided.
  - Only a super admin voids an invoice, with a reason, and only while it is open.
- **Payments** are recorded from verified provider events only, and are idempotent on the provider's payment id.
  - Money the provider reports is always recorded as it happened.
  - It settles the invoice only if it is paid, for exactly the invoice's total and currency, while the invoice is
    open. Anything else leaves the invoice open, to be looked into.
  - A paid or failed payment is never changed.
- **Refunds** are asked for by a super admin with a reason, in full (the default) or in part, and settled by the
  provider.
  - Pending and succeeded refunds together never exceed the payment.
  - The payment row is never touched: it reads *partially refunded* or *refunded* from its succeeded refunds.
- **Payment methods** are the provider's reference and "Visa •••• 4242"-style display data. Anything
  card-number-like is refused, and nothing in the billing code writes to the logs.

### An academy's first subscription (SAAS-009, extended)

An academy with no live subscription (never subscribed, or its last one ended) can buy one from **Billing**,
if online payment is configured and the admin holds `settings.edit`:
1. The admin chooses a plan on sale and a cycle.
2. The server prices the plan's current version, taxes it (SAAS-007), and issues one first-purchase invoice
   recording that version and cycle (SAAS-008).
3. The provider's checkout takes the payment.
4. When the provider confirms it, through the verified confirmation or the webhook, the subscription starts
   **active** on exactly the version paid for, even if the plan was repriced in between. It is created
   through the SAAS-004 lifecycle, and its features and limits apply from then.
5. A failed, pending, short or excess payment starts nothing, and the invoice stays open to pay again.
6. If the platform started a subscription for the academy while the payment was under way, no second one is
   created. The payment stays recorded for the platform to refund or apply (`payment.unmatched`).
7. A trial is live: it converts by paying its own invoice, never through a first purchase. Trials are still
   started by the platform.

### Billing over time (SAAS-012)

What the jobs do, by the server's clock, each at most once:

- **Trial ends:** a trial whose end has passed expires unconverted. Paying its first invoice before then
  converts it.
- **Renewal invoice:** issued `SUBSCRIPTION_INVOICE_LEAD_DAYS` (default 7) before the period ends, at the next
  period's price. A downgrade scheduled for that boundary sets that price (D10). An open invoice whose price
  changed is voided and replaced; one being paid never is. A cancelling or paused subscription gets none.
- **Boundary:**
  - a scheduled downgrade applies first;
  - if the next period's invoice is paid, the subscription renews;
  - if not, it falls past due and keeps its access (§8).

  A renewal paid early renews immediately, unless a downgrade takes effect at that boundary; then it
  renews at the boundary, on the new plan.
- **Past due:**
  - a payment made but never confirmed (a closed window, a lost webhook) is found by asking the provider,
    which recovers the subscription;
  - after `SUBSCRIPTION_RETRY_DAYS` without payment, the grace period (`SUBSCRIPTION_GRACE_DAYS`) starts;
  - either setting unset means nothing is forced.
- **Grace ends:** the subscription expires, and the academy is restricted.
- **Cancellation at period end:** takes effect when the period ends.
- **Pause:** ends on its planned date, and the renewal moves out by the time paused (D9).
- **Usage:** it is counted live, so the reconciliation job only reports academies over a limit. It writes
  nothing.

### Usage limits and restricted mode (SAAS-011)

All of this is on only when `ENTITLEMENT_ENFORCEMENT=on`; off, nothing changes.

**How each limit is measured** (§23; `USAGE_STRATEGY`). Every metric is counted live, inside the transaction
that would add to it, after taking the academy's guard for that limit. Nothing is cached, so nothing drifts and
nothing needs reconciling.

| Limit | Counts | Checked when |
| --- | --- | --- |
| learners | every learner account | a learner signs up |
| instructors | instructors not inactive (invited ones count) | an instructor is added, unless added as inactive |
| courses | courses not archived | a course is created or restored |
| storage | bytes of every upload | a **staff** member uploads, by the file's size. A learner's hand-in counts but is never refused. |
| live classes | classes in the **month the class starts** (UTC), not cancelled | a class is scheduled, or moved into another month |
| admin accounts | admins not deactivated | the platform creates or reactivates an admin |

**Refusals.**
- Over a limit: `403 LIMIT_REACHED`, naming the limit, the plan's figure and the current usage.
- Concurrency: requests for the same academy and limit queue at the guard, so exactly the room left goes through.

**Restricted mode** (§21; `RESTRICTED_MODE_POLICY`) applies while an academy's subscription serves no plan:
never subscribed, paused, cancelled or expired. **Nothing that exists is taken away; nothing new is added.**

| Operation | Restricted? |
| --- | --- |
| Reads, including the basic reports, settings and the dashboard | allowed |
| Editing existing courses, curriculum, quizzes, assignments, live classes, the default certificate template | allowed |
| Withdrawing: unpublish, archive, delete, cancel, revoke | allowed |
| Serving learners: learning, hand-ins (uploads too), grading, registration, reminders, issuing earned certificates | allowed |
| Creating courses, curriculum, quizzes, assignments or templates; duplicating | refused |
| Publishing | refused |
| Scheduling a live class | refused |
| Advanced reports and analytics | refused |
| Branding | refused |
| Staff uploads | refused |
| New learner sign-ups | refused |
| Adding instructors | refused |

- Every refusal is `402 SUBSCRIPTION_EXPIRED` (ended) or `402 SUBSCRIPTION_REQUIRED` (paused or never
  subscribed), with a renew or subscribe message the screens turn into a prompt (SAAS-015).
- The platform itself is never restricted: a super admin can still add an admin to a restricted academy.


## Rules added in October 2026

| Rule | Where | Enforced |
| --- | --- | --- |
| Every self-registration confirms a 6-digit emailed code before any account exists; the academy, role, invitation and course are fixed by the server when the pending row is made; every door's rules are checked again when the code is confirmed | `lib/pendingAccounts.ts`, `lib/signup.ts`, `lib/verificationCode.ts` | ✅ `emailVerification.test.ts`, `signup.test.ts`, `learnerJoin.test.ts` |
| Codes are HMAC-hashed, expire in 15 minutes, allow 5 attempts and 5 sends, and spend an attempt before comparison | `lib/verificationCode.ts` | ✅ incl. concurrent guesses |
| An academy whose enrolment policy is `invite` takes learners by invitation only (`INVITATION_REQUIRED`); invitations are scoped to the inviting Admin's workspace, expire, and are used once | `lib/learners.ts`, `lib/invitations.ts` | ✅ `invitations.test.ts` |
| An instructor who asks to teach is `pending` and refused everywhere until an academy admin approves (D34) | `lib/instructorRequests.ts`, `lib/requestContext.ts` | ✅ `instructorRequests.test.ts` |
| A quiz attempt starts on the server, consumes an attempt, has the server's deadline (`timeLimit`), accepts a sheet only while open, before the deadline and in increasing sequence, and finishes exactly once; an expired session is scored on what was saved | `packages/domain/src/quizSession.ts`, `lib/quizSessions.ts` | ✅ `quizSession.test.ts`, `quizSessions.test.ts` |
| The built-in room opens from 15 minutes before the start until the scheduled end; only an enrolled learner (registered on join while there is room) or the course's staff (an admin with `live.manage`) may join; the host moderates (JaaS tokens); ending settles attendance; recordings are kept for `LIVE_RECORDING_DAYS` | `lib/liveRoom.ts`, `lib/liveSessions.ts` | ✅ `liveRoom.test.ts`, `liveSecurity.test.ts` |
| A course is for sale only with an admin-chosen price; the server prices every purchase; one open order per learner and course; the enrolment opens once, on the gateway's own confirmation; amount, currency, learner, course and order are immutable; course money settles to the academy's gateway, never the platform's | `lib/coursePurchases.ts`, `lib/academyPayments.ts` | ✅ `coursePurchases.test.ts`, trigger |
| A gateway in test mode takes no new payment on a production process; a payment the gateway reports `refunded` never settles an invoice; a late authorization after a recorded failure is not captured and raises `payment.unmatched`; a refund with no definite answer stays `pending` until its webhook | `lib/checkout.ts`, `lib/payments.ts`, `lib/razorpay.ts` | ✅ `checkout.test.ts`, `invoicesPayments.test.ts` |
| Two simultaneous renewals add one period, not two; a payment that renewed a subscription stops the renewal job marking it past due; a declined early renewal starts dunning only when the paid period ends | `lib/subscriptions.ts`, `lib/billingJobs.ts` | ✅ `billingJobs.test.ts` |
| Sign-in is throttled per account as well as per IP; password-reset links are budgeted per address and work once even when submitted twice at the same moment | `routes/auth.ts`, `lib/passwordReset.ts` | ✅ `auth.test.ts`, `hardening.test.ts` |
| The demo seed never runs against production (NODE_ENV/APP_ENV, a `zuviloai.com` origin, or a database not named `dev.db`/`test.db`/`e2e.db`) | `prisma/seedGuard.ts` | ✅ `seedGuard.test.ts` |
