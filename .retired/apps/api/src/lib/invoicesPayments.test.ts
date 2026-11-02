import { BYTES_PER_GB, type PlanLimits } from '@syniastrolms/domain';
import { afterEach, beforeAll, describe, expect, it, vi } from 'vitest';

import { platformDb } from '../test/db.js';
import { unique } from '../test/helpers.js';
import { setBillingProfile, setTaxRule } from './billing.js';
import { setClock } from './clock.js';
import { ApiError } from './errors.js';
import { getInvoice, issueInvoice, listInvoices, voidInvoice } from './invoices.js';
import { listPayments, listPaymentMethods, recordPayment, refundPayment, savePaymentMethod, settleRefund, getPayment } from './payments.js';
import { requestPlanChange } from './planChanges.js';
import { createPlan, publishPlan, updatePlan } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { createSubscription, type LifecycleActor } from './subscriptions.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/* SAAS-008: invoices and payments as append-only financial history. Every academy here is billed in the
 * UAE at a 5% VAT rule of its own, so the figures are easy to check: ₹3,999 + ₹199.95 = ₹4,198.95. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('invoice and payment tests act as the platform', fn);
const provider: LifecycleActor = { type: 'provider', provider: 'testpay' };
const scheduler: LifecycleActor = { type: 'system', job: 'billing-tests' };
let superAdmin: LifecycleActor & { type: 'user' };
let STARTER: string;
let PRO: string;

const LIMITS: PlanLimits = {
  'learners.max': 100,
  'instructors.max': 5,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 5,
  'admin_accounts.max': 2,
};

const refusal = async (promise: Promise<unknown>) => {
  const err = await promise.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(err, 'expected a refusal').toBeInstanceOf(ApiError);
  return err as ApiError;
};

async function plan(monthly: number, annual: number) {
  return asPlatform(async () => {
    const p = await createPlan(
      { auth: superAdmin.auth },
      {
        name: monthly > 500000 ? 'Pro' : 'Starter',
        description: 'A plan for the invoice suite.',
        code: `P${unique().toUpperCase()}`.slice(0, 24),
        currency: 'INR',
        cycles: ['monthly', 'annual'],
        monthlyPrice: monthly,
        annualPrice: annual,
        trialEnabled: false,
        trialDays: 0,
        features: ['courses.manage'],
        limits: LIMITS,
      },
    );
    await publishPlan({ auth: superAdmin.auth }, p.id);
    return p.id;
  });
}

/** An academy billed in the UAE, with an active monthly subscription (Starter unless said) from 1 September. */
async function billedSubscriber(planId = STARTER) {
  const tenantId = (await platformDb.tenant.create({ data: { name: 'Invoiced Academy', slug: `inv-${unique()}` } })).id;
  await asPlatform(() =>
    setBillingProfile({ auth: superAdmin.auth }, tenantId, {
      legalName: 'Invoiced Academy LLC',
      email: 'billing@example.com',
      addressLine1: '1 Sheikh Zayed Road',
      city: 'Dubai',
      postalCode: '00000',
      country: 'AE',
    }),
  );
  setClock('2026-09-01T00:00:00Z');
  const sub = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId, cycle: 'monthly', start: 'active' }));
  return { tenantId, sub };
}

const renewalInvoice = (subscriptionId: string) => asPlatform(() => issueInvoice(scheduler, { kind: 'renewal', subscriptionId }));

const pay = (invoiceId: string, amount: number, extra: object = {}) =>
  asPlatform(() =>
    recordPayment(provider, {
      invoiceId,
      providerPaymentId: `pay_${unique()}`,
      amount,
      currency: 'INR',
      status: 'paid',
      method: { kind: 'card', brand: 'Visa', last4: '4242' },
      ...extra,
    }),
  );

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `invoices-${unique()}@example.com`, password: 'invoices-suite-password', name: 'Billing' });
  superAdmin = { type: 'user', auth: { sub: created.user.id, role: 'superadmin' } };
  await asPlatform(() =>
    setTaxRule({ auth: superAdmin.auth }, { name: 'VAT', country: 'AE', components: [{ code: 'VAT', label: 'Value added tax', rateBps: 500 }] }),
  );
  STARTER = await plan(399900, 3999000);
  PRO = await plan(899900, 8999000);
});

