import type { ReactNode } from 'react';
import { useOutletContext, useSearchParams } from 'react-router-dom';
import { Field, Select } from '@/components/ui/Field/Field';
import type { Kpi, LearnerSegment, ReportFilters, ReportRange } from '@syniastrolms/domain';
import { LEARNER_SEGMENTS, REPORT_RANGES } from '@syniastrolms/domain';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatDate, formatDay, formatShortDate } from '@/lib/format';
import type { ChartDatum } from '@/components/charts/Charts';
import { Delta } from '@/components/data/KpiStrip';
import type { ReportContext, ReportPoint } from '@/services';
import { reportInstructor } from './reportScope';
import styles from './Reports.module.css';

export const RANGE_LABEL: Record<ReportRange, string> = { '30d': 'Last 30 days', '90d': 'Last 90 days', '6m': 'Last 6 months', '12m': 'Last 12 months' };
export const RANGE_SHORT: Record<ReportRange, string> = { '30d': '30 days', '90d': '90 days', '6m': '6 months', '12m': '12 months' };

export const SEGMENT_LABEL: Record<LearnerSegment, string> = {
  all: 'All learners',
  new: 'New learners',
  active: 'Active',
  'at-risk': 'At risk',
  inactive: 'Inactive',
  completers: 'Finished a course',
};

export const SEGMENT_DESCRIPTION: Record<LearnerSegment, string> = {
  all: 'Everyone studying in the period.',
  new: 'First enrolled in these courses during the period.',
  active: 'Studied in the last 10 days.',
  'at-risk': 'Quiet for 10 days or more with a course in progress.',
  inactive: 'Nothing opened for 45 days, or nothing in progress.',
  completers: 'Finished at least one course during the period.',
};

/** Filters live in the URL so a report can be shared or bookmarked as it looks. */
export function useReportFilters(): ReportFilters & { segment: LearnerSegment } {
  const [params] = useSearchParams();
  const workspace = useWorkspace();
  const range = params.get('range') as ReportRange | null;
  const segment = params.get('segment') as LearnerSegment | null;
  return {
    range: range && REPORT_RANGES.includes(range) ? range : '90d',
    categoryId: params.get('category') || undefined,
    courseId: params.get('course') || undefined,
    instructorId: reportInstructor(params, workspace),
    segment: segment && LEARNER_SEGMENTS.includes(segment) ? segment : 'all',
  };
}

export interface ReportsOutlet {
  /** The current query string, to keep filters on links between reports. */
  keep: string;
  resetFilters: () => void;
  filtered: boolean;
}

export const useReportsOutlet = () => useOutletContext<ReportsOutlet>();

/** The period picker on its own, for pages that don't show the full filter bar. */
export function PeriodSelect({ className }: { className?: string }) {
  const [params, setParams] = useSearchParams();
  const { range } = useReportFilters();
  return (
    <Field label="Period" hideLabel className={className}>
      <Select
        value={range}
        onChange={(e) => {
          const p = new URLSearchParams(params);
          if (e.target.value === '90d') p.delete('range');
          else p.set('range', e.target.value);
          setParams(p, { replace: true });
        }}
      >
        {REPORT_RANGES.map((r) => (
          <option key={r} value={r}>
            {RANGE_LABEL[r]}
          </option>
        ))}
      </Select>
    </Field>
  );
}

/** A cache key for a filter set. */
export const filterKey = (f: ReportFilters) => [f.range, f.categoryId ?? '', f.courseId ?? '', f.instructorId ?? '', f.segment ?? 'all'].join('|');

/** "16 Jun – 15 Sep 2026" */
export const periodText = (ctx: ReportContext) => `${formatShortDate(ctx.window.from)} – ${formatDate(ctx.window.to)}`;
export const previousText = (ctx: ReportContext) => `${formatShortDate(ctx.window.previousFrom)} – ${formatDate(ctx.window.previousTo)}`;

