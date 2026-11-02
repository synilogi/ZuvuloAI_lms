/* The emailed 6-digit code every registration confirms (docs/16, D-PLAT-06): what the code step checks before it asks
 * the server, and how long until another code may be requested. */

/** Six digits, with the spaces people type around them ignored. */
export const isRegistrationCode = (code: string) => /^\d{6}$/.test(code.trim());

/** Why a typed code cannot be sent yet, or undefined when it can. */
export const codeIssue = (code: string) => (isRegistrationCode(code) ? undefined : 'Enter the 6-digit code from the email.');

/** Seconds until a new code may be asked for (0 when it may now). */
export const resendWait = (resendAvailableAt: string, now = Date.now()) => Math.max(0, Math.ceil((Date.parse(resendAvailableAt) - now) / 1000));

/** A mobile number as the server accepts it. */
export const isPhone = (phone: string) => /^\+?\d[\d\s-]{7,18}\d$/.test(phone.trim());
