import { beforeAll, describe, expect, it } from 'vitest';

import { T, db } from '../test/db.js';
import { as, newStudent, type Client } from '../test/helpers.js';

/* A fresh learner walks through the seeded "Foundations" course: gating, thresholds, quizzes scored on
 * the server, drafts, completion. Settings are read from the API so the assertions follow the academy. */

let admin: Client;
let learner: Awaited<ReturnType<typeof newStudent>>;
let course: {
  id: string;
  slug: string;
  chapters: { id: string; title: string; lessons: { id: string; title: string; type: string; status: string; durationMin: number }[] }[];
};
let learning: Record<string, unknown>;

/** A lesson quiz's questions with their key, read the way its author reads them — never from a learner response. */
const answerKey = async (lessonId: string) =>
  JSON.parse((await db.quiz.findUniqueOrThrow({ where: { lessonId } })).questionsJson) as {
    id: string;
    type: string;
    correct: string[];
    acceptedAnswers?: string[];
  }[];

const published = () => course.chapters.flatMap((c, ci) => c.lessons.filter((l) => l.status === 'published').map((l) => ({ ...l, ci })));

beforeAll(async () => {
  admin = await as('admin');
  learner = await newStudent('Gating Learner');
  const catalog = (await learner.get('/catalog/courses')).body as (typeof course)[];
  course = catalog.find((c) => c.slug.includes('foundations')) ?? catalog[0];
  learning = (await admin.get('/settings')).body.settings.learning;
  await admin.put('/settings/learning', { ...learning, chapterGate: true, completionThreshold: 90, courseCompletion: 'all-lessons', retakeWaitHours: 0 });
});

describe('enrolment', () => {
  it('enrols under the open policy, sets access expiry from settings, and refuses under other policies', async () => {
    const general = (await admin.get('/settings')).body.settings.general;
    await admin.put('/settings/general', { ...general, enrollment: 'invite' });
    expect((await learner.post(`/learning/courses/${course.id}/enroll`)).status).toBe(409);
    await admin.put('/settings/general', { ...general, enrollment: 'approval' });
    expect((await learner.post(`/learning/courses/${course.id}/enroll`)).status).toBe(409);
    await admin.put('/settings/general', { ...general, enrollment: 'open', accessMonths: 6 });

    const res = await learner.post(`/learning/courses/${course.id}/enroll`);
    expect(res.status).toBe(200);
    expect(res.body.enrollment.status).toBe('active');
    expect(res.body.instructorNames.length).toBeGreaterThan(0);
    expect(res.body.levelTitle.length).toBeGreaterThan(0);
    const months = (new Date(res.body.enrollment.expiresAt).getTime() - new Date(res.body.enrollment.enrolledAt).getTime()) / (30 * 86_400_000);
    expect(Math.round(months)).toBe(6);
    await admin.put('/settings/general', general);
  });
});

