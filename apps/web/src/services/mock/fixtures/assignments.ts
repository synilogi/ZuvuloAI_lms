import type { Attachment, BirthDetails, Course, CourseAssignment, DuePolicy, RubricCriterion, Submission, SubmissionFormat } from '@syniastrolms/domain';
import { assignmentMaxScore, chapterDurationMin, courseDurationMin, slugify } from '@syniastrolms/domain';
import { createRandom, hashSeed, toIST, type Random } from '../random';
import { courses } from './catalog';
import { DEMO_NOW } from './learner';
import { enrollments, students } from './people';

/**
 * Assignments as instructors write them, and every learner's submission. Submissions are
 * generated from the roster: learners who have finished a chapter have mostly handed in its
 * work, and the review queue per course is pinned so the dashboard's counts agree.
 */

const NOW = new Date(DEMO_NOW);
const HOUR = 3_600_000;
const CREATED = '2026-02-10T10:00:00+05:30';

/* ─── Rubrics ──────────────────────────────────────────────────────────── */

const criterion = (id: string, title: string, description: string, points: number): RubricCriterion => ({ id, title, description, points });

const RUBRICS: Record<SubmissionFormat, (max: 20 | 30) => RubricCriterion[]> = {
  chart: (max) => [
    criterion('placement', 'Chart accuracy', 'Lagna, grahas and nakshatras placed correctly for the birth details given.', max === 30 ? 8 : 6),
    criterion('application', 'Applies the chapter', 'Uses the principles from this chapter, not general impressions.', max === 30 ? 12 : 8),
    criterion('reasoning', 'Reasoning', 'Each judgement is traced to a placement, lordship or aspect.', max === 30 ? 6 : 4),
    criterion('clarity', 'Clarity', 'Organised so a client or peer could follow it.', max === 30 ? 4 : 2),
  ],
  file: (max) => [
    criterion('working', 'Correct working', 'Answers are right and complete for every item.', max === 30 ? 14 : 10),
    criterion('method', 'Shows the method', 'Steps are visible, so a mistake can be found and learned from.', max === 30 ? 10 : 6),
    criterion('presentation', 'Presentation', 'Legible, labelled and in the requested format.', max === 30 ? 6 : 4),
  ],
  text: (max) => [
    criterion('understanding', 'Understanding', 'Explains the idea accurately in the learner’s own words.', max === 30 ? 12 : 8),
    criterion('examples', 'Examples', 'Grounds the argument in charts or classical examples.', max === 30 ? 8 : 6),
    criterion('structure', 'Structure', 'A clear opening, a developed middle and a conclusion.', max === 30 ? 6 : 4),
    criterion('sources', 'Sources', 'Cites BPHS, Phaladeepika or the course notes where relevant.', max === 30 ? 4 : 2),
  ],
};

/* ─── Assignments ──────────────────────────────────────────────────────── */

interface Spec {
  id: string;
  courseId: string;
  chapterId?: string;
  lessonId?: string;
  title: string;
  instructions: string;
  format: SubmissionFormat;
  max?: 20 | 30;
  due?: DuePolicy;
  wordLimit?: number;
  acceptsLate?: boolean;
  latePenalty?: number;
  attachments?: Attachment[];
  status?: CourseAssignment['status'];
  noRubric?: boolean;
  updatedAt?: string;
}

const pdf = (id: string, name: string, sizeMb: number, pages: number): Attachment => ({ id, name, sizeMb, pages });

