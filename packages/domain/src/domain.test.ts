import { describe, expect, it } from 'vitest';
import {
  validateLiveClass,
  validateCalendarEvent,
  validateNotificationSettings,
  validateSettings,
  reportWindow,
  reportBuckets,
  percentOf,
  median,
  calendarEventEnd,
  istDate,
  validateInstructor,
  assignmentMaxScore,
  reviewOverdue,
  reviewScore,
  validateAssignment,
  validateReview,
  buildTaxonomy,
  certificateState,
  courseProgress,
  criteriaPercent,
  deriveLiveClassPhase,
  canJoin,
  canStartRoom,
  effectiveAssignmentState,
  evaluateRankLadder,
  chapterProgress,
  deriveStudentStatus,
  kpiChange,
  lessonPublishIssues,
  readingMinutes,
  scoreAttempt,
  validateQuiz,
  publishChecklist,
  hasPublishedLessons,
  courseSale,
  chargeOf,
  pricingOf,
  slugify,
  type Assignment,
  type Course,
  type CourseProgressSnapshot,
  type LiveClass,
  type Rank,
  type Student,
} from './index';

const course: Course = {
  id: 'c1',
  slug: 'foundations',
  title: 'Foundations of Vedic Astrology',
  subtitle: 'Read the language of a birth chart.',
  description: '',
  levelId: 'beginner',
  categoryId: 'vedic',
  instructorIds: ['i1'],
  format: 'hybrid',
  language: 'English',
  coverMotif: 'houses',
  liveSessions: 12,
  enrolledCount: 0,
  status: 'draft',
  visibility: 'public',
  outcomes: [],
  tags: [],
  createdAt: '2026-08-01T00:00:00+05:30',
  updatedAt: '2026-09-01T00:00:00+05:30',
  chapters: [
    {
      id: 'm1',
      title: 'Introduction to Astrology',
      status: 'published',
      lessons: [
        { id: 'l1', title: 'What a chart records', type: 'video', durationMin: 30, status: 'published', updatedAt: '2026-09-01T00:00:00+05:30' },
        { id: 'l2', title: 'Sidereal and tropical zodiacs', type: 'video', durationMin: 10, status: 'published', updatedAt: '2026-09-01T00:00:00+05:30' },
      ],
    },
    {
      id: 'm2',
      title: 'The Nine Planets',
      status: 'draft',
      lessons: [{ id: 'l3', title: 'Surya', type: 'video', durationMin: 20, status: 'published', updatedAt: '2026-09-01T00:00:00+05:30' }],
    },
  ],
};

describe('progress', () => {
  it('weights progress by lesson duration', () => {
    const snapshot: CourseProgressSnapshot = {
      courseId: 'c1',
      lessons: {
        l1: { lessonId: 'l1', state: 'completed' },
        l2: { lessonId: 'l2', state: 'in-progress', fraction: 0.5 },
      },
    };
    const summary = courseProgress(course, snapshot);
    expect(summary.completed).toBe(1);
    expect(summary.total).toBe(3);
    expect(summary.percent).toBe(58); // 35 of 60 minutes
    expect(summary.remainingMin).toBe(25);
    expect(summary.state).toBe('in-progress');
  });

  it('reports locked chapters and completed chapters', () => {
    const snapshot: CourseProgressSnapshot = {
      courseId: 'c1',
      lessons: {
        l1: { lessonId: 'l1', state: 'completed' },
        l2: { lessonId: 'l2', state: 'completed' },
        l3: { lessonId: 'l3', state: 'locked' },
      },
    };
    expect(chapterProgress(course.chapters[0], snapshot).state).toBe('completed');
    expect(chapterProgress(course.chapters[1], snapshot).state).toBe('locked');
    expect(chapterProgress(course.chapters[1]).state).toBe('not-started');
  });
});

