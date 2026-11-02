import { useEffect, useState } from 'react';
import { Warning } from '@phosphor-icons/react';
import type { PermissionKey } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { services, type PlatformPermissionState, type PlatformUserRow } from '@/services';
import { grantedInGroup, isActive } from './platformMeta';
import styles from './Platform.module.css';

/**
 * What one academy admin may do. Every key, what it means and whether they hold it comes from the
 * API, which builds it from the catalogue in `packages/domain` — there is no second list here.
 *
 * One key at a time: each toggle is its own request, and the answer is the whole state as it now
 * stands, so the checkboxes always show what the database holds rather than what was hoped for.
 */
export function PermissionsDialog({ admin, onClose }: { admin: PlatformUserRow | null; onClose: () => void }) {
  const [state, setState] = useState<PlatformPermissionState | null>(null);
  const [saving, setSaving] = useState<PermissionKey | null>(null);
  const [failure, setFailure] = useState<string>();

  const load = useAsync(`platform:permissions:${admin?.id ?? 'none'}`, async () => (admin ? services.platform.adminPermissions(admin.id) : null), {
    immediate: Boolean(admin),
  });

  useEffect(() => {
    if (load.data) setState(load.data);
  }, [load.data]);

  useEffect(() => {
    if (admin) {
      setFailure(undefined);
      setSaving(null);
    } else {
      setState(null);
    }
  }, [admin]);

  const toggle = async (key: PermissionKey, next: boolean) => {
    if (!admin || saving) return;
    setSaving(key);
    setFailure(undefined);
    try {
      // The response is the source of truth for what changed — nothing is assumed.
      setState(next ? await services.platform.grantPermission(admin.id, key) : await services.platform.revokePermission(admin.id, key));
    } catch (err) {
      setFailure(err instanceof Error ? err.message : 'The change could not be saved.');
    } finally {
      setSaving(null);
    }
  };

  const groups = state?.groups ?? [];

  return (
    <Modal
      open={Boolean(admin)}
      onClose={onClose}
      width={620}
      title={admin ? `What ${admin.name} may do` : 'Permissions'}
      description="Each one takes effect immediately, on the session they already have."
      footer={<Button onClick={onClose}>Close</Button>}
    >
      {admin && !isActive(admin) && (
        <InlineMessage kind="warn" title="This account is deactivated">
          They cannot sign in until it is reactivated. Their permissions are kept as they are and can still be changed here.
        </InlineMessage>
      )}

      {failure && (
        <InlineMessage kind="error" title="That change didn’t save">
          {failure}
        </InlineMessage>
      )}

      {load.status === 'error' && !state ? (
        <InlineMessage kind="error" title="Their permissions didn’t load" action={<Button onClick={() => load.run().catch(() => undefined)}>Try again</Button>}>
          {load.error?.message}
        </InlineMessage>
      ) : !state ? (
        <div className={styles.permissionGroups} aria-busy="true" aria-label="Loading permissions">
          {Array.from({ length: 4 }, (_, i) => (
            <Skeleton key={i} height={78} radius="var(--r-lg)" />
          ))}
        </div>
      ) : (
        <div className={styles.permissionGroups}>
          {state.unknown.length > 0 && (
            <InlineMessage kind="warn" title="Keys the platform no longer uses">
              {state.unknown.join(', ')} — kept on the account but granting nothing.
            </InlineMessage>
          )}

          {groups.map((group) => (
            <section key={group.group} className={styles.permissionGroup} aria-label={group.label}>
              <header className={styles.permissionGroupHead}>
                <h3 className={styles.permissionGroupTitle}>{group.label}</h3>
                <Badge size="sm" tone="neutral">
                  {grantedInGroup(group)} of {group.permissions.length}
                </Badge>
              </header>
              {group.permissions.map((permission) => (
                <div key={permission.key} className={styles.permissionRow}>
                  <Checkbox
                    label={permission.label}
                    checked={permission.granted}
                    disabled={saving !== null}
                    onChange={(e) => toggle(permission.key, e.target.checked)}
                  />
                  <p className={styles.permissionText}>{permission.description}</p>
                  <code className={styles.permissionKey}>{permission.key}</code>
                </div>
              ))}
            </section>
          ))}

          {state.granted.length === 0 && (
            <InlineMessage kind="info" title="They hold nothing">
              <Warning size={14} aria-hidden="true" /> This admin can still reach the parts of the platform that are governed by role rather than by permission.
            </InlineMessage>
          )}
        </div>
      )}
    </Modal>
  );
}
