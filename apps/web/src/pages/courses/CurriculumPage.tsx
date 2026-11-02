import { useState, type DragEvent } from 'react';
import { Link, useMatch, useNavigate } from 'react-router-dom';
import {
  ArrowDown,
  ArrowRight,
  ArrowUp,
  ArrowsDownUp,
  CaretDown,
  Copy,
  DotsSixVertical,
  DotsThree,
  Eye,
  EyeSlash,
  ListNumbers,
  PencilSimple,
  Plus,
  RocketLaunch,
  SquaresFour,
  Trash,
} from '@phosphor-icons/react';
import type { Chapter } from '@syniastrolms/domain';
import { chapterDisplayMin, courseDurationMin, courseLessons } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { cx } from '@/lib/cx';
import { formatCount, formatDuration, pad2, plural } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { ProgressRing } from '@/components/lms/progress/ProgressRing';
import { services } from '@/services';
import { ChapterForm, DeleteChapterDialog, MoveChapterDialog } from './chapters/ChapterPanels';
import { useCourseWorkspace } from './CourseLayout';
import styles from './Curriculum.module.css';

/**
 * Course → Chapter → Lesson. Chapters are managed here: add, edit, duplicate, publish, move and
 * delete; lessons expand in place. Hierarchy is carried by numbering, indentation and hairlines.
 */
