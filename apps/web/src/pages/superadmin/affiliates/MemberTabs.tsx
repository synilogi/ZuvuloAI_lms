import { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  formatMoney,
  MLM_KYC_STATUS_LABEL,
  MLM_REWARD_STATUS_LABEL,
  MLM_WALLET_ENTRY_LABEL,
  type MlmMatchingRunRow,
  type MlmOrderRow,
  type MlmRewardRow,
  type MlmWalletEntryRow,
} from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { Badge } from '@/components/ui/Badge/Badge';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { formatDate, formatMoment } from '@/lib/format';
import { services, ServiceError } from '@/services';
import { PlatformError } from '../platformMeta';
import { AFFILIATES_BASE, cvText, OrderStatusBadge, REWARD_KIND_LABEL } from './affiliateMeta';
import { Pager } from './earningsParts';
import styles from './Affiliates.module.css';

/* The sections of a member's page: what the program's lists show, narrowed to this one person. Reads only; the actions stay on their own pages. */

const inr = (n: number) => formatMoney(n, 'INR');
const signed = (n: number) => (n === 0 ? '' : n < 0 ? `− ${inr(-n)}` : `+ ${inr(n)}`);

function Fact({ label, value }: { label: string; value: string }) {
  return (
    <div className={styles.fact}>
      <span className={styles.factLabel}>{label}</span>
      <span className={styles.factValue}>{value}</span>
    </div>
  );
}

export function MemberWallet({ memberId, code }: { memberId: string; code: string }) {
  const [page, setPage] = useState(1);
  const wallets = useAsync(`affiliates:member-wallet:${code}`, () => services.platformEarnings.wallets({ search: code }));
  const entries = useAsync(`affiliates:member-entries:${memberId}:${page}`, () => services.platformEarnings.walletEntries(memberId, { page }));
  const wallet = wallets.data?.rows.find((w) => w.affiliate.id === memberId);
  const columns: Column<MlmWalletEntryRow>[] = [
    {
      key: 'type',
      header: 'Entry',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <span>{MLM_WALLET_ENTRY_LABEL[r.type]}</span>
          {r.note && <span className={styles.cellMeta}>{r.note}</span>}
        </span>
      ),
    },
    { key: 'available', header: 'Available', mobile: 'meta', render: (r) => signed(r.availableDelta) },
    { key: 'held', header: 'In withdrawals', mobile: 'detail', render: (r) => signed(r.heldDelta) },
    { key: 'paid', header: 'Paid out', mobile: 'detail', render: (r) => signed(r.paidDelta) },
    { key: 'date', header: 'Date', mobile: 'detail', render: (r) => formatMoment(r.createdAt) },
  ];
  return (
    <section className={styles.panel} aria-label="Wallet">
      {wallets.status === 'error' && !wallets.data ? (
        <PlatformError title="The balances didn’t load" error={wallets.error} onRetry={() => void wallets.run().catch(() => undefined)} />
      ) : !wallets.data ? (
        <Skeleton height={64} radius="var(--r-md)" />
      ) : (
        <div className={styles.facts}>
          <Fact label="Available" value={inr(wallet?.available ?? 0)} />
          <Fact label="In withdrawals" value={inr(wallet?.held ?? 0)} />
          <Fact label="Paid out" value={inr(wallet?.paid ?? 0)} />
          <Fact label="On hold" value={inr(wallet?.heldByPolicy ?? 0)} />
        </div>
      )}
      {entries.status === 'error' && !entries.data ? (
        <PlatformError title="The ledger didn’t load" error={entries.error} onRetry={() => void entries.run().catch(() => undefined)} />
      ) : !entries.data ? (
        <Skeleton height={160} radius="var(--r-md)" />
      ) : entries.data.rows.length === 0 ? (
        <StateMessage title="No entries yet">A wallet entry appears with the member’s first credit.</StateMessage>
      ) : (
        <>
          <DataTable<MlmWalletEntryRow> rows={entries.data.rows} columns={columns} rowKey={(r) => r.id} label="Wallet entries" rowLabel={(r) => r.type} />
          <Pager page={page} pageSize={entries.data.pageSize} total={entries.data.total} onPage={setPage} />
        </>
      )}
    </section>
  );
}

