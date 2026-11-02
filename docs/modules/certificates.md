# Module — Certificates

Status: **COMPLETED** (phase F9) · Depends on: Learning progress, Settings

## 1. Purpose
Templates, issuing/revoking certificates for completed courses, learner certificate wallet, public
verification.

## 2. Existing UI
`/admin/certificates` (list, filters), `/admin/certificates/:id` (detail, issue/revoke/restore),
`/admin/certificates/templates`, template editor; learner `/certificates` (issued + working towards),
`/certificates/:id`; public `/verify/:credentialId`. Files: `pages/lms/certificates/*`,
`pages/learner/certificates/*`, `pages/marketing/VerifyPage.tsx`.

## 3. UI Data Requirements
`CertificateRow` (learner, course, credentialId, status pending|issued|revoked, issuedAt, finalScore,
hours, template); `CertificateTemplate` (name, layout, colours, signature, default); learner
`CertificateRecord` (issued list + `working[]` with criteria progress); `VerifyResult`.

## 4. Database
`CertificateTemplate` (name, layoutJson, isDefault, timestamps) · `IssuedCertificate` (studentId FK,
courseId FK, enrollmentId FK, templateId FK, credentialId unique, status, finalScore, hours, issuedAt,
revokedAt, revokeReason, verifyCount, timestamps; unique (studentId, courseId)).

## 5. API
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/certificates` · `/certificates/:id` | admin, instructor (own courses) |
| POST | `/certificates/:id/issue` (staff of the course; pending only) · `/revoke` (admin, reason ≥ 3 chars, notifies the learner) · `/restore` (admin, revoked only) | |
| GET/POST | `/certificates/templates`, `/templates/:id`, `/templates/:id/default` | admin |
| GET | `/certificates/verify/:credentialId` | public — 404 when `publicVerification` is off or the certificate is still pending; revoked ones verify as revoked; counts checks |
| learner | `/learning/certificates`, `/:id`, `/:id/claim` | student, owner only |

## 6. Business Rules
`lib/certificates.ts` — `onCourseCompleted` (from the learning engine) creates the certificate when
`settings.certificates.enabled`, none exists yet and the final score meets `minScore` (courses without
scored work always qualify): status `pending`, or `issued` with `autoIssue`; the learner is notified
(claim / issued). Credential id `<credentialPrefix>-<course code>-<year>-<5-digit sequence>` where the
code is the initials of the title's first two significant words. Hours = published lesson minutes ÷ 60
(nearest ½). Final score = mean of best quiz percentages and graded assignment percentages. Template =
the course's template, else `settings.certificates.defaultTemplateId`, else the default template
(setting a default template updates the setting too). Working-towards records for active enrollments
without a certificate: course progress (required 100, or `completionPercent` under the percentage rule),
assignments passed (when the course has published assignments), final score vs `minScore` (when the
course has scored work); the course page shows the same record, or the issued certificate.

## 7. Permissions
Admin writes; instructors read their courses' certificates; learners own rows only; verify is public.

## 8. Backend Status
✅ list/detail/issue/revoke/restore/templates/verify/claim · ✅ scope + learner ownership (F2) · ✅ creation on completion, credential id / score / hours / template from settings, working-towards records, notifications, verification rules (F9).

## 9. Frontend Integration
`services/http/certificates.ts`, `learning.ts`; wired.

## 10. Testing
`routes/certificates.test.ts` — completion creates a pending certificate (id pattern, score, hours,
notification), pending never verifies, claim → issued → verification counted; autoIssue; disabled
setting and minScore block creation; working-towards criteria; revoke (reason, notification), verify
revoked, restore, issue/restore state guards, publicVerification off. Ownership in `permissions.test.ts`.

## 11. Completion
- [x] Admin routes + verify
- [x] Creation rules + ownership
- [x] Tests
