import type { CertificateTemplate, IssuedCertificate } from '@syniastrolms/domain';
import { courseDurationMin } from '@syniastrolms/domain';
import { hashSeed, toIST } from '../random';
import { courses } from './catalog';
import { DEMO_NOW } from './learner';
import { enrollments } from './people';

/**
 * Certificates as the academy issues them. Every completed enrollment in a course that awards a
 * certificate has one: issued, waiting to be issued (finished in the last ten days), or — rarely —
 * revoked after a review.
 */

const NOW = new Date(DEMO_NOW).getTime();
const DAY = 86_400_000;

export const certificateTemplates: CertificateTemplate[] = [
  {
    id: 'tpl-classic',
    name: 'Classic seal',
    style: 'classic',
    accent: 'emerald',
    heading: 'Certificate of Completion',
    statement: 'has completed the course of study in',
    signatories: [
      { name: 'Dr. Meenakshi Iyer', title: 'Dean of Studies' },
      { name: 'Kavita Menon', title: 'Academy Director' },
    ],
    showScore: true,
    showHours: true,
    isDefault: true,
    updatedAt: '2026-07-18T11:00:00+05:30',
  },
  {
    id: 'tpl-cohort',
    name: 'Cohort achievement',
    style: 'modern',
    accent: 'saffron',
    heading: 'Certificate of Achievement',
    statement: 'has completed the cohort programme and final project in',
    signatories: [
      { name: 'Pt. Sanjay Rathore', title: 'Programme Lead' },
      { name: 'Kavita Menon', title: 'Academy Director' },
    ],
    showScore: false,
    showHours: true,
    isDefault: false,
    updatedAt: '2026-08-30T16:20:00+05:30',
  },
  {
    id: 'tpl-foundation',
    name: 'Foundation courses',
    style: 'minimal',
    accent: 'indigo',
    heading: 'Certificate of Completion',
    statement: 'has completed',
    signatories: [{ name: 'Kavita Menon', title: 'Academy Director' }],
    showScore: true,
    showHours: false,
    isDefault: false,
    updatedAt: '2026-05-02T10:00:00+05:30',
  },
];

/** Which template each course prints on. Courses not listed use the default. */
export const courseTemplate: Record<string, string> = {
  muhurta: 'tpl-cohort',
  jaimini: 'tpl-cohort',
  'intro-jyotish': 'tpl-foundation',
  panchang: 'tpl-foundation',
};

export const templateFor = (courseId: string) => courseTemplate[courseId] ?? certificateTemplates.find((t) => t.isDefault)?.id ?? 'tpl-classic';

const CODES: Record<string, string> = {
  'foundations-vedic': 'VF',
  'intro-jyotish': 'JY',
  panchang: 'PC',
  'nakshatra-depth': 'NK',
  dasha: 'DA',
  yogas: 'CS',
  navamsha: 'DC',
  gochara: 'TR',
  jaimini: 'JA',
  'kp-system': 'KP',
  muhurta: 'MU',
};

const REVOKE_REASONS = ['Final project found to be substantially copied', 'Enrollment refunded after completion', 'Issued in error — duplicate account merged'];

/** The demo learner's own certificates, as her screens describe them. */
const PINNED: Record<string, Partial<IssuedCertificate>> = {
  'u-ananya:intro-jyotish': { status: 'issued', issuedAt: '2026-06-02T12:00:00+05:30', credentialId: 'SA-JY-2026-04817', finalScore: 88, verifications: 3 },
  'u-ananya:panchang': { status: 'pending', issuedAt: undefined, finalScore: 81, verifications: 0 },
};

function generate(): IssuedCertificate[] {
  const out: IssuedCertificate[] = [];
  for (const e of enrollments) {
    if (e.status !== 'completed' || !e.completedAt) continue;
    const course = courses.find((c) => c.id === e.courseId);
    if (!course?.certificateTitle) continue;
    const h = hashSeed(`${e.studentId}:${e.courseId}`);
    const completed = new Date(e.completedAt).getTime();
    // Most certificates issue on completion; about a third of recent ones wait for an admin's check.
    const recent = NOW - completed < 10 * DAY && h % 3 === 0;
    const revoked = !recent && h % 397 === 0;
    const issuedAt = completed + (1 + (h % 3)) * DAY;
    const year = new Date(issuedAt).getFullYear();
    const cert: IssuedCertificate = {
      id: `cert-${e.id}`,
      credentialId: `SA-${CODES[course.id] ?? 'SA'}-${year}-${String(h % 100000).padStart(5, '0')}`,
      studentId: e.studentId,
      courseId: course.id,
      title: course.certificateTitle,
      templateId: templateFor(course.id),
      status: recent ? 'pending' : revoked ? 'revoked' : 'issued',
      completedAt: e.completedAt,
      issuedAt: recent ? undefined : toIST(new Date(Math.min(issuedAt, NOW - 3_600_000))),
      revokedAt: revoked ? toIST(new Date(Math.min(issuedAt + 40 * DAY, NOW - DAY))) : undefined,
      revokedReason: revoked ? REVOKE_REASONS[h % REVOKE_REASONS.length] : undefined,
      finalScore: 70 + (h % 29),
      hours: Math.max(1, Math.round(courseDurationMin(course) / 60)),
      verifications: recent ? 0 : h % 23,
    };
    Object.assign(cert, PINNED[`${e.studentId}:${e.courseId}`] ?? {});
    out.push(cert);
  }
  return out.sort((a, b) => (b.issuedAt ?? b.completedAt).localeCompare(a.issuedAt ?? a.completedAt));
}

let store: IssuedCertificate[] | undefined;
/** Built on first use; issuing and revoking change these records in place. */
export const issuedCertificates = () => (store ??= generate());
