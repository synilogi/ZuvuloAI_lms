# Autonomous SyniastroLMS SaaS Workflow

You are the lead full-stack engineer for the SyniastroLMS SaaS phase: tenants, plans, entitlements,
subscriptions, billing, webhooks and usage enforcement.

This workflow governs **`.claude/saas/modules.json` and nothing else.**

---

## 0. Scope

**Scope: `FULL_STACK`.**

This workflow explicitly permits, where a SaaS specification section requires it:

- backend code and services (`apps/api`)
- database schema and Prisma migrations
- tenant architecture and `tenantId` on existing tables
- authentication and authorization changes
- payment-provider integration through an abstraction
- webhooks
- background jobs
- SaaS billing: plans, pricing, invoices, payments, refunds, taxes

This is the permission that `.claude/saas/subscriptions.md` §2 and §0 require before any of this
work may begin. It applies **only** to modules whose id begins with `SAAS-`.

### What this workflow must never touch

1. **`.claude/modules.json`** — the UI-only module list (`scope: UI_ONLY`, all 20 modules
   completed). Never read it to pick work, never change a status in it, never add a module to it.
2. **`.claude/workflow.md`, `.claude/project.md`, `.claude/rules.md`, `.claude/ui/*`** — the UI-only
   workflow. It is finished and stays as it is. Read `rules.md` for the UI conventions you must keep
   honouring when you touch a screen; never edit it.
3. **`.claude/progress.md`** — the UI build's historical record. SaaS progress goes in
   `.claude/saas/progress.md` instead.

If a module id you are about to work on does not start with `SAAS-`, **stop immediately**: you are
in the wrong module list.

---

## 1. Read project context

Before doing anything, read in this order:

1. `.claude/saas/subscriptions.md` — the specification, starting with §0 (how this phase runs), §2
   (scope rule) and §54 (the architecture principle).
2. `.claude/saas/modules.json` — the module list, its `permits`, `verification` and `notes` fields.
3. `.claude/saas/progress.md` — what has been built so far, and any recorded blocker. On the very
   first run this file does not exist yet; create it as part of the first module (§7).
4. `docs/00-PROJECT-STATUS.md` — the F-series backend tracker and where this phase sits beside it.
5. `docs/01-PROJECT-ARCHITECTURE.md` — the workspace layout and conventions.
6. `docs/11-SUPERADMIN-FLOW.md` — the platform role this phase builds on, especially §23.

Then read, for whatever the selected module touches:

- `docs/03-DATABASE-SPECIFICATION.md` before any schema change
- `docs/04-AUTHENTICATION-AUTHORIZATION.md` before any auth or permission change
- `docs/05-API-SPECIFICATION.md` before adding an endpoint
- `docs/06-BUSINESS-RULES.md` before adding a rule to `packages/domain`
- `docs/09-SECURITY.md` before anything touching money, secrets, webhooks or tenancy
- `docs/10-DEPLOYMENT.md` before anything needing a new environment variable or process

Finally, inspect the existing code the module extends. Never guess at a signature or a table.

---

## 2. Select work — never skip a dependency check

Selection is mechanical. Do it exactly like this, and record the reasoning in your first message.

1. Load `.claude/saas/modules.json`. Confirm `scope` is `FULL_STACK` and every id starts with
   `SAAS-`. If not, stop.
2. **Resume before you start.** If exactly one module has `status: "in_progress"`, that is the
   module — resume it. Do not select anything else.
3. If **more than one** module is `in_progress`, stop and report it as a corrupted state (§6). Two
   modules may never be open at once.
4. If a module is `blocked`, do not select it, and do not select anything that depends on it.
5. Otherwise choose the `pending` module with the **lowest `priority`** whose **every** entry in
   `dependencies` has `status: "completed"`. A dependency that is `pending`, `in_progress` or
   `blocked` disqualifies the module — there is no "mostly done" and no working ahead.
6. If no module qualifies but `pending` modules remain, stop and report which dependency is holding
   the queue (§6). Do not improvise a different order.
7. If every module is `completed`, go to §9.

Having selected a module, read the specification sections it names in `sections` and the anchor in
`spec`. Read all of them before writing any code.

---

## 3. Claim the module — duplicate protection

Two SaaS modules must never be implemented at the same time, by you or by a parallel session.

Before writing any code:

1. Re-read `.claude/saas/modules.json` from disk. If anything is now `in_progress`, another run
   already claimed a module — stop and report it rather than racing it.
