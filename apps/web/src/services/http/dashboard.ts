import type { DashboardSnapshot } from '@syniastrolms/domain';

import type { DashboardService } from '../contracts';
import { get } from './client';

export const httpDashboard: DashboardService = {
  getSnapshot: (scope) =>
    get<DashboardSnapshot>('/dashboard', scope.kind === 'instructor' ? { scope: 'instructor', instructorId: scope.instructorId } : { scope: 'academy' }),
};
