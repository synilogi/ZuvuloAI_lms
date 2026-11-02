import { Router, type Request, type Response } from 'express';
import {
  validateAssignment,
  validateReview,
  reviewScore,
  assignmentMaxScore,
  type CourseAssignment,
  type AssignmentInput,
  type AssignmentStatus,
  type Attachment,
  type RubricCriterion,
  type DuePolicy,
  type Submission,
  type Review,
  type BirthDetails,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { asyncHandler, conflict, notFound } from '../lib/errors.js';
import { requireAuth, requireRole } from '../lib/auth.js';
import { requireStaffPermission } from '../lib/permissions.js';
import { assertAssignmentAccess, assertCourseAccess, assertSubmissionAccess, courseScopeWhere } from '../lib/scope.js';
import { getSettings } from '../lib/settings.js';
import { notify } from '../lib/notify.js';
import { completeLesson, dueAtFor, loadLearnerCourse } from './learning.js';
import { completionRuleOf, locateLesson } from '../lib/learning.js';
import { id as idSchema, optionalId, paging, parseBody, parseQuery, searchText, z, patchOf } from '../lib/validate.js';

const dueSchema = z.discriminatedUnion('kind', [
  z.object({ kind: z.literal('none') }),
  z.object({ kind: z.literal('date'), dueAt: z.string().refine((v) => !Number.isNaN(Date.parse(v)), 'Enter a valid date.') }),
  z.object({ kind: z.literal('relative'), days: z.number().int().min(1).max(365) }),
]);
const assignmentSchema = z.object({
  courseId: idSchema,
  chapterId: idSchema.optional().nullable(),
  lessonId: idSchema.optional().nullable(),
  title: z.string().trim().min(1).max(160),
  instructions: z.string().max(20_000).default(''),
  attachments: z
    .array(z.object({ id: z.string().max(64).optional(), name: z.string().max(200), sizeMb: z.number().min(0).max(1000) }).passthrough())
    .max(20)
    .default([]),
  format: z.enum(['file', 'text', 'chart']).default('text'),
  wordLimit: z.number().int().min(0).max(100_000).optional().nullable(),
  due: dueSchema.default({ kind: 'none' }),
  acceptsLate: z.boolean().optional(),
  latePenalty: z.number().int().min(0).max(100).optional(),
  rubric: z
    .array(z.object({ id: z.string().max(64), title: z.string().max(200), points: z.number().min(0).max(1000) }).passthrough())
    .max(30)
    .default([]),
  maxScore: z.number().int().min(1).max(1000).default(100),
  passMark: z.number().int().min(0).max(1000).default(60),
  status: z.enum(['draft', 'published', 'closed']).default('draft'),
});
const reviewSchema = z.object({
  decision: z.enum(['draft', 'graded', 'returned']),
  scores: z.record(z.string(), z.number().min(0).max(1000)).default({}),
  points: z.number().min(0).max(1000).optional(),
  feedback: z.string().max(10_000).default(''),
  privateNote: z.string().max(5000).optional(),
});

/** Learners enrolled in the course who have not handed this assignment in (any enrollment that is not paused). */
async function missingLearnersFor(assignmentId: string, courseId: string) {
  const enrolled = await db.enrollment.findMany({
    where: { courseId, status: { in: ['active', 'completed', 'expired'] } },
    include: { student: { include: { user: true } } },
  });
  const submitted = new Set((await db.submission.findMany({ where: { assignmentId }, select: { studentId: true } })).map((s) => s.studentId));
  return enrolled.filter((e) => !submitted.has(e.studentId)).map((e) => e.student);
}

/** An assignment may be delivered by one assignment/practice lesson of its own course. */
async function assertLessonLink(courseId: string, lessonId: string | null | undefined, excludeId?: string) {
  if (!lessonId) return;
  const lesson = await db.lesson.findFirst({ where: { id: lessonId, courseId } });
  if (!lesson) throw conflict('Choose a lesson from the same course.');
  if (lesson.type !== 'assignment' && lesson.type !== 'practice') throw conflict('Only an assignment or practice lesson can deliver an assignment.');
  const taken = await db.courseAssignment.findFirst({ where: { lessonId, ...(excludeId ? { id: { not: excludeId } } : {}) } });
  if (taken) throw conflict('That lesson already delivers another assignment.');
}
import { readJson, writeJson } from '../lib/json.js';

export const assignmentsRouter = Router();

function mapAssignment(row: {
  id: string;
  courseId: string;
  chapterId: string | null;
  lessonId: string | null;
  title: string;
  instructions: string;
  attachmentsJson: string;
  format: string;
  wordLimit: number | null;
  dueJson: string;
  acceptsLate: boolean;
  latePenalty: number;
  rubricJson: string;
  maxScore: number;
  passMark: number;
  status: string;
  createdAt: Date;
  updatedAt: Date;
}): CourseAssignment {
  return {
    id: row.id,
    courseId: row.courseId,
    chapterId: row.chapterId ?? undefined,
    lessonId: row.lessonId ?? undefined,
    title: row.title,
    instructions: row.instructions,
    attachments: readJson<Attachment[]>(row.attachmentsJson, []),
    format: row.format as CourseAssignment['format'],
    wordLimit: row.wordLimit ?? undefined,
    due: readJson<DuePolicy>(row.dueJson, { kind: 'none' }),
    acceptsLate: row.acceptsLate,
    latePenalty: row.latePenalty,
    rubric: readJson<RubricCriterion[]>(row.rubricJson, []),
    maxScore: row.maxScore,
    passMark: row.passMark,
    status: row.status as AssignmentStatus,
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
  };
}

function mapSubmission(row: {
  id: string;
  assignmentId: string;
  studentId: string;
  attempt: number;
  submittedAt: Date;
  late: boolean;
  text: string | null;
  filesJson: string;
  chartJson: string | null;
  reviewStatus: string;
  reviewerId: string | null;
  scoresJson: string;
  points: number | null;
  score: number | null;
  feedback: string;
  privateNote: string | null;
  reviewUpdatedAt: Date | null;
}): Submission {
  return {
    id: row.id,
    assignmentId: row.assignmentId,
    studentId: row.studentId,
    attempt: row.attempt,
    submittedAt: row.submittedAt.toISOString(),
    late: row.late,
    text: row.text ?? undefined,
    files: readJson<Attachment[]>(row.filesJson, []),
    chart: readJson<BirthDetails | undefined>(row.chartJson, undefined),
    review: {
      status: row.reviewStatus as Review['status'],
      reviewerId: row.reviewerId ?? undefined,
      scores: readJson<Record<string, number>>(row.scoresJson, {}),
      points: row.points ?? undefined,
      score: row.score ?? undefined,
      feedback: row.feedback,
      privateNote: row.privateNote ?? undefined,
      updatedAt: row.reviewUpdatedAt?.toISOString(),
    },
  };
}

assignmentsRouter.get(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    const { search, courseId, status } = parseQuery(req, z.object({ search: searchText, courseId: optionalId, status: optionalId }));
    const where = { ...(courseId ? { courseId } : {}), course: courseScopeWhere(req) };
    const assignments = await db.courseAssignment.findMany({ where, include: { course: true, submissions: true } });
    const chapters = new Map(
      (
        await db.chapter.findMany({ where: { id: { in: assignments.flatMap((a) => (a.chapterId ? [a.chapterId] : [])) } }, select: { id: true, title: true } })
      ).map((c) => [c.id, c.title]),
    );
    const enrolledByCourse = new Map<string, number>();
    for (const e of await db.enrollment.groupBy({
      by: ['courseId'],
      where: { courseId: { in: assignments.map((a) => a.courseId) }, status: { in: ['active', 'completed', 'expired'] } },
      _count: { _all: true },
    }))
      enrolledByCourse.set(e.courseId, e._count._all);
    const now = Date.now();

    let rows = assignments.map((a) => {
      const submitted = a.submissions.length;
      const toReview = a.submissions.filter((s) => s.reviewStatus === 'waiting' || s.reviewStatus === 'in-review').length;
      const overdue = a.submissions.filter(
        (s) => (s.reviewStatus === 'waiting' || s.reviewStatus === 'in-review') && now - s.submittedAt.getTime() > 48 * 3_600_000,
      ).length;
      const graded = a.submissions.filter((s) => s.reviewStatus === 'graded' || s.reviewStatus === 'returned').length;
      const scored = a.submissions.filter((s) => s.score != null);
      return {
        assignment: mapAssignment(a),
        courseTitle: a.course.title,
        chapterTitle: a.chapterId ? chapters.get(a.chapterId) : undefined,
        submitted,
        toReview,
        overdue,
        graded,
        // Enrolled learners (not paused) without a hand-in — only meaningful once the assignment is live.
        missing: a.status === 'published' ? Math.max(0, (enrolledByCourse.get(a.courseId) ?? 0) - new Set(a.submissions.map((s) => s.studentId)).size) : 0,
        avgScore: scored.length
          ? Math.round((scored.reduce((n, s) => n + (s.score ?? 0), 0) / scored.length / assignmentMaxScore(mapAssignment(a))) * 100)
          : null,
      };
    });

    const counts: Record<AssignmentStatus | 'all', number> = { all: rows.length, draft: 0, published: 0, closed: 0 };
    for (const r of rows) counts[r.assignment.status]++;
    if (search) rows = rows.filter((r) => r.assignment.title.toLowerCase().includes(search.toLowerCase()));
    if (status && status !== 'all') rows = rows.filter((r) => r.assignment.status === status);

    res.json({ rows, counts });
  }),
);

