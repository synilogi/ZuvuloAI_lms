import { courseSale, type CoursePricing } from '@syniastrolms/domain';
import type { LearnerRegistrationInput } from './learners.js';
import { randomBytes } from 'node:crypto';
import type { Request } from 'express';

import { recordAuditLog } from './audit.js';
import { verifyPassword } from './auth.js';
import { db } from './db.js';
import { ApiError, conflict, forbidden, notFound, unauthorized } from './errors.js';
import { assertSelfRegistrationOpen, registerLearner } from './learners.js';
import { APP_URL, queueEmail } from './mail.js';
import { hashToken, INVITE_TOKEN_TTL_MS } from './passwordReset.js';
import { workspaceClosed, workspaceId } from './requestContext.js';
import { SUSPENDED_MESSAGE } from './scope.js';
import { getSettings } from './settings.js';
import { runAsPlatform, runInTenant, tenant } from './tenancy.js';

/*
 * Learner invitations (`/invite/<token>`). An Admin makes a link for one learner; whoever opens it is shown that
 * Admin's LMS and creates an account there, or signs in with the account they already have there. The token is the
 * credential: 32 random bytes, stored only as its SHA-256, scoped to one workspace and the learner role, valid for
 * seven days and used once. The workspace and role always come from the invitation row — never from the request.
 */

const TOKEN = /^[a-f0-9]{64}$/;

const INVALID = () =>
  new ApiError(
    404,
    'This invitation link isn’t valid. It may have expired, been used or been withdrawn — contact support for a new one.',
    undefined,
    'INVITE_INVALID',
  );

export type InvitationStatus = 'pending' | 'accepted' | 'expired' | 'revoked';

const statusOf = (row: { usedAt: Date | null; revokedAt: Date | null; expiresAt: Date }, now = new Date()): InvitationStatus =>
  row.usedAt ? 'accepted' : row.revokedAt ? 'revoked' : row.expiresAt <= now ? 'expired' : 'pending';

const view = (row: { id: string; email: string | null; expiresAt: Date; createdAt: Date; usedAt: Date | null; revokedAt: Date | null }) => ({
  id: row.id,
  email: row.email,
  status: statusOf(row),
  expiresAt: row.expiresAt.toISOString(),
  createdAt: row.createdAt.toISOString(),
  usedAt: row.usedAt?.toISOString() ?? null,
});

export type InvitationView = ReturnType<typeof view>;

/** The platform name a learner sees: the Admin's own setting, else the workspace name. */
async function lmsName(tenantId: string, fallback: string) {
  const { general } = await runInTenant(tenantId, () => getSettings());
  return general.academyName || fallback;
}

/**
 * An Admin invites one learner to their own workspace (the request's). The plain link is returned once, for the
 * Admin to copy, and emailed when an address is given; only its hash is kept.
 */
export async function createInvitation(req: Request, input: { email?: string }) {
  const email = input.email?.toLowerCase();
  if (email) {
    const taken = await runAsPlatform('an email address is unique across the platform (D2)', () =>
      db.user.findUnique({ where: { email }, select: { id: true } }),
    );
    if (taken) throw conflict('An account with this email already exists.', [{ field: 'email', message: 'An account with this email already exists.' }]);
  }
  const token = randomBytes(32).toString('hex');
  const row = await db.invitation.create({
    data: {
      ...tenant(),
      role: 'student',
      tokenHash: hashToken(token),
      email: email ?? null,
      createdById: req.auth?.sub ?? null,
      expiresAt: new Date(Date.now() + INVITE_TOKEN_TTL_MS),
    },
  });
  const url = `${APP_URL}/invite/${token}`;
  await recordAuditLog(req, { action: 'invitation.created', targetType: 'invitation', targetId: row.id, meta: email ? { email } : {} });
  if (email) {
    const { general } = await getSettings();
    await queueEmail({
      to: email,
      subject: `You're invited to learn at ${general.academyName || 'ZuviloAI'}`,
      templateKey: 'learner-invitation',
      text: [
        'Hello,',
        '',
        'You’re invited to learn on ZuviloAI.',
        'Open the link below within seven days to create your account:',
        url,
        '',
        'The link works once. If you were not expecting it, ignore this email.',
      ].join('\n'),
    });
  }
  return { invitation: view(row), url };
}

/** This workspace's invitations, newest first. */
export async function listInvitations() {
  const rows = await db.invitation.findMany({ orderBy: { createdAt: 'desc' }, take: 100 });
  return { rows: rows.map(view) };
}

/** Withdraws an invitation of this workspace that has not been used. Another workspace's is simply not found. */
export async function revokeInvitation(req: Request, id: string) {
  const row = await db.invitation.findUnique({ where: { id } });
  if (!row) throw notFound('Invitation not found.');
  if (row.usedAt) throw conflict('This invitation has already been accepted.');
  const updated = row.revokedAt ? row : await db.invitation.update({ where: { id }, data: { revokedAt: new Date() } });
  if (!row.revokedAt) await recordAuditLog(req, { action: 'invitation.revoked', targetType: 'invitation', targetId: id });
  return view(updated);
}

/** The usable invitation a token names, with its workspace. Anything else — malformed, unknown, used, withdrawn, expired — is one answer. */
export async function usableInvitation(token: string) {
  return usable(token);
}

async function usable(token: string) {
  if (!TOKEN.test(token)) throw INVALID();
  const row = await runAsPlatform('an invitation token is the credential, and names its own workspace', () =>
    db.invitation.findUnique({ where: { tokenHash: hashToken(token) }, include: { tenant: { select: { id: true, name: true, slug: true, status: true } } } }),
  );
  if (!row || statusOf(row) !== 'pending' || row.tenant.status === 'archived') throw INVALID();
  return row;
}

