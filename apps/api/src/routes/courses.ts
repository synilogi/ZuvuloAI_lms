import { Router } from 'express';
import { COURSE_PRICE_MAX, COURSE_PRICE_MIN, publishChecklist, slugify, type CourseStatus } from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { db, type DbClient } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { asyncHandler, badRequest, conflict, forbidden, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requireStaffPermission } from '../lib/permissions.js';
import { COURSE_INCLUDE, mapCourse } from '../lib/mapCourse.js';
import { assertCourseAccess, courseScopeWhere, instructorScope } from '../lib/scope.js';
import { getSettings } from '../lib/settings.js';
import { id as idSchema, optionalId, paging, parseBody, parseQuery, searchText, z, patchOf } from '../lib/validate.js';
import { adminUserIds, instructorUserIdsFor, notifyMany } from '../lib/notify.js';

const courseSchema = z.object({
  title: z.string().trim().min(3, 'Give the course a title of at least 3 characters.').max(160),
  subtitle: z.string().trim().max(200).default(''),
  description: z.string().trim().max(10_000).default(''),
  /** Left out of a new course, the academy's first level and category fill them (`placementDefaults`). */
  levelId: idSchema.optional(),
  categoryId: idSchema.optional(),
  instructorIds: z.array(idSchema).max(20).default([]),
  format: z.enum(['self-paced', 'cohort', 'hybrid']).optional(),
  language: z.string().trim().max(10).optional(),
  coverMotif: z.enum(['orbits', 'houses', 'nakshatra', 'ecliptic']).default('orbits'),
  /** A media id from `POST /media/upload`; `null` removes the cover image. */
  coverImageId: idSchema.nullable().optional(),
  outcomes: z.array(z.string().trim().max(300)).max(20).default([]),
  tags: z.array(z.string().trim().max(40)).max(20).default([]),
  visibility: z.enum(['public', 'unlisted', 'private']).optional(),
  liveSessions: z.number().int().min(0).max(500).default(0),
  certificateTitle: z.string().trim().max(160).optional(),
  estimatedWeeks: z.number().int().min(1).max(104).optional(),
  /** Free or paid; a paid course carries its all-inclusive price in whole rupees. */
  pricing: z.enum(['free', 'paid']).optional(),
  salePrice: z.number().int().min(COURSE_PRICE_MIN).max(COURSE_PRICE_MAX).nullable().optional(),
  priceAmount: z
    .number()
    .int('Enter the price in whole rupees.')
    .min(COURSE_PRICE_MIN, `A paid course costs at least ₹${COURSE_PRICE_MIN}.`)
    .max(COURSE_PRICE_MAX, `A course costs at most ₹${COURSE_PRICE_MAX.toLocaleString('en-IN')}.`)
    .nullable()
    .optional(),
});

/**
 * The pricing a save leaves the course with. A paid course must have a valid price (never free by omission); a free
 * course keeps no price. Left out of an edit, both stay as they are; left out of a new course, it is free unless a
 * price is given. Nothing is filled from the academy's default price any more: an admin chooses.
 */
function pricingFor(
  input: { pricing?: 'free' | 'paid'; priceAmount?: number | null; salePrice?: number | null },
  current?: { pricing: string; salePrice?: number | null; priceAmount: number | null },
) {
  if (input.pricing === undefined && input.priceAmount === undefined && input.salePrice === undefined)
    return current ? {} : { pricing: 'free', priceAmount: null, salePrice: null };
  const pricing = input.pricing ?? (input.priceAmount != null ? 'paid' : current?.pricing === 'paid' ? 'paid' : 'free');
  if (pricing === 'free') {
    if (input.priceAmount != null && input.pricing === 'free')
      throw badRequest('A free course has no price.', [{ field: 'priceAmount', message: 'A free course has no price.' }]);
    return { pricing: 'free', priceAmount: null, salePrice: null };
  }
  const priceAmount = input.priceAmount !== undefined ? input.priceAmount : (current?.priceAmount ?? null);
  if (priceAmount == null)
    throw badRequest('Enter the price of this paid course.', [{ field: 'priceAmount', message: 'Enter the price of this paid course.' }]);
  const salePrice = input.salePrice !== undefined ? input.salePrice : (current?.salePrice ?? null);
  if (salePrice != null && salePrice >= priceAmount)
    throw badRequest('A sale price must be below the list price.', [{ field: 'salePrice', message: 'A sale price must be below the list price.' }]);
  return { pricing: 'paid', priceAmount, salePrice };
}

