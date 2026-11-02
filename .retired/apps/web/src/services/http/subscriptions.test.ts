/// <reference types="node" />
import { readFileSync, readdirSync, statSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { Plan, PlanInput } from '@syniastrolms/domain';
import { BILLING_REFUSAL_CODES, BILLING_STATES, billingStateOf } from '@/lib/billingStates';
import { PlanStatusError, ServiceError } from '../contracts';
import { BILLING_REFUSAL_EVENT } from './client';
import { httpServices } from './httpServices';
import { httpSubscriptions } from './subscriptions';
import { httpTenantBilling } from './tenantBilling';

/* SAAS-015: the subscription screens against the billing API — what each call asks for, that the client
 * never sends a price or a timing the server decides, and that every §34 refusal arrives as a state. */

interface Call {
  url: URL;
  init: RequestInit;
  body?: unknown;
}

/** Answers each request with the next of `replies` (the last one repeats), recording what was asked. */
function stubFetch(...replies: { status?: number; body: unknown }[]): Call[] {
  const calls: Call[] = [];
  vi.stubGlobal('fetch', (input: string, init: RequestInit) => {
    calls.push({ url: new URL(input), init, body: init.body ? JSON.parse(String(init.body)) : undefined });
    const reply = replies[Math.min(calls.length - 1, replies.length - 1)];
    return Promise.resolve(new Response(JSON.stringify(reply.body), { status: reply.status ?? 200, headers: { 'content-type': 'application/json' } }));
  });
  return calls;
}

const events: string[] = [];
beforeEach(() => {
  events.length = 0;
  vi.stubGlobal('window', { dispatchEvent: (e: CustomEvent<{ code: string }>) => events.push(`${e.type}:${e.detail?.code ?? ''}`) });
});
afterEach(() => vi.unstubAllGlobals());

const plan = (over: Partial<Plan> = {}): Plan => ({
  id: 'p1',
  name: 'Growth',
  description: 'For growing academies.',
  code: 'GROWTH',
  monthlyPrice: 399900,
  annualPrice: 3999000,
  currency: 'INR',
  cycles: ['monthly', 'annual'],
  trialEnabled: true,
  trialDays: 14,
  limits: { 'learners.max': 500, 'instructors.max': 10, 'courses.max': 50, 'storage.bytes': null, 'live_classes.max': 20, 'admin_accounts.max': 3 },
  features: ['courses.manage'],
  status: 'draft',
  order: 2,
  createdAt: '2026-09-01T00:00:00.000Z',
  updatedAt: '2026-09-01T00:00:00.000Z',
  ...over,
});
const planDetail = (over: Partial<Plan> = {}) => ({
  plan: plan(over),
  subscribers: 0,
  activeSubscribers: 0,
  mrr: 0,
  trend: [],
  subscriptions: [],
  byStatus: [],
});
const subscriptionDetail = (status = 'active') => ({
  subscription: { id: 's1', status, planId: 'p1', cycle: 'monthly', customer: { id: 't1', name: 'Academy' } },
  plan: plan(),
  events: [],
  invoices: [],
});

describe('the Super Admin screens read the billing API’s own read models', () => {
  it('reads each view from /superadmin/billing-views, passing the filters as they are', async () => {
    const calls = stubFetch({ body: {} });
    await httpSubscriptions.overview();
    await httpSubscriptions.listPlans({ status: 'active', sort: 'price', search: 'gro' });
    await httpSubscriptions.getPlan('p1');
    await httpSubscriptions.listSubscribers({ status: 'past-due', planId: 'p1', page: 2, pageSize: 20 });
    await httpSubscriptions.getSubscription('s1');
    await httpSubscriptions.listPayments({ status: 'failed' });
    await httpSubscriptions.getInvoice('INV-2026-000001');
    expect(calls.map((c) => `${c.init.method} ${c.url.pathname}${c.url.search}`)).toEqual([
      'GET /superadmin/billing-views/overview',
      'GET /superadmin/billing-views/plans?status=active&sort=price&search=gro',
      'GET /superadmin/billing-views/plans/p1',
      // The version history is the plan record's.
      'GET /superadmin/plans/p1',
      'GET /superadmin/billing-views/subscribers?status=past-due&planId=p1&page=2&pageSize=20',
      'GET /superadmin/billing-views/subscriptions/s1',
      // The open plan changes, the payments and the lifecycle are the subscription record's.
      'GET /superadmin/subscriptions/s1',
      'GET /superadmin/billing-views/payments?status=failed',
      'GET /superadmin/billing-views/invoices/INV-2026-000001',
    ]);
  });

  it('is what http mode uses — no screen reads the demo’s records against the API', () => {
    expect(httpServices.subscriptions).toBe(httpSubscriptions);
    expect(httpServices.tenantBilling).toBe(httpTenantBilling);
  });
});

describe('the Super Admin’s changes go through the billing endpoints', () => {
  it('creates a plan as a draft and publishes it through its own step', async () => {
    const calls = stubFetch({ status: 201, body: { id: 'p9' } }, { body: {} }, { body: planDetail({ id: 'p9', status: 'active' }) });
    const input: PlanInput = { ...plan(), status: 'active' };
    const created = await httpSubscriptions.createPlan(input);
    expect(calls[0]).toMatchObject({ init: { method: 'POST' } });
    expect(calls[0].url.pathname).toBe('/superadmin/plans');
    expect(calls[0].body).not.toHaveProperty('status');
    expect(calls[0].body).toMatchObject({ monthlyPrice: 399900, annualPrice: 3999000, displayOrder: 2 });
    expect(calls[1].url.pathname).toBe('/superadmin/plans/p9/publish');
    expect(created.status).toBe('active');
  });

  it('edits a plan, then archives or restores it by the named steps', async () => {
    const calls = stubFetch({ body: planDetail({ status: 'active' }) });
    await httpSubscriptions.updatePlan('p1', { ...plan(), status: 'archived' });
    expect(calls.map((c) => `${c.init.method} ${c.url.pathname}`)).toEqual([
      'GET /superadmin/billing-views/plans/p1',
      'PATCH /superadmin/plans/p1',
      'POST /superadmin/plans/p1/archive',
      'GET /superadmin/billing-views/plans/p1',
    ]);
  });

  it('duplicates a plan as a draft under the first free code', async () => {
    const list = { rows: [{ plan: plan({ code: 'GROWTH' }) }, { plan: plan({ code: 'GROWTH-2' }) }], counts: { all: 2, active: 0, draft: 2, archived: 0 } };
    const calls = stubFetch({ body: planDetail() }, { body: list }, { status: 201, body: { id: 'p3' } }, { body: planDetail({ id: 'p3' }) });
    await httpSubscriptions.duplicatePlan('p1');
    const create = calls.find((c) => c.init.method === 'POST')!;
    expect(create.body).toMatchObject({ code: 'GROWTH-3', name: 'Growth (copy)' });
  });

  it('asks for a plan change with the plan and cycle only — when it applies is the rules’, not the screen’s', async () => {
    const calls = stubFetch({ status: 201, body: {} }, { body: subscriptionDetail() });
    await httpSubscriptions.changePlan('s1', { planId: 'p2', cycle: 'annual' });
    expect(calls[0].url.pathname).toBe('/superadmin/subscriptions/s1/plan-change');
    expect(calls[0].body).toEqual({ planId: 'p2', cycle: 'annual' });
  });

  it('pauses, resumes and cancels, sending what each endpoint takes', async () => {
    const calls = stubFetch({ body: subscriptionDetail() });
    await httpSubscriptions.pause('s1', 14);
    await httpSubscriptions.resume('s1');
    await httpSubscriptions.cancel('s1', { reason: 'Cohort finished.', effective: 'immediately' });
    await httpSubscriptions.cancel('s1', { reason: 'Cohort finished.', effective: 'period-end' });
    const writes = calls.filter((c) => c.init.method === 'POST');
    expect(writes.map((c) => [c.url.pathname, c.body])).toEqual([
      ['/superadmin/subscriptions/s1/pause', { days: 14 }],
      ['/superadmin/subscriptions/s1/resume', {}],
      ['/superadmin/subscriptions/s1/cancel', { reason: 'Cohort finished.', immediately: true }],
      ['/superadmin/subscriptions/s1/cancel', { reason: 'Cohort finished.', immediately: false }],
    ]);
  });

  it('reactivates by withdrawing a pending cancellation, or by starting a new subscription for one that is over', async () => {
    const canceling = stubFetch({ body: subscriptionDetail('canceling') });
    await httpSubscriptions.reactivate('s1');
    expect(canceling.filter((c) => c.init.method === 'POST').map((c) => c.url.pathname)).toEqual(['/superadmin/subscriptions/s1/resume']);

    const over = stubFetch(
      { body: subscriptionDetail('canceled') },
      { body: subscriptionDetail('canceled') },
      { status: 201, body: { id: 's2' } },
      { body: subscriptionDetail() },
    );
    await httpSubscriptions.reactivate('s1');
    const started = over.find((c) => c.init.method === 'POST')!;
    expect(started.url.pathname).toBe('/superadmin/subscriptions');
    expect(started.body).toEqual({ tenantId: 't1', planId: 'p1', cycle: 'monthly', start: 'active' });
    expect(over.slice(-2).map((c) => c.url.pathname)).toEqual(['/superadmin/billing-views/subscriptions/s2', '/superadmin/subscriptions/s2']);
  });
});

describe('a plan’s status moves only where the rules allow, checked before anything is sent', () => {
  it('refuses to take a plan that has been offered back to draft, without sending the edit', async () => {
    const calls = stubFetch({ body: planDetail({ status: 'active' }) });
    const error = await httpSubscriptions.updatePlan('p1', { ...plan(), status: 'draft' }).catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ServiceError);
    expect(calls.map((c) => c.init.method)).toEqual(['GET']);
  });

  it('carries the created draft on the error when publishing it is refused, so the screen does not create it twice', async () => {
    const calls = stubFetch(
      { status: 201, body: { id: 'p9' } },
      { status: 409, body: { message: 'Enter a price above zero for the monthly cycle, or stop offering it.', code: 'VALIDATION_FAILED' } },
      { body: planDetail({ id: 'p9', status: 'draft' }) },
    );
    const error = (await httpSubscriptions.createPlan({ ...plan(), status: 'active' }).catch((e: unknown) => e)) as PlanStatusError;
    expect(error).toBeInstanceOf(PlanStatusError);
    expect(error.message).toContain('price above zero');
    expect(error.plan).toMatchObject({ id: 'p9', status: 'draft' });
    expect(calls.filter((c) => c.url.pathname === '/superadmin/plans' && c.init.method === 'POST')).toHaveLength(1);
  });

  it('publishes a draft through its own step', async () => {
    const calls = stubFetch({ body: planDetail({ status: 'active' }) });
    await httpSubscriptions.publishPlan('p1');
    expect(calls[0]).toMatchObject({ init: { method: 'POST' } });
    expect(calls[0].url.pathname).toBe('/superadmin/plans/p1/publish');
  });

  it('reads the plan’s version history from the plan record', async () => {
    const version = {
      id: 'v1',
      version: 1,
      currency: 'INR',
      monthlyPrice: 399900,
      annualPrice: null,
      cycles: ['monthly'],
      trialDays: 0,
      features: [],
      limits: {},
      createdAt: '2026-09-01T00:00:00.000Z',
    };
    stubFetch({ body: planDetail() }, { body: { plan: {}, versions: [version] } });
    expect((await httpSubscriptions.getPlan('p1')).versions).toEqual([version]);
  });
});

