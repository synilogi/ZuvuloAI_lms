import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { ServiceError } from '../contracts';
import { EXPIRED_DEMO_INVITE, invitationService } from './invitations';
import { simulation } from './simulation';

/* Learner invitations and course links in the demo build: made, used once, withdrawn — refused the way the API refuses. */

beforeAll(() => {
  vi.stubGlobal('window', Object.assign(globalThis, { location: { search: '', origin: 'https://lms.example.com' } }));
  simulation.latencyMs = 0;
});
afterAll(() => vi.unstubAllGlobals());

const tokenOf = (url: string) => url.split('/invite/')[1];
const reasonOf = (promise: Promise<unknown>) =>
  promise.then(
    () => 'resolved',
    (err: unknown) => (err instanceof ServiceError ? (err.reason ?? err.code) : 'thrown'),
  );

describe('an Admin’s invitations in the demo build', () => {
  it('makes a one-time link of 64 hex characters on this site, listed as pending', async () => {
    const { invitation, url } = await invitationService.create({});
    expect(url).toMatch(/^https:\/\/lms\.example\.com\/invite\/[a-f0-9]{64}$/);
    expect(invitation).toMatchObject({ email: null, status: 'pending', usedAt: null });
    expect(Date.parse(invitation.expiresAt) - Date.now()).toBeGreaterThan(6.9 * 86_400_000);
    expect((await invitationService.list()).map((r) => r.id)).toContain(invitation.id);
  });

  it('binds a link to an address, and refuses an address that already has an account', async () => {
    const { invitation, url } = await invitationService.create({ email: '  New.Learner@Example.com ' });
    expect(invitation.email).toBe('new.learner@example.com');
    await expect(invitationService.describe(tokenOf(url))).resolves.toMatchObject({ email: 'new.learner@example.com', open: true, role: 'student' });
    const taken = await invitationService.create({ email: 'kavita@zuviloai.com' }).catch((e: ServiceError) => e);
    expect(taken).toBeInstanceOf(ServiceError);
  });

  it('is used once: a second visit finds the link no longer valid', async () => {
    const { invitation, url } = await invitationService.create({});
    const token = tokenOf(url);
    const session = await invitationService.register(token, { name: 'Rahul Verma', email: 'rahul@example.com', password: 'long-enough' });
    expect(session).toMatchObject({ status: 'created', user: { role: 'student', name: 'Rahul Verma', email: 'rahul@example.com' } });
    expect(await reasonOf(invitationService.describe(token))).toBe('INVITE_INVALID');
    expect((await invitationService.list()).find((r) => r.id === invitation.id)?.status).toBe('accepted');
  });

  it('refuses another address on a bound link, and a staff account signing in', async () => {
    const { url } = await invitationService.create({ email: 'only.me@example.com' });
    const token = tokenOf(url);
    const wrong = await invitationService
      .register(token, { name: 'Someone', email: 'other@example.com', password: 'long-enough' })
      .catch((e: ServiceError) => e);
    expect(wrong).toMatchObject({ code: 'forbidden', message: expect.stringMatching(/different email/) });
    const staff = await invitationService.signIn(token, { email: 'meenakshi@zuviloai.com', password: 'x' }).catch((e: ServiceError) => e);
    expect(staff).toMatchObject({ code: 'conflict', message: expect.stringMatching(/another LMS/) });
    await expect(invitationService.signIn(token, { email: 'only.me@example.com', password: 'secret' })).resolves.toMatchObject({ token: 'demo' });
  });

  it('withdraws a pending link, which then stops working; an accepted one can’t be withdrawn', async () => {
    const { invitation, url } = await invitationService.create({});
    await expect(invitationService.revoke(invitation.id)).resolves.toMatchObject({ status: 'revoked' });
    expect(await reasonOf(invitationService.describe(tokenOf(url)))).toBe('INVITE_INVALID');

    const used = await invitationService.create({});
    await invitationService.register(tokenOf(used.url), { name: 'Asha', email: 'asha@example.com', password: 'long-enough' });
    expect(await reasonOf(invitationService.revoke(used.invitation.id))).toBe('conflict');
  });

  it('refuses a malformed or expired link', async () => {
    expect(await reasonOf(invitationService.describe('not-a-token'))).toBe('INVITE_INVALID');
    expect(await reasonOf(invitationService.describe(EXPIRED_DEMO_INVITE))).toBe('INVITE_INVALID');
    // A well-formed link the demo has not seen opens the demo LMS, once.
    const pasted = 'ab'.repeat(32);
    await expect(invitationService.describe(pasted)).resolves.toMatchObject({ lms: { slug: 'demo' }, email: null });
    await invitationService.register(pasted, { name: 'Pasted', email: 'pasted@example.com', password: 'long-enough' });
    expect(await reasonOf(invitationService.describe(pasted))).toBe('INVITE_INVALID');
  });
});

describe('a course link in the demo build', () => {
  it('names a published course and its LMS, and enrols a new learner in a free course', async () => {
    await expect(invitationService.courseLink('intro-jyotish')).resolves.toMatchObject({ course: { id: 'intro-jyotish', sale: { kind: 'free' } }, open: true });
    await expect(invitationService.joinCourse('intro-jyotish', { name: 'Neha', email: 'neha@example.com', password: 'long-enough' })).resolves.toMatchObject({
      enrolled: true,
      user: { role: 'student' },
    });
  });

  it('makes the account for a paid course, but leaves the course to be bought', async () => {
    await expect(invitationService.courseLink('foundations-vedic')).resolves.toMatchObject({ course: { sale: { kind: 'paid', price: { amount: 18500 } } } });
    await expect(
      invitationService.joinCourse('foundations-vedic', { name: 'Ravi', email: 'ravi@example.com', password: 'long-enough' }),
    ).resolves.toMatchObject({ enrolled: false, enrolmentCode: 'COURSE_PURCHASE_REQUIRED', user: { role: 'student' } });
  });

  it('finds no unknown course', async () => {
    expect(await reasonOf(invitationService.courseLink('no-such-course'))).toBe('not-found');
  });
});
