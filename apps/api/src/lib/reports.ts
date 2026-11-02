import {
  INACTIVE_AFTER_DAYS,
  median,
  percentOf,
  reportBuckets,
  type EnrollmentSource,
  type LearnerSegment,
  type ReportRange,
  type StudentStatus,
} from '@syniastrolms/domain';

import { db } from './db.js';

/*
 * Report arithmetic, shared by every tab of the reports router.
 *
 * Every figure is read from records: enrolments, lesson progress, quiz attempts, submissions and
 * live classes. Each enrolment is treated as a study span — from enrolling to finishing or last
 * being seen — so any period can be measured and the equal period before it compared against it,
 * which is what `Kpi.previous` means everywhere in the UI.
 *
 * Progress at a past moment is rebuilt from the timestamps on lesson progress rather than read
 * from `Enrollment.progress`, which only knows where a learner stands today. A lesson counts its
 * full duration once `completedAt` has passed, and a lesson still in progress counts the fraction
 * watched from `lastAccessedAt` onwards — the same duration-weighted rule as `courseProgress()`.
 */

export const DAY = 86_400_000;
export const HOUR = 3_600_000;

/** Enrolments that have had 60 days to finish are the ones a completion rate may judge. */
const SETTLED_AFTER = 60 * DAY;
/** A review answered within two days counts as on time. */
const ON_TIME_HOURS = 48;

export const round1 = (n: number) => Math.round(n * 10) / 10;
export const avg = (values: number[]) => (values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0);
export const countIn = (values: number[], from: number, to: number) => values.reduce((n, v) => (v > from && v <= to ? n + 1 : n), 0);

/** Up to `count` evenly spaced items, always keeping the last. */
export const sample = <T>(items: T[], count: number) =>
  items.length <= count ? items : Array.from({ length: count }, (_, i) => items[Math.round((i * (items.length - 1)) / (count - 1))]);

/* ─── Study spans ─── */

export interface Span {
  studentId: string;
  courseId: string;
  status: string;
  source: EnrollmentSource;
  progress: number;
  start: number;
  /** Finished, or last seen — where the span stops counting as under way. */
  end: number;
  /** When the course was finished, or 0. */
  done: number;
}

export interface EnrollmentRow {
  studentId: string;
  courseId: string;
  status: string;
  source: string;
  progress: number;
  enrolledAt: Date;
  lastActiveAt: Date | null;
  completedAt: Date | null;
}

export function spanOf(e: EnrollmentRow): Span {
  const start = e.enrolledAt.getTime();
  const done = e.completedAt?.getTime() ?? 0;
  return {
    studentId: e.studentId,
    courseId: e.courseId,
    status: e.status,
    source: e.source as EnrollmentSource,
    progress: e.progress,
    start,
    end: done || e.lastActiveAt?.getTime() || start,
    done,
  };
}

/** Was this enrolment under way at any point in the period? */
export const activeIn = (s: Span, from: number, to: number) => s.start <= to && s.end > from;

/** Distinct learners whose study overlapped the period. */
export function activeLearners(spans: Span[], from: number, to: number) {
  const people = new Set<string>();
  for (const s of spans) if (activeIn(s, from, to)) people.add(s.studentId);
  return people.size;
}

/** Finished, among enrolments that were already at least 60 days old at that moment. */
export function completionAt(spans: Span[], t: number) {
  let eligible = 0;
  let done = 0;
  for (const s of spans) {
    if (s.start > t - SETTLED_AFTER || s.status === 'paused') continue;
    eligible += 1;
    if (s.done && s.done <= t) done += 1;
  }
  return eligible ? Math.round((done / eligible) * 100) : 0;
}

/** Finished, among enrolments old enough to judge — the whole-period form of `completionAt`. */
export const completionRateOf = (spans: Span[], now: number) => completionAt(spans, now);

/* ─── Progress rebuilt from lesson timestamps ─── */

interface LessonMark {
  /** Minutes this lesson is worth. */
  minutes: number;
  /** When it was finished, or 0. */
  completedAt: number;
  /** Fraction watched while still in progress, and when that was last touched. */
  fraction: number;
  touchedAt: number;
}

export interface ProgressIndex {
  /** Total published minutes per course. */
  courseMinutes: Map<string, number>;
  /** `studentId:courseId` → what they have worked through. */
  marks: Map<string, LessonMark[]>;
  /** Published lesson count per course. */
  lessonCount: Map<string, number>;
}

const markKey = (studentId: string, courseId: string) => `${studentId}:${courseId}`;

