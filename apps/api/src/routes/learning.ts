import { Router } from 'express';
import {
  attemptsUsed,
  clampPercent,
  courseSale,
  deriveLiveClassPhase,
  learnerQuestion,
  lessonState,
  quizTotalPoints,
  quizWindow,
  resultsOut,
  scoreShown,
  creditedPercent,
  resultsVisibilityOf,
  REVIEW_COMMENT_MAX,
  REVIEW_RATING_MAX,
  REVIEW_RATING_MIN,
  reviewAttempt,
  validateSubmission,
  type AttemptResult,
  type AttemptReview,
  type Attachment,
  type BirthDetails,
  type Course,
  type CoursePricing,
  type CourseProgressSnapshot,
  type LearningEvent,
  type QuizAnswers,
  type QuizQuestion,
  type QuizSessionStart,
  type QuizSettings,
  type QuizStanding,
} from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { ApiError, asyncHandler, badRequest, conflict, notFound } from '../lib/errors.js';
import { requireAuth } from '../lib/auth.js';
import { COURSE_INCLUDE, mapCourse, withoutLessonContent } from '../lib/mapCourse.js';
import { forLearner, mapLive } from '../lib/mapLive.js';
import { readJson, writeJson } from '../lib/json.js';
import { assertNotSuspended, requireEnrollment, requireLessonAccess, requireStudent } from '../lib/scope.js';
import { ownCourseReview, saveCourseReview } from '../lib/courseReviews.js';
import { mergeLinkedContent } from '../lib/lessonLinks.js';
import {
  applyLocks,
  completionRuleOf,
  expiryFor,
  isCourseComplete,
  learnerRules,
  locateLesson,
  lockedReason,
  nextLessonFor,
  progressOf,
  publishedLessons,
  settleExpiry,
  snapshotFor,
  type LearnerRules,
} from '../lib/learning.js';
import { certificateRecordFor, onCourseCompleted, workingTowards } from '../lib/certificates.js';
import { progressRowsFor, studyDays } from '../lib/study.js';
import { id as idSchema, parseBody, z } from '../lib/validate.js';
import { getSettings } from '../lib/settings.js';
import { instructorUserIdsFor, notify, notifyMany } from '../lib/notify.js';
import {
  finishOverdue,
  finishSession,
  latestSession,
  ownSession,
  saveAnswers,
  sessionQuestions,
  sessionView,
  startSession,
  type Finished,
} from '../lib/quizSessions.js';

export const learningRouter = Router();

const DAY_MS = 86_400_000;

const reviewBody = z.object({
  rating: z.number().int().min(REVIEW_RATING_MIN).max(REVIEW_RATING_MAX),
  comment: z.string().trim().max(REVIEW_COMMENT_MAX).default(''),
});

/** The learner's own review of a course, and whether they may write one. */
learningRouter.get(
  '/courses/:courseId/review',
  requireAuth,
  asyncHandler(async (req, res) => {
    res.json(await ownCourseReview(await requireStudent(req), req.params.courseId));
  }),
);

/** Creates or edits the learner's review: an active or completed enrolment only. */
learningRouter.put(
  '/courses/:courseId/review',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await requireStudent(req);
    res.json(await saveCourseReview(req, studentId, req.params.courseId, parseBody(req, reviewBody)));
  }),
);

async function studentIdOf(req: import('express').Request) {
  const id = req.auth?.studentId;
  if (!id) throw badRequest('Only learners have a learning workspace.');
  // Every learner action passes through here, so this is where a suspension takes hold.
  await assertNotSuspended(id);
  return id;
}

const learnerInclude = { ...COURSE_INCLUDE, instructors: { include: { instructor: true } }, level: true };

/** A course as the learner sees it: enrollment (with lazy expiry), progress snapshot with locks, names. */
export async function loadLearnerCourse(studentId: string, courseId: string, rules?: LearnerRules) {
  const r = rules ?? (await learnerRules());
  const courseRow = await db.course.findUnique({ where: { id: courseId }, include: learnerInclude });
  if (!courseRow) throw notFound('Course not found.');
  let enrollment = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId, courseId } } });
  // Drafts are invisible to learners unless they already hold an enrollment (e.g. it was unpublished later).
  if (!enrollment && courseRow.status !== 'published') throw notFound('Course not found.');
  if (enrollment) enrollment = await settleExpiry(enrollment);
  // Lesson bodies are only for enrolled learners; the outline (and free previews) stay visible.
  const course = enrollment ? mapCourse(courseRow) : withoutLessonContent(mapCourse(courseRow));
  const snapshot = await snapshotFor(course, studentId, r.chapterGate);
  const progress = progressOf(course, snapshot);
  return {
    courseRow,
    course,
    enrollment,
    snapshot,
    progress,
    rules: r,
    instructorNames: courseRow.instructors.map((i) => i.instructor.name),
    levelTitle: courseRow.level.name,
  };
}

function mapEnrollment(e: {
  id: string;
  studentId: string;
  courseId: string;
  enrolledAt: Date;
  status: string;
  progress: number;
  source: string;
  lastActiveAt: Date | null;
  completedAt: Date | null;
  lastLessonId: string | null;
  expiresAt: Date | null;
}) {
  return {
    id: e.id,
    studentId: e.studentId,
    courseId: e.courseId,
    enrolledAt: e.enrolledAt.toISOString(),
    status: e.status,
    progress: e.progress,
    source: e.source,
    lastActiveAt: e.lastActiveAt?.toISOString(),
    completedAt: e.completedAt?.toISOString(),
    lastLessonId: e.lastLessonId ?? undefined,
    expiresAt: e.expiresAt?.toISOString(),
  };
}

async function learnerCourseShape(studentId: string, courseId: string, rules?: LearnerRules) {
  const loaded = await loadLearnerCourse(studentId, courseId, rules);
  const { course, enrollment, snapshot, progress, instructorNames, levelTitle } = loaded;
  return {
    loaded,
    shape: {
      course,
      enrollment: enrollment ? mapEnrollment(enrollment) : { id: '', studentId, courseId, enrolledAt: '', status: 'active', progress: 0, source: 'self' },
      progress,
      snapshot,
      next: nextLessonFor(course, snapshot),
      instructorNames,
      levelTitle,
      lastActiveAt: enrollment?.lastActiveAt?.toISOString(),
    },
  };
}

/**
 * Writes progress back to the enrollment after any change and completes the course when the
 * academy's rule is met (which hands over to the certificates module).
 */
async function syncEnrollment(studentId: string, course: Course, snapshot: CourseProgressSnapshot, rules: LearnerRules, lastLessonId?: string) {
  const progress = progressOf(course, snapshot);
  const enrollment = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId, courseId: course.id } } });
  if (!enrollment) return { progress, courseCompleted: false };
  const completeNow = isCourseComplete(course, snapshot, rules);
  const justCompleted = completeNow && enrollment.status !== 'completed';
  await db.enrollment.update({
    where: { id: enrollment.id },
    data: {
      progress: progress.percent,
      lastActiveAt: new Date(),
      ...(lastLessonId ? { lastLessonId } : {}),
      ...(justCompleted ? { status: 'completed', completedAt: new Date() } : {}),
    },
  });
  await db.student.update({ where: { id: studentId }, data: { lastActiveAt: new Date() } });
  if (justCompleted) await onCourseCompleted(studentId, course);
  return { progress, courseCompleted: completeNow };
}

/** Marks a lesson complete and reports what changed (chapter finished, course finished, what comes next). */
export async function completeLesson(studentId: string, course: Course, lessonId: string, rules: LearnerRules) {
  const located = locateLesson(course, lessonId);
  if (!located || located.lesson.status !== 'published') throw notFound('Lesson not found.');
  const before = await snapshotFor(course, studentId, rules.chapterGate);
  if (before.lessons[lessonId]?.state === 'locked') throw conflict(lockedReason(course, located.chapterIndex, located.lesson, before));
  const chapterLessons = located.chapter.lessons.filter((l) => l.status === 'published');
  const chapterWasDone = chapterLessons.every((l) => before.lessons[l.id]?.state === 'completed');

  await db.lessonProgress.upsert({
    where: { studentId_lessonId: { studentId, lessonId } },
    update: { state: 'completed', fraction: 1, completedAt: new Date(), lastAccessedAt: new Date() },
    create: { ...tenant(), studentId, lessonId, state: 'completed', fraction: 1, completedAt: new Date(), lastAccessedAt: new Date() },
  });
  const snapshot = await snapshotFor(course, studentId, rules.chapterGate);
  const { progress, courseCompleted } = await syncEnrollment(studentId, course, snapshot, rules, lessonId);
  const chapterDone = chapterLessons.every((l) => snapshot.lessons[l.id]?.state === 'completed');
  const all = publishedLessons(course);
  const after = all
    .slice(all.findIndex((x) => x.lesson.id === lessonId) + 1)
    .find((x) => !['completed', 'locked'].includes(snapshot.lessons[x.lesson.id]?.state ?? ''));
  return {
    snapshot,
    progress,
    chapterCompleted: !chapterWasDone && chapterDone ? located.chapter.title : undefined,
    courseCompleted,
    nextLessonId: after?.lesson.id,
  };
}

