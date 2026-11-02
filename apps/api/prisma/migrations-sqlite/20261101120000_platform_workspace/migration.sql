-- The platform conversion (docs/16 §3.2). Additive only: nothing is dropped, and every existing row keeps its values.

-- A learner's mobile number, asked for at registration. Not unique: the email is what identifies an account.
ALTER TABLE "User" ADD COLUMN "phone" TEXT;

-- An instructor's application: title, bio, expertise, experience and phone already have columns.
ALTER TABLE "Instructor" ADD COLUMN "linksJson" TEXT NOT NULL DEFAULT '[]';

-- What a registration holds until its emailed code is confirmed.
ALTER TABLE "PendingAccount" ADD COLUMN "phone" TEXT;
ALTER TABLE "PendingAccount" ADD COLUMN "profileJson" TEXT;
