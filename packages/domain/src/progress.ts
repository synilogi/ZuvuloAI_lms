import type { Chapter, Course, ID, ISODateTime, Lesson } from './catalog';
import type { ProgressState } from './status';

export interface LessonProgress {
  lessonId: ID;
  state: ProgressState;
  /** 0–1 for partially consumed lessons (video watched, reading scrolled). */
  fraction?: number;
  /** Resume position in seconds for video lessons. */
  positionSec?: number;
  completedAt?: ISODateTime;
}

export interface CourseProgressSnapshot {
  courseId: ID;
  lessons: Record<ID, LessonProgress>;
  lastLessonId?: ID;
  lastActiveAt?: ISODateTime;
}

export interface ProgressSummary {
  completed: number;
  total: number;
  /** 0–100, weighted by lesson duration — a 40-minute lesson counts more than a 5-minute one. */
  percent: number;
  remainingMin: number;
  state: ProgressState;
}

export const clampPercent = (value: number) => Math.max(0, Math.min(100, value));

export function lessonState(lessonId: ID, snapshot?: CourseProgressSnapshot): ProgressState {
  return snapshot?.lessons[lessonId]?.state ?? 'not-started';
}

function summarise(lessons: Lesson[], snapshot?: CourseProgressSnapshot): ProgressSummary {
  const total = lessons.length;
  let completed = 0;
  let doneMin = 0;
  let totalMin = 0;
  let started = false;
  let allLocked = total > 0;

  for (const lesson of lessons) {
    totalMin += lesson.durationMin;
    const p = snapshot?.lessons[lesson.id];
    if (p?.state !== 'locked') allLocked = false;
    if (p?.state === 'completed') {
      completed += 1;
      doneMin += lesson.durationMin;
      started = true;
    } else if (p?.state === 'in-progress') {
      doneMin += lesson.durationMin * (p.fraction ?? 0);
      started = true;
    }
  }

  const percent = totalMin === 0 ? 0 : clampPercent(Math.round((doneMin / totalMin) * 100));
  const state: ProgressState = total > 0 && completed === total ? 'completed' : started ? 'in-progress' : allLocked ? 'locked' : 'not-started';

  return { completed, total, percent, remainingMin: Math.max(0, Math.round(totalMin - doneMin)), state };
}

export function chapterProgress(chapter: Chapter, snapshot?: CourseProgressSnapshot): ProgressSummary {
  return summarise(chapter.lessons, snapshot);
}

export function courseProgress(course: Course, snapshot?: CourseProgressSnapshot): ProgressSummary {
  return summarise(
    course.chapters.flatMap((c) => c.lessons),
    snapshot,
  );
}