/* ─── Assignments (learner view) ───────────────────────────────────────── */

type AssignmentRow = Awaited<ReturnType<typeof db.courseAssignment.findUniqueOrThrow>>;

function authoredAssignment(a: AssignmentRow) {
  return {
    id: a.id,
    courseId: a.courseId,
    chapterId: a.chapterId ?? undefined,
    lessonId: a.lessonId ?? undefined,
    title: a.title,
    instructions: a.instructions,
    attachments: readJson(a.attachmentsJson, []),
    format: a.format,
    wordLimit: a.wordLimit ?? undefined,
    due: readJson(a.dueJson, { kind: 'none' }),
    acceptsLate: a.acceptsLate,
    latePenalty: a.latePenalty,
    rubric: readJson(a.rubricJson, []),
    maxScore: a.maxScore,
    passMark: a.passMark,
    status: a.status,
    createdAt: a.createdAt.toISOString(),
    updatedAt: a.updatedAt.toISOString(),
  };
}

function mapLearnerSubmission(s: {
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
  scoresJson: string;
  points: number | null;
  score: number | null;
  feedback: string;
}) {
  return {
    id: s.id,
    assignmentId: s.assignmentId,
    studentId: s.studentId,
    attempt: s.attempt,
    submittedAt: s.submittedAt.toISOString(),
    late: s.late,
    text: s.text ?? undefined,
    files: readJson<Attachment[]>(s.filesJson, []),
    chart: readJson<BirthDetails | undefined>(s.chartJson, undefined),
    review: { status: s.reviewStatus, scores: readJson(s.scoresJson, {}), points: s.points ?? undefined, score: s.score ?? undefined, feedback: s.feedback },
  };
}

/**
 * When an assignment is due for this learner: a fixed date as set, a relative deadline counted from
 * the moment its chapter opened for them (first activity in the chapter, else enrolment).
 */
export async function dueAtFor(a: AssignmentRow, studentId: string, enrolledAt?: Date): Promise<string | undefined> {
  const due = readJson<{ kind: string; dueAt?: string; days?: number }>(a.dueJson, { kind: 'none' });
  if (due.kind === 'date') return due.dueAt;
  if (due.kind !== 'relative' || !due.days || !enrolledAt) return undefined;
  let opened = enrolledAt;
  if (a.chapterId) {
    const first = await db.lessonProgress.findFirst({
      where: { studentId, lesson: { chapterId: a.chapterId } },
      orderBy: { lastAccessedAt: 'asc' },
      select: { lastAccessedAt: true, completedAt: true },
    });
    const at = first?.lastAccessedAt ?? first?.completedAt;
    if (at && at > opened) opened = at;
  }
  return new Date(opened.getTime() + due.days * DAY_MS).toISOString();
}

async function learnerAssignmentFor(studentId: string, a: AssignmentRow & { course: { title: string } }, enrolledAt?: Date) {
  const submission = await db.submission.findFirst({ where: { studentId, assignmentId: a.id }, orderBy: { attempt: 'desc' } });
  const draftRow = await db.assignmentDraft.findUnique({ where: { studentId_assignmentId: { studentId, assignmentId: a.id } } });
  const chapter = a.chapterId ? await db.chapter.findUnique({ where: { id: a.chapterId }, select: { title: true } }) : null;
  const dueAt = await dueAtFor(a, studentId, enrolledAt);
  const overdue = !!dueAt && new Date(dueAt) < new Date();
  const state = submission
    ? submission.reviewStatus === 'waiting'
      ? 'submitted'
      : submission.reviewStatus === 'in-review'
        ? 'under-review'
        : submission.reviewStatus === 'graded'
          ? 'graded'
          : 'draft'
    : a.status === 'closed'
      ? 'closed'
      : draftRow
        ? overdue
          ? 'overdue'
          : 'draft'
        : overdue
          ? 'overdue'
          : 'not-started';
  return {
    assignment: authoredAssignment(a),
    courseTitle: a.course.title,
    chapterTitle: chapter?.title,
    lessonId: a.lessonId ?? undefined,
    state,
    dueAt,
    submission: submission ? mapLearnerSubmission(submission) : undefined,
    draft: draftRow
      ? { text: draftRow.text, files: readJson<Attachment[]>(draftRow.filesJson, []), chart: readJson<BirthDetails | undefined>(draftRow.chartJson, undefined) }
      : undefined,
  };
}

/* ─── Home & course lists ─────────────────────────────────────────────── */

learningRouter.get(
  '/home',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const rules = await learnerRules();
    const student = await db.student.findUnique({ where: { id: studentId }, include: { user: true, enrollments: true, savedCourses: true } });
    if (!student) throw notFound('Student not found.');
    const now = new Date();

    const courses = (
      await Promise.all(
        student.enrollments.map((e) =>
          learnerCourseShape(studentId, e.courseId, rules)
            .then((r) => r.shape)
            .catch(() => null),
        ),
      )
    ).filter((c): c is NonNullable<typeof c> => c !== null);
    courses.sort(
      (a, b) =>
        Number(a.enrollment.status === 'completed') - Number(b.enrollment.status === 'completed') || (b.lastActiveAt ?? '').localeCompare(a.lastActiveAt ?? ''),
    );

    // Recently accessed lessons across every course, newest first
    const progressRows = await db.lessonProgress.findMany({
      where: { studentId, OR: [{ lastAccessedAt: { not: null } }, { completedAt: { not: null } }] },
      include: { lesson: { include: { chapter: { include: { course: { select: { id: true, title: true } } } } } } },
    });
    const recent = progressRows
      .map((p) => ({
        courseId: p.lesson.courseId,
        courseTitle: p.lesson.chapter.course.title,
        lessonId: p.lessonId,
        lessonTitle: p.lesson.title,
        type: p.lesson.type,
        at: (p.lastAccessedAt ?? p.completedAt)!.toISOString(),
        state: p.state,
      }))
      .sort((a, b) => b.at.localeCompare(a.at) || Number(b.state === 'in-progress') - Number(a.state === 'in-progress'))
      .slice(0, 5);

    // Coming up in the next two weeks: live classes, deadlines, quizzes ready to take
    const upcoming: {
      id: string;
      kind: 'live' | 'assignment' | 'quiz';
      title: string;
      context: string;
      at: string;
      to: string;
      flag?: 'live-now' | 'starting-soon' | 'overdue' | 'due-soon';
    }[] = [];
    const activeCourseIds = courses.filter((c) => c.enrollment.status === 'active').map((c) => c.course.id);
    const liveClasses = await db.liveClass.findMany({
      where: { courseId: { in: courses.map((c) => c.course.id) }, cancelled: false },
      include: { course: true },
    });
    for (const cls of liveClasses) {
      const phase = deriveLiveClassPhase(mapLive(cls), now);
      if (phase === 'cancelled' || phase === 'ended' || phase === 'recording-expired') continue;
      if (cls.startsAt.getTime() - now.getTime() > 14 * DAY_MS) continue;
      upcoming.push({
        id: cls.id,
        kind: 'live',
        title: cls.title,
        context: `${cls.course.title} · ${cls.durationMin} min`,
        at: cls.startsAt.toISOString(),
        to: `/live/${cls.id}`,
        flag: phase === 'live' ? 'live-now' : phase === 'starting-soon' ? 'starting-soon' : undefined,
      });
    }
    const assignments = await db.courseAssignment.findMany({ where: { courseId: { in: activeCourseIds }, status: 'published' }, include: { course: true } });
    for (const a of assignments) {
      const enrollment = student.enrollments.find((e) => e.courseId === a.courseId);
      const la = await learnerAssignmentFor(studentId, a, enrollment?.enrolledAt);
      if (!la.dueAt || !['not-started', 'draft', 'overdue'].includes(la.state)) continue;
      const days = (new Date(la.dueAt).getTime() - now.getTime()) / DAY_MS;
      if (days > 14) continue;
      upcoming.push({
        id: a.id,
        kind: 'assignment',
        title: a.title,
        context: la.state === 'overdue' ? `${a.course.title} · overdue` : a.course.title,
        at: la.dueAt,
        to: `/assignments/${a.id}`,
        flag: la.state === 'overdue' ? 'overdue' : days < 3 ? 'due-soon' : undefined,
      });
    }
    for (const c of courses.filter((x) => x.enrollment.status === 'active')) {
      const quiz = publishedLessons(c.course).find(({ lesson }) => lesson.type === 'assessment' && !c.snapshot.lessons[lesson.id]);
      if (quiz)
        upcoming.push({
          id: quiz.lesson.id,
          kind: 'quiz',
          title: quiz.lesson.title,
          context: `${c.course.title} · ready to take`,
          at: now.toISOString(),
          to: `/learn/${c.course.id}/lessons/${quiz.lesson.id}`,
        });
    }
    upcoming.sort((a, b) => Number(Boolean(b.flag)) - Number(Boolean(a.flag)) || a.at.localeCompare(b.at));

    const savedCourses = await db.course.findMany({
      where: { id: { in: student.savedCourses.map((s) => s.courseId) }, status: 'published' },
      include: learnerInclude,
    });
    const saved = savedCourses.map((c) => ({
      course: withoutLessonContent(mapCourse(c)),
      instructorNames: c.instructors.map((i) => i.instructor.name),
      levelTitle: c.level.name,
    }));

    const week = studyDays(await progressRowsFor(studentId), 7, now);

    res.json({ firstName: student.user.name.split(' ')[0], courses, saved, recent, upcoming: upcoming.slice(0, 6), week });
  }),
);

