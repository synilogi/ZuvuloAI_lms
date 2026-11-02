# Module — Lessons & media

Status: **COMPLETED** (phase F5) · Depends on: Curriculum

## 1. Purpose
Lessons of every type (video, reading, document, quiz/assessment, practice/assignment, live) with content,
settings (free preview, completion rule, duration), publish validation, and file uploads.

## 2. Existing UI
`/:base/courses/:id/lessons` (list), lesson editor `/:base/courses/:id/lessons/:lessonId` (Content,
Settings, Preview tabs) with `MediaDrop` uploads. Files: `pages/lms/lessons/*`, `components/forms/Upload.tsx`.

## 3. UI Data Requirements
`Lesson { id, chapterId, title, type, status, duration, freePreview, completion, content }` where
`content` is typed per lesson type (`video.file: MediaFile`, `reading.body`, `document.file`,
`quiz { quizId, questionCount, passMark, attempts }`, `assignment { assignmentId, brief, maxScore }`,
`live { liveClassId }`); `MediaFile { name, sizeMb, id?, url?, mime? }` — `url` is the API path `/media/<id>`.

## 4. Database
`Lesson` (chapterId FK, courseId FK, title, type, status, position, durationMin, isPreview,
description, objectivesJson, contentJson, settingsJson, updatedAt). `MediaAsset` (ownerUserId, kind
video|document|image, originalName, mime, sizeBytes, storageName unique, createdAt); files live under
`UPLOAD_DIR` (default `apps/api/uploads`, git-ignored) with random names.

## 5. API (mounted at `/courses/:courseId/lessons`)
| Method | Path | Auth |
| --- | --- | --- |
| GET | `/` · `/:lessonId` | admin, instructor (own course) |
| POST | `/` | same — `{ chapterId, input: LessonInput, position? }` (400 on shape); academy defaults for `durationMin` and first-lesson preview |
| PATCH | `/:lessonId` | same — content/settings; publishing runs `lessonPublishIssues`; changing the type releases a linked quiz/assignment |
| POST | `/:lessonId/move` · `/:lessonId/duplicate` | same — a copy never claims the original's quiz/assignment |
| DELETE | `/:lessonId` | same — the linked quiz/assignment is kept, unlinked |
| POST | `/media/upload` (top-level) | any signed-in account — multipart field `file`; returns `MediaFile` |
| GET | `/media/:id` | any signed-in account — streams with `Content-Disposition` + nosniff; Range supported |

## 6. Business Rules
`lessonPublishIssues`; `content.quiz` / `content.assignment` are refreshed from the record whose
`lessonId` points at the lesson every time a lesson is read (`lib/lessonLinks.ts`), so the builder and
editor stay the source of truth; a quiz/assignment is linked by creating it with `lessonId` (the editor's
"Build the quiz" / "Write the full assignment" links carry `&lesson=`); only an assessment lesson can
deliver a quiz and only an assignment/practice lesson an assignment, one each; delivered records cannot be
deleted (409); deleting a lesson or changing its type releases the link. Uploads: MIME + extension
allow-list (mp4/webm/mov, pdf, png/jpg/webp), 500 MB / 25 MB / 5 MB, random storage names, 400/413 on
rejection.

## 7. Permissions
Staff of the course. Learners read lessons only through `/learning/*` with enrollment checks (F2/F6).

## 8. Backend Status
✅ CRUD + publish validation · ✅ scope (F2) · ✅ mirroring, link rules, delete guards, real uploads + streaming, validation, defaults (F5).

## 9. Frontend Integration
`services/http/lessons.ts`; `services.media.upload(file, onProgress)` in the contracts (`http/media.ts` =
XMLHttpRequest multipart with progress, `mock/media.ts` = simulated); `MediaDrop` calls it and shows
upload errors inline; quiz/assignment editors accept `?lesson=` and send `lessonId` on create. The learner
video player stays the designed simulated player (uploaded files are stored and streamable; playing them
in the player is a product decision, see REMAINING ITEMS).

## 10. Testing
`routes/catalog.test.ts` — defaults, publish refused with issues, quiz linked via `lessonId` and mirrored,
duplicate/wrong-type link 409, delete guard 409, type change releases, assignment link + release on lesson
delete; uploads accepted/streamed/401, rejected by type/extension/size (400/413).

## 11. Completion
- [x] CRUD + publish validation
- [x] Upload endpoint + MediaDrop
- [x] Mirroring, scope, validation, tests
