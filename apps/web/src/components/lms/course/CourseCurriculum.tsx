import { useId, useState } from 'react';
import { CaretDown, Eye, LockSimple, Play } from '@phosphor-icons/react';
import type { Course, Chapter, CourseProgressSnapshot, Lesson, ProgressState } from '@syniastrolms/domain';
import { lessonState, chapterDurationMin, chapterProgress } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatDuration, pad2 } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';
import { ProgressRing } from '../progress/ProgressRing';
import { StatusNode } from '../status/Status';
import { lessonTypeMeta } from './CourseIdentity';
import styles from './Curriculum.module.css';

/* ─── Lesson row ───────────────────────────────────────────────────────── */

interface LessonRowProps {
  lesson: Lesson;
  index: number;
  state: ProgressState;
  fraction?: number;
  current?: boolean;
  enrolled?: boolean;
  /** Plays the completion settle on the status node. */
  justCompleted?: boolean;
  onSelect?: (lesson: Lesson) => void;
}

const STATE_LABEL: Record<ProgressState, string> = {
  completed: 'Completed',
  'in-progress': 'In progress',
  'not-started': 'Not started',
  locked: 'Locked',
};

export function LessonStatus({ state, fraction, size = 18, settle }: { state: ProgressState; fraction?: number; size?: number; settle?: boolean }) {
  return (
    <StatusNode
      size={size}
      shape={state === 'completed' ? 'filled' : state === 'in-progress' ? 'partial' : state === 'locked' ? 'dashed' : 'ring'}
      tone={state === 'completed' || state === 'in-progress' ? 'accent' : 'neutral'}
      fraction={fraction}
      settle={settle}
    />
  );
}

export function LessonDuration({ minutes, fraction }: { minutes: number; fraction?: number }) {
  if (fraction !== undefined && fraction > 0 && fraction < 1) {
    return <span className={styles.duration}>{Math.ceil(minutes * (1 - fraction))} min left</span>;
  }
  return <span className={styles.duration}>{formatDuration(minutes)}</span>;
}

export function LessonRow({ lesson, index, state, fraction, current, enrolled = true, justCompleted, onSelect }: LessonRowProps) {
  const type = lessonTypeMeta[lesson.type];
  const accessible = enrolled ? state !== 'locked' : !!lesson.isPreview;
  const content = (
    <>
      <LessonStatus state={enrolled ? state : lesson.isPreview ? 'not-started' : 'locked'} fraction={fraction} settle={justCompleted} />
      <span className={styles.lessonIndex}>{pad2(index)}</span>
      <span className={styles.lessonType} title={type.label}>
        {type.icon}
      </span>
      <span className={styles.lessonTitle}>
        {lesson.title}
        <span className="sr-only">
          {' '}
          — {type.label}, {STATE_LABEL[state]}
        </span>
      </span>
      <span className={styles.lessonEnd}>
        {!enrolled && lesson.isPreview && (
          <Badge tone="info" size="sm" icon={<Eye size={11} />}>
            Preview
          </Badge>
        )}
        {current && (
          <span className={styles.resume}>
            <Play size={11} weight="fill" /> Resume
          </span>
        )}
        {!accessible && <LockSimple size={14} className={styles.lock} aria-label="Locked" />}
        <LessonDuration minutes={lesson.durationMin} fraction={current ? fraction : undefined} />
      </span>
    </>
  );

  const className = cx(styles.lesson, styles[state], current && styles.current, !accessible && styles.inaccessible);
  return (
    <li>
      {accessible && onSelect ? (
        <button type="button" className={className} onClick={() => onSelect(lesson)} aria-current={current ? 'step' : undefined}>
          {content}
        </button>
      ) : (
        <div className={className} aria-disabled={!accessible || undefined}>
          {content}
        </div>
      )}
    </li>
  );
}

/* ─── Module ───────────────────────────────────────────────────────────── */

interface ChapterSectionProps {
  chapter: Chapter;
  index: number;
  snapshot?: CourseProgressSnapshot;
  currentLessonId?: string;
  enrolled: boolean;
  open: boolean;
  onToggle: () => void;
  onSelectLesson?: (lesson: Lesson) => void;
  lessonOffset: number;
  lockedReason?: string;
}