const SPECS: Spec[] = [
  {
    id: 'a-sidereal',
    courseId: 'foundations-vedic',
    chapterId: 'm1',
    title: 'Sidereal and tropical: a short reflection',
    format: 'text',
    wordLimit: 400,
    due: { kind: 'relative', days: 5 },
    instructions:
      'Write a short reflection — no more than 400 words — on why the ayanamsha matters for your practice.\n\n## Cover\n\n- What the precession of the equinoxes is, in one or two sentences\n- How far the tropical and sidereal zodiacs have drifted apart today\n- One placement in your own chart that changes sign between the two systems, and what that change means for how you read it\n\n> Write for a curious friend, not an examiner. Plain language earns more than jargon.',
  },
  {
    id: 'a-navagraha',
    courseId: 'foundations-vedic',
    chapterId: 'm2',
    lessonId: 'm2-l10',
    title: 'Map the Navagraha in your own chart',
    format: 'chart',
    due: { kind: 'relative', days: 7 },
    instructions:
      'Cast your own birth chart with Lahiri ayanamsha, then place each of the nine grahas.\n\n## For each graha, note\n\n- The sign and house it occupies\n- Its dignity: exalted, own sign, friendly, neutral, enemy or debilitated\n- Two lines on its strongest signification in your chart\n\nFinish with a paragraph on the graha you think is strongest, and why. If you would rather not share your own chart, use the practice chart in the lesson resources.',
    attachments: [pdf('att-navagraha-1', 'practice-chart-delhi-1984.pdf', 0.4, 1)],
  },
  {
    id: 'a-dignities',
    courseId: 'foundations-vedic',
    chapterId: 'm2',
    title: 'Identify exalted and debilitated planets',
    format: 'file',
    due: { kind: 'relative', days: 7 },
    instructions:
      'Five sample charts are attached. For each chart, find every graha that is exalted, debilitated or in moolatrikona, and record them in one table.\n\n## Your table\n\n- One row per chart, one column per graha\n- Mark exaltation, debilitation or moolatrikona, and the exact degree where it matters\n- Note any neecha bhanga you notice — it is not marked yet, but it is a good habit\n\nUpload a single PDF or a clear photo of a handwritten table.',
    attachments: [pdf('att-dignities-1', 'five-sample-charts.pdf', 1.8, 5)],
  },
  {
    id: 'a-submitted',
    courseId: 'foundations-vedic',
    chapterId: 'm2',
    title: 'Planetary friendships table',
    format: 'file',
    due: { kind: 'relative', days: 5 },
    instructions:
      'Complete the friendship table for the seven visible planets.\n\n## Two parts\n\n- **Natural friendships** (naisargika maitri) as given in Brihat Parashara Hora Shastra\n- **Temporary friendships** (tatkalika maitri) in the practice chart, from each planet’s position\n\nCombine the two into the five-fold relationship for each pair. Use the template attached so reviews are quick.',
    attachments: [pdf('att-friendship-1', 'friendship-table-template.pdf', 0.2, 2)],
  },
  {
    id: 'a-kendra',
    courseId: 'foundations-vedic',
    chapterId: 'm3',
    title: 'Kendra houses: a first essay',
    format: 'text',
    wordLimit: 600,
    due: { kind: 'relative', days: 7 },
    instructions:
      'Describe the four kendras — the 1st, 4th, 7th and 10th houses — in a chart of your choice.\n\n## Include\n\n- What each kendra signifies, and why the kendras are called the pillars of a chart\n- The sign on each kendra cusp and its lord’s placement\n- Which kendra is strongest in the chart, with your reasons\n\nUp to 600 words. Name the chart you use (a public figure is fine) and give its birth details.',
  },
  {
    id: 'a-lordship',
    courseId: 'foundations-vedic',
    chapterId: 'm3',
    lessonId: 'm3-l7',
    title: 'House lordship worksheet: Aries lagna',
    format: 'file',
    due: { kind: 'relative', days: 7 },
    instructions:
      'Work out the lord of every house for an Aries ascendant and where each lord is placed in the worksheet chart.\n\n## Then answer\n\n- Which planets are functional benefics for Aries lagna, and which are functional malefics?\n- Which planet becomes the yogakaraka, and why?\n- Where is the 10th lord placed, and what does that suggest about career?\n\nUse the worksheet attached. Show the lordship for each house before the answers.',
    attachments: [pdf('att-lordship-1', 'lordship-worksheet-aries.pdf', 0.6, 2)],
  },
  {
    id: 'a-journal',
    courseId: 'foundations-vedic',
    chapterId: 'm5',
    title: 'Nakshatra observation journal',
    format: 'text',
    due: { kind: 'relative', days: 10 },
    acceptsLate: true,
    latePenalty: 10,
    instructions:
      'For seven evenings, note the nakshatra the Moon is transiting and one thing you noticed about the day.\n\n## Each entry\n\n- The date, the Moon’s nakshatra and its lord\n- The mood of the day — your own, your household’s or the news\n- Whether it matched the nakshatra’s traditional nature\n\nThis is observation, not proof. End with three sentences on what surprised you.',
  },
  {
    id: 'asg-muhurta-c4-l3',
    courseId: 'muhurta',
    title: 'Elect a muhurta for a real family event',
    format: 'text',
    max: 30,
    due: { kind: 'date', dueAt: '2026-09-30T23:59:00+05:30' },
    wordLimit: 1200,
    instructions:
      'Choose a real event in your family in the next three months — a griha pravesh, a vehicle purchase, the start of a course — and elect the best muhurta you can find.\n\n## Show your working\n\n- The panchang elements for your chosen window: tithi, vara, nakshatra, yoga and karana\n- Tara and chandra balam for the person the muhurta is for\n- The lagna you chose and why, with any doshas you had to accept\n\n> Cohort project: due 30 September for everyone, so we can review muhurtas together in the October live class.',
  },
];