assignmentsRouter.get(
  '/review',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    const where = { assignment: { course: courseScopeWhere(req) } };
    const submissions = await db.submission.findMany({ where, include: { assignment: { include: { course: true } } }, orderBy: { submittedAt: 'asc' } });
    const toReview = submissions.filter((s) => s.reviewStatus === 'waiting' || s.reviewStatus === 'in-review');
    const overdue = toReview.filter((s) => Date.now() - s.submittedAt.getTime() > 48 * 3_600_000);
    const byCourse = new Map<string, { courseId: string; toReview: number; overdue: number }>();
    for (const s of toReview) {
      const key = s.assignment.courseId;
      const entry = byCourse.get(key) ?? { courseId: key, toReview: 0, overdue: 0 };
      entry.toReview++;
      if (Date.now() - s.submittedAt.getTime() > 48 * 3_600_000) entry.overdue++;
      byCourse.set(key, entry);
    }
    res.json({ toReview: toReview.length, overdue: overdue.length, byCourse: [...byCourse.values()] });
  }),
);

assignmentsRouter.get(
  '/submissions',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    await submissionsHandler(req, res);
  }),
);

assignmentsRouter.get(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    const row = await assertAssignmentAccess(req, req.params.id);
    res.json(mapAssignment(row));
  }),
);

