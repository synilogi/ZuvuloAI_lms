import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';
import { settingsService as service } from './settings';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

describe('settings mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('saves a section on its own and records who changed it', async () => {
    const before = await settle(service.get());
    const general = { ...before.settings.general, lmsLabel: 'My learning' };
    const after = await settle(service.save('general', general));
    expect(after.settings.general.lmsLabel).toBe('My learning');
    expect(after.settings.learning).toEqual(before.settings.learning);
    expect(after.updatedAt.general > before.updatedAt.general).toBe(true);
    expect(after.updatedBy.general).toBe('Kavita Menon');
  });

  it('refuses a section that fails validation and keeps the saved one', async () => {
    const before = await settle(service.get());
    const refused = service.save('certificates', { ...before.settings.certificates, credentialPrefix: 'a1' });
    const expectation = expect(refused).rejects.toThrow('capital letters');
    await vi.runAllTimersAsync();
    await expectation;
    expect((await settle(service.get())).settings.certificates.credentialPrefix).toBe(before.settings.certificates.credentialPrefix);
  });
});