/** Lessons of type assignment outside Foundations each deliver one. */
const LESSON_SPECS: Record<string, Pick<Spec, 'format' | 'max' | 'due' | 'instructions' | 'attachments'>> = {
  'Nakshatra portrait of a chart': {
    format: 'chart',
    due: { kind: 'relative', days: 10 },
    instructions:
      'Write a nakshatra portrait of one chart: the lagna, Moon and Sun nakshatras, their lords and their deities.\n\n## Cover\n\n- The nature (gana, guna and animal symbol) of each of the three nakshatras\n- How the Moon’s nakshatra colours the mind in this chart\n- Where the nakshatra lords sit, and whether they support the portrait\n\nAround 800 words.',
  },
  'Time three events in a case chart': {
    format: 'file',
    max: 30,
    due: { kind: 'relative', days: 14 },
    instructions:
      'The case chart attached belongs to a consenting volunteer who shared three dated events: a marriage, a move abroad and a career change.\n\n## For each event\n\n- The Vimshottari mahadasha and antardasha running at the time\n- Why those lords could deliver that event in this chart\n- Supporting transits of Jupiter and Saturn\n\nUpload a PDF. Tables are welcome; show the dasha balance at birth.',
    attachments: [pdf('att-dasha-1', 'case-chart-events-volunteer-07.pdf', 0.9, 3)],
  },
  'Synthesis report on an unseen chart': {
    format: 'file',
    max: 30,
    due: { kind: 'relative', days: 14 },
    instructions:
      'Read the unseen chart attached as you would for a first consultation.\n\n## Your report\n\n- The three most significant yogas, with the placements that form them\n- Which yogas are cancelled or weakened, and why\n- A synthesis paragraph: what this person’s life is likely organised around\n\nTwo to four pages. Write for the client, then add a technical appendix for your reviewer.',
    attachments: [pdf('att-yogas-1', 'unseen-chart-12.pdf', 0.5, 1)],
  },
  'Career reading with the D10': {
    format: 'chart',
    due: { kind: 'relative', days: 14 },
    instructions:
      'Give a career reading for a chart of your choice, using the dashamsha alongside the rashi chart.\n\n## Include\n\n- The 10th house, its lord and their dignity in both D1 and D10\n- The D10 lagna lord and any planets in its kendras\n- A timing note: which coming dasha is most important for career\n\nState the birth time and how confident you are in it — the D10 is sensitive to minutes.',
  },
  'Chara dasha timeline of a life': {
    format: 'file',
    max: 30,
    due: { kind: 'relative', days: 14 },
    instructions:
      'Build a Jaimini chara dasha timeline for the biography chart attached, from birth to age 60.\n\n## Mark on the timeline\n\n- Each sign dasha and its length, with your calculation for two of them\n- The known life events from the biography\n- For three events, the chara karakas and arudhas that explain them\n\nA spreadsheet export or a hand-drawn timeline, uploaded as PDF.',
    attachments: [pdf('att-jaimini-1', 'biography-chart-and-events.pdf', 1.2, 4)],
  },
};

