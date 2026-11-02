import { useState } from 'react';
import { Link, useMatch, useNavigate, useSearchParams } from 'react-router-dom';
import { ClipboardText, Copy, DotsThree, Eye, MagnifyingGlass, PencilSimple, Plus, Trash, Tray, WarningCircle } from '@phosphor-icons/react';
import type { AssignmentStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatCount, plural } from '@/lib/format';
import { Figure } from '@/components/data/KpiStrip';
import { PageHeader } from '@/components/page/PageHeader';
import { RouteTabs } from '@/components/page/RouteTabs';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Meter } from '@/components/lms/progress/Meters';
import { services, type AssignmentRow } from '@/services';
import { AssignmentStatusBadge, dueText, FORMATS } from './assignmentMeta';
import { SubmissionList } from './SubmissionList';
import styles from './Assignments.module.css';

export default function AssignmentsPage() {
  const { can } = usePermissions();
  const { base, instructorId, isTeaching } = useWorkspace();
  const onQueue = Boolean(useMatch(`${base}/assignments/review`));
  const summary = useAsync(`review-summary:${instructorId}:${onQueue}`, () => services.assignments.summary(instructorId));

  return (
    <div className={styles.page}>
      <PageHeader
        title="Assignments"
        description={
          isTeaching
            ? 'Work your students hand in. Write the task and how it’s marked, then mark what comes in under To mark — oldest first.'
            : 'Coursework across the platform. Write the brief and rubric, and keep reviews inside the 48-hour window.'
        }
        actions={
          can('assessment.edit') && (
            <LinkButton to={`${base}/assignments/new`} iconStart={<Plus size={16} />}>
              New assignment
            </LinkButton>
          )
        }
      />
      <RouteTabs
        label="Assignments"
        tabs={[
          { to: `${base}/assignments`, label: 'Assignments', icon: <ClipboardText size={16} />, end: true },
          { to: `${base}/assignments/review`, label: 'To mark', icon: <Tray size={16} />, count: summary.data?.toReview },
        ]}
      />
      {onQueue ? <ReviewQueue summary={summary.data} /> : <AssignmentTable />}
    </div>
  );
}

function ReviewQueue({ summary }: { summary?: { toReview: number; overdue: number; byCourse: unknown[] } }) {
  return (
    <>
      <dl className={styles.figures} aria-busy={!summary || undefined}>
        <Figure label="to review" value={summary ? formatCount(summary.toReview) : '–'} />
        <Figure
          label="waiting more than 48 hours"
          value={summary ? <span className={summary.overdue ? styles.overdueText : undefined}>{formatCount(summary.overdue)}</span> : '–'}
        />
        <Figure label={summary?.byCourse.length === 1 ? 'course waiting' : 'courses waiting'} value={summary ? String(summary.byCourse.length) : '–'} />
      </dl>
      <SubmissionList mode="queue" />
    </>
  );
}

