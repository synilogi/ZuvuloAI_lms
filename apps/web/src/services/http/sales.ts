import type { Coupon, OrderRefund, PaymentEventRow, SalesOrderDetail, SalesOrderList } from '@syniastrolms/domain';

import type { SalesService } from '../contracts';
import { csv } from './affiliatesPlatform';
import { get, patch, post } from './client';

const BASE = '/superadmin/sales';

/** The platform's course orders, coupons and payment events (docs/16 §2.4). Every figure is the server's. */
export const httpSales: SalesService = {
  orders: (query = {}) => get<SalesOrderList>(`${BASE}/orders`, query),
  order: (id) => get<SalesOrderDetail>(`${BASE}/orders/${encodeURIComponent(id)}`),
  refund: (id, input) => post<SalesOrderDetail>(`${BASE}/orders/${encodeURIComponent(id)}/refund`, input),
  ordersCsv: (query = {}) => csv(`${BASE}/orders/export.csv`, { ...query }, 'Could not export the orders.'),
  coupons: async () => (await get<{ rows: Coupon[] }>(`${BASE}/coupons`)).rows,
  createCoupon: (input) => post<Coupon>(`${BASE}/coupons`, input),
  updateCoupon: (id, changes) => patch<Coupon>(`${BASE}/coupons/${encodeURIComponent(id)}`, changes),
  events: (query = {}) => get<{ rows: PaymentEventRow[]; total: number; page: number; pageSize: number }>(`${BASE}/events`, query),
};

export type { OrderRefund };
