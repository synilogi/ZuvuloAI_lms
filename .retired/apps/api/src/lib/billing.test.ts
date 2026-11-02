import { BYTES_PER_GB, calculateTax, type PlanLimits } from '@syniastrolms/domain';
import { afterEach, beforeAll, describe, expect, it } from 'vitest';

import { platformDb } from '../test/db.js';
import { unique } from '../test/helpers.js';
import type { AuditActor } from './audit.js';
import {
  getBillingProfile,
  listTaxRules,
  payableForNewSubscription,
  payableForPlanChange,
  payableForRenewal,
  retireTaxRule,
  setBillingProfile,
  setTaxRule,
  taxRuleFor,
  type BillingProfileInput,
} from './billing.js';
import { setClock } from './clock.js';
import { ApiError } from './errors.js';
import { requestPlanChange } from './planChanges.js';
import { createPlan, publishPlan, type CreatePlanInput } from './plans.js';
import { provisionSuperAdmin } from './provisionSuperAdmin.js';
import { createSubscription, type LifecycleActor } from './subscriptions.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/* SAAS-007: integer money, tax as data, and a payable amount only the server calculates. Each test that
 * sets a tax rule uses a country of its own, so no two tests — and not the seed's demo rule for India —
 * share one. */

const asPlatform = <R>(fn: () => Promise<R>) => runAsPlatform('billing tests act as the platform', fn);
let operator: AuditActor & { auth: { sub: string; role: 'superadmin' } };
let superAdmin: LifecycleActor & { type: 'user' };

const LIMITS: PlanLimits = {
  'learners.max': 100,
  'instructors.max': 5,
  'courses.max': 10,
  'storage.bytes': BYTES_PER_GB,
  'live_classes.max': 5,
  'admin_accounts.max': 2,
};

async function plan(monthly: number, annual: number, over: Partial<CreatePlanInput> = {}) {
  return asPlatform(async () => {
    const p = await createPlan(operator, {
      name: 'Billing test plan',
      description: 'A plan for the billing suite.',
      code: `B${unique().toUpperCase()}`.slice(0, 24),
      currency: 'INR',
      cycles: ['monthly', 'annual'],
      monthlyPrice: monthly,
      annualPrice: annual,
      trialEnabled: false,
      trialDays: 0,
      features: ['courses.manage'],
      limits: LIMITS,
      ...over,
    });
    await publishPlan(operator, p.id);
    return p.id;
  });
}

const address = (country: string, over: Partial<BillingProfileInput> = {}): BillingProfileInput => ({
  legalName: 'Vidya Shiksha Pvt Ltd',
  email: 'Accounts@Example.com',
  addressLine1: '12 MG Road',
  city: 'Bengaluru',
  postalCode: '560001',
  country,
  ...over,
});

const newAcademy = async () => (await platformDb.tenant.create({ data: { name: 'Billing Academy', slug: `bill-${unique()}` } })).id;

async function billedAcademy(country: string, over: Partial<BillingProfileInput> = {}) {
  const tenantId = await newAcademy();
  await asPlatform(() => setBillingProfile(operator, tenantId, address(country, over)));
  return tenantId;
}

const refusal = async (promise: Promise<unknown>) => {
  const err = await promise.then(
    () => undefined,
    (e: unknown) => e,
  );
  expect(err, 'expected a refusal').toBeInstanceOf(ApiError);
  return err as ApiError;
};

const gst = (country: string, over: object = {}) =>
  asPlatform(() => setTaxRule(operator, { name: 'GST', country, components: [{ code: 'GST', label: 'Goods and Services Tax', rateBps: 1800 }], ...over }));

beforeAll(async () => {
  const created = await provisionSuperAdmin({ email: `billing-${unique()}@example.com`, password: 'billing-suite-password', name: 'Billing' });
  operator = { auth: { sub: created.user.id, role: 'superadmin' } };
  superAdmin = { type: 'user', auth: operator.auth };
});