learningRouter.get(
  '/courses',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const rules = await learnerRules();
    const enrollments = await db.enrollment.findMany({ where: { studentId } });
    const courses = (
      await Promise.all(
        enrollments.map((e) =>
          learnerCourseShape(studentId, e.courseId, rules)
            .then((r) => r.shape)
            .catch(() => null),
        ),
      )
    ).filter((c): c is NonNullable<typeof c> => c !== null);
    const student = await db.student.findUnique({ where: { id: studentId }, include: { savedCourses: true } });
    const savedCourses = await db.course.findMany({
      where: { id: { in: student?.savedCourses.map((s) => s.courseId) ?? [] }, status: 'published' },
      include: learnerInclude,
    });
    res.json({
      courses,
      saved: savedCourses.map((c) => ({
        course: withoutLessonContent(mapCourse(c)),
        instructorNames: c.instructors.map((i) => i.instructor.name),
        levelTitle: c.level.name,
      })),
    });
  }),
);

learningRouter.get(
  '/courses/:courseId',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId } = req.params;
    const { loaded, shape } = await learnerCourseShape(studentId, courseId);
    const { enrollment, course } = loaded;
    const live = await db.liveClass.findMany({ where: { courseId, startsAt: { gte: new Date() }, cancelled: false }, orderBy: { startsAt: 'asc' } });
    const assignmentRows = enrollment ? await db.courseAssignment.findMany({ where: { courseId, status: 'published' }, include: { course: true } }) : [];
    const assignments = await Promise.all(assignmentRows.map((a) => learnerAssignmentFor(studentId, a, enrollment?.enrolledAt)));
    const student = await db.student.findUnique({ where: { id: studentId }, include: { savedCourses: true } });
    const certificate = enrollment ? await certificateRecordFor(studentId, courseId) : undefined;

    res.json({
      ...shape,
      enrolled: !!enrollment,
      // The course page lists its classes to anyone looking at it, enrolled or not: never with an outside meeting's link.
      live: live.map((l) => forLearner(mapLive(l))),
      assignments: assignments.map((a) => ({
        assignment: {
          id: a.assignment.id,
          courseId: a.assignment.courseId,
          title: a.assignment.title,
          instructions: a.assignment.instructions,
          dueAt: a.dueAt,
        },
        courseTitle: course.title,
        state: a.state,
        dueAt: a.dueAt,
        lessonId: a.lessonId,
      })),
      certificate,
      saved: !!student?.savedCourses.some((s) => s.courseId === courseId),
    });
  }),
);

/* ─── Lesson player ───────────────────────────────────────────────────── */

learningRouter.get(
  '/courses/:courseId/lessons/:lessonId',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    const { course, enrollment, snapshot, progress, rules, instructorNames } = await loadLearnerCourse(studentId, courseId);
    const located = locateLesson(course, lessonId);
    if (!located) throw notFound('Lesson not found.');
    let { lesson } = located;
    const { chapterIndex, lessonIndex } = located;

    const flat = course.chapters.flatMap((c) => c.lessons);
    const flatIndex = flat.findIndex((l) => l.id === lessonId);
    const state = lessonState(lessonId, snapshot);
    const expired = enrollment?.status === 'expired';
    const access: 'open' | 'locked' | 'not-enrolled' | 'unavailable' =
      !enrollment && !lesson.isPreview ? 'not-enrolled' : lesson.status !== 'published' || expired ? 'unavailable' : state === 'locked' ? 'locked' : 'open';

    if (access === 'open' && enrollment) {
      // Every open visit is recorded: it drives "recently accessed", resume and at-risk detection.
      await db.lessonProgress.upsert({
        where: { studentId_lessonId: { studentId, lessonId } },
        update: { lastAccessedAt: new Date() },
        create: { ...tenant(), studentId, lessonId, state: 'not-started', lastAccessedAt: new Date() },
      });
      await db.enrollment.update({ where: { id: enrollment.id }, data: { lastLessonId: lessonId, lastActiveAt: new Date() } });
      await db.student.update({ where: { id: studentId }, data: { lastActiveAt: new Date() } });
    }

    const note = await db.lessonNote.findUnique({ where: { studentId_lessonId: { studentId, lessonId } } });
    const bookmark = await db.lessonBookmark.findUnique({ where: { studentId_lessonId: { studentId, lessonId } } });

    // Anything but an open lesson returns its outline only — no body, quiz or assignment brief.
    if (access !== 'open') lesson = { ...lesson, content: {} as typeof lesson.content, settings: undefined };

    let quiz;
    let quizBest: number | undefined;
    let assignment;
    let live;
    if (access === 'open') {
      const [linkedQuiz, linkedAssignment] = await Promise.all([
        db.quiz.findUnique({ where: { lessonId } }),
        db.courseAssignment.findUnique({ where: { lessonId }, include: { course: true } }),
      ]);
      lesson = { ...lesson, content: mergeLinkedContent(lesson.content ?? {}, linkedQuiz, linkedAssignment) };
      if (lesson.type === 'assessment' && linkedQuiz && linkedQuiz.status === 'published') {
        const settings = readJson<QuizSettings>(linkedQuiz.settingsJson, {} as QuizSettings);
        const authored = readJson<QuizQuestion[]>(linkedQuiz.questionsJson, []);
        await settleOverdueQuizSessions({ quizId: linkedQuiz.id, studentId });
        const [attempts, sessions] = await Promise.all([
          db.quizAttempt.findMany({ where: { studentId, quizId: linkedQuiz.id }, select: { percent: true, passed: true, createdAt: true, sessionId: true } }),
          db.quizSession.findMany({ where: { studentId, quizId: linkedQuiz.id }, orderBy: { attemptNo: 'desc' } }),
        ]);
        const open = sessions.find((x) => x.status === 'active');
        const now = new Date();
        quiz = {
          id: linkedQuiz.id,
          courseId,
          chapterId: linkedQuiz.chapterId ?? undefined,
          lessonId,
          title: linkedQuiz.title,
          instructions: linkedQuiz.instructions,
          status: linkedQuiz.status,
          // The questions come with a session the server starts — `POST …/quiz-session` — so a time limit runs from
          // the moment they are first seen. Only a quiz with no limit and no window still lists them here, without
          // their key, for apps built before sessions; new screens start a session for every quiz.
          questions: takenInOneGo(settings) ? authored.map(learnerQuestion) : [],
          questionCount: authored.length,
          totalPoints: quizTotalPoints({ questions: authored }),
          // Said before the start, which uses an attempt: wrong answers here cost marks.
          negativeMarking: authored.some((q) => (q.negativePoints ?? 0) > 0),
          attemptsUsed: attemptsUsed(sessions, attempts),
          /** The attempt still open, to resume. */
          openSession: open ? sessionView(open, now) : undefined,
          window: quizWindow(settings, now),
          settings: { ...settings, showResults: resultsVisibilityOf(settings.showResults) },
          createdAt: linkedQuiz.createdAt.toISOString(),
          updatedAt: linkedQuiz.updatedAt.toISOString(),
        };
        quizBest = scoreShown(settings, now) ? creditedPercent(attempts) : undefined;
      }
      if ((lesson.type === 'assignment' || lesson.type === 'practice') && linkedAssignment && linkedAssignment.status !== 'draft') {
        assignment = await learnerAssignmentFor(studentId, linkedAssignment, enrollment?.enrolledAt);
      }
      const liveId = lesson.content?.live?.liveClassId;
      if (lesson.type === 'live' && liveId) {
        const liveRow = await db.liveClass.findUnique({ where: { id: liveId } });
        if (liveRow) live = forLearner(mapLive(liveRow));
      }
    }

    const nextLesson = flatIndex < flat.length - 1 ? flat[flatIndex + 1] : undefined;
    res.json({
      course,
      enrolled: !!enrollment,
      snapshot,
      progress,
      chapterIndex,
      lessonIndex,
      lesson,
      number: `${chapterIndex + 1}.${lessonIndex + 1}`,
      position: { index: flatIndex, total: flat.length },
      state,
      lessonProgress: snapshot.lessons[lessonId],
      access,
      lockedReason: access === 'locked' ? lockedReason(course, chapterIndex, lesson, snapshot) : expired ? 'Your access to this course has ended.' : undefined,
      previous: flatIndex > 0 ? { id: flat[flatIndex - 1].id, title: flat[flatIndex - 1].title } : undefined,
      next: nextLesson ? { id: nextLesson.id, title: nextLesson.title, locked: snapshot.lessons[nextLesson.id]?.state === 'locked' } : undefined,
      quiz,
      quizBest,
      assignment,
      live,
      instructorNames,
      note: note?.text ?? '',
      bookmarked: !!bookmark,
      threshold: rules.threshold,
    });
  }),
);