afterEach(() => setClock(null));

describe('issuing an invoice from the server’s figures', () => {
  it('bills the next period at the stored price, taxed, with the address it was sent to', async () => {
    const { tenantId, sub } = await billedSubscriber();
    setClock('2026-09-28T00:00:00Z');
    const invoice = await renewalInvoice(sub.id);
    expect(invoice).toMatchObject({
      tenantId,
      purpose: 'renewal',
      status: 'open',
      subscriptionId: sub.id,
      currency: 'INR',
      subtotal: 399900,
      taxTotal: 19995,
      total: 419895,
      inclusive: false,
      taxLines: [{ code: 'VAT', rateBps: 500, amount: 19995 }],
      period: { start: '2026-10-01T00:00:00.000Z', end: '2026-11-01T00:00:00.000Z' },
      issuedAt: '2026-09-28T00:00:00.000Z',
      billedTo: { legalName: 'Invoiced Academy LLC', country: 'AE' },
    });
    expect(invoice.number).toMatch(/^INV-2026-\d{6}$/);
    expect(invoice.lines).toEqual([
      { description: 'Starter — monthly subscription, 2026-10-01 to 2026-11-01', quantity: 1, unitAmount: 399900, amount: 399900 },
    ]);
  });

  it('bills a plan change at the charge fixed on its quote, once', async () => {
    const { sub } = await billedSubscriber();
    setClock('2026-09-16T00:00:00Z');
    const change = await asPlatform(() => requestPlanChange(superAdmin, sub.id, { planId: PRO, cycle: 'monthly' }));
    const invoice = await asPlatform(() => issueInvoice(scheduler, { kind: 'plan_change', planChangeId: change.id }));
    expect(invoice).toMatchObject({ purpose: 'plan_change', planChangeId: change.id, subtotal: 250000, taxTotal: 12500, total: 262500 });
    expect(invoice.lines[0].description).toMatch(/^Upgrade to Pro for the rest of the period to 2026-10-01, less ₹1,999\.50 unused on Starter$/);
    expect((await refusal(asPlatform(() => issueInvoice(scheduler, { kind: 'plan_change', planChangeId: change.id })))).status).toBe(409);
  });

  it('never bills the same renewal period twice, until the first invoice is voided', async () => {
    const { sub } = await billedSubscriber();
    const first = await renewalInvoice(sub.id);
    expect((await refusal(renewalInvoice(sub.id))).message).toBe('This has already been invoiced.');
    await asPlatform(() => voidInvoice({ auth: superAdmin.auth }, first.id, 'Issued with the wrong address'));
    expect((await renewalInvoice(sub.id)).number).not.toBe(first.number);
  });

  it('is issued by the platform, and refused without a billing address', async () => {
    const { sub } = await billedSubscriber();
    const admin: LifecycleActor = { type: 'user', auth: { sub: 'a', role: 'admin' } };
    expect((await refusal(asPlatform(() => issueInvoice(admin, { kind: 'renewal', subscriptionId: sub.id })))).status).toBe(403);
    const bare = (await platformDb.tenant.create({ data: { name: 'No Address', slug: `na-${unique()}` } })).id;
    expect(
      (await refusal(asPlatform(() => issueInvoice(scheduler, { kind: 'new_subscription', tenantId: bare, planId: STARTER, cycle: 'monthly' })))).status,
    ).toBe(409);
  });
});