describe('live classes', () => {
  const cls: LiveClass = {
    id: 'lc1',
    courseId: 'c1',
    title: 'Nakshatras in practice',
    instructorId: 'i1',
    startsAt: '2026-09-15T19:00:00+05:30',
    durationMin: 90,
    recording: { durationMin: 84, availableUntil: '2026-10-15T00:00:00+05:30' },
  };
  const at = (iso: string) => new Date(iso);

  it('moves through its phases', () => {
    expect(deriveLiveClassPhase(cls, at('2026-09-15T18:00:00+05:30'))).toBe('upcoming');
    expect(deriveLiveClassPhase(cls, at('2026-09-15T18:50:00+05:30'))).toBe('starting-soon');
    expect(deriveLiveClassPhase(cls, at('2026-09-15T19:30:00+05:30'))).toBe('live');
    expect(deriveLiveClassPhase(cls, at('2026-09-16T10:00:00+05:30'))).toBe('ended');
    expect(deriveLiveClassPhase(cls, at('2026-11-01T10:00:00+05:30'))).toBe('recording-expired');
    expect(deriveLiveClassPhase({ ...cls, cancelled: true }, at('2026-09-15T19:30:00+05:30'))).toBe('cancelled');
  });

  it('runs the built-in room on the host: live from start until end, waiting before', () => {
    const room: LiveClass = { ...cls, meeting: { kind: 'room' }, recording: undefined };
    // In its slot but not opened: learners wait for the host and cannot go in.
    expect(deriveLiveClassPhase(room, at('2026-09-15T19:30:00+05:30'))).toBe('starting-soon');
    expect(canJoin('starting-soon', room)).toBe(false);
    expect(canStartRoom(room, at('2026-09-15T18:50:00+05:30'))).toBe(true);
    expect(canStartRoom(room, at('2026-09-15T18:00:00+05:30'))).toBe(false);
    // Opened early: live straight away, and joinable.
    const started = { ...room, startedAt: '2026-09-15T18:55:00+05:30' };
    expect(deriveLiveClassPhase(started, at('2026-09-15T18:56:00+05:30'))).toBe('live');
    expect(canJoin('live', started)).toBe(true);
    expect(canStartRoom(started, at('2026-09-15T18:56:00+05:30'))).toBe(false);
    // An overrun stays live for an hour past the slot, then counts as ended.
    expect(deriveLiveClassPhase(started, at('2026-09-15T21:00:00+05:30'))).toBe('live');
    expect(deriveLiveClassPhase(started, at('2026-09-15T21:31:00+05:30'))).toBe('recording-expired');
    // Ended by the host before the slot is over.
    const ended = { ...started, endedAt: '2026-09-15T19:40:00+05:30' };
    expect(deriveLiveClassPhase(ended, at('2026-09-15T19:41:00+05:30'))).toBe('recording-expired');
    const recorded = { ...ended, recording: { durationMin: 45, availableUntil: '2026-10-15T00:00:00+05:30', status: 'ready' as const } };
    expect(deriveLiveClassPhase(recorded, at('2026-09-15T19:41:00+05:30'))).toBe('ended');
    // Never opened and the slot is over: missed.
    expect(deriveLiveClassPhase(room, at('2026-09-15T20:31:00+05:30'))).toBe('recording-expired');
  });
});

describe('assignments', () => {
  const base: Assignment = {
    id: 'a1',
    courseId: 'c1',
    chapterId: 'm1',
    title: 'Map the Navagraha',
    brief: '',
    dueAt: '2026-09-19T23:59:00+05:30',
    state: 'draft',
  };
  it('turns unsubmitted work past its deadline into overdue or closed', () => {
    const late = new Date('2026-09-20T09:00:00+05:30');
    expect(effectiveAssignmentState(base, late)).toBe('closed');
    expect(effectiveAssignmentState({ ...base, acceptsLate: true }, late)).toBe('overdue');
    expect(effectiveAssignmentState({ ...base, state: 'submitted' }, late)).toBe('submitted');
  });
});

