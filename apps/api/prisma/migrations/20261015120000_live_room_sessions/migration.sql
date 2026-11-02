-- The built-in live room: the host starts and ends a class, attendance is taken on join. Additive: existing
-- classes keep null start/end/room and existing registrations a null join time.
ALTER TABLE "LiveClass" ADD COLUMN "startedAt" DATETIME;
ALTER TABLE "LiveClass" ADD COLUMN "endedAt" DATETIME;
ALTER TABLE "LiveClass" ADD COLUMN "roomName" TEXT;
ALTER TABLE "LiveRegistration" ADD COLUMN "joinedAt" DATETIME;

-- CreateIndex
CREATE UNIQUE INDEX "LiveClass_roomName_key" ON "LiveClass"("roomName");