const DRAFT_SPECS: Spec[] = [
  {
    id: 'asg-remedies-sade-sati',
    courseId: 'remedies',
    title: 'Remedy plan for a Sade Sati consultation',
    format: 'text',
    due: { kind: 'relative', days: 10 },
    status: 'draft',
    updatedAt: '2026-09-14T17:05:00+05:30',
    instructions:
      'A client in the second phase of Sade Sati asks what they can do. Using the chart provided, write a remedy plan you would be comfortable prescribing.\n\n## Include\n\n- Whether a remedy is indicated at all, and why\n- One mantra, one daana and one lifestyle remedy, each with its reasoning\n- What you would tell the client about expectations',
  },
  {
    id: 'asg-prashna-three',
    courseId: 'prashna',
    title: 'Judge three horary questions',
    format: 'chart',
    status: 'draft',
    updatedAt: '2026-09-11T12:30:00+05:30',
    instructions: 'Three questions, three charts. ',
  },
  {
    id: 'asg-bridge-conversion',
    courseId: 'sidereal-bridge',
    title: 'Convert a tropical reading to sidereal',
    format: 'text',
    due: { kind: 'relative', days: 7 },
    status: 'closed',
    noRubric: true,
    updatedAt: '2026-03-02T09:00:00+05:30',
    instructions:
      'Take a tropical reading you have given before and rework it in the sidereal zodiac.\n\n- List every placement that changes sign\n- Rewrite the two paragraphs most affected\n- Reflect on which version you trust more, and why',
  },
];

function build(spec: Spec): CourseAssignment {
  const max = spec.max ?? 20;
  const rubric = spec.noRubric ? [] : RUBRICS[spec.format](max);
  const maxScore = spec.noRubric ? 10 : max;
  const passMark = Math.round(maxScore * 0.6);
  return {
    id: spec.id,
    courseId: spec.courseId,
    chapterId: spec.chapterId,
    lessonId: spec.lessonId,
    title: spec.title,
    instructions: spec.instructions,
    attachments: spec.attachments ?? [],
    format: spec.format,
    wordLimit: spec.wordLimit,
    due: spec.due ?? { kind: 'none' },
    acceptsLate: spec.acceptsLate ?? true,
    latePenalty: spec.latePenalty ?? (spec.acceptsLate === false ? 0 : 10),
    rubric,
    maxScore: assignmentMaxScore({ rubric, maxScore }),
    passMark,
    status: spec.status ?? 'published',
    createdAt: CREATED,
    updatedAt: spec.updatedAt ?? '2026-08-20T11:00:00+05:30',
  };
}

function fromLessons(): CourseAssignment[] {
  const out: CourseAssignment[] = [];
  for (const course of courses) {
    for (const chapter of course.chapters) {
      for (const lesson of chapter.lessons) {
        if (lesson.type !== 'assignment') continue;
        const existing = [...SPECS].find((s) => s.lessonId === lesson.id || s.title === lesson.title);
        if (existing) {
          existing.chapterId ??= chapter.id;
          existing.lessonId ??= lesson.id;
          continue;
        }
        const spec = LESSON_SPECS[lesson.title];
        if (spec) out.push(build({ id: `asg-${lesson.id}`, courseId: course.id, chapterId: chapter.id, lessonId: lesson.id, title: lesson.title, ...spec }));
      }
    }
  }
  return out;
}

const lessonAssignments = fromLessons();
export const courseAssignments: CourseAssignment[] = [...SPECS.map(build), ...lessonAssignments, ...DRAFT_SPECS.map(build)];

/* ─── Submissions ──────────────────────────────────────────────────────── */

/** Waiting and past-the-window reviews per course — the numbers the dashboard opens with. */
const QUEUE: Record<string, [waiting: number, overdue: number]> = {
  'foundations-vedic': [11, 3],
  muhurta: [3, 0],
  dasha: [9, 6],
  'nakshatra-depth': [2, 1],
  jaimini: [1, 0],
  navamsha: [2, 2],
};

