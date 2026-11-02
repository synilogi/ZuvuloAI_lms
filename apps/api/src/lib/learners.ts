import { randomUUID } from 'node:crypto';
import type { MlmLeg } from '@syniastrolms/domain';
import { attachAffiliate, prepareReferral } from './mlm/affiliates.js';
import type { Request } from 'express';

import { recordAuditLog } from './audit.js';
import { hashPassword } from './auth.js';
import { db } from './db.js';
import { ApiError, conflict, notFound } from './errors.js';
import { APP_URL, queueEmail } from './mail.js';
import { INVITE_TOKEN_TTL_MS, issuePasswordResetToken } from './passwordReset.js';
import { workspaceId } from './requestContext.js';
import { getSettings } from './settings.js';
import { currentTenantId, runAsPlatform, runInTenant, tenant } from './tenancy.js';

/*
 * A learner joining an academy (SAAS-028). Three doors, one rule: the learner belongs to the academy the request runs
 * for — the host's academy for `POST /auth/register`, the academy a join link names for
 * `POST /public/academies/:slug/register`, and the admin's own academy for `POST /students`. Every one is counted
 * against the academy's `learners.max` and refused in restricted mode, and the email is unique across the platform (D2).
 */

/** Whether the address already has an account anywhere on the platform (D2). */
async function emailTaken(email: string) {
  return !!(await runAsPlatform('an email address is unique across the platform (D2)', () => db.user.findUnique({ where: { email }, select: { id: true } })));
}

/** What an affiliate referral adds to a learner's registration (MLM-001): the sponsor's code, the leg their link named, and the learner's own preference for their referrals. */
export interface LearnerReferral {
  referralCode?: string;
  preferredLeg?: MlmLeg;
  requestedLeg?: MlmLeg;
  /** A verified registration whose sponsor vanished meanwhile is still created, without the affiliate row. */
  referralLenient?: boolean;
}

export type LearnerRegistrationInput = { name: string; email: string; password: string; phone?: string } & LearnerReferral;

/** Creates the learner and their student record in the current academy, inside the plan's limit — and, with a referral, their affiliate row. */
export async function createLearner(input: { name: string; email: string; passwordHash: string; phone?: string } & LearnerReferral) {
  if (await emailTaken(input.email))
    throw conflict('An account with this email already exists.', [{ field: 'email', message: 'An account with this email already exists.' }]);
  const firstRank = await db.rank.findFirst({ orderBy: { order: 'asc' } });
  // The referral is resolved before anything exists, so a bad code refuses the registration rather than an affiliate row.
  const referral = await prepareReferral(currentTenantId(), input);
  const user = await db.$transaction((tx) =>
    tx.user.create({
      data: {
        ...tenant(),
        name: input.name,
        email: input.email,
        passwordHash: input.passwordHash,
        phone: input.phone || null,
        role: 'student',
        descriptor: firstRank ? `Beginner · ${firstRank.title}` : 'Learner',
        student: { create: { ...tenant(), rankId: firstRank?.id, phone: input.phone || null } },
      },
      include: { student: true },
    }),
  );
  await attachAffiliate(user, referral);
  return user;
}

/** The Admin workspace a join link names, or not found. Archived workspaces are not found. */
export async function workspaceAt(slug: string) {
  const row = await runAsPlatform('a visitor opens an Admin’s join link', () =>
    db.tenant.findUnique({ where: { slug: slug.toLowerCase() }, select: { id: true, name: true, slug: true, status: true } }),
  );
  // One workspace (docs/16, D-PLAT-01): an address that names any other tenant finds nothing.
  if (!row || row.id !== (await workspaceId())) throw notFound('This join link isn’t valid. Check the link you were given.');
  return row;
}

/** The workspace a join link names, when it takes new learners: refused while it is suspended. */
export async function openWorkspaceAt(slug: string) {
  const workspace = await workspaceAt(slug);
  if (workspace.status !== 'active')
    throw new ApiError(403, 'The platform isn’t accepting new learners right now. Contact support for help.', undefined, 'ACADEMY_SUSPENDED');
  return workspace;
}

/**
 * Refuses a learner registering themselves where the academy adds learners by invitation only (its enrolment policy
 * is `invite`): a join link or a course link — whose address anyone can guess — is then no way in. An invitation is.
 * Runs in the academy's context.
 */
export async function assertSelfRegistrationOpen() {
  const { general } = await getSettings();
  if (general.enrollment === 'invite')
    throw new ApiError(403, 'Learners join by invitation only. Ask support for an invitation link.', undefined, 'INVITATION_REQUIRED');
}

/** A learner signs up into the workspace a join link names — refused while it is suspended or invitation-only. */
export async function registerLearnerAt(slug: string, input: LearnerRegistrationInput) {
  const workspace = await openWorkspaceAt(slug);
  return runInTenant(workspace.id, async () => {
    await assertSelfRegistrationOpen();
    return registerLearner(input);
  });
}

/** A visitor signing themselves up, with the password they chose. */
export async function registerLearner(input: LearnerRegistrationInput) {
  return createLearner({
    name: input.name,
    email: input.email,
    passwordHash: await hashPassword(input.password),
    phone: input.phone,
    referralCode: input.referralCode,
    preferredLeg: input.preferredLeg,
    requestedLeg: input.requestedLeg,
    referralLenient: input.referralLenient,
  });
}

/**
 * An academy admin adding a learner. The account has no usable password until the learner follows the invitation,
 * which lets them choose one (the password-reset link, valid seven days). Audited.
 */
export async function addLearnerByAdmin(req: Request, input: { name: string; email: string }) {
  const user = await createLearner({ ...input, passwordHash: await hashPassword(randomUUID()) });
  await recordAuditLog(req, { action: 'learner.created', targetType: 'student', targetId: user.student?.id ?? user.id, meta: { email: input.email } });
  await sendLearnerInvite(user);
  return user;
}

/** The invitation to set a password, in the academy's name. */
export async function sendLearnerInvite(user: { id: string; email: string; name: string }) {
  const { general } = await getSettings();
  const token = await issuePasswordResetToken(user.id, INVITE_TOKEN_TTL_MS);
  await queueEmail({
    to: user.email,
    name: user.name,
    subject: `You have been added to ${general.academyName}`,
    templateKey: 'learner-invite',
    text: [
      `Hi ${user.name.split(' ')[0]},`,
      '',
      `${general.academyName} has added you as a learner. Choose a password to open your learning workspace — the link works for seven days:`,
      `${APP_URL}/reset-password/${token}`,
      '',
      'If you were not expecting this, you can ignore this email.',
    ].join('\n'),
  });
}

/** Sends a learner's invitation again — for a learner of this academy who has not signed in yet. */
export async function resendLearnerInvite(studentId: string) {
  const student = await db.student.findUnique({ where: { id: studentId }, include: { user: { select: { id: true, email: true, name: true } } } });
  if (!student?.user) throw notFound('Learner not found.');
  await sendLearnerInvite(student.user);
  return { sentTo: student.user.email };
}
