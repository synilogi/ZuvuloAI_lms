import type { AssignmentInput, CourseAssignment, Submission } from '@syniastrolms/domain';
import {
  assignmentMaxScore,
  chapterDurationMin,
  courseDurationMin,
  needsReview,
  reviewOverdue,
  reviewScore,
  validateAssignment,
  validateReview,
} from '@syniastrolms/domain';
import type { AssignmentAdminService, AssignmentRow, SubmissionFilter, SubmissionPerson, SubmissionRow } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNow, mockNowIso } from './clock';
import { courseAssignments, submissions, withResponse, withReviewDetail } from './fixtures/assignments';
import { courses } from './fixtures/catalog';
import { enrollments, students } from './fixtures/people';
import { respond, scenario } from './simulation';

const studentById = new Map(students.map((s) => [s.id, s]));
const person = (id: string): SubmissionPerson => {
  const s = studentById.get(id);
  return { id, name: s?.name ?? 'Former learner', email: s?.email ?? '', city: s?.city ?? '' };
};

const allowedCourses = (scopeInstructorId?: string) =>
  new Set(courses.filter((c) => !scopeInstructorId || c.instructorIds.includes(scopeInstructorId)).map((c) => c.id));

function find(id: string, scopeInstructorId?: string) {
  const assignment = courseAssignments.find((a) => a.id === id);
  if (!assignment || !allowedCourses(scopeInstructorId).has(assignment.courseId)) {
    throw new ServiceError('This assignment doesn’t exist or isn’t shared with you.', 'not-found');
  }
  return assignment;
}

/** Learners who have finished the assignment's chapter — the ones expected to hand it in. */
function expectedLearners(assignment: CourseAssignment) {
  const course = courses.find((c) => c.id === assignment.courseId);
  if (!course || assignment.status === 'draft') return [];
  const total = courseDurationMin(course) || 1;
  const index = Math.max(
    0,
    course.chapters.findIndex((c) => c.id === assignment.chapterId),
  );
  const through = course.chapters.slice(0, index + 1).reduce((n, c) => n + chapterDurationMin(c), 0) / total;
  return enrollments.filter((e) => e.courseId === course.id && e.progress / 100 >= through);
}

function byAssignment() {
  const map = new Map<string, Submission[]>();
  for (const s of submissions()) {
    const list = map.get(s.assignmentId);
    if (list) list.push(s);
    else map.set(s.assignmentId, [s]);
  }
  return map;
}

function row(assignment: CourseAssignment, list: Submission[], now: Date): AssignmentRow {
  const course = courses.find((c) => c.id === assignment.courseId);
  const graded = list.filter((s) => s.review.status === 'graded');
  const submitted = new Set(list.map((s) => s.studentId));
  const expected = assignment.status === 'draft' ? 0 : expectedLearners(assignment).filter((e) => !submitted.has(e.studentId)).length;
  return {
    assignment,
    courseTitle: course?.title ?? 'Unknown course',
    chapterTitle: course?.chapters.find((c) => c.id === assignment.chapterId)?.title,
    submitted: submitted.size,
    toReview: list.filter(needsReview).length,
    overdue: list.filter((s) => reviewOverdue(s, now)).length,
    graded: graded.length,
    missing: expected,
    avgScore: graded.length ? Math.round((graded.reduce((n, s) => n + (s.review.score ?? 0), 0) / graded.length / assignment.maxScore) * 100) : null,
  };
}

function assertPublishable(input: AssignmentInput) {
  if (input.title.trim().length < 3) throw new ServiceError('Give the assignment a title of at least 3 characters.', 'conflict');
  if (!courses.some((c) => c.id === input.courseId)) throw new ServiceError('Choose the course this assignment belongs to.', 'conflict');
  if (input.status === 'draft') return;
  const issues = validateAssignment(input, mockNow());
  if (issues.length)
    throw new ServiceError(
      `The assignment can’t be published yet: ${issues[0].message}${issues.length > 1 ? ` (and ${issues.length - 1} more)` : ''}`,
      'conflict',
    );
}

let serial = 0;
const nextId = (prefix: string) => `${prefix}-${Date.now().toString(36)}${(serial++).toString(36)}`;

const normalise = (input: AssignmentInput): AssignmentInput => ({ ...input, title: input.title.trim(), maxScore: assignmentMaxScore(input) });

