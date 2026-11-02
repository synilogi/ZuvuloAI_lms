/*
 * How a self-registration is verified. Every door — a learner at `/register`, an instructor at `/teach/apply`, an
 * invitation, a course link — confirms a 6-digit code emailed to the address before any account exists
 * (`lib/pendingAccounts.ts`, `lib/verificationCode.ts`).
 *
 * `SIGNUP_EMAIL_VERIFICATION=off` skips the code — only for a deployment that has no email delivery yet, never the
 * default. `OTP_CHANNEL` names how the code travels: `email` (the only channel that exists) or `sms`, which the
 * brief asks for and which needs an SMS provider nobody has configured yet (docs/16, D-PLAT-09). The API refuses to
 * start with `sms` until one exists, so the setting cannot silently fall back to email.
 */

export const emailVerificationRequired = () => process.env.SIGNUP_EMAIL_VERIFICATION !== 'off';

export type OtpChannel = 'email' | 'sms';

/** The channel the verification code is sent through. */
export const otpChannel = (env: NodeJS.ProcessEnv = process.env): OtpChannel => (env.OTP_CHANNEL === 'sms' ? 'sms' : 'email');

/** Refuses a configuration that names a channel the platform cannot deliver through. */
export function assertRegistrationConfig(env: NodeJS.ProcessEnv = process.env) {
  if (env.OTP_CHANNEL && env.OTP_CHANNEL !== 'email' && env.OTP_CHANNEL !== 'sms') {
    throw new Error(`OTP_CHANNEL must be "email" or "sms" (got "${env.OTP_CHANNEL}").`);
  }
  if (otpChannel(env) === 'sms') {
    throw new Error('OTP_CHANNEL=sms: no SMS provider is configured on this platform yet. Use OTP_CHANNEL=email (docs/16, D-PLAT-09).');
  }
}
