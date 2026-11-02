import { createHash } from 'node:crypto';

import { BYTES_PER_GB } from '@syniastrolms/domain';
import request from 'supertest';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { setClock } from '../lib/clock.js';
import { issueInvoice } from '../lib/invoices.js';
import { setPaymentProvider } from '../lib/paymentProvider.js';
import { recordPayment } from '../lib/payments.js';
import { provisionSuperAdmin } from '../lib/provisionSuperAdmin.js';
import type { LifecycleActor } from '../lib/subscriptions.js';
import { runAsPlatform } from '../lib/tenancy.js';
import { platformDb } from '../test/db.js';
import { FakeProvider, signWebhook } from '../test/fakeProvider.js';
import { PASSWORD, anon, app, as, unique, type Client } from '../test/helpers.js';

/* SAAS-010: provider webhooks — verified, idempotent, transactional — through the real route, with bodies
 * signed exactly as Razorpay signs them. Billed in Australia at 5% so no other suite's tax rule is disturbed. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('webhook tests act as the platform', fn);
const scheduler: LifecycleActor = { type: 'system', job: 'webhook-tests' };
let platform: Client;
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
    name: `Webhook Plan ${unique()}`,
    description: 'A plan for the webhook suite.',
    code: `WH${unique().toUpperCase()}`.slice(0, 24),
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
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Webhook Academy', slug: `wh-${unique()}` } })).id;
  const email = `wh-admin-${unique()}@example.com`;
  expect((await platform.post('/superadmin/admins', { name: 'Webhook Admin', email, password: PASSWORD, tenantId })).status).toBe(201);
  const admin = await as({ email, password: PASSWORD });
  await admin.put('/tenant/billing-profile', {
    legalName: 'Webhook Academy Pty',
    email: 'accounts@example.com',
    addressLine1: '1 George Street',
    city: 'Sydney',
    postalCode: '2000',
    country: 'AU',
  });
  setClock('2026-09-01T00:00:00Z');
  const sub = await platform.post('/superadmin/subscriptions', { tenantId, planId, cycle: 'monthly', start: 'active' });
  expect(sub.status, JSON.stringify(sub.body)).toBe(201);
  setClock(null);
  return { tenantId, admin, subscriptionId: sub.body.id as string };
}

/** A Razorpay-shaped payment event, carrying the payer's details a real one carries. */
function paymentEvent(event: string, paymentId: string, orderId: string, status: string) {
  return {
    entity: 'event',
    account_id: 'acc_test',
    event,
    contains: ['payment'],
    payload: {
      payment: {
        entity: {
          id: paymentId,
          entity: 'payment',
          order_id: orderId,
          status,
          amount: 1,
          currency: 'INR',
          method: 'card',
          email: 'payer@example.com',
          contact: '+919876543210',
          card: { last4: '4242', network: 'Visa' },
        },
      },
    },
    created_at: Math.floor(Date.now() / 1000),
  };
}

function refundEvent(event: string, refundId: string, paymentId: string, status: string, refundRef?: string) {
  return {
    entity: 'event',
    event,
    contains: ['refund'],
    payload: { refund: { entity: { id: refundId, payment_id: paymentId, status, amount: 1, notes: refundRef ? { refundId: refundRef } : {} } } },
    created_at: Math.floor(Date.now() / 1000),
  };
}

/** Delivers `body` as the provider would: raw JSON, signed, with an event id. */
function deliver(body: unknown, opts: { eventId?: string; signature?: string | null; raw?: string; provider?: string } = {}) {
  const raw = opts.raw ?? JSON.stringify(body);
  let req = request(app)
    .post(`/webhooks/${opts.provider ?? 'fakepay'}/subscription`)
    .set('content-type', 'application/json')
    .set('x-razorpay-event-id', opts.eventId ?? `evt_${unique()}`);
  if (opts.signature !== null) req = req.set('x-razorpay-signature', opts.signature ?? signWebhook(raw));
  return req.send(raw);
}