afterEach(() => setClock(null));

describe('a client-supplied amount is ignored and the server figure is used', () => {
  it('prices a new subscription from the plan version, taxed at the academy’s address', async () => {
    await gst('SG');
    const tenantId = await billedAcademy('SG');
    const planId = await plan(399900, 3999000);
    // Everything a client might send to set its own price: an amount, a total, a tax, a rate.
    const payable = await asPlatform(() =>
      payableForNewSubscription(tenantId, { planId, cycle: 'monthly', amount: 1, total: 1, tax: 0, rateBps: 0, currency: 'USD' } as never),
    );
    expect(payable).toMatchObject({
      purpose: 'new_subscription',
      currency: 'INR',
      net: 399900,
      tax: 71982,
      gross: 471882,
      inclusive: false,
      billedTo: { country: 'SG' },
    });
    expect(payable.lines).toEqual([{ code: 'GST', label: 'Goods and Services Tax', rateBps: 1800, amount: 71982 }]);
  });

  it('prices a renewal from the subscription’s stored amount', async () => {
    await gst('MY');
    const tenantId = await billedAcademy('MY');
    const planId = await plan(149900, 1499000);
    const sub = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId, cycle: 'annual', start: 'active' }));
    expect(await asPlatform(() => payableForRenewal(sub.id))).toMatchObject({ purpose: 'renewal', net: 1499000, tax: 269820, gross: 1768820 });
  });

  it('prices a plan change from the charge fixed on its quote (SAAS-006)', async () => {
    await gst('NZ');
    const tenantId = await billedAcademy('NZ');
    const [small, big] = [await plan(399900, 3999000), await plan(899900, 8999000)];
    setClock('2026-09-01T00:00:00Z');
    const sub = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId: small, cycle: 'monthly', start: 'active' }));
    setClock('2026-09-16T00:00:00Z');
    const change = await asPlatform(() => requestPlanChange(superAdmin, sub.id, { planId: big, cycle: 'monthly' }));
    expect(await asPlatform(() => payableForPlanChange(change.id))).toMatchObject({ purpose: 'plan_change', net: 250000, tax: 45000, gross: 295000 });
  });

  it('refuses to price anything for an academy with no billing address', async () => {
    const tenantId = await newAcademy();
    const planId = await plan(399900, 3999000);
    expect((await refusal(asPlatform(() => payableForNewSubscription(tenantId, { planId, cycle: 'monthly' })))).status).toBe(409);
  });
});

