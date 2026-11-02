# FLUTTER-025 Admin Instructors & Certificates — LIVE UI E2E scenarios

Generated from `apps/mobile/tool/live_e2e/scenarios/` (`tool/live_e2e.sh docs`). Each scenario is
executed on the emulator through the accessibility tree and `adb input` — no code runs inside the app.

## INS-001 — The instructor directory and one profile

- **Module:** FLUTTER-025
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** More → Instructors lists GET /instructors; an instructor opens her profile with her courses.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Admin: More → Instructors
2. Open Dr. Meenakshi Iyer
3. Courses tab

**Expected**

- Her name listed
- Profile Overview/Courses/Performance; her course titles under Courses

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed

## INS-002 — The certificate register finds a credential

- **Module:** FLUTTER-025
- **Tier:** smoke
- **Priority:** P0
- **Safe to repeat:** yes
- **Purpose:** More → Certificates (admin) searches the register for the learner's credential and opens it.
- **Preconditions:** none
- **Test data:** none

**Actions**

1. Admin: More → Certificates
2. Search the credential ID
3. Open it

**Expected**

- That credential and learner listed
- Detail: "The learner", "Certificate details", "Public verification"

**Evidence:** screenshot of the final state; logcat on failure

**Cleanup:** none needed
