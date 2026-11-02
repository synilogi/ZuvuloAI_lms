import { useLayoutEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { CreditCard, PlayCircle } from '@phosphor-icons/react';
import type { BillingCycle, Plan } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate, plural } from '@/lib/format';
import { ChoiceCards } from '@/components/forms/Forms';
import { SectionHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Field, Select } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { BillingDetailsDialog } from '@/pages/billing/BillingDetailsDialog';
import { PlatformError } from '../platformMeta';
import { Fact, PrototypeNote, SUBS_BASE, SubscriptionStatusBadge, cycleLabel, cyclePer, money, priceFor } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

type Start = 'trial' | 'active';

/**
 * One academy's billing, for the platform: its subscription — live, or the last one it had — and where its
 * invoices are addressed. An academy with no live subscription can be started on one here: a trial, or an
 * agreement billed outside the gateway. Drawn as a section of the academy's own page.
 */
export function AcademyBilling({ tenantId, onChanged }: { tenantId: string; onChanged?: () => void }) {
  const toast = useToast();
  const navigate = useNavigate();
  const [editing, setEditing] = useState(false);
  const [starting, setStarting] = useState(false);

  const query = useAsync(`subs:academy:${tenantId}`, () =>
    Promise.all([services.subscriptions.getAcademyBilling(tenantId), services.subscriptions.listPlans({ status: 'active' })]).then(([billing, list]) => ({
      billing,
      plans: list.rows.map((r) => r.plan),
    })),
  );
  const billing = query.data?.billing;
  const reload = () => query.run().catch(() => undefined);

  const header = (live: boolean | null) => (
    <SectionHeader
      id="academy-billing"
      title="Subscription and billing"
      description={
        live === null
          ? undefined
          : live
            ? 'Its subscription and where its invoices are addressed.'
            : 'No live subscription. Start one here, or leave the Admin to choose a plan or start a free trial.'
      }
      actions={
        live === false && query.data ? (
          <Button variant="primary" onClick={() => setStarting(true)} iconStart={<PlayCircle size={16} />} disabled={query.data.plans.length === 0}>
            Start subscription
          </Button>
        ) : undefined
      }
    />
  );

  if (query.status === 'error' && !query.data) {
    return (
      <section className={styles.column} aria-labelledby="academy-billing">
        {header(null)}
        <PlatformError title="The Admin’s billing didn’t load" error={query.error} onRetry={reload} />
      </section>
    );
  }

  if (!billing || !query.data) {
    return (
      <section className={styles.column} aria-labelledby="academy-billing" aria-busy="true">
        {header(null)}
        <div className={styles.twoUp}>
          <Skeleton height={180} radius="var(--r-lg)" />
          <Skeleton height={180} radius="var(--r-lg)" />
        </div>
      </section>
    );
  }

  const { subscription: s, plan, profile } = billing;
  const live = Boolean(s && s.status !== 'canceled' && s.status !== 'expired');

  return (
    <section className={styles.column} aria-labelledby="academy-billing">
      {header(live)}
      <PrototypeNote />

      <div className={styles.twoUp}>
        <section className={styles.panel} aria-labelledby="academy-subscription">
          <SectionHeader
            id="academy-subscription"
            as="h3"
            title={live ? 'Subscription' : s ? 'Last subscription' : 'Subscription'}
            actions={
              s ? (
                <LinkButton size="sm" to={`${SUBS_BASE}/subscribers/${s.id}`}>
                  Open
                </LinkButton>
              ) : undefined
            }
          />
          {s && plan ? (
            <dl className={styles.facts}>
              <Fact label="Status" value={<SubscriptionStatusBadge status={s.status} />} />
              <Fact label="Plan" value={<Link to={`${SUBS_BASE}/plans/${plan.id}`}>{plan.name}</Link>} />
              <Fact label="Billing cycle" value={cycleLabel(s.cycle)} />
              <Fact label="Amount" value={`${money(s.amount, s.currency)} ${cyclePer(s.cycle)}`} />
              <Fact label={live ? 'Current period ends' : 'Ended'} value={formatDate(s.renewsAt)} />
            </dl>
          ) : (
            <StateMessage icon={<CreditCard size={26} />} title="No plan yet" compact>
              This Admin has not been on a plan yet. Its admin is offered the plans and a free trial on first sign-in.
            </StateMessage>
          )}
        </section>

        <section className={styles.panel} aria-labelledby="academy-profile">
          <SectionHeader
            id="academy-profile"
            as="h3"
            title="Billing address"
            description="Where invoices are sent. Tax is worked out from the country and region."
            actions={
              <Button size="sm" onClick={() => setEditing(true)}>
                {profile ? 'Edit' : 'Add'}
              </Button>
            }
          />
          {profile ? (
            <div className={styles.stack}>
              <span className={styles.strong}>{profile.legalName}</span>
              <span className={styles.cellMeta}>{profile.email}</span>
              <span>
                {profile.addressLine1}
                {profile.addressLine2 ? `, ${profile.addressLine2}` : ''}
              </span>
              <span>
                {profile.city}
                {profile.region ? `, ${profile.region}` : ''} {profile.postalCode} · {profile.country}
              </span>
              {profile.taxRegistration && <span className={styles.cellMeta}>Tax registration {profile.taxRegistration}</span>}
            </div>
          ) : (
            <p className={styles.muted}>Not set yet. The Admin can add it, or you can add it here.</p>
          )}
        </section>
      </div>

      <BillingDetailsDialog
        open={editing}
        initial={profile}
        onClose={() => setEditing(false)}
        onSave={async (details) => {
          await services.subscriptions.saveAcademyBillingProfile(tenantId, details);
          setEditing(false);
          toast({ kind: 'success', title: 'Billing address saved', text: `${billing.academy.name}’s next invoices are addressed there.` });
          await reload();
        }}
      />
      <StartSubscriptionDialog
        open={starting}
        academy={billing.academy}
        plans={query.data.plans}
        onClose={() => setStarting(false)}
        onStarted={(subscriptionId, start) => {
          setStarting(false);
          onChanged?.();
          toast({
            kind: 'success',
            title: start === 'trial' ? 'Trial started' : 'Subscription started',
            text: `${billing.academy.name} is on its new plan from today.`,
          });
          navigate(`${SUBS_BASE}/subscribers/${subscriptionId}`);
        }}
      />
    </section>
  );
}

