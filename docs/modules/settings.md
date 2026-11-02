# Module — Settings

Status: **COMPLETED** (phase F13) · Depends on: —; consumed by every module

## 1. Purpose
Academy-wide configuration in six sections: general, courses, learning, certificates, notifications,
branding.

## 2. Existing UI
`/admin/settings/general|courses|learning|certificates|notifications|branding`. Files: `pages/lms/settings/*`.

## 3. UI Data Requirements
`Settings` (domain shape) + `meta { updatedAt, updatedBy }` per section.

## 4. Database
`Settings` singleton (id 'academy', sectionsJson, metaJson, updatedAt).

## 5. API
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/settings` | admin, instructor (read) |
| PUT | `/settings/:section` | admin — 400 for an unknown section or non-object body; `validateSettings` (409); `updatedBy` = the admin's name |

## 6. Business Rules
Where each field is consumed:

| Section · field | Consumer |
| --- | --- |
| general.language / defaultVisibility | course create defaults |
| general.enrollment / accessMonths | self-enrolment policy, `expiresAt` (staff enrolments too) |
| general.lessonDefaults.durationMin / completion / allowComments / allowDownloads / previewFirstLesson | lesson create defaults (`view` → opened, `time` → watched for video, `check` → passed for quizzes) |
| general.academyName / supportEmail | email sender identity fallback |
| general.lmsLabel | UI label (settings page) |
| courses.defaultFormat / defaultPrice / maxInstructors / requireReview | course create defaults, instructor limit, review-before-publish (admins notified) |
| courses.showRatings / minRatings | public catalog hides ratings below the threshold |
| courses.archiveInactiveMonths | daily job archives published courses without activity, admins notified |
| courses.release / showEnrolmentCount | display preferences kept for the UI (the approved screens do not vary on them) |
| learning.completionThreshold / courseCompletion / completionPercent / chapterGate / quizAttempts / retakeWaitHours | learner progress engine |
| learning.latePolicy / latePenalty | assignment hand-in and grading |
| learning.atRiskDays | learner status (staff lists/profiles) and inactivity nudges |
| learning.learnerPreferences.studyReminders | inactivity nudges on/off; the other preferences are learner-UI defaults |
| certificates.enabled / autoIssue / minScore / credentialPrefix / defaultTemplateId / publicVerification / validityMonths | certificate creation, verification (`validUntil`, `expired`) |
| certificates.fields | template display (UI) |
| notifications.senderName / replyTo | email footer / transport identity |
| notifications.learner.* / staff.* / smsEnabled | notification engine switches and scheduled jobs; SMS channel availability |
| appearance.* | branding shown by the settings page; the shell's brand is fixed by design |

## 7. Permissions
Admin only for writes; `GET` is admin/instructor.

## 8. Backend Status
✅ get/put + validation · ✅ every field traced to a consumer or documented as UI-only · ✅ `updatedBy` by name (F13).

## 9. Frontend Integration
`services/http/settings.ts`; wired.

## 10. Testing
`routes/settings.test.ts` — updatedBy name, unknown section / bad body 400, validation 409, instructor 403, at-risk days change statuses, lesson defaults + default price + rating threshold, inactive course archiving, study reminders off. Each other consumer is tested in its module suite.

## 11. Completion
- [x] Routes
- [x] Enforcement verified module by module
- [x] Tests
