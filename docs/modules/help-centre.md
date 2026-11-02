# Module — Help centre

Status: **COMPLETED** (F19) · Depends on: —

## 1. Purpose
Knowledge base for learners, instructors, admins and the public support site.

## 2. Existing UI
`/help`, `/help/:category`, `/help/:category/:article` (per role), public `/support/*`.

## 3. UI Data Requirements
`HelpCategory { slug, title, description, audience[], articleCount }`; `HelpArticle { slug, title, body
(markdown), audience, updatedAt, related[] }`.

## 4. Database
`HelpCategory`, `HelpArticle` (categoryId FK, slug unique, audiencesJson, body, updatedAt).

## 5. API
`GET /help/categories?audience=`, `GET /help/articles?category=&q=`, `GET /help/articles/:slug` — public,
filtered by audience (anonymous → public).

## 6. Business Rules
Audience filtering; markdown rendered by the safe client renderer (no raw HTML).

## 7. Permissions
Public read; content managed by seed (no editing UI exists).

## 8. Backend Status
✅ complete · ⬜ tests.

## 9. Frontend Integration
`services/http/help.ts`; wired.

## 10. Testing
`help.test.ts` — audience filtering; unknown slug 404; search.

## 11. Completion
- [x] Routes
- [ ] Tests
