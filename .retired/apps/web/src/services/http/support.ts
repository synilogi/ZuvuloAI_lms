import type { Inquiry } from '@syniastrolms/domain';

import type { SupportService } from '../contracts';
import { get, post } from './client';

/** An academy admin's support requests, against `/tenant/support` (SAAS-029). */
export const httpSupport: SupportService = {
  list: () => get<{ rows: Inquiry[] }>('/tenant/support').then((r) => r.rows),
  create: (input) => post<Inquiry>('/tenant/support', input),
};
