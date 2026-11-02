# FLUTTER-014 Learner Certificates & Ranks — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## CERT-001 — The wallet shows her issued certificate and its details

- **Module:** FLUTTER-014
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** More → Certificates lists the learner's issued certificate; its detail shows that credential.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Certificates
2. Open the issued certificate

**Expected**

- "Issued" section with the credential ID from /learning/certificates
- Detail: "Certificate details" and the same ID

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## CERT-002 — The rank ladder shows where she is

- **Module:** FLUTTER-014
- **Tier:** smoke
- **Priority:** P1
- **Safe to repeat:** yes
- **Purpose:** More → Rank ladder shows the ranks and marks the current one.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. More → Rank ladder

**Expected**

- "Rank I · Beginner" and "Where you are now" on one step

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
