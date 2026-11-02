import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Archive, ArrowCounterClockwise, ChartBar, Copy, DotsThree, Exam, Eye, MagnifyingGlass, PencilSimple, Plus, Trash } from '@phosphor-icons/react';
import type { QuizStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatCount, formatDate, formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Meter } from '@/components/lms/progress/Meters';
import { services, type QuizRow } from '@/services';
import { STATUS_LABEL } from './quizForm';
import styles from './Quizzes.module.css';

/** A quiz's status as a badge: live, being written, or kept with its results but closed to new attempts. */
function StatusBadge({ status }: { status: QuizStatus }) {
  if (status === 'published')
    return (
      <Badge size="sm" tone="accent" dot>
        {STATUS_LABEL.published}
      </Badge>
    );
  return (
    <Badge size="sm" tone={status === 'archived' ? 'neutral' : 'warn'}>
      {STATUS_LABEL[status]}
    </Badge>
  );
}

export default function QuizListPage() {
  const { can } = usePermissions();
  const { base, instructorId, isTeaching } = useWorkspace();
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const [deleting, setDeleting] = useState<QuizRow | null>(null);

  const search = params.get('q') ?? '';
  const courseId = params.get('course') ?? '';
  const status = (params.get('status') as QuizStatus | 'all') ?? 'all';
  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all') p.delete(k);
      else p.set(k, v);
    }
    setParams(p, { replace: true });
  };

  const query = { search, courseId: courseId || undefined, status, scopeInstructorId: instructorId };
  const list = useAsync(JSON.stringify(query), () => services.quizzes.list(query));
  const courses = useAsync(`quiz-courses:${instructorId}`, () => services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }));
  const rows = list.data?.rows ?? [];
  const counts = list.data?.counts;
  const filtered = Boolean(search || courseId || status !== 'all');
  const to = (row: QuizRow, tab = '') => `${base}/quizzes/${row.quiz.id}${tab}`;

  // Archiving keeps the quiz and every result, but no learner starts it again; restoring publishes it again.
  const setArchived = async (row: QuizRow, archived: boolean) => {
    try {
      await services.quizzes.update(row.quiz.id, { status: archived ? 'archived' : 'published' });
      toast({
        kind: 'success',
        title: archived ? 'Quiz archived' : 'Quiz restored',
        text: archived ? `Learners can’t start “${row.quiz.title}” any more. Its results are kept.` : `Learners can take “${row.quiz.title}” again.`,
      });
      list.run().catch(() => undefined);
    } catch (e) {
      toast({ kind: 'error', title: archived ? 'Couldn’t archive the quiz' : 'Couldn’t restore the quiz', text: (e as Error).message });
    }
  };

  const duplicate = async (row: QuizRow) => {
    try {
      const copy = await services.quizzes.duplicate(row.quiz.id);
      toast({
        kind: 'success',
        title: 'Quiz duplicated',
        text: `“${copy.title}” is a draft.`,
        action: { label: 'Open', onClick: () => navigate(`${base}/quizzes/${copy.id}`) },
      });
      list.run().catch(() => undefined);
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t duplicate the quiz', text: (e as Error).message });
    }
  };

  const menu = (row: QuizRow) => (
    <Menu
      align="end"
      width={200}
      trigger={(props) => <IconButton {...props} size="sm" label={`More actions for ${row.quiz.title}`} icon={<DotsThree size={18} weight="bold" />} />}
      sections={[
        {
          items: [
            { id: 'edit', label: 'Edit questions', icon: <PencilSimple size={17} />, onSelect: () => navigate(to(row)) },
            { id: 'preview', label: 'Preview', icon: <Eye size={17} />, onSelect: () => navigate(to(row, '/preview')) },
            { id: 'results', label: 'Results', icon: <ChartBar size={17} />, onSelect: () => navigate(to(row, '/results')) },
            { id: 'duplicate', label: 'Duplicate', icon: <Copy size={17} />, onSelect: () => duplicate(row) },
          ],
        },
        {
          items: [
            ...(!can('assessment.edit')
              ? []
              : row.quiz.status === 'archived'
                ? [{ id: 'restore', label: 'Restore', icon: <ArrowCounterClockwise size={17} />, onSelect: () => setArchived(row, false) }]
                : row.quiz.status === 'published'
                  ? [{ id: 'archive', label: 'Archive', icon: <Archive size={17} />, onSelect: () => setArchived(row, true) }]
                  : []),
            row.quiz.lessonId
              ? { id: 'delete', label: 'Delete…', icon: <Trash size={17} />, disabled: true, hint: 'Delivered by a lesson' }
              : { id: 'delete', label: 'Delete…', icon: <Trash size={17} />, tone: 'danger', onSelect: () => setDeleting(row) },
          ],
        },
      ]}
    />
  );

  const columns: Column<QuizRow>[] = [
    {
      key: 'quiz',
      header: 'Quiz',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.quizCell}>
          <Link to={to(r)} className={styles.quizTitle}>
            {r.quiz.title}
          </Link>
          <span className={styles.quizMeta}>
            {r.courseTitle}
            {r.chapterTitle && ` · ${r.chapterTitle}`}
          </span>
        </span>
      ),
    },
    {
      key: 'questions',
      header: 'Questions',
      width: '120px',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.nowrap}>{r.quiz.questions.length ? `${plural(r.quiz.questions.length, 'question')} · ${r.points} pts` : 'No questions'}</span>
      ),
    },
    { key: 'pass', header: 'Pass mark', width: '96px', mobile: 'detail', render: (r) => <span className="tabular">{r.quiz.settings.passMark}%</span> },
    {
      key: 'attempts',
      header: 'Attempts',
      width: '96px',
      align: 'end',
      mobile: 'detail',
      render: (r) => <span className="tabular">{r.attempts ? formatCount(r.attempts) : '—'}</span>,
    },
    {
      key: 'passRate',
      header: 'Passed',
      width: '140px',
      mobile: 'detail',
      render: (r) =>
        r.passRate === null ? (
          <span className={styles.muted}>No attempts</span>
        ) : (
          <span className={styles.rateCell}>
            <Meter value={r.passRate} size="sm" label={`${r.quiz.title}: ${r.passRate}% passed`} />
            <span className="tabular">{r.passRate}%</span>
          </span>
        ),
    },
    {
      key: 'status',
      header: 'Status',
      width: '104px',
      mobile: 'status',
      render: (r) => <StatusBadge status={r.quiz.status} />,
    },
    {
      key: 'updated',
      header: 'Updated',
      width: '120px',
      mobile: 'detail',
      render: (r) => (
        <time dateTime={r.quiz.updatedAt} title={formatDate(r.quiz.updatedAt)} className={styles.nowrap}>
          {formatRelative(r.quiz.updatedAt, now)}
        </time>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      width: '84px',
      align: 'end',
      mobile: 'hidden',
      render: (r) => (
        <span className={styles.rowActions}>
          <IconButton size="sm" label={`Edit ${r.quiz.title}`} icon={<PencilSimple size={16} />} onClick={() => navigate(to(r))} />
          {menu(r)}
        </span>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        title={isTeaching ? 'Tests & quizzes' : 'Quizzes'}
        count={counts ? plural(counts.all, 'quiz', 'quizzes') : undefined}
        description={
          isTeaching
            ? 'Tests and quizzes in the courses you teach. Add questions, choose the pass mark, and see which questions students find hardest.'
            : 'Chapter checks and final assessments across the platform. Build questions, set how they are scored, and see which questions learners find hardest.'
        }
        actions={
          can('assessment.edit') && (
            <LinkButton to={`${base}/quizzes/new${courseId ? `?course=${courseId}` : ''}`} iconStart={<Plus size={16} />}>
              New quiz
            </LinkButton>
          )
        }
      />

      <div className={styles.controls} hidden={counts?.all === 0 && !filtered}>
        <SegmentedControl<QuizStatus | 'all'>
          label="Quiz status"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: counts?.all },
            { value: 'published', label: 'Published', count: counts?.published },
            { value: 'draft', label: 'Drafts', count: counts?.draft },
            { value: 'archived', label: 'Archived', count: counts?.archived },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search quizzes" aria-label="Search quizzes" />
          </div>
          <Field label="Course" hideLabel className={styles.filter}>
            <Select value={courseId} onChange={(e) => update({ course: e.target.value })}>
              <option value="">All courses</option>
              {courses.data?.rows.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.title}
                </option>
              ))}
            </Select>
          </Field>
        </div>
      </div>

      {list.status === 'error' && !list.data ? (
        <StateMessage
          kind="error"
          title="Quizzes didn’t load"
          actions={
            <Button variant="primary" onClick={() => list.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : list.data && rows.length === 0 ? (
        filtered ? (
          <StateMessage
            icon={<MagnifyingGlass size={26} />}
            title="No quizzes match"
            actions={<Button onClick={() => setParams(new URLSearchParams(), { replace: true })}>Clear filters</Button>}
          >
            Try another title or course.
          </StateMessage>
        ) : (
          <StateMessage
            icon={<Exam size={26} />}
            title="No quizzes yet"
            actions={
              <LinkButton to={`${base}/quizzes/new`} iconStart={<Plus size={16} />}>
                Build the first quiz
              </LinkButton>
            }
          >
            Quizzes check understanding at the end of a chapter or course, with single choice, multiple choice, true/false and short-answer questions.
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label="Quizzes" aria-busy={!list.data || undefined}>
          {!list.data
            ? Array.from({ length: 4 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <Skeleton width="70%" height={12} />
                  <Skeleton width="50%" height={8} />
                </li>
              ))
            : rows.map((r) => (
                <li key={r.quiz.id} className={styles.card}>
                  <div className={styles.cardHead}>
                    <Link to={to(r)} className={styles.quizTitle}>
                      {r.quiz.title}
                    </Link>
                    {menu(r)}
                  </div>
                  <span className={styles.quizMeta}>{r.courseTitle}</span>
                  <span className={styles.cardFacts}>
                    <StatusBadge status={r.quiz.status} />
                    <span>{plural(r.quiz.questions.length, 'question')}</span>
                    {r.passRate !== null && <span>{r.passRate}% passed</span>}
                  </span>
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Quizzes"
            rows={rows}
            columns={columns}
            rowKey={(r) => r.quiz.id}
            rowLabel={(r) => r.quiz.title}
            loading={!list.data}
            skeletonRows={6}
          />
        </div>
      )}

      {deleting && deleting.attempts > 0 ? (
        // A quiz learners have taken is never deleted — that would delete their results — so it is archived instead.
        <ConfirmDialog
          open
          onClose={() => setDeleting(null)}
          onConfirm={async () => {
            await services.quizzes.update(deleting.quiz.id, { status: 'archived' });
            toast({ kind: 'success', title: 'Quiz archived', text: `Learners can’t start “${deleting.quiz.title}” any more. Its results are kept.` });
            setDeleting(null);
            list.run().catch(() => undefined);
          }}
          icon={<Archive size={20} />}
          title="Archive this quiz instead?"
          description={deleting.quiz.title}
          confirmLabel="Archive quiz"
        >
          <ul className={styles.impact}>
            <li>
              Learners have taken it {plural(deleting.attempts, 'time')}, so deleting it would delete their results. It can’t be deleted — archive it instead.
            </li>
            <li>An archived quiz keeps every result, and no learner can start it again. You can restore it later.</li>
          </ul>
        </ConfirmDialog>
      ) : (
        deleting && (
          <ConfirmDialog
            open
            onClose={() => setDeleting(null)}
            onConfirm={async () => {
              // Refused once anyone has started it; the dialog shows the server's reason ("…Archive it instead.").
              await services.quizzes.remove(deleting.quiz.id);
              toast({ kind: 'success', title: 'Quiz deleted', text: deleting.quiz.title });
              setDeleting(null);
              list.run().catch(() => undefined);
            }}
            tone="danger"
            icon={<Trash size={20} />}
            title="Delete this quiz?"
            description={deleting.quiz.title}
            confirmLabel="Delete quiz"
          >
            <ul className={styles.impact}>
              <li>{plural(deleting.quiz.questions.length, 'question')} and the quiz settings are removed. This can’t be undone.</li>
            </ul>
          </ConfirmDialog>
        )
      )}
    </div>
  );
}