describe('tax calculation — kept apart from the price, decided by data', () => {
  it('charges no tax where no rule applies', async () => {
    const tenantId = await billedAcademy('IS');
    const planId = await plan(399900, 3999000);
    expect(await asPlatform(() => payableForNewSubscription(tenantId, { planId, cycle: 'monthly' }))).toMatchObject({
      net: 399900,
      tax: 0,
      gross: 399900,
      lines: [],
      taxRuleId: null,
    });
  });

  it('prefers a region’s own rule over its country’s: split components in one region, one elsewhere', async () => {
    await asPlatform(() => setTaxRule(operator, { name: 'IGST', country: 'LK', components: [{ code: 'IGST', label: 'Integrated GST', rateBps: 1800 }] }));
    await asPlatform(() =>
      setTaxRule(operator, {
        name: 'CGST + SGST',
        country: 'LK',
        region: 'wp',
        components: [
          { code: 'cgst', label: 'Central GST', rateBps: 900 },
          { code: 'sgst', label: 'State GST', rateBps: 900 },
        ],
      }),
    );
    const planId = await plan(399900, 3999000);
    const inRegion = await billedAcademy('LK', { region: 'WP' });
    const elsewhere = await billedAcademy('LK', { region: 'CP' });
    const a = await asPlatform(() => payableForNewSubscription(inRegion, { planId, cycle: 'monthly' }));
    const b = await asPlatform(() => payableForNewSubscription(elsewhere, { planId, cycle: 'monthly' }));
    expect(a.lines.map((l) => [l.code, l.amount])).toEqual([
      ['CGST', 35991],
      ['SGST', 35991],
    ]);
    expect(b.lines.map((l) => [l.code, l.amount])).toEqual([['IGST', 71982]]);
    expect(a.gross).toBe(b.gross);
  });

  it('takes the tax out of a price that already includes it', async () => {
    await asPlatform(() =>
      setTaxRule(operator, { name: 'VAT', country: 'IE', inclusive: true, components: [{ code: 'VAT', label: 'Value added tax', rateBps: 2300 }] }),
    );
    const tenantId = await billedAcademy('IE');
    const planId = await plan(123000, 1230000);
    const payable = await asPlatform(() => payableForNewSubscription(tenantId, { planId, cycle: 'monthly' }));
    expect(payable).toMatchObject({ inclusive: true, gross: 123000, net: 100000, tax: 23000 });
  });

  it('replaces a rule by retiring it, so tax already charged keeps its rule', async () => {
    const first = await gst('TH');
    const second = await asPlatform(() => setTaxRule(operator, { name: 'GST', country: 'TH', components: [{ code: 'GST', label: 'GST', rateBps: 700 }] }));
    const rules = await asPlatform(() => listTaxRules({ includeRetired: true }));
    expect(rules.find((r) => r.id === first.id)?.retiredAt).toBeDefined();
    expect((await asPlatform(() => taxRuleFor('TH')))?.id).toBe(second.id);
    await asPlatform(() => retireTaxRule(operator, second.id));
    expect(await asPlatform(() => taxRuleFor('TH'))).toBeNull();
    expect((await refusal(asPlatform(() => retireTaxRule(operator, second.id)))).status).toBe(409);
  });

  it('holds rules fixed in the database, one active per place', async () => {
    const rule = await gst('VN');
    await expect(platformDb.$executeRawUnsafe(`UPDATE "TaxRuleComponent" SET "rateBps" = 1 WHERE "ruleId" = ?`, rule.id)).rejects.toThrow(/never altered/);
    await expect(platformDb.$executeRawUnsafe(`UPDATE "TaxRule" SET "inclusive" = 1 WHERE "id" = ?`, rule.id)).rejects.toThrow(/never altered/);
    await expect(platformDb.$executeRawUnsafe(`DELETE FROM "TaxRule" WHERE "id" = ?`, rule.id)).rejects.toThrow(/never deleted/);
    await expect(
      platformDb.$executeRawUnsafe(
        `INSERT INTO "TaxRuleComponent" ("ruleId", "code", "label", "rateBps", "position") VALUES (?, 'EXTRA', 'Extra', 100, 9)`,
        rule.id,
      ),
    ).rejects.toThrow(/every component/);
    await expect(
      platformDb.$executeRawUnsafe(`INSERT INTO "TaxRule" ("id", "name", "country", "componentCount") VALUES (?, 'Second', 'VN', 1)`, `tr-${unique()}`),
    ).rejects.toThrow(/UNIQUE/);
    await expect(
      platformDb.$executeRawUnsafe(`INSERT INTO "TaxRuleComponent" ("ruleId", "code", "label", "rateBps", "position") VALUES (?, 'X', 'X', 18.5, 0)`, rule.id),
    ).rejects.toThrow();
  });

  it('refuses a malformed rule, and anyone but a super admin working as the platform', async () => {
    for (const bad of [
      { name: 'G', country: 'PT', components: [{ code: 'A', label: 'A', rateBps: 100 }] },
      { name: 'GST', country: 'XX', components: [{ code: 'A', label: 'A', rateBps: 100 }] },
      { name: 'GST', country: 'PT', components: [] },
      { name: 'GST', country: 'PT', components: [{ code: 'A', label: 'A', rateBps: 18.5 }] },
      { name: 'GST', country: 'PT', components: [{ code: 'A', label: 'A', rateBps: 10001 }] },
      {
        name: 'GST',
        country: 'PT',
        components: [
          { code: 'A', label: 'A', rateBps: 1 },
          { code: 'a', label: 'A again', rateBps: 1 },
        ],
      },
    ]) {
      expect((await refusal(asPlatform(() => setTaxRule(operator, bad)))).status, JSON.stringify(bad)).toBe(400);
    }
    const tenantId = await newAcademy();
    expect(
      (await refusal(runInTenant(tenantId, () => setTaxRule(operator, { name: 'GST', country: 'PT', components: [{ code: 'A', label: 'A', rateBps: 100 }] }))))
        .status,
    ).toBe(403);
    expect(
      (
        await refusal(
          asPlatform(() =>
            setTaxRule({ auth: { sub: 'x', role: 'admin' } }, { name: 'GST', country: 'PT', components: [{ code: 'A', label: 'A', rateBps: 100 }] }),
          ),
        )
      ).status,
    ).toBe(403);
  });
});

