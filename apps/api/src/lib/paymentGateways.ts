import { GATEWAY_AUDIT_ACTIONS, recordAuditLog, type AuditAttribution } from './audit.js';
import { openCredentials, sealCredentials, vaultConfigured, vaultKeyId, VaultError } from './credentialVault.js';
import { db } from './db.js';
import { ApiError, notFound } from './errors.js';
import { readJson, writeJson } from './json.js';
import { observe } from './observe.js';
import { PaymentUnavailableError, providerOverride, type PaymentProvider } from './paymentProvider.js';
import { RazorpayProvider } from './razorpay.js';
import { SANDBOX, sandboxEnabled, sandboxProvider } from './sandboxGateway.js';
import { runAsPlatform } from './tenancy.js';

/*
 * The payment gateways and the factory that builds them (SAAS-017, decision D11).
 *
 * The Super Admin configures each gateway from the panel. The one server prerequisite is the encryption key,
 * `PAYMENT_CREDENTIALS_KEY`, a deployment secret that is never entered in the panel or stored in the database.
 * Each gateway has two credential slots, `test` and `live`, stored apart (`PaymentGatewayCredential`) and
 * encrypted. The gateway's `environment` says which slot new payments use. Which gateway is active is the
 * Super Admin's choice; the backend alone applies it:
 *
 *   - a new payment goes through the active gateway, in its environment (`activeProvider`); the invoice is
 *     pinned to the gateway, and the checkout order records the environment;
 *   - anything that already exists — an invoice's further checkouts, a confirmation, a webhook, a refund,
 *     reconciliation — goes through the gateway and environment recorded on it (`providerFor`), never
 *     re-resolved from what is active now. A gateway that is disabled or no longer active still serves what it
 *     created, while its credentials are stored.
 *
 * Rules on the active gateway: it is implemented, enabled, and has credentials for its environment (the
 * database holds the last two); at most one is active (a unique index); the active gateway cannot be disabled —
 * activate another, or deactivate online payment on purpose ("no gateway" is supported: invoices are then paid
 * by hand). Every change is audited, and a refused save too, with no secret in any entry.
 *
 * Nothing here returns, logs or audits a decrypted credential. `listGateways` returns only what the panel may
 * show: status flags, the environment, and masked hints.
 */

export type GatewayEnvironment = 'test' | 'live';
export const GATEWAY_ENVIRONMENTS: readonly GatewayEnvironment[] = ['test', 'live'];

export interface GatewayField {
  key: string;
  label: string;
  /** A secret is write-only: never returned, and a blank value on save keeps the stored one. */
  secret: boolean;
  help?: string;
}

interface GatewayDescriptor {
  id: string;
  label: string;
  /** Whether the platform has an adapter for it. Without one its credentials can be stored, but it cannot take payments. */
  implemented: boolean;
  /** Why an unimplemented gateway cannot take payments, for the panel. */
  unavailableReason?: string;
  /** The credential fields are what is publicly confirmed, pending the gateway's full merchant contract. */
  fieldsProvisional?: boolean;
  fields: GatewayField[];
  /** A format check of complete credentials for an environment; a message when they cannot be right. Never echoes a value. */
  validate?: (credentials: Record<string, string>, environment: GatewayEnvironment) => string | null;
  build?: (credentials: Record<string, string>, environment: GatewayEnvironment) => PaymentProvider;
  /** A hint that is safe to show for the non-secret fields. */
  hint?: (credentials: Record<string, string>) => Record<string, string>;
}

/** The last four characters, behind the value's publishable prefix: `rzp_test_…AbCd`. */
const maskKeyId = (value: string) => {
  const prefix = /^rzp_(test|live)_/.exec(value)?.[0] ?? '';
  return `${prefix}…${value.slice(-4)}`;
};

const VYAPAR_PENDING =
  'VyaparGateway’s merchant API contract is not available: its payment, status and refund endpoints, authentication and webhook signature format are published only in the merchant dashboard. Its credentials can be stored now; it can take payments once the adapter is written from that contract.';