describe('gating and completion rules', () => {
  it('locks later chapters and the chapter quiz until the lessons before them are done', async () => {
    const view = await learner.get(`/learning/courses/${course.id}`);
    expect(view.status).toBe(200);
    const snap = view.body.snapshot.lessons as Record<string, { state: string }>;
    const chapter2 = course.chapters[1].lessons.filter((l) => l.status === 'published')[0];
    expect(snap[chapter2.id]?.state).toBe('locked');
    const quiz = published().find((l) => l.type === 'assessment' && l.ci === 0);
    if (quiz) expect(snap[quiz.id]?.state).toBe('locked');
    expect(view.body.next.chapterIndex).toBe(0);

    const locked = await learner.get(`/learning/courses/${course.id}/lessons/${chapter2.id}`);
    expect(locked.body.access).toBe('locked');
    expect(locked.body.lockedReason).toMatch(/Finish/);
    expect(locked.body.lesson.content).toEqual({});
    expect((await learner.post(`/learning/courses/${course.id}/lessons/${chapter2.id}/complete`)).status).toBe(409);
  });

  it('completes a video only past the threshold, and records recent access', async () => {
    const video = published().find((l) => l.type === 'video' && l.ci === 0)!;
    const open = await learner.get(`/learning/courses/${course.id}/lessons/${video.id}`);
    expect(open.body.access).toBe('open');
    expect(open.body.threshold).toBe(90);
    expect(Object.keys(open.body.lesson.content).length).toBeGreaterThan(0);

    await learner.put(`/learning/courses/${course.id}/lessons/${video.id}/position`, { positionSec: 60, fraction: 0.4 });
    const early = await learner.post(`/learning/courses/${course.id}/lessons/${video.id}/complete`);
    expect(early.status).toBe(409);
    expect(early.body.message).toMatch(/90%/);

    await learner.put(`/learning/courses/${course.id}/lessons/${video.id}/position`, { positionSec: 600, fraction: 0.95 });
    const after = await learner.get(`/learning/courses/${course.id}/lessons/${video.id}`);
    expect(after.body.state).toBe('completed'); // auto-completed at the threshold

    const home = await learner.get('/learning/home');
    expect(home.body.recent[0].lessonId).toBe(video.id);
    expect(home.body.week).toHaveLength(7);
    expect(home.body.courses[0].enrollment.lastLessonId).toBe(video.id);
  });

  it('marks readings complete on request, refuses to mark quizzes/assignments by hand, and opens the quiz when the chapter is done', async () => {
    const first = course.chapters[0].lessons.filter((l) => l.status === 'published');
    for (const l of first.filter((l) => l.type !== 'assessment' && l.type !== 'assignment' && l.type !== 'video')) {
      if (l.type === 'practice') {
        // a practice exercise needs written working first
        expect((await learner.post(`/learning/courses/${course.id}/lessons/${l.id}/complete`)).status).toBe(409);
        await learner.put(`/learning/courses/${course.id}/lessons/${l.id}/note`, {
          text: '(−3) × (−4) = 12, because like signs give a positive product.',
        });
      }
      const r = await learner.post(`/learning/courses/${course.id}/lessons/${l.id}/complete`);
      expect(r.status).toBe(200);
    }
    for (const l of first.filter((l) => l.type === 'video')) {
      await learner.put(`/learning/courses/${course.id}/lessons/${l.id}/position`, { positionSec: 1, fraction: 1 });
    }
    const quiz = first.find((l) => l.type === 'assessment');
    if (quiz) {
      expect((await learner.post(`/learning/courses/${course.id}/lessons/${quiz.id}/complete`)).status).toBe(409);
      const view = await learner.get(`/learning/courses/${course.id}/lessons/${quiz.id}`);
      expect(view.body.access).toBe('open');
      expect(view.body.quiz).toBeDefined();
    }
    const assignment = first.find((l) => l.type === 'assignment');
    if (assignment) expect((await learner.post(`/learning/courses/${course.id}/lessons/${assignment.id}/complete`)).status).toBe(409);
  });

  it('scores quiz attempts on the server, ignores client scores, limits attempts and completes the lesson on a pass', async () => {
    const quizLesson = published().find((l) => l.type === 'assessment' && l.ci === 0);
    if (!quizLesson) return;
    const view = await learner.get(`/learning/courses/${course.id}/lessons/${quizLesson.id}`);
    // The learner's view has no answer key (SAAS-018); the test knows it the way the author does, from the quiz.
    expect(JSON.stringify(view.body.quiz)).not.toMatch(/"correct"|"acceptedAnswers"/);
    const quiz = { questions: await answerKey(quizLesson.id), settings: view.body.quiz.settings as { passMark: number; attempts: number } };
    const correct = Object.fromEntries(quiz.questions.map((q) => [q.id, q.type === 'short' ? (q.acceptedAnswers?.[0] ?? '') : q.correct]));
    const wrong = Object.fromEntries(quiz.questions.map((q) => [q.id, q.type === 'short' ? 'definitely wrong' : []]));

    // A claimed pass with wrong answers is not a pass.
    const fake = await learner.post(`/learning/courses/${course.id}/lessons/${quizLesson.id}/quiz-attempt`, { percent: 100, passed: true, answers: wrong });
    expect(fake.status).toBe(200);
    expect(fake.body).toBeNull();
    const stored = await db.quizAttempt.findFirst({ where: { studentId: learner.studentId }, orderBy: { createdAt: 'desc' } });
    expect(stored?.passed).toBe(false);
    expect(stored?.percent).toBe(0);

    const list = await learner.get('/learning/assessments');
    const row = list.body.find((r: { lessonId: string }) => r.lessonId === quizLesson.id);
    expect(row.state).toBe('failed');
    expect(row.attemptsUsed).toBe(1);

    const real = await learner.post(`/learning/courses/${course.id}/lessons/${quizLesson.id}/quiz-attempt`, { percent: 0, passed: false, answers: correct });
    expect(real.status).toBe(200);
    expect(real.body.snapshot.lessons[quizLesson.id].state).toBe('completed');
    expect((await db.quizAttempt.findFirst({ where: { studentId: learner.studentId }, orderBy: { createdAt: 'desc' } }))?.passed).toBe(true);

    // chapter 2 opens once chapter 1 is finished (assignments excepted)
    const after = await learner.get(`/learning/courses/${course.id}`);
    const chapter2 = course.chapters[1].lessons.filter((l) => l.status === 'published')[0];
    expect(after.body.snapshot.lessons[chapter2.id]?.state ?? 'not-started').not.toBe('locked');

    // attempt limits apply to a learner who has not passed yet
    const other = await newStudent('Limited Learner');
    await other.post(`/learning/courses/${course.id}/enroll`);
    await admin.put('/settings/learning', { ...learning, chapterGate: false, retakeWaitHours: 0 });
    const limit = quiz.settings.attempts || 0;
    if (limit > 0) {
      for (let i = 0; i < limit; i++) await other.post(`/learning/courses/${course.id}/lessons/${quizLesson.id}/quiz-attempt`, { answers: wrong });
      const blocked = await other.post(`/learning/courses/${course.id}/lessons/${quizLesson.id}/quiz-attempt`, { answers: correct });
      expect(blocked.status).toBe(409);
      expect(blocked.body.message).toMatch(/attempts/);
    }
    await admin.put('/settings/learning', { ...learning, chapterGate: true, completionThreshold: 90, courseCompletion: 'all-lessons', retakeWaitHours: 0 });
  });
});

