import type { CalendarEvent, Course } from '@syniastrolms/domain';
import { courses } from './catalog';
import { personas } from './learner';
import { quizzes } from './quizzes';
import { DAY_MS, dayKey, hashSeed } from '../random';

/** A cohort course's current intake: chapters open a fortnight apart from a Monday start. */
export interface CohortPlan {
  startsOn: string;
  /** The date each chapter opens, in order. */
  releases: string[];
  endsOn: string;
  nextStartsOn: string;
  enrolmentClosesOn: string;
}

const COHORT_BASE = new Date('2026-08-03T00:00:00+05:30').getTime(); // a Monday
const on = (key: string, days: number) => dayKey(new Date(new Date(`${key}T00:00:00+05:30`).getTime() + days * DAY_MS));
const at = (key: string, time = '00:00') => `${key}T${time}:00+05:30`;
const monthName = (key: string) => new Intl.DateTimeFormat('en-IN', { month: 'long', timeZone: 'Asia/Kolkata' }).format(new Date(at(key)));

export function cohortPlan(course: Course): CohortPlan | undefined {
  if (course.format !== 'cohort' || course.status !== 'published' || course.chapters.length === 0) return undefined;
  const startsOn = dayKey(new Date(COHORT_BASE + (hashSeed(`cohort:${course.id}`) % 4) * 7 * DAY_MS));
  const releases = course.chapters.map((_, i) => on(startsOn, i * 14));
  const endsOn = on(startsOn, course.chapters.length * 14);
  const nextStartsOn = on(endsOn, 21);
  return { startsOn, releases, endsOn, nextStartsOn, enrolmentClosesOn: on(nextStartsOn, -3) };
}

const ADMIN = personas.admin.id;
const TEACHER = personas.instructor.id;