function StartSubscriptionDialog({
  open,
  academy,
  plans,
  onClose,
  onStarted,
}: {
  open: boolean;
  academy: { id: string; name: string };
  plans: Plan[];
  onClose: () => void;
  onStarted: (subscriptionId: string, start: Start) => void;
}) {
  const [planId, setPlanId] = useState('');
  const [cycle, setCycle] = useState<BillingCycle>('monthly');
  const [start, setStart] = useState<Start>('active');
  // Before the dialog paints, not after: a reset that ran after paint could land after the person had already chosen
  // "Active now" and silently switch them back to a trial.
  useLayoutEffect(() => {
    if (!open) return;
    const first = plans[0];
    setPlanId(first?.id ?? '');
    setCycle(first?.cycles[0] ?? 'monthly');
    setStart(first?.trialEnabled && first.trialDays > 0 ? 'trial' : 'active');
  }, [open, plans]);

  const plan = plans.find((p) => p.id === planId);
  const cycles = plan?.cycles ?? [];
  const chosenCycle = cycles.includes(cycle) ? cycle : (cycles[0] ?? 'monthly');
  const hasTrial = Boolean(plan?.trialEnabled && plan.trialDays > 0);
  const chosenStart: Start = start === 'trial' && !hasTrial ? 'active' : start;

  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={async () => {
        const detail = await services.subscriptions.startSubscription({ tenantId: academy.id, planId, cycle: chosenCycle, start: chosenStart });
        onStarted(detail.subscription.id, chosenStart);
      }}
      icon={<PlayCircle size={20} />}
      title={`Start a subscription for ${academy.name}?`}
      description="The price is the plan’s. Nothing is charged through the gateway."
      confirmLabel={chosenStart === 'trial' ? 'Start trial' : 'Start subscription'}
      blocked={!plan}
    >
      <div className={styles.dialogBody}>
        <Field label="Plan">
          <Select value={planId} onChange={(e) => setPlanId(e.target.value)}>
            {plans.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </Select>
        </Field>
        <Field label="Billing cycle">
          <Select value={chosenCycle} onChange={(e) => setCycle(e.target.value as BillingCycle)}>
            {cycles.map((c) => (
              <option key={c} value={c}>
                {cycleLabel(c)} — {plan ? `${money(priceFor(plan, c), plan.currency)} ${cyclePer(c)}` : '—'}
              </option>
            ))}
          </Select>
        </Field>
        <ChoiceCards<Start>
          legend="How it starts"
          value={chosenStart}
          onChange={setStart}
          columns={1}
          choices={[
            {
              value: 'trial',
              label: hasTrial ? `Free trial — ${plural(plan!.trialDays, 'day')}` : 'Free trial',
              description: hasTrial ? 'Nothing is charged until the trial converts.' : 'This plan has no trial.',
              disabled: !hasTrial,
            },
            {
              value: 'active',
              label: 'Active now',
              description: 'An agreement billed outside the gateway: the first period starts today at the plan’s price.',
            },
          ]}
        />
        {plans.length === 0 && <InlineMessage kind="warn">No plan is on sale. Publish one first.</InlineMessage>}
      </div>
    </ConfirmDialog>
  );
}
