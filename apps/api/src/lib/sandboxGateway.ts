import { createHmac, randomUUID, timingSafeEqual } from 'node:crypto';

import { APP_URL } from './mail.js';
import {
  ProviderError,
  WebhookPayloadError,
  type CheckoutParams,
  type PaymentProvider,
  type ProviderOrder,
  type ProviderPayment,
  type ProviderRefund,
  type ProviderWebhookEvent,
} from './paymentProvider.js';

/*
 * The sandbox payment gateway (SAAS-030) — for development and end-to-end tests only, never production.
 *
 * It stands in for a hosted-page gateway so the whole paid journey can be driven in a browser: the academy opens
 * checkout as with any gateway; the browser is sent to a test checkout page (`/sandbox-checkout/:orderId` in the web
 * app) that offers pay, decline and cancel; the outcome is reported back to the platform the way a real gateway
 * reports it — an HMAC-signed webhook to `POST /webhooks/sandbox/subscription`, verified, made idempotent and
 * settled by exactly the code that settles Razorpay's. Nothing here is a shortcut around that path: the sandbox
 * only plays the gateway's part.
 *
 * `PAYMENT_SANDBOX=on` turns it on, and only while no real gateway is active. The API refuses to start with it in
 * production (`assertSandboxConfig`), and every sandbox route answers 404 while it is off. Its orders and payments
 * live in this process's memory, as a gateway's live on the gateway's side.
 */

export const SANDBOX = 'sandbox';

/** On only when asked for, and never in production. */
export const sandboxEnabled = (env: NodeJS.ProcessEnv = process.env) => env.PAYMENT_SANDBOX === 'on' && env.NODE_ENV !== 'production';

/** Called once at boot: a production process refuses the sandbox outright. */
export function assertSandboxConfig(env: NodeJS.ProcessEnv = process.env) {
  if (env.PAYMENT_SANDBOX === 'on' && env.NODE_ENV === 'production')
    throw new Error('PAYMENT_SANDBOX=on is refused in production: the sandbox gateway moves no real money.');
}

/** The sandbox's own secrets, derived from the server secret — distinct for checkout and webhook signatures. */
const secret = (purpose: string) =>
  createHmac('sha256', process.env.JWT_SECRET ?? 'dev-secret-change-me')
    .update(`sandbox-gateway:${purpose}`)
    .digest('hex');

const sign = (key: string, data: string | Buffer) => createHmac('sha256', key).update(data).digest('hex');

function sameHex(a: string, b: string) {
  const x = Buffer.from(a, 'hex');
  const y = Buffer.from(b, 'hex');
  return x.length > 0 && x.length === y.length && timingSafeEqual(x, y);
}

interface SandboxOrder {
  order: ProviderOrder;
  receipt: string;
  notes: Record<string, string>;
  payments: string[];
  createdAt: number;
}

export type SandboxOutcome = 'success' | 'failure';

/** A webhook as the sandbox delivers it: the exact body and its signature header. */
export interface SandboxWebhook {
  body: string;
  headers: Record<string, string>;
}

export class SandboxProvider implements PaymentProvider {
  readonly name = SANDBOX;
  readonly environment = 'test' as const;
  readonly webhookSignatureHeader = 'x-sandbox-signature';
  readonly webhookEventIdHeader = 'x-sandbox-event-id';
  private readonly orders = new Map<string, SandboxOrder>();
  private readonly payments = new Map<string, ProviderPayment>();

  private get keySecret() {
    return secret('checkout');
  }
  private get webhookSecret() {
    return secret('webhook');
  }

  async createCustomer() {
    return { providerCustomerId: `sbx_cust_${randomUUID()}` };
  }
  async createSubscription() {
    return { providerSubscriptionId: `sbx_sub_${randomUUID()}`, status: 'created' };
  }
  async cancelSubscription() {}
  async pauseSubscription() {}
  async resumeSubscription() {}
  async changePlan() {}

  async createPayment(input: { amount: number; currency: string; receipt: string; notes: Record<string, string> }): Promise<ProviderOrder> {
    if (!Number.isInteger(input.amount) || input.amount <= 0)
      throw new ProviderError('The payment could not be opened.', { operation: 'create order', description: 'amount' });
    const order = { providerOrderId: `sbx_order_${randomUUID()}`, amount: input.amount, currency: input.currency };
    this.orders.set(order.providerOrderId, { order, receipt: input.receipt, notes: input.notes, payments: [], createdAt: Date.now() });
    return order;
  }

  async fetchPayment(providerPaymentId: string): Promise<ProviderPayment> {
    const payment = this.payments.get(providerPaymentId);
    if (!payment) throw new ProviderError('The payment could not be found at the gateway.', { operation: 'fetch payment', status: 404 });
    return { ...payment };
  }

  async listOrderPayments(providerOrderId: string): Promise<ProviderPayment[]> {
    return (this.orders.get(providerOrderId)?.payments ?? []).map((id) => ({ ...this.payments.get(id)! }));
  }

  async capturePayment(providerPaymentId: string, amount: number, currency: string): Promise<ProviderPayment> {
    const payment = await this.fetchPayment(providerPaymentId);
    if (payment.amount !== amount || payment.currency !== currency) throw new ProviderError('The capture amount does not match.', { operation: 'capture' });
    if (payment.status === 'authorized') this.payments.set(providerPaymentId, { ...payment, status: 'paid' });
    return this.fetchPayment(providerPaymentId);
  }