function ChapterSection({
  chapter,
  index,
  snapshot,
  currentLessonId,
  enrolled,
  open,
  onToggle,
  onSelectLesson,
  lessonOffset,
  lockedReason,
}: ChapterSectionProps) {
  const id = useId();
  const summary = chapterProgress(chapter, snapshot);
  const isCurrent = chapter.lessons.some((l) => l.id === currentLessonId);
  const locked = enrolled && summary.state === 'locked';

  return (
    <li className={cx(styles.chapter, open && styles.open, isCurrent && styles.chapterCurrent, locked && styles.chapterLocked)}>
      <h3 className={styles.chapterHeading}>
        <button type="button" className={styles.chapterButton} aria-expanded={open} aria-controls={`${id}-lessons`} onClick={onToggle}>
          <span className={styles.chapterIndex}>{pad2(index + 1)}</span>
          <span className={styles.chapterText}>
            <span className={styles.chapterTitle}>{chapter.title}</span>
            <span className={styles.chapterMeta}>
              {chapter.lessons.length} lessons · {formatDuration(chapterDurationMin(chapter))}
              {locked && lockedReason && (
                <span className={styles.chapterLockedReason}>
                  <LockSimple size={12} /> {lockedReason}
                </span>
              )}
            </span>
          </span>
          {enrolled && !locked && (
            <span className={styles.chapterProgress}>
              {summary.state === 'completed' ? (
                <span className={styles.chapterDone}>Completed</span>
              ) : summary.state === 'in-progress' ? (
                <span className={styles.chapterCount}>
                  {summary.completed}/{summary.total}
                </span>
              ) : null}
              <ProgressRing value={summary.percent} size="xs" label={`${chapter.title} progress`} />
            </span>
          )}
          <CaretDown size={14} className={styles.caret} />
        </button>
      </h3>
      <div id={`${id}-lessons`} className={styles.lessonsWrap}>
        <ol className={styles.lessons}>
          {chapter.lessons.map((lesson, i) => (
            <LessonRow
              key={lesson.id}
              lesson={lesson}
              index={lessonOffset + i + 1}
              state={lessonState(lesson.id, snapshot)}
              fraction={snapshot?.lessons[lesson.id]?.fraction}
              current={lesson.id === currentLessonId}
              enrolled={enrolled}
              onSelect={onSelectLesson}
            />
          ))}
        </ol>
      </div>
    </li>
  );
}

/* ─── Curriculum ───────────────────────────────────────────────────────── */

interface CourseCurriculumProps {
  course: Course;
  snapshot?: CourseProgressSnapshot;
  enrolled?: boolean;
  currentLessonId?: string;
  onSelectLesson?: (lesson: Lesson) => void;
  /** Modules open on first render. Defaults to the module holding the current lesson. */
  defaultOpen?: string[];
}

/**
 * Expandable curriculum. Density comes from the surrounding data-density, so the same
 * component serves a lesson side panel (immersive), a course page (balanced) and an
 * instructor outline (dense).
 */
export function CourseCurriculum({ course, snapshot, enrolled = true, currentLessonId, onSelectLesson, defaultOpen }: CourseCurriculumProps) {
  const currentChapter = course.chapters.find((m) => m.lessons.some((l) => l.id === currentLessonId));
  const [openIds, setOpenIds] = useState<Set<string>>(() => new Set(defaultOpen ?? (currentChapter ? [currentChapter.id] : [course.chapters[0]?.id])));
  const allOpen = openIds.size === course.chapters.length;

  const toggle = (id: string) =>
    setOpenIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  let offset = 0;
  const total = course.chapters.reduce((n, m) => n + m.lessons.length, 0);

  return (
    <section className={styles.root} aria-label="Curriculum">
      <div className={styles.toolbar}>
        <span className={styles.toolbarSummary}>
          {course.chapters.length} chapters · {total} lessons
        </span>
        <button type="button" className={styles.toggleAll} onClick={() => setOpenIds(allOpen ? new Set() : new Set(course.chapters.map((m) => m.id)))}>
          {allOpen ? 'Collapse all' : 'Expand all'}
        </button>
      </div>
      <ol className={styles.chapters}>
        {course.chapters.map((chapter, i) => {
          const lessonOffset = offset;
          offset += chapter.lessons.length;
          return (
            <ChapterSection
              key={chapter.id}
              chapter={chapter}
              index={i}
              snapshot={snapshot}
              currentLessonId={currentLessonId}
              enrolled={enrolled}
              open={openIds.has(chapter.id)}
              onToggle={() => toggle(chapter.id)}
              onSelectLesson={onSelectLesson}
              lessonOffset={lessonOffset}
              lockedReason={i > 0 ? `Unlocks after ${course.chapters[i - 1].title}` : undefined}
            />
          );
        })}
      </ol>
    </section>
  );
}