export const GATEWAYS: readonly GatewayDescriptor[] = [
  {
    id: 'razorpay',
    label: 'Razorpay',
    implemented: true,
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
    validate: (c, environment) => {
      const prefix = environment === 'live' ? 'rzp_live_' : 'rzp_test_';
      if (!c.keyId!.startsWith(prefix)) return `This is not a ${environment} key: Razorpay ${environment} key IDs begin with ${prefix}.`;
      if (c.webhookSecret === c.keySecret) return 'The webhook secret must be different from the key secret.';
      return null;
    },
    build: (c, environment) => new RazorpayProvider({ keyId: c.keyId!, keySecret: c.keySecret!, webhookSecret: c.webhookSecret }, undefined, environment),
    hint: (c) => ({ keyId: maskKeyId(c.keyId ?? '') }),
  },
  {
    id: 'vyapargateway',
    label: 'VyaparGateway',
    implemented: false,
    unavailableReason: VYAPAR_PENDING,
    fieldsProvisional: true,
    // Only what VyaparGateway publicly confirms: server-side API credentials, and a webhook secret for its
    // HMAC-SHA256-signed webhooks. The exact credential names come from the merchant dashboard.
    fields: [
      { key: 'apiCredential', label: 'API credential', secret: true, help: 'The server-side API key or secret from the VyaparGateway merchant dashboard.' },
      { key: 'webhookSecret', label: 'Webhook secret', secret: true, help: 'The secret VyaparGateway signs webhooks with (HMAC-SHA256).' },
    ],
    validate: (c) => (c.webhookSecret === c.apiCredential ? 'The webhook secret must be different from the API credential.' : null),
  },
];

export const GATEWAY_IDS = GATEWAYS.map((g) => g.id);

function descriptor(provider: string): GatewayDescriptor {
  const found = GATEWAYS.find((g) => g.id === provider);
  if (!found) throw notFound('No such payment gateway.');
  return found;
}

/** The gateway a payment was made through can no longer be used: a controlled refusal, nothing changed. */
export class GatewayUnavailableError extends ApiError {
  constructor(message: string) {
    super(409, message, undefined, 'CONFLICT');
    this.name = 'GatewayUnavailableError';
  }
}

/** No `PAYMENT_CREDENTIALS_KEY` on the server: credentials cannot be stored or read until it is set. */
export class SecureStorageNotConfiguredError extends ApiError {
  constructor() {
    super(
      503,
      'Secure credential storage is not configured on the server. The server administrator must set PAYMENT_CREDENTIALS_KEY and restart the API; nothing was saved.',
      undefined,
      'SECURE_CREDENTIAL_STORAGE_NOT_CONFIGURED',
    );
    this.name = 'SecureStorageNotConfiguredError';
  }
}

const conflict = (message: string) => new ApiError(409, message, undefined, 'CONFLICT');
const invalid = (message: string) => new ApiError(400, message, undefined, 'VALIDATION_FAILED');
const platform = <R>(fn: () => Promise<R>) => runAsPlatform('payment gateways are platform configuration', fn);

type ConfigRow = NonNullable<Awaited<ReturnType<typeof db.paymentGatewayConfig.findUnique>>>;
type CredentialRow = NonNullable<Awaited<ReturnType<typeof db.paymentGatewayCredential.findUnique>>>;

const readConfig = (provider: string) => platform(() => db.paymentGatewayConfig.findUnique({ where: { provider } }));
const readCredential = (provider: string, environment: string) =>
  platform(() => db.paymentGatewayCredential.findUnique({ where: { provider_environment: { provider, environment } } }));

const asEnvironment = (value: string | null | undefined): GatewayEnvironment => (value === 'live' ? 'live' : 'test');

/** Whether stored credentials open under the key this deployment has. */
const usable = (cred: CredentialRow | null | undefined): cred is CredentialRow => Boolean(cred) && vaultConfigured() && cred!.keyId === vaultKeyId();

/* ─── The factory ─────────────────────────────────────────────────────── */

const built = new Map<string, { key: string; provider: PaymentProvider }>();

