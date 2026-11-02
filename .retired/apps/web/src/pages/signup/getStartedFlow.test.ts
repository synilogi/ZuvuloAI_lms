import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import type { Plan } from '@syniastrolms/domain';
import { accountIssues, activatePath, choiceFromQuery, codeIssue, EMPTY_ACCOUNT, effectiveSlug, resendWait, type AccountForm } from './getStartedFlow';
import { DEMO_SIGNUP_CODE, signupService } from '@/services/mock/signup';
import { simulation } from '@/services/mock/simulation';

/* Get started (SAAS-026): the steps' checks, where the visitor goes, and the demo build's registration. */

const plan = (over: Partial<Plan>): Plan =>
  ({
    id: 'p-growth',
    name: 'Growth',
    description: '',
    code: 'GROWTH',
    monthlyPrice: 399900,
    annualPrice: 3999000,
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    trialEnabled: true,
    trialDays: 14,
    limits: {},
    features: [],
    status: 'active',
    order: 1,
    createdAt: '',
    updatedAt: '',
    ...over,
  }) as Plan;

const valid: AccountForm = {
  ...EMPTY_ACCOUNT,
  academyName: 'Jyotish Vidya Academy',
  name: 'Ananya Rao',
  email: 'ananya@school.in',
  password: 'long-enough',
  confirm: 'long-enough',
  agree: true,
};

describe('the plan the pricing page sent', () => {
  const plans = [plan({}), plan({ id: 'p-starter', code: 'STARTER', cycles: ['monthly'] })];

  it('is taken by id or code, on the asked cycle when the plan sells it', () => {
    expect(choiceFromQuery(new URLSearchParams('plan=p-growth&cycle=annual'), plans)).toEqual({ planId: 'p-growth', cycle: 'annual' });
    expect(choiceFromQuery(new URLSearchParams('plan=growth'), plans)).toEqual({ planId: 'p-growth', cycle: 'monthly' });
  });

  it('falls back to a cycle the plan sells, and ignores a plan not on sale', () => {
    expect(choiceFromQuery(new URLSearchParams('plan=STARTER&cycle=annual'), plans)).toEqual({ planId: 'p-starter', cycle: 'monthly' });
    expect(choiceFromQuery(new URLSearchParams('plan=archived-one'), plans)).toBeNull();
    expect(choiceFromQuery(new URLSearchParams(''), plans)).toBeNull();
  });
});

describe('the account form', () => {
  it('is ready when every field is filled in properly', () => {
    expect(accountIssues(valid)).toEqual({});
  });

  it('says what each field is missing', () => {
    const issues = accountIssues({ ...EMPTY_ACCOUNT, password: 'short', confirm: 'other' });
    expect(Object.keys(issues).sort()).toEqual(['academyName', 'agree', 'confirm', 'email', 'name', 'password']);
  });

  it('derives the address from the name until it is edited, and checks an edited one', () => {
    expect(effectiveSlug(valid)).toBe('jyotish-vidya-academy');
    expect(effectiveSlug({ ...valid, slug: 'JVA', slugEdited: true })).toBe('jva');
    expect(accountIssues({ ...valid, slug: 'superadmin', slugEdited: true }).slug).toMatch(/reserved/);
    expect(accountIssues({ ...valid, slug: 'a', slugEdited: true }).slug).toBeDefined();
  });
});

describe('the verification step', () => {
  it('accepts six digits only', () => {
    expect(codeIssue('123456')).toBeUndefined();
    expect(codeIssue('12345')).toBeDefined();
    expect(codeIssue('12345a')).toBeDefined();
  });

  it('counts down to the next resend', () => {
    const now = Date.parse('2026-10-03T10:00:00Z');
    expect(resendWait('2026-10-03T10:00:30Z', now)).toBe(30);
    expect(resendWait('2026-10-03T09:59:00Z', now)).toBe(0);
  });

  it('sends the new admin to their plan page, with their choice marked', () => {
    expect(activatePath(null)).toBe('/admin/welcome');
    expect(activatePath({ planId: 'p-growth', cycle: 'annual' })).toBe('/admin/welcome?plan=p-growth&cycle=annual');
  });
});

describe('the demo build’s registration', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    simulation.latencyMs = 0;
  });
  afterAll(() => {
    vi.unstubAllGlobals();
  });

  it('holds the registration until the demo code confirms it, and refuses a wrong code', async () => {
    const started = await signupService.start({
      academyName: 'Demo',
      name: 'Demo Admin',
      email: 'demo@example.com',
      password: 'long-enough',
      acceptTerms: true,
    });
    expect(started.status).toBe('verify');
    if (started.status !== 'verify') return;
    await expect(signupService.verify(started.signupId, '000000')).rejects.toThrow(/not right/);
    await expect(signupService.resend(started.signupId)).rejects.toThrow(/Wait/);
    const created = await signupService.verify(started.signupId, DEMO_SIGNUP_CODE);
    expect(created.user.role).toBe('admin');
    await expect(signupService.verify(started.signupId, DEMO_SIGNUP_CODE)).rejects.toThrow(/no longer open/);
  });

  it('lists only plans on sale', async () => {
    const { plans } = await signupService.plans();
    expect(plans.length).toBeGreaterThan(0);
    expect(plans.every((p) => p.status === 'active')).toBe(true);
  });
});