learningRouter.post(
  '/courses/:courseId/lessons/:lessonId/complete',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    const enrollment = await settleExpiry(await requireEnrollment(studentId, courseId));
    if (enrollment.status === 'expired') throw conflict('Your access to this course has ended.');
    const { course, rules } = await loadLearnerCourse(studentId, courseId);
    const located = locateLesson(course, lessonId);
    if (!located || located.lesson.status !== 'published') throw notFound('Lesson not found.');

    // The lesson's completion rule decides what "complete" needs.
    const rule = completionRuleOf(located.lesson);
    if (rule === 'passed') throw conflict('Pass the quiz to complete this lesson.');
    if (rule === 'submitted') {
      // An assignment lesson completes on hand-in; a practice exercise completes with written working (or a hand-in).
      const linked = await db.courseAssignment.findUnique({ where: { lessonId }, select: { id: true } });
      const submitted = linked ? await db.submission.findFirst({ where: { studentId, assignmentId: linked.id }, select: { id: true } }) : null;
      if (located.lesson.type === 'assignment') {
        if (!submitted) throw conflict('Submit the assignment to complete this lesson.');
      } else if (!submitted) {
        const note = await db.lessonNote.findUnique({ where: { studentId_lessonId: { studentId, lessonId } } });
        if ((note?.text.trim().length ?? 0) < 20) throw conflict('Write your working in the notes to complete the exercise.');
      }
    }
    if (rule === 'watched') {
      const row = await db.lessonProgress.findUnique({ where: { studentId_lessonId: { studentId, lessonId } } });
      const watched = (row?.fraction ?? 0) * 100;
      // A little slack because the player saves positions every few seconds.
      if (watched < rules.threshold - 10) throw conflict(`Watch at least ${rules.threshold}% of the lesson to complete it.`);
    }
    res.json(await completeLesson(studentId, course, lessonId, rules));
  }),
);

learningRouter.put(
  '/courses/:courseId/lessons/:lessonId/position',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    const { positionSec, fraction } = parseBody(req, z.object({ positionSec: z.number().min(0).max(10_000_000), fraction: z.number().min(0).max(1) }));
    const enrollment = await requireLessonAccess(studentId, courseId, lessonId);
    const rules = await learnerRules();
    const current = await db.lessonProgress.findUnique({ where: { studentId_lessonId: { studentId, lessonId } } });
    if (current?.state === 'completed') return res.status(204).end();

    const reached = fraction * 100 >= rules.threshold;
    const course = enrollment ? (await loadLearnerCourse(studentId, courseId, rules)).course : null;
    const lesson = course ? locateLesson(course, lessonId)?.lesson : undefined;
    const autoComplete = reached && !!enrollment && !!lesson && completionRuleOf(lesson) === 'watched';
    if (course && lesson && (await snapshotFor(course, studentId, rules.chapterGate)).lessons[lessonId]?.state === 'locked') return res.status(204).end();

    await db.lessonProgress.upsert({
      where: { studentId_lessonId: { studentId, lessonId } },
      update: {
        positionSec: Math.round(positionSec),
        fraction: Math.max(current?.fraction ?? 0, clampPercent(fraction * 100) / 100),
        state: autoComplete ? 'completed' : 'in-progress',
        lastAccessedAt: new Date(),
        ...(autoComplete ? { completedAt: new Date() } : {}),
      },
      create: {
        ...tenant(),
        studentId,
        lessonId,
        positionSec: Math.round(positionSec),
        fraction,
        state: autoComplete ? 'completed' : 'in-progress',
        lastAccessedAt: new Date(),
        ...(autoComplete ? { completedAt: new Date() } : {}),
      },
    });
    if (course) await syncEnrollment(studentId, course, await snapshotFor(course, studentId, rules.chapterGate), rules, lessonId);
    res.status(204).end();
  }),
);

learningRouter.put(
  '/courses/:courseId/lessons/:lessonId/note',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    await requireLessonAccess(studentId, courseId, lessonId);
    const { text } = parseBody(req, z.object({ text: z.string().max(20_000) }));
    const row = await db.lessonNote.upsert({
      where: { studentId_lessonId: { studentId, lessonId } },
      update: { text },
      create: { ...tenant(), studentId, lessonId, text },
    });
    res.json({ savedAt: row.savedAt.toISOString() });
  }),
);

learningRouter.post(
  '/courses/:courseId/lessons/:lessonId/bookmark',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    await requireLessonAccess(studentId, courseId, lessonId);
    const existing = await db.lessonBookmark.findUnique({ where: { studentId_lessonId: { studentId, lessonId } } });
    if (existing) {
      await db.lessonBookmark.delete({ where: { studentId_lessonId: { studentId, lessonId } } });
      return res.json({ bookmarked: false });
    }
    await db.lessonBookmark.create({ data: { ...tenant(), studentId, lessonId } });
    res.json({ bookmarked: true });
  }),
);

learningRouter.post(
  '/courses/:courseId/save',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId } = req.params;
    const course = await db.course.findFirst({ where: { id: courseId, status: 'published' }, select: { id: true } });
    if (!course) throw notFound('Course not found.');
    const existing = await db.savedCourse.findUnique({ where: { studentId_courseId: { studentId, courseId } } });
    if (existing) {
      await db.savedCourse.delete({ where: { studentId_courseId: { studentId, courseId } } });
      return res.json({ saved: false });
    }
    await db.savedCourse.create({ data: { ...tenant(), studentId, courseId } });
    res.json({ saved: true });
  }),
);

/* ─── Enrolment ───────────────────────────────────────────────────────── */

learningRouter.post(
  '/courses/:courseId/enroll',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId } = req.params;
    const rules = await selfEnrol(studentId, courseId);
    const { shape } = await learnerCourseShape(studentId, courseId, rules);
    res.json(shape);
  }),
);

/**
 * A learner enrolling themselves, in the current academy: refused unless the course is published and listed, the
 * learner is not suspended and the academy's enrolment policy is "open". Enrolling twice changes nothing.
 */
