import { calculateTax, isTaxRate, type BillingCycle, type TaxComponent, type TaxedCharge } from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { recordAuditLog, type AuditActor } from './audit.js';
import { now } from './clock.js';
import { db } from './db.js';
import { badRequest, conflict, forbidden, notFound } from './errors.js';
import { planForNewSubscription } from './plans.js';
import { loadSubscriptionRow, nextPeriodTerms, withinAcademy } from './subscriptions.js';
import { currentContext, runAsPlatform } from './tenancy.js';

/*
 * Money, tax and currency on the server (subscriptions.md §26–28, SAAS-007).
 *
 *   - Tax rules are platform data: a rule names the country (and optionally the region) it applies to,
 *     whether prices include it, and its components in basis points. Which tax a buyer pays is looked
 *     up — region first, then country, else none — never decided by a condition in code, and no rate is
 *     written anywhere but the rules the operator configures.
 *   - Each academy's billing profile holds the address and registration its tax is decided by.
 *   - What an academy pays is calculated here and only here, from the stored price of what it is
 *     buying and the rule for its address. None of the functions below takes an amount: a figure a
 *     client sends has nowhere to go.
 *
 * Every amount is an integer of the currency's minor unit and every rate an integer of basis points; the
 * arithmetic is the domain's `calculateTax`, in integers. Currency travels with the price it belongs
 * to, so a second currency is a plan priced in it and nothing more.
 */

/* ─── Billing profiles ─────────────────────────────────────────────────── */

export interface BillingProfileInput {
  legalName: string;
  email: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  region?: string;
  postalCode: string;
  country: string;
  taxRegistration?: string;
}

export type BillingProfileRecord = Required<Omit<BillingProfileInput, 'addressLine2' | 'region' | 'taxRegistration'>> &
  Pick<BillingProfileInput, 'addressLine2' | 'region' | 'taxRegistration'> & { tenantId: string; updatedAt: string };

const regionNames = new Intl.DisplayNames(['en'], { type: 'region', fallback: 'none' });

/** Two-letter codes the runtime names that are not countries: ISO's user-assigned range and groupings. */
const NOT_A_COUNTRY = /^(AA|Q[M-Z]|X[A-JL-Z]|ZZ|EU|EZ|UN)$/;

/** An ISO 3166-1 alpha-2 country code the runtime knows — not a grouping, not a code left for private use. */
export function isCountryCode(code: string): boolean {
  if (!/^[A-Z]{2}$/.test(code) || NOT_A_COUNTRY.test(code)) return false;
  try {
    return regionNames.of(code) !== undefined;
  } catch {
    return false;
  }
}

const clean = (v: string | undefined) => {
  const t = v?.trim();
  return t ? t : undefined;
};

function validateProfile(input: BillingProfileInput): BillingProfileInput {
  const out: BillingProfileInput = {
    legalName: input.legalName?.trim() ?? '',
    email: input.email?.trim().toLowerCase() ?? '',
    addressLine1: input.addressLine1?.trim() ?? '',
    addressLine2: clean(input.addressLine2),
    city: input.city?.trim() ?? '',
    region: clean(input.region)?.toUpperCase(),
    postalCode: input.postalCode?.trim() ?? '',
    country: input.country?.trim().toUpperCase() ?? '',
    taxRegistration: clean(input.taxRegistration)?.toUpperCase().replace(/\s+/g, ''),
  };
  const issues: { field: string; message: string }[] = [];
  if (out.legalName.length < 2) issues.push({ field: 'legalName', message: 'Give the name the LMS bills under.' });
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(out.email)) issues.push({ field: 'email', message: 'Give an email address for invoices.' });
  if (out.addressLine1.length < 3) issues.push({ field: 'addressLine1', message: 'Give the street address.' });
  if (out.city.length < 2) issues.push({ field: 'city', message: 'Give the city.' });
  if (out.postalCode.length < 2) issues.push({ field: 'postalCode', message: 'Give the postal code.' });
  if (!isCountryCode(out.country)) issues.push({ field: 'country', message: 'Choose the country by its two-letter code, e.g. IN.' });
  if (out.region !== undefined && !/^[A-Z0-9-]{1,10}$/.test(out.region)) issues.push({ field: 'region', message: 'A region is a short code, e.g. KA.' });
  // A registration is kept as issued: no one country's format is enforced here (§27).
  if (out.taxRegistration !== undefined && !/^[A-Z0-9-]{3,32}$/.test(out.taxRegistration)) {
    issues.push({ field: 'taxRegistration', message: 'A tax registration is 3–32 letters, digits or hyphens.' });
  }
  if (issues.length) throw badRequest(issues[0].message, issues);
  return out;
}

