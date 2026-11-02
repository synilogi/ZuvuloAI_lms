import { BYTES_PER_GB } from '@syniastrolms/domain';
import request from 'supertest';
import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest';

import { runBillingSchedule } from '../lib/scheduler.js';
import { setClock } from '../lib/clock.js';
import { issueInvoice } from '../lib/invoices.js';
import { setPaymentProvider } from '../lib/paymentProvider.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { expireTrial, type LifecycleActor } from '../lib/subscriptions.js';
import { runAsPlatform } from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { FakeProvider, signWebhook } from '../test/fakeProvider.js';
import { PASSWORD, anon, app, as, unique, type Client } from '../test/helpers.js';

/* SAAS-016: the §47 security list, one item per block, each attempted over HTTP the way a client would —
 * cross-tenant access, forged tenant ids, unauthorised plan changes and refunds, forged and duplicate
 * webhooks, expired-subscription bypass, and a client setting its own price, plan or entitlement. Billed in
 * Canada at 5% so no other suite's tax rule is disturbed. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('security audit acts as the platform', fn);
const scheduler: LifecycleActor = { type: 'system', job: 'security-audit' };
let platform: Client;
let SMALL: string;
let BIG: string;
let TRIAL: string;

const limits = {
  'learners.max': 100,
  'instructors.max': 10,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 10,
  'admin_accounts.max': 5,
};

async function publishedPlan(monthly: number, over: object = {}): Promise<string> {
  const created = await platform.post('/superadmin/plans', {
    name: `Audit Plan ${unique()}`,
    description: 'A plan for the security audit.',
    code: `SA${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    monthlyPrice: monthly,
    annualPrice: monthly * 10,
    trialEnabled: false,
    trialDays: 0,
    limits,
    features: ['courses.manage'],
    ...over,
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  expect((await platform.post(`/superadmin/plans/${created.body.id}/publish`)).status).toBe(200);
  return created.body.id as string;
}

interface Academy {
  tenantId: string;
  admin: Client;
  adminId: string;
  subscriptionId: string;
}

async function academy(planId: string, start: 'active' | 'trial' = 'active'): Promise<Academy> {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Audit Academy', slug: `sa-${unique()}` } })).id;
  const email = `sa-admin-${unique()}@example.com`;
  const created = await platform.post('/superadmin/admins', { name: 'Audit Admin', email, password: PASSWORD, tenantId });
  expect(created.status).toBe(201);
  const admin = await as({ email, password: PASSWORD });
  await admin.put('/tenant/billing-profile', {
    legalName: 'Audit Academy Inc',
    email: 'accounts@example.com',
    addressLine1: '1 Bay Street',
    city: 'Toronto',
    postalCode: 'M5J 2N8',
    country: 'CA',
  });
  setClock('2026-09-01T00:00:00Z');
  const sub = await platform.post('/superadmin/subscriptions', { tenantId, planId, cycle: 'monthly', start });
  expect(sub.status, JSON.stringify(sub.body)).toBe(201);
  setClock(null);
  return { tenantId, admin, adminId: created.body.id as string, subscriptionId: sub.body.id as string };
}

const subOf = (id: string) => platformDb.subscription.findUniqueOrThrow({ where: { id } });

beforeAll(async () => {
  const email = `sa-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Auditor' });
  platform = await as({ email, password: PASSWORD });
  expect((await platform.post('/superadmin/tax-rules', { name: 'GST', country: 'CA', components: [{ code: 'GST', label: 'GST', rateBps: 500 }] })).status).toBe(
    201,
  );
  SMALL = await publishedPlan(200000);
  BIG = await publishedPlan(400000);
  TRIAL = await publishedPlan(150000, { trialEnabled: true, trialDays: 14 });
});

afterEach(() => {
  setClock(null);
  setPaymentProvider(undefined);
  vi.unstubAllEnvs();
});

describe('§47 cross-tenant access', () => {
  it('shows an academy only its own subscription, invoices and payments; another’s are not found', async () => {
    const mine = await academy(SMALL);
    const theirs = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: theirs.subscriptionId }));
    setClock(null);
    expect((await mine.admin.get('/tenant/billing')).body.subscription.id).toBe(mine.subscriptionId);
    for (const path of [`/tenant/invoices/${invoice.id}`, `/tenant/billing/invoices/${invoice.id}`, `/tenant/billing/invoices/${invoice.number}`]) {
      expect((await mine.admin.get(path)).status, path).toBe(404);
    }
    expect((await mine.admin.get('/tenant/invoices')).body.rows).toEqual([]);
    expect((await mine.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id })).status).toBe(404); // another academy's invoice is not found, with or without a gateway
  });
});

describe('§47 forged tenant ids', () => {
  it('ignores a tenant id in the body, the query or a header: the academy is the signed-in account’s', async () => {
    const mine = await academy(SMALL);
    const theirs = await academy(BIG);
    const forged = mine.admin
      .get('/tenant/billing')
      .query({ tenantId: theirs.tenantId })
      .set('x-tenant-id', theirs.tenantId)
      .set('x-academy-id', theirs.tenantId);
    const res = await forged;
    expect(res.body.academy.id).toBe(mine.tenantId);
    expect(res.body.subscription.id).toBe(mine.subscriptionId);

    // A change asked for "on behalf of" the other academy lands on the caller's own subscription, or nowhere.
    setClock('2026-09-16T00:00:00Z');
    const change = await mine.admin.post('/tenant/subscription/change', {
      planId: BIG,
      cycle: 'monthly',
      tenantId: theirs.tenantId,
      subscriptionId: theirs.subscriptionId,
    });
    expect(change.status).toBe(201);
    expect(await platformDb.planChange.count({ where: { subscriptionId: theirs.subscriptionId } })).toBe(0);
    expect(await platformDb.planChange.count({ where: { subscriptionId: mine.subscriptionId } })).toBe(1);
    // And a billing profile written "for" them is the caller's own.
    await mine.admin.put('/tenant/billing-profile', {
      legalName: 'Forged Ltd',
      email: 'x@example.com',
      addressLine1: '1 X',
      city: 'X',
      postalCode: '1',
      country: 'CA',
      tenantId: theirs.tenantId,
    });
    expect((await theirs.admin.get('/tenant/billing-profile')).body.legalName).toBe('Audit Academy Inc');
  });
});

describe('§47 unauthorised plan changes', () => {
  it('refuses staff below admin, an admin without settings.edit, another academy’s change, and the platform’s endpoints', async () => {
    const a = await academy(SMALL);
    const other = await academy(BIG);
    setClock('2026-09-16T00:00:00Z');
    const theirs = await other.admin.post('/tenant/subscription/change', { planId: SMALL, cycle: 'monthly' });
    expect((await (await as('instructor')).post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' })).status).toBe(403);
    expect((await (await as('student')).post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' })).status).toBe(403);
    // Another academy's plan change cannot even be named.
    expect((await a.admin.post(`/tenant/subscription/plan-changes/${theirs.body.change.id}/cancel`, {})).status).toBe(404);
    // The platform's own plan and subscription endpoints refuse an academy admin.
    expect((await a.admin.post(`/superadmin/subscriptions/${a.subscriptionId}/plan-change`, { planId: BIG, cycle: 'monthly' })).status).toBe(403);
    expect((await a.admin.patch(`/superadmin/plans/${SMALL}`, { monthlyPrice: 1 })).status).toBe(403);
    // With settings.edit revoked, the admin can read billing but change nothing.
    expect((await platform.delete(`/superadmin/admins/${a.adminId}/permissions/settings.edit`)).status).toBe(200);
    const readOnly = await as({ email: (await platformDb.user.findUniqueOrThrow({ where: { id: a.adminId } })).email, password: PASSWORD });
    expect((await readOnly.get('/tenant/billing')).status).toBe(200);
    expect((await readOnly.post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' })).status).toBe(403);
    expect((await subOf(a.subscriptionId)).planId).toBe(SMALL);
  });
});

describe('§47 unauthorised refunds', () => {
  it('lets only a super admin refund, with a reason', async () => {
    const a = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const { recordPayment } = await import('../lib/payments.js');
    const paid = await asPlatform(() =>
      recordPayment(
        { type: 'provider', provider: 'bank-transfer' },
        { invoiceId: invoice.id, providerPaymentId: `bt_${unique()}`, amount: invoice.total, currency: 'INR', status: 'paid' },
      ),
    );
    setClock(null);
    const path = `/superadmin/payments/${paid.payment.id}/refund`;
    expect((await a.admin.post(path, { reason: 'I would like my money back' })).status).toBe(403);
    expect((await (await as('instructor')).post(path, { reason: 'Refund please' })).status).toBe(403);
    expect((await anon().post(path, { reason: 'Refund please' })).status).toBe(401);
    expect((await platform.post(path, {})).status).toBe(400);
    expect(await platformDb.refund.count({ where: { paymentId: paid.payment.id } })).toBe(0);
  });
});

describe('§47 forged and duplicate webhooks', () => {
  it('rejects a forged webhook, and changes state once for a duplicate', async () => {
    const fake = new FakeProvider();
    setPaymentProvider(fake);
    const a = await academy(SMALL);
    setClock('2026-09-16T00:00:00Z');
    const quote = await a.admin.post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' });
    const { body } = await a.admin.post('/tenant/billing/checkout', { planChangeId: quote.body.change.id });
    const { paymentId } = fake.pay(body.checkout.orderId, 'paid');
    const raw = JSON.stringify({
      entity: 'event',
      event: 'payment.captured',
      payload: { payment: { entity: { id: paymentId, order_id: body.checkout.orderId } } },
    });
    const send = (signature: string, eventId: string) =>
      request(app)
        .post('/webhooks/fakepay/subscription')
        .set('content-type', 'application/json')
        .set('x-razorpay-event-id', eventId)
        .set('x-razorpay-signature', signature)
        .send(raw);
    expect((await send('0'.repeat(64), `evt_${unique()}`)).status).toBe(401);
    expect((await subOf(a.subscriptionId)).planId).toBe(SMALL);
    const eventId = `evt_${unique()}`;
    expect((await send(signWebhook(raw), eventId)).status).toBe(200);
    expect((await send(signWebhook(raw), eventId)).body).toMatchObject({ duplicate: true });
    expect(await platformDb.subscriptionEvent.count({ where: { subscriptionId: a.subscriptionId, transition: 'change_plan' } })).toBe(1);
  });
});

describe('§47 expired-subscription bypass', () => {
  it('refuses an expired academy’s new work once enforcement is on — while it can still reach billing to renew', async () => {
    const a = await academy(TRIAL, 'trial');
    setClock('2026-09-15T00:00:00Z');
    await asPlatform(() => expireTrial(scheduler, a.subscriptionId));
    setClock(null);
    vi.stubEnv('ENTITLEMENT_ENFORCEMENT', 'on');
    const create = await a.admin.post('/courses', { title: 'Sneaking one in', levelId: 'x', categoryId: 'x' });
    expect(create.status).toBe(402);
    expect(create.body.code).toBe('SUBSCRIPTION_EXPIRED');
    expect((await a.admin.get('/tenant/billing')).status).toBe(200);
    // Switching enforcement off (the rollback) lets it through to ordinary validation again.
    vi.stubEnv('ENTITLEMENT_ENFORCEMENT', 'off');
    expect((await a.admin.post('/courses', { title: 'Sneaking one in', levelId: 'x', categoryId: 'x' })).status).not.toBe(402);
  });
});

describe('§47 client-modified price, plan and entitlement', () => {
  it('prices every charge on the server, whatever the client sends', async () => {
    setPaymentProvider(new FakeProvider());
    const a = await academy(SMALL);
    const sub = await subOf(a.subscriptionId);
    expect(sub.amount).toBe(200000);
    setClock('2026-09-16T00:00:00Z');
    const quote = await a.admin.post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly', charge: 1, credit: 999999, amount: 1 });
    expect(quote.body.change).toMatchObject({ charge: 100000, credit: 100000 });
    const checkout = await a.admin.post('/tenant/billing/checkout', { planChangeId: quote.body.change.id, amount: 1, total: 1 });
    expect(checkout.body.checkout.amount).toBe(105000);
    // A subscription started by the platform costs the plan's price, not the request's.
    const tenantId = (await platformDb.tenant.create({ data: { name: 'Priced', slug: `pr-${unique()}` } })).id;
    const started = await platform.post('/superadmin/subscriptions', { tenantId, planId: SMALL, cycle: 'monthly', start: 'active', amount: 1, price: 1 });
    expect(started.body.amount).toBe(200000);
  });

  it('gives a client no way to set its plan, status or entitlements', async () => {
    const a = await academy(SMALL);
    const before = await a.admin.get('/tenant/subscription/entitlements');
    for (const attempt of [
      a.admin.patch('/tenant/subscription', { planId: BIG, status: 'active', features: ['live_classes'] }),
      a.admin.put('/tenant/subscription', { planId: BIG }),
      a.admin.post('/tenant/subscription/entitlements', { features: ['live_classes'], limits: { 'courses.max': null } }),
    ]) {
      expect((await attempt).status).toBe(404);
    }
    // Extra fields on the endpoints that do exist are ignored.
    await a.admin.put('/tenant/billing-profile', {
      legalName: 'Audit Academy Inc',
      email: 'accounts@example.com',
      addressLine1: '1 Bay Street',
      city: 'Toronto',
      postalCode: 'M5J 2N8',
      country: 'CA',
      features: ['live_classes'],
      limits: { 'courses.max': null },
      planId: BIG,
      status: 'active',
    });
    // A draft or unknown plan cannot be moved to.
    const draft = await platform.post('/superadmin/plans', {
      name: 'Hidden',
      description: 'Not on sale.',
      code: `HD${unique().toUpperCase()}`.slice(0, 24),
      currency: 'INR',
      cycles: ['monthly'],
      monthlyPrice: 1,
      annualPrice: 0,
      trialEnabled: false,
      trialDays: 0,
      limits: { ...limits, 'courses.max': null },
      features: ['courses.manage', 'live_classes'],
    });
    setClock('2026-09-16T00:00:00Z');
    const toDraft = await a.admin.post('/tenant/subscription/change', { planId: draft.body.id, cycle: 'monthly' });
    expect(toDraft.status).toBe(409);
    expect(toDraft.body.code).toBe('PLAN_UNAVAILABLE');
    setClock(null);
    expect((await a.admin.get('/tenant/subscription/entitlements')).body).toEqual(before.body);
    expect(await subOf(a.subscriptionId)).toMatchObject({ planId: SMALL, status: 'active' });
  });
});

describe('rollout switches are reversible (§50)', () => {
  it('pauses every billing job with BILLING_JOBS=off, and resumes them when it is back on', async () => {
    const a = await academy(TRIAL, 'trial');
    setClock('2026-09-20T00:00:00Z');
    vi.stubEnv('BILLING_JOBS', 'off');
    const paused = await runBillingSchedule();
    expect(paused.paused).toBe(true);
    expect((await subOf(a.subscriptionId)).status).toBe('trialing');
    vi.stubEnv('BILLING_JOBS', 'on');
    const resumed = await runBillingSchedule();
    expect(resumed.paused).toBe(false);
    expect((await subOf(a.subscriptionId)).status).toBe('expired');
  });
});
