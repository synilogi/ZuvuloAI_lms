-- SAAS-003 · The basic-reports feature does not gate the dashboard (the admin's home), so its catalogue
-- description no longer says it does. Mirrors packages/domain/src/entitlement.ts; a label edit only.
UPDATE "Feature" SET "description" = 'The course, learner and enrolment reports.' WHERE "id" = 'reports.basic';
