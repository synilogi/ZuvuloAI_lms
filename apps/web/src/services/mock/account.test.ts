import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { accountService as service } from './account';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('account mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('confirms a deletion with a password the demo sign-in would accept', async () => {
    await expect(settle(service.deleteAccount('demo-password'))).resolves.toBeUndefined();
  });

  it('refuses a password the demo sign-in would not accept, in the words the API uses', async () => {
    const result = service.deleteAccount('nope');
    const settled = expect(result).rejects.toMatchObject({ code: 'forbidden', message: 'Your password is not correct.' });
    await vi.runAllTimersAsync();
    await settled;
  });
});
