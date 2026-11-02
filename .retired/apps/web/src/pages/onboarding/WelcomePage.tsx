import { useEffect, useState } from 'react';
import { Navigate, useSearchParams } from 'react-router-dom';
import { Sparkle } from '@phosphor-icons/react';
import type { BillingCycle, Plan, TenantBilling } from '@syniastrolms/domain';
import { PlanOfferCard, PlanOfferNote } from '@/components/plan/PlanOfferCard';
import { usePlanAccess } from '@/hooks/useAcademyPlan';
import { useTenantBilling } from '@/hooks/useTenantBilling';
import { formatDate } from '@/lib/format';
import { hasNoPlanYet } from '@/lib/planAccess';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { useSession } from '@/providers/SessionProvider';
import { services } from '@/services';
import { buyPath, canBuy, canTrial, offeredCycles, startFreeTrial } from './welcomeFlow';
import styles from './Welcome.module.css';

/*
 * The academy's first sign-in (`/admin/welcome`): an academy that has never had a plan chooses one here. Every
 * plan on sale side by side — price, trial, limits, what it includes — with its free trial a click away (no
 * payment, no billing address) and buying it straight away where online payment is connected. `/admin` sends an
 * academy here while plans are enforced; where they are not, the dashboard offers it instead. An academy that
 * already has a plan is sent on to its dashboard.
 */

export default function WelcomePage() {
  const { user } = useSession();
  const toast = useToast();
  const canChange = (user.permissions ?? []).includes('settings.edit');
  const plan = usePlanAccess();
  const billing = useTenantBilling(user.id, { refresh: true });
  // Get started (SAAS-026) and the pricing page arrive with the plan and cycle the visitor chose.
  const [params] = useSearchParams();
  const [cycle, setCycle] = useState<BillingCycle>(params.get('cycle') === 'annual' ? 'annual' : 'monthly');
  // Or the plan the owner chose while registering, kept by the server (survives a refresh and a new sign-in).
  const remembered = billing.data?.signupChoice ?? null;
  const chosenPlanId = params.get('plan') ?? remembered?.planId ?? undefined;
  useEffect(() => {
    if (!params.get('cycle') && remembered) setCycle(remembered.cycle);
    // Once, when the billing summary arrives.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [remembered?.planId]);
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [started, setStarted] = useState<{ plan: string; endsAt?: string } | null>(null);

  if (started) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="success"
          title="Your free trial has started"
          actions={
            <LinkButton to="/admin" variant="primary">
              Go to your dashboard
            </LinkButton>
          }
        >
          {started.plan} is yours free{started.endsAt ? ` until ${formatDate(started.endsAt)}` : ''}. Everything in the plan is open now — start with your first
          course.
        </StateMessage>
      </div>
    );
  }

  // An academy that already has a plan has nothing to choose here — unless it is this page that just started one.
  if (!busy && plan.plan && !hasNoPlanYet(plan.plan)) return <Navigate to="/admin" replace />;

  const failed = (billing.status === 'error' && !billing.data) || (plan.error && !plan.plan);
  if (failed) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title="The plans didn’t load"
          actions={
            <Button
              variant="primary"
              onClick={() => {
                billing.run().catch(() => undefined);
                plan.refresh().catch(() => undefined);
              }}
            >
              Try again
            </Button>
          }
        >
          {(billing.error ?? plan.error)?.message ?? 'Something went wrong.'} Nothing was changed.
        </StateMessage>
      </div>
    );
  }

  if (!billing.data || plan.loading) return <WelcomeSkeleton />;

  const trial = async (choice: Plan) => {
    setBusy(choice.id);
    setError(null);
    const outcome = await startFreeTrial(
      { start: (input) => services.tenantBilling.startTrial(input), refresh: () => [billing.run(), plan.refresh()] },
      { planId: choice.id, cycle },
    );
    setBusy(null);
    if (!outcome.ok) {
      setError(outcome.message);
      toast({ kind: 'error', title: 'The trial didn’t start', text: outcome.message });
      return;
    }
    toast({ kind: 'success', title: 'Free trial started', text: `${choice.name} is open for ${choice.trialDays} days.` });
    setStarted({ plan: choice.name, endsAt: new Date(Date.now() + choice.trialDays * 86_400_000).toISOString() });
  };

  return (
    <WelcomeView
      academyName={billing.data.academy.name}
      billing={billing.data}
      canChange={canChange}
      cycle={cycle}
      onCycle={setCycle}
      busyPlanId={busy}
      chosenPlanId={chosenPlanId}
      error={error}
      onTrial={trial}
    />
  );
}

export interface WelcomeViewProps {
  academyName: string;
  billing: Pick<TenantBilling, 'plans' | 'trialAvailable' | 'checkoutAvailable'>;
  canChange: boolean;
  cycle: BillingCycle;
  onCycle: (cycle: BillingCycle) => void;
  busyPlanId: string | null;
  /** The plan chosen before signing in (Get started, the pricing page): shown first and marked. */
  chosenPlanId?: string;
  error: string | null;
  onTrial: (plan: Plan) => void;
}

