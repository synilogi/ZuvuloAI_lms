import type { Course, CourseProgressSnapshot, Enrollment, Lesson, LiveClass, Quiz, Submission } from '@syniastrolms/domain';
import {
  courseProgress,
  courseSale,
  deriveLiveClassPhase,
  effectiveAssignmentState,
  learnerQuiz,
  quizTotalPoints,
  quizWindow,
  resultsOut,
  resultsVisibilityOf,
} from '@syniastrolms/domain';
import type {
  CompletionResult,
  LearnerAssessment,
  LearnerAssignment,
  LearnerCourse,
  LearningHome,
  LearningService,
  LessonQuiz,
  LessonView,
  NextLesson,
} from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { certificateDetail, issue as issueCertificate } from './certificates';
import { issuedCertificates } from './fixtures/certificates';
import { mockNow, mockNowIso } from './clock';
import { mockLearningRules } from './settings';
import { courseAssignments, submissions } from './fixtures/assignments';
import { courses, instructors, levels } from './fixtures/catalog';
import { assignments as learnerAssignmentFixtures, certificates, foundationsProgress, liveClasses, personas, studyWeek } from './fixtures/learner';
import { enrollments, students } from './fixtures/people';
import { quizzes } from './fixtures/quizzes';
import { complete } from './lessons';
import { learnerLiveClass } from './liveLearner';
import { ownMockReview, saveMockReview } from './reviews';
import {
  ENROLMENT_PAUSED,
  latestSession,
  learnerQuizState,
  onQuizPassed,
  quizStanding,
  saveAnswers,
  sessionView,
  settleOverdue,
  startSession,
  submitSession,
} from './quizSessions';
import { confirmMockPurchase, listMockPurchases, mockPurchaseStatus, quoteMockPurchase, startMockPurchase } from './coursePurchases';
import { DAY_MS, createRandom, hashSeed } from './random';
import { respond, scenario } from './simulation';

/** The signed-in learner in the demo. */
const ME = personas.student.id;

const courseById = (id: string) => courses.find((c) => c.id === id);
const mine = () => enrollments.filter((e) => e.studentId === ME);
const published = (course: Course) =>
  course.chapters.flatMap((c, chapterIndex) =>
    c.lessons.filter((l) => l.status === 'published').map((lesson, lessonIndex) => ({ lesson, chapterIndex, lessonIndex })),
  );

/* ─── Progress state ───────────────────────────────────────────────────── */

const snapshots = new Map<string, CourseProgressSnapshot>([[foundationsProgress.courseId, foundationsProgress]]);
const notes = new Map<string, string>([
  ['foundations-vedic:m3-l5', 'Kendra lords that also own trikonas become yogakarakas — check Saturn for Taurus and Libra lagna.'],
]);
const bookmarks = new Set<string>(['foundations-vedic:m2-l6']);
const saved = new Set<string>(['nakshatra-depth', 'dasha']);
/** Best scores from before this visit's attempts — the demo's history. Attempts made here are kept by `quizSessions`. */
const quizBest = new Map<string, number>([['m1-l5', 92]]);
const drafts = new Map<string, NonNullable<LearnerAssignment['draft']>>([
  ['a-navagraha', { text: 'Sun in Scorpio in the 4th — own dignity is neutral here; Moon in Taurus (exalted) in the 10th…', files: [] }],
]);

/**
 * Chapters open in order: a chapter unlocks when the one before it is finished, not counting
 * assignments (they wait on review). A chapter's quiz unlocks once its other lessons are done.
 */
function applyLocks(course: Course, snap: CourseProgressSnapshot) {
  const done = (l: Lesson) => snap.lessons[l.id]?.state === 'completed';
  course.chapters.forEach((chapter, i) => {
    const previous = course.chapters[i - 1];
    const chapterOpen = !previous || previous.lessons.filter((l) => l.status === 'published' && l.type !== 'assignment').every(done);
    for (const lesson of chapter.lessons.filter((l) => l.status === 'published')) {
      const p = snap.lessons[lesson.id];
      if (p && p.state !== 'locked' && p.state !== 'not-started') continue;
      const quizWaiting =
        lesson.type === 'assessment' &&
        chapter.lessons.some((l) => l.id !== lesson.id && l.status === 'published' && l.type !== 'assignment' && l.type !== 'assessment' && !done(l));
      if (!chapterOpen || quizWaiting) snap.lessons[lesson.id] = { lessonId: lesson.id, state: 'locked' };
      else if (p?.state === 'locked') delete snap.lessons[lesson.id];
    }
  });
}

function snapshotFor(course: Course, enrollment?: Enrollment): CourseProgressSnapshot {
  let snap = snapshots.get(course.id);
  if (!snap) {
    snap = { courseId: course.id, lessons: {}, lastActiveAt: enrollment?.lastActiveAt };
    if (enrollment?.status === 'completed') {
      for (const { lesson } of published(course)) snap.lessons[lesson.id] = { lessonId: lesson.id, state: 'completed', completedAt: enrollment.completedAt };
    }
    snapshots.set(course.id, snap);
  }
  applyLocks(course, snap);
  return snap;
}

