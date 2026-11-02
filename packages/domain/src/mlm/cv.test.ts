import { describe, expect, it } from 'vitest';
import type { MlmLeg } from './plan';
import { creditsAlongPath, cvOfSale, eligibleAtFor } from './cv';

describe('commissionable volume', () => {
  it('is a share of the net sale in basis points, rounded half-up', () => {
    expect(cvOfSale(10_000 * 100, 10_000)).toBe(10_000 * 100); // the whole ₹10,000
    expect(cvOfSale(10_000 * 100, 5000)).toBe(5_000 * 100);
    expect(cvOfSale(1, 5000)).toBe(1); // half a paisa rounds up
  });

  it('credits every ancestor in the leg the buyer sits under', () => {
    // X ─A─ Rahul ─A─ Rohan ─B─ Deep (the buyer, on Rohan's B).
    const legs: Record<string, MlmLeg> = { Rahul: 'A', Rohan: 'A', Deep: 'B' };
    const legOf = (id: string): MlmLeg | null => legs[id] ?? null;
    expect(creditsAlongPath(['X', 'Rahul', 'Rohan'], 'B', legOf)).toEqual([
      { ancestorId: 'X', leg: 'A' }, // Rahul is on X's A
      { ancestorId: 'Rahul', leg: 'A' }, // Rohan is on Rahul's A
      { ancestorId: 'Rohan', leg: 'B' }, // Deep is on Rohan's B
    ]);
    expect(creditsAlongPath([], null, legOf)).toEqual([]); // a root, or an unplaced buyer: nobody above
    expect(creditsAlongPath(['X'], null, legOf)).toEqual([]); // placed without a leg: nothing is credited blindly
  });

  it('dates eligibility from the sale plus the plan’s delay', () => {
    const paid = new Date('2026-11-01T00:00:00Z');
    expect(eligibleAtFor(paid, 0)).toEqual(paid);
    expect(eligibleAtFor(paid, 7).toISOString()).toBe('2026-11-08T00:00:00.000Z');
  });
});
