# Continue SyniastroLMS Flutter

Start (or resume) the autonomous Flutter mobile development pipeline, and keep it running.

Read `.claude/flutter/workflow.md` and follow it exactly. It is the authority; this command is the
summary.

**Module list: `.claude/flutter/modules.json` only.** Every id must begin with `FLUTTER-`. Never read
another module list to pick work, never change another workflow's files, and never continue the React
workflow. The app lives in `apps/mobile`. The backend (`apps/api`), database, web app (`apps/web`) and
shared packages are read-only: they are the source of truth, and the app consumes their real contracts.

Loop, without stopping between modules:

1. **Discover.** Read `.claude/flutter/progress.md` (the `## Session Checkpoint` first), then
   `.claude/flutter/modules.json`, then `.claude/flutter/modules.md` (architecture §1–§28 and the selected
   module's section), then the workflow.
2. **Validate.** Check the registry: `FLUTTER_MOBILE` scope, unique `FLUTTER-` ids, valid and acyclic
   dependencies, at most one `in_progress`. Check `git status` for concurrent changes in `apps/mobile/`
   or `.claude/flutter/` that the checkpoint does not account for.
3. **Select.** Resume the `in_progress` module from the checkpoint's next exact action if there is one.
   Otherwise take the lowest-`priority` `pending` module whose dependencies are all `completed` and that
   does not depend on a `blocked` module.
4. **Claim.** Mark it `in_progress`, write the checkpoint, and commit the claim (only `.claude/flutter/`)
   when `git.commitCheckpoints` is on.
5. **Implement** it completely against the real backend contracts: models, API service, repository,
   controller, screens, routes, states, gates, tests. Update the checkpoint after every task.
6. **Test and fix.** Run the verification commands. Fix every recoverable failure at its root cause and
   run again — compile, analyze, format, unit, widget, integration, build. Never weaken or delete a test
   to make it pass.
7. **Verify.** Prove each acceptance criterion with evidence, and run the full suite for regressions.
8. **Complete.** Mark `completed` only after verification passes in full, record the evidence in
   progress.md, reset the checkpoint, commit (only `apps/mobile/` and `.claude/flutter/`) when enabled.
9. **Continue** straight to the next eligible module. Do not report and wait. Do not ask whether to go on.

A **blocked** module (missing credential, missing backend capability, undocumented API contract,
product decision, approval needed) is marked `blocked` with a precise `blockedReason` and a progress
entry, and the loop carries on with every module that does not depend on it.

Stop only when every module is completed, when every remaining module waits on a recorded blocker, when
the registry is corrupt, when another session is modifying this workflow's files, or when an action needs
human approval (deployment, store release, signing keys). Before stopping — or whenever the context
grows large — save the checkpoint so the next `/continue-flutter` resumes exactly where this one ended.

Never: fabricate an endpoint, ship mock business data, store a secret or token outside secure storage,
send a client-controlled price, amount, tenant, status or entitlement, `git reset --hard`, `git add -A`,
force-push, or touch another session's uncommitted changes.