function lockedReason(course: Course, chapterIndex: number, lesson: Lesson, snap: CourseProgressSnapshot) {
  const previous = course.chapters[chapterIndex - 1];
  if (previous && previous.lessons.some((l) => l.status === 'published' && l.type !== 'assignment' && snap.lessons[l.id]?.state !== 'completed')) {
    return `Finish “${previous.title}” to open this chapter.`;
  }
  if (lesson.type === 'assessment') return `Finish the other lessons in “${course.chapters[chapterIndex].title}” to take this quiz.`;
  return 'This lesson opens after the ones before it.';
}

function nextLesson(course: Course, snap: CourseProgressSnapshot): NextLesson | undefined {
  const all = published(course);
  const pick =
    all.find((x) => x.lesson.id === snap.lastLessonId && snap.lessons[x.lesson.id]?.state === 'in-progress') ??
    all.find((x) => snap.lessons[x.lesson.id]?.state === 'in-progress') ??
    all.find((x) => !snap.lessons[x.lesson.id]);
  if (!pick) return undefined;
  const p = snap.lessons[pick.lesson.id];
  return {
    id: pick.lesson.id,
    title: pick.lesson.title,
    type: pick.lesson.type,
    durationMin: pick.lesson.durationMin,
    chapterIndex: pick.chapterIndex,
    chapterTitle: course.chapters[pick.chapterIndex].title,
    lessonNumber: `${pick.chapterIndex + 1}.${pick.lessonIndex + 1}`,
    state: p?.state ?? 'not-started',
    fraction: p?.fraction,
    positionSec: p?.positionSec,
  };
}

const namesOf = (course: Course) => course.instructorIds.map((id) => instructors.find((i) => i.id === id)?.name ?? '').filter(Boolean);
const levelOf = (course: Course) => levels.find((l) => l.id === course.levelId)?.name ?? '';

function learnerCourse(course: Course, enrollment: Enrollment): LearnerCourse {
  const snapshot = snapshotFor(course, enrollment);
  return {
    course,
    enrollment,
    progress: courseProgress(course, snapshot),
    snapshot,
    next: nextLesson(course, snapshot),
    instructorNames: namesOf(course),
    levelTitle: levelOf(course),
    lastActiveAt: snapshot.lastActiveAt ?? enrollment.lastActiveAt,
  };
}

/** Keeps the learner's enrollment — what admins and instructors see — in step with lesson progress. */
function sync(course: Course, snap: CourseProgressSnapshot, lessonId: string) {
  const enrollment = mine().find((e) => e.courseId === course.id);
  const now = mockNowIso();
  snap.lastLessonId = lessonId;
  snap.lastActiveAt = now;
  const summary = courseProgress(course, snap);
  if (enrollment) {
    enrollment.progress = summary.percent;
    enrollment.lastActiveAt = now;
    enrollment.lastLessonId = lessonId;
    if (summary.state === 'completed' && enrollment.status !== 'completed') {
      enrollment.status = 'completed';
      enrollment.completedAt = now;
    }
  }
  const me = students.find((s) => s.id === ME);
  if (me) me.lastActiveAt = now;
  invalidateAnalytics();
  return summary;
}

function completeInternal(course: Course, lessonId: string): CompletionResult {
  const enrollment = mine().find((e) => e.courseId === course.id);
  if (!enrollment) throw new ServiceError('Enroll in the course to track your progress.', 'conflict');
  const snap = snapshotFor(course, enrollment);
  const located = published(course).find((x) => x.lesson.id === lessonId);
  if (!located) throw new ServiceError('This lesson isn’t available.', 'not-found');
  if (snap.lessons[lessonId]?.state === 'locked') throw new ServiceError(lockedReason(course, located.chapterIndex, located.lesson, snap), 'conflict');
  const chapter = course.chapters[located.chapterIndex];
  const chapterWasDone = chapter.lessons.filter((l) => l.status === 'published').every((l) => snap.lessons[l.id]?.state === 'completed');
  snap.lessons[lessonId] = { lessonId, state: 'completed', completedAt: mockNowIso() };
  applyLocks(course, snap);
  const progress = sync(course, snap, lessonId);
  const chapterDone = chapter.lessons.filter((l) => l.status === 'published').every((l) => snap.lessons[l.id]?.state === 'completed');
  const all = published(course);
  const after = all
    .slice(all.findIndex((x) => x.lesson.id === lessonId) + 1)
    .find((x) => snap.lessons[x.lesson.id]?.state !== 'completed' && snap.lessons[x.lesson.id]?.state !== 'locked');
  return {
    snapshot: snap,
    progress,
    chapterCompleted: !chapterWasDone && chapterDone ? chapter.title : undefined,
    courseCompleted: progress.state === 'completed',
    nextLessonId: after?.lesson.id,
  };
}

