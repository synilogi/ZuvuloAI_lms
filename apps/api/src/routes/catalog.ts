import path from 'node:path';
import { Router, type Request } from 'express';

import { db } from '../lib/db.js';
import { asyncHandler, notFound } from '../lib/errors.js';
import { contentDisposition, ensureUploadDir } from '../lib/media.js';
import { COURSE_INCLUDE, mapCategory, mapCourse, mapInstructor, mapLevel, withoutLessonContent } from '../lib/mapCourse.js';
import { getSettings } from '../lib/settings.js';
import { publicCourseReviews } from '../lib/courseReviews.js';
import { parseQuery, queryInt, z } from '../lib/validate.js';
import type { Course } from '@syniastrolms/domain';
import { STAFF_ONLY } from '../lib/instructorRequests.js';

/** The public view of a course: outline only, ratings hidden until the academy's threshold is met. */
async function publicCourse(row: Parameters<typeof mapCourse>[0]): Promise<Course> {
  const { courses } = await getSettings();
  const course = withoutLessonContent(mapCourse(row));
  const showRating = courses.showRatings && (course.ratingCount ?? 0) >= courses.minRatings;
  return showRating ? course : { ...course, rating: undefined, ratingCount: undefined };
}

export const catalogRouter = Router();

catalogRouter.get(
  '/levels',
  asyncHandler(async (_req, res) => {
    const levels = await db.level.findMany({ orderBy: { order: 'asc' } });
    res.json(levels.map(mapLevel));
  }),
);

catalogRouter.get(
  '/categories',
  asyncHandler(async (_req, res) => {
    const categories = await db.category.findMany({ orderBy: { order: 'asc' }, include: { levels: true } });
    res.json(categories.map(mapCategory));
  }),
);

catalogRouter.get(
  '/instructors',
  asyncHandler(async (_req, res) => {
    const instructors = await db.instructor.findMany({ where: STAFF_ONLY, orderBy: { name: 'asc' } });
    res.json(instructors.map(mapInstructor));
  }),
);

catalogRouter.get(
  '/courses',
  asyncHandler(async (req, res) => {
    const { levelId, categoryId } = req.query as { levelId?: string; categoryId?: string };
    const rows = await db.course.findMany({
      where: {
        status: 'published',
        visibility: 'public',
        ...(levelId ? { levelId } : {}),
        ...(categoryId ? { categoryId } : {}),
      },
      include: COURSE_INCLUDE,
      orderBy: { updatedAt: 'desc' },
    });
    // Public listing: the outline only — lesson bodies are for enrolled learners.
    res.json(await Promise.all(rows.map(publicCourse)));
  }),
);

catalogRouter.get(
  '/courses/:slug',
  asyncHandler(async (req, res) => {
    // `unlisted` is reachable by its link but kept out of the listing; `private` is reachable by neither.
    const row = await db.course.findFirst({
      where: { slug: req.params.slug, status: 'published', visibility: { in: ['public', 'unlisted'] } },
      include: COURSE_INCLUDE,
    });
    if (!row) throw notFound('Course not found.');
    res.json(await publicCourse(row));
  }),
);

/** A listed course's published reviews, a page at a time: first name, rating and comment, nothing else. */
catalogRouter.get(
  '/courses/:slug/reviews',
  asyncHandler(async (req, res) => {
    const { page, pageSize } = parseQuery(req, z.object({ page: queryInt(1, 100_000, 1), pageSize: queryInt(1, 50, 10) }));
    res.json(await publicCourseReviews(req.params.slug, page, pageSize));
  }),
);

/** Published and public or unlisted: the course page is open to anyone, and so is its cover. */
const isListed = (course: { status: string; visibility: string }) => course.status === 'published' && course.visibility !== 'private';

/**
 * Whether the requester may see the cover of a course that is not listed (a draft, a private or archived course):
 * the academy's staff and learners enrolled in it. The academy is the request's (`lib/requestContext.ts`), so
 * another academy's course is never found in the first place.
 */
async function canSeeUnlistedCover(req: Request, course: { id: string }): Promise<boolean> {
  const viewer = req.auth;
  if (!viewer || req.accountClosed) return false;
  if (viewer.role === 'admin' || viewer.role === 'superadmin' || viewer.role === 'instructor') return true;
  if (viewer.role !== 'student' || !viewer.studentId) return false;
  return (await db.enrollment.count({ where: { courseId: course.id, studentId: viewer.studentId, status: { not: 'expired' } } })) > 0;
}

/**
 * Streams a course's cover image. Readable without a session so the public catalog and the website can show it; a
 * signed-in request is read in its own academy. Only a file that is some course's cover is served here — any other
 * upload, and a cover the requester may not see, answers the same 404 as a file that does not exist.
 */
catalogRouter.get(
  '/covers/:mediaId',
  asyncHandler(async (req, res) => {
    const courses = await db.course.findMany({
      where: { coverImageId: req.params.mediaId },
      select: { id: true, status: true, visibility: true, coverImage: { select: { storageName: true, mime: true, originalName: true, kind: true } } },
    });
    const image = courses[0]?.coverImage;
    if (!image || image.kind !== 'image') throw notFound('Image not found.');
    const listed = courses.some(isListed);
    if (!listed && !(await Promise.all(courses.map((c) => canSeeUnlistedCover(req, c)))).some(Boolean)) throw notFound('Image not found.');
    await new Promise<void>((resolve, reject) =>
      res.sendFile(
        path.join(ensureUploadDir(), image.storageName),
        {
          headers: {
            'Content-Type': image.mime,
            'Content-Disposition': contentDisposition(image.originalName),
            'X-Content-Type-Options': 'nosniff',
            // A replaced cover is a new media id, so a cached copy never goes stale; one not in the catalog stays out of shared caches.
            'Cache-Control': listed ? 'public, max-age=86400' : 'private, max-age=3600',
          },
          dotfiles: 'deny',
        },
        (err) => (err ? reject(err) : resolve()),
      ),
    ).catch((err: NodeJS.ErrnoException) => {
      if (err.code === 'ENOENT') throw notFound('Image not found.');
      if (!res.headersSent) throw err;
    });
  }),
);
