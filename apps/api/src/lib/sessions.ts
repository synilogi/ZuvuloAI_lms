import { randomUUID } from 'node:crypto';
import jwt from 'jsonwebtoken';

import { signToken, type AuthTokenPayload } from './auth.js';
import { db } from './db.js';
import { runAsOwnerOf, runAsPlatform } from './tenancy.js';

/*
 * Server-side sessions (SAAS-020). Signing in creates a `UserSession` row and names it in the token (`sid`);
 * `lib/requestContext.ts` checks that row on the account read every request already makes, so revoking it
 * ends the token at once. Tokens signed before sessions existed carry no `sid`: they stay valid until they
 * expire, unless `User.tokensValidAfter` (set by logout-all, a password change or a reset) is later than
 * their issue time. Nothing about a session is ever taken from the client except its own description.
 */

export type RevokeReason = 'logout' | 'logout-all' | 'revoked' | 'password-changed' | 'password-reset' | 'account-deleted';

type SessionOwner = { id: string; tenantId: string | null; role: string; instructorId?: string | null; studentId?: string | null };

/** Starts a session for `user` and answers with its token. */
export async function startSession(user: SessionOwner, userAgent?: string): Promise<string> {
  const sid = randomUUID();
  const token = signToken({
    sub: user.id,
    role: user.role as AuthTokenPayload['role'],
    studentId: user.studentId ?? undefined,
    instructorId: user.instructorId ?? undefined,
    tenantId: user.tenantId ?? undefined,
    sid,
  });
  const { exp } = jwt.decode(token) as { exp: number };
  await runAsOwnerOf(user, () =>
    db.userSession.create({
      data: { id: sid, tenantId: user.tenantId, userId: user.id, expiresAt: new Date(exp * 1000), userAgent: userAgent?.slice(0, 200) || null },
    }),
  );
  return token;
}

/** Ends one session of `userId`. Answers whether there was an open one to end. */
export async function revokeSession(owner: { id: string; tenantId: string | null }, sid: string, reason: RevokeReason): Promise<boolean> {
  const { count } = await runAsOwnerOf(owner, () =>
    db.$transaction(async (tx) => {
      const ended = await tx.userSession.updateMany({
        where: { id: sid, userId: owner.id, revokedAt: null },
        data: { revokedAt: new Date(), revokedReason: reason },
      });
      // The devices that session registered for push stop receiving them (SAAS-021).
      if (ended.count) await tx.deviceToken.deleteMany({ where: { userId: owner.id, sessionId: sid } });
      return ended;
    }),
  );
  return count > 0;
}

/**
 * Ends every session of `owner` but `keep`, and every token it holds that predates sessions. Answers how many
 * sessions were ended.
 */
export async function revokeAllSessions(owner: { id: string; tenantId: string | null }, reason: RevokeReason, keep?: string): Promise<number> {
  const at = new Date();
  return runAsOwnerOf(owner, () =>
    db.$transaction(async (tx) => {
      const { count } = await tx.userSession.updateMany({
        where: { userId: owner.id, revokedAt: null, ...(keep ? { id: { not: keep } } : {}) },
        data: { revokedAt: at, revokedReason: reason },
      });
      await tx.user.update({ where: { id: owner.id }, data: { tokensValidAfter: at } });
      // Every device the account registered for push, but the one whose session survives.
      await tx.deviceToken.deleteMany({ where: { userId: owner.id, ...(keep ? { OR: [{ sessionId: null }, { sessionId: { not: keep } }] } : {}) } });
      return count;
    }),
  );
}

/** The account's open sessions, newest first. */
export async function openSessions(owner: { id: string; tenantId: string | null }) {
  return runAsOwnerOf(owner, () =>
    db.userSession.findMany({
      where: { userId: owner.id, revokedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { createdAt: 'desc' },
      select: { id: true, createdAt: true, expiresAt: true, userAgent: true },
    }),
  );
}

/** How long an ended or expired session is kept, for the account's own history, before it is removed. */
export const SESSION_RETENTION_DAYS = 30;

/** Removes sessions that expired more than `SESSION_RETENTION_DAYS` ago. Idempotent; the scheduler runs it. */
export async function pruneSessions(now = new Date()): Promise<number> {
  const before = new Date(now.getTime() - SESSION_RETENTION_DAYS * 86_400_000);
  const { count } = await runAsPlatform('the scheduler removes long-expired sessions', () =>
    db.userSession.deleteMany({ where: { expiresAt: { lt: before } } }),
  );
  return count;
}

/**
 * Whether the token's session still stands, given what the account read found: a token with a session id
 * needs that session open; one without needs to predate nothing `tokensValidAfter` ended.
 */
export function sessionStands(
  auth: { sid?: string; iat?: number },
  account: { tokensValidAfter: Date | null; sessions?: { revokedAt: Date | null }[] },
): boolean {
  if (auth.sid) return !!account.sessions?.length && !account.sessions[0].revokedAt;
  if (!account.tokensValidAfter) return true;
  // Strictly after: `iat` has whole seconds, and a token from the same second as the cut-off may predate it. No
  // token is signed without a session any more, so nothing issued after the cut-off falls under this rule.
  return (auth.iat ?? 0) > Math.floor(account.tokensValidAfter.getTime() / 1000);
}