describe('certificates and ranks', () => {
  it('becomes eligible only when every criterion is met', () => {
    const record = {
      id: 'cert1',
      courseId: 'c1',
      title: 'Certificate in Vedic Astrology Foundations',
      criteria: [
        { id: 'lessons', label: 'Lessons completed', current: 80, required: 80, unit: '%' },
        { id: 'live', label: 'Live sessions attended', current: 6, required: 8 },
      ],
    };
    expect(certificateState(record)).toBe('not-eligible');
    expect(criteriaPercent(record.criteria)).toBe(88);
    expect(certificateState({ ...record, criteria: record.criteria.map((c) => ({ ...c, current: c.required })) })).toBe('eligible');
    expect(certificateState({ ...record, issuedAt: '2026-09-01T00:00:00+05:30' })).toBe('issued');
  });

  it('evaluates the rank ladder around the current rank', () => {
    const ranks: Rank[] = [
      { id: 'advanced', title: 'Advanced', order: 3, descriptor: '', criteria: [] },
      { id: 'beginner', title: 'Beginner', order: 1, descriptor: '', criteria: [] },
      {
        id: 'intermediate',
        title: 'Intermediate',
        order: 2,
        descriptor: '',
        criteria: [{ id: 'cert', label: 'Certificates', current: 0, required: 2 }],
      },
    ];
    const ladder = evaluateRankLadder(ranks, { rankId: 'beginner', achieved: {}, progress: { cert: 1 } });
    expect(ladder.map((s) => s.state)).toEqual(['current', 'next', 'future']);
    expect(ladder[1].percent).toBe(50);
  });
});

describe('taxonomy', () => {
  it('nests courses under levels and categories and drops empty branches', () => {
    const tree = buildTaxonomy(
      [
        { id: 'advanced', name: 'Advanced', order: 3 },
        { id: 'beginner', name: 'Beginner', order: 1 },
      ],
      [
        {
          id: 'vedic',
          name: 'Vedic Foundations',
          description: '',
          levelIds: ['beginner', 'advanced'],
          order: 1,
          status: 'active',
          glyph: 'sun',
          updatedAt: '2026-09-01T00:00:00+05:30',
        },
      ],
      [course],
    );
    expect(tree).toHaveLength(1);
    expect(tree[0].level.id).toBe('beginner');
    expect(tree[0].categories[0].courses[0].id).toBe('c1');
  });
});

describe('catalog rules', () => {
  it('slugifies titles', () => {
    expect(slugify('Reading the Navamsha (D9)')).toBe('reading-the-navamsha-d9');
    expect(slugify('  Muhurta: Electional Astrology ')).toBe('muhurta-electional-astrology');
  });

  it('lists what blocks publishing', () => {
    const unmet = publishChecklist(course)
      .filter((c) => !c.met)
      .map((c) => c.id);
    expect(unmet).toEqual(['description']);
  });

  it('asks only for a title, a description and an instructor before publishing', () => {
    const bare: Course = { ...course, subtitle: '', description: 'Fractions for Class 6.', outcomes: [], tags: [], chapters: [] };
    expect(publishChecklist(bare).every((c) => c.met)).toBe(true);
    expect(publishChecklist({ ...bare, title: 'Hi' }).find((c) => c.id === 'title')?.met).toBe(false);
    expect(publishChecklist({ ...bare, description: '   ' }).find((c) => c.id === 'description')?.met).toBe(false);
    expect(publishChecklist({ ...bare, instructorIds: [] }).find((c) => c.id === 'instructor')?.met).toBe(false);
  });

  it('tells whether learners would find lessons to study', () => {
    expect(hasPublishedLessons(course)).toBe(true);
    expect(hasPublishedLessons({ ...course, chapters: [] })).toBe(false);
    expect(hasPublishedLessons({ ...course, chapters: course.chapters.map((c) => ({ ...c, status: 'draft' as const })) })).toBe(false);
  });
});

describe('course pricing', () => {
  it('joins a free course for nothing, sells a paid one at its price, and opens an undecided one to nobody', () => {
    expect(courseSale({ pricing: 'free' })).toEqual({ kind: 'free' });
    expect(courseSale({ pricing: 'free', price: { amount: 999, currency: 'INR' } })).toEqual({ kind: 'free' });
    expect(courseSale({ pricing: 'paid', price: { amount: 1499, currency: 'INR' } })).toEqual({ kind: 'paid', price: { amount: 1499, currency: 'INR' } });
    expect(courseSale({ pricing: 'unset', price: { amount: 2999, currency: 'INR' } })).toEqual({ kind: 'unavailable' });
  });

  it('never treats a paid course without a valid price as free', () => {
    for (const price of [
      undefined,
      { amount: 0, currency: 'INR' as const },
      { amount: -5, currency: 'INR' as const },
      { amount: 99.5, currency: 'INR' as const },
      { amount: 600_000, currency: 'INR' as const },
    ]) {
      expect(courseSale({ pricing: 'paid', price }), JSON.stringify(price)).toEqual({ kind: 'unavailable' });
    }
  });

  it('reads a record from before pricing existed as undecided when it carries a price', () => {
    expect(pricingOf({ price: { amount: 2999, currency: 'INR' } })).toBe('unset');
    expect(pricingOf({})).toBe('free');
  });

  it('charges in paise', () => {
    expect(chargeOf({ amount: 1499, currency: 'INR' })).toBe(149_900);
  });
});

