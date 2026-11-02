import { useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, ArrowRight, ArrowsDownUp, Copy, DotsThree, Eye, PencilSimple, Target, Trash } from '@phosphor-icons/react';
import { chapterDisplayMin, type LessonType } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatCount, formatDuration, pad2, plural } from '@/lib/format';
import { Figure } from '@/components/data/KpiStrip';
import { SectionHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { lessonTypeCount, lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { Meter } from '@/components/lms/progress/Meters';
import { services } from '@/services';
import { useCourseWorkspace } from '../CourseLayout';
import { ChapterForm, DeleteChapterDialog, MoveChapterDialog } from './ChapterPanels';
import styles from './Chapters.module.css';

/** One chapter in depth: its purpose, its lessons, and where learners stop. */
export default function ChapterOverviewPage() {
  const { chapterId } = useParams();
  const { course, base, refresh } = useCourseWorkspace();
  const navigate = useNavigate();
  const toast = useToast();
  const [editing, setEditing] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [moving, setMoving] = useState(false);
  const stats = useAsync(`curriculum-stats:${course.id}:${course.updatedAt}`, () => services.chapters.stats(course.id));

  const index = course.chapters.findIndex((c) => c.id === chapterId);
  const chapter = course.chapters[index];
  const to = `${base}/courses/${course.id}`;

  if (!chapter) {
    return (
      <StateMessage
        kind="error"
        title="Chapter not found"
        actions={
          <LinkButton to={`${to}/curriculum`} iconStart={<ArrowLeft size={16} />}>
            Back to curriculum
          </LinkButton>
        }
      >
        It may have been deleted or moved to another course.
      </StateMessage>
    );
  }

  const prev = course.chapters[index - 1];
  const next = course.chapters[index + 1];
  const chapterStats = stats.data?.chapters[chapter.id];
  const live = chapter.status === 'published' && (stats.data?.enrolled ?? 0) > 0 && chapter.lessons.length > 0;
  const typeCounts = chapter.lessons.reduce<Record<string, number>>((acc, l) => ({ ...acc, [l.type]: (acc[l.type] ?? 0) + 1 }), {});

  const duplicate = async () => {
    try {
      const copy = await services.chapters.duplicate(course.id, chapter.id);
      toast({
        kind: 'success',
        title: 'Chapter duplicated',
        text: `“${copy.title}” was added as a draft after this chapter.`,
        action: { label: 'Open copy', onClick: () => navigate(`${to}/chapters/${copy.id}`) },
      });
      refresh();
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t duplicate the chapter', text: (e as Error).message });
    }
  };

  return (
    <article className={styles.overview} aria-labelledby="chapter-heading">
      <header className={styles.header}>
        <Link to={`${to}/curriculum`} className={styles.back}>
          <ArrowLeft size={14} aria-hidden="true" /> Curriculum
        </Link>
        <div className={styles.headerRow}>
          <span className={styles.bigIndex} aria-hidden="true">
            {pad2(index + 1)}
          </span>
          <div className={styles.headerText}>
            <span className={styles.eyebrow}>
              Chapter {index + 1} of {course.chapters.length}
            </span>
            <h2 id="chapter-heading" className={styles.title}>
              {chapter.title}
            </h2>
            {chapter.summary && <p className={styles.summary}>{chapter.summary}</p>}
            <div className={styles.meta}>
              {chapter.status === 'draft' ? (
                <Badge tone="warn">Draft · hidden from learners</Badge>
              ) : (
                <Badge tone="accent" dot>
                  Published
                </Badge>
              )}
              <span>
                {plural(chapter.lessons.length, 'lesson')} · {chapter.lessons.length ? '' : 'about '}
                {formatDuration(chapterDisplayMin(chapter))}
              </span>
            </div>
          </div>
          <div className={styles.actions}>
            <Button iconStart={<PencilSimple size={16} />} onClick={() => setEditing(true)}>
              Edit chapter
            </Button>
            <Menu
              align="end"
              width={210}
              trigger={(props) => <IconButton {...props} boxed label="More chapter actions" icon={<DotsThree size={18} weight="bold" />} />}
              sections={[
                {
                  items: [
                    { id: 'duplicate', label: 'Duplicate', icon: <Copy size={17} />, onSelect: duplicate },
                    {
                      id: 'move',
                      label: 'Move to position…',
                      icon: <ArrowsDownUp size={17} />,
                      disabled: course.chapters.length < 2,
                      onSelect: () => setMoving(true),
                    },
                    { id: 'preview', label: 'Preview course', icon: <Eye size={17} />, onSelect: () => navigate(`${to}/preview`) },
                  ],
                },
                { items: [{ id: 'delete', label: 'Delete…', icon: <Trash size={17} />, tone: 'danger', onSelect: () => setDeleting(true) }] },
              ]}
            />
          </div>
        </div>
      </header>

      {chapter.objective ? (
        <blockquote className={styles.objective}>
          <Target size={20} aria-hidden="true" />
          <span>
            <span className={styles.objectiveLabel}>By the end of this chapter, learners can</span>
            {chapter.objective.charAt(0).toLowerCase() + chapter.objective.slice(1)}
          </span>
        </blockquote>
      ) : (
        <p className={styles.missing}>
          No learning objective yet.{' '}
          <button type="button" className={styles.inlineLink} onClick={() => setEditing(true)}>
            Add one
          </button>{' '}
          so learners know what the chapter is for.
        </p>
      )}

      <dl className={styles.figures} aria-busy={!stats.data || undefined}>
        <Figure label="lessons" value={chapter.lessons.length} />
        <Figure label={chapter.lessons.length ? 'of lessons' : 'estimated'} value={formatDuration(chapterDisplayMin(chapter))} />
        {stats.data ? (
          <>
            <Figure label="of learners started" value={live ? `${chapterStats?.startedRate}%` : '—'} />
            <Figure label="of learners finished" value={live ? `${chapterStats?.completionRate}%` : '—'} />
          </>
        ) : (
          <>
            <Skeleton height={40} radius="var(--r-sm)" />
            <Skeleton height={40} radius="var(--r-sm)" />
          </>
        )}
      </dl>

      <section aria-labelledby="lessons-title" className={styles.lessonsSection}>
        <SectionHeader
          id="lessons-title"
          title="Lessons"
          description={
            live
              ? `Bars show the share of ${formatCount(stats.data?.enrolled ?? 0)} enrolled learners who finished each lesson — the steepest drop is where to look first.`
              : 'Learner completion appears once the chapter is published and learners reach it.'
          }
        />
        {chapter.lessons.length ? (
          <>
            <p className={styles.typeLine}>
              {Object.entries(typeCounts).map(([type, count]) => (
                <span key={type}>
                  {lessonTypeMeta[type as LessonType].icon} {lessonTypeCount(type as LessonType, count)}
                </span>
              ))}
            </p>
            <ol className={styles.lessonList}>
              {chapter.lessons.map((lesson, li) => {
                const rate = stats.data?.lessons[lesson.id] ?? 0;
                const previous = li > 0 ? (stats.data?.lessons[chapter.lessons[li - 1].id] ?? rate) : (chapterStats?.startedRate ?? rate);
                const drop = previous - rate;
                return (
                  <li key={lesson.id} className={styles.lessonItem}>
                    <span className={styles.lessonNumber}>
                      {index + 1}.{li + 1}
                    </span>
                    <span className={styles.lessonMain}>
                      <span className={styles.lessonName}>{lesson.title}</span>
                      <span className={styles.lessonMeta}>
                        {lessonTypeMeta[lesson.type].icon}
                        {lessonTypeMeta[lesson.type].label} · {formatDuration(lesson.durationMin)}
                        {lesson.isPreview && ' · Free preview'}
                        {lesson.status === 'draft' && ' · Draft'}
                      </span>
                    </span>
                    {live && (
                      <span className={styles.lessonRate}>
                        <Meter value={rate} size="sm" tone={drop >= 8 ? 'warn' : 'accent'} label={`${lesson.title}: ${rate}% of learners finished`} />
                        <span className={styles.rateValue}>{rate}%</span>
                        {drop >= 8 && <span className={styles.dropNote}>−{drop} pts</span>}
                      </span>
                    )}
                  </li>
                );
              })}
            </ol>
          </>
        ) : (
          <p className={styles.missing}>This chapter has no lessons yet. Lessons are added and ordered inside the chapter.</p>
        )}
      </section>

      <nav className={styles.pager} aria-label="Other chapters">
        {prev ? (
          <Link to={`${to}/chapters/${prev.id}`} className={styles.pagerLink}>
            <ArrowLeft size={16} aria-hidden="true" />
            <span>
              <span className={styles.pagerLabel}>Previous · Chapter {index}</span>
              <span className={styles.pagerTitle}>{prev.title}</span>
            </span>
          </Link>
        ) : (
          <span />
        )}
        {next && (
          <Link to={`${to}/chapters/${next.id}`} className={`${styles.pagerLink} ${styles.pagerNext}`}>
            <span>
              <span className={styles.pagerLabel}>Next · Chapter {index + 2}</span>
              <span className={styles.pagerTitle}>{next.title}</span>
            </span>
            <ArrowRight size={16} aria-hidden="true" />
          </Link>
        )}
      </nav>

      {editing && (
        <ChapterForm
          course={course}
          chapter={chapter}
          onClose={() => setEditing(false)}
          onSaved={(saved) => {
            toast({ kind: 'success', title: 'Chapter saved', text: saved.title });
            setEditing(false);
            refresh();
          }}
        />
      )}
      {deleting && (
        <DeleteChapterDialog
          course={course}
          chapter={chapter}
          learners={stats.data?.enrolled ?? 0}
          onClose={() => setDeleting(false)}
          onDeleted={(removed) => {
            toast({ kind: 'success', title: 'Chapter deleted', text: removed ? `${plural(removed, 'lesson')} removed with it.` : chapter.title });
            refresh();
            navigate(`${to}/curriculum`);
          }}
        />
      )}
      {moving && (
        <MoveChapterDialog
          course={course}
          chapter={chapter}
          onClose={() => setMoving(false)}
          onMoved={(position) => {
            toast({ kind: 'success', title: 'Chapter moved', text: `Now chapter ${position} of ${course.chapters.length}.` });
            setMoving(false);
            refresh();
          }}
        />
      )}
    </article>
  );
}