/* ─── Assignments ──────────────────────────────────────────────────────── */

function learnerAssignment(assignmentId: string): LearnerAssignment {
  const assignment = courseAssignments.find((a) => a.id === assignmentId);
  const course = assignment && courseById(assignment.courseId);
  if (!assignment || !course || assignment.status === 'draft') throw new ServiceError('This assignment isn’t available.', 'not-found');
  const enrollment = mine().find((e) => e.courseId === course.id);
  const own = submissions()
    .filter((s) => s.assignmentId === assignmentId && s.studentId === ME)
    .sort((a, b) => b.attempt - a.attempt);
  const submission: Submission | undefined = own[0];
  const chapterIndex = course.chapters.findIndex((c) => c.id === assignment.chapterId);
  const fixture = learnerAssignmentFixtures.find((a) => a.id === assignmentId);
  const dueAt =
    fixture?.dueAt ??
    (assignment.due.kind === 'date'
      ? assignment.due.dueAt
      : assignment.due.kind === 'relative' && enrollment
        ? new Date(new Date(enrollment.enrolledAt).getTime() + ((Math.max(0, chapterIndex) + 1) * 7 + assignment.due.days) * DAY_MS).toISOString()
        : undefined);
  const draft = drafts.get(assignmentId);
  const base: LearnerAssignment['state'] = submission
    ? submission.review.status === 'waiting'
      ? 'submitted'
      : submission.review.status === 'in-review'
        ? 'under-review'
        : submission.review.status === 'graded'
          ? 'graded'
          : 'draft'
    : draft
      ? 'draft'
      : 'not-started';
  const state =
    dueAt && (base === 'not-started' || base === 'draft') && !submission
      ? effectiveAssignmentState(
          {
            id: assignment.id,
            courseId: course.id,
            chapterId: assignment.chapterId ?? '',
            title: assignment.title,
            brief: '',
            dueAt,
            state: base,
            acceptsLate: assignment.acceptsLate,
          },
          mockNow(),
        )
      : base;
  return {
    assignment,
    courseTitle: course.title,
    chapterTitle: course.chapters[chapterIndex]?.title,
    lessonId: assignment.lessonId,
    state,
    dueAt,
    submission,
    draft,
  };
}

/* ─── Quizzes ──────────────────────────────────────────────────────────── */

/** A quiz an app built before quiz sessions could take in one request: no time limit and no window. */
const takenInOneGo = (quiz: Quiz) => !quiz.settings.timeLimitMin && !quiz.settings.opensAt && !quiz.settings.closesAt;

/** The lesson's published quiz as the learner's lesson carries it — without its key, and without its questions when timed. */
function lessonQuiz(lessonId: string): LessonQuiz | undefined {
  const quiz = quizzes.find((q) => q.lessonId === lessonId && q.status === 'published');
  if (!quiz) return undefined;
  settleOverdue({ quizId: quiz.id, studentId: ME });
  const { used, open } = learnerQuizState(quiz.id, ME);
  const learner = learnerQuiz(quiz);
  return {
    ...learner,
    questions: takenInOneGo(quiz) ? learner.questions : [],
    questionCount: quiz.questions.length,
    totalPoints: quizTotalPoints(quiz),
    attemptsUsed: used,
    openSession: open ? sessionView(open) : undefined,
    window: quizWindow(quiz.settings, mockNow()),
    settings: { ...quiz.settings, showResults: resultsVisibilityOf(quiz.settings.showResults) },
    negativeMarking: quiz.questions.some((q) => (q.negativePoints ?? 0) > 0),
  };
}

/** The learner's best score at a lesson's quiz — absent while its results are held until it closes. */
function bestScore(lessonId: string, completed: boolean) {
  const quiz = quizzes.find((q) => q.lessonId === lessonId);
  if (quiz && !resultsOut(quiz.settings, mockNow())) return undefined;
  const made = quiz ? learnerQuizState(quiz.id, ME).best : undefined;
  const before = quizBest.get(lessonId) ?? (completed ? 80 + (hashSeed(lessonId) % 17) : undefined);
  return made === undefined ? before : Math.max(made, before ?? 0);
}

/**
 * The quiz a lesson delivers, for the enrolled learner. `starting` adds what a new attempt needs — the quiz published
 * and the lesson unlocked; starting or answering needs the learner's place open, not paused or expired.
 */
