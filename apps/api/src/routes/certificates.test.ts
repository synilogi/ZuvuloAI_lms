import { beforeAll, describe, expect, it } from 'vitest';

import { db } from '../test/db.js';
import { anon, as, newStudent, type Client } from '../test/helpers.js';

let admin: Client;
let course: { id: string; title: string; chapters: { lessons: { id: string; type: string; status: string }[] }[] };
let learning: Record<string, unknown>;
let certSettings: Record<string, unknown>;

const published = () => course.chapters.flatMap((c) => c.lessons.filter((l) => l.status === 'published'));

/** Finishes every non-assignment lesson of the course for the learner, passing quizzes with the right answers. */
async function finishCourse(learner: Client & { studentId: string }) {
  await learner.post(`/learning/courses/${course.id}/enroll`);
  for (const l of published()) {
    if (l.type === 'assignment') continue;
    if (l.type === 'assessment') {
      const view = await learner.get(`/learning/courses/${course.id}/lessons/${l.id}`);
      if (!view.body.quiz) continue;
      // The key comes from the quiz, as its author knows it: a learner's view never carries it (SAAS-018).
      const key = JSON.parse((await db.quiz.findUniqueOrThrow({ where: { lessonId: l.id } })).questionsJson);
      const answers = Object.fromEntries(
        (key as { id: string; type: string; correct: string[]; acceptedAnswers?: string[] }[]).map((q) => [
          q.id,
          q.type === 'short' ? (q.acceptedAnswers?.[0] ?? '') : q.correct,
        ]),
      );
      await learner.post(`/learning/courses/${course.id}/lessons/${l.id}/quiz-attempt`, { answers });
    } else if (l.type === 'video') {
      await learner.put(`/learning/courses/${course.id}/lessons/${l.id}/position`, { positionSec: 1, fraction: 1 });
    } else {
      if (l.type === 'practice')
        await learner.put(`/learning/courses/${course.id}/lessons/${l.id}/note`, { text: 'Detailed working for the practice exercise, as required.' });
      await learner.post(`/learning/courses/${course.id}/lessons/${l.id}/complete`);
    }
  }
  return (await learner.get(`/learning/courses/${course.id}`)).body;
}

beforeAll(async () => {
  admin = await as('admin');
  const catalog = (await admin.get('/catalog/courses')).body as (typeof course)[];
  course = catalog.find((c) => c.title.includes('Foundations')) ?? catalog[0];
  learning = (await admin.get('/settings')).body.settings.learning;
  certSettings = (await admin.get('/settings')).body.settings.certificates;
  await admin.put('/settings/learning', { ...learning, chapterGate: false, retakeWaitHours: 0, courseCompletion: 'all-lessons' });
});

