import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { DownloadSimple } from '@phosphor-icons/react';
import { BarList } from '@/components/charts/BarList';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column, type SortState } from '@/components/ui/DataTable/DataTable';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type InstructorReportRow } from '@/services';
import { Rating } from '@/components/lms/shared/Rating';
import { NoReportData, ReportSkeleton } from './ReportsOverviewPage';
import { count, downloadCsv, filterKey, Metric, pct, periodText, previousText, ReportSection, useReportFilters, useReportsOutlet } from './reportMeta';
import styles from './Reports.module.css';

const SORTERS: Record<string, (r: InstructorReportRow) => number | string> = {
  name: (r) => r.name,
  learners: (r) => r.learners,
  completion: (r) => r.completionRate ?? -1,
  rating: (r) => r.rating ?? -1,
  reviews: (r) => r.reviews,
  reviewHours: (r) => r.reviewHours ?? 9999,
  live: (r) => r.liveClasses,
};

export default function InstructorReportsPage() {
  const filters = useReportFilters();
  const { filtered, resetFilters } = useReportsOutlet();
  usePageCrumbs([{ label: 'Instructors' }]);
  const query = useAsync(`report-instructors:${filterKey({ ...filters, segment: 'all' })}`, () =>
    services.reports.instructors({ ...filters, segment: undefined }),
  );
  const [sort, setSort] = useState<SortState>({ key: 'learners', direction: 'desc' });
  const data = query.data;
  const rows = useMemo(() => {
    if (!data) return [];
    const pick = SORTERS[sort.key] ?? SORTERS.learners;
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
        title="The instructor report didn’t load"
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

  const f = data.figures;
  const columns: Column<InstructorReportRow>[] = [
    {
      key: 'name',
      header: 'Instructor',
      sortable: true,
      mobile: 'primary',
      render: (r) => (
        <span className={styles.person}>
          <Avatar name={r.name} size={30} />
          <span className={styles.stack}>
            <Link to={`/admin/instructors/${r.instructorId}/performance`} className={styles.cellTitle}>
              {r.name}
            </Link>
            <span className={styles.cellMeta}>
              {r.title} · {r.courses} {r.courses === 1 ? 'course' : 'courses'}
            </span>
          </span>
        </span>
      ),
    },
    {
      key: 'learners',
      header: 'Learners',
      sortable: true,
      align: 'end',
      width: '96px',
      mobile: 'meta',
      render: (r) => <span className="tabular">{count(r.learners)}</span>,
    },
    {
      key: 'completion',
      header: 'Completion',
      sortable: true,
      align: 'end',
      width: '104px',
      mobile: 'detail',
      render: (r) => <span className="tabular">{pct(r.completionRate)}</span>,
    },
    {
      key: 'rating',
      header: 'Rating',
      sortable: true,
      width: '84px',
      mobile: 'status',
      render: (r) => (r.rating ? <Rating value={r.rating} /> : <span className={styles.cellMeta}>—</span>),
    },
    {
      key: 'reviews',
      header: 'Reviews',
      sortable: true,
      align: 'end',
      width: '96px',
      mobile: 'detail',
      render: (r) => <span className="tabular">{count(r.reviews)}</span>,
    },
    {
      key: 'reviewHours',
      header: 'Review time',
      sortable: true,
      align: 'end',
      width: '124px',
      mobile: 'detail',
      render: (r) =>
        r.reviewHours === null ? (
          <span className={styles.cellMeta}>—</span>
        ) : (
          <span className={styles.numberCell}>
            <span className="tabular">{r.reviewHours}h median</span>
            <span className={r.onTime !== null && r.onTime < 85 ? styles.down : styles.flat}>{pct(r.onTime)} within 48h</span>
          </span>
        ),
    },
    {
      key: 'live',
      header: 'Live classes',
      sortable: true,
      align: 'end',
      width: '118px',
      mobile: 'detail',
      render: (r) =>
        r.liveClasses === 0 ? (
          <span className={styles.cellMeta}>None</span>
        ) : (
          <span className={styles.numberCell}>
            <span className="tabular">{r.liveClasses}</span>
            <span className={styles.flat}>{pct(r.attendance)} attended</span>
          </span>
        ),
    },
  ];

  const exportCsv = () =>
    downloadCsv(
      `instructor-performance-${filters.range}.csv`,
      [
        'Instructor',
        'Title',
        'Courses',
        'Learners',
        'Completion rate %',
        'Rating',
        'Reviews',
        'Median review hours',
        'Reviews within 48h %',
        'Live classes',
        'Attendance %',
      ],
      rows.map((r) => [r.name, r.title, r.courses, r.learners, r.completionRate, r.rating, r.reviews, r.reviewHours, r.onTime, r.liveClasses, r.attendance]),
    );

  const reviewers = rows.filter((r) => r.reviews > 0);

  return (
    <div className={styles.report} aria-busy={query.status === 'loading' || undefined}>
      <p className={styles.periodLine}>
        {periodText(data)} · {count(rows.length)} {rows.length === 1 ? 'instructor' : 'instructors'} teaching · compared with {previousText(data)}
      </p>
      <dl className={`${styles.metrics} ${styles.metricBand}`}>
        <Metric label="Reviews returned" value={count(f.reviews.value)} kpi={f.reviews} />
        <Metric label="Median review time" value={`${f.reviewHours.value}h`} kpi={f.reviewHours} good="down" absolute hint="Learners are promised 48 hours" />
        <Metric label="Returned within 48 hours" value={pct(f.onTime.value)} kpi={f.onTime} />
        <Metric label="Live class attendance" value={pct(f.attendance.value)} kpi={f.attendance} missingNote="No classes the period before" />
      </dl>

      <div className={styles.twoColumns}>
        <ReportSection id="completion-by-instructor" title="Completion rate by instructor" description="Across the courses each instructor teaches.">
          <BarList
            label="Completion rate by instructor"
            max={100}
            items={[...rows]
              .filter((r) => r.completionRate !== null)
              .sort((a, b) => (b.completionRate ?? 0) - (a.completionRate ?? 0))
              .map((r) => ({
                key: r.instructorId,
                label: r.name,
                value: r.completionRate ?? 0,
                display: pct(r.completionRate),
                note: `${count(r.learners)} learners`,
              }))}
          />
        </ReportSection>
        <ReportSection id="review-load" title="Review load" description="Submissions each instructor returned in the period.">
          {reviewers.length === 0 ? (
            <p className={styles.emptyNote}>No reviews were returned in this period.</p>
          ) : (
            <BarList
              label="Reviews returned by instructor"
              items={[...reviewers]
                .sort((a, b) => b.reviews - a.reviews)
                .map((r) => ({
                  key: r.instructorId,
                  label: r.name,
                  value: r.reviews,
                  display: count(r.reviews),
                  note: r.reviewHours !== null ? `${r.reviewHours}h median` : undefined,
                }))}
            />
          )}
        </ReportSection>
      </div>

      <ReportSection
        id="instructor-table"
        title="Instructor performance"
        description="Select an instructor for their full profile."
        actions={
          <Button size="sm" iconStart={<DownloadSimple size={15} />} onClick={exportCsv}>
            Export CSV
          </Button>
        }
      >
        <DataTable
          label="Instructor performance"
          rows={rows}
          columns={columns}
          rowKey={(r) => r.instructorId}
          rowLabel={(r) => r.name}
          sort={sort}
          onSortChange={setSort}
        />
      </ReportSection>
    </div>
  );
}
