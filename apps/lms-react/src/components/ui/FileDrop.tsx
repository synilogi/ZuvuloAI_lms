import { UploadSimple } from '@phosphor-icons/react';
import { useId, useRef, useState, type DragEvent, type ReactNode } from 'react';

import { cx } from '@/lib/cx';
import { formatBytes } from '@/lib/format';

import { Button } from './Button';
import styles from './Form.module.css';

export interface FileDropProps {
  /** Called with the accepted files. Uploading is the caller's job (REACT-013). */
  onFiles: (files: File[]) => void;
  /** `accept` attribute, e.g. "video/mp4,video/webm" or ".pdf". */
  accept?: string;
  multiple?: boolean;
  /** Files larger than this are refused before anything is sent. */
  maxBytes?: number;
  label?: ReactNode;
  hint?: ReactNode;
  disabled?: boolean;
  /** Called with a human message when a file is refused here. */
  onReject?: (message: string) => void;
}

const matchesAccept = (file: File, accept?: string) => {
  if (!accept) return true;
  return accept
    .split(',')
    .map((part) => part.trim().toLowerCase())
    .some((rule) =>
      rule.startsWith('.') ? file.name.toLowerCase().endsWith(rule) : rule.endsWith('/*') ? file.type.startsWith(rule.slice(0, -1)) : file.type === rule,
    );
};

/** Drop zone plus a "Choose file" button — the button is the keyboard path; dropping is a shortcut. */
export function FileDrop({ onFiles, accept, multiple = false, maxBytes, label = 'Drop a file here, or', hint, disabled, onReject }: FileDropProps) {
  const input = useRef<HTMLInputElement>(null);
  const [active, setActive] = useState(false);
  const hintId = useId();

  const take = (list: FileList | null) => {
    const files = Array.from(list ?? []).slice(0, multiple ? undefined : 1);
    const accepted: File[] = [];
    for (const file of files) {
      if (!matchesAccept(file, accept)) onReject?.(`${file.name} is not a supported file type.`);
      else if (maxBytes !== undefined && file.size > maxBytes) onReject?.(`${file.name} is larger than ${formatBytes(maxBytes)}.`);
      else accepted.push(file);
    }
    if (accepted.length) onFiles(accepted);
  };

  const onDrop = (event: DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    setActive(false);
    if (!disabled) take(event.dataTransfer.files);
  };

  return (
    <div
      className={cx(styles.drop, active && styles.dropActive)}
      onDragOver={(event) => {
        event.preventDefault();
        if (!disabled) setActive(true);
      }}
      onDragLeave={() => setActive(false)}
      onDrop={onDrop}
      data-testid="file-drop"
    >
      <UploadSimple size={28} aria-hidden="true" />
      <div>
        {label}{' '}
        <Button size="sm" onClick={() => input.current?.click()} disabled={disabled} aria-describedby={hint ? hintId : undefined}>
          Choose {multiple ? 'files' : 'a file'}
        </Button>
      </div>
      {hint && (
        <p id={hintId} className={styles.hint}>
          {hint}
        </p>
      )}
      <input
        ref={input}
        type="file"
        hidden
        accept={accept}
        multiple={multiple}
        onChange={(event) => {
          take(event.target.files);
          event.target.value = '';
        }}
      />
    </div>
  );
}