const eventsOf = (id: string) => platformDb.subscriptionEvent.findMany({ where: { subscriptionId: id }, orderBy: { id: 'asc' } });
const receiptOf = (eventId: string) =>
  platformDb.webhookEvent.findUnique({ where: { provider_providerEventId: { provider: 'fakepay', providerEventId: eventId } } });

/** An academy with an upgrade quote and its checkout order, and the provider-side payment for it. */
async function paidUpgrade(status: 'paid' | 'authorized' = 'paid') {
  const a = await academy(SMALL);
  setClock('2026-09-16T00:00:00Z');
  const quote = await a.admin.post('/tenant/subscription/change', { planId: BIG, cycle: 'monthly' });
  const { body } = await a.admin.post('/tenant/billing/checkout', { planChangeId: quote.body.change.id });
  const orderId = body.checkout.orderId as string;
  const payment = fake.pay(orderId, status);
  return { a, orderId, ...payment };
}

beforeAll(async () => {
  const email = `wh-su-${unique()}@example.com`;
  await provisionSuperAdmin({ email, password: PASSWORD, name: 'Hooks' });
  platform = await as({ email, password: PASSWORD });
  expect((await platform.post('/superadmin/tax-rules', { name: 'GST', country: 'AU', components: [{ code: 'GST', label: 'GST', rateBps: 500 }] })).status).toBe(
    201,
  );
  SMALL = await publishedPlan(200000);
  BIG = await publishedPlan(400000);
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

describe('a forged or unsigned webhook is rejected', () => {
  it('refuses no signature, a wrong secret, a tampered body and a wrong provider — and stores none of them', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade();
    const body = paymentEvent('payment.captured', paymentId, orderId, 'captured');
    const raw = JSON.stringify(body);
    const ids = [`evt_${unique()}`, `evt_${unique()}`, `evt_${unique()}`, `evt_${unique()}`];

    expect((await deliver(body, { eventId: ids[0], signature: null })).status).toBe(401);
    expect((await deliver(body, { eventId: ids[1], signature: signWebhook(raw, 'not-the-secret') })).status).toBe(401);
    // Signed, then altered in transit: a payment id swapped in.
    const tampered = raw.replace(paymentId, 'pay_attacker');
    expect((await deliver(null, { eventId: ids[2], raw: tampered, signature: signWebhook(raw) })).status).toBe(401);
    expect((await deliver(body, { eventId: ids[3], provider: 'stripe' })).status).toBe(404);

    for (const id of ids) expect(await receiptOf(id)).toBeNull();
    expect((await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId } })).planId).toBe(SMALL);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(0);
  });

  it('is not found at all without a configured provider, and a signed body that is not an event is refused', async () => {
    setPaymentProvider(null);
    expect((await deliver({ event: 'payment.captured', payload: {} })).status).toBe(404);
    useFake();
    const noId = request(app).post('/webhooks/fakepay/subscription').set('content-type', 'application/json');
    const raw = JSON.stringify({ event: 'payment.captured', payload: {} });
    expect((await noId.set('x-razorpay-signature', signWebhook(raw)).send(raw)).status).toBe(400);
    expect((await deliver({ hello: 'world' })).status).toBe(400);
    expect((await deliver(null, { raw: 'not json at all' })).status).toBe(400);
    expect((await deliver({ event: 'payment.captured', payload: { payment: { entity: {} } } })).status).toBe(400);
  });
});