/** Builds (or reuses) the adapter for a gateway's credentials in one environment. Rebuilt whenever they change. */
async function adapterFor(provider: string, environment: GatewayEnvironment): Promise<PaymentProvider> {
  const gateway = descriptor(provider);
  if (!gateway.implemented || !gateway.build) throw new GatewayUnavailableError(`${gateway.label} cannot take payments on this platform yet.`);
  const cred = await readCredential(provider, environment);
  if (!usable(cred)) throw new GatewayUnavailableError(`${gateway.label} has no usable ${environment} credentials on this platform.`);
  const slot = `${provider}:${environment}`;
  const key = `${cred.id}:${cred.updatedAt.getTime()}:${cred.keyId}`;
  const cached = built.get(slot);
  if (cached?.key === key) return cached.provider;
  let credentials: Record<string, string>;
  try {
    credentials = openCredentials(cred.cipher, cred.keyId);
  } catch (err) {
    observe('payment.failed', { provider, environment, operation: 'open gateway credentials', reason: err instanceof VaultError ? err.message : 'unreadable' });
    throw new GatewayUnavailableError(`${gateway.label}'s stored ${environment} credentials cannot be read. A Super Admin must enter them again.`);
  }
  const adapter = gateway.build(credentials, environment);
  built.set(slot, { key, provider: adapter });
  return adapter;
}

/** Whether a gateway's test mode may take new payments here: anywhere but a production process. */
export const testPaymentsAllowedHere = (env: NodeJS.ProcessEnv = process.env) => env.NODE_ENV !== 'production';

/** The active gateway, in its environment, for a new payment — or null when online payment is off. */
export async function activeProvider(): Promise<PaymentProvider | null> {
  const override = providerOverride();
  if (override) return override.active ? (override.providers.get(override.active) ?? null) : null;
  const row = await platform(() => db.paymentGatewayConfig.findFirst({ where: { isActive: true } }));
  // The sandbox stands in only while no real gateway is active, and never in production (SAAS-030).
  if (!row) return sandboxEnabled() ? sandboxProvider : null;
  const environment = asEnvironment(row.environment);
  // A production process takes no new payment in test mode: a test card would buy a real plan. Records already made in
  // test mode are still settled through `providerFor`.
  if (environment === 'test' && !testPaymentsAllowedHere()) {
    observe('payment.failed', { provider: row.provider, environment, operation: 'start a payment', reason: 'test mode is refused in production' });
    return null;
  }
  try {
    return await adapterFor(row.provider, environment);
  } catch (err) {
    // An active gateway whose credentials no longer open (the key was rotated) offers no online payment.
    if (err instanceof GatewayUnavailableError) return null;
    throw err;
  }
}

/** The active gateway, or a refusal that says online payment is not available. */
export async function requireActiveProvider(): Promise<PaymentProvider> {
  const provider = await activeProvider();
  if (!provider) throw new PaymentUnavailableError();
  return provider;
}

/**
 * The gateway recorded on an existing invoice, order, payment or refund, with the credentials of the
 * environment recorded on it — whether or not the gateway is still enabled or active. A record made before
 * environments were recorded (`null`) uses the gateway's current environment; the gateway refuses an id from
 * the other environment, so nothing is recorded wrongly. Refuses, changing nothing, when it cannot be used.
 */
export async function providerFor(name: string, environment?: string | null): Promise<PaymentProvider> {
  const override = providerOverride();
  if (override) {
    const provider = override.providers.get(name);
    if (!provider) throw new GatewayUnavailableError('The gateway this payment was made through is not configured on this platform, so it cannot be used.');
    return provider;
  }
  if (name === SANDBOX) {
    if (sandboxEnabled()) return sandboxProvider;
    throw new GatewayUnavailableError('The sandbox gateway is switched off on this platform.');
  }
  if (!GATEWAY_IDS.includes(name)) throw new GatewayUnavailableError('The gateway this payment was made through is not known to this platform.');
  const env = environment ? asEnvironment(environment) : asEnvironment((await readConfig(name))?.environment);
  return adapterFor(name, env);
}

/** Like `providerFor`, but null instead of a refusal. */
export async function findProvider(name: string, environment?: string | null): Promise<PaymentProvider | null> {
  try {
    return await providerFor(name, environment);
  } catch (err) {
    if (err instanceof GatewayUnavailableError) return null;
    throw err;
  }
}

/**
 * The adapters that may verify a webhook addressed to `name`: one per environment with usable credentials.
 * A gateway's test and live webhooks come to the same URL, each signed with its own environment's secret.
 */
