import { useId, useState } from 'react';
import { Copy, EnvelopeSimple, LinkSimple } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, ServiceError, type InvitationRow, type InvitationStatus } from '@/services';
import type { Tone } from '@/design/tokens';
import styles from './Students.module.css';

/*
 * An Admin's learner invitations (`/invite/<token>`): a link for one learner, optionally bound to their email (and then
 * emailed to them too). The server keeps only the link's hash, so the link is shown once, here, to copy. It works once
 * and for seven days; a pending one can be withdrawn.
 */

const STATUS: Record<InvitationStatus, { label: string; tone: Tone }> = {
  pending: { label: 'Pending', tone: 'info' },
  accepted: { label: 'Accepted', tone: 'accent' },
  expired: { label: 'Expired', tone: 'neutral' },
  revoked: { label: 'Withdrawn', tone: 'neutral' },
};

export function InvitationStatusBadge({ status }: { status: InvitationStatus }) {
  return (
    <Badge size="sm" tone={STATUS[status].tone} dot={status === 'pending'}>
      {STATUS[status].label}
    </Badge>
  );
}

/** The link just made — the only time it is shown. */
export function CreatedInvitation({ url, email, onCopy }: { url: string; email: string | null; onCopy: () => void }) {
  const id = useId();
  return (
    <div className={styles.inviteCreated} role="status">
      <Field label="Invitation link" id={id} hint="It works once and expires in 7 days. Copy it now — it isn’t shown again.">
        <div className={styles.inviteLinkRow}>
          <Input id={id} value={url} readOnly onFocus={(e) => e.currentTarget.select()} />
          <Button iconStart={<Copy size={16} />} onClick={onCopy}>
            Copy
          </Button>
        </div>
      </Field>
      {email && <p className={styles.inviteNote}>We’ve also emailed it to {email}.</p>}
    </div>
  );
}

export function InvitationList({
  rows,
  withdrawing,
  onWithdraw,
}: {
  rows: InvitationRow[];
  withdrawing?: string | null;
  onWithdraw: (row: InvitationRow) => void;
}) {
  if (!rows.length) return <p className={styles.inviteNote}>No invitations yet. Links you create appear here, with whether they were used.</p>;
  return (
    <ul className={styles.inviteList} aria-label="Invitations">
      {rows.map((row) => (
        <li key={row.id} className={styles.inviteRow}>
          <span className={styles.inviteWho}>
            {row.email ? <EnvelopeSimple size={16} aria-hidden="true" /> : <LinkSimple size={16} aria-hidden="true" />}
            <span className={styles.personText}>
              <span className={styles.cellStrong}>{row.email ?? 'Link for one learner'}</span>
              <span className={styles.cellMeta}>
                {row.status === 'accepted' && row.usedAt
                  ? `Accepted ${formatDate(row.usedAt)}`
                  : row.status === 'pending'
                    ? `Expires ${formatDate(row.expiresAt)}`
                    : `Created ${formatDate(row.createdAt)}`}
              </span>
            </span>
          </span>
          <InvitationStatusBadge status={row.status} />
          {row.status === 'pending' && (
            <Button
              size="sm"
              variant="ghost"
              loading={withdrawing === row.id}
              onClick={() => onWithdraw(row)}
              aria-label={`Withdraw invitation ${row.email ?? ''}`.trim()}
            >
              Withdraw
            </Button>
          )}
        </li>
      ))}
    </ul>
  );
}

export function InviteLearnersDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const toast = useToast();
  const list = useAsync('invitations', () => services.invitations.list());
  const [email, setEmail] = useState('');
  const [attempt, setAttempt] = useState(false);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<{ field?: string; message: string } | null>(null);
  const [created, setCreated] = useState<{ url: string; email: string | null } | null>(null);
  const [withdrawing, setWithdrawing] = useState<string | null>(null);
  const emailIssue = email.trim() && !/^\S+@\S+\.\S+$/.test(email.trim()) ? 'Enter a valid email address, or leave it empty.' : undefined;

  const close = () => {
    setEmail('');
    setAttempt(false);
    setError(null);
    setCreated(null);
    onClose();
  };

  const create = async () => {
    setAttempt(true);
    setError(null);
    if (emailIssue) return;
    setCreating(true);
    try {
      const result = await services.invitations.create(email.trim() ? { email: email.trim() } : {});
      setCreated({ url: result.url, email: result.invitation.email });
      setEmail('');
      setAttempt(false);
      list.run().catch(() => undefined);
    } catch (e) {
      const issue = e instanceof ServiceError ? e.issues?.find((i) => i.field === 'email') : undefined;
      setError(issue ? { field: 'email', message: issue.message } : { message: (e as Error).message });
    } finally {
      setCreating(false);
    }
  };

  const copy = async () => {
    if (!created) return;
    try {
      await navigator.clipboard.writeText(created.url);
      toast({ kind: 'success', title: 'Invitation link copied', text: 'Send it to your learner — it works once.' });
    } catch {
      toast({ kind: 'error', title: 'Couldn’t copy the link', text: 'Select the link and copy it yourself.' });
    }
  };

  const withdraw = async (row: InvitationRow) => {
    setWithdrawing(row.id);
    try {
      await services.invitations.revoke(row.id);
      toast({
        kind: 'success',
        title: 'Invitation withdrawn',
        text: row.email ? `The link sent to ${row.email} no longer works.` : 'The link no longer works.',
      });
      await list.run().catch(() => undefined);
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t withdraw the invitation', text: (e as Error).message });
      list.run().catch(() => undefined);
    } finally {
      setWithdrawing(null);
    }
  };

  return (
    <Modal
      open={open}
      onClose={close}
      width={580}
      title="Invite learners"
      description="Create a link for one learner. They open it to create their account on the platform — no address to type."
    >
      <div className={styles.dialogForm}>
        {error && !error.field && (
          <InlineMessage kind="error" title="The invitation wasn’t created.">
            {error.message}
          </InlineMessage>
        )}
        <Field
          label="Learner’s email address"
          optional
          hint="Optional. With an address, only that person can use the link, and we email it to them."
          error={attempt ? (emailIssue ?? (error?.field === 'email' ? error.message : undefined)) : undefined}
        >
          <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="learner@example.com" autoComplete="off" />
        </Field>
        <Button variant="primary" iconStart={<LinkSimple size={16} />} loading={creating} onClick={create}>
          Create invitation link
        </Button>
        {created && <CreatedInvitation url={created.url} email={created.email} onCopy={copy} />}

        <section className={styles.inviteSection} aria-labelledby="invitations-heading">
          <h4 id="invitations-heading" className={styles.inviteHeading}>
            Invitations
          </h4>
          {list.status === 'error' && !list.data ? (
            <InlineMessage kind="error" title="Invitations didn’t load">
              {list.error.message}
            </InlineMessage>
          ) : !list.data ? (
            <div role="status" aria-label="Loading invitations">
              <Skeleton width="80%" height={12} />
              <Skeleton width="60%" height={12} />
            </div>
          ) : (
            <InvitationList rows={list.data} withdrawing={withdrawing} onWithdraw={withdraw} />
          )}
        </section>
      </div>
    </Modal>
  );
}
