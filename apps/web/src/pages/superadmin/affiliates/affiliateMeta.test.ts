import { describe, expect, it } from 'vitest';
import { compactCv, compactMoney, cvText, fieldId, memberWithCode, parseSignedCv, percentOfBps } from './affiliateMeta';

describe('affiliate plan formatting', () => {
  it('reads basis points as percentages', () => {
    expect(percentOfBps(1000)).toBe('10%');
    expect(percentOfBps(1250)).toBe('12.5%');
    expect(percentOfBps(10_000)).toBe('100%');
    expect(percentOfBps(Number.NaN)).toBe('—%');
  });

  it('writes large rupee amounts the way the plan reads them', () => {
    expect(compactMoney(5_000 * 100)).toBe('₹5,000');
    expect(compactMoney(7_50_000 * 100)).toBe('₹7.5 L');
    expect(compactMoney(1_00_000 * 100)).toBe('₹1 L');
    expect(compactMoney(1_20_00_000 * 100)).toBe('₹1.2 Cr');
    expect(compactMoney(500_00_00_000 * 100)).toBe('₹500 Cr');
    expect(compactMoney(Number.NaN)).toBe('—');
  });

  it('writes CV as CV, never as rupees', () => {
    expect(cvText(149_900)).toBe('1,499 CV');
    expect(cvText(50)).toBe('0.5 CV');
    expect(compactCv(5_000 * 100)).toBe('5,000 CV');
    expect(compactCv(7_50_000 * 100)).toBe('7.5 L CV');
    expect(compactCv(500_00_00_000 * 100)).toBe('500 Cr CV');
    expect(compactCv(Number.NaN)).toBe('—');
  });

  it('reads a signed correction typed by a person, refusing what is not one', () => {
    expect(parseSignedCv('500')).toBe(50_000);
    expect(parseSignedCv('+1,250.5')).toBe(125_050);
    expect(parseSignedCv('-20')).toBe(-2_000);
    expect(parseSignedCv('−20')).toBe(-2_000);
    expect(parseSignedCv(' -.5 ')).toBe(-50);
    for (const bad of ['', '0', '0.00', 'abc', '1.234', '1e5', '--4', '12-']) expect(parseSignedCv(bad), bad).toBeUndefined();
  });

  it('finds only the member whose code matches exactly, however it was typed', () => {
    const rows = [{ code: 'ABCD2345' }, { code: 'ABCD2346' }];
    expect(memberWithCode(rows, 'abcd-2346')).toBe(rows[1]);
    expect(memberWithCode(rows, 'ABCD')).toBeUndefined();
  });

  it('names a DOM id for every validation field, nested ones included', () => {
    expect(fieldId('matchingRateBps')).toBe('plan-matchingRateBps');
    expect(fieldId('tiers.3.groupCv')).toBe('plan-tiers-3-groupCv');
  });
});