export async function webhookVerifiers(name: string): Promise<PaymentProvider[]> {
  const override = providerOverride();
  if (override) {
    const provider = override.providers.get(name);
    return provider ? [provider] : [];
  }
  if (name === SANDBOX) return sandboxEnabled() ? [sandboxProvider] : [];
  if (!GATEWAY_IDS.includes(name)) return [];
  const out: PaymentProvider[] = [];
  for (const environment of GATEWAY_ENVIRONMENTS) {
    const adapter = await findProvider(name, environment);
    if (adapter) out.push(adapter);
  }
  return out;
}

/** Every gateway with stored credentials — the webhook retry job walks these. */
export async function gatewaysWithCredentials(): Promise<string[]> {
  const override = providerOverride();
  if (override) return [...override.providers.keys()];
  const rows = await platform(() => db.paymentGatewayCredential.findMany({ select: { provider: true }, distinct: ['provider'] }));
  return [...rows.map((r) => r.provider), ...(sandboxEnabled() ? [SANDBOX] : [])];
}

/* ─── What the panel sees ─────────────────────────────────────────────── */

export interface GatewayCredentialView {
  configured: boolean;
  /** Stored, but sealed under another key: must be entered again. */
  needsReentry: boolean;
  /** Masked, never a secret: e.g. the key ID's last four. */
  hint: Record<string, string>;
  /** Which secret fields have a stored value. */
  secretsSet: string[];
  configuredAt: string | null;
}

export interface GatewayView {
  provider: string;
  label: string;
  implemented: boolean;
  unavailableReason?: string;
  fieldsProvisional: boolean;
  enabled: boolean;
  /** Whose credentials new payments use. */
  environment: GatewayEnvironment;
  isActive: boolean;
  /** Usable credentials for `environment`. */
  configured: boolean;
  needsReentry: boolean;
  credentials: Record<GatewayEnvironment, GatewayCredentialView>;
  /** For `environment`, as in `credentials`. */
  hint: Record<string, string>;
  secretsSet: string[];
  configuredAt: string | null;
  /** Whether it can be set active now, and if not, why. */
  canActivate: boolean;
  activationBlockedReason?: string;
  /** Whether "Test configuration" can check its credentials with the gateway. */
  testSupported: boolean;
  fields: GatewayField[];
  updatedAt: string | null;
}

function credentialView(cred: CredentialRow | undefined): GatewayCredentialView {
  const hint = readJson<{ hint?: Record<string, string>; secretsSet?: string[] }>(cred?.hint ?? '{}', {});
  return {
    configured: usable(cred),
    needsReentry: Boolean(cred) && !usable(cred),
    hint: hint.hint ?? {},
    secretsSet: hint.secretsSet ?? [],
    configuredAt: cred?.configuredAt.toISOString() ?? null,
  };
}

function activationBlocker(gateway: GatewayDescriptor, row: ConfigRow | undefined, current: GatewayCredentialView): string | undefined {
  if (!gateway.implemented) return gateway.unavailableReason ?? `${gateway.label} cannot take payments yet.`;
  const env = asEnvironment(row?.environment);
  if (current.needsReentry) return `Its ${env} credentials were saved under another encryption key. Enter them again.`;
  if (!current.configured) return `It has no ${env} credentials. Configure them first.`;
  if (!row?.enabled) return 'It is disabled. Enable it first.';
  return undefined;
}

function viewOf(gateway: GatewayDescriptor, row: ConfigRow | undefined, creds: CredentialRow[]): GatewayView {
  const environment = asEnvironment(row?.environment);
  const credentials = Object.fromEntries(
    GATEWAY_ENVIRONMENTS.map((env) => [env, credentialView(creds.find((c) => c.provider === gateway.id && c.environment === env))]),
  ) as Record<GatewayEnvironment, GatewayCredentialView>;
  const current = credentials[environment];
  const blocker = row?.isActive ? undefined : activationBlocker(gateway, row, current);
  const updated = [row?.updatedAt, ...creds.filter((c) => c.provider === gateway.id).map((c) => c.updatedAt)].filter((d): d is Date => Boolean(d));
  return {
    provider: gateway.id,
    label: gateway.label,
    implemented: gateway.implemented,
    ...(gateway.unavailableReason ? { unavailableReason: gateway.unavailableReason } : {}),
    fieldsProvisional: Boolean(gateway.fieldsProvisional),
    enabled: row?.enabled ?? false,
    environment,
    isActive: row?.isActive ?? false,
    configured: current.configured,
    needsReentry: current.needsReentry,
    credentials,
    hint: current.hint,
    secretsSet: current.secretsSet,
    configuredAt: current.configuredAt,
    canActivate: !row?.isActive && !blocker,
    ...(blocker ? { activationBlockedReason: blocker } : {}),
    testSupported: gateway.implemented,
    fields: gateway.fields,
    updatedAt: updated.length ? new Date(Math.max(...updated.map((d) => d.getTime()))).toISOString() : null,
  };
}

