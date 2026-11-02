import { useEffect, useState, type ReactNode } from 'react';
import { Archive, CheckCircle, LockSimpleOpen, PauseCircle, Prohibit } from '@phosphor-icons/react';
import { academyTransition, type AcademyAction, type AcademyStatus } from '@syniastrolms/domain';
import { SectionHeader } from '@/components/page/PageHeader';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Button } from '@/components/ui/Button/Button';
import { Field, Textarea } from '@/components/ui/Field/Field';
import { services, type PlatformAcademy } from '@/services';
import { AcademyStatusBadge } from './academyMeta';
import styles from './Academies.module.css';

/** The subscription states that still bill or give access: an LMS with one cannot be closed until it ends. */
const LIVE_SUBSCRIPTION = new Set(['trialing', 'active', 'past_due', 'paused', 'canceling']);

/** What each status means to the people inside the LMS, said plainly. */
const MEANING: Record<AcademyStatus, { title: string; text: string }> = {
  active: { title: 'Open', text: 'Its admins, instructors and students can sign in and use it as normal.' },
  suspended: { title: 'Paused', text: 'Nobody in this LMS can sign in. Everything in it is kept, and you can reactivate it at any time.' },
  archived: { title: 'Closed', text: 'Nobody in this LMS can sign in. Everything in it is kept, and you can reopen it if they come back.' },
};

interface ActionCopy {
  label: string;
  icon: ReactNode;
  variant: 'primary' | 'secondary' | 'danger';
  title: (name: string) => string;
  confirm: string;
  consequences: string[];
  needsReason: boolean;
  done: (name: string) => string;
}

const ACTIONS: Record<AcademyAction, ActionCopy> = {
  suspend: {
    label: 'Pause access',
    icon: <PauseCircle size={16} />,
    variant: 'secondary',
    title: (name) => `Pause access to ${name}?`,
    confirm: 'Pause access',
    consequences: [
      'Everyone in this LMS is signed out at once, and can’t sign back in.',
      'Nothing is deleted — students, courses and payments are all kept.',
      'Their subscription is not changed. Cancel it separately if billing should stop too.',
      'You can reactivate it at any time.',
    ],
    needsReason: true,
    done: (name) => `${name} is paused. Nobody in it can sign in.`,
  },
  archive: {
    label: 'Close this LMS',
    icon: <Archive size={16} />,
    variant: 'danger',
    title: (name) => `Close ${name}?`,
    confirm: 'Close LMS',
    consequences: [
      'Everyone in this LMS is signed out at once, and can’t sign back in.',
      'Nothing is deleted — you can reopen it later with everything still in place.',
      'Use this when a customer has left for good. To stop them for a while, pause access instead.',
    ],
    needsReason: true,
    done: (name) => `${name} is closed. Nobody in it can sign in.`,
  },
  reactivate: {
    label: 'Reactivate',
    icon: <LockSimpleOpen size={16} />,
    variant: 'primary',
    title: (name) => `Reactivate ${name}?`,
    confirm: 'Reactivate',
    consequences: [
      'Its admins, instructors and students can sign in again with their usual passwords.',
      'Everything is just as they left it.',
      'Check their plan below — an LMS with no live plan opens with limited features.',
    ],
    needsReason: false,
    done: (name) => `${name} is open again. Its people can sign in.`,
  },
};

/**
 * Whether people can get into an Admin's LMS, and the buttons that change it: pause access, close it, or let them back
 * in. The buttons offered are the moves the shared rule allows from the current status (`academyTransition`); the API
 * applies the same rule, needs a reason for a pause or a closure, and records the change in the activity log.
 */
export function AcademyAccess({ academy, onChanged }: { academy: PlatformAcademy; onChanged: (next: PlatformAcademy) => void }) {
  const toast = useToast();
  const [action, setAction] = useState<AcademyAction | null>(null);
  const [reason, setReason] = useState('');
  useEffect(() => {
    if (action) setReason('');
  }, [action]);

  const meaning = MEANING[academy.status] ?? MEANING.active;
  const available = (['reactivate', 'suspend', 'archive'] as const).filter((a) => academyTransition(academy.status, a));
  const liveSubscription = academy.subscription && LIVE_SUBSCRIPTION.has(academy.subscription.status);
  // The LMS this installation serves is the public site itself; the API refuses to pause or close it.
  const protectedLms = academy.isDefault;

  const blockedReason = (a: AcademyAction): string | null => {
    if (a === 'reactivate') return null;
    if (protectedLms) return 'This is the LMS the website itself runs on, so it can’t be paused or closed.';
    if (a === 'archive' && liveSubscription) return 'Cancel its subscription first (in Subscription and billing below), then close it.';
    return null;
  };

  const run = async () => {
    if (!action) return;
    const next = await services.platform.changeAcademyStatus(academy.id, action, ACTIONS[action].needsReason ? reason : undefined);
    toast({ kind: 'success', title: 'Access updated', text: ACTIONS[action].done(academy.name) });
    setAction(null);
    onChanged(next);
  };

  const copy = action ? ACTIONS[action] : null;

  return (
    <section className={styles.panel} aria-labelledby="academy-access">
      <SectionHeader id="academy-access" title="Access" description="Who can get into this LMS right now." />
      <div className={styles.accessState} data-status={academy.status}>
        <span className={styles.accessIcon} aria-hidden="true">
          {academy.status === 'active' ? <CheckCircle size={22} weight="duotone" /> : <Prohibit size={22} weight="duotone" />}
        </span>
        <span className={styles.accessText}>
          <span className={styles.accessTitle}>
            {meaning.title} <AcademyStatusBadge status={academy.status} />
          </span>
          <span className={styles.accessBody}>{meaning.text}</span>
          {academy.status !== 'active' && academy.statusReason && <span className={styles.accessReason}>Reason given: “{academy.statusReason}”</span>}
        </span>
      </div>

      <div className={styles.panelActions}>
        {available.map((a) => {
          const blocked = blockedReason(a);
          return (
            <Button
              key={a}
              variant={ACTIONS[a].variant}
              iconStart={ACTIONS[a].icon}
              onClick={() => setAction(a)}
              disabled={Boolean(blocked)}
              title={blocked ?? undefined}
            >
              {ACTIONS[a].label}
            </Button>
          );
        })}
      </div>
      {available.map((a) => blockedReason(a)).filter(Boolean).length > 0 && (
        <p className={styles.muted}>{available.map((a) => blockedReason(a)).find(Boolean)}</p>
      )}

      {copy && action && (
        <ConfirmDialog
          open
          onClose={() => setAction(null)}
          onConfirm={run}
          title={copy.title(academy.name)}
          icon={copy.icon}
          confirmLabel={copy.confirm}
          tone={action === 'reactivate' ? 'default' : 'danger'}
          blocked={copy.needsReason && reason.trim().length < 3}
        >
          <ul className={styles.consequences}>
            {copy.consequences.map((c) => (
              <li key={c}>{c}</li>
            ))}
          </ul>
          {copy.needsReason && (
            <Field label="Reason" hint="Required. Saved in the activity log so everyone knows why later.">
              <Textarea
                rows={2}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder={action === 'suspend' ? 'For example: invoices unpaid for two months' : 'For example: the customer has moved to another provider'}
              />
            </Field>
          )}
        </ConfirmDialog>
      )}
    </section>
  );
}
