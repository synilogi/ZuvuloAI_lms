import { describe, expect, it } from 'vitest';
import { divideRounded } from './money';
import { calculateTax, taxRuleIssues } from './tax';

const GST = [{ code: 'GST', label: 'GST', rateBps: 1800 }];
const SPLIT = [
  { code: 'CGST', label: 'Central GST', rateBps: 900 },
  { code: 'SGST', label: 'State GST', rateBps: 900 },
];

describe('divideRounded — money division in integers', () => {
  it('rounds half up, and handles signs', () => {
    expect(divideRounded(3999000, 12)).toBe(333250);
    expect(divideRounded(7, 2)).toBe(4);
    expect(divideRounded(5, 3)).toBe(2);
    expect(divideRounded(4, 3)).toBe(1);
    expect(divideRounded(-7, 2)).toBe(-4);
    expect(divideRounded(10n ** 15n, 3)).toBe(333_333_333_333_333);
  });

  it('refuses a zero divisor, a fraction and an amount too large to hold', () => {
    expect(() => divideRounded(1, 0)).toThrow();
    expect(() => divideRounded(1.5, 2)).toThrow();
    expect(() => divideRounded(10n ** 20n, 1)).toThrow();
  });
});

describe('calculateTax — exclusive', () => {
  it('adds each component to the net', () => {
    expect(calculateTax(399900, 'INR', GST)).toEqual({
      currency: 'INR',
      net: 399900,
      lines: [{ ...GST[0], amount: 71982 }],
      tax: 71982,
      gross: 471882,
      inclusive: false,
    });
    const split = calculateTax(399900, 'INR', SPLIT);
    expect(split.lines.map((l) => l.amount)).toEqual([35991, 35991]);
    expect(split).toMatchObject({ tax: 71982, gross: 471882 });
  });

  it('rounds each component to a whole paisa, half up', () => {
    // 18% of 149951 is 26991.18 → 26991; 9% of 149951 is 13495.59 → 13496, twice.
    expect(calculateTax(149951, 'INR', GST).tax).toBe(26991);
    expect(calculateTax(149951, 'INR', SPLIT).lines.map((l) => l.amount)).toEqual([13496, 13496]);
    // 18% of 25 is 4.5 → 5.
    expect(calculateTax(25, 'INR', GST).tax).toBe(5);
  });
});

describe('calculateTax — inclusive', () => {
  it('takes the tax out of a gross price, and adds back to exactly that price', () => {
    const t = calculateTax(471882, 'INR', GST, true);
    expect(t).toMatchObject({ net: 399900, tax: 71982, gross: 471882, inclusive: true });
    for (const gross of [1, 99, 100000, 399900, 399999, 24999000]) {
      for (const components of [GST, SPLIT]) {
        const r = calculateTax(gross, 'INR', components, true);
        expect(r.net + r.tax, `${gross}`).toBe(gross);
        expect(
          r.lines.reduce((s, l) => s + l.amount, 0),
          `${gross}`,
        ).toBe(r.tax);
      }
    }
  });

  it('gives the rounding paisa to the last component, never losing or inventing one', () => {
    const r = calculateTax(100001, 'INR', SPLIT, true);
    // net = 100001 ÷ 1.18 = 84746.61 → 84747; tax 15254, split 7627 + 7627.
    expect(r).toMatchObject({ net: 84747, tax: 15254 });
    expect(r.lines.map((l) => l.amount)).toEqual([7627, 7627]);
    const odd = calculateTax(
      100000,
      'INR',
      [
        { code: 'A', label: 'A', rateBps: 700 },
        { code: 'B', label: 'B', rateBps: 1100 },
      ],
      true,
    );
    expect(odd.lines[0].amount + odd.lines[1].amount).toBe(odd.tax);
  });
});

describe('calculateTax — whatever the rule says, in any currency', () => {
  it('leaves an untaxed charge untouched', () => {
    expect(calculateTax(399900, 'INR', [])).toMatchObject({ net: 399900, tax: 0, gross: 399900, lines: [] });
    expect(calculateTax(399900, 'INR', [], true)).toMatchObject({ net: 399900, tax: 0, gross: 399900 });
  });

  it('works in a currency without minor units, and in one with two', () => {
    expect(calculateTax(10000, 'JPY', [{ code: 'JCT', label: 'Consumption tax', rateBps: 1000 }])).toMatchObject({ currency: 'JPY', tax: 1000, gross: 11000 });
    expect(calculateTax(4999, 'USD', [{ code: 'VAT', label: 'VAT', rateBps: 2000 }])).toMatchObject({ tax: 1000, gross: 5999 });
  });

  it('refuses a fraction of a paisa, a negative amount and a rate outside 0–100%', () => {
    expect(() => calculateTax(10.5, 'INR', GST)).toThrow();
    expect(() => calculateTax(-1, 'INR', GST)).toThrow();
    expect(() => calculateTax(100, 'INR', [{ code: 'X', label: 'X', rateBps: 18.5 }])).toThrow();
    expect(() => calculateTax(100, 'INR', [{ code: 'X', label: 'X', rateBps: 10001 }])).toThrow();
  });

  it('keeps every figure an integer, and gross = net + tax, over many amounts', () => {
    for (let amount = 0; amount < 5000; amount += 7) {
      for (const inclusive of [false, true]) {
        const r = calculateTax(amount, 'INR', SPLIT, inclusive);
        for (const figure of [r.net, r.tax, r.gross, ...r.lines.map((l) => l.amount)]) expect(Number.isSafeInteger(figure)).toBe(true);
        expect(r.gross).toBe(r.net + r.tax);
      }
    }
  });
});

describe('taxRuleIssues — the server’s checks, for the form', () => {
  const rule = { name: 'GST', country: 'IN', components: SPLIT };

  it('accepts a named rule for a country with distinct, rated components', () => {
    expect(taxRuleIssues(rule)).toEqual([]);
    expect(taxRuleIssues({ ...rule, region: 'KA', inclusive: true })).toEqual([]);
  });

  it('refuses a missing name, a country that is not a code, and a long region', () => {
    expect(taxRuleIssues({ ...rule, name: ' ' })).toContain('Name the tax, e.g. GST.');
    expect(taxRuleIssues({ ...rule, country: 'India' })).toContain('Choose the country by its two-letter code, e.g. IN.');
    expect(taxRuleIssues({ ...rule, region: 'KARNATAKA-STATE' })).toContain('A region is a short code, e.g. KA.');
  });

  it('refuses no components, a code listed twice, and a rate that is not whole basis points', () => {
    expect(taxRuleIssues({ ...rule, components: [] })).toContain('A tax rule has between one and five components.');
    expect(taxRuleIssues({ ...rule, components: [...GST, ...GST] })).toContain('The component GST is listed twice.');
    expect(taxRuleIssues({ ...rule, components: [{ code: 'GST', label: 'GST', rateBps: 18.5 }] }).length).toBe(1);
    expect(taxRuleIssues({ ...rule, components: [{ code: 'GST', label: 'GST', rateBps: 10001 }] }).length).toBe(1);
  });
});