2. Set the selected module's `status` to `in_progress` and add `"startedAt": "<ISO date>"`.
3. Write the claim to `.claude/saas/progress.md` under `## In Progress`: the module id, the date,
   and what you are about to build.
4. Commit that claim on its own: `chore(saas): start [SAAS-0XX module name]`.

That commit is the lock. A later run that sees an `in_progress` module resumes it instead of picking
new work, and a run that sees two `in_progress` modules stops.

Clear the lock only in §7 (completed) or §8 (blocked). Never leave a module `in_progress` at the end
of a session without a progress entry saying exactly where it stands.

---

## 4. Plan

Translate the specification sections into:

- the schema change and its Prisma migration
- the domain rules that belong in `packages/domain` (pure TypeScript — shared by the API and the web
  app, and unit-tested there)
- the API surface, following `docs/05-API-SPECIFICATION.md`
- the authorization and entitlement order (`subscriptions.md` §33)
- the frontend integration, if the module has one
- the tests that prove it, including the security tests in `subscriptions.md` §47
- the audit entries (`subscriptions.md` §36)

Write the plan down in your first message before implementing. Where the specification says a policy
must be "defined" or "documented before production" — upgrade proration (§10), downgrade timing
(§11), restricted-mode policies (§21), per-metric usage strategy (§23) — write that decision into
`.claude/saas/progress.md` as part of the module. A policy that only exists in code is not defined.

Do not ask for another specification when `subscriptions.md` already answers the question.

---

## 5. Implement

Implement the selected module completely: database, backend, API, frontend integration, tests and
audit. One module per session's worth of work; do not begin the next one before this one is closed.

### Conventions to preserve

- **Architecture.** Follow `docs/01-PROJECT-ARCHITECTURE.md`. Shared rules go in
  `packages/domain`; the API and the web app both consume them. The frontend talks to
  `services/contracts.ts` interfaces only.
- **Code style.** Match the surrounding file: comment density, naming, error shapes, test style.
  Prettier settings are in `.prettierrc`; run `npm run format` before finishing.
- **UI work.** When a module touches a screen, the rules in `.claude/rules.md` still apply — reuse
  the existing shell and primitives, keep the loading, empty and error states, keep it working on
  desktop, tablet and mobile, keep the accessibility basics. `scope: FULL_STACK` widens what you may
  build; it does not lower the bar for what you build.

### Security rules that are not negotiable

These come from `docs/09-SECURITY.md`, `docs/11-SUPERADMIN-FLOW.md` §23 and
`.claude/saas/subscriptions.md` §35. None of them may be relaxed for convenience.

1. **Backend authorization is the source of truth.** Frontend guards are UX, never security.
2. **Do not modify `requireRole`** (`apps/api/src/lib/auth.ts`). Entitlement is a *separate* layer
   that runs after role and tenant checks (§33), never a replacement for either.
3. **Do not rename, convert or remove the `admin` role** without an explicit migration plan
   (`subscriptions.md` §40, `docs/11` §23.3). `Role` is defined in exactly one place:
   `packages/domain/src/identity.ts`.
4. **Tenant identity comes from the authenticated server context**, never from a client-supplied
   `tenantId`.
5. **The client never controls price, plan, subscription status or entitlement grants.** The server
   calculates the payable amount from the plan.
6. **A frontend success callback never activates a subscription.** Only a verified provider event
   does (§43).
7. **Every webhook is signature-verified and idempotent** on `provider + providerEventId` (§17–18).
8. **No raw card data** anywhere — schema, logs or responses. Masked display metadata only (§16).
9. **Financial history is append-only.** Never update or delete a paid payment, an invoice, a
   webhook event or a lifecycle record (§38). No destructive cascades.
10. **No secret is committed.** Provider credentials and webhook signing secrets come from the
    environment; document them in `apps/api/.env.example` and `docs/10-DEPLOYMENT.md`.
11. **Never log** payment secrets, webhook secrets, card data, passwords or tokens (§48).
12. **Enforcement ships behind a flag** and is switched on deliberately (§50), never as a side
    effect of a migration.

> `docs/11-SUPERADMIN-FLOW.md` §23.7 forbade any Tenant, Organization, Subscription, Plan or Billing
> model, and §23.8 forbade a PostgreSQL migration and mobile changes. Those were scoped to the Super
> Admin phase. Lifted here: §23.7 in full, and the PostgreSQL half of §23.8 — that is what this phase
> exists to build. **Still in force:** no mobile changes, and every other rule in §23.

### Migrations

Backward-safe where possible. Backfill before enforcing: a tenant column is added and populated in
one step and enforced in another, never both at once. Never write a migration that can erase
financial history.

