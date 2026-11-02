import type { Lesson, LessonType } from '@syniastrolms/domain';

import type { LessonAdminService, LessonDetail, LessonRow } from '../contracts';
import { del, get, patch, post } from './client';

export const httpLessons: LessonAdminService = {
  list: (courseId, query) =>
    get<{ rows: LessonRow[]; counts: { all: number; published: number; draft: number; byType: Partial<Record<LessonType, number>> } }>(
      `/courses/${courseId}/lessons`,
      query,
    ),
  get: (courseId, lessonId) => get<LessonDetail>(`/courses/${courseId}/lessons/${lessonId}`),
  create: (courseId, chapterId, input, position) => post<Lesson>(`/courses/${courseId}/lessons`, { chapterId, input, position }),
  update: (courseId, lessonId, input) => patch<Lesson>(`/courses/${courseId}/lessons/${lessonId}`, input),
  move: (courseId, lessonId, chapterId, position) => post<LessonDetail>(`/courses/${courseId}/lessons/${lessonId}/move`, { chapterId, position }),
  duplicate: (courseId, lessonId) => post<Lesson>(`/courses/${courseId}/lessons/${lessonId}/duplicate`),
  remove: (courseId, lessonId) => del<void>(`/courses/${courseId}/lessons/${lessonId}`),
};
