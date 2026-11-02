-- CreateTable
CREATE TABLE "Inquiry" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "tenantId" TEXT,
    "kind" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'new',
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "organisation" TEXT,
    "phone" TEXT,
    "size" TEXT,
    "subject" TEXT,
    "message" TEXT NOT NULL,
    "userId" TEXT,
    "note" TEXT,
    "handledById" TEXT,
    "closedAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    CONSTRAINT "Inquiry_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "Tenant" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "Inquiry_tenantId_idx" ON "Inquiry"("tenantId");

-- CreateIndex
CREATE INDEX "Inquiry_status_createdAt_idx" ON "Inquiry"("status", "createdAt");

-- A request to the platform team is part of the record: it is closed, never deleted.
CREATE TRIGGER "Inquiry_no_delete" BEFORE DELETE ON "Inquiry"
BEGIN
  SELECT RAISE(ABORT, 'An inquiry is kept on the record: close it instead.');
END;
