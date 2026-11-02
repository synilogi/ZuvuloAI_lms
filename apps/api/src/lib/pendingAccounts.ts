import { hashPassword } from './auth.js';
import { normaliseAffiliateCode, type MlmLeg } from '@syniastrolms/domain';
import { assertReferralUsable } from './mlm/affiliates.js';
import { db } from './db.js';
import { ApiError, conflict } from './errors.js';
import { assertInstructorEmailFree, createInstructorRequest, instructorWorkspaceAt, type InstructorProfileInput } from './instructorRequests.js';
import { readJson, writeJson } from './json.js';
import { consumeInvitation, courseAt, releaseInvitation, usableInvitation } from './invitations.js';
import { assertSelfRegistrationOpen, createLearner, openWorkspaceAt } from './learners.js';
import { queueEmail } from './mail.js';
import { deliverQueuedEmail } from './mailDelivery.js';
import { workspaceId } from './requestContext.js';
import { getSettings } from './settings.js';
import { currentTenantId, runAsPlatform, runInTenant, tenant } from './tenancy.js';
import { testOtpMatches } from './testOtp.js';
import { CODE_MAX_ATTEMPTS, CODE_MAX_SENDS, CODE_TTL_MS, codeMatches, hashCode, newCode, resendAvailableAt } from './verificationCode.js';

/*
 * Learners and instructors who register themselves verify their email first. Every door a visitor can register
 * through — the academy's join link, an invitation, a course link, the host's own sign-up, and an instructor's request
 * to teach — is checked as before (the academy is the link's, open, taking learners; the address is free), and then
 * held as a `PendingAccount` in that academy, with the password hashed and a 6-digit code emailed. Nothing that can
 * sign in exists, and no seat on the plan is taken, until the right code arrives in time and within its attempts;
 * then the account is made through the same path the door always used, and every rule is checked again, since the
 * academy, the invitation or the address may have changed while the code was waiting.
 *
 * The academy, the role, the invitation and the course are fixed on the row by the server when it is made, and a
 * database trigger keeps the academy, role and address from changing; the request that confirms the code names only
 * the row and the code.
 *
 * `SIGNUP_EMAIL_VERIFICATION=off` (lib/registration.ts) turns this off — only for a deployment with no email delivery.
 */

const PURPOSE = 'account';

export type PendingRole = 'student' | 'instructor';

interface Door {
  tenantId: string;
  lms: string;
  role: PendingRole;
  invitationId?: string;
  courseId?: string;
}

export interface RegistrationInput {
  name: string;
  email: string;
  password: string;
  title?: string;
  phone?: string;
  /** An instructor's application (docs/16 §2.5), held with the registration until the code is confirmed. */
  profile?: InstructorProfileInput;
  /** An affiliate referral (MLM-001): checked when the door opens, carried to the account when the code is confirmed. */
  referralCode?: string;
  preferredLeg?: MlmLeg;
  requestedLeg?: MlmLeg;
}

export interface VerificationView {
  status: 'verify';
  verificationId: string;
  email: string;
  role: PendingRole;
  lms: string;
  expiresAt: string;
  resendAvailableAt: string;
}

const failure = (status: number, message: string, field?: string) =>
  new ApiError(status, message, field ? [{ field, message }] : undefined, 'VERIFICATION_FAILED');

const CLOSED = () => failure(404, 'This registration is no longer open. Start again.');

const TAKEN = 'An account with this email already exists.';

const lmsName = async () => (await getSettings()).general.academyName;

async function emailFree(email: string, role: PendingRole) {
  if (role === 'instructor') return assertInstructorEmailFree(email);
  const taken = await runAsPlatform('an email address is unique across the platform (D2)', () =>
    db.user.findUnique({ where: { email }, select: { id: true } }),
  );
  if (taken) throw conflict(TAKEN, [{ field: 'email', message: TAKEN }]);
}

