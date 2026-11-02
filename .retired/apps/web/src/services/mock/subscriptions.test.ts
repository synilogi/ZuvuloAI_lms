import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { invoiceTotal, isBilling, monthlyValue, BYTES_PER_GB } from '@syniastrolms/domain';
import { subscriptionService as service } from './subscriptions';
import { invoices, plans, subscriptions } from './fixtures/subscriptions';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

/** The first subscription in a given state — the tests act on real fixture records, not stand-ins. */
const firstWith = (...statuses: string[]) => subscriptions.find((s) => statuses.includes(s.status))!;

describe('subscription mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  /* ─── Overview ─── */

  it('computes the overview from the same records the lists serve', async () => {
    const overview = await settle(service.overview());
    const billing = subscriptions.filter((s) => isBilling(s.status));
    expect(overview.kpis.active.value).toBe(subscriptions.filter((s) => s.status === 'active').length);
    expect(overview.kpis.trial.value).toBe(subscriptions.filter((s) => s.status === 'trial').length);
    expect(overview.kpis.mrr.value).toBe(billing.reduce((sum, s) => sum + monthlyValue(s), 0));
    expect(overview.kpis.arr.value).toBe(overview.kpis.mrr.value * 12);
    expect(overview.revenue).toHaveLength(12);
    expect(overview.growth).toHaveLength(12);
  });

  it('puts the soonest trial and grace deadlines on the watch list', async () => {
    const overview = await settle(service.overview());
    expect(overview.attention.length).toBeGreaterThan(0);
    expect(overview.attention.every((r) => r.subscription.status === 'trial' || r.subscription.status === 'past-due')).toBe(true);
    const dates = overview.attention.map((r) => r.subscription.trialEndsAt ?? r.subscription.graceEndsAt ?? '');
    expect([...dates].sort()).toEqual(dates);
  });

  /* ─── Plans ─── */

  it('filters plans by status and searches name, code and description', async () => {
    const all = await settle(service.listPlans());
    expect(all.rows.length).toBe(plans.length);
    expect(all.counts.all).toBe(plans.length);

    const drafts = await settle(service.listPlans({ status: 'draft' }));
    expect(drafts.rows.every((r) => r.plan.status === 'draft')).toBe(true);
    // Counts describe everything that matched the search, so the tabs keep their numbers.
    expect(drafts.counts.all).toBe(plans.length);

    const byCode = await settle(service.listPlans({ search: 'pro-2025' }));
    expect(byCode.rows.map((r) => r.plan.id)).toEqual(['legacy-professional']);
  });

  it('sorts plans by price and by subscriber count', async () => {
    const byPrice = await settle(service.listPlans({ sort: 'price' }));
    const prices = byPrice.rows.map((r) => r.plan.monthlyPrice);
    expect([...prices].sort((a, b) => a - b)).toEqual(prices);

    const bySubscribers = await settle(service.listPlans({ sort: 'subscribers' }));
    const counts = bySubscribers.rows.map((r) => r.activeSubscribers);
    expect([...counts].sort((a, b) => b - a)).toEqual(counts);
  });

  it('counts a plan’s subscribers and what they are worth a month', async () => {
    const starter = (await settle(service.listPlans())).rows.find((r) => r.plan.id === 'starter')!;
    const on = subscriptions.filter((s) => s.planId === 'starter');
    expect(starter.subscribers).toBe(on.length);
    expect(starter.mrr).toBe(on.reduce((sum, s) => sum + monthlyValue(s), 0));
  });

  it('refuses a plan whose code is already taken', async () => {
    const attempt = expect(
      service.createPlan({
        name: 'Another Growth',
        description: 'A second plan using a code that is already in use.',
        code: 'GROWTH',
        monthlyPrice: 100000,
        annualPrice: 1000000,
        currency: 'INR',
        cycles: ['monthly'],
        trialEnabled: false,
        trialDays: 0,
        limits: {
          'learners.max': 10,
          'instructors.max': 1,
          'courses.max': 1,
          'storage.bytes': 1 * BYTES_PER_GB,
          'live_classes.max': 1,
          'admin_accounts.max': 1,
        },
        features: ['courses.manage'],
        status: 'draft',
        order: 9,
      }),
    ).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
  });

  it('creates, edits and archives a plan', async () => {
    const created = await settle(
      service.createPlan({
        name: 'Community',
        description: 'An entry tier for study circles running one course.',
        code: 'COMMUNITY',
        monthlyPrice: 9900,
        annualPrice: 0,
        currency: 'INR',
        cycles: ['monthly'],
        trialEnabled: false,
        trialDays: 0,
        limits: {
          'learners.max': 25,
          'instructors.max': 1,
          'courses.max': 1,
          'storage.bytes': 5 * BYTES_PER_GB,
          'live_classes.max': 1,
          'admin_accounts.max': 1,
        },
        features: ['courses.manage'],
        status: 'active',
        order: 9,
      }),
    );
    expect(created.code).toBe('COMMUNITY');
    expect(created.id).toBe('community');

    const edited = await settle(service.updatePlan(created.id, { ...created, name: 'Community circle', monthlyPrice: 19900 }));
    expect(edited.name).toBe('Community circle');
    expect(edited.monthlyPrice).toBe(19900);
    expect(edited.createdAt).toBe(created.createdAt);

    const archived = await settle(service.archivePlan(created.id));
    expect(archived.status).toBe('archived');
    const restored = await settle(service.restorePlan(created.id));
    expect(restored.status).toBe('active');

    const again = expect(service.restorePlan(created.id)).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await again;
  });

  it('duplicates a plan as a draft with a free code', async () => {
    const copy = await settle(service.duplicatePlan('starter'));
    expect(copy.status).toBe('draft');
    expect(copy.code).not.toBe('STARTER');
    expect(copy.name).toBe('Starter (copy)');
    expect(copy.features).toEqual(plans.find((p) => p.id === 'starter')!.features);
    // A copy starts with nobody on it.
    const detail = await settle(service.getPlan(copy.id));
    expect(detail.subscribers).toBe(0);
  });

  it('reports a plan that is gone as not found', async () => {
    const attempt = expect(service.getPlan('no-such-plan')).rejects.toMatchObject({ code: 'not-found' });
    await vi.runAllTimersAsync();
    await attempt;
  });

  /* ─── Subscribers ─── */

  it('counts every status before applying the status filter', async () => {
    const all = await settle(service.listSubscribers({ pageSize: 100 }));
    const trials = await settle(service.listSubscribers({ status: 'trial', pageSize: 100 }));
    expect(trials.rows.every((r) => r.subscription.status === 'trial')).toBe(true);
    expect(trials.total).toBe(all.counts.trial);
    expect(trials.counts).toEqual(all.counts);
  });

  it('searches academy name, billing email and subscription ID', async () => {
    const target = subscriptions[0];
    for (const term of [target.customer.name.slice(0, 8), target.customer.email, target.id]) {
      const found = await settle(service.listSubscribers({ search: term, pageSize: 100 }));
      expect(found.rows.some((r) => r.subscription.id === target.id)).toBe(true);
    }
  });

  it('filters by plan, cycle and renewal window', async () => {
    const annual = await settle(service.listSubscribers({ cycle: 'annual', pageSize: 100 }));
    expect(annual.rows.every((r) => r.subscription.cycle === 'annual')).toBe(true);

    const onGrowth = await settle(service.listSubscribers({ planId: 'growth', pageSize: 100 }));
    expect(onGrowth.rows.every((r) => r.subscription.planId === 'growth')).toBe(true);
    // Each row carries the facts of the plan it is on.
    const growth = plans.find((p) => p.id === 'growth')!;
    expect(onGrowth.rows.every((r) => r.planName === growth.name)).toBe(true);

    const window = await settle(service.listSubscribers({ from: '2026-09-01', to: '2026-09-30', pageSize: 100 }));
    expect(window.rows.every((r) => r.subscription.renewsAt.slice(0, 10) >= '2026-09-01' && r.subscription.renewsAt.slice(0, 10) <= '2026-09-30')).toBe(true);
  });

  it('pages without losing or repeating a row', async () => {
    const first = await settle(service.listSubscribers({ page: 1, pageSize: 5 }));
    const second = await settle(service.listSubscribers({ page: 2, pageSize: 5 }));
    expect(first.rows).toHaveLength(5);
    expect(first.total).toBe(subscriptions.length);
    expect(first.rows.map((r) => r.subscription.id)).not.toEqual(second.rows.map((r) => r.subscription.id));
  });

  it('sorts by renewal date by default', async () => {
    const rows = (await settle(service.listSubscribers({ pageSize: 100 }))).rows.map((r) => r.subscription.renewsAt);
    expect([...rows].sort()).toEqual(rows);
  });

  /* ─── Subscription actions ─── */

  it('quotes an upgrade and waits for its payment, schedules a downgrade, and refuses the same plan (D7–D10)', async () => {
    const target = firstWith('active');
    const before = await settle(service.getSubscription(target.id));
    const monthly = plans.filter((p) => p.status === 'active' && p.id !== before.plan.id && p.cycles.includes('monthly'));
    const dearer = monthly.find((p) => p.monthlyPrice > before.subscription.amount && target.cycle === 'monthly');
    const cheaper = monthly.find((p) => p.monthlyPrice < before.subscription.amount);

    if (dearer) {
      const quoted = await settle(service.changePlan(target.id, { planId: dearer.id, cycle: 'monthly' }));
      // Nothing moves until the payment is confirmed.
      expect(quoted.subscription.planId).toBe(before.subscription.planId);
      expect(quoted.subscription.amount).toBe(before.subscription.amount);
      expect(quoted.events[0]).toMatchObject({ kind: 'plan-changed' });
      expect(quoted.events[0].summary).toMatch(/quoted — .* due after a .* credit\. It applies once paid\.$/);
    }
    if (cheaper) {
      const scheduled = await settle(service.changePlan(target.id, { planId: cheaper.id, cycle: 'monthly' }));
      expect(scheduled.subscription.planId).toBe(before.subscription.planId);
      expect(scheduled.events[0].summary).toMatch(/scheduled for the end of the period/);
    }
    expect(Boolean(dearer || cheaper)).toBe(true);

    const same = expect(service.changePlan(target.id, { planId: before.plan.id, cycle: before.subscription.cycle })).rejects.toMatchObject({
      code: 'conflict',
    });
    await vi.runAllTimersAsync();
    await same;
  });

  it('refuses a move on to an archived plan, and a cycle the plan is not sold on', async () => {
    const target = firstWith('active');
    const archived = expect(service.changePlan(target.id, { planId: 'legacy-professional', cycle: 'monthly' })).rejects.toMatchObject({
      code: 'conflict',
      reason: 'PLAN_UNAVAILABLE',
    });
    await vi.runAllTimersAsync();
    await archived;

    // Enterprise is sold annually only.
    const badCycle = expect(service.changePlan(target.id, { planId: 'enterprise', cycle: 'monthly' })).rejects.toMatchObject({
      code: 'conflict',
    });
    await vi.runAllTimersAsync();
    await badCycle;
  });

  it('pauses for 1–30 days, resumes with the renewal date moved by the time paused, and refuses more (D9)', async () => {
    const target = firstWith('active');
    const renewsAt = target.renewsAt;
    const paused = await settle(service.pause(target.id, 30));
    expect(paused.subscription.status).toBe('paused');
    expect(paused.subscription.resumesAt).toBeTruthy();
    expect(paused.subscription.renewsAt).toBe(renewsAt);
    expect(paused.events[0].kind).toBe('paused');

    const twice = expect(service.pause(target.id, 30)).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await twice;

    const resumed = await settle(service.resume(target.id));
    expect(resumed.subscription.status).toBe('active');
    expect(resumed.subscription.pausedAt).toBeUndefined();
    // Resumed a moment later on the demo clock: the renewal date moves by exactly that moment.
    const moved = new Date(resumed.subscription.renewsAt).getTime() - new Date(renewsAt).getTime();
    expect(moved).toBeGreaterThanOrEqual(0);
    expect(moved).toBeLessThan(60_000);

    const tooLong = expect(service.pause(target.id, 31)).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await tooLong;
  });

  it('cancels at the end of the period, then reactivates', async () => {
    const target = firstWith('active');
    const canceling = await settle(service.cancel(target.id, { reason: 'Cohort finished for the year.', effective: 'period-end' }));
    expect(canceling.subscription.status).toBe('canceling');
    expect(canceling.subscription.cancelReason).toBe('Cohort finished for the year.');
    expect(canceling.events[0].kind).toBe('cancellation-requested');

    const back = await settle(service.reactivate(target.id));
    expect(back.subscription.status).toBe('active');
    expect(back.subscription.cancelReason).toBeUndefined();
    // Withdrawing a pending cancellation keeps the period it was in.
    expect(back.subscription.renewsAt).toBe(canceling.subscription.renewsAt);
    expect(back.events[0].kind).toBe('reactivated');
  });

  it('cancels immediately and closes the subscription in one step', async () => {
    const target = subscriptions.filter((s) => s.status === 'active')[1];
    const closed = await settle(service.cancel(target.id, { reason: 'Moved to another platform.', effective: 'immediately' }));
    expect(closed.subscription.status).toBe('canceled');
    expect(closed.events.map((e) => e.kind).slice(0, 2)).toEqual(['cancellation-completed', 'cancellation-requested']);
  });

  it('insists on a reason worth reading', async () => {
    const target = firstWith('active');
    const attempt = expect(service.cancel(target.id, { reason: 'no', effective: 'period-end' })).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
  });

  it('refuses to reactivate a subscription that is not cancelled', async () => {
    const target = firstWith('active');
    const attempt = expect(service.reactivate(target.id)).rejects.toMatchObject({ code: 'conflict' });
    await vi.runAllTimersAsync();
    await attempt;
  });

  /* ─── Billing ─── */

  it('filters payments by status and totals what matched', async () => {
    const all = await settle(service.listPayments({ pageSize: 500 }));
    expect(all.total).toBe(invoices.length);
    expect(all.counts.all).toBe(invoices.length);

    const failed = await settle(service.listPayments({ status: 'failed', pageSize: 500 }));
    expect(failed.rows.every((i) => i.status === 'failed')).toBe(true);
    expect(failed.totals.collected).toBe(0);
    expect(failed.totals.outstanding).toBe(failed.rows.reduce((sum, i) => sum + invoiceTotal(i), 0));
  });

  it('searches invoice number, academy and subscription ID', async () => {
    const target = invoices[0];
    for (const term of [target.number, target.customerName.slice(0, 8), target.subscriptionId]) {
      const found = await settle(service.listPayments({ search: term, pageSize: 500 }));
      expect(found.rows.some((i) => i.id === target.id)).toBe(true);
    }
  });

  it('opens one invoice by id or by its printed number', async () => {
    const target = invoices[0];
    expect((await settle(service.getInvoice(target.id))).number).toBe(target.number);
    expect((await settle(service.getInvoice(target.number))).id).toBe(target.id);

    const missing = expect(service.getInvoice('INV-0000-0000')).rejects.toMatchObject({ code: 'not-found' });
    await vi.runAllTimersAsync();
    await missing;
  });
});

