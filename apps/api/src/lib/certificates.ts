import { creditedPercent, type CertificateCriterion, type CertificateRecord, type Course } from '@syniastrolms/domain';

import { db } from './db.js';
import { runAsPlatform, tenant } from './tenancy.js';
import { readJson } from './json.js';
import { notify } from './notify.js';
import { getSettings } from './settings.js';

/**
 * Certificates: created when a learner completes a course (per the academy's certificate settings),
 * with the credential id, hours and final score derived here. Issuing/revoking and the public
 * verification live in the certificates router.
 */

/** Mean of the learner's best quiz percentages and graded assignment percentages in a course; null without any. */
export async function finalScoreFor(studentId: string, courseId: string): Promise<number | null> {
  const quizzes = await db.quiz.findMany({ where: { courseId, status: 'published', lessonId: { not: null } }, select: { id: true } });
  const bests: number[] = [];
  for (const q of quizzes) {
    const attempts = await db.quizAttempt.findMany({ where: { quizId: q.id, studentId }, select: { percent: true, passed: true, createdAt: true } });
    // Practice retakes after a pass never raise it: they are taken with the answers already shown.
    const credited = creditedPercent(attempts);
    if (credited !== undefined) bests.push(credited);
  }
  const graded = await db.submission.findMany({
    where: { studentId, reviewStatus: 'graded', score: { not: null }, assignment: { courseId, status: { not: 'draft' } } },
    include: { assignment: { select: { maxScore: true, rubricJson: true } } },
  });
  const assignmentPercents = graded.map((s) => {
    const rubric = readJson<{ points?: number }[]>(s.assignment.rubricJson, []);
    const max = rubric.length ? rubric.reduce((n, c) => n + (c.points ?? 0), 0) : s.assignment.maxScore;
    return max > 0 ? Math.min(100, ((s.score ?? 0) / max) * 100) : 0;
  });
  const all = [...bests, ...assignmentPercents];
  return all.length ? Math.round(all.reduce((n, v) => n + v, 0) / all.length) : null;
}

/** Learning hours = published lesson minutes / 60, to the nearest half hour. */
export function hoursFor(course: Pick<Course, 'chapters'>): number {
  const minutes = course.chapters
    .flatMap((c) => c.lessons)
    .filter((l) => l.status === 'published')
    .reduce((n, l) => n + l.durationMin, 0);
  return Math.max(0.5, Math.round((minutes / 60) * 2) / 2);
}

/** Two-letter course code from the title's first significant words, e.g. "Class Mathematics" → CM. */
export function courseCode(title: string): string {
  const stop = new Set(['the', 'of', 'and', 'a', 'an', 'to', 'in', 'for', 'introduction', 'intro']);
  const words = title.split(/[^A-Za-z]+/).filter((w) => w && !stop.has(w.toLowerCase()));
  const code = (words.length >= 2 ? words[0][0] + words[1][0] : (words[0] ?? 'CR').slice(0, 2)).toUpperCase();
  return code.padEnd(2, 'X');
}

/**
 * `<prefix>-<course code>-<year>-<5 digits>`, unique across the platform (D4): verification links
 * carry no academy, so two academies with the same prefix must never be handed the same number. The
 * count that picks a starting point is this academy's; the uniqueness check spans every academy.
 */
export async function nextCredentialId(courseTitle: string, prefix: string): Promise<string> {
  const year = new Date().getFullYear();
  const base = `${prefix}-${courseCode(courseTitle)}-${year}-`;
  let n = (await db.issuedCertificate.count({ where: { credentialId: { startsWith: `${prefix}-` }, completedAt: { gte: new Date(year, 0, 1) } } })) + 1;
  for (let tries = 0; tries < 50; tries++, n++) {
    const candidate = `${base}${String(n).padStart(5, '0')}`;
    const taken = await runAsPlatform('a credential ID is unique across the platform (D4)', () =>
      db.issuedCertificate.findUnique({ where: { credentialId: candidate }, select: { id: true } }),
    );
    if (!taken) return candidate;
  }
  return `${base}${Date.now().toString().slice(-5)}`;
}

/** The template a course's certificates print on: the course's own, else the academy default. */
export async function templateFor(courseId: string): Promise<string | null> {
  const course = await db.course.findUnique({ where: { id: courseId }, select: { certificateTemplateId: true } });
  if (course?.certificateTemplateId) return course.certificateTemplateId;
  const { certificates } = await getSettings();
  if (certificates.defaultTemplateId && (await db.certificateTemplate.findUnique({ where: { id: certificates.defaultTemplateId }, select: { id: true } })))
    return certificates.defaultTemplateId;
  const fallback = (await db.certificateTemplate.findFirst({ where: { isDefault: true } })) ?? (await db.certificateTemplate.findFirst());
  return fallback?.id ?? null;
}

