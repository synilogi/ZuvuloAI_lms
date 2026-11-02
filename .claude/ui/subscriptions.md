# Subscription & Plan Management — UI Specification

## 1. Purpose

Build the **Subscription & Plan Management** experience for the SyniastroLMS **Super Admin / platform administration** workspace.

This module is a **UI prototype only**.

The existing autonomous workflow is UI-only, so do not implement:

- payment gateway integration
- real subscription creation/cancellation
- billing backend
- database changes
- API integration
- tenant isolation
- SaaS billing logic
- webhook processing
- real invoices
- real refunds
- real payment collection

Use realistic local mock data and functional UI-level interactions.

This module represents the future platform subscription layer and must not change the existing academy LMS behavior.

---

## 2. Existing Product Context

Existing Super Admin workspace:

- `/superadmin`
- `/superadmin/admins`
- `/superadmin/users`
- `/superadmin/audit`
- `/superadmin/system`

Add the subscription area under the existing Super Admin shell.

Recommended route:

- `/superadmin/subscriptions`

The exact route may follow the project's established routing conventions if a better existing pattern is found.

Do not redesign the Super Admin shell.

---

## 3. Navigation

Add:

### OPERATIONS / PLATFORM

- Subscriptions

Use the existing Super Admin navigation component and visual language.

Do not move or rename existing:

- Dashboard
- Admins
- Users
- Audit log
- System

The new navigation item should use the existing icon/component conventions.

---

# 4. Subscription Overview

Route:

`/superadmin/subscriptions`

Page title:

**Subscriptions**

Subtitle:

**Manage platform plans, customer subscriptions, and billing status.**

Include a compact KPI band.

### KPIs

- Active subscriptions
- Trial subscriptions
- Past due
- Canceling
- Monthly recurring revenue
- Annual recurring revenue

Use realistic mock values.

Do not imply these are real production figures.

---

# 5. Subscription Status

Support the following UI statuses:

- Trial
- Active
- Past due
- Canceling
- Canceled
- Paused
- Expired

Use the existing status/badge components.

Status styling must be consistent with the existing design system.

---

# 6. Plans Section

Provide a plans management area.

Recommended route pattern:

`/superadmin/subscriptions/plans`

If the existing project prefers a tabbed page, plans may be a tab inside `/superadmin/subscriptions`.

### Plan list

Columns:

- Plan
- Billing cycle
- Price
- Active subscribers
- Trial period
- Status
- Updated
- Actions

Filters:

- All
- Active
- Draft
- Archived

Search:

- plan name

Sorting:

- name
- price
- subscribers
- updated

Responsive behavior:

- desktop table
- mobile cards

---

# 7. Plan Creation

Provide a Create Plan action.

Form fields:

### Identity

- Plan name
- Short description
- Internal plan code

### Pricing

- Monthly price
- Annual price
- Currency
- Billing cycle options

### Trial

- Trial enabled
- Trial duration

### Limits

Support configurable UI values such as:

- Maximum learners
- Maximum instructors
- Maximum courses
- Maximum storage
- Live classes
- Admin accounts

Do not connect these limits to actual application behavior.

### Features

Use grouped feature toggles such as:

- Course management
- Assessments
- Certificates
- Live classes
- Reports
- Notifications
- Advanced analytics
- Custom branding
- Priority support

The feature list is UI configuration only.

### Visibility

- Draft
- Active
- Archived

Include validation.

Validation examples:

- required name
- positive pricing
- valid trial duration
- no duplicate plan code
- sensible limits

Use the existing project's form validation and error-summary patterns.

---

# 8. Plan Detail

Plan detail should show:

### Header

- Plan name
- status
- price
- billing cycle
- active subscriber count
- actions

Actions:

- Edit
- Duplicate
- Archive
- Restore

All actions are simulated locally.

### Overview

- pricing
- trial
- limits
- enabled features
- subscriber summary

### Subscription trend

Show a simple mock trend:

- active subscriptions
- new subscriptions
- cancellations

