# Module — Dashboard

Status: **COMPLETED** (phase F15) · Depends on: Reports, Live, Assignments, Students

## 1. Purpose
Landing overview for admin (`/admin`) and instructor (`/teach`): KPIs, trends, upcoming events, attention
items, recent activity.

## 2. Existing UI
`pages/lms/dashboard/*` (KPI cards, trend chart, events list, attention list, activity feed).

## 3. UI Data Requirements
`Dashboard { kpis, trends[], events[], attention[], activity[], liveAttendance }`.

## 4. Database
Aggregation only.

## 5. API
`GET /dashboard` — admin (academy), instructor (own courses).

## 6. Business Rules
Attention items: overdue reviews (high), at-risk learners, nearly full classes (≥ 90 %), stale drafts
(> 6 weeks), videos without captions. Events = next 7 days of live classes and deadlines. Live attendance
= attended / registered over the last 30 days.

## 7. Permissions
Admin; instructor scoped.

## 8. Backend Status
✅ KPIs/trends · ✅ instructor scope (F2) · 🟨 events placeholder, attendance 0, attention partial · ⬜ tests.

## 9. Frontend Integration
`services/http/dashboard.ts`; wired.

## 10. Testing
`dashboard.test.ts` — seeded data yields events/attention; instructor scope.

## 11. Completion
- [x] Route
- [ ] Real events/attention/attendance
- [ ] Tests
