# Module — Curriculum (chapters)

Status: **COMPLETED** (phase F5) · Depends on: Courses

## 1. Purpose
Chapters inside a course: create, edit, duplicate, delete, move; chapter stats and publish status.

## 2. Existing UI
`/:base/courses/:id/curriculum` (chapter list with drag-order, panels), `/:base/courses/:id/chapters/:chapterId`
(chapter overview). Files: `pages/lms/courses/curriculum/*`, `pages/lms/chapters/*`.

## 3. UI Data Requirements
`Chapter { id, courseId, title, summary, position, status draft|published, lessons[] }`;
`ChapterStats` (per chapter: lessons, published, minutes, quiz/assignment presence).

## 4. Database
`Chapter` (courseId FK, title, summary, position, status, timestamps; index (courseId, position)).

## 5. API (mounted at `/courses/:courseId/chapters`)
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/stats` | admin, instructor (own course) |
| POST | `/` | same — `{ input: { title, summary?, objective?, status?, estimatedMin? }, position? }` (400 on shape) |
| PATCH | `/:chapterId` | same — chapter must belong to the course (404) |
| POST | `/:chapterId/duplicate` | same — copies lessons |
| DELETE | `/:chapterId` | same — deletes lessons + progress |
| POST | `/:chapterId/move` | same — `{ direction | position }` |

## 6. Business Rules
Positions stay contiguous; a chapter is published only with ≥ 1 published lesson; deleting a chapter
removes its lessons and lesson progress (transaction).

## 7. Permissions
Admin, or instructor of the parent course (F2).

## 8. Backend Status
✅ complete · ✅ scope check at the router mount (F2) · ✅ validation + course ownership of chapter ids (F5).

## 9. Frontend Integration
`services/http/chapters.ts`; wired.

## 10. Testing
`routes/catalog.test.ts` — validation 400, insert at position, move, contiguous positions, foreign chapter 404; scope in `permissions.test.ts`.

## 11. Completion
- [x] Routes
- [x] Scope + validation + tests
