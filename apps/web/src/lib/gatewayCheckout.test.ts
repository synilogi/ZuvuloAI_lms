import { describe, expect, it, vi } from 'vitest';
import type { CheckoutStart } from '@syniastrolms/domain';
import { CHECKOUT_UNAVAILABLE, openGatewayCheckout, planCheckout } from './gatewayCheckout';

const checkout = (over: Partial<CheckoutStart['checkout']> = {}): CheckoutStart['checkout'] => ({
  provider: 'razorpay',
  keyId: 'rzp_test_abc',
  orderId: 'order_1',
  amount: 105000,
  currency: 'INR',
  ...over,
});

const start = (over: Partial<CheckoutStart['checkout']> = {}): CheckoutStart => ({
  checkout: checkout(over),
  invoice: { id: 'inv_1', number: 'INV-0001', total: 105000, currency: 'INR' },
});

describe('following the gateway the server chose', () => {
  it('opens Razorpay in the page when the server named Razorpay and gave its key id', () => {
    expect(planCheckout(checkout())).toEqual({ kind: 'razorpay', keyId: 'rzp_test_abc' });
  });

  it('never opens Razorpay without a key id', () => {
    expect(planCheckout(checkout({ keyId: undefined })).kind).toBe('unavailable');
  });

  it('sends the payer to a hosted page when the server gave one', () => {
    expect(planCheckout(checkout({ provider: 'vyapargateway', keyId: undefined, redirectUrl: 'https://pay.example.com/o/1' }))).toEqual({
      kind: 'redirect',
      url: 'https://pay.example.com/o/1',
    });
  });

  it('follows the provider, not the fields: a Razorpay key id on another gateway opens nothing in the page', () => {
    expect(planCheckout(checkout({ provider: 'vyapargateway' })).kind).toBe('unavailable');
  });

  it('refuses a redirect that is not a safe web address', () => {
    for (const redirectUrl of ['javascript:alert(1)', 'http://pay.example.com/o/1', 'not a url', 'data:text/html,hi']) {
      expect(planCheckout(checkout({ provider: 'other', keyId: undefined, redirectUrl })).kind, redirectUrl).toBe('unavailable');
    }
    expect(planCheckout(checkout({ provider: 'other', keyId: undefined, redirectUrl: 'http://localhost:4000/pay' })).kind).toBe('redirect');
  });

  it('says plainly when a gateway has no browser checkout', () => {
    expect(planCheckout(checkout({ provider: 'vyapargateway', keyId: undefined }))).toEqual({ kind: 'unavailable', message: CHECKOUT_UNAVAILABLE });
  });

  it('navigates for a hosted page and throws for an unavailable one', async () => {
    const navigate = vi.fn();
    await expect(
      openGatewayCheckout(start({ provider: 'hosted', keyId: undefined, redirectUrl: 'https://pay.example.com/o/1' }), { academy: 'A' }, navigate),
    ).resolves.toBe('redirected');
    expect(navigate).toHaveBeenCalledWith('https://pay.example.com/o/1');

    await expect(openGatewayCheckout(start({ provider: 'hosted', keyId: undefined }), { academy: 'A' }, navigate)).rejects.toThrow(CHECKOUT_UNAVAILABLE);
    expect(navigate).toHaveBeenCalledTimes(1);
  });
});