assignmentsRouter.post(
  '/',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.edit'),
  asyncHandler(async (req, res) => {
    const parsed = parseBody(req, assignmentSchema);
    const { learning } = await getSettings();
    // The academy's late policy fills the defaults an author did not set.
    const input = {
      ...parsed,
      acceptsLate: parsed.acceptsLate ?? learning.latePolicy !== 'reject',
      latePenalty: parsed.latePenalty ?? (learning.latePolicy === 'penalty' ? learning.latePenalty : 0),
    } as unknown as AssignmentInput & { lessonId?: string | null };
    await assertCourseAccess(req, input.courseId);
    await assertLessonLink(input.courseId, input.lessonId);
    const issues = validateAssignment(input, new Date());
    if (input.status === 'published' && issues.length) throw conflict('This assignment is not ready to publish.', issues);
    const row = await db.courseAssignment.create({
      data: {
        ...tenant(),
        courseId: input.courseId,
        chapterId: input.chapterId,
        title: input.title,
        instructions: input.instructions,
        attachmentsJson: writeJson(input.attachments ?? []),
        format: input.format,
        wordLimit: input.wordLimit,
        dueJson: writeJson(input.due),
        acceptsLate: input.acceptsLate,
        latePenalty: input.latePenalty,
        rubricJson: writeJson(input.rubric ?? []),
        maxScore: input.maxScore,
        passMark: input.passMark,
        status: input.status,
        lessonId: input.lessonId ?? undefined,
      },
    });
    res.status(201).json(mapAssignment(row));
  }),
);

