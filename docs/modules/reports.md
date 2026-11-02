# Module — Reports

Status: **COMPLETED** (phase F14) · Depends on: all data modules

## 1. Purpose
Analytics for staff over a selectable period compared with the previous equal period.

## 2. Existing UI
`/admin/reports` (overview), `/courses`, `/courses/:courseId`, `/learners`, `/instructors`, `/enrolments`.
Files: `pages/lms/reports/*`.

## 3. UI Data Requirements
`ReportKpi { value, previous }`, `ReportPoint { from, to, value }[]` series, tables per report
(courses: enrollments, completion, passRate, rating; course: funnel, per-chapter drop-off, quiz pass rates,
assignment stats; learners: segments, cohorts, cities; instructors: per-instructor figures; enrolments: by
source, by category).

## 4. Database
Read-only aggregation over enrollments, lesson progress, quiz attempts, submissions, certificates,
live registrations.

## 5. API
`GET /reports/overview|courses|courses/:courseId|learners|instructors|enrolments?range=30d|90d|12m`
— admin (all), instructor (own courses only).

## 6. Business Rules
`reportWindow`, `reportBuckets`, `completionRate`, `percentOf`, `median`; every KPI has a real previous
value; instructor scope filters every query.

## 7. Permissions
Admin; instructor scoped.

## 8. Backend Status
✅ routes + shapes · ✅ instructor scope (F2) · 🟨 many figures 0/null/[] · ⬜ tests.

## 9. Frontend Integration
`services/http/reports.ts`; wired.

## 10. Testing
`reports.test.ts` — each report returns non-zero seeded figures; previous period differs; instructor scope.

## 11. Completion
- [x] Routes
- [ ] Real figures
- [ ] Tests