export async function selfEnrol(studentId: string, courseId: string) {
  const rules = await learnerRules();
  const existing = await db.enrollment.findUnique({ where: { studentId_courseId: { studentId, courseId } } });
  if (!existing) {
    const target = await db.course.findUnique({
      where: { id: courseId },
      select: { status: true, visibility: true, pricing: true, priceAmount: true, priceCurrency: true },
    });
    if (!target || target.status !== 'published' || target.visibility === 'private') throw notFound('Course not found.');
    // Only a free course is joined for nothing. A paid course is bought (lib/coursePurchases.ts); a course whose price
    // no admin chose, or a paid course without a valid price, is open to nobody until the academy decides.
    const sale = courseSale({
      pricing: target.pricing as CoursePricing,
      price: target.priceAmount != null ? { amount: target.priceAmount, currency: target.priceCurrency as 'INR' } : undefined,
    });
    if (sale.kind === 'paid') throw new ApiError(409, 'This is a paid course. Buy it to start learning.', undefined, 'COURSE_PURCHASE_REQUIRED');
    if (sale.kind === 'unavailable') throw new ApiError(409, 'This course isn’t open for enrolment yet. Contact support.', undefined, 'COURSE_NOT_FOR_SALE');
    const student = await db.student.findUnique({ where: { id: studentId }, select: { suspended: true } });
    if (student?.suspended) throw conflict('This account is suspended. Contact your admin to continue.');
    // The academy's enrolment policy: only "open" lets learners enrol themselves.
    if (rules.enrollmentPolicy === 'approval') throw conflict('Enrolment needs approval — ask an instructor or your admin to add you to the course.');
    if (rules.enrollmentPolicy === 'invite') throw conflict('Courses here are joined by invitation. Contact your admin to join the course.');
    await db.$transaction([
      // The course's row first: inserting the enrolment takes a shared lock on it, and learners who then all ask to upgrade
      // that lock to write the count would deadlock each other.
      db.course.update({ where: { id: courseId }, data: { enrolledCount: { increment: 1 } } }),
      db.enrollment.create({ data: { ...tenant(), studentId, courseId, source: 'self', expiresAt: expiryFor(new Date(), rules.accessMonths) } }),
    ]);
    await confirmEnrolment(studentId, courseId, 'self');
  }
  return rules;
}

/** The enrolment confirmation every learner gets (subject to the academy switch and their preferences). */
export async function confirmEnrolment(studentId: string, courseId: string, source: string) {
  const [student, course] = await Promise.all([
    db.student.findUnique({ where: { id: studentId }, select: { userId: true } }),
    db.course.findUnique({ where: { id: courseId }, include: { instructors: { include: { instructor: { select: { name: true } } } } } }),
  ]);
  if (!student || !course) return;
  const lessons = await db.lesson.count({ where: { courseId, status: 'published' } });
  await notify({
    recipientUserId: student.userId,
    category: 'enrollment',
    title: `You're enrolled in ${course.title}`,
    summary:
      source === 'self'
        ? `Your place is confirmed — ${lessons} lessons are waiting. Start with lesson 1.1 whenever you are ready.`
        : `Your admin added you to this course — ${lessons} lessons are waiting.`,
    facts: [
      { label: 'Course', value: course.title },
      ...(course.instructors.length ? [{ label: 'Instructors', value: course.instructors.map((i) => i.instructor.name).join(', ') }] : []),
    ],
    action: { label: 'Start the course', to: `/learn/${courseId}` },
    switch: 'learner.enrolmentConfirmation',
  });
}

/* ─── Assignments ─────────────────────────────────────────────────────── */

const draftSchema = z.object({
  text: z.string().max(50_000).default(''),
  files: z
    .array(
      z
        .object({
          id: idSchema.optional(),
          name: z.string().max(200),
          sizeMb: z.number().min(0).max(1000),
          url: z.string().max(300).optional(),
          mime: z.string().max(100).optional(),
        })
        .passthrough(),
    )
    .max(20)
    .default([]),
  chart: z
    .object({
      label: z.string().max(120),
      date: z.string().max(20),
      time: z.string().max(20),
      place: z.string().max(120),
      lagna: z.string().max(40),
      moonSign: z.string().max(40),
      nakshatra: z.string().max(40),
    })
    .optional(),
});

/**
 * The files a hand-in names, resolved against the media the learner uploaded. A file that is not the
 * learner's own upload in this academy is refused, and the name and size are read from the stored file
 * rather than taken from the request.
 */
async function ownFiles(userId: string, files: { id?: string }[]): Promise<Attachment[]> {
  const ids = files.map((f) => f.id).filter((id): id is string => !!id);
  if (ids.length !== files.length) throw conflict('Upload each file before adding it to your work.');
  const rows = await db.mediaAsset.findMany({ where: { id: { in: ids }, ownerUserId: userId, kind: { in: ['document', 'image'] } } });
  const byId = new Map(rows.map((r) => [r.id, r]));
  return ids.map((id) => {
    const row = byId.get(id);
    if (!row) throw conflict('One of the files is not an upload of yours. Upload it again.');
    return { id: row.id, name: row.originalName, sizeMb: Math.max(0.1, Math.round((row.sizeBytes / 1_048_576) * 10) / 10) };
  });
}

async function enrolledAssignment(studentId: string, assignmentId: string) {
  const a = await db.courseAssignment.findUnique({ where: { id: assignmentId }, include: { course: true } });
  if (!a || a.status === 'draft') throw notFound('Assignment not found.');
  const enrollment = await settleExpiry(await requireEnrollment(studentId, a.courseId));
  return { a, enrollment };
}

learningRouter.get(
  '/assignments',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const enrollments = await db.enrollment.findMany({ where: { studentId } });
    const assignments = await db.courseAssignment.findMany({
      where: { courseId: { in: enrollments.map((e) => e.courseId) }, status: { not: 'draft' } },
      include: { course: true },
    });
    const rows = await Promise.all(assignments.map((a) => learnerAssignmentFor(studentId, a, enrollments.find((e) => e.courseId === a.courseId)?.enrolledAt)));
    rows.sort((x, y) => (x.dueAt ?? '9').localeCompare(y.dueAt ?? '9'));
    res.json(rows);
  }),
);

learningRouter.get(
  '/assignments/:assignmentId',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { a, enrollment } = await enrolledAssignment(studentId, req.params.assignmentId);
    res.json(await learnerAssignmentFor(studentId, a, enrollment.enrolledAt));
  }),
);

learningRouter.put(
  '/assignments/:assignmentId/draft',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { a } = await enrolledAssignment(studentId, req.params.assignmentId);
    const draft = parseBody(req, draftSchema);
    const files = await ownFiles(req.auth!.sub, draft.files);
    const row = await db.assignmentDraft.upsert({
      where: { studentId_assignmentId: { studentId, assignmentId: a.id } },
      update: { text: draft.text, filesJson: writeJson(files), chartJson: draft.chart ? writeJson(draft.chart) : null },
      create: {
        ...tenant(),
        studentId,
        assignmentId: a.id,
        text: draft.text,
        filesJson: writeJson(files),
        chartJson: draft.chart ? writeJson(draft.chart) : null,
      },
    });
    res.json({ savedAt: row.savedAt.toISOString() });
  }),
);

learningRouter.post(
  '/assignments/:assignmentId/submit',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { a, enrollment } = await enrolledAssignment(studentId, req.params.assignmentId);
    if (enrollment.status === 'expired') throw conflict('Your access to this course has ended.');
    if (a.status === 'closed') throw conflict('This assignment is closed to new submissions.');
    const draft = parseBody(req, draftSchema);
    if (!draft.text.trim() && !draft.files.length && !draft.chart) throw conflict('Add your work before submitting.');
    const issues = validateSubmission({ format: a.format as 'text' | 'file' | 'chart', wordLimit: a.wordLimit ?? undefined }, draft);
    if (issues.length) throw conflict(issues[0].message, issues);
    const files = await ownFiles(req.auth!.sub, draft.files);

    const latest = await db.submission.findFirst({ where: { studentId, assignmentId: a.id }, orderBy: { attempt: 'desc' } });
    if (latest && latest.reviewStatus !== 'returned') throw conflict('This assignment has already been submitted.');
    const dueAt = await dueAtFor(a, studentId, enrollment.enrolledAt);
    const late = !!dueAt && new Date() > new Date(dueAt);
    // The academy's late policy wins over the assignment's own setting when it rejects late work.
    const { learning: learningSettings } = await getSettings();
    if (late && (learningSettings.latePolicy === 'reject' || !a.acceptsLate)) throw conflict('The deadline for this assignment has passed.');

    const row = await db.submission.create({
      data: {
        ...tenant(),
        assignmentId: a.id,
        studentId,
        attempt: (latest?.attempt ?? 0) + 1,
        late,
        text: draft.text || null,
        filesJson: writeJson(files),
        chartJson: draft.chart ? writeJson(draft.chart) : null,
        reviewStatus: 'waiting',
      },
    });
    await db.assignmentDraft.deleteMany({ where: { studentId, assignmentId: a.id } });

    // A lesson that completes on hand-in is done now.
    if (a.lessonId) {
      const { course, rules } = await loadLearnerCourse(studentId, a.courseId);
      const lesson = locateLesson(course, a.lessonId)?.lesson;
      if (lesson && completionRuleOf(lesson) === 'submitted') await completeLesson(studentId, course, a.lessonId, rules).catch(() => undefined);
    }
    await db.enrollment.update({ where: { id: enrollment.id }, data: { lastActiveAt: new Date() } });

    // Tell the course's instructors there is work to review.
    const student = await db.student.findUnique({ where: { id: studentId }, include: { user: { select: { name: true } } } });
    await notifyMany(await instructorUserIdsFor(a.courseId), {
      category: 'assignment',
      title: `${student?.user.name ?? 'A learner'} submitted “${a.title}”`,
      summary: `${a.course.title} · attempt ${row.attempt}${late ? ' · late' : ''}. It is waiting in your review queue.`,
      actor: student?.user.name,
      facts: [
        { label: 'Course', value: a.course.title },
        { label: 'Submitted', value: row.submittedAt.toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' }) },
      ],
      action: { label: 'Open the review', to: `/teach/assignments/${a.id}/submissions/${row.id}` },
      switch: 'staff.newSubmission',
    });
    res.json(await learnerAssignmentFor(studentId, a, enrollment.enrolledAt));
  }),
);

