import { ServiceError } from '@/services/contracts';

export type JoinField = 'name' | 'email' | 'password';

/**
 * What a refused join (an invitation, or a course link) means for the page: the link itself is gone, the platform can't take
 * the learner, or something about one of the fields. Every message is the server's own.
 */
export interface JoinFailure {
  /** The link is no longer usable — the page swaps the form for this message. */
  invalid?: string;
  /** Shown above the form. */
  banner?: { title: string; text: string };
  /** Shown beside each field. */
  fields: Partial<Record<JoinField, string>>;
}

const FIELDS: JoinField[] = ['name', 'email', 'password'];

export function joinFailure(err: unknown, lmsName: string, mode: 'register' | 'sign-in'): JoinFailure {
  const fields: JoinFailure['fields'] = {};
  if (!(err instanceof ServiceError)) {
    return { fields, banner: { title: 'Something went wrong', text: err instanceof Error ? err.message : 'Try again in a moment.' } };
  }
  const { reason, message, status, code } = err;
  if (reason === 'INVITE_INVALID') return { fields, invalid: message };
  if (reason === 'ACADEMY_SUSPENDED' || reason === 'ACADEMY_ARCHIVED') {
    return {
      fields,
      banner: { title: mode === 'register' ? `${lmsName} isn’t taking new learners right now` : `${lmsName} isn’t available right now`, text: message },
    };
  }

  // Per-field issues go beside their fields; anything else the server named goes above the form.
  const loose: string[] = [];
  for (const issue of err.issues ?? []) {
    if ((FIELDS as string[]).includes(issue.field)) fields[issue.field as JoinField] ??= issue.message;
    else loose.push(issue.message);
  }
  if (Object.keys(fields).length) return { fields, ...(loose.length ? { banner: { title: 'Check the form', text: loose.join(' ') } } : {}) };

  if (status === 401) return { fields: { password: message } };
  if (code === 'forbidden' && /different email/i.test(message)) return { fields: { email: message } };
  if (code === 'forbidden') return { fields, banner: { title: 'You can’t continue with this account', text: message } };
  if (code === 'conflict' && mode === 'sign-in') return { fields, banner: { title: 'This account can’t be used here', text: message } };
  if (code === 'conflict' && /already exists|already has/i.test(message)) return { fields: { email: message } };
  return { fields, banner: { title: mode === 'register' ? 'Your account wasn’t created' : 'You weren’t signed in', text: message } };
}

/** Why a signed-in learner's enrolment from a course link was refused. */
export function enrolFailure(err: unknown): string {
  if (err instanceof ServiceError && err.code === 'not-found') return 'This course isn’t open to your account.';
  return err instanceof Error ? err.message : 'Could not enrol you in this course.';
}