describe('billing profiles', () => {
  it('keeps an academy’s address and registration as given, normalised', async () => {
    const tenantId = await newAcademy();
    const saved = await asPlatform(() => setBillingProfile(operator, tenantId, address('in', { region: 'ka', taxRegistration: '29abcde 1234f1z5' })));
    expect(saved).toMatchObject({ country: 'IN', region: 'KA', email: 'accounts@example.com', taxRegistration: '29ABCDE1234F1Z5' });
    expect(await asPlatform(() => getBillingProfile(tenantId))).toMatchObject({ legalName: 'Vidya Shiksha Pvt Ltd' });
    expect(await platformDb.auditLog.findFirst({ where: { targetId: tenantId, action: 'billing.profile_updated' } })).not.toBeNull();
  });

  it('lets the academy’s own admin set it from inside the academy, and no one else', async () => {
    const tenantId = await newAcademy();
    const admin = await platformDb.user.create({ data: { tenantId, email: `bp-${unique()}@example.com`, passwordHash: 'x', name: 'Admin', role: 'admin' } });
    const own = { auth: { sub: admin.id, role: 'admin' as const } };
    expect((await runInTenant(tenantId, () => setBillingProfile(own, tenantId, address('IN')))).country).toBe('IN');
    const other = await newAcademy();
    expect((await refusal(runInTenant(other, () => setBillingProfile(own, tenantId, address('IN'))))).status).toBe(403);
    expect((await refusal(runInTenant(tenantId, () => setBillingProfile({ auth: { sub: 'i', role: 'instructor' } }, tenantId, address('IN'))))).status).toBe(
      403,
    );
  });

  it('refuses an address it cannot bill to', async () => {
    const tenantId = await newAcademy();
    for (const over of [
      { country: 'ZZ' },
      { country: 'EU' },
      { country: 'XX' },
      { country: 'India' },
      { email: 'not-an-email' },
      { addressLine1: '' },
      { taxRegistration: 'no spaces allowed!' },
    ]) {
      expect((await refusal(asPlatform(() => setBillingProfile(operator, tenantId, address('IN', over))))).status, JSON.stringify(over)).toBe(400);
    }
  });
});