/** Course titles are unique across the academy, ignoring case. */
async function assertUniqueTitle(title: string, excludeId?: string) {
  const rows = await db.course.findMany({ select: { id: true, title: true } });
  if (rows.some((r) => r.id !== excludeId && r.title.trim().toLowerCase() === title.trim().toLowerCase()))
    throw conflict(`A course called “${title.trim()}” already exists. Choose a different title.`);
}

/**
 * A cover image is a PNG, JPG or WebP that a member of staff uploaded to this academy (`POST /media/upload`
 * checks the type, size and file signature). The lookup runs inside the request's academy, so another
 * academy's file — or a learner's hand-in — is refused the same way as one that does not exist.
 */
async function assertCoverImage(mediaId: string) {
  const asset = await db.mediaAsset.findUnique({ where: { id: mediaId }, select: { kind: true, ownerUserId: true } });
  const owner = asset ? await db.user.findUnique({ where: { id: asset.ownerUserId }, select: { role: true } }) : null;
  if (!asset || !owner || (owner.role !== 'admin' && owner.role !== 'superadmin' && owner.role !== 'instructor'))
    throw badRequest('The cover image was not found. Upload it again.');
  if (asset.kind !== 'image') throw badRequest('The cover must be a PNG, JPG or WebP image.');
}

/**
 * Where a new course sits when the form leaves level or category blank: the academy's first level, and
 * its first active category (any category if every one is hidden). An academy with no category yet — a
 * newly provisioned one — gets a "General" category, so a first course needs no catalog setup beforehand.
 */
async function placementDefaults(input: { levelId?: string; categoryId?: string }) {
  const levelId = input.levelId ?? (await db.level.findFirst({ orderBy: { order: 'asc' }, select: { id: true } }))?.id;
  if (!levelId) throw conflict('The platform has no course levels set up yet, so the course can’t be placed. Contact support.');
  if (input.categoryId) return { levelId, categoryId: input.categoryId };
  const existing =
    (await db.category.findFirst({ where: { status: 'active' }, orderBy: { order: 'asc' }, select: { id: true } })) ??
    (await db.category.findFirst({ orderBy: { order: 'asc' }, select: { id: true } }));
  if (existing) return { levelId, categoryId: existing.id };
  const general = await db.category.create({
    data: { ...tenant(), name: 'General', description: 'Courses not yet placed in a category.', glyph: 'compass', status: 'active', order: 1 },
    select: { id: true },
  });
  return { levelId, categoryId: general.id };
}

async function assertInstructorLimit(instructorIds: string[]) {
  const { courses } = await getSettings();
  if (instructorIds.length > courses.maxInstructors)
    throw conflict(`A course can have at most ${courses.maxInstructors} instructor${courses.maxInstructors === 1 ? '' : 's'} (platform setting).`);
}
import { writeJson } from '../lib/json.js';

export const coursesRouter = Router();

async function uniqueSlug(title: string, excludeId?: string): Promise<string> {
  const base = slugify(title) || 'course';
  let slug = base;
  let n = 2;
  while (await db.course.findFirst({ where: { slug, ...(excludeId ? { id: { not: excludeId } } : {}) } })) {
    slug = `${base}-${n++}`;
  }
  return slug;
}

coursesRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.view'),
  asyncHandler(async (req, res) => {
    const { search, categoryId, instructorId, status, sort, page, pageSize } = parseQuery(
      req,
      z.object({ search: searchText, categoryId: optionalId, instructorId: optionalId, status: optionalId, sort: optionalId, ...paging }),
    );

    // Instructors only ever see the courses they teach; the token decides, not the query.
    const where: Prisma.CourseWhereInput = {
      AND: [courseScopeWhere(req), instructorId ? { instructors: { some: { instructorId } } } : {}],
      ...(categoryId ? { categoryId } : {}),
      ...(search ? { title: { contains: search } } : {}),
    };

    const orderBy =
      sort === 'title'
        ? { title: 'asc' as const }
        : sort === 'learners'
          ? { enrolledCount: 'desc' as const }
          : sort === 'created'
            ? { createdAt: 'desc' as const }
            : { updatedAt: 'desc' as const };

    const all = await db.course.findMany({ where, include: COURSE_INCLUDE, orderBy });
    const counts: Record<CourseStatus | 'all', number> = { all: all.length, draft: 0, published: 0, archived: 0 };
    for (const c of all) counts[c.status as CourseStatus]++;

    const filtered = status && status !== 'all' ? all.filter((c) => c.status === status) : all;
    const rows = filtered.slice((page - 1) * pageSize, page * pageSize).map(mapCourse);

    res.json({ rows, total: filtered.length, counts });
  }),
);

