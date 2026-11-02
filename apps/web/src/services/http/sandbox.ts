import type { SandboxGatewayService } from '../contracts';
import { get, post } from './client';

/** The sandbox gateway's test checkout page, against `/sandbox` (SAAS-030). Not found unless the API runs it. */
export const httpSandbox: SandboxGatewayService = {
  order: (orderId) => get(`/sandbox/orders/${encodeURIComponent(orderId)}`),
  pay: (orderId, outcome) => post(`/sandbox/orders/${encodeURIComponent(orderId)}/pay`, { outcome }),
};
