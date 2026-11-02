/**
 * Tax on a charge (subscriptions.md §27), kept apart from the price. Nothing here knows a country: a
 * charge is taxed by whatever components the platform's configured rule for the buyer names — one
 * "GST" at 18%, a "CGST" and an "SGST" at 9% each, a "VAT" at 20%, or none. Which rule applies to
 * whom is data (the API's `TaxRule` table), never a condition in code.
 *
 * Rates are integers in basis points (1800 is 18.00%) and every amount is an integer of the currency's
 * minor unit; each division is `divideRounded`, so no figure passes through floating point.
 */

import { divideRounded } from './money';

/** One tax a rule levies, e.g. `{ code: 'CGST', label: 'Central GST', rateBps: 900 }`. */
export interface TaxComponent {
  code: string;
  label: string;
  /** Basis points: 100 is 1%, 1800 is 18%. 0–10000. */
  rateBps: number;
}

export interface TaxLine extends TaxComponent {
  amount: number;
}

export interface TaxedCharge {
  currency: string;
  /** The amount before tax. */
  net: number;
  lines: TaxLine[];
  tax: number;
  /** What is paid: `net + tax`, always. */
  gross: number;
  /** Whether the price already included the tax (the amount given was the gross). */
  inclusive: boolean;
}

const BPS = 10_000;

export function isTaxRate(rateBps: number): boolean {
  return Number.isInteger(rateBps) && rateBps >= 0 && rateBps <= BPS;
}

/**
 * Taxes `amount` (minor units) by `components`.
 *
 * Exclusive: `amount` is the net; each component's tax is `net × rate`, rounded half up per component.
 * Inclusive: `amount` is the gross; the net is `gross ÷ (1 + Σrates)`, rounded half up, and the tax on it
 * is split by component the same way — the last component takes any paisa of rounding, so `net + tax`
 * is exactly the gross that was quoted.
 *
 * With no components the charge is untaxed. Every figure is a whole number of minor units.
 */
export function calculateTax(amount: number, currency: string, components: readonly TaxComponent[], inclusive = false): TaxedCharge {
  if (!Number.isSafeInteger(amount) || amount < 0) throw new RangeError('Tax is calculated on a non-negative whole amount of minor units.');
  for (const c of components) if (!isTaxRate(c.rateBps)) throw new RangeError(`${c.code}: a tax rate is a whole number of basis points from 0 to 10000.`);
  const totalBps = components.reduce((sum, c) => sum + c.rateBps, 0);

  if (!inclusive) {
    const lines = components.map((c) => ({ ...c, amount: divideRounded(BigInt(amount) * BigInt(c.rateBps), BPS) }));
    const tax = lines.reduce((sum, l) => sum + l.amount, 0);
    return { currency, net: amount, lines, tax, gross: amount + tax, inclusive };
  }

  const net = divideRounded(BigInt(amount) * BigInt(BPS), BPS + totalBps);
  const tax = amount - net;
  const lines = components.map((c) => ({ ...c, amount: totalBps === 0 ? 0 : divideRounded(BigInt(tax) * BigInt(c.rateBps), totalBps) }));
  // Rounding each share can leave a paisa over or under: the last component settles it.
  const spread = lines.reduce((sum, l) => sum + l.amount, 0);
  if (lines.length) lines[lines.length - 1].amount += tax - spread;
  return { currency, net, lines, tax, gross: amount, inclusive };
}

/** A tax rule as the Super Admin sets it: the tax for a country, or a region of it. */
export interface TaxRuleInput {
  name: string;
  /** ISO 3166-1 alpha-2, e.g. `IN`. */
  country: string;
  /** A short region code, e.g. `KA`; none applies the rule to the whole country. */
  region?: string;
  /** Whether prices already include this tax. */
  inclusive?: boolean;
  components: TaxComponent[];
}

/**
 * The checks the billing API makes before it sets a rule, so the form can say what is wrong before it is
 * sent. The server checks again and is the authority.
 */
export function taxRuleIssues(input: TaxRuleInput): string[] {
  const issues: string[] = [];
  const region = input.region?.trim();
  if (input.name.trim().length < 2) issues.push('Name the tax, e.g. GST.');
  if (!/^[A-Za-z]{2}$/.test(input.country.trim())) issues.push('Choose the country by its two-letter code, e.g. IN.');
  if (region && !/^[A-Za-z0-9-]{1,10}$/.test(region)) issues.push('A region is a short code, e.g. KA.');
  if (input.components.length < 1 || input.components.length > 5) issues.push('A tax rule has between one and five components.');
  const codes = new Set<string>();
  for (const c of input.components) {
    const code = c.code.trim().toUpperCase();
    if (!/^[A-Z0-9_-]{1,16}$/.test(code)) issues.push('A component code is 1–16 letters, digits, hyphens or underscores.');
    else if (codes.has(code)) issues.push(`The component ${code} is listed twice.`);
    codes.add(code);
    if (!c.label.trim()) issues.push(`Give component ${code || 'each component'} a label.`);
    if (!isTaxRate(c.rateBps)) issues.push(`${code || 'Each component'}: a rate is from 0% to 100%, to at most two decimal places.`);
  }
  return issues;
}