function quizOfLesson(courseId: string, lessonId: string, opts: { starting?: boolean; answering?: boolean } = {}) {
  const course = courseById(courseId);
  if (!course) throw new ServiceError('This course isn’t available.', 'not-found');
  const enrollment = mine().find((e) => e.courseId === courseId);
  if (!enrollment) throw new ServiceError('Enroll in the course to take its quizzes.', 'not-found');
  if (opts.starting || opts.answering) {
    if (enrollment.status === 'expired') throw new ServiceError('Your access to this course has ended.', 'conflict', 'ENROLLMENT_EXPIRED', undefined, 409);
    if (enrollment.status === 'paused') throw new ServiceError(ENROLMENT_PAUSED, 'conflict', 'ENROLLMENT_PAUSED', undefined, 409);
  }
  const located = published(course).find((x) => x.lesson.id === lessonId);
  if (!located) throw new ServiceError('Lesson not found.', 'not-found');
  const snap = snapshotFor(course, enrollment);
  if (opts.starting && snap.lessons[lessonId]?.state === 'locked')
    throw new ServiceError(lockedReason(course, located.chapterIndex, located.lesson, snap), 'conflict', undefined, undefined, 409);
  const quiz = quizzes.find((q) => q.lessonId === lessonId && q.courseId === courseId);
  if (!quiz) throw new ServiceError('This quiz is not available yet.', 'not-found');
  if (opts.starting && quiz.status !== 'published') throw new ServiceError('This quiz is not available yet.', 'not-found');
  if (!opts.starting && quiz.status === 'draft' && learnerQuizState(quiz.id, ME).used === 0)
    throw new ServiceError('This quiz is not available yet.', 'not-found');
  return { course, quiz, snap, enrollment };
}

/** Completions made by a pass, kept for the submission that finished it. */
const completionByAttempt = new Map<string, CompletionResult>();

// A pass completes the lesson, whether the learner handed it in or the server finished it at the deadline.
onQuizPassed((quizId, studentId, finished) => {
  if (studentId !== ME || !finished.finishedNow) return;
  const quiz = quizzes.find((q) => q.id === quizId);
  const course = quiz && courseById(quiz.courseId);
  if (!quiz?.lessonId || !course) return;
  const snap = snapshotFor(
    course,
    mine().find((e) => e.courseId === course.id),
  );
  if (snap.lessons[quiz.lessonId]?.state === 'completed') return;
  try {
    completionByAttempt.set(finished.attempt.id, completeInternal(course, quiz.lessonId));
  } catch {
    // A lesson locked since the attempt started stays as it is; the attempt is still recorded.
  }
});

/** What a pass means for the lesson when it completed nothing new: the course as it stands. */
function completionSummary(course: Course): CompletionResult {
  const snap = snapshotFor(
    course,
    mine().find((e) => e.courseId === course.id),
  );
  const progress = courseProgress(course, snap);
  return { snapshot: snap, progress, courseCompleted: progress.state === 'completed', nextLessonId: nextLesson(course, snap)?.id };
}

/* ─── Service ──────────────────────────────────────────────────────────── */

function lessonView(courseId: string, lessonId: string): LessonView {
  const course = courseById(courseId);
  if (!course || course.status === 'draft') throw new ServiceError('This course isn’t available.', 'not-found');
  const enrollment = mine().find((e) => e.courseId === courseId && e.status !== 'expired');
  const snap = snapshotFor(course, enrollment);
  const chapterIndex = course.chapters.findIndex((c) => c.lessons.some((l) => l.id === lessonId));
  if (chapterIndex < 0) throw new ServiceError('This lesson doesn’t exist.', 'not-found');
  const chapter = course.chapters[chapterIndex];
  const raw = chapter.lessons.find((l) => l.id === lessonId)!;
  const lessonIndex = chapter.lessons.indexOf(raw);
  const lesson = complete(course, chapter, raw);
  const all = published(course);
  const index = all.findIndex((x) => x.lesson.id === lessonId);
  const lessonProgress = snap.lessons[lessonId];
  const enrolled = Boolean(enrollment);
  const state = enrolled ? (lessonProgress?.state ?? 'not-started') : 'not-started';
  const access = raw.status !== 'published' ? 'unavailable' : !enrolled && !raw.isPreview ? 'not-enrolled' : enrolled && state === 'locked' ? 'locked' : 'open';
  const prev = index > 0 ? all[index - 1] : undefined;
  const next = index >= 0 ? all[index + 1] : undefined;
  const liveId = lesson.content?.live?.liveClassId;
  const live: LiveClass | undefined =
    lesson.type === 'live'
      ? learnerLiveClass(
          liveClasses.find((c) => c.id === liveId) ?? {
            id: `lc-${lesson.id}`,
            courseId,
            title: lesson.title,
            instructorId: course.instructorIds[0],
            startsAt: lesson.content?.live?.startsAt ?? mockNowIso(),
            durationMin: lesson.content?.live?.durationMin ?? lesson.durationMin,
            recording: lesson.content?.live?.recorded
              ? { durationMin: lesson.durationMin, availableUntil: new Date(mockNow().getTime() + 60 * DAY_MS).toISOString() }
              : undefined,
          },
        )
      : undefined;
  const linked = courseAssignments.find((a) => a.lessonId === lessonId && a.status !== 'draft');
  return {
    course,
    enrolled,
    snapshot: snap,
    progress: courseProgress(course, snap),
    chapterIndex,
    lessonIndex,
    lesson,
    number: `${chapterIndex + 1}.${lessonIndex + 1}`,
    position: { index: index + 1, total: all.length },
    state,
    lessonProgress,
    access,
    lockedReason: access === 'locked' ? lockedReason(course, chapterIndex, raw, snap) : undefined,
    previous: prev && { id: prev.lesson.id, title: prev.lesson.title },
    next: next && { id: next.lesson.id, title: next.lesson.title, locked: enrolled && snap.lessons[next.lesson.id]?.state === 'locked' },
    quiz: lesson.type === 'assessment' ? lessonQuiz(lessonId) : undefined,
    quizBest: bestScore(lessonId, state === 'completed'),
    assignment: linked ? learnerAssignment(linked.id) : undefined,
    live,
    instructorNames: namesOf(course),
    note: notes.get(`${courseId}:${lessonId}`) ?? '',
    bookmarked: bookmarks.has(`${courseId}:${lessonId}`),
  };
}

