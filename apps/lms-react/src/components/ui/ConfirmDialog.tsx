import { useEffect, useId, useState, type ReactNode } from 'react';

import { InlineAlert } from '@/components/feedback/InlineAlert';

import { Button } from './Button';
import { Dialog } from './Dialog';
import { Field } from './Field';
import { Textarea } from './inputs';
import styles from './Overlay.module.css';

export interface ConfirmReason {
  label: string;
  /** Minimum characters, as the server requires (e.g. 3 for a revoke or cancel reason). */
  minLength?: number;
  required?: boolean;
  hint?: ReactNode;
}

export interface ConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Names the object: "Archive Class 10 Mathematics?" */
  title: ReactNode;
  /** States the consequence in plain words. */
  description: ReactNode;
  /** The verb on the button: "Archive course". Never "OK". */
  confirmLabel: string;
  cancelLabel?: string;
  tone?: 'default' | 'danger';
  /** Ask for a reason before confirming. */
  reason?: ConfirmReason;
  /** Extra content (impact details, a destination picker). */
  children?: ReactNode;
  /** Runs the action. A rejected promise keeps the dialog open and shows the message. */
  onConfirm: (reason: string) => Promise<unknown> | unknown;
  /** Disable the confirm button (e.g. until a destination is chosen). */
  confirmDisabled?: boolean;
}

const messageOf = (error: unknown) => (error instanceof Error && error.message ? error.message : 'Something went wrong. Please try again.');

export function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel,
  cancelLabel = 'Cancel',
  tone = 'default',
  reason,
  children,
  onConfirm,
  confirmDisabled = false,
}: ConfirmDialogProps) {
  const [text, setText] = useState('');
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [touched, setTouched] = useState(false);
  const reasonId = useId();

  useEffect(() => {
    if (open) {
      setText('');
      setError(null);
      setTouched(false);
    }
  }, [open]);

  const trimmed = text.trim();
  const reasonProblem =
    reason && (reason.required ?? true) && trimmed.length < (reason.minLength ?? 1)
      ? reason.minLength && reason.minLength > 1
        ? `Enter at least ${reason.minLength} characters.`
        : 'Enter a reason.'
      : null;

  const confirm = async () => {
    setTouched(true);
    if (reasonProblem) return;
    setPending(true);
    setError(null);
    try {
      await onConfirm(trimmed);
      onOpenChange(false);
    } catch (caught) {
      setError(messageOf(caught));
    } finally {
      setPending(false);
    }
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(next) => !pending && onOpenChange(next)}
      title={title}
      description={description}
      size="sm"
      dismissible={!pending}
      footer={
        <>
          <Button onClick={() => onOpenChange(false)} disabled={pending}>
            {cancelLabel}
          </Button>
          <Button variant={tone === 'danger' ? 'danger' : 'primary'} onClick={confirm} loading={pending} disabled={confirmDisabled}>
            {confirmLabel}
          </Button>
        </>
      }
    >
      {children}
      {reason && (
        <div className={styles.reason}>
          <Field label={reason.label} hint={reason.hint} required={reason.required ?? true} error={touched ? reasonProblem : undefined} id={reasonId}>
            <Textarea value={text} onChange={(event) => setText(event.target.value)} rows={3} />
          </Field>
        </div>
      )}
      {error && (
        <div className={styles.inlineError}>
          <InlineAlert tone="danger">{error}</InlineAlert>
        </div>
      )}
    </Dialog>
  );
}
