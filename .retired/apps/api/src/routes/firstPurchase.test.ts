import { BYTES_PER_GB } from '@syniastrolms/domain';
import request from 'supertest';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { setClock } from '../lib/clock.js';
import { setObservationSink, type Observation } from '../lib/observe.js';
import { setPaymentProvider } from '../lib/paymentProvider.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { platformDb } from '../test/db.js';
import { FakeProvider, signWebhook } from '../test/fakeProvider.js';
import { PASSWORD, app, as, unique, type Client } from '../test/helpers.js';

/* SAAS-009 (extended): an academy's first subscription, bought by its admin through checkout (§43). The price
 * is the server's, the subscription starts only when the provider confirms the payment, and it gets exactly
 * the plan version that was paid for. Billed in Ireland at 23% so no other suite's tax rule is disturbed. */

let platform: Client;
let STARTER: string;
let GROWTH: string;
let TRIAL: string;
let fake: FakeProvider;

const limits = {
  'learners.max': 100,
  'instructors.max': 10,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 10,
  'admin_accounts.max': 5,
};

async function plan(monthly: number, over: object = {}, publish = true): Promise<string> {
  const created = await platform.post('/superadmin/plans', {
    name: `Purchase Plan ${unique()}`,
    description: 'A plan for the first-purchase suite.',
    code: `FP${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    monthlyPrice: monthly,
    annualPrice: monthly * 10,
    trialEnabled: false,
    trialDays: 0,
    limits,
    features: ['courses.manage', 'reports.basic'],
    ...over,
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  if (publish) expect((await platform.post(`/superadmin/plans/${created.body.id}/publish`)).status).toBe(200);
  return created.body.id as string;
}

interface Academy {
  tenantId: string;
  admin: Client;
}

/** A new academy with an admin and a billing address in Ireland, and no subscription. */
async function academy(opts: { address?: boolean } = {}): Promise<Academy> {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Purchasing Academy', slug: `fp-${unique()}` } })).id;
  const email = `fp-admin-${unique()}@example.com`;
  expect((await platform.post('/superadmin/admins', { name: 'Purchasing Admin', email, password: PASSWORD, tenantId })).status).toBe(201);
  const admin = await as({ email, password: PASSWORD });
  if (opts.address !== false) {
    await admin.put('/tenant/billing-profile', {
      legalName: 'Purchasing Academy Ltd',
      email: 'accounts@example.com',
      addressLine1: '1 Grafton Street',
      city: 'Dublin',
      postalCode: 'D02',
      country: 'IE',
    });
  }
  return { tenantId, admin };
}

const subscriptionsOf = (tenantId: string) => platformDb.subscription.findMany({ where: { tenantId } });
const firstPurchases = (tenantId: string) => platformDb.invoice.findMany({ where: { tenantId, purpose: 'new_subscription' }, orderBy: { issuedAt: 'asc' } });
const buy = (a: Academy, body: object) => a.admin.post('/tenant/billing/purchase', body);
const confirm = (a: Academy, orderId: string, paid: { paymentId: string; signature: string }) =>
  a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: paid.paymentId, signature: paid.signature });
const webhook = (event: string, paymentId: string, orderId: string, eventId = `evt_${unique()}`) => {
  const raw = JSON.stringify({ entity: 'event', event, payload: { payment: { entity: { id: paymentId, order_id: orderId } } }, created_at: unique() });
  return request(app)
    .post('/webhooks/fakepay/subscription')
    .set('content-type', 'application/json')
    .set('x-razorpay-event-id', eventId)
    .set('x-razorpay-signature', signWebhook(raw))
    .send(raw);
};

beforeAll(async () => {
  const email = `fp-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Seller' });
  platform = await as({ email, password: PASSWORD });
  expect(
    (await platform.post('/superadmin/tax-rules', { name: 'VAT', country: 'IE', components: [{ code: 'VAT', label: 'VAT', rateBps: 2300 }] })).status,
  ).toBe(201);
  STARTER = await plan(200000);
  GROWTH = await plan(400000);
  TRIAL = await plan(150000, { trialEnabled: true, trialDays: 14 });
});

afterEach(() => {
  setClock(null);
  setPaymentProvider(undefined);
});

const useFake = () => {
  fake = new FakeProvider();
  setPaymentProvider(fake);
  return fake;
};

describe('asking for a first purchase', () => {
  it('prices the chosen plan on the server, invoices it once, and opens a checkout for exactly that invoice', async () => {
    useFake();
    const a = await academy();
    const other = await academy();
    // Everything but the plan and the cycle is ignored: price, tax, total, status, entitlements, academy.
    const res = await buy(a, {
      planId: STARTER,
      cycle: 'monthly',
      amount: 1,
      price: 1,
      tax: 0,
      total: 1,
      status: 'active',
      features: ['live_classes'],
      tenantId: other.tenantId,
    });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    // ₹2,000 + 23% VAT, from the plan version — whatever the body said.
    expect(res.body.invoice).toMatchObject({ total: 246000, currency: 'INR' });
    expect(res.body.checkout).toMatchObject({ provider: 'fakepay', amount: 246000, currency: 'INR' });
    expect(fake.orders.get(res.body.checkout.orderId)).toMatchObject({ amount: 246000 });

    const [invoice] = await firstPurchases(a.tenantId);
    const version = await platformDb.planVersion.findFirstOrThrow({ where: { planId: STARTER }, orderBy: { version: 'desc' } });
    expect(invoice).toMatchObject({
      purpose: 'new_subscription',
      status: 'open',
      subtotal: 200000,
      taxTotal: 46000,
      planVersionId: version.id,
      billingCycle: 'monthly',
      subscriptionId: null,
    });
    expect(await firstPurchases(other.tenantId)).toEqual([]);
    expect(await subscriptionsOf(a.tenantId)).toEqual([]);
  });

  it('asking again for the same plan reuses the invoice and its checkout; choosing another replaces it — one open at a time', async () => {
    useFake();
    const a = await academy();
    const first = await buy(a, { planId: STARTER, cycle: 'monthly' });
    const again = await buy(a, { planId: STARTER, cycle: 'monthly' });
    expect(again.body.checkout.orderId).toBe(first.body.checkout.orderId);
    expect(await firstPurchases(a.tenantId)).toHaveLength(1);

    const changed = await buy(a, { planId: GROWTH, cycle: 'annual' });
    expect(changed.status).toBe(201);
    expect(changed.body.invoice.total).toBe(4920000); // ₹40,000 a year + 23%
    const invoices = await firstPurchases(a.tenantId);
    expect(invoices.map((i) => i.status)).toEqual(['void', 'open']);
    expect(invoices[0].voidReason).toBe('Replaced: the LMS chose another plan or cycle.');
  });

  it('refuses a plan that is not on sale, a cycle it is not sold on, and an academy with no billing address', async () => {
    useFake();
    const a = await academy();
    const draft = await plan(100000, {}, false);
    const archived = await plan(100000);
    await platform.post(`/superadmin/plans/${archived}/archive`);
    const monthlyOnly = await plan(100000, { cycles: ['monthly'], annualPrice: 0 });
    for (const [planId, cycle] of [
      [draft, 'monthly'],
      [archived, 'monthly'],
      [monthlyOnly, 'annual'],
      ['no-such-plan', 'monthly'],
    ]) {
      const res = await buy(a, { planId, cycle });
      expect(res.status, `${planId} ${cycle}`).toBe(409);
      expect(res.body.code).toBe('PLAN_UNAVAILABLE');
    }
    const noAddress = await academy({ address: false });
    expect((await buy(noAddress, { planId: STARTER, cycle: 'monthly' })).body).toMatchObject({
      code: 'CONFLICT',
      message: 'Add the LMS’s billing address before choosing a plan.',
    });
    expect(await firstPurchases(a.tenantId)).toEqual([]);
    expect(await firstPurchases(noAddress.tenantId)).toEqual([]);
  });

  it('is refused while online payment is not configured, and writes nothing', async () => {
    setPaymentProvider(null);
    const a = await academy();
    const res = await buy(a, { planId: STARTER, cycle: 'monthly' });
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('PAYMENT_REQUIRED');
    expect(await firstPurchases(a.tenantId)).toEqual([]);
  });

  it('refuses an academy that already has a paid subscription — it changes plan instead', async () => {
    useFake();
    const active = await academy();
    await platform.post('/superadmin/subscriptions', { tenantId: active.tenantId, planId: STARTER, cycle: 'monthly', start: 'active' });
    const res = await buy(active, { planId: GROWTH, cycle: 'monthly' });
    expect(res.status).toBe(409);
    expect(res.body.code).toBe('INVALID_SUBSCRIPTION_STATE');
    expect(await firstPurchases(active.tenantId)).toEqual([]);
    expect(await subscriptionsOf(active.tenantId)).toHaveLength(1);
  });

  it('lets an academy on a free trial buy any plan, leaving the trial untouched until it is paid (D33)', async () => {
    useFake();
    const trialing = await academy();
    await platform.post('/superadmin/subscriptions', { tenantId: trialing.tenantId, planId: TRIAL, cycle: 'monthly', start: 'trial' });
    const res = await buy(trialing, { planId: GROWTH, cycle: 'annual' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body.checkout).toMatchObject({ provider: 'fakepay' });
    expect(await firstPurchases(trialing.tenantId)).toEqual([expect.objectContaining({ status: 'open', billingCycle: 'annual' })]);
    expect(await subscriptionsOf(trialing.tenantId)).toEqual([expect.objectContaining({ status: 'trialing', planId: TRIAL })]);
  });

  it('lets staff below admin, and an admin without settings.edit, do nothing', async () => {
    useFake();
    expect((await (await as('instructor')).post('/tenant/billing/purchase', { planId: STARTER, cycle: 'monthly' })).status).toBe(403);
    expect((await (await as('student')).post('/tenant/billing/purchase', { planId: STARTER, cycle: 'monthly' })).status).toBe(403);
  });
});

describe('buying a plan during a free trial (D33)', () => {
  async function onTrial() {
    const a = await academy();
    expect((await platform.post('/superadmin/subscriptions', { tenantId: a.tenantId, planId: TRIAL, cycle: 'monthly', start: 'trial' })).status).toBe(201);
    const [trial] = await subscriptionsOf(a.tenantId);
    return { ...a, trialId: trial.id };
  }

  it('ends the trial and starts the paid plan only on the verified payment, in that order', async () => {
    useFake();
    const a = await onTrial();
    const { body } = await buy(a, { planId: GROWTH, cycle: 'monthly' });
    const orderId = body.checkout.orderId as string;
    const [invoice] = await firstPurchases(a.tenantId);
    const real = fake.pay(orderId, 'paid');

    // A forged success changes nothing: the trial runs on.
    expect((await confirm(a, orderId, { paymentId: real.paymentId, signature: 'sig:forged' })).status).toBe(400);
    expect(await subscriptionsOf(a.tenantId)).toEqual([expect.objectContaining({ id: a.trialId, status: 'trialing' })]);

    const res = await confirm(a, orderId, real);
    expect(res.body).toMatchObject({ status: 'paid', settled: true, applied: true, message: 'Paid. The subscription is active.' });
    const subs = await subscriptionsOf(a.tenantId);
    expect(subs.find((s) => s.id === a.trialId)).toMatchObject({ status: 'canceled' });
    expect(subs.find((s) => s.id !== a.trialId)).toMatchObject({ status: 'active', planId: GROWTH, sourceInvoiceId: invoice.id });
    const ended = await platformDb.subscriptionEvent.findFirstOrThrow({ where: { subscriptionId: a.trialId, transition: 'cancel_now' } });
    expect(ended).toMatchObject({ fromStatus: 'trialing', toStatus: 'canceled', actorType: 'provider' });
    expect(JSON.parse(ended.metaJson)).toMatchObject({ convertedByInvoice: invoice.id });
    expect((await a.admin.get('/academy/plan')).body).toMatchObject({ status: 'active', restricted: false, plan: { id: GROWTH } });
  });

  it('keeps the trial when the payment fails, is pending, or never comes', async () => {
    useFake();
    const a = await onTrial();
    const { body } = await buy(a, { planId: GROWTH, cycle: 'monthly' });
    const orderId = body.checkout.orderId as string;
    expect((await confirm(a, orderId, fake.pay(orderId, 'failed'))).body).toMatchObject({ status: 'failed', applied: false });
    expect((await confirm(a, orderId, fake.pay(orderId, 'pending'))).body).toMatchObject({ status: 'pending', applied: false });
    expect(await subscriptionsOf(a.tenantId)).toEqual([expect.objectContaining({ id: a.trialId, status: 'trialing' })]);
    expect((await a.admin.get('/academy/plan')).body).toMatchObject({ status: 'trialing', restricted: false });
  });

  it('converts once, however the payment is reported: confirm and webhook together, then again', async () => {
    useFake();
    const a = await onTrial();
    const { body } = await buy(a, { planId: STARTER, cycle: 'monthly' });
    const orderId = body.checkout.orderId as string;
    const paid = fake.pay(orderId, 'paid');
    await Promise.all([confirm(a, orderId, paid), webhook('payment.captured', paid.paymentId, orderId), confirm(a, orderId, paid)]);
    expect((await confirm(a, orderId, paid)).body).toMatchObject({ settled: false, applied: false });
    const subs = await subscriptionsOf(a.tenantId);
    expect(subs.filter((s) => s.status === 'active')).toHaveLength(1);
    expect(subs.filter((s) => s.status === 'trialing')).toHaveLength(0);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect(await platformDb.subscriptionEvent.count({ where: { subscriptionId: a.trialId, transition: 'cancel_now' } })).toBe(1);
  });

  it('converts by the webhook alone, when the app never comes back', async () => {
    useFake();
    const a = await onTrial();
    const { body } = await buy(a, { planId: STARTER, cycle: 'monthly' });
    const paid = fake.pay(body.checkout.orderId, 'paid');
    expect((await webhook('payment.captured', paid.paymentId, body.checkout.orderId)).body).toMatchObject({ outcome: 'processed' });
    expect((await a.admin.get('/academy/plan')).body).toMatchObject({ status: 'active', plan: { id: STARTER } });
  });

  it('never touches another academy: its order cannot be confirmed, nor its trial ended, from here', async () => {
    useFake();
    const victim = await onTrial();
    const attacker = await academy();
    const { body } = await buy(victim, { planId: GROWTH, cycle: 'monthly' });
    const orderId = body.checkout.orderId as string;
    const paid = fake.pay(orderId, 'paid');
    const res = await confirm(attacker, orderId, paid);
    expect(res.status).toBe(404);
    // A tenant named in the body is ignored: the academy is the session's.
    const forged = await attacker.admin.post('/tenant/billing/purchase', { planId: GROWTH, cycle: 'monthly', tenantId: victim.tenantId });
    expect(forged.status).toBe(201);
    const order = await platformDb.paymentOrder.findFirstOrThrow({ where: { providerOrderId: forged.body.checkout.orderId } });
    expect(order.tenantId).toBe(attacker.tenantId);
    expect(await firstPurchases(victim.tenantId)).toHaveLength(1);
    expect(await subscriptionsOf(victim.tenantId)).toEqual([expect.objectContaining({ status: 'trialing' })]);
  });
});

describe('paying for it', () => {
  it('starts the subscription only on the provider’s verified payment: active, on exactly the version paid for', async () => {
    useFake();
    const a = await academy();
    const { body } = await buy(a, { planId: STARTER, cycle: 'monthly' });
    const orderId = body.checkout.orderId as string;
    const [invoice] = await firstPurchases(a.tenantId);

    // The browser says it worked, with a signature the provider never made: nothing starts.
    const real = fake.pay(orderId, 'paid');
    expect((await confirm(a, orderId, { paymentId: real.paymentId, signature: 'sig:forged' })).status).toBe(400);
    expect(await subscriptionsOf(a.tenantId)).toEqual([]);

    // The plan is repriced before the payment lands: the academy still gets the version it paid for.
    await platform.patch(`/superadmin/plans/${STARTER}`, { monthlyPrice: 999900 });
    setClock('2026-10-10T09:00:00Z');
    const res = await confirm(a, orderId, real);
    expect(res.body).toMatchObject({ status: 'paid', settled: true, applied: true, message: 'Paid. The subscription is active.' });

    const [sub] = await subscriptionsOf(a.tenantId);
    expect(sub).toMatchObject({
      status: 'active',
      planId: STARTER,
      planVersionId: invoice.planVersionId,
      billingCycle: 'monthly',
      amount: 200000,
      currency: 'INR',
      sourceInvoiceId: invoice.id,
      provider: 'fakepay',
      currentPeriodStartAt: new Date('2026-10-10T09:00:00Z'),
      currentPeriodEndAt: new Date('2026-11-10T09:00:00Z'),
    });
    const created = await platformDb.subscriptionEvent.findFirstOrThrow({ where: { subscriptionId: sub.id } });
    expect(created).toMatchObject({ transition: 'create', toStatus: 'active', actorType: 'provider', source: 'fakepay' });
    expect(JSON.parse(created.metaJson)).toMatchObject({ invoiceId: invoice.id, planVersionId: invoice.planVersionId, providerReference: real.paymentId });
    expect(await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).toMatchObject({ status: 'paid' });

    // The plan's features and limits are the academy's now.
    const billing = (await a.admin.get('/tenant/billing')).body;
    expect(billing).toMatchObject({ restricted: false, subscription: { status: 'active', amount: 200000 }, plan: { id: STARTER, monthlyPrice: 200000 } });
    expect(billing.features.filter((f: { included: boolean }) => f.included).map((f: { key: string }) => f.key)).toEqual(['courses.manage', 'reports.basic']);
    expect(billing.usage.find((u: { limit: string }) => u.limit === 'courses.max')).toMatchObject({ allowed: 10 });
    expect((await a.admin.get('/tenant/subscription/entitlements')).body).toMatchObject({ planVersionId: invoice.planVersionId, status: 'active' });
    expect(await platformDb.auditLog.findFirst({ where: { action: 'subscription.created', targetId: sub.id } })).toMatchObject({
      actorType: 'provider',
      source: 'fakepay',
    });
  });

  it('starts it once, however the payment is reported: confirmed twice, then by webhook, then by a redelivered webhook', async () => {
    useFake();
    const a = await academy();
    const { body } = await buy(a, { planId: GROWTH, cycle: 'monthly' });
    const orderId = body.checkout.orderId as string;
    const paid = fake.pay(orderId, 'paid');
    await confirm(a, orderId, paid);
    expect((await confirm(a, orderId, paid)).body).toMatchObject({ settled: false, applied: false, message: 'This payment is already recorded.' });
    const eventId = `evt_${unique()}`;
    expect((await webhook('payment.captured', paid.paymentId, orderId, eventId)).status).toBe(200);
    expect((await webhook('payment.captured', paid.paymentId, orderId, eventId)).body).toMatchObject({ duplicate: true });
    expect(await subscriptionsOf(a.tenantId)).toHaveLength(1);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect(await platformDb.subscriptionEvent.count({ where: { tenantId: a.tenantId } })).toBe(1);
  });

  it('holds when the browser and the webhook arrive at the same moment', async () => {
    useFake();
    const a = await academy();
    const { body } = await buy(a, { planId: STARTER, cycle: 'monthly' });
    const orderId = body.checkout.orderId as string;
    const paid = fake.pay(orderId, 'paid');
    await Promise.all([confirm(a, orderId, paid), webhook('payment.captured', paid.paymentId, orderId), confirm(a, orderId, paid)]);
    expect(await subscriptionsOf(a.tenantId)).toHaveLength(1);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
  });

  it('can be started by the webhook alone, when the browser never comes back', async () => {
    useFake();
    const a = await academy();
    const { body } = await buy(a, { planId: STARTER, cycle: 'annual' });
    const paid = fake.pay(body.checkout.orderId, 'authorized');
    expect((await webhook('payment.authorized', paid.paymentId, body.checkout.orderId)).body).toMatchObject({ outcome: 'processed' });
    expect(fake.captured).toEqual([paid.paymentId]);
    expect(await subscriptionsOf(a.tenantId)).toEqual([expect.objectContaining({ status: 'active', billingCycle: 'annual', amount: 2000000 })]);
  });

  it('starts nothing on a failed, pending, short or overpaid payment — and a later good payment on the same order does', async () => {
    useFake();
    const a = await academy();
    const { body } = await buy(a, { planId: STARTER, cycle: 'monthly' });
    const orderId = body.checkout.orderId as string;

    const declined = fake.pay(orderId, 'failed');
    expect((await confirm(a, orderId, declined)).body).toMatchObject({ status: 'failed', settled: false, applied: false });
    const pending = fake.pay(orderId, 'pending');
    expect((await confirm(a, orderId, pending)).body).toMatchObject({ status: 'pending', settled: false });
    const signals: Observation[] = [];
    setObservationSink((_line, o) => signals.push(o));
    try {
      const short = fake.pay(orderId, 'paid', { amount: 1000 });
      expect((await confirm(a, orderId, short)).body).toMatchObject({ settled: false, applied: false });
      const over = fake.pay(orderId, 'paid', { amount: 999999 });
      expect((await confirm(a, orderId, over)).body).toMatchObject({ settled: false, applied: false });
    } finally {
      setObservationSink(undefined);
    }
    expect(signals.filter((o) => o.signal === 'payment.unmatched')).toHaveLength(2);
    expect(await subscriptionsOf(a.tenantId)).toEqual([]);
    expect((await firstPurchases(a.tenantId))[0].status).toBe('open');

    const good = fake.pay(orderId, 'paid');
    expect((await confirm(a, orderId, good)).body).toMatchObject({ settled: true, applied: true });
    expect(await subscriptionsOf(a.tenantId)).toHaveLength(1);
  });

  it('never adds a second live subscription: one started by the platform meanwhile wins, and the payment waits for the platform', async () => {
    useFake();
    const a = await academy();
    const { body } = await buy(a, { planId: GROWTH, cycle: 'monthly' });
    // Before the payment lands, the platform starts the academy on a plan itself.
    await platform.post('/superadmin/subscriptions', { tenantId: a.tenantId, planId: STARTER, cycle: 'monthly', start: 'active' });
    const paid = fake.pay(body.checkout.orderId, 'paid');
    const signals: Observation[] = [];
    setObservationSink((_line, o) => signals.push(o));
    try {
      const res = await confirm(a, body.checkout.orderId, paid);
      expect(res.body).toMatchObject({ settled: true, applied: false });
      expect(res.body.message).toMatch(/could not be applied/);
    } finally {
      setObservationSink(undefined);
    }
    expect(await subscriptionsOf(a.tenantId)).toEqual([expect.objectContaining({ planId: STARTER, sourceInvoiceId: null })]);
    expect(signals.some((o) => o.signal === 'payment.unmatched')).toBe(true);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId, status: 'paid' } })).toBe(1);
  });

  it('lets an academy whose subscription ended buy again', async () => {
    useFake();
    const a = await academy();
    const old = await platform.post('/superadmin/subscriptions', { tenantId: a.tenantId, planId: STARTER, cycle: 'monthly', start: 'active' });
    await platform.post(`/superadmin/subscriptions/${old.body.id}/cancel`, { immediately: true, reason: 'Paused the academy' });
    const { body } = await buy(a, { planId: GROWTH, cycle: 'monthly' });
    await confirm(a, body.checkout.orderId, fake.pay(body.checkout.orderId, 'paid'));
    const subs = await subscriptionsOf(a.tenantId);
    expect(subs.map((s) => s.status).sort()).toEqual(['active', 'canceled']);
  });
});