describe('a subscription’s detail adds what the view leaves out', () => {
  const records = {
    subscription: { id: 's1' },
    lifecycle: [
      { id: 7, transition: 'extend', event: 'subscription.extended', meta: { days: 10, reason: 'Goodwill after the outage' } },
      { id: 6, transition: 'pause', event: 'subscription.paused', meta: { days: 7 } },
    ],
    planChanges: [
      {
        id: 'c1',
        kind: 'downgrade',
        status: 'scheduled',
        to: { planId: 'p0', planVersionId: 'v0', cycle: 'monthly', amount: 99900 },
        currency: 'INR',
        credit: 0,
        charge: 0,
        period: { start: '2026-09-01T00:00:00.000Z', end: '2026-10-01T00:00:00.000Z' },
        quotedAt: '2026-09-10T00:00:00.000Z',
      },
      {
        id: 'c0',
        kind: 'upgrade',
        status: 'applied',
        to: { planId: 'p1', cycle: 'monthly', amount: 1 },
        currency: 'INR',
        credit: 0,
        charge: 1,
        period: { start: '', end: '' },
        quotedAt: '',
      },
    ],
    payments: [
      {
        id: 'pay1',
        provider: 'offline',
        providerPaymentId: 'offline_1',
        amount: 471882,
        currency: 'INR',
        status: 'partially_refunded',
        refunded: 1000,
        refundable: 470882,
        method: { kind: 'invoice', brand: 'Bank transfer', display: 'Bank transfer' },
        paidAt: '2026-09-02T00:00:00.000Z',
        createdAt: '2026-09-02T00:00:00.000Z',
      },
    ],
  };
  const view = {
    ...subscriptionDetail(),
    events: [
      { id: 'event-7', subscriptionId: 's1', kind: 'created', at: '2026-09-12T00:00:00.000Z', summary: 'subscription.extended', actor: 'A person' },
      { id: 'event-6', subscriptionId: 's1', kind: 'paused', at: '2026-09-11T00:00:00.000Z', summary: 'Paused for 7 days.', actor: 'A person' },
    ],
  };

  it('keeps the open plan changes and the payments, and words an extension', async () => {
    stubFetch({ body: view }, { body: records });
    const detail = await httpSubscriptions.getSubscription('s1');
    expect(detail.openChanges).toEqual([expect.objectContaining({ id: 'c1', kind: 'downgrade', toPlanId: 'p0', periodEnd: '2026-10-01T00:00:00.000Z' })]);
    expect(detail.payments).toEqual([
      expect.objectContaining({ id: 'pay1', method: 'Bank transfer', refundable: 470882, at: '2026-09-02T00:00:00.000Z', status: 'partially_refunded' }),
    ]);
    expect(detail.events.map((e) => [e.kind, e.summary])).toEqual([
      ['extended', 'Complimentary days added (10 days) — Goodwill after the outage.'],
      ['paused', 'Paused for 7 days.'],
    ]);
  });

  it('adds complimentary days, then reads the subscription again', async () => {
    const calls = stubFetch({ body: {} }, { body: view }, { body: records });
    await httpSubscriptions.extend('s1', { days: 10, reason: 'Goodwill after the outage' });
    expect(calls[0].url.pathname).toBe('/superadmin/subscriptions/s1/extend');
    expect(calls[0].body).toEqual({ days: 10, reason: 'Goodwill after the outage' });
  });

  it('starts an academy’s subscription naming the plan, cycle and start only', async () => {
    const calls = stubFetch({ status: 201, body: { id: 's9' } }, { body: view }, { body: records });
    await httpSubscriptions.startSubscription({ tenantId: 't1', planId: 'p1', cycle: 'annual', start: 'trial' });
    expect(calls[0].url.pathname).toBe('/superadmin/subscriptions');
    expect(calls[0].body).toEqual({ tenantId: 't1', planId: 'p1', cycle: 'annual', start: 'trial' });
    expect(calls.slice(1).map((c) => c.url.pathname)).toEqual(['/superadmin/billing-views/subscriptions/s9', '/superadmin/subscriptions/s9']);
  });
});

