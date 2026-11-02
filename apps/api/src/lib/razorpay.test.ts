import { createHmac } from 'node:crypto';

import { afterEach, describe, expect, it } from 'vitest';

import { ApiError } from './errors.js';
import { activeProvider, assertPaymentConfig } from './paymentGateways.js';
import { ProviderError, setPaymentProvider } from './paymentProvider.js';
import { RazorpayProvider } from './razorpay.js';

/* SAAS-009: the Razorpay adapter over a stubbed HTTP layer — what it asks Razorpay for, what it keeps of the
 * answers, and how it verifies signatures. No test reaches Razorpay itself. */

const KEY_ID = 'rzp_test_UnitTestKey01';
const KEY_SECRET = 'unit-test-key-secret-000';
const WEBHOOK_SECRET = 'unit-test-webhook-secret';

interface Sent {
  url: string;
  method: string;
  headers: Record<string, string>;
  body?: Record<string, unknown>;
}

/** An adapter whose HTTP answers come from `replies`, in order; the last repeats. */
function adapter(
  replies: { status?: number; body: unknown }[] | 'offline',
  opts: { webhookSecret?: string; keyId?: string; environment?: 'test' | 'live' } = {},
) {
  const sent: Sent[] = [];
  const http = (async (url: string, init: RequestInit) => {
    sent.push({
      url,
      method: String(init.method),
      headers: init.headers as Record<string, string>,
      body: init.body ? JSON.parse(String(init.body)) : undefined,
    });
    if (replies === 'offline') throw new TypeError('fetch failed');
    const reply = replies[Math.min(sent.length - 1, replies.length - 1)];
    return new Response(JSON.stringify(reply.body), { status: reply.status ?? 200, headers: { 'content-type': 'application/json' } });
  }) as unknown as typeof fetch;
  const provider = new RazorpayProvider({ keyId: opts.keyId ?? KEY_ID, keySecret: KEY_SECRET, webhookSecret: opts.webhookSecret }, http, opts.environment);
  return { provider, sent };
}

const refusal = async (promise: Promise<unknown>) => {
  const err = await promise.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(err).toBeInstanceOf(ProviderError);
  return err as ProviderError;
};

describe('asking Razorpay for money', () => {
  it('creates an order for exactly the amount given, in paise, authenticated with the key id and secret', async () => {
    const { provider, sent } = adapter([{ body: { id: 'order_abc', amount: 419895, currency: 'INR', status: 'created' } }]);
    const order = await provider.createPayment({
      amount: 419895,
      currency: 'INR',
      receipt: 'INV-2026-000123-with-a-very-long-suffix-that-overflows',
      notes: { invoiceId: 'inv1' },
    });
    expect(order).toEqual({ providerOrderId: 'order_abc', amount: 419895, currency: 'INR' });
    expect(sent[0]).toMatchObject({ url: 'https://api.razorpay.com/v1/orders', method: 'POST' });
    expect(sent[0].headers.Authorization).toBe(`Basic ${Buffer.from(`${KEY_ID}:${KEY_SECRET}`).toString('base64')}`);
    expect(sent[0].body).toEqual({ amount: 419895, currency: 'INR', receipt: 'INV-2026-000123-with-a-very-long-suffix-', notes: { invoiceId: 'inv1' } });
  });

  it('refuses an order Razorpay answers with a different amount, and a non-integer amount before asking', async () => {
    const { provider } = adapter([{ body: { id: 'order_abc', amount: 1, currency: 'INR' } }]);
    await refusal(provider.createPayment({ amount: 419895, currency: 'INR', receipt: 'r', notes: {} }));
    const { provider: again, sent } = adapter([{ body: {} }]);
    await refusal(again.createPayment({ amount: 4198.95, currency: 'INR', receipt: 'r', notes: {} }));
    expect(sent).toHaveLength(0);
  });

  it('keeps at most 15 notes of 256 characters, as Razorpay allows', async () => {
    const { provider, sent } = adapter([{ body: { id: 'order_x', amount: 100, currency: 'INR' } }]);
    const notes = Object.fromEntries(Array.from({ length: 20 }, (_, i) => [`k${i}`, 'x'.repeat(300)]));
    await provider.createPayment({ amount: 100, currency: 'INR', receipt: 'r', notes });
    const kept = sent[0].body!.notes as Record<string, string>;
    expect(Object.keys(kept)).toHaveLength(15);
    expect(Object.values(kept).every((v) => v.length === 256)).toBe(true);
  });
});

