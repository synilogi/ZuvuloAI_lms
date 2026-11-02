import { describe, expect, it } from 'vitest';
import { addMonths, isDayKey, istKey, layoutOverlaps, minuteOfDay, monthWeeks, stepDate, viewRange, weekLabel } from './calendarDates';

describe('calendar dates', () => {
  it('reads IST dates and minutes', () => {
    expect(istKey('2026-09-15T19:00:00Z')).toBe('2026-09-16');
    expect(minuteOfDay('2026-09-15T19:30:00+05:30')).toBe(19 * 60 + 30);
    expect(isDayKey('2026-02-30')).toBe(false);
    expect(isDayKey('2026-09-15')).toBe(true);
  });

  it('builds Monday-first month grids that cover the whole month', () => {
    const weeks = monthWeeks('2026-09-15');
    expect(weeks[0][0]).toBe('2026-08-31');
    expect(weeks.at(-1)?.[6]).toBe('2026-10-04');
    expect(weeks).toHaveLength(5);
    expect(monthWeeks('2026-02-01')[0][0]).toBe('2026-01-26');
    expect(viewRange('week', '2026-09-15')).toEqual({ from: '2026-09-14', to: '2026-09-20' });
    expect(viewRange('list', '2026-09-15')).toEqual({ from: '2026-09-01', to: '2026-09-30' });
  });

  it('steps by month without overflowing short months', () => {
    expect(addMonths('2026-01-31', 1)).toBe('2026-02-28');
    expect(stepDate('month', '2026-12-15', 1)).toBe('2027-01-15');
    expect(stepDate('week', '2026-09-15', -1)).toBe('2026-09-08');
  });

  it('labels weeks across months and years', () => {
    expect(weekLabel('2026-09-15')).toBe('14 – 20 Sep 2026');
    expect(weekLabel('2026-10-01')).toBe('28 Sep – 4 Oct 2026');
    expect(weekLabel('2026-12-30')).toBe('28 Dec 2026 – 3 Jan 2027');
  });

  it('puts overlapping blocks side by side and leaves separate ones full width', () => {
    const placed = layoutOverlaps([
      { item: 'a', start: 60, end: 120 },
      { item: 'b', start: 90, end: 150 },
      { item: 'c', start: 100, end: 110 },
      { item: 'd', start: 200, end: 260 },
    ]);
    const by = Object.fromEntries(placed.map((p) => [p.item, [p.column, p.columns]]));
    expect(by).toEqual({ a: [0, 3], b: [1, 3], c: [2, 3], d: [0, 1] });
  });
});
