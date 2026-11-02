# Autonomous SyniastroLMS Flutter Workflow

You are the lead Flutter engineer for the **SyniastroLMS mobile application**: a new, production
Flutter client that consumes the existing SyniastroLMS backend (`apps/api`).

This workflow governs **`.claude/flutter/modules.json` and nothing else.** It is started by
`/continue-flutter` and runs module after module, on its own, until every module is completed or a
genuine blocker needs a human.

---

## 0. Scope

**Scope: `FLUTTER_MOBILE`.**

### What this workflow may create and change

| Path | What |₹
| --- | --- |
| `apps/mobile/**` | The Flutter application: source, tests, assets, Android/iOS runners, its own `.gitignore`, `pubspec.yaml`, `pubspec.lock` |
| `.claude/flutter/modules.json` | Module status fields only (`status`, `startedAt`, `completedAt`, `blockedReason`, `blockedAt`) |
| `.claude/flutter/progress.md` | The recovery state and the record of this phase |
| `.claude/flutter/modules.md` | Only to append a clarification answer or an `API contract` finding discovered while building — never to widen scope silently |

### What this workflow must never touch

1. **The backend and database.** `apps/api/**`, `apps/api/prisma/**`, migrations, seeds, `.env`
   files, `deploy/**`. Read them to learn a contract; never edit them. If the app needs something the
   backend does not provide, record `Backend capability required` (§8) — never build a fake API, a
   mock server shipped in the app, or a workaround that duplicates backend logic.
2. **The web application.** `apps/web/**`, `apps/lms-react/**`, `packages/**`.
3. **Other workflows.** `.claude/modules.json`, `.claude/workflow.md`, `.claude/progress.md`,
   `.claude/project.md`, `.claude/rules.md`, `.claude/architecture.md`, `.claude/ui/**`,
   `.claude/saas/**`, `.claude/react/**`, and their commands. Read `.claude/ui/*.md` and
   `.claude/saas/subscriptions.md` as product requirements; never edit them.
4. **Root workspace files** — `package.json`, `package-lock.json`, `eslint.config.js`, `.prettierrc.json`,
   `.prettierignore`, `.gitignore`, `README.md`, `docs/**`. The one allowed exception: if a root check
   (`npm run lint`, `npm run format:check`) starts failing *because* `apps/mobile` exists, add the
   narrowest possible ignore entry for `apps/mobile` and record it in progress.md as a decision.

If a module id you are about to work on does not start with `FLUTTER-`, **stop**: you are in the
wrong module list. The React workflow (`apps/lms-react`, `.claude/react`) is not this workflow and is
never continued from here.

### Backend is authoritative

The app never decides authorization, tenant identity, subscription state, entitlements, prices,
payment amounts, payment status, ownership, quiz scores, completion, certificate status or enrollment
status. It renders what the backend says and sends only what the backend's request schema reads. A
UI guard is UX; the API's refusal is the truth and must always be handled.

---

## 1. Discover — read the state first

Every run, before anything else, read in this order:

1. `.claude/flutter/progress.md` — **start with `## Session Checkpoint`.** If it names a module and a
   next exact action, that is where you resume.
2. `.claude/flutter/modules.json` — the registry.
3. `.claude/flutter/modules.md` — the master specification: the cross-cutting architecture sections
   (§1–§28) once per session, then the selected module's own section in full.
4. This file.

Then, for the selected module, read what it consumes:

- the backend route files and domain types its `API requirements` name
  (`apps/api/src/routes/*.ts`, `packages/domain/src/*.ts`), to confirm every field before modelling it;
- `docs/05-API-SPECIFICATION.md`, `docs/04-AUTHENTICATION-AUTHORIZATION.md`, `docs/06-BUSINESS-RULES.md`
  and the relevant `docs/modules/*.md`;
- the product requirement files in `.claude/ui/` the module lists under `sources`;
- the existing code in `apps/mobile` that the module extends. Never guess a signature.

---

