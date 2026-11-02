import { useEffect, useRef, useState, type DragEvent, type ReactNode } from 'react';
import { CloudArrowUp, Trash, X } from '@phosphor-icons/react';
import type { MediaFile } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { Meter } from '@/components/lms/progress/Meters';
import { services } from '@/services';
import styles from './Upload.module.css';

type UploadState = { phase: 'idle' } | { phase: 'uploading' | 'processing'; name: string; progress: number };

/**
 * A file picker and drop zone. The file goes through `services.media.upload` — a real multipart
 * upload against the API, or a simulated one in the demo build — and the zone shows uploading,
 * processing and done, with cancelling part-way.
 */
export function MediaDrop({
  id,
  accept,
  label,
  hint,
  icon,
  onDone,
  error,
}: {
  id: string;
  accept: string;
  label: string;
  hint: string;
  icon: ReactNode;
  onDone: (file: MediaFile) => void;
  error?: string;
}) {
  const [state, setState] = useState<UploadState>({ phase: 'idle' });
  const [over, setOver] = useState(false);
  const [uploadError, setUploadError] = useState<string>();
  // Bumped on cancel/unmount so a late response from the upload is ignored.
  const attempt = useRef(0);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => () => void (attempt.current += 1), []);

  const start = (file: File) => {
    const id = ++attempt.current;
    setUploadError(undefined);
    setState({ phase: 'uploading', name: file.name, progress: 0 });
    services.media
      .upload(file, (progress) => {
        if (attempt.current !== id) return;
        setState(progress < 100 ? { phase: 'uploading', name: file.name, progress } : { phase: 'processing', name: file.name, progress: 100 });
      })
      .then((stored) => {
        if (attempt.current !== id) return;
        setState({ phase: 'idle' });
        onDone(stored);
      })
      .catch((err: Error) => {
        if (attempt.current !== id) return;
        setState({ phase: 'idle' });
        setUploadError(err.message || 'The upload failed. Try again.');
      });
  };

  const cancel = () => {
    attempt.current += 1;
    setState({ phase: 'idle' });
  };

  const onDrop = (e: DragEvent) => {
    e.preventDefault();
    setOver(false);
    const file = e.dataTransfer.files[0];
    if (file) start(file);
  };

  if (state.phase !== 'idle') {
    return (
      <div className={styles.uploading} role="status">
        <div className={styles.uploadingHead}>
          {icon}
          <span className={styles.uploadingName}>{state.name}</span>
          {state.phase === 'uploading' && <IconButton size="sm" label="Cancel upload" icon={<X size={14} />} onClick={cancel} />}
        </div>
        <Meter value={state.progress} size="sm" label={state.phase === 'uploading' ? 'Upload progress' : 'Processing'} />
        <span className={styles.uploadingText}>{state.phase === 'uploading' ? `Uploading · ${Math.round(state.progress)}%` : 'Processing — almost ready'}</span>
      </div>
    );
  }

  return (
    <div
      id={id}
      tabIndex={-1}
      className={cx(styles.drop, over && styles.dropOver, error && styles.dropError)}
      onDragOver={(e) => {
        e.preventDefault();
        setOver(true);
      }}
      onDragLeave={() => setOver(false)}
      onDrop={onDrop}
    >
      <CloudArrowUp size={30} aria-hidden="true" />
      <strong className={styles.dropTitle}>{label}</strong>
      <span className={styles.dropHint}>{hint}</span>
      <Button size="sm" onClick={() => inputRef.current?.click()}>
        Choose file
      </Button>
      <input
        ref={inputRef}
        type="file"
        accept={accept}
        className="sr-only"
        tabIndex={-1}
        aria-hidden="true"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) start(file);
          e.target.value = '';
        }}
      />
      {(error ?? uploadError) && <span className={styles.dropErrorText}>{error ?? uploadError}</span>}
    </div>
  );
}

export function FileCard({
  icon,
  file,
  detail,
  onRemove,
  onReplace,
}: {
  icon: ReactNode;
  file: MediaFile;
  detail: string;
  onRemove?: () => void;
  onReplace?: () => void;
}) {
  return (
    <div className={styles.fileCard}>
      <span className={styles.fileIcon}>{icon}</span>
      <span className={styles.fileText}>
        <span className={styles.fileName}>{file.name}</span>
        <span className={styles.fileMeta}>
          {file.sizeMb} MB · {detail}
        </span>
      </span>
      {onReplace && (
        <Button size="sm" variant="ghost" onClick={onReplace}>
          Replace
        </Button>
      )}
      {onRemove && <IconButton size="sm" label={`Remove ${file.name}`} icon={<Trash size={16} />} onClick={onRemove} />}
    </div>
  );
}