/** Every gateway the platform knows, with what is safe to show about each. */
export async function listGateways(): Promise<{ rows: GatewayView[]; vaultConfigured: boolean; active: string | null }> {
  const [rows, creds] = await platform(() => Promise.all([db.paymentGatewayConfig.findMany(), db.paymentGatewayCredential.findMany()]));
  return {
    rows: GATEWAYS.map((g) =>
      viewOf(
        g,
        rows.find((r) => r.provider === g.id),
        creds,
      ),
    ),
    vaultConfigured: vaultConfigured(),
    active: rows.find((r) => r.isActive)?.provider ?? null,
  };
}

export async function getGateway(provider: string): Promise<GatewayView> {
  const gateway = descriptor(provider);
  const [row, creds] = await platform(() =>
    Promise.all([db.paymentGatewayConfig.findUnique({ where: { provider } }), db.paymentGatewayCredential.findMany({ where: { provider } })]),
  );
  return viewOf(gateway, row ?? undefined, creds);
}

/* ─── What the Super Admin changes ────────────────────────────────────── */

const actorId = (who: AuditAttribution) => ('auth' in who && who.auth ? who.auth.sub : null);
const gatewayAudit = (who: AuditAttribution, action: string, provider: string, meta: Record<string, unknown>, client?: Parameters<typeof recordAuditLog>[2]) =>
  recordAuditLog(who, { action, targetType: 'payment_gateway', targetId: provider, meta: { provider, ...meta } }, client);

/**
 * Saves a gateway's credentials for one environment, encrypted, replacing what that environment had in one
 * write (rotation). The other environment's credentials are untouched. A secret left blank keeps the stored
 * one, so a secret is replaced without the old one ever being shown; every field must end up with a value. A
 * refused save is audited with its reason — never a value.
 */
export async function configureGateway(
  provider: string,
  input: { environment: GatewayEnvironment; credentials: Record<string, string | undefined> },
  who: AuditAttribution,
): Promise<GatewayView> {
  const gateway = descriptor(provider);
  try {
    if (!vaultConfigured()) throw new SecureStorageNotConfiguredError();
    const known = new Set(gateway.fields.map((f) => f.key));
    const unknown = Object.keys(input.credentials).filter((k) => !known.has(k));
    if (unknown.length) throw invalid(`${gateway.label} has no field ${unknown.join(', ')}.`);
    await platform(() =>
      db.$transaction(async (tx) => {
        const where = { provider_environment: { provider, environment: input.environment } };
        const existing = await tx.paymentGatewayCredential.findUnique({ where });
        const stored = usable(existing) ? openCredentials(existing.cipher, existing.keyId) : {};
        const merged: Record<string, string> = {};
        const changed: string[] = [];
        for (const field of gateway.fields) {
          const given = input.credentials[field.key]?.trim();
          if (given) {
            if (given.length > 500) throw invalid(`${field.label} is too long.`);
            if (given !== stored[field.key]) changed.push(field.key);
            merged[field.key] = given;
          } else if (stored[field.key]) {
            merged[field.key] = stored[field.key]!;
          } else {
            throw invalid(
              existing && !usable(existing) ? `${field.label} is required: the stored credentials must be entered again.` : `${field.label} is required.`,
            );
          }
        }
        const problem = gateway.validate?.(merged, input.environment);
        if (problem) throw invalid(problem);
        const sealed = sealCredentials(merged);
        const hint = writeJson({ hint: gateway.hint?.(merged) ?? {}, secretsSet: gateway.fields.filter((f) => f.secret).map((f) => f.key) });
        const data = { cipher: sealed.cipher, keyId: sealed.keyId, hint, configuredAt: new Date(), updatedById: actorId(who) };
        if (existing) await tx.paymentGatewayCredential.update({ where, data });
        else await tx.paymentGatewayCredential.create({ data: { provider, environment: input.environment, ...data } });
        // The gateway's row: created in the environment first configured; otherwise its environment is kept.
        await tx.paymentGatewayConfig.upsert({
          where: { provider },
          create: { provider, environment: input.environment, updatedById: actorId(who) },
          update: { version: { increment: 1 }, updatedById: actorId(who) },
        });
        await gatewayAudit(
          who,
          existing ? GATEWAY_AUDIT_ACTIONS.credentialsReplaced : GATEWAY_AUDIT_ACTIONS.configured,
          provider,
          // Which fields changed, never their values; the hint is masked.
          { environment: input.environment, fieldsChanged: changed, hint: gateway.hint?.(merged) ?? {} },
          tx,
        );
      }),
    );
  } catch (err) {
    if (err instanceof ApiError && (err.status === 400 || err.status === 503)) {
      await platform(() => gatewayAudit(who, GATEWAY_AUDIT_ACTIONS.configurationFailed, provider, { environment: input.environment, reason: err.message }));
    }
    throw err;
  }
  return getGateway(provider);
}

