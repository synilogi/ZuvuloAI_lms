import { Link, useLocation, useNavigate } from 'react-router-dom';
import { ArrowRight, Buildings, MagnifyingGlass, Plus } from '@phosphor-icons/react';
import { isAcademyStatus } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { SearchInput } from '@/components/ui/Field/Field';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, type PlatformAcademy } from '@/services';
import { PAGE_SIZE, PLATFORM_EYEBROW, PlatformError, pageCount, rangeSummary } from '../platformMeta';
import { useListParams } from '../subscriptions/subscriptionMeta';
import { ACADEMIES_BASE, AcademyStatusBadge, NEW_ACADEMY_PATH, PlanSummaryBadge } from './academyMeta';
import { NewAcademyDialog } from './NewAcademyDialog';
import platformStyles from '../Platform.module.css';
import styles from './Academies.module.css';

/**
 * Every academy on the platform — every customer — with its plan at a glance. A new customer starts here: a new
 * academy, empty, with its first admin. `/superadmin/academies/new` opens that form over the list.
 */
export default function AcademiesPage() {
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const toast = useToast();
  const { params, update, reset, page } = useListParams();
  const search = params.get('q') ?? '';
  const statusParam = params.get('status');
  const status = isAcademyStatus(statusParam) ? statusParam : undefined;
  const creating = pathname === NEW_ACADEMY_PATH;

  const list = useAsync(`platform:academies:${search}:${status ?? 'all'}:${page}`, () =>
    services.platform.listAcademies({ search, status, page, pageSize: PAGE_SIZE }),
  );
  const data = list.data;
  const reload = () => list.run().catch(() => undefined);
  const openNew = () => navigate({ pathname: NEW_ACADEMY_PATH, search: params.toString() });
  const closeNew = () => navigate({ pathname: ACADEMIES_BASE, search: params.toString() }, { replace: true });

  const columns: Column<PlatformAcademy>[] = [
    {
      // The customer is the Admin (D26); their LMS's internal workspace is secondary.
      key: 'client',
      header: 'Admin',
      mobile: 'primary',
      render: (a) => (
        <span className={styles.name}>
          <span className={styles.nameLine}>{a.owner?.name ?? 'No admin recorded'}</span>
          {a.owner && <span className={styles.slug}>{a.owner.email}</span>}
        </span>
      ),
    },
    {
      key: 'name',
      header: 'Their LMS',
      mobile: 'meta',
      render: (a) => (
        <span className={styles.name}>
          <span className={styles.nameLine}>
            <Link to={`${ACADEMIES_BASE}/${a.id}`} className={styles.nameLink}>
              {a.name}
            </Link>
            {a.isDefault && (
              <Badge size="sm" tone="warn">
                Demo LMS
              </Badge>
            )}
          </span>
          <span className={styles.slug}>{a.slug}</span>
        </span>
      ),
    },
    { key: 'status', header: 'Status', width: '120px', mobile: 'status', render: (a) => <AcademyStatusBadge status={a.status} /> },
    { key: 'plan', header: 'Plan', width: '240px', mobile: 'meta', render: (a) => <PlanSummaryBadge subscription={a.subscription} /> },
    {
      key: 'learners',
      header: 'Students',
      width: '100px',
      align: 'end',
      mobile: 'detail',
      render: (a) => <span className={styles.number}>{a.learners.toLocaleString('en-IN')}</span>,
    },
    {
      key: 'courses',
      header: 'Courses',
      width: '100px',
      align: 'end',
      mobile: 'detail',
      render: (a) => <span className={styles.number}>{a.courses.toLocaleString('en-IN')}</span>,
    },
    { key: 'created', header: 'Joined', width: '120px', mobile: 'detail', render: (a) => formatDate(a.createdAt) },
    {
      key: 'manage',
      header: 'Actions',
      width: '110px',
      align: 'end',
      mobile: 'detail',
      render: (a) => (
        <LinkButton to={`${ACADEMIES_BASE}/${a.id}`} size="sm" iconEnd={<ArrowRight size={14} />} aria-label={`Manage ${a.name}`}>
          Manage
        </LinkButton>
      ),
    },
  ];

  return (
    <div className={platformStyles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Admins"
        count={data ? data.total : undefined}
        description="Your customers. Each Admin runs their own LMS, with its own students, courses and billing kept separate from everyone else’s. Admins can sign up on the website, or you can add one here. Open one to manage its plan or pause its access."
        actions={
          <Button variant="primary" iconStart={<Plus size={16} />} onClick={openNew}>
            New admin
          </Button>
        }
      />

      <div className={styles.toolbar}>
        <SegmentedControl
          label="Show"
          value={status ?? 'all'}
          onChange={(v) => update({ status: v === 'all' ? undefined : v })}
          segments={[
            { value: 'all', label: 'All' },
            { value: 'active', label: 'Active' },
            { value: 'suspended', label: 'Suspended' },
            { value: 'archived', label: 'Closed' },
          ]}
        />
        <div className={styles.search}>
          <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search admin, LMS name or address" aria-label="Search admins" />
        </div>
      </div>

      {list.status === 'error' && !data ? (
        <PlatformError title="Admins didn’t load" error={list.error} onRetry={reload} />
      ) : data && data.rows.length === 0 && (search || status) ? (
        <StateMessage icon={<MagnifyingGlass size={26} />} title="No admins match" actions={<Button onClick={reset}>Show every Admin</Button>}>
          {search ? 'Try part of the admin’s name or email, or their LMS name or address.' : 'No Admin is in this state right now.'}
        </StateMessage>
      ) : (
        <>
          <DataTable
            framed
            label="Admins"
            rows={data?.rows ?? []}
            columns={columns}
            rowKey={(a) => a.id}
            rowLabel={(a) => a.name}
            loading={!data}
            skeletonRows={6}
            empty={
              <StateMessage
                icon={<Buildings size={26} />}
                title="No admins yet"
                compact
                actions={
                  <Button variant="primary" iconStart={<Plus size={16} />} onClick={openNew}>
                    Create the first admin
                  </Button>
                }
              >
                Each Admin gets an LMS of their own. It starts empty, and they choose a plan when they first sign in.
              </StateMessage>
            }
          />
          {data && data.total > data.pageSize && (
            <Pagination
              page={page}
              pageCount={pageCount(data.total, data.pageSize)}
              onChange={(next) => update({ page: next > 1 ? String(next) : undefined }, true)}
              summary={rangeSummary(data.total, data.page, data.pageSize)}
            />
          )}
        </>
      )}

      <NewAcademyDialog
        open={creating}
        onClose={closeNew}
        onCreated={(academy, password) => {
          toast({ kind: 'success', title: `${academy.name} is ready`, text: 'Share the sign-in details with its admin.' });
          // The password goes to the academy's page in navigation state only — shown once there, never stored.
          navigate(`${ACADEMIES_BASE}/${academy.id}`, { state: { created: { email: academy.owner?.email, password } } });
        }}
      />
    </div>
  );
}
