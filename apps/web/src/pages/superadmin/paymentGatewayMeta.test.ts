import { describe, expect, it } from 'vitest';
import type { GatewayCredentialView, GatewayView } from '@/services';
import {
  MASKED,
  activationReason,
  blankValues,
  credentialsPayload,
  environmentSwitchBlocker,
  fieldIsSet,
  gatewayActions,
  gatewayFormIssues,
  hasAnyCredentials,
  hasTyped,
  slotStatus,
  storedValue,
  testResultTone,
  webhookUrl,
} from './paymentGatewayMeta';

const empty: GatewayCredentialView = { configured: false, needsReentry: false, hint: {}, secretsSet: [], configuredAt: null };
const testSlot: GatewayCredentialView = {
  configured: true,
  needsReentry: false,
  hint: { keyId: 'rzp_test_…te01' },
  secretsSet: ['keySecret', 'webhookSecret'],
  configuredAt: '2026-09-01T10:00:00Z',
};

const razorpay = (over: Partial<GatewayView> = {}): GatewayView => ({
  provider: 'razorpay',
  label: 'Razorpay',
  implemented: true,
  fieldsProvisional: false,
  enabled: true,
  environment: 'test',
  isActive: false,
  configured: true,
  needsReentry: false,
  credentials: { test: testSlot, live: empty },
  hint: testSlot.hint,
  secretsSet: testSlot.secretsSet,
  configuredAt: testSlot.configuredAt,
  canActivate: true,
  testSupported: true,
  fields: [
    { key: 'keyId', label: 'Key ID', secret: false },
    { key: 'keySecret', label: 'Key secret', secret: true },
    { key: 'webhookSecret', label: 'Webhook secret', secret: true },
  ],
  updatedAt: '2026-09-01T10:00:00Z',
  ...over,
});

const vyapar = (over: Partial<GatewayView> = {}): GatewayView => ({
  ...razorpay(),
  provider: 'vyapargateway',
  label: 'VyaparGateway',
  implemented: false,
  enabled: false,
  fieldsProvisional: true,
  credentials: { test: empty, live: empty },
  configured: false,
  canActivate: false,
  activationBlockedReason: 'The merchant API contract is not available.',
  testSupported: false,
  fields: [
    { key: 'apiCredential', label: 'API credential', secret: true },
    { key: 'webhookSecret', label: 'Webhook secret', secret: true },
  ],
  ...over,
});

const messages = (g: GatewayView, env: 'test' | 'live', values: Record<string, string>) => gatewayFormIssues(g, env, values).map((i) => i.message);