describe('reading a payment back from Razorpay', () => {
  it('reads a captured card payment as paid, keeping only the network and the last four digits', async () => {
    const { provider, sent } = adapter([
      {
        body: {
          id: 'pay_1',
          order_id: 'order_abc',
          amount: 419895,
          currency: 'INR',
          status: 'captured',
          method: 'card',
          card_id: 'card_secretref',
          card: { id: 'card_secretref', network: 'Visa', last4: '1111', name: 'Card Holder', international: false },
          email: 'payer@example.com',
          contact: '+919999999999',
        },
      },
    ]);
    const payment = await provider.fetchPayment('pay_1');
    expect(sent[0]).toMatchObject({ url: 'https://api.razorpay.com/v1/payments/pay_1?expand[]=card', method: 'GET' });
    expect(payment).toEqual({
      providerPaymentId: 'pay_1',
      providerOrderId: 'order_abc',
      amount: 419895,
      currency: 'INR',
      status: 'paid',
      method: { kind: 'card', brand: 'Visa', last4: '1111' },
    });
    expect(JSON.stringify(payment)).not.toMatch(/card_secretref|payer@|9999999999|Card Holder/);
  });

  it('keeps no UPI address, and names the bank for net banking and mandates', async () => {
    const upi = await adapter([
      { body: { id: 'p', amount: 1, currency: 'INR', status: 'captured', method: 'upi', vpa: 'someone@okbank' } },
    ]).provider.fetchPayment('p');
    expect(upi.method).toEqual({ kind: 'upi', brand: 'UPI' });
    expect(JSON.stringify(upi)).not.toContain('someone@okbank');
    const bank = await adapter([
      { body: { id: 'p', amount: 1, currency: 'INR', status: 'captured', method: 'netbanking', bank: 'HDFC' } },
    ]).provider.fetchPayment('p');
    expect(bank.method).toEqual({ kind: 'netbanking', brand: 'HDFC' });
    const wallet = await adapter([
      { body: { id: 'p', amount: 1, currency: 'INR', status: 'captured', method: 'wallet', wallet: 'paytm' } },
    ]).provider.fetchPayment('p');
    expect(wallet.method).toBeUndefined();
  });

  it('maps every Razorpay status, carries the failure reason, and refuses one it does not know', async () => {
    const read = (status: string, extra: object = {}) =>
      adapter([{ body: { id: 'p', amount: 1, currency: 'INR', status, ...extra } }]).provider.fetchPayment('p');
    expect((await read('created')).status).toBe('pending');
    expect((await read('authorized')).status).toBe('authorized');
    expect((await read('refunded')).status).toBe('refunded');
    expect(await read('failed', { error_code: 'BAD_REQUEST_ERROR', error_description: 'Payment declined by bank' })).toMatchObject({
      status: 'failed',
      failureCode: 'BAD_REQUEST_ERROR',
      failureMessage: 'Payment declined by bank',
    });
    await refusal(read('mystery'));
  });

  it('captures an authorized payment for exactly the amount, then reads it again', async () => {
    const { provider, sent } = adapter([{ body: { id: 'p', status: 'captured' } }, { body: { id: 'p', amount: 500, currency: 'INR', status: 'captured' } }]);
    expect((await provider.capturePayment('p', 500, 'INR')).status).toBe('paid');
    expect(sent.map((s) => [s.method, s.url, s.body])).toEqual([
      ['POST', 'https://api.razorpay.com/v1/payments/p/capture', { amount: 500, currency: 'INR' }],
      ['GET', 'https://api.razorpay.com/v1/payments/p?expand[]=card', undefined],
    ]);
  });
});

