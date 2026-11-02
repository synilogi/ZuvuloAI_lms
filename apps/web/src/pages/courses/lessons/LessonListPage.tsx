import { Fragment, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { ArrowsLeftRight, BookOpenText, Copy, DotsThree, Eye, EyeSlash, MagnifyingGlass, PencilSimple, Plus, RocketLaunch, Trash } from '@phosphor-icons/react';
import type { ContentStatus, LessonType } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { formatDate, formatDuration, formatRelative, pad2, plural } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { lessonTypeMeta } from '@/components/lms/course/CourseIdentity';
import { services, type LessonRow, type LessonSort } from '@/services';
import { useCourseWorkspace } from '../CourseLayout';
import styles from './Lessons.module.css';

const TYPES: LessonType[] = ['video', 'reading', 'document', 'assessment', 'assignment', 'live', 'practice'];

/** Every lesson in the course, grouped under its chapter so the Course → Chapter → Lesson context stays visible. */
export default function LessonListPage() {
  const { course, base, refresh } = useCourseWorkspace();
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const [deleting, setDeleting] = useState<LessonRow | null>(null);
  const [moving, setMoving] = useState<LessonRow | null>(null);

  const search = params.get('q') ?? '';
  const chapterId = params.get('chapter') ?? '';
  const type = (params.get('type') as LessonType | 'all') ?? 'all';
  const status = (params.get('status') as ContentStatus | 'all') ?? 'all';
  const sort = (params.get('sort') as LessonSort) ?? 'position';
  const to = `${base}/courses/${course.id}`;

  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [key, value] of Object.entries(next)) {
      if (!value || value === 'all' || (key === 'sort' && value === 'position')) p.delete(key);
      else p.set(key, value);
    }
    setParams(p, { replace: true });
  };

  const query = { search, chapterId: chapterId || undefined, type, status, sort };
  const list = useAsync(`lessons:${course.id}:${course.updatedAt}:${JSON.stringify(query)}`, () => services.lessons.list(course.id, query));
  const rows = list.data?.rows ?? [];
  const counts = list.data?.counts;
  const filtered = Boolean(search || chapterId || type !== 'all' || status !== 'all');
  const grouped = sort === 'position';
  const newLessonTo = `${to}/lessons/new${chapterId ? `?chapter=${chapterId}` : ''}`;

  const act = async (label: string, action: () => Promise<unknown>, title: string, text?: string) => {
    try {
      await action();
      toast({ kind: 'success', title, text });
      refresh();
    } catch (e) {
      toast({ kind: 'error', title: `Couldn’t ${label}`, text: (e as Error).message });
    }
  };

  const menu = (row: LessonRow) => (
    <Menu
      align="end"
      width={220}
      trigger={(props) => <IconButton {...props} size="sm" label={`More actions for ${row.lesson.title}`} icon={<DotsThree size={18} weight="bold" />} />}
      sections={[
        {
          items: [
            { id: 'edit', label: 'Edit lesson', icon: <PencilSimple size={17} />, onSelect: () => navigate(`${to}/lessons/${row.lesson.id}`) },
            { id: 'preview', label: 'Preview', icon: <Eye size={17} />, onSelect: () => navigate(`${to}/lessons/${row.lesson.id}/preview`) },
            {
              id: 'duplicate',
              label: 'Duplicate',
              icon: <Copy size={17} />,
              onSelect: () =>
                act(
                  'duplicate the lesson',
                  () => services.lessons.duplicate(course.id, row.lesson.id),
                  'Lesson duplicated',
                  `A draft copy was added after “${row.lesson.title}”.`,
                ),
            },
            { id: 'move', label: 'Move to chapter…', icon: <ArrowsLeftRight size={17} />, onSelect: () => setMoving(row) },
          ],
        },
        {
          items: [
            row.lesson.status === 'draft'
              ? {
                  id: 'publish',
                  label: 'Publish',
                  icon: <RocketLaunch size={17} />,
                  onSelect: () =>
                    act(
                      'publish the lesson',
                      () => services.lessons.update(course.id, row.lesson.id, { status: 'published' }),
                      'Lesson published',
                      row.lesson.title,
                    ),
                }
              : {
                  id: 'draft',
                  label: 'Move to draft',
                  icon: <EyeSlash size={17} />,
                  onSelect: () =>
                    act(
                      'move the lesson to draft',
                      () => services.lessons.update(course.id, row.lesson.id, { status: 'draft' }),
                      'Lesson moved to draft',
                      row.lesson.title,
                    ),
                },
            { id: 'delete', label: 'Delete…', icon: <Trash size={17} />, tone: 'danger', onSelect: () => setDeleting(row) },
          ],
        },
      ]}
    />
  );

  const number = (row: LessonRow) => `${row.chapterIndex + 1}.${row.lessonIndex + 1}`;
  const status_ = (s: ContentStatus) =>
    s === 'draft' ? (
      <Badge size="sm" tone="warn">
        Draft
      </Badge>
    ) : (
      <Badge size="sm" tone="accent" dot>
        Published
      </Badge>
    );

  // Group consecutive rows by chapter when showing course order.
  const groups = grouped
    ? rows.reduce<{ chapterId: string; title: string; index: number; rows: LessonRow[] }[]>((acc, row) => {
        const last = acc[acc.length - 1];
        if (last?.chapterId === row.chapterId) last.rows.push(row);
        else acc.push({ chapterId: row.chapterId, title: row.chapterTitle, index: row.chapterIndex, rows: [row] });
        return acc;
      }, [])
    : [{ chapterId: 'all', title: '', index: -1, rows }];

  return (
    <section className={styles.list} aria-labelledby="lessons-title">
      <div className={styles.head}>
        <div>
          <h2 id="lessons-title" className={styles.title}>
            Lessons
          </h2>
          <p className={styles.summary}>
            {counts ? `${plural(counts.all, 'lesson')} · ${counts.published} published · ${plural(counts.draft, 'draft')}` : 'Loading lessons…'}
          </p>
        </div>
        <Button variant="primary" iconStart={<Plus size={16} />} onClick={() => navigate(newLessonTo)} disabled={!course.chapters.length}>
          Add lesson
        </Button>
      </div>

      {course.chapters.length === 0 ? (
        <StateMessage
          icon={<BookOpenText size={26} />}
          title="Add a chapter first"
          actions={
            <Button variant="primary" onClick={() => navigate(`${to}/curriculum/chapters/new`)}>
              Add chapter
            </Button>
          }
        >
          Lessons live inside chapters. Plan the first chapter, then add its lessons here.
        </StateMessage>
      ) : (
        <>
          <div className={styles.controls}>
            <SegmentedControl<LessonType | 'all'>
              size="sm"
              label="Lesson type"
              value={type}
              onChange={(v) => update({ type: v })}
              segments={[
                { value: 'all', label: 'All', count: counts?.all },
                ...TYPES.filter((t) => counts?.byType[t] || type === t).map((t) => ({
                  value: t,
                  label: lessonTypeMeta[t].label,
                  count: counts?.byType[t] ?? 0,
                })),
              ]}
            />
            <div className={styles.toolbar}>
              <div className={styles.search}>
                <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search lessons" aria-label="Search lessons" />
              </div>
              <Field label="Chapter" hideLabel className={styles.filter}>
                <Select value={chapterId} onChange={(e) => update({ chapter: e.target.value })}>
                  <option value="">All chapters</option>
                  {course.chapters.map((c, i) => (
                    <option key={c.id} value={c.id}>
                      {pad2(i + 1)} · {c.title}
                    </option>
                  ))}
                </Select>
              </Field>
              <Field label="Status" hideLabel className={styles.filterSmall}>
                <Select value={status} onChange={(e) => update({ status: e.target.value })}>
                  <option value="all">Any status</option>
                  <option value="published">Published</option>
                  <option value="draft">Drafts</option>
                </Select>
              </Field>
              <Field label="Sort" hideLabel className={styles.filterSmall}>
                <Select value={sort} onChange={(e) => update({ sort: e.target.value })}>
                  <option value="position">Course order</option>
                  <option value="updated">Recently updated</option>
                  <option value="duration">Longest first</option>
                  <option value="title">Title A–Z</option>
                </Select>
              </Field>
            </div>
          </div>

          {list.status === 'error' && !list.data ? (
            <InlineMessage
              kind="error"
              title="Lessons didn’t load."
              action={
                <Button size="sm" onClick={() => list.run().catch(() => undefined)}>
                  Try again
                </Button>
              }
            >
              {list.error.message}
            </InlineMessage>
          ) : !list.data ? (
            <div className={styles.skeleton} role="status" aria-label="Loading lessons">
              {Array.from({ length: 6 }, (_, i) => (
                <Skeleton key={i} height={44} radius="var(--r-sm)" />
              ))}
            </div>
          ) : rows.length === 0 ? (
            filtered ? (
              <StateMessage
                icon={<MagnifyingGlass size={26} />}
                title="No lessons match"
                actions={<Button onClick={() => setParams(new URLSearchParams(), { replace: true })}>Clear filters</Button>}
              >
                Try another word, chapter or type.
              </StateMessage>
            ) : (
              <StateMessage
                icon={<BookOpenText size={26} />}
                title="No lessons yet"
                actions={
                  <Button variant="primary" iconStart={<Plus size={16} />} onClick={() => navigate(newLessonTo)}>
                    Add the first lesson
                  </Button>
                }
              >
                Videos, articles, PDFs, quizzes, assignments and live sessions all start here.
              </StateMessage>
            )
          ) : isMobile ? (
            <div className={styles.cards}>
              {groups.map((group) => (
                <section key={group.chapterId} aria-label={group.title || 'Lessons'}>
                  {grouped && (
                    <h3 className={styles.groupTitle}>
                      <span className={styles.groupIndex}>{pad2(group.index + 1)}</span> {group.title}
                    </h3>
                  )}
                  <ul className={styles.cardList}>
                    {group.rows.map((row) => (
                      <li key={row.lesson.id} className={styles.card}>
                        <span className={styles.typeIcon} title={lessonTypeMeta[row.lesson.type].label}>
                          {lessonTypeMeta[row.lesson.type].icon}
                        </span>
                        <span className={styles.cardText}>
                          <Link to={`${to}/lessons/${row.lesson.id}`} className={styles.lessonLink}>
                            {row.lesson.title}
                          </Link>
                          <span className={styles.cardMeta}>
                            {number(row)} · {lessonTypeMeta[row.lesson.type].label} · {formatDuration(row.lesson.durationMin)}
                            {!grouped && ` · ${row.chapterTitle}`}
                          </span>
                          <span className={styles.cardFlags}>
                            {status_(row.lesson.status)}
                            {row.lesson.isPreview && (
                              <Badge size="sm" tone="info">
                                Free preview
                              </Badge>
                            )}
                          </span>
                        </span>
                        {menu(row)}
                      </li>
                    ))}
                  </ul>
                </section>
              ))}
            </div>
          ) : (
            <div className={styles.tablePanel}>
              <table className={styles.table} aria-label={`Lessons in ${course.title}`}>
                <thead>
                  <tr>
                    <th scope="col" className={styles.colNumber}>
                      #
                    </th>
                    <th scope="col">Lesson</th>
                    <th scope="col" className={styles.colType}>
                      Type
                    </th>
                    {!grouped && <th scope="col">Chapter</th>}
                    <th scope="col" className={styles.colDuration}>
                      Duration
                    </th>
                    <th scope="col" className={styles.colStatus}>
                      Status
                    </th>
                    <th scope="col" className={styles.colUpdated}>
                      Updated
                    </th>
                    <th scope="col" className={styles.colActions}>
                      <span className="sr-only">Actions</span>
                    </th>
                  </tr>
                </thead>
                {groups.map((group) => (
                  <tbody key={group.chapterId}>
                    {grouped && (
                      <tr className={styles.groupRow}>
                        <th scope="rowgroup" colSpan={7}>
                          <span className={styles.groupIndex}>{pad2(group.index + 1)}</span>
                          <Link to={`${to}/chapters/${group.chapterId}`} className={styles.groupLink}>
                            {group.title}
                          </Link>
                          <span className={styles.groupMeta}>
                            {plural(group.rows.length, 'lesson')} · {formatDuration(group.rows.reduce((n, r) => n + r.lesson.durationMin, 0))}
                          </span>
                        </th>
                      </tr>
                    )}
                    {group.rows.map((row) => (
                      <Fragment key={row.lesson.id}>
                        <tr>
                          <td className={styles.number}>{number(row)}</td>
                          <td>
                            <span className={styles.lessonCell}>
                              <Link to={`${to}/lessons/${row.lesson.id}`} className={styles.lessonLink}>
                                {row.lesson.title}
                              </Link>
                              {row.lesson.isPreview && (
                                <Badge size="sm" tone="info" icon={<Eye size={11} />}>
                                  Free preview
                                </Badge>
                              )}
                            </span>
                          </td>
                          <td>
                            <span className={styles.type}>
                              {lessonTypeMeta[row.lesson.type].icon}
                              {lessonTypeMeta[row.lesson.type].label}
                            </span>
                          </td>
                          {!grouped && <td className={styles.chapterCell}>{row.chapterTitle}</td>}
                          <td className={styles.duration}>{formatDuration(row.lesson.durationMin)}</td>
                          <td>{status_(row.lesson.status)}</td>
                          <td>
                            <time dateTime={row.lesson.updatedAt} title={formatDate(row.lesson.updatedAt)} className={styles.updated}>
                              {formatRelative(row.lesson.updatedAt, now)}
                            </time>
                          </td>
                          <td className={styles.actions}>
                            <IconButton
                              size="sm"
                              label={`Edit ${row.lesson.title}`}
                              icon={<PencilSimple size={16} />}
                              onClick={() => navigate(`${to}/lessons/${row.lesson.id}`)}
                            />
                            {menu(row)}
                          </td>
                        </tr>
                      </Fragment>
                    ))}
                  </tbody>
                ))}
              </table>
            </div>
          )}
        </>
      )}

      {deleting && (
        <ConfirmDialog
          open
          onClose={() => setDeleting(null)}
          onConfirm={async () => {
            await services.lessons.remove(course.id, deleting.lesson.id);
            toast({ kind: 'success', title: 'Lesson deleted', text: deleting.lesson.title });
            setDeleting(null);
            refresh();
          }}
          tone="danger"
          icon={<Trash size={20} />}
          title="Delete this lesson?"
          description={`${number(deleting)} · ${deleting.lesson.title}`}
          confirmLabel="Delete lesson"
          acknowledge={deleting.lesson.status === 'published' && course.enrolledCount > 0 ? 'I understand learners lose progress on this lesson' : undefined}
        >
          <ul className={styles.impact}>
            <li>Its content, objectives and settings are removed. This can’t be undone.</li>
            {deleting.lesson.status === 'published' && course.enrolledCount > 0 && (
              <li>Enrolled learners will no longer see it, and progress recorded on it is removed.</li>
            )}
            <li>Lessons after it in “{deleting.chapterTitle}” move up one place.</li>
          </ul>
        </ConfirmDialog>
      )}
      {moving && (
        <MoveLessonDialog
          row={moving}
          onClose={() => setMoving(null)}
          onMoved={() => {
            setMoving(null);
            refresh();
          }}
        />
      )}
    </section>
  );
}

