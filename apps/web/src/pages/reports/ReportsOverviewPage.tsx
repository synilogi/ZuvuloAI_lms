import { useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, ChartLineUp, MagnifyingGlass } from '@phosphor-icons/react';
import { BarList } from '@/components/charts/BarList';
import { ColumnChart, Sparkline, TrendChart } from '@/components/charts/Charts';
import { KpiStrip, type KpiItem } from '@/components/data/KpiStrip';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { Meter } from '@/components/lms/progress/Meters';
import { useAsync } from '@/hooks/useAsync';
import { useWorkspace } from '@/hooks/useWorkspace';
import { services, type CourseReportRow, type ReportOverview } from '@/services';
import {
  bucketNoun,
  chartData,
  count,
  filterKey,
  Metric,
  pct,
  periodText,
  previousText,
  RANGE_SHORT,
  ReportSection,
  useReportFilters,
  useReportsOutlet,
} from './reportMeta';
import styles from './Reports.module.css';

type Measure = 'enrollments' | 'completions' | 'activeLearners';
const MEASURE: Record<Measure, { label: string; unit: string }> = {
  enrollments: { label: 'Enrolments', unit: 'enrolments' },
  completions: { label: 'Completions', unit: 'completions' },
  activeLearners: { label: 'Active learners', unit: 'learners studying' },
};

