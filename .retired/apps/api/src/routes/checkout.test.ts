import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { BYTES_PER_GB } from '@syniastrolms/domain';
import { afterAll, afterEach, beforeAll, describe, expect, it } from 'vitest';

import { setClock } from '../lib/clock.js';
import { issueInvoice } from '../lib/invoices.js';
import { setObservationSink, type Observation } from '../lib/observe.js';
import { setPaymentProvider } from '../lib/paymentProvider.js';
import { FakeProvider } from '../test/fakeProvider.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import { refundThroughProvider } from '../lib/checkout.js';
import { recordPayment } from '../lib/payments.js';
import type { LifecycleActor } from '../lib/subscriptions.js';
import { runAsPlatform } from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { PASSWORD, as, unique, type Client } from '../test/helpers.js';

/* SAAS-009: taking a payment through the provider abstraction (§43–§45), against a fake provider that
 * behaves as Razorpay does — orders, payments read back server to server, signed checkouts. Billed in New
 * Zealand at 5% so no other suite's tax rule is disturbed. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('checkout tests act as the platform', fn);
const scheduler: LifecycleActor = { type: 'system', job: 'checkout-tests' };

let platform: Client;
let superAdmin: LifecycleActor & { type: 'user' };
let SMALL: string;
let BIG: string;
let fake: FakeProvider;

const limits = {
  'learners.max': 100,
  'instructors.max': 10,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 10,
  'admin_accounts.max': 5,
};

async function publishedPlan(monthly: number): Promise<string> {
  const created = await platform.post('/superadmin/plans', {
    name: `Checkout Plan ${unique()}`,
    description: 'A plan for the checkout suite.',
    code: `CK${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly', 'annual'],
    monthlyPrice: monthly,
    annualPrice: monthly * 10,
    trialEnabled: false,
    trialDays: 0,
    limits,
    features: ['courses.manage'],
  });
  expect(created.status, JSON.stringify(created.body)).toBe(201);
  expect((await platform.post(`/superadmin/plans/${created.body.id}/publish`)).status).toBe(200);
  return created.body.id as string;
}

interface Academy {
  tenantId: string;
  admin: Client;
  subscriptionId: string;
}

async function academy(planId: string): Promise<Academy> {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Checkout Academy', slug: `ck-${unique()}` } })).id;
  const email = `ck-admin-${unique()}@example.com`;
  expect((await platform.post('/superadmin/admins', { name: 'Checkout Admin', email, password: PASSWORD, tenantId })).status).toBe(201);
  const admin = await as({ email, password: PASSWORD });
  await admin.put('/tenant/billing-profile', {
    legalName: 'Checkout Academy Ltd',
    email: 'accounts@example.com',
    addressLine1: '1 Queen Street',
    city: 'Auckland',
    postalCode: '1010',
    country: 'NZ',
  });
  setClock('2026-09-01T00:00:00Z');
  const sub = await platform.post('/superadmin/subscriptions', { tenantId, planId, cycle: 'monthly', start: 'active' });
  expect(sub.status, JSON.stringify(sub.body)).toBe(201);
  setClock(null);
  return { tenantId, admin, subscriptionId: sub.body.id as string };
}

const subscriptionOf = (id: string) => platformDb.subscription.findUniqueOrThrow({ where: { id } });
const eventsOf = (id: string) => platformDb.subscriptionEvent.findMany({ where: { subscriptionId: id }, orderBy: { id: 'asc' } });

beforeAll(async () => {
  const email = `ck-su-${unique()}@example.com`;
  const created = await provisionSuperAdmin({ email, password: PASSWORD, name: 'Cashier' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  platform = await as({ email, password: PASSWORD });
  expect((await platform.post('/superadmin/tax-rules', { name: 'GST', country: 'NZ', components: [{ code: 'GST', label: 'GST', rateBps: 500 }] })).status).toBe(
    201,
  );
  SMALL = await publishedPlan(200000);
  BIG = await publishedPlan(400000);
});

afterEach(() => {
  setClock(null);
  setPaymentProvider(undefined);
});
afterAll(() => setPaymentProvider(undefined));

const useFake = () => {
  fake = new FakeProvider();
  setPaymentProvider(fake);
  return fake;
};

describe('without a payment provider', () => {
  it('says online payment is not available, in a stable code, and the billing page knows', async () => {
    setPaymentProvider(null);
    const a = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const res = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    expect(res.status).toBe(409);
    expect(res.body).toMatchObject({ code: 'PAYMENT_REQUIRED' });
    expect((await a.admin.get('/tenant/billing')).body.checkoutAvailable).toBe(false);
  });
});

describe('the §43 payment flow: an upgrade paid through checkout', () => {
  it('prices the checkout from the invoice, opens one order, and reuses it', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-16T00:00:00Z');
    const quote = await a.admin.post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' });
    expect(quote.status).toBe(201);
    const first = await a.admin.post('/tenant/billing/checkout', { planChangeId: quote.body.change.id, amount: 1, currency: 'USD' });
    expect(first.status, JSON.stringify(first.body)).toBe(201);
    // Half a month of ₹4,000 − ₹2,000, plus 5% GST — the invoice's figure, whatever the body said.
    expect(first.body.invoice).toMatchObject({ total: 105000, currency: 'INR' });
    expect(first.body.checkout).toMatchObject({ provider: 'fakepay', keyId: 'fake_key_id', amount: 105000, currency: 'INR' });
    const again = await a.admin.post('/tenant/billing/checkout', { planChangeId: quote.body.change.id });
    expect(again.body.checkout.orderId).toBe(first.body.checkout.orderId);
    expect(await platformDb.paymentOrder.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect(await platformDb.invoice.count({ where: { tenantId: a.tenantId, purpose: 'plan_change' } })).toBe(1);
    expect((await a.admin.get('/tenant/billing')).body.checkoutAvailable).toBe(true);
  });

  it('activates nothing on the browser’s word: a forged confirmation is refused, an unfinished payment is not recorded', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-16T00:00:00Z');
    const quote = await a.admin.post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' });
    const { body } = await a.admin.post('/tenant/billing/checkout', { planChangeId: quote.body.change.id });
    const orderId = body.checkout.orderId as string;

    // A browser claiming success with a made-up signature.
    const real = fake.pay(orderId, 'paid');
    const forged = await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: real.paymentId, signature: 'sig:forged' });
    expect(forged.status).toBe(400);
    // A correctly signed checkout whose payment the provider has not completed.
    const pending = fake.pay(orderId, 'pending');
    const early = await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: pending.paymentId, signature: pending.signature });
    expect(early.status).toBe(200);
    expect(early.body).toMatchObject({ status: 'pending', settled: false, applied: false });

    expect((await subscriptionOf(a.subscriptionId)).planId).toBe(SMALL);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(0);
    expect((await eventsOf(a.subscriptionId)).map((e) => e.transition)).toEqual(['create']);
  });

  it('records the provider’s payment, settles the invoice and applies the upgrade — once, however often it is confirmed', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-16T00:00:00Z');
    const quote = await a.admin.post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' });
    const { body } = await a.admin.post('/tenant/billing/checkout', { planChangeId: quote.body.change.id });
    const orderId = body.checkout.orderId as string;
    // The bank approved it; the platform captures it for exactly the order's amount.
    const paid = fake.pay(orderId, 'authorized');
    const confirm = () => a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: paid.paymentId, signature: paid.signature });
    const res = await confirm();
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    expect(res.body).toMatchObject({ status: 'paid', settled: true, applied: true });
    expect(fake.captured).toEqual([paid.paymentId]);

    const sub = await subscriptionOf(a.subscriptionId);
    expect(sub).toMatchObject({ planId: BIG, amount: 400000, currentPeriodEndAt: new Date('2026-10-01T00:00:00Z') });
    const change = (await eventsOf(a.subscriptionId)).find((e) => e.transition === 'change_plan')!;
    expect(change).toMatchObject({ actorType: 'provider', source: 'fakepay' });
    expect(JSON.parse(change.metaJson)).toMatchObject({ providerReference: paid.paymentId });
    expect(await platformDb.paymentOrder.findFirst({ where: { providerOrderId: orderId } })).toMatchObject({
      status: 'paid',
      providerPaymentId: paid.paymentId,
    });
    expect(
      await platformDb.auditLog.findFirst({
        where: { action: 'payment.succeeded', actorType: 'provider', source: 'fakepay', targetId: { not: null } },
        orderBy: { createdAt: 'desc' },
      }),
    ).toBeTruthy();

    // Confirmed again — a retried browser, a double click: nothing more happens.
    const twice = await confirm();
    expect(twice.body).toMatchObject({ settled: false, applied: false, message: 'This payment is already recorded.' });
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'change_plan')).toHaveLength(1);
  });

  it('refuses a payment that belongs to another order', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const { body } = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    const other = await fake.createPayment({ amount: 1, currency: 'INR' });
    const stray = fake.pay(other.providerOrderId, 'paid');
    const res = await a.admin.post('/tenant/billing/checkout/confirm', {
      orderId: body.checkout.orderId,
      paymentId: stray.paymentId,
      signature: `sig:${body.checkout.orderId}|${stray.paymentId}`,
    });
    expect(res.status).toBe(400);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(0);
  });
});

describe('renewals: paid, and the §44 failed-payment flow', () => {
  it('renews an active subscription for the next period when its renewal invoice is paid', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const { body } = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    const paid = fake.pay(body.checkout.orderId, 'paid');
    const res = await a.admin.post('/tenant/billing/checkout/confirm', {
      orderId: body.checkout.orderId,
      paymentId: paid.paymentId,
      signature: paid.signature,
    });
    expect(res.body).toMatchObject({ status: 'paid', settled: true, applied: true });
    expect(await subscriptionOf(a.subscriptionId)).toMatchObject({ status: 'active', currentPeriodEndAt: new Date('2026-11-01T00:00:00Z') });
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('paid');
  });

  it('records a declined early renewal without dunning: the period already paid runs to its end', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const { body } = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    const declined = fake.pay(body.checkout.orderId, 'failed');
    const res = await a.admin.post('/tenant/billing/checkout/confirm', {
      orderId: body.checkout.orderId,
      paymentId: declined.paymentId,
      signature: declined.signature,
    });
    expect(res.body).toMatchObject({ status: 'failed', settled: false });
    expect(await subscriptionOf(a.subscriptionId)).toMatchObject({ status: 'active', pastDueAt: null });
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'payment_failed')).toHaveLength(0);
  });

  it('records a failed renewal after the period ended, leaves the invoice open, moves the subscription past due — and recovers on the next payment', async () => {
    useFake();
    const a = await academy(SMALL);
    // Just past the period's end (1 Oct), before the renewal check ran.
    setClock('2026-10-01T06:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const { body } = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    const orderId = body.checkout.orderId as string;

    const declined = fake.pay(orderId, 'failed');
    const res = await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: declined.paymentId, signature: declined.signature });
    expect(res.body).toMatchObject({ status: 'failed', settled: false, message: 'Payment declined by the bank' });
    expect(await platformDb.payment.findFirst({ where: { providerPaymentId: declined.paymentId } })).toMatchObject({
      status: 'failed',
      failureCode: 'BAD_REQUEST_ERROR',
      failureMessage: 'Payment declined by the bank',
    });
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('open');
    expect(await subscriptionOf(a.subscriptionId)).toMatchObject({ status: 'past_due', pastDueReason: 'Payment declined by the bank' });
    expect((await eventsOf(a.subscriptionId)).at(-1)).toMatchObject({ transition: 'payment_failed', actorType: 'provider', source: 'fakepay' });

    // The same failure reported again changes nothing; a retry on the same order succeeds.
    await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: declined.paymentId, signature: declined.signature });
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'payment_failed')).toHaveLength(1);
    const retry = fake.pay(orderId, 'paid');
    const recovered = await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: retry.paymentId, signature: retry.signature });
    expect(recovered.body).toMatchObject({ settled: true, applied: true });
    expect(await subscriptionOf(a.subscriptionId)).toMatchObject({ status: 'active', pastDueAt: null, currentPeriodEndAt: new Date('2026-11-01T00:00:00Z') });
  });
});

describe('a payment declined, then authorized after all', () => {
  it('is not captured, leaves the invoice open to pay again, and tells the platform', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const { body } = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    const orderId = body.checkout.orderId as string;

    const declined = fake.pay(orderId, 'failed');
    await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: declined.paymentId, signature: declined.signature });
    // The bank answers late: the provider now holds the same payment as authorized.
    fake.payments.set(declined.paymentId, { ...fake.payments.get(declined.paymentId)!, status: 'authorized' });

    const signals: Observation[] = [];
    setObservationSink((_line, o) => signals.push(o));
    try {
      const late = await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: declined.paymentId, signature: declined.signature });
      expect(late.body).toMatchObject({ settled: false, applied: false, message: expect.stringMatching(/not taken/) });
    } finally {
      setObservationSink(undefined);
    }
    expect(fake.captured).not.toContain(declined.paymentId);
    expect(signals.some((o) => o.signal === 'payment.unmatched' && /recorded as failed/.test(String(o.fields.reason)))).toBe(true);
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('open');

    // Paying again works as any retry does.
    const retry = fake.pay(orderId, 'paid');
    const recovered = await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId: retry.paymentId, signature: retry.signature });
    expect(recovered.body).toMatchObject({ settled: true, applied: true });
  });
});

describe('one academy cannot pay, or confirm, another’s', () => {
  it('finds neither the invoice nor the order', async () => {
    useFake();
    const mine = await academy(SMALL);
    const theirs = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: theirs.subscriptionId }));
    expect((await mine.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id })).status).toBe(404);
    const { body } = await theirs.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    const paid = fake.pay(body.checkout.orderId, 'paid');
    const res = await mine.admin.post('/tenant/billing/checkout/confirm', {
      orderId: body.checkout.orderId,
      paymentId: paid.paymentId,
      signature: paid.signature,
    });
    expect(res.status).toBe(404);
    expect(await platformDb.payment.count({ where: { invoiceId: invoice.id } })).toBe(0);
    // Staff below admin cannot start one at all.
    expect((await (await as('instructor')).post('/tenant/billing/checkout', { invoiceId: invoice.id })).status).toBe(403);
  });
});

describe('a checkout order in the database', () => {
  it('is for its invoice’s exact total, fixed once made, settles once, and is never deleted', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const base = { tenantId: a.tenantId, invoiceId: invoice.id, provider: 'fakepay', currency: 'INR' };
    await expect(platformDb.paymentOrder.create({ data: { ...base, providerOrderId: `o_${unique()}`, amount: invoice.total - 1 } })).rejects.toThrow();
    await expect(
      platformDb.paymentOrder.create({ data: { ...base, providerOrderId: `o_${unique()}`, amount: invoice.total, currency: 'USD' } }),
    ).rejects.toThrow();
    const order = await platformDb.paymentOrder.create({ data: { ...base, providerOrderId: `o_${unique()}`, amount: invoice.total } });
    await expect(platformDb.paymentOrder.update({ where: { id: order.id }, data: { amount: 1 } })).rejects.toThrow();
    await expect(platformDb.paymentOrder.update({ where: { id: order.id }, data: { status: 'paid' } })).rejects.toThrow(); // no payment named
    await platformDb.paymentOrder.update({ where: { id: order.id }, data: { status: 'paid', providerPaymentId: 'pay_x', paidAt: new Date() } });
    await expect(platformDb.paymentOrder.update({ where: { id: order.id }, data: { status: 'created' } })).rejects.toThrow();
    await expect(platformDb.paymentOrder.delete({ where: { id: order.id } })).rejects.toThrow();
  });
});

describe('refunds through the provider (§29)', () => {
  async function paidPayment(a: Academy) {
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const { body } = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    const paid = fake.pay(body.checkout.orderId, 'paid');
    await a.admin.post('/tenant/billing/checkout/confirm', { orderId: body.checkout.orderId, paymentId: paid.paymentId, signature: paid.signature });
    return platformDb.payment.findFirstOrThrow({ where: { providerPaymentId: paid.paymentId } });
  }

  it('asks the provider, and its answer settles the refund', async () => {
    useFake();
    const payment = await paidPayment(await academy(SMALL));
    const res = await platform.post(`/superadmin/payments/${payment.id}/refund`, { amount: 5000, reason: 'Goodwill credit' });
    expect(res.status, JSON.stringify(res.body)).toBe(201);
    expect(res.body).toMatchObject({ amount: 5000, status: 'succeeded' });
    expect(fake.refunds).toEqual([{ providerPaymentId: payment.providerPaymentId, amount: 5000, notes: expect.any(Object) }]);
    expect(await platformDb.auditLog.findFirst({ where: { action: 'payment.refunded', targetId: payment.id } })).toMatchObject({
      actorType: 'provider',
      source: 'fakepay',
    });
  });

  it('records a refund the provider refuses as failed, leaving the payment refundable', async () => {
    useFake();
    const payment = await paidPayment(await academy(SMALL));
    fake.refundAnswer = 'error';
    const res = await platform.post(`/superadmin/payments/${payment.id}/refund`, { reason: 'Billed in error' });
    expect(res.body).toMatchObject({ status: 'failed' });
    expect((await platform.get(`/superadmin/payments/${payment.id}`)).body.payment.refundable).toBe(payment.amount);
  });

  it('keeps a refund pending when the provider gives no answer, so the money cannot be refunded twice', async () => {
    useFake();
    const payment = await paidPayment(await academy(SMALL));
    fake.refundAnswer = 'timeout';
    const res = await platform.post(`/superadmin/payments/${payment.id}/refund`, { reason: 'Billed in error' });
    expect(res.body).toMatchObject({ status: 'pending' });
    expect((await platform.get(`/superadmin/payments/${payment.id}`)).body.payment.refundable).toBe(0);
    fake.refundAnswer = { providerRefundId: 'rf_default', status: 'succeeded' };
    expect((await platform.post(`/superadmin/payments/${payment.id}/refund`, { amount: 100, reason: 'Trying again' })).status).toBe(409);
    expect(fake.refunds).toHaveLength(1);
  });

  it('keeps a refund pending for a payment the provider did not take', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-09-28T00:00:00Z');
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const manual = await asPlatform(() =>
      recordPayment(
        { type: 'provider', provider: 'bank-transfer' },
        { invoiceId: invoice.id, providerPaymentId: `bt_${unique()}`, amount: invoice.total, currency: 'INR', status: 'paid' },
      ),
    );
    const refund = await asPlatform(() => refundThroughProvider({ auth: superAdmin.auth }, manual.payment.id, { reason: 'Refunded by bank transfer' }));
    expect(refund.status).toBe('pending');
    expect(fake.refunds).toEqual([]);
  });
});

describe('the gateway stays behind its adapter, and no secret is committed', () => {
  const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..', '..', '..');
  const tracked = () => execFileSync('git', ['ls-files'], { cwd: repo, encoding: 'utf8' }).split('\n').filter(Boolean);

  it('calls the Razorpay API from lib/razorpay.ts only, and uses no gateway SDK', () => {
    const offenders = tracked()
      .filter((f) => /\.(ts|tsx|js|mjs)$/.test(f) && !f.endsWith('.test.ts') && f !== 'apps/api/src/lib/razorpay.ts')
      .filter((f) => /api\.razorpay\.com|from ['"](razorpay|stripe)['"]|require\(['"](razorpay|stripe)['"]\)/.test(readFileSync(path.join(repo, f), 'utf8')));
    expect(offenders).toEqual([]);
    for (const pkg of ['package.json', 'apps/api/package.json', 'apps/web/package.json']) {
      const deps = JSON.parse(readFileSync(path.join(repo, pkg), 'utf8'));
      expect(Object.keys({ ...deps.dependencies, ...deps.devDependencies })).not.toContain('razorpay');
    }
  });

  it('commits no gateway credential: none of the configured values, and no live key anywhere', () => {
    const envFile = path.join(repo, 'apps/api/.env');
    const configured = existsSync(envFile)
      ? readFileSync(envFile, 'utf8')
          .split('\n')
          .map((l) => /^(RAZORPAY_[A-Z_]+|STRIPE_[A-Z_]+|PAYMENT_CREDENTIALS_KEY)=(.*)$/.exec(l.trim()))
          .map((m) => m?.[2]?.trim().replace(/^['"]|['"]$/g, ''))
          .filter((v): v is string => Boolean(v && v.length >= 8))
      : [];
    expect(tracked()).not.toContain('apps/api/.env');
    const leaks: string[] = [];
    for (const file of tracked()) {
      const full = path.join(repo, file);
      if (!existsSync(full) || /\.(png|jpg|jpeg|gif|webp|ico|pdf|woff2?|db)$/.test(file)) continue;
      const text = readFileSync(full, 'utf8');
      // Secret-scanning tests (TypeScript and the mobile app's Dart) carry made-up live-looking keys on purpose; the
      // configured values are checked everywhere.
      const livePattern = !/(\.test\.tsx?|_test\.dart)$/.test(file) && /rzp_live_[A-Za-z0-9]{8,}|sk_live_[A-Za-z0-9]{8,}/.test(text);
      if (configured.some((secret) => text.includes(secret)) || livePattern) leaks.push(file);
    }
    expect(leaks).toEqual([]);
  });
});