/* ─── Quizzes ─────────────────────────────────────────────────────────── */

learningRouter.get(
  '/assessments',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const rules = await learnerRules();
    const enrollments = await db.enrollment.findMany({ where: { studentId } });
    const now = new Date();
    const out: unknown[] = [];
    for (const e of enrollments) {
      const loaded = await loadLearnerCourse(studentId, e.courseId, rules).catch(() => null);
      if (!loaded) continue;
      const { course, snapshot } = loaded;
      for (const { lesson, chapterIndex } of publishedLessons(course).filter((x) => x.lesson.type === 'assessment')) {
        const quiz = await db.quiz.findUnique({ where: { lessonId: lesson.id } });
        if (!quiz || quiz.status !== 'published') continue;
        const settings = readJson<QuizSettings>(quiz.settingsJson, { passMark: 70, attempts: 0 } as QuizSettings);
        await settleOverdueQuizSessions({ quizId: quiz.id, studentId });
        const [attempts, sessions] = await Promise.all([
          db.quizAttempt.findMany({ where: { studentId, quizId: quiz.id }, orderBy: { createdAt: 'desc' } }),
          db.quizSession.findMany({ where: { studentId, quizId: quiz.id }, select: { status: true, deadlineAt: true } }),
        ]);
        const p = snapshot.lessons[lesson.id];
        const open = sessions.find((x) => x.status === 'active');
        // An attempt under way comes first — a practice retake after a pass included — so the list offers to resume it.
        const state = open
          ? 'in-progress'
          : p?.state === 'completed' || attempts.some((a) => a.passed)
            ? 'passed'
            : p?.state === 'locked'
              ? 'locked'
              : attempts.length
                ? 'failed'
                : 'available';
        out.push({
          id: quiz.id,
          lessonId: lesson.id,
          courseId: course.id,
          courseTitle: course.title,
          title: quiz.title,
          questions: readJson<unknown[]>(quiz.questionsJson, []).length,
          durationMin: settings.timeLimitMin ?? lesson.durationMin,
          passMark: settings.passMark,
          attemptsAllowed: settings.attempts ?? rules.quizAttempts,
          attemptsUsed: attemptsUsed(sessions, attempts),
          // Once passed, further attempts are practice and not limited.
          passed: attempts.some((a) => a.passed),
          state,
          lockedReason: state === 'locked' ? lockedReason(course, chapterIndex, lesson, snapshot) : undefined,
          score: scoreShown(settings, now) ? creditedPercent(attempts) : undefined,
          ...(!resultsOut(settings, now) && settings.closesAt ? { resultsAt: settings.closesAt } : {}),
          negativeMarking: readJson<QuizQuestion[]>(quiz.questionsJson, []).some((q) => (q.negativePoints ?? 0) > 0),
          window: quizWindow(settings, now),
          ...(settings.opensAt ? { opensAt: settings.opensAt } : {}),
          ...(settings.closesAt ? { closesAt: settings.closesAt } : {}),
          ...(open?.deadlineAt ? { deadlineAt: open.deadlineAt.toISOString() } : {}),
        });
      }
    }
    const order = ['available', 'in-progress', 'failed', 'locked', 'passed', 'submitted'];
    res.json((out as { state: string }[]).sort((a, b) => order.indexOf(a.state) - order.indexOf(b.state)));
  }),
);

/* ─── Quiz sessions ────────────────────────────────────────────────────
 * A quiz is taken through a session the server starts, keeps and finishes — `lib/quizSessions.ts`. The questions
 * come with the session, the deadline is the server's, and answers count only once the server has accepted them,
 * before that deadline. Ported from the Classplus track (A2) so both branches keep one design and one migration. */

const ENROLMENT_PAUSED = 'Your place in this course is paused. Contact support to continue.';

/** Starting or answering needs the learner's place in the course open: not expired, not paused by staff. */
function assertLearningOpen(enrollment: { status: string }) {
  if (enrollment.status === 'expired') throw new ApiError(409, 'Your access to this course has ended.', undefined, 'ENROLLMENT_EXPIRED');
  if (enrollment.status === 'paused') throw new ApiError(409, ENROLMENT_PAUSED, undefined, 'ENROLLMENT_PAUSED');
}

/**
 * The quiz an assessment lesson delivers, for an enrolled learner. `starting` adds the checks a new attempt needs —
 * the quiz published, the lesson unlocked. An attempt already under way carries on with the questions it started on,
 * even if the quiz was unpublished or archived since; a draft quiz no lesson has delivered is not found.
 */
async function lessonQuiz(studentId: string, courseId: string, lessonId: string, opts: { starting?: boolean; answering?: boolean } = {}) {
  const enrollment = await settleExpiry(await requireEnrollment(studentId, courseId));
  if (opts.starting || opts.answering) assertLearningOpen(enrollment);
  const { course, rules, snapshot } = await loadLearnerCourse(studentId, courseId);
  const located = locateLesson(course, lessonId);
  if (!located || located.lesson.status !== 'published') throw notFound('Lesson not found.');
  if (opts.starting && snapshot.lessons[lessonId]?.state === 'locked') throw conflict(lockedReason(course, located.chapterIndex, located.lesson, snapshot));
  const quiz = await db.quiz.findUnique({ where: { lessonId } });
  if (!quiz || quiz.courseId !== courseId) throw notFound('This quiz is not available yet.');
  if (opts.starting && quiz.status !== 'published') throw notFound('This quiz is not available yet.');
  if (!opts.starting && quiz.status === 'draft' && !(await db.quizSession.count({ where: { quizId: quiz.id, studentId } }))) {
    throw notFound('This quiz is not available yet.');
  }
  return { enrollment, course, rules, snapshot, quiz };
}

/** What finishing an attempt means for the lesson: completed on a first pass, as a completed lesson always did. */
async function completionAfter(studentId: string, courseId: string, lessonId: string, finished: Finished) {
  if (!finished.attempt.passed) return null;
  const { course, rules, snapshot } = await loadLearnerCourse(studentId, courseId);
  if (finished.finishedNow && snapshot.lessons[lessonId]?.state !== 'completed') {
    try {
      return await completeLesson(studentId, course, lessonId, rules);
    } catch {
      // A lesson locked since the attempt started stays as it is; the attempt is still recorded.
    }
  }
  return {
    snapshot,
    progress: progressOf(course, snapshot),
    courseCompleted: isCourseComplete(course, snapshot, rules),
    nextLessonId: nextLessonFor(course, snapshot)?.id,
  };
}

/**
 * Finishes the open sessions matched by `where` that are past their deadline and grace, and completes the lesson of
 * any that passed. Run before a learner's quiz is read, and every minute by the scheduler for every academy.
 */
export async function settleOverdueQuizSessions(where: { quizId?: string; studentId?: string } = {}, now = new Date()) {
  const finished = await finishOverdue(where, now);
  for (const f of finished) {
    if (!f.attempt.passed) continue;
    const quiz = await db.quiz.findUnique({ where: { id: f.row.quizId }, select: { courseId: true, lessonId: true } });
    if (quiz?.lessonId) await completionAfter(f.row.studentId, quiz.courseId, quiz.lessonId, f).catch(() => undefined);
  }
  return finished.length;
}

type QuizRow = NonNullable<Awaited<ReturnType<typeof db.quiz.findUnique>>>;

/**
 * Where the learner stands with a quiz, and their submitted attempts cut to what they may see:
 * - the key (right answers, explanations) only once the quiz can no longer be taken for credit — passed, or every
 *   attempt used — and never while an attempt is open: one failed attempt must not hand the answers to the next;
 * - nothing but "received" while `resultsRelease: after-close` holds results until the quiz closes.
 * `canStart` repeats the start's own checks without starting anything; the start still decides.
 */
