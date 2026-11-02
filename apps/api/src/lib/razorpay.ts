import { createHmac, timingSafeEqual } from 'node:crypto';

import { describeError, observe } from './observe.js';
import {
  ProviderError,
  type CheckoutParams,
  type CredentialCheck,
  type PaymentProvider,
  type ProviderOrder,
  type ProviderPayment,
  type ProviderPlanRef,
  type ProviderRefund,
  type ProviderWebhookEvent,
  WebhookPayloadError,
  type MaskedMethod,
} from './paymentProvider.js';

/*
 * The Razorpay adapter (SAAS-009) — the only code in the LMS that knows Razorpay exists. It speaks the
 * REST API directly over HTTPS with the key id and secret the gateway factory decrypted from the Super Admin's
 * configuration (SAAS-017) — never from the environment; there is no SDK.
 *
 *   - Money goes out exactly as the server fixed it: integer paise, never a float.
 *   - A payment's status is read back from Razorpay, server to server; nothing a browser says about a
 *     payment is taken on trust. Checkout and webhook signatures are HMAC-SHA256, compared in constant time.
 *   - Only masked method data leaves here: a card network and its last four digits, "UPI", a bank's name.
 *     A UPI address, a card number or a full card id is never returned.
 *   - Errors carry our own message; Razorpay's response is logged through `observe`, redacted, and never
 *     reaches a client.
 */

const API = 'https://api.razorpay.com/v1';
const TIMEOUT_MS = 15_000;

export interface RazorpayCredentials {
  keyId: string;
  keySecret: string;
  /** Separate from the key secret: Razorpay signs webhooks with the secret set on the webhook itself. */
  webhookSecret?: string;
}

type Json = Record<string, unknown>;

/** A constant-time comparison of two hex HMACs; false for anything that is not one. */
function sameHmac(expectedHex: string, given: string | undefined): boolean {
  if (!given || !/^[0-9a-f]+$/i.test(given) || given.length !== expectedHex.length) return false;
  return timingSafeEqual(Buffer.from(expectedHex, 'hex'), Buffer.from(given.toLowerCase(), 'hex'));
}

const hmac = (secret: string, payload: string | Buffer) => createHmac('sha256', secret).update(payload).digest('hex');

/** Razorpay's notes: at most 15 keys, each value at most 256 characters. */
function notesOf(notes: Record<string, string> = {}): Record<string, string> {
  return Object.fromEntries(
    Object.entries(notes)
      .slice(0, 15)
      .map(([k, v]) => [k, String(v).slice(0, 256)]),
  );
}

/** A payment's method as far as it is safe to keep. Kinds the LMS does not show (wallets, EMI) are left out. */
function methodOf(p: Json): MaskedMethod | undefined {
  const card = (p.card ?? {}) as Json;
  switch (p.method) {
    case 'card': {
      const last4 = typeof card.last4 === 'string' && /^\d{4}$/.test(card.last4) ? card.last4 : undefined;
      return { kind: 'card', brand: typeof card.network === 'string' && card.network ? card.network : 'Card', ...(last4 ? { last4 } : {}) };
    }
    case 'upi':
      return { kind: 'upi', brand: 'UPI' };
    case 'netbanking':
      return { kind: 'netbanking', brand: typeof p.bank === 'string' && p.bank ? p.bank : 'Net banking' };
    case 'emandate':
    case 'nach':
      return { kind: 'mandate', brand: typeof p.bank === 'string' && p.bank ? p.bank : 'Mandate' };
    default:
      return undefined;
  }
}

const STATUS: Record<string, ProviderPayment['status']> = {
  created: 'pending',
  authorized: 'authorized',
  captured: 'paid',
  failed: 'failed',
  refunded: 'refunded',
};

function toPayment(p: Json): ProviderPayment {
  const status = STATUS[String(p.status)];
  if (!status || typeof p.id !== 'string' || !Number.isSafeInteger(p.amount) || typeof p.currency !== 'string') {
    throw new ProviderError('The payment provider sent a payment the platform could not read.', { operation: 'read payment' });
  }
  const method = methodOf(p);
  return {
    providerPaymentId: p.id,
    ...(typeof p.order_id === 'string' ? { providerOrderId: p.order_id } : {}),
    amount: p.amount as number,
    currency: p.currency,
    status,
    ...(method ? { method } : {}),
    ...(status === 'failed' && typeof p.error_code === 'string' ? { failureCode: p.error_code } : {}),
    ...(status === 'failed' && typeof p.error_description === 'string' ? { failureMessage: p.error_description } : {}),
  };
}

const isRecord = (v: unknown): v is Json => typeof v === 'object' && v !== null && !Array.isArray(v);

/** `payload.<kind>.entity` of a Razorpay webhook, when present. */
function entity(payload: Json, kind: string): Json | undefined {
  const holder = payload[kind];
  return isRecord(holder) && isRecord(holder.entity) ? holder.entity : undefined;
}

export class RazorpayProvider implements PaymentProvider {
  readonly name = 'razorpay';
  readonly webhookSignatureHeader = 'x-razorpay-signature';
  readonly webhookEventIdHeader = 'x-razorpay-event-id';

