import type { ActivityKind, Course, CourseProgressSnapshot, Enrollment, LearningEvent, Student } from '@syniastrolms/domain';
import { chapterProgress, deriveStudentStatus, needsReview } from '@syniastrolms/domain';
import type { StudentActivity, StudentAdminService, StudentEnrollment, StudentProfile, StudentProgress, StudentRow } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNowIso } from './clock';
import { courseAssignments, submissions } from './fixtures/assignments';
import { issuedCertificates } from './fixtures/certificates';
import { courses, instructors, levels } from './fixtures/catalog';
import { DEMO_NOW, ranks } from './fixtures/learner';
import { enrollments, students } from './fixtures/people';
import { quizzes } from './fixtures/quizzes';
import { createRandom, DAY_MS, hashSeed, toIST } from './random';
import { respond, scenario } from './simulation';
import { formatShortDate } from '@/lib/format';

const NOW = new Date(DEMO_NOW);
const courseById = new Map(courses.map((c) => [c.id, c]));
const levelOrder = new Map(levels.map((l) => [l.id, l.order]));

/** Enrollments per student, rebuilt when the roster changes. */
let index: Map<string, Enrollment[]> | undefined;
function enrollmentsOf(studentId: string) {
  if (!index) {
    index = new Map();
    for (const e of enrollments) {
      const list = index.get(e.studentId);
      if (list) list.push(e);
      else index.set(e.studentId, [e]);
    }
  }
  return index.get(studentId) ?? [];
}
const reindex = () => {
  index = undefined;
  invalidateAnalytics();
};

const allowedCourses = (scopeInstructorId?: string) =>
  new Set(courses.filter((c) => !scopeInstructorId || c.instructorIds.includes(scopeInstructorId)).map((c) => c.id));

function findStudent(id: string, scopeInstructorId?: string) {
  const student = students.find((s) => s.id === id);
  const allowed = allowedCourses(scopeInstructorId);
  if (!student || (scopeInstructorId && !enrollmentsOf(id).some((e) => allowed.has(e.courseId)))) {
    throw new ServiceError('This learner doesn’t exist or isn’t in your courses.', 'not-found');
  }
  return student;
}

const statusOf = (s: Student) => deriveStudentStatus(s, enrollmentsOf(s.id), NOW);

/* ─── Progress simulation ──────────────────────────────────────────────── */

interface Walk {
  snapshot: CourseProgressSnapshot;
  /** Completed lessons with when they were finished, in course order. */
  done: { lessonId: string; title: string; type: string; chapterIndex: number; durationMin: number; at: number }[];
  lastLessonTitle?: string;
}

/**
 * Turns an enrollment's percentage into lesson-by-lesson progress: lessons complete in course
 * order until their minutes reach the percentage, spread between enrolling and last activity.
 */
function walk(course: Course, e: Enrollment): Walk {
  const lessons = course.chapters.flatMap((c, chapterIndex) => c.lessons.filter((l) => l.status === 'published').map((l) => ({ lesson: l, chapterIndex })));
  const total = lessons.reduce((n, x) => n + x.lesson.durationMin, 0) || 1;
  const target = (e.progress / 100) * total;
  const start = new Date(e.enrolledAt).getTime();
  const end = new Date(e.completedAt ?? e.lastActiveAt ?? e.enrolledAt).getTime();
  const rng = createRandom(hashSeed(`walk:${e.id}`));
  const snapshot: CourseProgressSnapshot = { courseId: course.id, lessons: {} };
  const done: Walk['done'] = [];
  let minutes = 0;
  let lastLessonTitle: string | undefined;
  for (const { lesson, chapterIndex } of lessons) {
    if (minutes + lesson.durationMin <= target + 0.5) {
      minutes += lesson.durationMin;
      const at = Math.min(end, start + (end - start) * (minutes / Math.max(target, 1)) - rng.between(0, 6) * 3_600_000);
      snapshot.lessons[lesson.id] = { lessonId: lesson.id, state: 'completed', completedAt: toIST(new Date(at)) };
      done.push({ lessonId: lesson.id, title: lesson.title, type: lesson.type, chapterIndex, durationMin: lesson.durationMin, at: Math.max(start, at) });
      lastLessonTitle = lesson.title;
    } else {
      const fraction = Math.max(0, Math.min(0.95, (target - minutes) / lesson.durationMin));
      if (fraction > 0.05) {
        snapshot.lessons[lesson.id] = { lessonId: lesson.id, state: 'in-progress', fraction };
        lastLessonTitle = lesson.title;
      }
      break;
    }
  }
  return { snapshot, done, lastLessonTitle };
}

