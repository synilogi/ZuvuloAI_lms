import { academySlugFrom, validateAcademySlug } from '@syniastrolms/domain';

import { provisionSelfRegisteredAcademy } from './academies.js';
import { hashPassword } from './auth.js';
import { db } from './db.js';
import { ApiError, badRequest, conflict } from './errors.js';
import { queueEmail } from './mail.js';
import { deliverQueuedEmail } from './mailDelivery.js';
import { runAsPlatform } from './tenancy.js';
import { testOtpMatches } from './testOtp.js';
import {
  CODE_MAX_ATTEMPTS,
  CODE_MAX_SENDS,
  CODE_RESEND_COOLDOWN_MS,
  CODE_TTL_MS,
  codeMatches as matches,
  hashCode as hmac,
  newCode,
} from './verificationCode.js';

/*
 * Self-serve registration (SAAS-026, D27). Anyone may register an academy and become its admin, in two steps:
 *
 *   start  — the organisation and the admin's account are checked (the email is unique across the platform, D2;
 *            the address is free) and held as a pending signup, with the password hashed and a 6-digit code
 *            emailed. Nothing exists yet that can sign in.
 *   verify — the right code, in time, within the attempts, provisions the academy through `lib/academies` in one
 *            transaction (one academy per admin, D1). The academy starts with no subscription (D28).
 *
 * The code is stored as an HMAC under the server secret, bound to its row, so a leaked table does not give the
 * codes away and a code from one signup never confirms another. A row is confirmed at most once: the platform-wide
 * unique email makes a second provisioning impossible, and `consumedAt` is set conditionally.
 *
 * `SIGNUP_EMAIL_VERIFICATION=off` skips the code — only for a deployment that has no email delivery yet, never the
 * default.
 */

export const SIGNUP_CODE_TTL_MS = CODE_TTL_MS;
export const SIGNUP_MAX_ATTEMPTS = CODE_MAX_ATTEMPTS;
export const SIGNUP_RESEND_COOLDOWN_MS = CODE_RESEND_COOLDOWN_MS;

export const emailVerificationRequired = () => process.env.SIGNUP_EMAIL_VERIFICATION !== 'off';

export interface SignupStartInput {
  academyName: string;
  slug?: string;
  name: string;
  email: string;
  password: string;
  /** The plan chosen on the pricing page or the first step; kept with the signup, never a grant (D28). */
  planId?: string;
  cycle?: 'monthly' | 'annual';
}

export interface SignupChoice {
  planId: string;
  cycle: 'monthly' | 'annual';
}

const platform = <T>(reason: string, fn: () => Promise<T>) => runAsPlatform(reason, fn);

const hashCode = (signupId: string, code: string) => hmac('signup', signupId, code);
const codeMatches = (signupId: string, code: string, stored: string) => matches('signup', signupId, code, stored);

const signupError = (status: number, message: string, field?: string) => new ApiError(status, message, field ? [{ field, message }] : undefined);

/** Checks the address and the email are free, and gives the address to use. Throws with field-level issues. */
async function assertAvailable(input: SignupStartInput): Promise<string> {
  const slug = (input.slug?.trim() || academySlugFrom(input.academyName)).toLowerCase();
  const issue = validateAcademySlug(slug);
  if (issue) throw badRequest(issue, [{ field: 'slug', message: issue }]);
  const [user, academy] = await Promise.all([
    db.user.findUnique({ where: { email: input.email }, select: { id: true } }),
    db.tenant.findUnique({ where: { slug }, select: { id: true } }),
  ]);
  if (user)
    throw conflict('An account with this email already exists. Sign in instead.', [{ field: 'email', message: 'An account with this email already exists.' }]);
  if (academy) throw conflict('Another LMS already uses that address.', [{ field: 'slug', message: 'Another LMS already uses that address.' }]);
  return slug;
}

async function sendCode(to: string, name: string, academyName: string, code: string) {
  // As the platform: the academy does not exist yet, so no academy's name signs this email.
  await queueEmail({
    to,
    name,
    subject: `${code} is your ZuviloAI verification code`,
    text: `Hello ${name},\n\nUse this code to verify your email and create ${academyName} on ZuviloAI:\n\n${code}\n\nIt expires in ${SIGNUP_CODE_TTL_MS / 60_000} minutes. If you did not ask for this, ignore this email — nothing is created without the code.`,
    templateKey: 'signup-verification',
  });
  // The registrant is waiting for it: deliver now rather than on the scheduler's next tick. Claiming is per message,
  // so this never sends twice alongside the worker; a failure is retried by the worker as usual.
  void deliverQueuedEmail().catch(() => undefined);
}

