import { useEffect, useState, type ReactNode } from 'react';
import { Button } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from './Overlay';
import styles from './Overlay.module.css';

interface ConfirmDialogProps {
  open: boolean;
  onClose: () => void;
  /** May return a promise; the dialog shows progress and stays open with the error if it rejects. */
  onConfirm: () => unknown;
  title: ReactNode;
  description?: ReactNode;
  icon?: ReactNode;
  confirmLabel: string;
  tone?: 'default' | 'danger';
  /** Consequences, listed before the decision. */
  children?: ReactNode;
  /** A statement the person must tick before a destructive action is enabled. */
  acknowledge?: string;
  /** Disables confirm with a reason shown in place of the button's normal state. */
  blocked?: boolean;
}

/** A decision with consequences: what will happen, what stays, then one clear action. */
export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  description,
  icon,
  confirmLabel,
  tone = 'default',
  children,
  acknowledge,
  blocked,
}: ConfirmDialogProps) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [acknowledged, setAcknowledged] = useState(false);

  useEffect(() => {
    if (open) {
      setError(null);
      setAcknowledged(false);
      setBusy(false);
    }
  }, [open]);

  const confirm = async () => {
    setBusy(true);
    setError(null);
    try {
      await onConfirm();
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={busy ? () => undefined : onClose}
      title={title}
      description={description}
      icon={icon}
      footer={
        <>
          <Button onClick={onClose} disabled={busy}>
            Cancel
          </Button>
          <Button variant={tone === 'danger' ? 'danger' : 'primary'} loading={busy} disabled={blocked || (!!acknowledge && !acknowledged)} onClick={confirm}>
            {confirmLabel}
          </Button>
        </>
      }
    >
      {(children || acknowledge || error) && (
        <div className={styles.confirmBody}>
          {children}
          {acknowledge && <Checkbox label={acknowledge} checked={acknowledged} onChange={(e) => setAcknowledged(e.target.checked)} />}
          {error && (
            <InlineMessage kind="error" title="That didn’t work.">
              {error}
            </InlineMessage>
          )}
        </div>
      )}
    </Modal>
  );
}
