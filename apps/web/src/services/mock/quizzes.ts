import type { Quiz, QuizInput } from '@syniastrolms/domain';
import { quizTotalPoints, validateQuiz } from '@syniastrolms/domain';
import type { QuizAdminService, QuizRow, QuizStats } from '../contracts';
import { ServiceError } from '../contracts';
import { mockNowIso } from './clock';
import { courses } from './fixtures/catalog';
import { quizzes } from './fixtures/quizzes';
import { attemptRows, quizTaken } from './quizSessions';
import { createRandom, hashSeed } from './random';
import { respond, scenario } from './simulation';

function find(id: string, scopeInstructorId?: string) {
  const quiz = quizzes.find((q) => q.id === id);
  const course = quiz && courses.find((c) => c.id === quiz.courseId);
  if (!quiz || !course || (scopeInstructorId && !course.instructorIds.includes(scopeInstructorId))) {
    throw new ServiceError('This quiz doesn’t exist or isn’t shared with you.', 'not-found');
  }
  return quiz;
}

/**
 * Attempt statistics, generated deterministically per quiz. Harder questions (short answers,
 * multi-select, long prompts) get lower correct rates, and the distribution centres on the mean.
 */
export function statsFor(quiz: Quiz): QuizStats {
  const course = courses.find((c) => c.id === quiz.courseId);
  const rng = createRandom(hashSeed(quiz.id));
  // An archived quiz keeps the results it gathered while it was published.
  const published = quiz.status !== 'draft' && quiz.questions.length > 0;
  const learners = published ? Math.round((course?.enrolledCount ?? 0) * rng.between(0.32, 0.7)) : 0;
  const attempts = published ? Math.round(learners * (quiz.settings.attempts === 1 ? 1 : rng.between(1.2, 1.55))) : 0;
  const questions = quiz.questions.map((q) => {
    const difficulty = (q.type === 'short' ? 0.16 : q.type === 'multiple' ? 0.2 : q.type === 'true-false' ? -0.08 : 0) + (q.prompt.length > 70 ? 0.05 : 0);
    const correctRate = published ? Math.round(Math.min(97, Math.max(28, rng.between(66, 92) - difficulty * 100))) : 0;
    const wrong = q.options.filter((o) => !q.correct.includes(o.id));
    return { questionId: q.id, correctRate, commonWrongOptionId: wrong.length ? rng.pick(wrong).id : undefined };
  });
  const points = quizTotalPoints(quiz) || 1;
  const avgScore = published ? Math.round((quiz.questions.reduce((n, q, i) => n + (questions[i].correctRate / 100) * q.points, 0) / points) * 100) : 0;
  const spread = 14;
  const weights = Array.from({ length: 10 }, (_, i) => {
    const centre = i * 10 + 5;
    return Math.exp(-((centre - avgScore) ** 2) / (2 * spread * spread));
  });
  const total = weights.reduce((n, w) => n + w, 0) || 1;
  // Largest-remainder rounding, so the bands add up to the attempts shown beside them.
  const shares = weights.map((w) => (w / total) * attempts);
  const counts = shares.map(Math.floor);
  const byRemainder = shares.map((s, i) => [s - Math.floor(s), i] as const).sort((a, b) => b[0] - a[0]);
  const missing = attempts - counts.reduce((n, c) => n + c, 0);
  for (let k = 0; k < missing; k++) counts[byRemainder[k][1]] += 1;
  const distribution = counts.map((value, i) => ({ label: i === 9 ? '90–100%' : `${i * 10}–${i * 10 + 9}%`, value }));
  const passing = distribution.slice(Math.floor(quiz.settings.passMark / 10)).reduce((n, b) => n + b.value, 0);
  return {
    quizId: quiz.id,
    attempts,
    learners,
    passRate: attempts ? Math.round((passing / attempts) * 100) : 0,
    avgScore,
    medianMinutes: published ? Math.max(3, Math.round((quiz.settings.timeLimitMin ?? quiz.questions.length * 1.4) * rng.between(0.55, 0.8))) : 0,
    distribution,
    questions,
  };
}

function row(quiz: Quiz): QuizRow {
  const course = courses.find((c) => c.id === quiz.courseId);
  const stats = statsFor(quiz);
  return {
    quiz,
    courseTitle: course?.title ?? 'Unknown course',
    chapterTitle: course?.chapters.find((c) => c.id === quiz.chapterId)?.title,
    points: quizTotalPoints(quiz),
    attempts: stats.attempts,
    passRate: stats.attempts ? stats.passRate : null,
    avgScore: stats.attempts ? stats.avgScore : null,
  };
}