const toProfile = (row: Prisma.BillingProfileGetPayload<object>): BillingProfileRecord => ({
  tenantId: row.tenantId,
  legalName: row.legalName,
  email: row.email,
  addressLine1: row.addressLine1,
  ...(row.addressLine2 ? { addressLine2: row.addressLine2 } : {}),
  city: row.city,
  ...(row.region ? { region: row.region } : {}),
  postalCode: row.postalCode,
  country: row.country,
  ...(row.taxRegistration ? { taxRegistration: row.taxRegistration } : {}),
  updatedAt: row.updatedAt.toISOString(),
});

/** Who may set an academy's billing details: a super admin as the platform, or that academy's own admin. */
function assertBillingEditor(actor: AuditActor, tenantId: string) {
  const role = actor.auth?.role;
  const context = currentContext();
  if (role === 'superadmin' && context?.kind === 'platform') return;
  if (role === 'admin' && context?.kind === 'tenant' && context.tenantId === tenantId) return;
  throw forbidden('You cannot change this LMS’s billing details.');
}

export async function getBillingProfile(tenantId: string): Promise<BillingProfileRecord | null> {
  const row = await withinAcademy(tenantId, () => db.billingProfile.findUnique({ where: { tenantId } }));
  return row ? toProfile(row) : null;
}

/** Creates or replaces the academy's billing profile. Audited with what changed. */
export async function setBillingProfile(actor: AuditActor, tenantId: string, input: BillingProfileInput): Promise<BillingProfileRecord> {
  assertBillingEditor(actor, tenantId);
  const data = validateProfile(input);
  const columns = {
    legalName: data.legalName,
    email: data.email,
    addressLine1: data.addressLine1,
    addressLine2: data.addressLine2 ?? null,
    city: data.city,
    region: data.region ?? null,
    postalCode: data.postalCode,
    country: data.country,
    taxRegistration: data.taxRegistration ?? null,
  };
  const row = await withinAcademy(tenantId, () =>
    db.$transaction(async (tx) => {
      const saved = await tx.billingProfile.upsert({ where: { tenantId }, create: { tenantId, ...columns }, update: columns });
      await recordAuditLog(
        actor,
        {
          action: 'billing.profile_updated',
          targetType: 'tenant',
          targetId: tenantId,
          meta: { country: data.country, region: data.region ?? null, hasRegistration: Boolean(data.taxRegistration) },
        },
        tx,
      );
      return saved;
    }),
  );
  return toProfile(row);
}

/* ─── Tax rules ────────────────────────────────────────────────────────── */

export interface TaxRuleInput {
  name: string;
  country: string;
  region?: string;
  inclusive?: boolean;
  components: TaxComponent[];
}

export interface TaxRuleRecord {
  id: string;
  name: string;
  country: string;
  region?: string;
  inclusive: boolean;
  components: TaxComponent[];
  createdAt: string;
  retiredAt?: string;
}

const WITH_COMPONENTS = { components: { orderBy: { position: 'asc' } } } satisfies Prisma.TaxRuleInclude;

const toRule = (row: Prisma.TaxRuleGetPayload<{ include: typeof WITH_COMPONENTS }>): TaxRuleRecord => ({
  id: row.id,
  name: row.name,
  country: row.country,
  ...(row.region ? { region: row.region } : {}),
  inclusive: row.inclusive,
  components: row.components.map((c) => ({ code: c.code, label: c.label, rateBps: c.rateBps })),
  createdAt: row.createdAt.toISOString(),
  ...(row.retiredAt ? { retiredAt: row.retiredAt.toISOString() } : {}),
});

