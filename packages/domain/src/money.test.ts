import { describe, expect, it } from 'vitest';
import { currencyDigits, formatMoney, isCurrencyCode, isMinorAmount, majorToMinor, minorToMajor, parseMajorAmount } from './money';

describe('minor units', () => {
  it('knows how many digits each currency has, from the runtime rather than a table', () => {
    expect(currencyDigits('INR')).toBe(2);
    expect(currencyDigits('USD')).toBe(2);
    expect(currencyDigits('JPY')).toBe(0);
    expect(currencyDigits('KWD')).toBe(3);
    expect(() => currencyDigits('rupees')).toThrow();
  });

  it('recognises a currency code only in the ISO shape', () => {
    expect(isCurrencyCode('INR')).toBe(true);
    for (const code of ['', 'inr', 'IN', 'INRS', '₹']) expect(isCurrencyCode(code), code).toBe(false);
  });

  it('holds only whole, exactly representable amounts', () => {
    expect(isMinorAmount(399900)).toBe(true);
    expect(isMinorAmount(0)).toBe(true);
    for (const value of [3999.5, Number.NaN, Number.POSITIVE_INFINITY, 2 ** 53, '399900', null]) expect(isMinorAmount(value)).toBe(false);
  });

  it('converts whole major units written in code', () => {
    expect(majorToMinor(3999, 'INR')).toBe(399900);
    expect(majorToMinor(3999, 'JPY')).toBe(3999);
    expect(() => majorToMinor(39.99, 'INR')).toThrow();
  });
});

describe('parseMajorAmount', () => {
  it('reads what a person types, exactly', () => {
    expect(parseMajorAmount('3999', 'INR')).toBe(399900);
    expect(parseMajorAmount(' 3,999.5 ', 'INR')).toBe(399950);
    expect(parseMajorAmount('0.07', 'INR')).toBe(7);
    // 1.15 * 100 is 114.99999999999999 as a float; joined as text it is exactly 115.
    expect(parseMajorAmount('1.15', 'INR')).toBe(115);
  });

  it('refuses what is not an amount in that currency', () => {
    for (const text of ['', '-5', 'abc', '1e3', '12.345', '1.2.3']) expect(parseMajorAmount(text, 'INR'), text).toBeNull();
    expect(parseMajorAmount('12.5', 'JPY')).toBeNull();
  });
});

describe('formatMoney', () => {
  it('writes a whole amount without decimals, in the Indian grouping', () => {
    expect(formatMoney(24999000)).toBe('₹2,49,990');
    expect(formatMoney(0)).toBe('₹0');
  });

  it('never rounds a paisa away', () => {
    expect(formatMoney(399950)).toBe('₹3,999.50');
    expect(formatMoney(1)).toBe('₹0.01');
  });

  it('follows the currency it is given', () => {
    expect(formatMoney(120000, 'USD')).toContain('1,200');
    expect(formatMoney(1200, 'JPY')).toContain('1,200');
  });

  it('reads back as a major-unit number for inputs and axes', () => {
    expect(minorToMajor(399950, 'INR')).toBe(3999.5);
  });
});
