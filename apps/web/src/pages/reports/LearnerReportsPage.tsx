import { useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { DownloadSimple, MagnifyingGlass } from '@phosphor-icons/react';
import type { LearnerSegment } from '@syniastrolms/domain';
import { LEARNER_SEGMENTS } from '@syniastrolms/domain';
import { BarList } from '@/components/charts/BarList';
import { ColumnChart } from '@/components/charts/Charts';
import { KpiStrip, type KpiItem } from '@/components/data/KpiStrip';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column, type SortState } from '@/components/ui/DataTable/DataTable';
import { SearchInput } from '@/components/ui/Field/Field';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { Meter } from '@/components/lms/progress/Meters';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatRelative } from '@/lib/format';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type LearnerReportRow, type LearnerReportSort } from '@/services';
import { STUDENT_STATUS, StudentStatusBadge } from '../students/studentMeta';
import { NoReportData, ReportSkeleton } from './ReportsOverviewPage';
import {
  count,
  downloadCsv,
  filterKey,
  pct,
  periodText,
  previousText,
  ReportSection,
  SEGMENT_DESCRIPTION,
  SEGMENT_LABEL,
  useReportFilters,
  useReportsOutlet,
} from './reportMeta';
import styles from './Reports.module.css';

const PAGE_SIZE = 15;
/** The API's largest page: the export asks for the report in pages of this size. */
const EXPORT_PAGE = 500;
const SORT_KEYS: LearnerReportSort[] = ['name', 'courses', 'progress', 'assignments', 'lastActive'];