## 2. Validate state

Before selecting work, validate the registry. Stop (§10) on any failure — these are corruption, not
bugs to work around:

1. `scope` is `FLUTTER_MOBILE` and every id matches `^FLUTTER-\d{3}$`.
2. Ids are unique; every `dependencies` entry names an existing `FLUTTER-` id; the dependency graph is
   acyclic; every dependency has a lower `priority` than its dependent.
3. `status` is one of `pending`, `in_progress`, `completed`, `blocked`.
4. At most **one** module is `in_progress`.
5. No module is `completed` while one of its dependencies is not.
6. progress.md's `## Session Checkpoint` agrees with the registry (same in-progress module, or none).
   If they disagree, trust the registry for status and progress.md for the work log, and record the
   repair.

Then check the working tree (§12 Git safety):

```bash
git status --short
git log --oneline -10
```

- Uncommitted changes under `apps/mobile/` or `.claude/flutter/` that progress.md's checkpoint does
  **not** list as this workflow's own modified files mean another session may be working here. Stop
  and record it (§10 "concurrent modification") rather than overwrite it.
- Changes anywhere else (e.g. another session on `apps/api`) are not yours: leave them alone, never
  stage them, and carry on. If they touch a backend contract the current module consumes, re-read
  that contract before relying on it and note it in progress.md.
- An unresolved merge conflict anywhere under the paths this workflow owns is a stop condition.

---

## 3. Select the module — mechanical, never skip a dependency check

1. **Resume first.** If one module is `in_progress`, that is the module. Resume from the checkpoint's
   next exact action. Never restart a partially completed module from scratch.
2. Otherwise choose the `pending` module with the **lowest `priority`** whose **every** dependency is
   `completed`.
3. A `blocked` module is never selected, and neither is anything that depends on it (directly or
   transitively). Independent modules keep flowing — a blocker stops only its own branch of the graph.
4. If no module qualifies and `pending` modules remain, every remaining branch is waiting on a
   blocker: go to §10 and stop with the list of blockers holding the queue.
5. If every module is `completed`, go to §11.

Record the selection reasoning in one line in progress.md (`Selected FLUTTER-0XX because …`).

---

## 4. Claim the module — duplicate protection

1. Re-read `.claude/flutter/modules.json` from disk. If another module is now `in_progress`, another
   run claimed it — stop and record it, do not race it.
2. Set the module `status: "in_progress"` and `startedAt: "<ISO date>"`.
3. Write the claim into progress.md: `## Session Checkpoint` (module, task list, next action) and the
   `## In Progress` section.
4. If `git.commitCheckpoints` in modules.json is `true`, commit the claim alone, staging **only**
   `.claude/flutter/`: `chore(flutter): start FLUTTER-0XX <name>`. That commit is the lock.

---

## 5. Plan the module

Turn the module's specification into a task list and write it into the checkpoint before coding:

- models (request/response) — field-for-field from the backend's route and domain types;
- API service methods and repository methods, with their `Result` types and error mapping;
- controllers/notifiers and their states;
- screens, routes and navigation entries;
- permission/entitlement gates the screens need (UX only);
- tests: unit, notifier, repository/API (against recorded fixtures), widget, navigation, and
  integration where the module requires it;
- anything in the module marked `Needs clarification` / `API contract required` /
  `Backend capability required`, and how the module handles it (usually: build the part that is
  specified, hide the rest behind a clearly worded unavailable state, and record the item — see §8).

Do not ask for another specification when modules.md already answers the question.

---

## 6. Implement

Follow modules.md's architecture exactly. The rules that are not negotiable:

1. **Layering.** Widget → Controller (Riverpod notifier) → Repository → API service → `ApiClient`
   (Dio). A widget never imports Dio, an API service, or `ApiClient`. A feature never imports another
   feature's internals — only its public `domain` exports or a shared contract in `lib/core` /
   `lib/shared`.
