import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import { platformErrorOf } from '@/lib/platformErrors';
import { ServiceError } from '../contracts';
import {
  SECURE_STORAGE_MESSAGE,
  markNeedsReentry,
  maskKeyId,
  paymentGatewayService as service,
  resetPaymentGateways,
  setMockVaultConfigured,
} from './paymentGateways';

async function settle<T>(promise: Promise<T>) {
  await vi.runAllTimersAsync();
  return promise;
}

/** Settles a call that should be refused, and answers with the refusal. */
async function refused(promise: Promise<unknown>): Promise<ServiceError> {
  const caught = promise.then(
    () => {
      throw new Error('expected the call to be refused');
    },
    (e: unknown) => e as ServiceError,
  );
  await vi.runAllTimersAsync();
  return caught;
}

const TEST = { keyId: 'rzp_test_AbCdEfGh1234', keySecret: 'test-key-secret-never-returned', webhookSecret: 'test-whsec-never-returned' };
const LIVE = { keyId: 'rzp_live_ZyXwVuTs9876', keySecret: 'live-key-secret-never-returned', webhookSecret: 'live-whsec-never-returned' };
const VYAPAR = { apiCredential: 'vyapar-api-credential-never-returned', webhookSecret: 'vyapar-whsec-never-returned' };

describe('payment gateway mock service', () => {
  beforeAll(() => {
    vi.stubGlobal('window', globalThis);
    vi.useFakeTimers();
  });
  afterAll(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });
  beforeEach(() => resetPaymentGateways());

  it('opens with Razorpay configured for test and active, VyaparGateway unconfigured, and says which is active', async () => {
    const list = await settle(service.list());
    expect(list.vaultConfigured).toBe(true);
    expect(list.active).toBe('razorpay');
    expect(list.rows.map((r) => r.provider)).toEqual(['razorpay', 'vyapargateway']);
    const [razorpay, vyapar] = list.rows;
    expect(razorpay).toMatchObject({ isActive: true, enabled: true, environment: 'test', configured: true, canActivate: false, testSupported: true });
    expect(razorpay.credentials.test.configured).toBe(true);
    expect(razorpay.credentials.live.configured).toBe(false);
    expect(vyapar).toMatchObject({ implemented: false, fieldsProvisional: true, configured: false, testSupported: false, canActivate: false });
    expect(vyapar.fields.map((f) => f.key)).toEqual(['apiCredential', 'webhookSecret']);
    expect(vyapar.activationBlockedReason).toMatch(/merchant API contract/);
  });

  it('keeps test and live apart: saving live leaves test untouched', async () => {
    const view = await settle(service.configure('razorpay', { environment: 'live', credentials: LIVE }));
    expect(view.credentials.live).toMatchObject({ configured: true, hint: { keyId: 'rzp_live_…9876' }, secretsSet: ['keySecret', 'webhookSecret'] });
    expect(view.credentials.test).toMatchObject({ configured: true, hint: { keyId: 'rzp_test_…mo01' } });
    // New payments still use test until the environment is switched.
    expect(view.environment).toBe('test');
    expect(view.hint).toEqual({ keyId: 'rzp_test_…mo01' });
  });

  it('never returns a typed value — only masks and which secrets are set', async () => {
    await settle(service.configure('razorpay', { environment: 'live', credentials: LIVE }));
    await settle(service.configure('razorpay', { environment: 'test', credentials: TEST }));
    await settle(service.configure('vyapargateway', { environment: 'test', credentials: VYAPAR }));
    const everything = JSON.stringify([await settle(service.list()), await settle(service.get('razorpay')), await settle(service.get('vyapargateway'))]);
    for (const value of [...Object.values(TEST), ...Object.values(LIVE), ...Object.values(VYAPAR)]) expect(everything).not.toContain(value);
  });

  it('masks a key id the way the API does', () => {
    expect(maskKeyId('rzp_live_ZyXw9876')).toBe('rzp_live_…9876');
    expect(maskKeyId('whatever1234')).toBe('…1234');
  });

  it('requires every field where the environment has nothing, then keeps a blank one', async () => {
    const missing = await refused(service.configure('razorpay', { environment: 'live', credentials: { keyId: LIVE.keyId } }));
    expect(missing).toMatchObject({ code: 'conflict', reason: 'VALIDATION_FAILED', message: 'Key secret is required.' });

    await settle(service.configure('razorpay', { environment: 'live', credentials: LIVE }));
    const replaced = await settle(service.configure('razorpay', { environment: 'live', credentials: { keySecret: 'a-new-live-secret' } }));
    expect(replaced.credentials.live).toMatchObject({ configured: true, hint: { keyId: 'rzp_live_…9876' }, secretsSet: ['keySecret', 'webhookSecret'] });
  });

  it('asks for everything again when the stored credentials need re-entry', async () => {
    markNeedsReentry('razorpay', 'test');
    const view = await settle(service.get('razorpay'));
    expect(view.credentials.test).toMatchObject({ configured: false, needsReentry: true });
    const error = await refused(service.configure('razorpay', { environment: 'test', credentials: { keySecret: 'x' } }));
    expect(error.message).toBe('Key ID is required: the stored credentials must be entered again.');
  });

  it('checks the key prefix, the distinct secrets and unknown fields as the API does', async () => {
    const prefix = await refused(service.configure('razorpay', { environment: 'live', credentials: TEST }));
    expect(prefix.message).toBe('This is not a live key: Razorpay live key IDs begin with rzp_live_.');
    const same = await refused(service.configure('razorpay', { environment: 'live', credentials: { ...LIVE, webhookSecret: LIVE.keySecret } }));
    expect(same.message).toBe('The webhook secret must be different from the key secret.');
    const unknown = await refused(service.configure('razorpay', { environment: 'test', credentials: { apiKey: 'x' } }));
    expect(unknown.message).toMatch(/no field apiKey/);
  });

  it('lets VyaparGateway be configured and enabled, but never activated', async () => {
    const configured = await settle(service.configure('vyapargateway', { environment: 'test', credentials: VYAPAR }));
    expect(configured.credentials.test.configured).toBe(true);
    expect(configured.secretsSet).toEqual(['apiCredential', 'webhookSecret']);
    const enabled = await settle(service.update('vyapargateway', { enabled: true }));
    expect(enabled.enabled).toBe(true);
    expect(enabled.canActivate).toBe(false);
    expect((await refused(service.activate('vyapargateway'))).message).toMatch(/cannot be set active/);
  });

  it('switches environment only to one with credentials', async () => {
    const refusedSwitch = await refused(service.update('razorpay', { environment: 'live' }));
    expect(refusedSwitch.message).toMatch(/no usable live credentials/);

    await settle(service.configure('razorpay', { environment: 'live', credentials: LIVE }));
    const switched = await settle(service.update('razorpay', { environment: 'live' }));
    expect(switched).toMatchObject({ environment: 'live', isActive: true, configured: true, hint: { keyId: 'rzp_live_…9876' } });
  });

  it('will not disable the active gateway', async () => {
    expect((await refused(service.update('razorpay', { enabled: false }))).message).toMatch(/active gateway/);
    await settle(service.deactivate());
    expect((await settle(service.update('razorpay', { enabled: false }))).enabled).toBe(false);
  });

  it('activates only an implemented, enabled gateway with credentials for its environment — and exactly one', async () => {
    await settle(service.deactivate());
    await settle(service.update('razorpay', { enabled: false }));
    const off = await settle(service.get('razorpay'));
    expect(off).toMatchObject({ canActivate: false, activationBlockedReason: 'It is disabled. Enable it first.' });
    expect((await refused(service.activate('razorpay'))).message).toMatch(/disabled/);

    await settle(service.update('razorpay', { enabled: true }));
    markNeedsReentry('razorpay');
    expect((await settle(service.get('razorpay'))).activationBlockedReason).toMatch(/another encryption key/);
    await settle(service.configure('razorpay', { environment: 'test', credentials: TEST }));

    const active = await settle(service.activate('razorpay'));
    expect(active.isActive).toBe(true);
    const list = await settle(service.list());
    expect(list.rows.filter((r) => r.isActive).map((r) => r.provider)).toEqual(['razorpay']);
    expect(list.active).toBe('razorpay');
  });

  it('turns online payment off, and says what it turned off', async () => {
    expect(await settle(service.deactivate())).toEqual({ deactivated: 'razorpay' });
    const list = await settle(service.list());
    expect(list.active).toBeNull();
    expect(list.rows.some((r) => r.isActive)).toBe(false);
    expect(await settle(service.deactivate())).toEqual({ deactivated: null });
  });

  it('never reports a check it did not make', async () => {
    const demo = await settle(service.test('razorpay'));
    expect(demo).toEqual({ ok: false, checked: false, environment: 'test', detail: 'Demo data: no gateway was contacted, so nothing was checked.' });
    expect(await settle(service.test('razorpay', 'live'))).toMatchObject({
      ok: false,
      checked: false,
      environment: 'live',
      detail: 'No live credentials are saved.',
    });

    await settle(service.configure('vyapargateway', { environment: 'test', credentials: VYAPAR }));
    const vyapar = await settle(service.test('vyapargateway'));
    expect(vyapar).toMatchObject({ ok: false, checked: false });
    expect(vyapar.detail).toMatch(/^Nothing was checked/);
  });

  it('refuses to save without secure storage, as the API does, and still lists the gateways', async () => {
    setMockVaultConfigured(false);
    const list = await settle(service.list());
    expect(list.vaultConfigured).toBe(false);
    const error = await refused(service.configure('razorpay', { environment: 'live', credentials: LIVE }));
    expect(error).toBeInstanceOf(ServiceError);
    expect(error.reason).toBe('SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED');
    expect(error.message).toBe(SECURE_STORAGE_MESSAGE);
    expect(platformErrorOf(error)?.title).toBe('Secure credential storage is not configured on the server.');
    expect((await settle(service.test('razorpay'))).checked).toBe(false);
  });

  it('answers an unknown gateway as not found', async () => {
    expect((await refused(service.get('stripe'))).code).toBe('not-found');
  });
});
