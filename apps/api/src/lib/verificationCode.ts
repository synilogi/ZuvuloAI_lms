import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';

/*
 * The 6-digit email codes self-registration sends (SAAS-026 for an academy's admin, and learners and instructors who
 * register themselves). A code is stored only as an HMAC under the server secret, bound to its purpose and its row,
 * so a leaked table does not give the codes away and a code from one registration never confirms another.
 */

/** How long a code is good for. */
export const CODE_TTL_MS = 15 * 60_000;
/** Wrong codes allowed before the registrant must ask for a new one. */
export const CODE_MAX_ATTEMPTS = 5;
/** How soon another code may be sent for the same registration. */
export const CODE_RESEND_COOLDOWN_MS = 60_000;
/** Codes one registration may send in all (the first and its resends), so an address cannot be flooded through it. */
export const CODE_MAX_SENDS = 5;

const secret = () => process.env.JWT_SECRET ?? 'dev-secret-change-me';

export const hashCode = (purpose: string, rowId: string, code: string) => createHmac('sha256', secret()).update(`${purpose}:${rowId}:${code}`).digest('hex');

export function codeMatches(purpose: string, rowId: string, code: string, stored: string) {
  const given = Buffer.from(hashCode(purpose, rowId, code), 'hex');
  const expected = Buffer.from(stored, 'hex');
  return given.length === expected.length && timingSafeEqual(given, expected);
}

export const newCode = () => String(randomInt(0, 1_000_000)).padStart(6, '0');

/** When the next code may be sent, given when the last one was. */
export const resendAvailableAt = (lastSentAt: Date) => new Date(lastSentAt.getTime() + CODE_RESEND_COOLDOWN_MS).toISOString();
