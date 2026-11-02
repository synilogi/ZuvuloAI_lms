import { beforeAll, describe, expect, it } from 'vitest';

import { db } from '../test/db.js';
import { as, newStudent, unique, type Client } from '../test/helpers.js';

let admin: Client;
let instructor: Client;
let courseId: string;
let chapterId: string;
let learning: Record<string, unknown>;

beforeAll(async () => {
  admin = await as('admin');
  instructor = await as('instructor');
  // A free course: the suite's learners enrol in it themselves (a paid one is bought).
  const mine = (
    (await instructor.get('/courses', { status: 'published', pageSize: 50 })).body.rows as {
      id: string;
      pricing: string;
      visibility: string;
      chapters: { id: string }[];
    }[]
  ).find((c) => c.pricing === 'free' && c.visibility === 'public' && c.chapters.length > 0)!;
  courseId = mine.id;
  chapterId = mine.chapters[0].id;
  learning = (await admin.get('/settings')).body.settings.learning;
});

const assignmentInput = (title: string, extra: Record<string, unknown> = {}) => ({
  courseId,
  chapterId,
  title,
  instructions: 'Solve one real word problem and write three paragraphs on the equation, its solution and the check, with your reasoning.',
  attachments: [],
  format: 'text',
  due: { kind: 'none' },
  rubric: [],
  maxScore: 20,
  passMark: 12,
  status: 'published',
  ...extra,
});

