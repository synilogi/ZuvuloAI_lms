# Sample education catalogue and course-data reset

> **Since 1 Nov 2026 the product is one centralized learning platform, not multi-tenant SaaS.** Where this document describes academies, plans, subscriptions, invoices or per-academy gateways, [`16-PLATFORM-CONVERSION.md`](16-PLATFORM-CONVERSION.md) is the current account and this text is history.

Two operator scripts in `apps/api`:

| Script | What it does |
| --- | --- |
| `npm run data:clear-courses` | Deletes course and learning data. Keeps every account. Dry run by default. |
| `npm run seed:education` | Adds 13 sample school and competitive-exam courses to one academy. Never deletes anything. |

Both refuse to run unless `NODE_ENV` is `development`, `staging`, or `production`. Production also
requires `--production` on the command line.

## Clearing course data

```bash
cd apps/api
npm run data:clear-courses -- --academy default                                   # dry run: counts only
CLEAR_COURSE_DATA=yes npm run data:clear-courses -- --academy default --apply     # backup, then delete
```

Without `--academy`, the script resets **every** academy. You can repeat `--academy` to name several.

- **Deleted:** categories and levels; courses and their curriculum; quizzes and attempts; assignments,
  drafts and submissions; enrolments and progress; notes, bookmarks and saved courses; issued
  certificates; live classes and registrations; calendar events tied to a course; learning
  notifications; course files (the `MediaAsset` rows only — the files stay on disk); and instructor
  profiles that have no login.
- **Kept:** academies; users and passwords; learner profiles; instructors who have a login; admin
  permissions; ranks; certificate templates; settings; subscriptions and all billing rows;
  invitations; inquiries; system notifications; the email outbox (held mail stays held); and the
  audit trail.
- **Safety:** before deleting, the script writes `backups/before-course-clear-<db>-<stamp>.db` (a name `db:backup` rotation never prunes) with
  `VACUUM INTO`, next to the database. It never prunes older backups. All deletes run in one
  transaction. After the run, it checks that the counts of academies, users, learners and outbox
  messages are unchanged.
- **Rollback:** stop the API, copy the backup over the database, and start the API again.

## Sample catalogue

```bash
npm run seed:education -- --dry-run
npm run seed:education                                                      # into the `default` academy
npm run seed:education -- --academy <slug>
npm run seed:education -- --demo-student ananya@syniastrolms.test           # + learner activity (dev/staging only)
```

The catalogue goes into one existing academy:

- 5 categories: Rajasthan State Exams, Central Exams & General Studies, Reasoning & Maths,
  Class 9–10, and Class 11–12.
- 13 courses:
  - RAS Prelims
  - Rajasthan GK
  - Indian Polity
  - SSC GD
  - Reasoning
  - Quantitative Aptitude
  - REET Level 2 pedagogy
  - Rajasthan Patwari
  - Class 10 Maths
  - Class 10 Science
  - Class 12 Physics
  - Class 11–12 Chemistry
  - English Grammar
- The exam courses have bilingual Hindi and English titles.
- Content: 64 lessons, 13 tests and 3 assignments.
- Media: 4 playable slide lectures, 4 PDF notes, and 13 licensed cover images
  (`apps/api/prisma/demo-assets/education/CREDITS.md`).

All the text is original. Nothing is copied from Utkarsh or any other coaching app. Each faculty
profile is a subject team ("Rajasthan GK Faculty"), not an invented person, so an admin can rename it
or replace it with real teachers. Courses have no ratings, and enrolment counts reflect real
enrolments only. Prices are display-only: enrolment is free.

The seed never creates or changes an account. `--demo-student` writes learner activity for that one
learner: enrolments, progress, a passed test, live classes and notifications. It accepts only a
`.test` account, and refuses to run in production, so real learners never see fabricated progress or
classes that won't happen.

Every row has a fixed `edu-` id and is written with an upsert, so re-running the seed adds nothing.
The tests cover this table by table: `apps/api/src/routes/educationCatalog.test.ts` and
`apps/mobile/test/contract/education_demo_test.dart`.

## Running on the server (not yet deployed)

The scripts reach the server through a normal deploy. Until then, the one-off run uploads them to a
temporary folder whose `src` and `node_modules` link to the live checkout, and runs them with the live
`.env`. Afterwards, remove the folder. The API keeps running throughout. The planned live
run uses `--academy default` for both scripts and no `--demo-student`.
