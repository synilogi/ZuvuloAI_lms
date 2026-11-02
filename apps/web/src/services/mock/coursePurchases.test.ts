import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { learningService as service } from './learning';
import { sandboxService } from './sandbox';
import { DEMO_NOW } from './fixtures/learner';
import { enrollments } from './fixtures/people';

vi.hoisted(() => {
  vi.useFakeTimers({ now: new Date('2026-09-15T18:52:00+05:30') });
});

/* The demo's paid courses: bought on its test checkout, and open only once the purchase is next read. */

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}
/** The refusal's reason, with the handler attached before the timers run so nothing goes unhandled. */
function reasonOf(promise: Promise<unknown>) {
  const outcome = promise.then(
    () => 'resolved',
    (err: { reason?: string; code?: string }) => err.reason ?? err.code,
  );
  return settle(outcome);
}

describe('buying a course in the demo build', () => {
  beforeAll(() => {
    vi.stubGlobal('window', Object.assign(globalThis, { location: { origin: 'http://demo.test', search: '' } }));
    vi.useFakeTimers({ now: new Date(DEMO_NOW) });
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('refuses to enrol in a paid course for free', async () => {
    expect(await reasonOf(service.enroll('dasha'))).toBe('COURSE_PURCHASE_REQUIRED');
  });

  it('refuses a purchase of a free course, or one the learner already has', async () => {
    expect(await reasonOf(service.startPurchase('nakshatra-depth'))).toBe('CONFLICT');
    expect(await reasonOf(service.startPurchase('foundations-vedic'))).toBe('ALREADY_ENROLLED');
  });

  it('opens one order at the course’s own price, and hands the same one back on a retry', async () => {
    const first = await settle(service.startPurchase('dasha'));
    expect(first.purchase).toMatchObject({ courseId: 'dasha', status: 'created', amount: first.purchase.listPrice * 100, enrolled: false });
    expect(first.checkout).toMatchObject({ provider: 'sandbox', redirectUrl: `http://demo.test/sandbox-checkout/${first.checkout.orderId}` });
    const again = await settle(service.startPurchase('dasha'));
    expect(again.purchase.id).toBe(first.purchase.id);
  });

  it('keeps the course closed after a declined payment, and opens it once a payment goes through', async () => {
    const { purchase, checkout } = await settle(service.startPurchase('dasha'));
    await settle(sandboxService.pay(checkout.orderId, 'failure'));
    const declined = await settle(service.getPurchase(purchase.id));
    expect(declined).toMatchObject({ status: 'failed', enrolled: false, failureMessage: 'The test card was declined.' });
    // Failed is not final: buying again hands back the same order.
    expect((await settle(service.startPurchase('dasha'))).purchase.id).toBe(purchase.id);
    expect(enrollments.some((e) => e.courseId === 'dasha' && e.studentId === 'u-ananya')).toBe(false);

    await settle(sandboxService.pay(checkout.orderId, 'success'));
    const paid = await settle(service.getPurchase(purchase.id));
    expect(paid).toMatchObject({ status: 'paid', enrolled: true });
    expect(enrollments.find((e) => e.courseId === 'dasha' && e.studentId === 'u-ananya')?.source).toBe('purchase');
    expect((await settle(service.listPurchases()))[0]).toMatchObject({ id: purchase.id, status: 'paid' });
    expect(await reasonOf(service.startPurchase('dasha'))).toBe('ALREADY_ENROLLED');
  });
});
