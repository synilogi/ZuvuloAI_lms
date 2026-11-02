import { timingSafeEqual } from 'node:crypto';

/*
 * A static verification code for named test accounts, for a developer's own machine and the test suite only — never a
 * staging or production server (owner's rule, 2026-10-28: no static or universal code outside local development).
 *
 * The emailed code stays the only code anyone else can use, and it keeps working for the test accounts too: the
 * static code is a fallback for when that email does not arrive. It is checked only where the emailed code is — after
 * the registration's expiry and attempt limits — so it is no way round either, and only for the listed addresses.
 *
 *   TEST_OTP_EMAIL — the test accounts' addresses, comma-separated (compared case-insensitively), or `*` for every
 *                    address.
 *   TEST_OTP_CODE  — exactly 6 digits.
 *
 * Where it may run: NODE_ENV=development or test, on a process that names neither the production site nor a staging or
 * production APP_ENV. Anywhere else the API refuses to start with either
 * variable set (`assertTestOtpConfig`), and `testOtpMatches` answers false whatever is set, so a process that somehow
 * started still accepts only the emailed code. Neither value is ever logged, returned or sent to a client.
 */

/** The live site, by name and by its server's address. A process serving it never takes the static code. */
const PRODUCTION_HOSTS = new Set(['zuviloai.com', 'www.zuviloai.com', '82.25.115.114']);

const CODE = /^\d{6}$/;

const hostOf = (url: string | undefined) => {
  try {
    // A trailing dot names the same host (`zuviloai.com.`).
    return url ? new URL(url).hostname.toLowerCase().replace(/\.$/, '') : undefined;
  } catch {
    return undefined;
  }
};

/** Every host APP_URL and CORS_ORIGIN name; CORS_ORIGIN may list several origins, comma-separated. */
const hostsOf = (env: NodeJS.ProcessEnv) => [env.APP_URL, ...(env.CORS_ORIGIN ?? '').split(',')].map((url) => hostOf(url?.trim()));

/**
 * Whether this process is one the static code may run in. Fails closed: an unset NODE_ENV is not development, and a
 * process that names the live site is refused whatever NODE_ENV says — a production box started as `development`
 * included.
 */
export function testOtpAllowedHere(env: NodeJS.ProcessEnv = process.env): boolean {
  if (hostsOf(env).some((host) => host !== undefined && PRODUCTION_HOSTS.has(host))) return false;
  // A server that calls itself staging or production never takes it, whatever NODE_ENV says.
  if (['staging', 'production'].includes(env.APP_ENV?.trim().toLowerCase() ?? '')) return false;
  return env.NODE_ENV === 'development' || env.NODE_ENV === 'test';
}

/** The listed addresses, normalised; empty entries are dropped. */
const testEmails = (env: NodeJS.ProcessEnv) =>
  (env.TEST_OTP_EMAIL ?? '')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);

/** A plain address: something@domain.tld, no wildcard or spaces. */
const ADDRESS = /^[^\s@*,]+@[^\s@*,]+\.[^\s@*,]+$/;

/** TEST_OTP_EMAIL=* — every address. Like the code itself, only on a developer's own machine. */
export const ANY_EMAIL = '*';
const anyEmail = (env: NodeJS.ProcessEnv) => env.TEST_OTP_EMAIL?.trim() === ANY_EMAIL;
const local = (env: NodeJS.ProcessEnv) => env.NODE_ENV === 'development' || env.NODE_ENV === 'test';

/** Whether TEST_OTP_EMAIL is usable here: `*` on a local process, or a list of plain addresses. */
const emailsValid = (env: NodeJS.ProcessEnv) => {
  if (anyEmail(env)) return local(env);
  const emails = testEmails(env);
  return emails.length > 0 && emails.every((email) => ADDRESS.test(email));
};

const configured = (env: NodeJS.ProcessEnv) => Boolean(env.TEST_OTP_EMAIL?.trim() || env.TEST_OTP_CODE?.trim());

/** Called once at boot: either variable set where the static code may not run, or set half or wrong, stops the API. */
export function assertTestOtpConfig(env: NodeJS.ProcessEnv = process.env) {
  if (!configured(env)) return;
  // The messages name the variables, never their values.
  if (!testOtpAllowedHere(env))
    throw new Error(
      'TEST_OTP_EMAIL / TEST_OTP_CODE are refused here: the static test code runs only with NODE_ENV=development or test on a developer’s machine, never on a staging or production server. Remove both.',
    );
  if (!env.TEST_OTP_EMAIL?.trim() || !env.TEST_OTP_CODE?.trim()) throw new Error('Set both TEST_OTP_EMAIL and TEST_OTP_CODE, or neither.');
  if (anyEmail(env) && !local(env))
    throw new Error('TEST_OTP_EMAIL=* runs only with NODE_ENV=development or test: a staging server must list its test accounts.');
  if (!emailsValid(env))
    throw new Error('TEST_OTP_EMAIL must be * (development only) or the test accounts’ email addresses, comma-separated — no other wildcards.');
  if (!CODE.test(env.TEST_OTP_CODE.trim())) throw new Error('TEST_OTP_CODE must be exactly 6 digits.');
}

/** Whether the static code is on in this process — for the boot notice; says nothing about the accounts or the code. */
export const testOtpEnabled = (env: NodeJS.ProcessEnv = process.env) => configured(env) && testOtpAllowedHere(env);

/**
 * Whether `code` is the static test code and `email` an address it confirms (any, with TEST_OTP_EMAIL=* locally). False
 * whenever the environment does not allow it or anything is unset or malformed — it never throws, so a bad setting can
 * only turn it off.
 */
export function testOtpMatches(email: string, code: string, env: NodeJS.ProcessEnv = process.env): boolean {
  if (!testOtpAllowedHere(env) || !emailsValid(env)) return false;
  const testCode = env.TEST_OTP_CODE?.trim();
  if (!testCode || !CODE.test(testCode)) return false;
  if (!anyEmail(env) && !testEmails(env).includes(email.trim().toLowerCase())) return false;
  const given = Buffer.from(code.trim());
  const expected = Buffer.from(testCode);
  return given.length === expected.length && timingSafeEqual(given, expected);
}