describe('people and analytics', () => {
  const student: Student = {
    id: 's1',
    name: 'Arjun Nair',
    email: 'arjun@mail.in',
    city: 'Kochi',
    joinedAt: '2026-01-01T00:00:00+05:30',
    lastActiveAt: '2026-09-01T00:00:00+05:30',
    rankId: 'r-beginner',
  };
  const now = new Date('2026-09-15T12:00:00+05:30');
  const open = [
    { id: 'e1', studentId: 's1', courseId: 'c1', enrolledAt: '2026-08-01T00:00:00+05:30', status: 'active' as const, progress: 20, source: 'self' as const },
  ];

  it('marks quiet learners with open work as at risk, and long-quiet learners inactive', () => {
    expect(deriveStudentStatus(student, open, now)).toBe('at-risk');
    expect(deriveStudentStatus(student, [], now)).toBe('inactive');
    expect(deriveStudentStatus({ ...student, lastActiveAt: '2026-09-14T00:00:00+05:30' }, open, now)).toBe('active');
    expect(deriveStudentStatus({ ...student, lastActiveAt: '2026-07-01T00:00:00+05:30' }, open, now)).toBe('inactive');
    expect(deriveStudentStatus({ ...student, suspended: true }, open, now)).toBe('suspended');
  });

  it('compares rates in points and counts in percent', () => {
    expect(kpiChange({ value: 64, previous: 61, unit: '%' })).toEqual({ direction: 'up', amount: 3, unit: 'pts' });
    expect(kpiChange({ value: 90, previous: 100, unit: 'count' })).toEqual({ direction: 'down', amount: 10, unit: '%' });
    expect(kpiChange({ value: 8, previous: 8 })).toEqual({ direction: 'flat', amount: 0, unit: '%' });
  });
});

describe('lesson rules', () => {
  it('asks for the content each lesson type needs before publishing', () => {
    expect(lessonPublishIssues({ title: 'Surya', type: 'video', durationMin: 18 }).map((i) => i.field)).toEqual(['lesson-media']);
    expect(
      lessonPublishIssues({
        title: 'Surya',
        type: 'video',
        durationMin: 18,
        content: { video: { file: { name: 'surya.mp4', sizeMb: 420 }, captions: true, markers: [] } },
      }),
    ).toEqual([]);
    expect(lessonPublishIssues({ title: 'Ab', type: 'reading', durationMin: 0 }).map((i) => i.field)).toEqual([
      'lesson-title',
      'lesson-duration',
      'lesson-body',
    ]);
  });

  it('estimates reading time at 200 words a minute', () => {
    expect(readingMinutes('word '.repeat(1000))).toBe(5);
    expect(readingMinutes('short')).toBe(1);
  });
});

