import { useCallback, useEffect, useSyncExternalStore } from 'react';
import type { TenantBilling } from '@syniastrolms/domain';
import { services } from '@/services';
import type { AsyncState } from './useAsync';
import { createSharedStore, type SharedStore } from './sharedStore';

export { createSharedStore, type SharedStore } from './sharedStore';

/*
 * The academy's billing summary (`/tenant/billing`), read once and shared: the shell's billing banner reads it
 * on load, and the billing page shows the same record and refreshes it after every change, so the banner
 * follows what the page did. A different signed-in account starts from nothing — one academy's summary is
 * never shown to another.
 */

export type TenantBillingStore = SharedStore<TenantBilling>;

/** The academy's billing summary. Kept under its own name: the tests and the billing screens know it by it. */
export const createTenantBillingStore = (read: () => Promise<TenantBilling>): TenantBillingStore => createSharedStore(read);

/** The one billing summary the app holds. Exported so the academy's plan can follow what billing does. */
export const tenantBillingStore = createTenantBillingStore(() => services.tenantBilling.summary());
const store = tenantBillingStore;

/**
 * The shared summary for the signed-in `account`, read when first asked for. `refresh` reads it again on mount
 * (the billing page wants it current) while showing what is already known. Shaped like `useAsync`.
 */
export function useTenantBilling(account: string | null | undefined, { enabled = true, refresh = false } = {}) {
  const snapshot = useSyncExternalStore(store.subscribe, store.getState);
  useEffect(() => {
    if (enabled && account) store.load(account, refresh).catch(() => undefined);
  }, [account, enabled, refresh]);
  const run = useCallback(() => (account ? store.load(account, true) : Promise.reject(new Error('Not signed in.'))), [account]);
  const state: AsyncState<TenantBilling> = account && store.owner() === account ? snapshot : { status: 'idle' };
  return { ...state, run };
}
