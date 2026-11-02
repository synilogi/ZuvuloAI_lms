import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { ChatText, DotsThree, EnvelopeSimple, LinkSimple, MagnifyingGlass, Prohibit, UserCircle, UserPlus, Users, X } from '@phosphor-icons/react';
import type { StudentStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { useWorkspace } from '@/hooks/useWorkspace';
import { formatDate, formatRelative, plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Meter } from '@/components/lms/progress/Meters';
import { services, type StudentRow, type StudentSort } from '@/services';
import { AddStudentDialog, EnrollDialog, signUpLink, MessageDialog, StudentStatusBadge } from './studentMeta';
import { InviteLearnersDialog } from './InviteLearnersDialog';
import styles from './Students.module.css';

const PAGE_SIZE = 25;

export default function StudentsPage() {
  const { can } = usePermissions();
  const { base, instructorId, isTeaching } = useWorkspace();
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [messaging, setMessaging] = useState<{ id: string; name: string }[] | null>(null);
  const [enrolling, setEnrolling] = useState<StudentRow | null>(null);
  const [suspending, setSuspending] = useState<StudentRow | null>(null);

  const search = params.get('q') ?? '';
  const courseId = params.get('course') ?? '';
  const status = (params.get('status') as StudentStatus | 'all' | null) ?? 'all';
  const sort = (params.get('sort') as StudentSort | null) ?? 'recent';
  const page = Math.max(1, Number(params.get('page')) || 1);
  const update = (next: Record<string, string | undefined>, keepPage = false) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all' || (k === 'sort' && v === 'recent')) p.delete(k);
      else p.set(k, v);
    }
    if (!keepPage) p.delete('page');
    setParams(p, { replace: true });
    setSelected(new Set());
  };

  // `?add=1` opens the Add student dialog (SAAS-028) — where the plan-aware action links to.
  const adding = !isTeaching && params.get('add') === '1';
  // `?invite=1` opens Invite learners: one-time links for single learners, made by an admin who can enrol learners.
  const inviting = !isTeaching && can('learners.enroll') && params.get('invite') === '1';
  const copyJoinLink = async () => {
    try {
      await navigator.clipboard.writeText(signUpLink());
      toast({ kind: 'success', title: 'Sign-up link copied', text: 'Share it with learners — they create their account on the platform.' });
    } catch {
      toast({ kind: 'error', title: 'Couldn’t copy the link', text: signUpLink() });
    }
  };

  const query = { search, courseId: courseId || undefined, status, sort, scopeInstructorId: instructorId, page, pageSize: PAGE_SIZE };
  const list = useAsync(`students:${JSON.stringify(query)}`, () => services.students.list(query));
  const courses = useAsync(`student-courses:${instructorId}`, () => services.courses.list({ scopeInstructorId: instructorId, page: 1, pageSize: 100 }));
  const data = list.data;
  const rows = data?.rows ?? [];
  const filtered = Boolean(search || courseId || status !== 'all');
  const profileTo = (r: StudentRow) => `${base}/students/${r.student.id}`;
  const noun = 'student';

  const menu = (r: StudentRow) => (
    <Menu
      align="end"
      width={210}
      trigger={(props) => <IconButton {...props} size="sm" label={`More actions for ${r.student.name}`} icon={<DotsThree size={18} weight="bold" />} />}
      sections={[
        {
          items: [
            { id: 'profile', label: 'View profile', icon: <UserCircle size={17} />, onSelect: () => navigate(profileTo(r)) },
            {
              id: 'message',
              label: 'Send a message',
              icon: <ChatText size={17} />,
              onSelect: () => setMessaging([{ id: r.student.id, name: r.student.name }]),
            },
            ...(isTeaching || !can('learners.enroll')
              ? []
              : [{ id: 'enroll', label: 'Enroll in a course', icon: <UserPlus size={17} />, onSelect: () => setEnrolling(r) }]),
          ],
        },
        ...(isTeaching
          ? []
          : [
              {
                items: [
                  r.status === 'suspended'
                    ? { id: 'reactivate', label: 'Restore access', icon: <Prohibit size={17} />, onSelect: () => setSuspending(r) }
                    : { id: 'suspend', label: 'Suspend access…', icon: <Prohibit size={17} />, tone: 'danger' as const, onSelect: () => setSuspending(r) },
                ],
              },
            ]),
      ]}
    />
  );

  const coursesCell = (r: StudentRow) =>
    r.courses.length === 0 ? (
      <span className={styles.muted}>No courses yet</span>
    ) : (
      <span className={styles.coursesCell} title={r.courses.map((c) => c.title).join('\n')}>
        <span className={styles.cellStrong}>{r.courses[0].title}</span>
        <span className={styles.cellMeta}>
          {r.courses.length > 1 ? `+ ${plural(r.courses.length - 1, 'more course')}` : r.courses[0].status === 'completed' ? 'Completed' : 'In progress'}
        </span>
      </span>
    );

  const columns: Column<StudentRow>[] = [
    {
      key: 'student',
      header: 'Student',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.person}>
          <Avatar name={r.student.name} size={34} />
          <span className={styles.personText}>
            <Link to={profileTo(r)} className={styles.personName}>
              {r.student.name}
            </Link>
            <span className={styles.personMeta}>{r.student.email}</span>
          </span>
        </span>
      ),
    },
    { key: 'courses', header: 'Courses', mobile: 'meta', render: coursesCell },
    {
      key: 'progress',
      header: 'Progress',
      width: '150px',
      mobile: 'detail',
      render: (r) =>
        r.courses.length ? (
          <span className={styles.rateCell}>
            <Meter value={r.progress} size="sm" label={`${r.student.name}: ${r.progress}% average progress`} />
            <span className="tabular">{r.progress}%</span>
          </span>
        ) : (
          <span className={styles.muted}>—</span>
        ),
    },
    {
      key: 'active',
      header: 'Last active',
      width: '130px',
      mobile: 'detail',
      render: (r) => (
        <time dateTime={r.student.lastActiveAt} title={formatDate(r.student.lastActiveAt)} className={styles.nowrap}>
          {formatRelative(r.student.lastActiveAt, now)}
        </time>
      ),
    },
    { key: 'status', header: 'Status', width: '120px', mobile: 'status', render: (r) => <StudentStatusBadge status={r.status} /> },
    {
      key: 'actions',
      header: 'Actions',
      width: '96px',
      align: 'end',
      mobile: 'hidden',
      render: (r) => (
        <span className={styles.rowActions}>
          <IconButton
            size="sm"
            label={`Message ${r.student.name}`}
            icon={<ChatText size={16} />}
            onClick={() => setMessaging([{ id: r.student.id, name: r.student.name }])}
          />
          {menu(r)}
        </span>
      ),
    },
  ];

  const counts = data?.counts;
  const pageCount = data ? Math.max(1, Math.ceil(data.total / PAGE_SIZE)) : 1;
  const selectedRows = rows.filter((r) => selected.has(r.student.id));

  return (
    <div className={styles.page}>
      <PageHeader
        title={isTeaching ? 'My students' : 'Students'}
        count={counts ? plural(counts.all, noun) : undefined}
        description={
          isTeaching
            ? 'Everyone in the courses you teach. See how far each one has got, and spot anyone who has gone quiet — a quick message can help them get back on track.'
            : 'Everyone learning on the platform. Find a student, see where they are in each course, and support the ones at risk.'
        }
        actions={
          !isTeaching && (
            <>
              <Button iconStart={<LinkSimple size={16} />} onClick={copyJoinLink}>
                Copy sign-up link
              </Button>
              {can('learners.enroll') && (
                <Button iconStart={<EnvelopeSimple size={16} />} onClick={() => update({ invite: '1' }, true)}>
                  Invite learners
                </Button>
              )}
              {can('learners.enroll') && (
                <LinkButton to={`${base}/students?add=1`} iconStart={<UserPlus size={16} />}>
                  Add student
                </LinkButton>
              )}
            </>
          )
        }
      />
      {!isTeaching && (
        <p className={styles.joinLine}>
          Learners can also sign up on their own at <a href={signUpLink()}>{signUpLink()}</a>.
        </p>
      )}
      {inviting && <InviteLearnersDialog open onClose={() => update({ invite: undefined }, true)} />}
      <AddStudentDialog open={adding} onClose={() => update({ add: undefined })} onAdded={() => list.run().catch(() => undefined)} />

      <div className={styles.controls} hidden={counts?.all === 0 && !filtered}>
        <SegmentedControl<StudentStatus | 'all'>
          label={`${noun} status`}
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: counts?.all },
            { value: 'active', label: 'Active', count: counts?.active },
            { value: 'at-risk', label: 'At risk', count: counts?.['at-risk'] },
            { value: 'inactive', label: 'Inactive', count: counts?.inactive },
            ...(isTeaching ? [] : [{ value: 'suspended' as const, label: 'Suspended', count: counts?.suspended }]),
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search by name, email or ID" aria-label={`Search ${noun}s`} />
          </div>
          <Field label="Course" hideLabel className={styles.filter}>
            <Select value={courseId} onChange={(e) => update({ course: e.target.value })}>
              <option value="">All courses</option>
              {courses.data?.rows
                .filter((c) => c.enrolledCount > 0)
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.title}
                  </option>
                ))}
            </Select>
          </Field>
          <Field label="Sort" hideLabel className={styles.sort}>
            <Select value={sort} onChange={(e) => update({ sort: e.target.value })}>
              <option value="recent">Recently active</option>
              <option value="name">Name A–Z</option>
              <option value="progress">Most progress</option>
              <option value="joined">Newest members</option>
            </Select>
          </Field>
        </div>
      </div>

      {selected.size > 0 && !isMobile && (
        <div className={styles.bulkBar} role="region" aria-label="Selected learners">
          <span className={styles.bulkCount}>{plural(selected.size, 'selected', 'selected')}</span>
          <Button
            size="sm"
            variant="primary"
            iconStart={<ChatText size={15} />}
            onClick={() => setMessaging(selectedRows.map((r) => ({ id: r.student.id, name: r.student.name })))}
          >
            Message
          </Button>
          <Button size="sm" variant="ghost" iconStart={<X size={15} />} onClick={() => setSelected(new Set())}>
            Clear
          </Button>
        </div>
      )}

      {list.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title={`${isTeaching ? 'Your students' : 'Students'} didn’t load`}
          actions={
            <Button variant="primary" onClick={() => list.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : data && rows.length === 0 ? (
        filtered ? (
          <StateMessage
            icon={<MagnifyingGlass size={26} />}
            title={`No ${noun}s match`}
            actions={<Button onClick={() => update({ q: undefined, course: undefined, status: undefined })}>Clear filters</Button>}
          >
            {status === 'at-risk' && !search && !courseId
              ? 'Nobody is at risk right now — every learner with a course in progress has studied in the last 10 days.'
              : 'Try another name, email, course or status.'}
          </StateMessage>
        ) : (
          <StateMessage icon={<Users size={26} />} title={`No ${noun}s yet`}>
            {isTeaching
              ? 'Learners appear here as soon as they enroll in one of your courses.'
              : 'Add your first student, or share your join link — learners who sign up through it appear here.'}
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label={isTeaching ? 'My students' : 'Students'} aria-busy={!data || undefined}>
          {!data
            ? Array.from({ length: 5 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <Skeleton width="60%" height={12} />
                  <Skeleton width="80%" height={8} />
                </li>
              ))
            : rows.map((r) => (
                <li key={r.student.id} className={styles.card}>
                  <div className={styles.cardHead}>
                    <Link to={profileTo(r)} className={styles.person}>
                      <Avatar name={r.student.name} size={36} />
                      <span className={styles.personText}>
                        <span className={styles.personName}>{r.student.name}</span>
                        <span className={styles.personMeta}>{r.courses[0]?.title ?? 'No courses yet'}</span>
                      </span>
                    </Link>
                    {menu(r)}
                  </div>
                  {r.courses.length > 0 && <Meter value={r.progress} size="sm" label={`${r.student.name}: ${r.progress}% average progress`} />}
                  <div className={styles.cardFacts}>
                    <StudentStatusBadge status={r.status} />
                    {r.courses.length > 0 && <span className="tabular">{r.progress}%</span>}
                    {r.courses.length > 1 && <span>{plural(r.courses.length, 'course')}</span>}
                    <span>Active {formatRelative(r.student.lastActiveAt, now)}</span>
                  </div>
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label={isTeaching ? 'My students' : 'Students'}
            rows={rows}
            columns={columns}
            rowKey={(r) => r.student.id}
            rowLabel={(r) => r.student.name}
            loading={!data}
            skeletonRows={8}
            selectable
            selected={selected}
            onSelectedChange={setSelected}
          />
        </div>
      )}

      {data && data.total > PAGE_SIZE && (
        <Pagination
          page={page}
          pageCount={pageCount}
          onChange={(p) => update({ page: String(p) }, true)}
          summary={`${((page - 1) * PAGE_SIZE + 1).toLocaleString('en-IN')}–${Math.min(page * PAGE_SIZE, data.total).toLocaleString('en-IN')} of ${plural(data.total, noun)}`}
        />
      )}

      {messaging && <MessageDialog open onClose={() => setMessaging(null)} recipients={messaging} />}
      {enrolling && (
        <EnrollDialog
          open
          onClose={() => setEnrolling(null)}
          student={{ id: enrolling.student.id, name: enrolling.student.name }}
          enrolledCourseIds={enrolling.courses.map((c) => c.id)}
          onEnrolled={() => list.run().catch(() => undefined)}
        />
      )}
      {suspending && (
        <ConfirmDialog
          open
          onClose={() => setSuspending(null)}
          onConfirm={async () => {
            const restore = suspending.status === 'suspended';
            await services.students.setSuspended(suspending.student.id, !restore);
            toast({ kind: 'success', title: restore ? 'Access restored' : 'Access suspended', text: suspending.student.name });
            setSuspending(null);
            list.run().catch(() => undefined);
          }}
          tone={suspending.status === 'suspended' ? 'default' : 'danger'}
          icon={<Prohibit size={20} />}
          title={suspending.status === 'suspended' ? `Restore ${suspending.student.name}’s access?` : `Suspend ${suspending.student.name}?`}
          description={suspending.student.email}
          confirmLabel={suspending.status === 'suspended' ? 'Restore access' : 'Suspend access'}
          acknowledge={suspending.status === 'suspended' ? undefined : 'I’ve recorded the reason in the support ticket'}
        >
          <ul className={styles.impact}>
            {suspending.status === 'suspended' ? (
              <li>They can sign in and continue their courses where they left off.</li>
            ) : (
              <>
                <li>They can’t sign in or open lessons until access is restored.</li>
                <li>Progress, submissions and certificates are kept.</li>
                <li>Live class registrations are cancelled and the seats released.</li>
              </>
            )}
          </ul>
        </ConfirmDialog>
      )}
    </div>
  );
}
