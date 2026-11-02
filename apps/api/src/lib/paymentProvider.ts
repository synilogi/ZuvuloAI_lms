import { ApiError } from './errors.js';

/** How a payment was made, as the provider reports it — never a card number. */
export interface MaskedMethod {
  kind: 'card' | 'upi' | 'netbanking' | 'mandate' | 'invoice';
  brand: string;
  last4?: string;
}

/*
 * The payment provider interface (subscriptions.md §13; SAAS-009, SAAS-017). The LMS never talks to a gateway
 * itself: business logic holds a `PaymentProvider`, obtained from the gateway factory (`lib/paymentGateways.ts`)
 * — the active gateway for a new payment, the recorded gateway for everything that already exists. Only an
 * adapter (`lib/razorpay.ts`, …) knows a gateway's URLs, credentials or payload shapes; a source test holds
 * that line. Credentials live encrypted in the database (`PaymentGatewayConfig`), never in source or env files.
 */

export type ProviderCycle = 'monthly' | 'annual';

/** What a recurring plan is, as the provider needs it described. Amounts in minor units. */
export interface ProviderPlanRef {
  name: string;
  amount: number;
  currency: string;
  cycle: ProviderCycle;
}

/** A payment request the academy completes in the provider's checkout: an order, in Razorpay's terms. */
export interface ProviderOrder {
  providerOrderId: string;
  amount: number;
  currency: string;
}

/** A payment as the provider reports it — the only account of a payment the LMS believes. */
export interface ProviderPayment {
  providerPaymentId: string;
  providerOrderId?: string;
  amount: number;
  currency: string;
  /**
   * `paid` once the money is captured; `authorized` when the bank approved it and it still has to be
   * captured; `pending` before that; `failed` when it was refused; `refunded` after a full refund.
   */
  status: 'pending' | 'authorized' | 'paid' | 'failed' | 'refunded';
  method?: MaskedMethod;
  failureCode?: string;
  failureMessage?: string;
}

export interface ProviderRefund {
  providerRefundId: string;
  status: 'pending' | 'succeeded' | 'failed';
}

/**
 * A webhook, in the LMS's terms rather than the provider's (§17). Only the ids and the status the event
 * reports — never the payer's contact or card details, which the provider's payload also carries.
 */
export type ProviderWebhookEvent =
  | { kind: 'payment'; eventType: string; providerPaymentId: string; providerOrderId?: string }
  | { kind: 'refund'; eventType: string; providerRefundId: string; providerPaymentId: string; status: ProviderRefund['status']; refundRef?: string }
  | { kind: 'other'; eventType: string };

/** A signed webhook whose body is not the provider's shape: rejected with 400, not processed. */
export class WebhookPayloadError extends ApiError {
  constructor(message: string) {
    super(400, message, undefined, 'VALIDATION_FAILED');
    this.name = 'WebhookPayloadError';
  }
}

/**
 * What the browser needs to open the chosen gateway's checkout. The backend chose the gateway; `provider` only
 * tells the browser which checkout to open. Nothing secret: a key id is publishable. A gateway whose checkout
 * is a hosted page gives `redirectUrl` instead of an embedded widget's key.
 */
export interface CheckoutParams {
  provider: string;
  keyId?: string;
  orderId: string;
  amount: number;
  currency: string;
  redirectUrl?: string;
}

/** The outcome of a credential check that moves no money. `detail` is safe to show: never a secret. */
export interface CredentialCheck {
  ok: boolean;
  detail: string;
}

