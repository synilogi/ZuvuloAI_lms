import { courseProgress, defaultCompletion, type Course, type CourseProgressSnapshot, type Lesson, type ProgressState } from '@syniastrolms/domain';

import { db } from './db.js';
import { getSettings } from './settings.js';

/**
 * Learner-side rules: which lessons are open, what finishing a lesson takes, when a course is
 * complete, and how enrollments expire. Everything reads the academy settings.
 */

export interface LearnerRules {
  /** % of a video/reading that counts as finished. */
  threshold: number;
  courseCompletion: 'all-lessons' | 'lessons-and-assessments' | 'percentage';
  completionPercent: number;
  chapterGate: boolean;
  /** Default attempts for quizzes that leave theirs unset. */
  quizAttempts: number;
  retakeWaitHours: number;
  accessMonths: number | null;
  enrollmentPolicy: 'open' | 'approval' | 'invite';
}

export async function learnerRules(): Promise<LearnerRules> {
  const s = await getSettings();
  return {
    threshold: s.learning.completionThreshold,
    courseCompletion: s.learning.courseCompletion,
    completionPercent: s.learning.completionPercent,
    chapterGate: s.learning.chapterGate,
    quizAttempts: s.learning.quizAttempts,
    retakeWaitHours: s.learning.retakeWaitHours,
    accessMonths: s.general.accessMonths,
    enrollmentPolicy: s.general.enrollment,
  };
}

export interface LocatedLesson {
  lesson: Lesson;
  chapter: Course['chapters'][number];
  chapterIndex: number;
  lessonIndex: number;
}

/** Published lessons in course order. */
export function publishedLessons(course: Course): LocatedLesson[] {
  return course.chapters.flatMap((chapter, chapterIndex) =>
    chapter.lessons.filter((l) => l.status === 'published').map((lesson, lessonIndex) => ({ lesson, chapter, chapterIndex, lessonIndex })),
  );
}

export function locateLesson(course: Course, lessonId: string): LocatedLesson | undefined {
  for (let ci = 0; ci < course.chapters.length; ci++) {
    const li = course.chapters[ci].lessons.findIndex((l) => l.id === lessonId);
    if (li !== -1) return { lesson: course.chapters[ci].lessons[li], chapter: course.chapters[ci], chapterIndex: ci, lessonIndex: li };
  }
  return undefined;
}

/** What finishing a lesson takes: the lesson's own rule, else the default for its type. */
export const completionRuleOf = (lesson: Lesson) => lesson.settings?.completion ?? defaultCompletion[lesson.type];

/**
 * Chapters open in order: a chapter unlocks when the one before it is finished, not counting
 * assignments (they wait on review). A chapter's quiz unlocks once its other lessons are done.
 * Without chapter gating every published lesson is open.
 */
export function applyLocks(course: Course, snapshot: CourseProgressSnapshot, chapterGate: boolean): CourseProgressSnapshot {
  for (const [id, p] of Object.entries(snapshot.lessons)) if (p.state === 'locked') delete snapshot.lessons[id];
  if (!chapterGate) return snapshot;
  const done = (l: Lesson) => snapshot.lessons[l.id]?.state === 'completed';
  course.chapters.forEach((chapter, i) => {
    const previous = course.chapters[i - 1];
    const chapterOpen = !previous || previous.lessons.filter((l) => l.status === 'published' && l.type !== 'assignment').every(done);
    for (const lesson of chapter.lessons.filter((l) => l.status === 'published')) {
      const p = snapshot.lessons[lesson.id];
      if (p && p.state !== 'not-started') continue;
      const quizWaiting =
        lesson.type === 'assessment' &&
        chapter.lessons.some((l) => l.id !== lesson.id && l.status === 'published' && l.type !== 'assignment' && l.type !== 'assessment' && !done(l));
      if (!chapterOpen || quizWaiting) snapshot.lessons[lesson.id] = { lessonId: lesson.id, state: 'locked' };
    }
  });
  return snapshot;
}

