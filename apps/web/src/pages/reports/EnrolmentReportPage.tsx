import { DownloadSimple } from '@phosphor-icons/react';
import { BarList } from '@/components/charts/BarList';
import { ColumnChart, TrendChart } from '@/components/charts/Charts';
import { KpiStrip, type KpiItem } from '@/components/data/KpiStrip';
import { Button } from '@/components/ui/Button/Button';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type EnrolmentReport } from '@/services';
import { SOURCE } from '../students/studentMeta';
import { NoReportData, ReportSkeleton } from './ReportsOverviewPage';
import {
  bucketNoun,
  chartData,
  count,
  downloadCsv,
  filterKey,
  pct,
  periodText,
  previousText,
  ReportSection,
  SEGMENT_LABEL,
  useReportFilters,
  useReportsOutlet,
} from './reportMeta';
import styles from './Reports.module.css';

export default function EnrolmentReportPage() {
  const filters = useReportFilters();
  const { filtered, resetFilters } = useReportsOutlet();
  usePageCrumbs([{ label: 'Enrolment and completion' }]);
  const query = useAsync(`report-enrolments:${filterKey(filters)}`, () => services.reports.enrolments(filters));
  const data = query.data;

  if (query.status === 'error' && !data) {
    return (
      <StateMessage
        kind="error"
        title="The enrolment report didn’t load"
        actions={
          <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
            Try again
          </Button>
        }
      >
        {query.error.message}
      </StateMessage>
    );
  }
  if (!data) return <ReportSkeleton />;
  if (data.courseCount === 0 || data.kpis.enrollments.value + data.kpis.completions.value + data.cohorts.reduce((n, c) => n + c.enrolled, 0) === 0) {
    return <NoReportData filtered={filtered} onReset={resetFilters} />;
  }
  return <Enrolments data={data} busy={query.status === 'loading'} segment={SEGMENT_LABEL[filters.segment]} range={filters.range} />;
}

/** Shade for a completion share: one hue, deeper as more finished. */
const heat = (value: number | null) =>
  value === null ? undefined : `color-mix(in srgb, var(--accent) ${Math.round(6 + (value / 100) * 40)}%, var(--surface))`;