export type SignupStartResult =
  | { status: 'verify'; signupId: string; email: string; expiresAt: string; resendAvailableAt: string; choice: SignupChoice | null }
  | { status: 'created'; academyId: string; adminId: string; choice: SignupChoice | null };

/** A chosen plan is kept only when it is on sale on that cycle; anything else is dropped, not refused. */
async function choiceOf(input: Pick<SignupStartInput, 'planId' | 'cycle'>): Promise<SignupChoice | null> {
  if (!input.planId) return null;
  const plan = await db.plan.findUnique({ where: { id: input.planId }, include: { versions: { orderBy: { version: 'desc' }, take: 1 } } });
  const cycle = input.cycle ?? 'monthly';
  const current = plan?.versions[0];
  if (!plan || plan.status !== 'active' || !current) return null;
  const sold = cycle === 'annual' ? current.annualPrice !== null : current.monthlyPrice !== null;
  return sold ? { planId: plan.id, cycle } : null;
}

const asChoice = (row: { planId: string | null; cycle: string | null }): SignupChoice | null =>
  row.planId ? { planId: row.planId, cycle: row.cycle === 'annual' ? 'annual' : 'monthly' } : null;

export async function startSignup(input: SignupStartInput): Promise<SignupStartResult> {
  return platform('a visitor registers an academy (SAAS-026)', async () => {
    const slug = await assertAvailable(input);
    const passwordHash = await hashPassword(input.password);
    const choice = await choiceOf(input);

    if (!emailVerificationRequired()) {
      const created = await createAcademy({ id: 'unverified', email: input.email, adminName: input.name, academyName: input.academyName, slug, passwordHash });
      // The choice is still kept with the new academy, so its plan page offers it first.
      if (choice) {
        await db.pendingSignup.create({
          data: {
            email: input.email,
            adminName: input.name,
            academyName: input.academyName,
            slug,
            passwordHash: '',
            codeHash: '',
            expiresAt: new Date(),
            lastSentAt: new Date(),
            consumedAt: new Date(),
            createdAcademyId: created.academyId,
            ...choice,
          },
        });
      }
      return { status: 'created', ...created, choice };
    }

    const now = Date.now();
    // A new start for the same email replaces what was pending: only the latest code can confirm it.
    await db.pendingSignup.deleteMany({ where: { email: input.email, consumedAt: null } });
    const row = await db.pendingSignup.create({
      data: {
        email: input.email,
        adminName: input.name,
        academyName: input.academyName,
        slug,
        passwordHash,
        codeHash: 'pending',
        expiresAt: new Date(now + SIGNUP_CODE_TTL_MS),
        lastSentAt: new Date(now),
        ...(choice ?? {}),
      },
      select: { id: true, expiresAt: true, lastSentAt: true },
    });
    const code = newCode();
    await db.pendingSignup.update({ where: { id: row.id }, data: { codeHash: hashCode(row.id, code) } });
    await sendCode(input.email, input.name, input.academyName, code);
    return {
      status: 'verify',
      signupId: row.id,
      email: input.email,
      expiresAt: row.expiresAt.toISOString(),
      resendAvailableAt: new Date(row.lastSentAt.getTime() + SIGNUP_RESEND_COOLDOWN_MS).toISOString(),
      choice,
    };
  });
}

/** Where an open registration stands — so a refreshed page can carry on at the code step. Never the code. */
export async function signupStatus(signupId: string) {
  return platform('a registrant’s page reads where their registration stands', async () => {
    const row = await openSignup(signupId);
    return {
      status: 'verify' as const,
      signupId: row.id,
      email: row.email,
      expiresAt: row.expiresAt.toISOString(),
      resendAvailableAt: new Date(row.lastSentAt.getTime() + SIGNUP_RESEND_COOLDOWN_MS).toISOString(),
      choice: asChoice(row),
    };
  });
}

/** The plan an academy's owner chose while registering, while it has not chosen one since — for its plan page. */
export async function signupChoiceFor(tenantId: string): Promise<SignupChoice | null> {
  const row = await runAsPlatform('an academy’s plan page reads the plan chosen at registration', () =>
    db.pendingSignup.findFirst({
      where: { createdAcademyId: tenantId, planId: { not: null } },
      orderBy: { createdAt: 'desc' },
      select: { planId: true, cycle: true },
    }),
  );
  return row ? asChoice(row) : null;
}