/**
 * Enables or disables a gateway, and switches which environment's credentials its new payments use. The active
 * gateway cannot be disabled, and can move only to an environment that has credentials; orders already made
 * keep the environment they were made in.
 */
export async function updateGateway(
  provider: string,
  input: { enabled?: boolean; environment?: GatewayEnvironment },
  who: AuditAttribution,
): Promise<GatewayView> {
  const gateway = descriptor(provider);
  await platform(() =>
    db.$transaction(async (tx) => {
      const row = await tx.paymentGatewayConfig.findUnique({ where: { provider } });
      const current = asEnvironment(row?.environment);
      const data: { enabled?: boolean; environment?: GatewayEnvironment } = {};
      if (input.enabled !== undefined && input.enabled !== (row?.enabled ?? false)) {
        if (!input.enabled && row?.isActive) {
          throw conflict(`${gateway.label} is the active gateway. Activate another gateway, or turn off online payment, before disabling it.`);
        }
        data.enabled = input.enabled;
      }
      if (input.environment && input.environment !== current) {
        const cred = await tx.paymentGatewayCredential.findUnique({ where: { provider_environment: { provider, environment: input.environment } } });
        if (!usable(cred)) throw conflict(`${gateway.label} has no usable ${input.environment} credentials. Configure them first.`);
        data.environment = input.environment;
      }
      if (!Object.keys(data).length) return;
      await tx.paymentGatewayConfig.upsert({
        where: { provider },
        create: { provider, ...data, updatedById: actorId(who) },
        update: { ...data, updatedById: actorId(who), version: { increment: 1 } },
      });
      if (data.enabled !== undefined) await gatewayAudit(who, data.enabled ? GATEWAY_AUDIT_ACTIONS.enabled : GATEWAY_AUDIT_ACTIONS.disabled, provider, {}, tx);
      if (data.environment) {
        await gatewayAudit(
          who,
          GATEWAY_AUDIT_ACTIONS.environmentChanged,
          provider,
          { from: current, to: data.environment, active: row?.isActive ?? false },
          tx,
        );
      }
    }),
  );
  return getGateway(provider);
}

/** Makes a gateway the one new payments go through. It must be implemented, enabled and configured. */
export async function activateGateway(provider: string, who: AuditAttribution): Promise<GatewayView> {
  const gateway = descriptor(provider);
  await platform(() =>
    db.$transaction(async (tx) => {
      const row = await tx.paymentGatewayConfig.findUnique({ where: { provider } });
      if (row?.isActive) return;
      const env = asEnvironment(row?.environment);
      const cred = await tx.paymentGatewayCredential.findUnique({ where: { provider_environment: { provider, environment: env } } });
      const blocker = activationBlocker(gateway, row ?? undefined, credentialView(cred ?? undefined));
      if (blocker) throw conflict(`${gateway.label} cannot be set active: ${blocker}`);
      const previous = await tx.paymentGatewayConfig.findFirst({ where: { isActive: true } });
      if (previous) {
        await tx.paymentGatewayConfig.update({ where: { id: previous.id }, data: { isActive: false, version: { increment: 1 } } });
        await gatewayAudit(who, GATEWAY_AUDIT_ACTIONS.deactivated, previous.provider, { replacedBy: provider }, tx);
      }
      await tx.paymentGatewayConfig.update({ where: { provider }, data: { isActive: true, updatedById: actorId(who), version: { increment: 1 } } });
      await gatewayAudit(who, GATEWAY_AUDIT_ACTIONS.activated, provider, { environment: env, previous: previous?.provider ?? null }, tx);
    }),
  );
  return getGateway(provider);
}

