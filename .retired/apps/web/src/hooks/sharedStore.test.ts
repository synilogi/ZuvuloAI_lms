import { describe, expect, it, vi } from 'vitest';
import { createSharedStore } from './sharedStore';

/* The academy's plan follows what billing does: a new summary means the plan may have changed. */

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('the academy’s plan follows billing', () => {
  it('is read again when billing reads a new summary, not for the first one', async () => {
    const billing = createSharedStore(vi.fn().mockResolvedValueOnce({ v: 1 }).mockResolvedValueOnce({ v: 2 }));
    const readPlan = vi.fn().mockResolvedValue({ status: 'trialing' });
    const plan = createSharedStore(readPlan);
    followBilling(billing, plan);

    await plan.load('u1');
    await billing.load('u1');
    await flush();
    expect(readPlan).toHaveBeenCalledTimes(1);

    // A trial started, a plan bought: the billing page reads the summary again.
    await billing.load('u1', true);
    await flush();
    expect(readPlan).toHaveBeenCalledTimes(2);
  });

  it('reads nothing for a plan nobody has asked for yet', async () => {
    const billing = createSharedStore(vi.fn().mockResolvedValueOnce({ v: 1 }).mockResolvedValueOnce({ v: 2 }));
    const readPlan = vi.fn().mockResolvedValue({});
    const plan = createSharedStore(readPlan);
    followBilling(billing, plan);
    await billing.load('u1');
    await billing.load('u1', true);
    await flush();
    expect(readPlan).not.toHaveBeenCalled();
  });

  it('never reads one account’s plan because of another’s billing', async () => {
    const billing = createSharedStore(vi.fn(() => Promise.resolve({ v: 1 })));
    const readPlan = vi.fn().mockResolvedValue({});
    const plan = createSharedStore(readPlan);
    followBilling(billing, plan);
    await plan.load('u2');
    await billing.load('u1');
    await billing.load('u1', true);
    await flush();
    expect(readPlan).toHaveBeenCalledTimes(1);
  });
});
