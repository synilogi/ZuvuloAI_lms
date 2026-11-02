import { describe, expect, it } from 'vitest';
import { PURCHASES, isCourseReceipt, returnPath } from './SandboxCheckoutPage';

/* The sandbox's test checkout sends each payer back to the page that asks the API about their payment. */

describe('where the sandbox checkout returns to', () => {
  it('returns a course order opened in this tab to its course page, which reads the purchase back', () => {
    const recall = () => ({ purchaseId: 'p1', courseId: 'c1' });
    expect(returnPath('order_1', 'cp_abc', 'paid', recall)).toBe('/learn/c1?purchase=p1&checkout=paid');
    expect(returnPath('order_1', 'cp_abc', 'cancelled', recall)).toBe('/learn/c1?purchase=p1&checkout=cancelled');
  });

  it('sends any other order to the learner’s purchases', () => {
    expect(returnPath('order_1', 'cp_abc', 'failed', () => null)).toBe(PURCHASES);
    expect(returnPath('order_1', 'INV-0001', 'failed', () => null)).toBe(PURCHASES);
    expect(isCourseReceipt('mock-purchase-3')).toBe(true);
    expect(isCourseReceipt(undefined)).toBe(false);
  });
});
