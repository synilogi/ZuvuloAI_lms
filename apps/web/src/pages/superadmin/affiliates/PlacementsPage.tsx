import { useSearchParams } from 'react-router-dom';
import type { PlacementHistoryRow } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AffiliateTabs } from './affiliateMeta';
import styles from './Affiliates.module.css';

const REASON_LABEL: Record<PlacementHistoryRow['reason'], string> = { 'sponsor-direct': 'Direct', spillover: 'Spillover', manual: 'Manual', root: 'Root' };

/** Every placement and move (MLM-002), newest first: by rule or by hand, with the reason a person gave. */
export default function PlacementsPage() {
  const now = useNow();
  const [params, setParams] = useSearchParams();
  const page = Math.max(1, Number(params.get('page')) || 1);
  const list = useAsync(`affiliates:placements:${page}`, () => services.affiliatesPlatform.placements({ page, pageSize: 50 }));
  const data = list.data;
  const goTo = (next: number) => {
    const p = new URLSearchParams(params);
    if (next <= 1) p.delete('page');
    else p.set('page', String(next));
    setParams(p, { replace: true });
  };

  const columns: Column<PlacementHistoryRow>[] = [
    {
      key: 'who',
      header: 'Affiliate',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <span className={styles.cellTitle}>{r.affiliate.name}</span>
          <span className={styles.cellMeta}>{r.affiliate.code}</span>
        </span>
      ),
    },
    {
      key: 'from',
      header: 'From',
      width: '150px',
      mobile: 'detail',
      render: (r) => (r.from ? `${r.from.parentCode} · ${r.from.leg}` : <span className={styles.faint}>—</span>),
    },
    {
      key: 'to',
      header: 'To',
      width: '150px',
      mobile: 'meta',
      render: (r) => (r.to ? `${r.to.parentCode} · ${r.to.leg}` : <span className={styles.faint}>Root</span>),
    },
    {
      key: 'reason',
      header: 'How',
      width: '110px',
      mobile: 'status',
      render: (r) => (
        <Badge size="sm" tone={r.reason === 'manual' ? 'warn' : 'neutral'}>
          {REASON_LABEL[r.reason]}
        </Badge>
      ),
    },
    { key: 'by', header: 'By', width: '140px', mobile: 'detail', render: (r) => (r.actor.type === 'user' ? (r.actor.name ?? 'Platform team') : 'Automatic') },
    { key: 'note', header: 'Note', mobile: 'detail', render: (r) => r.note ?? <span className={styles.faint}>—</span> },
    {
      key: 'when',
      header: 'When',
      width: '120px',
      mobile: 'detail',
      render: (r) => (
        <time dateTime={r.createdAt} className={styles.nowrap}>
          {formatRelative(r.createdAt, now)}
        </time>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Placements"
        count={data ? plural(data.total, 'placement') : undefined}
        description="Every position taken and every move: by the sponsor’s choice, by spillover, or by the platform team with a reason."
      />
      <AffiliateTabs />
      <PrototypeNote>A demo history.</PrototypeNote>
      {list.status === 'error' && !data ? (
        <PlatformError title="The placements didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title="No placements yet">Placements appear as affiliates join.</StateMessage>
      ) : (
        <>
          <DataTable<PlacementHistoryRow>
            rows={data.rows}
            columns={columns}
            rowKey={(r) => r.id}
            label="Placements"
            rowLabel={(r) => r.affiliate.name}
            framed
          />
          {data.total > data.pageSize && (
            <div className={styles.formActions}>
              <Button disabled={page <= 1} onClick={() => goTo(page - 1)}>
                Previous
              </Button>
              <Button disabled={page * data.pageSize >= data.total} onClick={() => goTo(page + 1)}>
                Next
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