/** Chart points labelled for their period length. */
export function chartData(points: ReportPoint[]): ChartDatum[] {
  if (!points.length) return [];
  const days = Math.round((new Date(points[0].to).getTime() - new Date(points[0].from).getTime()) / 86_400_000);
  return points.map((p) => {
    const start = new Date(new Date(p.from).getTime() + 86_400_000).toISOString();
    return {
      label: days === 1 ? formatShortDate(p.to) : formatShortDate(start),
      detail:
        days === 1
          ? `${formatDay(p.to)}${p.partial ? ' (today so far)' : ''}`
          : days === 7
            ? `Week of ${formatShortDate(start)}${p.partial ? ' (so far)' : ''}`
            : `${formatShortDate(start)} – ${formatShortDate(p.to)}${p.partial ? ' (so far)' : ''}`,
      value: p.value,
    };
  });
}

/** "day", "week" or "four weeks" — the length of each chart period. */
export function bucketNoun(points: ReportPoint[]) {
  if (!points.length) return 'period';
  const days = Math.round((new Date(points[0].to).getTime() - new Date(points[0].from).getTime()) / 86_400_000);
  return days === 1 ? 'day' : days === 7 ? 'week' : 'four weeks';
}

export const pct = (n: number | null | undefined) => (n === null || n === undefined ? '—' : `${Math.round(n)}%`);
export const count = (n: number) => n.toLocaleString('en-IN');

/** Earlier data is missing when the previous period had nothing to measure. */
export const comparable = (k: Kpi) => !(k.previous === 0 && k.value !== 0);

/** A figure with its change against the previous period, for dense groups inside a section. */
export function Metric({
  label,
  value,
  kpi,
  good = 'up',
  absolute,
  hint,
  missingNote = 'Nothing to compare with',
}: {
  label: string;
  value: ReactNode;
  kpi: Kpi;
  good?: 'up' | 'down' | 'neutral';
  absolute?: boolean;
  hint?: ReactNode;
  missingNote?: string;
}) {
  return (
    <div className={styles.metric}>
      <dt className={styles.metricLabel}>{label}</dt>
      <dd className={styles.metricBody}>
        <span className={styles.metricValue}>{value}</span>
        {comparable(kpi) ? <Delta kpi={kpi} good={good} absolute={absolute} /> : <span className={styles.metricHint}>{missingNote}</span>}
        {hint && <span className={styles.metricHint}>{hint}</span>}
      </dd>
    </div>
  );
}

/** A titled block of a report. */
export function ReportSection({
  id,
  title,
  description,
  actions,
  children,
  className,
}: {
  id: string;
  title: string;
  description?: ReactNode;
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section className={`${styles.section} ${className ?? ''}`} aria-labelledby={id}>
      <header className={styles.sectionHead}>
        <div className={styles.sectionText}>
          <h2 id={id} className={styles.sectionTitle}>
            {title}
          </h2>
          {description && <p className={styles.sectionDescription}>{description}</p>}
        </div>
        {actions && <div className={styles.sectionActions}>{actions}</div>}
      </header>
      {children}
    </section>
  );
}

/** Builds a CSV file from rows and hands it to the browser to save. */
export function downloadCsv(filename: string, header: string[], rows: (string | number | null | undefined)[][]) {
  const cell = (v: string | number | null | undefined) => {
    const raw = v === null || v === undefined ? '' : String(v);
    // A name typed as `=HYPERLINK(…)` would run as a formula in Excel or Sheets: text that starts like one is kept as
    // text with a leading apostrophe. Numbers are written as numbers, so a negative one is never touched.
    const text = typeof v === 'string' && /^[=+\-@\t\r]/.test(raw) ? `'${raw}` : raw;
    return /[",\n]/.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
  };
  const csv = [header, ...rows].map((r) => r.map(cell).join(',')).join('\n');
  const url = URL.createObjectURL(new Blob([String.fromCharCode(0xfeff) + csv], { type: 'text/csv;charset=utf-8' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  window.setTimeout(() => URL.revokeObjectURL(url), 1000);
}
