import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { ChalkboardTeacher, DotsThree, EnvelopeSimple, MagnifyingGlass, PencilSimple, Plus, Power, UserCircle } from '@phosphor-icons/react';
import type { InstructorStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useViewport } from '@/hooks/useViewport';
import { formatCount, formatRelative, plural } from '@/lib/format';
import { useNow } from '@/hooks/useNow';
import { PageHeader } from '@/components/page/PageHeader';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Meter } from '@/components/lms/progress/Meters';
import { services, type InstructorRow, type InstructorSort } from '@/services';
import { Rating } from '@/components/lms/shared/Rating';
import { InstructorRequests } from './InstructorRequests';
import { InstructorStatusBadge } from './instructorMeta';
import styles from './Instructors.module.css';

export default function InstructorsPage() {
  const { can } = usePermissions();
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const [changing, setChanging] = useState<InstructorRow | null>(null);

  const search = params.get('q') ?? '';
  const status = (params.get('status') as InstructorStatus | 'all' | null) ?? 'all';
  const expertise = params.get('expertise') ?? '';
  const sort = (params.get('sort') as InstructorSort | null) ?? 'name';
  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [k, v] of Object.entries(next)) {
      if (!v || v === 'all' || (k === 'sort' && v === 'name')) p.delete(k);
      else p.set(k, v);
    }
    setParams(p, { replace: true });
  };

  const query = { search, status, expertise: expertise || undefined, sort };
  const list = useAsync(`instructors:${JSON.stringify(query)}`, () => services.instructors.list(query));
  const data = list.data;
  const rows = data?.rows ?? [];
  const filtered = Boolean(search || expertise || status !== 'all');
  const profileTo = (r: InstructorRow) => `/admin/instructors/${r.instructor.id}`;

  const resend = async (r: InstructorRow) => {
    try {
      const { sentTo } = await services.instructors.resendInvite(r.instructor.id);
      toast({ kind: 'success', title: 'Invitation sent again', text: sentTo });
    } catch (e) {
      toast({ kind: 'error', title: 'The invitation wasn’t sent', text: (e as Error).message });
    }
  };

  const menu = (r: InstructorRow) => (
    <Menu
      align="end"
      width={220}
      trigger={(props) => <IconButton {...props} size="sm" label={`More actions for ${r.instructor.name}`} icon={<DotsThree size={18} weight="bold" />} />}
      sections={[
        {
          items: [
            { id: 'profile', label: 'View profile', icon: <UserCircle size={17} />, onSelect: () => navigate(profileTo(r)) },
            ...(can('instructors.manage')
              ? [{ id: 'edit', label: 'Edit details', icon: <PencilSimple size={17} />, onSelect: () => navigate(`${profileTo(r)}/edit`) }]
              : []),
            ...(r.instructor.status === 'invited' && can('instructors.manage')
              ? [{ id: 'resend', label: 'Resend invitation', icon: <EnvelopeSimple size={17} />, onSelect: () => resend(r) }]
              : []),
          ],
        },
        {
          items: !can('instructors.status')
            ? []
            : [
                r.instructor.status === 'inactive'
                  ? { id: 'reactivate', label: 'Reactivate', icon: <Power size={17} />, onSelect: () => setChanging(r) }
                  : {
                      id: 'deactivate',
                      label: r.instructor.status === 'invited' ? 'Withdraw invitation…' : 'Deactivate…',
                      icon: <Power size={17} />,
                      tone: 'danger' as const,
                      onSelect: () => setChanging(r),
                    },
              ],
        },
      ]}
    />
  );

  const columns: Column<InstructorRow>[] = [
    {
      key: 'instructor',
      header: 'Instructor',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.person}>
          <Avatar name={r.instructor.name} size={36} />
          <span className={styles.personText}>
            <Link to={profileTo(r)} className={styles.personName}>
              {r.instructor.name}
            </Link>
            <span className={styles.personMeta}>{r.instructor.title}</span>
          </span>
        </span>
      ),
    },
    {
      key: 'expertise',
      header: 'Expertise',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.chips}>
          {r.instructor.expertise.slice(0, 2).map((x) => (
            <span key={x} className={styles.chip}>
              {x}
            </span>
          ))}
          {r.instructor.expertise.length > 2 && <span className={styles.more}>+{r.instructor.expertise.length - 2}</span>}
        </span>
      ),
    },
    {
      key: 'courses',
      header: 'Courses',
      width: '110px',
      mobile: 'meta',
      render: (r) => {
        const published = r.courses.filter((c) => c.status === 'published').length;
        return (
          <span className={styles.stack} title={r.courses.map((c) => c.title).join('\n')}>
            <span className="tabular">{r.courses.length ? plural(r.courses.length, 'course') : 'None yet'}</span>
            {r.courses.length > 0 && <span className={styles.cellMeta}>{published} published</span>}
          </span>
        );
      },
    },
    {
      key: 'students',
      header: 'Students',
      width: '100px',
      align: 'end',
      mobile: 'detail',
      render: (r) => <span className="tabular">{r.students ? formatCount(r.students) : '—'}</span>,
    },
    {
      key: 'performance',
      header: 'Performance',
      width: '170px',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.stack}>
          <Rating value={r.rating} count={r.ratingCount || undefined} />
          {r.completion !== null && (
            <span className={styles.rateCell}>
              <Meter value={r.completion} size="xs" label={`${r.instructor.name}: ${r.completion}% completion`} />
              <span className={styles.cellMeta}>{r.completion}% complete</span>
            </span>
          )}
        </span>
      ),
    },
    {
      key: 'reviews',
      header: 'Reviews',
      width: '110px',
      mobile: 'detail',
      render: (r) =>
        r.toReview ? (
          <span className={styles.stack}>
            <span className="tabular">{r.toReview} waiting</span>
            {r.overdue > 0 && <span className={styles.overdue}>{r.overdue} overdue</span>}
          </span>
        ) : (
          <span className={styles.muted}>Up to date</span>
        ),
    },
    { key: 'status', header: 'Status', width: '110px', mobile: 'status', render: (r) => <InstructorStatusBadge status={r.instructor.status} /> },
    {
      key: 'actions',
      header: 'Actions',
      width: '84px',
      align: 'end',
      mobile: 'hidden',
      render: (r) => (
        <span className={styles.rowActions}>
          {can('instructors.manage') && (
            <IconButton size="sm" label={`Edit ${r.instructor.name}`} icon={<PencilSimple size={16} />} onClick={() => navigate(`${profileTo(r)}/edit`)} />
          )}
          {menu(r)}
        </span>
      ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        title="Instructors"
        count={data ? plural(data.counts.all, 'instructor') : undefined}
        description="The acharyas and mentors who teach at ZuviloAI. See what each teaches, who they reach and how their courses are doing."
        actions={
          can('instructors.manage') && (
            <LinkButton to="/admin/instructors/new" iconStart={<Plus size={16} />}>
              Add instructor
            </LinkButton>
          )
        }
      />

      <InstructorRequests onDecided={() => list.run().catch(() => undefined)} />

      <div className={styles.controls} hidden={data?.counts.all === 0 && !filtered}>
        <SegmentedControl<InstructorStatus | 'all'>
          label="Instructor status"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: data?.counts.all },
            { value: 'active', label: 'Active', count: data?.counts.active },
            { value: 'invited', label: 'Invited', count: data?.counts.invited },
            { value: 'inactive', label: 'Inactive', count: data?.counts.inactive },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput
              value={search}
              onValueChange={(v) => update({ q: v })}
              placeholder="Search by name, title or expertise"
              aria-label="Search instructors"
            />
          </div>
          <Field label="Expertise" hideLabel className={styles.filter}>
            <Select value={expertise} onChange={(e) => update({ expertise: e.target.value })}>
              <option value="">All expertise</option>
              {data?.expertise.map((x) => (
                <option key={x} value={x}>
                  {x}
                </option>
              ))}
            </Select>
          </Field>
          <Field label="Sort" hideLabel className={styles.sort}>
            <Select value={sort} onChange={(e) => update({ sort: e.target.value })}>
              <option value="name">Name A–Z</option>
              <option value="students">Most students</option>
              <option value="rating">Highest rated</option>
              <option value="joined">Newest</option>
            </Select>
          </Field>
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <StateMessage
          kind="error"
          title="Instructors didn’t load"
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
            title="No instructors match"
            actions={<Button onClick={() => setParams(new URLSearchParams(), { replace: true })}>Clear filters</Button>}
          >
            Try another name, expertise or status.
          </StateMessage>
        ) : (
          <StateMessage
            icon={<ChalkboardTeacher size={26} />}
            title="No instructors yet"
            actions={
              <LinkButton to="/admin/instructors/new" iconStart={<Plus size={16} />}>
                Add the first instructor
              </LinkButton>
            }
          >
            Instructors build courses, run live classes and review submissions. Invite one to get started.
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label="Instructors" aria-busy={!data || undefined}>
          {!data
            ? Array.from({ length: 4 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <Skeleton width="60%" height={12} />
                  <Skeleton width="80%" height={8} />
                </li>
              ))
            : rows.map((r) => (
                <li key={r.instructor.id} className={styles.card}>
                  <div className={styles.cardHead}>
                    <Link to={profileTo(r)} className={styles.person}>
                      <Avatar name={r.instructor.name} size={40} />
                      <span className={styles.personText}>
                        <span className={styles.personName}>{r.instructor.name}</span>
                        <span className={styles.personMeta}>{r.instructor.title}</span>
                      </span>
                    </Link>
                    {menu(r)}
                  </div>
                  <span className={styles.chips}>
                    {r.instructor.expertise.slice(0, 3).map((x) => (
                      <span key={x} className={styles.chip}>
                        {x}
                      </span>
                    ))}
                  </span>
                  <div className={styles.cardFacts}>
                    <InstructorStatusBadge status={r.instructor.status} />
                    <Rating value={r.rating} />
                    <span>{plural(r.courses.length, 'course')}</span>
                    {r.students > 0 && <span>{formatCount(r.students)} students</span>}
                    {r.instructor.status === 'invited' && <span>Invited {formatRelative(r.instructor.joinedAt, now)}</span>}
                  </div>
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Instructors"
            rows={rows}
            columns={columns}
            rowKey={(r) => r.instructor.id}
            rowLabel={(r) => r.instructor.name}
            loading={!data}
            skeletonRows={6}
          />
        </div>
      )}

      {changing && (
        <StatusDialog
          row={changing}
          onClose={() => setChanging(null)}
          onDone={() => {
            setChanging(null);
            list.run().catch(() => undefined);
          }}
        />
      )}
    </div>
  );
}