/** Reminders people set for themselves or for a course's learners. */
const REMINDERS: Omit<CalendarEvent, 'type'>[] = [
  {
    id: 'rem-welcome-email',
    ownerId: ADMIN,
    title: 'Send the welcome email to the September intake',
    timing: 'moment',
    startsAt: '2026-09-01T09:30:00+05:30',
    done: true,
    audience: 'me',
  },
  {
    id: 'rem-muhurta-note',
    ownerId: ADMIN,
    title: 'Publish the Muhurta chapter 3 announcement',
    timing: 'moment',
    startsAt: '2026-09-10T10:00:00+05:30',
    courseId: 'muhurta',
    done: true,
    audience: 'me',
  },
  {
    id: 'rem-issue-certs',
    ownerId: ADMIN,
    title: 'Issue the certificates that are ready',
    description: 'Check the ready-to-issue list before the weekly digest goes out at 6 PM.',
    timing: 'moment',
    startsAt: '2026-09-15T17:00:00+05:30',
    done: true,
    audience: 'me',
  },
  {
    id: 'rem-pricing',
    ownerId: ADMIN,
    title: 'Approve pricing for the October cohorts',
    description: 'Finance needs a yes or no on the ₹2,000 early-bird discount for Reading the Dasha System and Jaimini.',
    timing: 'moment',
    startsAt: '2026-09-16T10:30:00+05:30',
    notifyMin: 60,
    audience: 'me',
  },
  {
    id: 'rem-vinod-call',
    ownerId: ADMIN,
    title: 'Call with Acharya Vinod about the Jaimini intake',
    description: 'Agree the October start date and whether the case clinic moves to Saturdays.',
    timing: 'timed',
    startsAt: '2026-09-17T12:00:00+05:30',
    durationMin: 30,
    courseId: 'jaimini',
    notifyMin: 15,
    audience: 'me',
  },
  {
    id: 'rem-finance-report',
    ownerId: ADMIN,
    title: 'Send the August enrolment report to finance',
    timing: 'all-day',
    startsAt: '2026-09-18T00:00:00+05:30',
    notifyMin: 1440,
    audience: 'me',
  },
  {
    id: 'rem-dasha-backlog',
    ownerId: ADMIN,
    title: 'Check the review backlog on Reading the Dasha System',
    description: 'Six reviews were past 48 hours last week. If it’s still above three, ask Rohan to take some.',
    timing: 'moment',
    startsAt: '2026-09-21T09:30:00+05:30',
    courseId: 'dasha',
    audience: 'me',
  },
  {
    id: 'rem-room-licence',
    ownerId: ADMIN,
    title: 'Renew the live room licence',
    timing: 'all-day',
    startsAt: '2026-09-29T00:00:00+05:30',
    notifyMin: 1440,
    audience: 'me',
  },
  {
    id: 'rem-navaratri',
    ownerId: ADMIN,
    title: 'Plan the Navaratri taster class',
    description: 'A free public class on the nine nights and the grahas. Pick an instructor and a date in the week of 12 October.',
    timing: 'timed',
    startsAt: '2026-10-05T11:00:00+05:30',
    durationMin: 45,
    audience: 'me',
  },
  {
    id: 'rem-muhurta-learners',
    ownerId: ADMIN,
    title: 'Last week to finish Choosing a Muhurta chapter 3',
    description: 'A nudge before the cohort wraps up, with the link to the practice set.',
    timing: 'moment',
    startsAt: '2026-09-28T09:00:00+05:30',
    courseId: 'muhurta',
    audience: 'learners',
  },
  {
    id: 'rem-reading-list',
    ownerId: TEACHER,
    title: 'Share the reading list for chapter 3',
    timing: 'moment',
    startsAt: '2026-09-08T10:00:00+05:30',
    courseId: 'foundations-vedic',
    done: true,
    audience: 'me',
  },
  {
    id: 'rem-dignity-charts',
    ownerId: TEACHER,
    title: 'Prepare dignity charts for tonight’s class',
    timing: 'moment',
    startsAt: '2026-09-15T16:00:00+05:30',
    courseId: 'foundations-vedic',
    done: true,
    audience: 'me',
  },
  {
    id: 'rem-clear-queue',
    ownerId: TEACHER,
    title: 'Clear the Foundations review queue',
    timing: 'all-day',
    startsAt: '2026-09-16T00:00:00+05:30',
    courseId: 'foundations-vedic',
    audience: 'me',
  },
  {
    id: 'rem-record-walkthrough',
    ownerId: TEACHER,
    title: 'Record the chapter 5 walkthrough',
    description: 'Studio booked from 10. Bring the three navamsha examples from last cohort.',
    timing: 'timed',
    startsAt: '2026-09-17T10:00:00+05:30',
    durationMin: 90,
    courseId: 'foundations-vedic',
    notifyMin: 60,
    audience: 'me',
  },
  {
    id: 'rem-worksheet-learners',
    ownerId: TEACHER,
    title: 'House lordship worksheet — hand it in by Sunday',
    description: 'Learners get a short note with the worksheet link and the rubric.',
    timing: 'moment',
    startsAt: '2026-09-18T09:00:00+05:30',
    courseId: 'foundations-vedic',
    audience: 'learners',
  },
  {
    id: 'rem-pooja-reply',
    ownerId: TEACHER,
    title: 'Reply to Pooja about co-teaching the October cohort',
    timing: 'moment',
    startsAt: '2026-09-22T11:00:00+05:30',
    audience: 'me',
  },
];

