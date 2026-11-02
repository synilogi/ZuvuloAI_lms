import { forwardRef, useId, type ReactNode } from 'react';

import styles from './Form.module.css';

export interface ErrorSummaryItem {
  /** The control's id; the message links to it. Omit for errors that belong to no field. */
  fieldId?: string;
  message: ReactNode;
}

export interface ErrorSummaryProps {
  errors: ErrorSummaryItem[];
  title?: ReactNode;
}

/**
 * The list of problems at the top of a form. Forms focus it on a failed submit (it takes the ref), so a screen
 * reader announces it and a keyboard user can jump from each message to its field.
 */
export const ErrorSummary = forwardRef<HTMLDivElement, ErrorSummaryProps>(function ErrorSummary({ errors, title = 'There is a problem' }, ref) {
  const titleId = useId();
  if (errors.length === 0) return null;
  return (
    <div ref={ref} className={styles.summary} role="alert" tabIndex={-1} aria-labelledby={titleId}>
      <h2 id={titleId} className={styles.summaryTitle}>
        {title}
      </h2>
      <ul>
        {errors.map((error, index) => (
          <li key={error.fieldId ?? index}>
            {error.fieldId ? (
              <a
                href={`#${error.fieldId}`}
                onClick={(event) => {
                  event.preventDefault();
                  document.getElementById(error.fieldId!)?.focus();
                }}
              >
                {error.message}
              </a>
            ) : (
              error.message
            )}
          </li>
        ))}
      </ul>
    </div>
  );
});
