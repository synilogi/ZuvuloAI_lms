import type { Course, CourseInput, CourseStatus } from '@syniastrolms/domain';
import { COURSE_PRICE_MAX, COURSE_PRICE_MIN, courseDurationMin, publishChecklist, slugify } from '@syniastrolms/domain';
import type { CourseAdminService, CourseStats } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics, reviewQueue } from './analytics';
import { mockNowIso } from './clock';
import { categories, courses, levels } from './fixtures/catalog';
import { DEMO_NOW } from './fixtures/learner';
import { mockMediaUrl } from './media';
import { enrollments, students } from './fixtures/people';
import { academyLiveClasses } from './fixtures/schedule';
import { addDays, dayKey } from './random';
import { respond, scenario } from './simulation';

const NOW = new Date(DEMO_NOW);

function find(id: string, scopeInstructorId?: string) {
  const course = courses.find((c) => c.id === id);
  if (!course || (scopeInstructorId && !course.instructorIds.includes(scopeInstructorId))) {
    throw new ServiceError('This course doesn’t exist or isn’t shared with you.', 'not-found');
  }
  return course;
}

/** The cover image a form's `coverImageId` asks for: an id sets it, `null` clears it, absent keeps `current`'s. */
function coverFields(coverImageId: string | null | undefined, current?: Course): Pick<Course, 'coverImageId' | 'coverImageUrl'> {
  if (coverImageId === undefined) return { coverImageId: current?.coverImageId, coverImageUrl: current?.coverImageUrl };
  if (coverImageId === null) return { coverImageId: undefined, coverImageUrl: undefined };
  return { coverImageId, coverImageUrl: mockMediaUrl(coverImageId) };
}

/** Replaces a course in place so every importer of the catalog sees the change. */
/**
 * The pricing a save leaves a course with, by the API's rules: left out on an edit, it is unchanged; a new course with
 * none is free; a paid course needs a whole-rupee price in range; a free course has none.
 */
function pricingFields(input: Pick<CourseInput, 'pricing' | 'priceAmount'>, current?: Course): Pick<Course, 'pricing' | 'price'> {
  if (input.pricing === undefined && input.priceAmount === undefined)
    return current ? { pricing: current.pricing, price: current.price } : { pricing: 'free', price: undefined };
  const pricing = input.pricing ?? (input.priceAmount != null ? 'paid' : 'free');
  if (pricing === 'free') {
    if (input.priceAmount != null)
      throw new ServiceError(
        'A free course has no price.',
        'conflict',
        'VALIDATION_FAILED',
        [{ field: 'priceAmount', message: 'A free course has no price.' }],
        400,
      );
    return { pricing: 'free', price: undefined };
  }
  const amount = input.priceAmount !== undefined ? input.priceAmount : current?.price?.amount;
  if (amount == null || !Number.isInteger(amount) || amount < COURSE_PRICE_MIN || amount > COURSE_PRICE_MAX) {
    const message =
      amount == null ? 'Enter the price of this paid course.' : `The price is a whole number of rupees from ${COURSE_PRICE_MIN} to ${COURSE_PRICE_MAX}.`;
    throw new ServiceError(message, 'conflict', 'VALIDATION_FAILED', [{ field: 'priceAmount', message }], 400);
  }
  return { pricing: 'paid', price: { amount, currency: 'INR' } };
}

function save(next: Course) {
  const index = courses.findIndex((c) => c.id === next.id);
  if (index >= 0) courses[index] = next;
  else courses.unshift(next);
  invalidateAnalytics();
  return next;
}

function assertUniqueTitle(title: string, exceptId?: string) {
  const slug = slugify(title);
  if (courses.some((c) => c.id !== exceptId && (c.slug === slug || c.title.trim().toLowerCase() === title.trim().toLowerCase()))) {
    throw new ServiceError(`A course called “${title.trim()}” already exists. Choose a different title.`, 'conflict');
  }
}

const transition = (id: string, to: CourseStatus, guard?: (c: Course) => void) =>
  respond(() => {
    const course = find(id);
    guard?.(course);
    const now = mockNowIso();
    return save({ ...course, status: to, updatedAt: now, publishedAt: to === 'published' ? (course.publishedAt ?? now) : course.publishedAt });
  }, 900);