export const assignmentAdminService: AssignmentAdminService = {
  list: ({ search = '', courseId, status = 'all', scopeInstructorId }) =>
    respond(() => {
      if (scenario() === 'empty') return { rows: [], counts: { all: 0, draft: 0, published: 0, closed: 0 } };
      const now = mockNow();
      const q = search.trim().toLowerCase();
      const allowed = allowedCourses(scopeInstructorId);
      const matching = courseAssignments.filter(
        (a) => allowed.has(a.courseId) && (!courseId || a.courseId === courseId) && (!q || a.title.toLowerCase().includes(q)),
      );
      const lists = byAssignment();
      const rows = matching
        .filter((a) => status === 'all' || a.status === status)
        .map((a) => row(a, lists.get(a.id) ?? [], now))
        .sort((a, b) => b.overdue - a.overdue || b.toReview - a.toReview || b.assignment.updatedAt.localeCompare(a.assignment.updatedAt));
      const count = (s: CourseAssignment['status']) => matching.filter((a) => a.status === s).length;
      return { rows, counts: { all: matching.length, draft: count('draft'), published: count('published'), closed: count('closed') } };
    }, 480),

  get: (id, scopeInstructorId) => respond(() => find(id, scopeInstructorId), 420),

  create: (input) =>
    respond(() => {
      const clean = normalise(input);
      assertPublishable(clean);
      const now = mockNowIso();
      const assignment: CourseAssignment = { ...clean, id: nextId('asg'), createdAt: now, updatedAt: now };
      courseAssignments.unshift(assignment);
      return assignment;
    }, 850),

  update: (id, input) =>
    respond(() => {
      const current = find(id);
      const next: CourseAssignment = { ...current, ...input, updatedAt: mockNowIso() };
      Object.assign(next, normalise(next));
      assertPublishable(next);
      courseAssignments[courseAssignments.indexOf(current)] = next;
      return next;
    }, 800),

  duplicate: (id) =>
    respond(() => {
      const source = find(id);
      const now = mockNowIso();
      const copy: CourseAssignment = {
        ...structuredClone(source),
        id: nextId('asg'),
        lessonId: undefined,
        title: `Copy of ${source.title}`,
        status: 'draft',
        createdAt: now,
        updatedAt: now,
      };
      courseAssignments.splice(courseAssignments.indexOf(source) + 1, 0, copy);
      return copy;
    }, 800),

  remove: (id) =>
    respond(() => {
      const assignment = find(id);
      if (assignment.lessonId)
        throw new ServiceError('This assignment is delivered by a lesson. Change that lesson to another type, or delete the lesson, first.', 'conflict');
      courseAssignments.splice(courseAssignments.indexOf(assignment), 1);
      const all = submissions();
      for (let i = all.length - 1; i >= 0; i--) if (all[i].assignmentId === id) all.splice(i, 1);
      invalidateAnalytics();
    }, 700),

  submissions: ({ assignmentId, courseId, filter = 'all', search = '', sort = 'oldest', scopeInstructorId, page, pageSize }) =>
    respond(() => {
      const empty: Record<SubmissionFilter, number> = { all: 0, 'to-review': 0, graded: 0, returned: 0, missing: 0 };
      if (scenario() === 'empty') return { rows: [], total: 0, counts: empty };
      const now = mockNow();
      const allowed = allowedCourses(scopeInstructorId);
      const scoped = new Map(
        courseAssignments
          .filter((a) => allowed.has(a.courseId) && (!assignmentId || a.id === assignmentId) && (!courseId || a.courseId === courseId))
          .map((a) => [a.id, a]),
      );
      if (assignmentId && !scoped.size) throw new ServiceError('This assignment doesn’t exist or isn’t shared with you.', 'not-found');
      const courseTitle = (a: CourseAssignment) => courses.find((c) => c.id === a.courseId)?.title ?? '';

      const submitted: SubmissionRow[] = submissions()
        .filter((s) => scoped.has(s.assignmentId))
        .map((s) => {
          const a = scoped.get(s.assignmentId)!;
          return {
            id: s.id,
            submission: s,
            student: person(s.studentId),
            assignmentId: a.id,
            assignmentTitle: a.title,
            courseTitle: courseTitle(a),
            maxScore: a.maxScore,
            overdue: reviewOverdue(s, now),
          };
        });
      // Only a single assignment lists the learners who haven't handed in.
      const target = assignmentId ? scoped.get(assignmentId) : undefined;
      const handedIn = new Set(submitted.map((r) => r.student.id));
      const missing: SubmissionRow[] = target
        ? expectedLearners(target)
            .filter((e) => !handedIn.has(e.studentId))
            .map((e) => ({
              id: `missing-${target.id}-${e.studentId}`,
              student: person(e.studentId),
              assignmentId: target.id,
              assignmentTitle: target.title,
              courseTitle: courseTitle(target),
              maxScore: target.maxScore,
              overdue: false,
            }))
        : [];

      const counts: Record<SubmissionFilter, number> = {
        all: submitted.length,
        'to-review': submitted.filter((r) => needsReview(r.submission!)).length,
        graded: submitted.filter((r) => r.submission!.review.status === 'graded').length,
        returned: submitted.filter((r) => r.submission!.review.status === 'returned').length,
        missing: missing.length,
      };
      const q = search.trim().toLowerCase();
      const pool =
        filter === 'missing'
          ? missing
          : submitted.filter((r) => filter === 'all' || (filter === 'to-review' ? needsReview(r.submission!) : r.submission!.review.status === filter));
      const matched = pool.filter((r) => !q || r.student.name.toLowerCase().includes(q) || r.student.email.toLowerCase().includes(q));
      const at = (r: SubmissionRow) => r.submission?.submittedAt ?? '';
      matched.sort((a, b) =>
        sort === 'score'
          ? (b.submission?.review.score ?? -1) - (a.submission?.review.score ?? -1)
          : sort === 'newest'
            ? at(b).localeCompare(at(a))
            : at(a).localeCompare(at(b)) || a.student.name.localeCompare(b.student.name),
      );
      return { rows: matched.slice((page - 1) * pageSize, page * pageSize), total: matched.length, counts };
    }, 520),

  submission: (id, scopeInstructorId) =>
    respond(() => {
      const submission = submissions().find((s) => s.id === id);
      if (!submission) throw new ServiceError('This submission doesn’t exist or was removed.', 'not-found');
      const assignment = find(submission.assignmentId, scopeInstructorId);
      withResponse(submission, assignment);
      withReviewDetail(submission, assignment);
      const course = courses.find((c) => c.id === assignment.courseId)!;
      const enrollment = enrollments.find((e) => e.courseId === course.id && e.studentId === submission.studentId);
      const queue = submissions()
        .filter((s) => s.assignmentId === assignment.id && (needsReview(s) || s.id === id))
        .sort((a, b) => a.submittedAt.localeCompare(b.submittedAt));
      const index = queue.findIndex((s) => s.id === id);
      const waiting = queue.filter(needsReview);
      const position = needsReview(submission) ? waiting.findIndex((s) => s.id === id) + 1 : 0;
      return {
        submission,
        assignment,
        courseTitle: course.title,
        chapterTitle: course.chapters.find((c) => c.id === assignment.chapterId)?.title,
        student: { ...person(submission.studentId), progress: enrollment?.progress ?? 0, enrolledAt: enrollment?.enrolledAt ?? submission.submittedAt },
        queue: {
          position,
          total: waiting.length,
          previousId: queue.slice(0, index).reverse().find(needsReview)?.id,
          nextId: queue.slice(index + 1).find(needsReview)?.id ?? waiting.find((s) => s.id !== id)?.id,
        },
      };
    }, 520),

  review: (id, input) =>
    respond(() => {
      const submission = submissions().find((s) => s.id === id);
      if (!submission) throw new ServiceError('This submission doesn’t exist or was removed.', 'not-found');
      const assignment = find(submission.assignmentId);
      if (input.decision !== 'draft') {
        const issues = validateReview(assignment, input, input.decision);
        if (issues.length) throw new ServiceError(issues[0].message, 'conflict');
      }
      const { score } = reviewScore(assignment, input, submission.late);
      submission.review = {
        status: input.decision === 'draft' ? 'in-review' : input.decision,
        reviewerId: submission.review.reviewerId ?? courses.find((c) => c.id === assignment.courseId)?.instructorIds[0],
        scores: input.scores,
        points: input.points,
        score: input.decision === 'graded' ? score : undefined,
        feedback: input.feedback,
        privateNote: input.privateNote,
        updatedAt: mockNowIso(),
      };
      invalidateAnalytics();
      return submission;
    }, 800),

  remind: (_assignmentId, studentIds) => respond(() => ({ sent: studentIds.length }), 700),

  summary: (scopeInstructorId) =>
    respond(() => {
      if (scenario() === 'empty') return { toReview: 0, overdue: 0, byCourse: [] };
      const now = mockNow();
      const allowed = allowedCourses(scopeInstructorId);
      const courseOf = new Map(courseAssignments.map((a) => [a.id, a.courseId]));
      const byCourse = new Map<string, { courseId: string; toReview: number; overdue: number }>();
      for (const s of submissions()) {
        const courseId = courseOf.get(s.assignmentId);
        if (!courseId || !allowed.has(courseId) || !needsReview(s)) continue;
        const entry = byCourse.get(courseId) ?? { courseId, toReview: 0, overdue: 0 };
        entry.toReview += 1;
        if (reviewOverdue(s, now)) entry.overdue += 1;
        byCourse.set(courseId, entry);
      }
      const list = [...byCourse.values()];
      return { toReview: list.reduce((n, c) => n + c.toReview, 0), overdue: list.reduce((n, c) => n + c.overdue, 0), byCourse: list };
    }, 300),
};