function MoveLessonDialog({ row, onClose, onMoved }: { row: LessonRow; onClose: () => void; onMoved: () => void }) {
  const { course } = useCourseWorkspace();
  const toast = useToast();
  const [chapterId, setChapterId] = useState(row.chapterId);
  const target = course.chapters.find((c) => c.id === chapterId)!;
  const sameChapter = chapterId === row.chapterId;
  const maxPosition = sameChapter ? target.lessons.length : target.lessons.length + 1;
  const [position, setPosition] = useState(row.lessonIndex + 1);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const move = async () => {
    setBusy(true);
    setError(null);
    try {
      await services.lessons.move(course.id, row.lesson.id, chapterId, Math.min(position, maxPosition));
      toast({ kind: 'success', title: 'Lesson moved', text: `Now lesson ${Math.min(position, maxPosition)} in “${target.title}”.` });
      onMoved();
    } catch (e) {
      setError((e as Error).message);
      setBusy(false);
    }
  };

  const others = target.lessons.filter((l) => l.id !== row.lesson.id);
  return (
    <Modal
      open
      onClose={onClose}
      icon={<ArrowsLeftRight size={20} />}
      title="Move lesson"
      description={row.lesson.title}
      footer={
        <>
          <Button onClick={onClose} disabled={busy}>
            Cancel
          </Button>
          <Button variant="primary" loading={busy} disabled={sameChapter && position === row.lessonIndex + 1} onClick={move}>
            Move lesson
          </Button>
        </>
      }
    >
      <Field label="Chapter">
        <Select
          value={chapterId}
          onChange={(e) => {
            setChapterId(e.target.value);
            setPosition((course.chapters.find((c) => c.id === e.target.value)?.lessons.length ?? 0) + 1);
          }}
        >
          {course.chapters.map((c, i) => (
            <option key={c.id} value={c.id}>
              {pad2(i + 1)} · {c.title}
            </option>
          ))}
        </Select>
      </Field>
      <Field label="Position">
        <Select value={Math.min(position, maxPosition)} onChange={(e) => setPosition(Number(e.target.value))}>
          {Array.from({ length: maxPosition }, (_, i) => (
            <option key={i} value={i + 1}>
              {i === 0 ? 'First in the chapter' : `After “${others[i - 1]?.title ?? 'the last lesson'}”`}
            </option>
          ))}
        </Select>
      </Field>
      {error && (
        <InlineMessage kind="error" title="The lesson didn’t move.">
          {error}
        </InlineMessage>
      )}
    </Modal>
  );
}
