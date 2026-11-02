import type { CoursePurchase } from '@prisma/client';
import type { DbClient } from './db.js';
import { observe } from './observe.js';

/*
 * What happens inside a course purchase's settlement transaction, beyond opening the course: other modules register
 * here at boot (the affiliate program's CV module, MLM-003), and course sales never import them. A hook runs in the
 * same transaction as the payment and the enrolment, so a paid purchase and what it caused cannot disagree; a hook
 * that throws is reported and skipped, never allowed to roll back a payment the gateway has already taken.
 */

export type PurchasePaidHook = (tx: DbClient, purchase: CoursePurchase & { providerPaymentId: string }) => Promise<void>;

const paidHooks: PurchasePaidHook[] = [];

export function onCoursePurchasePaid(hook: PurchasePaidHook): void {
  if (!paidHooks.includes(hook)) paidHooks.push(hook);
}

export async function runCoursePurchasePaidHooks(tx: DbClient, purchase: CoursePurchase & { providerPaymentId: string }): Promise<void> {
  for (const hook of paidHooks) {
    try {
      await hook(tx, purchase);
    } catch (err) {
      observe('job.failed', { job: 'course-purchase-hook', purchaseId: purchase.id, error: err instanceof Error ? err.message : String(err) }, 'error');
    }
  }
}

/**
 * After the settlement has committed: for work that writes rows pointing at what the settlement created (the tenancy
 * extension checks foreign keys against committed rows, so such writes cannot happen inside the transaction).
 */
export type PurchaseSettledHook = (purchase: CoursePurchase & { providerPaymentId: string }) => Promise<void>;

const settledHooks: PurchaseSettledHook[] = [];

export function onCoursePurchaseSettled(hook: PurchaseSettledHook): void {
  if (!settledHooks.includes(hook)) settledHooks.push(hook);
}

export async function runCoursePurchaseSettledHooks(purchase: CoursePurchase & { providerPaymentId: string }): Promise<void> {
  for (const hook of settledHooks) {
    try {
      await hook(purchase);
    } catch (err) {
      observe('job.failed', { job: 'course-purchase-settled-hook', purchaseId: purchase.id, error: err instanceof Error ? err.message : String(err) }, 'error');
    }
  }
}

/** After a refund of the whole order has committed: what the sale caused elsewhere is undone (docs/16, D-PLAT-12). */
export type PurchaseRefundedHook = (purchase: CoursePurchase) => Promise<void>;

const refundedHooks: PurchaseRefundedHook[] = [];

export function onCoursePurchaseRefunded(hook: PurchaseRefundedHook): void {
  if (!refundedHooks.includes(hook)) refundedHooks.push(hook);
}

export async function runCoursePurchaseRefundedHooks(purchase: CoursePurchase): Promise<void> {
  for (const hook of refundedHooks) {
    try {
      await hook(purchase);
    } catch (err) {
      observe(
        'job.failed',
        { job: 'course-purchase-refunded-hook', purchaseId: purchase.id, error: err instanceof Error ? err.message : String(err) },
        'error',
      );
    }
  }
}

/** For tests. */
export function clearCoursePurchaseHooks(): void {
  paidHooks.length = 0;
  settledHooks.length = 0;
  refundedHooks.length = 0;
}

/** After the gateway reports a dispute the company lost: the sale's volume is taken back. Access is left to a person (docs/15 §6.8). */
export type PurchaseChargedBackHook = (purchase: CoursePurchase, provider: string) => Promise<void>;

const chargebackHooks: PurchaseChargedBackHook[] = [];

export function onCoursePurchaseChargedBack(hook: PurchaseChargedBackHook): void {
  if (!chargebackHooks.includes(hook)) chargebackHooks.push(hook);
}

export async function runCoursePurchaseChargedBackHooks(purchase: CoursePurchase, provider: string): Promise<void> {
  for (const hook of chargebackHooks) {
    try {
      await hook(purchase, provider);
    } catch (err) {
      observe('job.failed', { job: 'course-purchase-chargeback-hook', purchaseId: purchase.id, error: err instanceof Error ? err.message : String(err) });
    }
  }
}
