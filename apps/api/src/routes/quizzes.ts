import { Router } from 'express';
import {
  resultsVisibilityOf,
  validateQuiz,
  quizTotalPoints,
  type Quiz,
  type QuizInput,
  type QuizStatus,
  type QuizQuestion,
  type QuizSettings,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { asyncHandler, conflict } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requireStaffPermission } from '../lib/permissions.js';
import { assertCourseAccess, assertQuizAccess, courseScopeWhere } from '../lib/scope.js';
import { readJson, writeJson } from '../lib/json.js';
import { settleOverdueQuizSessions } from './learning.js';
import { id as idSchema, parseBody, z, patchOf, parseQuery, searchText, optionalId } from '../lib/validate.js';

const questionSchema = z
  .object({
    id: z.string().min(1).max(64),
    type: z.enum(['single', 'multiple', 'true-false', 'short']),
    prompt: z.string().max(2000),
    points: z.number().int().min(0).max(100),
    options: z
      .array(z.object({ id: z.string().min(1).max(64), text: z.string().max(500) }).passthrough())
      .max(20)
      .default([]),
    correct: z.array(z.string().max(64)).max(20).default([]),
    acceptedAnswers: z.array(z.string().max(200)).max(50).optional(),
    explanation: z.string().max(2000).optional(),
    /** Marks taken away for a wrong answer; never more than the question is worth (checked on publishing). */
    negativePoints: z.number().min(0).max(100).optional(),
  })
  .passthrough();

/** A moment, never a wall-clock time: an ISO date-time with its offset (`Z` or `+05:30`), so no server's zone decides it. */
const moment = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,3})?)?(Z|[+-]\d{2}:\d{2})$/, 'Enter the time with its time zone.')
  .refine((v) => !Number.isNaN(Date.parse(v)), 'Enter a valid time.')
  // Stored in one form, so every reader compares the same string.
  .transform((v) => new Date(v).toISOString());
const settingsSchema = z
  .object({
    passMark: z.number().int().min(1).max(100).optional(),
    attempts: z.number().int().min(0).max(99).optional(),
    timeLimitMin: z.number().int().min(1).max(600).optional().nullable(),
    shuffleQuestions: z.boolean().optional(),
    shuffleOptions: z.boolean().optional(),
    // `hidden` is the domain's value; `nothing` is still read, and stored as `hidden`.
    showResults: z.enum(['score-only', 'score-and-answers', 'hidden', 'nothing']).transform(resultsVisibilityOf).optional(),
    resultsRelease: z.enum(['on-submit', 'after-close']).optional(),
    // Cleared with null: a window that is not set is not stored.
    opensAt: moment.optional().nullable(),
    closesAt: moment.optional().nullable(),
  })
  .passthrough()
  .transform(({ opensAt, closesAt, ...rest }) => ({ ...rest, ...(opensAt ? { opensAt } : {}), ...(closesAt ? { closesAt } : {}) }));
const quizSchema = z.object({
  courseId: idSchema,
  chapterId: idSchema.optional().nullable(),
  lessonId: idSchema.optional().nullable(),
  title: z.string().trim().min(1).max(160),
  instructions: z.string().max(5000).default(''),
  status: z.enum(['draft', 'published', 'archived']).default('draft'),
  questions: z.array(questionSchema).max(200).default([]),
  settings: settingsSchema.default({}),
});

/** A quiz may be delivered by one published-or-draft assessment lesson of its own course. */
async function assertLessonLink(courseId: string, lessonId: string | null | undefined, excludeQuizId?: string) {
  if (!lessonId) return;
  const lesson = await db.lesson.findFirst({ where: { id: lessonId, courseId } });
  if (!lesson) throw conflict('Choose a lesson from the same course.');
  if (lesson.type !== 'assessment') throw conflict('Only an assessment lesson can deliver a quiz.');
  const taken = await db.quiz.findFirst({ where: { lessonId, ...(excludeQuizId ? { id: { not: excludeQuizId } } : {}) } });
  if (taken) throw conflict('That lesson already delivers another quiz.');
}

