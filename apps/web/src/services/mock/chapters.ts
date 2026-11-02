import type { Chapter, ChapterInput, Course } from '@syniastrolms/domain';
import { courseDurationMin } from '@syniastrolms/domain';
import type { ChapterAdminService, CurriculumStats } from '../contracts';
import { ServiceError } from '../contracts';
import { invalidateAnalytics } from './analytics';
import { mockNowIso } from './clock';
import { courses } from './fixtures/catalog';
import { enrollments } from './fixtures/people';
import { respond } from './simulation';

function findCourse(courseId: string) {
  const course = courses.find((c) => c.id === courseId);
  if (!course) throw new ServiceError('This course doesn’t exist.', 'not-found');
  return course;
}

function findChapter(course: Course, chapterId: string) {
  const chapter = course.chapters.find((c) => c.id === chapterId);
  if (!chapter) throw new ServiceError('This chapter no longer exists. It may have been deleted.', 'not-found');
  return chapter;
}

function saveCourse(next: Course) {
  courses[courses.findIndex((c) => c.id === next.id)] = next;
  invalidateAnalytics();
}

let serial = 0;
const newId = (prefix: string) => `${prefix}-${Date.now().toString(36)}${(serial++).toString(36)}`;

function validate(input: Partial<ChapterInput>) {
  if (input.title !== undefined && input.title.trim().length < 3) throw new ServiceError('A chapter title needs at least 3 characters.', 'conflict');
}

/**
 * Chapter and lesson completion come from each learner's course progress: a learner at 40% has
 * finished every chapter whose lessons end within the first 40% of the course's minutes.
 */
function curriculumStats(course: Course): CurriculumStats {
  const list = enrollments.filter((e) => e.courseId === course.id);
  const total = courseDurationMin(course) || 1;
  const chapters: CurriculumStats['chapters'] = {};
  const lessons: CurriculumStats['lessons'] = {};
  const share = (threshold: number) => (list.length ? Math.round((list.filter((e) => e.progress >= threshold).length / list.length) * 100) : 0);
  let elapsed = 0;
  for (const chapter of course.chapters) {
    const start = (elapsed / total) * 100;
    for (const lesson of chapter.lessons) {
      elapsed += lesson.durationMin;
      lessons[lesson.id] = chapter.status === 'published' ? share(Math.min(100, (elapsed / total) * 100)) : 0;
    }
    const end = (elapsed / total) * 100;
    chapters[chapter.id] =
      chapter.status === 'published' && chapter.lessons.length
        ? { completionRate: share(Math.min(100, end)), startedRate: share(Math.min(99.5, start + 0.5)) }
        : { completionRate: 0, startedRate: 0 };
  }
  return { courseId: course.id, enrolled: list.length, chapters, lessons };
}

export const chapterAdminService: ChapterAdminService = {
  stats: (courseId) => respond(() => curriculumStats(findCourse(courseId)), 450),

  create: (courseId, input, position) =>
    respond(() => {
      validate(input);
      const course = findCourse(courseId);
      const chapter: Chapter = {
        id: newId(`${courseId}-c`),
        title: input.title.trim(),
        summary: input.summary?.trim() || undefined,
        objective: input.objective?.trim() || undefined,
        estimatedMin: input.estimatedMin,
        status: input.status,
        lessons: [],
      };
      const chapters = [...course.chapters];
      chapters.splice(position ? Math.max(0, Math.min(chapters.length, position - 1)) : chapters.length, 0, chapter);
      saveCourse({ ...course, chapters, updatedAt: mockNowIso() });
      return chapter;
    }, 800),

  update: (courseId, chapterId, input) =>
    respond(() => {
      validate(input);
      const course = findCourse(courseId);
      const current = findChapter(course, chapterId);
      const next: Chapter = {
        ...current,
        ...input,
        title: (input.title ?? current.title).trim(),
        summary: input.summary !== undefined ? input.summary.trim() || undefined : current.summary,
        objective: input.objective !== undefined ? input.objective.trim() || undefined : current.objective,
      };
      saveCourse({ ...course, chapters: course.chapters.map((c) => (c.id === chapterId ? next : c)), updatedAt: mockNowIso() });
      return next;
    }, 700),

  duplicate: (courseId, chapterId) =>
    respond(() => {
      const course = findCourse(courseId);
      const source = findChapter(course, chapterId);
      const id = newId(`${courseId}-c`);
      const now = mockNowIso();
      const copy: Chapter = {
        ...source,
        id,
        title: `Copy of ${source.title}`,
        status: 'draft',
        lessons: source.lessons.map((l, i) => ({ ...l, id: `${id}-l${i + 1}`, status: 'draft', isPreview: false, updatedAt: now })),
      };
      const chapters = [...course.chapters];
      chapters.splice(chapters.indexOf(source) + 1, 0, copy);
      saveCourse({ ...course, chapters, updatedAt: now });
      return copy;
    }, 900),

  remove: (courseId, chapterId) =>
    respond(() => {
      const course = findCourse(courseId);
      const chapter = findChapter(course, chapterId);
      if (course.status === 'published' && chapter.status === 'published' && course.chapters.filter((c) => c.status === 'published').length === 1) {
        throw new ServiceError(
          'A published course needs at least one published chapter. Move the course to drafts first, or publish another chapter.',
          'conflict',
        );
      }
      saveCourse({ ...course, chapters: course.chapters.filter((c) => c.id !== chapterId), updatedAt: mockNowIso() });
      return { lessonsRemoved: chapter.lessons.length };
    }, 900),

  move: (courseId, chapterId, position) =>
    respond(() => {
      const course = findCourse(courseId);
      const chapter = findChapter(course, chapterId);
      const chapters = course.chapters.filter((c) => c.id !== chapterId);
      chapters.splice(Math.max(0, Math.min(chapters.length, position - 1)), 0, chapter);
      saveCourse({ ...course, chapters, updatedAt: mockNowIso() });
      return chapters;
    }, 650),
};
