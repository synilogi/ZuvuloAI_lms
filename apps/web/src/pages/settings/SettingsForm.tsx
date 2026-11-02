import { useEffect, useRef, useState, type FormEvent, type KeyboardEvent, type ReactNode } from 'react';
import { useBlocker, useOutletContext } from 'react-router-dom';
import { CheckCircle, FloppyDisk } from '@phosphor-icons/react';
import type { LmsSettings, SettingsSection } from '@syniastrolms/domain';
import { validateSettings } from '@syniastrolms/domain';
import { useNow } from '@/hooks/useNow';
import { usePermissions } from '@/hooks/usePermissions';
import { useViewport } from '@/hooks/useViewport';
import { formatRelative } from '@/lib/format';
import { ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { Button } from '@/components/ui/Button/Button';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { services } from '@/services';
import { SECTION_META, type SettingsOutlet } from './SettingsLayout';
import styles from './Settings.module.css';

export interface FormApi<S extends SettingsSection> {
  value: LmsSettings[S];
  /** Merge a change into the section. */
  update: (patch: Partial<LmsSettings[S]>) => void;
  errorFor: (field: string) => string | undefined;
}

interface SettingsFormProps<S extends SettingsSection> {
  section: S;
  description: string;
  children: (api: FormApi<S>) => ReactNode;
  /** Shown beside the form on wide screens, under it on narrow ones. */
  preview?: (value: LmsSettings[S]) => ReactNode;
}

/**
 * One settings section: its own draft, validation, save bar and leave guard. Unsaved changes are
 * named in the bar and guarded when leaving; Ctrl/⌘ + S saves.
 */
export function SettingsForm<S extends SettingsSection>({ section, description, children, preview }: SettingsFormProps<S>) {
  const { can } = usePermissions();
  const { record, onSaved } = useOutletContext<SettingsOutlet>();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const meta = SECTION_META[section];
  const [baseline, setBaseline] = useState<LmsSettings[S]>(record.settings[section]);
  const [value, setValue] = useState<LmsSettings[S]>(record.settings[section]);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [savedAt, setSavedAt] = useState<number | null>(null);
  const savingRef = useRef(false);
  const dirty = JSON.stringify(value) !== JSON.stringify(baseline);

  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !savingRef.current && currentLocation.pathname !== nextLocation.pathname);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const all = validateSettings(section, value);
  const issues: FieldIssue[] = attempt ? all.map((i) => ({ field: i.field, message: i.message })) : [];
  const errorFor = (field: string) => issues.find((i) => i.field === field)?.message;

  const save = async (e?: FormEvent) => {
    e?.preventDefault();
    if (!dirty || saving) return;
    setAttempt((a) => a + 1);
    setError(null);
    if (all.length) return;
    setSaving(true);
    savingRef.current = true;
    try {
      const next = await services.settings.save(section, value);
      onSaved(next);
      setBaseline(next.settings[section]);
      setValue(next.settings[section]);
      setAttempt(0);
      setSavedAt(Date.now());
      toast({ kind: 'success', title: `${meta.label} settings saved`, text: 'They apply from now on.' });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
      savingRef.current = false;
    }
  };

  const onKeyDown = (e: KeyboardEvent) => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 's') {
      e.preventDefault();
      save();
    }
  };

  const discard = () => {
    setValue(baseline);
    setAttempt(0);
    setError(null);
  };

  const status = dirty ? (
    <span className={styles.unsaved}>Unsaved changes</span>
  ) : savedAt ? (
    <span className={styles.saved}>
      <CheckCircle size={16} weight="fill" aria-hidden="true" /> Saved
    </span>
  ) : (
    <span className={styles.muted}>
      Last changed {formatRelative(record.updatedAt[section], now)} by {record.updatedBy[section]}
    </span>
  );

  const bar = (
    <div className={styles.saveBar}>
      <span role="status" aria-live="polite" className={styles.saveStatus}>
        {status}
      </span>
      <div className={styles.saveActions}>
        {/* Reading settings and changing them are separate permissions: without the second the page
            stays readable, and only the controls that would write go. */}
        {can('settings.edit') ? (
          <>
            <Button onClick={discard} disabled={!dirty || saving}>
              Discard
            </Button>
            <Button type="submit" form={`settings-${section}`} variant="primary" loading={saving} disabled={!dirty} iconStart={<FloppyDisk size={16} />}>
              Save changes
            </Button>
          </>
        ) : (
          <span className={styles.muted}>Read only — you don’t have permission to change settings.</span>
        )}
      </div>
    </div>
  );

  return (
    <div className={preview ? styles.withPreview : undefined}>
      <form id={`settings-${section}`} className={styles.form} onSubmit={save} onKeyDown={onKeyDown} noValidate aria-labelledby={`settings-${section}-title`}>
        <header className={styles.formHead}>
          <h2 id={`settings-${section}-title`} className={styles.formTitle}>
            {meta.label}
          </h2>
          <p className={styles.formDescription}>{description}</p>
        </header>
        <ErrorSummary issues={issues} attempt={attempt} />
        {error && (
          <InlineMessage kind="error" title="Couldn’t save.">
            {error}
          </InlineMessage>
        )}
        {children({ value, update: (patch) => setValue((v) => ({ ...v, ...patch })), errorFor })}
        {!isMobile && bar}
      </form>
      {preview && <aside className={styles.preview}>{preview(value)}</aside>}
      {isMobile && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{bar}</div>}>
          <span />
        </StickyActionBar>
      )}
      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description={`Your changes to ${meta.label.toLowerCase()} settings haven’t been saved.`}
        footer={
          <>
            <Button onClick={() => blocker.reset?.()}>Keep editing</Button>
            <Button variant="danger" onClick={() => blocker.proceed?.()}>
              Discard changes
            </Button>
          </>
        }
      />
    </div>
  );
}

/** Number inputs hold text while typing; the draft keeps a number. */
export const toNumber = (text: string) => (text.trim() === '' ? NaN : Number(text));
export const numberValue = (n: number) => (Number.isFinite(n) ? String(n) : '');