export const quizzesRouter = Router();

function mapQuiz(row: {
  id: string;
  courseId: string;
  chapterId: string | null;
  lessonId: string | null;
  title: string;
  instructions: string;
  status: string;
  questionsJson: string;
  settingsJson: string;
  createdAt: Date;
  updatedAt: Date;
}): Quiz {
  return {
    id: row.id,
    courseId: row.courseId,
    chapterId: row.chapterId ?? undefined,
    lessonId: row.lessonId ?? undefined,
    title: row.title,
    instructions: row.instructions,
    status: row.status as QuizStatus,
    questions: readJson<QuizQuestion[]>(row.questionsJson, []),
    settings: readJson<QuizSettings>(row.settingsJson, {
      passMark: 70,
      attempts: 2,
      shuffleQuestions: false,
      shuffleOptions: true,
      showResults: 'score-and-answers',
    }),
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

quizzesRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    const { search, courseId, status } = parseQuery(req, z.object({ search: searchText, courseId: optionalId, status: optionalId }));
    const where = { ...(courseId ? { courseId } : {}), course: courseScopeWhere(req) };
    const quizzes = await db.quiz.findMany({ where, include: { course: true, attempts: true, lesson: { select: { chapter: { select: { title: true } } } } } });
    const chapters = new Map(
      (await db.chapter.findMany({ where: { id: { in: quizzes.flatMap((q) => (q.chapterId ? [q.chapterId] : [])) } }, select: { id: true, title: true } })).map(
        (c) => [c.id, c.title],
      ),
    );

    let rows = quizzes.map((q) => {
      const points = quizTotalPoints({ questions: readJson<QuizQuestion[]>(q.questionsJson, []) });
      const passed = q.attempts.filter((a) => a.passed).length;
      return {
        quiz: mapQuiz(q),
        courseTitle: q.course.title,
        chapterTitle: (q.chapterId ? chapters.get(q.chapterId) : undefined) ?? q.lesson?.chapter.title,
        points,
        attempts: q.attempts.length,
        passRate: q.attempts.length ? Math.round((passed / q.attempts.length) * 100) : null,
        avgScore: q.attempts.length ? Math.round(q.attempts.reduce((n, a) => n + a.percent, 0) / q.attempts.length) : null,
      };
    });

    const counts: Record<QuizStatus | 'all', number> = { all: rows.length, draft: 0, published: 0, archived: 0 };
    for (const r of rows) counts[r.quiz.status]++;
    if (search) rows = rows.filter((r) => r.quiz.title.toLowerCase().includes(search.toLowerCase()));
    if (status && status !== 'all') rows = rows.filter((r) => r.quiz.status === status);

    res.json({ rows, counts });
  }),
);

quizzesRouter.get(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    const row = await assertQuizAccess(req, req.params.id);
    res.json(mapQuiz(row));
  }),
);

