# FLUTTER-001 Design System & Theme — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## DS-001 — The component gallery opens in the dev build and shows every group

- **Module:** FLUTTER-001
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The hidden gallery (dev builds only) is reachable from Profile and renders all eight component groups.
- **Preconditions:** dev flavor; learner signed in
- **Test data:** none

**Actions**

1. Profile → Component gallery
2. Scroll from top to bottom

**Expected**

- Group headers Actions, Inputs, Containers, Status, Charts, Overlays, States, Learning each appear
- Theme/text-size chips (Dark, 100%, 130%, 200%) present

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## DS-002 — Confirm dialog: cancel keeps things, confirm closes

- **Module:** FLUTTER-001
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** The shared confirmation dialog opens, Cancel dismisses it, Publish confirms it.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Gallery → Confirm dialog
2. Cancel
3. Confirm dialog again
4. Publish

**Expected**

- "Publish course?" with Publish and Cancel
- Dialog gone after Cancel
- Dialog gone after Publish

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## DS-003 — Destructive dialog needs the acknowledgement and shows a refusal

- **Module:** FLUTTER-001
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** A destructive action cannot be confirmed until "I understand this can't be undone" is ticked, and its error stays in the dialog.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Gallery → Dialog with error
2. Try Archive before ticking
3. Tick the acknowledgement
4. Archive

**Expected**

- Archive disabled until ticked
- After Archive: "The course has live classes scheduled." inside the dialog

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## DS-004 — Snackbar with Undo and the filter sheet

- **Module:** FLUTTER-001
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** Transient feedback offers Undo; a bottom sheet opens and closes with its own actions.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Gallery → Snackbar with undo
2. Read the snackbar
3. Gallery → Filter sheet
4. Apply

**Expected**

- "Notification removed" with Undo
- "Filter students" sheet with Reset/Apply, closed by Apply

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## DS-005 — Dark theme and 200% text render the same components

- **Module:** FLUTTER-001
- **Tier:** deep (deferred to the deep-QA phase)
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** The gallery switches to dark and to 200% text without losing any component (layout overflow is caught in logcat).
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Gallery → Dark
2. Gallery → 200%
3. Scroll the whole gallery

**Expected**

- Dark and 200% chips selected
- All groups still present
- No RenderFlex overflow logged

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
