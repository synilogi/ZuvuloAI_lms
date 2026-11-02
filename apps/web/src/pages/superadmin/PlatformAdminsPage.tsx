import { useState } from 'react';
import { CaretDown, Plus, Power, ShieldCheck, UsersThree, PencilSimple } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { formatRelative } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { Menu } from '@/components/ui/Menu/Menu';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { StateMessage } from '@/components/ui/Feedback/Feedback';
import { Pagination } from '@/components/ui/Pagination/Pagination';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, type PlatformUserRow } from '@/services';
import { CreateAdminDialog, EditAdminDialog } from './AdminDialogs';
import { PermissionsDialog } from './PermissionsDialog';
import {
  PAGE_SIZE,
  PLATFORM_EYEBROW,
  PlatformError,
  RoleBadge,
  adminChanges,
  isActive,
  pageCount,
  rangeSummary,
  usePageParam,
  type AdminForm,
} from './platformMeta';
import styles from './Platform.module.css';

/**
 * Who runs the academy, and the only place an academy admin can be created — nothing else in the
 * application can make one. Renaming, moving to another address, closing an account and opening it
 * again are the whole of it: a role is never chosen here, and no account is ever deleted.
 */
export default function PlatformAdminsPage() {
  const now = useNow();
  const toast = useToast();
  const [page, goToPage] = usePageParam();

  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState<PlatformUserRow | null>(null);
  const [changingStatus, setChangingStatus] = useState<PlatformUserRow | null>(null);
  const [managing, setManaging] = useState<PlatformUserRow | null>(null);

  const list = useAsync(`platform:admins:${page}`, () => services.platform.listAdmins({ page, pageSize: PAGE_SIZE }));
  const data = list.data;
  const rows = data?.rows ?? [];
  const reload = () => list.run().catch(() => undefined);

  const create = async (form: AdminForm) => {
    const admin = await services.platform.createAdmin({
      name: form.name.trim(),
      email: form.email.trim().toLowerCase(),
      password: form.password,
    });
    setCreating(false);
    toast({
      kind: 'success',
      title: `${admin.name} can now sign in`,
      text: 'Share the password with them another way — it is not shown again.',
    });
    await reload();
  };

  const save = async (id: string, form: AdminForm) => {
    const original = editing;
    if (!original) return;
    const admin = await services.platform.updateAdmin(id, adminChanges(form, original));
    setEditing(null);
    toast({ kind: 'success', title: 'Admin updated', text: `${admin.name} · ${admin.email}` });
    await reload();
  };

  const changeStatus = async () => {
    const target = changingStatus;
    if (!target) return;
    const wasActive = isActive(target);
    const admin = wasActive ? await services.platform.deactivateAdmin(target.id) : await services.platform.reactivateAdmin(target.id);
    setChangingStatus(null);
    toast({
      kind: 'success',
      title: wasActive ? `${admin.name} can no longer sign in` : `${admin.name} can sign in again`,
      text: wasActive ? 'Their account is kept and can be reopened at any time.' : 'Their admin access is back as it was.',
    });
    await reload();
  };

  const columns: Column<PlatformUserRow>[] = [
    {
      key: 'admin',
      header: 'Admin',
      mobile: 'primary',
      render: (row) => (
        <span className={styles.person}>
          <span className={styles.personName}>{row.name}</span>
          <span className={styles.personMeta}>{row.email}</span>
        </span>
      ),
    },
    { key: 'role', header: 'Role', width: '140px', mobile: 'detail', render: (row) => <RoleBadge role={row.role} /> },
    {
      key: 'status',
      header: 'Status',
      width: '120px',
      mobile: 'status',
      render: (row) =>
        isActive(row) ? (
          <Badge size="sm" tone="accent" dot>
            Active
          </Badge>
        ) : (
          <Badge size="sm" tone="neutral" dot>
            Turned off
          </Badge>
        ),
    },
    { key: 'descriptor', header: 'Job title', mobile: 'detail', render: (row) => row.descriptor || <span className={styles.none}>—</span> },
    {
      key: 'created',
      header: 'Added',
      width: '160px',
      mobile: 'detail',
      render: (row) => (
        <span className={styles.person}>
          <span>{formatRelative(row.createdAt, now)}</span>
          {row.deactivatedAt && <span className={styles.personMeta}>Turned off {formatRelative(row.deactivatedAt, now)}</span>}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      width: '128px',
      align: 'end',
      mobile: 'detail',
      render: (row) => (
        <span className={styles.rowActions}>
          <Menu
            align="end"
            width={250}
            trigger={(props) => (
              <Button size="sm" iconEnd={<CaretDown size={12} />} aria-label={`Manage ${row.name}`} {...props}>
                Manage
              </Button>
            )}
            sections={[
              {
                items: [
                  { id: 'edit', label: 'Change name or email', icon: <PencilSimple size={16} />, onSelect: () => setEditing(row) },
                  { id: 'permissions', label: 'Choose what they can do', icon: <ShieldCheck size={16} />, onSelect: () => setManaging(row) },
                ],
              },
              {
                items: [
                  {
                    id: 'status',
                    label: isActive(row) ? 'Turn off their login' : 'Turn their login back on',
                    icon: <Power size={16} />,
                    tone: isActive(row) ? ('danger' as const) : ('default' as const),
                    onSelect: () => setChangingStatus(row),
                  },
                ],
              },
            ]}
          />
        </span>
      ),
    },
  ];

  const target = changingStatus;
  const deactivating = target ? isActive(target) : false;

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Admin users"
        count={data ? data.total : undefined}
        description="Staff accounts for the workspace. Each works at /admin, as far as its permissions reach. Use Manage to change details, permissions or access."
        actions={
          <Button variant="primary" iconStart={<Plus size={16} />} onClick={() => setCreating(true)}>
            Add admin
          </Button>
        }
      />

      {list.status === 'error' && !data ? (
        <PlatformError title="The admin list didn’t load" error={list.error} onRetry={reload} />
      ) : (
        <>
          <DataTable
            framed
            rows={rows}
            columns={columns}
            rowKey={(row) => row.id}
            label="Admin logins"
            rowLabel={(row) => row.name}
            loading={list.status === 'loading' && !data}
            empty={
              <StateMessage
                kind="empty"
                icon={<UsersThree size={26} />}
                title="No admin logins yet"
                compact
                actions={
                  <Button variant="primary" iconStart={<Plus size={16} />} onClick={() => setCreating(true)}>
                    Add the first admin
                  </Button>
                }
              />
            }
          />
          {data && data.total > PAGE_SIZE && (
            <Pagination
              page={page}
              pageCount={pageCount(data.total, data.pageSize)}
              onChange={goToPage}
              summary={rangeSummary(data.total, data.page, data.pageSize)}
            />
          )}
        </>
      )}

      <PermissionsDialog admin={managing} onClose={() => setManaging(null)} />
      <CreateAdminDialog open={creating} onClose={() => setCreating(false)} onCreate={create} />
      <EditAdminDialog admin={editing} onClose={() => setEditing(null)} onSave={save} />
      <ConfirmDialog
        open={Boolean(target)}
        onClose={() => setChangingStatus(null)}
        onConfirm={changeStatus}
        tone={deactivating ? 'danger' : 'default'}
        icon={<Power size={20} />}
        title={deactivating ? `Deactivate ${target?.name}?` : `Reactivate ${target?.name}?`}
        description={target?.email}
        confirmLabel={deactivating ? 'Deactivate admin' : 'Reactivate admin'}
      >
        {deactivating
          ? 'They will not be able to sign in, and any session they have open ends. The account and everything they created are kept, and you can reopen it at any time.'
          : 'They will be able to sign in again and pick up the admin workspace where they left it.'}
      </ConfirmDialog>
    </div>
  );
}
