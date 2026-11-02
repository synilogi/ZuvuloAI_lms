/**
 * Calendar arithmetic on IST dates written as YYYY-MM-DD keys. India has no daylight saving,
 * so a key maps to one fixed UTC day and date maths can run in UTC without drift.
 */

export type CalendarView = 'month' | 'week' | 'list';

const IST_MS = 330 * 60_000;
const utc = (key: string) => new Date(`${key}T00:00:00Z`);
const keyOf = (d: Date) => d.toISOString().slice(0, 10);

/** The IST date of a moment. */
export const istKey = (at: Date | string) => keyOf(new Date(new Date(at).getTime() + IST_MS));

export const isDayKey = (value: string | null | undefined): value is string =>
  Boolean(value && /^\d{4}-\d{2}-\d{2}$/.test(value) && !Number.isNaN(utc(value).getTime()) && keyOf(utc(value)) === value);

export function addDays(key: string, days: number) {
  const d = utc(key);
  d.setUTCDate(d.getUTCDate() + days);
  return keyOf(d);
}

/** Monday is the first day of the week. */
export const weekdayIndex = (key: string) => (utc(key).getUTCDay() + 6) % 7;
export const startOfWeek = (key: string) => addDays(key, -weekdayIndex(key));
export const startOfMonth = (key: string) => `${key.slice(0, 7)}-01`;
export const sameMonth = (a: string, b: string) => a.slice(0, 7) === b.slice(0, 7);

export function endOfMonth(key: string) {
  const d = utc(startOfMonth(key));
  return keyOf(new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)));
}

/** Same day of the month, clamped to the month's length: 31 Jan + 1 month → 28 Feb. */
export function addMonths(key: string, months: number) {
  const d = utc(key);
  const target = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + months, 1));
  const last = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate();
  target.setUTCDate(Math.min(d.getUTCDate(), last));
  return keyOf(target);
}

/** Whole weeks covering the month, Monday to Sunday. */
export function monthWeeks(key: string): string[][] {
  const last = endOfMonth(key);
  const weeks: string[][] = [];
  let cursor = startOfWeek(startOfMonth(key));
  while (cursor <= last) {
    weeks.push(Array.from({ length: 7 }, (_, i) => addDays(cursor, i)));
    cursor = addDays(cursor, 7);
  }
  return weeks;
}

export const weekDays = (key: string) => Array.from({ length: 7 }, (_, i) => addDays(startOfWeek(key), i));

/** The dates a view loads events for. */
export function viewRange(view: CalendarView, key: string) {
  if (view === 'week') return { from: startOfWeek(key), to: addDays(startOfWeek(key), 6) };
  if (view === 'list') return { from: startOfMonth(key), to: endOfMonth(key) };
  const weeks = monthWeeks(key);
  return { from: weeks[0][0], to: weeks[weeks.length - 1][6] };
}

/** Where prev / next go from a date in a view. */
export const stepDate = (view: CalendarView, key: string, direction: 1 | -1) => (view === 'week' ? addDays(key, 7 * direction) : addMonths(key, direction));

/** Minutes since IST midnight. */
export function minuteOfDay(at: string) {
  const d = new Date(new Date(at).getTime() + IST_MS);
  return d.getUTCHours() * 60 + d.getUTCMinutes();
}

const monthFmt = new Intl.DateTimeFormat('en-IN', { month: 'long', year: 'numeric', timeZone: 'UTC' });
const dayMonthFmt = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short', timeZone: 'UTC' });
const weekdayFmt = new Intl.DateTimeFormat('en-IN', { weekday: 'short', timeZone: 'UTC' });
const longFmt = new Intl.DateTimeFormat('en-IN', { weekday: 'long', day: 'numeric', month: 'long', timeZone: 'UTC' });
const month3 = (text: string) => text.replace(/\bSept\b/, 'Sep');

/** "September 2026" */
export const monthLabel = (key: string) => monthFmt.format(utc(key));
/** "Tue" */
export const weekdayLabel = (key: string) => weekdayFmt.format(utc(key));
/** "Tuesday, 15 September" */
export const longDayLabel = (key: string) => longFmt.format(utc(key));

/** "14 – 20 Sep 2026", "28 Sep – 4 Oct 2026", "28 Dec 2026 – 3 Jan 2027" */
export function weekLabel(key: string) {
  const days = weekDays(key);
  const [first, last] = [days[0], days[6]];
  const year = (k: string) => k.slice(0, 4);
  if (year(first) !== year(last)) return `${month3(dayMonthFmt.format(utc(first)))} ${year(first)} – ${month3(dayMonthFmt.format(utc(last)))} ${year(last)}`;
  if (sameMonth(first, last)) return `${Number(first.slice(8))} – ${month3(dayMonthFmt.format(utc(last)))} ${year(last)}`;
  return `${month3(dayMonthFmt.format(utc(first)))} – ${month3(dayMonthFmt.format(utc(last)))} ${year(last)}`;
}

export interface Placed<T> {
  item: T;
  start: number;
  end: number;
  column: number;
  columns: number;
}

/** Lays out overlapping blocks side by side: each cluster of overlaps shares its width equally. */
export function layoutOverlaps<T>(items: { item: T; start: number; end: number }[]): Placed<T>[] {
  const sorted = [...items].sort((a, b) => a.start - b.start || b.end - a.end);
  const placed: Placed<T>[] = [];
  let cluster: Placed<T>[] = [];
  let clusterEnd = -Infinity;
  const close = () => {
    const columns = Math.max(1, ...cluster.map((p) => p.column + 1));
    for (const p of cluster) p.columns = columns;
    cluster = [];
  };
  for (const entry of sorted) {
    if (entry.start >= clusterEnd && cluster.length) close();
    const taken = new Set(cluster.filter((p) => p.end > entry.start).map((p) => p.column));
    let column = 0;
    while (taken.has(column)) column += 1;
    const p = { ...entry, column, columns: 1 };
    cluster.push(p);
    placed.push(p);
    clusterEnd = Math.max(clusterEnd, entry.end);
  }
  if (cluster.length) close();
  return placed;
}
