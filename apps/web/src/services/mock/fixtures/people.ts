import type { Enrollment, EnrollmentStatus, Student } from '@syniastrolms/domain';
import { courseDurationMin } from '@syniastrolms/domain';
import { addDays, createRandom, DAY_MS, toIST } from '../random';
import { courses, levels } from './catalog';
import { DEMO_NOW } from './learner';

/**
 * The academy roster, generated deterministically. Course enrollment totals match each
 * course's `enrolledCount` exactly, so every screen that counts learners agrees.
 */

const NOW = new Date(DEMO_NOW);
const ACADEMY_OPENED = new Date('2024-10-01T09:00:00+05:30');
const STUDENT_COUNT = 3412;

// prettier-ignore
const FIRST = [
  'Aarav', 'Aditi', 'Akash', 'Amrita', 'Anand', 'Anjali', 'Arjun', 'Ashwin', 'Bhavna', 'Chetan', 'Deepa', 'Devika', 'Divya', 'Gaurav', 'Geeta', 'Harsh',
  'Isha', 'Jaya', 'Kabir', 'Kavya', 'Kiran', 'Krishna', 'Lavanya', 'Madhav', 'Mahima', 'Manish', 'Maya', 'Mohan', 'Nandita', 'Naveen', 'Nikhil', 'Nisha',
  'Omkar', 'Pallavi', 'Pranav', 'Priya', 'Radha', 'Rajesh', 'Ramya', 'Ravi', 'Rekha', 'Rohit', 'Sahana', 'Sameer', 'Sangeeta', 'Sanjana', 'Shalini', 'Shankar',
  'Shreya', 'Shruti', 'Sneha', 'Sonal', 'Sridhar', 'Sudha', 'Suresh', 'Swati', 'Tanvi', 'Tarun', 'Uma', 'Usha', 'Varun', 'Vasudha', 'Vidya', 'Vijay',
  'Vineeta', 'Yamini', 'Yash', 'Zoya', 'Parth', 'Riya', 'Keshav', 'Aparna',
];
// prettier-ignore
const LAST = [
  'Agarwal', 'Bajaj', 'Banerjee', 'Bhat', 'Chatterjee', 'Chauhan', 'Das', 'Desai', 'Dixit', 'Dutta', 'Gupta', 'Hegde', 'Iyengar', 'Jain', 'Kamath', 'Kapoor',
  'Khanna', 'Kohli', 'Kumar', 'Mahajan', 'Malhotra', 'Mehta', 'Mishra', 'Mukherjee', 'Naidu', 'Nair', 'Pandey', 'Patel', 'Patil', 'Pillai', 'Prasad', 'Raghavan',
  'Rajan', 'Rao', 'Reddy', 'Saxena', 'Sen', 'Shah', 'Sharma', 'Shetty', 'Sinha', 'Srinivasan', 'Tiwari', 'Trivedi', 'Venkatesh', 'Verma', 'Wagle', 'Yadav',
  'Bose', 'Menon', 'Kulkarni', 'Joshi', 'Ghosh', 'Kaur', 'Qureshi',
];
// prettier-ignore
const CITIES = [
  'Mumbai', 'New Delhi', 'Bengaluru', 'Chennai', 'Hyderabad', 'Pune', 'Kolkata', 'Ahmedabad', 'Jaipur', 'Lucknow', 'Kochi', 'Chandigarh', 'Indore', 'Bhopal',
  'Nagpur', 'Coimbatore', 'Mysuru', 'Varanasi', 'Surat', 'Vadodara', 'Guwahati', 'Bhubaneswar', 'Dehradun', 'Thiruvananthapuram', 'Visakhapatnam', 'Nashik',
  'Singapore', 'Dubai', 'London', 'Toronto',
];