coursesRouter.get(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.view'),
  asyncHandler(async (req, res) => {
    await assertCourseAccess(req, req.params.id);
    const row = await db.course.findUnique({ where: { id: req.params.id }, include: COURSE_INCLUDE });
    if (!row) throw notFound('Course not found.');
    res.json(mapCourse(row));
  }),
);

coursesRouter.get(
  '/:id/stats',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.view'),
  asyncHandler(async (req, res) => {
    const courseId = req.params.id;
    await assertCourseAccess(req, courseId);
    const course = await db.course.findUnique({ where: { id: courseId }, include: COURSE_INCLUDE });
    if (!course) throw notFound('Course not found.');

    const enrollments = await db.enrollment.findMany({ where: { courseId }, include: { student: { include: { user: true } } } });
    const enrolled = enrollments.length;
    const fourteenDaysAgo = new Date(Date.now() - 14 * 86_400_000);
    const active = enrollments.filter((e) => e.status === 'active' && (e.lastActiveAt ?? e.enrolledAt) >= fourteenDaysAgo).length;
    const completed = enrollments.filter((e) => e.status === 'completed').length;
    const settled = enrollments.filter((e) => e.status !== 'paused').length;
    const completionRate = settled > 0 ? Math.round((completed / settled) * 100) : 0;
    const avgProgress = enrolled > 0 ? Math.round(enrollments.reduce((n, e) => n + e.progress, 0) / enrolled) : 0;

    const weekly: { date: string; value: number }[] = [];
    const now = Date.now();
    for (let i = 11; i >= 0; i--) {
      const to = new Date(now - i * 7 * 86_400_000);
      const from = new Date(to.getTime() - 7 * 86_400_000);
      weekly.push({ date: from.toISOString().slice(0, 10), value: enrollments.filter((e) => e.enrolledAt >= from && e.enrolledAt < to).length });
    }

    const buckets = [0, 0, 0, 0, 0]; // 0-20,20-40,40-60,60-80,80-100
    for (const e of enrollments) buckets[Math.min(4, Math.floor(e.progress / 20))]++;
    const progressBuckets = ['0-20%', '20-40%', '40-60%', '60-80%', '80-100%'].map((label, i) => ({ label, value: buckets[i] }));

    const recent = enrollments
      .slice()
      .sort((a, b) => b.enrolledAt.getTime() - a.enrolledAt.getTime())
      .slice(0, 8)
      .map((e) => ({ studentId: e.studentId, name: e.student.user.name, enrolledAt: e.enrolledAt.toISOString(), progress: e.progress, status: e.status }));

    const upcomingLive = await db.liveClass.count({ where: { courseId, startsAt: { gte: new Date() }, cancelled: false } });
    const certificatesIssued = await db.issuedCertificate.count({ where: { courseId, status: 'issued' } });
    const reviewsWaiting = await db.submission.count({ where: { assignment: { courseId }, reviewStatus: { in: ['waiting', 'in-review'] } } });
    const totalMinutes = course.chapters.reduce((n, c) => n + c.lessons.reduce((m, l) => m + l.durationMin, 0), 0);

    res.json({
      courseId,
      enrolled,
      active,
      completionRate,
      avgProgress,
      weekly,
      progressBuckets,
      recent,
      upcomingLive,
      certificatesIssued,
      reviewsWaiting,
      totalMinutes,
    });
  }),
);