2. **Typed everything.** Request and response models are `freezed` + `json_serializable`. No
   `Map<String, dynamic>` leaves the data layer. Repositories return `Result<T, AppFailure>`.
3. **Only the contract.** Model only fields the backend actually returns; send only fields its request
   schema reads. Never send `tenantId`, `role`, price, amount, tax, status, score, `passed`,
   completion, entitlement or any owner/recipient id the server derives itself.
4. **Secrets.** Tokens only in `flutter_secure_storage`. No secret, key, token or credential in source,
   assets, `--dart-define` files that are committed, logs, crash reports or analytics. The only payment
   value the app ever holds is what the backend's checkout response gives it for that one checkout.
5. **States.** Every data surface has loading (skeleton), empty, error-with-retry, offline, and — where
   relevant — permission-denied, feature-unavailable and subscription-restricted states, from the shared
   state widgets in `lib/shared/widgets/states`.
6. **Design system.** Use `lib/core/theme` tokens and `lib/shared/widgets` components. No hard-coded
   colors, font sizes or paddings in feature code. Touch targets ≥ 48dp. Every interactive element has a
   semantic label.
7. **No fake data.** No mock business data in the app and no demo mode. Test fixtures are JSON captured
   from the real local API (§7.3) and live only under `test/fixtures/`.
8. **Dependencies.** Add a package only if modules.md §25.2 lists it (or the module's section names it).
   Anything else needs a written reason appended to modules.md §25.2 table and progress.md
   `## Decisions` before `flutter pub add`. Never upgrade a dependency as a side effect.
9. **Code style.** `dart format`, the project's `analysis_options.yaml`, and the surrounding code's
   naming and comment density.

Update the checkpoint after each task: done steps, modified files, next action (§9).

---

## 7. Test → Fix → Verify

### 7.1 Verification commands (from `apps/mobile/`)

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --fatal-infos --fatal-warnings
flutter test --coverage
flutter test integration_test -d <device>      # when the module requires integration tests
flutter build apk --debug --flavor dev -t lib/main_dev.dart   # from FLUTTER-000 on, per module
```

`FLUTTER-000` fixes the exact flavor/entry-point names; after that, use the commands recorded in
progress.md `## Verification commands`. All must pass. A skipped or failing check is not a completed
module.

### 7.2 Recoverable failures — fix them, do not stop

Dart compile errors, analyzer/lint errors, formatting, failing unit/widget/integration tests, missing
imports, wrong model mapping, JSON parsing errors, navigation errors, Gradle/build errors, fixable
runtime exceptions, flaky waits in tests.

```
ERROR → ANALYZE (read the whole message and the code it names)
      → FIX THE ROOT CAUSE
      → RE-RUN THE FAILING CHECK
      → RE-RUN THE FULL VERIFICATION
      → CONTINUE
```

- **Never** weaken, skip, delete or `@Skip` a test to make it pass, loosen an assertion to match wrong
  output, add `// ignore:` to silence a real analyzer finding, or catch-and-swallow an exception to hide
  it. If a test itself is wrong, fix it and say why in progress.md.
- If a model fails to parse a real response, the model is wrong — re-read the backend route and fix
  the model; never make fields nullable just to stop the crash without checking the contract.
- After **five** genuinely different fix attempts on the same failure without progress, write down
  what was tried, then decide: if the cause is outside this workflow's paths (backend behaviour,
  missing toolchain, device unavailable), it is a blocker (§8); otherwise keep going with a new
  hypothesis.

### 7.3 Local contract server (for fixtures and integration tests)

Integration tests run against the **real** API, never a hand-written fake, and never against the
repository's own `dev.db` or `test.db` (other sessions use them).

```bash
SCRATCH=<session scratchpad>/flutter-api
mkdir -p "$SCRATCH"
cd apps/api
DATABASE_URL="file:$SCRATCH/flutter.db" npx prisma migrate deploy
DATABASE_URL="file:$SCRATCH/flutter.db" npm run seed
DATABASE_URL="file:$SCRATCH/flutter.db" UPLOAD_DIR="$SCRATCH/uploads" PORT=4100 \
  LIVE_REMINDERS=off npm run dev      # run in the background; stop it when done
```