quizzesRouter.get(
  '/:id/stats',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    const quiz = await assertQuizAccess(req, req.params.id);
    await settleOverdueQuizSessions({ quizId: quiz.id });
    const attempts = await db.quizAttempt.findMany({ where: { quizId: quiz.id } });
    const learners = new Set(attempts.map((a) => a.studentId)).size;
    const passed = attempts.filter((a) => a.passed).length;
    const passRate = attempts.length ? Math.round((passed / attempts.length) * 100) : 0;
    const avgScore = attempts.length ? Math.round(attempts.reduce((n, a) => n + a.percent, 0) / attempts.length) : 0;

    const bands = Array.from({ length: 10 }, () => 0);
    for (const a of attempts) bands[Math.min(9, Math.floor(a.percent / 10))]++;
    const distribution = bands.map((value, i) => ({ label: i === 9 ? '90–100%' : `${i * 10}–${i * 10 + 9}%`, value }));

    // Median time from stored attempt durations (attempts without one are ignored).
    const durations = attempts
      .map((a) => a.durationSec)
      .filter((d): d is number => d != null && d > 0)
      .sort((a, b) => a - b);
    const medianMinutes = durations.length ? Math.round(durations[Math.floor(durations.length / 2)] / 60) : 0;

    const questions = readJson<QuizQuestion[]>(quiz.questionsJson, []);
    const questionStats = questions.map((q) => {
      // resultJson holds the whole AttemptResult; per-question outcomes sit under `questions`.
      const results = attempts.map((a) => ({
        result: readJson<{ questions?: Record<string, { state: string }> }>(a.resultJson, {}).questions?.[q.id],
        answers: readJson<Record<string, unknown>>(a.answersJson, {}),
      }));
      const correct = results.filter((r) => r.result?.state === 'correct').length;
      // The wrong option picked most often, from the answers of attempts that got this question wrong.
      const picks = new Map<string, number>();
      if (q.type !== 'short') {
        const correctSet = new Set(q.correct);
        for (const r of results) {
          if (!r.result || r.result.state === 'correct' || r.result.state === 'unanswered') continue;
          const chosen = r.answers[q.id];
          for (const optionId of Array.isArray(chosen) ? (chosen as string[]) : chosen ? [String(chosen)] : []) {
            if (!correctSet.has(optionId)) picks.set(optionId, (picks.get(optionId) ?? 0) + 1);
          }
        }
      }
      const commonWrongOptionId = [...picks.entries()].sort((a, b) => b[1] - a[1])[0]?.[0];
      return { questionId: q.id, correctRate: attempts.length ? Math.round((correct / attempts.length) * 100) : 0, commonWrongOptionId };
    });

    res.json({ quizId: quiz.id, attempts: attempts.length, learners, passRate, avgScore, medianMinutes, distribution, questions: questionStats });
  }),
);

/**
 * Every attempt at the quiz, newest first: who, which attempt, under way or handed in (by the learner, or by the server
 * at the deadline), the score and the time taken — the server's clock throughout. Staff see scores whatever the quiz
 * shows learners; an attempt under way has none yet.
 */
quizzesRouter.get(
  '/:id/attempts',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    const quiz = await assertQuizAccess(req, req.params.id);
    await settleOverdueQuizSessions({ quizId: quiz.id });
    const [attempts, sessions] = await Promise.all([
      db.quizAttempt.findMany({ where: { quizId: quiz.id }, include: { student: { include: { user: { select: { name: true, email: true } } } } } }),
      db.quizSession.findMany({ where: { quizId: quiz.id }, include: { student: { include: { user: { select: { name: true, email: true } } } } } }),
    ]);
    const bySession = new Map(attempts.filter((a) => a.sessionId).map((a) => [a.sessionId!, a]));
    // Attempts made before sessions existed are numbered per learner in the order they were made.
    const legacyNo = new Map<string, number>();
    const seen = new Map<string, number>();
    for (const a of [...attempts].filter((x) => !x.sessionId).sort((x, y) => x.createdAt.getTime() - y.createdAt.getTime())) {
      const n = (seen.get(a.studentId) ?? 0) + 1;
      seen.set(a.studentId, n);
      legacyNo.set(a.id, n);
    }
    const learner = (s: { id: string; user: { name: string; email: string } }) => ({ studentId: s.id, name: s.user.name, email: s.user.email });
    const rows = [
      ...sessions.map((x) => {
        const a = bySession.get(x.id);
        return {
          ...learner(x.student),
          attemptId: a?.id,
          sessionId: x.id,
          attemptNo: x.attemptNo,
          status: x.status as 'active' | 'submitted' | 'expired',
          startedAt: x.startedAt.toISOString(),
          deadlineAt: x.deadlineAt?.toISOString(),
          submittedAt: (x.finishedAt ?? a?.createdAt)?.toISOString(),
          percent: a?.percent,
          passed: a?.passed,
          durationSec: a?.durationSec ?? undefined,
        };
      }),
      ...attempts
        .filter((a) => !a.sessionId)
        .map((a) => ({
          ...learner(a.student),
          attemptId: a.id,
          attemptNo: legacyNo.get(a.id)!,
          status: 'submitted' as const,
          startedAt: undefined,
          submittedAt: a.createdAt.toISOString(),
          percent: a.percent,
          passed: a.passed,
          durationSec: a.durationSec ?? undefined,
        })),
    ].sort((x, y) => (y.submittedAt ?? y.startedAt ?? '').localeCompare(x.submittedAt ?? x.startedAt ?? ''));
    res.json({ rows });
  }),
);

