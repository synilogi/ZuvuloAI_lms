import { openCredentials, sealCredentials, vaultConfigured, VaultError } from './credentialVault.js';
import { db } from './db.js';
import { ApiError, type ErrorCode } from './errors.js';
import { readJson, writeJson } from './json.js';
import { observe } from './observe.js';
import { GATEWAYS, testPaymentsAllowedHere, SecureStorageNotConfiguredError, type GatewayEnvironment } from './paymentGateways.js';
import type { PaymentProvider } from './paymentProvider.js';
import { SANDBOX, sandboxEnabled, sandboxProvider } from './sandboxGateway.js';
import { currentTenantId } from './tenancy.js';

/*
 * An academy's own online payments, for selling its courses to its learners. The money a learner pays settles to the
 * academy's gateway account: the platform's gateway (lib/paymentGateways.ts) sells plans to academies and is never
 * used for course sales.
 *
 * The academy's admin enters its Razorpay keys here, per environment, sealed under PAYMENT_CREDENTIALS_KEY exactly like
 * the platform's. Secrets are write-only: never returned, logged or audited, and a blank secret on save keeps the
 * stored one. A new purchase goes through the academy's chosen environment while sales are on (`saleProvider`);
 * anything already made — a confirmation, a webhook, a status check — goes through the environment recorded on the
 * purchase (`providerForPurchase`), whatever is chosen now. A production process takes no new purchase in test mode,
 * because a test card would open a paid course.
 *
 * Every query here runs in the request's academy (lib/tenancy.ts): one academy never reads another's keys.
 */

export const COURSE_GATEWAY = 'razorpay';
const descriptor = GATEWAYS.find((g) => g.id === COURSE_GATEWAY)!;

const conflict = (message: string, code: ErrorCode = 'CONFLICT') => new ApiError(409, message, undefined, code);
const invalid = (message: string, field?: string) => new ApiError(400, message, field ? [{ field, message }] : undefined, 'VALIDATION_FAILED');

/** Tests stand a fake gateway in for every academy (`setCoursePaymentProvider`); production never sets it. */
let override: PaymentProvider | null | undefined;
export function setCoursePaymentProvider(provider: PaymentProvider | null | undefined) {
  override = provider;
}

export interface AcademyPaymentsView {
  provider: string;
  environment: GatewayEnvironment;
  enabled: boolean;
  /** Whether learners can buy paid courses right now. */
  ready: boolean;
  /** Why they cannot, when they cannot. */
  notReadyReason?: string;
  credentials: Record<GatewayEnvironment, { configured: boolean; keyIdHint?: string; updatedAt?: string }>;
  /** Where the academy points its Razorpay webhook: the API's own path, which the client prefixes with its address. */
  webhookPath: string;
  /** The fields the form asks for. Secrets are write-only. */
  fields: { key: string; label: string; secret: boolean; help?: string }[];
  /** False when the server cannot store credentials (no PAYMENT_CREDENTIALS_KEY). */
  storageConfigured: boolean;
}

const asEnvironment = (value: string | null | undefined): GatewayEnvironment => (value === 'live' ? 'live' : 'test');
export const academyWebhookPath = (tenantId: string) => `/webhooks/academies/${encodeURIComponent(tenantId)}/${COURSE_GATEWAY}/courses`;

const readConfig = () => db.academyPaymentConfig.findUnique({ where: { tenantId: currentTenantId() } });
const readCredential = (environment: GatewayEnvironment) =>
  db.academyGatewayCredential.findUnique({
    where: { tenantId_provider_environment: { tenantId: currentTenantId(), provider: COURSE_GATEWAY, environment } },
  });