Use the project's existing chart components if available.

Do not add a new charting dependency just for this module.

---

# 9. Subscribers

Provide a subscriber/customer list.

Recommended route:

`/superadmin/subscriptions/subscribers`

or a Subscribers tab.

Columns:

- Customer / Academy
- Plan
- Status
- Billing cycle
- Started
- Renewal date
- Amount
- Payment status
- Actions

Filters:

- plan
- status
- billing cycle
- payment status
- date range

Search:

- customer/academy name
- email
- subscription ID

Pagination required.

Responsive mobile cards required.

---

# 10. Subscriber Detail

Create a detail view/panel.

Header:

- customer/academy name
- subscription status
- current plan
- renewal date

Sections:

### Subscription

- Subscription ID
- Plan
- Billing cycle
- Start date
- Renewal date
- Trial dates
- Cancellation date if applicable

### Billing

- Current amount
- Currency
- Payment status
- Last payment
- Next payment
- Payment method placeholder

Never show real card numbers.

Use masked placeholder data only, e.g.:

`•••• 4242`

### History

Timeline:

- subscription created
- trial started
- trial converted
- plan changed
- payment received
- payment failed
- cancellation requested
- cancellation completed
- subscription resumed

These are mock timeline events.

---

# 11. Subscription Actions

Provide simulated actions:

- Change plan
- Pause
- Resume
- Cancel
- Reactivate

Each action requires a confirmation dialog.

### Change Plan

Show:

- current plan
- new plan
- effective date
- price difference
- confirmation

### Cancel

Show:

- cancellation reason
- effective immediately / end of billing period
- confirmation

### Pause

Show:

- pause duration
- resume date

All interactions update local mock state only.

---

# 12. Billing / Payment History

Provide a payment-history view.

Columns:

- Date
- Customer
- Subscription
- Amount
- Currency
- Status
- Invoice
- Payment method

Statuses:

- Paid
- Pending
- Failed
- Refunded

Invoice action can open a mock invoice/detail dialog.

Do not generate a real invoice file.

---

# 13. Invoice Detail

Mock invoice view:

- Invoice number
- Customer
- Billing address placeholder
- Subscription
- Plan
- Billing period
- Line items
- Subtotal
- Tax
- Total
- Payment status
- Paid date

Actions:

- View
- Download
- Print

Download may be simulated with an existing UI interaction.

Do not implement real PDF generation unless an existing project component already supports it.

---

# 14. Trial / Grace Period UX

Support clear UI states for:

### Trial

Show:

- trial start
- trial end
- days remaining

### Grace period

Show:

- payment failure
- grace period end
- retry status

### Past due

Show:

- amount due
- last failed payment
- next retry

These are display states only.

---

# 15. Subscription Analytics

Within the overview, provide lightweight mock analytics:

### Subscription growth

- new subscriptions
- upgrades
- downgrades
- cancellations

### Revenue

- MRR
- ARR
- monthly trend

### Plan distribution

- subscribers by plan

Use existing chart components.

Do not add external chart dependencies unless the project already uses them.

---

# 16. Search / Filters / URL State

Where existing project conventions support it:

- search
- filters
- pagination
- sorting
- selected tab

should be reflected in URL query parameters.

Use existing query-state utilities.

Do not introduce a new state-management system.

---

# 17. Loading States

Every major data surface needs loading UI.

Use existing skeleton components.

Required:

- KPI skeleton
- table skeleton
- detail skeleton
- chart skeleton where applicable

---

# 18. Empty States

Handle:

- no plans
- no subscribers
- no payment history
- no search results
- no active subscriptions

Use existing empty-state components and visual language.

Examples:

**No plans yet**

Create your first subscription plan to start configuring platform offerings.

**No subscribers found**

Try changing the filters or search terms.

---

# 19. Error States

Use the existing error/retry pattern.

Provide:

- clear message
- Retry action

Do not expose implementation errors.

---

# 20. Responsive Design

Must support:

### Desktop