async function sendCode(row: { email: string; name: string; role: string }, lms: string, code: string) {
  // In the academy's context, so the email is signed with its name.
  await queueEmail({
    to: row.email,
    name: row.name,
    subject: `${code} is your ${lms} verification code`,
    templateKey: 'account-verification',
    text: [
      `Hi ${row.name.split(' ')[0]},`,
      '',
      `Use this code to verify your email and finish ${row.role === 'instructor' ? 'your application to teach on' : 'joining'} ${lms}:`,
      '',
      code,
      '',
      `It expires in ${CODE_TTL_MS / 60_000} minutes. If you did not ask for this, ignore this email — no account is created without the code.`,
    ].join('\n'),
  });
  // The registrant is waiting for it: deliver now rather than on the scheduler's next tick (claimed per message).
  void deliverQueuedEmail().catch(() => undefined);
}

const view = (row: { id: string; email: string; role: string; expiresAt: Date; lastSentAt: Date }, lms: string): VerificationView => ({
  status: 'verify',
  verificationId: row.id,
  email: row.email,
  role: row.role as PendingRole,
  lms,
  expiresAt: row.expiresAt.toISOString(),
  resendAvailableAt: resendAvailableAt(row.lastSentAt),
});

/** Holds the registration in the door's academy and emails its code. */
async function begin(door: Door, input: RegistrationInput): Promise<VerificationView> {
  const email = input.email.trim().toLowerCase();
  await emailFree(email, door.role);
  if (door.role === 'student') await assertReferralUsable(door.tenantId, input.referralCode);
  const passwordHash = await hashPassword(input.password);
  return runInTenant(door.tenantId, async () => {
    const now = Date.now();
    // A new start for the same address in this academy replaces what was pending: only the latest code confirms it.
    await db.pendingAccount.deleteMany({ where: { email, consumedAt: null } });
    const row = await db.pendingAccount.create({
      data: {
        ...tenant(),
        role: door.role,
        email,
        name: input.name.trim(),
        title: input.title?.trim() || null,
        phone: input.phone?.trim() || null,
        profileJson: input.profile ? writeJson(input.profile) : null,
        passwordHash,
        codeHash: 'pending',
        expiresAt: new Date(now + CODE_TTL_MS),
        lastSentAt: new Date(now),
        invitationId: door.invitationId ?? null,
        courseId: door.courseId ?? null,
        referralCode: door.role === 'student' && input.referralCode ? normaliseAffiliateCode(input.referralCode) : null,
        preferredLeg: door.role === 'student' ? (input.preferredLeg ?? null) : null,
        requestedLeg: door.role === 'student' && input.referralCode ? (input.requestedLeg ?? null) : null,
      },
    });
    const code = newCode();
    await db.pendingAccount.update({ where: { id: row.id }, data: { codeHash: hashCode(PURPOSE, row.id, code) } });
    await sendCode(row, door.lms, code);
    return view(row, door.lms);
  });
}

/* ─── The doors ────────────────────────────────────────────────────────── */

/** A learner through the academy's join link (`/join/<slug>`). */
export async function startJoinRegistration(slug: string, input: RegistrationInput) {
  const workspace = await openWorkspaceAt(slug);
  const lms = await runInTenant(workspace.id, async () => {
    await assertSelfRegistrationOpen();
    return (await lmsName()) || workspace.name;
  });
  return begin({ tenantId: workspace.id, lms, role: 'student' }, input);
}

/** A learner through the host's own sign-up (`POST /auth/register` with no workspace): the academy this request runs for. */
export async function startHostRegistration(input: RegistrationInput) {
  const tenantId = currentTenantId();
  const lms = await runInTenant(tenantId, async () => {
    await assertSelfRegistrationOpen();
    return lmsName();
  });
  return begin({ tenantId, lms, role: 'student' }, input);
}

/** A learner through an invitation (`/invite/<token>`): its academy, and its address when it names one. */
export async function startInvitationRegistration(token: string, input: RegistrationInput) {
  const invitation = await usableInvitation(token);
  if (invitation.tenant.status !== 'active')
    throw new ApiError(403, 'The platform isn’t accepting new learners right now. Contact support for help.', undefined, 'ACADEMY_SUSPENDED');
  if (invitation.email && invitation.email !== input.email.trim().toLowerCase())
    throw new ApiError(403, 'This invitation is for a different email address. Use the address it was sent to.');
  const lms = (await runInTenant(invitation.tenantId, lmsName)) || invitation.tenant.name;
  return begin({ tenantId: invitation.tenantId, lms, role: 'student', invitationId: invitation.id }, input);
}