/** Turns online payment off on purpose: no gateway is active, and invoices are paid by hand. */
export async function deactivateActiveGateway(who: AuditAttribution): Promise<{ deactivated: string | null }> {
  return platform(() =>
    db.$transaction(async (tx) => {
      const previous = await tx.paymentGatewayConfig.findFirst({ where: { isActive: true } });
      if (!previous) return { deactivated: null };
      await tx.paymentGatewayConfig.update({ where: { id: previous.id }, data: { isActive: false, updatedById: actorId(who), version: { increment: 1 } } });
      await gatewayAudit(who, GATEWAY_AUDIT_ACTIONS.deactivated, previous.provider, { replacedBy: null }, tx);
      return { deactivated: previous.provider };
    }),
  );
}

export interface GatewayTestResult {
  /** Whether the gateway accepted the credentials. Never true unless it was asked and said yes. */
  ok: boolean;
  /** Whether the gateway was actually asked. False when no safe check exists or nothing is configured. */
  checked: boolean;
  environment: GatewayEnvironment;
  detail: string;
}

/**
 * Checks a gateway's stored credentials for an environment with the gateway, server to server, without charging
 * anything. A gateway that offers no such check says so; it is never reported as a success it was not.
 */
export async function testGateway(provider: string, who: AuditAttribution, requested?: GatewayEnvironment): Promise<GatewayTestResult> {
  const gateway = descriptor(provider);
  const environment = requested ?? asEnvironment((await readConfig(provider))?.environment);
  const cred = await readCredential(provider, environment);
  let result: GatewayTestResult;
  if (!vaultConfigured()) {
    result = { ok: false, checked: false, environment, detail: 'Secure credential storage is not configured on the server, so no credentials can be read.' };
  } else if (!usable(cred)) {
    result = {
      ok: false,
      checked: false,
      environment,
      detail: cred ? `The ${environment} credentials were saved under another encryption key. Enter them again.` : `No ${environment} credentials are saved.`,
    };
  } else if (!gateway.implemented) {
    result = {
      ok: false,
      checked: false,
      environment,
      detail: `Nothing was checked: ${gateway.label} has no adapter yet, so credential validation is performed when it creates payments, once its merchant API contract is available.`,
    };
  } else {
    const adapter = await adapterFor(provider, environment);
    const check = adapter.testCredentials ? await adapter.testCredentials() : undefined;
    result = check
      ? { ok: check.ok, checked: true, environment, detail: check.detail }
      : { ok: false, checked: false, environment, detail: 'Credential validation is performed when creating a payment.' };
  }
  await platform(() =>
    gatewayAudit(who, GATEWAY_AUDIT_ACTIONS.testAttempted, provider, { environment, ok: result.ok, checked: result.checked, detail: result.detail }),
  );
  return result;
}

/**
 * Checks the deployment at start-up: a `PAYMENT_CREDENTIALS_KEY` that is set must be a usable key, so a
 * malformed one fails here rather than at an academy's checkout. Gateway credentials left in the environment
 * are ignored — they belong in the panel — and the log says so, naming the variable, never its value.
 */
export function assertPaymentConfig(env: NodeJS.ProcessEnv = process.env) {
  if (env.PAYMENT_CREDENTIALS_KEY?.trim() && !vaultConfigured(env)) {
    throw new Error('PAYMENT_CREDENTIALS_KEY must be 32 bytes: 64 hex characters, or base64.');
  }
  const leftover = ['PAYMENT_PROVIDER', 'RAZORPAY_KEY_ID', 'RAZORPAY_KEY_SECRET', 'RAZORPAY_WEBHOOK_SECRET'].filter((k) => env[k]?.trim());
  if (leftover.length) {
    observe('payment.failed', {
      operation: 'start-up',
      reason: `${leftover.join(', ')} ${leftover.length === 1 ? 'is' : 'are'} ignored: gateways are configured in the Super Admin panel. Import them with scripts/import-gateway-env.ts, then remove them.`,
    });
  }
}