/** Deactivate, withdraw an invitation, or reactivate. */
export function StatusDialog({ row, onClose, onDone }: { row: Pick<InstructorRow, 'instructor' | 'courses'>; onClose: () => void; onDone: () => void }) {
  const toast = useToast();
  const { instructor } = row;
  const reactivate = instructor.status === 'inactive';
  const invited = instructor.status === 'invited';
  return (
    <ConfirmDialog
      open
      onClose={onClose}
      onConfirm={async () => {
        await services.instructors.setStatus(instructor.id, reactivate ? 'active' : 'inactive');
        toast({
          kind: 'success',
          title: reactivate ? `${instructor.name} is active again` : invited ? 'Invitation withdrawn' : `${instructor.name} is deactivated`,
          text: instructor.email,
        });
        onDone();
      }}
      tone={reactivate ? 'default' : 'danger'}
      icon={<Power size={20} />}
      title={reactivate ? `Reactivate ${instructor.name}?` : invited ? `Withdraw ${instructor.name}’s invitation?` : `Deactivate ${instructor.name}?`}
      description={instructor.email}
      confirmLabel={reactivate ? 'Reactivate' : invited ? 'Withdraw invitation' : 'Deactivate'}
    >
      <ul className={styles.impact}>
        {reactivate ? (
          <li>They can sign in, edit their {plural(row.courses.length, 'course')} and review submissions again.</li>
        ) : invited ? (
          <li>The invitation link stops working. You can invite them again later.</li>
        ) : (
          <>
            <li>They can’t sign in, edit courses or review submissions.</li>
            <li>Their name stays on {plural(row.courses.length, 'course')} and on certificates they signed.</li>
            <li>Submissions waiting for their review stay in the queue for co-instructors and admins.</li>
          </>
        )}
      </ul>
    </ConfirmDialog>
  );
}
