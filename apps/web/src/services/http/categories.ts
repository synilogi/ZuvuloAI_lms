import type { Category, CategoryStatus } from '@syniastrolms/domain';

import type { CategoryAdminService, CategoryDetail, CategoryRow } from '../contracts';
import { del, get, patch, post } from './client';

export const httpCategories: CategoryAdminService = {
  list: (query) => get<{ rows: CategoryRow[]; counts: Record<CategoryStatus | 'all', number> }>('/categories', query),
  get: (id) => get<CategoryDetail>(`/categories/${id}`),
  create: (input) => post<Category>('/categories', input),
  update: (id, input) => patch<Category>(`/categories/${id}`, input),
  remove: (id, options) => del<{ moved: number }>(`/categories/${id}`, options),
};
