/** Presentation formatting. Academy times are shown in IST. */

const TZ = 'Asia/Kolkata';

export function formatDuration(totalMin: number): string {
  const min = Math.round(totalMin);
  if (min < 60) return `${min} min`;
  const h = Math.floor(min / 60);
  const m = min % 60;
  return m === 0 ? `${h}h` : `${h}h ${String(m).padStart(2, '0')}m`;
}

export function formatClock(totalSec: number): string {
  const s = Math.max(0, Math.round(totalSec));
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = String(s % 60).padStart(2, '0');
  return h > 0 ? `${h}:${String(m).padStart(2, '0')}:${sec}` : `${m}:${sec}`;
}

const dayFmt = new Intl.DateTimeFormat('en-IN', { weekday: 'short', day: 'numeric', month: 'short', timeZone: TZ });
const dateFmt = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short', year: 'numeric', timeZone: TZ });
const timeFmt = new Intl.DateTimeFormat('en-IN', { hour: 'numeric', minute: '2-digit', hour12: true, timeZone: TZ });
const partsFmt = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short', weekday: 'short', timeZone: TZ });

/** "Thu, 17 Sep" */
/** Newer ICU data writes "Sept"; the product uses three-letter months throughout. */
const month3 = (text: string) => text.replace(/\bSept\b/, 'Sep');

export const formatDay = (iso: string) => month3(dayFmt.format(new Date(iso)));
/** "17 Sep 2026" */
export const formatDate = (iso: string) => month3(dateFmt.format(new Date(iso)));
/** "7:00 pm" → "7:00 PM" */
export const formatTime = (iso: string) => timeFmt.format(new Date(iso)).toUpperCase();

export function formatTimeRange(startIso: string, durationMin: number) {
  const end = new Date(new Date(startIso).getTime() + durationMin * 60_000).toISOString();
  return `${formatTime(startIso)} – ${formatTime(end)} IST`;
}

/** { day: "17", month: "Sep", weekday: "Thu" } for date blocks. */
export function dateParts(iso: string) {
  const parts = partsFmt.formatToParts(new Date(iso));
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? '';
  return { day: get('day'), month: month3(get('month')), weekday: get('weekday') };
}

const rtf = new Intl.RelativeTimeFormat('en', { numeric: 'auto' });

/** "in 12 minutes", "in 2 days", "yesterday" */
export function formatRelative(iso: string, now: Date): string {
  const diffMs = new Date(iso).getTime() - now.getTime();
  const abs = Math.abs(diffMs);
  const min = 60_000;
  if (abs < min) return 'now';
  if (abs < 60 * min) return rtf.format(Math.round(diffMs / min), 'minute');
  if (abs < 24 * 60 * min) return rtf.format(Math.round(diffMs / (60 * min)), 'hour');
  return rtf.format(Math.round(diffMs / (24 * 60 * min)), 'day');
}

const inr = new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 });
export const formatINR = (amount: number) => inr.format(amount);

const compact = new Intl.NumberFormat('en-IN');
export const formatCount = (n: number) => compact.format(n);

export const initials = (name: string) =>
  name
    .replace(/^(Dr\.|Acharya|Pt\.)\s+/i, '')
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => w[0])
    .join('')
    .toUpperCase();

export const pad2 = (n: number) => String(n).padStart(2, '0');

const ROMAN = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
export const roman = (n: number) => ROMAN[n - 1] ?? String(n);

const longDayFmt = new Intl.DateTimeFormat('en-IN', { weekday: 'long', day: 'numeric', month: 'long', timeZone: TZ });
/** "Tuesday, 15 September" */
export const formatLongDay = (date: Date | string) => longDayFmt.format(new Date(date));

const shortDateFmt = new Intl.DateTimeFormat('en-IN', { day: 'numeric', month: 'short', timeZone: TZ });
/** "15 Sep" */
export const formatShortDate = (date: Date | string) => month3(shortDateFmt.format(new Date(date)));

const hourFmt = new Intl.DateTimeFormat('en-IN', { hour: 'numeric', hourCycle: 'h23', timeZone: TZ });
/** "Good morning" / "Good afternoon" / "Good evening" on the academy clock. */
export function greeting(now: Date) {
  const hour = Number(hourFmt.format(now));
  return hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
}

/** "1 learner" / "3 learners" */
export const plural = (n: number, one: string, many = `${one}s`) => `${n.toLocaleString('en-IN')} ${n === 1 ? one : many}`;

const momentFmt = new Intl.DateTimeFormat('en-IN', {
  weekday: 'short',
  day: 'numeric',
  month: 'short',
  hour: 'numeric',
  minute: '2-digit',
  hour12: true,
  timeZone: TZ,
  timeZoneName: 'short',
});

/**
 * A moment a learner has to act by (a quiz opening or closing, results coming out), in the academy's IST with the zone
 * named — "Sun, 1 Nov, 10:00 AM IST" — as live classes are shown.
 */
export const formatMoment = (iso: string) => month3(momentFmt.format(new Date(iso))).replace(/\b(am|pm)\b/, (m) => m.toUpperCase());
