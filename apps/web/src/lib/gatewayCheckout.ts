import type { CheckoutCompletion, CheckoutStart } from '@syniastrolms/domain';
import { openRazorpayCheckout } from './razorpayCheckout';

/*
 * Opening a checkout the way the server said to (SAAS-017). The server chooses the gateway for every
 * payment — the browser only follows `checkout.provider`: a gateway whose checkout opens in the page
 * (Razorpay) opens there, one with a hosted payment page sends the payer to it, and anything else is
 * reported plainly rather than guessed at.
 */

export const CHECKOUT_UNAVAILABLE = 'This payment gateway’s checkout is not available in the browser yet. Nothing was charged.';

export type CheckoutPlan = { kind: 'razorpay'; keyId: string } | { kind: 'redirect'; url: string } | { kind: 'unavailable'; message: string };

/** Only a web address the browser can safely be sent to: https, or http on this machine for development. */
function safeRedirect(url: string): string | null {
  try {
    const parsed = new URL(url);
    if (parsed.protocol === 'https:') return parsed.toString();
    if (parsed.protocol === 'http:' && (parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1')) return parsed.toString();
  } catch {
    /* not a URL */
  }
  return null;
}

/** What to do with the checkout the server opened. Pure — the decision, with nothing opened yet. */
export function planCheckout(checkout: CheckoutStart['checkout']): CheckoutPlan {
  if (checkout.provider === 'razorpay' && checkout.keyId) return { kind: 'razorpay', keyId: checkout.keyId };
  const url = checkout.redirectUrl ? safeRedirect(checkout.redirectUrl) : null;
  if (url) return { kind: 'redirect', url };
  return { kind: 'unavailable', message: CHECKOUT_UNAVAILABLE };
}

/**
 * Runs the checkout the server opened. Resolves with the completion to hand back to the server, `null` when
 * the payer closed the window, or `'redirected'` when the payer has been sent to the gateway's own page —
 * the payment is then confirmed by the gateway's webhook, not by this page.
 */
export async function openGatewayCheckout(
  start: CheckoutStart,
  details: { academy: string; email?: string },
  navigate: (url: string) => void = (url) => window.location.assign(url),
): Promise<CheckoutCompletion | null | 'redirected'> {
  const plan = planCheckout(start.checkout);
  if (plan.kind === 'razorpay') return openRazorpayCheckout(start, plan.keyId, details);
  if (plan.kind === 'redirect') {
    navigate(plan.url);
    return 'redirected';
  }
  throw new Error(plan.message);
}
