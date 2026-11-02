import type {
  GatewayCredentialView,
  GatewayEnvironment,
  GatewayField,
  GatewayList,
  GatewayTestResult,
  GatewayUpdate,
  GatewayView,
  PaymentGatewayService,
} from '../contracts';
import { GATEWAY_ENVIRONMENTS, ServiceError } from '../contracts';
import { mockNowIso } from './clock';
import { respond } from './simulation';

/*
 * The platform's payment gateways, served from memory — the demo build's stand-in for
 * `/superadmin/payment-gateways` (http mode reads `services/http/paymentGateways.ts`).
 *
 * It applies the API's rules: test and live credentials are separate slots, saved one at a time; a blank
 * field keeps what that slot has, and every field is needed where it has nothing; only an implemented,
 * enabled gateway with usable credentials for its environment can be made active; at most one is active; the
 * active one cannot be disabled, and a gateway can switch only to an environment that has credentials.
 * Without secure storage (`setMockVaultConfigured(false)`) a save is refused the way the API refuses it.
 *
 * Nothing typed is kept: a key id is reduced to its masked hint the moment it is saved and a secret to the
 * fact that it is set, so there is no value here to leak. No gateway is ever contacted, so a test never
 * reports a check it did not make.
 */

interface Descriptor {
  provider: string;
  label: string;
  implemented: boolean;
  unavailableReason?: string;
  fieldsProvisional: boolean;
  fields: GatewayField[];
}

const VYAPAR_PENDING =
  'VyaparGateway’s merchant API contract is not available: its payment, status and refund endpoints, authentication and webhook signature format are published only in the merchant dashboard. Its credentials can be stored now; it can take payments once the adapter is written from that contract.';

const GATEWAYS: readonly Descriptor[] = [
  {
    provider: 'razorpay',
    label: 'Razorpay',
    implemented: true,
    fieldsProvisional: false,
    fields: [
      { key: 'keyId', label: 'Key ID', secret: false, help: 'From Razorpay Dashboard → Account & Settings → API keys. Starts with rzp_test_ or rzp_live_.' },
      { key: 'keySecret', label: 'Key secret', secret: true, help: 'Shown once by Razorpay when the key is generated.' },
      {
        key: 'webhookSecret',
        label: 'Webhook secret',
        secret: true,
        help: 'The secret you set on the webhook in Razorpay Dashboard → Webhooks. It is not the key secret.',
      },
    ],
  },
  {
    provider: 'vyapargateway',
    label: 'VyaparGateway',
    implemented: false,
    unavailableReason: VYAPAR_PENDING,
    fieldsProvisional: true,
    fields: [
      { key: 'apiCredential', label: 'API credential', secret: true, help: 'The server-side API key or secret from the VyaparGateway merchant dashboard.' },
      { key: 'webhookSecret', label: 'Webhook secret', secret: true, help: 'The secret VyaparGateway signs webhooks with (HMAC-SHA256).' },
    ],
  },
];

/** One environment's stored credentials, as the demo keeps them: masks and flags, never a value. */
interface Slot {
  /** Sealed under another key: unreadable until entered again. */
  sealedElsewhere: boolean;
  hint: Record<string, string>;
  configuredAt: string;
}

interface Stored {
  enabled: boolean;
  environment: GatewayEnvironment;
  isActive: boolean;
  slots: Partial<Record<GatewayEnvironment, Slot>>;
  updatedAt: string | null;
}

/** The demo opens with Razorpay configured for test and taking payments; VyaparGateway has nothing stored. */
function initialState(): Record<string, Stored> {
  const at = '2026-09-01T10:30:00+05:30';
  return {
    razorpay: {
      enabled: true,
      environment: 'test',
      isActive: true,
      slots: { test: { sealedElsewhere: false, hint: { keyId: 'rzp_test_…mo01' }, configuredAt: at } },
      updatedAt: at,
    },
    vyapargateway: { enabled: false, environment: 'test', isActive: false, slots: {}, updatedAt: null },
  };
}

let state = initialState();
let vault = true;

/** Puts the demo back as it opened. For tests. */
export function resetPaymentGateways() {
  state = initialState();
  vault = true;
}

/** Whether the demo server has PAYMENT_CREDENTIALS_KEY. For tests and previews of the missing-key state. */
export function setMockVaultConfigured(configured: boolean) {
  vault = configured;
}

/** Marks one environment's credentials as sealed under another key, as after a key rotation. For tests. */
export function markNeedsReentry(provider: string, environment: GatewayEnvironment = 'test') {
  const slot = state[provider]?.slots[environment];
  if (slot) slot.sealedElsewhere = true;
}

