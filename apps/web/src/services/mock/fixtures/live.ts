import type { LiveClass } from '@syniastrolms/domain';
import { hashSeed, toIST } from '../random';
import { courses } from './catalog';
import { DEMO_NOW } from './learner';
import { enrollments } from './people';
import { academyLiveClasses } from './schedule';

/**
 * Details for every live class — descriptions, agendas, reminders — and ten weeks of past
 * sessions with attendance and recordings. Past sessions are added to the academy schedule
 * itself, so instructor figures and the calendar count the same classes.
 */

const NOW = new Date(DEMO_NOW).getTime();
const DAY = 86_400_000;

const DESCRIPTIONS: Record<string, string> = {
  'lc-live':
    'We read dignity chart by chart: exaltation, own sign, friendly and enemy signs, and how a planet’s dignity changes what it can deliver. Bring your own chart if you’d like it used as an example.',
  'lc-soon': 'Bring your questions from Chapter 2. Pooja works through the ones submitted in the discussion first, then opens the floor.',
  'lc-upcoming': 'The first four nakshatras in real charts — their lords, deities and symbols, and what changes when the Moon sits in each.',
  'lc-ended': 'Why the kendras and trikonas carry a chart, and how their lords combine into yogas. Recording available for a month.',
  'lc-dasha-antar': 'Timing events with antardashas: which sub-period lords can deliver, and how to cross-check with transits. Three case charts.',
  'lc-jaimini-clinic': 'Bring a chart you’ve worked with chara dasha. We’ll check sign dashas and the karakas together.',
  'lc-muhurta-griha': 'A griha pravesh muhurta from start to finish: panchang, tara and chandra balam, and choosing the lagna. For the cohort project.',
  'lc-yogas-public': 'Raja yogas in the charts of well-known public figures, with the dates their dashas ran. Open to every learner.',
  'lc-kp-ruling': 'Ruling planets in a live horary question, from casting to judgement.',
  'lc-nak-deities': 'The stories behind the nakshatra deities, and how they colour a placement.',
  'lc-cancelled': 'Open questions on Vimshottari timing.',
};

function agendaFor(cls: LiveClass) {
  const main = Math.max(15, cls.durationMin - 25);
  return [
    { title: 'Welcome and questions from last week', minutes: 10 },
    { title: cls.title, minutes: main },
    { title: 'Open questions', minutes: 15 },
  ];
}

const VISIBILITY: Record<string, LiveClass['visibility']> = { 'lc-muhurta-griha': 'cohort', 'lc-yogas-public': 'public' };

function enrich(cls: LiveClass) {
  cls.description ??=
    DESCRIPTIONS[cls.id] ??
    `A live session for ${courses.find((c) => c.id === cls.courseId)?.title ?? 'the course'}: a short talk, a worked chart and time for questions.`;
  cls.agenda ??= agendaFor(cls);
  cls.visibility ??= VISIBILITY[cls.id] ?? 'enrolled';
  cls.meeting ??= { kind: 'room' };
  cls.reminders ??= [1440, 60, 15];
  cls.capacity ??= 80;
  if (cls.registered === undefined) cls.registered = cls.attending !== undefined ? Math.min(cls.capacity, cls.attending + 25) : Math.round(cls.capacity * 0.8);
  if (cls.recording && cls.attended === undefined) cls.attended = Math.round((cls.registered ?? 60) * 0.72);
  // The built-in room is live only once its host opens it: sample classes already under way, or over, were.
  const start = Date.parse(cls.startsAt);
  if (cls.meeting.kind === 'room' && !cls.cancelled && start <= Date.parse(DEMO_NOW)) {
    cls.startedAt ??= cls.startsAt;
    const end = start + cls.durationMin * 60_000;
    if (end <= Date.parse(DEMO_NOW)) cls.endedAt ??= new Date(end).toISOString();
  }
  if (cls.cancelled) cls.cancelReason ??= 'Acharya Vinod is travelling for a conference. A new date will be announced in the course.';
}

function history(): LiveClass[] {
  const out: LiveClass[] = [];
  for (const course of courses.filter((c) => c.status === 'published' && c.liveSessions > 0)) {
    const active = enrollments.filter((e) => e.courseId === course.id && e.status === 'active').length;
    const chapters = course.chapters.filter((c) => c.lessons.length > 0);
    const offset = hashSeed(course.id) % 5;
    for (let k = 1; k <= 7; k++) {
      const h = hashSeed(`${course.id}:${k}`);
      const start = new Date(NOW - (k * 9 + offset) * DAY);
      start.setUTCHours(13, 30, 0, 0); // 7:00 PM IST
      if (start.getTime() > NOW - DAY) continue;
      const chapter = chapters[(chapters.length - (k % chapters.length)) % chapters.length];
      const capacity = [60, 80, 100, 120][h % 4];
      const registered = Math.max(12, Math.min(capacity, Math.round(active * (0.05 + (h % 5) / 100))));
      const cancelled = h % 23 === 0;
      const duration = [45, 60, 60, 75, 90][h % 5];
      out.push({
        id: `lc-h-${course.id}-${k}`,
        courseId: course.id,
        chapterId: chapter?.id,
        title: chapter ? `${chapter.title}: live review` : `${course.title}: live review`,
        instructorId: course.instructorIds[k % course.instructorIds.length],
        startsAt: toIST(start),
        durationMin: duration,
        capacity,
        registered,
        cancelled: cancelled || undefined,
        cancelReason: cancelled ? 'The instructor was unwell. The session was folded into the following week’s class.' : undefined,
        attended: cancelled ? undefined : Math.round(registered * (0.55 + ((h >> 3) % 30) / 100)),
        recording: cancelled ? undefined : { durationMin: duration - 3 - (h % 6), availableUntil: toIST(new Date(start.getTime() + 30 * DAY)) },
      });
    }
  }
  return out;
}

let ready = false;
/** The academy schedule with details filled in and past sessions added. Safe to call repeatedly. */
export function liveSchedule() {
  if (!ready) {
    ready = true;
    const existing = new Set(academyLiveClasses.map((c) => c.id));
    academyLiveClasses.push(...history().filter((c) => !existing.has(c.id)));
    academyLiveClasses.forEach(enrich);
  }
  return academyLiveClasses;
}
