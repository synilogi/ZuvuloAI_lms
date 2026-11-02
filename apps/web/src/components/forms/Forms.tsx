import { useEffect, useId, useRef, useState, type CSSProperties, type KeyboardEvent, type ReactNode } from 'react';
import { ArrowDown, ArrowUp, Check, Plus, WarningCircle, X } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import { IconButton } from '@/components/ui/Button/Button';
import styles from './Forms.module.css';

/* ─── Switch ───────────────────────────────────────────────────────────── */

interface SwitchProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label: ReactNode;
  description?: ReactNode;
  disabled?: boolean;
  /** Hide the visible label (still announced). */
  hideLabel?: boolean;
  id?: string;
}

/** An on/off setting that applies immediately to the form value. Label and description sit beside it, never inside. */
export function Switch({ checked, onChange, label, description, disabled, hideLabel, id }: SwitchProps) {
  const autoId = useId();
  const switchId = id ?? autoId;
  const descId = `${switchId}-desc`;
  return (
    <div className={cx(styles.switchRow, disabled && styles.disabled)}>
      <span className={cx(styles.switchText, hideLabel && 'sr-only')}>
        <label htmlFor={switchId} className={styles.switchLabel}>
          {label}
        </label>
        {description && (
          <span id={descId} className={styles.switchDescription}>
            {description}
          </span>
        )}
      </span>
      <button
        id={switchId}
        type="button"
        role="switch"
        aria-checked={checked}
        aria-describedby={description ? descId : undefined}
        disabled={disabled}
        className={styles.switch}
        onClick={() => onChange(!checked)}
      >
        <span className={styles.switchThumb}>{checked && <Check size={10} weight="bold" />}</span>
      </button>
    </div>
  );
}

/* ─── Choice cards ─────────────────────────────────────────────────────── */

export interface Choice<T extends string> {
  value: T;
  label: string;
  description?: string;
  icon?: ReactNode;
  /** Replaces the icon with a larger visual, e.g. a cover motif. */
  visual?: ReactNode;
  disabled?: boolean;
}

interface ChoiceCardsProps<T extends string> {
  legend: string;
  hideLegend?: boolean;
  value: T;
  onChange: (value: T) => void;
  choices: Choice<T>[];
  columns?: 1 | 2 | 3 | 4;
  name?: string;
  error?: ReactNode;
}

/** A radio group drawn as selectable tiles — for choices that need a sentence of explanation. */
export function ChoiceCards<T extends string>({ legend, hideLegend, value, onChange, choices, columns = 2, name, error }: ChoiceCardsProps<T>) {
  const autoName = useId();
  return (
    <fieldset className={styles.fieldset}>
      <legend className={cx(styles.legend, hideLegend && 'sr-only')}>{legend}</legend>
      <div className={cx(styles.choices, choices.some((c) => c.visual) && styles.choicesVisual)} style={{ '--choice-cols': columns } as CSSProperties}>
        {choices.map((choice) => {
          const selected = choice.value === value;
          return (
            <label
              key={choice.value}
              className={cx(styles.choice, selected && styles.choiceSelected, choice.disabled && styles.disabled, choice.visual && styles.choiceVisual)}
            >
              <input
                type="radio"
                className={styles.choiceInput}
                name={name ?? autoName}
                value={choice.value}
                checked={selected}
                disabled={choice.disabled}
                onChange={() => onChange(choice.value)}
              />
              {choice.visual ?? (choice.icon && <span className={styles.choiceIcon}>{choice.icon}</span>)}
              <span className={styles.choiceText}>
                <span className={styles.choiceLabel}>{choice.label}</span>
                {choice.description && <span className={styles.choiceDescription}>{choice.description}</span>}
              </span>
              <span className={styles.choiceMark} aria-hidden="true">
                {selected && <Check size={11} weight="bold" />}
              </span>
            </label>
          );
        })}
      </div>
      {error && (
        <p className={styles.fieldError}>
          <WarningCircle size={15} /> {error}
        </p>
      )}
    </fieldset>
  );
}

