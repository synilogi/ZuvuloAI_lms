# Continue SyniastroLMS SaaS

Read `.claude/saas/workflow.md` and every context file it lists.

Continue from the current SaaS phase state.

**Module list: `.claude/saas/modules.json` only.** Never read `.claude/modules.json` to select work,
and never change it. If a module id does not begin with `SAAS-`, stop — you are in the wrong list.

**Scope: FULL_STACK.** Backend, database and Prisma migrations, tenant architecture, authentication
and authorization changes, payment-provider integration, webhooks, background jobs and SaaS billing
are all permitted where `.claude/saas/subscriptions.md` requires them. The existing UI-only workflow,
its rules and its module list stay exactly as they are.

Per module, in order:

1. Select the next eligible module — resume the one that is `in_progress`, otherwise take the
   lowest-priority `pending` module whose dependencies are **all** `completed`. Never skip a
   dependency check. Stop if two modules are `in_progress` or a `SAAS-` id is missing.
2. Claim it: set `in_progress`, write the claim to `.claude/saas/progress.md`, and commit
   `chore(saas): start [module]`. That commit is the lock — two SaaS modules are never open at once.
3. Read the specification sections the module names in `spec` and `sections`, then the existing code
   it extends.
4. Implement it completely: schema and migration, domain rules, API, authorization and entitlement
   order, frontend integration, tests, audit entries.
5. Verify: `npm run typecheck`, `npm run lint`, `npm test`, `npm test -w @syniastrolms/api`,
   `npm run build`, `npm run format:check` — all green — plus the module's `doneWhen` list with
   evidence per item, the security tests for anything touching tenancy, money or webhooks, and a
   regression pass over the existing Super Admin, Admin, Instructor and Student workflows.
6. Complete: mark `completed`, write the progress entry with the evidence and the documented policy
   decisions, update the docs the module changes, and commit
   `feat(saas): complete [module]`.
7. Continue to the next eligible module immediately.

Preserve the project's existing architecture, coding conventions and security rules. Backend
authorization stays the source of truth, the client never controls price, plan, subscription status
or entitlements, webhooks are always verified and idempotent, and financial history is append-only.

Do not ask for permission between modules.

Never mark a module completed unless its `doneWhen` checklist and all six verification commands
pass. If a genuine architectural blocker exists — a business decision or credential that is not
yours to supply — mark the module `blocked` with the exact reason, record what you tried and what a
human must decide, and stop.

Stop only for a genuine blocker, a module list in a state the workflow says to stop on, or the
completion of every SaaS module — in which case run the final audit in §10.
