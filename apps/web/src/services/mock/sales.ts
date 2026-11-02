import type { SalesService } from '../contracts';
import { ServiceError } from '../contracts';
import { respond } from './simulation';

/** The demo build has no platform behind it (see `./platform.ts`), so its sales are honestly empty and nothing can be saved. */
const noPlatform = () => new ServiceError('The demo build has no platform to manage. Sign in to a real installation.', 'conflict');

export const salesService: SalesService = {
  orders: ({ page = 1, pageSize = 20 } = {}) =>
    respond({ rows: [], total: 0, page, pageSize, revenue: 0, counts: { all: 0, created: 0, paid: 0, failed: 0, expired: 0, refunded: 0 } }),
  order: () => Promise.reject(new ServiceError('Order not found.', 'not-found')),
  refund: () => Promise.reject(noPlatform()),
  ordersCsv: () => respond('Order,Date,Learner\r\n'),
  coupons: () => respond([]),
  createCoupon: () => Promise.reject(noPlatform()),
  updateCoupon: () => Promise.reject(noPlatform()),
  events: ({ page = 1, pageSize = 25 } = {}) => respond({ rows: [], total: 0, page, pageSize }),
};
