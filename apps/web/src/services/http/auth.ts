import type { UserProfile } from '@syniastrolms/domain';

import { ServiceError, type AccountService } from '../contracts';
import { get, post, setToken } from './client';

export async function login(email: string, password: string): Promise<UserProfile> {
  const { token, user } = await post<{ token: string; user: UserProfile }>('/auth/login', { email, password });
  setToken(token);
  return user;
}

/** Public registration always creates a learner account. */
export async function register(name: string, email: string, password: string): Promise<UserProfile> {
  const { token, user } = await post<{ token: string; user: UserProfile }>('/auth/register', { name, email, password });
  setToken(token);
  return user;
}

/** Keeps a session the API started elsewhere — the token a verified registration answers with. */
export function adoptSession(token: string) {
  setToken(token);
}

export async function me(): Promise<UserProfile> {
  const { user } = await get<{ user: UserProfile }>('/auth/me');
  return user;
}

export function logout() {
  setToken(null);
}

/**
 * Whether a failed session read means the stored token is finished. The API refusing it (signed out,
 * deactivated, suspended) does; the API being unreachable or failing (a deploy restarting it, a dropped
 * connection, a navigation aborting the request) does not — forgetting a good token then would sign the
 * person out for a moment's outage.
 */
export const sessionRefused = (error: unknown): boolean => !(error instanceof ServiceError && (error.code === 'network' || error.code === 'unknown'));

/** Always resolves — the API never reveals whether the address matches an account. */
export async function forgotPassword(email: string): Promise<void> {
  await post<{ ok: true }>('/auth/forgot-password', { email });
}

/** Whether a reset link is usable; `lms` names the LMS an invited instructor or learner is joining. */
export async function checkResetToken(token: string): Promise<{ valid: boolean; lms?: string }> {
  const { valid, lms } = await get<{ valid: boolean; lms?: string }>(`/auth/reset-password/${encodeURIComponent(token)}`);
  return { valid, ...(valid && lms ? { lms } : {}) };
}

/** Rejects with a conflict when the link is invalid or expired. */
export async function resetPassword(token: string, password: string): Promise<void> {
  await post<{ ok: true }>('/auth/reset-password', { token, password });
}

/** Learners only; the API ends every session on success, so the caller signs out locally too. */
export async function deleteAccount(password: string): Promise<void> {
  await post<{ ok: true }>('/auth/delete-account', { password });
}

export const httpAccount: AccountService = { deleteAccount };