function stats(id: string): CourseStats {
  const course = find(id);
  const list = enrollments.filter((e) => e.courseId === id);
  const settled = list.filter((e) => e.status !== 'paused');
  const inFlight = list.filter((e) => e.status === 'active' || e.status === 'completed');
  const names = new Map(students.map((s) => [s.id, s.name]));
  const weekly = Array.from({ length: 12 }, (_, i) => {
    const end = addDays(NOW, -7 * (11 - i));
    const start = addDays(end, -7);
    return {
      date: dayKey(addDays(start, 1)),
      value: list.filter((e) => new Date(e.enrolledAt) > start && new Date(e.enrolledAt) <= end).length,
    };
  });
  const buckets = [0, 25, 50, 75, 100].map((from, i, all) => ({
    label: i === 4 ? 'Completed' : `${from}–${all[i + 1] - 1}%`,
    value: list.filter((e) => (i === 4 ? e.progress === 100 : e.progress >= from && e.progress < all[i + 1])).length,
  }));
  return {
    courseId: id,
    enrolled: list.length,
    active: list.filter((e) => e.status === 'active' && e.lastActiveAt && NOW.getTime() - new Date(e.lastActiveAt).getTime() < 14 * 86_400_000).length,
    completionRate: settled.length ? Math.round((settled.filter((e) => e.status === 'completed').length / settled.length) * 100) : 0,
    avgProgress: inFlight.length ? Math.round(inFlight.reduce((n, e) => n + e.progress, 0) / inFlight.length) : 0,
    weekly,
    progressBuckets: buckets,
    recent: [...list]
      .sort((a, b) => b.enrolledAt.localeCompare(a.enrolledAt))
      .slice(0, 5)
      .map((e) => ({ studentId: e.studentId, name: names.get(e.studentId) ?? 'Learner', enrolledAt: e.enrolledAt, progress: e.progress, status: e.status })),
    upcomingLive: academyLiveClasses.filter((c) => c.courseId === id && new Date(c.startsAt) > NOW && !c.cancelled).length,
    certificatesIssued: course.certificateTitle ? list.filter((e) => e.status === 'completed').length : 0,
    reviewsWaiting: reviewQueue()[id]?.waiting ?? 0,
    totalMinutes: courseDurationMin(course),
  };
}

export const courseAdminService: CourseAdminService = {
  list: ({ search = '', categoryId, instructorId, scopeInstructorId, status = 'all', sort = 'updated', page, pageSize }) =>
    respond(() => {
      if (scenario() === 'empty') return { rows: [], total: 0, counts: { all: 0, draft: 0, published: 0, archived: 0 } };
      const q = search.trim().toLowerCase();
      const scoped = courses.filter((c) => !scopeInstructorId || c.instructorIds.includes(scopeInstructorId));
      const filtered = scoped.filter(
        (c) =>
          (!categoryId || c.categoryId === categoryId) &&
          (!instructorId || c.instructorIds.includes(instructorId)) &&
          (!q || `${c.title} ${c.subtitle} ${c.tags.join(' ')}`.toLowerCase().includes(q)),
      );
      const counts = {
        all: filtered.length,
        draft: filtered.filter((c) => c.status === 'draft').length,
        published: filtered.filter((c) => c.status === 'published').length,
        archived: filtered.filter((c) => c.status === 'archived').length,
      };
      const rows = filtered
        .filter((c) => status === 'all' || c.status === status)
        .sort((a, b) =>
          sort === 'title'
            ? a.title.localeCompare(b.title)
            : sort === 'learners'
              ? b.enrolledCount - a.enrolledCount
              : sort === 'created'
                ? b.createdAt.localeCompare(a.createdAt)
                : b.updatedAt.localeCompare(a.updatedAt),
        );
      const start = (page - 1) * pageSize;
      return { rows: rows.slice(start, start + pageSize), total: rows.length, counts };
    }, 420),

  get: (id, scopeInstructorId) => respond(() => find(id, scopeInstructorId), 380),

  stats: (id) => respond(() => stats(id), 520),

  create: ({ coverImageId, pricing, priceAmount, salePrice, ...input }: CourseInput) =>
    respond(() => {
      assertUniqueTitle(input.title);
      const now = mockNowIso();
      const slug = slugify(input.title);
      return save({
        ...input,
        salePrice: salePrice ?? undefined,
        // Left blank, a course lands on the first level and first active category, as the API places it.
        levelId: input.levelId || levels[0].id,
        categoryId: input.categoryId || (categories.find((c) => c.status === 'active') ?? categories[0]).id,
        ...coverFields(coverImageId),
        ...pricingFields({ pricing, priceAmount }),
        id: `${slug}-${Date.now().toString(36).slice(-4)}`,
        slug,
        chapters: [],
        enrolledCount: 0,
        status: 'draft',
        createdAt: now,
        updatedAt: now,
      });
    }, 1000),

  update: (id, { coverImageId, pricing, priceAmount, salePrice, ...input }) =>
    respond(() => {
      const course = find(id);
      if (input.title !== undefined) assertUniqueTitle(input.title, id);
      return save({
        ...course,
        ...input,
        ...coverFields(coverImageId, course),
        ...pricingFields({ pricing, priceAmount }, course),
        ...(salePrice !== undefined ? { salePrice: salePrice ?? undefined } : {}),
        slug: input.title ? slugify(input.title) : course.slug,
        updatedAt: mockNowIso(),
      });
    }, 900),

  publish: (id) =>
    transition(id, 'published', (course) => {
      const unmet = publishChecklist(course).filter((c) => !c.met);
      if (unmet.length) throw new ServiceError(`Not ready to publish: ${unmet.map((c) => c.label.toLowerCase()).join(', ')}.`, 'conflict');
    }),
  unpublish: (id) => transition(id, 'draft'),
  archive: (id) => transition(id, 'archived'),
  restore: (id) => transition(id, 'draft'),

  reorderChapters: (id, chapterIds) =>
    respond(() => {
      const course = find(id);
      const byId = new Map(course.chapters.map((c) => [c.id, c]));
      if (chapterIds.length !== course.chapters.length || chapterIds.some((cid) => !byId.has(cid))) {
        throw new ServiceError('The chapter list changed while you were reordering. Reload and try again.', 'conflict');
      }
      return save({ ...course, chapters: chapterIds.map((cid) => byId.get(cid)!), updatedAt: mockNowIso() });
    }, 700),
};
