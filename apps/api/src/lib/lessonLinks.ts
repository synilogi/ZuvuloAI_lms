import type { LessonContent } from '@syniastrolms/domain';

import { db } from './db.js';
import { readJson } from './json.js';

/**
 * A lesson's quiz/assignment block mirrors the record that delivers it (`Quiz.lessonId` /
 * `CourseAssignment.lessonId`). The database link is the source of truth; these helpers refresh the
 * mirror whenever a lesson is read, so edits in the quiz builder or assignment editor show up.
 */

export function quizMirror(q: { id: string; questionsJson: string; settingsJson: string }): NonNullable<LessonContent['quiz']> {
  const questions = readJson<unknown[]>(q.questionsJson, []);
  const settings = readJson<{ passMark?: number; attempts?: number; timeLimitMin?: number }>(q.settingsJson, {});
  return {
    quizId: q.id,
    questions: questions.length,
    passMark: settings.passMark ?? 70,
    attempts: settings.attempts ?? 0,
    timeLimitMin: settings.timeLimitMin,
  };
}

export function assignmentMirror(a: {
  id: string;
  instructions: string;
  dueJson: string;
  maxScore: number;
  format: string;
}): NonNullable<LessonContent['assignment']> {
  const firstParagraph = a.instructions.split(/\n{2,}/).find((p) => !p.startsWith('#')) ?? '';
  const due = readJson<{ kind?: string; days?: number }>(a.dueJson, {});
  return {
    assignmentId: a.id,
    brief: firstParagraph.replace(/\*\*/g, ''),
    dueAfterDays: due.kind === 'relative' && due.days ? due.days : 7,
    maxScore: a.maxScore,
    submission: a.format as 'file' | 'text' | 'chart',
  };
}

export function mergeLinkedContent(
  content: LessonContent,
  quiz?: { id: string; questionsJson: string; settingsJson: string } | null,
  assignment?: { id: string; instructions: string; dueJson: string; maxScore: number; format: string } | null,
): LessonContent {
  return { ...content, ...(quiz ? { quiz: quizMirror(quiz) } : {}), ...(assignment ? { assignment: assignmentMirror(assignment) } : {}) };
}

/** The quiz and assignment delivered by each lesson of a course, keyed by lesson id. */
export async function linkedByLesson(courseId: string) {
  const [quizzes, assignments] = await Promise.all([
    db.quiz.findMany({ where: { courseId, lessonId: { not: null } } }),
    db.courseAssignment.findMany({ where: { courseId, lessonId: { not: null } } }),
  ]);
  return {
    quiz: new Map(quizzes.map((q) => [q.lessonId!, q])),
    assignment: new Map(assignments.map((a) => [a.lessonId!, a])),
  };
}
