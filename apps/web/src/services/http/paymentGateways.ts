import type { GatewayList, GatewayTestResult, GatewayView, PaymentGatewayService } from '../contracts';
import { get, patch, post } from './client';

/*
 * The platform's payment gateways against the API (SAAS-017). Credentials go up for one environment and are
 * sealed on the server; nothing comes back but masked hints and which secrets are set. Only the fields the
 * super admin typed are sent — one left out keeps what is stored. Every rule (one active gateway, the active
 * one cannot be disabled, only a configured environment can be chosen) is the server's, answered as a 400,
 * 409 or 503 in its own words, with its code kept on the error.
 */

const BASE = '/superadmin/payment-gateways';
const at = (provider: string) => `${BASE}/${encodeURIComponent(provider)}`;

export const httpPaymentGateways: PaymentGatewayService = {
  list: () => get<GatewayList>(BASE),
  get: (provider) => get<GatewayView>(at(provider)),
  configure: (provider, input) => post<GatewayView>(`${at(provider)}/config`, { environment: input.environment, credentials: input.credentials }),
  update: (provider, changes) =>
    patch<GatewayView>(at(provider), {
      ...(changes.enabled !== undefined ? { enabled: changes.enabled } : {}),
      ...(changes.environment ? { environment: changes.environment } : {}),
    }),
  test: (provider, environment) => post<GatewayTestResult>(`${at(provider)}/test`, environment ? { environment } : {}),
  activate: (provider) => post<GatewayView>(`${at(provider)}/activate`),
  deactivate: () => post<{ deactivated: string | null }>(`${BASE}/deactivate`),
};