describe('invoice numbers are unique at the database level', () => {
  it('numbers invoices in one ascending series, even when issued at once', async () => {
    const academies = await Promise.all(Array.from({ length: 6 }, () => billedSubscriber()));
    setClock('2026-12-31T23:00:00Z');
    const invoices = await Promise.all(
      academies.map(({ tenantId }) => asPlatform(() => issueInvoice(scheduler, { kind: 'new_subscription', tenantId, planId: STARTER, cycle: 'monthly' }))),
    );
    const numbers = invoices.map((i) => i.number);
    expect(new Set(numbers).size).toBe(6);
    const seqs = numbers.map((n) => Number(n.split('-')[2])).sort((a, b) => a - b);
    for (let i = 1; i < seqs.length; i++) expect(seqs[i]).toBe(seqs[i - 1] + 1);
  });

  it('refuses a duplicate number and a counter that goes back', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    await expect(
      platformDb.$executeRawUnsafe(
        `INSERT INTO "Invoice" ("id","tenantId","number","purpose","status","currency","subtotal","taxTotal","total","inclusive","linesJson","taxLinesJson","billedToJson","issuedAt","dueAt") SELECT ?, "tenantId", "number", 'renewal', 'open', "currency", 0, 0, 0, 0, '[]', '[]', '{}', "issuedAt", "dueAt" FROM "Invoice" WHERE "id" = ?`,
        `dup-${unique()}`,
        invoice.id,
      ),
    ).rejects.toThrow(/UNIQUE/);
    await expect(platformDb.$executeRawUnsafe(`UPDATE "InvoiceSequence" SET "next" = 1`)).rejects.toThrow(/never reused/);
  });
});

describe('a historical invoice never changes', () => {
  it('keeps its figures and address through a price change and a change of address', async () => {
    // A plan of its own, so re-pricing it touches no other test.
    const own = await plan(399900, 3999000);
    const { tenantId, sub } = await billedSubscriber(own);
    const before = await renewalInvoice(sub.id);
    await asPlatform(() => updatePlan({ auth: superAdmin.auth }, own, { monthlyPrice: 499900, annualPrice: 4999000 }));
    await asPlatform(() =>
      setBillingProfile({ auth: superAdmin.auth }, tenantId, {
        legalName: 'Renamed LLC',
        email: 'new@example.com',
        addressLine1: '2 Other Road',
        city: 'Abu Dhabi',
        postalCode: '11111',
        country: 'AE',
      }),
    );
    expect(await asPlatform(() => getInvoice(before.id))).toEqual(before);
  });

  it('refuses any edit to an issued invoice, and marking it paid without a payment', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    for (const set of [`"total" = 1`, `"linesJson" = '[]'`, `"billedToJson" = '{}'`, `"number" = 'INV-2026-999999'`]) {
      await expect(platformDb.$executeRawUnsafe(`UPDATE "Invoice" SET ${set} WHERE "id" = ?`, invoice.id), set).rejects.toThrow(/never altered/);
    }
    await expect(platformDb.$executeRawUnsafe(`UPDATE "Invoice" SET "status" = 'paid', "paidAt" = 1 WHERE "id" = ?`, invoice.id)).rejects.toThrow(
      /paid payment of its total/,
    );
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "Invoice" WHERE "id" = ?`, invoice.id)).rejects.toThrow(/never deleted/);
  });
});

describe('no code path updates or deletes a paid payment', () => {
  it('settles the invoice with a paid payment for exactly its total', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const result = await pay(invoice.id, 419895);
    expect(result).toMatchObject({
      settledInvoice: true,
      duplicate: false,
      payment: { status: 'paid', amount: 419895, method: { display: 'Visa •••• 4242' } },
    });
    expect((await asPlatform(() => getInvoice(invoice.id))).status).toBe('paid');
  });

  it('records the same provider payment once, however often it is reported', async () => {
    const { tenantId, sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const report = { invoiceId: invoice.id, providerPaymentId: `pay_${unique()}`, amount: 419895, currency: 'INR', status: 'paid' as const };
    const first = await asPlatform(() => recordPayment(provider, report));
    const again = await asPlatform(() => recordPayment(provider, report));
    const failedLater = await asPlatform(() => recordPayment(provider, { ...report, status: 'failed', failureMessage: 'late' }));
    expect(again).toMatchObject({ duplicate: true, settledInvoice: false, payment: { id: first.payment.id, status: 'paid' } });
    expect(failedLater).toMatchObject({ duplicate: true, payment: { status: 'paid' } });
    expect(await asPlatform(() => listPayments(tenantId))).toHaveLength(1);
  });

  it('settles a pending payment once, and then never again', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const ref = `pay_${unique()}`;
    const pending = await asPlatform(() =>
      recordPayment(provider, { invoiceId: invoice.id, providerPaymentId: ref, amount: 419895, currency: 'INR', status: 'pending' }),
    );
    expect(pending).toMatchObject({ settledInvoice: false, payment: { status: 'pending' } });
    const paid = await asPlatform(() =>
      recordPayment(provider, { invoiceId: invoice.id, providerPaymentId: ref, amount: 419895, currency: 'INR', status: 'paid' }),
    );
    expect(paid).toMatchObject({ settledInvoice: true, payment: { id: pending.payment.id, status: 'paid' } });
  });

  it('is enforced by the database: a settled payment cannot be updated or deleted', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const { payment } = await pay(invoice.id, 419895);
    for (const set of [`"status" = 'failed', "failedAt" = 1, "paidAt" = NULL`, `"amount" = 1`, `"failureMessage" = 'rewritten'`, `"methodLast4" = '0000'`]) {
      await expect(platformDb.$executeRawUnsafe(`UPDATE "Payment" SET ${set} WHERE "id" = ?`, payment.id), set).rejects.toThrow(/never (updated|altered)/);
    }
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "Payment" WHERE "id" = ?`, payment.id)).rejects.toThrow(/never deleted/);
    // A failed payment is history too.
    const other = await billedSubscriber();
    const inv2 = await renewalInvoice(other.sub.id);
    const failed = await asPlatform(() =>
      recordPayment(provider, {
        invoiceId: inv2.id,
        providerPaymentId: `pay_${unique()}`,
        amount: 419895,
        currency: 'INR',
        status: 'failed',
        failureCode: 'card_declined',
      }),
    );
    await expect(
      platformDb.$executeRawUnsafe(`UPDATE "Payment" SET "status" = 'paid', "paidAt" = 1, "failedAt" = NULL WHERE "id" = ?`, failed.payment.id),
    ).rejects.toThrow(/never updated/);
  });

  it('records money that does not match the invoice as it happened, and leaves the invoice open', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const short = await pay(invoice.id, 100);
    expect(short).toMatchObject({ settledInvoice: false, payment: { status: 'paid', amount: 100 } });
    expect((await asPlatform(() => getInvoice(invoice.id))).status).toBe('open');
  });

  it('takes payments from a verified provider event and nothing else', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    for (const actor of [superAdmin, scheduler]) {
      expect(
        (
          await refusal(
            asPlatform(() => recordPayment(actor, { invoiceId: invoice.id, providerPaymentId: 'x', amount: 419895, currency: 'INR', status: 'paid' })),
          )
        ).status,
      ).toBe(403);
    }
  });
});