describe('refunds and recurring subscriptions', () => {
  it('refunds an amount and reads Razorpay’s refund status', async () => {
    const processed = adapter([{ body: { id: 'rfnd_1', status: 'processed' } }]);
    expect(await processed.provider.refundPayment({ providerPaymentId: 'pay_1', amount: 1000, notes: { reason: 'Goodwill' } })).toEqual({
      providerRefundId: 'rfnd_1',
      status: 'succeeded',
    });
    expect(processed.sent[0]).toMatchObject({
      url: 'https://api.razorpay.com/v1/payments/pay_1/refund',
      body: { amount: 1000, notes: { reason: 'Goodwill' } },
    });
    expect((await adapter([{ body: { id: 'r', status: 'pending' } }]).provider.refundPayment({ providerPaymentId: 'p', amount: 1, notes: {} })).status).toBe(
      'pending',
    );
    expect((await adapter([{ body: { id: 'r', status: 'failed' } }]).provider.refundPayment({ providerPaymentId: 'p', amount: 1, notes: {} })).status).toBe(
      'failed',
    );
  });

  it('creates a Razorpay plan for the price, then the subscription on it; changes, pauses, resumes and cancels', async () => {
    const { provider, sent } = adapter([{ body: { id: 'plan_1' } }, { body: { id: 'sub_1', status: 'created' } }, { body: { id: 'plan_1' } }, { body: {} }]);
    const plan = { name: 'Growth', amount: 399900, currency: 'INR', cycle: 'annual' as const };
    expect(await provider.createSubscription({ plan, totalCount: 12, notes: { tenantId: 't1' } })).toEqual({
      providerSubscriptionId: 'sub_1',
      status: 'created',
    });
    await provider.changePlan('sub_1', plan, { atPeriodEnd: true });
    await provider.pauseSubscription('sub_1');
    await provider.resumeSubscription('sub_1');
    await provider.cancelSubscription('sub_1', { atPeriodEnd: false });
    expect(sent.map((s) => [s.method, s.url.replace('https://api.razorpay.com/v1', ''), s.body])).toEqual([
      ['POST', '/plans', { period: 'yearly', interval: 1, item: { name: 'Growth', amount: 399900, currency: 'INR' } }],
      ['POST', '/subscriptions', { plan_id: 'plan_1', total_count: 12, customer_notify: 1, notes: { tenantId: 't1' } }],
      ['POST', '/plans', { period: 'yearly', interval: 1, item: { name: 'Growth', amount: 399900, currency: 'INR' } }],
      ['PATCH', '/subscriptions/sub_1', { plan_id: 'plan_1', schedule_change_at: 'cycle_end' }],
      ['POST', '/subscriptions/sub_1/pause', { pause_at: 'now' }],
      ['POST', '/subscriptions/sub_1/resume', { resume_at: 'now' }],
      ['POST', '/subscriptions/sub_1/cancel', { cancel_at_cycle_end: 0 }],
    ]);
  });

  it('creates a customer, returning the existing one for the same email', async () => {
    const { provider, sent } = adapter([{ body: { id: 'cust_1' } }]);
    expect(await provider.createCustomer({ name: 'Academy', email: 'billing@example.com' })).toEqual({ providerCustomerId: 'cust_1' });
    expect(sent[0].body).toMatchObject({ fail_existing: '0', email: 'billing@example.com' });
  });
});

describe('when Razorpay refuses or cannot be reached', () => {
  it('answers in the platform’s own words, with a stable code, and nothing of Razorpay’s response or the secret', async () => {
    for (const [status, description] of [
      [401, 'Authentication failed'],
      [400, 'The amount must be at least INR 1.00'],
    ] as const) {
      const err = await refusal(adapter([{ status, body: { error: { code: 'BAD_REQUEST_ERROR', description } } }]).provider.fetchPayment('p'));
      expect(err).toBeInstanceOf(ApiError);
      expect(err.status).toBe(502);
      expect(err.code).toBe('PAYMENT_FAILED');
      expect(err.message).not.toContain(description);
      expect(err.message).not.toContain(KEY_SECRET);
      expect(err.detail).toMatchObject({ status, providerCode: 'BAD_REQUEST_ERROR' });
    }
    const offline = await refusal(adapter('offline').provider.createPayment({ amount: 100, currency: 'INR', receipt: 'r', notes: {} }));
    expect(offline.message).toBe('The payment provider could not be reached. Nothing was charged; try again shortly.');
  });
});

describe('signatures', () => {
  const sign = (secret: string, payload: string) => createHmac('sha256', secret).update(payload).digest('hex');

  it('accepts a checkout signed with the key secret over "order|payment", and nothing else', () => {
    const { provider } = adapter([]);
    const good = sign(KEY_SECRET, 'order_abc|pay_1');
    expect(provider.verifyCheckout({ orderId: 'order_abc', paymentId: 'pay_1', signature: good })).toBe(true);
    expect(provider.verifyCheckout({ orderId: 'order_abc', paymentId: 'pay_1', signature: good.toUpperCase() })).toBe(true);
    for (const signature of [sign(KEY_SECRET, 'order_abc|pay_2'), sign('another-secret', 'order_abc|pay_1'), good.slice(0, -2), '', 'not-hex!', good + '00']) {
      expect(provider.verifyCheckout({ orderId: 'order_abc', paymentId: 'pay_1', signature }), signature).toBe(false);
    }
    // The same signature does not carry over to another payment on the order.
    expect(provider.verifyCheckout({ orderId: 'order_abc', paymentId: 'pay_9', signature: good })).toBe(false);
  });

  it('accepts a webhook signed over its exact body with the webhook secret — and every webhook fails without one', () => {
    const body = JSON.stringify({ event: 'payment.captured', payload: { payment: { entity: { id: 'pay_1' } } } });
    const { provider } = adapter([], { webhookSecret: WEBHOOK_SECRET });
    expect(provider.verifyWebhook(body, sign(WEBHOOK_SECRET, body))).toBe(true);
    expect(provider.verifyWebhook(Buffer.from(body), sign(WEBHOOK_SECRET, body))).toBe(true);
    expect(provider.verifyWebhook(`${body} `, sign(WEBHOOK_SECRET, body))).toBe(false);
    expect(provider.verifyWebhook(body, undefined)).toBe(false);
    expect(provider.verifyWebhook(body, sign(KEY_SECRET, body))).toBe(false);
    const unconfigured = adapter([]).provider;
    expect(unconfigured.verifyWebhook(body, sign('', body))).toBe(false);
  });

  it('gives the browser only what is publishable: the key id, never the secret', () => {
    const params = adapter([]).provider.checkoutParams({ providerOrderId: 'order_abc', amount: 500, currency: 'INR' });
    expect(params).toEqual({ provider: 'razorpay', keyId: KEY_ID, orderId: 'order_abc', amount: 500, currency: 'INR' });
    expect(JSON.stringify(params)).not.toContain(KEY_SECRET);
  });
});

