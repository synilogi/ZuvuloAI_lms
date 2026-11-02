import { useState } from 'react';
import { Link } from 'react-router-dom';
import { DotsThreeVertical, HandCoins, MagnifyingGlass, Prohibit, Receipt } from '@phosphor-icons/react';
import type { Invoice, PaymentStatus } from '@syniastrolms/domain';
import { invoiceTotal } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useViewport } from '@/hooks/useViewport';
import { formatDate, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { RecordPaymentDialog, VoidInvoiceDialog, isOpenInvoice } from './InvoiceActions';
import { InvoiceDialog } from './InvoiceDialog';
import {
  Fact,
  MethodLine,
  PAGE_SIZE,
  PaymentStatusBadge,
  PrototypeNote,
  SUBS_BASE,
  SubscriptionTabs,
  cycleLabel,
  money,
  rangeSummary,
  useListParams,
} from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/**
 * Every invoice the platform raised, and what came of it. An open invoice can be settled by a payment the
 * academy made outside the gateway, or withdrawn.
 */
export default function BillingPage() {
  const { isMobile } = useViewport();
  const toast = useToast();
  const { params, update, reset, page } = useListParams();
  const [invoiceId, setInvoiceId] = useState<string | null>(null);
  const [recording, setRecording] = useState<Invoice | null>(null);
  const [voiding, setVoiding] = useState<Invoice | null>(null);

  const search = params.get('q') ?? '';
  const status = (params.get('status') as PaymentStatus | 'all' | null) ?? 'all';
  const planId = params.get('plan') ?? '';

  const query = { search, status, planId: planId || undefined, page, pageSize: PAGE_SIZE };
  const list = useAsync(`subs:payments:${JSON.stringify(query)}`, () => services.subscriptions.listPayments(query));
  const plans = useAsync('subs:plan-options', () => services.subscriptions.listPlans());
  const data = list.data;
  const rows = data?.rows ?? [];
  const filtered = Boolean(search || planId || status !== 'all');
  const reload = async () => {
    await list.run().catch(() => undefined);
  };

  const columns: Column<Invoice>[] = [
    {
      key: 'date',
      header: 'Date',
      width: '120px',
      mobile: 'meta',
      render: (invoice) => (
        <time dateTime={invoice.issuedAt} className={styles.nowrap}>
          {formatDate(invoice.issuedAt)}
        </time>
      ),
    },
    {
      key: 'customer',
      header: 'Customer',
      mobile: 'primary',
      render: (invoice) => (
        <span className={styles.stack}>
          <Link to={`${SUBS_BASE}/subscribers/${invoice.subscriptionId}`} className={styles.cellTitle}>
            {invoice.customerName}
          </Link>
          <span className={styles.cellMeta}>
            {invoice.planName} · {cycleLabel(invoice.cycle)}
          </span>
        </span>
      ),
    },
    {
      key: 'subscription',
      header: 'Subscription',
      width: '130px',
      mobile: 'detail',
      render: (invoice) => (
        <Link to={`${SUBS_BASE}/subscribers/${invoice.subscriptionId}`} className={styles.mono}>
          {invoice.subscriptionId}
        </Link>
      ),
    },
    {
      key: 'amount',
      header: 'Amount',
      width: '140px',
      align: 'end',
      mobile: 'detail',
      render: (invoice) => (
        <span className={styles.stack}>
          <span className={`${styles.amount} ${styles.strong}`}>{money(invoiceTotal(invoice), invoice.currency)}</span>
          <span className={styles.cellMeta}>
            {invoice.currency} · incl. {invoice.taxPercent}% tax
          </span>
        </span>
      ),
    },
    { key: 'status', header: 'Status', width: '120px', mobile: 'status', render: (invoice) => <PaymentStatusBadge status={invoice.status} /> },
    {
      key: 'invoice',
      header: 'Invoice',
      width: '150px',
      mobile: 'detail',
      render: (invoice) => (
        <button type="button" className={`${styles.cellTitle} ${styles.mono}`} onClick={() => setInvoiceId(invoice.id)}>
          {invoice.number}
        </button>
      ),
    },
    { key: 'method', header: 'Payment method', width: '170px', mobile: 'detail', render: (invoice) => <MethodLine method={invoice.method} /> },
    {
      key: 'actions',
      header: 'Actions',
      width: '200px',
      align: 'end',
      mobile: 'hidden',
      render: (invoice) =>
        isOpenInvoice(invoice) ? (
          <span className={styles.rowActions}>
            <Button size="sm" iconStart={<HandCoins size={15} />} onClick={() => setRecording(invoice)} aria-label={`Record a payment for ${invoice.number}`}>
              Record payment
            </Button>
            <Menu
              align="end"
              trigger={(props) => <IconButton size="sm" label={`More for ${invoice.number}`} icon={<DotsThreeVertical size={16} weight="bold" />} {...props} />}
              sections={[
                {
                  items: [
                    { id: 'void', label: 'Withdraw invoice', icon: <Prohibit size={16} />, tone: 'danger' as const, onSelect: () => setVoiding(invoice) },
                  ],
                },
              ]}
            />
          </span>
        ) : null,
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Payments & invoices"
        count={data ? plural(data.counts.all, 'payment') : undefined}
        description="Every invoice sent to an Admin, and whether it has been paid. When an Admin pays by bank transfer, cheque or cash, press Record payment on their waiting invoice."
      />
      <SubscriptionTabs />
      <PrototypeNote>Demo invoices. No money moved, and no invoice document is generated.</PrototypeNote>

      {data && data.counts.all > 0 && (
        <section className={styles.panel} aria-label="Payment totals">
          <dl className={styles.facts}>
            <Fact label="Received" value={money(data.totals.collected, data.totals.currency)} />
            <Fact label="Still to collect" value={money(data.totals.outstanding, data.totals.currency)} />
            <Fact label="Refunded" value={money(data.totals.refunded, data.totals.currency)} />
          </dl>
          <p className={styles.muted}>Totals for everything that matches your filters, not just this page.</p>
        </section>
      )}

      <div className={styles.controls} hidden={data?.counts.all === 0 && !filtered}>
        <SegmentedControl<PaymentStatus | 'all'>
          label="Payment status"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: data?.counts.all },
            { value: 'paid', label: 'Paid', count: data?.counts.paid },
            { value: 'pending', label: 'Waiting', count: data?.counts.pending },
            { value: 'failed', label: 'Failed', count: data?.counts.failed },
            { value: 'refunded', label: 'Refunded', count: data?.counts.refunded },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput
              value={search}
              onValueChange={(v) => update({ q: v })}
              placeholder="Search Admin, invoice number or subscription ID"
              aria-label="Search payments"
            />
          </div>
          <Field label="Plan" className={styles.filter}>
            <Select value={planId} onChange={(e) => update({ plan: e.target.value })}>
              <option value="">All plans</option>
              {plans.data?.rows.map((r) => (
                <option key={r.plan.id} value={r.plan.id}>
                  {r.plan.name}
                </option>
              ))}
            </Select>
          </Field>
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <PlatformError title="Payments didn’t load" error={list.error} onRetry={() => list.run().catch(() => undefined)} />
      ) : data && rows.length === 0 ? (
        filtered ? (
          <StateMessage icon={<MagnifyingGlass size={26} />} title="No payments match" actions={<Button onClick={reset}>Clear filters</Button>}>
            Try an Admin's name, an invoice number, or a different status.
          </StateMessage>
        ) : (
          <StateMessage icon={<Receipt size={26} />} title="No payment history yet">
            Charges appear here as soon as a subscription is billed for the first time.
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label="Payments" aria-busy={!data || undefined}>
          {!data
            ? Array.from({ length: 5 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <div className={styles.cardButton}>
                    <Skeleton width="60%" height={13} />
                    <Skeleton width="80%" height={9} />
                  </div>
                </li>
              ))
            : rows.map((invoice) => (
                <li key={invoice.id} className={styles.card}>
                  <button type="button" className={styles.cardButton} onClick={() => setInvoiceId(invoice.id)}>
                    <span className={styles.cardHead}>
                      <span className={styles.stack}>
                        <span className={styles.cellTitle}>{invoice.customerName}</span>
                        <span className={styles.cellMeta}>
                          {invoice.number} · {formatDate(invoice.issuedAt)}
                        </span>
                      </span>
                      <PaymentStatusBadge status={invoice.status} />
                    </span>
                    <span className={styles.cardFacts}>
                      <span className={styles.strong}>{money(invoiceTotal(invoice), invoice.currency)}</span>
                      <span>{invoice.planName}</span>
                      <MethodLine method={invoice.method} />
                    </span>
                  </button>
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Payments"
            rows={rows}
            columns={columns}
            rowKey={(invoice) => invoice.id}
            rowLabel={(invoice) => `${invoice.number} — ${invoice.customerName}`}
            loading={!data}
            skeletonRows={8}
          />
        </div>
      )}

      {data && data.total > PAGE_SIZE && (
        <Pagination
          page={page}
          pageCount={Math.ceil(data.total / PAGE_SIZE)}
          onChange={(p) => update({ page: String(p) }, true)}
          summary={rangeSummary(data.total, page, PAGE_SIZE, 'payments')}
        />
      )}

      <InvoiceDialog invoiceId={invoiceId} onClose={() => setInvoiceId(null)} onChanged={reload} />
      <RecordPaymentDialog
        invoice={recording}
        onClose={() => setRecording(null)}
        onDone={async (outcome) => {
          setRecording(null);
          toast({ kind: outcome.status === 'failed' ? 'error' : outcome.settled ? 'success' : 'info', title: 'Payment recorded', text: outcome.message });
          await reload();
        }}
      />
      <VoidInvoiceDialog
        invoice={voiding}
        onClose={() => setVoiding(null)}
        onDone={async (voided) => {
          setVoiding(null);
          toast({ kind: 'success', title: `${voided.number} is withdrawn`, text: 'It can no longer be paid, and stays on the record.' });
          await reload();
        }}
      />
    </div>
  );
}