describe('the platform settles invoices and payments through the billing endpoints', () => {
  it('records an offline payment with no amount — the invoice’s total is the server’s', async () => {
    const calls = stubFetch({ status: 201, body: { status: 'paid', settled: true, applied: true, message: 'Recorded.' } });
    const outcome = await httpSubscriptions.recordInvoicePayment('inv1', { method: 'cheque', reference: 'CHQ 004512' });
    expect(outcome.status).toBe('paid');
    expect(calls[0].url.pathname).toBe('/superadmin/invoices/inv1/record-payment');
    expect(calls[0].body).toEqual({ method: 'cheque', reference: 'CHQ 004512' });
  });

  it('voids an open invoice with a reason, then reads it again', async () => {
    const calls = stubFetch({ body: {} });
    await httpSubscriptions.voidInvoice('inv1', 'Raised in error.');
    expect(calls.map((c) => [`${c.init.method} ${c.url.pathname}`, c.body])).toEqual([
      ['POST /superadmin/invoices/inv1/void', { reason: 'Raised in error.' }],
      ['GET /superadmin/billing-views/invoices/inv1', undefined],
    ]);
  });

  it('refunds in full by naming no amount, or in part by naming one in minor units', async () => {
    const calls = stubFetch({ status: 201, body: { id: 'r1', amount: 1000, currency: 'INR', status: 'succeeded' } });
    await httpSubscriptions.refundPayment('pay1', { reason: 'Duplicate charge.' });
    await httpSubscriptions.refundPayment('pay1', { amount: 1000, reason: 'Partial goodwill.' });
    expect(calls.map((c) => [c.url.pathname, c.body])).toEqual([
      ['/superadmin/payments/pay1/refund', { reason: 'Duplicate charge.' }],
      ['/superadmin/payments/pay1/refund', { amount: 1000, reason: 'Partial goodwill.' }],
    ]);
  });
});

