import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { LIMIT_KEYS } from '@syniastrolms/domain';
import { tenantBillingService as service } from './tenantBilling';
import { plans, subscriptions } from './fixtures/subscriptions';

/* The demo build's academy billing page: invented, but it follows the same rules as the API (D7–D10). */

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('the demo academy’s billing', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('shows the academy’s plan, usage against every limit, features, invoices and the plans on sale', async () => {
    const view = await settle(service.summary());
    expect(view.academy.name).toBe('ZuviloAI Academy');
    expect(view.subscription?.customer.name).toBe('ZuviloAI Academy');
    expect(view.usage.map((u) => u.limit)).toEqual([...LIMIT_KEYS]);
    expect(
      view.features
        .filter((f) => f.included)
        .map((f) => f.key)
        .sort(),
    ).toEqual([...view.plan!.features].sort());
    expect(view.plans.every((p) => p.status === 'active')).toBe(true);
    expect(view.invoices.every((i) => i.customerName === 'ZuviloAI Academy')).toBe(true);
    expect(view.checkoutAvailable).toBe(false);
  });

  it('previews an upgrade without writing anything, and needs the billing address to price it', async () => {
    const view = await settle(service.summary());
    const dearer = plans.find((p) => p.status === 'active' && p.cycles.includes('monthly') && p.monthlyPrice > view.subscription!.amount)!;
    const unpriced = await settle(service.previewChange({ planId: dearer.id, cycle: 'monthly' }));
    expect(unpriced).toMatchObject({ kind: 'upgrade', when: 'on_payment', needsBillingAddress: true, payable: null, to: { planId: dearer.id } });
    expect(unpriced.charge).toBeGreaterThan(0);
    // An upgrade cannot be asked for until the address is set — the same refusal the API gives.
    const refused = expect(service.requestChange({ planId: dearer.id, cycle: 'monthly' })).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await refused;

    await settle(
      service.saveBillingDetails({
        legalName: 'ZuviloAI Academy',
        email: 'billing@demo.in',
        addressLine1: '1 Main Road',
        city: 'Pune',
        postalCode: '411001',
        country: 'IN',
      }),
    );
    const priced = await settle(service.previewChange({ planId: dearer.id, cycle: 'monthly' }));
    expect(priced.needsBillingAddress).toBe(false);
    expect(priced.payable!.gross).toBe(priced.payable!.net + priced.payable!.tax);
    expect(priced.payable!.net).toBe(priced.charge);
    expect((await settle(service.summary())).openChange).toBeNull();
  });

  it('previews a downgrade for the period end, with nothing charged and the limits it would exceed', async () => {
    const view = await settle(service.summary());
    const cheaper = plans.find((p) => p.status === 'active' && p.cycles.includes('monthly') && p.monthlyPrice < view.subscription!.amount)!;
    const preview = await settle(service.previewChange({ planId: cheaper.id, cycle: 'monthly' }));
    expect(preview).toMatchObject({ kind: 'downgrade', when: 'period_end', appliesAt: view.subscription!.renewsAt, charge: 0, payable: null });
    for (const c of preview.conflicts) expect(c.usage).toBeGreaterThan(c.newLimit);
  });

  it('quotes an upgrade and waits for payment; one change at a time; withdrawn on request', async () => {
    const view = await settle(service.summary());
    const dearer = plans.find((p) => p.status === 'active' && p.cycles.includes('monthly') && p.monthlyPrice > view.subscription!.amount)!;
    const quote = await settle(service.requestChange({ planId: dearer.id, cycle: 'monthly' }));
    expect(quote.change).toMatchObject({ direction: 'upgrade', status: 'pending_payment', toPlanId: dearer.id });
    expect(quote.change.charge).toBeGreaterThan(0);
    expect(quote.payable!.gross).toBe(quote.payable!.net + quote.payable!.tax);
    // Nothing moved: the plan changes only once a payment is confirmed.
    expect((await settle(service.summary())).subscription!.planId).toBe(view.subscription!.planId);

    const second = expect(service.requestChange({ planId: dearer.id, cycle: 'annual' })).rejects.toMatchObject({ reason: 'INVALID_SUBSCRIPTION_STATE' });
    await vi.runAllTimersAsync();
    await second;

    await settle(service.withdrawChange(quote.change.id));
    expect((await settle(service.summary())).openChange).toBeNull();
  });

  it('schedules a downgrade for the end of the period, with nothing charged', async () => {
    const view = await settle(service.summary());
    const cheaper = plans.find((p) => p.status === 'active' && p.cycles.includes('monthly') && p.monthlyPrice < view.subscription!.amount)!;
    const scheduled = await settle(service.requestChange({ planId: cheaper.id, cycle: 'monthly' }));
    expect(scheduled.change).toMatchObject({ direction: 'downgrade', status: 'scheduled', charge: 0, effectiveAt: view.subscription!.renewsAt });
    expect(scheduled.payable).toBeUndefined();
    await settle(service.withdrawChange(scheduled.change.id));
  });

  it('refuses a plan that is not on sale as the state it is', async () => {
    const archived = plans.find((p) => p.status === 'archived')!;
    const attempt = expect(service.requestChange({ planId: archived.id, cycle: 'monthly' })).rejects.toMatchObject({ reason: 'PLAN_UNAVAILABLE' });
    await vi.runAllTimersAsync();
    await attempt;
  });

  it('leaves a pause to the platform: the academy cannot resume it', async () => {
    const id = (await settle(service.summary())).subscription!.id;
    const record = subscriptions.find((s) => s.id === id)!;
    const was = record.status;
    record.status = 'paused';
    const attempt = expect(service.resume()).rejects.toMatchObject({ code: 'forbidden', message: expect.stringContaining('paused by the platform team') });
    await vi.runAllTimersAsync();
    await attempt;
    record.status = was;
  });

  it('cancels at the period end with a reason, and withdraws the cancellation on resume', async () => {
    const short = expect(service.cancel({ immediately: false, reason: 'no' })).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await short;

    await settle(service.cancel({ immediately: false, reason: 'The cohort has finished.' }));
    const canceling = await settle(service.summary());
    expect(canceling.subscription).toMatchObject({ status: 'canceling', cancelReason: 'The cohort has finished.', cancelAt: 'period-end' });

    await settle(service.resume());
    expect((await settle(service.summary())).subscription).toMatchObject({ status: 'active', cancelReason: undefined });
  });
});