describe('the payment gateway screen', () => {
  it('builds the webhook address on the API base', () => {
    expect(webhookUrl('https://api.example.com/', 'razorpay')).toBe('https://api.example.com/webhooks/razorpay/courses');
    expect(webhookUrl('http://localhost:4000', 'vyapargateway')).toBe('http://localhost:4000/webhooks/vyapargateway/courses');
  });

  it('shows each environment on its own: a secret only as dots, a key id only as its mask', () => {
    const g = razorpay();
    expect(storedValue(g, 'test', 'keySecret')).toBe(MASKED);
    expect(storedValue(g, 'test', 'keyId')).toBe('rzp_test_…te01');
    expect(storedValue(g, 'live', 'keySecret')).toBe('Not set');
    expect(storedValue(g, 'live', 'keyId')).toBe('Not set');
    expect(storedValue(razorpay({ credentials: { test: { ...testSlot, configured: false, needsReentry: true }, live: empty } }), 'test', 'keyId')).toBe(
      'Must be re-entered',
    );
    expect(slotStatus(testSlot)).toBe('configured');
    expect(slotStatus(empty)).toBe('not-configured');
    expect(slotStatus({ ...testSlot, configured: false, needsReentry: true })).toBe('needs-reentry');
  });

  it('offers Configure only when nothing is stored in either environment', () => {
    expect(hasAnyCredentials(razorpay())).toBe(true);
    expect(hasAnyCredentials(vyapar())).toBe(false);
    expect(hasAnyCredentials(vyapar({ credentials: { test: empty, live: { ...empty, needsReentry: true } } }))).toBe(true);
  });

  it('never prefills, and sends only what was typed — a blank field keeps its stored value', () => {
    const g = razorpay();
    expect(blankValues(g)).toEqual({ keyId: '', keySecret: '', webhookSecret: '' });
    expect(hasTyped(blankValues(g))).toBe(false);
    const values = { keyId: '  ', keySecret: ' new-secret ', webhookSecret: '' };
    expect(hasTyped(values)).toBe(true);
    expect(credentialsPayload(g, values)).toEqual({ keySecret: 'new-secret' });
    expect(messages(g, 'test', values)).toEqual([]);
  });

  it('asks for every field in an environment with nothing usable, and only there', () => {
    const g = razorpay();
    expect(fieldIsSet(g, 'test', 'keySecret')).toBe(true);
    expect(fieldIsSet(g, 'live', 'keySecret')).toBe(false);
    expect(messages(g, 'live', blankValues(g))).toEqual(['Key ID is required.', 'Key secret is required.', 'Webhook secret is required.']);
    const reentry = razorpay({ credentials: { test: { ...testSlot, configured: false, needsReentry: true }, live: empty } });
    expect(messages(reentry, 'test', blankValues(reentry))).toHaveLength(3);
  });

  it('checks the Razorpay key prefix against the environment being saved', () => {
    const g = razorpay();
    expect(messages(g, 'live', { keyId: 'rzp_test_abc', keySecret: 'a', webhookSecret: 'b' })).toEqual([
      'This is not a live key: Razorpay live key IDs begin with rzp_live_.',
    ]);
    expect(messages(g, 'test', { keyId: 'rzp_live_abc', keySecret: '', webhookSecret: '' })).toEqual([
      'This is not a test key: Razorpay test key IDs begin with rzp_test_.',
    ]);
    expect(messages(g, 'live', { keyId: 'rzp_live_abc', keySecret: 'a', webhookSecret: 'b' })).toEqual([]);
  });

  it('refuses a value over 500 characters, and two secrets that are the same', () => {
    const g = razorpay();
    expect(messages(g, 'test', { keyId: '', keySecret: 'x'.repeat(501), webhookSecret: '' })).toEqual(['Key secret is too long.']);
    expect(messages(g, 'test', { keyId: '', keySecret: 'same', webhookSecret: 'same' })).toEqual(['The webhook secret must be different from the key secret.']);
    expect(messages(vyapar(), 'test', { apiCredential: 'same', webhookSecret: 'same' })).toEqual([
      'The webhook secret must be different from the API credential.',
    ]);
  });

  it('gives the server’s reason a gateway cannot be made active', () => {
    expect(activationReason(razorpay())).toBeNull();
    expect(activationReason(razorpay({ isActive: true, canActivate: false }))).toMatch(/already the active/);
    expect(activationReason(vyapar())).toBe('The merchant API contract is not available.');
    expect(activationReason(razorpay({ canActivate: false, activationBlockedReason: undefined }))).toMatch(/cannot be set active/);
  });

  it('allows switching new payments only to an environment with credentials', () => {
    expect(environmentSwitchBlocker(razorpay(), 'test')).toBeNull();
    expect(environmentSwitchBlocker(razorpay(), 'live')).toMatch(/No usable live credentials/);
    expect(environmentSwitchBlocker(razorpay({ credentials: { test: testSlot, live: testSlot } }), 'live')).toBeNull();
  });

  it('shows success only when the gateway was asked and accepted; nothing checked is information', () => {
    expect(testResultTone({ ok: true, checked: true, environment: 'test', detail: '' })).toBe('success');
    expect(testResultTone({ ok: false, checked: true, environment: 'test', detail: '' })).toBe('error');
    expect(testResultTone({ ok: false, checked: false, environment: 'test', detail: '' })).toBe('info');
    // A result that claims success without a check is still not a success.
    expect(testResultTone({ ok: true, checked: false, environment: 'test', detail: '' })).toBe('info');
  });
});

describe('the actions on a gateway card', () => {
  it('never disables Configure — not without secure storage on the server, not for a gateway without an adapter', () => {
    for (const vault of [true, false]) {
      for (const g of [razorpay(), razorpay({ isActive: true }), vyapar(), vyapar({ enabled: true })]) {
        expect(gatewayActions(g, vault).configure.disabled, `${g.provider} vault=${vault}`).toBe(false);
        expect(gatewayActions(g, vault).test.disabled).toBe(false);
      }
    }
    expect(gatewayActions(vyapar(), false).configure.label).toBe('Configure');
    expect(gatewayActions(razorpay(), false).configure.label).toBe('Replace credentials');
  });

  it('lets VyaparGateway be enabled, but not set active, with the server’s reason', () => {
    const actions = gatewayActions(vyapar(), true);
    expect(actions.toggle).toMatchObject({ label: 'Enable', disabled: false });
    expect(actions.activate).toMatchObject({ disabled: true, reason: 'The merchant API contract is not available.' });
  });

  it('will not offer to disable the active gateway', () => {
    expect(gatewayActions(razorpay({ isActive: true, canActivate: false }), true).toggle).toMatchObject({ label: 'Disable', disabled: true });
    expect(gatewayActions(razorpay(), true).toggle.disabled).toBe(false);
  });
});
