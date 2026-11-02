import { useEffect, useRef, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Check, UserPlus, X } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { formatDate } from '@/lib/format';
import { Avatar } from '@/components/ui/Avatar/Avatar';
import { Button } from '@/components/ui/Button/Button';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, type InstructorRequest } from '@/services';
import styles from './Instructors.module.css';

/**
 * Pending instructor applications (docs/16 §2.5): people who applied to teach and wait for a decision. Approving makes
 * them active staff who can sign in; rejecting keeps them out. What they told us is shown here, so it can be weighed. Shown only to an admin who may
 * manage instructors, and only while a request is waiting. `?tab=requests` (the admin's notification) brings it into view.
 */
export function InstructorRequests({ onDecided }: { onDecided: () => void }) {
  const { can } = usePermissions();
  const toast = useToast();
  const [params] = useSearchParams();
  const ref = useRef<HTMLElement>(null);
  const allowed = can('instructors.manage');
  const list = useAsync('instructor-requests', () => (allowed ? services.instructors.requests() : Promise.resolve([])));
  const [busy, setBusy] = useState<string | null>(null);
  const [rejecting, setRejecting] = useState<InstructorRequest | null>(null);
  const requests = list.data ?? [];

  useEffect(() => {
    if (params.get('tab') === 'requests' && requests.length) ref.current?.scrollIntoView({ block: 'start' });
  }, [params, requests.length]);

  if (!allowed || requests.length === 0) return null;

  const decide = async (r: InstructorRequest, approve: boolean) => {
    setBusy(r.id);
    try {
      if (approve) await services.instructors.approveRequest(r.id);
      else await services.instructors.rejectRequest(r.id);
      toast({
        kind: 'success',
        title: approve ? `${r.name} is now an instructor` : `${r.name}’s application was rejected`,
        text: approve ? 'They can sign in with the email and password they registered with.' : 'They have been told by email.',
      });
      await list.run();
      onDecided();
    } catch (e) {
      toast({ kind: 'error', title: approve ? 'The application wasn’t approved' : 'The application wasn’t rejected', text: (e as Error).message });
    } finally {
      setBusy(null);
    }
  };

  return (
    <section ref={ref} className={styles.requests} aria-labelledby="instructor-requests-title">
      <h2 id="instructor-requests-title" className={styles.requestsTitle}>
        <UserPlus size={18} /> Pending instructor applications <span className={styles.requestsCount}>{requests.length}</span>
      </h2>
      <ul className={styles.requestList}>
        {requests.map((r) => (
          <li key={r.id} className={styles.requestRow}>
            <span className={styles.person}>
              <Avatar name={r.name} size={36} />
              <span className={styles.personText}>
                <span className={styles.personName}>{r.name}</span>
                <span className={styles.personMeta}>
                  {r.email}
                  {r.phone ? ` · ${r.phone}` : ''} · Applied {formatDate(r.requestedAt)}
                </span>
                <span className={styles.personMeta}>
                  {r.title}
                  {r.yearsTeaching !== undefined ? ` · ${r.yearsTeaching} years teaching` : ''}
                  {r.expertise?.length ? ` · ${r.expertise.join(', ')}` : ''}
                </span>
                {r.bio && <span className={styles.personMeta}>{r.bio}</span>}
                {r.links?.map((link) => (
                  <a key={link} className={styles.personMeta} href={link} target="_blank" rel="noopener noreferrer">
                    {link}
                  </a>
                ))}
              </span>
            </span>
            <span className={styles.requestActions}>
              <Button size="sm" variant="primary" iconStart={<Check size={15} />} disabled={busy !== null} onClick={() => decide(r, true)}>
                Approve
              </Button>
              <Button size="sm" iconStart={<X size={15} />} disabled={busy !== null} onClick={() => setRejecting(r)}>
                Reject
              </Button>
            </span>
          </li>
        ))}
      </ul>
      <ConfirmDialog
        open={rejecting !== null}
        title={`Reject ${rejecting?.name ?? 'this application'}?`}
        description="They will not be able to sign in as an instructor. They are told by email."
        confirmLabel="Reject application"
        tone="danger"
        onClose={() => setRejecting(null)}
        onConfirm={async () => {
          if (rejecting) await decide(rejecting, false);
          setRejecting(null);
        }}
      />
    </section>
  );
}