describe('a verified webhook updates state through the services that own it', () => {
  it('reads the payment back from the provider, records it, settles the invoice and applies the upgrade — under the provider', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade('authorized');
    const eventId = `evt_${unique()}`;
    const res = await deliver(paymentEvent('payment.authorized', paymentId, orderId, 'authorized'), { eventId });
    expect(res.status, JSON.stringify(res.body)).toBe(200);
    expect(res.body).toMatchObject({ received: true, outcome: 'processed' });
    expect(fake.captured).toEqual([paymentId]);
    expect(await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId } })).toMatchObject({ planId: BIG });
    expect((await eventsOf(a.subscriptionId)).at(-1)).toMatchObject({ transition: 'change_plan', actorType: 'provider', source: 'fakepay' });
    const receipt = (await receiptOf(eventId))!;
    expect(receipt).toMatchObject({ status: 'processed', eventType: 'payment.authorized', attempts: 1 });
    expect(receipt.payloadHash).toMatch(/^[0-9a-f]{64}$/);
    expect(JSON.parse(receipt.referenceJson)).toEqual({ paymentId, orderId });
    // The receipt keeps the ids, never the payer's details the payload carried.
    expect(JSON.stringify(receipt)).not.toMatch(/payer@example\.com|9876543210/);
  });

  it('records a failed renewal and moves the subscription past due; a late copy of that failure after payment moves nothing', async () => {
    useFake();
    const a = await academy(SMALL);
    setClock('2026-10-01T06:00:00Z'); // past the period's end: an early decline does not dun
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId: a.subscriptionId }));
    const { body } = await a.admin.post('/tenant/billing/checkout', { invoiceId: invoice.id });
    const orderId = body.checkout.orderId as string;
    const declined = fake.pay(orderId, 'failed');
    const failure = paymentEvent('payment.failed', declined.paymentId, orderId, 'failed');
    expect((await deliver(failure, { eventId: `evt_fail_${unique()}` })).status).toBe(200);
    expect(await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId } })).toMatchObject({ status: 'past_due' });

    const paid = fake.pay(orderId, 'paid');
    expect((await deliver(paymentEvent('payment.captured', paid.paymentId, orderId, 'captured'))).status).toBe(200);
    expect(await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId } })).toMatchObject({ status: 'active' });
    // The provider redelivers the old failure under a new event id: the invoice is paid, nothing regresses.
    expect((await deliver(failure, { eventId: `evt_fail_again_${unique()}` })).status).toBe(200);
    expect(await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId } })).toMatchObject({ status: 'active' });
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'payment_failed')).toHaveLength(1);
  });

  it('settles a refund the provider finishes later, by the refund it was asked for', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade();
    expect((await deliver(paymentEvent('payment.captured', paymentId, orderId, 'captured'))).status).toBe(200);
    const payment = await platformDb.payment.findFirstOrThrow({ where: { providerPaymentId: paymentId } });
    fake.refundAnswer = { providerRefundId: 'ignored', status: 'pending' };
    const refund = await platform.post(`/superadmin/payments/${payment.id}/refund`, { amount: 1000, reason: 'Goodwill credit' });
    expect(refund.body).toMatchObject({ status: 'pending' });

    const settled = refundEvent('refund.processed', `rfnd_${unique()}`, paymentId, 'processed', refund.body.id);
    const eventId = `evt_${unique()}`;
    expect((await deliver(settled, { eventId })).body).toMatchObject({ outcome: 'processed' });
    expect(await platformDb.refund.findUniqueOrThrow({ where: { id: refund.body.id } })).toMatchObject({ status: 'succeeded' });
    expect((await deliver(settled, { eventId })).body).toMatchObject({ duplicate: true });
    // A refund event naming another payment is not applied to this refund.
    const stray = refundEvent('refund.failed', `rfnd_${unique()}`, 'pay_someone_else', 'failed', refund.body.id);
    expect((await deliver(stray)).body).toMatchObject({ outcome: 'ignored' });
    expect(await platformDb.refund.findUniqueOrThrow({ where: { id: refund.body.id } })).toMatchObject({ status: 'succeeded' });
    expect(a.tenantId).toBeTruthy();
  });

  it('acknowledges what the platform does not act on, and stores it as ignored', async () => {
    useFake();
    const other = { entity: 'event', event: 'subscription.charged', payload: { subscription: { entity: { id: `sub_${unique()}` } } } };
    const eventId = `evt_${unique()}`;
    expect((await deliver(other, { eventId })).body).toMatchObject({ received: true, outcome: 'ignored' });
    const stranger = paymentEvent('payment.captured', `pay_${unique()}`, `order_not_ours_${unique()}`, 'captured');
    expect((await deliver(stranger)).body).toMatchObject({ outcome: 'ignored' });
    expect(await receiptOf(eventId)).toMatchObject({ status: 'ignored', note: 'The platform does not act on subscription.charged.' });
  });
});

