import type { CourseSaleRow, CourseSalesService, CourseSalesSettings } from '../contracts';
import { get, post, put } from './client';

const env = (environment: string) => encodeURIComponent(environment);

/** The academy's own course-sales gateway, against `/tenant/course-sales`. Secrets go up, never come back. */
export const httpCourseSales: CourseSalesService = {
  settings: () => get<CourseSalesSettings>('/tenant/course-sales/settings'),
  update: (input) => put<CourseSalesSettings>('/tenant/course-sales/settings', { enabled: input.enabled, environment: input.environment }),
  saveCredentials: (environment, input) => {
    // Only what was typed: a blank secret keeps the stored one.
    const body: Record<string, string> = {};
    for (const key of ['keyId', 'keySecret', 'webhookSecret'] as const) {
      const value = input[key]?.trim();
      if (value) body[key] = value;
    }
    return put<CourseSalesSettings>(`/tenant/course-sales/credentials/${env(environment)}`, body);
  },
  test: (environment) => post<{ ok: boolean; detail: string }>(`/tenant/course-sales/credentials/${env(environment)}/test`),
  purchases: async () => (await get<{ rows: CourseSaleRow[] }>('/tenant/course-sales/purchases')).rows,
};
