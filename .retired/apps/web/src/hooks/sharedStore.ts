import type { AsyncState } from './useAsync';

/*
 * A record read once and shared by every screen that shows it — the academy's billing summary, its plan — for
 * one signed-in account at a time. Kept free of the services and the session so it can be tested on its own.
 */

/** One record read once and shared by every screen that shows it, for one signed-in account at a time. */
export interface SharedStore<T> {
  /** The record as last read, for `owner`. */
  getState(): AsyncState<T>;
  subscribe(listener: () => void): () => void;
  /** Reads the record for `owner` — once, unless `force`; a read already running is shared. */
  load(owner: string, force?: boolean): Promise<T>;
  /** Whose record the store holds. */
  owner(): string | null;
}

export function createSharedStore<T>(read: () => Promise<T>): SharedStore<T> {
  let owner: string | null = null;
  let state: AsyncState<T> = { status: 'idle' };
  let inflight: Promise<T> | null = null;
  const listeners = new Set<() => void>();
  const set = (next: AsyncState<T>) => {
    state = next;
    listeners.forEach((l) => l());
  };

  return {
    getState: () => state,
    owner: () => owner,
    subscribe(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    load(account, force = false) {
      if (owner !== account) {
        // Another account signed in: forget the last one's summary before reading this one's.
        owner = account;
        inflight = null;
        set({ status: 'idle' });
      }
      if (inflight && !force) return inflight;
      if (!force && state.status === 'success') return Promise.resolve(state.data);
      set({ status: 'loading', data: state.data });
      const call = read();
      inflight = call;
      return call.then(
        (data) => {
          if (inflight === call && owner === account) {
            inflight = null;
            set({ status: 'success', data });
          }
          return data;
        },
        (error: Error) => {
          if (inflight === call && owner === account) {
            inflight = null;
            set({ status: 'error', error, data: state.data });
          }
          throw error;
        },
      );
    },
  };
}
