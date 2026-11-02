import type { ID, ISODateTime } from './catalog';

export type AssignmentState = 'not-started' | 'draft' | 'submitted' | 'under-review' | 'graded' | 'overdue' | 'closed';

export interface Grade {
  score: number;
  max: number;
  /** Same unit as score. */
  passMark: number;
  feedbackAvailable?: boolean;
}

export interface Assignment {
  id: ID;
  courseId: ID;
  chapterId: ID;
  title: string;
  brief: string;
  dueAt: ISODateTime;
  state: AssignmentState;
  submittedAt?: ISODateTime;
  grade?: Grade;
  acceptsLate?: boolean;
}

export function gradePassed(grade: Grade) {
  return grade.score >= grade.passMark;
}

/** What the learner should see right now — unsubmitted work past its deadline reads as overdue or closed. */
export function effectiveAssignmentState(a: Assignment, now: Date): AssignmentState {
  const pastDue = now.getTime() > new Date(a.dueAt).getTime();
  if ((a.state === 'not-started' || a.state === 'draft') && pastDue) return a.acceptsLate ? 'overdue' : 'closed';
  return a.state;
}

/* ─── Authoring and review ─────────────────────────────────────────────── */

export type AssignmentStatus = 'draft' | 'published' | 'closed';
/** What a learner hands in. `chart` is a retired format (set details plus a written explanation): no longer
 * offered for new assignments, still read so older ones open. */
export type SubmissionFormat = 'file' | 'text' | 'chart';

export type DuePolicy = { kind: 'date'; dueAt: ISODateTime } | { kind: 'relative'; days: number } | { kind: 'none' };

export interface RubricCriterion {
  id: ID;
  title: string;
  description: string;
  points: number;
}

export interface Attachment {
  id: ID;
  name: string;
  sizeMb: number;
  pages?: number;
}

/** An assignment as instructors write it. `Assignment` above is one learner's view of it. */
export interface CourseAssignment {
  id: ID;
  courseId: ID;
  chapterId?: ID;
  /** Set when a lesson in the curriculum delivers the assignment. */
  lessonId?: ID;
  title: string;
  /** Markdown: headings, lists and quotes. */
  instructions: string;
  attachments: Attachment[];
  format: SubmissionFormat;
  /** Written and chart submissions only. */
  wordLimit?: number;
  due: DuePolicy;
  acceptsLate: boolean;
  /** Percent taken off a late submission's score. */
  latePenalty: number;
  /** Graded against the rubric when it has criteria; otherwise out of `maxScore`. */
  rubric: RubricCriterion[];
  maxScore: number;
  /** In points. */
  passMark: number;
  status: AssignmentStatus;
  createdAt: ISODateTime;
  updatedAt: ISODateTime;
}

export type AssignmentInput = Omit<CourseAssignment, 'id' | 'createdAt' | 'updatedAt'>;

export type ReviewStatus = 'waiting' | 'in-review' | 'graded' | 'returned';

export interface BirthDetails {
  label: string;
  date: string;
  time: string;
  place: string;
  lagna: string;
  moonSign: string;
  nakshatra: string;
}

export interface Review {
  status: ReviewStatus;
  reviewerId?: ID;
  /** Points per rubric criterion. */
  scores: Record<ID, number>;
  /** Without a rubric, the points given directly. */
  points?: number;
  /** The final score after any late penalty. */
  score?: number;
  feedback: string;
  privateNote?: string;
  updatedAt?: ISODateTime;
}

export interface Submission {
  id: ID;
  assignmentId: ID;
  studentId: ID;
  attempt: number;
  submittedAt: ISODateTime;
  late: boolean;
  text?: string;
  files: Attachment[];
  chart?: BirthDetails;
  review: Review;
}

/** Submissions should be reviewed within this many hours. */
export const REVIEW_WINDOW_HOURS = 48;

export const assignmentMaxScore = (a: Pick<CourseAssignment, 'rubric' | 'maxScore'>) =>
  a.rubric.length ? a.rubric.reduce((n, c) => n + (c.points || 0), 0) : a.maxScore;

export const needsReview = (s: Pick<Submission, 'review'>) => s.review.status === 'waiting' || s.review.status === 'in-review';

export function reviewOverdue(s: Pick<Submission, 'review' | 'submittedAt'>, now: Date) {
  return needsReview(s) && now.getTime() - new Date(s.submittedAt).getTime() > REVIEW_WINDOW_HOURS * 3_600_000;
}

/** Raw points, the late penalty in points, and the final score. */
export function reviewScore(a: Pick<CourseAssignment, 'rubric' | 'maxScore' | 'latePenalty'>, review: Pick<Review, 'scores' | 'points'>, late: boolean) {
  const raw = a.rubric.length ? a.rubric.reduce((n, c) => n + (review.scores[c.id] ?? 0), 0) : (review.points ?? 0);
  const penalty = late && a.latePenalty > 0 ? Math.round(((raw * a.latePenalty) / 100) * 2) / 2 : 0;
  return { raw, penalty, score: Math.max(0, raw - penalty), max: assignmentMaxScore(a) };
}

export interface AssignmentIssue {
  field: 'title' | 'course' | 'instructions' | 'rubric' | 'maxScore' | 'passMark' | 'due' | 'wordLimit';
  criterionId?: ID;
  message: string;
}

