-- SAAS-010 · Webhooks & Idempotency (subscriptions.md §17, §18).
--
-- One row per provider event: the receipt, and the idempotency key (provider + providerEventId). What an
-- event is never changes; only its processing state moves, and a processed or ignored event is final.

-- CreateTable
CREATE TABLE "WebhookEvent" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "provider" TEXT NOT NULL,
    "providerEventId" TEXT NOT NULL CHECK (length("providerEventId") BETWEEN 1 AND 128),
    "eventType" TEXT NOT NULL,
    "payloadHash" TEXT NOT NULL CHECK (length("payloadHash") = 64),
    "referenceJson" TEXT NOT NULL DEFAULT '{}',
    "status" TEXT NOT NULL DEFAULT 'received' CHECK ("status" IN ('received', 'processed', 'ignored', 'failed')),
    "attempts" INTEGER NOT NULL DEFAULT 1 CHECK (typeof("attempts") = 'integer' AND "attempts" >= 1),
    "note" TEXT,
    "receivedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" DATETIME
);

-- CreateIndex
CREATE INDEX "WebhookEvent_provider_payloadHash_idx" ON "WebhookEvent"("provider", "payloadHash");

-- CreateIndex
CREATE INDEX "WebhookEvent_status_receivedAt_idx" ON "WebhookEvent"("status", "receivedAt");

-- CreateIndex
CREATE UNIQUE INDEX "WebhookEvent_provider_providerEventId_key" ON "WebhookEvent"("provider", "providerEventId");

-- The receipt is fixed: which event, from whom, of what kind, with what body, received when. Processing may
-- move received/failed onward — a failed event is retried — but a processed or ignored event is final.
CREATE TRIGGER "WebhookEvent_receipt"
BEFORE UPDATE ON "WebhookEvent"
FOR EACH ROW
WHEN NEW."id" <> OLD."id"
  OR NEW."provider" <> OLD."provider"
  OR NEW."providerEventId" <> OLD."providerEventId"
  OR NEW."eventType" <> OLD."eventType"
  OR NEW."payloadHash" <> OLD."payloadHash"
  OR NEW."receivedAt" <> OLD."receivedAt"
  OR OLD."status" IN ('processed', 'ignored')
  OR NEW."attempts" < OLD."attempts"
BEGIN
  SELECT RAISE(ABORT, 'WebhookEvent: the receipt is fixed, and a processed or ignored event is final');
END;

CREATE TRIGGER "WebhookEvent_no_delete"
BEFORE DELETE ON "WebhookEvent"
FOR EACH ROW
BEGIN
  SELECT RAISE(ABORT, 'WebhookEvent: never deleted');
END;