describe('quizzes', () => {
  const quiz = {
    title: 'Chapter 3 assessment',
    settings: { passMark: 70, attempts: 2, shuffleQuestions: false, shuffleOptions: true, showResults: 'score-and-answers' as const },
    questions: [
      {
        id: 'q1',
        type: 'single' as const,
        prompt: 'Which house is the lagna?',
        options: [
          { id: 'a', text: 'First' },
          { id: 'b', text: 'Seventh' },
        ],
        correct: ['a'],
        acceptedAnswers: [],
        points: 2,
        required: true,
      },
      {
        id: 'q2',
        type: 'multiple' as const,
        prompt: 'Which are kendra houses?',
        options: [
          { id: 'a', text: '1' },
          { id: 'b', text: '4' },
          { id: 'c', text: '5' },
          { id: 'd', text: '7' },
        ],
        correct: ['a', 'b', 'd'],
        acceptedAnswers: [],
        points: 3,
        required: true,
      },
      {
        id: 'q3',
        type: 'short' as const,
        prompt: 'Name the lord of Aries.',
        options: [],
        correct: [],
        acceptedAnswers: ['Mars', 'Mangala'],
        points: 1,
        required: false,
      },
    ],
  };

  it('scores single, partial multiple and short answers', () => {
    const result = scoreAttempt(quiz, { q1: ['a'], q2: ['a', 'b', 'c'], q3: '  mangala ' });
    expect(result.questions.q1.state).toBe('correct');
    expect(result.questions.q2).toEqual({ state: 'partial', points: 1 });
    expect(result.questions.q3.state).toBe('correct');
    expect(result.max).toBe(6);
    expect(result.percent).toBe(66); // 4 of 6, rounded down: a score never rounds up past a pass mark
    expect(result.passed).toBe(false);
    expect(scoreAttempt(quiz, {}).questions.q1.state).toBe('unanswered');
  });

  it('explains what blocks publishing', () => {
    const broken = {
      ...quiz,
      questions: [
        { ...quiz.questions[0], correct: [] },
        { ...quiz.questions[2], acceptedAnswers: [''] },
      ],
    };
    expect(validateQuiz(broken).map((i) => i.field)).toEqual(['correct', 'answers']);
    expect(validateQuiz({ ...quiz, title: 'Q', questions: [] }).map((i) => i.field)).toEqual(['title', 'questions']);
  });
});

describe('assignment authoring and review', () => {
  const now = new Date('2026-09-15T18:52:00+05:30');
  const rubric = [
    { id: 'accuracy', title: 'Accurate placements', description: '', points: 8 },
    { id: 'reasoning', title: 'Reasoning', description: '', points: 8 },
    { id: 'clarity', title: 'Clarity', description: '', points: 4 },
  ];
  const input = {
    courseId: 'foundations-vedic',
    title: 'House lordship worksheet',
    instructions: 'Work out the lord of every house for an Aries ascendant and where each lord is placed.',
    attachments: [],
    format: 'file' as const,
    due: { kind: 'relative' as const, days: 7 },
    acceptsLate: true,
    latePenalty: 10,
    rubric,
    maxScore: 0,
    passMark: 14,
    status: 'published' as const,
  };

  it('scores against the rubric with a late penalty', () => {
    expect(assignmentMaxScore(input)).toBe(20);
    expect(reviewScore(input, { scores: { accuracy: 7, reasoning: 6, clarity: 3 } }, true)).toEqual({ raw: 16, penalty: 1.5, score: 14.5, max: 20 });
    expect(reviewScore({ ...input, rubric: [], maxScore: 10 }, { scores: {}, points: 8 }, false).score).toBe(8);
  });

  it('blocks publishing until the brief and rubric are complete', () => {
    expect(validateAssignment(input, now)).toEqual([]);
    const broken = {
      ...input,
      instructions: 'Too short.',
      rubric: [
        { ...rubric[0], title: '' },
        { ...rubric[1], points: 0 },
      ],
      passMark: 30,
      due: { kind: 'date' as const, dueAt: '2026-09-01T23:59:00+05:30' },
    };
    expect(validateAssignment(broken, now).map((i) => i.field)).toEqual(['instructions', 'rubric', 'rubric', 'passMark', 'due']);
  });

  it('needs every criterion scored to grade, and a reason to return', () => {
    expect(validateReview(input, { scores: { accuracy: 7, reasoning: 9 }, feedback: 'Good work overall.' }, 'graded').map((i) => i.criterionId)).toEqual([
      'reasoning',
      'clarity',
    ]);
    expect(validateReview(input, { scores: {}, feedback: 'Redo it.' }, 'returned')).toHaveLength(1);
    expect(reviewOverdue({ submittedAt: '2026-09-12T21:14:00+05:30', review: { status: 'in-review', scores: {}, feedback: '' } }, now)).toBe(true);
    expect(reviewOverdue({ submittedAt: '2026-09-15T11:20:00+05:30', review: { status: 'waiting', scores: {}, feedback: '' } }, now)).toBe(false);
  });
});

