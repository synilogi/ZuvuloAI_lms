-- SAAS-014 · Audit & Observability (subscriptions.md §36).
--
-- The audit trail names who did something: a person, or — for what no person did — the scheduler
-- (`system`, with the job) or the payment provider (`provider`, with the provider). Existing rows were all
-- written for people, so they take `user`. Columns are added in place so the table keeps its rows.

ALTER TABLE "AuditLog" ADD COLUMN "actorType" TEXT NOT NULL DEFAULT 'user';
ALTER TABLE "AuditLog" ADD COLUMN "source" TEXT;

CREATE INDEX "AuditLog_action_idx" ON "AuditLog"("action");

-- A person has no source; a system or provider event has one and names no person.
CREATE TRIGGER "AuditLog_actor_shape"
BEFORE INSERT ON "AuditLog"
FOR EACH ROW
WHEN NEW."actorType" NOT IN ('user', 'system', 'provider')
  OR (NEW."actorType" = 'user' AND NEW."source" IS NOT NULL)
  OR (NEW."actorType" <> 'user' AND (NEW."source" IS NULL OR trim(NEW."source") = '' OR NEW."actorId" IS NOT NULL))
BEGIN
  SELECT RAISE(ABORT, 'AuditLog: a person has no source; a system or provider event names its source and no person');
END;

-- The trail is append-only. The one update allowed is the foreign key clearing actorId when the account
-- it names is removed (ON DELETE SET NULL) — every other column must stay as written.
CREATE TRIGGER "AuditLog_append_only_update"
BEFORE UPDATE ON "AuditLog"
FOR EACH ROW
WHEN NOT (
  NEW."actorId" IS NULL AND OLD."actorId" IS NOT NULL
  AND NEW."id" = OLD."id"
  AND NEW."actorEmail" = OLD."actorEmail"
  AND NEW."actorRole" = OLD."actorRole"
  AND NEW."actorType" = OLD."actorType"
  AND NEW."source" IS OLD."source"
  AND NEW."action" = OLD."action"
  AND NEW."targetType" = OLD."targetType"
  AND NEW."targetId" IS OLD."targetId"
  AND NEW."metaJson" = OLD."metaJson"
  AND NEW."createdAt" = OLD."createdAt"
)
BEGIN
  SELECT RAISE(ABORT, 'AuditLog is append-only');
END;

CREATE TRIGGER "AuditLog_append_only_delete"
BEFORE DELETE ON "AuditLog"
FOR EACH ROW
BEGIN
  SELECT RAISE(ABORT, 'AuditLog is append-only');
END;
