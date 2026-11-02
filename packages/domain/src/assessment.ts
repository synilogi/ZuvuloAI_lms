import type { ID, ISODateTime } from './catalog';

export type AssessmentState = 'locked' | 'available' | 'in-progress' | 'submitted' | 'passed' | 'failed';

export interface Assessment {
  id: ID;
  courseId: ID;
  title: string;
  questions: number;
  durationMin: number;
  /** Percentage required to pass, 0–100. */
  passMark: number;
  attemptsAllowed: number;
  attemptsUsed: number;
  state: AssessmentState;
  lockedReason?: string;
  /** Latest attempt score, 0–100. */
  score?: number;
  answered?: number;
  retakeAvailableAt?: ISODateTime;
}

export function attemptsRemaining(a: Assessment) {
  return Math.max(0, a.attemptsAllowed - a.attemptsUsed);
}
