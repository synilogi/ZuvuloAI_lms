import { Router } from 'express';
import { lessonPublishIssues, type LessonInput, type LessonType, type ContentStatus } from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { asyncHandler, conflict, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requireStaffPermission } from '../lib/permissions.js';
import { assertCourseAccess } from '../lib/scope.js';
import { getSettings } from '../lib/settings.js';
import { linkedByLesson, mergeLinkedContent } from '../lib/lessonLinks.js';
import { id as idSchema, parseBody, z, patchOf, parseQuery, searchText, optionalId } from '../lib/validate.js';

const LESSON_TYPES = ['video', 'reading', 'document', 'live', 'practice', 'assignment', 'assessment'] as const;
const lessonSchema = z.object({
  title: z.string().trim().min(1).max(160),
  type: z.enum(LESSON_TYPES),
  durationMin: z.number().int().min(0).max(10_000).optional(),
  isPreview: z.boolean().optional(),
  status: z.enum(['draft', 'published']).default('draft'),
  description: z.string().trim().max(2000).optional(),
  objectives: z.array(z.string().trim().max(300)).max(20).optional(),
  content: z.record(z.string(), z.unknown()).optional(),
  settings: z.record(z.string(), z.unknown()).optional(),
});

function stripLinks(content: Record<string, unknown>) {
  const next = { ...content } as { quiz?: Record<string, unknown>; assignment?: Record<string, unknown> };
  if (next.quiz) next.quiz = { ...next.quiz, quizId: undefined };
  if (next.assignment) next.assignment = { ...next.assignment, assignmentId: undefined };
  return next;
}

/** Lessons in a course with their quiz/assignment mirrors refreshed from the linked records. */
async function mapLinked(courseId: string, rows: Parameters<typeof mapLesson>[0][]) {
  const links = await linkedByLesson(courseId);
  return rows.map((row) => {
    const lesson = mapLesson(row);
    return { ...lesson, content: mergeLinkedContent(lesson.content ?? {}, links.quiz.get(row.id), links.assignment.get(row.id)) };
  });
}
import { mapChapter, mapLesson } from '../lib/mapCourse.js';
import { writeJson } from '../lib/json.js';

export const lessonsRouter = Router({ mergeParams: true });

// Every route here belongs to /courses/:courseId — staff only, and the course must be in the caller's scope.
lessonsRouter.use(
  requireAuth,
  requireRole('instructor', 'admin'),
  asyncHandler(async (req, _res, next) => {
    await assertCourseAccess(req, req.params.courseId);
    next();
  }),
);

async function courseChapters(courseId: string) {
  return db.chapter.findMany({ where: { courseId }, orderBy: { position: 'asc' }, include: { lessons: { orderBy: { position: 'asc' } } } });
}

function flatten(chapters: Awaited<ReturnType<typeof courseChapters>>) {
  return chapters.flatMap((chapter, chapterIndex) => chapter.lessons.map((lesson, lessonIndex) => ({ chapter, chapterIndex, lesson, lessonIndex })));
}

lessonsRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.view'),
  asyncHandler(async (req, res) => {
    const { courseId } = req.params;
    const { search, chapterId, type, status, sort } = parseQuery(
      req,
      z.object({ search: searchText, chapterId: optionalId, type: optionalId, status: optionalId, sort: optionalId }),
    );
    const chapters = await courseChapters(courseId);
    let flat = flatten(chapters);

    const counts = { all: flat.length, published: 0, draft: 0, byType: {} as Partial<Record<LessonType, number>> };
    for (const { lesson } of flat) {
      if (lesson.status === 'published') counts.published++;
      else counts.draft++;
      counts.byType[lesson.type as LessonType] = (counts.byType[lesson.type as LessonType] ?? 0) + 1;
    }

    if (search) flat = flat.filter((f) => f.lesson.title.toLowerCase().includes(search.toLowerCase()));
    if (chapterId) flat = flat.filter((f) => f.chapter.id === chapterId);
    if (type && type !== 'all') flat = flat.filter((f) => f.lesson.type === type);
    if (status && status !== 'all') flat = flat.filter((f) => f.lesson.status === status);
    if (sort === 'updated') flat.sort((a, b) => b.lesson.updatedAt.getTime() - a.lesson.updatedAt.getTime());
    else if (sort === 'duration') flat.sort((a, b) => b.lesson.durationMin - a.lesson.durationMin);
    else if (sort === 'title') flat.sort((a, b) => a.lesson.title.localeCompare(b.lesson.title));

    const linked = await mapLinked(
      courseId,
      flat.map((f) => f.lesson),
    );
    const rows = flat.map((f, i) => ({
      lesson: linked[i],
      chapterId: f.chapter.id,
      chapterTitle: f.chapter.title,
      chapterIndex: f.chapterIndex,
      lessonIndex: f.lessonIndex,
    }));
    res.json({ rows, counts });
  }),
);

