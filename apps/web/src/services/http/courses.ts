import type { Course } from '@syniastrolms/domain';

import type { CourseAdminService, CourseListResult, CourseStats } from '../contracts';
import { get, patch, post } from './client';

export const httpCourses: CourseAdminService = {
  list: (query) => get<CourseListResult>('/courses', query),
  get: (id) => get<Course>(`/courses/${id}`),
  stats: (id) => get<CourseStats>(`/courses/${id}/stats`),
  create: (input) => post<Course>('/courses', input),
  update: (id, input) => patch<Course>(`/courses/${id}`, input),
  publish: (id) => post<Course>(`/courses/${id}/publish`),
  unpublish: (id) => post<Course>(`/courses/${id}/unpublish`),
  archive: (id) => post<Course>(`/courses/${id}/archive`),
  restore: (id) => post<Course>(`/courses/${id}/restore`),
  reorderChapters: (id, chapterIds) => post<Course>(`/courses/${id}/reorder-chapters`, { chapterIds }),
};