describe('webhooks, tax rules and academies', () => {
  it('reads webhook receipts and tax rules with their filters', async () => {
    const calls = stubFetch({ body: { rows: [], total: 0, page: 1, pageSize: 20 } });
    await httpSubscriptions.listWebhooks({ status: 'failed', page: 2 });
    await httpSubscriptions.listWebhooks({ status: 'all' });
    await httpSubscriptions.listTaxRules({ includeRetired: true });
    await httpSubscriptions.listTaxRules();
    expect(calls.map((c) => `${c.url.pathname}${c.url.search}`)).toEqual([
      '/superadmin/webhooks?status=failed&page=2&pageSize=20',
      '/superadmin/webhooks?page=1&pageSize=20',
      '/superadmin/tax-rules?includeRetired=true',
      '/superadmin/tax-rules',
    ]);
  });

  it('sets and retires a tax rule', async () => {
    const calls = stubFetch({ status: 201, body: {} });
    await httpSubscriptions.createTaxRule({ name: 'GST', country: 'IN', components: [{ code: 'GST', label: 'GST', rateBps: 1800 }] });
    await httpSubscriptions.retireTaxRule('t1');
    expect(calls.map((c) => [c.url.pathname, c.body])).toEqual([
      ['/superadmin/tax-rules', { name: 'GST', country: 'IN', inclusive: false, components: [{ code: 'GST', label: 'GST', rateBps: 1800 }] }],
      ['/superadmin/tax-rules/t1/retire', {}],
    ]);
  });

  it('reads an academy’s billing, treating no billing profile as none yet', async () => {
    stubFetch(
      { body: { academy: { id: 't1', name: 'Academy' }, subscription: null, plan: null } },
      { status: 404, body: { message: 'This academy has no billing profile yet.' } },
    );
    expect(await httpSubscriptions.getAcademyBilling('t1')).toEqual({ academy: { id: 't1', name: 'Academy' }, subscription: null, plan: null, profile: null });
  });

  it('lists academies and saves a billing profile for one', async () => {
    const calls = stubFetch({ body: { rows: [{ id: 't1', name: 'Academy', slug: 'academy', status: 'active', accounts: 4 }] } });
    expect(await httpSubscriptions.listAcademies()).toEqual([{ id: 't1', name: 'Academy', slug: 'academy', status: 'active' }]);
    await httpSubscriptions.saveAcademyBillingProfile('t1', { legalName: 'A', email: 'a@b.in', addressLine1: 'x', city: 'y', postalCode: '1', country: 'IN' });
    expect(calls.map((c) => `${c.init.method} ${c.url.pathname}`)).toEqual(['GET /superadmin/tenants', 'PUT /superadmin/tenants/t1/billing-profile']);
  });
});

