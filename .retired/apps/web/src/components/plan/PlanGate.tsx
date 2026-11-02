import { useId, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { HourglassMedium, LockSimple } from '@phosphor-icons/react';
import type { FeatureKey, Plan, PlanAccess, WorkspaceModule } from '@syniastrolms/domain';
import { usePlanAccess } from '@/hooks/useAcademyPlan';
import { usePermissions } from '@/hooks/usePermissions';
import { useTenantBilling } from '@/hooks/useTenantBilling';
import { BILLING_PAGE, WELCOME_PAGE, gateFeature, isOrAre, plansWith } from '@/lib/planAccess';
import { Badge, IconChip } from '@/components/ui/Badge/Badge';
import { LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { PageLoading } from '@/pages/PageLoading';
import { useSession } from '@/providers/SessionProvider';
import { cyclePer, headlinePrice, money } from '@/pages/superadmin/subscriptions/subscriptionMeta';
import styles from './Plan.module.css';

/*
 * A plan-gated area of the staff workspace, as the academy's plan shows it (`GET /academy/plan`):
 *   - open: the page, untouched;
 *   - read-only: the page, under a notice that the plan ended — what is here stays readable, nothing new is added;
 *   - locked: in place of the page, what the area does and the plans that include it, with the way to them.
 * An academy still choosing its first plan shows its instructors that it is being set up, not a sales page.
 *
 * Convenience, never security: the API refuses the same calls on its own, and while the plan is unknown — or
 * could not be read — the page is shown as it always was.
 */

interface GateProps {
  /** The module the area belongs to. */
  module?: WorkspaceModule;
  /** A feature that is no module of its own — the advanced reports. Takes precedence over `module`. */
  feature?: FeatureKey;
  /** Drawn inside a page (a tab) rather than as the page. */
  compact?: boolean;
  children: ReactNode;
}

export function PlanGate({ module, feature, compact, children }: GateProps) {
  const { user, role } = useSession();
  const { canOpen } = usePermissions();
  const plan = usePlanAccess();
  const access: PlanAccess = feature ? plan.feature(feature) : module ? plan.access(module) : 'open';
  const isAdmin = role === 'admin';
  // The plans that include the area are on the academy's billing summary, which only its admins can read.
  const billing = useTenantBilling(user.id, { enabled: isAdmin && access === 'locked' && canOpen(BILLING_PAGE) });

  if (!plan.staff) return <>{children}</>;
  if (plan.loading) return compact ? <Skeleton height={160} radius="var(--r-lg)" /> : <PageLoading />;
  return (
    <PlanGateView
      access={access}
      module={module}
      feature={feature}
      compact={compact}
      isAdmin={isAdmin}
      settingUp={plan.choosingPlan}
      plans={billing.data?.plans}
      plansState={billing.status === 'error' ? 'error' : billing.data ? 'ready' : isAdmin && canOpen(BILLING_PAGE) ? 'loading' : 'none'}
    >
      {children}
    </PlanGateView>
  );
}

export interface PlanGateViewProps extends GateProps {
  access: PlanAccess;
  isAdmin: boolean;
  /** The academy has not chosen its first plan yet. */
  settingUp: boolean;
  plans?: Plan[];
  plansState: 'loading' | 'ready' | 'error' | 'none';
}

/** What a gated area shows for a given access. Drawn from props alone, so every state can be checked on its own. */
export function PlanGateView({ access, module, feature, compact, isAdmin, settingUp, plans, plansState, children }: PlanGateViewProps) {
  if (access === 'open') return <>{children}</>;
  if (access === 'read-only') {
    return (
      <>
        <ReadOnlyNotice module={module} feature={feature} isAdmin={isAdmin} />
        {children}
      </>
    );
  }
  if (settingUp && !isAdmin) {
    return (
      <StateMessage icon={<HourglassMedium size={26} />} title="Your LMS is being set up">
        Your admin is choosing a plan. Courses, quizzes and live classes open here as soon as they have — there is nothing you need to do.
      </StateMessage>
    );
  }
  return <LockedArea module={module} feature={feature} compact={compact} isAdmin={isAdmin} settingUp={settingUp} plans={plans} plansState={plansState} />;
}

/** The notice above a page whose plan has ended: what still works, what does not, and where to renew. */
export function ReadOnlyNotice({ module, feature, isAdmin }: { module?: WorkspaceModule; feature?: FeatureKey; isAdmin: boolean }) {
  const gate = gateFeature(module, feature);
  return (
    <div className={styles.banner} data-plan-gate="read-only">
      <InlineMessage
        kind="warn"
        title={`${gate.title} ${isOrAre(gate.title)} read-only.`}
        action={isAdmin ? <Link to={BILLING_PAGE}>Renew plan</Link> : undefined}
      >
        The LMS’s plan has ended. Everything already here stays readable, but nothing new can be added until the LMS is on a plan again.
        {isAdmin ? '' : ' Ask your admin to renew.'}
      </InlineMessage>
    </div>
  );
}

function LockedArea({ module, feature, compact, isAdmin, settingUp, plans, plansState }: Omit<PlanGateViewProps, 'access' | 'children'>) {
  const id = useId();
  const gate = gateFeature(module, feature);
  const including = plans ? plansWith(plans, gate.key) : [];
  const Heading = compact ? 'h2' : 'h1';
  const home = isAdmin ? '/admin' : '/teach';

  return (
    <section className={`${styles.locked} ${compact ? styles.compact : ''}`} aria-labelledby={id} data-plan-gate="locked">
      {!compact && (
        <IconChip size="xl">
          <LockSimple size={26} />
        </IconChip>
      )}
      <span className={styles.eyebrow}>
        {compact && <LockSimple size={13} weight="bold" aria-hidden="true" />}
        Not in your current plan
      </span>
      <Heading id={id} className={styles.title}>
        Unlock {gate.title}
      </Heading>
      <p className={styles.lead}>{gate.description}</p>

      {isAdmin && plansState !== 'none' && (
        <div className={styles.section}>
          <h3 className={styles.sectionTitle}>Included in</h3>
          {plansState === 'loading' ? (
            <Skeleton height={64} radius="var(--r-md)" />
          ) : plansState === 'error' ? (
            <p className={styles.note}>The plans didn’t load. See them on the billing page.</p>
          ) : including.length === 0 ? (
            <p className={styles.note}>No plan on sale includes it yet. Contact the platform team.</p>
          ) : (
            <ul className={styles.planList}>
              {including.map((p) => {
                const price = headlinePrice(p);
                return (
                  <li key={p.id} className={styles.planItem}>
                    <span className={styles.planName}>{p.name}</span>
                    <span className={styles.planPrice}>
                      {money(price.amount, p.currency)} {cyclePer(price.cycle)}
                    </span>
                    {p.trialEnabled && p.trialDays > 0 && (
                      <Badge size="sm" tone="info">
                        {p.trialDays}-day free trial
                      </Badge>
                    )}
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      )}

      <div className={styles.actions}>
        {isAdmin ? (
          <>
            <LinkButton to={settingUp ? WELCOME_PAGE : BILLING_PAGE} variant="primary">
              See plans
            </LinkButton>
            {!compact && <LinkButton to={home}>Back to dashboard</LinkButton>}
          </>
        ) : (
          <>
            <p className={styles.note}>Ask your admin to upgrade.</p>
            {!compact && <LinkButton to={home}>Back to overview</LinkButton>}
          </>
        )}
      </div>
    </section>
  );
}