/** Learners who appear by name elsewhere in the product keep their names and key facts. */
const PINNED: { id: string; name: string; email: string; city: string; joinedAt: string; rankId?: string }[] = [
  { id: 'u-ananya', name: 'Ananya Rao', email: 'ananya.rao@mail.in', city: 'Bengaluru', joinedAt: '2026-04-20T19:10:00+05:30' },
  { id: 's-siddharth', name: 'Siddharth Menon', email: 'sid.menon@mail.in', city: 'Kochi', joinedAt: '2026-03-02T09:00:00+05:30' },
  { id: 's-farah', name: 'Farah Qureshi', email: 'farah.q@mail.in', city: 'Hyderabad', joinedAt: '2025-06-11T09:00:00+05:30' },
  { id: 's-arjun', name: 'Arjun Nair', email: 'arjun.nair@mail.in', city: 'Kochi', joinedAt: '2026-05-14T09:00:00+05:30' },
  { id: 's-lakshmi', name: 'Lakshmi Pillai', email: 'lakshmi.p@mail.in', city: 'Chennai', joinedAt: '2025-04-03T09:00:00+05:30' },
  { id: 's-harpreet', name: 'Harpreet Kaur', email: 'harpreet.k@mail.in', city: 'Chandigarh', joinedAt: '2025-02-20T09:00:00+05:30' },
  { id: 's-vikram', name: 'Vikram Joshi', email: 'vikram.j@mail.in', city: 'Pune', joinedAt: '2026-06-01T09:00:00+05:30' },
  { id: 's-neha', name: 'Neha Bhattacharya', email: 'neha.b@mail.in', city: 'Kolkata', joinedAt: '2025-01-18T09:00:00+05:30' },
  { id: 's-karthik', name: 'Karthik Subramanian', email: 'karthik.s@mail.in', city: 'Coimbatore', joinedAt: '2025-05-27T09:00:00+05:30' },
  { id: 's-ishita', name: 'Ishita Ghosh', email: 'ishita.g@mail.in', city: 'Kolkata', joinedAt: '2024-10-04T09:00:00+05:30', rankId: 'r-master' },
  { id: 's-rahul', name: 'Rahul Verma', email: 'rahul.v@mail.in', city: 'Lucknow', joinedAt: '2026-08-30T09:00:00+05:30' },
  { id: 's-meera', name: 'Meera Krishnan', email: 'meera.k@mail.in', city: 'Mysuru', joinedAt: '2025-09-09T09:00:00+05:30' },
];

/** Enrollments that other fixtures depend on (the demo learner's courses, a certificate, a rank). */
const PINNED_ENROLLMENTS: Omit<Enrollment, 'id'>[] = [
  {
    studentId: 'u-ananya',
    courseId: 'intro-jyotish',
    enrolledAt: '2026-04-20T19:20:00+05:30',
    status: 'completed',
    progress: 100,
    source: 'self',
    completedAt: '2026-06-02T12:00:00+05:30',
    lastActiveAt: '2026-06-02T12:00:00+05:30',
  },
  {
    studentId: 'u-ananya',
    courseId: 'panchang',
    enrolledAt: '2026-06-05T10:00:00+05:30',
    status: 'completed',
    progress: 100,
    source: 'self',
    completedAt: '2026-08-21T21:00:00+05:30',
    lastActiveAt: '2026-08-21T21:00:00+05:30',
  },
  {
    studentId: 'u-ananya',
    courseId: 'foundations-vedic',
    enrolledAt: '2026-08-10T18:00:00+05:30',
    status: 'active',
    progress: 38,
    source: 'self',
    lastActiveAt: '2026-09-15T16:40:00+05:30',
    lastLessonId: 'm3-l5',
  },
  {
    studentId: 's-ishita',
    courseId: 'muhurta',
    enrolledAt: '2025-09-02T10:00:00+05:30',
    status: 'completed',
    progress: 100,
    source: 'cohort',
    completedAt: '2026-09-11T12:00:00+05:30',
    lastActiveAt: '2026-09-11T12:00:00+05:30',
  },
  {
    studentId: 's-lakshmi',
    courseId: 'yogas',
    enrolledAt: '2026-05-10T10:00:00+05:30',
    status: 'completed',
    progress: 100,
    source: 'self',
    completedAt: '2026-09-15T15:05:00+05:30',
    lastActiveAt: '2026-09-15T15:05:00+05:30',
  },
  {
    studentId: 's-siddharth',
    courseId: 'foundations-vedic',
    enrolledAt: '2026-03-03T09:00:00+05:30',
    status: 'active',
    progress: 72,
    source: 'self',
    lastActiveAt: '2026-09-15T16:40:00+05:30',
  },
  {
    studentId: 's-arjun',
    courseId: 'foundations-vedic',
    enrolledAt: '2026-05-15T09:00:00+05:30',
    status: 'active',
    progress: 14,
    source: 'self',
    lastActiveAt: '2026-08-29T18:00:00+05:30',
  },
];

