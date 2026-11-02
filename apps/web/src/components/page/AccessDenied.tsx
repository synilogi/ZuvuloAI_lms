import { Lock } from '@phosphor-icons/react';
import type { PermissionKey } from '@syniastrolms/domain';
import { PERMISSIONS } from '@syniastrolms/domain';
import { LinkButton } from '@/components/ui/Button/Button';
import { StateMessage } from '@/components/ui/Feedback/Feedback';

/**
 * A page this account may not open. It says which permission is missing, in the catalogue's own
 * words, so the person can ask for the right thing — and it is a dead end, not a redirect, so a
 * deep link never bounces anywhere unexpected.
 */
export function AccessDenied({ permission }: { permission?: PermissionKey }) {
  const meta = permission ? PERMISSIONS[permission] : undefined;
  return (
    <StateMessage
      kind="error"
      icon={<Lock size={26} />}
      title="You don’t have access to this"
      actions={
        <LinkButton to="/admin" variant="primary">
          Back to the dashboard
        </LinkButton>
      }
    >
      {meta ? `This page needs the “${meta.label}” permission. Ask a super admin to grant it.` : 'Ask a super admin if you need it.'}
    </StateMessage>
  );
}