describe('the academy’s billing page talks to /tenant, and names no academy', () => {
  it('reads its summary, asks for a change, withdraws one, opens its invoice', async () => {
    const calls = stubFetch({ body: {} });
    await httpTenantBilling.summary();
    await httpTenantBilling.requestChange({ planId: 'p2', cycle: 'monthly' });
    await httpTenantBilling.withdrawChange('c1');
    await httpTenantBilling.getInvoice('i1');
    await httpTenantBilling.startFirstPurchase({ planId: 'p3', cycle: 'annual' });
    await httpTenantBilling.startCheckout({ invoiceId: 'i1' });
    await httpTenantBilling.startCheckout({ planChangeId: 'c2' });
    await httpTenantBilling.confirmCheckout({ orderId: 'order_1', paymentId: 'pay_1', signature: 'abc' });
    await httpTenantBilling.previewChange({ planId: 'p2', cycle: 'annual' });
    await httpTenantBilling.cancel({ immediately: false, reason: 'The cohort has finished.' });
    await httpTenantBilling.resume();
    expect(calls.map((c) => [`${c.init.method} ${c.url.pathname}`, c.body])).toEqual([
      ['GET /tenant/billing', undefined],
      ['POST /tenant/subscription/change', { planId: 'p2', cycle: 'monthly' }],
      ['POST /tenant/subscription/plan-changes/c1/cancel', {}],
      ['GET /tenant/billing/invoices/i1', undefined],
      // A first purchase names the plan and the cycle, nothing else: no price, tax, status or academy.
      ['POST /tenant/billing/purchase', { planId: 'p3', cycle: 'annual' }],
      // What to pay, never how much: the server takes the amount from the invoice.
      ['POST /tenant/billing/checkout', { invoiceId: 'i1' }],
      ['POST /tenant/billing/checkout', { planChangeId: 'c2' }],
      // The checkout's answer, passed on unchanged for the server to verify with the provider.
      ['POST /tenant/billing/checkout/confirm', { orderId: 'order_1', paymentId: 'pay_1', signature: 'abc' }],
      // A preview names the plan and cycle, as the change does; it writes nothing.
      ['POST /tenant/subscription/preview', { planId: 'p2', cycle: 'annual' }],
      ['POST /tenant/subscription/cancel', { immediately: false, reason: 'The cohort has finished.' }],
      ['POST /tenant/subscription/resume', {}],
    ]);
    for (const c of calls) expect(JSON.stringify(c.body ?? {})).not.toMatch(/amount|price|total/);
    for (const c of calls) expect(`${c.url.search}${JSON.stringify(c.body ?? {})}`).not.toMatch(/tenantId/);
  });
});