export default function ReportsOverviewPage() {
  const filters = useReportFilters();
  const { keep, filtered, resetFilters } = useReportsOutlet();
  const query = useAsync(`report-overview:${filterKey({ ...filters, segment: 'all' })}`, () => services.reports.overview({ ...filters, segment: undefined }));
  const data = query.data;

  if (query.status === 'error' && !data) {
    return (
      <StateMessage
        kind="error"
        title="The report didn’t load"
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
  if (data.courseCount === 0 || data.kpis.activeLearners.value + data.kpis.enrollments.value === 0) {
    return <NoReportData filtered={filtered} onReset={resetFilters} />;
  }
  return <Overview data={data} keep={keep} busy={query.status === 'loading'} range={RANGE_SHORT[filters.range]} />;
}

function Overview({ data, keep, busy, range }: { data: ReportOverview; keep: string; busy: boolean; range: string }) {
  const { to } = useWorkspace();
  const [measure, setMeasure] = useState<Measure>('enrollments');
  const points = data.series[measure];
  const values = points.map((p) => p.value);
  const peakIndex = values.indexOf(Math.max(...values));
  const chart = chartData(points);
  const k = data.kpis;
  const vs = `vs ${previousText(data)}`;

  const kpis: KpiItem[] = [
    {
      id: 'enrollments',
      label: 'Enrolments',
      kpi: k.enrollments,
      value: count(k.enrollments.value),
      period: vs,
      note: `${count(k.completions.value)} completions`,
    },
    {
      id: 'completion',
      label: 'Completion rate',
      kpi: k.completionRate,
      value: pct(k.completionRate.value),
      period: vs,
      note: 'Among enrolments at least 60 days old',
    },
    {
      id: 'active',
      label: 'Active learners',
      kpi: k.activeLearners,
      value: count(k.activeLearners.value),
      period: vs,
      note: 'Studied at any point in the period',
    },
    { id: 'progress', label: 'Average progress', kpi: k.avgProgress, value: pct(k.avgProgress.value), period: vs, note: 'Across courses being studied' },
  ];

  const topColumns: Column<CourseReportRow>[] = [
    {
      key: 'course',
      header: 'Course',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Link to={to(`/reports/courses/${r.courseId}${keep}`)} className={styles.cellTitle}>
            {r.title}
          </Link>
          <span className={styles.cellMeta}>{r.categoryTitle}</span>
        </span>
      ),
    },
    { key: 'enrollments', header: 'Enrolments', align: 'end', width: '130px', mobile: 'meta', render: (r) => <EnrolmentCell row={r} /> },
    {
      key: 'completion',
      header: 'Completion',
      width: '150px',
      mobile: 'status',
      render: (r) => (
        <span className={styles.meterCell}>
          <Meter value={r.completionRate} size="sm" label={`${r.title} completion rate`} />
          <span className="tabular">{r.completionRate}%</span>
        </span>
      ),
    },
    {
      key: 'progress',
      header: 'Avg progress',
      align: 'end',
      width: '110px',
      mobile: 'detail',
      render: (r) => <span className="tabular">{r.avgProgress}%</span>,
    },
    { key: 'trend', header: 'Trend', width: '96px', mobile: 'hidden', render: (r) => <Sparkline values={r.trend} width={80} height={22} /> },
  ];

  return (
    <div className={styles.report} aria-busy={busy || undefined}>
      <p className={styles.periodLine}>
        {periodText(data)} · {count(data.courseCount)} {data.courseCount === 1 ? 'course' : 'courses'} · compared with the {range} before
      </p>
      <KpiStrip label="Headline figures" items={kpis} />

      <ReportSection
        id="over-time"
        title="Over time"
        description={`${MEASURE[measure].label} per ${bucketNoun(points)}. The latest period is still filling.`}
        actions={
          <SegmentedControl<Measure>
            size="sm"
            label="Measure"
            value={measure}
            onChange={setMeasure}
            segments={[
              { value: 'enrollments', label: 'Enrolments' },
              { value: 'completions', label: 'Completions' },
              { value: 'activeLearners', label: 'Active learners' },
            ]}
          />
        }
      >
        <div className={styles.chartFigures}>
          <div className={styles.figureInline}>
            <span className={styles.figureInlineValue}>{count(values.reduce((a, b) => a + b, 0) / (measure === 'activeLearners' ? values.length : 1))}</span>
            <span className={styles.figureInlineLabel}>
              {measure === 'activeLearners' ? 'studying in an average period' : `${MEASURE[measure].unit} in total`}
            </span>
          </div>
          {peakIndex >= 0 && values[peakIndex] > 0 && (
            <div className={styles.figureInline}>
              <span className={styles.figureInlineValue}>{count(values[peakIndex])}</span>
              <span className={styles.figureInlineLabel}>at the peak · {chart[peakIndex]?.detail}</span>
            </div>
          )}
        </div>
        <TrendChart
          data={chart}
          label={`${MEASURE[measure].label}, ${periodText(data)}`}
          unit={MEASURE[measure].unit}
          height={230}
          partialIndex={chart.length - 1}
          partialNote="Still filling"
        />
      </ReportSection>

      <ReportSection id="activity" title="Learning activity" description="Quizzes, assignments and lessons in the period, compared with the period before.">
        <div className={styles.activityGroups}>
          <div className={styles.activityGroup}>
            <h3 className={styles.groupTitle}>Quizzes</h3>
            <dl className={styles.metrics}>
              <Metric label="Attempts" value={count(data.quizzes.attempts.value)} kpi={data.quizzes.attempts} />
              <Metric label="Pass rate" value={pct(data.quizzes.passRate.value)} kpi={data.quizzes.passRate} />
              <Metric label="Average score" value={pct(data.quizzes.avgScore.value)} kpi={data.quizzes.avgScore} />
            </dl>
          </div>
          <div className={styles.activityGroup}>
            <h3 className={styles.groupTitle}>Assignments</h3>
            <dl className={styles.metrics}>
              <Metric label="Handed in" value={count(data.assignments.submitted.value)} kpi={data.assignments.submitted} />
              <Metric label="Passed" value={pct(data.assignments.passRate.value)} kpi={data.assignments.passRate} />
              <Metric label="On time" value={pct(data.assignments.onTime.value)} kpi={data.assignments.onTime} />
              <Metric
                label="Median review time"
                value={`${data.assignments.reviewHours.value}h`}
                kpi={data.assignments.reviewHours}
                good="down"
                absolute
                hint="Target: within 48 hours"
              />
            </dl>
          </div>
          <div className={styles.activityGroup}>
            <h3 className={styles.groupTitle}>Engagement</h3>
            <dl className={styles.metrics}>
              <Metric label="Lessons completed" value={count(data.engagement.lessonsCompleted.value)} kpi={data.engagement.lessonsCompleted} />
              <Metric
                label="Lessons per active learner"
                value={data.engagement.lessonsPerLearner.value.toLocaleString('en-IN')}
                kpi={data.engagement.lessonsPerLearner}
              />
              <Metric
                label="Live class attendance"
                value={pct(data.engagement.liveAttendance.value)}
                kpi={data.engagement.liveAttendance}
                missingNote="No classes the period before"
              />
            </dl>
          </div>
        </div>
      </ReportSection>

      <div className={styles.twoColumns}>
        <ReportSection id="where" title="Where learners are" description="Progress of every enrolment being studied, at the end of the period.">
          <ColumnChart
            data={data.progressBands.map((b) => ({ label: b.label, detail: `Progress ${b.label}`, value: b.value }))}
            label="Enrolments by progress at the end of the period"
            unit="enrolments"
            height={200}
          />
        </ReportSection>
        <ReportSection id="categories" title="By category" description="Enrolments in the period, with each category’s completion rate.">
          <BarList
            label="Enrolments by category"
            items={data.categories.map((c) => ({
              key: c.categoryId,
              label: c.title,
              value: c.enrollments,
              display: count(c.enrollments),
              note: `${c.completionRate}% finish`,
            }))}
          />
        </ReportSection>
      </div>

      <ReportSection
        id="top-courses"
        title="Courses with the most enrolments"
        description="Enrolment change is against the period before."
        actions={
          <LinkButton to={to(`/reports/courses${keep}`)} size="sm" variant="ghost" iconEnd={<ArrowRight size={14} />}>
            All courses
          </LinkButton>
        }
      >
        <DataTable label="Courses with the most enrolments" rows={data.topCourses} columns={topColumns} rowKey={(r) => r.courseId} rowLabel={(r) => r.title} />
      </ReportSection>
    </div>
  );
}

export function EnrolmentCell({ row }: { row: Pick<CourseReportRow, 'enrollments' | 'previousEnrollments' | 'title'> }) {
  const diff = row.enrollments - row.previousEnrollments;
  return (
    <span className={styles.numberCell}>
      <span className="tabular">{count(row.enrollments)}</span>
      <span className={diff > 0 ? styles.up : diff < 0 ? styles.down : styles.flat}>
        {diff === 0 ? 'no change' : `${diff > 0 ? '+' : '−'}${count(Math.abs(diff))}`}
        <span className="sr-only"> compared with the period before</span>
      </span>
    </span>
  );
}

export function ReportSkeleton() {
  return (
    <div className={styles.report} aria-busy="true">
      <Skeleton width="40%" height={14} />
      <Skeleton height={96} radius="var(--r-md)" />
      <Skeleton height={300} radius="var(--r-lg)" />
      <div className={styles.twoColumns}>
        <Skeleton height={260} radius="var(--r-lg)" />
        <Skeleton height={260} radius="var(--r-lg)" />
      </div>
    </div>
  );
}

export function NoReportData({ filtered, onReset }: { filtered: boolean; onReset: () => void }) {
  return filtered ? (
    <StateMessage
      icon={<MagnifyingGlass size={26} />}
      title="Nothing matches these filters"
      actions={
        <Button variant="primary" onClick={onReset}>
          Reset filters
        </Button>
      }
    >
      No published course fits this category, course and instructor together, or nobody studied it in the period.
    </StateMessage>
  ) : (
    <StateMessage icon={<ChartLineUp size={26} />} title="No report data yet">
      Reports fill in once learners enrol in published courses. Try a longer period.
    </StateMessage>
  );
}
