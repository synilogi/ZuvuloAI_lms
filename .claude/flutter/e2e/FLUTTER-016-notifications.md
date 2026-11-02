# FLUTTER-016 Notifications Centre & Preferences — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## NOTIF-001 — The bell opens her notifications

- **Module:** FLUTTER-016
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** The bell's unread count matches the server and opens the list of this learner's notifications.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Read the bell
2. Tap it

**Expected**

- Bell says "{n} unread notifications" (n from GET /notifications) or "Notifications"
- The newest notification title is listed

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## NOTIF-002 — Mark one notification unread, then read again

- **Module:** FLUTTER-016
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** Per-row read state round-trips through the server.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Bell → the newest notification's More menu → Mark unread / Mark read
2. Then the opposite

**Expected**

- The server's unread count goes up by one, then back

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** Read state restored

## NOTIF-003 — Notification settings open with her channels

- **Module:** FLUTTER-016
- **Tier:** smoke
- **Priority:** P2
- **Safe to repeat:** yes
- **Purpose:** Profile → Notification settings shows the per-category channels and the digest.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Profile → Notification settings

**Expected**

- "What you hear about" and "Email digest"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
