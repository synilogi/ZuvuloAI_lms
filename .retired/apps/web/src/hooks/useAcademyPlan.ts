import { useCallback, useEffect, useMemo, useSyncExternalStore } from 'react';
import type { AcademyPlan, FeatureKey, PlanAccess, WorkspaceModule } from '@syniastrolms/domain';
import { featureAccess, moduleAccess, needsPlanChoice } from '@syniastrolms/domain';
import { services } from '@/services';
import { useSession } from '@/providers/SessionProvider';
import type { AsyncState } from './useAsync';
import { createSharedStore, followBilling } from './sharedStore';
import { tenantBillingStore } from './useTenantBilling';

/*
 * What the academy's plan lets its staff use (`GET /academy/plan`), read once and shared: the sidebar marks each
 * module open, read-only or locked from it, the gated pages decide what to show, and the dashboard decides whether
 * the academy still has to choose its first plan. Whenever the billing summary is read again — after a trial
 * starts, a plan is bought or changed, a subscription is cancelled — the plan is read again too, so the sidebar
 * never lags behind what billing just did.
 */

export const academyPlanStore = createSharedStore(() => services.tenantBilling.academyPlan());

followBilling(tenantBillingStore, academyPlanStore);

/** The shared plan for the signed-in `account`, read when first asked for. Shaped like `useAsync`. */
export function useAcademyPlan(account: string | null | undefined, { enabled = true } = {}) {
  const snapshot = useSyncExternalStore(academyPlanStore.subscribe, academyPlanStore.getState);
  useEffect(() => {
    if (enabled && account) academyPlanStore.load(account).catch(() => undefined);
  }, [account, enabled]);
  const run = useCallback(() => (account ? academyPlanStore.load(account, true) : Promise.reject(new Error('Not signed in.'))), [account]);
  const state: AsyncState<AcademyPlan> = account && academyPlanStore.owner() === account ? snapshot : { status: 'idle' };
  return { ...state, run };
}

export interface PlanAccessView {
  /** Whether the signed-in account is academy staff — the only accounts a plan gates. */
  staff: boolean;
  plan?: AcademyPlan;
  /** The plan is still being read for the first time. Screens wait rather than flash a page they will replace. */
  loading: boolean;
  /** The plan could not be read. Screens carry on as if open: the API still refuses what the plan does not allow. */
  error?: Error;
  /** How a module appears: open when nothing is known, so a failed read never locks anyone out of their work. */
  access(module: WorkspaceModule): PlanAccess;
  feature(key: FeatureKey): PlanAccess;
  /** The academy still has to choose its first plan (`needsPlanChoice`). */
  choosingPlan: boolean;
  refresh(): Promise<unknown>;
}

/** The signed-in staff account's view of its academy's plan. Everyone else sees every module open. */
export function usePlanAccess(): PlanAccessView {
  const { user, role } = useSession();
  const staff = role === 'admin' || role === 'instructor';
  const query = useAcademyPlan(user.id || undefined, { enabled: staff });
  const plan = staff ? query.data : undefined;
  const status = query.status;
  const error = staff && status === 'error' ? query.error : undefined;
  const { run } = query;
  return useMemo(
    () => ({
      staff,
      plan,
      loading: staff && !plan && status !== 'error',
      error,
      access: (module: WorkspaceModule) => (plan ? moduleAccess(plan, module) : 'open'),
      feature: (key: FeatureKey) => (plan ? featureAccess(plan, key) : 'open'),
      choosingPlan: plan ? needsPlanChoice(plan) : false,
      refresh: run,
    }),
    [staff, plan, status, error, run],
  );
}
