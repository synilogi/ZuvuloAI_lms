import type { ID, ISODateTime } from './catalog';

export type ActivityKind =
  | 'enrolled'
  | 'lesson-completed'
  | 'chapter-completed'
  | 'live-attended'
  | 'assignment-submitted'
  | 'assessment-passed'
  | 'certificate-issued'
  | 'rank-achieved';

export interface LearningEvent {
  id: ID;
  kind: ActivityKind;
  title: string;
  context?: string;
  at: ISODateTime;
}

export interface StudyDay {
  /** YYYY-MM-DD */
  date: string;
  minutes: number;
}
