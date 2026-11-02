import type {
  Assessment,
  Assignment,
  CertificateRecord,
  CourseProgressSnapshot,
  LearningEvent,
  LiveClass,
  Rank,
  RankStanding,
  StudyDay,
  UserProfile,
} from '@syniastrolms/domain';
import { PERMISSION_KEYS } from '@syniastrolms/domain';

/** The demo clock. Time-based states (live, due, retake) are computed against it. */
export const DEMO_NOW = '2026-09-15T18:52:00+05:30';

/** The roles the demo build can be viewed as. There is no Super Admin persona — that role has no demo workspace. */
export type DemoRole = Exclude<UserProfile['role'], 'superadmin'>;

export const personas: Record<DemoRole, UserProfile> = {
  student: { id: 'u-ananya', name: 'Ananya Rao', email: 'ananya.rao@mail.in', role: 'student', descriptor: 'Beginner · Rank I' },
  instructor: {
    id: 'u-meenakshi',
    name: 'Dr. Meenakshi Iyer',
    email: 'meenakshi@zuviloai.com',
    role: 'instructor',
    descriptor: 'Jyotish Acharya',
    instructorId: 'meenakshi',
  },
  // The demo build has no permission store behind it, and this persona exists to show the academy
  // admin workspace, so she holds the whole catalogue. A real installation grants keys one at a time
  // from the platform workspace.
  admin: {
    id: 'u-kavita',
    name: 'Kavita Menon',
    email: 'kavita@zuviloai.com',
    role: 'admin',
    descriptor: 'Platform admin',
    permissions: [...PERMISSION_KEYS],
  },
};

const done = (id: string, completedAt = '2026-09-01T20:00:00+05:30') => [id, { lessonId: id, state: 'completed' as const, completedAt }] as const;
const locked = (id: string) => [id, { lessonId: id, state: 'locked' as const }] as const;

export const foundationsProgress: CourseProgressSnapshot = {
  courseId: 'foundations-vedic',
  lastLessonId: 'm3-l5',
  lastActiveAt: '2026-09-15T16:40:00+05:30',
  lessons: Object.fromEntries([
    ...['m1-l1', 'm1-l2', 'm1-l3', 'm1-l4', 'm1-l5'].map((id) => done(id)),
    ...['m2-l1', 'm2-l2', 'm2-l3', 'm2-l4', 'm2-l5', 'm2-l6', 'm2-l7', 'm2-l8', 'm2-l9'].map((id) => done(id)),
    ...['m3-l1', 'm3-l2', 'm3-l3', 'm3-l4'].map((id) => done(id, '2026-09-15T16:10:00+05:30')),
    ['m3-l5', { lessonId: 'm3-l5', state: 'in-progress', fraction: 0.55, positionSec: 561 }],
    locked('m3-l8'),
    ...['m4-l1', 'm4-l2', 'm4-l3', 'm4-l4', 'm5-l1', 'm5-l2', 'm5-l3', 'm5-l4', 'm6-l1', 'm6-l2', 'm6-l3', 'm7-l1', 'm7-l2', 'm7-l3'].map(locked),
  ]),
};

export const liveClasses: LiveClass[] = [
  {
    id: 'lc-live',
    courseId: 'foundations-vedic',
    title: 'Reading dignities in real charts',
    instructorId: 'meenakshi',
    startsAt: '2026-09-15T18:30:00+05:30',
    durationMin: 60,
    attending: 46,
    capacity: 80,
  },
  {
    id: 'lc-soon',
    courseId: 'foundations-vedic',
    title: 'Doubt-clearing: the Nine Planets',
    instructorId: 'pooja',
    startsAt: '2026-09-15T19:00:00+05:30',
    durationMin: 45,
    attending: 12,
    capacity: 60,
  },
  {
    id: 'lc-upcoming',
    courseId: 'foundations-vedic',
    title: 'Nakshatras in practice: Ashwini to Rohini',
    instructorId: 'pooja',
    startsAt: '2026-09-17T19:00:00+05:30',
    durationMin: 90,
    capacity: 80,
  },
  {
    id: 'lc-ended',
    courseId: 'foundations-vedic',
    title: 'The Twelve Houses: kendra and trikona',
    instructorId: 'meenakshi',
    startsAt: '2026-09-10T19:00:00+05:30',
    durationMin: 90,
    recording: { durationMin: 84, availableUntil: '2026-10-10T23:59:00+05:30' },
  },
  {
    id: 'lc-expired',
    courseId: 'foundations-vedic',
    title: 'Welcome session: how to study Jyotish',
    instructorId: 'meenakshi',
    startsAt: '2026-07-18T11:00:00+05:30',
    durationMin: 60,
    recording: { durationMin: 58, availableUntil: '2026-08-18T23:59:00+05:30' },
  },
  {
    id: 'lc-cancelled',
    courseId: 'dasha',
    title: 'Open Q&A: Vimshottari timing',
    instructorId: 'vinod',
    startsAt: '2026-09-16T18:00:00+05:30',
    durationMin: 60,
    cancelled: true,
  },
];