function AssignmentTable() {
  const { base, instructorId } = useWorkspace();
  const navigate = useNavigate();
  const toast = useToast();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const [deleting, setDeleting] = useState<AssignmentRow | null>(null);

  const search = params.get('q') ?? '';
  const courseId = params.get('course') ?? '';
  const status = (params.get('status') as AssignmentStatus | 'all' | null) ?? 'all';
  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all') p.delete(k);
      else p.set(k, v);
    }
    setParams(p, { replace: true });
  };

  const query = { search, courseId: courseId || undefined, status, scopeInstructorId: instructorId };
  const list = useAsync(`assignments:${JSON.stringify(query)}`, () => services.assignments.list(query));
  const courses = useAsync(`assignment-courses:${instructorId}`, () => services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }));
  const rows = list.data?.rows ?? [];
  const counts = list.data?.counts;
  const filtered = Boolean(search || courseId || status !== 'all');
  const to = (r: AssignmentRow, tab = '') => `${base}/assignments/${r.assignment.id}${tab}`;

  const duplicate = async (r: AssignmentRow) => {
    try {
      const copy = await services.assignments.duplicate(r.assignment.id);
      toast({
        kind: 'success',
        title: 'Assignment duplicated',
        text: `“${copy.title}” is a draft.`,
        action: { label: 'Open', onClick: () => navigate(`${base}/assignments/${copy.id}`) },
      });
      list.run().catch(() => undefined);
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t duplicate the assignment', text: (e as Error).message });
    }
  };

  const menu = (r: AssignmentRow) => (
    <Menu
      align="end"
      width={210}
      trigger={(props) => <IconButton {...props} size="sm" label={`More actions for ${r.assignment.title}`} icon={<DotsThree size={18} weight="bold" />} />}
      sections={[
        {
          items: [
            { id: 'edit', label: 'Edit', icon: <PencilSimple size={17} />, onSelect: () => navigate(to(r)) },
            { id: 'preview', label: 'Preview', icon: <Eye size={17} />, onSelect: () => navigate(to(r, '/preview')) },
            { id: 'submissions', label: 'Submissions', icon: <Tray size={17} />, onSelect: () => navigate(to(r, '/submissions')) },
            { id: 'duplicate', label: 'Duplicate', icon: <Copy size={17} />, onSelect: () => duplicate(r) },
          ],
        },
        {
          items: [
            r.assignment.lessonId
              ? { id: 'delete', label: 'Delete…', icon: <Trash size={17} />, disabled: true, hint: 'Delivered by a lesson' }
              : { id: 'delete', label: 'Delete…', icon: <Trash size={17} />, tone: 'danger', onSelect: () => setDeleting(r) },
          ],
        },
      ]}
    />
  );

  const reviewCell = (r: AssignmentRow) =>
    r.toReview ? (
      <Link to={to(r, '/submissions')} className={styles.reviewLink}>
        <span>
          <span className="tabular">{r.toReview}</span> to review
        </span>
        {r.overdue > 0 && (
          <span className={styles.overdueText}>
            <WarningCircle size={13} weight="bold" aria-hidden="true" /> {r.overdue} overdue
          </span>
        )}
      </Link>
    ) : (
      <span className={styles.muted}>{r.submitted ? 'All reviewed' : '—'}</span>
    );

  const columns: Column<AssignmentRow>[] = [
    {
      key: 'assignment',
      header: 'Assignment',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.titleCell}>
          <Link to={to(r)} className={styles.cellTitle}>
            {r.assignment.title}
          </Link>
          <span className={styles.cellMeta}>
            {r.courseTitle}
            {r.chapterTitle && ` · ${r.chapterTitle}`}
          </span>
        </span>
      ),
    },
    {
      key: 'format',
      header: 'Format',
      width: '170px',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.formatCell}>
          <span className={styles.formatLabel}>
            {FORMATS[r.assignment.format].icon(15)} {FORMATS[r.assignment.format].label}
          </span>
          <span className={styles.cellMeta}>{dueText(r.assignment.due, true)}</span>
        </span>
      ),
    },
    {
      key: 'submitted',
      header: 'Submitted',
      width: '120px',
      align: 'end',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.numberCell}>
          <span className="tabular">{r.assignment.status === 'draft' ? '—' : formatCount(r.submitted)}</span>
          {r.missing > 0 && <span className={styles.cellMeta}>{formatCount(r.missing)} not yet</span>}
        </span>
      ),
    },
    { key: 'review', header: 'Review', width: '150px', mobile: 'meta', render: reviewCell },
    {
      key: 'score',
      header: 'Average',
      width: '130px',
      mobile: 'detail',
      render: (r) =>
        r.avgScore === null ? (
          <span className={styles.muted}>No grades</span>
        ) : (
          <span className={styles.rateCell}>
            <Meter
              value={r.avgScore}
              size="sm"
              threshold={Math.round((r.assignment.passMark / r.assignment.maxScore) * 100)}
              label={`${r.assignment.title}: average ${r.avgScore}%`}
            />
            <span className="tabular">{r.avgScore}%</span>
          </span>
        ),
    },
    { key: 'status', header: 'Status', width: '104px', mobile: 'status', render: (r) => <AssignmentStatusBadge status={r.assignment.status} /> },
    {
      key: 'actions',
      header: 'Actions',
      width: '124px',
      align: 'end',
      mobile: 'hidden',
      render: (r) => (
        <span className={styles.rowActions}>
          {r.toReview > 0 ? (
            <LinkButton size="sm" to={to(r, '/submissions')}>
              Review
            </LinkButton>
          ) : (
            <IconButton size="sm" label={`Edit ${r.assignment.title}`} icon={<PencilSimple size={16} />} onClick={() => navigate(to(r))} />
          )}
          {menu(r)}
        </span>
      ),
    },
  ];

  return (
    <>
      <div className={styles.controls} hidden={counts?.all === 0 && !filtered}>
        <SegmentedControl<AssignmentStatus | 'all'>
          label="Assignment status"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: counts?.all },
            { value: 'published', label: 'Published', count: counts?.published },
            { value: 'draft', label: 'Drafts', count: counts?.draft },
            { value: 'closed', label: 'Closed', count: counts?.closed },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search assignments" aria-label="Search assignments" />
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
          title="Assignments didn’t load"
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
            title="No assignments match"
            actions={<Button onClick={() => setParams(new URLSearchParams(), { replace: true })}>Clear filters</Button>}
          >
            Try another title, course or status.
          </StateMessage>
        ) : (
          <StateMessage
            icon={<ClipboardText size={26} />}
            title="No assignments yet"
            actions={
              <LinkButton to={`${base}/assignments/new`} iconStart={<Plus size={16} />}>
                Write the first assignment
              </LinkButton>
            }
          >
            Assignments ask learners to apply a chapter to a real chart — a worksheet, an essay or a reading — and get feedback against a rubric.
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label="Assignments" aria-busy={!list.data || undefined}>
          {!list.data
            ? Array.from({ length: 4 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <Skeleton width="70%" height={12} />
                  <Skeleton width="50%" height={8} />
                </li>
              ))
            : rows.map((r) => (
                <li key={r.assignment.id} className={styles.card}>
                  <div className={styles.cardHead}>
                    <span className={styles.titleCell}>
                      <Link to={to(r)} className={styles.cellTitle}>
                        {r.assignment.title}
                      </Link>
                      <span className={styles.cellMeta}>{r.courseTitle}</span>
                    </span>
                    {menu(r)}
                  </div>
                  <div className={styles.cardFacts}>
                    <AssignmentStatusBadge status={r.assignment.status} />
                    <span>
                      {FORMATS[r.assignment.format].icon(14)} {FORMATS[r.assignment.format].label}
                    </span>
                    {r.assignment.status !== 'draft' && <span>{plural(r.submitted, 'submission')}</span>}
                    {r.overdue > 0 && <span className={styles.overdueText}>{r.overdue} overdue</span>}
                  </div>
                  {r.toReview > 0 && (
                    <div className={styles.cardAction}>
                      <LinkButton size="sm" variant="primary" to={to(r, '/submissions')}>
                        Review {r.toReview}
                      </LinkButton>
                    </div>
                  )}
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Assignments"
            rows={rows}
            columns={columns}
            rowKey={(r) => r.assignment.id}
            rowLabel={(r) => r.assignment.title}
            loading={!list.data}
            skeletonRows={6}
          />
        </div>
      )}

      {deleting && (
        <ConfirmDialog
          open
          onClose={() => setDeleting(null)}
          onConfirm={async () => {
            await services.assignments.remove(deleting.assignment.id);
            toast({ kind: 'success', title: 'Assignment deleted', text: deleting.assignment.title });
            setDeleting(null);
            list.run().catch(() => undefined);
          }}
          tone="danger"
          icon={<Trash size={20} />}
          title="Delete this assignment?"
          description={deleting.assignment.title}
          confirmLabel="Delete assignment"
          acknowledge={deleting.submitted ? `I understand ${plural(deleting.submitted, 'submission')} and their feedback will be deleted` : undefined}
        >
          <ul className={styles.impact}>
            <li>The brief, rubric and attachments are removed. This can’t be undone.</li>
            {deleting.submitted > 0 && <li>Grades already counted towards certificates stay counted; learners lose access to their feedback.</li>}
            {deleting.toReview > 0 && <li>{plural(deleting.toReview, 'submission')} waiting for review will never be reviewed.</li>}
          </ul>
        </ConfirmDialog>
      )}
    </>
  );
}
