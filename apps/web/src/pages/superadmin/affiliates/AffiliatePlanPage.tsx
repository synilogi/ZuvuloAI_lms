import { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { ArrowsClockwise, Copy, DotsThreeVertical, Eye, PencilSimple, Plus, Prohibit, RocketLaunch, Trash } from '@phosphor-icons/react';
import type { MlmPlanTerms, MlmPlanVersionSummary } from '@syniastrolms/domain';
import { legCvOf } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import {
  AffiliateTabs,
  CAP_OVERFLOW_LABEL,
  CARRY_FORWARD_LABEL,
  PLAN_PATH,
  PlanVersionBadge,
  REWARD_KIND_LABEL,
  SPILLOVER_LABEL,
  compactMoney,
  percentOfBps,
} from './affiliateMeta';
import styles from './Affiliates.module.css';

/**
 * The affiliate program's plan: which version runs today, every version there has been, and the terms of the one
 * selected. A version is data: a change is always a new draft, activated when ready, which retires the one before.
 */
export default function AffiliatePlanPage() {
  const now = useNow();
  const toast = useToast();
  const navigate = useNavigate();
  const [params, setParams] = useSearchParams();
  const overview = useAsync('affiliates:plan', () => services.affiliatesPlatform.plan());
  const data = overview.data;
  const selectedId = params.get('version') ?? data?.active?.id ?? data?.versions[0]?.id ?? null;
  const selected = useAsync(`affiliates:plan:version:${selectedId ?? 'none'}`, () =>
    selectedId ? services.affiliatesPlatform.getPlanVersion(selectedId) : Promise.resolve(null),
  );
  const [confirming, setConfirming] = useState<{ kind: 'activate' | 'retire' | 'delete'; row: MlmPlanVersionSummary } | null>(null);
  const [busy, setBusy] = useState(false);

  const reload = async () => {
    await overview.run().catch(() => undefined);
    await selected.run().catch(() => undefined);
  };
  const select = (id: string) => {
    const p = new URLSearchParams(params);
    p.set('version', id);
    setParams(p, { replace: true });
  };

  const newDraft = async (fromVersionId?: string) => {
    setBusy(true);
    try {
      const draft = await services.affiliatesPlatform.createPlanVersion(fromVersionId ? { fromVersionId } : {});
      toast({ kind: 'success', title: `Version ${draft.version} created`, text: 'Saved as a draft. Nothing runs under it until it is activated.' });
      navigate(`${PLAN_PATH}/versions/${draft.id}/edit`);
    } catch (error) {
      toast({ kind: 'error', title: 'Couldn’t create a draft', text: (error as Error).message });
    } finally {
      setBusy(false);
    }
  };

  const confirm = async () => {
    if (!confirming) return;
    const { kind, row } = confirming;
    if (kind === 'activate') {
      const v = await services.affiliatesPlatform.activatePlanVersion(row.id);
      toast({ kind: 'success', title: `Version ${v.version} is active`, text: 'The program runs under it from now on. The previous version was retired.' });
    } else if (kind === 'retire') {
      await services.affiliatesPlatform.retirePlanVersion(row.id);
      toast({ kind: 'success', title: `Version ${row.version} retired`, text: 'No version is active now: nothing earns until another is activated.' });
    } else {
      await services.affiliatesPlatform.deletePlanDraft(row.id);
      toast({ kind: 'success', title: `Draft ${row.version} deleted` });
      if (selectedId === row.id) {
        const p = new URLSearchParams(params);
        p.delete('version');
        setParams(p, { replace: true });
      }
    }
    setConfirming(null);
    await reload();
  };

  const rowMenu = (row: MlmPlanVersionSummary) => (
    <Menu
      align="end"
      trigger={(props) => <IconButton size="sm" label={`Actions for version ${row.version}`} icon={<DotsThreeVertical size={16} weight="bold" />} {...props} />}
      sections={[
        {
          items: [
            { id: 'view', label: 'View terms', icon: <Eye size={16} />, onSelect: () => select(row.id) },
            ...(row.status === 'draft'
              ? [
                  { id: 'edit', label: 'Edit draft', icon: <PencilSimple size={16} />, onSelect: () => navigate(`${PLAN_PATH}/versions/${row.id}/edit`) },
                  { id: 'activate', label: 'Activate', icon: <RocketLaunch size={16} />, onSelect: () => setConfirming({ kind: 'activate', row }) },
                ]
              : []),
            { id: 'copy', label: 'New draft from this', icon: <Copy size={16} />, onSelect: () => void newDraft(row.id) },
          ],
        },
        {
          items: [
            row.status === 'active'
              ? { id: 'retire', label: 'Retire', icon: <Prohibit size={16} />, tone: 'danger' as const, onSelect: () => setConfirming({ kind: 'retire', row }) }
              : row.status === 'draft'
                ? {
                    id: 'delete',
                    label: 'Delete draft',
                    icon: <Trash size={16} />,
                    tone: 'danger' as const,
                    onSelect: () => setConfirming({ kind: 'delete', row }),
                  }
                : { id: 'noop', label: 'Kept for its history', icon: <ArrowsClockwise size={16} />, disabled: true, onSelect: () => undefined },
          ],
        },
      ]}
    />
  );

  const columns: Column<MlmPlanVersionSummary>[] = [
    {
      key: 'version',
      header: 'Version',
      mobile: 'primary',
      render: (row) => (
        <span className={styles.stack}>
          <button
            type="button"
            className={styles.cellTitle}
            onClick={() => select(row.id)}
            style={{ background: 'none', border: 0, padding: 0, cursor: 'pointer', textAlign: 'left' }}
          >
            Version {row.version}
          </button>
          <span className={styles.cellMeta}>{row.note || 'No note'}</span>
        </span>
      ),
    },
    { key: 'status', header: 'Status', width: '110px', mobile: 'status', render: (row) => <PlanVersionBadge status={row.status} /> },
    { key: 'ranks', header: 'Ranks', width: '90px', mobile: 'meta', render: (row) => <span className={styles.amount}>{row.tierCount}</span> },
    {
      key: 'courses',
      header: 'Eligible courses',
      width: '140px',
      mobile: 'detail',
      render: (row) => (row.eligibleCourseCount ? plural(row.eligibleCourseCount, 'course') : <span className={styles.faint}>None yet</span>),
    },
    {
      key: 'when',
      header: 'Activated',
      width: '140px',
      mobile: 'detail',
      render: (row) =>
        row.activatedAt ? (
          <time dateTime={row.activatedAt} className={styles.nowrap}>
            {formatRelative(row.activatedAt, now)}
          </time>
        ) : (
          <span className={styles.faint}>—</span>
        ),
    },
    {
      key: 'actions',
      header: 'Actions',
      width: '72px',
      align: 'end',
      mobile: 'meta',
      render: (row) => <span className={styles.rowActions}>{rowMenu(row)}</span>,
    },
  ];

  if (overview.status === 'error' && !data) {
    return (
      <div className={styles.page}>
        <PageHeader eyebrow={PLATFORM_EYEBROW} title="Affiliate plan" />
        <AffiliateTabs />
        <PlatformError title="The affiliate plan didn’t load" error={overview.error} onRetry={() => void reload()} />
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Affiliate plan"
        count={data ? plural(data.versions.length, 'version') : undefined}
        description="Every compensation term of the affiliate program, as data: course CV, matching, daily caps, carry-forward, the 18 ranks and their rewards, and the company payout ceiling. A change is a new version; activating it retires the one before."
        actions={
          <Button variant="primary" iconStart={<Plus size={16} />} loading={busy} onClick={() => void newDraft(data?.active?.id)}>
            New draft
          </Button>
        }
      />
      <AffiliateTabs />
      <PrototypeNote>A demo plan: changes last until the page is reloaded.</PrototypeNote>

      <section className={styles.panel} aria-labelledby="active-version">
        <div className={styles.panelHead}>
          <div>
            <h2 id="active-version" className={styles.panelTitle}>
              Running today
            </h2>
            <p className={styles.panelHint}>
              {data?.active
                ? `Version ${data.active.version}, active since ${formatRelative(data.active.activatedAt ?? data.active.createdAt, now)}.`
                : 'No version is active. Affiliates can register, but nothing earns until a version is activated.'}
            </p>
          </div>
        </div>
        {!data ? (
          <Skeleton height={56} radius="var(--r-md)" />
        ) : data.active ? (
          <TermFacts terms={data.active} />
        ) : (
          <div className={styles.empty}>Open a draft below, name the eligible course, and activate it to start the program.</div>
        )}
      </section>

      <section className={styles.panel} aria-labelledby="versions">
        <div className={styles.panelHead}>
          <h2 id="versions" className={styles.panelTitle}>
            Versions
          </h2>
        </div>
        {!data ? (
          <Skeleton height={160} radius="var(--r-md)" />
        ) : data.versions.length === 0 ? (
          <StateMessage
            kind="empty"
            title="No plan yet"
            actions={
              <Button variant="primary" onClick={() => void newDraft()}>
                Start from the published plan
              </Button>
            }
          >
            The first draft is written from the AI Course 2-Leg plan: 18 ranks, 10% matching, six daily cap bands and a 25% payout ceiling.
          </StateMessage>
        ) : (
          <DataTable<MlmPlanVersionSummary>
            rows={data.versions}
            columns={columns}
            rowKey={(row) => row.id}
            label="Plan versions"
            rowLabel={(row) => `Version ${row.version}`}
          />
        )}
      </section>

      {selectedId && (
        <section className={styles.panel} aria-labelledby="selected-version">
          <div className={styles.panelHead}>
            <div>
              <h2 id="selected-version" className={styles.panelTitle}>
                {selected.data ? `Version ${selected.data.version}` : 'Version'} {selected.data && <PlanVersionBadge status={selected.data.status} />}
              </h2>
              {selected.data?.note && <p className={styles.panelHint}>{selected.data.note}</p>}
            </div>
            {selected.data?.status === 'draft' && (
              <Button iconStart={<PencilSimple size={16} />} onClick={() => navigate(`${PLAN_PATH}/versions/${selected.data!.id}/edit`)}>
                Edit draft
              </Button>
            )}
          </div>
          {selected.status === 'error' ? (
            <PlatformError title="This version didn’t load" error={selected.error} onRetry={() => void selected.run().catch(() => undefined)} />
          ) : !selected.data ? (
            <Skeleton height={320} radius="var(--r-md)" />
          ) : (
            <VersionDetail terms={selected.data} />
          )}
        </section>
      )}

      <ConfirmDialog
        open={confirming !== null}
        onClose={() => setConfirming(null)}
        onConfirm={confirm}
        title={
          confirming?.kind === 'activate'
            ? `Activate version ${confirming.row.version}?`
            : confirming?.kind === 'retire'
              ? `Retire version ${confirming.row.version}?`
              : `Delete draft ${confirming?.row.version ?? ''}?`
        }
        confirmLabel={confirming?.kind === 'activate' ? 'Activate' : confirming?.kind === 'retire' ? 'Retire' : 'Delete'}
        tone={confirming?.kind === 'activate' ? 'default' : 'danger'}
      >
        {confirming?.kind === 'activate' && (
          <>
            <p>From the next job tick, CV, matching, ranks and the ceiling are computed under this version.</p>
            <p>The version active today is retired and kept, because commissions were computed under it.</p>
          </>
        )}
        {confirming?.kind === 'retire' && (
          <p>No version will be active. Affiliates keep what they earned; nothing new is credited until another version is activated.</p>
        )}
        {confirming?.kind === 'delete' && <p>A draft that was never activated leaves no trace. This cannot be undone.</p>}
      </ConfirmDialog>
    </div>
  );
}

/** The headline terms of a version, as facts. */
function TermFacts({ terms }: { terms: MlmPlanTerms }) {
  return (
    <dl className={styles.facts}>
      <Fact label="CV per sale" value={percentOfBps(terms.cvBasisPoints)} hint="of the net amount" />
      <Fact label="Matching" value={percentOfBps(terms.matchingRateBps)} hint="of the weaker leg" />
      <Fact label="Payout ceiling" value={percentOfBps(terms.payoutCeilingBps)} hint={`normal ${percentOfBps(terms.normalPayoutBps)}`} />
      <Fact label="Ranks" value={String(terms.tiers.length)} hint="exact 50:50 per leg" />
      <Fact label="Top daily cap" value={compactMoney(Math.max(...terms.capBands.map((b) => b.dailyCap)), terms.currency)} />
      <Fact label="Eligible courses" value={terms.eligibleCourseIds.length ? String(terms.eligibleCourseIds.length) : 'None'} />
      <Fact
        label="Matching run"
        value={`${String(terms.matchingRunHourIst).padStart(2, '0')}:00 IST`}
        hint={terms.cvEligibilityDelayDays ? `CV after ${plural(terms.cvEligibilityDelayDays, 'day')}` : 'CV counts at once'}
      />
      <Fact
        label="Withdrawals"
        value={`from ${compactMoney(terms.withdrawalMinAmount, terms.currency)}`}
        hint={terms.withdrawalRequiresKyc ? 'KYC required' : 'no KYC gate'}
      />
    </dl>
  );
}

function Fact({ label, value, hint }: { label: string; value: string; hint?: string }) {
  return (
    <div className={styles.fact}>
      <dt className={styles.factLabel}>{label}</dt>
      <dd className={styles.factValue}>
        {value}
        {hint && <span className={`${styles.muted} ${styles.nowrap}`}> · {hint}</span>}
      </dd>
    </div>
  );
}

/** Everything a version says, laid out for reading: terms, cap bands and the rank table. */
function VersionDetail({ terms }: { terms: MlmPlanTerms }) {
  const band = (key: string) => terms.capBands.find((b) => b.key === key);
  return (
    <>
      <TermFacts terms={terms} />
      <dl className={styles.facts}>
        <Fact label="Above the daily cap" value={CAP_OVERFLOW_LABEL[terms.capOverflowPolicy]} />
        <Fact
          label="Carry-forward"
          value={
            terms.carryForwardPolicy === 'expire-days'
              ? `Expires after ${plural(terms.carryExpiryDays ?? 0, 'day')}`
              : CARRY_FORWARD_LABEL[terms.carryForwardPolicy]
          }
        />
        <Fact label="Spillover" value={SPILLOVER_LABEL[terms.spilloverRule]} />
        <Fact label="TDS at payout" value={percentOfBps(terms.tdsBps)} />
      </dl>
      <h3 className={styles.panelTitle}>Daily matching caps</h3>
      <div className={styles.tableWrap}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th>Band</th>
              <th>Key</th>
              <th className={styles.num}>Daily cap</th>
              <th className={styles.num}>30-day maximum</th>
            </tr>
          </thead>
          <tbody>
            {terms.capBands.map((b) => (
              <tr key={b.key}>
                <td>{b.label}</td>
                <td className={styles.mono}>{b.key}</td>
                <td className={styles.num}>{compactMoney(b.dailyCap, terms.currency)}</td>
                <td className={`${styles.num} ${styles.muted}`}>{compactMoney(b.dailyCap * 30, terms.currency)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <h3 className={styles.panelTitle}>Ranks and rewards</h3>
      <div className={styles.tableWrap}>
        <table className={styles.table}>
          <thead>
            <tr>
              <th>#</th>
              <th>Rank</th>
              <th className={styles.num}>Group CV</th>
              <th className={styles.num}>A leg</th>
              <th className={styles.num}>B leg</th>
              <th>Reward</th>
              <th>Cap band</th>
              <th className={styles.num}>Vesting</th>
            </tr>
          </thead>
          <tbody>
            {terms.tiers.map((t) => (
              <tr key={t.order}>
                <td className={styles.num}>{t.order}</td>
                <td className={styles.strong}>{t.name}</td>
                <td className={styles.num}>{compactMoney(t.groupCv, terms.currency)}</td>
                <td className={styles.num}>{compactMoney(legCvOf(t), terms.currency)}</td>
                <td className={styles.num}>{compactMoney(legCvOf(t), terms.currency)}</td>
                <td>
                  {t.rewardKind === 'cash'
                    ? t.rewardAmount
                      ? compactMoney(t.rewardAmount, terms.currency) + (t.rewardCapAmount ? ` (up to ${compactMoney(t.rewardCapAmount, terms.currency)})` : '')
                      : `Up to ${compactMoney(t.rewardCapAmount ?? 0, terms.currency)}`
                    : REWARD_KIND_LABEL[t.rewardKind]}
                </td>
                <td>{band(t.capBandKey)?.label ?? t.capBandKey}</td>
                <td className={styles.num}>{t.vestingDays ? plural(t.vestingDays, 'day') : '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </>
  );
}
