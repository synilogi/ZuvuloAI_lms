import { ServiceError, type SandboxGatewayService } from '../contracts';
import { mockOrder, payMockOrder } from './coursePurchases';
import { respond } from './simulation';

/*
 * The demo build has no payment gateway. Its test checkout serves only the demo's own course orders
 * (`coursePurchases.ts`); a plan payment still finds nothing here.
 */
const none = () => new ServiceError('The demo build has no payment gateway.', 'not-found');

export const sandboxService: SandboxGatewayService = {
  order: (orderId) =>
    respond(() => {
      const order = mockOrder(orderId);
      if (!order) throw none();
      return order;
    }, 300),
  pay: (orderId, outcome) => (mockOrder(orderId) ? respond(() => payMockOrder(orderId, outcome), 600) : Promise.reject(none())),
};
