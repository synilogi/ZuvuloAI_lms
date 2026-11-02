import type { AccountCreated, AccountVerificationPending, InstructorRequestPending, UserProfile } from '@syniastrolms/domain';

import { ServiceError, type SignupService } from '../contracts';
import { personas } from './fixtures/learner';
import { respond } from './simulation';

/*
 * The demo build's registration: it keeps no accounts, so a registration is held in memory and the code is always
 * 123456 (the page says so in demo mode). Confirming it signs in as the demo learner persona.
 */
export const DEMO_SIGNUP_CODE = '123456';

/* A learner's or instructor's own registration, as the demo holds it: the same code, and confirming it signs in as the
 * demo learner (or leaves an instructor's request waiting). */
const accounts = new Map<string, AccountVerificationPending & { user?: UserProfile }>();

const holdAccount = (email: string, role: 'student' | 'instructor', user?: UserProfile): AccountVerificationPending => {
  const now = Date.now();
  const row = {
    status: 'verify' as const,
    verificationId: `account-${accounts.size + 1}`,
    email,
    role,
    lms: 'ZuviloAI',
    expiresAt: new Date(now + 15 * 60_000).toISOString(),
    resendAvailableAt: new Date(now + 60_000).toISOString(),
  };
  accounts.set(row.verificationId, { ...row, user });
  return row;
};

const accountFor = (id: string) => {
  const row = accounts.get(id);
  if (!row) throw new ServiceError('This registration is no longer open. Start again.', 'not-found');
  return row;
};

const viewOf = ({ user: _user, ...row }: AccountVerificationPending & { user?: UserProfile }): AccountVerificationPending => row;

export const signupService: SignupService = {
  // Registering signs in as the demo learner.
  register: (input) => respond(() => holdAccount(input.email.trim(), 'student', personas.student), 700),
  applyToTeach: (input) => respond(() => holdAccount(input.email.trim(), 'instructor'), 700),

  resendVerification: (id) =>
    respond(() => {
      const row = accountFor(id);
      if (Date.now() < Date.parse(row.resendAvailableAt)) throw new ServiceError('Wait a minute before asking for another code.', 'conflict');
      const now = Date.now();
      Object.assign(row, { resendAvailableAt: new Date(now + 60_000).toISOString(), expiresAt: new Date(now + 15 * 60_000).toISOString() });
      return viewOf(row);
    }),
  confirmVerification: (id, code) =>
    respond((): AccountCreated | InstructorRequestPending => {
      const row = accountFor(id);
      if (code.trim() !== DEMO_SIGNUP_CODE)
        throw new ServiceError('That code is not right.', 'conflict', 'VERIFICATION_FAILED', [{ field: 'code', message: 'That code is not right.' }]);
      accounts.delete(id);
      if (row.role === 'instructor')
        return { status: 'pending', message: 'Your instructor application is being reviewed. You will be able to sign in once it is approved.' };
      return { status: 'created', token: 'demo', user: row.user ?? personas.student };
    }, 700),
};
