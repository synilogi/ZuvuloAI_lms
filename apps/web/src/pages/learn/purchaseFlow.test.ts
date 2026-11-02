import { describe, expect, it } from 'vitest';
import type { CoursePurchase } from '@syniastrolms/domain';
import { ServiceError } from '@/services/contracts';
import { confirmationPhase, courseReturnPath, isBusy, readCheckoutReturn, recallCheckout, refusalPhase, rememberCheckout, statusPhase } from './purchaseFlow';

/* Buying a course: the page believes only the API, and every refusal has words the learner can act on. */

const purchase = (over: Partial<CoursePurchase> = {}): CoursePurchase => ({
  id: 'p1',
  orderNumber: 'ORD-2026-000001',
  courseId: 'c1',
  courseTitle: 'Class 10 Science',
  status: 'created',
  amount: 149900,
  currency: 'INR',
  listPrice: 1499,
  enrolled: false,
  createdAt: '2026-10-23T10:00:00.000Z',
  ...over,
});

const refused = (reason: string, code: ServiceError['code'] = 'conflict') => new ServiceError(`Server says ${reason}`, code, reason, undefined, 409);

describe('what a refused purchase means', () => {
  it('shows the LMS’s own reason when it takes no payments, or the course is not on sale', () => {
    expect(refusalPhase(refused('PAYMENTS_NOT_SET_UP'))).toEqual({
      kind: 'blocked',
      title: 'Online payment isn’t available yet.',
      message: 'Server says PAYMENTS_NOT_SET_UP',
    });
    expect(refusalPhase(refused('COURSE_NOT_FOR_SALE'))).toMatchObject({ kind: 'blocked', title: 'This course isn’t open for enrolment yet.' });
    expect(refusalPhase(refused('CONFLICT'))).toMatchObject({ kind: 'blocked', title: 'You can’t buy this course here.' });
    expect(refusalPhase(new ServiceError('Course not found.', 'not-found'))).toMatchObject({ kind: 'blocked' });
  });

  it('reloads the course for a learner who already has it', () => {
    expect(refusalPhase(refused('ALREADY_ENROLLED'))).toEqual({ kind: 'owned' });
  });

  it('offers a retry for a payment that did not verify, or a network failure', () => {
    expect(refusalPhase(new ServiceError('Not verified.', 'conflict', 'PAYMENT_FAILED', undefined, 400))).toEqual({ kind: 'failed', message: 'Not verified.' });
    expect(refusalPhase(new ServiceError('Could not reach the server.', 'network'))).toEqual({ kind: 'failed', message: 'Could not reach the server.' });
  });
});

describe('what the server’s answer means', () => {
  it('opens the course only when the API says the learner is enrolled', () => {
    expect(
      confirmationPhase({ purchase: purchase({ status: 'paid', enrolled: true }), outcome: { status: 'paid', enrolled: true, message: 'Open.' } }),
    ).toEqual({
      kind: 'success',
      message: 'Open.',
    });
    // Paid at the gateway but not (yet) open: keep checking, never call it a success.
    expect(confirmationPhase({ purchase: purchase({ status: 'paid' }), outcome: { status: 'paid', enrolled: false, message: '' } }).kind).toBe('verifying');
    expect(confirmationPhase({ purchase: purchase(), outcome: { status: 'pending', enrolled: false, message: 'Confirming' } })).toEqual({
      kind: 'verifying',
      purchaseId: 'p1',
    });
    expect(confirmationPhase({ purchase: purchase(), outcome: { status: 'failed', enrolled: false, message: 'Declined.' } })).toEqual({
      kind: 'failed',
      message: 'Declined.',
    });
  });

  it('reads a purchase as open, failed, or still being confirmed', () => {
    expect(statusPhase(purchase({ status: 'paid', enrolled: true }))?.kind).toBe('success');
    expect(statusPhase(purchase())).toBeNull();
    expect(statusPhase(purchase({ status: 'paid' }))).toBeNull();
    expect(statusPhase(purchase({ status: 'expired' }))?.kind).toBe('failed');
    // The latest attempt failed: shown as failed (with a retry), never as pending.
    expect(statusPhase(purchase({ status: 'failed', failureMessage: 'Declined by the bank.' }))).toEqual({ kind: 'failed', message: 'Declined by the bank.' });
    // Back from a declined checkout: the order stays open, but this attempt failed.
    expect(statusPhase(purchase({ failureMessage: 'The test card was declined.' }), true)).toEqual({ kind: 'failed', message: 'The test card was declined.' });
    expect(statusPhase(purchase(), true)?.kind).toBe('failed');
  });

  it('holds the buy button while a purchase is opening, open or being confirmed', () => {
    expect(isBusy({ kind: 'starting' })).toBe(true);
    expect(isBusy({ kind: 'checkout' })).toBe(true);
    expect(isBusy({ kind: 'verifying', purchaseId: 'p1' })).toBe(true);
    expect(isBusy({ kind: 'failed', message: '' })).toBe(false);
    expect(isBusy({ kind: 'cancelled' })).toBe(false);
  });
});

describe('coming back from a hosted checkout', () => {
  const memory = () => {
    const map = new Map<string, string>();
    return { setItem: (k: string, v: string) => void map.set(k, v), getItem: (k: string) => map.get(k) ?? null, removeItem: (k: string) => void map.delete(k) };
  };

  it('remembers which purchase an order is for, once', () => {
    const storage = memory();
    rememberCheckout('order_1', { purchaseId: 'p1', courseId: 'c1' }, storage);
    expect(recallCheckout('order_1', storage)).toEqual({ purchaseId: 'p1', courseId: 'c1' });
    expect(recallCheckout('order_1', storage)).toBeNull();
    expect(recallCheckout('order_2', storage)).toBeNull();
  });

  it('survives storage that refuses or holds junk', () => {
    const broken = {
      setItem: () => {
        throw new Error('denied');
      },
      getItem: () => '{not json',
      removeItem: () => undefined,
    };
    expect(() => rememberCheckout('o', { purchaseId: 'p', courseId: 'c' }, broken)).not.toThrow();
    expect(recallCheckout('o', broken)).toBeNull();
  });

  it('sends the learner to the course page, which reads the purchase back', () => {
    const path = courseReturnPath({ purchaseId: 'p 1', courseId: 'c1' }, 'paid');
    expect(path).toBe('/learn/c1?purchase=p%201&checkout=paid');
    expect(readCheckoutReturn(path.split('?')[1])).toEqual({ purchaseId: 'p 1', outcome: 'paid' });
    expect(readCheckoutReturn('purchase=p1&checkout=bogus')).toBeNull();
    expect(readCheckoutReturn('checkout=paid')).toBeNull();
  });
});
