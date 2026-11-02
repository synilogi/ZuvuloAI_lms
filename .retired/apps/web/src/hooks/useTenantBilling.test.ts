import { describe, expect, it, vi } from 'vitest';
import type { TenantBilling } from '@syniastrolms/domain';
import { createTenantBillingStore } from './useTenantBilling';

/* The academy's billing summary is read once and shared by the banner and the billing page — and never shown to
 * another account. */

const summary = (name: string) => ({ academy: { id: name, name } }) as TenantBilling;

describe('the shared billing summary', () => {
  it('reads once for everyone who asks, and again only when forced', async () => {
    const read = vi.fn(() => Promise.resolve(summary('a')));
    const store = createTenantBillingStore(read);
    await Promise.all([store.load('u1'), store.load('u1')]);
    await store.load('u1');
    expect(read).toHaveBeenCalledTimes(1);
    expect(store.getState()).toMatchObject({ status: 'success', data: { academy: { name: 'a' } } });

    await store.load('u1', true);
    expect(read).toHaveBeenCalledTimes(2);
  });

  it('tells its listeners, and keeps what it had while it reads again', async () => {
    let resolve!: (v: TenantBilling) => void;
    const read = vi
      .fn()
      .mockResolvedValueOnce(summary('a'))
      .mockImplementationOnce(() => new Promise<TenantBilling>((r) => (resolve = r)));
    const store = createTenantBillingStore(read);
    const heard = vi.fn();
    store.subscribe(heard);
    await store.load('u1');
    const again = store.load('u1', true);
    expect(store.getState()).toMatchObject({ status: 'loading', data: { academy: { name: 'a' } } });
    resolve(summary('b'));
    await again;
    expect(store.getState()).toMatchObject({ status: 'success', data: { academy: { name: 'b' } } });
    expect(heard).toHaveBeenCalled();
  });

  it('forgets one account’s summary when another signs in', async () => {
    const read = vi.fn().mockResolvedValueOnce(summary('first')).mockResolvedValueOnce(summary('second'));
    const store = createTenantBillingStore(read);
    await store.load('u1');
    const next = store.load('u2');
    expect(store.getState().data).toBeUndefined();
    await next;
    expect(store.owner()).toBe('u2');
    expect(store.getState().data?.academy.name).toBe('second');
  });

  it('keeps a failed read as an error, with what it had before', async () => {
    const read = vi.fn().mockResolvedValueOnce(summary('a')).mockRejectedValueOnce(new Error('offline'));
    const store = createTenantBillingStore(read);
    await store.load('u1');
    await expect(store.load('u1', true)).rejects.toThrow('offline');
    expect(store.getState()).toMatchObject({ status: 'error', data: { academy: { name: 'a' } } });
  });
});