/** A pending signup that can still be acted on, or the refusal that says why not. */
async function openSignup(signupId: string) {
  const row = await db.pendingSignup.findUnique({ where: { id: signupId } });
  if (!row || row.consumedAt) throw signupError(404, 'This registration is no longer open. Start again.');
  return row;
}

export async function resendSignupCode(signupId: string) {
  return platform('a registrant asks for a new verification code (SAAS-026)', async () => {
    const row = await openSignup(signupId);
    const wait = row.lastSentAt.getTime() + SIGNUP_RESEND_COOLDOWN_MS - Date.now();
    if (wait > 0) throw signupError(429, `Wait ${Math.ceil(wait / 1000)} seconds before asking for another code.`);
    if (row.sendCount >= CODE_MAX_SENDS) throw signupError(429, 'We have sent the most codes we can for this registration. Start again in a little while.');
    const code = newCode();
    const now = Date.now();
    const updated = await db.pendingSignup.update({
      where: { id: row.id },
      // A new code starts a new count and a new expiry; the old code stops working.
      data: {
        codeHash: hashCode(row.id, code),
        attempts: 0,
        expiresAt: new Date(now + SIGNUP_CODE_TTL_MS),
        lastSentAt: new Date(now),
        sendCount: { increment: 1 },
      },
      select: { expiresAt: true, lastSentAt: true },
    });
    await sendCode(row.email, row.adminName, row.academyName, code);
    return {
      signupId: row.id,
      email: row.email,
      expiresAt: updated.expiresAt.toISOString(),
      resendAvailableAt: new Date(updated.lastSentAt.getTime() + SIGNUP_RESEND_COOLDOWN_MS).toISOString(),
    };
  });
}

/** Confirms the code and provisions the academy. Answers the new admin's id, for the caller to start a session. */
export async function verifySignup(signupId: string, code: string): Promise<{ academyId: string; adminId: string; choice: SignupChoice | null }> {
  return platform('a registrant confirms their email (SAAS-026)', async () => {
    const row = await openSignup(signupId);
    if (row.attempts >= SIGNUP_MAX_ATTEMPTS) throw signupError(429, 'Too many wrong codes. Ask for a new code.', 'code');
    if (row.expiresAt.getTime() <= Date.now()) throw signupError(410, 'This code has expired. Ask for a new code.', 'code');

    // Every guess spends an attempt before it is compared, so concurrent guesses cannot get past the limit: one that
    // finds no attempt left is refused without being checked.
    const spent = await db.pendingSignup.updateMany({ where: { id: row.id, attempts: { lt: SIGNUP_MAX_ATTEMPTS } }, data: { attempts: { increment: 1 } } });
    if (spent.count !== 1) throw signupError(429, 'Too many wrong codes. Ask for a new code.', 'code');
    // The test account's static code (lib/testOtp.ts) is a fallback for development and staging only.
    if (!codeMatches(row.id, code, row.codeHash) && !testOtpMatches(row.email, code)) {
      const left = SIGNUP_MAX_ATTEMPTS - row.attempts - 1;
      throw signupError(
        400,
        left > 0 ? `That code is not right. ${left} ${left === 1 ? 'try' : 'tries'} left.` : 'Too many wrong codes. Ask for a new code.',
        'code',
      );
    }

    // Claimed once: of two concurrent confirmations, only one gets the row.
    const claimed = await db.pendingSignup.updateMany({ where: { id: row.id, consumedAt: null }, data: { consumedAt: new Date() } });
    if (claimed.count !== 1) throw signupError(404, 'This registration is no longer open. Start again.');
    try {
      const created = await createAcademy(row);
      await db.pendingSignup.update({ where: { id: row.id }, data: { createdAcademyId: created.academyId } });
      return { ...created, choice: asChoice(row) };
    } catch (err) {
      // The address or the email was taken while the code was waiting: release the row so the registrant sees why.
      await db.pendingSignup.update({ where: { id: row.id }, data: { consumedAt: null } });
      throw err;
    }
  });
}

async function createAcademy(row: { id: string; email: string; adminName: string; academyName: string; slug: string; passwordHash: string }) {
  const academy = await provisionSelfRegisteredAcademy(row.id, {
    name: row.academyName,
    slug: row.slug,
    admin: { name: row.adminName, email: row.email, passwordHash: row.passwordHash },
  });
  if (!academy.owner) throw new Error('A provisioned academy has no owner.');
  return { academyId: academy.id, adminId: academy.owner.id };
}