export function MemberKyc({ memberId }: { memberId: string }) {
  const kyc = useAsync(`affiliates:member-kyc:${memberId}`, () => services.platformEarnings.memberKyc(memberId));
  const none = kyc.status === 'error' && kyc.error instanceof ServiceError && kyc.error.code === 'not-found';
  return (
    <section className={styles.panel} aria-label="Identity check">
      {none ? (
        <StateMessage title="Nothing submitted">This member hasn’t submitted an identity check.</StateMessage>
      ) : kyc.status === 'error' && !kyc.data ? (
        <PlatformError title="The identity check didn’t load" error={kyc.error} onRetry={() => void kyc.run().catch(() => undefined)} />
      ) : !kyc.data ? (
        <Skeleton height={140} radius="var(--r-md)" />
      ) : (
        <>
          <div className={styles.panelHead}>
            <Badge tone={kyc.data.status === 'verified' ? 'accent' : kyc.data.status === 'rejected' ? 'warn' : 'info'}>
              {MLM_KYC_STATUS_LABEL[kyc.data.status]}
            </Badge>
            <Link to={`${AFFILIATES_BASE}/kyc?status=${kyc.data.status === 'none' ? 'submitted' : kyc.data.status}`}>Open the review queue</Link>
          </div>
          <div className={styles.facts}>
            <Fact label="Legal name" value={kyc.data.legalName} />
            <Fact label="PAN" value={`••••••${kyc.data.panLast4}`} />
            <Fact label="Bank account" value={`••••${kyc.data.bankAccountLast4}`} />
            <Fact label="IFSC" value={kyc.data.ifsc} />
            <Fact label="Account holder" value={kyc.data.accountHolder} />
            <Fact label="UPI" value={kyc.data.upiId ?? 'None'} />
            <Fact label="Submitted" value={kyc.data.submittedAt ? formatDate(kyc.data.submittedAt) : '—'} />
            <Fact label="Reviewed" value={kyc.data.reviewedAt ? formatDate(kyc.data.reviewedAt) : 'Not yet'} />
            <Fact label="Documents" value={kyc.data.documents.length ? kyc.data.documents.map((d) => d.name).join(', ') : 'None'} />
          </div>
          {kyc.data.rejectionReason && <p className={styles.panelHint}>Sent back: {kyc.data.rejectionReason}</p>}
        </>
      )}
    </section>
  );
}

export function MemberOrders({ code }: { code: string }) {
  const [page, setPage] = useState(1);
  const orders = useAsync(`affiliates:member-orders:${code}:${page}`, () => services.affiliatesPlatform.orders({ search: code, page, pageSize: 20 }));
  const columns: Column<MlmOrderRow>[] = [
    { key: 'course', header: 'Course', mobile: 'primary', render: (o) => o.course.title },
    { key: 'amount', header: 'Amount', width: '120px', mobile: 'meta', render: (o) => inr(o.netAmount) },
    { key: 'cv', header: 'CV', width: '120px', mobile: 'detail', render: (o) => cvText(o.cv) },
    { key: 'paid', header: 'Paid', width: '150px', mobile: 'detail', render: (o) => formatMoment(o.paidAt) },
    { key: 'status', header: 'Status', width: '110px', mobile: 'status', render: (o) => <OrderStatusBadge status={o.status} /> },
  ];
  return (
    <section className={styles.panel} aria-label="Orders">
      {orders.status === 'error' && !orders.data ? (
        <PlatformError title="The orders didn’t load" error={orders.error} onRetry={() => void orders.run().catch(() => undefined)} />
      ) : !orders.data ? (
        <Skeleton height={160} radius="var(--r-md)" />
      ) : orders.data.rows.length === 0 ? (
        <StateMessage title="No orders">This member hasn’t bought an eligible course.</StateMessage>
      ) : (
        <>
          <DataTable<MlmOrderRow> rows={orders.data.rows} columns={columns} rowKey={(o) => o.id} label="Orders" rowLabel={(o) => o.course.title} />
          <Pager page={page} pageSize={orders.data.pageSize} total={orders.data.total} onPage={setPage} />
        </>
      )}
    </section>
  );
}