describe('instructor rules', () => {
  const input = {
    name: 'Kiran Joshi',
    title: 'Vastu consultant',
    email: 'kiran.joshi@zuviloai.com',
    bio: '',
    expertise: ['Vastu Shastra'],
    status: 'invited' as const,
    city: 'Ahmedabad',
    languages: ['Gujarati'],
    courseIds: [],
  };

  it('asks for a bio only once an instructor is active', () => {
    expect(validateInstructor(input)).toEqual([]);
    expect(validateInstructor({ ...input, status: 'active' }).map((i) => i.field)).toEqual(['bio']);
  });

  it('checks email format, uniqueness and phone digits', () => {
    expect(validateInstructor({ ...input, email: 'kiran@' }).map((i) => i.field)).toEqual(['email']);
    expect(validateInstructor(input, ['Kiran.Joshi@zuviloai.com']).map((i) => i.message)).toEqual(['Another instructor already uses this email.']);
    expect(validateInstructor({ ...input, phone: '+91 98200 12345' })).toEqual([]);
    expect(validateInstructor({ ...input, phone: '12ab' }).map((i) => i.field)).toEqual(['phone']);
  });
});

describe('live class scheduling rules', () => {
  const now = new Date('2026-09-15T18:52:00+05:30');
  const input = {
    courseId: 'dasha',
    title: 'Antardasha timing workshop',
    instructorId: 'vinod',
    startsAt: '2026-09-20T19:00:00+05:30',
    durationMin: 90,
    capacity: 120,
  };

  it('accepts a future class and explains what is wrong with a broken one', () => {
    expect(validateLiveClass(input, now)).toEqual([]);
    const broken = { ...input, title: 'Q', startsAt: '2026-09-14T19:00:00+05:30', durationMin: 5, meeting: { kind: 'external' as const, link: 'zoom.us/j/1' } };
    expect(validateLiveClass(broken, now).map((i) => i.field)).toEqual(['title', 'startsAt', 'duration', 'meeting']);
    expect(validateLiveClass({ ...input, agenda: [{ title: 'Talk', minutes: 100 }] }, now).map((i) => i.field)).toEqual(['agenda']);
  });

  it('reads a cleared capacity as no limit', () => {
    expect(validateLiveClass({ ...input, capacity: null as unknown as undefined }, now, 40)).toEqual([]);
    expect(validateLiveClass({ ...input, capacity: undefined }, now)).toEqual([]);
  });

  it('won’t shrink capacity below the learners already registered', () => {
    expect(validateLiveClass({ ...input, capacity: 40 }, now, 118)[0].message).toContain('118 learners');
  });
});

describe('calendar event rules', () => {
  const now = new Date('2026-09-15T18:52:00+05:30');
  const reminder = {
    type: 'reminder' as const,
    title: 'Approve cohort pricing',
    timing: 'moment' as const,
    startsAt: '2026-09-16T10:30:00+05:30',
    audience: 'me' as const,
  };

  it('accepts a personal reminder without a course, but not a nudge to learners', () => {
    expect(validateCalendarEvent(reminder, now)).toEqual([]);
    expect(validateCalendarEvent({ ...reminder, audience: 'learners' }, now).map((i) => i.field)).toEqual(['course']);
  });

  it('needs the quiz, milestone kind and chapter that an event points at', () => {
    expect(validateCalendarEvent({ ...reminder, type: 'quiz', courseId: 'dasha' }, now).map((i) => i.field)).toEqual(['quiz']);
    expect(
      validateCalendarEvent({ ...reminder, type: 'milestone', timing: 'all-day', courseId: 'dasha', milestone: 'chapter-release' }, now).map((i) => i.field),
    ).toEqual(['chapter']);
    expect(validateCalendarEvent({ ...reminder, type: 'live' }, now).map((i) => i.field)).toEqual(['type']);
  });

  it('allows today for all-day events but not a time that has passed', () => {
    expect(validateCalendarEvent({ ...reminder, timing: 'all-day', startsAt: '2026-09-15T00:00:00+05:30' }, now)).toEqual([]);
    expect(validateCalendarEvent({ ...reminder, startsAt: '2026-09-15T09:00:00+05:30' }, now).map((i) => i.field)).toEqual(['startsAt']);
    expect(validateCalendarEvent({ ...reminder, timing: 'timed', durationMin: 0 }, now).map((i) => i.field)).toEqual(['duration']);
  });

  it('reads IST dates and event ends', () => {
    expect(istDate('2026-09-15T20:00:00Z')).toBe('2026-09-16');
    expect(calendarEventEnd({ timing: 'timed', startsAt: '2026-09-16T10:00:00+05:30', durationMin: 90 }).toISOString()).toBe('2026-09-16T06:00:00.000Z');
    expect(calendarEventEnd({ timing: 'all-day', startsAt: '2026-09-16T00:00:00+05:30' }).toISOString()).toBe('2026-09-16T18:30:00.000Z');
  });
});