export const assignments: Assignment[] = [
  {
    id: 'a-navagraha',
    courseId: 'foundations-vedic',
    chapterId: 'm2',
    title: 'Map the Navagraha in your own chart',
    brief: 'Place each graha, note its sign and dignity, and write two lines on its strongest signification.',
    dueAt: '2026-09-19T23:59:00+05:30',
    state: 'draft',
  },
  {
    id: 'a-lordship',
    courseId: 'foundations-vedic',
    chapterId: 'm3',
    title: 'House lordship worksheet: Aries lagna',
    brief: 'Work out the lord of every house for an Aries ascendant and where each lord is placed.',
    dueAt: '2026-09-26T23:59:00+05:30',
    state: 'not-started',
  },
  {
    id: 'a-sidereal',
    courseId: 'foundations-vedic',
    chapterId: 'm1',
    title: 'Sidereal and tropical: a short reflection',
    brief: '400 words on why ayanamsha matters for your practice.',
    dueAt: '2026-09-12T23:59:00+05:30',
    state: 'under-review',
    submittedAt: '2026-09-12T21:14:00+05:30',
  },
  {
    id: 'a-dignities',
    courseId: 'foundations-vedic',
    chapterId: 'm2',
    title: 'Identify exalted and debilitated planets',
    brief: 'Five sample charts, one table.',
    dueAt: '2026-09-08T23:59:00+05:30',
    state: 'graded',
    submittedAt: '2026-09-07T19:02:00+05:30',
    grade: { score: 18, max: 20, passMark: 14, feedbackAvailable: true },
  },
  {
    id: 'a-kendra',
    courseId: 'foundations-vedic',
    chapterId: 'm3',
    title: 'Kendra houses: a first essay',
    brief: 'Describe the four kendras in a chart of your choice.',
    dueAt: '2026-09-11T23:59:00+05:30',
    state: 'graded',
    submittedAt: '2026-09-11T22:40:00+05:30',
    grade: { score: 11, max: 20, passMark: 14, feedbackAvailable: true },
  },
  {
    id: 'a-journal',
    courseId: 'foundations-vedic',
    chapterId: 'm5',
    title: 'Nakshatra observation journal',
    brief: 'Note the Moon’s nakshatra each evening for a week.',
    dueAt: '2026-09-13T23:59:00+05:30',
    state: 'not-started',
    acceptsLate: true,
  },
  {
    id: 'a-submitted',
    courseId: 'foundations-vedic',
    chapterId: 'm2',
    title: 'Planetary friendships table',
    brief: 'Natural and temporary friendships for all seven visible planets.',
    dueAt: '2026-09-18T23:59:00+05:30',
    state: 'submitted',
    submittedAt: '2026-09-15T11:20:00+05:30',
  },
];

export const assessments: Assessment[] = [
  {
    id: 'as-planets',
    courseId: 'foundations-vedic',
    title: 'Chapter 2 check: The Nine Planets',
    questions: 20,
    durationMin: 30,
    passMark: 70,
    attemptsAllowed: 2,
    attemptsUsed: 1,
    state: 'passed',
    score: 84,
  },
  {
    id: 'as-houses',
    courseId: 'foundations-vedic',
    title: 'Chapter 3 assessment: The Twelve Houses',
    questions: 25,
    durationMin: 40,
    passMark: 70,
    attemptsAllowed: 2,
    attemptsUsed: 0,
    state: 'locked',
    lockedReason: 'Finish 3 more lessons in Chapter 3 to unlock',
  },
  {
    id: 'as-signs',
    courseId: 'foundations-vedic',
    title: 'Practice test: sign rulership',
    questions: 15,
    durationMin: 20,
    passMark: 70,
    attemptsAllowed: 3,
    attemptsUsed: 0,
    state: 'in-progress',
    answered: 9,
  },
  {
    id: 'as-intro',
    courseId: 'foundations-vedic',
    title: 'Check-in: foundations quiz',
    questions: 10,
    durationMin: 15,
    passMark: 60,
    attemptsAllowed: 3,
    attemptsUsed: 0,
    state: 'available',
  },
  {
    id: 'as-drill',
    courseId: 'foundations-vedic',
    title: 'Nakshatra lords: timed drill',
    questions: 27,
    durationMin: 15,
    passMark: 70,
    attemptsAllowed: 2,
    attemptsUsed: 1,
    state: 'failed',
    score: 58,
    retakeAvailableAt: '2026-09-17T09:00:00+05:30',
  },
  {
    id: 'as-written',
    courseId: 'foundations-vedic',
    title: 'Written assessment: first chart synthesis',
    questions: 4,
    durationMin: 60,
    passMark: 65,
    attemptsAllowed: 1,
    attemptsUsed: 1,
    state: 'submitted',
  },
];