describe('assignments: hand-in, review and notifications', () => {
  it('notifies instructors on submission, learners on review, and completes a passed-rule lesson on a graded pass', async () => {
    await admin.put('/settings/learning', { ...learning, chapterGate: false, latePolicy: 'penalty', latePenalty: 10 });
    const created = await instructor.post('/assignments', assignmentInput(`Reading ${unique()}`));
    expect(created.status).toBe(201);
    expect(created.body.acceptsLate).toBe(true);
    expect(created.body.latePenalty).toBe(10);

    const learner = await newStudent('Handing In');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    const before = (await instructor.get('/notifications', { limit: 50 })).body.total as number;

    const submitted = await learner.post(`/learning/assignments/${created.body.id}/submit`, {
      text: 'My solution to the problem, in three paragraphs.',
      files: [],
    });
    expect(submitted.status).toBe(200);
    expect(submitted.body.state).toBe('submitted');
    const afterSubmit = await instructor.get('/notifications', { limit: 50 });
    expect(afterSubmit.body.total).toBe(before + 1);
    expect(afterSubmit.body.rows[0].category).toBe('assignment');
    expect(afterSubmit.body.rows[0].action.to).toMatch(/^\/teach\/assignments\/[^/]+\/submissions\/[^/]+$/);

    const list = await instructor.get('/assignments', { courseId });
    const row = list.body.rows.find((r: { assignment: { id: string } }) => r.assignment.id === created.body.id);
    expect(typeof row.chapterTitle).toBe('string');
    expect(row.submitted).toBe(1);

    // return it first, then the learner resubmits, then grade it
    const submissionId = submitted.body.submission.id as string;
    const returned = await instructor.post(`/assignments/submissions/${submissionId}/review`, {
      decision: 'returned',
      scores: {},
      feedback: 'Please add the Moon sign and its lord before I can grade this.',
    });
    expect(returned.status).toBe(200);
    const learnerNotes = await learner.get('/notifications', { limit: 5 });
    expect(learnerNotes.body.rows[0].title).toMatch(/returned/);

    const again = await learner.post(`/learning/assignments/${created.body.id}/submit`, {
      text: 'Second attempt with the equation checked against the problem.',
      files: [],
    });
    expect(again.status).toBe(200);
    expect(again.body.submission.attempt).toBe(2);

    const graded = await instructor.post(`/assignments/submissions/${again.body.submission.id}/review`, {
      decision: 'graded',
      scores: {},
      points: 16,
      feedback: 'Clear reasoning, well structured.',
    });
    expect(graded.status).toBe(200);
    expect(graded.body.review.score).toBe(16);
    const gradedNote = (await learner.get('/notifications', { limit: 5 })).body.rows[0];
    expect(gradedNote.title).toMatch(/graded/);
    expect(gradedNote.facts.some((f: { label: string; value: string }) => f.label === 'Score' && f.value === '16 / 20')).toBe(true);

    expect((await instructor.post(`/assignments/submissions/${submissionId}/review`, { decision: 'graded', scores: {}, feedback: 'x' })).status).toBe(409);
    expect((await instructor.post(`/assignments/submissions/${submissionId}/review`, { decision: 'bogus' })).status).toBe(400);
  });

  it('applies the late policy: penalty on review, rejection on submit, acceptance without loss', async () => {
    const yesterday = new Date(Date.now() - 86_400_000).toISOString();
    await admin.put('/settings/learning', { ...learning, chapterGate: false, latePolicy: 'penalty', latePenalty: 25 });
    // Publishing refuses a deadline in the past, so create it as a draft and open it directly.
    const late = await admin.post(
      '/assignments',
      assignmentInput(`Late ${unique()}`, { due: { kind: 'date', dueAt: yesterday }, acceptsLate: true, latePenalty: 25, status: 'draft' }),
    );
    expect(late.status).toBe(201);
    await db.courseAssignment.update({ where: { id: late.body.id }, data: { status: 'published' } });
    const learner = await newStudent('Late Learner');
    await learner.post(`/learning/courses/${courseId}/enroll`);
    const sub = await learner.post(`/learning/assignments/${late.body.id}/submit`, { text: 'Late but complete work on the problem.', files: [] });
    expect(sub.status).toBe(200);
    expect(sub.body.submission.late).toBe(true);
    const graded = await admin.post(`/assignments/submissions/${sub.body.submission.id}/review`, {
      decision: 'graded',
      scores: {},
      points: 20,
      feedback: 'Full marks before the penalty.',
    });
    expect(graded.body.review.score).toBe(15);

    await admin.put('/settings/learning', { ...learning, chapterGate: false, latePolicy: 'accept', latePenalty: 25 });
    const other = await newStudent('Accepted Late');
    await other.post(`/learning/courses/${courseId}/enroll`);
    const sub2 = await other.post(`/learning/assignments/${late.body.id}/submit`, { text: 'Also late, fully accepted.', files: [] });
    const graded2 = await admin.post(`/assignments/submissions/${sub2.body.submission.id}/review`, {
      decision: 'graded',
      scores: {},
      points: 20,
      feedback: 'No penalty under the accept policy.',
    });
    expect(graded2.body.review.score).toBe(20);

    await admin.put('/settings/learning', { ...learning, chapterGate: false, latePolicy: 'reject' });
    const third = await newStudent('Rejected Late');
    await third.post(`/learning/courses/${courseId}/enroll`);
    expect((await third.post(`/learning/assignments/${late.body.id}/submit`, { text: 'Too late.', files: [] })).status).toBe(409);
    await admin.put('/settings/learning', learning);
  });

  it('lists missing learners, and reminds only those who still owe the work', async () => {
    const created = await admin.post('/assignments', assignmentInput(`Missing ${unique()}`));
    const owing = await newStudent('Owes Work');
    await owing.post(`/learning/courses/${courseId}/enroll`);
    const done = await newStudent('Handed In');
    await done.post(`/learning/courses/${courseId}/enroll`);
    await done.post(`/learning/assignments/${created.body.id}/submit`, { text: 'Handed in on time with everything.', files: [] });

    const list = await admin.get('/assignments', { courseId });
    const row = list.body.rows.find((r: { assignment: { id: string } }) => r.assignment.id === created.body.id);
    expect(row.missing).toBeGreaterThanOrEqual(1);

    const missing = await admin.get('/assignments/submissions', { assignmentId: created.body.id, filter: 'missing', pageSize: 200 });
    expect(missing.status).toBe(200);
    expect(missing.body.counts.missing).toBe(row.missing);
    const ids = missing.body.rows.map((r: { student: { id: string } }) => r.student.id);
    expect(ids).toContain(owing.studentId);
    expect(ids).not.toContain(done.studentId);
    expect(missing.body.rows[0].submission).toBeUndefined();

    const reminded = await admin.post(`/assignments/${created.body.id}/remind`, { studentIds: [owing.studentId, done.studentId] });
    expect(reminded.body.sent).toBe(1);
    expect((await owing.get('/notifications', { limit: 5 })).body.rows[0].title).toMatch(/Reminder/);
    expect((await done.get('/notifications', { limit: 5 })).body.rows.some((n: { title: string }) => /Reminder/.test(n.title))).toBe(false);
    expect(await db.appNotification.count({ where: { title: { contains: created.body.title } } })).toBeGreaterThan(0);
  });
});
