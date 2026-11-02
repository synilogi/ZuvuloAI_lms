import { useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { MLM_KYC_STATUS_LABEL, type MlmKycRow, type MlmKycStatus } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useAsync } from '@/hooks/useAsync';
import { formatMoment } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AffiliateTabs } from './affiliateMeta';
import { ActionDialog, Pager, type Pending } from './earningsParts';
import styles from './Affiliates.module.css';

/** The identity-check queue (docs/15 §6.9). PAN and account numbers are sealed at rest and only their last digits show here. */
export default function KycPage() {
  const [params, setParams] = useSearchParams();
  const status = (params.get('status') as MlmKycStatus | null) ?? 'submitted';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const list = useAsync(`mlm:kyc:${status}:${page}`, () => services.platformEarnings.kyc({ status, page }));
  const [pending, setPending] = useState<Pending | null>(null);
  const data = list.data;
  const toast = useToast();
  const openDocument = async (affiliateId: string, assetId: string) => {
    try {
      const url = URL.createObjectURL(await services.platformEarnings.kycDocument(affiliateId, assetId));
      window.open(url, '_blank', 'noopener');
      window.setTimeout(() => URL.revokeObjectURL(url), 60_000);
    } catch (err) {
      toast({ kind: 'error', title: 'The document didn’t open', text: (err as Error).message });
    }
  };

  const columns: Column<MlmKycRow>[] = [
    {
      key: 'member',
      header: 'Member',
      mobile: 'primary',
      render: (k) => (
        <span className={styles.stack}>
          <span>
            {k.affiliate.name} · {k.affiliate.code}
          </span>
          {k.rejectionReason && <span className={styles.cellMeta}>{k.rejectionReason}</span>}
          {k.documents.map((d) => (
            <button key={d.id} type="button" className={styles.cellTitle} onClick={() => void openDocument(k.affiliate.id, d.id)}>
              {d.name}
            </button>
          ))}
        </span>
      ),
    },
    { key: 'legal', header: 'Legal name', mobile: 'detail', render: (k) => k.legalName },
    { key: 'pan', header: 'PAN', width: '110px', mobile: 'detail', render: (k) => `••••••${k.panLast4}` },
    { key: 'bank', header: 'Bank', mobile: 'detail', render: (k) => `${k.accountHolder} · ••••${k.bankAccountLast4} · ${k.ifsc}` },
    { key: 'date', header: 'Submitted', mobile: 'detail', render: (k) => (k.submittedAt ? formatMoment(k.submittedAt) : '') },
    {
      key: 'status',
      header: 'Status',
      mobile: 'status',
      render: (k) => (
        <Badge size="sm" tone={k.status === 'verified' ? 'accent' : k.status === 'rejected' ? 'warn' : 'info'}>
          {MLM_KYC_STATUS_LABEL[k.status]}
        </Badge>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      align: 'end',
      mobile: 'detail',
      render: (k) =>
        k.status === 'submitted' ? (
          <span className={styles.rowActions}>
            <Button
              size="sm"
              variant="primary"
              onClick={() =>
                setPending({
                  title: `Verify ${k.legalName}?`,
                  text: 'Confirm you have checked these details. The member can then request withdrawals to this account.',
                  confirmLabel: 'Verify',
                  run: () => services.platformEarnings.verifyKyc(k.affiliate.id),
                  done: 'Identity verified',
                })
              }
            >
              Verify
            </Button>
            <Button
              size="sm"
              onClick={() =>
                setPending({
                  title: `Send back ${k.legalName}’s details?`,
                  text: 'The member sees your reason and can submit again.',
                  confirmLabel: 'Send back',
                  input: { label: 'What needs to change', min: 3, multiline: true },
                  run: (reason) => services.platformEarnings.rejectKyc(k.affiliate.id, reason),
                  done: 'Sent back to the member',
                })
              }
            >
              Send back
            </Button>
          </span>
        ) : null,
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Identity checks"
        description="A member must be verified before they can withdraw. A change to verified details comes back here."
      />
      <AffiliateTabs />
      <PrototypeNote>The demo build stores no identity details.</PrototypeNote>
      <div className={styles.controls}>
        <SegmentedControl<MlmKycStatus>
          label="Status"
          value={status}
          onChange={(v) => setParams({ status: v }, { replace: true })}
          segments={[
            { value: 'submitted', label: 'To review' },
            { value: 'verified', label: 'Verified' },
            { value: 'rejected', label: 'Sent back' },
          ]}
        />
      </div>
      {list.status === 'error' && !data ? (
        <PlatformError title="The queue didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : data.rows.length === 0 ? (
        <StateMessage title="Nothing here">Submitted details appear here for review.</StateMessage>
      ) : (
        <>
          <DataTable<MlmKycRow>
            rows={data.rows}
            columns={columns}
            rowKey={(k) => k.affiliate.id}
            label="Identity checks"
            rowLabel={(k) => k.affiliate.code}
            framed
          />
          <Pager page={page} pageSize={data.pageSize} total={data.total} onPage={(n) => setParams({ status, page: String(n) }, { replace: true })} />
        </>
      )}
      <ActionDialog pending={pending} onClose={() => setPending(null)} onDone={() => list.run()} />
    </div>
  );
}
