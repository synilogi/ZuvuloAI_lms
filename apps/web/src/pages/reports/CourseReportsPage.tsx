import { useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, DownloadSimple } from '@phosphor-icons/react';
import { BarList } from '@/components/charts/BarList';
import { Sparkline, TrendChart } from '@/components/charts/Charts';
import { KpiStrip, type KpiItem } from '@/components/data/KpiStrip';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column, type SortState } from '@/components/ui/DataTable/DataTable';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { Meter } from '@/components/lms/progress/Meters';
import { useAsync } from '@/hooks/useAsync';
import { useWorkspace } from '@/hooks/useWorkspace';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type CourseReport, type CourseReportRow } from '@/services';
import { Rating } from '@/components/lms/shared/Rating';
import { EnrolmentCell, NoReportData, ReportSkeleton } from './ReportsOverviewPage';
import {
  chartData,
  count,
  downloadCsv,
  filterKey,
  pct,
  PeriodSelect,
  periodText,
  previousText,
  ReportSection,
  useReportFilters,
  useReportsOutlet,
} from './reportMeta';
import styles from './Reports.module.css';

const SORTERS: Record<string, (r: CourseReportRow) => number | string> = {
  course: (r) => r.title,
  enrollments: (r) => r.enrollments,
  completion: (r) => r.completionRate,
  active: (r) => r.activeLearners,
  progress: (r) => r.avgProgress,
  quiz: (r) => r.quizPassRate ?? -1,
  assignments: (r) => r.assignmentPassRate ?? -1,
  rating: (r) => r.rating ?? -1,
};

export default function CourseReportsPage() {
  const filters = useReportFilters();
  const { to } = useWorkspace();
  const { keep, filtered, resetFilters } = useReportsOutlet();
  usePageCrumbs([{ label: 'Courses' }]);
  const query = useAsync(`report-courses:${filterKey({ ...filters, segment: 'all' })}`, () => services.reports.courses({ ...filters, segment: undefined }));
  const [sort, setSort] = useState<SortState>({ key: 'enrollments', direction: 'desc' });
  const data = query.data;
  const rows = useMemo(() => {
    if (!data) return [];
    const pick = SORTERS[sort.key] ?? SORTERS.enrollments;
    const dir = sort.direction === 'asc' ? 1 : -1;
    return [...data.rows].sort((a, b) => {
      const x = pick(a);
      const y = pick(b);
      return (typeof x === 'string' ? x.localeCompare(y as string) : x - (y as number)) * dir;
    });
  }, [data, sort]);

  if (query.status === 'error' && !data) {
    return (
      <StateMessage
        kind="error"
        title="The course report didn’t load"
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
  if (data.rows.length === 0) return <NoReportData filtered={filtered} onReset={resetFilters} />;

  const totalEnrolments = data.rows.reduce((n, r) => n + r.enrollments, 0);
  const columns: Column<CourseReportRow>[] = [
    {
      key: 'course',
      header: 'Course',
      sortable: true,
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Link to={to(`/reports/courses/${r.courseId}${keep}`)} className={styles.cellTitle}>
            {r.title}
          </Link>
          <span className={styles.cellMeta}>
            {r.categoryTitle} · {r.instructorNames.join(', ')}
            {r.status === 'archived' ? ' · Archived' : ''}
          </span>
        </span>
      ),
    },
    { key: 'enrollments', header: 'Enrolments', sortable: true, align: 'end', width: '118px', mobile: 'meta', render: (r) => <EnrolmentCell row={r} /> },
    {
      key: 'completion',
      header: 'Completion',
      sortable: true,
      width: '140px',
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
      sortable: true,
      align: 'end',
      width: '104px',
      mobile: 'detail',
      render: (r) => <span className="tabular">{r.avgProgress}%</span>,
    },
    {
      key: 'quiz',
      header: 'Pass rate',
      sortable: true,
      align: 'end',
      width: '128px',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.numberCell}>
          <span className="tabular">{pct(r.quizPassRate)} quizzes</span>
          <span className={styles.flat}>{pct(r.assignmentPassRate)} assignments</span>
        </span>
      ),
    },
    {
      key: 'rating',
      header: 'Rating',
      sortable: true,
      width: '76px',
      mobile: 'detail',
      render: (r) => (r.rating ? <Rating value={r.rating} /> : <span className={styles.cellMeta}>—</span>),
    },
    { key: 'trend', header: 'Trend', width: '88px', mobile: 'hidden', render: (r) => <Sparkline values={r.trend} width={72} height={22} /> },
  ];

  const exportCsv = () =>
    downloadCsv(
      `course-performance-${filters.range}.csv`,
      [
        'Course',
        'Category',
        'Instructors',
        'Status',
        'Enrolments',
        'Enrolments (previous period)',
        'Completions',
        'Completion rate %',
        'Active learners',
        'Average progress %',
        'Quiz pass rate %',
        'Assignment pass rate %',
        'Rating',
      ],
      rows.map((r) => [
        r.title,
        r.categoryTitle,
        r.instructorNames.join('; '),
        r.status,
        r.enrollments,
        r.previousEnrollments,
        r.completions,
        r.completionRate,
        r.activeLearners,
        r.avgProgress,
        r.quizPassRate,
        r.assignmentPassRate,
        r.rating,
      ]),
    );

  return (
    <div className={styles.report} aria-busy={query.status === 'loading' || undefined}>
      <p className={styles.periodLine}>
        {periodText(data)} · {count(data.rows.length)} courses with learners · {count(totalEnrolments)} enrolments
      </p>

      <div className={styles.twoColumns}>
        <ReportSection id="completion-by-course" title="Completion rate" description="Finished, among enrolments at least 60 days old.">
          <BarList
            label="Completion rate by course"
            max={100}
            items={[...data.rows]
              .sort((a, b) => b.completionRate - a.completionRate)
              .map((r) => ({ key: r.courseId, label: r.title, value: r.completionRate, display: `${r.completionRate}%` }))}
          />
        </ReportSection>
        <ReportSection id="progress-by-course" title="Average progress" description="Where learners studying in the period have got to.">
          <BarList
            label="Average progress by course"
            max={100}
            items={data.rows
              .filter((r) => r.activeLearners > 0)
              .sort((a, b) => b.avgProgress - a.avgProgress)
              .map((r) => ({
                key: r.courseId,
                label: r.title,
                value: r.avgProgress,
                display: `${r.avgProgress}%`,
                note: `${count(r.activeLearners)} studying`,
              }))}
          />
        </ReportSection>
      </div>

      <ReportSection
        id="course-table"
        title="Course performance"
        description={`Enrolment change is against ${previousText(data)}. Select a course for its chapters and assessments.`}
        actions={
          <Button size="sm" iconStart={<DownloadSimple size={15} />} onClick={exportCsv}>
            Export CSV
          </Button>
        }
      >
        <DataTable
          label="Course performance"
          rows={rows}
          columns={columns}
          rowKey={(r) => r.courseId}
          rowLabel={(r) => r.title}
          sort={sort}
          onSortChange={setSort}
        />
      </ReportSection>
    </div>
  );
}