assignmentsRouter.patch(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.edit'),
  asyncHandler(async (req, res) => {
    const existing = await assertAssignmentAccess(req, req.params.id);
    const input = parseBody(req, patchOf(assignmentSchema)) as unknown as Partial<AssignmentInput> & { lessonId?: string | null };
    if (input.courseId && input.courseId !== existing.courseId) await assertCourseAccess(req, input.courseId);
    if (input.lessonId !== undefined) await assertLessonLink(input.courseId ?? existing.courseId, input.lessonId, existing.id);
    const merged: AssignmentInput = {
      courseId: input.courseId ?? existing.courseId,
      chapterId: input.chapterId ?? existing.chapterId ?? undefined,
      title: input.title ?? existing.title,
      instructions: input.instructions ?? existing.instructions,
      attachments: input.attachments ?? readJson(existing.attachmentsJson, []),
      format: input.format ?? (existing.format as AssignmentInput['format']),
      wordLimit: input.wordLimit ?? existing.wordLimit ?? undefined,
      due: input.due ?? readJson(existing.dueJson, { kind: 'none' }),
      acceptsLate: input.acceptsLate ?? existing.acceptsLate,
      latePenalty: input.latePenalty ?? existing.latePenalty,
      rubric: input.rubric ?? readJson(existing.rubricJson, []),
      maxScore: input.maxScore ?? existing.maxScore,
      passMark: input.passMark ?? existing.passMark,
      status: input.status ?? (existing.status as AssignmentStatus),
    };
    const issues = validateAssignment(merged, new Date());
    if (merged.status === 'published' && issues.length) throw conflict('This assignment is not ready to publish.', issues);

    const row = await db.courseAssignment.update({
      where: { id: existing.id },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.instructions !== undefined ? { instructions: input.instructions } : {}),
        ...(input.attachments !== undefined ? { attachmentsJson: writeJson(input.attachments) } : {}),
        ...(input.format !== undefined ? { format: input.format } : {}),
        ...(input.wordLimit !== undefined ? { wordLimit: input.wordLimit } : {}),
        ...(input.due !== undefined ? { dueJson: writeJson(input.due) } : {}),
        ...(input.acceptsLate !== undefined ? { acceptsLate: input.acceptsLate } : {}),
        ...(input.latePenalty !== undefined ? { latePenalty: input.latePenalty } : {}),
        ...(input.rubric !== undefined ? { rubricJson: writeJson(input.rubric) } : {}),
        ...(input.maxScore !== undefined ? { maxScore: input.maxScore } : {}),
        ...(input.passMark !== undefined ? { passMark: input.passMark } : {}),
        ...(input.status !== undefined ? { status: input.status } : {}),
        ...(input.lessonId !== undefined ? { lessonId: input.lessonId } : {}),
      },
    });
    res.json(mapAssignment(row));
  }),
);