/** The API's refusal when the server has no PAYMENT_CREDENTIALS_KEY, as the HTTP client hands it on (a 503). */
export const SECURE_STORAGE_MESSAGE =
  'Secure credential storage is not configured on the server. The server administrator must set PAYMENT_CREDENTIALS_KEY and restart the API; nothing was saved.';

const conflict = (message: string) => new ServiceError(message, 'conflict', 'CONFLICT');
const invalid = (message: string) => new ServiceError(message, 'conflict', 'VALIDATION_FAILED');

function descriptor(provider: string): Descriptor {
  const found = GATEWAYS.find((g) => g.provider === provider);
  if (!found) throw new ServiceError('No such payment gateway.', 'not-found', 'NOT_FOUND');
  return found;
}

/** The same masking the API applies: the key id's publishable prefix and its last four characters. */
export const maskKeyId = (value: string) => `${/^rzp_(test|live)_/.exec(value)?.[0] ?? ''}…${value.slice(-4)}`;

/** Stored credentials open only under this deployment's key. */
const usable = (slot: Slot | undefined): slot is Slot => Boolean(slot) && vault && !slot!.sealedElsewhere;

function credentialView(g: Descriptor, slot: Slot | undefined): GatewayCredentialView {
  return {
    configured: usable(slot),
    needsReentry: Boolean(slot) && !usable(slot),
    hint: { ...(slot?.hint ?? {}) },
    secretsSet: slot ? g.fields.filter((f) => f.secret).map((f) => f.key) : [],
    configuredAt: slot?.configuredAt ?? null,
  };
}

function activationBlocker(g: Descriptor, s: Stored, current: GatewayCredentialView): string | undefined {
  if (!g.implemented) return g.unavailableReason ?? `${g.label} cannot take payments yet.`;
  if (current.needsReentry) return `Its ${s.environment} credentials were saved under another encryption key. Enter them again.`;
  if (!current.configured) return `It has no ${s.environment} credentials. Configure them first.`;
  if (!s.enabled) return 'It is disabled. Enable it first.';
  return undefined;
}

function view(g: Descriptor): GatewayView {
  const s = state[g.provider];
  const credentials = Object.fromEntries(GATEWAY_ENVIRONMENTS.map((env) => [env, credentialView(g, s.slots[env])])) as Record<
    GatewayEnvironment,
    GatewayCredentialView
  >;
  const current = credentials[s.environment];
  const blocker = s.isActive ? undefined : activationBlocker(g, s, current);
  return {
    provider: g.provider,
    label: g.label,
    implemented: g.implemented,
    ...(g.unavailableReason ? { unavailableReason: g.unavailableReason } : {}),
    fieldsProvisional: g.fieldsProvisional,
    enabled: s.enabled,
    environment: s.environment,
    isActive: s.isActive,
    configured: current.configured,
    needsReentry: current.needsReentry,
    credentials,
    hint: { ...current.hint },
    secretsSet: [...current.secretsSet],
    configuredAt: current.configuredAt,
    canActivate: !s.isActive && !blocker,
    ...(blocker ? { activationBlockedReason: blocker } : {}),
    testSupported: g.implemented,
    fields: g.fields.map((f) => ({ ...f })),
    updatedAt: s.updatedAt,
  };
}

function configure(provider: string, environment: GatewayEnvironment, credentials: Record<string, string>): GatewayView {
  const g = descriptor(provider);
  if (!vault) throw new ServiceError(SECURE_STORAGE_MESSAGE, 'unknown', 'SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED');
  if (environment !== 'test' && environment !== 'live') throw invalid('Choose the test or the live environment.');
  const known = new Set(g.fields.map((f) => f.key));
  const unknown = Object.keys(credentials ?? {}).filter((k) => !known.has(k));
  if (unknown.length) throw invalid(`${g.label} has no field ${unknown.join(', ')}.`);

  const s = state[provider];
  const existing = s.slots[environment];
  const kept = usable(existing);
  const given: Record<string, string> = {};
  for (const field of g.fields) {
    const value = credentials?.[field.key]?.trim();
    if (value) {
      if (value.length > 500) throw invalid(`${field.label} is too long.`);
      given[field.key] = value;
    } else if (!kept) {
      throw invalid(existing ? `${field.label} is required: the stored credentials must be entered again.` : `${field.label} is required.`);
    }
  }
  // The format checks the API runs on the merged credentials. A kept value was checked when it was saved.
  if (g.provider === 'razorpay' && given.keyId) {
    const prefix = environment === 'live' ? 'rzp_live_' : 'rzp_test_';
    if (!given.keyId.startsWith(prefix)) throw invalid(`This is not a ${environment} key: Razorpay ${environment} key IDs begin with ${prefix}.`);
  }
  const [a, b] = g.provider === 'razorpay' ? ['keySecret', 'webhookSecret'] : ['apiCredential', 'webhookSecret'];
  if (given[a] && given[a] === given[b]) {
    throw invalid(`The webhook secret must be different from the ${g.provider === 'razorpay' ? 'key secret' : 'API credential'}.`);
  }

  const now = mockNowIso();
  const hint: Record<string, string> = g.provider === 'razorpay' ? { keyId: given.keyId ? maskKeyId(given.keyId) : (existing?.hint.keyId ?? '') } : {};
  // Only the mask survives the save; the values typed are dropped here.
  s.slots[environment] = { sealedElsewhere: false, hint, configuredAt: now };
  // A gateway configured for the first time takes the environment it was configured in.
  if (!s.updatedAt && !s.slots[environment === 'test' ? 'live' : 'test']) s.environment = environment;
  s.updatedAt = now;
  return view(g);
}