/* ─── Tag input ────────────────────────────────────────────────────────── */

interface TagInputProps {
  label: string;
  value: string[];
  onChange: (value: string[]) => void;
  suggestions?: string[];
  placeholder?: string;
  max?: number;
  hint?: ReactNode;
}

/** Free-text tags. Enter or comma adds, Backspace on an empty field removes the last tag. */
export function TagInput({ label, value, onChange, suggestions = [], placeholder, max = 8, hint }: TagInputProps) {
  const id = useId();
  const [draft, setDraft] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);
  const full = value.length >= max;

  const add = (raw: string) => {
    const tag = raw.trim().replace(/,$/, '');
    if (!tag || full || value.some((t) => t.toLowerCase() === tag.toLowerCase())) return;
    onChange([...value, tag]);
    setDraft('');
  };
  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      add(draft);
    } else if (e.key === 'Backspace' && !draft && value.length) {
      onChange(value.slice(0, -1));
    }
  };
  const available = suggestions.filter((s) => !value.some((t) => t.toLowerCase() === s.toLowerCase())).slice(0, 6);

  return (
    <div className={styles.field}>
      <label htmlFor={id} className={styles.fieldLabel}>
        {label}
        <span className={styles.counter}>
          {value.length}/{max}
        </span>
      </label>
      <div className={styles.tagBox} onClick={() => inputRef.current?.focus()}>
        {value.map((tag) => (
          <span key={tag} className={styles.tag}>
            {tag}
            <button type="button" className={styles.tagRemove} aria-label={`Remove ${tag}`} onClick={() => onChange(value.filter((t) => t !== tag))}>
              <X size={11} weight="bold" />
            </button>
          </span>
        ))}
        <input
          ref={inputRef}
          id={id}
          className={styles.tagInput}
          value={draft}
          disabled={full}
          placeholder={full ? `Up to ${max} tags` : value.length ? '' : placeholder}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={onKeyDown}
          onBlur={() => add(draft)}
        />
      </div>
      {available.length > 0 && !full && (
        <div className={styles.suggestions}>
          <span className={styles.suggestionsLabel}>Suggested</span>
          {available.map((s) => (
            <button key={s} type="button" className={styles.suggestion} onClick={() => add(s)}>
              <Plus size={11} weight="bold" /> {s}
            </button>
          ))}
        </div>
      )}
      {hint && <p className={styles.hint}>{hint}</p>}
    </div>
  );
}

/* ─── List input ───────────────────────────────────────────────────────── */

interface ListInputProps {
  label: string;
  value: string[];
  onChange: (value: string[]) => void;
  placeholder?: string;
  addLabel?: string;
  min?: number;
  max?: number;
  hint?: ReactNode;
  error?: ReactNode;
  numbered?: boolean;
}