function buildRoster() {
  const rng = createRandom(20260915);
  const span = NOW.getTime() - ACADEMY_OPENED.getTime();
  const used = new Set(PINNED.map((p) => p.name));
  const students: Student[] = PINNED.map((p) => ({ ...p, lastActiveAt: p.joinedAt, rankId: p.rankId ?? 'r-beginner' }));

  let serial = 0;
  while (students.length < STUDENT_COUNT) {
    const first = rng.pick(FIRST);
    const last = rng.pick(LAST);
    let name = `${first} ${last}`;
    if (used.has(name)) name = `${first} ${String.fromCharCode(65 + rng.int(0, 25))}. ${last}`;
    if (used.has(name)) continue;
    used.add(name);
    serial += 1;
    // Growth: more recent sign-ups than early ones
    const joined = new Date(ACADEMY_OPENED.getTime() + Math.sqrt(rng.next()) * span);
    const handle = `${first}.${last}`.toLowerCase().replace(/[^a-z.]/g, '');
    students.push({
      id: `s-${String(serial).padStart(4, '0')}`,
      name,
      email: `${handle}${rng.chance(0.4) ? rng.int(7, 98) : ''}@${rng.pick(['mail.in', 'gmail.com', 'outlook.com', 'yahoo.co.in'])}`,
      city: rng.pick(CITIES),
      joinedAt: toIST(joined),
      lastActiveAt: toIST(joined),
      suspended: rng.chance(0.002) || undefined,
      rankId: 'r-beginner',
    });
  }

  const byId = new Map(students.map((s) => [s.id, s]));
  const engagement = new Map(students.map((s) => [s.id, rng.next()]));
  const enrollments: Enrollment[] = PINNED_ENROLLMENTS.map((e, i) => ({ ...e, id: `en-p${i + 1}` }));
  /** Earliest enrollment date per student per level order — later levels follow earlier ones. */
  const levelOrder = new Map(levels.map((l) => [l.id, l.order]));
  const firstAtLevel = new Map<string, Map<number, number>>();
  const note = (e: Enrollment) => {
    const order = levelOrder.get(courses.find((c) => c.id === e.courseId)!.levelId)!;
    const map = firstAtLevel.get(e.studentId) ?? new Map<number, number>();
    const t = new Date(e.enrolledAt).getTime();
    map.set(order, Math.min(map.get(order) ?? Infinity, t));
    firstAtLevel.set(e.studentId, map);
  };
  enrollments.forEach(note);

  const ordered = [...courses].filter((c) => c.enrolledCount > 0).sort((a, b) => levelOrder.get(a.levelId)! - levelOrder.get(b.levelId)!);

  for (const course of ordered) {
    const order = levelOrder.get(course.levelId)!;
    const opened = new Date(course.publishedAt ?? course.createdAt).getTime();
    const closes = course.status === 'archived' ? new Date(course.updatedAt).getTime() : NOW.getTime() - 2 * 3_600_000;
    const pinnedCount = enrollments.filter((e) => e.courseId === course.id).length;
    const taken = new Set(enrollments.filter((e) => e.courseId === course.id).map((e) => e.studentId));

    /** When this learner would plausibly have enrolled: soon after joining for a first course, months after the level below for later ones. */
    const plan = (s: Student) => {
      const joined = new Date(s.joinedAt).getTime();
      const prior = firstAtLevel.get(s.id);
      const lowerAt = Math.min(...[...(prior?.entries() ?? [])].filter(([o]) => o < order).map(([, t]) => t), Infinity);
      const base =
        order === 1
          ? joined - Math.log(1 - rng.next()) * 14 * DAY_MS
          : Number.isFinite(lowerAt)
            ? lowerAt + rng.between(30, 160) * DAY_MS
            : joined + rng.between(20, 220) * DAY_MS;
      return Math.max(base, opened + rng.between(0, 28) * DAY_MS);
    };

    const candidates = students
      .filter((s) => !taken.has(s.id))
      .map((s) => {
        const prior = firstAtLevel.get(s.id);
        const hasLower = order === 1 || [...(prior?.keys() ?? [])].some((o) => o < order);
        return { s, at: plan(s), score: rng.next() + (hasLower ? 0.75 : 0) + engagement.get(s.id)! * 0.25 };
      })
      // The demo learner keeps exactly the courses her own screens describe.
      .filter((c) => c.at < closes && c.s.id !== 'u-ananya')
      .sort((a, b) => b.score - a.score)
      .slice(0, course.enrolledCount - pinnedCount);

    const hours = courseDurationMin(course) / 60;
    const lengthDays = Math.min(160, Math.max(24, hours * 7));

    for (const { s, at } of candidates) {
      const enrolledAt = new Date(at);

      const e = engagement.get(s.id)!;
      const pace = 0.35 + e * 1.1 + rng.between(-0.15, 0.15);
      const days = (NOW.getTime() - enrolledAt.getTime()) / DAY_MS;
      const raw = (days / lengthDays) * pace * 100;
      const stalls = rng.chance(0.46 - e * 0.24);
      const stallAt = rng.between(4, 72);

      let status: EnrollmentStatus = 'active';
      let progress: number;
      let lastActive: Date;
      let completedAt: string | undefined;

      if (stalls && raw > stallAt) {
        progress = Math.round(stallAt);
        lastActive = addDays(enrolledAt, (stallAt / 100) * (lengthDays / pace));
      } else if (raw >= 100) {
        progress = 100;
        status = 'completed';
        const done = addDays(enrolledAt, lengthDays / pace);
        completedAt = toIST(done > NOW ? NOW : done);
        lastActive = new Date(completedAt);
      } else {
        progress = Math.max(1, Math.round(raw));
        lastActive = new Date(NOW.getTime() - rng.between(0.02, 1.5 + (1 - e) * 9) * DAY_MS);
      }
      if (lastActive > NOW) lastActive = new Date(NOW.getTime() - rng.between(0.05, 2) * DAY_MS);
      if (lastActive < enrolledAt) lastActive = enrolledAt;
      if (status === 'active' && course.status === 'archived' && days > 150) status = 'expired';
      else if (status === 'active' && rng.chance(0.03)) status = 'paused';

      const enrollment: Enrollment = {
        id: `en-${course.id}-${s.id}`,
        studentId: s.id,
        courseId: course.id,
        enrolledAt: toIST(enrolledAt),
        status,
        progress,
        source: course.format === 'cohort' && rng.chance(0.55) ? 'cohort' : rng.chance(0.06) ? 'scholarship' : rng.chance(0.08) ? 'admin' : 'self',
        lastActiveAt: toIST(lastActive),
        completedAt,
      };
      enrollments.push(enrollment);
      note(enrollment);
    }
  }

  // Last activity and rank follow from enrollments
  const completedLevels = new Map<string, number>();
  for (const e of enrollments) {
    const s = byId.get(e.studentId)!;
    if (e.lastActiveAt && e.lastActiveAt > s.lastActiveAt) s.lastActiveAt = e.lastActiveAt;
    if (e.status === 'completed') {
      const order = levelOrder.get(courses.find((c) => c.id === e.courseId)!.levelId)!;
      completedLevels.set(e.studentId, Math.max(completedLevels.get(e.studentId) ?? 0, order));
    }
  }
  const RANK_BY_ORDER = ['r-beginner', 'r-beginner', 'r-intermediate', 'r-advanced', 'r-master'];
  for (const s of students) {
    if (s.rankId === 'r-beginner') s.rankId = RANK_BY_ORDER[completedLevels.get(s.id) ?? 0];
  }

  return { students, enrollments };
}

export const { students, enrollments } = buildRoster();
