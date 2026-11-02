import type { Quiz, QuizStatus } from '@syniastrolms/domain';

import type { QuizAdminService, QuizAttemptRow, QuizRow, QuizStats } from '../contracts';
import { del, get, patch, post } from './client';

export const httpQuizzes: QuizAdminService = {
  list: (query) => get<{ rows: QuizRow[]; counts: Record<QuizStatus | 'all', number> }>('/quizzes', query),
  get: (id) => get<Quiz>(`/quizzes/${id}`),
  stats: (id) => get<QuizStats>(`/quizzes/${id}/stats`),
  attempts: async (id) => (await get<{ rows: QuizAttemptRow[] }>(`/quizzes/${id}/attempts`)).rows,
  create: (input) => post<Quiz>('/quizzes', input),
  update: (id, input) => patch<Quiz>(`/quizzes/${id}`, input),
  duplicate: (id) => post<Quiz>(`/quizzes/${id}/duplicate`),
  remove: (id) => del<void>(`/quizzes/${id}`),
};