/** Publishing is refused as the API refuses it: a conflict that lists the validator's issues. */
function assertPublishable(quiz: Pick<Quiz, 'status' | 'title' | 'questions' | 'settings'>) {
  if (quiz.status !== 'published') return;
  const issues = validateQuiz(quiz);
  if (issues.length)
    throw new ServiceError(
      ['This quiz is not ready to publish.', ...new Set(issues.map((i) => i.message))].join(' '),
      'conflict',
      undefined,
      issues.map((i) => ({ field: i.field, message: i.message })),
      409,
    );
}

let serial = 0;
const nextQuizId = () => `quiz-${Date.now().toString(36)}${(serial++).toString(36)}`;

export const quizAdminService: QuizAdminService = {
  list: ({ search = '', courseId, status = 'all', scopeInstructorId }) =>
    respond(() => {
      if (scenario() === 'empty') return { rows: [], counts: { all: 0, draft: 0, published: 0, archived: 0 } };
      const q = search.trim().toLowerCase();
      const allowed = new Set(courses.filter((c) => !scopeInstructorId || c.instructorIds.includes(scopeInstructorId)).map((c) => c.id));
      const matching = quizzes.filter(
        (quiz) => allowed.has(quiz.courseId) && (!courseId || quiz.courseId === courseId) && (!q || quiz.title.toLowerCase().includes(q)),
      );
      const rows = matching
        .filter((quiz) => status === 'all' || quiz.status === status)
        .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
        .map(row);
      return {
        rows,
        counts: {
          all: matching.length,
          draft: matching.filter((x) => x.status === 'draft').length,
          published: matching.filter((x) => x.status === 'published').length,
          archived: matching.filter((x) => x.status === 'archived').length,
        },
      };
    }, 420),

  get: (id, scopeInstructorId) => respond(() => find(id, scopeInstructorId), 420),

  stats: (id) => respond(() => statsFor(find(id)), 520),

  attempts: (id) => respond(() => attemptRows(find(id).id), 420),

  create: (input: QuizInput) =>
    respond(() => {
      if (input.title.trim().length < 3) throw new ServiceError('Give the quiz a title of at least 3 characters.', 'conflict');
      if (!courses.some((c) => c.id === input.courseId)) throw new ServiceError('Choose the course this quiz belongs to.', 'conflict');
      assertPublishable(input);
      const now = mockNowIso();
      const quiz: Quiz = { ...input, id: nextQuizId(), title: input.title.trim(), createdAt: now, updatedAt: now };
      quizzes.unshift(quiz);
      return quiz;
    }, 850),

  update: (id, input) =>
    respond(() => {
      const current = find(id);
      const next: Quiz = { ...current, ...input, updatedAt: mockNowIso() };
      if (input.title !== undefined) next.title = input.title.trim();
      assertPublishable(next);
      quizzes[quizzes.findIndex((q) => q.id === id)] = next;
      return next;
    }, 800),

  duplicate: (id) =>
    respond(() => {
      const source = find(id);
      const now = mockNowIso();
      const copyId = nextQuizId();
      const copy: Quiz = {
        ...structuredClone(source),
        id: copyId,
        lessonId: undefined,
        title: `Copy of ${source.title}`,
        status: 'draft',
        createdAt: now,
        updatedAt: now,
        questions: source.questions.map((q, i) => {
          const qid = `${copyId}-q${i + 1}`;
          // True/false options keep their suffixes, which is how the editor recognises them.
          const optionIds = new Map(
            q.options.map((o, j) => [o.id, /-(true|false)$/.test(o.id) ? `${qid}${o.id.slice(o.id.lastIndexOf('-'))}` : `${qid}-o${j + 1}`]),
          );
          return {
            ...q,
            id: qid,
            options: q.options.map((o) => ({ ...o, id: optionIds.get(o.id)! })),
            correct: q.correct.map((c) => optionIds.get(c) ?? c),
          };
        }),
      };
      quizzes.splice(quizzes.indexOf(source) + 1, 0, copy);
      return copy;
    }, 800),

  remove: (id) =>
    respond(() => {
      const quiz = find(id);
      if (quiz.lessonId) {
        throw new ServiceError('This quiz is delivered by a lesson. Change that lesson to another type, or delete the lesson, first.', 'conflict');
      }
      // Deleting would take every learner's result with it: a quiz that has been taken is archived instead.
      if (quizTaken(quiz.id) || statsFor(quiz).attempts > 0)
        throw new ServiceError(
          'Learners have taken this quiz, so deleting it would delete their results. Archive it instead.',
          'conflict',
          undefined,
          undefined,
          409,
        );
      quizzes.splice(quizzes.indexOf(quiz), 1);
    }, 700),
};
