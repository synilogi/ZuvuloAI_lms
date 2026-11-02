-- AlterTable
ALTER TABLE "NotificationSettings" ADD COLUMN "lastDigestAt" DATETIME;

-- AlterTable
ALTER TABLE "Student" ADD COLUMN "nudgedAt" DATETIME;

-- AlterTable
ALTER TABLE "Submission" ADD COLUMN "overdueNotifiedAt" DATETIME;
