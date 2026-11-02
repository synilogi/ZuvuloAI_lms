import type { ID, ISODateTime } from './catalog';

export type StudentStatus = 'active' | 'at-risk' | 'inactive' | 'suspended';
export type EnrollmentStatus = 'active' | 'completed' | 'paused' | 'expired';
/** How a learner got into a course. `purchase`: a paid course opened by a verified purchase (staff never choose it). */
export type EnrollmentSource = 'self' | 'admin' | 'cohort' | 'scholarship' | 'purchase';

export interface Enrollment {
  id: ID;
  studentId: ID;
  courseId: ID;
  enrolledAt: ISODateTime;
  status: EnrollmentStatus;
  /** 0–100, duration-weighted like course progress. */
  progress: number;
  source: EnrollmentSource;
  lastActiveAt?: ISODateTime;
  completedAt?: ISODateTime;
  lastLessonId?: ID;
  /** When access ends, from the academy's access length; absent for lifetime access. */
  expiresAt?: ISODateTime;
}

export interface Student {
  id: ID;
  name: string;
  email: string;
  phone?: string;
  city: string;
  joinedAt: ISODateTime;
  lastActiveAt: ISODateTime;
  /** Set by an admin; overrides the derived status. */
  suspended?: boolean;
  rankId: ID;
}

const DAY = 86_400_000;

/** A learner with open coursework is at risk after this many quiet days. */
export const AT_RISK_AFTER_DAYS = 10;
/** Nothing opened for this long and the learner reads as inactive. */
export const INACTIVE_AFTER_DAYS = 45;

/**
 * Engagement status. At risk means there is unfinished work and the learner has gone quiet —
 * someone with nothing in progress is simply inactive, not at risk.
 */
/** `atRiskDays` is the academy's `settings.learning.atRiskDays`; the default matches the demo. */
export function deriveStudentStatus(student: Student, enrollments: Enrollment[], now: Date, atRiskDays = AT_RISK_AFTER_DAYS): StudentStatus {
  if (student.suspended) return 'suspended';
  const quietDays = (now.getTime() - new Date(student.lastActiveAt).getTime()) / DAY;
  const hasOpenWork = enrollments.some((e) => e.status === 'active');
  if (quietDays >= INACTIVE_AFTER_DAYS) return 'inactive';
  if (hasOpenWork && quietDays >= atRiskDays) return 'at-risk';
  if (!hasOpenWork && quietDays >= atRiskDays) return 'inactive';
  return 'active';
}

/** Share of finished enrollments among those old enough to have finished, 0–100. */
export function completionRate(enrollments: Enrollment[]): number {
  const settled = enrollments.filter((e) => e.status !== 'paused');
  if (settled.length === 0) return 0;
  return Math.round((settled.filter((e) => e.status === 'completed').length / settled.length) * 100);
}