assignmentsRouter.post(
  '/:id/duplicate',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.edit'),
  asyncHandler(async (req, res) => {
    const original = await assertAssignmentAccess(req, req.params.id);
    const copy = await db.courseAssignment.create({
      data: {
        ...tenant(),
        courseId: original.courseId,
        chapterId: original.chapterId,
        title: `${original.title} (copy)`,
        instructions: original.instructions,
        attachmentsJson: original.attachmentsJson,
        format: original.format,
        wordLimit: original.wordLimit,
        dueJson: original.dueJson,
        acceptsLate: original.acceptsLate,
        latePenalty: original.latePenalty,
        rubricJson: original.rubricJson,
        maxScore: original.maxScore,
        passMark: original.passMark,
        status: 'draft',
      },
    });
    res.status(201).json(mapAssignment(copy));
  }),
);

assignmentsRouter.delete(
  '/:id',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.edit'),
  asyncHandler(async (req, res) => {
    const assignment = await assertAssignmentAccess(req, req.params.id);
    if (assignment.lessonId) throw conflict('This assignment is delivered by a lesson. Change that lesson to another type, or delete the lesson, first.');
    await db.courseAssignment.delete({ where: { id: req.params.id } });
    res.status(204).end();
  }),
);

assignmentsRouter.get(
  '/:id/submissions',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    await assertAssignmentAccess(req, req.params.id);
    await submissionsHandler(req, res, req.params.id);
  }),
);

async function submissionsHandler(req: Request, res: Response, forcedAssignmentId?: string) {
  const { assignmentId, courseId, filter, search, sort, page, pageSize } = parseQuery(
    req,
    z.object({ assignmentId: optionalId, courseId: optionalId, filter: optionalId, search: searchText, sort: optionalId, ...paging }),
  );
  const resolvedAssignmentId = forcedAssignmentId ?? assignmentId;

  const assignments = await db.courseAssignment.findMany({
    where: {
      ...(resolvedAssignmentId ? { id: resolvedAssignmentId } : {}),
      ...(courseId ? { courseId } : {}),
      course: courseScopeWhere(req),
    },
    include: { course: true, submissions: { include: { student: { include: { user: true } } } } },
  });

  type Row = {
    id: string;
    submission?: Submission;
    student: { id: string; name: string; email: string; city: string };
    assignmentId: string;
    assignmentTitle: string;
    courseTitle: string;
    maxScore: number;
    overdue: boolean;
  };
  let rows: Row[] = assignments.flatMap((a) =>
    a.submissions.map((s) => ({
      id: s.id,
      submission: mapSubmission(s),
      student: { id: s.student.id, name: s.student.user.name, email: s.student.user.email, city: s.student.city },
      assignmentId: a.id,
      assignmentTitle: a.title,
      courseTitle: a.course.title,
      maxScore: assignmentMaxScore(mapAssignment(a)),
      overdue: (s.reviewStatus === 'waiting' || s.reviewStatus === 'in-review') && Date.now() - s.submittedAt.getTime() > 48 * 3_600_000,
    })),
  );

  // Learners who have not handed in a published assignment appear as rows without a submission.
  const missingRows: Row[] = [];
  for (const a of assignments.filter((x) => x.status === 'published')) {
    for (const student of await missingLearnersFor(a.id, a.courseId)) {
      missingRows.push({
        id: `missing-${a.id}-${student.id}`,
        student: { id: student.id, name: student.user.name, email: student.user.email, city: student.city },
        assignmentId: a.id,
        assignmentTitle: a.title,
        courseTitle: a.course.title,
        maxScore: assignmentMaxScore(mapAssignment(a)),
        overdue: false,
      });
    }
  }

  const counts = { all: rows.length, 'to-review': 0, graded: 0, returned: 0, missing: missingRows.length } as Record<string, number>;
  for (const r of rows) {
    if (r.submission?.review.status === 'waiting' || r.submission?.review.status === 'in-review') counts['to-review']++;
    else if (r.submission?.review.status === 'graded') counts.graded++;
    else if (r.submission?.review.status === 'returned') counts.returned++;
  }
  if (filter === 'missing') rows = missingRows;

  if (search)
    rows = rows.filter((r) => r.student.name.toLowerCase().includes(search.toLowerCase()) || r.student.email.toLowerCase().includes(search.toLowerCase()));
  if (filter === 'to-review') rows = rows.filter((r) => r.submission?.review.status === 'waiting' || r.submission?.review.status === 'in-review');
  else if (filter === 'graded') rows = rows.filter((r) => r.submission?.review.status === 'graded');
  else if (filter === 'returned') rows = rows.filter((r) => r.submission?.review.status === 'returned');

  if (sort === 'newest') rows.sort((a, b) => (b.submission?.submittedAt ?? '').localeCompare(a.submission?.submittedAt ?? ''));
  else if (sort === 'score') rows.sort((a, b) => (b.submission?.review.score ?? 0) - (a.submission?.review.score ?? 0));
  else rows.sort((a, b) => (a.submission?.submittedAt ?? '').localeCompare(b.submission?.submittedAt ?? ''));

  res.json({ rows: rows.slice((page - 1) * pageSize, page * pageSize), total: rows.length, counts });
}