describe('no float arithmetic reaches a stored total', () => {
  it('guards every stored amount with an integer CHECK in the database', async () => {
    const tables = await platformDb.$queryRawUnsafe<{ name: string; sql: string }[]>(`SELECT name, sql FROM sqlite_master WHERE type = 'table'`);
    const sqlOf = (t: string) => tables.find((r) => r.name === t)?.sql ?? '';
    const alterations = await platformDb.$queryRawUnsafe<{ sql: string }[]>(`SELECT sql FROM sqlite_master WHERE sql LIKE '%typeof%'`);
    const all = alterations.map((a) => a.sql).join('\n');
    const money: [string, string][] = [
      ['PlanVersion', 'monthlyPrice'],
      ['PlanVersion', 'annualPrice'],
      ['Subscription', 'amount'],
      ['PlanChange', 'fromAmount'],
      ['PlanChange', 'toAmount'],
      ['PlanChange', 'credit'],
      ['PlanChange', 'charge'],
      ['PlanChange', 'forfeited'],
      ['TaxRuleComponent', 'rateBps'],
    ];
    for (const [table, column] of money) expect(sqlOf(table) + all, `${table}.${column}`).toContain(`typeof("${column}") = 'integer'`);
  });

  it('refuses a fractional amount wherever one would be stored', async () => {
    const tenantId = await newAcademy();
    const planId = await plan(399900, 3999000);
    const sub = await asPlatform(() => createSubscription(superAdmin, { tenantId, planId, cycle: 'monthly', start: 'active' }));
    // No trigger path allows an amount to change without a plan change, and the CHECK refuses a fraction regardless.
    await expect(platformDb.$executeRawUnsafe(`UPDATE "Subscription" SET "amount" = 3999.5 WHERE "id" = ?`, sub.id)).rejects.toThrow();
    expect((await refusal(asPlatform(() => createPlan(operator, { ...planInput(), monthlyPrice: 3999.5 })))).status).toBe(400);
  });

  it('calculates tax in integers where a float would drift', async () => {
    // 0.1 + 0.2-style drift: 18% of 1,000,000,000,001 paise is 180,000,000,000.18 — a float product of
    // the rupee figure loses the last paisa; the integer path does not.
    expect(calculateTax(1_000_000_000_001, 'INR', [{ code: 'GST', label: 'GST', rateBps: 1800 }]).tax).toBe(180_000_000_000);
    expect(calculateTax(33, 'INR', [{ code: 'T', label: 'T', rateBps: 1500 }]).tax).toBe(5); // 4.95 → 5
  });
});

describe('adding a second currency needs no schema change', () => {
  it('sells, subscribes and taxes in dollars and yen with the tables as they are', async () => {
    await asPlatform(() => setTaxRule(operator, { name: 'Sales tax', country: 'CA', components: [{ code: 'GST', label: 'GST', rateBps: 500 }] }));
    await asPlatform(() =>
      setTaxRule(operator, { name: 'Consumption tax', country: 'JP', components: [{ code: 'JCT', label: 'Consumption tax', rateBps: 1000 }] }),
    );
    const usd = await plan(4999, 49990, { currency: 'USD' });
    const jpy = await plan(5000, 50000, { currency: 'JPY' });
    const canada = await billedAcademy('CA');
    const japan = await billedAcademy('JP');

    const dollars = await asPlatform(() => payableForNewSubscription(canada, { planId: usd, cycle: 'monthly' }));
    expect(dollars).toMatchObject({ currency: 'USD', net: 4999, tax: 250, gross: 5249 });
    const yen = await asPlatform(() => payableForNewSubscription(japan, { planId: jpy, cycle: 'annual' }));
    expect(yen).toMatchObject({ currency: 'JPY', net: 50000, tax: 5000, gross: 55000 });

    const subUsd = await asPlatform(() => createSubscription(superAdmin, { tenantId: canada, planId: usd, cycle: 'monthly', start: 'active' }));
    expect(subUsd).toMatchObject({ currency: 'USD', amount: 4999 });
    expect(await asPlatform(() => payableForRenewal(subUsd.id))).toMatchObject({ currency: 'USD', gross: 5249 });
  });
});

function planInput(): CreatePlanInput {
  return {
    name: 'Fraction plan',
    description: 'A plan priced in half a paisa.',
    code: `F${unique().toUpperCase()}`.slice(0, 24),
    currency: 'INR',
    cycles: ['monthly'],
    monthlyPrice: 100,
    annualPrice: 0,
    trialEnabled: false,
    trialDays: 0,
    features: ['courses.manage'],
    limits: LIMITS,
  };
}