---

## 6. Verify

Run, from the repository root:

- `npm run typecheck`
- `npm run lint` — zero warnings
- `npm test` — the web and domain suites
- `npm test -w @syniastrolms/api` — the API suite
- `npm run build`
- `npm run format:check`

All six must pass. A failing or skipped check is not a completed module.

Then verify the module's own claims:

- Walk its `doneWhen` list item by item and record, per item, **how** you proved it — a test name, a
  command, a request you made. "Looks right" is not proof.
- Run the tests `subscriptions.md` §47 requires for what you built: unit, integration and, for
  anything touching tenancy, money or webhooks, the security tests — cross-tenant access, forged
  tenant ids, forged and duplicate webhooks, client-modified price, plan or entitlement.
- **Regression:** the existing Super Admin, Admin, Instructor and Student workflows must still work.
  The UI build's route crawl and interaction checks are recorded in `.claude/progress.md`; anything
  this module could plausibly have broken gets re-checked in a browser against the real API.
- Inspect the browser console on any screen the module touched.

Fix everything before going near §7.

---

## 7. Complete

Only when §6 passed in full:

1. Set the module's `status` to `completed` in `.claude/saas/modules.json`, remove `startedAt` and
   add `"completedAt": "<ISO date>"`. Leave every other module untouched.
2. Append a section to `.claude/saas/progress.md` recording: what was built (schema, API, domain
   rules, frontend), the files added and changed, every policy decision the specification asked to
   be documented, the `doneWhen` list with the evidence for each item, the verification results, and
   the known limitations.
3. Update `docs/00-PROJECT-STATUS.md` if the module changes what that tracker says.
4. Update `docs/01-PROJECT-ARCHITECTURE.md` when the module adds a workspace file, a domain module
   or a service other engineers will need to find.
5. Commit: `feat(saas): complete [SAAS-0XX module name]`.

Never mark a module completed because it compiles, because the happy path works, or because the
remaining items are small. If one `doneWhen` item is unproven, the module is not complete — either
prove it or record it as blocked.

---

## 8. Blockers

A genuine blocker is a decision that is not yours to make: a business rule the specification leaves
open (which payment provider, what the proration policy is, whether repeat trials are allowed), a
credential or account you do not have, or an architectural conflict with something already built.

A hard bug is not a blocker. Fix it.

When genuinely blocked:

1. Set the module's `status` to `blocked` in `.claude/saas/modules.json` and add
   `"blockedReason": "<one sentence>"`.
2. Record in `.claude/saas/progress.md`: what you were building, exactly what stopped you, what you
   already tried, and the precise decision or credential a human must supply.
3. Commit: `chore(saas): block [SAAS-0XX module name] — <reason>`.
4. Leave whatever you completed in a working state: green checks, no half-applied migration, no
   dead code.
5. Stop. Do not select another module: the dependency chain is linear enough that working around a
   blocked module produces work that has to be redone.

Never mark a module completed when it is blocked, and never invent a business rule to unblock
yourself.

---

## 9. Continue automatically

Do **not** ask "Should I continue?".

After §7, go back to §2 and select the next eligible module immediately.

Stop only when:

- every module in `.claude/saas/modules.json` is `completed` — then run §10; or
- a genuine blocker is recorded (§8); or
- the module list is in a state §2 says to stop on (two modules `in_progress`, a non-`SAAS-` id, or
  a dependency deadlock).

---

## 10. Final audit

When every SaaS module is completed, audit the whole system against
`.claude/saas/subscriptions.md` §53 Definition of Done, item by item, with evidence for each:

- tenants isolated; plans, subscriptions, invoices and payments database-backed
- features and limits centrally defined; entitlements and limits enforced server-side
- lifecycle transitions, trials and cancellation enforced server-side
- upgrade and downgrade rules written down
- the payment provider reached only through the abstraction
- payment records immutable; invoices persisted
- webhooks verified and idempotent
- tenant isolation, payment failure and duplicate webhook tests passing
- audit logging in place
- existing LMS regression tests passing
- Super Admin platform access and Tenant Admin subscription access both working
- secrets protected; production deployment tested

Also audit for: cross-tenant leaks, money handled as floats, plan-name checks that should be
entitlement checks, endpoints bypassing the entitlement service, unindexed tenant columns,
destructive cascades, secrets in logs, TODOs, dead code and console errors.

Record the audit in `.claude/saas/progress.md` and set **SAAS PHASE STATUS: COMPLETED** only when
the system is genuinely complete — every §53 item true, not merely attempted.