/** Why sales cannot run in this environment now, or null when they can. */
function blocked(config: { enabled: boolean } | null, environment: GatewayEnvironment, hasCredentials: boolean): string | null {
  if (!config?.enabled) return 'Online course payments are switched off.';
  if (!hasCredentials) return `No ${environment} Razorpay keys are saved.`;
  if (environment === 'test' && !testPaymentsAllowedHere()) return 'Test mode cannot take payments on the live site. Switch to live keys.';
  if (!vaultConfigured()) return 'Secure credential storage is not configured on the server.';
  return null;
}

/** What the admin's Payments settings show: status, environment and masked hints — never a secret. */
export async function readAcademyPayments(): Promise<AcademyPaymentsView> {
  const tenantId = currentTenantId();
  const [config, test, live] = await Promise.all([readConfig(), readCredential('test'), readCredential('live')]);
  const environment = asEnvironment(config?.environment);
  const current = environment === 'live' ? live : test;
  const reason = blocked(config, environment, Boolean(current));
  const show = (row: typeof test) =>
    row ? { configured: true, keyIdHint: readJson<{ keyId?: string }>(row.hint, {}).keyId, updatedAt: row.updatedAt.toISOString() } : { configured: false };
  return {
    provider: COURSE_GATEWAY,
    environment,
    enabled: Boolean(config?.enabled),
    ready: reason === null,
    ...(reason ? { notReadyReason: reason } : {}),
    credentials: { test: show(test), live: show(live) },
    webhookPath: academyWebhookPath(tenantId),
    fields: descriptor.fields.map(({ key, label, secret, help }) => ({ key, label, secret, help })),
    storageConfigured: vaultConfigured(),
  };
}

/**
 * Saves the academy's Razorpay keys for one environment. A blank secret keeps the stored one; a new key id with no
 * stored secret needs both secrets. The values are checked for shape (a test key for test, a live key for live, two
 * different secrets) and sealed; nothing is echoed back.
 */
export async function saveAcademyCredentials(
  userId: string,
  environment: GatewayEnvironment,
  input: { keyId?: string; keySecret?: string; webhookSecret?: string },
): Promise<AcademyPaymentsView> {
  if (!vaultConfigured()) throw new SecureStorageNotConfiguredError();
  const existing = await readCredential(environment);
  let stored: Record<string, string> = {};
  if (existing) {
    try {
      stored = openCredentials(existing.cipher, existing.keyId);
    } catch (err) {
      // Sealed under a key the server no longer has: the admin enters every value again.
      if (!(err instanceof VaultError)) throw err;
    }
  }
  const next: Record<string, string> = {};
  for (const field of descriptor.fields) {
    const typed = input[field.key as keyof typeof input]?.trim();
    const value = typed || stored[field.key];
    if (!value) throw invalid(`Enter the ${field.label.toLowerCase()}.`, field.key);
    next[field.key] = value;
  }
  const problem = descriptor.validate?.(next, environment);
  if (problem) throw invalid(problem, problem.includes('webhook') ? 'webhookSecret' : 'keyId');

  const sealed = sealCredentials(next);
  const hint = writeJson(descriptor.hint?.(next) ?? {});
  const tenantId = currentTenantId();
  await db.academyGatewayCredential.upsert({
    where: { tenantId_provider_environment: { tenantId, provider: COURSE_GATEWAY, environment } },
    create: { tenantId, provider: COURSE_GATEWAY, environment, cipher: sealed.cipher, keyId: sealed.keyId, hint, updatedById: userId },
    update: { cipher: sealed.cipher, keyId: sealed.keyId, hint, updatedById: userId },
  });
  observe('course_sales.changed', { scope: 'academy', tenantId, provider: COURSE_GATEWAY, environment, change: 'credentials saved' });
  return readAcademyPayments();
}