- full tables
- side-by-side cards
- analytics grid

### Tablet

- compressed table
- adaptive filters
- two-column cards where appropriate

### Mobile

- cards instead of wide tables
- filter sheet/drawer
- stacked KPI cards
- bottom-sheet dialogs where existing design supports them
- sticky primary actions for long forms

Follow the project's existing responsive breakpoints.

---

# 21. Accessibility

Follow existing accessibility conventions.

Ensure:

- labels for inputs
- keyboard-accessible dialogs
- visible focus states
- semantic buttons
- no click-only div interactions
- meaningful empty/error states
- appropriate dialog titles
- escape closes dialogs where existing modal system supports it

---

# 22. Mock Data

Create realistic local mock data.

Include at least:

### Plans

- Starter
- Growth
- Professional
- Enterprise

Use realistic but clearly mock values.

### Subscribers

Include a mixture of:

- Trial
- Active
- Past due
- Canceling
- Canceled
- Paused

### Payment history

Include:

- successful
- pending
- failed
- refunded

### Timeline

Include plan changes, payments, cancellation, and renewal examples.

Keep mock data centralized according to the existing project architecture.

---

# 23. Interaction Requirements

The UI should feel functional.

Implement locally:

- create plan
- edit plan
- duplicate plan
- archive/restore
- search
- filtering
- sorting
- pagination
- open subscriber detail
- change plan
- pause
- resume
- cancel
- reactivate
- open payment detail
- open invoice detail
- confirmation dialogs
- success feedback
- validation errors

Refresh/reload persistence is not required unless the existing mock service architecture already supports it.

---

# 24. Design Consistency

Reuse:

- AppShell
- Super Admin navigation
- page header
- cards
- tables
- badges
- dialogs
- drawers
- buttons
- inputs
- pagination
- toast/feedback system
- typography
- spacing
- responsive breakpoints

Do not create a second design system.

The module must look like it belongs to the existing SyniastroLMS platform.

---

# 25. Security / Scope Boundary

This is a UI prototype.

Do not implement real:

- payments
- payment gateways
- Razorpay
- Stripe
- PayPal
- webhooks
- invoices backend
- billing database
- subscription APIs
- recurring billing
- tenant isolation
- subscription enforcement

Do not modify existing Admin permission enforcement.

Do not make subscription state affect learner/instructor/admin access.

That belongs to a future backend/SaaS phase.

---

# 26. Testing

Add focused frontend tests for:

- subscription overview rendering
- plan list
- plan filtering
- plan search
- create plan validation
- edit plan
- archive/restore
- subscriber filtering
- subscriber detail
- change-plan confirmation
- cancellation confirmation
- payment status
- empty states
- error/retry
- responsive-safe rendering where practical

Run existing test suite.

---

# 27. Verification

Run:

- typecheck
- lint
- formatting
- tests
- production build

Also inspect:

- routes
- imports
- browser console
- direct URL access
- desktop
- tablet
- mobile
- loading
- empty
- error states
- dialogs
- keyboard interaction

Fix issues before marking complete.

---

# 28. Documentation / Progress

When complete:

Update `.claude/modules.json`:

LMS-019
    status = completed

Update `.claude/progress.md` with:

- screens
- routes
- components
- mock services/data
- files changed
- verification results
- known UI-only limitations

Create the commit following the autonomous workflow convention:

`feat(lms-ui): complete subscription & plan management`

Then continue automatically according to the existing autonomous workflow.

Do not ask the user whether to continue.

---

# 29. Important Autonomous Rule

Follow the existing `.claude/workflow.md`.

Before implementation:

1. Read project.md
2. Read architecture.md
3. Read rules.md
4. Read modules.json
5. Read progress.md
6. Inspect existing Super Admin shell
7. Read this specification

Then implement the module completely.

Do not ask for another design prompt.

If a genuine architectural blocker exists:

- set the module to blocked
- document the exact blocker
- do not falsely mark it completed

Otherwise complete the module and continue according to the existing workflow.