coursesRouter.post(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const parsed = parseBody(req, courseSchema);
    const settings = await getSettings();
    // Academy defaults fill what the form left blank.
    const input = {
      ...parsed,
      format: parsed.format ?? settings.courses.defaultFormat,
      visibility: parsed.visibility ?? settings.general.defaultVisibility,
      language: parsed.language ?? settings.general.language,
    };
    // Pricing is the academy's decision: an instructor's new course waits, unpriced, for an admin to choose. Checked
    // first, so an invalid price changes nothing.
    const pricing = instructorScope(req) ? { pricing: 'unset', priceAmount: null, salePrice: null } : pricingFor(input);
    await assertUniqueTitle(input.title);
    // An instructor always teaches the course they create.
    const scope = instructorScope(req);
    if (scope && !(input.instructorIds ?? []).includes(scope)) input.instructorIds = [scope, ...(input.instructorIds ?? [])];
    await assertInstructorLimit(input.instructorIds ?? []);
    if (input.coverImageId) await assertCoverImage(input.coverImageId);
    const slug = await uniqueSlug(input.title);
    // After every other check, so a refused request does not leave a new default category behind. Outside the
    // transaction: the tenant reference check reads committed rows, so it cannot see a category made inside it.
    const placement = await placementDefaults(input);
    const row = await db.$transaction((tx) =>
      tx.course.create({
        data: {
          ...tenant(),
          slug,
          title: input.title,
          subtitle: input.subtitle,
          description: input.description,
          levelId: placement.levelId,
          categoryId: placement.categoryId,
          format: input.format,
          language: input.language,
          coverMotif: input.coverMotif,
          coverImageId: input.coverImageId ?? null,
          liveSessions: input.liveSessions ?? 0,
          estimatedWeeks: input.estimatedWeeks,
          certificateTitle: input.certificateTitle,
          visibility: input.visibility,
          outcomesJson: writeJson(input.outcomes ?? []),
          tagsJson: writeJson(input.tags ?? []),
          ...pricing,
          instructors: { create: (input.instructorIds ?? []).map((instructorId) => ({ ...tenant(), instructorId })) },
        },
        include: COURSE_INCLUDE,
      }),
    );
    res.status(201).json(mapCourse(row));
  }),
);

coursesRouter.patch(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, patchOf(courseSchema)) as Partial<import('@syniastrolms/domain').CourseInput>;
    await assertCourseAccess(req, req.params.id);
    const existing = await db.course.findUnique({ where: { id: req.params.id } });
    if (!existing) throw notFound('Course not found.');
    if (input.title !== undefined) await assertUniqueTitle(input.title, existing.id);
    // An instructor cannot hand a course away by removing themselves from it.
    const scope = instructorScope(req);
    if (scope && input.instructorIds && !input.instructorIds.includes(scope)) input.instructorIds = [scope, ...input.instructorIds];
    if (input.instructorIds) await assertInstructorLimit(input.instructorIds);
    if (input.coverImageId) await assertCoverImage(input.coverImageId);
    // Checked before anything changes: an invalid price leaves the course exactly as it was.
    if (scope && (input.pricing !== undefined || input.priceAmount !== undefined || input.salePrice !== undefined))
      throw forbidden('Only an admin can change whether a course is free or paid, and its price.');
    const pricing = pricingFor(input, existing);

    if (input.instructorIds) {
      await db.courseInstructor.deleteMany({ where: { courseId: existing.id } });
    }

    const row = await db.course.update({
      where: { id: existing.id },
      data: {
        ...pricing,
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.subtitle !== undefined ? { subtitle: input.subtitle } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.levelId !== undefined ? { levelId: input.levelId } : {}),
        ...(input.categoryId !== undefined ? { categoryId: input.categoryId } : {}),
        ...(input.format !== undefined ? { format: input.format } : {}),
        ...(input.language !== undefined ? { language: input.language } : {}),
        ...(input.coverMotif !== undefined ? { coverMotif: input.coverMotif } : {}),
        ...(input.coverImageId !== undefined ? { coverImageId: input.coverImageId } : {}),
        ...(input.liveSessions !== undefined ? { liveSessions: input.liveSessions } : {}),
        ...(input.estimatedWeeks !== undefined ? { estimatedWeeks: input.estimatedWeeks } : {}),
        ...(input.certificateTitle !== undefined ? { certificateTitle: input.certificateTitle } : {}),
        ...(input.visibility !== undefined ? { visibility: input.visibility } : {}),
        ...(input.outcomes !== undefined ? { outcomesJson: writeJson(input.outcomes) } : {}),
        ...(input.tags !== undefined ? { tagsJson: writeJson(input.tags) } : {}),
        ...(input.instructorIds ? { instructors: { create: input.instructorIds.map((instructorId) => ({ ...tenant(), instructorId })) } } : {}),
      },
      include: COURSE_INCLUDE,
    });
    res.json(mapCourse(row));
  }),
);

