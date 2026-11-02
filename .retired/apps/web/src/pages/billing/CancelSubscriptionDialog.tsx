import { useEffect, useState } from 'react';
import { Prohibit } from '@phosphor-icons/react';
import type { Subscription } from '@syniastrolms/domain';
import { formatDate } from '@/lib/format';
import { ChoiceCards } from '@/components/forms/Forms';
import { Field, Textarea } from '@/components/ui/Field/Field';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { services } from '@/services';
import styles from '@/pages/superadmin/subscriptions/Subscriptions.module.css';

type When = 'period-end' | 'immediately';

/**
 * The academy cancels its own subscription: at the end of the period by default, keeping everything until
 * then, or at once. Either way nothing is refunded and nothing the academy made is deleted. A cancellation at
 * the period end can be withdrawn until that date.
 */
export function CancelSubscriptionDialog({
  subscription,
  open,
  onClose,
  onDone,
}: {
  subscription: Subscription;
  open: boolean;
  onClose: () => void;
  onDone: (immediately: boolean) => void | Promise<void>;
}) {
  const [when, setWhen] = useState<When>('period-end');
  const [reason, setReason] = useState('');
  useEffect(() => {
    if (open) {
      setWhen('period-end');
      setReason('');
    }
  }, [open]);

  const trial = subscription.status === 'trial';
  const ends = trial && subscription.trialEndsAt ? subscription.trialEndsAt : subscription.renewsAt;

  return (
    <ConfirmDialog
      open={open}
      onClose={onClose}
      onConfirm={async () => {
        await services.tenantBilling.cancel({ immediately: when === 'immediately', reason: reason.trim() });
        await onDone(when === 'immediately');
      }}
      tone="danger"
      icon={<Prohibit size={20} />}
      title="Cancel the subscription?"
      description={trial ? `The trial runs until ${formatDate(ends)}` : `Paid until ${formatDate(ends)}`}
      confirmLabel={when === 'immediately' ? 'Cancel now' : 'Cancel at period end'}
      blocked={reason.trim().length < 3}
      acknowledge={when === 'immediately' ? 'I understand the LMS stops being able to add anything today, and nothing is refunded.' : undefined}
    >
      <div className={styles.dialogBody}>
        <ChoiceCards<When>
          legend="When it ends"
          value={when}
          onChange={setWhen}
          columns={1}
          choices={[
            {
              value: 'period-end',
              label: `At the end of the period — ${formatDate(ends)}`,
              description: 'Everything keeps working until then, and you can change your mind before that date. Nothing more is charged.',
            },
            {
              value: 'immediately',
              label: 'Now',
              description: 'The subscription ends today. Nothing is refunded for the rest of the period.',
            },
          ]}
        />
        <Field label="Reason" hint="At least 3 characters. It helps the platform team understand what didn’t work.">
          <Textarea rows={2} value={reason} onChange={(e) => setReason(e.target.value)} maxLength={500} placeholder="Why are you cancelling?" />
        </Field>
        <p className={styles.muted}>
          Once it ends, the LMS keeps its courses, learners and records — they stay readable and editable — but nothing new can be added until a plan is chosen
          again.
        </p>
      </div>
    </ConfirmDialog>
  );
}
