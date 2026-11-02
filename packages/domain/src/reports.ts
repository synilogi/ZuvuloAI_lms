import type { ID } from './catalog';

export type ReportRange = '30d' | '90d' | '6m' | '12m';

export const REPORT_RANGES: ReportRange[] = ['30d', '90d', '6m', '12m'];

export const REPORT_RANGE_DAYS: Record<ReportRange, number> = { '30d': 30, '90d': 91, '6m': 182, '12m': 364 };

/** Which learners a report counts. */
export type LearnerSegment = 'all' | 'new' | 'active' | 'at-risk' | 'inactive' | 'completers';

export const LEARNER_SEGMENTS: LearnerSegment[] = ['all', 'new', 'active', 'at-risk', 'inactive', 'completers'];

export interface ReportFilters {
  range: ReportRange;
  categoryId?: ID;
  courseId?: ID;
  instructorId?: ID;
  segment?: LearnerSegment;
}

const DAY = 86_400_000;

export interface ReportWindow {
  from: Date;
  to: Date;
  previousFrom: Date;
  previousTo: Date;
}

/** The period a report covers, ending now, and the equal period before it for comparison. */
export function reportWindow(range: ReportRange, now: Date): ReportWindow {
  const span = REPORT_RANGE_DAYS[range] * DAY;
  const to = now;
  const from = new Date(to.getTime() - span);
  return { from, to, previousFrom: new Date(from.getTime() - span), previousTo: from };
}

export interface ReportBucket {
  from: Date;
  to: Date;
  /** The newest bucket is still filling. */
  partial: boolean;
}

/** Chart periods for a range: days for 30 days, weeks up to six months, four-week months for a year. */
export function reportBuckets(range: ReportRange, now: Date): ReportBucket[] {
  const days = REPORT_RANGE_DAYS[range];
  const size = range === '30d' ? 1 : range === '12m' ? 28 : 7;
  const count = Math.round(days / size);
  return Array.from({ length: count }, (_, i) => {
    const to = new Date(now.getTime() - (count - 1 - i) * size * DAY);
    return { from: new Date(to.getTime() - size * DAY), to, partial: i === count - 1 };
  });
}

/** Share as a whole percentage; null when there is nothing to divide by. */
export const percentOf = (part: number, whole: number) => (whole > 0 ? Math.round((part / whole) * 100) : null);

/** Median of a list, or null when empty. */
export function median(values: number[]) {
  if (values.length === 0) return null;
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}