async function quizStanding(
  studentId: string,
  quiz: QuizRow,
  rules: LearnerRules,
  enrollment: { status: string },
  now = new Date(),
): Promise<{ attempts: AttemptReview[]; standing: QuizStanding }> {
  const questions = readJson<QuizQuestion[]>(quiz.questionsJson, []);
  const settings = readJson<QuizSettings>(quiz.settingsJson, {} as QuizSettings);
  const [attempts, sessions] = await Promise.all([
    db.quizAttempt.findMany({ where: { studentId, quizId: quiz.id }, orderBy: { createdAt: 'desc' } }),
    db.quizSession.findMany({ where: { studentId, quizId: quiz.id }, orderBy: { attemptNo: 'desc' } }),
  ]);
  const limit = settings.attempts ?? rules.quizAttempts;
  const used = attemptsUsed(sessions, attempts);
  const passed = attempts.some((a) => a.passed);
  const open = sessions.find((x) => x.status === 'active');
  const window = quizWindow(settings, now);
  const out = resultsOut(settings, now);

  let blockedReason: string | undefined;
  // A paused or ended place refuses a resume as much as a new start.
  if (enrollment.status === 'expired') blockedReason = 'Your access to this course has ended.';
  else if (enrollment.status === 'paused') blockedReason = ENROLMENT_PAUSED;
  else if (!open) {
    if (quiz.status !== 'published') blockedReason = 'This quiz is no longer open for attempts.';
    else if (window === 'upcoming') blockedReason = 'This quiz has not opened yet.';
    else if (window === 'closed') blockedReason = 'This quiz has closed.';
    else if (!questions.length) blockedReason = 'This quiz has no questions yet.';
    else if (!passed && limit > 0 && used >= limit) blockedReason = `You have used all ${limit} attempts for this quiz.`;
    else if (!passed && attempts[0] && rules.retakeWaitHours > 0) {
      const readyAt = attempts[0].createdAt.getTime() + rules.retakeWaitHours * 3_600_000;
      if (now.getTime() < readyAt) {
        const hours = Math.ceil((readyAt - now.getTime()) / 3_600_000);
        blockedReason = `You can try this quiz again in ${hours} hour${hours === 1 ? '' : 's'}.`;
      }
    }
  }

  const keyWithheld = Boolean(open) || (!passed && (limit === 0 || used < limit) && window !== 'closed' && quiz.status === 'published');
  const shown: QuizSettings = !out
    ? { ...settings, showResults: 'hidden' }
    : keyWithheld && resultsVisibilityOf(settings.showResults) === 'score-and-answers'
      ? { ...settings, showResults: 'score-only' }
      : settings;
  const bySession = new Map(sessions.map((x) => [x.id, x]));
  // Attempts made before sessions were numbered in the order they were made; a session's number counts them too.
  const legacy = attempts.filter((a) => !a.sessionId).sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
  const reviews = attempts.map((a) => {
    const session = a.sessionId ? bySession.get(a.sessionId) : undefined;
    // An attempt made in a session is reviewed against the questions and pass mark it was scored with, not the quiz as
    // edited since.
    const scoredWith = session ? readJson<Partial<QuizSettings>>(session.settingsJson, {}) : {};
    const review = reviewAttempt(
      {
        questions: session ? readJson<QuizQuestion[]>(session.questionsJson, questions) : questions,
        settings: { ...shown, ...(scoredWith.passMark !== undefined ? { passMark: scoredWith.passMark } : {}) },
      },
      {
        id: a.id,
        submittedAt: a.createdAt.toISOString(),
        // The row's own score fills in whatever a stored result lacks — sample data stored `{}`.
        result: { points: 0, max: 0, percent: a.percent, passed: a.passed, questions: {}, ...readJson<Partial<AttemptResult>>(a.resultJson, {}) },
        answers: readJson<QuizAnswers>(a.answersJson, {}),
      },
    );
    return {
      ...review,
      attemptNo: session?.attemptNo ?? legacy.indexOf(a) + 1,
      finish: session?.status === 'expired' ? ('expired' as const) : ('submitted' as const),
      ...(keyWithheld && out && resultsVisibilityOf(settings.showResults) === 'score-and-answers' ? { keyWithheld: true } : {}),
      ...(!out && settings.closesAt ? { resultsAt: settings.closesAt } : {}),
    };
  });
  return {
    attempts: reviews,
    standing: {
      quizId: quiz.id,
      serverNow: now.toISOString(),
      window,
      ...(settings.opensAt ? { opensAt: settings.opensAt } : {}),
      ...(settings.closesAt ? { closesAt: settings.closesAt } : {}),
      attemptsAllowed: limit,
      attemptsUsed: used,
      passed,
      ...(open ? { openSession: sessionView(open, now) } : {}),
      canStart: !blockedReason,
      ...(blockedReason ? { blockedReason } : {}),
      ...(!out && settings.closesAt ? { resultsAt: settings.closesAt } : {}),
    },
  };
}

/** A quiz an app built before quiz sessions can still take in one request: no time limit and no window to keep. */
const takenInOneGo = (settings: QuizSettings) => !settings.timeLimitMin && !settings.opensAt && !settings.closesAt;

const attemptSchema = z.object({
  answers: z.record(z.string(), z.union([z.string().max(2000), z.array(z.string().max(200)).max(50)])),
  /** Sent by older apps; the server measures time itself and ignores it. */
  durationSec: z.number().int().min(0).max(86_400).optional(),
});

/**
 * The submit of an app built before quiz sessions: the answers it held since the lesson opened. An untimed quiz with
 * no window is taken as a session started and handed in at once — counted, limited and scored like any other. A
 * timed one cannot be: the app is told to update. Answers `null` when not passed, else the lesson's completion.
 */
learningRouter.post(
  '/courses/:courseId/lessons/:lessonId/quiz-attempt',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    // A learner outside the course is told nothing about its quizzes, before the body is even read.
    const { enrollment, rules, quiz } = await lessonQuiz(studentId, courseId, lessonId, { starting: true });
    const { answers } = parseBody(req, attemptSchema);
    if (!takenInOneGo(readJson<QuizSettings>(quiz.settingsJson, {} as QuizSettings))) {
      throw new ApiError(
        409,
        'This quiz is timed on the server. Update the app — or open the course on the web — to take it.',
        undefined,
        'QUIZ_SESSION_REQUIRED',
      );
    }
    await settleOverdueQuizSessions({ quizId: quiz.id, studentId });
    const { row } = await startSession({ quiz, studentId, enrollmentId: enrollment.id, rules });
    const finished = await finishSession(row.id, 'submit', { answers: answers as QuizAnswers, seq: row.answersSeq + 1 });
    res.json(await completionAfter(studentId, courseId, lessonId, finished));
  }),
);

const sessionStartSchema = z.object({
  /** The client's key for this start: retrying it answers with the same session. */
  startKey: z.string().trim().min(8).max(100).optional(),
});

/** Starts the learner's next attempt — or picks up the one still open — and only now sends the questions. */
learningRouter.post(
  '/courses/:courseId/lessons/:lessonId/quiz-session',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    const { startKey } = parseBody(req, sessionStartSchema);
    const { enrollment, rules, quiz } = await lessonQuiz(studentId, courseId, lessonId, { starting: true });
    await settleOverdueQuizSessions({ quizId: quiz.id, studentId });
    const { row, resumed } = await startSession({ quiz, studentId, enrollmentId: enrollment.id, rules, startKey });
    const body: QuizSessionStart = { session: sessionView(row), questions: row.status === 'active' ? sessionQuestions(row) : [], resumed };
    res.status(resumed ? 200 : 201).json(body);
  }),
);

/** The learner's latest attempt at the quiz: the open one with its questions, a finished one without, or none. */
learningRouter.get(
  '/courses/:courseId/lessons/:lessonId/quiz-session',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    const { quiz } = await lessonQuiz(studentId, courseId, lessonId);
    await settleOverdueQuizSessions({ quizId: quiz.id, studentId });
    const row = await latestSession(quiz.id, studentId);
    res.json({ session: row ? sessionView(row) : null, questions: row?.status === 'active' ? sessionQuestions(row) : [] });
  }),
);

const sheetSchema = z.object({
  answers: z.record(z.string(), z.union([z.string().max(2000), z.array(z.string().max(200)).max(50)])),
  /** Grows with every save: a sheet numbered no higher than the stored one arrived late and changes nothing. */
  seq: z.number().int().min(1).max(1_000_000_000),
});