const walks = new Map<string, Walk>();
const walkOf = (course: Course, e: Enrollment) => {
  const key = `${e.id}:${e.progress}`;
  let w = walks.get(key);
  if (!w) {
    w = walk(course, e);
    walks.set(key, w);
  }
  return w;
};

/** The learner's issued certificate for a course, from the academy's certificate records. */
function certificateFor(course: Course, e: Enrollment) {
  const cert = issuedCertificates().find((c) => c.studentId === e.studentId && c.courseId === course.id && c.status === 'issued');
  if (!cert?.issuedAt) return undefined;
  return { id: cert.id, courseId: course.id, courseTitle: course.title, title: cert.title, issuedAt: cert.issuedAt, credentialId: cert.credentialId };
}

/** Rank follows the highest level of course a learner has completed; everyone starts as a Beginner. */
function rankFor(list: Enrollment[]) {
  const completed = list
    .filter((e) => e.status === 'completed')
    .map((e) => ({ order: levelOrder.get(courseById.get(e.courseId)!.levelId) ?? 1, at: e.completedAt }));
  const best = completed.sort((a, b) => b.order - a.order)[0];
  const ordered = [...ranks].sort((a, b) => a.order - b.order);
  const rank = ordered[Math.min(ordered.length - 1, best ? best.order - 1 : 0)] ?? ordered[0];
  return { id: rank.id, title: rank.title, order: rank.order, descriptor: rank.descriptor, achievedAt: best?.at };
}

function detail(e: Enrollment): StudentEnrollment {
  const course = courseById.get(e.courseId)!;
  const w = walkOf(course, e);
  const chapters = course.chapters.filter((c) => c.lessons.length > 0);
  return {
    enrollment: e,
    courseTitle: course.title,
    levelTitle: levels.find((l) => l.id === course.levelId)?.name ?? '',
    categoryId: course.categoryId,
    instructorNames: course.instructorIds.map((id) => instructors.find((i) => i.id === id)?.name ?? '').filter(Boolean),
    chapters: { done: chapters.filter((c) => chapterProgress(c, w.snapshot).state === 'completed').length, total: chapters.length },
    lessons: { done: w.done.length, total: course.chapters.reduce((n, c) => n + c.lessons.filter((l) => l.status === 'published').length, 0) },
    lastLessonTitle: w.lastLessonTitle,
    certificateTitle: course.certificateTitle,
  };
}

/* ─── Service ──────────────────────────────────────────────────────────── */