function Enrolments({ data, busy, segment, range }: { data: EnrolmentReport; busy: boolean; segment: string; range: string }) {
  const k = data.kpis;
  const vs = `vs ${previousText(data)}`;
  const kpis: KpiItem[] = [
    { id: 'enrollments', label: 'Enrolments', kpi: k.enrollments, value: count(k.enrollments.value), period: vs },
    { id: 'completions', label: 'Completions', kpi: k.completions, value: count(k.completions.value), period: vs },
    {
      id: 'rate',
      label: 'Completion rate',
      kpi: k.completionRate,
      value: pct(k.completionRate.value),
      period: vs,
      note: 'Among enrolments at least 60 days old',
    },
    {
      id: 'self',
      label: 'Enrolled themselves',
      kpi: k.selfShare,
      value: pct(k.selfShare.value),
      good: 'neutral',
      period: vs,
      note: 'The rest are cohort places, admin enrolments and scholarships',
    },
  ];
  const noun = bucketNoun(data.series.enrollments);
  const enrolChart = chartData(data.series.enrollments);
  const completeChart = chartData(data.series.completions);

  const exportCsv = () =>
    downloadCsv(
      `enrolment-completion-${range}.csv`,
      ['Intake', 'Enrolled', 'Finished within 30 days %', 'Finished within 60 days %', 'Finished within 90 days %', 'Finished to date %'],
      data.cohorts.map((c) => [c.month, c.enrolled, c.within30, c.within60, c.within90, c.toDate]),
    );

  return (
    <div className={styles.report} aria-busy={busy || undefined}>
      <p className={styles.periodLine}>
        {periodText(data)} · {segment.toLowerCase()} · {count(data.courseCount)} {data.courseCount === 1 ? 'course' : 'courses'}
      </p>
      <KpiStrip label="Enrolment figures" items={kpis} />

      <div className={styles.twoColumns}>
        <ReportSection id="enrol-trend" title="Enrolments" description={`Per ${noun}. The latest period is still filling.`}>
          <TrendChart
            data={enrolChart}
            label="Enrolments over time"
            unit="enrolments"
            height={210}
            partialIndex={enrolChart.length - 1}
            partialNote="Still filling"
          />
        </ReportSection>
        <ReportSection id="complete-trend" title="Completions" description={`Per ${noun}. The latest period is still filling.`}>
          <ColumnChart
            data={completeChart}
            label="Completions over time"
            unit="completions"
            height={210}
            partialIndex={completeChart.length - 1}
            partialNote="Still filling"
          />
        </ReportSection>
      </div>

      <div className={styles.twoColumns}>
        <ReportSection id="sources" title="How learners enrolled" description="Enrolments in the period, with each route’s completion rate.">
          <BarList
            label="Enrolments by route"
            items={data.sources.map((s) => ({
              key: s.source,
              label: SOURCE[s.source],
              value: s.enrollments,
              display: `${count(s.enrollments)} · ${s.share}%`,
              note: `${s.completionRate}% finish`,
            }))}
          />
        </ReportSection>
        <ReportSection id="enrol-categories" title="By category" description={`Compared with ${previousText(data)}.`}>
          <div className={styles.tableScroll}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th scope="col">Category</th>
                  <th scope="col" className={styles.num}>
                    Enrolments
                  </th>
                  <th scope="col" className={styles.num}>
                    Change
                  </th>
                  <th scope="col" className={styles.num}>
                    Completion
                  </th>
                </tr>
              </thead>
              <tbody>
                {data.categories.map((c) => {
                  const diff = c.enrollments - c.previousEnrollments;
                  return (
                    <tr key={c.categoryId}>
                      <th scope="row">{c.title}</th>
                      <td className={styles.num}>{count(c.enrollments)}</td>
                      <td className={styles.num}>
                        <span className={diff > 0 ? styles.up : diff < 0 ? styles.down : styles.flat}>
                          {diff === 0 ? '0' : `${diff > 0 ? '+' : '−'}${count(Math.abs(diff))}`}
                        </span>
                      </td>
                      <td className={styles.num}>{c.completionRate}%</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </ReportSection>
      </div>

      <ReportSection
        id="cohorts"
        title="How quickly each intake finishes"
        description="Learners who enrolled in each month, and the share who finished within 30, 60 and 90 days. A dash means not enough time has passed."
        actions={
          <Button size="sm" iconStart={<DownloadSimple size={15} />} onClick={exportCsv}>
            Export CSV
          </Button>
        }
      >
        <div className={styles.tableScroll}>
          <table className={`${styles.table} ${styles.cohortTable}`}>
            <thead>
              <tr>
                <th scope="col">Intake</th>
                <th scope="col" className={styles.num}>
                  Enrolled
                </th>
                <th scope="col" className={styles.num}>
                  Within 30 days
                </th>
                <th scope="col" className={styles.num}>
                  Within 60 days
                </th>
                <th scope="col" className={styles.num}>
                  Within 90 days
                </th>
                <th scope="col" className={styles.num}>
                  To date
                </th>
              </tr>
            </thead>
            <tbody>
              {data.cohorts.map((c) => (
                <tr key={c.month}>
                  <th scope="row">{c.month}</th>
                  <td className={styles.num}>{count(c.enrolled)}</td>
                  {[c.within30, c.within60, c.within90, c.toDate].map((v, i) => (
                    <td key={i} className={`${styles.num} ${styles.heatCell}`} style={{ background: heat(v) }}>
                      {v === null ? <span className={styles.cellMeta}>—</span> : `${v}%`}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </ReportSection>
    </div>
  );
}
