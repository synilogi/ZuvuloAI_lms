import { useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { BellRinging, CheckCircle, MagnifyingGlass, Tray } from '@phosphor-icons/react';
import type { CourseAssignment } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatDate, formatRelative, formatTime, plural } from '@/lib/format';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, type SubmissionFilter, type SubmissionRow } from '@/services';
import { ReviewBadge, scoreText, waitingFor } from './assignmentMeta';
import styles from './Assignments.module.css';

const PAGE_SIZE = 20;

interface SubmissionListProps {
  /** Across every assignment in scope, or one assignment's submissions. */
  mode: 'queue' | 'assignment';
  assignment?: CourseAssignment;
}

export function SubmissionList({ mode, assignment }: SubmissionListProps) {
  const { base, instructorId } = useWorkspace();
  const [params, setParams] = useSearchParams();
  const now = useNow();
  const toast = useToast();
  const { isMobile } = useViewport();
  const [reminding, setReminding] = useState<string | null>(null);
  const [reminded, setReminded] = useState<Set<string>>(new Set());

  const filter = (params.get('filter') as SubmissionFilter | null) ?? 'to-review';
  const search = params.get('q') ?? '';
  const courseId = params.get('course') ?? '';
  const sort = (params.get('sort') as 'oldest' | 'newest' | 'score' | null) ?? 'oldest';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const update = (next: Record<string, string | undefined>, keepPage = false) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || (k === 'filter' && v === 'to-review') || (k === 'sort' && v === 'oldest')) p.delete(k);
      else p.set(k, v);
    }
    if (!keepPage) p.delete('page');
    setParams(p, { replace: true });
  };

  const query = {
    assignmentId: assignment?.id,
    courseId: courseId || undefined,
    filter,
    search,
    sort,
    scopeInstructorId: instructorId,
    page,
    pageSize: PAGE_SIZE,
  };
  const list = useAsync(`submissions:${JSON.stringify(query)}`, () => services.assignments.submissions(query));
  const courses = useAsync(`review-courses:${instructorId}`, () => services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }), {
    immediate: mode === 'queue',
  });
  const data = list.data;
  const rows = data?.rows ?? [];
  const from = mode === 'queue' ? '?from=queue' : '';
  const reviewTo = (r: SubmissionRow) => `${base}/assignments/${r.assignmentId}/submissions/${r.id}${from}`;

  const remind = async (studentIds: string[], key: string) => {
    if (!assignment) return;
    setReminding(key);
    try {
      const { sent } = await services.assignments.remind(assignment.id, studentIds);
      setReminded((prev) => new Set([...prev, ...studentIds]));
      toast({
        kind: 'success',
        title: sent === 1 ? 'Reminder sent' : `${plural(sent, 'reminder')} sent`,
        text: `${assignment.title} · by email and in the app`,
      });
    } catch (e) {
      toast({ kind: 'error', title: 'Reminders weren’t sent', text: (e as Error).message });
    } finally {
      setReminding(null);
    }
  };

  const action = (r: SubmissionRow, block = false) => {
    if (!r.submission) {
      const done = reminded.has(r.student.id);
      return (
        <Button
          size="sm"
          variant={block ? 'secondary' : 'ghost'}
          iconStart={done ? <CheckCircle size={15} /> : <BellRinging size={15} />}
          disabled={done}
          loading={reminding === r.id}
          onClick={() => remind([r.student.id], r.id)}
          aria-label={done ? `Reminder sent to ${r.student.name}` : `Remind ${r.student.name}`}
        >
          {done ? 'Reminded' : 'Remind'}
        </Button>
      );
    }
    const open = r.submission.review.status === 'waiting' || r.submission.review.status === 'in-review';
    return (
      <LinkButton size="sm" variant={open ? 'primary' : 'secondary'} to={reviewTo(r)} aria-label={`${open ? 'Review' : 'Open'} ${r.student.name}’s submission`}>
        {open ? 'Review' : 'Open'}
      </LinkButton>
    );
  };

  const submittedCell = (r: SubmissionRow) =>
    r.submission ? (
      <span className={styles.submittedCell}>
        {mode === 'queue' ? (
          <time dateTime={r.submission.submittedAt}>
            {formatDate(r.submission.submittedAt)}, {formatTime(r.submission.submittedAt)}
          </time>
        ) : (
          <time dateTime={r.submission.submittedAt} title={`${formatDate(r.submission.submittedAt)}, ${formatTime(r.submission.submittedAt)}`}>
            {formatRelative(r.submission.submittedAt, now)}
          </time>
        )}
        {r.submission.late && (
          <Badge size="sm" tone="warn">
            Late
          </Badge>
        )}
      </span>
    ) : (
      <span className={styles.muted}>Finished the chapter, nothing handed in</span>
    );

  const columns: Column<SubmissionRow>[] = [
    {
      key: 'student',
      header: 'Student',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.person}>
          <Avatar name={r.student.name} size={30} />
          <span className={styles.personText}>
            {r.submission ? (
              <Link to={reviewTo(r)} className={styles.personName}>
                {r.student.name}
              </Link>
            ) : (
              <span className={styles.personName}>{r.student.name}</span>
            )}
            <span className={styles.personMeta}>{mode === 'queue' ? r.student.city : r.student.email}</span>
          </span>
        </span>
      ),
    },
    ...(mode === 'queue'
      ? [
          {
            key: 'assignment',
            header: 'Assignment',
            mobile: 'meta' as const,
            render: (r: SubmissionRow) => (
              <span className={styles.titleCell}>
                <span className={styles.cellStrong}>{r.assignmentTitle}</span>
                <span className={styles.cellMeta}>{r.courseTitle}</span>
              </span>
            ),
          },
        ]
      : []),
    {
      key: 'submitted',
      header: mode === 'queue' ? 'Submitted' : 'Submission',
      width: mode === 'queue' ? '150px' : '190px',
      mobile: 'detail',
      render: submittedCell,
    },
    ...(mode === 'queue'
      ? [
          {
            key: 'waiting',
            header: 'Waiting',
            width: '110px',
            mobile: 'detail' as const,
            render: (r: SubmissionRow) => (
              <span className={r.overdue ? styles.overdueText : undefined}>{r.submission ? waitingFor(r.submission.submittedAt, now) : '—'}</span>
            ),
          },
        ]
      : [
          {
            key: 'score',
            header: 'Score',
            width: '90px',
            align: 'end' as const,
            mobile: 'detail' as const,
            render: (r: SubmissionRow) => <span className="tabular">{scoreText(r.submission, r.maxScore)}</span>,
          },
        ]),
    { key: 'review', header: 'Review', width: '190px', mobile: 'status', render: (r) => <ReviewBadge submission={r.submission} overdue={r.overdue} /> },
    { key: 'action', header: 'Action', width: '110px', align: 'end', mobile: 'hidden', render: (r) => action(r) },
  ];

  const segments = [
    { value: 'to-review' as const, label: 'To review', count: data?.counts['to-review'] },
    { value: 'graded' as const, label: 'Graded', count: data?.counts.graded },
    { value: 'returned' as const, label: 'Returned', count: data?.counts.returned },
    ...(mode === 'assignment' ? [{ value: 'missing' as const, label: 'Not submitted', count: data?.counts.missing }] : []),
    { value: 'all' as const, label: 'All', count: data?.counts.all },
  ];
  const filtered = Boolean(search || courseId);
  const pageCount = data ? Math.max(1, Math.ceil(data.total / PAGE_SIZE)) : 1;
  const missingIds = filter === 'missing' ? rows.filter((r) => !reminded.has(r.student.id)).map((r) => r.student.id) : [];

  const emptyState = () => {
    if (filtered)
      return (
        <StateMessage
          icon={<MagnifyingGlass size={26} />}
          title="No learners match"
          actions={<Button onClick={() => update({ q: undefined, course: undefined })}>Clear search</Button>}
        >
          Try another name or email{mode === 'queue' ? ', or all courses' : ''}.
        </StateMessage>
      );
    if (assignment?.status === 'draft')
      return (
        <StateMessage icon={<Tray size={26} />} title="No submissions yet">
          Learners can hand in work once the assignment is published.
        </StateMessage>
      );
    if (filter === 'to-review')
      return (
        <StateMessage icon={<CheckCircle size={26} />} title="All caught up">
          {mode === 'queue'
            ? 'Nothing is waiting for review in your courses. New submissions appear here oldest first.'
            : 'Every submission for this assignment has been reviewed.'}
        </StateMessage>
      );
    if (filter === 'missing')
      return (
        <StateMessage icon={<CheckCircle size={26} />} title="Everyone has handed in">
          Every learner who finished this chapter has submitted the assignment.
        </StateMessage>
      );
    return (
      <StateMessage
        icon={<Tray size={26} />}
        title={filter === 'returned' ? 'No resubmissions requested' : filter === 'graded' ? 'Nothing graded yet' : 'No submissions yet'}
      >
        {filter === 'all' ? 'Submissions appear here as learners hand in their work.' : 'Submissions move here once they’re reviewed.'}
      </StateMessage>
    );
  };

  return (
    <div className={styles.submissions}>
      <div className={styles.controls}>
        <SegmentedControl<SubmissionFilter> label="Submissions" value={filter} onChange={(v) => update({ filter: v })} segments={segments} />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search students" aria-label="Search students" />
          </div>
          {mode === 'queue' && (
            <Field label="Course" hideLabel className={styles.filter}>
              <Select value={courseId} onChange={(e) => update({ course: e.target.value })}>
                <option value="">All courses</option>
                {courses.data?.rows
                  .filter((c) => c.status !== 'draft')
                  .map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.title}
                    </option>
                  ))}
              </Select>
            </Field>
          )}
          {filter !== 'missing' && (
            <Field label="Sort" hideLabel className={styles.sort}>
              <Select value={sort} onChange={(e) => update({ sort: e.target.value })}>
                <option value="oldest">Oldest first</option>
                <option value="newest">Newest first</option>
                <option value="score">Highest score</option>
              </Select>
            </Field>
          )}
          {filter === 'missing' && missingIds.length > 0 && (
            <Button iconStart={<BellRinging size={16} />} loading={reminding === 'all'} onClick={() => remind(missingIds, 'all')}>
              Remind {missingIds.length === 1 ? 'this learner' : `these ${missingIds.length}`}
            </Button>
          )}
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Submissions didn’t load"
          actions={
            <Button variant="primary" onClick={() => list.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : data && rows.length === 0 ? (
        emptyState()
      ) : isMobile ? (
        <ul className={styles.cards} aria-label={mode === 'queue' ? 'Submissions to review' : 'Submissions'} aria-busy={!data || undefined}>
          {!data
            ? Array.from({ length: 4 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <Skeleton width="60%" height={12} />
                  <Skeleton width="40%" height={8} />
                  <Skeleton width="100%" height={34} radius="var(--r-sm)" />
                </li>
              ))
            : rows.map((r) => (
                <li key={r.id} className={styles.card}>
                  <div className={styles.cardHead}>
                    <span className={styles.person}>
                      <Avatar name={r.student.name} size={32} />
                      <span className={styles.personText}>
                        <span className={styles.personName}>{r.student.name}</span>
                        <span className={styles.personMeta}>{mode === 'queue' ? r.assignmentTitle : r.student.email}</span>
                      </span>
                    </span>
                  </div>
                  <div className={styles.cardFacts}>
                    <ReviewBadge submission={r.submission} overdue={r.overdue} />
                    {r.submission && (
                      <span>
                        {mode === 'queue'
                          ? `Waiting ${waitingFor(r.submission.submittedAt, now)}`
                          : `Submitted ${formatRelative(r.submission.submittedAt, now)}`}
                        {r.submission.late ? ' · late' : ''}
                      </span>
                    )}
                    {r.submission?.review.status === 'graded' && <span className="tabular">{scoreText(r.submission, r.maxScore)}</span>}
                  </div>
                  <div className={styles.cardAction}>{action(r, true)}</div>
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label={mode === 'queue' ? 'Submissions to review' : 'Submissions'}
            rows={rows}
            columns={columns}
            rowKey={(r) => r.id}
            rowLabel={(r) => r.student.name}
            loading={!data}
            skeletonRows={6}
          />
        </div>
      )}

      {data && data.total > PAGE_SIZE && (
        <Pagination
          page={page}
          pageCount={pageCount}
          onChange={(p) => update({ page: String(p) }, true)}
          summary={`${((page - 1) * PAGE_SIZE + 1).toLocaleString('en-IN')}–${Math.min(page * PAGE_SIZE, data.total).toLocaleString('en-IN')} of ${plural(data.total, 'learner')}`}
        />
      )}
    </div>
  );
}