describe('the same providerEventId delivered twice causes exactly one state change', () => {
  it('answers a redelivery as a duplicate and repeats nothing', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade();
    const body = paymentEvent('payment.captured', paymentId, orderId, 'captured');
    const eventId = `evt_${unique()}`;
    expect((await deliver(body, { eventId })).body).toMatchObject({ outcome: 'processed' });
    const again = await deliver(body, { eventId });
    expect(again.status).toBe(200);
    expect(again.body).toMatchObject({ duplicate: true, outcome: 'processed' });
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'change_plan')).toHaveLength(1);
    expect(await platformDb.webhookEvent.count({ where: { providerEventId: eventId } })).toBe(1);
  });

  it('holds when the deliveries arrive at the same moment', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade();
    const body = paymentEvent('payment.captured', paymentId, orderId, 'captured');
    const eventId = `evt_${unique()}`;
    const answers = await Promise.all([deliver(body, { eventId }), deliver(body, { eventId }), deliver(body, { eventId })]);
    // Exactly one delivery processes it. Each other one is either told to come back (409, it arrived while
    // the first was in flight) or answered as a duplicate (200, it arrived after) — never processed alongside.
    // Which of the two depends on timing; that none processes it twice does not.
    const processedNow = answers.filter((r) => r.status === 200 && !r.body.duplicate);
    expect(processedNow).toHaveLength(1);
    expect(processedNow[0].body).toMatchObject({ outcome: 'processed' });
    for (const other of answers.filter((r) => r !== processedNow[0])) {
      expect(other.status === 409 || (other.status === 200 && other.body.duplicate === true), JSON.stringify(other.body)).toBe(true);
    }
    // The provider's next attempt finds it done.
    expect((await deliver(body, { eventId })).body).toMatchObject({ duplicate: true, outcome: 'processed' });
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'change_plan')).toHaveLength(1);
    expect(await platformDb.webhookEvent.count({ where: { providerEventId: eventId } })).toBe(1);
  });

  it('agrees with the browser: a webhook and a checkout confirmation for the same payment change state once', async () => {
    useFake();
    const { a, orderId, paymentId, signature } = await paidUpgrade();
    await a.admin.post('/tenant/billing/checkout/confirm', { orderId, paymentId, signature });
    expect((await deliver(paymentEvent('payment.captured', paymentId, orderId, 'captured'))).status).toBe(200);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'change_plan')).toHaveLength(1);
  });
});

describe('replay protection', () => {
  it('treats the same signed body under a new event id as a replay: stored, ignored, no effect', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade();
    const raw = JSON.stringify(paymentEvent('payment.captured', paymentId, orderId, 'captured'));
    expect((await deliver(null, { raw, eventId: `evt_${unique()}` })).body).toMatchObject({ outcome: 'processed' });
    const replayId = `evt_replay_${unique()}`;
    const replay = await deliver(null, { raw, eventId: replayId });
    expect(replay.body).toMatchObject({ duplicate: true, outcome: 'ignored' });
    expect((await receiptOf(replayId))!.note).toMatch(/^A replay of event evt_/);
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'change_plan')).toHaveLength(1);
  });
});

