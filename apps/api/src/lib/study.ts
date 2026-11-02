import { db } from './db.js';

/**
 * Study time, derived from lesson progress: a completed lesson counts its full duration at the
 * time it was completed; a lesson in progress counts the fraction watched/read at its last access.
 */

interface ProgressRow {
  lessonId: string;
  state: string;
  fraction: number | null;
  completedAt: Date | null;
  lastAccessedAt: Date | null;
  lesson: { durationMin: number; courseId: string; title: string; status: string };
}

function minutesOf(row: ProgressRow): number {
  if (row.state === 'completed') return row.lesson.durationMin;
  if (row.state === 'in-progress') return Math.round((row.fraction ?? 0) * row.lesson.durationMin);
  return 0;
}

function momentOf(row: ProgressRow): Date | null {
  return row.state === 'completed' ? (row.completedAt ?? row.lastAccessedAt) : row.lastAccessedAt;
}

export async function progressRowsFor(studentId: string, courseIds?: string[]): Promise<ProgressRow[]> {
  return db.lessonProgress.findMany({
    where: { studentId, ...(courseIds ? { lesson: { courseId: { in: courseIds } } } : {}) },
    include: { lesson: { select: { durationMin: true, courseId: true, title: true, status: true } } },
  });
}

export function studyMinutes(rows: ProgressRow[]): number {
  return rows.reduce((n, r) => n + minutesOf(r), 0);
}

const DAY_MS = 86_400_000;
const shortDate = (d: Date) => d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', timeZone: 'Asia/Kolkata' });

/** `weeks` buckets, oldest first, ending with the current week (label "This week"). */
export function studyWeeks(rows: ProgressRow[], weeks = 12, now = new Date()): { label: string; detail: string; minutes: number }[] {
  const out: { label: string; detail: string; minutes: number }[] = [];
  for (let w = weeks - 1; w >= 0; w--) {
    const to = new Date(now.getTime() - w * 7 * DAY_MS);
    const from = new Date(to.getTime() - 7 * DAY_MS);
    const minutes = rows.reduce((n, r) => {
      const at = momentOf(r);
      return at && at > from && at <= to ? n + minutesOf(r) : n;
    }, 0);
    const label = shortDate(from);
    out.push({ label: w === 0 ? 'This week' : label, detail: `Week of ${label}`, minutes });
  }
  return out;
}

/** Minutes studied per calendar day (IST) for the last `days` days, oldest first. */
export function studyDays(rows: ProgressRow[], days = 7, now = new Date()): { date: string; minutes: number }[] {
  const dayKey = (d: Date) => d.toLocaleDateString('en-CA', { timeZone: 'Asia/Kolkata' });
  const out: { date: string; minutes: number }[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const date = dayKey(new Date(now.getTime() - i * DAY_MS));
    const minutes = rows.reduce((n, r) => {
      const at = momentOf(r);
      return at && dayKey(at) === date ? n + minutesOf(r) : n;
    }, 0);
    out.push({ date, minutes });
  }
  return out;
}

/** The learner's next lesson in a course: the one in progress, else the first published lesson not yet completed. */
export function nextLessonTitle(
  chapters: { lessons: { id: string; title: string; status: string; position: number }[]; position: number }[],
  rows: Pick<ProgressRow, 'lessonId' | 'state'>[],
): string | undefined {
  const byLesson = new Map(rows.map((r) => [r.lessonId, r.state]));
  const ordered = chapters
    .slice()
    .sort((a, b) => a.position - b.position)
    .flatMap((c) => c.lessons.slice().sort((a, b) => a.position - b.position))
    .filter((l) => l.status === 'published');
  return ordered.find((l) => byLesson.get(l.id) === 'in-progress')?.title ?? ordered.find((l) => byLesson.get(l.id) !== 'completed')?.title;
}