describe('a refund leaves the original payment row intact', () => {
  it('refunds part, then the rest, as separate events, never touching the payment', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const { payment } = await pay(invoice.id, 419895);
    const rowBefore = await platformDb.payment.findUniqueOrThrow({ where: { id: payment.id } });

    const part = await asPlatform(() => refundPayment({ auth: superAdmin.auth }, payment.id, { amount: 100000, reason: 'Goodwill credit for an outage' }));
    expect(part).toMatchObject({ status: 'pending', amount: 100000 });
    await asPlatform(() => settleRefund(provider, part.id, { status: 'succeeded', providerRefundId: `re_${unique()}` }));
    expect(await asPlatform(() => getPayment(payment.id))).toMatchObject({ status: 'partially_refunded', refunded: 100000, refundable: 319895 });

    const rest = await asPlatform(() => refundPayment({ auth: superAdmin.auth }, payment.id, { reason: 'Closing the account' }));
    expect(rest.amount).toBe(319895);
    await asPlatform(() => settleRefund(provider, rest.id, { status: 'succeeded' }));
    expect(await asPlatform(() => getPayment(payment.id))).toMatchObject({ status: 'refunded', refunded: 419895, refundable: 0 });

    expect(await platformDb.payment.findUniqueOrThrow({ where: { id: payment.id } })).toEqual(rowBefore);
    expect(await platformDb.auditLog.count({ where: { targetId: payment.id, action: 'payment.refund_requested' } })).toBe(2);
  });

  it('never refunds more than was paid — in the service and in the database', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const { payment } = await pay(invoice.id, 419895);
    expect((await refusal(asPlatform(() => refundPayment({ auth: superAdmin.auth }, payment.id, { amount: 419896, reason: 'Too much' })))).status).toBe(409);
    await asPlatform(() => refundPayment({ auth: superAdmin.auth }, payment.id, { amount: 400000, reason: 'Most of it' }));
    // Pending refunds count too: only 19,895 is left.
    expect((await refusal(asPlatform(() => refundPayment({ auth: superAdmin.auth }, payment.id, { amount: 20000, reason: 'A bit more' })))).status).toBe(409);
    const { tenantId } = await platformDb.payment.findUniqueOrThrow({ where: { id: payment.id }, select: { tenantId: true } });
    await expect(
      platformDb.$executeRawUnsafe(
        `INSERT INTO "Refund" ("id","tenantId","paymentId","amount","currency","reason","status","provider") VALUES (?, ?, ?, 20000, 'INR', 'Around the service', 'pending', 'testpay')`,
        `r-${unique()}`,
        tenantId,
        payment.id,
      ),
    ).rejects.toThrow(/never more than is left/);
    const refund = await platformDb.refund.findFirstOrThrow({ where: { paymentId: payment.id } });
    await expect(platformDb.$executeRawUnsafe(`UPDATE "Refund" SET "amount" = 1 WHERE "id" = ?`, refund.id)).rejects.toThrow(/never altered/);
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "Refund" WHERE "id" = ?`, refund.id)).rejects.toThrow(/never deleted/);
  });

  it('lets only one of two refunds requested at the same moment through, and refuses the other as a conflict', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const { payment } = await pay(invoice.id, 419895);
    const results = await Promise.allSettled(
      [1, 2].map(() => asPlatform(() => refundPayment({ auth: superAdmin.auth }, payment.id, { amount: 300000, reason: 'Twice at once' }))),
    );
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    const refused = results.find((r) => r.status === 'rejected') as PromiseRejectedResult;
    expect(refused.reason).toMatchObject({ status: 409 });
    expect(await platformDb.refund.count({ where: { paymentId: payment.id } })).toBe(1);
  });

  it('refuses a refund on an unpaid payment, without a reason, or from anyone but a super admin', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    const failed = await asPlatform(() =>
      recordPayment(provider, { invoiceId: invoice.id, providerPaymentId: `pay_${unique()}`, amount: 419895, currency: 'INR', status: 'failed' }),
    );
    expect((await refusal(asPlatform(() => refundPayment({ auth: superAdmin.auth }, failed.payment.id, { reason: 'Never paid' })))).status).toBe(409);
    const { payment } = await pay(invoice.id, 419895);
    expect((await refusal(asPlatform(() => refundPayment({ auth: superAdmin.auth }, payment.id, { reason: '' })))).status).toBe(400);
    expect((await refusal(asPlatform(() => refundPayment({ auth: { sub: 'a', role: 'admin' } }, payment.id, { reason: 'Please' })))).status).toBe(403);
  });
});

describe('no raw card data exists anywhere in the schema or logs', () => {
  it('has no column a card number, security code or full expiry could be kept in', async () => {
    const tables = await platformDb.$queryRawUnsafe<{ name: string }[]>(`SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'`);
    const offenders: string[] = [];
    for (const { name } of tables) {
      const cols = await platformDb.$queryRawUnsafe<{ name: string }[]>(`PRAGMA table_info("${name}")`);
      for (const c of cols) if (/card.?number|^pan$|cvv|cvc|security.?code|card.?data|full.?number/i.test(c.name)) offenders.push(`${name}.${c.name}`);
    }
    expect(offenders).toEqual([]);
  });

  it('keeps only masked display data, and refuses anything card-number-like', async () => {
    const { tenantId } = await billedSubscriber();
    const saved = await asPlatform(() =>
      savePaymentMethod(provider, tenantId, {
        providerMethodRef: 'pm_1Ntest',
        kind: 'card',
        brand: 'Visa',
        last4: '4242',
        expMonth: 12,
        expYear: 2030,
        makeDefault: true,
        cardNumber: '4242424242424242',
        cvv: '123',
      } as never),
    );
    expect(saved).toMatchObject({ display: 'Visa •••• 4242', isDefault: true });
    expect(JSON.stringify(await platformDb.paymentMethod.findUniqueOrThrow({ where: { id: saved.id } }))).not.toMatch(/4242424242424242|"123"/);
    for (const bad of [{ last4: '4242424242424242' }, { brand: 'Visa 4242424242' }, { providerMethodRef: '4242424242424242' }, { last4: '42a2' }]) {
      expect(
        (await refusal(asPlatform(() => savePaymentMethod(provider, tenantId, { providerMethodRef: `pm_${unique()}`, kind: 'card', brand: 'Visa', ...bad }))))
          .status,
        JSON.stringify(bad),
      ).toBe(400);
    }
    await expect(
      platformDb.$executeRawUnsafe(
        `INSERT INTO "PaymentMethod" ("id","tenantId","provider","providerMethodRef","kind","brand","last4") VALUES (?, ?, 'testpay', ?, 'card', 'Visa', '4242424242424242')`,
        `pm-${unique()}`,
        tenantId,
        `raw_${unique()}`,
      ),
    ).rejects.toThrow(/CHECK/);
    expect(await asPlatform(() => listPaymentMethods(tenantId))).toHaveLength(1);
  });

  it('writes nothing card-like — nothing at all — to the logs through a whole billing flow', async () => {
    const spies = (['log', 'info', 'warn', 'error', 'debug'] as const).map((level) => vi.spyOn(console, level));
    try {
      const { tenantId, sub } = await billedSubscriber();
      await asPlatform(() => savePaymentMethod(provider, tenantId, { providerMethodRef: `pm_${unique()}`, kind: 'card', brand: 'Mastercard', last4: '5454' }));
      const invoice = await renewalInvoice(sub.id);
      const { payment } = await pay(invoice.id, 419895, { method: { kind: 'card', brand: 'Mastercard', last4: '5454' } });
      const refund = await asPlatform(() => refundPayment({ auth: superAdmin.auth }, payment.id, { amount: 1000, reason: 'Partial goodwill' }));
      await asPlatform(() => settleRefund(provider, refund.id, { status: 'succeeded' }));
      await refusal(pay(invoice.id, 419895, { method: { kind: 'card', brand: 'Visa', last4: '5555555555554444' } }));
      const written = spies.flatMap((s) => s.mock.calls.map((c) => c.map(String).join(' '))).join('\n');
      expect(written).not.toMatch(/\b\d{12,19}\b/);
      expect(written).not.toMatch(/cvv|cvc/i);
      expect(spies.reduce((n, s) => n + s.mock.calls.length, 0)).toBe(0);
    } finally {
      for (const s of spies) s.mockRestore();
    }
  });
});

describe('tenant isolation', () => {
  it('shows an academy its own invoices and payments only', async () => {
    const a = await billedSubscriber();
    const b = await billedSubscriber();
    const invoice = await renewalInvoice(a.sub.id);
    await pay(invoice.id, 419895);
    expect((await refusal(runInTenant(b.tenantId, () => getInvoice(invoice.id)))).status).toBe(404);
    expect(await runInTenant(b.tenantId, () => listInvoices(b.tenantId))).toEqual([]);
    expect(await runInTenant(b.tenantId, () => listPayments(b.tenantId))).toEqual([]);
    expect(await runInTenant(a.tenantId, () => listInvoices(a.tenantId))).toHaveLength(1);
  });

  it('voids only an open invoice, by a super admin, with a reason on the trail', async () => {
    const { sub } = await billedSubscriber();
    const invoice = await renewalInvoice(sub.id);
    expect((await refusal(asPlatform(() => voidInvoice({ auth: { sub: 'a', role: 'admin' } }, invoice.id, 'Mistake')))).status).toBe(403);
    await pay(invoice.id, 419895);
    expect((await refusal(asPlatform(() => voidInvoice({ auth: superAdmin.auth }, invoice.id, 'Too late')))).status).toBe(409);
  });
});
