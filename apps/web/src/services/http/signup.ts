import type { AccountCreated, AccountStartResult, AccountVerificationPending, InstructorRequestPending } from '@syniastrolms/domain';

import type { SignupService } from '../contracts';
import { post } from './client';

/** A deployment with verification off answers a learner's registration with the session itself, unlabelled. */
export const asAccountStart = (r: AccountStartResult | Omit<AccountCreated, 'status'>): AccountStartResult => ('status' in r ? r : { status: 'created', ...r });

/** Registration against `/public`. */
export const httpSignup: SignupService = {
  register: (input) => post<AccountStartResult>('/public/register', input).then(asAccountStart),
  applyToTeach: (input) => post<AccountVerificationPending | InstructorRequestPending>('/public/instructor-applications', input),

  resendVerification: (id) => post<AccountVerificationPending>('/public/verifications/resend', { verificationId: id }),
  confirmVerification: (id, code) => post<AccountCreated | InstructorRequestPending>('/public/verifications/verify', { verificationId: id, code: code.trim() }),
};
