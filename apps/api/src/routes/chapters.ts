import { Router } from 'express';
import type { ChapterInput } from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { asyncHandler, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requireStaffPermission } from '../lib/permissions.js';
import { assertCourseAccess } from '../lib/scope.js';
import { parseBody, z, patchOf } from '../lib/validate.js';

const chapterSchema = z.object({
  title: z.string().trim().min(2, 'Give the chapter a title.').max(160),
  summary: z.string().trim().max(1000).optional(),
  objective: z.string().trim().max(500).optional(),
  status: z.enum(['draft', 'published']).default('draft'),
  estimatedMin: z.number().int().min(0).max(10_000).optional(),
});
import { mapChapter } from '../lib/mapCourse.js';

export const chaptersRouter = Router({ mergeParams: true });

// Every route here belongs to /courses/:courseId — staff only, and the course must be in the caller's scope.
chaptersRouter.use(
  requireAuth,
  requireRole('instructor', 'admin'),
  asyncHandler(async (req, _res, next) => {
    await assertCourseAccess(req, req.params.courseId);
    next();
  }),
);

async function allChapters(courseId: string) {
  return db.chapter.findMany({ where: { courseId }, orderBy: { position: 'asc' }, include: { lessons: { orderBy: { position: 'asc' } } } });
}

chaptersRouter.get(
  '/stats',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.view'),
  asyncHandler(async (req, res) => {
    const { courseId } = req.params;
    const chapters = await allChapters(courseId);
    const enrolled = await db.enrollment.count({ where: { courseId } });
    const progressRows = await db.lessonProgress.findMany({ where: { lesson: { courseId } } });

    const lessons: Record<string, number> = {};
    const chapterStats: Record<string, { completionRate: number; startedRate: number }> = {};
    for (const chapter of chapters) {
      let doneSum = 0;
      let startedSum = 0;
      for (const lesson of chapter.lessons) {
        const rows = progressRows.filter((p) => p.lessonId === lesson.id);
        const done = rows.filter((p) => p.state === 'completed').length;
        const started = rows.filter((p) => p.state === 'completed' || p.state === 'in-progress').length;
        lessons[lesson.id] = enrolled > 0 ? Math.round((done / enrolled) * 100) : 0;
        doneSum += done;
        startedSum += started;
      }
      const denom = enrolled * Math.max(1, chapter.lessons.length);
      chapterStats[chapter.id] = {
        completionRate: denom > 0 ? Math.round((doneSum / denom) * 100) : 0,
        startedRate: denom > 0 ? Math.round((startedSum / denom) * 100) : 0,
      };
    }
    res.json({ courseId, enrolled, chapters: chapterStats, lessons });
  }),
);

chaptersRouter.post(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const { courseId } = req.params;
    const { input, position } = parseBody(req, z.object({ input: chapterSchema, position: z.number().int().min(1).max(1000).optional() })) as {
      input: ChapterInput;
      position?: number;
    };
    const existing = await allChapters(courseId);
    const insertAt = position && position >= 1 && position <= existing.length + 1 ? position - 1 : existing.length;

    await db.$transaction(existing.slice(insertAt).map((c, i) => db.chapter.update({ where: { id: c.id }, data: { position: insertAt + i + 1 } })));
    const row = await db.chapter.create({
      data: {
        ...tenant(),
        courseId,
        title: input.title,
        summary: input.summary,
        objective: input.objective,
        status: input.status,
        estimatedMin: input.estimatedMin,
        position: insertAt,
      },
      include: { lessons: true },
    });
    res.status(201).json(mapChapter(row));
  }),
);

chaptersRouter.patch(
  '/:chapterId',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, patchOf(chapterSchema)) as Partial<ChapterInput>;
    const owned = await db.chapter.findFirst({ where: { id: req.params.chapterId, courseId: req.params.courseId }, select: { id: true } });
    if (!owned) throw notFound('Chapter not found.');
    const row = await db.chapter.update({ where: { id: owned.id }, data: input, include: { lessons: { orderBy: { position: 'asc' } } } });
    res.json(mapChapter(row));
  }),
);

chaptersRouter.post(
  '/:chapterId/duplicate',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const { courseId, chapterId } = req.params;
    const original = await db.chapter.findUnique({ where: { id: chapterId }, include: { lessons: { orderBy: { position: 'asc' } } } });
    if (!original) throw notFound('Chapter not found.');

    const rest = await db.chapter.findMany({ where: { courseId, position: { gt: original.position } } });
    await db.$transaction(rest.map((c) => db.chapter.update({ where: { id: c.id }, data: { position: c.position + 1 } })));

    const copy = await db.chapter.create({
      data: {
        ...tenant(),
        courseId,
        title: `${original.title} (copy)`,
        summary: original.summary,
        objective: original.objective,
        status: 'draft',
        estimatedMin: original.estimatedMin,
        position: original.position + 1,
        lessons: {
          create: original.lessons.map((l, i) => ({
            ...tenant(),
            courseId,
            title: l.title,
            type: l.type,
            durationMin: l.durationMin,
            isPreview: l.isPreview,
            status: 'draft',
            description: l.description,
            objectivesJson: l.objectivesJson,
            contentJson: l.contentJson,
            settingsJson: l.settingsJson,
            position: i,
          })),
        },
      },
      include: { lessons: { orderBy: { position: 'asc' } } },
    });
    res.status(201).json(mapChapter(copy));
  }),
);

chaptersRouter.delete(
  '/:chapterId',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const { courseId, chapterId } = req.params;
    const chapter = await db.chapter.findUnique({ where: { id: chapterId }, include: { lessons: true } });
    if (!chapter) throw notFound('Chapter not found.');
    const lessonsRemoved = chapter.lessons.length;
    await db.chapter.delete({ where: { id: chapterId } });
    const rest = await allChapters(courseId);
    await db.$transaction(rest.map((c, i) => db.chapter.update({ where: { id: c.id }, data: { position: i } })));
    res.json({ lessonsRemoved });
  }),
);

chaptersRouter.post(
  '/:chapterId/move',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const { courseId, chapterId } = req.params;
    const { position } = parseBody(req, z.object({ position: z.number().int().min(1).max(1000) }));
    const chapters = await allChapters(courseId);
    const ordered = chapters.filter((c) => c.id !== chapterId);
    const moving = chapters.find((c) => c.id === chapterId);
    if (!moving) throw notFound('Chapter not found.');
    ordered.splice(Math.max(0, Math.min(ordered.length, position - 1)), 0, moving);
    await db.$transaction(ordered.map((c, i) => db.chapter.update({ where: { id: c.id }, data: { position: i } })));
    const updated = await allChapters(courseId);
    res.json(updated.map(mapChapter));
  }),
);
