import type { Category, Course, Instructor, Level, PublicCourseReviewPage } from '@syniastrolms/domain';

import type { CatalogService } from '../contracts';
import { get } from './client';

export const httpCatalog: CatalogService = {
  listLevels: () => get<Level[]>('/catalog/levels'),
  listCategories: () => get<Category[]>('/catalog/categories'),
  listCourses: (filter) => get<Course[]>('/catalog/courses', filter),
  getCourse: (slug) => get<Course>(`/catalog/courses/${slug}`),
  listInstructors: () => get<Instructor[]>('/catalog/instructors'),
  listCourseReviews: (slug, query) => get<PublicCourseReviewPage>(`/catalog/courses/${encodeURIComponent(slug)}/reviews`, query),
};
