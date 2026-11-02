# Module — Courses

Status: **COMPLETED** (phase F5) · Depends on: Categories, Instructors

## 1. Purpose
Course lifecycle for staff: create draft, edit identity/cover/description/instructors/outcomes/pricing,
publish, unpublish, archive, restore, stats.

## 2. Existing UI
`/:base/courses` (list, filters), `/:base/courses/new`, `/:base/courses/:id/edit`,
`/:base/courses/:id` (overview), `/:base/courses/:id/preview`; public `/courses` + `/courses/:slug`.

## 3. UI Data Requirements
`Course` (domain shape with chapters/lessons nested, `instructors[]`, `category`, `level`, `outcomes[]`,
`price`, `enrolledCount`, `rating`, `status`, `publishedAt`, `certificateTemplateId`); `CourseStats`
(enrollments, active, completion, revenue display, recent activity); `publishChecklist` result.

## 4. Database
`Course` (slug unique, title, subtitle, description, categoryId FK, levelId FK, status, price, thumbnail,
outcomesJson, enrolledCount, rating, ratingCount, publishedAt, certificateTemplateId, timestamps) ·
`CourseInstructor`.

## 5. API
| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/courses` | admin, instructor | instructor: only own courses (F2) |
| GET | `/courses/:id` | admin, instructor (own) | full course |
| GET | `/courses/:id/stats` | admin, instructor (own) | |
| POST | `/courses` | admin, instructor | schema-validated (400); creates a draft; academy defaults for format/visibility/language; instructor is always added; 409 duplicate title or too many instructors |
| PATCH | `/courses/:id` | admin, instructor (own) | field-by-field copy |
| POST | `/courses/:id/publish` | admin, instructor (own) | 403 for instructors while `settings.courses.requireReview` is on; 409 with checklist issues |
| POST | `/courses/:id/unpublish` `/archive` `/restore` | admin, instructor (own) | |
| POST | `/courses/:id/reorder-chapters` | admin, instructor (own) | `{ chapterIds }` |
| GET | `/catalog/courses`, `/catalog/courses/:slug` | public | published only |

## 6. Business Rules
`publishChecklist`; unique title (case-insensitive); ≤ `settings.courses.maxInstructors` instructors;
`settings.courses.requireReview` blocks instructor publishing; `settings.courses.defaultFormat`,
`general.defaultVisibility` and `general.language` fill blanks on create; archived/draft courses hidden from
the catalog; lesson bodies never leave the API for non-enrolled viewers (F2).

## 7. Permissions
Admin: all courses. Instructor: courses where they are lead or co-instructor. Students: public catalog only.

## 8. Backend Status
✅ lifecycle + stats · ✅ instructor scope (F2) · ✅ unique title / maxInstructors / requireReview / defaults / validation (F5).

## 9. Frontend Integration
`services/http/courses.ts`, `catalog.ts`; wired. The command palette searches the published catalog
(courses and lessons) in http mode and navigates to the course or lesson.

## 10. Testing
`routes/catalog.test.ts` — defaults from settings, duplicate title 409 (create + rename), validation 400,
maxInstructors 409, requireReview 403 then allowed; `permissions.test.ts` — scope, self-assignment, drafts hidden.

## 11. Completion
- [x] Lifecycle routes
- [x] Settings-driven rules
- [x] Scope + validation + tests

## 12. Cover images and course sales (October 2026)

- **Cover image (9 Oct 2026):** `Course.coverImageId` references an uploaded `MediaAsset` (image kind, `POST /media/upload`);
  the course editor sets it and the public catalogue, course page and app show it. Deleting the asset sets it null.
  `courseCover.test.ts`.
- **Price and sale (24 Oct 2026):** `price` is whole rupees, all-inclusive. A course with an admin-chosen price is for sale
  to its academy's learners once the academy has enabled its own Razorpay account under its payment settings
  (`/tenant/course-sales/*`); a learner buys it with `POST /learning/courses/:courseId/purchase`, and the enrolment opens
  only on the gateway's confirmation. A course with no price enrols free as before. Rules and endpoints:
  `05-API-SPECIFICATION.md` › Course sales; tables: `03-DATABASE-SPECIFICATION.md` › Course sales; tests:
  `coursePurchases.test.ts`, `e2e/coursePurchase.spec.ts`. Course checkout is off in the mobile app on `zuviloai.com`.
