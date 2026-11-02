import { ApiError } from './errors.js';
import { activeProvider, providerFor, webhookVerifiers } from './paymentGateways.js';
import { setPaymentProvider, type PaymentProvider } from './paymentProvider.js';

/*
 * The gateway course sales go through: the platform's own (docs/16, D-PLAT-07). The Super Admin configures Razorpay
 * once (`lib/paymentGateways.ts`: credentials sealed under PAYMENT_CREDENTIALS_KEY, tested, activated), and every
 * learner's purchase is an order on that account. Outside production, with no gateway active and PAYMENT_SANDBOX=on,
 * the sandbox gateway stands in so checkout can be driven in a browser. A production process takes no new purchase
 * through a gateway in test mode (`activeProvider` refuses it): a test card would open a paid course.
 *
 * Anything already made — a confirmation, a webhook, a status check — goes through the gateway and environment
 * recorded on the purchase (`providerForPurchase`), whatever is active now.
 */

const notSetUp = () => new ApiError(409, 'Online payments are not available yet. Please try again later.', undefined, 'PAYMENTS_NOT_SET_UP');

/** The gateway a new purchase goes through, in its environment; refused when online payment is not set up. */
export async function saleProvider(): Promise<{ provider: PaymentProvider; environment: 'test' | 'live' }> {
  const provider = await activeProvider();
  if (!provider) throw notSetUp();
  return { provider, environment: provider.environment ?? 'test' };
}

/** The gateway an existing purchase was made through, with that environment's credentials. */
export const providerForPurchase = (purchase: { provider: string; environment: string }): Promise<PaymentProvider> =>
  providerFor(purchase.provider, purchase.environment);

/**
 * The adapter whose webhook secret signed this body — the gateway's test or live environment, whichever verifies —
 * or null when none does.
 */
export async function verifyCourseWebhook(provider: string, raw: Buffer, headers: Record<string, string | undefined>): Promise<PaymentProvider | null> {
  for (const adapter of await webhookVerifiers(provider)) {
    try {
      if (adapter.verifyWebhook(raw, headers[adapter.webhookSignatureHeader])) return adapter;
    } catch {
      // An adapter whose credentials cannot be opened verifies nothing.
    }
  }
  return null;
}

/** Tests stand a fake gateway in (`null` means no gateway at all; `undefined` goes back to the configuration). */
export const setCoursePaymentProvider = (provider: PaymentProvider | null | undefined) => setPaymentProvider(provider);
