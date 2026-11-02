import type { ID, ISODateTime } from './catalog';

export type CertificateState = 'not-eligible' | 'eligible' | 'issued';

export interface CertificateCriterion {
  id: ID;
  label: string;
  current: number;
  required: number;
  /** Display unit — "%", "sessions". */
  unit?: string;
}

export interface CertificateRecord {
  id: ID;
  courseId: ID;
  title: string;
  criteria: CertificateCriterion[];
  issuedAt?: ISODateTime;
  credentialId?: string;
}

export const criterionMet = (c: CertificateCriterion) => c.current >= c.required;

export function certificateState(record: CertificateRecord): CertificateState {
  if (record.issuedAt) return 'issued';
  return record.criteria.every(criterionMet) ? 'eligible' : 'not-eligible';
}

/** Mean completion across criteria, 0–100 — for "how close am I" displays. */
export function criteriaPercent(criteria: CertificateCriterion[]): number {
  if (criteria.length === 0) return 100;
  const sum = criteria.reduce((acc, c) => acc + (c.required === 0 ? 1 : Math.min(1, c.current / c.required)), 0);
  return Math.round((sum / criteria.length) * 100);
}

/* ─── Issuing ──────────────────────────────────────────────────────────── */

/** issued — valid and verifiable · pending — earned, waiting to be issued · revoked — withdrawn */
export type IssuedCertificateStatus = 'issued' | 'pending' | 'revoked';

export interface IssuedCertificate {
  id: ID;
  credentialId: string;
  studentId: ID;
  courseId: ID;
  title: string;
  templateId: ID;
  status: IssuedCertificateStatus;
  completedAt: ISODateTime;
  issuedAt?: ISODateTime;
  revokedAt?: ISODateTime;
  revokedReason?: string;
  /** Final assessment, 0–100. */
  finalScore?: number;
  hours: number;
  /** Times the public verification link has been opened. */
  verifications: number;
}

export type CertificateStyle = 'classic' | 'modern' | 'minimal';
export type CertificateAccent = 'emerald' | 'saffron' | 'indigo';

export interface Signatory {
  name: string;
  title: string;
}

export interface CertificateTemplate {
  id: ID;
  name: string;
  style: CertificateStyle;
  accent: CertificateAccent;
  heading: string;
  /** The line under the learner's name, before the course title. */
  statement: string;
  signatories: Signatory[];
  showScore: boolean;
  showHours: boolean;
  isDefault: boolean;
  updatedAt: ISODateTime;
}

export type CertificateTemplateInput = Omit<CertificateTemplate, 'id' | 'isDefault' | 'updatedAt'>;

export function validateTemplate(input: CertificateTemplateInput): { field: 'name' | 'heading' | 'statement' | 'signatories'; message: string }[] {
  const issues: { field: 'name' | 'heading' | 'statement' | 'signatories'; message: string }[] = [];
  if (input.name.trim().length < 3) issues.push({ field: 'name', message: 'Name the template so admins can tell templates apart.' });
  if (input.heading.trim().length < 3) issues.push({ field: 'heading', message: 'Add the heading printed at the top, such as “Certificate of Completion”.' });
  if (input.statement.trim().length < 6) issues.push({ field: 'statement', message: 'Add the line that introduces the course.' });
  if (input.signatories.length === 0) issues.push({ field: 'signatories', message: 'Add at least one signatory.' });
  else if (input.signatories.some((s) => !s.name.trim() || !s.title.trim()))
    issues.push({ field: 'signatories', message: 'Give every signatory a name and a title.' });
  return issues;
}
