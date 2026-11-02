import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { AcademyPlan } from '@syniastrolms/domain';
import { BILLING_REFUSAL_EVENT } from './client';
import { httpTenantBilling } from './tenantBilling';

/* The academy's own plan and its self-serve trial, against `/academy/plan` and `/tenant/billing/trial`. */

interface Call {
  url: URL;
  init: RequestInit;
  body?: unknown;
}

function stubFetch(status: number, payload: unknown): Call[] {
  const calls: Call[] = [];
  vi.stubGlobal('fetch', (input: string, init: RequestInit) => {
    calls.push({ url: new URL(input), init, body: init.body ? JSON.parse(String(init.body)) : undefined });
    return Promise.resolve(new Response(JSON.stringify(payload), { status, headers: { 'content-type': 'application/json' } }));
  });
  return calls;
}

const events: string[] = [];
beforeEach(() => {
  events.length = 0;
  vi.stubGlobal('window', { dispatchEvent: (e: CustomEvent<{ code: string }>) => events.push(`${e.type}:${e.detail?.code ?? ''}`) });
});
afterEach(() => vi.unstubAllGlobals());

describe('the academy’s plan', () => {
  it('is read from /academy/plan, exactly as the API answers', async () => {
    const plan: AcademyPlan = {
      enforced: true,
      status: 'trialing',
      restricted: false,
      plan: { id: 'p1', code: 'GROWTH', name: 'Growth' },
      features: ['courses.manage', 'reports.basic'],
      lastFeatures: [],
      trialEndsAt: '2026-10-17T00:00:00.000Z',
    };
    const calls = stubFetch(200, plan);
    await expect(httpTenantBilling.academyPlan()).resolves.toEqual(plan);
    expect(calls[0].url.pathname).toBe('/academy/plan');
    expect(calls[0].init.method).toBe('GET');
  });
});

describe('starting the free trial', () => {
  it('names only the plan and the cycle — no price, no payment, no address', async () => {
    const calls = stubFetch(201, { subscription: { id: 's1', status: 'trialing' } });
    await expect(httpTenantBilling.startTrial({ planId: 'p1', cycle: 'monthly' })).resolves.toBeUndefined();
    expect(calls[0].url.pathname).toBe('/tenant/billing/trial');
    expect(calls[0].init.method).toBe('POST');
    expect(calls[0].body).toEqual({ planId: 'p1', cycle: 'monthly' });
  });

  it('turns a second trial into its state, with the server’s reason', async () => {
    stubFetch(409, { code: 'INVALID_SUBSCRIPTION_STATE', message: 'This academy has already had a free trial.' });
    await expect(httpTenantBilling.startTrial({ planId: 'p1', cycle: 'monthly' })).rejects.toMatchObject({
      reason: 'INVALID_SUBSCRIPTION_STATE',
      message: expect.stringContaining('already had a free trial'),
    });
    expect(events).toEqual([`${BILLING_REFUSAL_EVENT}:INVALID_SUBSCRIPTION_STATE`]);
  });

  it('turns a plan without a trial into its state', async () => {
    stubFetch(409, { code: 'PLAN_UNAVAILABLE', message: 'Starter has no free trial.' });
    await expect(httpTenantBilling.startTrial({ planId: 'p2', cycle: 'annual' })).rejects.toMatchObject({ reason: 'PLAN_UNAVAILABLE' });
  });
});