describe('assignments: drafts and hand-in', () => {
  it('saves a draft, returns it with the assignment, and clears it on submission', async () => {
    // A written assignment of its own in the learner's course, so this run's draft and hand-in start clean:
    // file and chart hand-ins have their own rules (assessmentIntegrity.test.ts).
    const written = await db.courseAssignment.create({
      data: { ...T, courseId: course.id, title: `Written hand-in ${Date.now()}`, instructions: 'Answer in writing.', format: 'text', status: 'published' },
    });
    const mine = await learner.get('/learning/assignments');
    const item = mine.body.find((a: { assignment: { id: string } }) => a.assignment.id === written.id);
    expect(item).toBeDefined();
    const id = item.assignment.id as string;
    const saved = await learner.put(`/learning/assignments/${id}/draft`, { text: 'Work in progress on the word problems.', files: [] });
    expect(saved.status).toBe(200);
    const detail = await learner.get(`/learning/assignments/${id}`);
    expect(detail.body.draft.text).toBe('Work in progress on the word problems.');
    expect(['draft', 'overdue']).toContain(detail.body.state);
    expect(typeof detail.body.chapterTitle === 'string' || detail.body.chapterTitle === undefined).toBe(true);

    expect((await learner.post(`/learning/assignments/${id}/submit`, { text: '', files: [] })).status).toBe(409);
    const submitted = await learner.post(`/learning/assignments/${id}/submit`, { text: 'Final answer with the full reading.', files: [] });
    expect(submitted.status).toBe(200);
    expect(submitted.body.state).toBe('submitted');
    expect(submitted.body.draft).toBeUndefined();
    expect((await learner.post(`/learning/assignments/${id}/submit`, { text: 'again', files: [] })).status).toBe(409);
  });
});

describe('course completion', () => {
  it('completes the course under the all-lessons rule once every non-assignment lesson is done', async () => {
    const solo = await newStudent('Finisher');
    await admin.put('/settings/learning', { ...learning, chapterGate: false, completionThreshold: 90, courseCompletion: 'all-lessons', retakeWaitHours: 0 });
    await solo.post(`/learning/courses/${course.id}/enroll`);
    let last: { courseCompleted?: boolean } = {};
    for (const l of published()) {
      if (l.type === 'assignment') continue;
      if (l.type === 'assessment') {
        const view = await solo.get(`/learning/courses/${course.id}/lessons/${l.id}`);
        if (!view.body.quiz) continue;
        const answers = Object.fromEntries((await answerKey(l.id)).map((q) => [q.id, q.type === 'short' ? (q.acceptedAnswers?.[0] ?? '') : q.correct]));
        const r = await solo.post(`/learning/courses/${course.id}/lessons/${l.id}/quiz-attempt`, { answers });
        expect(r.status).toBe(200);
        last = r.body ?? last;
      } else if (l.type === 'video') {
        await solo.put(`/learning/courses/${course.id}/lessons/${l.id}/position`, { positionSec: 1, fraction: 1 });
        last = (await solo.get(`/learning/courses/${course.id}`)).body.progress.state === 'completed' ? { courseCompleted: true } : last;
      } else {
        if (l.type === 'practice')
          await solo.put(`/learning/courses/${course.id}/lessons/${l.id}/note`, {
            text: 'Worked example: 3/4 = 0.75 = 75%, checked on the number line.',
          });
        const r = await solo.post(`/learning/courses/${course.id}/lessons/${l.id}/complete`);
        expect(r.status).toBe(200);
        last = r.body;
      }
    }
    const final = await solo.get(`/learning/courses/${course.id}`);
    expect(final.body.enrollment.status).toBe('completed');
    expect(final.body.enrollment.completedAt).toBeDefined();
    expect(last.courseCompleted ?? final.body.progress.state === 'completed').toBe(true);
    await admin.put('/settings/learning', learning);
  });
});
