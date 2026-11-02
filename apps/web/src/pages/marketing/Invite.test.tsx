import { describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { MemoryRouter } from 'react-router-dom';
import type { ReactNode } from 'react';
import type { AsyncState } from '@/hooks/useAsync';
import type { InvitationDetails } from '@/services/contracts';
import { ServiceError } from '@/services/contracts';
import { joinFailure } from './joinFailure';

// The session module reads the address bar when it loads; the server renderer has none.
vi.hoisted(() => {
  (globalThis as { window?: unknown }).window ??= { location: { search: '', origin: 'http://localhost' } };
});

const { InviteView } = await import('./InvitePage');

/* A learner invitation (`/invite/<token>`) in each of its states, and what each refusal means on the page. */

const render = (node: ReactNode) => renderToStaticMarkup(<MemoryRouter>{node}</MemoryRouter>);
const details = (over: Partial<InvitationDetails> = {}): InvitationDetails => ({
  lms: { name: 'Jyotish Vidya Peetham', slug: 'jyotish-vidya' },
  role: 'student',
  email: null,
  expiresAt: '2026-10-12T10:00:00.000Z',
  open: true,
  ...over,
});
const loaded = (data: InvitationDetails): AsyncState<InvitationDetails> => ({ status: 'success', data });
const view = (load: AsyncState<InvitationDetails>, initialMode: 'create' | 'sign-in' = 'create') =>
  render(<InviteView load={load} token={'a'.repeat(64)} onJoined={() => undefined} retry={() => undefined} initialMode={initialMode} />);

describe('the invitation page', () => {
  it('names the LMS and asks a new learner to create an account', () => {
    const html = view(loaded(details()));
    expect(html).toMatch(/<h1[^>]*>Join Jyotish Vidya Peetham<\/h1>/);
    expect(html).toContain('Create account');
    expect(html).toContain('I already have an account');
    expect(html).toContain('Full name');
    expect(html).toContain('Confirm password');
    expect(html).toContain('This invitation works once');
    expect(html).not.toMatch(/academy/i);
  });

  it('fills in and locks the address an invitation is bound to', () => {
    const html = view(loaded(details({ email: 'meera@example.com' })));
    expect(html).toMatch(/<input[^>]*type="email" readonly=""[^>]*value="meera@example.com"/);
    expect(html).toContain('This invitation is for meera@example.com.');
  });

  it('lets someone already learning there sign in instead', () => {
    const html = view(loaded(details()), 'sign-in');
    expect(html).toContain('Sign in and join');
    expect(html).not.toContain('Full name');
  });

  it('says plainly when the link is no longer valid', () => {
    const error = new ServiceError('This invitation link isn’t valid. It may have expired, been used or been withdrawn.', 'not-found', 'INVITE_INVALID');
    const html = view({ status: 'error', error });
    expect(html).toContain('This invitation link isn’t valid');
    expect(html).toContain('It may have expired, been used or been withdrawn.');
    expect(html).not.toContain('Create account');
  });

  it('says when the LMS takes nobody new', () => {
    const html = view(loaded(details({ open: false })));
    expect(html).toContain('Jyotish Vidya Peetham isn’t taking new learners right now');
    expect(html).not.toContain('Full name');
  });
});

describe('what a refused join means', () => {
  const lms = 'Jyotish Vidya Peetham';
  it('a used or expired link replaces the form', () => {
    expect(joinFailure(new ServiceError('Gone.', 'not-found', 'INVITE_INVALID'), lms, 'register')).toEqual({ fields: {}, invalid: 'Gone.' });
  });
  it('a closed workspace is said in a learner’s words', () => {
    expect(joinFailure(new ServiceError('Not accepting.', 'forbidden', 'ACADEMY_SUSPENDED'), lms, 'register').banner?.title).toBe(
      `${lms} isn’t taking new learners right now`,
    );
  });
  it('server field issues go beside their fields', () => {
    const taken = new ServiceError('An account with this email already exists.', 'conflict', 'CONFLICT', [
      { field: 'email', message: 'An account with this email already exists.' },
    ]);
    expect(joinFailure(taken, lms, 'register').fields).toEqual({ email: 'An account with this email already exists.' });
    const invalid = new ServiceError('Check the request.', 'conflict', 'VALIDATION_FAILED', [
      { field: 'name', message: 'Enter your full name.' },
      { field: 'password', message: 'Password must be at least 8 characters.' },
    ]);
    expect(joinFailure(invalid, lms, 'register').fields).toEqual({ name: 'Enter your full name.', password: 'Password must be at least 8 characters.' });
  });
  it('a different address, a wrong password and an account elsewhere each say so', () => {
    const wrong = new ServiceError('This invitation is for a different email address. Use the address it was sent to.', 'forbidden', undefined, undefined, 403);
    expect(joinFailure(wrong, lms, 'register').fields.email).toMatch(/different email/);
    const password = new ServiceError('Incorrect email or password.', 'conflict', undefined, undefined, 401);
    expect(joinFailure(password, lms, 'sign-in').fields.password).toBe('Incorrect email or password.');
    const elsewhere = new ServiceError('This account belongs to another LMS, so this invitation can’t be used with it.', 'conflict', undefined, undefined, 409);
    expect(joinFailure(elsewhere, lms, 'sign-in').banner?.title).toBe('This account can’t be used here');
  });
});