export function lockedReason(course: Course, chapterIndex: number, lesson: Lesson, snapshot: CourseProgressSnapshot): string {
  const previous = course.chapters[chapterIndex - 1];
  if (previous && previous.lessons.some((l) => l.status === 'published' && l.type !== 'assignment' && snapshot.lessons[l.id]?.state !== 'completed'))
    return `Finish “${previous.title}” to open this chapter.`;
  if (lesson.type === 'assessment') return `Finish the other lessons in “${course.chapters[chapterIndex].title}” to take this quiz.`;
  return 'This lesson opens after the ones before it.';
}

/** The first published lesson that is neither completed nor locked, with its place in the course. */
export function nextLessonFor(course: Course, snapshot: CourseProgressSnapshot) {
  for (const { lesson, chapter, chapterIndex, lessonIndex } of publishedLessons(course)) {
    const state: ProgressState = snapshot.lessons[lesson.id]?.state ?? 'not-started';
    if (state === 'completed' || state === 'locked') continue;
    return {
      id: lesson.id,
      title: lesson.title,
      type: lesson.type,
      durationMin: lesson.durationMin,
      chapterIndex,
      chapterTitle: chapter.title,
      lessonNumber: `${chapterIndex + 1}.${lessonIndex + 1}`,
      state,
      fraction: snapshot.lessons[lesson.id]?.fraction,
      positionSec: snapshot.lessons[lesson.id]?.positionSec,
    };
  }
  return undefined;
}

/** Whether the course counts as complete under the academy's rule. */
export function isCourseComplete(course: Course, snapshot: CourseProgressSnapshot, rules: LearnerRules): boolean {
  const lessons = publishedLessons(course).map((x) => x.lesson);
  if (!lessons.length) return false;
  const completed = (l: Lesson) => snapshot.lessons[l.id]?.state === 'completed';
  if (rules.courseCompletion === 'percentage') {
    const share = (lessons.filter(completed).length / lessons.length) * 100;
    return share >= rules.completionPercent && lessons.filter((l) => l.type === 'assessment').every(completed);
  }
  if (rules.courseCompletion === 'lessons-and-assessments') return lessons.every(completed);
  // all-lessons: every lesson except assignments (which wait on review) must be done
  return lessons.filter((l) => l.type !== 'assignment').every(completed) && lessons.filter((l) => l.type === 'assessment').every(completed);
}

/** Builds a snapshot from stored progress rows and applies the gating rules. */
export async function snapshotFor(course: Course, studentId: string, chapterGate: boolean): Promise<CourseProgressSnapshot> {
  const rows = await db.lessonProgress.findMany({ where: { studentId, lesson: { courseId: course.id } } });
  const snapshot: CourseProgressSnapshot = { courseId: course.id, lessons: {} };
  for (const r of rows)
    snapshot.lessons[r.lessonId] = {
      lessonId: r.lessonId,
      state: r.state as ProgressState,
      fraction: r.fraction ?? undefined,
      positionSec: r.positionSec ?? undefined,
      completedAt: r.completedAt?.toISOString(),
    };
  const last = rows
    .filter((r) => r.lastAccessedAt || r.completedAt)
    .sort((a, b) => (b.lastAccessedAt ?? b.completedAt)!.getTime() - (a.lastAccessedAt ?? a.completedAt)!.getTime())[0];
  snapshot.lastLessonId = last?.lessonId;
  snapshot.lastActiveAt = (last?.lastAccessedAt ?? last?.completedAt)?.toISOString();
  return applyLocks(course, snapshot, chapterGate);
}

export const progressOf = (course: Course, snapshot: CourseProgressSnapshot) => courseProgress(course, snapshot);

/** Access length from settings → when the enrollment stops. */
export function expiryFor(enrolledAt: Date, accessMonths: number | null): Date | null {
  if (!accessMonths) return null;
  const d = new Date(enrolledAt);
  d.setMonth(d.getMonth() + accessMonths);
  return d;
}

/** Lazily flips an active enrollment to `expired` once its access has run out. */
export async function settleExpiry<T extends { id: string; status: string; expiresAt: Date | null }>(enrollment: T): Promise<T> {
  if (enrollment.status === 'active' && enrollment.expiresAt && enrollment.expiresAt < new Date()) {
    await db.enrollment.update({ where: { id: enrollment.id }, data: { status: 'expired' } });
    return { ...enrollment, status: 'expired' };
  }
  return enrollment;
}