/** Autosave: the learner's whole answer sheet, taken only before the deadline. */
learningRouter.put(
  '/courses/:courseId/lessons/:lessonId/quiz-session/:sessionId/answers',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId, sessionId } = req.params;
    const { answers, seq } = parseBody(req, sheetSchema);
    const { quiz } = await lessonQuiz(studentId, courseId, lessonId, { answering: true });
    const row = await ownSession(sessionId, quiz.id, studentId);
    res.json(sessionView(await saveAnswers(row, answers as QuizAnswers, seq)));
  }),
);

const submitSchema = z
  .object({
    /** A final sheet: taken only if it arrives by the deadline. In the grace after it, only stored answers count. */
    answers: sheetSchema.shape.answers.optional(),
    seq: sheetSchema.shape.seq.optional(),
  })
  // A sheet without its number could not be ordered against the autosaves, so it would be dropped without a word.
  .refine((b) => (b.answers === undefined) === (b.seq === undefined), { message: 'Send the answers with their save number.', path: ['seq'] });

/**
 * Hands the attempt in. Safe to repeat: a finished attempt answers with its result again. Answers `{ session,
 * completion, answersAccepted, review, standing }` — `completion` as completing a lesson does on a pass, `null`
 * otherwise; `review` the attempt as the learner may see it.
 */
learningRouter.post(
  '/courses/:courseId/lessons/:lessonId/quiz-session/:sessionId/submit',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId, sessionId } = req.params;
    const { answers, seq } = parseBody(req, submitSchema);
    // A final sheet is an answer: like an autosave, it is not taken once the learner's access has ended.
    const { quiz, rules, enrollment } = await lessonQuiz(studentId, courseId, lessonId, { answering: Boolean(answers) });
    await ownSession(sessionId, quiz.id, studentId);
    const finished = await finishSession(sessionId, 'submit', answers && seq ? { answers: answers as QuizAnswers, seq } : undefined);
    const completion = await completionAfter(studentId, courseId, lessonId, finished);
    const { attempts, standing } = await quizStanding(studentId, quiz, rules, enrollment);
    res.json({
      session: { ...sessionView(finished.row), attemptId: finished.attempt.id },
      completion,
      answersAccepted: finished.answersAccepted,
      review: attempts.find((a) => a.attemptId === finished.attempt.id) ?? null,
      standing,
    });
  }),
);

/**
 * The learner's own attempts at a lesson's quiz, newest first, each cut to what they may see (`quizStanding`), and
 * where they stand: attempts used and allowed, the window, an attempt open to resume, whether they can start.
 */
learningRouter.get(
  '/courses/:courseId/lessons/:lessonId/quiz-attempts',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const { courseId, lessonId } = req.params;
    const { quiz, rules, enrollment } = await lessonQuiz(studentId, courseId, lessonId);
    await settleOverdueQuizSessions({ quizId: quiz.id, studentId });
    res.json(await quizStanding(studentId, quiz, rules, enrollment));
  }),
);

/* ─── Certificates (learner wallet; creation rules live in the certificates module) ─── */

learningRouter.get(
  '/certificates',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const certs = await db.issuedCertificate.findMany({ where: { studentId }, include: { course: { include: { level: true } }, template: true } });
    const student = await db.student.findUnique({ where: { id: studentId }, include: { user: true } });
    const issuer = (await getSettings()).general.academyName;
    res.json({
      issued: certs.filter((c) => c.status === 'issued').map((c) => detailShape(c, student!, issuer)),
      pending: certs.filter((c) => c.status === 'pending').map((c) => detailShape(c, student!, issuer)),
      working: await workingTowards(studentId),
    });
  }),
);

function detailShape(
  c: {
    id: string;
    credentialId: string;
    studentId: string;
    courseId: string;
    title: string;
    templateId: string;
    status: string;
    completedAt: Date;
    issuedAt: Date | null;
    finalScore: number | null;
    hours: number;
    verifications: number;
    course: { title: string; level: { name: string } };
    template: {
      id: string;
      name: string;
      style: string;
      accent: string;
      heading: string;
      statement: string;
      signatoriesJson: string;
      showScore: boolean;
      showHours: boolean;
      isDefault: boolean;
      updatedAt: Date;
    };
  },
  student: { user: { name: string; email: string }; city: string },
  issuer: string,
) {
  return {
    // The platform that issued it, by its own name — never the platform's or another Admin's (multi-admin SaaS).
    issuer,
    certificate: {
      id: c.id,
      credentialId: c.credentialId,
      studentId: c.studentId,
      courseId: c.courseId,
      title: c.title,
      templateId: c.templateId,
      status: c.status,
      completedAt: c.completedAt.toISOString(),
      issuedAt: c.issuedAt?.toISOString(),
      finalScore: c.finalScore ?? undefined,
      hours: c.hours,
      verifications: c.verifications,
    },
    student: { id: c.studentId, name: student.user.name, email: student.user.email, city: student.city },
    courseTitle: c.course.title,
    levelTitle: c.course.level.name,
    template: {
      id: c.template.id,
      name: c.template.name,
      style: c.template.style,
      accent: c.template.accent,
      heading: c.template.heading,
      statement: c.template.statement,
      signatories: readJson(c.template.signatoriesJson, []),
      showScore: c.template.showScore,
      showHours: c.template.showHours,
      isDefault: c.template.isDefault,
      updatedAt: c.template.updatedAt.toISOString(),
    },
    verifyUrl: `/verify/${c.credentialId}`,
  };
}

learningRouter.get(
  '/certificates/:id',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const row = await db.issuedCertificate.findFirst({
      where: { id: req.params.id, studentId },
      include: { course: { include: { level: true } }, template: true },
    });
    if (!row) throw notFound('Certificate not found.');
    const student = await db.student.findUnique({ where: { id: studentId }, include: { user: true } });
    res.json(detailShape(row, student!, (await getSettings()).general.academyName));
  }),
);

learningRouter.post(
  '/certificates/:id/claim',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    // A learner can only claim a certificate the academy already marked pending for them.
    const pending = await db.issuedCertificate.findFirst({ where: { id: req.params.id, studentId, status: 'pending' }, select: { id: true } });
    if (!pending) throw notFound('Certificate not found.');
    const row = await db.issuedCertificate.update({
      where: { id: pending.id },
      data: { status: 'issued', issuedAt: new Date() },
      include: { course: { include: { level: true } }, template: true },
    });
    const student = await db.student.findUnique({ where: { id: studentId }, include: { user: true } });
    res.json(detailShape(row, student!, (await getSettings()).general.academyName));
  }),
);

/* ─── Rank & activity ─────────────────────────────────────────────────── */

learningRouter.get(
  '/rank-ladder',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const [ranks, student] = await Promise.all([db.rank.findMany({ orderBy: { order: 'asc' } }), db.student.findUnique({ where: { id: studentId } })]);
    const mapped = ranks.map((r) => ({ id: r.id, title: r.title, order: r.order, descriptor: r.descriptor, criteria: readJson(r.criteriaJson, []) }));
    const standing = { rankId: student?.rankId ?? mapped[0]?.id ?? '', achieved: {}, progress: {} };
    res.json({ ranks: mapped, standing });
  }),
);

learningRouter.get(
  '/activity',
  requireAuth,
  asyncHandler(async (req, res) => {
    const studentId = await studentIdOf(req);
    const enrollments = await db.enrollment.findMany({ where: { studentId }, include: { course: true } });
    const events: LearningEvent[] = enrollments.map((e) => ({
      id: `enr-${e.id}`,
      kind: 'enrolled',
      title: `Enrolled in ${e.course.title}`,
      at: e.enrolledAt.toISOString(),
    }));
    const completions = await db.lessonProgress.findMany({ where: { studentId, state: 'completed', completedAt: { not: null } }, include: { lesson: true } });
    for (const c of completions) events.push({ id: `lp-${c.id}`, kind: 'lesson-completed', title: c.lesson.title, at: c.completedAt!.toISOString() });
    const attempts = await db.quizAttempt.findMany({ where: { studentId, passed: true }, include: { quiz: true } });
    for (const a of attempts) events.push({ id: `qa-${a.id}`, kind: 'assessment-passed', title: a.quiz.title, at: a.createdAt.toISOString() });
    const submissions = await db.submission.findMany({ where: { studentId }, include: { assignment: true } });
    for (const s of submissions) events.push({ id: `sub-${s.id}`, kind: 'assignment-submitted', title: s.assignment.title, at: s.submittedAt.toISOString() });
    events.sort((a, b) => b.at.localeCompare(a.at));
    const week = studyDays(await progressRowsFor(studentId), 7);
    res.json({ week, events: events.slice(0, 30) });
  }),
);

export { applyLocks };
