import type { Chapter, Course, CourseAssignment, Lesson, LessonContent, LessonSettings } from '@syniastrolms/domain';
import { defaultCompletion, lessonPublishIssues, slugify } from '@syniastrolms/domain';
import type { LessonAdminService, LessonDetail, LessonRow } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNowIso } from './clock';
import { courses } from './fixtures/catalog';
import { courseAssignments } from './fixtures/assignments';
import { quizzes } from './fixtures/quizzes';
import { academyLiveClasses } from './fixtures/schedule';
import { createRandom, hashSeed } from './random';
import { respond, scenario } from './simulation';

/* ─── Content the catalog doesn't spell out, generated per lesson ──────── */

const ARTICLES: Record<string, string> = {
  'm1-l3': `## Five limbs of time

The Vedic tradition does not measure a day by the clock alone. A panchang — literally "five limbs" — describes each day through tithi, vara, nakshatra, yoga and karana. Each limb is a relationship between the Sun, the Moon and the day of the week.

## Tithi: the lunar day

A tithi is the time the Moon takes to gain twelve degrees on the Sun. Thirty tithis make a lunar month, and because the Moon's speed varies, a tithi can last anywhere from about nineteen to twenty-six hours.

> Learners often confuse the tithi with the calendar date. Keep them separate: the date is civil, the tithi is astronomical.

## Vara and nakshatra

Vara is the weekday, each ruled by a graha — Sunday by Surya, Monday by Chandra, and so on. The nakshatra is the lunar mansion the Moon occupies, one of twenty-seven divisions of 13°20′ each.

In the next lesson you will set up a study practice that uses the day's panchang as a daily prompt.`,
  'm1-l4': `## A practice that lasts

Jyotish rewards steady attention more than long sessions. Twenty minutes a day with one chart will teach you more than a weekend with twenty.

## What to prepare

- A notebook kept only for charts
- Your own birth chart, cast in both North and South Indian formats
- A printed panchang for the current month

## The daily rhythm

1. Note the Moon's nakshatra and tithi each morning.
2. Read one lesson, then find its idea in your own chart.
3. Write two sentences: what you expected, and what you found.

By the end of the course these notes become your first reference book.`,
  'm5-l3': `## Ashwini to Rohini

The first four nakshatras open the zodiac with themes of beginnings, restraint, sharpness and growth.

## Ashwini — the horse-headed healers

Ruled by Ketu and presided over by the Ashvini Kumaras, Ashwini carries swiftness and the power to heal. Planets here act quickly and prefer to begin rather than to finish.

## Bharani — the bearer

Ruled by Venus with Yama as deity, Bharani holds the discipline of limits: birth, death and the responsibility that comes between them.

## Krittika — the cutting flame

Ruled by the Sun and presided over by Agni, Krittika purifies by burning away. Its natives are exacting, and often quietly protective.

## Rohini — the red one

Ruled by the Moon with Brahma as deity, Rohini is fertile, creative and beloved — the Moon's favourite mansion, where it is exalted.`,
};

function articleFor(course: Course, chapter: Chapter, lesson: Lesson) {
  if (ARTICLES[lesson.id]) return ARTICLES[lesson.id];
  return `## ${lesson.title}

This lesson belongs to “${chapter.title}”${chapter.summary ? ` — ${chapter.summary.charAt(0).toLowerCase()}${chapter.summary.slice(1)}` : ''}.

Work through it with your own chart open beside you. Each idea is followed by a short example from a real chart, and a question to answer in your notebook before moving on.

## Why it matters

${course.title} builds one layer at a time. The idea in this lesson is used again in the chapters that follow, so take the time to make it your own before continuing.`;
}

function generatedContent(course: Course, chapter: Chapter, lesson: Lesson): LessonContent {
  const rng = createRandom(hashSeed(lesson.id));
  const draft = lesson.status === 'draft';
  switch (lesson.type) {
    case 'video': {
      const durationSec = lesson.durationMin * 60 - rng.int(5, 55);
      return {
        video: {
          file: draft ? undefined : { name: `${slugify(lesson.title)}.mp4`, sizeMb: Math.round(lesson.durationMin * rng.between(34, 46)) },
          durationSec: draft ? undefined : durationSec,
          captions: !draft && course.id !== 'gochara',
          markers: draft
            ? []
            : [
                { atSec: 0, title: 'Introduction' },
                { atSec: Math.round(durationSec * 0.32), title: 'Worked example' },
                { atSec: Math.round(durationSec * 0.74), title: 'Summary and practice' },
              ],
        },
      };
    }
    case 'reading':
    case 'practice':
      return { article: { body: draft ? '' : articleFor(course, chapter, lesson) } };
    case 'document':
      return {
        document: {
          file: draft ? undefined : { name: `${slugify(lesson.title)}.pdf`, sizeMb: Math.round(rng.between(1.2, 6.8) * 10) / 10 },
          pages: rng.int(6, 24),
          downloadable: true,
        },
      };
    case 'assessment': {
      const quiz = quizzes.find((q) => q.lessonId === lesson.id);
      return {
        quiz: quiz
          ? {
              quizId: quiz.id,
              questions: quiz.questions.length,
              passMark: quiz.settings.passMark,
              attempts: quiz.settings.attempts,
              timeLimitMin: quiz.settings.timeLimitMin,
            }
          : { questions: rng.int(10, 25), passMark: 70, attempts: 2, timeLimitMin: lesson.durationMin },
      };
    }
    case 'assignment': {
      const linked = courseAssignments.find((a) => a.lessonId === lesson.id);
      if (linked) return { assignment: assignmentMirror(linked) };
      return {
        assignment: {
          brief: `Apply “${chapter.title}” to one real chart. Show your working, then write a paragraph explaining what you found and why.`,
          dueAfterDays: 7,
          maxScore: 20,
          submission: 'file',
        },
      };
    }
    case 'live': {
      const match = academyLiveClasses.find(
        (c) => c.courseId === course.id && lesson.title.toLowerCase().includes(c.title.toLowerCase().split(':')[0].slice(0, 12)),
      );
      return { live: { startsAt: match?.startsAt ?? '2026-09-24T19:00:00+05:30', durationMin: lesson.durationMin, recorded: true, liveClassId: match?.id } };
    }
  }
}

