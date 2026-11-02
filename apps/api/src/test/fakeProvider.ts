import { createHmac } from 'node:crypto';

import { ProviderError, type PaymentProvider, type ProviderOrder, type ProviderPayment, type ProviderRefund } from '../lib/paymentProvider.js';
import { RazorpayProvider } from '../lib/razorpay.js';
import { unique } from './helpers.js';

/** The webhook secret the fake provider signs with. */
export const FAKE_WEBHOOK_SECRET = 'fake-webhook-secret-for-tests';

/** Razorpay's own webhook signature check and parser, under the test secret — the code production runs. */
const razorpayWebhooks = new RazorpayProvider({ keyId: 'rzp_test_fake', keySecret: 'fake-key-secret', webhookSecret: FAKE_WEBHOOK_SECRET });

/** Signs a webhook body the way Razorpay does: HMAC-SHA256 of the exact body, hex. */
export const signWebhook = (body: string, secret = FAKE_WEBHOOK_SECRET) => createHmac('sha256', secret).update(body).digest('hex');

/** A provider that keeps its orders and payments in memory, and signs checkouts `sig:<order>|<payment>`. */
export class FakeProvider implements PaymentProvider {
  readonly webhookSignatureHeader = razorpayWebhooks.webhookSignatureHeader;
  readonly webhookEventIdHeader = razorpayWebhooks.webhookEventIdHeader;
  orders = new Map<string, ProviderOrder>();
  payments = new Map<string, ProviderPayment>();
  captured: string[] = [];
  /** `error`: the gateway refuses (400); `timeout`: no answer, so nobody knows whether it paid. */
  refundAnswer: ProviderRefund | 'error' | 'timeout' = { providerRefundId: 'rf_default', status: 'succeeded' };
  refunds: { providerPaymentId: string; amount: number }[] = [];
  private seq = 0;

  /** A second fake under another name stands in for a second gateway (SAAS-017 switching tests). */
  constructor(readonly name = 'fakepay') {}

  /** Each fake signs as itself, so one gateway's signature never verifies at another. */
  private get sigPrefix() {
    return this.name === 'fakepay' ? 'sig' : `sig-${this.name}`;
  }

  /** The provider's side of a checkout: a payment on `orderId`, in whatever state the bank left it. */
  pay(orderId: string, status: ProviderPayment['status'], over: Partial<ProviderPayment> = {}): { paymentId: string; signature: string } {
    const order = this.orders.get(orderId)!;
    const paymentId = `pay_fake_${++this.seq}_${unique()}`;
    this.payments.set(paymentId, {
      providerPaymentId: paymentId,
      providerOrderId: orderId,
      amount: order.amount,
      currency: order.currency,
      status,
      method: { kind: 'card', brand: 'Visa', last4: '4242' },
      ...(status === 'failed' ? { failureCode: 'BAD_REQUEST_ERROR', failureMessage: 'Payment declined by the bank' } : {}),
      ...over,
    });
    return { paymentId, signature: `${this.sigPrefix}:${orderId}|${paymentId}` };
  }

  async createCustomer() {
    return { providerCustomerId: 'cust_fake' };
  }
  async createSubscription() {
    return { providerSubscriptionId: 'sub_fake', status: 'created' };
  }
  async cancelSubscription() {}
  async pauseSubscription() {}
  async resumeSubscription() {}
  async changePlan() {}
  async createPayment(input: { amount: number; currency: string }) {
    const order = { providerOrderId: `order_fake_${++this.seq}_${unique()}`, amount: input.amount, currency: input.currency };
    this.orders.set(order.providerOrderId, order);
    return order;
  }
  async fetchPayment(id: string) {
    const payment = this.payments.get(id);
    if (!payment) throw new ProviderError('The payment provider refused the request.', { operation: 'read payment', status: 400 });
    return { ...payment };
  }
  async listOrderPayments(orderId: string) {
    return [...this.payments.values()].filter((p) => p.providerOrderId === orderId).map((p) => ({ ...p }));
  }
  async capturePayment(id: string, amount: number) {
    const payment = this.payments.get(id)!;
    if (payment.status !== 'authorized' || payment.amount !== amount)
      throw new ProviderError('The payment provider refused the request.', { operation: 'capture' });
    this.captured.push(id);
    this.payments.set(id, { ...payment, status: 'paid' });
    return { ...payment, status: 'paid' as const };
  }
  async refundPayment(input: { providerPaymentId: string; amount: number }) {
    this.refunds.push(input);
    if (this.refundAnswer === 'error') throw new ProviderError('The payment provider refused the request.', { operation: 'refund', status: 400 });
    if (this.refundAnswer === 'timeout')
      throw new ProviderError('The payment provider could not be reached. Nothing was charged; try again shortly.', { operation: 'refund' });
    return { ...this.refundAnswer, providerRefundId: `rf_${unique()}` };
  }
  verifyWebhook(rawBody: string | Buffer, signature: string | undefined) {
    return razorpayWebhooks.verifyWebhook(rawBody, signature);
  }
  parseWebhook(body: unknown, headers: Record<string, string | undefined>) {
    return razorpayWebhooks.parseWebhook(body, headers);
  }
  verifyCheckout(input: { orderId: string; paymentId: string; signature: string }) {
    return input.signature === `${this.sigPrefix}:${input.orderId}|${input.paymentId}`;
  }
  checkoutParams(order: ProviderOrder) {
    return { provider: this.name, keyId: 'fake_key_id', orderId: order.providerOrderId, amount: order.amount, currency: order.currency };
  }
}
