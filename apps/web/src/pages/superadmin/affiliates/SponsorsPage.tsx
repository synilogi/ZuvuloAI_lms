import { Link, useSearchParams } from 'react-router-dom';
import type { SponsorRow } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { SearchInput } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AFFILIATES_BASE, AffiliateStatusBadge, AffiliateTabs } from './affiliateMeta';
import styles from './Affiliates.module.css';

/** Who refers (MLM-002): every sponsor with how many they brought in and how many of those activated. */
export default function SponsorsPage() {
  const [params, setParams] = useSearchParams();
  const search = params.get('q') ?? '';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v) p.delete(k);
      else p.set(k, v);
    }
    if (!('page' in next)) p.delete('page');
    setParams(p, { replace: true });
  };
  const list = useAsync(`affiliates:sponsors:${search}:${page}`, () =>
    services.affiliatesPlatform.sponsors({ search: search || undefined, page, pageSize: 20 }),
  );
  const data = list.data;

  const columns: Column<SponsorRow>[] = [
    {
      key: 'sponsor',
      header: 'Sponsor',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <Link to={`${AFFILIATES_BASE}/members/${r.id}`} className={styles.cellTitle}>
            {r.name}
          </Link>
          <span className={styles.cellMeta}>{r.code}</span>
        </span>
      ),
    },
    { key: 'referrals', header: 'Referred', width: '110px', mobile: 'meta', render: (r) => <span className={styles.amount}>{r.directReferrals}</span> },
    { key: 'active', header: 'Activated', width: '110px', mobile: 'detail', render: (r) => <span className={styles.amount}>{r.activeReferrals}</span> },
    {
      key: 'rate',
      header: 'Activation rate',
      width: '130px',
      mobile: 'detail',
      render: (r) => `${r.directReferrals ? Math.round((100 * r.activeReferrals) / r.directReferrals) : 0}%`,
    },
    { key: 'status', header: 'Status', width: '110px', mobile: 'status', render: (r) => <AffiliateStatusBadge status={r.status} /> },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Sponsors"
        count={data ? plural(data.total, 'sponsor') : undefined}
        description="Who is bringing people in, and how many of them activate. A sponsor is who referred someone; where they were placed is the tree’s business."
      />
      <AffiliateTabs />
      <PrototypeNote>A demo network.</PrototypeNote>
      <div className={styles.controls}>
        <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Name or code" aria-label="Search sponsors" />
      </div>
      {list.status === 'error' && !data ? (
        <PlatformError title="The sponsors didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title="No sponsors yet">Sponsors appear once an affiliate refers somebody.</StateMessage>
      ) : (
        <>
          <DataTable<SponsorRow> rows={data.rows} columns={columns} rowKey={(r) => r.id} label="Sponsors" rowLabel={(r) => r.name} framed />
          {data.total > data.pageSize && (
            <div className={styles.formActions}>
              <Button disabled={page <= 1} onClick={() => update({ page: String(page - 1) })}>
                Previous
              </Button>
              <Button disabled={page * data.pageSize >= data.total} onClick={() => update({ page: String(page + 1) })}>
                Next
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