describe('certificates: created on completion', () => {
  it('creates a pending certificate with a credential id, score and hours; the learner claims it', async () => {
    await admin.put('/settings/certificates', {
      ...certSettings,
      enabled: true,
      autoIssue: false,
      minScore: 60,
      publicVerification: true,
      credentialPrefix: 'SA',
    });
    const learner = await newStudent('Graduate');
    const done = await finishCourse(learner);
    expect(done.enrollment.status).toBe('completed');
    expect(done.certificate).toBeDefined();

    const wallet = await learner.get('/learning/certificates');
    expect(wallet.body.pending).toHaveLength(1);
    const cert = wallet.body.pending[0].certificate;
    expect(cert.credentialId).toMatch(/^SA-[A-Z]{2}-\d{4}-\d{5}$/);
    expect(cert.finalScore).toBeGreaterThanOrEqual(60);
    expect(cert.hours).toBeGreaterThan(0);
    expect((await learner.get('/notifications', { limit: 5 })).body.rows[0].category).toBe('certificate');

    // not verifiable while pending
    expect((await anon().get(`/certificates/verify/${cert.credentialId}`)).status).toBe(404);
    const claimed = await learner.post(`/learning/certificates/${cert.id}/claim`);
    expect(claimed.status).toBe(200);
    expect(claimed.body.certificate.status).toBe('issued');
    const verified = await anon().get(`/certificates/verify/${cert.credentialId}`);
    expect(verified.status).toBe(200);
    expect(verified.body.certificate.verifications).toBe(0);
    expect((await anon().get(`/certificates/verify/${cert.credentialId}`)).body.certificate.verifications).toBe(1);
    expect(verified.body.student.email).toBeDefined(); // shown only to staff/learner screens; verify still returns the printed detail shape
  });

  it('issues immediately when autoIssue is on, and creates nothing when certificates are disabled or the score is too low', async () => {
    await admin.put('/settings/certificates', { ...certSettings, enabled: true, autoIssue: true, minScore: 0 });
    const auto = await newStudent('Auto Issued');
    await finishCourse(auto);
    const wallet = await auto.get('/learning/certificates');
    expect(wallet.body.issued).toHaveLength(1);
    expect(wallet.body.pending).toHaveLength(0);

    await admin.put('/settings/certificates', { ...certSettings, enabled: false });
    const none = await newStudent('No Certificate');
    await finishCourse(none);
    expect((await none.get('/learning/certificates')).body.issued.length + (await none.get('/learning/certificates')).body.pending.length).toBe(0);

    await admin.put('/settings/certificates', { ...certSettings, enabled: true, autoIssue: false, minScore: 101 });
    const low = await newStudent('Below Minimum');
    await finishCourse(low);
    expect(await db.issuedCertificate.count({ where: { studentId: low.studentId } })).toBe(0);
    await admin.put('/settings/certificates', certSettings);
  });

  it('shows what an active learner is still working towards', async () => {
    await admin.put('/settings/certificates', { ...certSettings, enabled: true, minScore: 60 });
    const learner = await newStudent('Still Working');
    await learner.post(`/learning/courses/${course.id}/enroll`);
    const wallet = await learner.get('/learning/certificates');
    expect(wallet.body.working).toHaveLength(1);
    const record = wallet.body.working[0];
    expect(record.courseId).toBe(course.id);
    const progress = record.criteria.find((c: { id: string }) => c.id === 'progress');
    expect(progress).toMatchObject({ current: 0, required: 100, unit: '%' });
    expect(record.criteria.some((c: { id: string }) => c.id === 'final')).toBe(true);
    const page = await learner.get(`/learning/courses/${course.id}`);
    expect(page.body.certificate.criteria.length).toBeGreaterThan(0);
    await admin.put('/settings/certificates', certSettings);
  });
});

describe('certificates: staff actions', () => {
  it('revokes with a reason (notifying the learner), verifies as revoked, restores, and respects publicVerification', async () => {
    const list = await admin.get('/certificates', { status: 'issued', pageSize: 5 });
    const row = list.body.rows[0];
    expect((await admin.post(`/certificates/${row.certificate.id}/revoke`, { reason: '' })).status).toBe(400);
    const revoked = await admin.post(`/certificates/${row.certificate.id}/revoke`, { reason: 'Issued to the wrong learner by mistake.' });
    expect(revoked.status).toBe(200);
    expect(revoked.body.status).toBe('revoked');
    const asRevoked = await anon().get(`/certificates/verify/${row.certificate.credentialId}`);
    expect(asRevoked.body.certificate.status).toBe('revoked');
    const learnerUser = await db.student.findUnique({ where: { id: row.certificate.studentId }, select: { userId: true } });
    expect(await db.appNotification.count({ where: { recipientId: learnerUser!.userId, title: { contains: 'revoked' } } })).toBeGreaterThan(0);
    expect((await admin.post(`/certificates/${row.certificate.id}/restore`)).body.status).toBe('issued');
    expect((await admin.post(`/certificates/${row.certificate.id}/restore`)).status).toBe(409);
    expect((await admin.post(`/certificates/${row.certificate.id}/issue`)).status).toBe(409);

    await admin.put('/settings/certificates', { ...certSettings, publicVerification: false });
    expect((await anon().get(`/certificates/verify/${row.certificate.credentialId}`)).status).toBe(404);
    await admin.put('/settings/certificates', certSettings);
    await admin.put('/settings/learning', learning);
  });
});