/** Load the lesson-level history needed to place progress at any moment in the period. */
export async function progressIndex(courseIds: string[]): Promise<ProgressIndex> {
  const lessons = await db.lesson.findMany({
    where: { courseId: { in: courseIds }, status: 'published' },
    select: { id: true, courseId: true, durationMin: true },
  });
  const courseMinutes = new Map<string, number>();
  const lessonCount = new Map<string, number>();
  const lessonById = new Map(lessons.map((l) => [l.id, l]));
  for (const l of lessons) {
    courseMinutes.set(l.courseId, (courseMinutes.get(l.courseId) ?? 0) + l.durationMin);
    lessonCount.set(l.courseId, (lessonCount.get(l.courseId) ?? 0) + 1);
  }

  const rows = await db.lessonProgress.findMany({
    where: { lessonId: { in: lessons.map((l) => l.id) } },
    select: { studentId: true, lessonId: true, state: true, fraction: true, completedAt: true, lastAccessedAt: true },
  });
  const marks = new Map<string, LessonMark[]>();
  for (const r of rows) {
    const lesson = lessonById.get(r.lessonId);
    if (!lesson) continue;
    const key = markKey(r.studentId, lesson.courseId);
    const list = marks.get(key);
    const mark: LessonMark = {
      minutes: lesson.durationMin,
      completedAt: r.state === 'completed' ? (r.completedAt?.getTime() ?? r.lastAccessedAt?.getTime() ?? 0) : 0,
      fraction: r.state === 'in-progress' ? (r.fraction ?? 0) : 0,
      touchedAt: r.lastAccessedAt?.getTime() ?? 0,
    };
    if (list) list.push(mark);
    else marks.set(key, [mark]);
  }
  return { courseMinutes, marks, lessonCount };
}

/** How far this learner had come in this course at moment `t`, 0–100. */
export function progressAt(index: ProgressIndex, s: Span, t: number): number {
  if (t <= s.start) return 0;
  if (s.done && s.done <= t) return 100;
  const total = index.courseMinutes.get(s.courseId) ?? 0;
  if (total === 0) return 0;
  let done = 0;
  for (const m of index.marks.get(markKey(s.studentId, s.courseId)) ?? []) {
    if (m.completedAt && m.completedAt <= t) done += m.minutes;
    else if (m.fraction && m.touchedAt && m.touchedAt <= t) done += m.minutes * m.fraction;
  }
  return Math.max(0, Math.min(100, Math.round((done / total) * 100)));
}

/** Lessons finished inside the period, across the given enrolments. */
export function lessonsFinishedIn(index: ProgressIndex, spans: Span[], from: number, to: number) {
  let n = 0;
  for (const s of spans) {
    for (const m of index.marks.get(markKey(s.studentId, s.courseId)) ?? []) {
      if (m.completedAt > from && m.completedAt <= to) n += 1;
    }
  }
  return n;
}

/** Average progress across the enrolments under way in the period, as it stood at the end of it. */
export function avgProgressAt(index: ProgressIndex, spans: Span[], from: number, to: number) {
  let sum = 0;
  let n = 0;
  for (const s of spans) {
    if (!activeIn(s, from, to)) continue;
    sum += progressAt(index, s, to);
    n += 1;
  }
  return n ? Math.round(sum / n) : 0;
}

/* ─── Bands ─── */

const BANDS: { label: string; test: (p: number) => boolean }[] = [
  { label: '0–24%', test: (p) => p < 25 },
  { label: '25–49%', test: (p) => p >= 25 && p < 50 },
  { label: '50–74%', test: (p) => p >= 50 && p < 75 },
  { label: '75–99%', test: (p) => p >= 75 && p < 100 },
  { label: 'Finished', test: (p) => p >= 100 },
];

export const progressBands = (values: number[]) => BANDS.map((b) => ({ label: b.label, value: values.filter(b.test).length }));

/* ─── Chart periods ─── */

export interface Bucket {
  from: Date;
  to: Date;
  partial: boolean;
}

export const bucketsFor = (range: ReportRange, now: Date): Bucket[] => reportBuckets(range, now);

export const asPoints = (buckets: Bucket[], values: number[]) =>
  buckets.map((b, i) => ({ from: b.from.toISOString(), to: b.to.toISOString(), value: values[i] ?? 0, partial: b.partial || undefined }));

/** Place each moment in its bucket and count. */
export function bucketCounts(buckets: Bucket[], moments: number[]) {
  const counts = new Array(buckets.length).fill(0);
  for (const m of moments) {
    for (let i = 0; i < buckets.length; i++) {
      if (m > buckets[i].from.getTime() && m <= buckets[i].to.getTime()) {
        counts[i] += 1;
        break;
      }
    }
  }
  return counts;
}

/** Moments to read a rate at for a sparkline. */
export const sparkEnds = (buckets: Bucket[]) => sample(buckets, 10).map((b) => b.to.getTime());

/* ─── Learner status ─── */

/** A learner's status as it would have read at a moment; activity after it counts as not quiet. */
export function statusAt(lastSeen: number, hasOpenWork: boolean, t: number, atRiskDays: number): StudentStatus {
  const quiet = (t - Math.min(lastSeen, t)) / DAY;
  if (quiet >= INACTIVE_AFTER_DAYS) return 'inactive';
  if (quiet >= atRiskDays) return hasOpenWork ? 'at-risk' : 'inactive';
  return 'active';
}

