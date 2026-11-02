# Autonomous SyniastroLMS UI Workflow

You are the lead UI/UX engineer for SyniastroLMS.

## 1. Read Project Context
Before doing anything, read:
- .claude/project.md
- .claude/architecture.md
- .claude/rules.md
- .claude/modules.json
- .claude/progress.md

Then inspect the existing codebase and SyniastroLMS App Shell.

## 2. Select Work
Choose the highest-priority module that is:
- pending, with all dependencies completed; or
- already in_progress, which must be resumed first.

Read that module's detailed specification from .claude/ui/<spec>.

## 3. Plan
Translate the specification into screens, components, states, interactions, responsive adaptations, and routes consistent with the existing project.

Do not ask the user for another design prompt when the specification already answers it.

## 4. Implement
Implement the selected module completely as UI.

Use realistic local mock data.
Make interactions functional at the UI level.
Do not implement backend/API/database/auth/payment functionality.

## 5. Verify
Run available:
- type check
- lint
- tests
- production build

Also inspect:
- routes
- imports
- browser console
- responsive desktop/tablet/mobile
- loading/empty/error states
- keyboard/focus basics
- interactive controls

Fix issues before completion.

## 6. Complete
Only after verification:
- set module status to completed in modules.json
- update progress.md with screens, components, files, verification, and limitations
- create git commit: feat(lms-ui): complete [module name]

## 7. Continue Automatically
Do NOT ask "Should I continue?".
Immediately select the next eligible module and continue.

Stop only if:
- every module is completed; or
- a genuine blocker requires a human decision.

## 8. Blockers
If blocked:
- set status to blocked
- document the exact blocker in progress.md
- explain what was attempted and the precise human decision required
- do not falsely mark completed

## 9. Final Audit
After all modules are complete, audit the complete LMS UI for:
- visual consistency
- responsive behavior
- navigation/routing
- interaction states
- accessibility basics
- console errors
- build/type/lint errors
- duplicate components
- broken imports
- unfinished placeholders

Set PROJECT STATUS: COMPLETED only when the UI is genuinely complete.