const defaultSettings = (lesson: Lesson): LessonSettings => ({
  completion: defaultCompletion[lesson.type],
  sequential: false,
  discussion: true,
  resourcesDownloadable: lesson.type === 'document',
});

function assignmentMirror(a: CourseAssignment): NonNullable<LessonContent['assignment']> {
  const firstParagraph = a.instructions.split(/\n{2,}/).find((p) => !p.startsWith('#')) ?? '';
  return {
    assignmentId: a.id,
    brief: firstParagraph.replace(/\*\*/g, ''),
    dueAfterDays: a.due.kind === 'relative' ? a.due.days : 7,
    maxScore: a.maxScore,
    submission: a.format,
  };
}

/** Reads the linked quiz and assignment again, so edits made in their own editors show on the lesson. */
function withLiveQuiz(content: LessonContent): LessonContent {
  const quiz = content.quiz?.quizId ? quizzes.find((q) => q.id === content.quiz?.quizId) : undefined;
  const assignment = content.assignment?.assignmentId ? courseAssignments.find((a) => a.id === content.assignment?.assignmentId) : undefined;
  return {
    ...content,
    ...(quiz && {
      quiz: {
        quizId: quiz.id,
        questions: quiz.questions.length,
        passMark: quiz.settings.passMark,
        attempts: quiz.settings.attempts,
        timeLimitMin: quiz.settings.timeLimitMin,
      },
    }),
    ...(assignment && { assignment: assignmentMirror(assignment) }),
  };
}

/** A lesson with its content and settings filled in. */
export const complete = (course: Course, chapter: Chapter, lesson: Lesson): Lesson => ({
  ...lesson,
  content: withLiveQuiz(lesson.content ?? generatedContent(course, chapter, lesson)),
  settings: lesson.settings ?? defaultSettings(lesson),
});

/* ─── Store helpers ─────────────────────────────────────────────────────── */

function findCourse(courseId: string) {
  const course = courses.find((c) => c.id === courseId);
  if (!course) throw new ServiceError('This course doesn’t exist.', 'not-found');
  return course;
}

function locate(course: Course, lessonId: string) {
  for (let ci = 0; ci < course.chapters.length; ci++) {
    const li = course.chapters[ci].lessons.findIndex((l) => l.id === lessonId);
    if (li >= 0) return { chapter: course.chapters[ci], chapterIndex: ci, lessonIndex: li, lesson: course.chapters[ci].lessons[li] };
  }
  throw new ServiceError('This lesson no longer exists. It may have been deleted.', 'not-found');
}

function saveCourse(course: Course, chapters: Chapter[]) {
  courses[courses.findIndex((c) => c.id === course.id)] = { ...course, chapters, updatedAt: mockNowIso() };
  invalidateAnalytics();
}

function detail(courseId: string, lessonId: string): LessonDetail {
  const course = findCourse(courseId);
  const found = locate(course, lessonId);
  const flat = course.chapters.flatMap((c) => c.lessons);
  const at = flat.findIndex((l) => l.id === lessonId);
  return {
    lesson: complete(course, found.chapter, found.lesson),
    chapter: found.chapter,
    chapterId: found.chapter.id,
    chapterTitle: found.chapter.title,
    chapterIndex: found.chapterIndex,
    lessonIndex: found.lessonIndex,
    previous: flat[at - 1] ? { id: flat[at - 1].id, title: flat[at - 1].title } : undefined,
    next: flat[at + 1] ? { id: flat[at + 1].id, title: flat[at + 1].title } : undefined,
  };
}

function assertPublishable(lesson: Lesson) {
  if (lesson.status !== 'published') return;
  const issues = lessonPublishIssues(lesson);
  if (issues.length) throw new ServiceError(issues.map((i) => i.message).join(' '), 'conflict');
}

let serial = 0;