const PINNED: Submission[] = [
  {
    id: 'sub-a-sidereal-u-ananya',
    assignmentId: 'a-sidereal',
    studentId: 'u-ananya',
    attempt: 1,
    submittedAt: '2026-09-12T21:14:00+05:30',
    late: false,
    files: [],
    text: 'The zodiac most of us grew up with is tropical: it begins wherever the Sun stands at the spring equinox. The sidereal zodiac used in Jyotish is anchored to the stars instead. Because the Earth’s axis wobbles slowly — the precession of the equinoxes — the equinox point drifts backwards against the stars by about one degree every 72 years.\n\nToday the two zodiacs are roughly 24 degrees apart (Lahiri ayanamsha puts it at 24°12′ this year). That is almost a whole sign, so most placements move back one sign when you switch systems.\n\nIn my own chart the Sun is at 2° Scorpio tropically, which becomes 8° Libra sidereally. I had always identified with Scorpio’s intensity, and it was uncomfortable at first to read my Sun as debilitated in Libra. But the Libra reading explains more: a lifelong habit of putting other people’s preferences first, and needing a partner’s approval before trusting my own judgement.\n\nThe ayanamsha matters because it decides which sign — and so which dignity, which lord and which nakshatra — every planet is read in. Two astrologers can look at the same sky and give opposite judgements if they don’t agree on where the zodiac starts.',
    review: {
      status: 'in-review',
      reviewerId: 'meenakshi',
      scores: { understanding: 7, examples: 5 },
      feedback: 'A clear account of precession, Ananya, and the Sun-in-Libra example is exactly the kind of personal test this reflection is for.',
      privateNote: 'Check the ayanamsha figure — 24°12′ is close but she should say which date it is for.',
      updatedAt: '2026-09-14T10:05:00+05:30',
    },
  },
  {
    id: 'sub-a-dignities-u-ananya',
    assignmentId: 'a-dignities',
    studentId: 'u-ananya',
    attempt: 1,
    submittedAt: '2026-09-07T19:02:00+05:30',
    late: false,
    files: [pdf('file-ananya-dignities', 'ananya-rao-dignities-table.pdf', 0.7, 2)],
    review: {
      status: 'graded',
      reviewerId: 'meenakshi',
      scores: { working: 9, method: 6, presentation: 3 },
      score: 18,
      feedback:
        'Excellent — every exaltation and debilitation is right, and you spotted the neecha bhanga in chart 4 before we have even covered it. Label the charts by number next time so the table is quicker to check.',
      updatedAt: '2026-09-08T16:30:00+05:30',
    },
  },
  {
    id: 'sub-a-kendra-u-ananya',
    assignmentId: 'a-kendra',
    studentId: 'u-ananya',
    attempt: 1,
    submittedAt: '2026-09-11T22:40:00+05:30',
    late: false,
    files: [],
    text: 'The kendras are the 1st, 4th, 7th and 10th houses. They are called the pillars of the chart because they hold up the four directions of a life: the self, the home, relationships and work.\n\nI used the chart of a friend born with Leo rising. The Sun rules the lagna and sits in the 10th house in Taurus, so self and career are closely tied. The 4th house has Scorpio on it and Mars is in the 7th.\n\nI think the 10th house is strongest because the lagna lord is there.',
    review: {
      status: 'graded',
      reviewerId: 'meenakshi',
      scores: { understanding: 5, examples: 3, structure: 2, sources: 1 },
      score: 11,
      feedback:
        'Good start on the meaning of the kendras. The essay stops just as it gets interesting: say what Mars in the 7th does as lord of the 4th and 9th, and weigh the 10th against the other kendras rather than asserting it. Compare with the worked example in lesson 3.3.',
      updatedAt: '2026-09-13T09:15:00+05:30',
    },
  },
  {
    id: 'sub-a-submitted-u-ananya',
    assignmentId: 'a-submitted',
    studentId: 'u-ananya',
    attempt: 1,
    submittedAt: '2026-09-15T11:20:00+05:30',
    late: false,
    files: [pdf('file-ananya-friendships', 'planetary-friendships-ananya.pdf', 0.4, 2)],
    text: 'Temporary friendships are worked from the practice chart; I wasn’t sure whether to count Rahu and Ketu so I left them out.',
    review: { status: 'waiting', scores: {}, feedback: '' },
  },
];