/** An ordered list of short statements — learning outcomes, objectives, agenda items. */
export function ListInput({ label, value, onChange, placeholder, addLabel = 'Add item', min = 0, max = 10, hint, error, numbered = true }: ListInputProps) {
  const id = useId();
  const listRef = useRef<HTMLOListElement>(null);
  const rows = value.length ? value : [''];

  const set = (i: number, text: string) => onChange(rows.map((r, j) => (j === i ? text : r)));
  const remove = (i: number) => onChange(rows.filter((_, j) => j !== i));
  const move = (i: number, dir: -1 | 1) => {
    const next = [...rows];
    [next[i], next[i + dir]] = [next[i + dir], next[i]];
    onChange(next);
    requestAnimationFrame(() => listRef.current?.querySelectorAll<HTMLInputElement>('input')[i + dir]?.focus());
  };
  const add = () => {
    onChange([...rows, '']);
    requestAnimationFrame(() => {
      const inputs = listRef.current?.querySelectorAll<HTMLInputElement>('input');
      inputs?.[inputs.length - 1]?.focus();
    });
  };

  return (
    <div className={styles.field} role="group" aria-labelledby={`${id}-label`}>
      <span id={`${id}-label`} className={styles.fieldLabel}>
        {label}
        <span className={styles.counter}>{min ? `${rows.filter((r) => r.trim()).length} of ${min} needed` : `${rows.length}/${max}`}</span>
      </span>
      <ol ref={listRef} className={styles.listRows}>
        {rows.map((row, i) => (
          <li key={i} className={styles.listRow}>
            {numbered && (
              <span className={styles.listIndex} aria-hidden="true">
                {i + 1}
              </span>
            )}
            <input
              className={styles.listControl}
              value={row}
              placeholder={placeholder}
              aria-label={`${label} ${i + 1}`}
              aria-invalid={error && !row.trim() ? true : undefined}
              onChange={(e) => set(i, e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  if (rows.length < max) add();
                }
              }}
            />
            <span className={styles.listActions}>
              <IconButton
                size="sm"
                label={`Move ${label.toLowerCase()} ${i + 1} up`}
                icon={<ArrowUp size={14} />}
                disabled={i === 0}
                onClick={() => move(i, -1)}
              />
              <IconButton
                size="sm"
                label={`Move ${label.toLowerCase()} ${i + 1} down`}
                icon={<ArrowDown size={14} />}
                disabled={i === rows.length - 1}
                onClick={() => move(i, 1)}
              />
              <IconButton
                size="sm"
                label={`Remove ${label.toLowerCase()} ${i + 1}`}
                icon={<X size={14} />}
                disabled={rows.length === 1 && !row}
                onClick={() => remove(i)}
              />
            </span>
          </li>
        ))}
      </ol>
      <button type="button" className={styles.addRow} onClick={add} disabled={rows.length >= max}>
        <Plus size={14} weight="bold" /> {rows.length >= max ? `Up to ${max}` : addLabel}
      </button>
      {error ? (
        <p className={styles.fieldError}>
          <WarningCircle size={15} /> {error}
        </p>
      ) : (
        hint && <p className={styles.hint}>{hint}</p>
      )}
    </div>
  );
}

/* ─── Form section ─────────────────────────────────────────────────────── */

interface FormSectionProps {
  id?: string;
  title: string;
  description?: ReactNode;
  children: ReactNode;
  aside?: ReactNode;
}

/** A titled group of fields. Wide containers put the title and its explanation in a left column. */
export function FormSection({ id, title, description, children, aside }: FormSectionProps) {
  return (
    <section id={id} className={styles.section} aria-labelledby={id ? `${id}-title` : undefined}>
      <div className={styles.sectionIntro}>
        <h2 id={id ? `${id}-title` : undefined} className={styles.sectionTitle}>
          {title}
        </h2>
        {description && <p className={styles.sectionDescription}>{description}</p>}
        {aside}
      </div>
      <div className={styles.sectionFields}>{children}</div>
    </section>
  );
}

/* ─── Error summary ────────────────────────────────────────────────────── */

export interface FieldIssue {
  /** DOM id of the control to focus. */
  field: string;
  message: string;
}

/** Lists what blocks a submit, with links that move focus to each field. Receives focus when it appears. */
export function ErrorSummary({ issues, title = 'Fix these before saving', attempt = 0 }: { issues: FieldIssue[]; title?: string; attempt?: number }) {
  const ref = useRef<HTMLDivElement>(null);
  // Move focus to the summary each time a submit fails.
  useEffect(() => {
    if (issues.length && attempt > 0) ref.current?.focus();
  }, [attempt, issues.length]);
  if (!issues.length) return null;
  return (
    <div ref={ref} className={styles.summary} role="alert" tabIndex={-1}>
      <WarningCircle size={20} />
      <div>
        <p className={styles.summaryTitle}>{title}</p>
        <ul className={styles.summaryList}>
          {issues.map((issue) => (
            <li key={issue.field}>
              <a
                href={`#${issue.field}`}
                onClick={(e) => {
                  e.preventDefault();
                  const el = document.getElementById(issue.field);
                  el?.scrollIntoView({ block: 'center', behavior: 'smooth' });
                  el?.focus({ preventScroll: true });
                }}
              >
                {issue.message}
              </a>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