describe('webhook state updates are transactional, and a failure is retried to completion', () => {
  it('answers 500 when processing fails, so the provider retries — and the retry finishes the work once', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade();
    const body = paymentEvent('payment.captured', paymentId, orderId, 'captured');
    const eventId = `evt_${unique()}`;
    // The provider cannot be reached when the platform reads the payment back.
    const read = fake.fetchPayment.bind(fake);
    fake.fetchPayment = async () => {
      throw new Error('socket hang up');
    };
    const first = await deliver(body, { eventId });
    expect(first.status).toBe(500);
    expect(await receiptOf(eventId)).toMatchObject({ status: 'failed', attempts: 1 });
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(0);

    fake.fetchPayment = read;
    const retry = await deliver(body, { eventId });
    expect(retry.body).toMatchObject({ outcome: 'processed' });
    expect(await receiptOf(eventId)).toMatchObject({ status: 'processed', attempts: 2 });
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'change_plan')).toHaveLength(1);
  });

  it('finishes a move interrupted after the payment was recorded, without recording it twice', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade();
    // An earlier attempt recorded the payment and settled the invoice — one transaction — then stopped
    // before the subscription moved.
    const order = await platformDb.paymentOrder.findFirstOrThrow({ where: { providerOrderId: orderId } });
    const invoice = await platformDb.invoice.findUniqueOrThrow({ where: { id: order.invoiceId } });
    await asPlatform(() =>
      recordPayment(
        { type: 'provider', provider: 'fakepay', reference: paymentId },
        {
          invoiceId: invoice.id,
          providerPaymentId: paymentId,
          amount: invoice.total,
          currency: 'INR',
          status: 'paid',
        },
      ),
    );
    expect((await platformDb.invoice.findUniqueOrThrow({ where: { id: invoice.id } })).status).toBe('paid');
    expect((await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId } })).planId).toBe(SMALL);

    expect((await deliver(paymentEvent('payment.captured', paymentId, orderId, 'captured'))).body).toMatchObject({ outcome: 'processed' });
    expect((await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId } })).planId).toBe(BIG);
    expect(await platformDb.payment.count({ where: { tenantId: a.tenantId } })).toBe(1);
    expect((await eventsOf(a.subscriptionId)).filter((e) => e.transition === 'change_plan')).toHaveLength(1);
  });

  it('takes over an attempt that crashed mid-way — a receipt left in `received` — once it is clearly not in flight', async () => {
    useFake();
    const { a, orderId, paymentId } = await paidUpgrade();
    const raw = JSON.stringify(paymentEvent('payment.captured', paymentId, orderId, 'captured'));
    const eventId = `evt_${unique()}`;
    // What a process that died after storing the receipt leaves behind: received, five minutes ago.
    await platformDb.webhookEvent.create({
      data: {
        provider: 'fakepay',
        providerEventId: eventId,
        eventType: 'payment.captured',
        payloadHash: createHash('sha256').update(raw).digest('hex'),
        receivedAt: new Date(Date.now() - 5 * 60_000),
      },
    });
    const res = await deliver(null, { raw, eventId });
    expect(res.body).toMatchObject({ outcome: 'processed' });
    expect(await receiptOf(eventId)).toMatchObject({ status: 'processed', attempts: 2 });
    expect((await platformDb.subscription.findUniqueOrThrow({ where: { id: a.subscriptionId } })).planId).toBe(BIG);
  });

  it('keeps each receipt fixed: what arrived never changes, a finished event is final, and none is deleted', async () => {
    useFake();
    const eventId = `evt_${unique()}`;
    await deliver({ entity: 'event', event: 'subscription.charged', payload: {}, created_at: unique() }, { eventId });
    const row = (await receiptOf(eventId))!;
    await expect(platformDb.webhookEvent.update({ where: { id: row.id }, data: { eventType: 'payment.captured' } })).rejects.toThrow();
    await expect(platformDb.webhookEvent.update({ where: { id: row.id }, data: { status: 'received' } })).rejects.toThrow();
    await expect(platformDb.webhookEvent.delete({ where: { id: row.id } })).rejects.toThrow();
  });
});

describe('the Super Admin sees what arrived', () => {
  it('lists receipts with their status and ids, never a body — and only for the Super Admin', async () => {
    useFake();
    const eventId = `evt_${unique()}`;
    await deliver({ entity: 'event', event: 'subscription.charged', payload: {}, created_at: unique() }, { eventId });
    const res = await platform.get('/superadmin/webhooks', { pageSize: 100 });
    expect(res.status).toBe(200);
    const row = res.body.rows.find((r: { providerEventId: string }) => r.providerEventId === eventId);
    expect(row).toMatchObject({ provider: 'fakepay', eventType: 'subscription.charged', status: 'ignored', attempts: 1 });
    expect(Object.keys(row)).not.toContain('payloadHash');
    expect((await (await as('admin')).get('/superadmin/webhooks')).status).toBe(403);
    expect((await anon().get('/superadmin/webhooks')).status).toBe(401);
  });
});
