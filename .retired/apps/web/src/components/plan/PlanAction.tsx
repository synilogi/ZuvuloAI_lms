import { useId, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { LockSimple } from '@phosphor-icons/react';
import type { LimitKey, PlanAccess, WorkspaceModule } from '@syniastrolms/domain';
import { usePlanAccess } from '@/hooks/useAcademyPlan';
import { usePermissions } from '@/hooks/usePermissions';
import { useTenantBilling } from '@/hooks/useTenantBilling';
import { cx } from '@/lib/cx';
import { BILLING_PAGE, blockedReason, capacityOf, capacityText, limitReason, type Capacity } from '@/lib/planAccess';
import { Button, LinkButton, type ButtonSize, type ButtonVariant } from '@/components/ui/Button/Button';
import { useSession } from '@/providers/SessionProvider';
import styles from './Plan.module.css';

/*
 * A "New …" action in a plan-gated module. It is a plain link while the plan allows it; otherwise a disabled
 * button that says why — the plan ended (read-only), the plan does not include the module (locked), or the
 * plan's limit is used up. For an admin who can see billing, what is left of the limit is shown beside it.
 * The API refuses the same thing regardless; this only saves the walk into a refusal.
 */

interface PlanActionProps {
  /** The plan-gated module the action adds to. Absent for one that only a limit governs (instructors). */
  module?: WorkspaceModule;
  /** The plan limit a new one counts against, if any. */
  limit?: LimitKey;
  to: string;
  icon?: ReactNode;
  variant?: ButtonVariant;
  size?: ButtonSize;
  /** Show what is left of the limit beside the action. Off where the action repeats one that already shows it. */
  showCapacity?: boolean;
  children: ReactNode;
}

export function PlanAction({ module, limit, showCapacity = true, ...rest }: PlanActionProps) {
  const { user, role } = useSession();
  const { canOpen } = usePermissions();
  const plan = usePlanAccess();
  // Usage is on the billing summary, which only an admin who may open billing can read.
  const canSeeBilling = role === 'admin' && canOpen(BILLING_PAGE);
  const billing = useTenantBilling(user.id, { enabled: Boolean(limit) && canSeeBilling });
  const capacity = limit && canSeeBilling ? capacityOf(billing.data, limit) : null;
  return (
    <PlanActionView
      {...rest}
      module={module}
      access={module ? plan.access(module) : 'open'}
      capacity={capacity}
      showCapacity={showCapacity}
      canSeeBilling={canSeeBilling}
    />
  );
}

export interface PlanActionViewProps extends Omit<PlanActionProps, 'limit'> {
  access: PlanAccess;
  capacity: Capacity | null;
  canSeeBilling: boolean;
}

/** The action for a given access and capacity. Drawn from props alone, so every state can be checked on its own. */
export function PlanActionView({
  module,
  access,
  capacity,
  canSeeBilling,
  to,
  icon,
  variant = 'primary',
  size,
  showCapacity = true,
  children,
}: PlanActionViewProps) {
  const reasonId = useId();
  const reason = (module ? blockedReason(access, module) : null) ?? (capacity?.reached ? limitReason(capacity) : null);

  if (reason) {
    return (
      <span className={styles.action} data-plan-action="blocked">
        {access === 'open' && capacity?.reached && showCapacity && (
          <span className={cx(styles.capacity, styles.capacityReached)}>
            Limit reached{canSeeBilling ? ' · ' : ''}
            {canSeeBilling && <Link to={BILLING_PAGE}>See plans</Link>}
          </span>
        )}
        <Button variant={variant} size={size} iconStart={<LockSimple size={size === 'sm' ? 14 : 16} />} disabled title={reason} aria-describedby={reasonId}>
          {children}
        </Button>
        <span id={reasonId} className="sr-only">
          {reason}
        </span>
      </span>
    );
  }

  return (
    <span className={styles.action}>
      {capacity && showCapacity && <span className={styles.capacity}>{capacityText(capacity)}</span>}
      <LinkButton to={to} variant={variant} size={size} iconStart={icon}>
        {children}
      </LinkButton>
    </span>
  );
}