/** Everything that must be true before learners can see the assignment. */
export function validateAssignment(input: AssignmentInput, now: Date): AssignmentIssue[] {
  const issues: AssignmentIssue[] = [];
  if (input.title.trim().length < 3) issues.push({ field: 'title', message: 'Give the assignment a title of at least 3 characters.' });
  if (!input.courseId) issues.push({ field: 'course', message: 'Choose the course this assignment belongs to.' });
  if (input.instructions.trim().length < 40)
    issues.push({ field: 'instructions', message: 'Write instructions of at least 40 characters so learners know what to hand in.' });
  if (input.rubric.length) {
    for (const c of input.rubric) {
      if (!c.title.trim()) issues.push({ field: 'rubric', criterionId: c.id, message: 'Name every criterion.' });
      else if (!(c.points > 0)) issues.push({ field: 'rubric', criterionId: c.id, message: `Give “${c.title}” at least 1 point.` });
    }
  } else if (!(input.maxScore > 0)) {
    issues.push({ field: 'maxScore', message: 'Set a maximum score above 0.' });
  }
  const max = assignmentMaxScore(input);
  if (!(input.passMark > 0) || input.passMark > max)
    issues.push({ field: 'passMark', message: `Set a pass mark between 1 and ${max || 'the maximum score'}.` });
  if (input.due.kind === 'date' && input.status === 'published' && new Date(input.due.dueAt).getTime() <= now.getTime()) {
    issues.push({ field: 'due', message: 'The due date has passed. Choose a later date or no due date.' });
  }
  if (input.due.kind === 'relative' && !(input.due.days >= 1)) issues.push({ field: 'due', message: 'Allow at least 1 day after the lesson unlocks.' });
  if (input.wordLimit !== undefined && input.wordLimit < 50) issues.push({ field: 'wordLimit', message: 'A word limit should be at least 50 words.' });
  return issues;
}

export interface ReviewIssue {
  field: 'scores' | 'points' | 'feedback';
  criterionId?: ID;
  message: string;
}

/** A review can be saved as a draft at any time; grading or returning needs these. */
export function validateReview(
  a: Pick<CourseAssignment, 'rubric' | 'maxScore'>,
  review: Pick<Review, 'scores' | 'points' | 'feedback'>,
  decision: 'graded' | 'returned',
): ReviewIssue[] {
  const issues: ReviewIssue[] = [];
  if (decision === 'graded') {
    if (a.rubric.length) {
      for (const c of a.rubric) {
        const v = review.scores[c.id];
        if (v === undefined || Number.isNaN(v)) issues.push({ field: 'scores', criterionId: c.id, message: `Score “${c.title}”.` });
        else if (v < 0 || v > c.points) issues.push({ field: 'scores', criterionId: c.id, message: `“${c.title}” is scored out of ${c.points}.` });
      }
    } else if (review.points === undefined || review.points < 0 || review.points > a.maxScore) {
      issues.push({ field: 'points', message: `Give a score from 0 to ${a.maxScore}.` });
    }
  }
  const words = review.feedback.trim().split(/\s+/).filter(Boolean).length;
  if (decision === 'returned' && words < 8)
    issues.push({ field: 'feedback', message: 'Explain what to change — at least a sentence — so the learner can resubmit.' });
  if (decision === 'graded' && words < 3) issues.push({ field: 'feedback', message: 'Leave the learner a line of feedback with their grade.' });
  return issues;
}

/** Words as a reader counts them: runs of non-space characters. */
export const countWords = (text = '') => (text.trim() ? text.trim().split(/\s+/).length : 0);

/** The most files a hand-in may carry. */
export const MAX_SUBMISSION_FILES = 3;

export interface SubmissionIssue {
  field: 'text' | 'files' | 'chart';
  message: string;
}

/**
 * What a hand-in must be for its assignment's format. A written answer is text; a file hand-in is at least
 * one file with an optional note; a chart hand-in is the birth details and the interpretation. The word
 * limit applies to written and chart work, where the text is the answer.
 */
export function validateSubmission(
  a: Pick<CourseAssignment, 'format' | 'wordLimit'>,
  work: { text: string; files: unknown[]; chart?: unknown },
): SubmissionIssue[] {
  const issues: SubmissionIssue[] = [];
  const words = countWords(work.text);
  if (a.format === 'text') {
    if (!words) issues.push({ field: 'text', message: 'Write your answer before submitting.' });
    if (work.files.length) issues.push({ field: 'files', message: 'This assignment takes a written answer, not files.' });
  }
  if (a.format === 'file') {
    if (!work.files.length) issues.push({ field: 'files', message: 'Upload your work before submitting.' });
    if (work.files.length > MAX_SUBMISSION_FILES) issues.push({ field: 'files', message: `Upload at most ${MAX_SUBMISSION_FILES} files.` });
  }
  if (a.format === 'chart') {
    if (!work.chart) issues.push({ field: 'chart', message: 'Add the birth details for the chart.' });
    if (work.files.length) issues.push({ field: 'files', message: 'This assignment takes a chart and its interpretation, not files.' });
  }
  if (a.format !== 'chart' && work.chart) issues.push({ field: 'chart', message: 'This assignment does not take a chart.' });
  if (a.format !== 'file' && a.wordLimit && words > a.wordLimit)
    issues.push({ field: 'text', message: `Keep your answer to ${a.wordLimit} words — it is ${words} now.` });
  return issues;
}