export const learningService: LearningService = {
  getHome: () =>
    respond((): LearningHome => {
      const now = mockNow();
      const empty = scenario() === 'empty';
      const list = empty ? [] : mine().flatMap((e) => (courseById(e.courseId) ? [learnerCourse(courseById(e.courseId)!, e)] : []));
      list.sort(
        (a, b) =>
          Number(a.enrollment.status === 'completed') - Number(b.enrollment.status === 'completed') ||
          (b.lastActiveAt ?? '').localeCompare(a.lastActiveAt ?? ''),
      );
      const recent = list
        .flatMap((c) =>
          published(c.course).flatMap(({ lesson }) => {
            const p = c.snapshot.lessons[lesson.id];
            const at = p?.completedAt ?? (p?.state === 'in-progress' ? c.snapshot.lastActiveAt : undefined);
            return p && at
              ? [{ courseId: c.course.id, courseTitle: c.course.title, lessonId: lesson.id, lessonTitle: lesson.title, type: lesson.type, at, state: p.state }]
              : [];
          }),
        )
        .sort((a, b) => b.at.localeCompare(a.at) || Number(b.state === 'in-progress') - Number(a.state === 'in-progress'))
        .slice(0, 5);
      const upcoming: LearningHome['upcoming'] = [];
      if (!empty) {
        for (const cls of liveClasses) {
          const phase = deriveLiveClassPhase(cls, now);
          if (phase === 'cancelled' || phase === 'ended' || phase === 'recording-expired') continue;
          if (new Date(cls.startsAt).getTime() - now.getTime() > 14 * DAY_MS) continue;
          upcoming.push({
            id: cls.id,
            kind: 'live',
            title: cls.title,
            context: `${courseById(cls.courseId)?.title} · ${cls.durationMin} min`,
            at: cls.startsAt,
            to: '/live',
            flag: phase === 'live' ? 'live-now' : phase === 'starting-soon' ? 'starting-soon' : undefined,
          });
        }
        for (const c of list.filter((x) => x.enrollment.status === 'active')) {
          for (const a of courseAssignments.filter((x) => x.courseId === c.course.id && x.status === 'published')) {
            const la = learnerAssignment(a.id);
            if (!la.dueAt || !['not-started', 'draft', 'overdue'].includes(la.state)) continue;
            const days = (new Date(la.dueAt).getTime() - now.getTime()) / DAY_MS;
            if (days > 14 || (days < 0 && la.state !== 'overdue')) continue;
            upcoming.push({
              id: a.id,
              kind: 'assignment',
              title: a.title,
              context: la.state === 'overdue' ? `${c.course.title} · overdue` : c.course.title,
              at: la.dueAt,
              to: `/assignments/${a.id}`,
              flag: la.state === 'overdue' ? 'overdue' : days < 3 ? 'due-soon' : undefined,
            });
          }
          const quiz = published(c.course).find(({ lesson }) => lesson.type === 'assessment' && !c.snapshot.lessons[lesson.id]);
          if (quiz)
            upcoming.push({
              id: quiz.lesson.id,
              kind: 'quiz',
              title: quiz.lesson.title,
              context: `${c.course.title} · ready to take`,
              at: mockNowIso(),
              to: `/learn/${c.course.id}/lessons/${quiz.lesson.id}`,
            });
        }
      }
      upcoming.sort((a, b) => Number(Boolean(b.flag)) - Number(Boolean(a.flag)) || a.at.localeCompare(b.at));
      return {
        firstName: personas.student.name.split(' ')[0],
        courses: list,
        saved: empty
          ? []
          : [...saved].flatMap((id) =>
              courseById(id) ? [{ course: courseById(id)!, instructorNames: namesOf(courseById(id)!), levelTitle: levelOf(courseById(id)!) }] : [],
            ),
        recent,
        upcoming: upcoming.slice(0, 6),
        week: empty ? studyWeek.map((d) => ({ ...d, minutes: 0 })) : studyWeek,
      };
    }, 560),

  listCourses: () =>
    respond(() => {
      if (scenario() === 'empty') return { courses: [], saved: [] };
      return {
        courses: mine().flatMap((e) => (courseById(e.courseId) ? [learnerCourse(courseById(e.courseId)!, e)] : [])),
        saved: [...saved].flatMap((id) =>
          courseById(id) ? [{ course: courseById(id)!, instructorNames: namesOf(courseById(id)!), levelTitle: levelOf(courseById(id)!) }] : [],
        ),
      };
    }, 520),

  getCourse: (courseId) =>
    respond(() => {
      const course = courseById(courseId);
      if (!course || course.status === 'draft') throw new ServiceError('This course isn’t available.', 'not-found');
      const enrollment = mine().find((e) => e.courseId === courseId);
      const base: LearnerCourse = enrollment
        ? learnerCourse(course, enrollment)
        : (() => {
            const snapshot = { courseId, lessons: {} } as CourseProgressSnapshot;
            return {
              course,
              enrollment: { id: 'preview', studentId: ME, courseId, enrolledAt: mockNowIso(), status: 'active', progress: 0, source: 'self' } as Enrollment,
              progress: courseProgress(course, snapshot),
              snapshot,
              instructorNames: namesOf(course),
              levelTitle: levelOf(course),
            };
          })();
      return {
        ...base,
        enrolled: Boolean(enrollment),
        saved: saved.has(courseId),
        live: liveClasses.filter((c) => c.courseId === courseId && !c.cancelled).map(learnerLiveClass),
        assignments: enrollment ? courseAssignments.filter((a) => a.courseId === courseId && a.status === 'published').map((a) => learnerAssignment(a.id)) : [],
        certificate: certificates.find((c) => c.courseId === courseId),
      };
    }, 520),

  getLesson: (courseId, lessonId) => respond(() => lessonView(courseId, lessonId), 480),

  completeLesson: (courseId, lessonId) =>
    respond(() => {
      const course = courseById(courseId);
      if (!course) throw new ServiceError('This course isn’t available.', 'not-found');
      return completeInternal(course, lessonId);
    }, 500),

  savePosition: (courseId, lessonId, positionSec, fraction) =>
    respond(() => {
      const course = courseById(courseId);
      const enrollment = mine().find((e) => e.courseId === courseId);
      if (!course || !enrollment) return;
      const snap = snapshotFor(course, enrollment);
      const current = snap.lessons[lessonId];
      if (current?.state === 'completed' || current?.state === 'locked') return;
      snap.lessons[lessonId] = { lessonId, state: 'in-progress', positionSec: Math.round(positionSec), fraction: Math.min(0.99, fraction) };
      sync(course, snap, lessonId);
    }, 120),

  saveNote: (courseId, lessonId, text) =>
    respond(() => {
      if (text.trim()) notes.set(`${courseId}:${lessonId}`, text);
      else notes.delete(`${courseId}:${lessonId}`);
      return { savedAt: mockNowIso() };
    }, 350),

  toggleBookmark: (courseId, lessonId) =>
    respond(() => {
      const key = `${courseId}:${lessonId}`;
      if (bookmarks.has(key)) bookmarks.delete(key);
      else bookmarks.add(key);
      return { bookmarked: bookmarks.has(key) };
    }, 300),

  toggleSaved: (courseId) =>
    respond(() => {
      if (saved.has(courseId)) saved.delete(courseId);
      else saved.add(courseId);
      return { saved: saved.has(courseId) };
    }, 300),

  enroll: (courseId) =>
    respond(() => {
      const course = courseById(courseId);
      if (!course || course.status !== 'published') throw new ServiceError('This course isn’t open for enrollment.', 'conflict');
      const existing = mine().find((e) => e.courseId === courseId);
      if (existing) return learnerCourse(course, existing);
      // As on the API: a paid course is bought, never enrolled in for free; one with no price chosen is open to nobody.
      const sale = courseSale(course);
      if (sale.kind === 'paid')
        throw new ServiceError('This is a paid course. Buy it to start learning.', 'conflict', 'COURSE_PURCHASE_REQUIRED', undefined, 409);
      if (sale.kind === 'unavailable')
        throw new ServiceError('This course isn’t open for enrolment yet. Contact the LMS.', 'conflict', 'COURSE_NOT_FOR_SALE', undefined, 409);
      const enrollment: Enrollment = {
        id: `en-${Date.now().toString(36)}`,
        studentId: ME,
        courseId,
        enrolledAt: mockNowIso(),
        status: 'active',
        progress: 0,
        source: 'self',
        lastActiveAt: mockNowIso(),
      };
      enrollments.push(enrollment);
      course.enrolledCount += 1;
      saved.delete(courseId);
      invalidateAnalytics();
      return learnerCourse(course, enrollment);
    }, 1000),

  listAssignments: () =>
    respond(() => {
      if (scenario() === 'empty') return [];
      const ids = new Set(mine().map((e) => e.courseId));
      return courseAssignments
        .filter((a) => ids.has(a.courseId) && a.status !== 'draft')
        .map((a) => learnerAssignment(a.id))
        .filter((la) => la.submission || la.state !== 'not-started' || la.dueAt || la.lessonId)
        .sort((a, b) => (a.dueAt ?? '9').localeCompare(b.dueAt ?? '9'));
    }, 480),

  getAssignment: (assignmentId) =>
    respond(() => {
      const la = learnerAssignment(assignmentId);
      if (!mine().some((e) => e.courseId === la.assignment.courseId)) throw new ServiceError('Enroll in the course to open this assignment.', 'not-found');
      return la;
    }, 460),

  saveAssignmentDraft: (assignmentId, draft) =>
    respond(() => {
      drafts.set(assignmentId, draft);
      return { savedAt: mockNowIso() };
    }, 400),

  submitAssignment: (assignmentId, draft) =>
    respond(() => {
      const la = learnerAssignment(assignmentId);
      const a = la.assignment;
      if (la.state === 'closed') throw new ServiceError('Submissions for this assignment are closed.', 'conflict');
      if (la.submission && la.submission.review.status !== 'returned')
        throw new ServiceError('You’ve already handed this in. It’s waiting for review.', 'conflict');
      const words = (draft.text ?? '').trim().split(/\s+/).filter(Boolean).length;
      if (a.format === 'file' && draft.files.length === 0) throw new ServiceError('Upload your work before submitting.', 'conflict');
      if (a.format !== 'file' && words < 20) throw new ServiceError('Write at least a paragraph before submitting.', 'conflict');
      if (a.format === 'chart' && (!draft.chart?.date || !draft.chart.place)) throw new ServiceError('Add the birth date and place for the chart.', 'conflict');
      if (a.wordLimit && words > a.wordLimit) throw new ServiceError(`Your response is ${words} words — the limit is ${a.wordLimit}.`, 'conflict');
      const attempt = (la.submission?.attempt ?? 0) + 1;
      const now = mockNowIso();
      const rng = createRandom(hashSeed(`${assignmentId}:${attempt}`));
      submissions().push({
        id: `sub-${assignmentId}-${ME}-${attempt}`,
        assignmentId,
        studentId: ME,
        attempt,
        submittedAt: now,
        late: Boolean(la.dueAt && new Date(la.dueAt).getTime() < mockNow().getTime()),
        text: draft.text,
        files: draft.files,
        chart: draft.chart && {
          label: draft.chart.label || 'My own chart',
          date: draft.chart.date,
          time: draft.chart.time,
          place: draft.chart.place,
          lagna: draft.chart.lagna || ['Aries', 'Leo', 'Libra'][rng.int(0, 2)],
          moonSign: draft.chart.moonSign || 'Taurus',
          nakshatra: draft.chart.nakshatra || 'Rohini',
        },
        review: { status: 'waiting', scores: {}, feedback: '' },
      });
      drafts.delete(assignmentId);
      const course = courseById(a.courseId)!;
      if (
        a.lessonId &&
        snapshotFor(
          course,
          mine().find((e) => e.courseId === course.id),
        ).lessons[a.lessonId]?.state !== 'completed'
      )
        completeInternal(course, a.lessonId);
      invalidateAnalytics();
      return learnerAssignment(assignmentId);
    }, 1100),

  listAssessments: () =>
    respond(() => {
      if (scenario() === 'empty') return [];
      const rules = mockLearningRules();
      const now = mockNow();
      const out: LearnerAssessment[] = [];
      for (const e of mine()) {
        const course = courseById(e.courseId);
        if (!course) continue;
        const snap = snapshotFor(course, e);
        for (const { lesson, chapterIndex } of published(course).filter((x) => x.lesson.type === 'assessment')) {
          const quiz = quizzes.find((q) => q.lessonId === lesson.id);
          if (!quiz || quiz.status !== 'published') continue;
          settleOverdue({ quizId: quiz.id, studentId: ME });
          const { used, open, taken, passed } = learnerQuizState(quiz.id, ME);
          const p = snap.lessons[lesson.id];
          // As the API: an attempt under way comes first, a practice retake after a pass included.
          const state = open
            ? 'in-progress'
            : p?.state === 'completed' || passed
              ? 'passed'
              : p?.state === 'locked'
                ? 'locked'
                : taken.length
                  ? 'failed'
                  : 'available';
          out.push({
            id: quiz.id,
            lessonId: lesson.id,
            courseId: course.id,
            courseTitle: course.title,
            title: quiz.title,
            questions: quiz.questions.length,
            durationMin: quiz.settings.timeLimitMin ?? lesson.durationMin,
            passMark: quiz.settings.passMark,
            attemptsAllowed: quiz.settings.attempts ?? rules.quizAttempts,
            attemptsUsed: used,
            state,
            lockedReason: state === 'locked' ? lockedReason(course, chapterIndex, lesson, snap) : undefined,
            score: bestScore(lesson.id, p?.state === 'completed'),
            window: quizWindow(quiz.settings, now),
            ...(quiz.settings.opensAt ? { opensAt: quiz.settings.opensAt } : {}),
            ...(quiz.settings.closesAt ? { closesAt: quiz.settings.closesAt } : {}),
            ...(open?.deadlineAt ? { deadlineAt: open.deadlineAt.toISOString() } : {}),
            ...(!resultsOut(quiz.settings, now) && quiz.settings.closesAt ? { resultsAt: quiz.settings.closesAt } : {}),
            negativeMarking: quiz.questions.some((q) => (q.negativePoints ?? 0) > 0),
          });
        }
      }
      const order = ['available', 'in-progress', 'failed', 'locked', 'passed', 'submitted'];
      return out.sort((a, b) => order.indexOf(a.state) - order.indexOf(b.state));
    }, 480),

  quizAttempts: (courseId, lessonId) =>
    respond(() => {
      const { quiz, enrollment } = quizOfLesson(courseId, lessonId);
      return quizStanding(quiz, ME, enrollment);
    }, 260),

  startQuizSession: (courseId, lessonId, startKey) =>
    respond(() => {
      const { quiz } = quizOfLesson(courseId, lessonId, { starting: true });
      return startSession(quiz, ME, startKey);
    }, 420),

  getQuizSession: (courseId, lessonId) =>
    respond(() => {
      const { quiz } = quizOfLesson(courseId, lessonId);
      return latestSession(quiz, ME);
    }, 260),

  saveQuizAnswers: (courseId, lessonId, sessionId, answers, seq) =>
    respond(() => {
      const { quiz } = quizOfLesson(courseId, lessonId, { answering: true });
      return saveAnswers(quiz, sessionId, ME, answers, seq);
    }, 240),

  submitQuizSession: (courseId, lessonId, sessionId, final) =>
    respond(() => {
      // A final sheet is an answer: like an autosave, it is not taken once the learner's access has ended.
      const { course, quiz, enrollment } = quizOfLesson(courseId, lessonId, { answering: Boolean(final) });
      const { finished, ...rest } = submitSession(quiz, sessionId, ME, enrollment, final);
      const completion = finished.attempt.passed
        ? ((finished.finishedNow ? completionByAttempt.get(finished.attempt.id) : undefined) ?? completionSummary(course))
        : null;
      return { ...rest, completion };
    }, 600),

  listCertificates: () =>
    respond(() => {
      if (scenario() === 'empty') return { issued: [], pending: [], working: [] };
      const own = issuedCertificates().filter((c) => c.studentId === ME);
      const earned = new Set(own.map((c) => c.courseId));
      return {
        issued: own.filter((c) => c.status === 'issued').map(certificateDetail),
        pending: own.filter((c) => c.status === 'pending').map(certificateDetail),
        // Courses in progress that award a certificate, with how close the learner is.
        working: certificates.filter((r) => !earned.has(r.courseId) && mine().some((e) => e.courseId === r.courseId && e.status === 'active')),
      };
    }, 480),

  getCertificate: (id) =>
    respond(() => {
      const cert = issuedCertificates().find((c) => c.id === id && c.studentId === ME);
      if (!cert || cert.status === 'revoked') throw new ServiceError('This certificate isn’t available.', 'not-found');
      return certificateDetail(cert);
    }, 420),

  claimCertificate: (id) =>
    respond(() => {
      const cert = issuedCertificates().find((c) => c.id === id && c.studentId === ME);
      if (!cert) throw new ServiceError('This certificate isn’t available.', 'not-found');
      return certificateDetail(issueCertificate(cert));
    }, 900),

  quotePurchase: (courseId) => respond(() => quoteMockPurchase(courseId), 300),
  startPurchase: (courseId) => respond(() => startMockPurchase(courseId), 700),
  confirmPurchase: (purchaseId) => respond(() => confirmMockPurchase(purchaseId), 600),
  getPurchase: (purchaseId) =>
    respond(() => {
      const purchase = mockPurchaseStatus(purchaseId);
      if (purchase.enrolled) saved.delete(purchase.courseId);
      return purchase;
    }, 400),
  listPurchases: () => respond(() => (scenario() === 'empty' ? [] : listMockPurchases()), 420),
  getCourseReview: (courseId) => respond(() => ownMockReview(courseId)),
  saveCourseReview: (courseId, input) => respond(() => saveMockReview(courseId, input)),
};