/** A learner through a course link (`/courses/<id>/enroll`): the course's academy; enrolled once verified. */
export async function startCourseRegistration(courseId: string, input: RegistrationInput) {
  const course = await courseAt(courseId);
  if (course.tenant.status !== 'active')
    throw new ApiError(403, 'The platform isn’t accepting new learners right now. Contact support for help.', undefined, 'ACADEMY_SUSPENDED');
  const lms = await runInTenant(course.tenant.id, async () => {
    await assertSelfRegistrationOpen();
    return (await lmsName()) || course.tenant.name;
  });
  return begin({ tenantId: course.tenant.id, lms, role: 'student', courseId: course.id }, input);
}

/** An instructor asking to teach at the academy its join link names (D34): the request reaches the admin once verified. */
export async function startInstructorRegistration(slug: string, input: RegistrationInput) {
  const workspace = await instructorWorkspaceAt(slug);
  const lms = (await runInTenant(workspace.id, lmsName)) || workspace.name;
  return begin({ tenantId: workspace.id, lms, role: 'instructor' }, input);
}

/** An instructor applying on the website (`/teach/apply`): the request reaches the staff and the owner once verified. */
export async function startInstructorApplication(input: RegistrationInput) {
  const tenantId = await workspaceId();
  const lms = await runInTenant(tenantId, lmsName);
  return begin({ tenantId, lms, role: 'instructor' }, input);
}

/* ─── The code ─────────────────────────────────────────────────────────── */

/** An open registration by its id, wherever it lives — the id is a random cuid the registrant was given. */
async function openRow(id: string) {
  const row = await runAsPlatform('a registrant’s code names its own registration, which names its academy', () =>
    db.pendingAccount.findUnique({ where: { id } }),
  );
  if (!row || row.consumedAt) throw CLOSED();
  return row;
}

/** Where a registration stands, so a refreshed page can carry on at the code step. Never the code. */
export async function verificationStatus(id: string): Promise<VerificationView> {
  const row = await openRow(id);
  return runInTenant(row.tenantId, async () => view(row, await lmsName()));
}

export async function resendVerification(id: string): Promise<VerificationView> {
  const row = await openRow(id);
  const wait = new Date(resendAvailableAt(row.lastSentAt)).getTime() - Date.now();
  if (wait > 0) throw failure(429, `Wait ${Math.ceil(wait / 1000)} seconds before asking for another code.`);
  if (row.sendCount >= CODE_MAX_SENDS) throw failure(429, 'We have sent the most codes we can for this registration. Start again in a little while.');
  return runInTenant(row.tenantId, async () => {
    const code = newCode();
    const now = Date.now();
    // A new code starts a new count and a new expiry; the old code stops working.
    const updated = await db.pendingAccount.update({
      where: { id: row.id },
      data: {
        codeHash: hashCode(PURPOSE, row.id, code),
        attempts: 0,
        expiresAt: new Date(now + CODE_TTL_MS),
        lastSentAt: new Date(now),
        sendCount: { increment: 1 },
      },
    });
    const lms = await lmsName();
    await sendCode(updated, lms, code);
    return view(updated, lms);
  });
}

export type VerifiedAccount =
  { role: 'student'; tenantId: string; courseId: string | null; user: Awaited<ReturnType<typeof createLearner>> } | { role: 'instructor'; tenantId: string };