lessonsRouter.get(
  '/:lessonId',
  requireAuth,
  requireStaffPermission('catalog.view'),
  asyncHandler(async (req, res) => {
    const { courseId, lessonId } = req.params;
    const chapters = await courseChapters(courseId);
    const flat = flatten(chapters);
    const idx = flat.findIndex((f) => f.lesson.id === lessonId);
    if (idx === -1) throw notFound('Lesson not found.');
    const { chapter, chapterIndex, lessonIndex, lesson } = flat[idx];
    res.json({
      lesson: (await mapLinked(courseId, [lesson]))[0],
      chapterId: chapter.id,
      chapterTitle: chapter.title,
      chapterIndex,
      lessonIndex,
      chapter: mapChapter(chapter),
      previous: idx > 0 ? { id: flat[idx - 1].lesson.id, title: flat[idx - 1].lesson.title } : undefined,
      next: idx < flat.length - 1 ? { id: flat[idx + 1].lesson.id, title: flat[idx + 1].lesson.title } : undefined,
    });
  }),
);

lessonsRouter.post(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const { courseId } = req.params;
    const parsed = parseBody(req, z.object({ chapterId: idSchema, input: lessonSchema, position: z.number().int().min(1).max(1000).optional() }));
    const { chapterId, position } = parsed;
    const input = parsed.input as LessonInput;
    const chapter = await db.chapter.findFirst({ where: { id: chapterId, courseId }, select: { id: true } });
    if (!chapter) throw notFound('Chapter not found.');
    // Academy lesson defaults fill what the form left blank.
    const { general } = await getSettings();
    const defaults = general.lessonDefaults;
    if (input.durationMin === undefined) input.durationMin = defaults.durationMin;
    if (input.isPreview === undefined && defaults.previewFirstLesson) input.isPreview = (await db.lesson.count({ where: { courseId } })) === 0;
    if (input.settings === undefined) {
      // view → opening counts · time → most of a video must play · check → the quiz must be passed
      const completion =
        input.type === 'assessment'
          ? 'passed'
          : input.type === 'assignment' || input.type === 'practice'
            ? 'submitted'
            : defaults.completion === 'time' && input.type === 'video'
              ? 'watched'
              : 'opened';
      input.settings = { completion, sequential: false, discussion: defaults.allowComments, resourcesDownloadable: defaults.allowDownloads };
    }
    if (input.status === 'published') {
      const issues = lessonPublishIssues(input);
      if (issues.length) throw conflict('This lesson is not ready to publish.', issues);
    }
    const existing = await db.lesson.findMany({ where: { chapterId }, orderBy: { position: 'asc' } });
    const insertAt = position && position >= 1 && position <= existing.length + 1 ? position - 1 : existing.length;
    await db.$transaction(existing.slice(insertAt).map((l, i) => db.lesson.update({ where: { id: l.id }, data: { position: insertAt + i + 1 } })));

    const row = await db.lesson.create({
      data: {
        ...tenant(),
        chapterId,
        courseId,
        title: input.title,
        type: input.type,
        durationMin: input.durationMin,
        isPreview: input.isPreview ?? false,
        status: input.status,
        description: input.description,
        objectivesJson: writeJson(input.objectives ?? []),
        contentJson: writeJson(input.content ?? {}),
        settingsJson: writeJson(input.settings ?? {}),
        position: insertAt,
      },
    });
    res.status(201).json(mapLesson(row));
  }),
);

lessonsRouter.patch(
  '/:lessonId',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const existing = await db.lesson.findFirst({ where: { id: req.params.lessonId, courseId: req.params.courseId } });
    if (!existing) throw notFound('Lesson not found.');
    const input = parseBody(req, patchOf(lessonSchema)) as Partial<LessonInput>;
    const merged = {
      title: input.title ?? existing.title,
      type: (input.type ?? existing.type) as LessonType,
      durationMin: input.durationMin ?? existing.durationMin,
      content: input.content ?? JSON.parse(existing.contentJson || '{}'),
    };
    if ((input.status ?? existing.status) === 'published') {
      const issues = lessonPublishIssues(merged);
      if (issues.length) throw conflict('This lesson is not ready to publish.', issues);
    }
    const row = await db.lesson.update({
      where: { id: existing.id },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.type !== undefined ? { type: input.type } : {}),
        ...(input.durationMin !== undefined ? { durationMin: input.durationMin } : {}),
        ...(input.isPreview !== undefined ? { isPreview: input.isPreview } : {}),
        ...(input.status !== undefined ? { status: input.status as ContentStatus } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.objectives !== undefined ? { objectivesJson: writeJson(input.objectives) } : {}),
        ...(input.content !== undefined ? { contentJson: writeJson(input.content) } : {}),
        ...(input.settings !== undefined ? { settingsJson: writeJson(input.settings) } : {}),
      },
    });
    // A lesson that no longer delivers a quiz/assignment releases the link (the record itself stays).
    if (input.type !== undefined && input.type !== existing.type) {
      if (existing.type === 'assessment') await db.quiz.updateMany({ where: { lessonId: existing.id }, data: { lessonId: null } });
      if (existing.type === 'assignment' || existing.type === 'practice')
        await db.courseAssignment.updateMany({ where: { lessonId: existing.id }, data: { lessonId: null } });
    }
    res.json((await mapLinked(req.params.courseId, [row]))[0]);
  }),
);

