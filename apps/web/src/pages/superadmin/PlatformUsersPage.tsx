import { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { MagnifyingGlass, Users } from '@phosphor-icons/react';
import type { Role } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatRelative } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, SearchInput, Select } from '@/components/ui/Field/Field';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { services, type PlatformUserRow } from '@/services';
import { PAGE_SIZE, PLATFORM_EYEBROW, PlatformError, ROLE_LABEL, RoleBadge, pageCount, pageParam, rangeSummary } from './platformMeta';
import styles from './Platform.module.css';

const ROLE_OPTIONS: (Role | 'all')[] = ['all', 'student', 'instructor', 'admin', 'superadmin'];
const isRole = (value: string | null): value is Role => ROLE_OPTIONS.includes(value as Role) && value !== 'all';

/**
 * Every account on the installation, from `GET /superadmin/users`. The search and the role filter are
 * the API's own query parameters, and paging follows its envelope, so a filtered count is the real
 * count rather than the length of one page. Nothing on this screen changes a user.
 */
export default function PlatformUsersPage() {
  const now = useNow();
  const [params, setParams] = useSearchParams();
  const search = params.get('q') ?? '';
  const role = isRole(params.get('role')) ? (params.get('role') as Role) : undefined;
  const page = pageParam(params);

  // The field stays responsive while the request for the previous keystroke is still in flight.
  const [draft, setDraft] = useState(search);
  useEffect(() => setDraft(search), [search]);

  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [key, value] of Object.entries(next)) {
      if (!value || value === 'all') p.delete(key);
      else p.set(key, value);
    }
    // Any change to the filters starts again at the first page.
    if (!('page' in next)) p.delete('page');
    setParams(p, { replace: true });
  };

  useEffect(() => {
    if (draft === search) return;
    const id = setTimeout(() => update({ q: draft || undefined }), 250);
    return () => clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [draft]);

  const query = { page, pageSize: PAGE_SIZE, search: search || undefined, role };
  const list = useAsync(`platform:users:${JSON.stringify(query)}`, () => services.platform.listUsers(query));
  const data = list.data;
  const rows = data?.rows ?? [];
  const filtered = Boolean(search || role);

  const columns: Column<PlatformUserRow>[] = [
    {
      key: 'user',
      header: 'Account',
      mobile: 'primary',
      render: (row) => (
        <span className={styles.person}>
          <span className={styles.personName}>{row.name}</span>
          <span className={styles.personMeta}>{row.email}</span>
        </span>
      ),
    },
    { key: 'role', header: 'Role', width: '150px', mobile: 'status', render: (row) => <RoleBadge role={row.role} /> },
    { key: 'descriptor', header: 'Details', mobile: 'meta', render: (row) => row.descriptor || <span className={styles.none}>—</span> },
    { key: 'created', header: 'Joined', width: '150px', mobile: 'detail', render: (row) => formatRelative(row.createdAt, now) },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="All users"
        count={data ? data.total : undefined}
        description="Every account on the platform — students, instructors, admins and the platform team. Search by name or email, or filter by role."
      />

      <div className={styles.filters}>
        <Field label="Search" hideLabel className={styles.search}>
          <SearchInput value={draft} onValueChange={setDraft} placeholder="Search a name or an email address" />
        </Field>
        <Field label="Role" className={styles.roleFilter}>
          <Select value={role ?? 'all'} onChange={(e) => update({ role: e.target.value })}>
            {ROLE_OPTIONS.map((option) => (
              <option key={option} value={option}>
                {option === 'all' ? 'All roles' : ROLE_LABEL[option]}
              </option>
            ))}
          </Select>
        </Field>
      </div>

      {list.status === 'error' && !data ? (
        <PlatformError title="The user list didn’t load" error={list.error} onRetry={() => list.run().catch(() => undefined)} />
      ) : (
        <>
          <DataTable
            framed
            rows={rows}
            columns={columns}
            rowKey={(row) => row.id}
            label="All users"
            rowLabel={(row) => row.name}
            loading={list.status === 'loading' && !data}
            empty={
              <StateMessage
                kind="empty"
                icon={filtered ? <MagnifyingGlass size={26} /> : <Users size={26} />}
                title={filtered ? 'No account matches those filters' : 'No accounts yet'}
                compact
              >
                {filtered ? 'Try a shorter search, or a different role.' : undefined}
              </StateMessage>
            }
          />
          {data && data.total > PAGE_SIZE && (
            <Pagination
              page={page}
              pageCount={pageCount(data.total, data.pageSize)}
              onChange={(next) => update({ page: next > 1 ? String(next) : undefined })}
              summary={rangeSummary(data.total, data.page, data.pageSize)}
            />
          )}
        </>
      )}
    </div>
  );
}