  constructor(
    private readonly credentials: RazorpayCredentials,
    private readonly http: typeof fetch = (input, init) => fetch(input, init),
    readonly environment: 'test' | 'live' = 'test',
  ) {}

  /** One call to the API. Refusals and outages become a `ProviderError` with our own words. */
  private async call(operation: string, method: 'GET' | 'POST' | 'PATCH', path: string, body?: Json): Promise<Json> {
    const auth = Buffer.from(`${this.credentials.keyId}:${this.credentials.keySecret}`).toString('base64');
    let response: Response;
    try {
      response = await this.http(`${API}${path}`, {
        method,
        headers: { Authorization: `Basic ${auth}`, ...(body ? { 'Content-Type': 'application/json' } : {}) },
        ...(body ? { body: JSON.stringify(body) } : {}),
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
    } catch (err) {
      observe('payment.failed', { provider: this.name, operation, reason: 'unreachable', error: describeError(err) });
      throw new ProviderError('The payment provider could not be reached. Nothing was charged; try again shortly.', { operation });
    }
    const payload = (await response.json().catch(() => ({}))) as Json;
    if (!response.ok) {
      const error = (payload.error ?? {}) as Json;
      const detail = {
        operation,
        status: response.status,
        providerCode: typeof error.code === 'string' ? error.code : undefined,
        description: typeof error.description === 'string' ? error.description : undefined,
      };
      observe('payment.failed', { provider: this.name, ...detail });
      throw new ProviderError(
        response.status === 401 ? 'The payment provider refused the platform’s credentials.' : 'The payment provider refused the request.',
        detail,
      );
    }
    return payload;
  }

  /** A Razorpay plan for a recurring price. Razorpay plans are immutable, like our plan versions. */
  private async plan(plan: ProviderPlanRef): Promise<string> {
    const created = await this.call('create plan', 'POST', '/plans', {
      period: plan.cycle === 'annual' ? 'yearly' : 'monthly',
      interval: 1,
      item: { name: plan.name.slice(0, 100), amount: plan.amount, currency: plan.currency },
    });
    return String(created.id);
  }

  async createCustomer(input: { name: string; email: string; notes?: Record<string, string> }) {
    // `fail_existing: 0` returns the existing customer for the same email instead of failing.
    const created = await this.call('create customer', 'POST', '/customers', {
      name: input.name.slice(0, 50),
      email: input.email,
      fail_existing: '0',
      notes: notesOf(input.notes),
    });
    return { providerCustomerId: String(created.id) };
  }

  async createSubscription(input: { plan: ProviderPlanRef; totalCount: number; notes?: Record<string, string> }) {
    const planId = await this.plan(input.plan);
    const created = await this.call('create subscription', 'POST', '/subscriptions', {
      plan_id: planId,
      total_count: input.totalCount,
      customer_notify: 1,
      notes: notesOf(input.notes),
    });
    return { providerSubscriptionId: String(created.id), status: String(created.status) };
  }

  async cancelSubscription(id: string, opts: { atPeriodEnd: boolean }) {
    await this.call('cancel subscription', 'POST', `/subscriptions/${encodeURIComponent(id)}/cancel`, { cancel_at_cycle_end: opts.atPeriodEnd ? 1 : 0 });
  }

  async pauseSubscription(id: string) {
    await this.call('pause subscription', 'POST', `/subscriptions/${encodeURIComponent(id)}/pause`, { pause_at: 'now' });
  }

  async resumeSubscription(id: string) {
    await this.call('resume subscription', 'POST', `/subscriptions/${encodeURIComponent(id)}/resume`, { resume_at: 'now' });
  }

  async changePlan(id: string, plan: ProviderPlanRef, opts: { atPeriodEnd: boolean }) {
    const planId = await this.plan(plan);
    await this.call('change plan', 'PATCH', `/subscriptions/${encodeURIComponent(id)}`, {
      plan_id: planId,
      schedule_change_at: opts.atPeriodEnd ? 'cycle_end' : 'now',
    });
  }

  async createPayment(input: { amount: number; currency: string; receipt: string; notes: Record<string, string> }): Promise<ProviderOrder> {
    if (!Number.isSafeInteger(input.amount) || input.amount < 1)
      throw new ProviderError('A payment is a whole number of paise, at least 1.', { operation: 'create order' });
    const order = await this.call('create order', 'POST', '/orders', {
      amount: input.amount,
      currency: input.currency,
      receipt: input.receipt.slice(0, 40),
      notes: notesOf(input.notes),
    });
    if (typeof order.id !== 'string' || order.amount !== input.amount || order.currency !== input.currency) {
      throw new ProviderError('The payment provider answered with a different amount than was asked for.', { operation: 'create order' });
    }
    return { providerOrderId: order.id, amount: input.amount, currency: input.currency };
  }

  async fetchPayment(providerPaymentId: string): Promise<ProviderPayment> {
    // `expand[]=card` returns the card's network and last four; the full card id stays with Razorpay.
    return toPayment(await this.call('read payment', 'GET', `/payments/${encodeURIComponent(providerPaymentId)}?expand[]=card`));
  }

  async listOrderPayments(providerOrderId: string): Promise<ProviderPayment[]> {
    const list = await this.call('list order payments', 'GET', `/orders/${encodeURIComponent(providerOrderId)}/payments`);
    return (Array.isArray(list.items) ? (list.items as Json[]) : []).map(toPayment);
  }

  async capturePayment(providerPaymentId: string, amount: number, currency: string): Promise<ProviderPayment> {
    await this.call('capture payment', 'POST', `/payments/${encodeURIComponent(providerPaymentId)}/capture`, { amount, currency });
    return this.fetchPayment(providerPaymentId);
  }

  async refundPayment(input: { providerPaymentId: string; amount: number; notes: Record<string, string> }): Promise<ProviderRefund> {
    const refund = await this.call('refund payment', 'POST', `/payments/${encodeURIComponent(input.providerPaymentId)}/refund`, {
      amount: input.amount,
      notes: notesOf(input.notes),
    });
    const status = refund.status === 'processed' ? 'succeeded' : refund.status === 'failed' ? 'failed' : 'pending';
    return { providerRefundId: String(refund.id), status };
  }

  verifyWebhook(rawBody: string | Buffer, signature: string | undefined): boolean {
    // No secret, no trust: an unconfigured webhook secret rejects every webhook.
    if (!this.credentials.webhookSecret) return false;
    return sameHmac(hmac(this.credentials.webhookSecret, rawBody), signature);
  }

  /**
   * Razorpay names each delivery in the `X-Razorpay-Event-Id` header and the event in `event`; payment
   * events carry `payload.payment.entity`, refund events `payload.refund.entity`. Only ids and statuses
   * are taken — the entities also hold the payer's email, phone and address, which are not.
   */
  parseWebhook(body: unknown, headers: Record<string, string | undefined>): { eventId: string; event: ProviderWebhookEvent } {
    const eventId = headers['x-razorpay-event-id']?.trim();
    if (!eventId || eventId.length > 128) throw new WebhookPayloadError('The webhook has no event id.');
    if (!isRecord(body) || typeof body.event !== 'string' || !isRecord(body.payload))
      throw new WebhookPayloadError('The webhook body is not a Razorpay event.');
    const eventType = body.event.slice(0, 64);
    if (eventType.startsWith('payment.') || eventType === 'order.paid') {
      const payment = entity(body.payload, 'payment');
      if (!payment || typeof payment.id !== 'string') throw new WebhookPayloadError('The payment event names no payment.');
      return {
        eventId,
        event: {
          kind: 'payment',
          eventType,
          providerPaymentId: payment.id,
          ...(typeof payment.order_id === 'string' ? { providerOrderId: payment.order_id } : {}),
        },
      };
    }
    if (eventType.startsWith('refund.')) {
      const refund = entity(body.payload, 'refund');
      if (!refund || typeof refund.id !== 'string' || typeof refund.payment_id !== 'string') throw new WebhookPayloadError('The refund event names no refund.');
      const notes = isRecord(refund.notes) ? refund.notes : {};
      const status = refund.status === 'processed' ? 'succeeded' : refund.status === 'failed' ? 'failed' : 'pending';
      return {
        eventId,
        event: {
          kind: 'refund',
          eventType,
          providerRefundId: refund.id,
          providerPaymentId: refund.payment_id,
          status,
          ...(typeof notes.refundId === 'string' ? { refundRef: notes.refundId } : {}),
        },
      };
    }
    return { eventId, event: { kind: 'other', eventType } };
  }

  verifyCheckout(input: { orderId: string; paymentId: string; signature: string }): boolean {
    return sameHmac(hmac(this.credentials.keySecret, `${input.orderId}|${input.paymentId}`), input.signature);
  }

  /**
   * A read that moves no money: the newest order, if any. It proves the key pair authenticates, and the key
   * id's prefix must match the environment the Super Admin chose — a live key never runs as "test".
   */
  async testCredentials(): Promise<CredentialCheck> {
    const prefix = this.environment === 'live' ? 'rzp_live_' : 'rzp_test_';
    if (!this.credentials.keyId.startsWith(prefix)) {
      return { ok: false, detail: `The key id is not a ${this.environment} key: Razorpay ${this.environment} key ids begin with ${prefix}.` };
    }
    if (!this.credentials.webhookSecret) return { ok: false, detail: 'The webhook secret is missing: payments are confirmed by signed webhooks.' };
    try {
      await this.call('test credentials', 'GET', '/orders?count=1');
      return { ok: true, detail: 'Razorpay accepted the key id and secret. Nothing was charged.' };
    } catch (err) {
      const status = err instanceof ProviderError ? err.detail.status : undefined;
      if (status === 401) return { ok: false, detail: 'Razorpay refused the key id and secret.' };
      return { ok: false, detail: 'Razorpay could not be reached, so the credentials were not confirmed. Try again shortly.' };
    }
  }

  checkoutParams(order: ProviderOrder): CheckoutParams {
    return { provider: this.name, keyId: this.credentials.keyId, orderId: order.providerOrderId, amount: order.amount, currency: order.currency };
  }
}