describe('notification settings', () => {
  const settings = {
    categories: [
      { category: 'live' as const, channels: { app: true, email: false, sms: true } },
      { category: 'system' as const, channels: { app: true, email: true, sms: false } },
    ],
    emailDigest: 'daily' as const,
    quietHours: { enabled: true, from: '22:00', to: '07:00' },
  };

  it('accepts overnight quiet hours and keeps account notices on', () => {
    expect(validateNotificationSettings(settings)).toEqual([]);
    expect(validateNotificationSettings({ ...settings, quietHours: { enabled: true, from: '22:00', to: '22:00' } }).map((i) => i.field)).toEqual([
      'quietHours',
    ]);
    const off = settings.categories.map((c) => (c.category === 'system' ? { ...c, channels: { ...c.channels, email: false } } : c));
    expect(validateNotificationSettings({ ...settings, categories: off }).map((i) => i.field)).toEqual(['categories']);
  });
});

describe('report periods', () => {
  const now = new Date('2026-09-15T18:52:00+05:30');

  it('compares a range with the same length of time before it', () => {
    const w = reportWindow('90d', now);
    expect(w.to.getTime() - w.from.getTime()).toBe(w.previousTo.getTime() - w.previousFrom.getTime());
    expect(w.previousTo.getTime()).toBe(w.from.getTime());
  });

  it('charts days, weeks or four-week months and marks the newest as partial', () => {
    expect(reportBuckets('30d', now)).toHaveLength(30);
    expect(reportBuckets('90d', now)).toHaveLength(13);
    const year = reportBuckets('12m', now);
    expect(year).toHaveLength(13);
    expect(year.at(-1)?.partial).toBe(true);
    expect(year.at(-1)?.to.getTime()).toBe(now.getTime());
  });

  it('divides safely', () => {
    expect(percentOf(3, 0)).toBeNull();
    expect(percentOf(1, 3)).toBe(33);
    expect(median([5, 1, 3])).toBe(3);
    expect(median([])).toBeNull();
  });
});

describe('LMS settings rules', () => {
  it('checks each section on its own terms', () => {
    const general = {
      academyName: 'ZuviloAI Academy',
      lmsLabel: 'Learning',
      supportEmail: 'help@zuviloai.com',
      language: 'en-IN' as const,
      defaultVisibility: 'public' as const,
      enrollment: 'open' as const,
      accessMonths: 12,
      lessonDefaults: { durationMin: 15, completion: 'time' as const, allowComments: true, allowDownloads: false, previewFirstLesson: true },
    };
    expect(validateSettings('general', general)).toEqual([]);
    expect(validateSettings('general', { ...general, supportEmail: 'help@', lmsLabel: 'L' }).map((i) => i.field)).toEqual(['lmsLabel', 'supportEmail']);
    const learning = {
      completionThreshold: 90,
      courseCompletion: 'percentage' as const,
      completionPercent: 40,
      chapterGate: true,
      quizAttempts: 2,
      retakeWaitHours: 24,
      latePolicy: 'penalty' as const,
      latePenalty: 0,
      atRiskDays: 45,
      learnerPreferences: { playbackSpeed: true, captionsByDefault: false, downloadNotes: true, showRank: true, studyReminders: true },
    };
    expect(validateSettings('learning', learning).map((i) => i.field)).toEqual(['completionPercent', 'latePenalty', 'atRiskDays']);
  });
});