function assertPlatformOperator(actor: AuditActor) {
  if (currentContext()?.kind !== 'platform') throw forbidden('Tax rules are the platform’s.');
  if (actor.auth && actor.auth.role !== 'superadmin') throw forbidden('Only a super admin can set tax rules.');
}

/**
 * Sets the tax for a country, or a region of it: the rule already active there is retired and this one
 * takes its place, in one transaction. Rates are whole basis points (1800 is 18%); a rule has 1–5
 * components with distinct codes. Tax already charged keeps the rule it was charged under.
 */
export async function setTaxRule(actor: AuditActor, input: TaxRuleInput): Promise<TaxRuleRecord> {
  assertPlatformOperator(actor);
  const country = input.country?.trim().toUpperCase() ?? '';
  const region = clean(input.region)?.toUpperCase();
  const name = input.name?.trim() ?? '';
  if (name.length < 2) throw badRequest('Name the tax, e.g. GST.');
  if (!isCountryCode(country)) throw badRequest('Choose the country by its two-letter code, e.g. IN.');
  if (region !== undefined && !/^[A-Z0-9-]{1,10}$/.test(region)) throw badRequest('A region is a short code, e.g. KA.');
  const components = input.components ?? [];
  if (components.length < 1 || components.length > 5) throw badRequest('A tax rule has between one and five components.');
  const codes = new Set<string>();
  for (const c of components) {
    const code = c.code?.trim().toUpperCase();
    if (!code || !/^[A-Z0-9_-]{1,16}$/.test(code)) throw badRequest('A component code is 1–16 letters, digits, hyphens or underscores.');
    if (codes.has(code)) throw badRequest(`The component ${code} is listed twice.`);
    codes.add(code);
    if (!c.label?.trim()) throw badRequest(`Give component ${code} a label.`);
    if (!isTaxRate(c.rateBps)) throw badRequest(`${code}: a rate is a whole number of basis points from 0 to 10000 (1800 is 18%).`);
  }

  const created = await db.$transaction(async (tx) => {
    const retired = await tx.taxRule.updateMany({ where: { country, region: region ?? null, retiredAt: null }, data: { retiredAt: now() } });
    const rule = await tx.taxRule.create({
      data: {
        name,
        country,
        region: region ?? null,
        inclusive: Boolean(input.inclusive),
        componentCount: components.length,
        createdAt: now(),
        components: { create: components.map((c, position) => ({ code: c.code.trim().toUpperCase(), label: c.label.trim(), rateBps: c.rateBps, position })) },
      },
      include: WITH_COMPONENTS,
    });
    await recordAuditLog(
      actor,
      {
        action: 'tax.rule_set',
        targetType: 'tax_rule',
        targetId: rule.id,
        meta: { country, region: region ?? null, inclusive: rule.inclusive, components: toRule(rule).components, replaced: retired.count },
      },
      tx,
    );
    return rule;
  });
  return toRule(created);
}

/** Stops charging a rule's tax where it applied. Its history stays. */
export async function retireTaxRule(actor: AuditActor, id: string): Promise<TaxRuleRecord> {
  assertPlatformOperator(actor);
  const rule = await db.taxRule.findUnique({ where: { id }, include: WITH_COMPONENTS });
  if (!rule) throw notFound('Tax rule not found.');
  if (rule.retiredAt) throw conflict('This tax rule is already retired.');
  const saved = await db.$transaction(async (tx) => {
    const row = await tx.taxRule.update({ where: { id }, data: { retiredAt: now() }, include: WITH_COMPONENTS });
    await recordAuditLog(actor, { action: 'tax.rule_retired', targetType: 'tax_rule', targetId: id, meta: { country: rule.country, region: rule.region } }, tx);
    return row;
  });
  return toRule(saved);
}

