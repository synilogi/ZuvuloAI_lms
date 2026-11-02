import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Archive, ArrowCounterClockwise, Copy, DotsThreeVertical, MagnifyingGlass, PencilSimple, Plus, RocketLaunch, Stack } from '@phosphor-icons/react';
import type { PlanStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, type PlanRow, type PlanSort } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PlanStatusBadge, PrototypeNote, SUBS_BASE, SubscriptionTabs, cyclePer, headlinePrice, money, useListParams } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/**
 * Every plan the platform offers, draft or archived included. A plan is configuration: archiving
 * one closes it to new sign-ups and leaves the academies already on it exactly where they are.
 */
export default function PlansPage() {
  const now = useNow();
  const toast = useToast();
  const navigate = useNavigate();
  const { isMobile } = useViewport();
  const { params, update, reset } = useListParams();

  const search = params.get('q') ?? '';
  const status = (params.get('status') as PlanStatus | 'all' | null) ?? 'all';
  const sort = (params.get('sort') as PlanSort | null) ?? 'name';
  const [archiving, setArchiving] = useState<PlanRow | null>(null);
  const [publishing, setPublishing] = useState<PlanRow | null>(null);

  const query = { search, status, sort };
  const list = useAsync(`subs:plans:${JSON.stringify(query)}`, () => services.subscriptions.listPlans(query));
  const data = list.data;
  const rows = data?.rows ?? [];
  const filtered = Boolean(search || status !== 'all');
  const reload = () => list.run().catch(() => undefined);

  const duplicate = async (row: PlanRow) => {
    try {
      const copy = await services.subscriptions.duplicatePlan(row.plan.id);
      toast({
        kind: 'success',
        title: `${copy.name} created`,
        text: `Saved as a draft with the code ${copy.code}. Nobody can buy it until it is made active.`,
      });
      await reload();
      navigate(`${SUBS_BASE}/plans/${copy.id}/edit`);
    } catch (error) {
      toast({ kind: 'error', title: 'Couldn’t duplicate the plan', text: (error as Error).message });
    }
  };

  const changeArchive = async () => {
    const row = archiving;
    if (!row) return;
    const wasArchived = row.plan.status === 'archived';
    const plan = wasArchived ? await services.subscriptions.restorePlan(row.plan.id) : await services.subscriptions.archivePlan(row.plan.id);
    setArchiving(null);
    toast({
      kind: 'success',
      title: wasArchived ? `${plan.name} is back on sale` : `${plan.name} is retired`,
      text: wasArchived ? 'It can be chosen for new subscriptions from now on.' : 'New sign-ups can’t choose it. The Admins on it keep it.',
    });
    await reload();
  };

  const publish = async () => {
    if (!publishing) return;
    const plan = await services.subscriptions.publishPlan(publishing.plan.id);
    setPublishing(null);
    toast({ kind: 'success', title: `${plan.name} is on sale`, text: 'New Admins can choose it from now on.' });
    await reload();
  };

  const to = (row: PlanRow) => `${SUBS_BASE}/plans/${row.plan.id}`;

  const rowMenu = (row: PlanRow) => (
    <Menu
      align="end"
      trigger={(props) => <IconButton size="sm" label={`Actions for ${row.plan.name}`} icon={<DotsThreeVertical size={16} weight="bold" />} {...props} />}
      sections={[
        {
          items: [
            { id: 'edit', label: 'Edit plan', icon: <PencilSimple size={16} />, onSelect: () => navigate(`${to(row)}/edit`) },
            { id: 'duplicate', label: 'Duplicate as draft', icon: <Copy size={16} />, onSelect: () => void duplicate(row) },
            ...(row.plan.status === 'draft'
              ? [{ id: 'publish', label: 'Put on sale', icon: <RocketLaunch size={16} />, onSelect: () => setPublishing(row) }]
              : []),
          ],
        },
        {
          items: [
            row.plan.status === 'archived'
              ? { id: 'restore', label: 'Put back on sale', icon: <ArrowCounterClockwise size={16} />, onSelect: () => setArchiving(row) }
              : { id: 'archive', label: 'Retire plan', icon: <Archive size={16} />, tone: 'danger' as const, onSelect: () => setArchiving(row) },
          ],
        },
      ]}
    />
  );

  const columns: Column<PlanRow>[] = [
    {
      key: 'plan',
      header: 'Plan',
      mobile: 'primary',
      render: (row) => (
        <span className={styles.stack}>
          <Link to={to(row)} className={styles.cellTitle}>
            {row.plan.name}
          </Link>
          <span className={styles.cellMeta}>{row.plan.description}</span>
        </span>
      ),
    },
    {
      key: 'cycle',
      header: 'Billing cycle',
      width: '140px',
      mobile: 'detail',
      render: (row) => <span className={styles.nowrap}>{row.plan.cycles.map((c) => (c === 'annual' ? 'Annual' : 'Monthly')).join(' · ')}</span>,
    },
    {
      key: 'price',
      header: 'Price',
      width: '150px',
      mobile: 'meta',
      render: (row) => {
        const { amount, cycle } = headlinePrice(row.plan);
        return (
          <span className={styles.stack}>
            <span className={`${styles.amount} ${styles.strong}`}>
              {money(amount, row.plan.currency)} <span className={styles.faint}>{cyclePer(cycle)}</span>
            </span>
            <span className={styles.cellMeta}>{row.plan.code}</span>
          </span>
        );
      },
    },
    {
      key: 'subscribers',
      header: 'Admins on it',
      width: '150px',
      mobile: 'detail',
      render: (row) => (
        <span className={styles.stack}>
          <span className={styles.amount}>{row.activeSubscribers.toLocaleString('en-IN')}</span>
          <span className={styles.cellMeta}>{money(row.mrr, row.plan.currency)} a month</span>
        </span>
      ),
    },
    {
      key: 'trial',
      header: 'Trial period',
      width: '120px',
      mobile: 'detail',
      render: (row) =>
        row.plan.trialEnabled ? <span className={styles.nowrap}>{plural(row.plan.trialDays, 'day')}</span> : <span className={styles.faint}>None</span>,
    },
    { key: 'status', header: 'Status', width: '120px', mobile: 'status', render: (row) => <PlanStatusBadge status={row.plan.status} /> },
    {
      key: 'updated',
      header: 'Updated',
      width: '130px',
      mobile: 'detail',
      render: (row) => (
        <time dateTime={row.plan.updatedAt} className={styles.nowrap}>
          {formatRelative(row.plan.updatedAt, now)}
        </time>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      width: '72px',
      align: 'end',
      mobile: 'hidden',
      render: (row) => <span className={styles.rowActions}>{rowMenu(row)}</span>,
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Plans"
        count={data ? plural(data.counts.all, 'plan') : undefined}
        description="What Admins can buy. Each plan sets a price, a free trial, limits — like how many students — and which features are switched on."
        actions={
          <LinkButton variant="primary" to={`${SUBS_BASE}/plans/new`} iconStart={<Plus size={16} />}>
            Create a plan
          </LinkButton>
        }
      />
      <SubscriptionTabs />
      <PrototypeNote>Demo plans. Nothing here is sold, and no Admin is gated by them.</PrototypeNote>

      <div className={styles.controls} hidden={data?.counts.all === 0 && !filtered}>
        <SegmentedControl<PlanStatus | 'all'>
          label="Plan status"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: data?.counts.all },
            { value: 'active', label: 'On sale', count: data?.counts.active },
            { value: 'draft', label: 'Draft', count: data?.counts.draft },
            { value: 'archived', label: 'Retired', count: data?.counts.archived },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search plan name or code" aria-label="Search plans" />
          </div>
          <Field label="Sort by" className={styles.filter}>
            <Select value={sort} onChange={(e) => update({ sort: e.target.value })}>
              <option value="name">Display order</option>
              <option value="price">Price, lowest first</option>
              <option value="subscribers">Most Admins</option>
              <option value="updated">Recently updated</option>
            </Select>
          </Field>
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <PlatformError title="Plans didn’t load" error={list.error} onRetry={reload} />
      ) : data && rows.length === 0 ? (
        filtered ? (
          <StateMessage icon={<MagnifyingGlass size={26} />} title="No plans match" actions={<Button onClick={reset}>Clear filters</Button>}>
            Try part of a plan's name, or its code.
          </StateMessage>
        ) : (
          <StateMessage
            icon={<Stack size={26} />}
            title="No plans yet"
            actions={
              <LinkButton variant="primary" to={`${SUBS_BASE}/plans/new`} iconStart={<Plus size={16} />}>
                Create your first plan
              </LinkButton>
            }
          >
            Create your first subscription plan to start configuring platform offerings.
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label="Plans" aria-busy={!data || undefined}>
          {!data
            ? Array.from({ length: 4 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <div className={styles.cardButton}>
                    <Skeleton width="60%" height={13} />
                    <Skeleton width="85%" height={9} />
                  </div>
                </li>
              ))
            : rows.map((row) => {
                const { amount, cycle } = headlinePrice(row.plan);
                return (
                  <li key={row.plan.id} className={styles.card}>
                    <button type="button" className={styles.cardButton} onClick={() => navigate(to(row))}>
                      <span className={styles.cardHead}>
                        <span className={styles.stack}>
                          <span className={styles.cellTitle}>{row.plan.name}</span>
                          <span className={styles.cellMeta}>{row.plan.code}</span>
                        </span>
                        <PlanStatusBadge status={row.plan.status} />
                      </span>
                      <span className={styles.cardFacts}>
                        <span className={styles.strong}>
                          {money(amount, row.plan.currency)} {cyclePer(cycle)}
                        </span>
                        <span>{plural(row.activeSubscribers, 'subscriber')}</span>
                        <span>{row.plan.trialEnabled ? `${row.plan.trialDays}-day trial` : 'No trial'}</span>
                      </span>
                    </button>
                  </li>
                );
              })}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Plans"
            rows={rows}
            columns={columns}
            rowKey={(row) => row.plan.id}
            rowLabel={(row) => row.plan.name}
            loading={!data}
            skeletonRows={5}
          />
        </div>
      )}

      <ConfirmDialog
        open={Boolean(publishing)}
        onClose={() => setPublishing(null)}
        onConfirm={publish}
        icon={<RocketLaunch size={20} />}
        title={`Put ${publishing?.plan.name} on sale?`}
        description={publishing?.plan.code}
        confirmLabel="Put on sale"
      >
        New Admins can choose it, and it appears when you change an Admin’s plan. A plan on sale can be retired later, but it can’t go back to being a draft.
      </ConfirmDialog>

      <ConfirmDialog
        open={Boolean(archiving)}
        onClose={() => setArchiving(null)}
        onConfirm={changeArchive}
        tone={archiving?.plan.status === 'archived' ? 'default' : 'danger'}
        icon={archiving?.plan.status === 'archived' ? <ArrowCounterClockwise size={20} /> : <Archive size={20} />}
        title={archiving?.plan.status === 'archived' ? `Put ${archiving?.plan.name} back on sale?` : `Retire ${archiving?.plan.name}?`}
        description={archiving ? `${plural(archiving.subscribers, 'subscription')} on this plan` : undefined}
        confirmLabel={archiving?.plan.status === 'archived' ? 'Put back on sale' : 'Retire plan'}
      >
        {archiving?.plan.status === 'archived'
          ? 'It goes back on the list new Admins choose from. Nothing about the subscriptions already on it changes.'
          : 'New Admins can no longer choose it, and it no longer appears when you change an Admin’s plan. Admins already on it keep its price and features until they move.'}
      </ConfirmDialog>
    </div>
  );
}