const slowShare = (reviewerId: string) => 0.04 + (hashSeed(reviewerId) % 14) / 100;
const clampTime = (ms: number) => Math.min(ms, NOW.getTime() - 20 * 60_000);

function scoreFor(assignment: CourseAssignment, studentId: string, rng: Random) {
  const ability = createRandom(hashSeed(studentId)).between(0.52, 0.96);
  const pct = Math.min(1, Math.max(0.25, ability + rng.between(-0.14, 0.08)));
  return Math.round(pct * assignment.maxScore * 2) / 2;
}

function generate(): Submission[] {
  const out: Submission[] = [...PINNED];
  const pinnedKeys = new Set(PINNED.map((s) => `${s.assignmentId}:${s.studentId}`));
  const byCourse = new Map<string, typeof enrollments>();
  for (const e of enrollments) {
    const list = byCourse.get(e.courseId);
    if (list) list.push(e);
    else byCourse.set(e.courseId, [e]);
  }

  for (const assignment of courseAssignments) {
    if (assignment.status === 'draft') continue;
    const course = courses.find((c) => c.id === assignment.courseId) as Course;
    const total = courseDurationMin(course) || 1;
    const index = Math.max(
      0,
      course.chapters.findIndex((c) => c.id === assignment.chapterId),
    );
    const through = course.chapters.slice(0, index + 1).reduce((n, c) => n + chapterDurationMin(c), 0) / total;
    const reviewer = course.instructorIds[0];

    for (const e of byCourse.get(course.id) ?? []) {
      // The demo learner's work is all pinned above.
      if (e.progress / 100 < through || e.studentId === 'u-ananya' || pinnedKeys.has(`${assignment.id}:${e.studentId}`)) continue;
      const rng = createRandom(hashSeed(`${assignment.id}:${e.studentId}`));
      if (!rng.chance(0.86)) continue;
      const start = new Date(e.enrolledAt).getTime();
      const end = new Date(e.completedAt ?? e.lastActiveAt ?? DEMO_NOW).getTime();
      const at = clampTime(start + (end - start) * Math.min(1, through / Math.max(e.progress / 100, 0.01)) + rng.between(0, 36) * HOUR);
      const due = assignment.due;
      const late = assignment.acceptsLate && (due.kind === 'date' ? at > new Date(due.dueAt).getTime() : due.kind === 'relative' && rng.chance(0.08));
      const raw = scoreFor(assignment, e.studentId, rng);
      const penalty = late ? Math.round(((raw * assignment.latePenalty) / 100) * 2) / 2 : 0;
      const recent = NOW.getTime() - at < 21 * 24 * HOUR;
      const returned = raw - penalty < assignment.passMark && recent && rng.chance(0.45);
      out.push({
        id: `sub-${assignment.id}-${e.studentId}`,
        assignmentId: assignment.id,
        studentId: e.studentId,
        attempt: 1,
        submittedAt: toIST(new Date(at)),
        late,
        files: [],
        review: {
          status: returned ? 'returned' : 'graded',
          reviewerId: reviewer,
          scores: {},
          points: raw,
          score: returned ? undefined : raw - penalty,
          feedback: '',
          // Each reviewer lets a small, steady share of reviews run past the 48-hour window.
          updatedAt: toIST(new Date(clampTime(at + (rng.chance(slowShare(reviewer)) ? rng.between(52, 130) : rng.between(3, 44)) * HOUR))),
        },
      });
    }
  }

  // Pin the open review queue per course: the newest submissions wait, some past the window.
  for (const [courseId, [waiting, overdue]] of Object.entries(QUEUE)) {
    const ids = new Set(courseAssignments.filter((a) => a.courseId === courseId).map((a) => a.id));
    const pinned = PINNED.filter((s) => ids.has(s.assignmentId) && (s.review.status === 'waiting' || s.review.status === 'in-review'));
    const pinnedOverdue = pinned.filter((s) => NOW.getTime() - new Date(s.submittedAt).getTime() > 48 * HOUR).length;
    const candidates = out
      .filter((s) => ids.has(s.assignmentId) && !PINNED.includes(s) && s.review.status === 'graded')
      .sort((a, b) => b.submittedAt.localeCompare(a.submittedAt))
      .slice(0, waiting - pinned.length);
    const inWindow = waiting - overdue - (pinned.length - pinnedOverdue);
    candidates.forEach((s, i) => {
      const rng = createRandom(hashSeed(`queue:${s.id}`));
      const hoursAgo = i < inWindow ? rng.between(2, 46) : rng.between(52, 150);
      s.submittedAt = toIST(new Date(NOW.getTime() - hoursAgo * HOUR));
      s.late = false;
      s.review = { status: rng.chance(0.25) ? 'in-review' : 'waiting', reviewerId: s.review.reviewerId, scores: {}, feedback: '' };
    });
  }
  return out;
}