export async function listTaxRules(query: { includeRetired?: boolean } = {}): Promise<TaxRuleRecord[]> {
  const rows = await db.taxRule.findMany({
    where: query.includeRetired ? {} : { retiredAt: null },
    include: WITH_COMPONENTS,
    orderBy: [{ country: 'asc' }, { region: 'asc' }, { createdAt: 'desc' }],
  });
  return rows.map(toRule);
}

/** The active rule for a buyer at `country` / `region`: the region's own, else the country's, else none. */
export async function taxRuleFor(country: string, region?: string | null): Promise<TaxRuleRecord | null> {
  const rows = await db.taxRule.findMany({
    where: { country, retiredAt: null, OR: [{ region: null }, ...(region ? [{ region }] : [])] },
    include: WITH_COMPONENTS,
  });
  const match = rows.find((r) => region && r.region === region) ?? rows.find((r) => r.region === null);
  return match ? toRule(match) : null;
}

/* ─── What an academy pays ─────────────────────────────────────────────── */

export interface Payable extends TaxedCharge {
  /** What is being paid for, in the words an invoice line would use. */
  purpose: 'new_subscription' | 'renewal' | 'plan_change';
  /** The rule the tax came from, or null when no tax applies at the billing address. */
  taxRuleId: string | null;
  /** The billing address the tax was decided by. */
  billedTo: { country: string; region?: string };
  /** A first purchase only: the plan version and cycle this price was taken from — what the invoice sells. */
  sale?: { planVersionId: string; cycle: BillingCycle };
}

/**
 * Taxes `amount` for the academy at its billing address. An academy must have a billing profile to be
 * charged: without an address there is no telling which tax applies.
 */
/**
 * What the academy pays for a net `amount`: taxed at its billing address. A plan change's preview (SAAS-015)
 * prices the same way as its invoice will.
 */
export async function payableForAmount(tenantId: string, amount: number, currency: string, purpose: Payable['purpose']): Promise<Payable> {
  return taxFor(tenantId, amount, currency, purpose);
}

async function taxFor(tenantId: string, amount: number, currency: string, purpose: Payable['purpose']): Promise<Payable> {
  const profile = await getBillingProfile(tenantId);
  if (!profile) throw conflict('Add the LMS’s billing address before it can be charged.');
  const rule = await runAsPlatform('looking up the tax rule for an academy’s address', () => taxRuleFor(profile.country, profile.region));
  const taxed = calculateTax(amount, currency, rule?.components ?? [], rule?.inclusive ?? false);
  return { ...taxed, purpose, taxRuleId: rule?.id ?? null, billedTo: { country: profile.country, ...(profile.region ? { region: profile.region } : {}) } };
}

/** What starting `planId` on `cycle` costs the academy now: the plan version's price, taxed. */
export async function payableForNewSubscription(tenantId: string, input: { planId: string; cycle: BillingCycle }): Promise<Payable> {
  const sale = await planForNewSubscription(input.planId, input.cycle);
  // The version priced is the version sold: the invoice records it, and the subscription gets it (SAAS-009).
  return { ...(await taxFor(tenantId, sale.amount, sale.version.currency, 'new_subscription')), sale: { planVersionId: sale.version.id, cycle: input.cycle } };
}

/** What the subscription's next period costs: its stored amount, taxed. */
export async function payableForRenewal(subscriptionId: string): Promise<Payable> {
  const sub = await loadSubscriptionRow(subscriptionId);
  // A downgrade scheduled for this boundary is what the next period costs (D10).
  const next = await nextPeriodTerms(sub);
  return taxFor(sub.tenantId, next.amount, next.currency, 'renewal');
}

/** What settling a plan-change quote costs: the charge fixed on the quote (SAAS-006), taxed. */
export async function payableForPlanChange(changeId: string): Promise<Payable> {
  const change = await db.planChange.findUnique({ where: { id: changeId } });
  if (!change) throw notFound('Plan change not found.');
  if (change.status !== 'pending_payment') throw conflict('This plan change is not waiting for a payment.');
  return taxFor(change.tenantId, change.charge, change.currency, 'plan_change');
}