lessonsRouter.post(
  '/:lessonId/move',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const { courseId, lessonId } = req.params;
    const { chapterId, position } = parseBody(req, z.object({ chapterId: idSchema, position: z.number().int().min(1).max(1000) }));
    const lesson = await db.lesson.findFirst({ where: { id: lessonId, courseId } });
    if (!lesson) throw notFound('Lesson not found.');
    if (!(await db.chapter.findFirst({ where: { id: chapterId, courseId }, select: { id: true } }))) throw notFound('Chapter not found.');
    const oldSiblings = await db.lesson.findMany({ where: { chapterId: lesson.chapterId, id: { not: lessonId } }, orderBy: { position: 'asc' } });
    await db.$transaction(oldSiblings.map((l, i) => db.lesson.update({ where: { id: l.id }, data: { position: i } })));

    const newSiblings = await db.lesson.findMany({ where: { chapterId, id: { not: lessonId } }, orderBy: { position: 'asc' } });
    const insertAt = Math.max(0, Math.min(newSiblings.length, position - 1));
    await db.$transaction(newSiblings.slice(insertAt).map((l, i) => db.lesson.update({ where: { id: l.id }, data: { position: insertAt + i + 1 } })));
    await db.lesson.update({ where: { id: lessonId }, data: { chapterId, position: insertAt } });

    const chapters = await courseChapters(courseId);
    const flat = flatten(chapters);
    const idx = flat.findIndex((f) => f.lesson.id === lessonId);
    const { chapter, chapterIndex, lessonIndex, lesson: moved } = flat[idx];
    res.json({ lesson: mapLesson(moved), chapterId: chapter.id, chapterTitle: chapter.title, chapterIndex, lessonIndex, chapter: mapChapter(chapter) });
  }),
);

lessonsRouter.post(
  '/:lessonId/duplicate',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const original = await db.lesson.findFirst({ where: { id: req.params.lessonId, courseId: req.params.courseId } });
    if (!original) throw notFound('Lesson not found.');
    const siblings = await db.lesson.findMany({ where: { chapterId: original.chapterId, position: { gt: original.position } } });
    await db.$transaction(siblings.map((l) => db.lesson.update({ where: { id: l.id }, data: { position: l.position + 1 } })));
    const copy = await db.lesson.create({
      data: {
        ...tenant(),
        chapterId: original.chapterId,
        courseId: original.courseId,
        title: `${original.title} (copy)`,
        type: original.type,
        durationMin: original.durationMin,
        isPreview: original.isPreview,
        status: 'draft',
        description: original.description,
        objectivesJson: original.objectivesJson,
        // The copy does not deliver the original's quiz/assignment; its block keeps only the rules.
        contentJson: writeJson(stripLinks(JSON.parse(original.contentJson || '{}'))),
        settingsJson: original.settingsJson,
        position: original.position + 1,
      },
    });
    res.status(201).json(mapLesson(copy));
  }),
);

lessonsRouter.delete(
  '/:lessonId',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('catalog.edit'),
  asyncHandler(async (req, res) => {
    const lesson = await db.lesson.findFirst({ where: { id: req.params.lessonId, courseId: req.params.courseId } });
    if (!lesson) throw notFound('Lesson not found.');
    // The quiz/assignment it delivered is kept and simply unlinked.
    await db.quiz.updateMany({ where: { lessonId: lesson.id }, data: { lessonId: null } });
    await db.courseAssignment.updateMany({ where: { lessonId: lesson.id }, data: { lessonId: null } });
    await db.lesson.delete({ where: { id: lesson.id } });
    const rest = await db.lesson.findMany({ where: { chapterId: lesson.chapterId }, orderBy: { position: 'asc' } });
    await db.$transaction(rest.map((l, i) => db.lesson.update({ where: { id: l.id }, data: { position: i } })));
    res.status(204).end();
  }),
);