export const studentAdminService: StudentAdminService = {
  list: ({ search = '', courseId, status = 'all', sort = 'recent', scopeInstructorId, page, pageSize }) =>
    respond(() => {
      const empty = { all: 0, active: 0, 'at-risk': 0, inactive: 0, suspended: 0 };
      if (scenario() === 'empty') return { rows: [], total: 0, counts: empty };
      const allowed = allowedCourses(scopeInstructorId);
      const q = search.trim().toLowerCase();
      const matching: StudentRow[] = [];
      for (const s of students) {
        const scoped = enrollmentsOf(s.id).filter((e) => allowed.has(e.courseId));
        if (scopeInstructorId && scoped.length === 0) continue;
        if (courseId && !scoped.some((e) => e.courseId === courseId)) continue;
        if (q && !`${s.name} ${s.email} ${s.id}`.toLowerCase().includes(q)) continue;
        const inProgress = scoped.filter((e) => e.status === 'active');
        const basis = inProgress.length ? inProgress : scoped;
        matching.push({
          student: s,
          status: statusOf(s),
          courses: [...scoped]
            .sort((a, b) => b.enrolledAt.localeCompare(a.enrolledAt))
            .map((e) => ({ id: e.courseId, title: courseById.get(e.courseId)!.title, progress: e.progress, status: e.status })),
          progress: basis.length ? Math.round(basis.reduce((n, e) => n + e.progress, 0) / basis.length) : 0,
        });
      }
      const counts = { ...empty, all: matching.length };
      for (const r of matching) counts[r.status] += 1;
      const rows = matching.filter((r) => status === 'all' || r.status === status);
      rows.sort((a, b) =>
        sort === 'name'
          ? a.student.name.localeCompare(b.student.name)
          : sort === 'progress'
            ? b.progress - a.progress
            : sort === 'joined'
              ? b.student.joinedAt.localeCompare(a.student.joinedAt)
              : b.student.lastActiveAt.localeCompare(a.student.lastActiveAt),
      );
      return { rows: rows.slice((page - 1) * pageSize, page * pageSize), total: rows.length, counts };
    }, 520),

  get: (id, scopeInstructorId) =>
    respond((): StudentProfile => {
      const student = findStudent(id, scopeInstructorId);
      const allowed = allowedCourses(scopeInstructorId);
      const all = enrollmentsOf(id);
      const scoped = all.filter((e) => allowed.has(e.courseId)).sort((a, b) => b.enrolledAt.localeCompare(a.enrolledAt));
      const details = scoped.map(detail);
      const certificates = scoped.map((e) => certificateFor(courseById.get(e.courseId)!, e)).filter((c): c is NonNullable<typeof c> => Boolean(c));
      const ownSubmissions = submissions().filter(
        (s) => s.studentId === id && allowed.has(courseAssignments.find((a) => a.id === s.assignmentId)?.courseId ?? ''),
      );
      const graded = ownSubmissions.filter((s) => s.review.status === 'graded' && s.review.score !== undefined);
      const studyMinutes = scoped.reduce((n, e) => n + walkOf(courseById.get(e.courseId)!, e).done.reduce((m, d) => m + d.durationMin, 0), 0);
      const inProgress = scoped.filter((e) => e.status === 'active');
      return {
        student,
        status: statusOf(student),
        quietDays: Math.floor((NOW.getTime() - new Date(student.lastActiveAt).getTime()) / DAY_MS),
        rank: rankFor(all),
        enrollments: details,
        certificates,
        summary: {
          enrolled: scoped.length,
          active: inProgress.length,
          completed: scoped.filter((e) => e.status === 'completed').length,
          avgProgress: scoped.length
            ? Math.round((inProgress.length ? inProgress : scoped).reduce((n, e) => n + e.progress, 0) / (inProgress.length || scoped.length))
            : 0,
          studyMinutes: Math.round(studyMinutes * 1.25),
          submissions: ownSubmissions.length,
          avgScore: graded.length
            ? Math.round(
                (graded.reduce((n, s) => n + (s.review.score ?? 0) / (courseAssignments.find((a) => a.id === s.assignmentId)?.maxScore ?? 20), 0) /
                  graded.length) *
                  100,
              )
            : null,
        },
      };
    }, 520),

  progress: (id, scopeInstructorId) =>
    respond((): StudentProgress => {
      findStudent(id, scopeInstructorId);
      const allowed = allowedCourses(scopeInstructorId);
      const scoped = enrollmentsOf(id).filter((e) => allowed.has(e.courseId));
      const result: StudentProgress = { courses: [], quizzes: [], assignments: [], studyWeeks: [] };
      const minutesByDay: number[] = [];
      for (const e of scoped) {
        const course = courseById.get(e.courseId)!;
        const w = walkOf(course, e);
        result.courses.push({
          courseId: course.id,
          courseTitle: course.title,
          progress: e.progress,
          status: e.status,
          chapters: course.chapters
            .filter((c) => c.lessons.length > 0)
            .map((c) => {
              const p = chapterProgress(c, w.snapshot);
              return { id: c.id, title: c.title, percent: p.percent, completed: p.completed, total: p.total };
            }),
        });
        for (const d of w.done) {
          const daysAgo = Math.floor((NOW.getTime() - d.at) / DAY_MS);
          if (daysAgo >= 0 && daysAgo < 84) minutesByDay[daysAgo] = (minutesByDay[daysAgo] ?? 0) + Math.round(d.durationMin * 1.25);
          if (d.type === 'assessment') {
            const quiz = quizzes.find((q) => q.lessonId === d.lessonId);
            if (!quiz) continue;
            const rng = createRandom(hashSeed(`quiz:${e.id}:${quiz.id}`));
            result.quizzes.push({
              quizId: quiz.id,
              title: quiz.title,
              courseTitle: course.title,
              attempts: rng.chance(0.3) ? 2 : 1,
              best: Math.round(rng.between(quiz.settings.passMark, 98)),
              passMark: quiz.settings.passMark,
              lastAt: toIST(new Date(d.at)),
            });
          }
        }
      }
      result.quizzes.sort((a, b) => b.lastAt.localeCompare(a.lastAt));
      result.assignments = submissions()
        .filter((s) => s.studentId === id)
        .map((s) => ({ s, a: courseAssignments.find((x) => x.id === s.assignmentId)! }))
        .filter(({ a }) => a && allowed.has(a.courseId))
        .map(({ s, a }) => ({
          submissionId: s.id,
          assignmentId: a.id,
          title: a.title,
          courseTitle: courseById.get(a.courseId)?.title ?? '',
          submittedAt: s.submittedAt,
          status: s.review.status,
          score: s.review.status === 'graded' ? s.review.score : undefined,
          max: a.maxScore,
          passMark: a.passMark,
          late: s.late,
        }))
        .sort((x, y) => y.submittedAt.localeCompare(x.submittedAt));
      // Twelve weeks, oldest first, ending with the current week.
      for (let w = 11; w >= 0; w--) {
        const minutes = Array.from({ length: 7 }, (_, d) => minutesByDay[w * 7 + d] ?? 0).reduce((n, m) => n + m, 0);
        const starts = new Date(NOW.getTime() - (w * 7 + 6) * DAY_MS);
        const label = formatShortDate(starts);
        result.studyWeeks.push({ label: w === 0 ? 'This week' : label, detail: `Week of ${label}`, minutes });
      }
      return result;
    }, 560),

  activity: (id, { kind = 'all', courseId, scopeInstructorId, limit }) =>
    respond((): StudentActivity => {
      findStudent(id, scopeInstructorId);
      const allowed = allowedCourses(scopeInstructorId);
      const events: (LearningEvent & { courseId?: string })[] = [];
      for (const e of enrollmentsOf(id).filter((x) => allowed.has(x.courseId) && (!courseId || x.courseId === courseId))) {
        const course = courseById.get(e.courseId)!;
        events.push({
          id: `ev-${e.id}-enrolled`,
          kind: 'enrolled',
          title: course.title,
          context:
            e.source === 'self'
              ? 'Enrolled themselves'
              : e.source === 'cohort'
                ? 'Joined with a cohort'
                : e.source === 'scholarship'
                  ? 'Scholarship place'
                  : e.source === 'purchase'
                    ? 'Bought the course'
                    : 'Enrolled by an admin',
          at: e.enrolledAt,
          courseId: course.id,
        });
        const w = walkOf(course, e);
        const chaptersDone = new Set<number>();
        for (const d of w.done) {
          const chapter = course.chapters[d.chapterIndex];
          const at = toIST(new Date(d.at));
          const kindFor: ActivityKind = d.type === 'assessment' ? 'assessment-passed' : d.type === 'live' ? 'live-attended' : 'lesson-completed';
          if (d.type !== 'assignment')
            events.push({
              id: `ev-${e.id}-${d.lessonId}`,
              kind: kindFor,
              title: d.title,
              context: `${course.title} · ${chapter.title}`,
              at,
              courseId: course.id,
            });
          const last = chapter.lessons.filter((l) => l.status === 'published').at(-1);
          if (last?.id === d.lessonId && !chaptersDone.has(d.chapterIndex)) {
            chaptersDone.add(d.chapterIndex);
            events.push({ id: `ev-${e.id}-ch-${chapter.id}`, kind: 'chapter-completed', title: chapter.title, context: course.title, at, courseId: course.id });
          }
        }
        const cert = certificateFor(course, e);
        if (cert)
          events.push({
            id: `ev-${e.id}-cert`,
            kind: 'certificate-issued',
            title: cert.title,
            context: `Credential ${cert.credentialId}`,
            at: cert.issuedAt,
            courseId: course.id,
          });
      }
      for (const s of submissions().filter((x) => x.studentId === id)) {
        const a = courseAssignments.find((x) => x.id === s.assignmentId);
        if (!a || !allowed.has(a.courseId) || (courseId && a.courseId !== courseId)) continue;
        const context = needsReview(s)
          ? `${courseById.get(a.courseId)?.title} · waiting for review`
          : s.review.status === 'graded'
            ? `${courseById.get(a.courseId)?.title} · graded ${s.review.score} / ${a.maxScore}`
            : `${courseById.get(a.courseId)?.title} · resubmission requested`;
        events.push({ id: `ev-${s.id}`, kind: 'assignment-submitted', title: a.title, context, at: s.submittedAt, courseId: a.courseId });
      }
      events.sort((a, b) => b.at.localeCompare(a.at));
      const counts: StudentActivity['counts'] = { all: events.length };
      for (const ev of events) counts[ev.kind] = (counts[ev.kind] ?? 0) + 1;
      const filtered = events.filter((ev) => kind === 'all' || ev.kind === kind);
      return { events: filtered.slice(0, limit), total: filtered.length, counts };
    }, 520),

  message: (ids, message) =>
    respond(() => {
      if (!message.subject.trim() || !message.body.trim()) throw new ServiceError('Add a subject and a message.', 'conflict');
      return { sent: ids.length };
    }, 700),

  enroll: (id, courseId, source) =>
    respond(() => {
      const student = findStudent(id);
      const course = courseById.get(courseId);
      if (!course || course.status !== 'published') throw new ServiceError('Choose a published course.', 'conflict');
      if (enrollmentsOf(id).some((e) => e.courseId === courseId)) throw new ServiceError(`${student.name} is already enrolled in ${course.title}.`, 'conflict');
      const now = mockNowIso();
      const enrollment: Enrollment = {
        id: `en-${Date.now().toString(36)}`,
        studentId: id,
        courseId,
        enrolledAt: now,
        status: 'active',
        progress: 0,
        source,
        lastActiveAt: undefined,
      };
      enrollments.push(enrollment);
      course.enrolledCount += 1;
      reindex();
      return enrollment;
    }, 800),

  setEnrollmentStatus: (enrollmentId, status) =>
    respond(() => {
      const e = enrollments.find((x) => x.id === enrollmentId);
      if (!e) throw new ServiceError('This enrollment no longer exists.', 'not-found');
      if (e.status === 'completed') throw new ServiceError('A completed course can’t be paused.', 'conflict');
      e.status = status;
      reindex();
      return e;
    }, 650),

  removeEnrollment: (enrollmentId) =>
    respond(() => {
      const i = enrollments.findIndex((x) => x.id === enrollmentId);
      if (i < 0) throw new ServiceError('This enrollment no longer exists.', 'not-found');
      const course = courseById.get(enrollments[i].courseId);
      if (course) course.enrolledCount = Math.max(0, course.enrolledCount - 1);
      enrollments.splice(i, 1);
      reindex();
    }, 700),

  create: ({ name, email }) =>
    respond(() => {
      if (students.some((s) => s.email.toLowerCase() === email.trim().toLowerCase()))
        throw new ServiceError('An account with this email already exists.', 'conflict');
      const now = mockNowIso();
      const student: Student = {
        id: `student-${students.length + 1}`,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        city: '',
        joinedAt: now,
        lastActiveAt: now,
        rankId: ranks[0].id,
      };
      students.push(student);
      reindex();
      invalidateAnalytics();
      return student;
    }, 650),
  resendInvite: (id) => respond(() => ({ sentTo: findStudent(id).email }), 500),
  setSuspended: (id, suspended) =>
    respond(() => {
      const student = findStudent(id);
      student.suspended = suspended || undefined;
      reindex();
      return student;
    }, 650),
};