/** What the invitation page shows before anything is asked: whose LMS, for which role, and for which address. */
export async function describeInvitation(token: string) {
  const row = await usable(token);
  return {
    lms: { name: await lmsName(row.tenantId, row.tenant.name), slug: row.tenant.slug },
    role: row.role as 'student',
    email: row.email,
    expiresAt: row.expiresAt.toISOString(),
    open: row.tenant.status === 'active',
  };
}

/** Uses the invitation once, atomically: a second accept of the same link finds nothing to use. */
async function consume(id: string) {
  const { count } = await db.invitation.updateMany({
    where: { id, usedAt: null, revokedAt: null, expiresAt: { gt: new Date() } },
    data: { usedAt: new Date() },
  });
  if (count !== 1) throw INVALID();
}

/** Uses an invitation of the current academy once, for a registration whose email was just verified. */
export const consumeInvitation = (id: string) => consume(id);

/** Gives an invitation back when the account it was used for could not be created. */
export async function releaseInvitation(id: string) {
  await db.invitation.updateMany({ where: { id, usedByUserId: null }, data: { usedAt: null } });
}

function assertAddress(invited: string | null, email: string) {
  if (invited && invited !== email.toLowerCase()) throw forbidden('This invitation is for a different email address. Use the address it was sent to.');
}

function assertOpen(status: string) {
  if (status !== 'active')
    throw new ApiError(403, 'The platform isn’t accepting new learners right now. Contact support for help.', undefined, 'ACADEMY_SUSPENDED');
}

/** A new learner accepts: the account is created in the invitation's workspace, as a learner, counted against its plan. */
export async function acceptWithNewAccount(token: string, input: LearnerRegistrationInput) {
  const row = await usable(token);
  assertOpen(row.tenant.status);
  assertAddress(row.email, input.email);
  return runInTenant(row.tenantId, async () => {
    await consume(row.id);
    try {
      const user = await registerLearner(input);
      await db.invitation.update({ where: { id: row.id }, data: { usedByUserId: user.id } });
      return user;
    } catch (err) {
      // Nothing was created: the link is still theirs to use (with another address, or once the plan has room).
      await db.invitation.update({ where: { id: row.id }, data: { usedAt: null } });
      throw err;
    }
  });
}

/**
 * Someone who already learns at this Admin's LMS accepts by signing in. An account belongs to one workspace (D2):
 * an account elsewhere, or a staff account, cannot be moved by a link.
 */
export async function acceptWithSignIn(token: string, input: { email: string; password: string }) {
  const row = await usable(token);
  const user = await runAsPlatform('signing in finds the account by email across the platform (D2)', () =>
    db.user.findUnique({ where: { email: input.email.toLowerCase() }, include: { student: true, tenant: { select: { status: true } } } }),
  );
  if (!user || !(await verifyPassword(input.password, user.passwordHash))) throw unauthorized('Incorrect email or password.');
  if (user.deactivatedAt) throw forbidden('This account has been deactivated.');
  if (user.tenantId && user.tenantId !== (await workspaceId())) throw workspaceClosed();
  if (user.tenantId !== row.tenantId || user.role !== 'student')
    throw conflict('This account can’t be used with this invitation. Create a new account with a different email instead.');
  if (user.student?.suspended) throw forbidden(SUSPENDED_MESSAGE);
  assertAddress(row.email, user.email);
  await runInTenant(row.tenantId, async () => {
    await consume(row.id);
    await db.invitation.update({ where: { id: row.id }, data: { usedByUserId: user.id } });
  });
  return user;
}

/*
 * Course links (`/courses/<course-id>/enroll`). The course id is unique across the platform, so the link names the
 * course and, through it, the Admin whose LMS it is. A visitor joins that LMS as a learner and is enrolled when its
 * enrolment policy lets learners enrol themselves; nothing in the request chooses the workspace.
 */

/** The published, listed course a link names, with its workspace. */
export async function courseAt(courseId: string) {
  if (!/^[A-Za-z0-9_-]{8,64}$/.test(courseId)) throw notFound('Course not found.');
  const course = await runAsPlatform('a visitor opens an Admin’s course link', () =>
    db.course.findUnique({
      where: { id: courseId },
      select: {
        id: true,
        title: true,
        slug: true,
        status: true,
        visibility: true,
        pricing: true,
        priceAmount: true,
        tenant: { select: { id: true, name: true, slug: true, status: true } },
      },
    }),
  );
  if (!course || course.status !== 'published' || course.visibility === 'private' || course.tenant.status === 'archived') throw notFound('Course not found.');
  return course;
}

export async function describeCourseLink(courseId: string) {
  const course = await courseAt(courseId);
  return {
    lms: { name: await lmsName(course.tenant.id, course.tenant.name), slug: course.tenant.slug },
    course: {
      id: course.id,
      title: course.title,
      slug: course.slug,
      // How the visitor gets in once they have an account: free, bought at this price, or not open yet.
      sale: courseSale({
        pricing: course.pricing as CoursePricing,
        price: course.priceAmount != null ? { amount: course.priceAmount, currency: 'INR' } : undefined,
      }),
    },
    open: course.tenant.status === 'active',
  };
}

/** A new learner joins the course's LMS from its link. Enrolment is attempted by the caller under the platform's policy. */
export async function joinFromCourseLink(courseId: string, input: LearnerRegistrationInput) {
  const course = await courseAt(courseId);
  assertOpen(course.tenant.status);
  const user = await runInTenant(course.tenant.id, async () => {
    await assertSelfRegistrationOpen();
    return registerLearner(input);
  });
  return { user, tenantId: course.tenant.id, courseId: course.id };
}