/** Confirms the code and creates the account, re-checking every rule its door checked. */
export async function confirmVerification(id: string, code: string): Promise<VerifiedAccount> {
  const row = await openRow(id);
  return runInTenant(row.tenantId, async () => {
    if (row.attempts >= CODE_MAX_ATTEMPTS) throw failure(429, 'Too many wrong codes. Ask for a new code.', 'code');
    if (row.expiresAt.getTime() <= Date.now()) throw failure(410, 'This code has expired. Ask for a new code.', 'code');
    // Every guess spends an attempt before it is compared, so concurrent guesses cannot get past the limit: one that
    // finds no attempt left is refused without being checked.
    const spent = await db.pendingAccount.updateMany({ where: { id: row.id, attempts: { lt: CODE_MAX_ATTEMPTS } }, data: { attempts: { increment: 1 } } });
    if (spent.count !== 1) throw failure(429, 'Too many wrong codes. Ask for a new code.', 'code');
    // The test account's static code (lib/testOtp.ts) is a fallback for development and staging only.
    if (!codeMatches(PURPOSE, row.id, code, row.codeHash) && !testOtpMatches(row.email, code)) {
      const left = CODE_MAX_ATTEMPTS - row.attempts - 1;
      throw failure(
        400,
        left > 0 ? `That code is not right. ${left} ${left === 1 ? 'try' : 'tries'} left.` : 'Too many wrong codes. Ask for a new code.',
        'code',
      );
    }

    // Claimed once: of two concurrent confirmations, only one gets the row.
    const claimed = await db.pendingAccount.updateMany({ where: { id: row.id, consumedAt: null }, data: { consumedAt: new Date() } });
    if (claimed.count !== 1) throw CLOSED();
    let invitationUsed = false;
    try {
      const academy = await runAsPlatform('a verified registration re-checks its academy', () =>
        db.tenant.findUniqueOrThrow({ where: { id: row.tenantId }, select: { id: true, name: true, status: true } }),
      );
      if (academy.status !== 'active')
        throw new ApiError(403, 'The platform isn’t accepting new members right now. Contact support for help.', undefined, 'ACADEMY_SUSPENDED');

      if (row.role === 'instructor') {
        const created = await createInstructorRequest(academy, {
          name: row.name,
          email: row.email,
          title: row.title,
          passwordHash: row.passwordHash,
          phone: row.phone,
          profile: readJson<InstructorProfileInput | null>(row.profileJson, null) ?? undefined,
        });
        await db.pendingAccount.update({ where: { id: row.id }, data: { createdUserId: created.userId } });
        return { role: 'instructor', tenantId: row.tenantId };
      }

      if (row.invitationId) {
        await consumeInvitation(row.invitationId);
        invitationUsed = true;
      } else {
        await assertSelfRegistrationOpen();
      }
      const user = await createLearner({
        name: row.name,
        email: row.email,
        passwordHash: row.passwordHash,
        phone: row.phone ?? undefined,
        referralCode: row.referralCode ?? undefined,
        preferredLeg: (row.preferredLeg as MlmLeg | null) ?? undefined,
        requestedLeg: (row.requestedLeg as MlmLeg | null) ?? undefined,
        referralLenient: true,
      });
      if (row.invitationId) await db.invitation.update({ where: { id: row.invitationId }, data: { usedByUserId: user.id } });
      await db.pendingAccount.update({ where: { id: row.id }, data: { createdUserId: user.id } });
      return { role: 'student', tenantId: row.tenantId, courseId: row.courseId, user };
    } catch (err) {
      // Nothing was created — the address was taken, the plan is full, the link was withdrawn: release the row (and the
      // invitation) so the registrant sees why and can act on it.
      if (invitationUsed && row.invitationId) await releaseInvitation(row.invitationId);
      await db.pendingAccount.update({ where: { id: row.id }, data: { consumedAt: null } });
      throw err;
    }
  });
}

/** Removes registrations long past their code's expiry: they hold a password hash and can never be confirmed. */
export async function prunePendingRegistrations(now = new Date()): Promise<number> {
  const before = new Date(now.getTime() - 86_400_000);
  return runAsPlatform('the scheduler removes registrations that were never verified', async () => {
    const accounts = await db.pendingAccount.deleteMany({ where: { consumedAt: null, expiresAt: { lt: before } } });
    const signups = await db.pendingSignup.deleteMany({ where: { consumedAt: null, expiresAt: { lt: before } } });
    return accounts.count + signups.count;
  });
}
