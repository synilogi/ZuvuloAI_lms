import type { Category, CategoryInput } from '@syniastrolms/domain';
import { slugify } from '@syniastrolms/domain';
import type { CategoryAdminService, CategoryDetail, CategoryRow } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNowIso } from './clock';
import { categories, courses } from './fixtures/catalog';
import { respond, scenario } from './simulation';

function row(category: Category): CategoryRow {
  const list = courses.filter((c) => c.categoryId === category.id);
  return {
    category,
    courseCount: list.length,
    publishedCount: list.filter((c) => c.status === 'published').length,
    learnerCount: list.reduce((n, c) => n + c.enrolledCount, 0),
  };
}

function find(id: string) {
  const category = categories.find((c) => c.id === id);
  if (!category) throw new ServiceError('This category no longer exists.', 'not-found');
  return category;
}

function assertUniqueName(name: string, exceptId?: string) {
  if (categories.some((c) => c.id !== exceptId && c.name.trim().toLowerCase() === name.trim().toLowerCase())) {
    throw new ServiceError(`There is already a category called “${name.trim()}”.`, 'conflict');
  }
}

/** Moves a category to a 1-based position and renumbers the rest so orders stay contiguous. */
function placeAt(id: string, position: number) {
  const ordered = [...categories].sort((a, b) => a.order - b.order).filter((c) => c.id !== id);
  const target = categories.find((c) => c.id === id)!;
  ordered.splice(Math.max(0, Math.min(ordered.length, position - 1)), 0, target);
  ordered.forEach((c, i) => {
    const index = categories.findIndex((x) => x.id === c.id);
    categories[index] = { ...categories[index], order: i + 1 };
  });
}

export const categoryAdminService: CategoryAdminService = {
  list: ({ search = '', status = 'all', sort = 'order' }) =>
    respond(() => {
      if (scenario() === 'empty') return { rows: [], counts: { all: 0, active: 0, hidden: 0 } };
      const q = search.trim().toLowerCase();
      const matching = categories.filter((c) => !q || `${c.name} ${c.description}`.toLowerCase().includes(q)).map(row);
      const counts = {
        all: matching.length,
        active: matching.filter((r) => r.category.status === 'active').length,
        hidden: matching.filter((r) => r.category.status === 'hidden').length,
      };
      const rows = matching
        .filter((r) => status === 'all' || r.category.status === status)
        .sort((a, b) =>
          sort === 'name'
            ? a.category.name.localeCompare(b.category.name)
            : sort === 'courses'
              ? b.courseCount - a.courseCount
              : sort === 'updated'
                ? b.category.updatedAt.localeCompare(a.category.updatedAt)
                : a.category.order - b.category.order,
        );
      return { rows, counts };
    }, 420),

  get: (id) =>
    respond((): CategoryDetail => {
      const category = find(id);
      return {
        ...row(category),
        courses: courses
          .filter((c) => c.categoryId === id)
          .map(({ id: courseId, title, status, enrolledCount, levelId, coverMotif, coverImageUrl }) => ({
            id: courseId,
            title,
            status,
            enrolledCount,
            levelId,
            coverMotif,
            coverImageUrl,
          })),
      };
    }, 360),

  create: (input: CategoryInput) =>
    respond(() => {
      assertUniqueName(input.name);
      const base = slugify(input.name) || 'category';
      const id = categories.some((c) => c.id === base) ? `${base}-${categories.length + 1}` : base;
      const category: Category = { ...input, id, name: input.name.trim(), description: input.description.trim(), updatedAt: mockNowIso() };
      categories.push(category);
      placeAt(id, input.order);
      invalidateAnalytics();
      return categories.find((c) => c.id === id)!;
    }, 800),

  update: (id, input) =>
    respond(() => {
      const current = find(id);
      if (input.name !== undefined) assertUniqueName(input.name, id);
      const index = categories.findIndex((c) => c.id === id);
      categories[index] = { ...current, ...input, name: (input.name ?? current.name).trim(), updatedAt: mockNowIso() };
      if (input.order !== undefined && input.order !== current.order) placeAt(id, input.order);
      invalidateAnalytics();
      return categories.find((c) => c.id === id)!;
    }, 750),

  remove: (id, options) =>
    respond(() => {
      find(id);
      const using = courses.filter((c) => c.categoryId === id);
      if (using.length && !options?.moveCoursesTo) {
        throw new ServiceError(
          `${using.length} ${using.length === 1 ? 'course uses' : 'courses use'} this category. Choose where to move them first.`,
          'conflict',
        );
      }
      if (options?.moveCoursesTo) {
        const destination = find(options.moveCoursesTo);
        if (destination.id === id) throw new ServiceError('Choose a different category to move the courses to.', 'conflict');
        for (const course of using) {
          const index = courses.findIndex((c) => c.id === course.id);
          courses[index] = { ...course, categoryId: destination.id };
        }
      }
      categories.splice(
        categories.findIndex((c) => c.id === id),
        1,
      );
      [...categories]
        .sort((a, b) => a.order - b.order)
        .forEach((c, i) => {
          const index = categories.findIndex((x) => x.id === c.id);
          categories[index] = { ...categories[index], order: i + 1 };
        });
      invalidateAnalytics();
      return { moved: using.length };
    }, 900),
};
