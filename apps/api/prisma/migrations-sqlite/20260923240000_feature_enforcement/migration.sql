-- SAAS-025: how each catalogue feature is delivered. Additive: one defaulted column, and the two features that no
-- route gates are marked for what they are — a service level, and a capability sold but not built yet.
ALTER TABLE "Feature" ADD COLUMN "enforcement" TEXT NOT NULL DEFAULT 'route';
UPDATE "Feature" SET "enforcement" = 'service' WHERE "id" = 'priority_support';
UPDATE "Feature" SET "enforcement" = 'planned' WHERE "id" = 'analytics.advanced';