describe('every §34 refusal arrives as a state, not a raw message', () => {
  it('has a state for each of the nine codes', () => {
    expect([...BILLING_REFUSAL_CODES].sort()).toEqual(
      [
        'SUBSCRIPTION_REQUIRED',
        'SUBSCRIPTION_PAST_DUE',
        'SUBSCRIPTION_EXPIRED',
        'FEATURE_NOT_INCLUDED',
        'LIMIT_REACHED',
        'PAYMENT_REQUIRED',
        'PAYMENT_FAILED',
        'PLAN_UNAVAILABLE',
        'INVALID_SUBSCRIPTION_STATE',
      ].sort(),
    );
    for (const code of BILLING_REFUSAL_CODES) expect(BILLING_STATES[code].title.length, code).toBeGreaterThan(3);
  });

  it.each(BILLING_REFUSAL_CODES.map((code) => [code, code.startsWith('SUBSCRIPTION_REQ') || code === 'SUBSCRIPTION_EXPIRED' ? 402 : 403] as const))(
    '%s (HTTP %i) becomes its state, keeps its code, and is announced',
    async (code, status) => {
      stubFetch({ status, body: { message: 'Course limit reached: 10 of 10 (courses.max) — raw text', code } });
      const error = (await httpSubscriptions.overview().catch((e: unknown) => e)) as ServiceError;
      expect(error).toBeInstanceOf(ServiceError);
      expect(error.reason).toBe(code);
      expect(error.code).toBe('forbidden');
      expect(error.message.startsWith(`${BILLING_STATES[code].title}.`)).toBe(true);
      expect(billingStateOf(error)).toMatchObject({ code, title: BILLING_STATES[code].title });
      expect(events).toEqual([`${BILLING_REFUSAL_EVENT}:${code}`]);
      // Only where the request's own reason matters is the server's sentence kept.
      if (code !== 'PLAN_UNAVAILABLE' && code !== 'INVALID_SUBSCRIPTION_STATE') expect(error.message).not.toContain('raw text');
    },
  );

  it('keeps any other code on the error, as its message, without announcing it', async () => {
    stubFetch({ status: 409, body: { message: 'A plan with that code already exists.', code: 'CONFLICT' } });
    const error = (await httpSubscriptions.overview().catch((e: unknown) => e)) as ServiceError;
    expect(error).toMatchObject({ code: 'conflict', reason: 'CONFLICT', message: 'A plan with that code already exists.' });
    expect(billingStateOf(error)).toBeNull();
    expect(events).toEqual([]);
  });
});

describe('no screen reads a mock subscription fixture', () => {
  it('leaves the demo’s subscription records to the demo services alone', () => {
    const src = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
    const offenders: string[] = [];
    const walk = (dir: string) => {
      for (const name of readdirSync(dir)) {
        const file = path.join(dir, name);
        if (statSync(file).isDirectory()) walk(file);
        else if (/\.(ts|tsx)$/.test(file) && !file.includes(`${path.sep}services${path.sep}mock${path.sep}`)) {
          const text = readFileSync(file, 'utf8');
          if (/mock\/(subscriptions|tenantBilling|fixtures\/subscriptions)['"]/.test(text)) offenders.push(path.relative(src, file));
        }
      }
    };
    walk(src);
    expect(offenders).toEqual([]);
  });
});
