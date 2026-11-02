import { randomBytes } from 'node:crypto';
import { Router } from 'express';
import type { PermissionKey, Role, UserProfile } from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { runAsOwnerOf, runAsPlatform, runInTenant } from '../lib/tenancy.js';
import { getSettings } from '../lib/settings.js';
import { asyncHandler, conflict, forbidden, notFound, unauthorized } from '../lib/errors.js';
import { hashPassword, requireAuth, verifyPassword } from '../lib/auth.js';
import { openSessions, revokeAllSessions, revokeSession, startSession } from '../lib/sessions.js';
import { assertSelfRegistrationOpen, registerLearner } from '../lib/learners.js';
import { startHostRegistration } from '../lib/pendingAccounts.js';
import { emailVerificationRequired } from '../lib/registration.js';
import { permissionsFor } from '../lib/permissions.js';
import { SUSPENDED_MESSAGE } from '../lib/scope.js';
import { workspaceClosed, workspaceId } from '../lib/requestContext.js';
import { recordAuditLog } from '../lib/audit.js';
import { removeStudentReviews } from '../lib/courseReviews.js';
import { APP_URL, queueEmail } from '../lib/mail.js';
import { findUsableToken, issuePasswordResetToken, revokePasswordResetTokens } from '../lib/passwordReset.js';
import { email, parseBody, phoneNumber, z } from '../lib/validate.js';
import { instructorRequestRefusal } from '../lib/instructorRequests.js';

/** A hash no password matches in practice: what an unknown email's password is compared with at sign-in. */
const STAND_IN_HASH = hashPassword(randomBytes(24).toString('hex'));

export const authRouter = Router();

export function toProfile(
  user: { id: string; name: string; email: string; role: string; descriptor: string; instructorId: string | null },
  permissions?: PermissionKey[],
): UserProfile {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role as Role,
    descriptor: user.descriptor,
    instructorId: user.instructorId ?? undefined,
    ...(permissions ? { permissions } : {}),
  };
}

/**
 * The academy permissions a session response carries. Read from the database every time, never from
 * the token: a grant taken away must be gone on the next request, not on the next sign-in. Only an
 * academy admin can hold any — every other role, the platform super admin included, answers `[]`.
 */
const permissionsInProfile = async (user: { id: string; role: string }): Promise<PermissionKey[]> => (user.role === 'admin' ? permissionsFor(user.id) : []);

const password = z.string().min(8, 'Password must be at least 8 characters.').max(128);

const registerSchema = z.object({
  name: z.string().trim().min(2, 'Enter your full name.').max(120),
  email: email,
  password,
  /** Optional here: apps already in people's hands do not send one. The website's door, `POST /public/register`, requires it. */
  phone: phoneNumber.optional(),
  /** Accepted and ignored for one release: older apps named the workspace they joined (docs/16 §3.1). */
  workspace: z.string().trim().toLowerCase().max(60).optional(),
  /** An affiliate referral (MLM-001). */
  referralCode: z.string().trim().max(16).optional(),
  preferredLeg: z.enum(['A', 'B']).optional(),
  requestedLeg: z.enum(['A', 'B']).optional(),
});

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().min(1, 'Enter your email and password.').max(254),
  password: z.string().min(1, 'Enter your email and password.').max(128),
});

authRouter.post(
  '/register',
  asyncHandler(async (req, res) => {
    // Public registration always creates a learner. Staff accounts are created by an admin
    // (Instructors module) or the seed — the role is never taken from the request.
    const input = parseBody(req, registerSchema);
    // The learner joins the platform's one workspace (docs/16, D-PLAT-01). Email is unique across the platform (D2).
    const { workspace: _ignored, ...learner } = input;
    void _ignored;
    // The email is verified before any account exists (`lib/pendingAccounts.ts`): `202 { status: 'verify', … }`, then
    // `POST /public/verifications/verify` with the emailed code.
    if (emailVerificationRequired()) return void res.status(202).json(await startHostRegistration(learner));
    await assertSelfRegistrationOpen();
    const user = await registerLearner(learner);

    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    res.status(201).json({ token, user: toProfile(user) });
  }),
);