async function setStatus(id: string, status: CourseStatus, extra: Record<string, unknown> = {}, client: DbClient = db) {
  const row = await client.course.update({ where: { id }, data: { status, ...extra }, include: COURSE_INCLUDE });
  return mapCourse(row);
}

coursesRouter.post(
  '/:id/publish',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.publish'),
  asyncHandler(async (req, res) => {
    await assertCourseAccess(req, req.params.id);
    const row = await db.course.findUnique({ where: { id: req.params.id }, include: COURSE_INCLUDE });
    if (!row) throw notFound('Course not found.');
    const course = mapCourse(row);
    const checklist = publishChecklist(course);
    const unmet = checklist.filter((c) => !c.met);
    if (unmet.length) throw conflict('This course is not ready to publish.', checklist);
    // With review-before-publish on, only an admin can take a course live — the request goes to the admins.
    if (instructorScope(req) && (await getSettings()).courses.requireReview) {
      const requester = await db.user.findUnique({ where: { id: req.auth!.sub }, select: { name: true } });
      const title = `${course.title} is ready for review`;
      // Asked once a day at most: pressing Publish again tells the instructor again, not every admin again.
      const asked = await db.appNotification.findFirst({
        where: { category: 'course', title, createdAt: { gte: new Date(Date.now() - 86_400_000) } },
        select: { id: true },
      });
      if (asked) throw forbidden('The platform asks an admin to review courses before they go live. The admins were asked to review it today.');
      await notifyMany(await adminUserIds(), {
        category: 'course',
        title,
        summary: `${requester?.name ?? 'An instructor'} asked to publish it. The checklist is complete — review and publish it from the course page.`,
        actor: requester?.name,
        action: { label: 'Review the course', to: `/admin/courses/${course.id}` },
        switch: 'staff.courseReview',
      });
      throw forbidden('The platform asks an admin to review courses before they go live. The admins have been asked to review it.');
    }
    const published = await setStatus(course.id, 'published', { publishedAt: row.publishedAt ?? new Date() });
    if (!instructorScope(req)) {
      // The teaching team hears when an admin takes their course live.
      await notifyMany(await instructorUserIdsFor(course.id), {
        category: 'course',
        title: `${course.title} is now live`,
        summary: 'Learners can find it in the catalog and enrol.',
        action: { label: 'Open the course', to: `/teach/courses/${course.id}` },
        switch: 'staff.courseReview',
      });
    }
    res.json(published);
  }),
);

coursesRouter.post(
  '/:id/unpublish',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.publish'),
  asyncHandler(async (req, res) => {
    await assertCourseAccess(req, req.params.id);
    res.json(await setStatus(req.params.id, 'draft'));
  }),
);

coursesRouter.post(
  '/:id/archive',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.archive'),
  asyncHandler(async (req, res) => {
    await assertCourseAccess(req, req.params.id);
    res.json(await setStatus(req.params.id, 'archived'));
  }),
);

coursesRouter.post(
  '/:id/restore',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.archive'),
  asyncHandler(async (req, res) => {
    await assertCourseAccess(req, req.params.id);
    // An archived course does not count; restoring it counts again, so it needs room on the plan and is
    // refused in restricted mode (§21).
    res.json(await db.$transaction((tx) => setStatus(req.params.id, 'draft', {}, tx)));
  }),
);

coursesRouter.post(
  '/:id/reorder-chapters',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const { chapterIds } = parseBody(req, z.object({ chapterIds: z.array(idSchema).max(500) }));
    await assertCourseAccess(req, req.params.id);
    // Only this course's chapters can be reordered through its route.
    const own = new Set((await db.chapter.findMany({ where: { courseId: req.params.id }, select: { id: true } })).map((c) => c.id));
    const ordered = chapterIds.filter((id) => own.has(id));
    await db.$transaction(ordered.map((chapterId, i) => db.chapter.update({ where: { id: chapterId }, data: { position: i } })));
    const row = await db.course.findUnique({ where: { id: req.params.id }, include: COURSE_INCLUDE });
    if (!row) throw notFound('Course not found.');
    res.json(mapCourse(row));
  }),
);
