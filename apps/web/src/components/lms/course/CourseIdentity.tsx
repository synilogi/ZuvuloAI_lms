import type { ReactNode } from 'react';
import { Article, Certificate, ClipboardText, Clock, Exam, FilePdf, PencilLine, PlayCircle, Translate, UsersThree, VideoCamera } from '@phosphor-icons/react';
import type { Category, Course, Instructor, LessonType, Level } from '@syniastrolms/domain';
import { courseDurationMin, courseLessons, levelPosition } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatCount, formatDuration } from '@/lib/format';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { CourseCover } from './CourseCover';
import styles from './Course.module.css';

/* ─── Lesson type icons ────────────────────────────────────────────────── */

export const lessonTypeMeta: Record<LessonType, { label: string; icon: ReactNode }> = {
  video: { label: 'Video', icon: <PlayCircle size={17} /> },
  reading: { label: 'Article', icon: <Article size={17} /> },
  document: { label: 'PDF', icon: <FilePdf size={17} /> },
  live: { label: 'Live session', icon: <VideoCamera size={17} /> },
  practice: { label: 'Practice', icon: <PencilLine size={17} /> },
  assignment: { label: 'Assignment', icon: <ClipboardText size={17} /> },
  assessment: { label: 'Quiz', icon: <Exam size={17} /> },
};

const TYPE_NOUNS: Record<LessonType, [string, string]> = {
  video: ['video', 'videos'],
  reading: ['article', 'articles'],
  document: ['PDF', 'PDFs'],
  live: ['live session', 'live sessions'],
  practice: ['practice exercise', 'practice exercises'],
  assignment: ['assignment', 'assignments'],
  assessment: ['quiz', 'quizzes'],
};

/** "3 videos", "1 quiz" — lesson types in running text. */
export const lessonTypeCount = (type: LessonType, count: number) => `${count} ${TYPE_NOUNS[type][count === 1 ? 0 : 1]}`;

/* ─── Level ────────────────────────────────────────────────────────────── */

/** Position within the level progression. Tick count follows the data, not a fixed four. */
export function CourseLevel({ levelId, levels, showLabel = true }: { levelId: string; levels: Level[]; showLabel?: boolean }) {
  const { index, total } = levelPosition(levels, levelId);
  const level = levels.find((l) => l.id === levelId);
  return (
    <span className={styles.level} aria-label={`${level?.name ?? 'Level'} — level ${index + 1} of ${total}`} role="img">
      <span className={styles.levelTicks} aria-hidden="true">
        {Array.from({ length: total }, (_, i) => (
          <span key={i} className={cx(styles.levelTick, i <= index && styles.levelTickOn)} style={{ height: 5 + i * 3 }} />
        ))}
      </span>
      {showLabel && <span className={styles.levelLabel}>{level?.name}</span>}
    </span>
  );
}

/* ─── Meta ─────────────────────────────────────────────────────────────── */

export interface MetaItem {
  id: string;
  icon: ReactNode;
  label: string;
  value: string;
}

export function courseMetaItems(course: Course): MetaItem[] {
  const lessons = courseLessons(course);
  const items: MetaItem[] = [
    { id: 'duration', icon: <Clock size={16} />, label: 'Duration', value: formatDuration(courseDurationMin(course)) },
    { id: 'lessons', icon: <PlayCircle size={16} />, label: 'Lessons', value: `${lessons.length} lessons · ${course.chapters.length} chapters` },
    { id: 'live', icon: <VideoCamera size={16} />, label: 'Live classes', value: `${course.liveSessions} live sessions` },
    { id: 'language', icon: <Translate size={16} />, label: 'Language', value: course.language },
    { id: 'enrolled', icon: <UsersThree size={16} />, label: 'Learners', value: `${formatCount(course.enrolledCount)} enrolled` },
  ];
  if (course.certificateTitle) items.push({ id: 'certificate', icon: <Certificate size={16} />, label: 'Certificate', value: 'Certificate on completion' });
  return items;
}