/** The page itself, drawn from props alone so each state can be checked on its own. */
export function WelcomeView({ academyName, billing, canChange, cycle, onCycle, busyPlanId, chosenPlanId, error, onTrial }: WelcomeViewProps) {
  const plans = [...billing.plans].sort((a, b) => Number(b.id === chosenPlanId) - Number(a.id === chosenPlanId) || a.order - b.order);
  const cycles = offeredCycles(plans);
  const anyTrial = plans.some((p) => canTrial(p, cycle, billing, canChange));

  return (
    <div className={styles.page}>
      <header className={styles.intro}>
        <span className={styles.eyebrow}>
          <Sparkle size={14} weight="fill" aria-hidden="true" /> Welcome
        </span>
        <h1 className={styles.title}>Welcome to {academyName}</h1>
        <p className={styles.lead}>
          Your LMS is ready and empty. Choose a plan to start building courses, live classes and certificates
          {anyTrial ? ' — try it free first, with no payment and no billing details.' : '.'}
        </p>
      </header>

      {error && (
        <InlineMessage kind="error" title="The trial didn’t start.">
          {error}
        </InlineMessage>
      )}
      {!canChange && (
        <InlineMessage kind="info" title="Only an admin who can change billing settings can choose the plan.">
          Ask them to start the free trial or choose a plan. Until then, nothing new can be added to the LMS.
        </InlineMessage>
      )}
      {canChange && !billing.trialAvailable && (
        <InlineMessage kind="info" title="This LMS has had its free trial.">
          Choose a plan to carry on — everything made during the trial is kept.
        </InlineMessage>
      )}
      {canChange && !billing.checkoutAvailable && (
        <InlineMessage kind="info" title="Online payment isn’t set up yet.">
          Start a trial, or contact the platform team to start a paid plan.
        </InlineMessage>
      )}

      {plans.length === 0 ? (
        <StateMessage title="No plans are on sale yet">The platform team hasn’t published a plan. Contact them to get started.</StateMessage>
      ) : (
        <>
          <div className={styles.controls}>
            <h2 className={styles.listTitle} id="welcome-plans">
              Plans
            </h2>
            {cycles.length > 1 ? (
              <SegmentedControl<BillingCycle>
                label="Billing cycle"
                value={cycle}
                onChange={onCycle}
                segments={[
                  { value: 'monthly', label: 'Monthly' },
                  { value: 'annual', label: 'Annual' },
                ]}
              />
            ) : (
              <span className={styles.controlsNote}>Prices are before tax.</span>
            )}
          </div>
          <ul className={styles.plans} aria-labelledby="welcome-plans">
            {plans.map((p) => (
              <PlanCard
                key={p.id}
                plan={p}
                cycle={cycle}
                trial={canTrial(p, cycle, billing, canChange)}
                buy={canBuy(p, cycle, billing, canChange)}
                busy={busyPlanId === p.id}
                disabled={busyPlanId !== null}
                chosen={p.id === chosenPlanId}
                onTrial={() => onTrial(p)}
              />
            ))}
          </ul>
        </>
      )}
    </div>
  );
}

function PlanCard({
  plan,
  cycle,
  trial,
  buy,
  busy,
  disabled,
  chosen,
  onTrial,
}: {
  plan: Plan;
  cycle: BillingCycle;
  trial: boolean;
  buy: boolean;
  busy: boolean;
  disabled: boolean;
  chosen: boolean;
  onTrial: () => void;
}) {
  const sold = plan.cycles.includes(cycle);
  return (
    <PlanOfferCard
      plan={plan}
      cycle={cycle}
      highlighted={chosen}
      ribbon={chosen ? 'Your choice' : undefined}
      actions={
        <>
          {trial && (
            <Button variant="primary" block loading={busy} disabled={disabled && !busy} onClick={onTrial}>
              Start {plan.trialDays}-day free trial
            </Button>
          )}
          {buy && (
            <LinkButton to={buyPath(plan, cycle)} variant={trial ? 'secondary' : 'primary'} block>
              Buy now
            </LinkButton>
          )}
          {trial && <PlanOfferNote>No payment needed. Choose a plan any time before it ends.</PlanOfferNote>}
          {!trial && !buy && sold && <PlanOfferNote>Contact the platform team to start this plan.</PlanOfferNote>}
        </>
      }
    />
  );
}

function WelcomeSkeleton() {
  return (
    <div className={styles.page} role="status" aria-label="Loading the plans">
      <Skeleton width={120} height={14} />
      <Skeleton width="55%" height={34} radius="var(--r-sm)" />
      <Skeleton width="70%" height={16} />
      <div className={styles.plans}>
        {[0, 1, 2].map((i) => (
          <Skeleton key={i} height={420} radius="var(--r-lg)" />
        ))}
      </div>
    </div>
  );
}
