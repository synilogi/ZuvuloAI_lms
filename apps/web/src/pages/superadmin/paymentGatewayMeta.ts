import type { FieldIssue } from '@/components/forms/Forms';
import type { GatewayCredentialView, GatewayEnvironment, GatewayTestResult, GatewayView } from '@/services';

/*
 * The pure parts of the payment gateway screen (SAAS-017): what a stored credential looks like on screen,
 * what the configuration form sends and the checks it runs before sending, and how a check's result reads.
 * None of it ever holds a stored secret — there is none to hold: the API returns masks and flags only.
 */

/** The address a gateway's dashboard is given for its webhooks (test and live share it), on the API this app talks to. */
export const webhookUrl = (apiBase: string, provider: string) => `${apiBase.replace(/\/+$/, '')}/webhooks/${encodeURIComponent(provider)}/courses`;

/** How a stored secret is shown, and the placeholder of an input whose secret is stored. */
export const MASKED = '••••••••••••';

export const environmentLabel = (environment: GatewayEnvironment) => (environment === 'live' ? 'Live' : 'Test');

export type SlotStatus = 'configured' | 'needs-reentry' | 'not-configured';

export const slotStatus = (slot: GatewayCredentialView): SlotStatus =>
  slot.needsReentry ? 'needs-reentry' : slot.configured ? 'configured' : 'not-configured';

export const SLOT_STATUS_LABEL: Record<SlotStatus, string> = {
  configured: 'Configured',
  'needs-reentry': 'Needs re-entry',
  'not-configured': 'Not configured',
};

/** Whether anything at all is stored, in either environment — "Replace credentials" rather than "Configure". */
export const hasAnyCredentials = (g: GatewayView) => Object.values(g.credentials).some((c) => c.configured || c.needsReentry);

/** Whether a field of one environment already has a value stored, which a blank input keeps. */
export function fieldIsSet(g: GatewayView, environment: GatewayEnvironment, key: string): boolean {
  const slot = g.credentials[environment];
  const field = g.fields.find((f) => f.key === key);
  if (!field || !slot.configured || slot.needsReentry) return false;
  return field.secret ? slot.secretsSet.includes(key) : true;
}

/** What a stored field shows as: a secret only as dots, anything else only as its masked hint. */
export function storedValue(g: GatewayView, environment: GatewayEnvironment, key: string): string {
  const slot = g.credentials[environment];
  const field = g.fields.find((f) => f.key === key);
  if (!field) return '—';
  if (slot.needsReentry) return 'Must be re-entered';
  if (!slot.configured) return 'Not set';
  if (field.secret) return slot.secretsSet.includes(key) ? MASKED : 'Not set';
  return slot.hint[key] ?? 'Set';
}

export type GatewayValues = Record<string, string>;

/** Every input blank. A stored secret is never prefilled — there is nothing to prefill it with. */
export const blankValues = (g: GatewayView): GatewayValues => Object.fromEntries(g.fields.map((f) => [f.key, '']));

/** Whether anything has been typed — closing then asks first. */
export const hasTyped = (values: GatewayValues) => Object.values(values).some((v) => v.trim() !== '');

/** What is sent: only the fields that were typed into. One left out keeps the stored value. */
export function credentialsPayload(g: GatewayView, values: GatewayValues): Record<string, string> {
  const out: Record<string, string> = {};
  for (const field of g.fields) {
    const value = values[field.key]?.trim();
    if (value) out[field.key] = value;
  }
  return out;
}

export const fieldInputId = (provider: string, key: string) => `gateway-${provider}-${key}`;

/** The pair of secrets the API refuses to be the same, per gateway. */
const DISTINCT: Record<string, [string, string, string]> = {
  razorpay: ['keySecret', 'webhookSecret', 'The webhook secret must be different from the key secret.'],
  vyapargateway: ['apiCredential', 'webhookSecret', 'The webhook secret must be different from the API credential.'],
};

