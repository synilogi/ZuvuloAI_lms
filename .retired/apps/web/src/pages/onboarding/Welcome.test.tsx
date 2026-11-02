import { describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { MemoryRouter } from 'react-router-dom';
import type { Plan } from '@syniastrolms/domain';
import { buyPath, canBuy, canTrial, offeredCycles, startFreeTrial } from './welcomeFlow';

vi.hoisted(() => {
  (globalThis as { window?: unknown }).window ??= { location: { search: '', origin: 'http://localhost' } };
});

const { WelcomeView } = await import('./WelcomePage');

/* The academy's first sign-in: the plans, the free trial, and what starting it does. */

const plan = (over: Partial<Plan>): Plan =>
  ({
    id: 'growth',
    name: 'Growth',
    description: 'For a small faculty.',
    code: 'GROWTH',
    monthlyPrice: 399900,
    annualPrice: 3999000,
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    trialEnabled: true,
    trialDays: 14,
    limits: { 'learners.max': 750, 'courses.max': 40, 'instructors.max': 8, 'live_classes.max': 20, 'storage.bytes': null, 'admin_accounts.max': 3 },
    features: ['courses.manage', 'assessments.manage', 'live_classes'],
    status: 'active',
    order: 2,
    createdAt: '',
    updatedAt: '',
    ...over,
  }) as Plan;

const starter = plan({ id: 'starter', name: 'Starter', trialEnabled: false, trialDays: 0, cycles: ['monthly'], order: 1 });
const growth = plan({});

const view = (over: Partial<Parameters<typeof WelcomeView>[0]> = {}) =>
  renderToStaticMarkup(
    <MemoryRouter>
      <WelcomeView
        academyName="Jyotish Vidya Peetham"
        billing={{ plans: [growth, starter], trialAvailable: true, checkoutAvailable: false }}
        canChange
        cycle="monthly"
        onCycle={() => undefined}
        busyPlanId={null}
        error={null}
        onTrial={() => undefined}
        {...over}
      />
    </MemoryRouter>,
  );

describe('the first-plan page', () => {
  it('welcomes the academy by name and lays out every plan, cheapest first', () => {
    const html = view();
    expect(html).toMatch(/<h1[^>]*>Welcome to Jyotish Vidya Peetham<\/h1>/);
    expect(html.indexOf('Starter')).toBeLessThan(html.indexOf('Growth'));
    expect(html).toContain('₹3,999');
    expect(html).toContain('Unlimited');
    expect(html).toMatch(/Live classes<span[^>]*> \(included\)/);
    expect(html).toMatch(/Certificates<span[^>]*> \(not included\)/);
  });

  it('offers the free trial on a plan that has one, and nothing to buy without online payment', () => {
    const html = view();
    expect(html).toContain('Start 14-day free trial');
    expect(html.match(/Start \d+-day free trial/g)).toHaveLength(1);
    expect(html).not.toContain('Buy now');
    expect(html).toContain('Online payment isn’t set up yet.');
    expect(html).toContain('Start a trial, or contact the platform team');
  });

  it('offers buying where online payment is connected, through the billing page', () => {
    const html = view({ billing: { plans: [growth], trialAvailable: true, checkoutAvailable: true } });
    expect(html).toContain('Buy now');
    expect(html).toContain(`href="${buyPath(growth, 'monthly').replace(/&/g, '&amp;')}"`);
    expect(html).not.toContain('Online payment isn’t set up yet.');
  });

  it('says the trial is used, and offers none, once the academy has had it', () => {
    const html = view({ billing: { plans: [growth], trialAvailable: false, checkoutAvailable: true } });
    expect(html).toContain('This LMS has had its free trial.');
    expect(html).not.toContain('Start 14-day free trial');
  });

  it('shows why the trial did not start', () => {
    expect(view({ error: 'This academy has already had a free trial.' })).toContain('This academy has already had a free trial.');
  });

  it('asks an admin who cannot change billing to find one who can', () => {
    const html = view({ canChange: false });
    expect(html).toContain('Only an admin who can change billing settings can choose the plan.');
    expect(html).not.toContain('Start 14-day free trial');
  });

  it('puts the plan chosen before signing in first, and marks it', () => {
    const html = view({ chosenPlanId: 'growth' });
    expect(html.indexOf('Your choice')).toBeGreaterThan(-1);
    expect(html.indexOf('Growth')).toBeLessThan(html.indexOf('Starter'));
    expect(view().indexOf('Your choice')).toBe(-1);
  });

  it('says when no plan is on sale', () => {
    expect(view({ billing: { plans: [], trialAvailable: true, checkoutAvailable: false } })).toContain('No plans are on sale yet');
  });
});

describe('what each plan offers to do', () => {
  it('trials only a plan with a trial, on a cycle it is sold on, while the academy has its trial', () => {
    expect(canTrial(growth, 'monthly', { trialAvailable: true }, true)).toBe(true);
    expect(canTrial(starter, 'monthly', { trialAvailable: true }, true)).toBe(false);
    expect(canTrial(starter, 'annual', { trialAvailable: true }, true)).toBe(false);
    expect(canTrial(growth, 'monthly', { trialAvailable: false }, true)).toBe(false);
    expect(canTrial(growth, 'monthly', { trialAvailable: true }, false)).toBe(false);
  });

  it('sells only where checkout is connected', () => {
    expect(canBuy(growth, 'annual', { checkoutAvailable: true }, true)).toBe(true);
    expect(canBuy(growth, 'annual', { checkoutAvailable: false }, true)).toBe(false);
    expect(canBuy(starter, 'annual', { checkoutAvailable: true }, true)).toBe(false);
  });

  it('shows the cycle toggle only when there is a choice', () => {
    expect(offeredCycles([starter])).toEqual(['monthly']);
    expect(offeredCycles([starter, growth])).toEqual(['monthly', 'annual']);
  });
});

describe('starting the free trial', () => {
  it('starts it, then reads billing and the plan again', async () => {
    const start = vi.fn().mockResolvedValue(undefined);
    const billing = vi.fn().mockResolvedValue({});
    const academyPlan = vi.fn().mockResolvedValue({});
    const outcome = await startFreeTrial({ start, refresh: () => [billing(), academyPlan()] }, { planId: 'growth', cycle: 'monthly' });
    expect(outcome).toEqual({ ok: true });
    expect(start).toHaveBeenCalledWith({ planId: 'growth', cycle: 'monthly' });
    expect(billing).toHaveBeenCalled();
    expect(academyPlan).toHaveBeenCalled();
  });

  it('counts a failed refresh as a started trial — the next read catches up', async () => {
    const outcome = await startFreeTrial(
      { start: () => Promise.resolve(), refresh: () => [Promise.reject(new Error('offline'))] },
      { planId: 'growth', cycle: 'monthly' },
    );
    expect(outcome.ok).toBe(true);
  });

  it('answers a refusal with its message and reads nothing again', async () => {
    const refresh = vi.fn(() => [] as Promise<unknown>[]);
    const outcome = await startFreeTrial(
      { start: () => Promise.reject(new Error('Not possible right now. This academy has already had a free trial.')), refresh },
      { planId: 'growth', cycle: 'monthly' },
    );
    expect(outcome).toEqual({ ok: false, message: 'Not possible right now. This academy has already had a free trial.' });
    expect(refresh).not.toHaveBeenCalled();
  });
});
