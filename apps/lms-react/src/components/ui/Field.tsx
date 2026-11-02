import { createContext, useContext, useId, type ReactNode } from 'react';

import styles from './Form.module.css';

interface FieldContextValue {
  id: string;
  describedBy?: string;
  invalid: boolean;
  required: boolean;
}

const FieldContext = createContext<FieldContextValue | null>(null);

/**
 * What an input inside a `Field` needs to be labelled and described. Outside a `Field` it returns the props the
 * input was given, so every input also works on its own.
 */
export function useFieldControl(props: { id?: string; 'aria-describedby'?: string; 'aria-invalid'?: boolean | 'true' | 'false'; required?: boolean }) {
  const field = useContext(FieldContext);
  const describedBy = [field?.describedBy, props['aria-describedby']].filter(Boolean).join(' ') || undefined;
  return {
    id: props.id ?? field?.id,
    'aria-describedby': describedBy,
    'aria-invalid': props['aria-invalid'] ?? (field?.invalid ? true : undefined),
    required: props.required ?? (field?.required || undefined),
  };
}

export interface FieldProps {
  label: ReactNode;
  children: ReactNode;
  hint?: ReactNode;
  /** A validation message. Its presence marks the control invalid. */
  error?: ReactNode;
  required?: boolean;
  /** Use a specific id for the control (e.g. to link from an ErrorSummary). */
  id?: string;
  className?: string;
}

/** Label, hint and error for one control; wires `id`, `aria-describedby`, `aria-invalid` and `required`. */
export function Field({ label, children, hint, error, required = false, id, className }: FieldProps) {
  const generated = useId();
  const controlId = id ?? `field-${generated}`;
  const hintId = hint ? `${controlId}-hint` : undefined;
  const errorId = error ? `${controlId}-error` : undefined;
  const describedBy = [hintId, errorId].filter(Boolean).join(' ') || undefined;

  return (
    <div className={[styles.field, className].filter(Boolean).join(' ')}>
      <label className={styles.label} htmlFor={controlId}>
        {label}
        {required && (
          <span className={styles.required} aria-hidden="true">
            *
          </span>
        )}
      </label>
      {hint && (
        <p id={hintId} className={styles.hint}>
          {hint}
        </p>
      )}
      <FieldContext.Provider value={{ id: controlId, describedBy, invalid: Boolean(error), required }}>{children}</FieldContext.Provider>
      {error && (
        <p id={errorId} className={styles.error}>
          {error}
        </p>
      )}
    </div>
  );
}