export const certificates: CertificateRecord[] = [
  {
    id: 'cert-foundations',
    courseId: 'foundations-vedic',
    title: 'Certificate in Vedic Astrology Foundations',
    criteria: [
      { id: 'progress', label: 'Course progress', current: 38, required: 80, unit: '%' },
      { id: 'assignments', label: 'Assignments passed', current: 3, required: 5 },
      { id: 'live', label: 'Live sessions attended', current: 5, required: 8 },
      { id: 'final', label: 'Final assessment score', current: 0, required: 75, unit: '%' },
    ],
  },
  {
    id: 'cert-panchang',
    courseId: 'panchang',
    title: 'Panchang Essentials',
    criteria: [
      { id: 'progress', label: 'Course progress', current: 100, required: 90, unit: '%' },
      { id: 'final', label: 'Final assessment score', current: 81, required: 70, unit: '%' },
    ],
  },
  {
    id: 'cert-intro',
    courseId: 'intro-jyotish',
    title: 'Introduction to Jyotish',
    criteria: [
      { id: 'progress', label: 'Course progress', current: 100, required: 80, unit: '%' },
      { id: 'final', label: 'Final assessment score', current: 88, required: 70, unit: '%' },
    ],
    issuedAt: '2026-06-02T12:00:00+05:30',
    credentialId: 'SA-JY-2026-04817',
  },
];

export const ranks: Rank[] = [
  { id: 'r-beginner', title: 'Beginner', order: 1, descriptor: 'Knows the building blocks — planets, signs, houses and nakshatras.', criteria: [] },
  {
    id: 'r-intermediate',
    title: 'Intermediate',
    order: 2,
    descriptor: 'Reads a birth chart with a sound method and explains it clearly.',
    criteria: [
      { id: 'certs', label: 'Foundation certificates', current: 0, required: 2 },
      { id: 'readings', label: 'Guided readings reviewed', current: 0, required: 3 },
      { id: 'live', label: 'Live sessions attended', current: 0, required: 12 },
    ],
  },
  {
    id: 'r-advanced',
    title: 'Advanced',
    order: 3,
    descriptor: 'Times events with dashas, transits and divisional charts.',
    criteria: [
      { id: 'certs-adv', label: 'Intermediate certificates', current: 0, required: 3 },
      { id: 'cases', label: 'Case studies approved', current: 0, required: 5 },
    ],
  },
  {
    id: 'r-master',
    title: 'Master Astrologer',
    order: 4,
    descriptor: 'Reads complex charts, mentors learners and teaches the tradition.',
    criteria: [
      { id: 'thesis', label: 'Research thesis accepted', current: 0, required: 1 },
      { id: 'mentoring', label: 'Mentoring hours', current: 0, required: 40 },
    ],
  },
];

export const rankStanding: RankStanding = {
  rankId: 'r-beginner',
  achieved: { 'r-beginner': '2026-06-02T12:00:00+05:30' },
  progress: { certs: 1, readings: 2, live: 9 },
};

export const studyWeek: StudyDay[] = [
  { date: '2026-09-09', minutes: 42 },
  { date: '2026-09-10', minutes: 96 },
  { date: '2026-09-11', minutes: 0 },
  { date: '2026-09-12', minutes: 65 },
  { date: '2026-09-13', minutes: 28 },
  { date: '2026-09-14', minutes: 51 },
  { date: '2026-09-15', minutes: 38 },
];

export const recentActivity: LearningEvent[] = [
  {
    id: 'e1',
    kind: 'lesson-completed',
    title: 'Courage and siblings: the third house',
    context: 'Foundations of Vedic Astrology',
    at: '2026-09-15T16:10:00+05:30',
  },
  { id: 'e2', kind: 'assignment-submitted', title: 'Planetary friendships table', context: 'Chapter 2 · The Nine Planets', at: '2026-09-15T11:20:00+05:30' },
  { id: 'e3', kind: 'live-attended', title: 'The Twelve Houses: kendra and trikona', context: 'with Dr. Meenakshi Iyer', at: '2026-09-10T20:30:00+05:30' },
  { id: 'e4', kind: 'assessment-passed', title: 'Chapter 2 check: The Nine Planets', context: 'Scored 84% · pass mark 70%', at: '2026-09-09T18:45:00+05:30' },
  { id: 'e5', kind: 'certificate-issued', title: 'Introduction to Jyotish', context: 'Credential SA-JY-2026-04817', at: '2026-06-02T12:00:00+05:30' },
];