let store: Submission[] | undefined;
/** Built on first use; the UI mutates these records in place. */
export const submissions = () => (store ??= generate());

/* ─── Response content, generated when a submission is opened ─────────── */

const PLACES = [
  'Pune, Maharashtra',
  'Kochi, Kerala',
  'Jaipur, Rajasthan',
  'Varanasi, Uttar Pradesh',
  'Mysuru, Karnataka',
  'Guwahati, Assam',
  'Indore, Madhya Pradesh',
  'Madurai, Tamil Nadu',
];
const SIGNS = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];
const NAKSHATRAS = [
  'Ashwini',
  'Bharani',
  'Krittika',
  'Rohini',
  'Mrigashira',
  'Ardra',
  'Punarvasu',
  'Pushya',
  'Ashlesha',
  'Magha',
  'Purva Phalguni',
  'Uttara Phalguni',
  'Hasta',
  'Chitra',
  'Swati',
  'Vishakha',
  'Anuradha',
  'Jyeshtha',
  'Mula',
  'Purva Ashadha',
  'Uttara Ashadha',
  'Shravana',
  'Dhanishta',
  'Shatabhisha',
  'Purva Bhadrapada',
  'Uttara Bhadrapada',
  'Revati',
];

const OPENINGS = [
  'I worked through this using the method from the chapter, one step at a time, before drawing any conclusions.',
  'Before writing anything I listed the placements, so the judgement below is traced back to the chart.',
  'This took longer than I expected, mostly because I kept checking my lordships against the table in the notes.',
];
const MIDDLES = [
  'The lagna lord is well placed in a kendra, which gives the chart a steady centre, but its dispositor is weak and that tempers the promise.',
  'Jupiter aspects the Moon from the fifth house, and I read that as the main protective influence on the mind in this chart.',
  'Saturn owns two houses here and sits in the tenth, so I weighed its role as a functional benefic for this lagna before calling it difficult.',
  'Mars in its own sign strengthens the house it occupies, though its eighth-house aspect is something I would want to watch in its dasha.',
  'The Moon’s nakshatra lord is placed in the twelfth, which fits a reflective, private temperament more than the sign alone suggests.',
  'I was unsure whether to count the Rahu–Ketu axis here, so I have noted it separately rather than mixing it into the main reading.',
];
const CLOSINGS = [
  'If I had more time I would check the navamsha to confirm the strength of the key planets.',
  'I would welcome feedback on whether my weighting of the dispositor is too heavy.',
  'Overall, the chart’s main theme seems to be responsibility that matures slowly and pays off later in life.',
];

function essay(rng: Random, paragraphs: number) {
  const middles = rng.shuffle(MIDDLES);
  const body = Array.from({ length: paragraphs }, (_, i) => `${middles[i % middles.length]} ${middles[(i + 3) % middles.length]}`);
  return [rng.pick(OPENINGS), ...body, rng.pick(CLOSINGS)].join('\n\n');
}

