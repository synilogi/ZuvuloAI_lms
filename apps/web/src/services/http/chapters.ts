import type { Chapter } from '@syniastrolms/domain';

import type { ChapterAdminService, CurriculumStats } from '../contracts';
import { del, get, patch, post } from './client';

export const httpChapters: ChapterAdminService = {
  stats: (courseId) => get<CurriculumStats>(`/courses/${courseId}/chapters/stats`),
  create: (courseId, input, position) => post<Chapter>(`/courses/${courseId}/chapters`, { input, position }),
  update: (courseId, chapterId, input) => patch<Chapter>(`/courses/${courseId}/chapters/${chapterId}`, input),
  duplicate: (courseId, chapterId) => post<Chapter>(`/courses/${courseId}/chapters/${chapterId}/duplicate`),
  remove: (courseId, chapterId) => del<{ lessonsRemoved: number }>(`/courses/${courseId}/chapters/${chapterId}`),
  move: (courseId, chapterId, position) => post<Chapter[]>(`/courses/${courseId}/chapters/${chapterId}/move`, { position }),
};