This reads backend code and writes only to the scratch database. The seed prints the demo accounts
(admin, instructor, student). The physical test phone reaches it over USB: `adb -s <device> reverse
tcp:4100 tcp:4100`, then the app built with `config/dev_device.json` (`http://localhost:4100`).

Capture fixtures by calling the real endpoints with `curl` and saving the JSON under
`apps/mobile/test/fixtures/<feature>/<endpoint>.json`, with the command used recorded in a comment
file beside them. Re-capture when the backend contract changes. Scrub tokens and emails before saving.

**Device rule (owner's standing instruction, 2026-10-09): test only on the USB-connected physical
Android phone** — Infinix X6525, adb id `11015313C8063805`. Before every device run, check
`adb devices -l` shows it as `device` (connected and authorized), and always target it explicitly:
`flutter run -d 11015313C8063805`, `flutter test integration_test -d 11015313C8063805`,
`adb -s 11015313C8063805 …`. If it is missing, `unauthorized` or `offline`, **stop and ask the owner
to reconnect it** — never fall back to an emulator, Chrome, desktop or any other device, and never
create, boot or use an AVD unless the owner explicitly says "use emulator".

### 7.4 Verify the module's own claims

- Walk the module's **Acceptance criteria** item by item and record, for each, **how** it was proved —
  a test name, a command, a screenshot path. "Looks right" is not proof.
- Walk its **Testing requirements**; each listed test exists and passes.
- Security items in the module (token handling, what is sent, what is logged) each have a test.
- Regression: the full `flutter test` suite, not just the new tests.
- Where a screen was built, run it on the physical test phone (§7.3 device rule) against the local contract server at least once
  (phone portrait; tablet/landscape where the module requires) and record the result.

---

## 8. Blockers — what they are and what to do

A **genuine blocker** is something this workflow cannot and must not decide:

- a missing credential or account (Firebase project, signing keystore, crash-reporting DSN, store
  account);
- an API the module requires that does not exist (`Backend capability required`) or whose contract is
  undocumented and not readable from the code (`API contract required`);
- an unclear product or business decision listed as `Needs clarification` that the module cannot
  proceed without (a module that can ship its specified part with the unclear part hidden is **not**
  blocked — it records the item and continues);
- a destructive database or backend decision;
- another session actively modifying the files this module needs; an unresolved merge conflict;
- a production deployment or store-release action that needs approval;
- a security-sensitive decision that cannot be safely inferred.

A hard bug is not a blocker. Fix it.

When genuinely blocked:

1. Leave the tree green: no half-applied change, no failing test, no dead code, no commented-out block.
   Revert only your own uncommitted work in the module's own files if that is what it takes — never
   anyone else's.
2. Set `status: "blocked"`, `blockedAt`, and a one-sentence `blockedReason` naming exactly what a human
   must supply.
3. Record in progress.md `## Blocked`: what was being built, what stopped it, what was tried, the exact
   decision/credential/API needed, and what becomes possible once it arrives.
4. Commit (if enabled, `.claude/flutter/` and `apps/mobile/` only):
   `chore(flutter): block FLUTTER-0XX <name> — <reason>`.
5. **Go back to §3** and continue with the next eligible module that does not depend on the blocked
   one. Stop only when no eligible module remains (§10).

Never mark a blocked module completed, never invent a requirement, endpoint or credential to unblock
yourself, and never ship a placeholder that pretends a feature works.

---

## 9. Session checkpoint — context-window and session recovery

progress.md's `## Session Checkpoint` is the single place a new session resumes from. Keep it current:

- **after every task** in the module's task list;
- **before** any long-running command (a build, an emulator boot, the integration suite);
- **immediately** when the context is getting large, before compaction, or before stopping for any
  reason.

It must always contain:

```
Module:            FLUTTER-0XX <name>            (or "none")
Status:            in_progress | between modules | blocked | all complete
Current task:      <task from the module's list>
Completed steps:   <numbered list>
Remaining steps:   <numbered list>
Modified files:    <paths this workflow changed and has not committed>
Tests run:         <command → result>
Failing tests:     <name → cause → what was tried>
Decisions:         <anything decided in this module, also copied to ## Decisions>
Blockers:          <none | description>
Next exact action: <one concrete command or edit — specific enough to execute cold>
Updated:           <ISO timestamp>
```

On resume: read the checkpoint, verify `Modified files` against `git status`, re-run `Tests run` to
confirm the recorded state is still true, then execute `Next exact action`. Never restart a module that
has completed steps; never redo a completed step unless verification shows it regressed.

---

## 10. Stop — and only for these

Stop the loop, with the checkpoint saved and a precise report, only when:

1. every module is `completed` (after §11);
2. no eligible module remains because every remaining branch waits on a recorded blocker;
3. the registry fails validation (§2) — two `in_progress` modules, a non-`FLUTTER-` id, a dependency
   cycle, a missing id;
4. concurrent modification or an unresolved merge conflict in this workflow's paths (§2);
5. an action needs human approval: a production deployment, a store upload, a signing-key creation,
   anything outward-facing.

The stop report names: completed modules this session, the blocked modules with their exact needs, the
next module that would run once unblocked, and the checkpoint's next action.

---

## 11. Complete a module — then continue automatically

Only when §7 passed in full:

1. Set `status: "completed"`, remove `startedAt`, add `completedAt: "<ISO date>"`. Touch no other
   module.
2. Append to progress.md `## Completed Modules`: what was built (screens, routes, models, endpoints
   consumed), files added/changed, decisions, each acceptance criterion with its evidence, verification
   results, and known limitations/clarifications still open.
3. Reset `## Session Checkpoint` to `Module: none / Status: between modules`, with `Next exact action:
   select next module`.
4. Commit (if `git.commitCheckpoints`), staging only `apps/mobile/` and `.claude/flutter/`:
   `feat(flutter): complete FLUTTER-0XX <name>`.
5. **Do not stop to report success. Do not ask "should I continue?".** Recalculate eligibility and go
   straight back to §3 with the next module.

When every module is `completed`, `FLUTTER-030` (Final Hardening & Release) has already run its full
audit. Set `PROJECT STATUS: COMPLETED` in progress.md only if its release-readiness checklist is true in
full; otherwise record what is outstanding.

---

## 12. Git safety

Never: `git reset --hard`, `git checkout -- <path>` or `git restore` on files you did not change,
`git clean`, `git stash` of other people's work, `git push --force`, `git add -A` / `git add .`,
rebasing or amending commits you did not make, or deleting a branch.

Always: stage explicit paths under `apps/mobile/` and `.claude/flutter/` only; inspect `git status`
before staging; leave every other modified file exactly as you found it (other sessions — e.g. the SaaS
workflow — may have uncommitted work in `apps/api`). Commits end with the attribution line the harness
provides. Never push unless a human asks.

---

## 13. Parallel work

The default mode is **sequential and dependency-safe**. One module at a time.

Parallel agents are allowed only for independent, read-only or isolated tasks inside the current
module:

- reading a set of backend route files to confirm a contract;
- analysing documentation or a failing test's cause;
- a security or accessibility review of finished code;
- isolated research (a package's API, an Android build error).

Parallel agents must **never** edit the same files, never run `flutter pub add`/`pub get`, and never
touch `pubspec.yaml`, `pubspec.lock`, `lib/app/router*`, `lib/core/theme/**`, `lib/core/network/**`,
`analysis_options.yaml`, Gradle files or `.claude/flutter/*`. Dependent modules are never parallelised.
If parallel *implementation* is ever justified, it happens in an isolated git worktree and is merged
back by the main session only after the full verification passes.