function birthDetails(rng: Random, name: string): BirthDetails {
  const year = rng.int(1972, 2003);
  const month = rng.int(1, 12);
  const day = rng.int(1, 28);
  return {
    label: rng.chance(0.6) ? `${name.split(' ')[0]}’s own chart` : 'A family member (shared with consent)',
    date: `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`,
    time: `${String(rng.int(0, 23)).padStart(2, '0')}:${String(rng.int(0, 59)).padStart(2, '0')}`,
    place: rng.pick(PLACES),
    lagna: rng.pick(SIGNS),
    moonSign: rng.pick(SIGNS),
    nakshatra: rng.pick(NAKSHATRAS),
  };
}

/** Fills in what the learner handed in, the first time a submission is opened. */
export function withResponse(submission: Submission, assignment: CourseAssignment): Submission {
  if (submission.text || submission.files.length || submission.chart) return submission;
  const rng = createRandom(hashSeed(`response:${submission.id}`));
  const student = students.find((s) => s.id === submission.studentId);
  const name = student?.name ?? 'Learner';
  const base = slugify(`${name} ${assignment.title}`).slice(0, 48);
  if (assignment.format === 'file') {
    submission.files = [pdf(`file-${submission.id}`, `${base}.pdf`, Math.round(rng.between(0.3, 3.2) * 10) / 10, rng.int(1, 6))];
    if (rng.chance(0.3))
      submission.files.push({ id: `file-${submission.id}-2`, name: 'chart-sketch.jpg', sizeMb: Math.round(rng.between(1.1, 4.5) * 10) / 10 });
    if (rng.chance(0.5)) submission.text = 'Covering note: I have shown each step on the first page and the answers on the second.';
  } else if (assignment.format === 'chart') {
    submission.chart = birthDetails(rng, name);
    submission.text = essay(rng, 3);
  } else {
    submission.text = essay(rng, assignment.maxScore > 20 ? 4 : 2);
  }
  return submission;
}

const FEEDBACK = {
  strong: [
    'Excellent work — clear, accurate and well reasoned. The link you drew between the lordship and the placement is exactly what this chapter is about.',
    'A confident piece. Your method is easy to follow and the conclusions are earned by the chart.',
  ],
  pass: [
    'Solid work that meets the brief. Push further on reasoning: say why a placement matters, not only where it is.',
    'Good understanding overall. A few judgements are asserted rather than shown — trace each one to a placement.',
  ],
  weak: [
    'You have the basics, but several placements are misread and that carries into the conclusions. Recheck the lordship table and resubmit.',
    'The structure is there, but the reasoning needs the chapter’s method. Rework the middle section using the worked example in the lessons.',
  ],
};

/** A graded submission's breakdown and comment, generated when it is first opened. */
export function withReviewDetail(submission: Submission, assignment: CourseAssignment): Submission {
  const r = submission.review;
  if ((r.status !== 'graded' && r.status !== 'returned') || r.feedback) return submission;
  const rng = createRandom(hashSeed(`review:${submission.id}`));
  const raw = r.points ?? r.score ?? 0;
  if (assignment.rubric.length) {
    let left = raw;
    const scores: Record<string, number> = {};
    assignment.rubric.forEach((c, i) => {
      const last = i === assignment.rubric.length - 1;
      const share = last ? left : Math.min(c.points, Math.round(((raw / assignment.maxScore) * c.points + rng.between(-0.8, 0.8)) * 2) / 2);
      scores[c.id] = Math.max(0, Math.min(c.points, share));
      left -= scores[c.id];
    });
    // Any remainder the caps couldn't place goes where there is room.
    for (const c of assignment.rubric) {
      if (left <= 0) break;
      const room = c.points - scores[c.id];
      const add = Math.min(room, left);
      scores[c.id] += add;
      left -= add;
    }
    r.scores = scores;
  }
  const pct = raw / assignment.maxScore;
  r.feedback = rng.pick(pct >= 0.8 ? FEEDBACK.strong : pct >= assignment.passMark / assignment.maxScore ? FEEDBACK.pass : FEEDBACK.weak);
  return submission;
}
