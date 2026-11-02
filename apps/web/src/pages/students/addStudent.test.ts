import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { studentAdminService } from '@/services/mock/students';
import { DEMO_SIGNUP_CODE, signupService } from '@/services/mock/signup';
import { simulation } from '@/services/mock/simulation';

/* Learners joining an academy (SAAS-028), as the demo build and the join link see it. */

vi.hoisted(() => {
  (globalThis as { window?: unknown }).window ??= { location: { search: '', origin: 'https://lms.example.com' } };
});

const { signUpLink } = await import('./studentMeta');

describe('the sign-up link', () => {
  it('is the platform’s registration address', () => {
    expect(signUpLink('https://lms.example.com')).toBe('https://lms.example.com/register');
  });
});

describe('adding a learner in the demo build', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    simulation.latencyMs = 0;
  });
  afterAll(() => vi.unstubAllGlobals());

  it('adds them to the roster, and refuses an email already there', async () => {
    const student = await studentAdminService.create({ name: '  Meera Das ', email: 'Meera.Das@Example.com' });
    expect(student).toMatchObject({ name: 'Meera Das', email: 'meera.das@example.com' });
    await expect(studentAdminService.create({ name: 'Again', email: 'meera.das@example.com' })).rejects.toThrow(/already exists/);
    await expect(studentAdminService.resendInvite(student.id)).resolves.toEqual({ sentTo: 'meera.das@example.com' });
  });

  it('registers a learner after the emailed code', async () => {
    const pending = await signupService.register({ name: 'Rahul', email: 'rahul@example.com', phone: '+91 98765 43210', password: 'long-enough' });
    expect(pending).toMatchObject({ status: 'verify', role: 'student', email: 'rahul@example.com' });
    if (pending.status !== 'verify') return;
    await expect(signupService.confirmVerification(pending.verificationId, '000000')).rejects.toThrow(/not right/);
    const session = await signupService.confirmVerification(pending.verificationId, DEMO_SIGNUP_CODE);
    expect(session).toMatchObject({ status: 'created', user: { role: 'student' } });
  });
});
