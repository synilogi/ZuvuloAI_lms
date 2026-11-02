# Module — Categories

Status: **COMPLETED** (phase F5) · Depends on: —

## 1. Purpose
Course taxonomy shown on the catalog and used for filtering and reports.

## 2. Existing UI
`/admin/categories` (list + detail panel + create/edit panel). Files: `pages/lms/categories/*`.

## 3. UI Data Requirements
`Category { id, slug, name, description, status active|hidden, courseCount, levels[] }`; detail returns the
category with its courses.

## 4. Database
`Category` (slug unique, name, description, status, position) · `CategoryLevel` (categoryId+levelId).

## 5. API
| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/categories` | admin, instructor | with course counts |
| GET | `/categories/:id` | admin, instructor | with courses |
| POST | `/categories` | admin | `{ name, description, glyph, status, levelIds, order? }` (schema-validated → 400); 409 on a duplicate name (case-insensitive) |
| PATCH | `/categories/:id` | admin | same fields, partial |
| DELETE | `/categories/:id?moveCoursesTo=` | admin | 409 while courses use it and no valid destination is given; otherwise moves them and returns `{ moved }` |

## 6. Business Rules
Unique name (case-insensitive); a category with courses can only be deleted by moving them to another
category; hidden categories are excluded from the public catalog.

## 7. Permissions
Admin writes; instructors read; students use `/catalog/categories` (public) instead.

## 8. Backend Status
✅ complete incl. validation, uniqueness and guarded delete (F5).

## 9. Frontend Integration
`services/http/categories.ts`; wired.

## 10. Testing
`routes/catalog.test.ts` — validation 400, create, duplicate 409, delete-with-courses 409 then move; instructor write 403 in `permissions.test.ts`.

## 11. Completion
- [x] CRUD
- [x] Validation + tests