export const SEGMENT_DEFAULT: LearnerSegment = 'all';

/* ─── Assessments, coursework and teaching ─── */

export interface AttemptRow {
  courseId: string;
  createdAt: Date;
  percent: number;
  passed: boolean;
}

export function quizFigures(attempts: AttemptRow[], from: number, to: number) {
  const inPeriod = attempts.filter((a) => a.createdAt.getTime() > from && a.createdAt.getTime() <= to);
  return {
    attempts: inPeriod.length,
    passRate: percentOf(inPeriod.filter((a) => a.passed).length, inPeriod.length) ?? 0,
    avgScore: inPeriod.length ? Math.round(avg(inPeriod.map((a) => a.percent))) : 0,
  };
}

export interface SubmissionRow {
  studentId: string;
  assignmentId: string;
  courseId: string;
  submittedAt: Date;
  late: boolean;
  score: number | null;
  maxScore: number;
  passMark: number;
  reviewStatus: string;
  reviewerId: string | null;
  reviewUpdatedAt: Date | null;
}

const isGraded = (s: SubmissionRow) => (s.reviewStatus === 'graded' || s.reviewStatus === 'returned') && s.score != null;

/** Review turnaround in hours for reviews *answered* in the period. */
export const reviewHoursIn = (subs: SubmissionRow[], from: number, to: number) =>
  subs
    .filter((s) => isGraded(s) && s.reviewUpdatedAt && s.reviewUpdatedAt.getTime() > from && s.reviewUpdatedAt.getTime() <= to)
    .map((s) => (s.reviewUpdatedAt!.getTime() - s.submittedAt.getTime()) / HOUR);

/** Share of reviews answered inside the on-time window. */
export const onTimeShare = (hours: number[]) => percentOf(hours.filter((h) => h <= ON_TIME_HOURS).length, hours.length);

export function assignmentFigures(subs: SubmissionRow[], from: number, to: number) {
  const handed = subs.filter((s) => s.submittedAt.getTime() > from && s.submittedAt.getTime() <= to);
  const graded = handed.filter(isGraded);
  const hours = reviewHoursIn(subs, from, to);
  return {
    submitted: handed.length,
    passRate: percentOf(graded.filter((s) => (s.score ?? 0) >= s.passMark).length, graded.length) ?? 0,
    onTime: percentOf(handed.filter((s) => !s.late).length, handed.length) ?? 0,
    reviewHours: Math.round(median(hours) ?? 0),
  };
}

/** A graded score as a percentage of what the assignment is worth. */
export const scorePercent = (s: SubmissionRow) => ((s.score ?? 0) / Math.max(1, s.maxScore)) * 100;

export interface LiveRow {
  courseId: string;
  instructorId: string;
  startsAt: Date;
  durationMin: number;
  cancelled: boolean;
  /** Learners who signed up, and how many of them were marked present. */
  registered: number;
  attended: number;
}

/** Attendance across the classes that had finished inside the period. */
export function liveAttendance(classes: LiveRow[], from: number, to: number, now: number, instructorId?: string) {
  let count = 0;
  let registered = 0;
  let attended = 0;
  for (const c of classes) {
    const at = c.startsAt.getTime();
    if (c.cancelled || (instructorId && c.instructorId !== instructorId)) continue;
    if (at <= from || at > to || at + c.durationMin * 60_000 >= now) continue;
    count += 1;
    registered += c.registered;
    attended += c.attended;
  }
  return { classes: count, rate: percentOf(attended, registered) };
}

/* ─── Cohorts ─── */

const monthFmt = new Intl.DateTimeFormat('en-IN', { month: 'short', year: 'numeric', timeZone: 'Asia/Kolkata' });

/** The last six monthly intakes and how quickly each finished. */
export function cohortsOf(spans: Span[], now: Date) {
  const ist = new Date(now.getTime() + 330 * 60_000);
  const monthStart = (offset: number) =>
    new Date(`${new Date(Date.UTC(ist.getUTCFullYear(), ist.getUTCMonth() + offset, 1)).toISOString().slice(0, 7)}-01T00:00:00+05:30`).getTime();

  return Array.from({ length: 6 }, (_, i) => {
    const start = monthStart(-6 + i);
    const end = monthStart(-5 + i);
    const intake = spans.filter((s) => s.start >= start && s.start < end);
    // A window only reports once every learner in it has had that long to finish.
    const within = (days: number) =>
      end + days * DAY > now.getTime() ? null : (percentOf(intake.filter((s) => s.done && s.done - s.start <= days * DAY).length, intake.length) ?? 0);
    return {
      month: monthFmt.format(new Date(start)).replace('Sept', 'Sep'),
      enrolled: intake.length,
      within30: within(30),
      within60: within(60),
      within90: within(90),
      toDate: percentOf(intake.filter((s) => s.done).length, intake.length) ?? 0,
    };
  }).reverse();
}

export { ON_TIME_HOURS };