assignmentsRouter.get(
  '/submissions/:submissionId',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.view'),
  asyncHandler(async (req, res) => {
    await assertSubmissionAccess(req, req.params.submissionId);
    const sub = await db.submission.findUnique({
      where: { id: req.params.submissionId },
      include: { student: { include: { user: true } }, assignment: { include: { course: true } } },
    });
    if (!sub) throw notFound('Submission not found.');
    const enrollment = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId: sub.studentId, courseId: sub.assignment.courseId } } });
    const queue = await db.submission.findMany({
      where: { assignmentId: sub.assignmentId, reviewStatus: { in: ['waiting', 'in-review'] } },
      orderBy: { submittedAt: 'asc' },
    });
    const position = queue.findIndex((q) => q.id === sub.id);

    const chapter = sub.assignment.chapterId ? await db.chapter.findUnique({ where: { id: sub.assignment.chapterId }, select: { title: true } }) : null;
    res.json({
      submission: mapSubmission(sub),
      assignment: mapAssignment(sub.assignment),
      courseTitle: sub.assignment.course.title,
      chapterTitle: chapter?.title,
      student: {
        id: sub.student.id,
        name: sub.student.user.name,
        email: sub.student.user.email,
        city: sub.student.city,
        progress: enrollment?.progress ?? 0,
        enrolledAt: enrollment?.enrolledAt.toISOString() ?? sub.submittedAt.toISOString(),
      },
      queue: {
        position: position === -1 ? 0 : position + 1,
        total: queue.length,
        previousId: position > 0 ? queue[position - 1].id : undefined,
        nextId: position >= 0 && position < queue.length - 1 ? queue[position + 1].id : undefined,
      },
    });
  }),
);