/**
 * Called when a learner completes a course. Creates the certificate as `pending` (or `issued` when
 * the academy auto-issues) when certificates are enabled and the final score meets `minScore`.
 */
export async function onCourseCompleted(studentId: string, course: Course): Promise<void> {
  const { certificates } = await getSettings();
  if (!certificates.enabled) return;
  const existing = await db.issuedCertificate.findFirst({ where: { studentId, courseId: course.id }, select: { id: true } });
  if (existing) return;
  const finalScore = await finalScoreFor(studentId, course.id);
  if (finalScore !== null && finalScore < certificates.minScore) return;
  const templateId = await templateFor(course.id);
  if (!templateId) return;

  const issued = certificates.autoIssue;
  const row = await db.issuedCertificate.create({
    data: {
      ...tenant(),
      credentialId: await nextCredentialId(course.title, certificates.credentialPrefix || 'SA'),
      studentId,
      courseId: course.id,
      title: course.certificateTitle ?? `Certificate in ${course.title}`,
      templateId,
      status: issued ? 'issued' : 'pending',
      completedAt: new Date(),
      issuedAt: issued ? new Date() : null,
      finalScore,
      hours: hoursFor(course),
    },
  });
  const student = await db.student.findUnique({ where: { id: studentId }, select: { userId: true } });
  if (student && (issued || certificates.autoIssue === false)) {
    await notify({
      recipientUserId: student.userId,
      category: 'certificate',
      title: issued ? `Your certificate for ${course.title} has been issued` : `Your certificate for ${course.title} is ready to claim`,
      summary: issued
        ? `Credential ${row.credentialId} — download and share it from your certificates.`
        : 'You finished the course. Claim the certificate to add it to your wallet.',
      important: true,
      facts: [
        { label: 'Credential', value: row.credentialId },
        ...(finalScore !== null ? [{ label: 'Final score', value: `${finalScore}%` }] : []),
        { label: 'Hours', value: String(row.hours) },
      ],
      action: { label: issued ? 'View certificate' : 'Claim certificate', to: `/certificates/${row.id}` },
      switch: 'learner.certificateIssued',
    });
  }
}

/** Courses the learner is still working through that award a certificate, with how close they are. */
export async function workingTowards(studentId: string): Promise<CertificateRecord[]> {
  const { certificates, learning } = await getSettings();
  if (!certificates.enabled) return [];
  const enrollments = await db.enrollment.findMany({
    where: { studentId, status: 'active' },
    include: { course: { include: { chapters: { include: { lessons: { select: { status: true, type: true, durationMin: true } } } } } } },
  });
  const earned = new Set((await db.issuedCertificate.findMany({ where: { studentId }, select: { courseId: true } })).map((c) => c.courseId));
  const out: CertificateRecord[] = [];
  for (const e of enrollments) {
    if (earned.has(e.courseId)) continue;
    const criteria: CertificateCriterion[] = [
      {
        id: 'progress',
        label: 'Course progress',
        current: e.progress,
        required: learning.courseCompletion === 'percentage' ? learning.completionPercent : 100,
        unit: '%',
      },
    ];
    const assignments = await db.courseAssignment.findMany({ where: { courseId: e.courseId, status: 'published' }, select: { id: true, passMark: true } });
    if (assignments.length) {
      const passed = await db.submission.count({
        where: {
          studentId,
          reviewStatus: 'graded',
          assignment: { courseId: e.courseId, status: 'published' },
          score: { gte: Math.min(...assignments.map((a) => a.passMark)) },
        },
      });
      criteria.push({ id: 'assignments', label: 'Assignments passed', current: Math.min(passed, assignments.length), required: assignments.length });
    }
    const hasQuizzes = (await db.quiz.count({ where: { courseId: e.courseId, status: 'published', lessonId: { not: null } } })) > 0;
    if (certificates.minScore > 0 && (hasQuizzes || assignments.length)) {
      criteria.push({
        id: 'final',
        label: 'Final score',
        current: (await finalScoreFor(studentId, e.courseId)) ?? 0,
        required: certificates.minScore,
        unit: '%',
      });
    }
    out.push({ id: `working-${e.courseId}`, courseId: e.courseId, title: e.course.certificateTitle ?? `Certificate in ${e.course.title}`, criteria });
  }
  return out;
}

/** The learner's certificate record for a course as the course page shows it (issued, or the criteria so far). */
export async function certificateRecordFor(studentId: string, courseId: string): Promise<CertificateRecord | undefined> {
  const issued = await db.issuedCertificate.findFirst({ where: { studentId, courseId, status: { not: 'revoked' } } });
  if (issued) {
    return {
      id: issued.id,
      courseId,
      title: issued.title,
      criteria: [],
      issuedAt: issued.issuedAt?.toISOString(),
      credentialId: issued.status === 'issued' ? issued.credentialId : undefined,
    };
  }
  return (await workingTowards(studentId)).find((r) => r.courseId === courseId);
}