function update(provider: string, changes: GatewayUpdate): GatewayView {
  const g = descriptor(provider);
  const s = state[provider];
  if (changes.enabled !== undefined && typeof changes.enabled !== 'boolean') throw invalid('Say whether the gateway is enabled.');
  if (changes.environment !== undefined && changes.environment !== 'test' && changes.environment !== 'live')
    throw invalid('Choose the test or the live environment.');
  const next = { ...s };
  if (changes.enabled !== undefined && changes.enabled !== s.enabled) {
    if (!changes.enabled && s.isActive) {
      throw conflict(`${g.label} is the active gateway. Activate another gateway, or turn off online payment, before disabling it.`);
    }
    next.enabled = changes.enabled;
  }
  if (changes.environment && changes.environment !== s.environment) {
    if (!usable(s.slots[changes.environment])) throw conflict(`${g.label} has no usable ${changes.environment} credentials. Configure them first.`);
    next.environment = changes.environment;
  }
  if (next.enabled !== s.enabled || next.environment !== s.environment) state[provider] = { ...next, updatedAt: mockNowIso() };
  return view(g);
}

function test(provider: string, requested?: GatewayEnvironment): GatewayTestResult {
  const g = descriptor(provider);
  const s = state[provider];
  const environment = requested ?? s.environment;
  const slot = s.slots[environment];
  if (!vault)
    return { ok: false, checked: false, environment, detail: 'Secure credential storage is not configured on the server, so no credentials can be read.' };
  if (!usable(slot)) {
    return {
      ok: false,
      checked: false,
      environment,
      detail: slot ? `The ${environment} credentials were saved under another encryption key. Enter them again.` : `No ${environment} credentials are saved.`,
    };
  }
  if (!g.implemented) {
    return {
      ok: false,
      checked: false,
      environment,
      detail: `Nothing was checked: ${g.label} has no adapter yet, so credential validation is performed when it creates payments, once its merchant API contract is available.`,
    };
  }
  return { ok: false, checked: false, environment, detail: 'Demo data: no gateway was contacted, so nothing was checked.' };
}

function activate(provider: string): GatewayView {
  const g = descriptor(provider);
  const s = state[provider];
  if (s.isActive) return view(g);
  const blocker = activationBlocker(g, s, credentialView(g, s.slots[s.environment]));
  if (blocker) throw conflict(`${g.label} cannot be set active: ${blocker}`);
  const now = mockNowIso();
  for (const [key, other] of Object.entries(state)) {
    if (other.isActive) state[key] = { ...other, isActive: false, updatedAt: now };
  }
  state[provider] = { ...state[provider], isActive: true, updatedAt: now };
  return view(g);
}

function deactivate(): { deactivated: string | null } {
  const active = Object.entries(state).find(([, s]) => s.isActive);
  if (!active) return { deactivated: null };
  state[active[0]] = { ...active[1], isActive: false, updatedAt: mockNowIso() };
  return { deactivated: active[0] };
}

export const paymentGatewayService: PaymentGatewayService = {
  list: () =>
    respond<GatewayList>(() => ({
      rows: GATEWAYS.map(view),
      vaultConfigured: vault,
      active: Object.entries(state).find(([, s]) => s.isActive)?.[0] ?? null,
    })),
  get: (provider) => respond(() => view(descriptor(provider))),
  configure: (provider, input) => respond(() => configure(provider, input.environment, input.credentials), 900),
  update: (provider, changes) => respond(() => update(provider, changes)),
  test: (provider, environment) => respond(() => test(provider, environment), 1100),
  activate: (provider) => respond(() => activate(provider)),
  deactivate: () => respond(deactivate),
};