describe('checking credentials without moving money (SAAS-017)', () => {
  it('reads one order — a GET, never a charge — and reports Razorpay accepting the keys', async () => {
    const { provider, sent } = adapter([{ body: { items: [] } }], { webhookSecret: WEBHOOK_SECRET });
    expect(await provider.testCredentials()).toEqual({ ok: true, detail: expect.stringMatching(/accepted/) });
    expect(sent).toHaveLength(1);
    expect(sent[0]).toMatchObject({ method: 'GET', url: 'https://api.razorpay.com/v1/orders?count=1' });
  });

  it('reports refused keys, an outage and a missing webhook secret as failures — never as success', async () => {
    expect(
      (await adapter([{ status: 401, body: { error: { code: 'BAD_REQUEST_ERROR' } } }], { webhookSecret: WEBHOOK_SECRET }).provider.testCredentials()).ok,
    ).toBe(false);
    expect((await adapter('offline', { webhookSecret: WEBHOOK_SECRET }).provider.testCredentials()).detail).toMatch(/could not be reached/);
    const noHook = adapter([{ body: { items: [] } }]);
    expect((await noHook.provider.testCredentials()).detail).toMatch(/webhook secret/);
    expect(noHook.sent).toHaveLength(0);
  });

  it('refuses a key whose prefix is not the chosen environment’s, before calling Razorpay', async () => {
    const live = adapter([{ body: { items: [] } }], { webhookSecret: WEBHOOK_SECRET, environment: 'live' });
    expect((await live.provider.testCredentials()).detail).toMatch(/rzp_live_/);
    expect(live.sent).toHaveLength(0);
  });

  it('never puts a secret in what it reports', async () => {
    for (const replies of [[{ body: {} }], [{ status: 401, body: {} }]] as const) {
      const check = await adapter([...replies], { webhookSecret: WEBHOOK_SECRET }).provider.testCredentials();
      expect(JSON.stringify(check)).not.toContain(KEY_SECRET);
      expect(JSON.stringify(check)).not.toContain(WEBHOOK_SECRET);
    }
  });
});

describe('the environment configures no gateway (SAAS-017)', () => {
  afterEach(() => setPaymentProvider(undefined));

  it('ignores RAZORPAY_* in the environment: no gateway is built from it', async () => {
    const saved = { ...process.env };
    try {
      Object.assign(process.env, { PAYMENT_PROVIDER: 'razorpay', RAZORPAY_KEY_ID: KEY_ID, RAZORPAY_KEY_SECRET: KEY_SECRET });
      expect(await activeProvider()).toBeNull();
    } finally {
      process.env = saved;
    }
  });

  it('starts with leftover gateway variables, but refuses a malformed credentials key — naming neither value', () => {
    expect(() => assertPaymentConfig({})).not.toThrow();
    expect(() => assertPaymentConfig({ PAYMENT_PROVIDER: 'razorpay', RAZORPAY_KEY_SECRET: KEY_SECRET })).not.toThrow();
    expect(() => assertPaymentConfig({ PAYMENT_CREDENTIALS_KEY: 'short' })).toThrow(/32 bytes/);
    try {
      assertPaymentConfig({ PAYMENT_CREDENTIALS_KEY: 'not-a-key-secret-value' });
    } catch (e) {
      expect(String(e)).not.toContain('not-a-key-secret-value');
    }
  });

  it('can be replaced by a test double, and put back', async () => {
    const fake = new RazorpayProvider({ keyId: 'k', keySecret: 's' });
    setPaymentProvider(fake);
    expect(await activeProvider()).toBe(fake);
    setPaymentProvider(null);
    expect(await activeProvider()).toBeNull();
    // Back to the database, which has no active gateway under the test runner's fresh database.
    setPaymentProvider(undefined);
    expect(await activeProvider()).toBeNull();
  });
});