/** Inline reads as a sentence of facts; "list" is a label/value ledger for side panels. */
export function CourseMeta({ items, variant = 'inline', className }: { items: MetaItem[]; variant?: 'inline' | 'list'; className?: string }) {
  if (variant === 'list') {
    return (
      <dl className={cx(styles.metaList, className)}>
        {items.map((item) => (
          <div key={item.id} className={styles.metaListRow}>
            <dt>
              {item.icon}
              {item.label}
            </dt>
            <dd>{item.value}</dd>
          </div>
        ))}
      </dl>
    );
  }
  return (
    <ul className={cx(styles.metaInline, className)}>
      {items.map((item) => (
        <li key={item.id}>
          {item.icon}
          <span className="sr-only">{item.label}: </span>
          {item.value}
        </li>
      ))}
    </ul>
  );
}

/* ─── Instructor ───────────────────────────────────────────────────────── */

export function CourseInstructor({ instructors, size = 'md' }: { instructors: Instructor[]; size?: 'sm' | 'md' }) {
  const [lead, ...rest] = instructors;
  if (!lead) return null;
  return (
    <div className={cx(styles.instructor, size === 'sm' && styles.instructorSm)}>
      <span className={styles.instructorAvatars}>
        {instructors.slice(0, 2).map((i) => (
          <Avatar key={i.id} name={i.name} size={size === 'sm' ? 26 : 36} className={styles.instructorAvatar} />
        ))}
      </span>
      <span className={styles.instructorText}>
        <span className={styles.instructorName}>
          {lead.name}
          {rest.length > 0 && <span className={styles.instructorMore}> and {rest.length === 1 ? rest[0].name : `${rest.length} others`}</span>}
        </span>
        {size === 'md' && (
          <span className={styles.instructorTitle}>
            {lead.title}
            {lead.yearsTeaching ? ` · ${lead.yearsTeaching} years teaching` : ''}
          </span>
        )}
      </span>
    </div>
  );
}

/* ─── Identity ─────────────────────────────────────────────────────────── */

interface CourseIdentityProps {
  course: Course;
  level?: Level;
  levels: Level[];
  category?: Category;
  instructors: Instructor[];
  variant?: 'hero' | 'row' | 'compact';
  /** Extra line under the title in row variant — progress, status, next session. */
  aside?: ReactNode;
  headingLevel?: 'h1' | 'h2' | 'h3';
  /** Hero only — hide the cover when the identity shares a row with an action panel. */
  showCover?: boolean;
}

/**
 * Who, what and at what level — the course's name tag. The hero variant is editorial:
 * typography carries the weight and the cover sits beside it rather than behind it.
 */
export function CourseIdentity({ course, levels, category, instructors, variant = 'hero', aside, headingLevel = 'h1', showCover = true }: CourseIdentityProps) {
  const Heading = headingLevel;

  if (variant === 'row' || variant === 'compact') {
    return (
      <div className={cx(styles.identityRow, variant === 'compact' && styles.identityCompact)}>
        {variant === 'row' && <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.rowCover} />}
        <div className={styles.rowText}>
          <span className={styles.rowEyebrow}>
            <CourseLevel levelId={course.levelId} levels={levels} />
            {category && <span className={styles.rowCategory}>{category.name}</span>}
          </span>
          <Heading className={styles.rowTitle}>{course.title}</Heading>
          {variant === 'row' && (aside ?? <CourseInstructor instructors={instructors} size="sm" />)}
        </div>
      </div>
    );
  }

  return (
    <header className={styles.hero}>
      <div className={cx(styles.heroGrid, !showCover && styles.heroNoCover)}>
        <div className={styles.heroText}>
          <span className={styles.heroEyebrow}>
            {category && <span className="type-eyebrow">{category.name}</span>}
            <CourseLevel levelId={course.levelId} levels={levels} />
          </span>
          <Heading className={styles.heroTitle}>{course.title}</Heading>
          <p className={styles.heroSubtitle}>{course.subtitle}</p>
          <CourseInstructor instructors={instructors} />
          <CourseMeta items={courseMetaItems(course).slice(0, 4)} className={styles.heroMeta} />
        </div>
        {showCover && <CourseCover motif={course.coverMotif} imageUrl={course.coverImageUrl} className={styles.heroCover} />}
      </div>
    </header>
  );
}
