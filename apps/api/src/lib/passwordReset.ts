import { createHash, randomBytes } from 'node:crypto';

import { db } from './db.js';
import { runAsPlatform } from './tenancy.js';

/** Password reset / account set-up links. Only the SHA-256 hash of a token is stored; tokens are single use. */
export const RESET_TOKEN_TTL_MS = 60 * 60 * 1000; // 1 hour for "forgot password"
export const INVITE_TOKEN_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 days for a staff invitation

export const hashToken = (token: string) => createHash('sha256').update(token).digest('hex');

/** Creates a fresh token for the account (older unused ones stop working) and returns the plain token for the link. */
export async function issuePasswordResetToken(userId: string, ttlMs = RESET_TOKEN_TTL_MS): Promise<string> {
  const token = randomBytes(32).toString('hex');
  await db.$transaction([
    db.passwordResetToken.updateMany({ where: { userId, usedAt: null }, data: { usedAt: new Date() } }),
    db.passwordResetToken.create({ data: { userId, tokenHash: hashToken(token), expiresAt: new Date(Date.now() + ttlMs) } }),
  ]);
  return token;
}

/**
 * Ends every reset or set-up link still open for the account: after its password changes, or after its email does — a
 * link mailed to the old address must not set the password of an account that address no longer names.
 */
export async function revokePasswordResetTokens(userId: string): Promise<void> {
  await db.passwordResetToken.updateMany({ where: { userId, usedAt: null }, data: { usedAt: new Date() } });
}

export async function findUsableToken(token: string) {
  if (!/^[a-f0-9]{64}$/.test(token)) return null;
  // The link carries no academy, and a visitor following it is not signed in: the unguessable token is
  // the credential, so it is looked up across the platform and the row names the account's academy.
  const row = await runAsPlatform('a reset token is the credential, and names its own academy', () =>
    db.passwordResetToken.findUnique({ where: { tokenHash: hashToken(token) } }),
  );
  if (!row || row.usedAt || row.expiresAt < new Date()) return null;
  return row;
}