export function CourseReportPage() {
  const { courseId } = useParams();
  const filters = useReportFilters();
  const { to } = useWorkspace();
  const { keep } = useReportsOutlet();
  const query = useAsync(`report-course:${courseId}:${filters.range}`, () => services.reports.course(courseId!, { range: filters.range }));
  const data = query.data?.row.courseId === courseId ? query.data : undefined;
  usePageCrumbs([{ label: 'Courses', to: to(`/reports/courses${keep}`) }, { label: data?.row.title ?? 'Course report' }]);

  if (query.status === 'error' && !data) {
    return (
      <StateMessage
        kind="error"
        title={(query.error as { code?: string }).code === 'not-found' ? 'No report for this course' : 'The course report didn’t load'}
        actions={
          <LinkButton to={to(`/reports/courses${keep}`)} iconStart={<ArrowLeft size={16} />}>
            Back to courses
          </LinkButton>
        }
      >
        {query.error.message}
      </StateMessage>
    );
  }
  if (!data) return <ReportSkeleton />;
  return <CourseDetail data={data} keep={keep} busy={query.status === 'loading'} />;
}

function CourseDetail({ data, keep, busy }: { data: CourseReport; keep: string; busy: boolean }) {
  const { to } = useWorkspace();
  const { row, kpis } = data;
  const vs = `vs ${previousText(data)}`;
  const items: KpiItem[] = [
    {
      id: 'enrollments',
      label: 'Enrolments',
      kpi: kpis.enrollments,
      value: count(kpis.enrollments.value),
      period: vs,
      note: `${count(row.completions)} completions`,
    },
    { id: 'completion', label: 'Completion rate', kpi: kpis.completionRate, value: pct(kpis.completionRate.value), period: vs },
    { id: 'active', label: 'Active learners', kpi: kpis.activeLearners, value: count(kpis.activeLearners.value), period: vs },
    { id: 'progress', label: 'Average progress', kpi: kpis.avgProgress, value: pct(kpis.avgProgress.value), period: vs },
  ];
  const enrolled = data.funnel[0]?.value ?? 0;
  const chart = chartData(data.series.enrollments);

  return (
    <div className={styles.report} aria-busy={busy || undefined}>
      <PageHeader
        back={{ label: 'Course reports', to: to(`/reports/courses${keep}`) }}
        eyebrow={row.categoryTitle}
        title={row.title}
        description={`${row.instructorNames.join(', ')} · ${periodText(data)}`}
        actions={
          <div className={styles.headerActions}>
            <PeriodSelect className={styles.periodSelect} />
            <LinkButton to={to(`/courses/${row.courseId}`)}>Open course</LinkButton>
          </div>
        }
      />
      <KpiStrip label={`${row.title} headline figures`} items={items} />

      <div className={styles.twoColumns}>
        <ReportSection id="funnel" title="From enrolling to finishing" description="Enrolments that started in the period, and how far they’ve come.">
          {enrolled === 0 ? (
            <p className={styles.emptyNote}>Nobody enrolled in this course during the period.</p>
          ) : (
            <BarList
              label="Enrolment funnel"
              max={enrolled}
              items={data.funnel.map((f) => ({
                key: f.label,
                label: f.label,
                value: f.value,
                display: count(f.value),
                note: `${Math.round((f.value / enrolled) * 100)}%`,
              }))}
            />
          )}
        </ReportSection>
        <ReportSection id="chapters" title="Chapters reached" description="Share of learners studying in the period who have reached each chapter.">
          <BarList
            label="Chapters reached"
            max={100}
            items={data.chapters.map((c, i) => ({ key: c.chapterId, label: `${i + 1}. ${c.title}`, value: c.reached, display: `${c.reached}%` }))}
          />
        </ReportSection>
      </div>

      <ReportSection id="course-trend" title="Enrolments over time" description="The latest period is still filling.">
        <TrendChart data={chart} label={`${row.title} enrolments`} unit="enrolments" height={200} partialIndex={chart.length - 1} partialNote="Still filling" />
      </ReportSection>

      <div className={styles.twoColumns}>
        <ReportSection id="quizzes" title="Quizzes" description="Attempts in the period, pass rate and average score.">
          {data.quizzes.length === 0 ? (
            <p className={styles.emptyNote}>This course has no published quizzes.</p>
          ) : (
            <div className={styles.tableScroll}>
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th scope="col">Quiz</th>
                    <th scope="col" className={styles.num}>
                      Attempts
                    </th>
                    <th scope="col" className={styles.num}>
                      Pass rate
                    </th>
                    <th scope="col" className={styles.num}>
                      Avg score
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.quizzes.map((q) => (
                    <tr key={q.quizId}>
                      <th scope="row">
                        <Link to={to(`/quizzes/${q.quizId}/results`)} className={styles.cellTitle}>
                          {q.title}
                        </Link>
                      </th>
                      <td className={styles.num}>{count(q.attempts)}</td>
                      <td className={styles.num}>{q.passRate}%</td>
                      <td className={styles.num}>{q.avgScore}%</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </ReportSection>
        <ReportSection id="assignments" title="Assignments" description="Handed in during the period.">
          {data.assignments.length === 0 ? (
            <p className={styles.emptyNote}>This course has no assignments.</p>
          ) : (
            <div className={styles.tableScroll}>
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th scope="col">Assignment</th>
                    <th scope="col" className={styles.num}>
                      Handed in
                    </th>
                    <th scope="col" className={styles.num}>
                      Passed
                    </th>
                    <th scope="col" className={styles.num}>
                      On time
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {data.assignments.map((a) => (
                    <tr key={a.assignmentId}>
                      <th scope="row">
                        <Link to={to(`/assignments/${a.assignmentId}/submissions`)} className={styles.cellTitle}>
                          {a.title}
                        </Link>
                        {a.avgScore !== null && <span className={styles.cellMeta}>Average score {a.avgScore}%</span>}
                      </th>
                      <td className={styles.num}>{count(a.submitted)}</td>
                      <td className={styles.num}>{pct(a.passRate)}</td>
                      <td className={styles.num}>{pct(a.onTime)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </ReportSection>
      </div>
    </div>
  );
}