assignmentsRouter.post(
  '/submissions/:submissionId/review',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('assessment.grade'),
  asyncHandler(async (req, res) => {
    const input = parseBody(req, reviewSchema);
    const sub = await assertSubmissionAccess(req, req.params.submissionId);
    const assignment = mapAssignment(sub.assignment);

    if (input.decision !== 'draft') {
      const issues = validateReview(assignment, input, input.decision);
      if (issues.length) throw conflict('Check the review before submitting it.', issues);
    }

    // The academy's late policy decides whether a late hand-in loses marks.
    const { learning } = await getSettings();
    const penalised = learning.latePolicy === 'penalty' ? assignment : { ...assignment, latePenalty: 0 };
    let score: number | undefined;
    if (input.decision !== 'draft') {
      score = reviewScore(penalised, input, sub.late).score;
    }

    const row = await db.submission.update({
      where: { id: sub.id },
      data: {
        reviewStatus: input.decision === 'draft' ? 'in-review' : input.decision,
        scoresJson: writeJson(input.scores),
        points: input.points,
        score,
        feedback: input.feedback,
        privateNote: input.privateNote,
        reviewUpdatedAt: new Date(),
        reviewerId: req.auth!.instructorId ?? req.auth!.sub,
      },
    });

    if (input.decision !== 'draft') {
      const student = await db.student.findUnique({ where: { id: sub.studentId }, select: { userId: true } });
      const reviewer = await db.user.findUnique({ where: { id: req.auth!.sub }, select: { name: true } });
      const course = await db.course.findUnique({ where: { id: assignment.courseId }, select: { title: true } });
      const max = assignmentMaxScore(assignment);
      if (student) {
        await notify({
          recipientUserId: student.userId,
          category: 'assignment',
          title: input.decision === 'graded' ? `“${assignment.title}” has been graded` : `“${assignment.title}” was returned for another attempt`,
          summary:
            input.decision === 'graded'
              ? `You scored ${score} / ${max}${(score ?? 0) >= assignment.passMark ? ' — passed.' : ` — the pass mark is ${assignment.passMark}.`}`
              : 'Your reviewer has left feedback and asked you to resubmit.',
          body: input.feedback ? [input.feedback] : undefined,
          actor: reviewer?.name,
          facts: [
            ...(input.decision === 'graded'
              ? [
                  { label: 'Score', value: `${score} / ${max}` },
                  { label: 'Pass mark', value: String(assignment.passMark) },
                ]
              : []),
            { label: 'Course', value: course?.title ?? '' },
          ],
          action: { label: input.decision === 'graded' ? 'Read the feedback' : 'Resubmit', to: `/assignments/${assignment.id}` },
        });
      }
      // A graded pass completes an assignment lesson whose rule is "passed".
      if (input.decision === 'graded' && assignment.lessonId && (score ?? 0) >= assignment.passMark) {
        const { course: learnerCourse, rules } = await loadLearnerCourse(sub.studentId, assignment.courseId).catch(() => ({ course: null, rules: null }));
        const lesson = learnerCourse ? locateLesson(learnerCourse, assignment.lessonId)?.lesson : undefined;
        if (learnerCourse && rules && lesson && completionRuleOf(lesson) === 'passed')
          await completeLesson(sub.studentId, learnerCourse, assignment.lessonId, rules).catch(() => undefined);
      }
    }
    res.json(mapSubmission(row));
  }),
);

assignmentsRouter.post(
  '/:id/remind',
  requireAuth,
  requireRole('instructor', 'admin'),
  requireStaffPermission('learners.message'),
  asyncHandler(async (req, res) => {
    const { studentIds } = parseBody(req, z.object({ studentIds: z.array(idSchema).max(500).default([]) }));
    const assignment = await assertAssignmentAccess(req, req.params.id);
    const course = await db.course.findUnique({ where: { id: assignment.courseId }, select: { title: true } });
    // Only learners who still owe this assignment are reminded; an empty list means everyone who does.
    const missing = await missingLearnersFor(assignment.id, assignment.courseId);
    const targets = missing.filter((s) => !studentIds.length || studentIds.includes(s.id));
    const sender = await db.user.findUnique({ where: { id: req.auth!.sub }, select: { name: true } });
    let sent = 0;
    for (const s of targets) {
      const dueAt = await dueAtFor(
        assignment,
        s.id,
        (await db.enrollment.findUnique({ where: { studentId_courseId: { studentId: s.id, courseId: assignment.courseId } } }))?.enrolledAt,
      );
      const r = await notify({
        recipientUserId: s.userId,
        category: 'assignment',
        title: `Reminder: “${assignment.title}” is waiting for you`,
        summary: dueAt
          ? `Due ${new Date(dueAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', timeZone: 'Asia/Kolkata' })} · ${course?.title ?? ''}`
          : `${course?.title ?? ''} · hand in when you are ready.`,
        actor: sender?.name,
        action: { label: 'Open the assignment', to: `/assignments/${assignment.id}` },
      });
      if (r.app || r.email) sent++;
    }
    res.json({ sent });
  }),
);