  async refundPayment(input: { providerPaymentId: string; amount: number }): Promise<ProviderRefund> {
    const payment = await this.fetchPayment(input.providerPaymentId);
    if (payment.status !== 'paid') throw new ProviderError('Only a captured payment can be refunded.', { operation: 'refund' });
    if (input.amount >= payment.amount) this.payments.set(payment.providerPaymentId, { ...payment, status: 'refunded' });
    return { providerRefundId: `sbx_rfnd_${randomUUID()}`, status: 'succeeded' };
  }

  verifyWebhook(rawBody: string | Buffer, signature: string | undefined): boolean {
    return Boolean(signature) && sameHex(sign(this.webhookSecret, rawBody), signature!);
  }

  parseWebhook(body: unknown): { eventId: string; event: ProviderWebhookEvent } {
    const b = body as { id?: unknown; event?: unknown; payment?: { id?: unknown; orderId?: unknown } };
    if (typeof b?.id !== 'string' || typeof b.event !== 'string') throw new WebhookPayloadError('The sandbox webhook has no id or event.');
    if (b.event.startsWith('payment.')) {
      if (typeof b.payment?.id !== 'string') throw new WebhookPayloadError('The sandbox payment event names no payment.');
      return {
        eventId: b.id,
        event: {
          kind: 'payment',
          eventType: b.event,
          providerPaymentId: b.payment.id,
          ...(typeof b.payment.orderId === 'string' ? { providerOrderId: b.payment.orderId } : {}),
        },
      };
    }
    return { eventId: b.id, event: { kind: 'other', eventType: b.event } };
  }

  verifyCheckout(input: { orderId: string; paymentId: string; signature: string }): boolean {
    return sameHex(sign(this.keySecret, `${input.orderId}|${input.paymentId}`), input.signature);
  }

  checkoutParams(order: ProviderOrder): CheckoutParams {
    return {
      provider: SANDBOX,
      orderId: order.providerOrderId,
      amount: order.amount,
      currency: order.currency,
      redirectUrl: `${APP_URL}/sandbox-checkout/${order.providerOrderId}`,
    };
  }

  async testCredentials() {
    return { ok: true, detail: 'The sandbox gateway needs no credentials. It moves no real money.' };
  }

  /* ─── The gateway's side: what the test checkout page does ─── */

  /** An order as the test checkout page shows it, or undefined. */
  order(orderId: string) {
    const found = this.orders.get(orderId);
    if (!found) return undefined;
    const last = found.payments.length ? this.payments.get(found.payments[found.payments.length - 1]!) : undefined;
    return { orderId, amount: found.order.amount, currency: found.order.currency, receipt: found.receipt, status: last?.status ?? 'created' };
  }

  /**
   * The payer pays (or is declined) on the test page. Records the payment as the gateway would, and answers the
   * signed webhook the gateway sends about it — the caller delivers it to the platform's webhook URL.
   */
  pay(orderId: string, outcome: SandboxOutcome): { payment: ProviderPayment; webhook: SandboxWebhook } {
    const found = this.orders.get(orderId);
    if (!found) throw new ProviderError('The order could not be found at the gateway.', { operation: 'pay', status: 404 });
    if (found.payments.some((id) => this.payments.get(id)?.status === 'paid'))
      throw new ProviderError('This order is already paid.', { operation: 'pay', status: 409 });
    const payment: ProviderPayment = {
      providerPaymentId: `sbx_pay_${randomUUID()}`,
      providerOrderId: orderId,
      amount: found.order.amount,
      currency: found.order.currency,
      status: outcome === 'success' ? 'paid' : 'failed',
      method: { kind: 'card', brand: 'Visa', last4: '4242' },
      ...(outcome === 'failure' ? { failureCode: 'card_declined', failureMessage: 'The test card was declined.' } : {}),
    };
    this.payments.set(payment.providerPaymentId, payment);
    found.payments.push(payment.providerPaymentId);
    return { payment: { ...payment }, webhook: this.webhookFor(payment, outcome === 'success' ? 'payment.captured' : 'payment.failed') };
  }

  /** A signed webhook about a payment — also how tests forge, replay or duplicate one. */
  webhookFor(payment: Pick<ProviderPayment, 'providerPaymentId' | 'providerOrderId'>, event: string, eventId = `sbx_evt_${randomUUID()}`): SandboxWebhook {
    const body = JSON.stringify({ id: eventId, event, payment: { id: payment.providerPaymentId, orderId: payment.providerOrderId } });
    return {
      body,
      headers: { 'content-type': 'application/json', [this.webhookSignatureHeader]: sign(this.webhookSecret, body), [this.webhookEventIdHeader]: eventId },
    };
  }

  /** The checkout completion a payer's browser would hand back — signed as the gateway signs it. */
  completionFor(orderId: string, paymentId: string) {
    return { orderId, paymentId, signature: sign(this.keySecret, `${orderId}|${paymentId}`) };
  }
}

/** The one sandbox gateway of this process. */
export const sandboxProvider = new SandboxProvider();

/** How the sandbox delivers its webhooks: to this API's own webhook URL. Tests replace it. */
export type WebhookSender = (webhook: SandboxWebhook) => Promise<{ status: number }>;

const defaultSender: WebhookSender = async (webhook) => {
  const url = process.env.SANDBOX_WEBHOOK_URL ?? `http://127.0.0.1:${process.env.PORT ?? 4000}/webhooks/${SANDBOX}/courses`;
  const res = await fetch(url, { method: 'POST', headers: webhook.headers, body: webhook.body });
  return { status: res.status };
};

let sender: WebhookSender = defaultSender;

/** Tests only: delivers the sandbox's webhooks some other way (`null` restores the default). */
export const setSandboxWebhookSender = (next: WebhookSender | null) => {
  sender = next ?? defaultSender;
};

export const deliverSandboxWebhook = (webhook: SandboxWebhook) => sender(webhook);