export interface PaymentProvider {
  readonly name: string;
  /** `test` or `live`: whose credentials this adapter holds. Recorded on every order it creates. */
  readonly environment?: 'test' | 'live';
  createCustomer(input: { name: string; email: string; notes?: Record<string, string> }): Promise<{ providerCustomerId: string }>;
  createSubscription(input: {
    plan: ProviderPlanRef;
    totalCount: number;
    notes?: Record<string, string>;
  }): Promise<{ providerSubscriptionId: string; status: string }>;
  cancelSubscription(providerSubscriptionId: string, opts: { atPeriodEnd: boolean }): Promise<void>;
  pauseSubscription(providerSubscriptionId: string): Promise<void>;
  resumeSubscription(providerSubscriptionId: string): Promise<void>;
  changePlan(providerSubscriptionId: string, plan: ProviderPlanRef, opts: { atPeriodEnd: boolean }): Promise<void>;
  /** Creates what the academy pays through checkout, for an amount the server already fixed. */
  createPayment(input: { amount: number; currency: string; receipt: string; notes: Record<string, string> }): Promise<ProviderOrder>;
  /** Reads a payment from the provider — server to server, so its answer is the provider's, not a browser's. */
  fetchPayment(providerPaymentId: string): Promise<ProviderPayment>;
  /** Every payment attempted on an order — how a missed confirmation is found again (SAAS-012). */
  listOrderPayments(providerOrderId: string): Promise<ProviderPayment[]>;
  /** Captures an authorized payment for exactly `amount`. */
  capturePayment(providerPaymentId: string, amount: number, currency: string): Promise<ProviderPayment>;
  refundPayment(input: { providerPaymentId: string; amount: number; notes: Record<string, string> }): Promise<ProviderRefund>;
  /** Whether a webhook body carries the provider's signature, under the webhook secret. */
  verifyWebhook(rawBody: string | Buffer, signature: string | undefined): boolean;
  /** The event id and the event, from a webhook whose signature has already been verified. */
  parseWebhook(body: unknown, headers: Record<string, string | undefined>): { eventId: string; event: ProviderWebhookEvent };
  /** The header the provider signs a webhook in. */
  readonly webhookSignatureHeader: string;
  /** The header carrying the provider's event id, where it sends one — logged when a signature fails. */
  readonly webhookEventIdHeader?: string;
  /** Whether a checkout's completion carries the provider's signature, under the key secret. */
  verifyCheckout(input: { orderId: string; paymentId: string; signature: string }): boolean;
  checkoutParams(order: ProviderOrder): CheckoutParams;
  /** Checks the credentials without creating any charge, where the gateway offers such a call. */
  testCredentials?(): Promise<CredentialCheck>;
}

/**
 * The provider could not do what was asked: unreachable, refused, or answered in a way we do not accept.
 * The message is ours and says nothing of the provider's internals (§34); the details go to `observe`.
 */
export class ProviderError extends ApiError {
  constructor(
    message: string,
    readonly detail: { operation: string; status?: number; providerCode?: string; description?: string },
  ) {
    super(502, message, undefined, 'PAYMENT_FAILED');
    this.name = 'ProviderError';
  }
}

/** Online payment is not set up on this deployment. */
export class PaymentUnavailableError extends ApiError {
  constructor() {
    super(409, 'Online payment is not available yet. The platform team records payments by hand until it is.', undefined, 'PAYMENT_REQUIRED');
    this.name = 'PaymentUnavailableError';
  }
}

/* ─── Test seam ──────────────────────────────────────────────────────── */

/** Providers installed by a test in place of the configured gateways: by name, with the active one named. */
export interface ProviderOverride {
  providers: Map<string, PaymentProvider>;
  active: string | null;
}

let override: ProviderOverride | undefined;

/** The providers a test installed, if any. Read by the gateway factory; production never sets it. */
export const providerOverride = (): ProviderOverride | undefined => override;

/**
 * Tests only. `setPaymentProvider(p)` makes `p` the active gateway (and resolvable by its name); `null` means no
 * gateway at all; `undefined` goes back to the database configuration.
 */
export function setPaymentProvider(provider: PaymentProvider | null | undefined) {
  override = provider === undefined ? undefined : { providers: new Map(provider ? [[provider.name, provider]] : []), active: provider?.name ?? null };
}

/** Tests only: several providers at once, one of them (or none) active — for switching the active gateway. */
export function setPaymentProviders(providers: PaymentProvider[], active: string | null) {
  override = { providers: new Map(providers.map((p) => [p.name, p])), active };
}