quizzesRouter.post(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.edit'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, quizSchema) as unknown as QuizInput & { lessonId?: string | null };
    await assertCourseAccess(req, input.courseId);
    await assertLessonLink(input.courseId, input.lessonId);
    if (input.status === 'published') {
      const issues = validateQuiz(input);
      if (issues.length) throw conflict('This quiz is not ready to publish.', issues);
    }
    const row = await db.quiz.create({
      data: {
        ...tenant(),
        courseId: input.courseId,
        chapterId: input.chapterId,
        title: input.title,
        instructions: input.instructions,
        status: input.status,
        questionsJson: writeJson(input.questions),
        settingsJson: writeJson(input.settings),
        lessonId: input.lessonId ?? undefined,
      },
    });
    res.status(201).json(mapQuiz(row));
  }),
);

quizzesRouter.patch(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.edit'),
  asyncHandler(async (req, res) => {
    const existing = await assertQuizAccess(req, req.params.id);
    const input = parseBody(req, patchOf(quizSchema)) as unknown as Partial<QuizInput> & { lessonId?: string | null };
    if (input.courseId && input.courseId !== existing.courseId) throw conflict('A quiz cannot move to another course.');
    if (input.lessonId !== undefined) await assertLessonLink(existing.courseId, input.lessonId, existing.id);
    const merged = {
      title: input.title ?? existing.title,
      questions: input.questions ?? readJson<QuizQuestion[]>(existing.questionsJson, []),
      settings: input.settings ?? readJson<QuizSettings>(existing.settingsJson, {} as QuizSettings),
    };
    if ((input.status ?? existing.status) === 'published') {
      const issues = validateQuiz(merged);
      if (issues.length) throw conflict('This quiz is not ready to publish.', issues);
    }
    const row = await db.quiz.update({
      where: { id: existing.id },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.instructions !== undefined ? { instructions: input.instructions } : {}),
        ...(input.status !== undefined ? { status: input.status } : {}),
        ...(input.chapterId !== undefined ? { chapterId: input.chapterId } : {}),
        ...(input.questions !== undefined ? { questionsJson: writeJson(input.questions) } : {}),
        ...(input.settings !== undefined ? { settingsJson: writeJson(input.settings) } : {}),
        ...(input.lessonId !== undefined ? { lessonId: input.lessonId } : {}),
      },
    });
    res.json(mapQuiz(row));
  }),
);

quizzesRouter.post(
  '/:id/duplicate',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.edit'),
  asyncHandler(async (req, res) => {
    const original = await assertQuizAccess(req, req.params.id);
    const copy = await db.quiz.create({
      data: {
        ...tenant(),
        courseId: original.courseId,
        chapterId: original.chapterId,
        title: `${original.title} (copy)`,
        instructions: original.instructions,
        status: 'draft',
        questionsJson: original.questionsJson,
        settingsJson: original.settingsJson,
      },
    });
    res.status(201).json(mapQuiz(copy));
  }),
);

quizzesRouter.delete(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.edit'),
  asyncHandler(async (req, res) => {
    const quiz = await assertQuizAccess(req, req.params.id);
    if (quiz.lessonId) throw conflict('This quiz is delivered by a lesson. Change that lesson to another type, or delete the lesson, first.');
    // Deleting would take every learner's result with it: a quiz that has been taken is archived instead.
    const [attempts, sessions] = await Promise.all([
      db.quizAttempt.count({ where: { quizId: quiz.id } }),
      db.quizSession.count({ where: { quizId: quiz.id } }),
    ]);
    if (attempts || sessions) throw conflict('Learners have taken this quiz, so deleting it would delete their results. Archive it instead.');
    await db.quiz.delete({ where: { id: req.params.id } });
    res.status(204).end();
  }),
);
