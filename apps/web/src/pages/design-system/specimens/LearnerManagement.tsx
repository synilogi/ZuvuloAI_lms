import { useEffect, useState } from 'react';
import { ChatText, DownloadSimple, Funnel, X } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { formatRelative } from '@/lib/format';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { DataTable, type Column, type SortState } from '@/components/ui/DataTable/DataTable';
import { SearchInput, Select } from '@/components/ui/Field/Field';
import { InlineMessage, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Meter } from '@/components/lms/progress/Meters';
import { useNow } from '@/hooks/useNow';
import { services, type LearnerQuery, type LearnerRow, type LearnerStatus } from '@/services';
import styles from './Specimens.module.css';

const STATUS: Record<LearnerStatus, { label: string; tone: 'accent' | 'warn' | 'info' | 'neutral' }> = {
  active: { label: 'Active', tone: 'accent' },
  'at-risk': { label: 'At risk', tone: 'warn' },
  completed: { label: 'Completed', tone: 'info' },
  paused: { label: 'Paused', tone: 'neutral' },
};

const PAGE_SIZE = 6;

/** Admin learner management — the dense end of the system: filter, sort, bulk act, paginate. */
export function LearnerManagement() {
  const now = useNow();
  const toast = useToast();
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<LearnerStatus | 'all'>('all');
  const [sort, setSort] = useState<SortState>({ key: 'progress', direction: 'desc' });
  const [page, setPage] = useState(1);
  const [selected, setSelected] = useState<Set<string>>(new Set());

  useEffect(() => setPage(1), [search, status]);

  const learnerQuery: LearnerQuery = {
    search,
    status,
    sort: { key: sort.key as NonNullable<LearnerQuery['sort']>['key'], direction: sort.direction },
    page,
    pageSize: PAGE_SIZE,
  };
  const query = useAsync(JSON.stringify(learnerQuery), () => services.admin.listLearners(learnerQuery));

  const rows = query.data?.rows ?? [];
  const total = query.data?.total ?? 0;
  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const columns: Column<LearnerRow>[] = [
    {
      key: 'name',
      header: 'Learner',
      sortable: true,
      mobile: 'primary',
      render: (r) => (
        <span className={styles.person}>
          <Avatar name={r.name} size={30} />
          <span className={styles.personText}>
            <span className={styles.personName}>{r.name}</span>
            <span className={styles.personEmail}>{r.email}</span>
          </span>
        </span>
      ),
    },
    {
      key: 'course',
      header: 'Course',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.truncate} title={r.course}>
          {r.course}
        </span>
      ),
    },
    {
      key: 'progress',
      header: 'Progress',
      sortable: true,
      width: '170px',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.progressCell}>
          <Meter value={r.progress} label={`${r.name} progress`} size="sm" />
          <span className="tabular">{r.progress}%</span>
        </span>
      ),
    },
    { key: 'rank', header: 'Rank', mobile: 'detail', render: (r) => <span className={styles.nowrap}>{r.rank}</span> },
    {
      key: 'lastActiveAt',
      header: 'Last active',
      sortable: true,
      mobile: 'detail',
      render: (r) => <span className={styles.nowrap}>{formatRelative(r.lastActiveAt, now)}</span>,
    },
    {
      key: 'status',
      header: 'Status',
      mobile: 'status',
      render: (r) => (
        <Badge tone={STATUS[r.status].tone} dot>
          {STATUS[r.status].label}
        </Badge>
      ),
    },
  ];

  const bulk = (label: string) => {
    toast({ kind: 'success', title: label, text: `${selected.size} learner${selected.size === 1 ? '' : 's'}` });
    setSelected(new Set());
  };

  return (
    <div className={styles.management}>
      <div className={styles.toolbar}>
        {selected.size > 0 ? (
          <div className={styles.bulkBar} role="region" aria-label="Bulk actions">
            <IconButton label="Clear selection" size="sm" icon={<X size={14} />} onClick={() => setSelected(new Set())} />
            <span className={styles.bulkCount}>{selected.size} selected</span>
            <Button size="sm" iconStart={<ChatText size={15} />} onClick={() => bulk('Message sent')}>
              Message
            </Button>
            <Button size="sm" onClick={() => bulk('Access extended by 30 days')}>
              Extend access
            </Button>
            <Button size="sm" variant="quiet" iconStart={<DownloadSimple size={15} />} onClick={() => bulk('Export started')}>
              Export
            </Button>
          </div>
        ) : (
          <>
            <div className={styles.search}>
              <SearchInput value={search} onValueChange={setSearch} placeholder="Search learners or courses" aria-label="Search learners" />
            </div>
            <div className={styles.filter}>
              <Funnel size={16} className={styles.filterIcon} />
              <Select aria-label="Filter by status" value={status} onChange={(e) => setStatus(e.target.value as LearnerStatus | 'all')}>
                <option value="all">All statuses</option>
                <option value="active">Active</option>
                <option value="at-risk">At risk</option>
                <option value="completed">Completed</option>
                <option value="paused">Paused</option>
              </Select>
            </div>
          </>
        )}
      </div>

      {query.status === 'error' && (
        <InlineMessage
          kind="error"
          title="Couldn’t load learners."
          action={
            <Button size="sm" onClick={() => query.run().catch(() => undefined)}>
              Retry
            </Button>
          }
        >
          {query.error.message}
        </InlineMessage>
      )}

      <DataTable
        label="Learners"
        rows={rows}
        columns={columns}
        rowKey={(r) => r.id}
        rowLabel={(r) => r.name}
        selectable
        selected={selected}
        onSelectedChange={setSelected}
        sort={sort}
        onSortChange={setSort}
        loading={query.status === 'loading' && !query.data}
        skeletonRows={PAGE_SIZE}
        empty={
          <StateMessage compact title="No learners match">
            Try a different name, or clear the status filter.
          </StateMessage>
        }
      />

      <Pagination
        page={page}
        pageCount={pageCount}
        onChange={setPage}
        summary={total ? `Showing ${(page - 1) * PAGE_SIZE + 1}–${Math.min(page * PAGE_SIZE, total)} of ${total} learners` : 'No results'}
      />
    </div>
  );
}