authRouter.post(
  '/login',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, loginSchema);

    // Sign-in has no academy picker (D2): the address finds the account wherever it lives.
    const user = await runAsPlatform('signing in finds the account by email across the platform (D2)', () =>
      db.user.findUnique({
        where: { email: input.email },
        include: { student: true, instructor: { select: { status: true } }, tenant: { select: { status: true } } },
      }),
    );
    // Same message for an unknown email and a wrong password — no account enumeration. An unknown email is checked
    // against a stand-in hash, so it takes as long to refuse as a wrong password does.
    if (!(await verifyPassword(input.password, user?.passwordHash ?? (await STAND_IN_HASH))) || !user) throw unauthorized('Incorrect email or password.');
    if (user.role === 'instructor' && user.instructor?.status === 'inactive') throw forbidden('This instructor account has been deactivated.');
    // A self-registered instructor waits for the academy admin (D34): told why only once the password matched.
    const awaitingApproval = user.role === 'instructor' ? instructorRequestRefusal(user.instructor?.status) : undefined;
    if (awaitingApproval) throw awaitingApproval;
    if (user.deactivatedAt) throw forbidden('This account has been deactivated.');
    if (user.student?.suspended) throw forbidden(SUSPENDED_MESSAGE);
    // After the password check, like the refusals above: an account of an academy from the SaaS era is kept, closed
    // (docs/16, D-PLAT-02), and told so only once the password matched.
    if (user.tenantId && user.tenantId !== (await workspaceId())) throw workspaceClosed();

    // The token carries the role, the ids the scope helpers need, the academy and its session — never the permissions.
    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    res.json({ token, user: toProfile(user, await runAsOwnerOf(user, () => permissionsInProfile(user))) });
  }),
);

authRouter.get(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const user = await runAsPlatform('an account reading its own row, by the id its verified token names', () =>
      db.user.findUnique({ where: { id: req.auth!.sub }, include: { student: { select: { suspended: true } } } }),
    );
    if (!user) throw notFound('Account not found.');
    // A token issued before the account was deactivated stays cryptographically valid; refusing the
    // session read is what ends it, since the app drops to signed-out on a failed `me`.
    if (user.deactivatedAt) throw forbidden('This account has been deactivated.');
    if (user.student?.suspended) throw forbidden(SUSPENDED_MESSAGE);
    res.json({ user: toProfile(user, await runAsOwnerOf(user, () => permissionsInProfile(user))) });
  }),
);

/* ─── Forgot / reset password ─────────────────────────────────────────── */

authRouter.post(
  '/forgot-password',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ email }));
    const user = await runAsPlatform('a reset link finds the account by email across the platform (D2)', () =>
      db.user.findUnique({ where: { email: input.email } }),
    );

    if (user) {
      // The token and its email belong to the account's academy — or to the platform, for a super admin.
      await runAsOwnerOf(user, async () => {
        const token = await issuePasswordResetToken(user.id);
        await queueEmail({
          to: user.email,
          name: user.name,
          subject: 'Reset your ZuviloAI password',
          templateKey: 'password-reset',
          text: [
            `Hi ${user.name.split(' ')[0]},`,
            '',
            'Someone asked to reset the password for this ZuviloAI account. Open the link below within the next hour to choose a new one:',
            `${APP_URL}/reset-password/${token}`,
            '',
            'If that was not you, ignore this email — your password stays the same.',
          ].join('\n'),
        });
      });
    }

    // Always the same answer, whether or not the address matches an account.
    res.json({ ok: true });
  }),
);

authRouter.get(
  '/reset-password/:token',
  asyncHandler(async (req, res) => {
    const row = await findUsableToken(req.params.token);
    if (!row) return void res.json({ valid: false });
    // An invited instructor or learner is shown whose LMS they are joining; the token already names its account's.
    const lms = row.tenantId ? (await runInTenant(row.tenantId, () => getSettings())).general.academyName : undefined;
    res.json({ valid: true, ...(lms ? { lms } : {}) });
  }),
);

authRouter.post(
  '/reset-password',
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ token: z.string().min(1).max(128), password }));
    const row = await findUsableToken(input.token);
    if (!row) throw conflict('This reset link is invalid or has expired. Request a new one.');

    const passwordHash = await hashPassword(input.password);
    // Claimed before the password changes: of two submissions of one link at the same moment, only one goes through.
    const claimed = await runAsOwnerOf(row, () => db.passwordResetToken.updateMany({ where: { id: row.id, usedAt: null }, data: { usedAt: new Date() } }));
    if (claimed.count !== 1) throw conflict('This reset link is invalid or has expired. Request a new one.');
    await runAsOwnerOf(row, () =>
      db.$transaction(async (tx) => {
        await tx.user.update({ where: { id: row.userId }, data: { passwordHash } });
        await recordAuditLog({ type: 'system', job: 'password-reset' }, { action: 'account.password_reset', targetType: 'user', targetId: row.userId }, tx);
      }),
    );
    // Whoever knew the old password is signed out everywhere (SAAS-020).
    await revokeAllSessions({ id: row.userId, tenantId: row.tenantId }, 'password-reset');
    res.json({ ok: true });
  }),
);

