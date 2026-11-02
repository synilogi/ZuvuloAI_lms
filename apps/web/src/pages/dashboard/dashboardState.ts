import type { DashboardSnapshot } from '@syniastrolms/domain';

/*
 * What the dashboard decides before it draws: whether there is anything to chart yet, and how far a new academy
 * has got with setting itself up. Pure, so each can be checked on its own.
 */

/**
 * Nothing has happened yet: no learners and no enrolments. Charts of zeros would read as a failing academy, so
 * the dashboard shows the way to get started instead — even when a draft course already exists.
 */
export const isNewAcademy = (snapshot: Pick<DashboardSnapshot, 'kpis' | 'enrollments'>) =>
  snapshot.kpis.students.value === 0 && snapshot.enrollments.every((p) => p.value === 0);

export type SetupStepId = 'course' | 'instructor';

export interface SetupStep {
  id: SetupStepId;
  done: boolean;
}

/** The new platform's checklist, in order: its first course and its first instructor. */
export function setupSteps({ courses, instructors }: { courses: number; instructors: number }): SetupStep[] {
  return [
    { id: 'course', done: courses > 0 },
    { id: 'instructor', done: instructors > 0 },
  ];
}