/**
 * The checks the API applies, run early so the form can answer at once: every field where the environment has
 * nothing usable; at most 500 characters; a Razorpay key id of the environment being saved; two secrets that
 * must differ. The server checks again regardless.
 */
export function gatewayFormIssues(g: GatewayView, environment: GatewayEnvironment, values: GatewayValues): FieldIssue[] {
  const issues: FieldIssue[] = [];
  const typed = (key: string) => values[key]?.trim() ?? '';
  for (const field of g.fields) {
    const id = fieldInputId(g.provider, field.key);
    const value = typed(field.key);
    if (!value && !fieldIsSet(g, environment, field.key)) issues.push({ field: id, message: `${field.label} is required.` });
    else if (value.length > 500) issues.push({ field: id, message: `${field.label} is too long.` });
  }
  if (g.provider === 'razorpay' && typed('keyId')) {
    const prefix = environment === 'live' ? 'rzp_live_' : 'rzp_test_';
    if (!typed('keyId').startsWith(prefix)) {
      issues.push({
        field: fieldInputId(g.provider, 'keyId'),
        message: `This is not a ${environment} key: Razorpay ${environment} key IDs begin with ${prefix}.`,
      });
    }
  }
  const distinct = DISTINCT[g.provider];
  if (distinct && typed(distinct[0]) && typed(distinct[0]) === typed(distinct[1])) {
    issues.push({ field: fieldInputId(g.provider, distinct[1]), message: distinct[2] });
  }
  return issues;
}

/** Why a gateway cannot be made active right now, or `null` when it can. The reason is the server's. */
export function activationReason(g: GatewayView): string | null {
  if (g.isActive) return `${g.label} is already the active gateway.`;
  if (g.canActivate) return null;
  return g.activationBlockedReason ?? `${g.label} cannot be set active right now.`;
}

/** Why new payments cannot be moved to `environment`, or `null` when they can. Mirrors the API's rule. */
export function environmentSwitchBlocker(g: GatewayView, environment: GatewayEnvironment): string | null {
  if (environment === g.environment) return null;
  if (!g.credentials[environment].configured) return `No usable ${environment} credentials. Configure them first.`;
  return null;
}

export type TestTone = 'success' | 'info' | 'error';

/**
 * How a check's result reads. A success only when the gateway was asked and accepted the credentials; when
 * nothing was checked it is information, never a pass and never a failed credential.
 */
export function testResultTone(result: GatewayTestResult): TestTone {
  if (!result.checked) return 'info';
  return result.ok ? 'success' : 'error';
}

export const TEST_RESULT_TITLE: Record<TestTone, string> = {
  success: 'Check passed.',
  info: 'Nothing was checked.',
  error: 'Check failed.',
};

export interface GatewayAction {
  label: string;
  disabled: boolean;
  /** Why it is disabled, shown beside it. */
  reason?: string;
}

/**
 * What each action on a gateway's card offers. Configuring is never disabled — not for a gateway without an
 * adapter, and not when the server has no PAYMENT_CREDENTIALS_KEY: the form opens, and the server's refusal
 * is shown in it. `vaultConfigured` is taken only to make that independence explicit.
 */
export function gatewayActions(g: GatewayView, vaultConfigured: boolean): Record<'configure' | 'toggle' | 'test' | 'activate', GatewayAction> {
  void vaultConfigured;
  const blockDisable = g.enabled && g.isActive;
  const activate = activationReason(g);
  return {
    configure: { label: hasAnyCredentials(g) ? 'Replace credentials' : 'Configure', disabled: false },
    toggle: {
      label: g.enabled ? 'Disable' : 'Enable',
      disabled: blockDisable,
      ...(blockDisable ? { reason: 'The active gateway cannot be disabled. Set another as active, or turn off online payment, first.' } : {}),
    },
    test: { label: 'Test configuration', disabled: false },
    activate: { label: 'Set as active', disabled: Boolean(activate), ...(activate ? { reason: activate } : {}) },
  };
}