export default function CurriculumPage() {
  const { course, base, refresh } = useCourseWorkspace();
  const navigate = useNavigate();
  const toast = useToast();
  const to = `${base}/courses/${course.id}`;
  const creating = Boolean(useMatch(`${to}/curriculum/chapters/new`));
  const editMatch = useMatch(`${to}/curriculum/chapters/:chapterId/edit`);
  const editing = editMatch ? course.chapters.find((c) => c.id === editMatch.params.chapterId) : undefined;

  const [open, setOpen] = useState<Set<string>>(() => new Set(course.chapters.slice(0, 1).map((c) => c.id)));
  const [order, setOrder] = useState<string[] | null>(null);
  const [dragging, setDragging] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [announcement, setAnnouncement] = useState('');
  const [deleting, setDeleting] = useState<Chapter | null>(null);
  const [moving, setMoving] = useState<Chapter | null>(null);

  const stats = useAsync(`curriculum-stats:${course.id}:${course.updatedAt}`, () => services.chapters.stats(course.id));
  const lessons = courseLessons(course);
  const drafts = course.chapters.filter((c) => c.status === 'draft').length;
  const byId = new Map(course.chapters.map((c) => [c.id, c]));
  const chapters = order ? order.map((id) => byId.get(id)!).filter(Boolean) : course.chapters;
  const reordering = order !== null;
  const changed = reordering && order.some((id, i) => id !== course.chapters[i]?.id);
  const allOpen = course.chapters.length > 0 && open.size === course.chapters.length;

  const toggle = (id: string) =>
    setOpen((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });

  const placeInOrder = (id: string, index: number) => {
    if (!order) return;
    const next = order.filter((x) => x !== id);
    next.splice(index, 0, id);
    setOrder(next);
    setAnnouncement(`${byId.get(id)!.title} moved to position ${index + 1} of ${next.length}.`);
  };
  const move = (index: number, dir: -1 | 1) => {
    if (!order) return;
    const id = order[index];
    placeInOrder(id, index + dir);
    requestAnimationFrame(() => document.getElementById(`move-${id}-${dir === -1 ? 'up' : 'down'}`)?.focus());
  };

  const onDrop = (e: DragEvent, targetIndex: number) => {
    e.preventDefault();
    if (dragging) placeInOrder(dragging, targetIndex);
    setDragging(null);
  };

  const saveOrder = async () => {
    if (!order) return;
    setSaving(true);
    setError(null);
    try {
      await services.courses.reorderChapters(course.id, order);
      setOrder(null);
      toast({ kind: 'success', title: 'Chapter order saved', text: 'Learners see the new sequence straight away.' });
      refresh();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const run = async (
    label: string,
    action: () => Promise<unknown>,
    success: { title: string; text?: string; action?: { label: string; onClick: () => void } },
  ) => {
    try {
      await action();
      toast({ kind: 'success', ...success });
      refresh();
    } catch (e) {
      toast({ kind: 'error', title: `Couldn’t ${label}`, text: (e as Error).message });
    }
  };

  const duplicate = async (chapter: Chapter) => {
    try {
      const copy = await services.chapters.duplicate(course.id, chapter.id);
      setOpen((prev) => new Set(prev).add(copy.id));
      toast({
        kind: 'success',
        title: 'Chapter duplicated',
        text: `“${copy.title}” is a draft with ${plural(copy.lessons.length, 'lesson')}.`,
        action: { label: 'Edit copy', onClick: () => navigate(`${to}/curriculum/chapters/${copy.id}/edit`) },
      });
      refresh();
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t duplicate the chapter', text: (e as Error).message });
    }
  };

  const setStatus = (chapter: Chapter, status: Chapter['status']) =>
    run(
      status === 'published' ? 'publish the chapter' : 'move the chapter to draft',
      () => services.chapters.update(course.id, chapter.id, { status }),
      status === 'published'
        ? { title: 'Chapter published', text: `Enrolled learners can now see “${chapter.title}”.` }
        : { title: 'Chapter moved to draft', text: `“${chapter.title}” is hidden from learners.` },
    );

  const formOpen = creating || Boolean(editing);
  const closeForm = () => navigate(`${to}/curriculum`);

  const header = (
    <div className={styles.head}>
      <div>
        <h2 id="outline-title" className={styles.title}>
          Curriculum
        </h2>
        <p className={styles.summary}>
          {plural(course.chapters.length, 'chapter')} · {plural(lessons.length, 'lesson')} · {formatDuration(courseDurationMin(course))}
          {drafts > 0 && ` · ${plural(drafts, 'draft chapter')}`}
          {stats.data && stats.data.enrolled > 0 && ` · ${formatCount(stats.data.enrolled)} learners`}
        </p>
      </div>
      <div className={styles.headActions}>
        {reordering ? (
          <>
            <Button onClick={() => setOrder(null)} disabled={saving}>
              Cancel
            </Button>
            <Button variant="primary" onClick={saveOrder} loading={saving} disabled={!changed}>
              Save order
            </Button>
          </>
        ) : (
          <>
            <Button variant="ghost" size="sm" onClick={() => setOpen(allOpen ? new Set() : new Set(course.chapters.map((c) => c.id)))}>
              {allOpen ? 'Collapse all' : 'Expand all'}
            </Button>
            <Button
              size="sm"
              iconStart={<ArrowsDownUp size={15} />}
              onClick={() => setOrder(course.chapters.map((c) => c.id))}
              disabled={course.chapters.length < 2}
            >
              Reorder
            </Button>
            <Button size="sm" variant="primary" iconStart={<Plus size={15} />} onClick={() => navigate(`${to}/curriculum/chapters/new`)}>
              Add chapter
            </Button>
          </>
        )}
      </div>
    </div>
  );

  return (
    <section className={styles.curriculum} aria-labelledby="outline-title">
      {course.chapters.length === 0 ? (
        <>
          {header}
          <div className={styles.empty}>
            <StateMessage
              icon={<ListNumbers size={26} />}
              title="Plan the first chapter"
              actions={
                <Button variant="primary" iconStart={<Plus size={16} />} onClick={() => navigate(`${to}/curriculum/chapters/new`)}>
                  Add chapter
                </Button>
              }
            >
              A curriculum is a sequence of chapters, each grouping lessons around one idea. Start broad — “Real Numbers”, then “Polynomials” — and add lessons
              inside each.
            </StateMessage>
          </div>
        </>
      ) : (
        <>
          {header}
          <p className={styles.legend} aria-hidden="true">
            <span>Course</span>
            <ArrowRight size={12} />
            <span>Chapter</span>
            <ArrowRight size={12} />
            <span>Lesson</span>
            <span className={styles.legendNote}>Completion shows the share of enrolled learners who finished each chapter.</span>
          </p>

          {reordering && (
            <InlineMessage kind="info" title="Reordering.">
              Drag chapters by the handle, or use the arrows, then save. Lessons stay inside their chapter.
            </InlineMessage>
          )}
          {error && (
            <InlineMessage kind="error" title="The order wasn’t saved.">
              {error}
            </InlineMessage>
          )}
          <span className="sr-only" aria-live="polite">
            {announcement}
          </span>

          <ol className={cx(styles.outline, reordering && styles.reordering)}>
            {chapters.map((chapter, i) => {
              const expanded = open.has(chapter.id) && !reordering;
              const panelId = `chapter-${chapter.id}`;
              const chapterStats = stats.data?.chapters[chapter.id];
              const hasLearners = Boolean(stats.data?.enrolled);
              return (
                <li
                  key={chapter.id}
                  className={cx(styles.chapter, expanded && styles.expanded, dragging === chapter.id && styles.dragging)}
                  draggable={reordering}
                  onDragStart={(e) => {
                    setDragging(chapter.id);
                    e.dataTransfer.effectAllowed = 'move';
                  }}
                  onDragOver={(e) => reordering && e.preventDefault()}
                  onDrop={(e) => onDrop(e, i)}
                  onDragEnd={() => setDragging(null)}
                >
                  <div className={styles.chapterRow}>
                    {reordering && (
                      <span className={styles.moves}>
                        <DotsSixVertical size={18} className={styles.handle} aria-hidden="true" />
                        <IconButton
                          id={`move-${chapter.id}-up`}
                          size="sm"
                          boxed
                          label={`Move ${chapter.title} up`}
                          icon={<ArrowUp size={14} />}
                          disabled={i === 0}
                          onClick={() => move(i, -1)}
                        />
                        <IconButton
                          id={`move-${chapter.id}-down`}
                          size="sm"
                          boxed
                          label={`Move ${chapter.title} down`}
                          icon={<ArrowDown size={14} />}
                          disabled={i === chapters.length - 1}
                          onClick={() => move(i, 1)}
                        />
                      </span>
                    )}
                    <button
                      type="button"
                      className={styles.chapterButton}
                      aria-expanded={expanded}
                      aria-controls={panelId}
                      disabled={reordering}
                      onClick={() => toggle(chapter.id)}
                    >
                      <span className={styles.index}>{pad2(i + 1)}</span>
                      <span className={styles.chapterText}>
                        <span className={styles.chapterTitle}>{chapter.title}</span>
                        {chapter.summary && <span className={styles.chapterSummary}>{chapter.summary}</span>}
                      </span>
                      <span className={styles.chapterMeta}>
                        {plural(chapter.lessons.length, 'lesson')} · {chapter.lessons.length ? '' : '~'}
                        {formatDuration(chapterDisplayMin(chapter))}
                      </span>
                      {!reordering && <CaretDown size={14} className={styles.caret} aria-hidden="true" />}
                    </button>
                    <span className={styles.completion}>
                      {!stats.data ? (
                        <Skeleton width={56} height={10} />
                      ) : chapter.status === 'draft' || !hasLearners || !chapter.lessons.length ? (
                        <span className={styles.completionNone} title="No learner data for drafts or chapters without lessons">
                          —
                        </span>
                      ) : (
                        <>
                          <ProgressRing
                            value={chapterStats?.completionRate ?? 0}
                            size="xs"
                            label={`${chapter.title}: ${chapterStats?.completionRate}% of learners finished`}
                          />
                          <span className={styles.completionValue}>{chapterStats?.completionRate}%</span>
                        </>
                      )}
                    </span>
                    <span className={styles.status}>
                      {chapter.status === 'draft' ? (
                        <Badge size="sm" tone="warn">
                          Draft
                        </Badge>
                      ) : (
                        <Badge size="sm" tone="accent" dot>
                          Published
                        </Badge>
                      )}
                    </span>
                    {!reordering && (
                      <span className={styles.rowActions}>
                        <IconButton
                          size="sm"
                          label={`Edit ${chapter.title}`}
                          icon={<PencilSimple size={16} />}
                          onClick={() => navigate(`${to}/curriculum/chapters/${chapter.id}/edit`)}
                        />
                        <Menu
                          align="end"
                          width={220}
                          trigger={(props) => (
                            <IconButton {...props} size="sm" label={`More actions for ${chapter.title}`} icon={<DotsThree size={18} weight="bold" />} />
                          )}
                          sections={[
                            {
                              items: [
                                {
                                  id: 'overview',
                                  label: 'Chapter overview',
                                  icon: <SquaresFour size={17} />,
                                  onSelect: () => navigate(`${to}/chapters/${chapter.id}`),
                                },
                                {
                                  id: 'edit',
                                  label: 'Edit chapter',
                                  icon: <PencilSimple size={17} />,
                                  onSelect: () => navigate(`${to}/curriculum/chapters/${chapter.id}/edit`),
                                },
                                { id: 'duplicate', label: 'Duplicate', icon: <Copy size={17} />, onSelect: () => duplicate(chapter) },
                                {
                                  id: 'move',
                                  label: 'Move to position…',
                                  icon: <ArrowsDownUp size={17} />,
                                  disabled: course.chapters.length < 2,
                                  onSelect: () => setMoving(chapter),
                                },
                              ],
                            },
                            {
                              items: [
                                chapter.status === 'draft'
                                  ? {
                                      id: 'publish',
                                      label: 'Publish chapter',
                                      icon: <RocketLaunch size={17} />,
                                      disabled: chapter.lessons.length === 0,
                                      hint: chapter.lessons.length ? undefined : 'Needs lessons',
                                      onSelect: () => setStatus(chapter, 'published'),
                                    }
                                  : { id: 'unpublish', label: 'Move to draft', icon: <EyeSlash size={17} />, onSelect: () => setStatus(chapter, 'draft') },
                                { id: 'delete', label: 'Delete…', icon: <Trash size={17} />, tone: 'danger', onSelect: () => setDeleting(chapter) },
                              ],
                            },
                          ]}
                        />
                      </span>
                    )}
                  </div>
                  <div id={panelId} className={styles.lessonsWrap} hidden={!expanded}>
                    {chapter.objective && (
                      <p className={styles.objective}>
                        <span className={styles.objectiveLabel}>Objective</span> {chapter.objective}
                      </p>
                    )}
                    {chapter.lessons.length === 0 ? (
                      <p className={styles.noLessons}>No lessons in this chapter yet. Lessons you add appear here in order.</p>
                    ) : (
                      <ol className={styles.lessons}>
                        {chapter.lessons.map((lesson, li) => (
                          <li key={lesson.id} className={styles.lesson}>
                            <span className={styles.lessonIndex}>
                              {i + 1}.{li + 1}
                            </span>
                            <span className={styles.lessonType} title={lessonTypeMeta[lesson.type].label}>
                              {lessonTypeMeta[lesson.type].icon}
                              <span className={styles.lessonTypeLabel}>{lessonTypeMeta[lesson.type].label}</span>
                            </span>
                            <span className={styles.lessonTitle}>{lesson.title}</span>
                            <span className={styles.lessonFlags}>
                              {lesson.isPreview && (
                                <Badge size="sm" tone="info" icon={<Eye size={11} />}>
                                  Free preview
                                </Badge>
                              )}
                              {lesson.status === 'draft' && (
                                <Badge size="sm" tone="warn">
                                  Draft
                                </Badge>
                              )}
                            </span>
                            <span className={styles.lessonDuration}>{formatDuration(lesson.durationMin)}</span>
                          </li>
                        ))}
                      </ol>
                    )}
                    <span className={styles.chapterLinks}>
                      <Link to={`${to}/lessons/new?chapter=${chapter.id}`} className={styles.chapterLink}>
                        <Plus size={13} /> Add lesson
                      </Link>
                      <Link to={`${to}/chapters/${chapter.id}`} className={styles.chapterLink}>
                        Open chapter overview <ArrowRight size={13} />
                      </Link>
                    </span>
                  </div>
                </li>
              );
            })}
          </ol>
        </>
      )}

      {formOpen && (
        <ChapterForm
          key={editing?.id ?? 'new'}
          course={course}
          chapter={editing}
          onClose={closeForm}
          onSaved={(saved, created) => {
            toast({
              kind: 'success',
              title: created ? 'Chapter added' : 'Chapter saved',
              text: created ? `“${saved.title}” is a draft. Add lessons, then publish it.` : saved.title,
            });
            if (created) setOpen((prev) => new Set(prev).add(saved.id));
            refresh();
            closeForm();
          }}
        />
      )}
      {deleting && (
        <DeleteChapterDialog
          course={course}
          chapter={deleting}
          learners={stats.data?.enrolled ?? 0}
          onClose={() => setDeleting(null)}
          onDeleted={(removed) => {
            toast({ kind: 'success', title: 'Chapter deleted', text: removed ? `${plural(removed, 'lesson')} removed with it.` : deleting.title });
            setDeleting(null);
            refresh();
          }}
        />
      )}
      {moving && (
        <MoveChapterDialog
          course={course}
          chapter={moving}
          onClose={() => setMoving(null)}
          onMoved={(position) => {
            toast({ kind: 'success', title: 'Chapter moved', text: `“${moving.title}” is now chapter ${position}.` });
            setMoving(null);
            refresh();
          }}
        />
      )}
    </section>
  );
}