function seed(): CalendarEvent[] {
  const out: CalendarEvent[] = [];
  for (const course of courses) {
    const plan = cohortPlan(course);
    if (!plan) continue;
    const lead = course.instructorIds[0];
    const base = { courseId: course.id, instructorId: lead, type: 'milestone' as const, timing: 'all-day' as const };
    out.push({
      ...base,
      id: `ms-${course.id}-start`,
      milestone: 'cohort-starts',
      title: `${monthName(plan.startsOn)} cohort starts`,
      description: 'Chapter 1 opens and the welcome session is scheduled for the first week.',
      startsAt: at(plan.startsOn),
      notifyMin: 1440,
    });
    plan.releases.slice(1).forEach((date, i) => {
      const chapter = course.chapters[i + 1];
      out.push({
        ...base,
        id: `ms-${course.id}-ch${i + 2}`,
        milestone: 'chapter-release',
        chapterId: chapter.id,
        title: `Chapter ${i + 2} opens: ${chapter.title}`,
        startsAt: at(date),
        notifyMin: 1440,
      });
    });
    out.push({
      ...base,
      id: `ms-${course.id}-end`,
      milestone: 'cohort-ends',
      title: `${monthName(plan.startsOn)} cohort wraps up`,
      description: 'The last chapter closes. Learners who finished receive their certificate.',
      startsAt: at(plan.endsOn),
    });
    out.push({
      ...base,
      id: `ms-${course.id}-enrol`,
      milestone: 'enrolment-closes',
      title: `Enrolment closes for the ${monthName(plan.nextStartsOn)} cohort`,
      description: 'Late enrolments go on the waiting list for the next intake.',
      startsAt: at(plan.enrolmentClosesOn),
      notifyMin: 1440,
    });
    out.push({
      ...base,
      id: `ms-${course.id}-next`,
      milestone: 'cohort-starts',
      title: `${monthName(plan.nextStartsOn)} cohort starts`,
      startsAt: at(plan.nextStartsOn),
      notifyMin: 1440,
    });

    for (const quiz of quizzes.filter((q) => q.courseId === course.id && q.status === 'published' && q.chapterId)) {
      const index = course.chapters.findIndex((c) => c.id === quiz.chapterId);
      if (index < 0) continue;
      out.push({
        id: `quiz-${quiz.id}`,
        type: 'quiz',
        quizId: quiz.id,
        title: quiz.title,
        description: 'Open from the day the chapter opens. It closes before the next chapter starts.',
        timing: 'moment',
        startsAt: at(on(plan.releases[index], 13), '23:59'),
        courseId: course.id,
        chapterId: quiz.chapterId,
        instructorId: lead,
        notifyMin: 1440,
      });
    }
  }

  for (const course of courses.filter((c) => c.status === 'draft')) {
    out.push({
      id: `ms-${course.id}-launch`,
      type: 'milestone',
      milestone: 'course-launch',
      title: `${course.title} launches`,
      description: 'Planned date for publishing the course to the catalog. Chapters and pricing need sign-off the week before.',
      timing: 'all-day',
      startsAt: at(on('2026-10-12', (hashSeed(`launch:${course.id}`) % 6) * 7)),
      courseId: course.id,
      instructorId: course.instructorIds[0],
      notifyMin: 1440,
    });
  }

  const sitting = (courseId: string, chapterIndex: number, id: string, title: string, startsAt: string, durationMin: number, description: string) => {
    const course = courses.find((c) => c.id === courseId);
    const chapter = course?.chapters[chapterIndex];
    const quiz = quizzes.find((q) => q.courseId === courseId && q.chapterId === chapter?.id && q.status === 'published');
    if (!course || !quiz) return;
    out.push({
      id,
      type: 'quiz',
      quizId: quiz.id,
      title,
      description,
      timing: 'timed',
      startsAt,
      durationMin,
      courseId,
      chapterId: chapter?.id,
      instructorId: course.instructorIds[0],
      notifyMin: 60,
    });
  };
  sitting(
    'foundations-vedic',
    2,
    'sit-foundations-ch3',
    'Chapter 3 checkpoint — sitting together',
    '2026-09-26T11:00:00+05:30',
    45,
    'The chapter 3 quiz, taken together with Dr. Meenakshi on hand to explain answers afterwards.',
  );
  sitting(
    'gochara',
    2,
    'sit-gochara-drill',
    'Transit timing drill',
    '2026-09-19T18:00:00+05:30',
    30,
    'A timed sitting before Saturday’s class — answers are discussed in the session.',
  );
  sitting(
    'navamsha',
    2,
    'sit-navamsha-review',
    'Navamsha review sitting',
    '2026-09-08T19:00:00+05:30',
    40,
    'Everyone takes the chapter 3 quiz at the same time, followed by a short walkthrough.',
  );

  for (const r of REMINDERS) out.push({ ...r, type: 'reminder' });
  return out;
}

let store: CalendarEvent[] | undefined;
/** Events added in the calendar — milestones, quiz windows and reminders. Live classes and deadlines are derived. */
export const calendarEvents = () => (store ??= seed());