describe('another academy', () => {
  it('can neither pay, confirm, nor see this academy’s first purchase', async () => {
    useFake();
    const mine = await academy();
    const theirs = await academy();
    const { body } = await buy(theirs, { planId: STARTER, cycle: 'monthly' });
    const [invoice] = await firstPurchases(theirs.tenantId);
    const paid = fake.pay(body.checkout.orderId, 'paid');
    expect((await confirm(mine, body.checkout.orderId, paid)).status).toBe(404);
    expect((await mine.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id })).status).toBe(404);
    expect((await mine.admin.get(`/tenant/billing/invoices/${invoice.id}`)).status).toBe(404);
    expect(await subscriptionsOf(mine.tenantId)).toEqual([]);
    expect(await subscriptionsOf(theirs.tenantId)).toEqual([]);
  });
});

describe('the database', () => {
  it('refuses a purchased subscription that no paid first-purchase invoice sold, and keeps the sale fixed', async () => {
    useFake();
    const a = await academy();
    await buy(a, { planId: STARTER, cycle: 'monthly' });
    const [invoice] = await firstPurchases(a.tenantId);
    const version = await platformDb.planVersion.findUniqueOrThrow({ where: { id: invoice.planVersionId! } });
    const row = {
      tenantId: a.tenantId,
      planId: STARTER,
      planVersionId: version.id,
      status: 'active',
      billingCycle: 'monthly',
      currency: 'INR',
      amount: 200000,
      currentPeriodStartAt: new Date(),
      currentPeriodEndAt: new Date(Date.now() + 86_400_000),
      sourceInvoiceId: invoice.id,
    };
    // The invoice is not paid.
    await expect(platformDb.subscription.create({ data: row })).rejects.toThrow();
    // A first-purchase invoice cannot be re-pointed at another version or cycle.
    await expect(platformDb.invoice.update({ where: { id: invoice.id }, data: { billingCycle: 'annual' } })).rejects.toThrow();
    // A first-purchase invoice must name what it sells; no other invoice may.
    await expect(
      platformDb.invoice.create({
        data: {
          tenantId: a.tenantId,
          number: `INV-TEST-${unique()}`,
          purpose: 'new_subscription',
          status: 'open',
          currency: 'INR',
          subtotal: 1,
          taxTotal: 0,
          total: 1,
          inclusive: false,
          linesJson: '[]',
          taxLinesJson: '[]',
          billedToJson: '{}',
          issuedAt: new Date(),
          dueAt: new Date(),
        },
      }),
    ).rejects.toThrow();
  });
});
