import { useSearchParams } from 'react-router-dom';
import { ClockCounterClockwise, X } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatDate, formatRelative, formatTime } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { services, type PlatformAuditEntry } from '@/services';
import {
  PAGE_SIZE,
  PLATFORM_EYEBROW,
  PlatformError,
  actorRoleLabel,
  auditPrefixLabel,
  describeAction,
  pageCount,
  rangeSummary,
  readableAuditDetails,
  targetLabel,
  usePageParam,
} from './platformMeta';
import styles from './Platform.module.css';

/**
 * The platform audit trail from `GET /superadmin/audit`, newest first — the order the API returns,
 * which this screen preserves rather than re-sorting. There is no way to write an entry from here:
 * events are recorded by the operations that cause them.
 */
export default function PlatformAuditPage() {
  const now = useNow();
  const [page, goToPage] = usePageParam();
  const [params, setParams] = useSearchParams();
  const prefix = params.get('prefix')?.trim() || undefined;

  const list = useAsync(`platform:audit:${prefix ?? ''}:${page}`, () => services.platform.listAudit({ page, pageSize: PAGE_SIZE, prefix }));
  const data = list.data;
  const rows = data?.rows ?? [];

  const columns: Column<PlatformAuditEntry>[] = [
    {
      key: 'action',
      header: 'What happened',
      mobile: 'primary',
      render: (entry) => (
        <span className={styles.person}>
          <span className={styles.personName} title={entry.action}>
            {describeAction(entry.action)}
          </span>
        </span>
      ),
    },
    {
      key: 'actor',
      header: 'Who did it',
      mobile: 'meta',
      render: (entry) => (
        <span className={styles.person}>
          <span>{entry.actor.email || <span className={styles.none}>Account removed</span>}</span>
          <span className={styles.personMeta}>{actorRoleLabel(entry.actor.role)}</span>
        </span>
      ),
    },
    {
      key: 'target',
      header: 'Changed',
      mobile: 'status',
      render: (entry) => (
        // The record's id is kept on hover, for support; the badge says what kind of thing it was.
        <span className={styles.person} title={entry.targetId ? `${entry.targetType} ${entry.targetId}` : entry.targetType}>
          <Badge size="sm" tone="neutral">
            {targetLabel(entry.targetType)}
          </Badge>
        </span>
      ),
    },
    {
      key: 'meta',
      header: 'Details',
      mobile: 'detail',
      render: (entry) => {
        const details = readableAuditDetails(entry);
        if (!details.length) return <span className={styles.none}>—</span>;
        return (
          <dl className={styles.details}>
            {details.map((detail) => (
              <span key={detail.label} className={styles.detail}>
                <dt className={styles.detailLabel}>{detail.label}</dt>
                <dd className={styles.detailValue}>{detail.value}</dd>
              </span>
            ))}
          </dl>
        );
      },
    },
    {
      key: 'when',
      header: 'When',
      width: '170px',
      mobile: 'meta',
      render: (entry) => (
        <span className={styles.person}>
          <span>{formatRelative(entry.createdAt, now)}</span>
          <span className={styles.personMeta}>
            {formatDate(entry.createdAt)} · {formatTime(entry.createdAt)}
          </span>
        </span>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Activity log"
        count={data ? data.total : undefined}
        description="A record of every important change on the platform — what happened, who did it and when. Newest first. Entries can’t be edited or deleted."
      />

      {prefix && (
        <div className={styles.auditFilter}>
          <Badge tone="info">Showing: {auditPrefixLabel(prefix)}</Badge>
          <Button size="sm" variant="ghost" iconStart={<X size={14} />} onClick={() => setParams(new URLSearchParams(), { replace: true })}>
            Show all activity
          </Button>
        </div>
      )}

      {list.status === 'error' && !data ? (
        <PlatformError title="The activity log didn’t load" error={list.error} onRetry={() => list.run().catch(() => undefined)} />
      ) : (
        <>
          <DataTable
            framed
            rows={rows}
            columns={columns}
            rowKey={(entry) => entry.id}
            label="Activity log"
            rowLabel={(entry) => `${describeAction(entry.action)} by ${entry.actor.email || 'a removed account'}`}
            loading={list.status === 'loading' && !data}
            empty={
              <StateMessage
                kind="empty"
                icon={<ClockCounterClockwise size={26} />}
                title={prefix ? 'Nothing recorded for this filter' : 'Nothing recorded yet'}
                compact
              >
                Changes are written here as they happen.
              </StateMessage>
            }
          />
          {data && data.total > PAGE_SIZE && (
            <Pagination
              page={page}
              pageCount={pageCount(data.total, data.pageSize)}
              onChange={goToPage}
              summary={rangeSummary(data.total, data.page, data.pageSize)}
            />
          )}
        </>
      )}
    </div>
  );
}