/* ─── Sessions and the signed-in account (SAAS-020) ───────────────────── */

/** The signed-in account, read by the id its verified token names: its own row, wherever it lives. */
async function self(userId: string) {
  const user = await runAsPlatform('an account reading its own row, by the id its verified token names', () =>
    db.user.findUnique({ where: { id: userId }, include: { student: { select: { id: true, suspended: true } } } }),
  );
  if (!user) throw notFound('Account not found.');
  return user;
}

/**
 * Ends the session this token was issued with. A closed account may still sign itself out, so this needs a
 * verified token and nothing more. A token from before sessions has no session of its own to end: the answer
 * says so, and `POST /auth/logout-all` ends those.
 */
authRouter.post(
  '/logout',
  asyncHandler(async (req, res) => {
    if (!req.auth) throw unauthorized();
    const user = await self(req.auth.sub);
    const revoked = req.auth.sid ? await revokeSession(user, req.auth.sid, 'logout') : false;
    res.json({ revoked: revoked ? 1 : 0 });
  }),
);

/** Ends every session of the account, this one included, and every token it holds from before sessions. */
authRouter.post(
  '/logout-all',
  requireAuth,
  asyncHandler(async (req, res) => {
    const user = await self(req.auth!.sub);
    res.json({ revoked: await revokeAllSessions(user, 'logout-all') });
  }),
);

/** The account's open sessions, newest first, marking the one making this request. */
authRouter.get(
  '/sessions',
  requireAuth,
  asyncHandler(async (req, res) => {
    const user = await self(req.auth!.sub);
    const rows = await openSessions(user);
    res.json({
      sessions: rows.map((s) => ({
        id: s.id,
        createdAt: s.createdAt.toISOString(),
        expiresAt: s.expiresAt.toISOString(),
        ...(s.userAgent ? { userAgent: s.userAgent } : {}),
        current: s.id === req.auth!.sid,
      })),
    });
  }),
);

/** Ends one of the account's own sessions. Another account's session id is the same 404 as none. */
authRouter.delete(
  '/sessions/:id',
  requireAuth,
  asyncHandler(async (req, res) => {
    const user = await self(req.auth!.sub);
    if (!(await revokeSession(user, req.params.id, 'revoked'))) throw notFound('Session not found.');
    res.status(204).end();
  }),
);

/**
 * Changes the password. The current one is required — a borrowed session cannot lock its owner out — and every
 * session is ended, this one included; the answer carries a fresh token for this device.
 */
authRouter.post(
  '/change-password',
  requireAuth,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ currentPassword: z.string().min(1).max(128), newPassword: password }));
    const user = await self(req.auth!.sub);
    if (!(await verifyPassword(input.currentPassword, user.passwordHash))) throw forbidden('Your current password is not correct.');
    if (input.currentPassword === input.newPassword) throw conflict('Choose a password different from your current one.');
    const passwordHash = await hashPassword(input.newPassword);
    await runAsOwnerOf(user, () =>
      db.$transaction(async (tx) => {
        await tx.user.update({ where: { id: user.id }, data: { passwordHash } });
        await recordAuditLog(req, { action: 'account.password_changed', targetType: 'user', targetId: user.id }, tx);
      }),
    );
    // A reset link asked for earlier would otherwise still undo the change.
    await runAsOwnerOf(user, () => revokePasswordResetTokens(user.id));
    await revokeAllSessions(user, 'password-changed');
    const token = await startSession({ ...user, studentId: user.student?.id }, req.get('user-agent'));
    res.json({ token, user: toProfile(user, await runAsOwnerOf(user, () => permissionsInProfile(user))) });
  }),
);

/**
 * Updates the signed-in account's own profile: its display name. Email, role and academy are not fields here —
 * a body naming them is dropped. An instructor's public profile carries the same name, so it follows.
 */
