import type { CheckoutCompletion, CheckoutStart } from '@syniastrolms/domain';

/*
 * Razorpay's hosted checkout, opened in the browser (SAAS-009). It takes only what the server returned
 * when it opened the order — the publishable key id, the order and its amount — so the browser never
 * names a price. What it hands back (order, payment, signature) is passed to the server unchanged; the
 * server verifies the signature and reads the payment from Razorpay before anything is recorded. No card
 * detail ever passes through this code: Razorpay's own frame collects it. It is opened only through
 * `gatewayCheckout.ts`, which follows the gateway the server chose.
 */

const SCRIPT = 'https://checkout.razorpay.com/v1/checkout.js';

interface RazorpayResponse {
  razorpay_payment_id: string;
  razorpay_order_id: string;
  razorpay_signature: string;
}

interface RazorpayInstance {
  open(): void;
}

type RazorpayConstructor = new (options: Record<string, unknown>) => RazorpayInstance;

let loading: Promise<RazorpayConstructor> | null = null;

/** Loads Razorpay's checkout script once. */
function loadRazorpay(): Promise<RazorpayConstructor> {
  const existing = (window as unknown as { Razorpay?: RazorpayConstructor }).Razorpay;
  if (existing) return Promise.resolve(existing);
  loading ??= new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = SCRIPT;
    script.async = true;
    script.onload = () => {
      const ctor = (window as unknown as { Razorpay?: RazorpayConstructor }).Razorpay;
      if (ctor) resolve(ctor);
      else reject(new Error('The payment window could not be opened.'));
    };
    script.onerror = () => {
      loading = null;
      reject(new Error('The payment window could not be loaded. Check the connection and try again.'));
    };
    document.head.appendChild(script);
  });
  return loading;
}

/** What Razorpay's checkout is opened with: the server's order, and what the payer sees. Never a secret. */
export interface RazorpayOrderOptions {
  keyId: string;
  orderId: string;
  /** Paise, as the server set the order. */
  amount: number;
  currency: string;
  name: string;
  description: string;
  prefill: { name?: string; email?: string };
  notes?: Record<string, string>;
}

/**
 * Opens Razorpay's checkout for an order the server made, and resolves with what Razorpay hands back, or `null` when
 * the payer closes it. A failed attempt inside the window is Razorpay's to show; the payer can try again there.
 */
export async function openRazorpayOrder(options: RazorpayOrderOptions): Promise<CheckoutCompletion | null> {
  const Razorpay = await loadRazorpay();
  return new Promise((resolve) => {
    const checkout = new Razorpay({
      key: options.keyId,
      order_id: options.orderId,
      amount: options.amount,
      currency: options.currency,
      name: options.name,
      description: options.description,
      prefill: Object.fromEntries(Object.entries(options.prefill).filter(([, v]) => Boolean(v))),
      ...(options.notes ? { notes: options.notes } : {}),
      handler: (response: RazorpayResponse) =>
        resolve({ orderId: response.razorpay_order_id, paymentId: response.razorpay_payment_id, signature: response.razorpay_signature }),
      modal: { ondismiss: () => resolve(null) },
    });
    checkout.open();
  });
}

/** Opens the checkout for a plan invoice's order (`start`). */
export function openRazorpayCheckout(start: CheckoutStart, keyId: string, details: { academy: string; email?: string }): Promise<CheckoutCompletion | null> {
  return openRazorpayOrder({
    keyId,
    orderId: start.checkout.orderId,
    amount: start.checkout.amount,
    currency: start.checkout.currency,
    name: 'ZuviloAI',
    description: `Invoice ${start.invoice.number}`,
    prefill: { name: details.academy, email: details.email },
    notes: { invoiceNumber: start.invoice.number },
  });
}