export function MemberMatching({ memberId }: { memberId: string }) {
  const [page, setPage] = useState(1);
  const runs = useAsync(`affiliates:member-runs:${memberId}:${page}`, () => services.platformEarnings.matchingRuns({ affiliateId: memberId, page }));
  const columns: Column<MlmMatchingRunRow>[] = [
    { key: 'date', header: 'Day', width: '110px', mobile: 'primary', render: (r) => r.runDate },
    { key: 'matched', header: 'Matched', mobile: 'meta', render: (r) => cvText(r.matchedCv) },
    { key: 'gross', header: 'Before cap', mobile: 'detail', render: (r) => inr(r.grossIncome) },
    { key: 'paid', header: 'After cap', mobile: 'detail', render: (r) => inr(r.cappedIncome) },
    { key: 'flushed', header: 'Flushed', mobile: 'detail', render: (r) => cvText(r.flushedCv) },
    { key: 'carry', header: 'Carried A / B', mobile: 'detail', render: (r) => `${cvText(r.carryAAfter)} / ${cvText(r.carryBAfter)}` },
    { key: 'held', header: 'Held', mobile: 'detail', render: (r) => inr(r.heldByCeiling) },
  ];
  return (
    <section className={styles.panel} aria-label="Matching runs">
      {runs.status === 'error' && !runs.data ? (
        <PlatformError title="The runs didn’t load" error={runs.error} onRetry={() => void runs.run().catch(() => undefined)} />
      ) : !runs.data ? (
        <Skeleton height={160} radius="var(--r-md)" />
      ) : runs.data.rows.length === 0 ? (
        <StateMessage title="No runs yet">A run appears once this member has volume on both legs.</StateMessage>
      ) : (
        <>
          <DataTable<MlmMatchingRunRow> rows={runs.data.rows} columns={columns} rowKey={(r) => r.id} label="Matching runs" rowLabel={(r) => r.runDate} />
          <Pager page={page} pageSize={runs.data.pageSize} total={runs.data.total} onPage={setPage} />
        </>
      )}
    </section>
  );
}

export function MemberRewards({ memberId }: { memberId: string }) {
  const [page, setPage] = useState(1);
  const rewards = useAsync(`affiliates:member-rewards:${memberId}:${page}`, () => services.platformEarnings.rewards({ affiliateId: memberId, page }));
  const columns: Column<MlmRewardRow>[] = [
    { key: 'rank', header: 'Rank', mobile: 'primary', render: (r) => r.tierName },
    { key: 'reward', header: 'Reward', mobile: 'meta', render: (r) => (r.kind === 'cash' ? inr(r.amount) : REWARD_KIND_LABEL[r.kind]) },
    { key: 'status', header: 'Status', mobile: 'status', render: (r) => <Badge size="sm">{MLM_REWARD_STATUS_LABEL[r.status]}</Badge> },
    { key: 'vests', header: 'Vests', width: '120px', mobile: 'detail', render: (r) => (r.vestsAt ? formatDate(r.vestsAt) : '') },
  ];
  return (
    <section className={styles.panel} aria-label="Rewards">
      {rewards.status === 'error' && !rewards.data ? (
        <PlatformError title="The rewards didn’t load" error={rewards.error} onRetry={() => void rewards.run().catch(() => undefined)} />
      ) : !rewards.data ? (
        <Skeleton height={160} radius="var(--r-md)" />
      ) : rewards.data.rows.length === 0 ? (
        <StateMessage title="No rewards">A reward appears when this member reaches a rank.</StateMessage>
      ) : (
        <>
          <DataTable<MlmRewardRow> rows={rewards.data.rows} columns={columns} rowKey={(r) => r.id} label="Rewards" rowLabel={(r) => r.tierName} />
          <Pager page={page} pageSize={rewards.data.pageSize} total={rewards.data.total} onPage={setPage} />
        </>
      )}
    </section>
  );
}