/** Switches the academy's course sales on or off, in an environment whose keys are saved. */
export async function updateAcademyPaymentSettings(userId: string, input: { enabled: boolean; environment: GatewayEnvironment }) {
  const tenantId = currentTenantId();
  if (input.enabled) {
    if (!vaultConfigured()) throw new SecureStorageNotConfiguredError();
    if (!(await readCredential(input.environment))) throw conflict(`Save your ${input.environment} Razorpay keys before turning payments on.`);
    if (input.environment === 'test' && !testPaymentsAllowedHere())
      throw conflict('Test mode cannot take payments on the live site. Save your live keys and choose live.');
  }
  await db.academyPaymentConfig.upsert({
    where: { tenantId },
    create: { tenantId, provider: COURSE_GATEWAY, environment: input.environment, enabled: input.enabled, updatedById: userId },
    update: { environment: input.environment, enabled: input.enabled, updatedById: userId },
  });
  observe('course_sales.changed', {
    scope: 'academy',
    tenantId,
    provider: COURSE_GATEWAY,
    environment: input.environment,
    change: input.enabled ? 'course payments on' : 'course payments off',
  });
  return readAcademyPayments();
}

/** Builds the adapter for one environment's stored keys. */
async function adapterFor(environment: GatewayEnvironment): Promise<PaymentProvider> {
  if (override) return override;
  const row = await readCredential(environment);
  if (!row) throw conflict('This LMS has no payment keys for that purchase any more. Contact the LMS.', 'PAYMENTS_NOT_SET_UP');
  try {
    return descriptor.build!(openCredentials(row.cipher, row.keyId), environment);
  } catch (err) {
    observe('payment.failed', { scope: 'academy', provider: COURSE_GATEWAY, environment, operation: 'open academy credentials' });
    if (err instanceof VaultError) throw conflict('This LMS’s payment keys cannot be read. Its admin must enter them again.', 'PAYMENTS_NOT_SET_UP');
    throw err;
  }
}

/** A read that moves no money, through the saved keys of an environment. */
export async function testAcademyCredentials(environment: GatewayEnvironment) {
  if (!vaultConfigured()) throw new SecureStorageNotConfiguredError();
  const provider = await adapterFor(environment);
  return provider.testCredentials ? provider.testCredentials() : { ok: false, detail: 'This gateway cannot be tested.' };
}

/** The gateway a new purchase goes through, in its environment; refused with the reason when sales are not open. */
export async function saleProvider(): Promise<{ provider: PaymentProvider; environment: GatewayEnvironment }> {
  if (override) return { provider: override, environment: override.environment ?? 'test' };
  const config = await readConfig();
  // Development and end-to-end runs only (PAYMENT_SANDBOX=on, never production): an academy with no gateway of its own
  // sells through the sandbox, whose test checkout pays, declines or cancels without real money.
  if (!config?.enabled && sandboxEnabled()) return { provider: sandboxProvider, environment: 'test' };
  const environment = asEnvironment(config?.environment);
  const reason = blocked(config, environment, Boolean(await readCredential(environment)));
  if (reason) {
    if (config?.enabled && environment === 'test' && !testPaymentsAllowedHere())
      observe('payment.failed', {
        scope: 'academy',
        provider: COURSE_GATEWAY,
        environment,
        operation: 'start a course purchase',
        reason: 'test mode is refused in production',
      });
    throw conflict('This LMS doesn’t take online payments yet. Contact the LMS to join this course.', 'PAYMENTS_NOT_SET_UP');
  }
  return { provider: await adapterFor(environment), environment };
}

/** The gateway an existing purchase was made through, with that environment's keys — whatever is chosen now. */
export const providerForPurchase = (purchase: { environment: string; provider?: string }) =>
  purchase.provider === SANDBOX && !override ? Promise.resolve<PaymentProvider>(sandboxProvider) : adapterFor(asEnvironment(purchase.environment));

/** Whether the academy's webhook signature checks out, under the webhook secret of the given environment. */
export async function verifyAcademyWebhook(environment: GatewayEnvironment, raw: Buffer, signature: string | undefined): Promise<boolean> {
  try {
    const provider = await adapterFor(environment);
    return provider.verifyWebhook(raw, signature);
  } catch {
    return false;
  }
}
