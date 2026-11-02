import type { Category, Chapter, Course, CoursePricing, Instructor, Lesson, Level } from '@syniastrolms/domain';
import type { Prisma } from '@prisma/client';

import { readJson } from './json.js';

const courseInclude = {
  chapters: { orderBy: { position: 'asc' as const }, include: { lessons: { orderBy: { position: 'asc' as const } } } },
  instructors: { include: { instructor: true } },
} satisfies Prisma.CourseInclude;

export type CourseRow = Prisma.CourseGetPayload<{ include: typeof courseInclude }>;
export const COURSE_INCLUDE = courseInclude;

/** Where a course's cover image streams from (`routes/catalog.ts`). The media id changes when the image is replaced, so the path does too. */
export const coverImagePath = (mediaId: string) => `/catalog/covers/${mediaId}`;

/** The cover image fields every course payload carries; both absent when the course has none. */
export const coverImageOf = (row: { coverImageId: string | null }) =>
  row.coverImageId ? { coverImageId: row.coverImageId, coverImageUrl: coverImagePath(row.coverImageId) } : {};

export function mapLesson(row: Prisma.LessonGetPayload<object>): Lesson {
  return {
    id: row.id,
    title: row.title,
    type: row.type as Lesson['type'],
    durationMin: row.durationMin,
    isPreview: row.isPreview || undefined,
    status: row.status as Lesson['status'],
    updatedAt: row.updatedAt.toISOString(),
    description: row.description ?? undefined,
    objectives: readJson<string[]>(row.objectivesJson, []),
    content: readJson(row.contentJson, {}),
    settings: readJson(row.settingsJson, undefined),
  };
}

export function mapChapter(row: CourseRow['chapters'][number]): Chapter {
  return {
    id: row.id,
    title: row.title,
    summary: row.summary ?? undefined,
    objective: row.objective ?? undefined,
    estimatedMin: row.estimatedMin ?? undefined,
    status: row.status as Chapter['status'],
    lessons: row.lessons.map(mapLesson),
  };
}

export function mapCourse(row: CourseRow): Course {
  return {
    id: row.id,
    slug: row.slug,
    title: row.title,
    subtitle: row.subtitle,
    description: row.description,
    levelId: row.levelId,
    categoryId: row.categoryId,
    instructorIds: row.instructors.map((i) => i.instructorId),
    format: row.format as Course['format'],
    language: row.language,
    coverMotif: row.coverMotif as Course['coverMotif'],
    ...coverImageOf(row),
    chapters: row.chapters.map(mapChapter),
    liveSessions: row.liveSessions,
    estimatedWeeks: row.estimatedWeeks ?? undefined,
    certificateTitle: row.certificateTitle ?? undefined,
    price: row.priceAmount != null ? { amount: row.priceAmount, currency: 'INR' } : undefined,
    pricing: row.pricing as CoursePricing,
    ...(row.salePrice != null ? { salePrice: row.salePrice } : {}),
    enrolledCount: row.enrolledCount,
    status: row.status as Course['status'],
    visibility: row.visibility as Course['visibility'],
    outcomes: readJson<string[]>(row.outcomesJson, []),
    tags: readJson<string[]>(row.tagsJson, []),
    createdAt: row.createdAt.toISOString(),
    updatedAt: row.updatedAt.toISOString(),
    publishedAt: row.publishedAt?.toISOString(),
    rating: row.rating ?? undefined,
    ratingCount: row.ratingCount ?? undefined,
  };
}

/**
 * Removes lesson bodies (video files, article text, documents, quiz/assignment details) from a
 * course a viewer is not entitled to — the public catalog and learners who have not enrolled — while
 * keeping the outline (titles, types, durations) and any published free-preview lessons.
 */
export function withoutLessonContent(course: Course): Course {
  return {
    ...course,
    chapters: course.chapters.map((chapter) => ({
      ...chapter,
      lessons: chapter.lessons.map((lesson) =>
        lesson.isPreview && lesson.status === 'published' ? lesson : { ...lesson, content: {} as Lesson['content'], settings: undefined },
      ),
    })),
  };
}

export function mapInstructor(row: {
  id: string;
  name: string;
  title: string;
  yearsTeaching: number | null;
  email: string;
  bio: string;
  expertiseJson: string;
  status: string;
  joinedAt: Date;
  city: string;
  languagesJson: string;
  phone: string | null;
  photoJson: string | null;
}): Instructor {
  return {
    id: row.id,
    name: row.name,
    title: row.title,
    yearsTeaching: row.yearsTeaching ?? undefined,
    email: row.email,
    bio: row.bio,
    expertise: readJson<string[]>(row.expertiseJson, []),
    status: row.status as Instructor['status'],
    joinedAt: row.joinedAt.toISOString(),
    city: row.city,
    languages: readJson<string[]>(row.languagesJson, []),
    phone: row.phone ?? undefined,
    photo: readJson(row.photoJson, undefined),
  };
}

export function mapLevel(row: { id: string; name: string; order: number; summary: string | null }): Level {
  return { id: row.id, name: row.name, order: row.order, summary: row.summary ?? undefined };
}

export function mapCategory(row: {
  id: string;
  name: string;
  description: string;
  order: number;
  status: string;
  glyph: string;
  updatedAt: Date;
  levels?: { levelId: string }[];
}): Category {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    levelIds: row.levels?.map((l) => l.levelId) ?? [],
    order: row.order,
    status: row.status as Category['status'],
    glyph: row.glyph as Category['glyph'],
    updatedAt: row.updatedAt.toISOString(),
  };
}
