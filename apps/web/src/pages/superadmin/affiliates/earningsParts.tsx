import { useState, type ReactNode } from 'react';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import styles from './Affiliates.module.css';

/* What the earnings pages share: paging, a dialog that asks for a reason, and a figure tile. */

export function Pager({ page, pageSize, total, onPage }: { page: number; pageSize: number; total: number; onPage: (page: number) => void }) {
  if (total <= pageSize) return null;
  return (
    <div className={styles.formActions}>
      <Button disabled={page <= 1} onClick={() => onPage(page - 1)}>
        Previous
      </Button>
      <span className={styles.muted}>
        Page {page} of {Math.ceil(total / pageSize)}
      </span>
      <Button disabled={page * pageSize >= total} onClick={() => onPage(page + 1)}>
        Next
      </Button>
    </div>
  );
}

export interface Pending {
  title: string;
  /** What the action does, stated before it happens. */
  text: ReactNode;
  confirmLabel: string;
  tone?: 'danger';
  /** Set when the action needs words from the person: a reason, a reference. */
  input?: { label: string; hint?: string; min: number; multiline?: boolean };
  run: (value: string) => Promise<unknown>;
  /** The toast afterwards; a function reads what `run` answered. */
  done: string | ((result: unknown) => string);
}

/** Every money action asks first, says what it does, and takes its reason where the record needs one. */
export function ActionDialog({ pending, onClose, onDone }: { pending: Pending | null; onClose: () => void; onDone: () => unknown }) {
  const toast = useToast();
  const [value, setValue] = useState('');
  const short = pending?.input ? value.trim().length < pending.input.min : false;
  return (
    <ConfirmDialog
      open={pending !== null}
      onClose={() => {
        setValue('');
        onClose();
      }}
      onConfirm={async () => {
        if (!pending) return;
        try {
          const result = await pending.run(value.trim());
          toast({ kind: 'success', title: typeof pending.done === 'function' ? pending.done(result) : pending.done });
          setValue('');
          onClose();
          await onDone();
        } catch (err) {
          toast({ kind: 'error', title: 'That didn’t work', text: (err as Error).message });
        }
      }}
      title={pending?.title ?? ''}
      confirmLabel={pending?.confirmLabel ?? 'Confirm'}
      tone={pending?.tone}
      blocked={short}
    >
      <p>{pending?.text}</p>
      {pending?.input && (
        <Field label={pending.input.label} hint={pending.input.hint}>
          {pending.input.multiline ? (
            <Textarea id="action-value" rows={3} value={value} maxLength={500} onChange={(e) => setValue(e.target.value)} />
          ) : (
            <Input id="action-value" value={value} maxLength={120} onChange={(e) => setValue(e.target.value)} />
          )}
        </Field>
      )}
    </ConfirmDialog>
  );
}

/** Saves text a server made as a file in the browser. */
export function saveCsv(csv: string, name: string) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
  a.download = name;
  a.click();
  URL.revokeObjectURL(a.href);
}
