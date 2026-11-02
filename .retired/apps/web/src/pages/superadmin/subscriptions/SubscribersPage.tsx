import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { FunnelSimple, MagnifyingGlass, Users } from '@phosphor-icons/react';
import type { BillingCycle, PaymentStatus, SubscriptionStatus } from '@syniastrolms/domain';
import { SUBSCRIPTION_STATUSES } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useViewport } from '@/hooks/useViewport';
import { formatDate, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, Input, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { BottomSheet } from '@/components/overlays/Overlay';
import { services, type SubscriberSort, type SubscriptionRow } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import {
  MethodLine,
  PAGE_SIZE,
  PaymentStatusBadge,
  PrototypeNote,
  SUBSCRIPTION_STATE,
  SUBS_BASE,
  SubscriptionStatusBadge,
  SubscriptionTabs,
  cycleLabel,
  cyclePer,
  money,
  rangeSummary,
  useListParams,
} from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/** The academies on the platform, what they pay and where each subscription stands. */
export default function SubscribersPage() {
  const navigate = useNavigate();
  const { isMobile } = useViewport();
  const { params, update, reset, page } = useListParams();
  const [sheetOpen, setSheetOpen] = useState(false);

  const search = params.get('q') ?? '';
  const planId = params.get('plan') ?? '';
  const status = (params.get('status') as SubscriptionStatus | 'all' | null) ?? 'all';
  const cycle = (params.get('cycle') as BillingCycle | 'all' | null) ?? 'all';
  const payment = (params.get('payment') as PaymentStatus | 'all' | null) ?? 'all';
  const from = params.get('from') ?? '';
  const to = params.get('to') ?? '';
  const sort = (params.get('sort') as SubscriberSort | null) ?? 'renewal';

  const query = { search, planId: planId || undefined, status, cycle, payment, from: from || undefined, to: to || undefined, sort, page, pageSize: PAGE_SIZE };
  const list = useAsync(`subs:subscribers:${JSON.stringify(query)}`, () => services.subscriptions.listSubscribers(query));
  const plans = useAsync('subs:plan-options', () => services.subscriptions.listPlans());
  const data = list.data;
  const rows = data?.rows ?? [];
  const filtered = Boolean(search || planId || status !== 'all' || cycle !== 'all' || payment !== 'all' || from || to);
  const activeFilters = [planId, cycle !== 'all' ? cycle : '', payment !== 'all' ? payment : '', from, to].filter(Boolean).length;

  const href = (row: SubscriptionRow) => `${SUBS_BASE}/subscribers/${row.subscription.id}`;

  const filterFields = (
    <>
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
      <Field label="Billing cycle" className={styles.filterNarrow}>
        <Select value={cycle} onChange={(e) => update({ cycle: e.target.value })}>
          <option value="all">Any cycle</option>
          <option value="monthly">Monthly</option>
          <option value="annual">Annual</option>
        </Select>
      </Field>
      <Field label="Payment status" className={styles.filterNarrow}>
        <Select value={payment} onChange={(e) => update({ payment: e.target.value })}>
          <option value="all">Any payment status</option>
          <option value="paid">Paid</option>
          <option value="pending">Pending</option>
          <option value="failed">Failed</option>
          <option value="refunded">Refunded</option>
        </Select>
      </Field>
      <Field label="Renews from" className={styles.filterNarrow}>
        <Input type="date" value={from} onChange={(e) => update({ from: e.target.value })} max={to || undefined} />
      </Field>
      <Field label="Renews until" className={styles.filterNarrow}>
        <Input type="date" value={to} onChange={(e) => update({ to: e.target.value })} min={from || undefined} />
      </Field>
      <Field label="Sort by" className={styles.filter}>
        <Select value={sort} onChange={(e) => update({ sort: e.target.value })}>
          <option value="renewal">Renewal date, soonest first</option>
          <option value="started">Newest subscription</option>
          <option value="customer">Admin / LMS name</option>
          <option value="amount">Highest amount</option>
        </Select>
      </Field>
    </>
  );

  const columns: Column<SubscriptionRow>[] = [
    {
      key: 'customer',
      header: 'Admin',
      mobile: 'primary',
      render: ({ subscription }) => (
        <span className={styles.method}>
          <Avatar name={subscription.customer.name} size={30} />
          <span className={styles.stack}>
            <Link to={`${SUBS_BASE}/subscribers/${subscription.id}`} className={styles.cellTitle}>
              {subscription.customer.name}
            </Link>
            <span className={styles.cellMeta}>{subscription.customer.email}</span>
          </span>
        </span>
      ),
    },
    {
      key: 'plan',
      header: 'Plan',
      width: '150px',
      mobile: 'meta',
      render: (row) => (
        <span className={styles.stack}>
          <span>{row.planName}</span>
          <span className={styles.cellMeta}>{cycleLabel(row.subscription.cycle)}</span>
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      width: '120px',
      mobile: 'status',
      render: ({ subscription }) => <SubscriptionStatusBadge status={subscription.status} />,
    },
    {
      key: 'started',
      header: 'Started',
      width: '120px',
      mobile: 'detail',
      render: ({ subscription }) => (
        <time dateTime={subscription.startedAt} className={styles.nowrap}>
          {formatDate(subscription.startedAt)}
        </time>
      ),
    },
    {
      key: 'renewal',
      header: 'Renews on',
      width: '130px',
      mobile: 'detail',
      render: ({ subscription }) =>
        subscription.status === 'canceled' || subscription.status === 'expired' ? (
          <span className={styles.faint}>Ended {formatDate(subscription.renewsAt)}</span>
        ) : (
          <time dateTime={subscription.renewsAt} className={styles.nowrap}>
            {formatDate(subscription.renewsAt)}
          </time>
        ),
    },
    {
      key: 'amount',
      header: 'Amount',
      width: '140px',
      align: 'end',
      mobile: 'detail',
      render: ({ subscription }) => (
        <span className={`${styles.amount} ${styles.strong}`}>
          {money(subscription.amount, subscription.currency)} <span className={styles.faint}>{cyclePer(subscription.cycle)}</span>
        </span>
      ),
    },
    {
      key: 'payment',
      header: 'Last payment',
      width: '160px',
      mobile: 'detail',
      render: ({ subscription }) => (
        <span className={styles.stack}>
          {subscription.lastPaymentStatus ? (
            <PaymentStatusBadge status={subscription.lastPaymentStatus} />
          ) : (
            <span className={styles.faint}>Not charged yet</span>
          )}
          <MethodLine method={subscription.paymentMethod} />
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      width: '90px',
      align: 'end',
      mobile: 'hidden',
      render: (row) => (
        <LinkButton size="sm" variant={row.subscription.status === 'past-due' ? 'primary' : 'secondary'} to={href(row)}>
          {row.subscription.status === 'past-due' ? 'Review' : 'Open'}
        </LinkButton>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Subscriptions"
        count={data ? plural(data.counts.all, 'subscription') : undefined}
        description="Every Admin with a subscription: their plan, what they pay and when it renews. Open one to change the plan, record a payment, add free days or cancel."
      />
      <SubscriptionTabs />
      <PrototypeNote />

      <div className={styles.controls} hidden={data?.counts.all === 0 && !filtered}>
        <SegmentedControl<SubscriptionStatus | 'all'>
          label="Show"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: data?.counts.all },
            ...SUBSCRIPTION_STATUSES.map((s) => ({
              value: s,
              label: SUBSCRIPTION_STATE[s].label,
              count: data?.counts[s],
            })),
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput
              value={search}
              onValueChange={(v) => update({ q: v })}
              placeholder="Search Admin, email or subscription ID"
              aria-label="Search subscribers"
            />
          </div>
          {isMobile ? (
            <Button onClick={() => setSheetOpen(true)} iconStart={<FunnelSimple size={16} />} block>
              Filters{activeFilters > 0 ? ` (${activeFilters})` : ''}
            </Button>
          ) : (
            filterFields
          )}
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <PlatformError title="Subscribers didn’t load" error={list.error} onRetry={() => list.run().catch(() => undefined)} />
      ) : data && rows.length === 0 ? (
        filtered ? (
          <StateMessage icon={<MagnifyingGlass size={26} />} title="No subscriptions match" actions={<Button onClick={reset}>Clear filters</Button>}>
            Try changing the filters or search terms.
          </StateMessage>
        ) : (
          <StateMessage icon={<Users size={26} />} title="No subscriptions yet">
            Admins appear here as soon as they start a trial or a paid subscription.
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label="Subscribers" aria-busy={!data || undefined}>
          {!data
            ? Array.from({ length: 5 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <div className={styles.cardButton}>
                    <Skeleton width="65%" height={13} />
                    <Skeleton width="85%" height={9} />
                  </div>
                </li>
              ))
            : rows.map((row) => (
                <li key={row.subscription.id} className={styles.card}>
                  <button type="button" className={styles.cardButton} onClick={() => navigate(href(row))}>
                    <span className={styles.cardHead}>
                      <span className={styles.method}>
                        <Avatar name={row.subscription.customer.name} size={34} />
                        <span className={styles.stack}>
                          <span className={styles.cellTitle}>{row.subscription.customer.name}</span>
                          <span className={styles.cellMeta}>
                            {row.planName} · {cycleLabel(row.subscription.cycle)}
                          </span>
                        </span>
                      </span>
                      <SubscriptionStatusBadge status={row.subscription.status} />
                    </span>
                    <span className={styles.cardFacts}>
                      <span className={styles.strong}>
                        {money(row.subscription.amount, row.subscription.currency)} {cyclePer(row.subscription.cycle)}
                      </span>
                      <span>Renews {formatDate(row.subscription.renewsAt)}</span>
                      <MethodLine method={row.subscription.paymentMethod} />
                    </span>
                  </button>
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Subscribers"
            rows={rows}
            columns={columns}
            rowKey={(row) => row.subscription.id}
            rowLabel={(row) => row.subscription.customer.name}
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
          summary={rangeSummary(data.total, page, PAGE_SIZE, 'subscriptions')}
        />
      )}

      <BottomSheet
        open={sheetOpen}
        onClose={() => setSheetOpen(false)}
        title="Filter subscriptions"
        footer={
          <>
            <Button onClick={reset}>Clear all</Button>
            <Button variant="primary" onClick={() => setSheetOpen(false)}>
              Show results
            </Button>
          </>
        }
      >
        <div className={styles.controls}>{filterFields}</div>
      </BottomSheet>
    </div>
  );
}