describe('the platform’s billing operations in the demo', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  /** Expects `promise` to be refused with `match`, running the demo's timers meanwhile. */
  async function refused(promise: Promise<unknown>, match: Record<string, unknown>) {
    const attempt = expect(promise).rejects.toMatchObject(match);
    await vi.runAllTimersAsync();
    await attempt;
  }

  it('publishes a draft, never takes a plan back to draft, and keeps a version for each change of terms', async () => {
    const draft = plans.find((p) => p.status === 'draft')!;
    const published = await settle(service.publishPlan(draft.id));
    expect(published.status).toBe('active');
    await refused(service.publishPlan(draft.id), { code: 'conflict' });
    await refused(service.updatePlan(draft.id, { ...published, status: 'draft' }), { code: 'conflict' });

    expect((await settle(service.getPlan(draft.id))).versions).toHaveLength(1);
    await settle(service.updatePlan(draft.id, { ...published, monthlyPrice: published.monthlyPrice + 10000 }));
    // A rename alone writes no new version.
    await settle(service.updatePlan(draft.id, { ...published, monthlyPrice: published.monthlyPrice + 10000, name: `${published.name} II` }));
    const versions = (await settle(service.getPlan(draft.id))).versions!;
    expect(versions.map((v) => v.version)).toEqual([1, 2]);
    expect(versions[1].monthlyPrice).toBe(published.monthlyPrice + 10000);
  });

  it('adds complimentary days to an active subscription only, and says so on its history', async () => {
    const target = subscriptions.find((s) => s.status === 'active')!;
    const renewsAt = new Date(target.renewsAt).getTime();
    const extended = await settle(service.extend(target.id, { days: 14, reason: 'Goodwill after the outage.' }));
    expect(new Date(extended.subscription.renewsAt).getTime() - renewsAt).toBe(14 * 86_400_000);
    expect(extended.events[0]).toMatchObject({ kind: 'extended', summary: 'Complimentary days added (14 days) — Goodwill after the outage.' });

    await refused(service.extend(target.id, { days: 91, reason: 'Too generous.' }), { code: 'conflict' });
    await refused(service.extend(target.id, { days: 5, reason: 'no' }), { code: 'conflict' });
    const paused = subscriptions.find((s) => s.status === 'paused')!;
    await refused(service.extend(paused.id, { days: 5, reason: 'Not while paused.' }), { reason: 'INVALID_SUBSCRIPTION_STATE' });
  });

  it('keeps an open plan change on the subscription until it applies', async () => {
    const target = subscriptions.find((s) => s.status === 'active' && s.cycle === 'monthly' && s.planId === 'starter')!;
    const detail = await settle(service.changePlan(target.id, { planId: 'growth', cycle: 'monthly' }));
    expect(detail.openChanges).toEqual([expect.objectContaining({ status: 'pending_payment', toPlanId: 'growth', toCycle: 'monthly' })]);
    expect(detail.openChanges![0].charge).toBeGreaterThan(0);
  });

  it('lists a subscription’s payments, and refunds part then the rest — never more', async () => {
    const sub = subscriptions.find((s) => invoices.some((i) => i.subscriptionId === s.id && i.status === 'paid'))!;
    const payment = (await settle(service.getSubscription(sub.id))).payments!.find((p) => p.status === 'paid')!;
    expect(payment.refundable).toBe(payment.amount);

    await refused(service.refundPayment(payment.id, { amount: payment.amount + 1, reason: 'Too much.' }), { code: 'conflict' });
    const part = await settle(service.refundPayment(payment.id, { amount: 1000, reason: 'Partial goodwill.' }));
    expect(part).toMatchObject({ amount: 1000, status: 'succeeded' });
    const after = (await settle(service.getSubscription(sub.id))).payments!.find((p) => p.id === payment.id)!;
    expect(after).toMatchObject({ status: 'partially_refunded', refunded: 1000, refundable: payment.amount - 1000 });

    const rest = await settle(service.refundPayment(payment.id, { reason: 'Refunded the remainder.' }));
    expect(rest.amount).toBe(payment.amount - 1000);
    const done = await settle(service.getSubscription(sub.id));
    expect(done.payments!.find((p) => p.id === payment.id)).toMatchObject({ status: 'refunded', refundable: 0 });
    // A refund never touches the subscription itself.
    expect(done.subscription.status).toBe(sub.status);
    await refused(service.refundPayment(payment.id, { reason: 'Once more.' }), { code: 'conflict' });
  });

  it('records an offline payment against an open invoice, which recovers an overdue subscription', async () => {
    const overdue = invoices.find((i) => i.status === 'failed' && subscriptions.find((s) => s.id === i.subscriptionId)?.status === 'past-due')!;
    await refused(service.recordInvoicePayment(overdue.id, { method: 'bank_transfer', reference: 'x' }), { code: 'conflict' });
    const outcome = await settle(
      service.recordInvoicePayment(overdue.id, { method: 'bank_transfer', reference: 'NEFT 2026-0091', note: 'Paid by the trust.' }),
    );
    expect(outcome).toMatchObject({ status: 'paid', settled: true, applied: true });
    expect((await settle(service.getInvoice(overdue.id))).status).toBe('paid');
    expect((await settle(service.getSubscription(overdue.subscriptionId))).subscription.status).toBe('active');
    await refused(service.recordInvoicePayment(overdue.id, { method: 'cash', reference: 'Receipt 12' }), { code: 'conflict' });
  });

  it('voids an open invoice with a reason, and nothing else', async () => {
    const open = invoices.find((i) => i.status === 'pending' || i.status === 'failed')!;
    const voided = await settle(service.voidInvoice(open.id, 'Raised in error.'));
    expect(voided).toMatchObject({ status: 'void', note: 'Void — Raised in error.' });
    await refused(service.voidInvoice(open.id, 'Again.'), { code: 'conflict' });
  });

  it('pages webhook receipts and filters them by status', async () => {
    const first = await settle(service.listWebhooks({ page: 1, pageSize: 10 }));
    expect(first.rows).toHaveLength(10);
    expect(first.total).toBeGreaterThan(10);
    const failed = await settle(service.listWebhooks({ status: 'failed' }));
    expect(failed.rows.length).toBeGreaterThan(0);
    expect(failed.rows.every((w) => w.status === 'failed' && w.attempts > 1)).toBe(true);
  });

  it('sets a tax rule in place of the one already there, and retires one', async () => {
    const before = await settle(service.listTaxRules());
    await refused(service.createTaxRule({ name: 'GST', country: 'India', components: [] }), { code: 'conflict' });
    const created = await settle(
      service.createTaxRule({
        name: 'GST',
        country: 'in',
        components: [
          { code: 'cgst', label: 'Central GST', rateBps: 900 },
          { code: 'sgst', label: 'State GST', rateBps: 900 },
        ],
      }),
    );
    expect(created).toMatchObject({ country: 'IN', components: [{ code: 'CGST' }, { code: 'SGST' }] });
    const active = await settle(service.listTaxRules());
    expect(active.filter((r) => r.country === 'IN' && !r.region)).toEqual([created]);
    expect((await settle(service.listTaxRules({ includeRetired: true }))).length).toBe(before.length + 1);

    expect((await settle(service.retireTaxRule(created.id))).retiredAt).toBeTruthy();
    await refused(service.retireTaxRule(created.id), { code: 'conflict' });
  });

  it('starts a subscription for an academy with none, and refuses one that has a live subscription', async () => {
    const academies = await settle(service.listAcademies());
    const fresh = academies.find((a) => !subscriptions.some((s) => s.customer.id === a.id))!;
    expect((await settle(service.getAcademyBilling(fresh.id))).subscription).toBeNull();

    await refused(service.startSubscription({ tenantId: fresh.id, planId: 'enterprise', cycle: 'monthly', start: 'active' }), {
      reason: 'PLAN_UNAVAILABLE',
    });
    const started = await settle(service.startSubscription({ tenantId: fresh.id, planId: 'growth', cycle: 'monthly', start: 'trial' }));
    expect(started.subscription).toMatchObject({ status: 'trial', planId: 'growth', customer: { id: fresh.id, name: fresh.name } });
    expect((await settle(service.getAcademyBilling(fresh.id))).subscription?.id).toBe(started.subscription.id);

    await refused(service.startSubscription({ tenantId: fresh.id, planId: 'growth', cycle: 'monthly', start: 'active' }), {
      reason: 'INVALID_SUBSCRIPTION_STATE',
    });
  });

  it('reads and saves an academy’s billing profile', async () => {
    const [academy] = await settle(service.listAcademies());
    const profile = {
      legalName: 'Trust of the Academy',
      email: 'accounts@academy.in',
      addressLine1: '4 Ring Road',
      city: 'Mysuru',
      postalCode: '570001',
      country: 'in',
    };
    expect((await settle(service.saveAcademyBillingProfile(academy.id, profile))).country).toBe('IN');
    expect((await settle(service.getAcademyBilling(academy.id))).profile).toMatchObject({ legalName: 'Trust of the Academy', country: 'IN' });
  });
});
