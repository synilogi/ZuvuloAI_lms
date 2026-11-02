/**
 * Money, counted in the smallest unit of its currency.
 *
 * Every amount the platform stores, sends or adds up is a whole number of the currency's minor unit —
 * paise for INR, cents for USD — so ₹3,999 is 399900 and never 3999.00. Financial totals are sums
 * and products of integers, with rounding stated where a division happens, and never pass through a
 * fraction of a rupee (subscriptions.md §26). Converting to the major unit happens only at the edges:
 * parsing what a person typed, and formatting what a person reads.
 *
 * Nothing here knows a particular currency. How many minor-unit digits one has comes from the ISO
 * 4217 data the runtime already carries, so a second currency needs no change here (§28).
 */

/** A currency code in the ISO 4217 shape: three capital letters. */
const CURRENCY_PATTERN = /^[A-Z]{3}$/;

const digitsCache = new Map<string, number>();

let known: Set<string> | undefined;

/**
 * Whether `code` is a currency the runtime knows — its ISO 4217 list, not merely three capitals, so
 * "ZZZ" is refused. A runtime too old to list its currencies accepts any code in the ISO shape.
 */
export function isCurrencyCode(code: string): boolean {
  if (!CURRENCY_PATTERN.test(code)) return false;
  known ??= typeof Intl.supportedValuesOf === 'function' ? new Set(Intl.supportedValuesOf('currency')) : new Set();
  return known.size === 0 || known.has(code);
}

/** How many minor-unit digits a currency has: 2 for INR and USD, 0 for JPY, 3 for KWD. Throws for an unknown code. */
export function currencyDigits(currency: string): number {
  let digits = digitsCache.get(currency);
  if (digits === undefined) {
    if (!CURRENCY_PATTERN.test(currency)) throw new RangeError(`${currency} is not a currency code.`);
    digits = new Intl.NumberFormat('en', { style: 'currency', currency }).resolvedOptions().maximumFractionDigits ?? 2;
    digitsCache.set(currency, digits);
  }
  return digits;
}

/** How many minor units make one major unit: 100 paise to the rupee. */
export const minorPerMajor = (currency: string): number => 10 ** currencyDigits(currency);

/** A stored amount must be a whole number of minor units, small enough to add up exactly. */
export const isMinorAmount = (value: unknown): value is number => typeof value === 'number' && Number.isSafeInteger(value);

/**
 * Whole major units as minor units — `majorToMinor(3999, 'INR')` is 399900. For prices written in
 * code (fixtures, the seed); an amount a person typed goes through `parseMajorAmount` instead.
 */
export function majorToMinor(major: number, currency: string): number {
  if (!Number.isSafeInteger(major)) throw new RangeError('majorToMinor takes a whole number of major units.');
  const minor = major * minorPerMajor(currency);
  if (!Number.isSafeInteger(minor)) throw new RangeError('That amount is too large to hold exactly.');
  return minor;
}

/**
 * Reads an amount a person typed in the major unit — "3999", "3,999.50", "0.5" — as minor units,
 * exactly: the digits are joined as text, so nothing is multiplied as a floating-point number.
 * Returns `null` for anything that is not a non-negative amount in that currency, including one with
 * more decimal places than the currency has.
 */
export function parseMajorAmount(text: string, currency: string): number | null {
  const digits = currencyDigits(currency);
  const match = /^(\d+)(?:\.(\d*))?$/.exec(text.trim().replace(/[,\s]/g, ''));
  if (!match) return null;
  const fraction = match[2] ?? '';
  if (fraction.length > digits) return null;
  const minor = Number(match[1] + fraction.padEnd(digits, '0'));
  return Number.isSafeInteger(minor) ? minor : null;
}

/**
 * An amount as a number of major units, for what a person reads or edits: an input's value, a chart
 * axis. Never feed the result back into a total — sum the minor units instead.
 */
export const minorToMajor = (minor: number, currency: string): number => minor / minorPerMajor(currency);

const formatters = new Map<string, Intl.NumberFormat>();

function formatterFor(locale: string, currency: string, fractionDigits: number): Intl.NumberFormat {
  const key = `${locale}|${currency}|${fractionDigits}`;
  let fmt = formatters.get(key);
  if (!fmt) {
    fmt = new Intl.NumberFormat(locale, { style: 'currency', currency, minimumFractionDigits: fractionDigits, maximumFractionDigits: fractionDigits });
    formatters.set(key, fmt);
  }
  return fmt;
}

/**
 * An amount in minor units, written for a person: `formatMoney(399900, 'INR')` is "₹3,999", and
 * `formatMoney(399950, 'INR')` is "₹3,999.50". Whole amounts drop the decimals; any other amount shows
 * every digit the currency has, so a paisa is never rounded away in what is shown.
 */
export function formatMoney(minor: number, currency = 'INR', locale = 'en-IN'): string {
  const per = minorPerMajor(currency);
  const whole = minor % per === 0;
  return formatterFor(locale, currency, whole ? 0 : currencyDigits(currency)).format(minor / per);
}

/**
 * `numerator ÷ denominator` for money, rounded half up to a whole minor unit, in integers: the division
 * happens on BigInts, so no fraction of a paisa ever exists as a floating-point number. Refuses a
 * non-integer operand or a zero denominator.
 */
export function divideRounded(numerator: number | bigint, denominator: number | bigint): number {
  const n = BigInt(numerator);
  const d = BigInt(denominator);
  if (d === 0n) throw new RangeError('Cannot divide an amount by zero.');
  const sign = n < 0n !== d < 0n ? -1n : 1n;
  const [a, b] = [n < 0n ? -n : n, d < 0n ? -d : d];
  const result = sign * ((2n * a + b) / (2n * b));
  if (result > BigInt(Number.MAX_SAFE_INTEGER) || result < BigInt(Number.MIN_SAFE_INTEGER)) throw new RangeError('That amount is too large to hold exactly.');
  return Number(result);
}