export default function LearnerReportsPage() {
  const toast = useToast();
  const [exporting, setExporting] = useState(false);
  const filters = useReportFilters();
  const { filtered, resetFilters } = useReportsOutlet();
  const now = useNow();
  const [params, setParams] = useSearchParams();
  usePageCrumbs([{ label: 'Learner progress' }]);
  const search = params.get('q') ?? '';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const [sortKey, sortDir] = (params.get('sort') ?? 'lastActive:desc').split(':');
  const sort: SortState = { key: SORT_KEYS.includes(sortKey as LearnerReportSort) ? sortKey : 'lastActive', direction: sortDir === 'asc' ? 'asc' : 'desc' };
  const setParam = (next: Record<string, string | undefined>, resetPage = true) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (v) p.set(k, v);
      else p.delete(k);
    }
    if (resetPage) p.delete('page');
    setParams(p, { replace: true });
  };

  const query = useAsync(`report-learners:${filterKey(filters)}:${search}:${sort.key}:${sort.direction}:${page}`, () =>
    services.reports.learners({ ...filters, search, sort: { key: sort.key as LearnerReportSort, direction: sort.direction }, page, pageSize: PAGE_SIZE }),
  );
  const data = query.data;

  if (query.status === 'error' && !data) {
    return (
      <StateMessage
        kind="error"
        title="The learner report didn’t load"
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
  if (data.courseCount === 0 || data.segments.all === 0) return <NoReportData filtered={filtered} onReset={resetFilters} />;

  const k = data.kpis;
  const vs = `vs ${previousText(data)}`;
  const segment: LearnerSegment = filters.segment;
  const kpis: KpiItem[] = [
    {
      id: 'learners',
      label: segment === 'all' ? 'Learners studying' : SEGMENT_LABEL[segment],
      kpi: k.learners,
      value: count(k.learners.value),
      period: vs,
      note: SEGMENT_DESCRIPTION[segment],
    },
    { id: 'active', label: 'Active now', kpi: k.active, value: count(k.active.value), period: vs, note: 'Studied in the last 10 days' },
    { id: 'risk', label: 'At risk', kpi: k.atRisk, value: count(k.atRisk.value), good: 'down', period: vs, note: 'Quiet 10+ days with a course open' },
    { id: 'progress', label: 'Average progress', kpi: k.avgProgress, value: pct(k.avgProgress.value), period: vs },
  ];

  const columns: Column<LearnerReportRow>[] = [
    {
      key: 'name',
      header: 'Learner',
      sortable: true,
      mobile: 'primary',
      render: (r) => (
        <span className={styles.person}>
          <Avatar name={r.name} size={30} />
          <span className={styles.stack}>
            <Link to={`/admin/students/${r.studentId}`} className={styles.cellTitle}>
              {r.name}
            </Link>
            <span className={styles.cellMeta}>{r.city}</span>
          </span>
        </span>
      ),
    },
    { key: 'status', header: 'Status', width: '120px', mobile: 'status', render: (r) => <StudentStatusBadge status={r.status} /> },
    {
      key: 'courses',
      header: 'Courses',
      sortable: true,
      align: 'end',
      width: '96px',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.numberCell}>
          <span className="tabular">{r.courses}</span>
          <span className={styles.flat}>{r.completed} finished</span>
        </span>
      ),
    },
    {
      key: 'progress',
      header: 'Avg progress',
      sortable: true,
      width: '150px',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.meterCell}>
          <Meter value={r.avgProgress} size="sm" label={`${r.name} average progress`} />
          <span className="tabular">{r.avgProgress}%</span>
        </span>
      ),
    },
    {
      key: 'assignments',
      header: 'Assignments',
      sortable: true,
      align: 'end',
      width: '112px',
      mobile: 'detail',
      render: (r) => <span className="tabular">{r.assignmentAvg === null ? '—' : `${r.assignmentAvg}%`}</span>,
    },
    {
      key: 'lastActive',
      header: 'Last active',
      sortable: true,
      width: '130px',
      mobile: 'detail',
      render: (r) => <span className={styles.cellMeta}>{formatRelative(r.lastActiveAt, now)}</span>,
    },
  ];

  const exportCsv = async () => {
    setExporting(true);
    try {
      // Page by page at the API's largest page (500): one request for everything would be refused.
      const rows: LearnerReportRow[] = [];
      for (let page = 1; ; page++) {
        const chunk = await services.reports.learners({
          ...filters,
          search,
          sort: { key: sort.key as LearnerReportSort, direction: sort.direction },
          page,
          pageSize: EXPORT_PAGE,
        });
        rows.push(...chunk.rows);
        if (chunk.rows.length < EXPORT_PAGE || rows.length >= chunk.total) break;
      }
      writeCsv(rows);
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t export the report', text: (e as Error).message });
    } finally {
      setExporting(false);
    }
  };

  const writeCsv = (all: LearnerReportRow[]) => {
    downloadCsv(
      `learner-progress-${filters.range}.csv`,
      ['Learner', 'City', 'Status', 'Courses', 'Finished', 'Average progress %', 'Assignment average %', 'Last active'],
      all.map((r) => [r.name, r.city, STUDENT_STATUS[r.status].label, r.courses, r.completed, r.avgProgress, r.assignmentAvg, r.lastActiveAt.slice(0, 10)]),
    );
  };

  return (
    <div className={styles.report} aria-busy={query.status === 'loading' || undefined}>
      <p className={styles.periodLine}>
        {periodText(data)} · {SEGMENT_LABEL[segment].toLowerCase()} in {count(data.courseCount)} {data.courseCount === 1 ? 'course' : 'courses'}
      </p>
      <KpiStrip label="Learner figures" items={kpis} />

      <div className={styles.twoColumns}>
        <ReportSection id="progress-spread" title="Progress" description="Average progress across each learner’s courses.">
          <ColumnChart
            data={data.progressBands.map((b) => ({ label: b.label, detail: `Average progress ${b.label}`, value: b.value }))}
            label="Learners by average progress"
            unit="learners"
            height={190}
          />
        </ReportSection>
        <ReportSection id="segments" title="Who’s studying" description="Choose a group to narrow the report.">
          <BarList
            label="Learners by group"
            max={data.segments.all}
            items={LEARNER_SEGMENTS.filter((s) => s !== 'all').map((s) => ({
              key: s,
              label: (
                <button
                  type="button"
                  className={styles.linkish}
                  aria-pressed={segment === s}
                  onClick={() => setParam({ segment: segment === s ? undefined : s })}
                >
                  {SEGMENT_LABEL[s]}
                </button>
              ),
              value: data.segments[s],
              display: count(data.segments[s]),
              note: `${Math.round((data.segments[s] / Math.max(1, data.segments.all)) * 100)}%`,
            }))}
          />
        </ReportSection>
      </div>

      <ReportSection
        id="learner-table"
        title="Learners"
        description={`${count(data.total)} ${data.total === 1 ? 'learner' : 'learners'}${search ? ` matching “${search}”` : ''} · status as of today`}
        actions={
          <Button size="sm" iconStart={<DownloadSimple size={15} />} onClick={exportCsv} disabled={data.total === 0} loading={exporting}>
            Export CSV
          </Button>
        }
      >
        <div className={styles.tableTools}>
          <SearchInput
            value={search}
            onValueChange={(v) => setParam({ q: v || undefined })}
            placeholder="Search by name or city"
            aria-label="Search learners"
          />
        </div>
        <DataTable
          label="Learner progress"
          rows={data.rows}
          columns={columns}
          rowKey={(r) => r.studentId}
          rowLabel={(r) => r.name}
          sort={sort}
          onSortChange={(s) => setParam({ sort: `${s.key}:${s.direction}` })}
          loading={query.status === 'loading'}
          empty={
            <StateMessage
              compact
              icon={<MagnifyingGlass size={22} />}
              title="No learners match"
              actions={<Button onClick={() => setParam({ q: undefined })}>Show all learners</Button>}
            >
              Try another name or city.
            </StateMessage>
          }
        />
        {data.total > PAGE_SIZE && (
          <Pagination
            page={page}
            pageCount={Math.ceil(data.total / PAGE_SIZE)}
            onChange={(p) => setParam({ page: String(p) }, false)}
            summary={`${count((page - 1) * PAGE_SIZE + 1)}–${count(Math.min(page * PAGE_SIZE, data.total))} of ${count(data.total)}`}
          />
        )}
      </ReportSection>
    </div>
  );
}