authRouter.patch(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ name: z.string().trim().min(2, 'Enter your full name.').max(120) }));
    const user = await self(req.auth!.sub);
    const updated = await runAsOwnerOf(user, () =>
      db.$transaction(async (tx) => {
        if (user.instructorId) await tx.instructor.update({ where: { id: user.instructorId }, data: { name: input.name } });
        return tx.user.update({ where: { id: user.id }, data: { name: input.name } });
      }),
    );
    res.json({ user: toProfile(updated, await runAsOwnerOf(user, () => permissionsInProfile(updated))) });
  }),
);

/**
 * Deletes the signed-in learner's own account (Google Play account-deletion policy). The password is required —
 * a borrowed session cannot erase its owner. The row is kept but no longer names anyone: the name and email are
 * replaced, the password is made unusable and the account is closed, so the email address is free to register
 * again. What only served the person — notes, bookmarks, saved courses, drafts, live-class registrations,
 * notifications, preferences, devices and reset links — is removed; course records and issued certificates stay,
 * under the anonymised name, so a credential someone may rely on keeps verifying (the privacy policy says so).
 * Every session ends. Staff accounts belong to their academy and are closed by its administrator instead.
 */
authRouter.post(
  '/delete-account',
  requireAuth,
  asyncHandler(async (req, res) => {
    const input = parseBody(req, z.object({ password: z.string().min(1, 'Enter your password.').max(128) }));
    const user = await self(req.auth!.sub);
    if (user.role !== 'student' || !user.student) {
      throw forbidden('Staff accounts are closed by the platform team. Ask them to remove your account.');
    }
    if (!(await verifyPassword(input.password, user.passwordHash))) throw forbidden('Your password is not correct.');

    const studentId = user.student.id;
    // Money still owed either way is settled first; an account that has gone cannot be paid or asked for it.
    const affiliate = await runAsOwnerOf(user, () => db.affiliate.findUnique({ where: { studentId }, select: { id: true, status: true } }));
    if (affiliate) {
      const [wallet, open] = await runAsOwnerOf(user, () =>
        Promise.all([
          db.mlmWallet.findUnique({ where: { affiliateId: affiliate.id }, select: { available: true, held: true } }),
          db.mlmWithdrawal.count({ where: { affiliateId: affiliate.id, status: { in: ['requested', 'approved', 'processing'] } } }),
        ]),
      );
      if (open > 0 || (wallet?.available ?? 0n) > 0n || (wallet?.held ?? 0n) > 0n) {
        throw conflict('You still have an affiliate balance or a withdrawal in progress. Withdraw it, or contact support, before deleting your account.');
      }
    }
    const passwordHash = await hashPassword(randomBytes(32).toString('hex'));
    await runAsOwnerOf(user, () =>
      db.$transaction(async (tx) => {
        await tx.lessonNote.deleteMany({ where: { studentId } });
        await tx.lessonBookmark.deleteMany({ where: { studentId } });
        await tx.savedCourse.deleteMany({ where: { studentId } });
        await tx.assignmentDraft.deleteMany({ where: { studentId } });
        await tx.liveRegistration.deleteMany({ where: { studentId } });
        await removeStudentReviews(tx, studentId);
        await tx.appNotification.deleteMany({ where: { recipientId: user.id } });
        await tx.notificationSettings.deleteMany({ where: { userId: user.id } });
        await tx.passwordResetToken.deleteMany({ where: { userId: user.id } });
        await tx.student.update({ where: { id: studentId }, data: { phone: null, city: '' } });
        if (affiliate) {
          // The tree keeps its position, earning stops, and the identity details are forgotten. Paid withdrawals keep their own record.
          if (affiliate.status !== 'terminated') await tx.affiliate.update({ where: { id: affiliate.id }, data: { status: 'terminated', kycStatus: 'none' } });
          await tx.mlmKyc.deleteMany({ where: { affiliateId: affiliate.id } });
        }
        await tx.user.update({
          where: { id: user.id },
          data: {
            name: 'Deleted learner',
            email: `deleted-${user.id}@deleted.invalid`,
            descriptor: '',
            passwordHash,
            deactivatedAt: new Date(),
          },
        });
        // The trail names the account by id only: the address it had is exactly what was asked to be forgotten.
        await recordAuditLog(req, { action: 'account.deleted', targetType: 'user', targetId: user.id }, tx);
      }),
    );
    await revokeAllSessions(user, 'account-deleted');
    res.json({ ok: true });
  }),
);
