import type { AdminService, LearnerRow, LearnerStatus, StudentListResult } from '../contracts';
import { get } from './client';

const toLearnerStatus = (status: string): LearnerStatus => (status === 'inactive' || status === 'suspended' ? 'paused' : (status as LearnerStatus));

export const httpAdmin: AdminService = {
  listLearners: async (query) => {
    const { rows, total } = await get<StudentListResult>('/students', { search: query.search, page: query.page, pageSize: query.pageSize });
    const mapped: LearnerRow[] = rows.map((r) => ({
      id: r.student.id,
      name: r.student.name,
      email: r.student.email,
      course: r.courses[0]?.title ?? '',
      progress: r.progress,
      rank: '',
      lastActiveAt: r.student.lastActiveAt,
      status: toLearnerStatus(r.status),
    }));
    return { rows: mapped, total };
  },
};
