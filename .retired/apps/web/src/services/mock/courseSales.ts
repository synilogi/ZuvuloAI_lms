import type { CourseSalesService, CourseSalesSettings, GatewayEnvironment } from '../contracts';
import { ServiceError } from '../contracts';
import { mockNowIso } from './clock';
import { respond } from './simulation';

/*
 * The demo academy's course-sales gateway. Nothing is sent anywhere: keys are "stored" only as a masked key id hint,
 * and the secrets typed in are dropped at once — the demo, like the API, never gives a secret back.
 */

const FIELDS: CourseSalesSettings['fields'] = [
  { key: 'keyId', label: 'Key ID', secret: false, help: 'Razorpay Dashboard → Account & Settings → API Keys.' },
  { key: 'keySecret', label: 'Key secret', secret: true, help: 'Shown once, when the key is generated.' },
  { key: 'webhookSecret', label: 'Webhook secret', secret: true, help: 'The secret you set on the webhook in Razorpay.' },
];

const state: { enabled: boolean; environment: GatewayEnvironment; credentials: CourseSalesSettings['credentials'] } = {
  enabled: false,
  environment: 'test',
  credentials: { test: { configured: false }, live: { configured: false } },
};

const view = (): CourseSalesSettings => {
  const reason = !state.enabled
    ? 'Online course payments are switched off.'
    : !state.credentials[state.environment].configured
      ? `No ${state.environment} Razorpay keys are saved.`
      : undefined;
  return {
    provider: 'razorpay',
    environment: state.environment,
    enabled: state.enabled,
    ready: !reason,
    ...(reason ? { notReadyReason: reason } : {}),
    credentials: structuredClone(state.credentials),
    webhookPath: '/webhooks/academies/demo-academy/razorpay/courses',
    fields: FIELDS,
    storageConfigured: true,
  };
};

const invalid = (field: string, message: string) => new ServiceError(message, 'conflict', 'VALIDATION_FAILED', [{ field, message }], 400);

export const courseSalesService: CourseSalesService = {
  settings: () => respond(view, 380),
  update: (input) =>
    respond(() => {
      if (input.enabled && !state.credentials[input.environment].configured)
        throw new ServiceError(`Save your ${input.environment} Razorpay keys before turning payments on.`, 'conflict', 'CONFLICT', undefined, 409);
      state.enabled = input.enabled;
      state.environment = input.environment;
      return view();
    }, 500),
  saveCredentials: (environment, input) =>
    respond(() => {
      const slot = state.credentials[environment];
      const keyId = input.keyId?.trim();
      if (!keyId && !slot.configured) throw invalid('keyId', 'Enter the key id.');
      if (!slot.configured && !input.keySecret?.trim()) throw invalid('keySecret', 'Enter the key secret.');
      if (!slot.configured && !input.webhookSecret?.trim()) throw invalid('webhookSecret', 'Enter the webhook secret.');
      const prefix = environment === 'live' ? 'rzp_live_' : 'rzp_test_';
      if (keyId && !keyId.startsWith(prefix)) throw invalid('keyId', `A ${environment} key id begins with ${prefix}.`);
      if (input.keySecret?.trim() && input.keySecret.trim() === input.webhookSecret?.trim())
        throw invalid('webhookSecret', 'The webhook secret must be different from the key secret.');
      state.credentials[environment] = {
        configured: true,
        keyIdHint: keyId ? `${keyId.slice(0, 9)}…${keyId.slice(-4)}` : slot.keyIdHint,
        updatedAt: mockNowIso(),
      };
      return view();
    }, 600),
  test: (environment) =>
    respond(() => {
      if (!state.credentials[environment].configured)
        throw new ServiceError(`No ${environment} keys are saved.`, 'conflict', 'PAYMENTS_NOT_SET_UP', undefined, 409);
      return { ok: true, detail: 'The demo build checks nothing with Razorpay. No money moved.' };
    }, 700),
  purchases: () => respond([], 400),
};