export const lessonAdminService: LessonAdminService = {
  list: (courseId, { search = '', chapterId, type = 'all', status = 'all', sort = 'position' }) =>
    respond(() => {
      const course = findCourse(courseId);
      if (scenario() === 'empty') return { rows: [], counts: { all: 0, published: 0, draft: 0, byType: {} } };
      const q = search.trim().toLowerCase();
      const all: LessonRow[] = course.chapters.flatMap((chapter, chapterIndex) =>
        chapter.lessons.map((lesson, lessonIndex) => ({ lesson, chapterId: chapter.id, chapterTitle: chapter.title, chapterIndex, lessonIndex })),
      );
      const scoped = all.filter((r) => (!chapterId || r.chapterId === chapterId) && (!q || r.lesson.title.toLowerCase().includes(q)));
      const byType: Partial<Record<Lesson['type'], number>> = {};
      for (const r of scoped) byType[r.lesson.type] = (byType[r.lesson.type] ?? 0) + 1;
      const rows = scoped
        .filter((r) => (type === 'all' || r.lesson.type === type) && (status === 'all' || r.lesson.status === status))
        .sort((a, b) =>
          sort === 'updated'
            ? b.lesson.updatedAt.localeCompare(a.lesson.updatedAt)
            : sort === 'duration'
              ? b.lesson.durationMin - a.lesson.durationMin
              : sort === 'title'
                ? a.lesson.title.localeCompare(b.lesson.title)
                : 0,
        );
      return {
        rows,
        counts: {
          all: scoped.length,
          published: scoped.filter((r) => r.lesson.status === 'published').length,
          draft: scoped.filter((r) => r.lesson.status === 'draft').length,
          byType,
        },
      };
    }, 420),

  get: (courseId, lessonId) => respond(() => detail(courseId, lessonId), 480),

  create: (courseId, chapterId, input, position) =>
    respond(() => {
      const course = findCourse(courseId);
      const chapter = course.chapters.find((c) => c.id === chapterId);
      if (!chapter) throw new ServiceError('Choose a chapter for the lesson.', 'conflict');
      if (input.title.trim().length < 3) throw new ServiceError('Give the lesson a title of at least 3 characters.', 'conflict');
      const lesson: Lesson = { ...input, id: `${chapterId}-l${Date.now().toString(36)}${serial++}`, title: input.title.trim(), updatedAt: mockNowIso() };
      assertPublishable(lesson);
      const lessons = [...chapter.lessons];
      lessons.splice(position ? Math.max(0, Math.min(lessons.length, position - 1)) : lessons.length, 0, lesson);
      saveCourse(
        course,
        course.chapters.map((c) => (c.id === chapterId ? { ...c, lessons } : c)),
      );
      return lesson;
    }, 900),

  update: (courseId, lessonId, input) =>
    respond(() => {
      const course = findCourse(courseId);
      const found = locate(course, lessonId);
      const next: Lesson = { ...complete(course, found.chapter, found.lesson), ...input, updatedAt: mockNowIso() };
      if (input.title !== undefined) next.title = input.title.trim();
      assertPublishable(next);
      saveCourse(
        course,
        course.chapters.map((c) => (c.id === found.chapter.id ? { ...c, lessons: c.lessons.map((l) => (l.id === lessonId ? next : l)) } : c)),
      );
      return next;
    }, 850),

  move: (courseId, lessonId, chapterId, position) =>
    respond(() => {
      const course = findCourse(courseId);
      const found = locate(course, lessonId);
      if (!course.chapters.some((c) => c.id === chapterId)) throw new ServiceError('That chapter no longer exists.', 'not-found');
      const without = course.chapters.map((c) => (c.id === found.chapter.id ? { ...c, lessons: c.lessons.filter((l) => l.id !== lessonId) } : c));
      const chapters = without.map((c) => {
        if (c.id !== chapterId) return c;
        const lessons = [...c.lessons];
        lessons.splice(Math.max(0, Math.min(lessons.length, position - 1)), 0, found.lesson);
        return { ...c, lessons };
      });
      saveCourse(course, chapters);
      return detail(courseId, lessonId);
    }, 700),

  duplicate: (courseId, lessonId) =>
    respond(() => {
      const course = findCourse(courseId);
      const found = locate(course, lessonId);
      const copy: Lesson = {
        ...complete(course, found.chapter, found.lesson),
        id: `${found.chapter.id}-l${Date.now().toString(36)}${serial++}`,
        title: `Copy of ${found.lesson.title}`,
        status: 'draft',
        isPreview: false,
        updatedAt: mockNowIso(),
      };
      saveCourse(
        course,
        course.chapters.map((c) => {
          if (c.id !== found.chapter.id) return c;
          const lessons = [...c.lessons];
          lessons.splice(found.lessonIndex + 1, 0, copy);
          return { ...c, lessons };
        }),
      );
      return copy;
    }, 800),

  remove: (courseId, lessonId) =>
    respond(() => {
      const course = findCourse(courseId);
      const found = locate(course, lessonId);
      saveCourse(
        course,
        course.chapters.map((c) => (c.id === found.chapter.id ? { ...c, lessons: c.lessons.filter((l) => l.id !== lessonId) } : c)),
      );
    }, 800),
};
