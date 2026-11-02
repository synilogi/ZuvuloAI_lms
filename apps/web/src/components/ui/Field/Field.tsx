import {
  Children,
  cloneElement,
  forwardRef,
  isValidElement,
  useId,
  type InputHTMLAttributes,
  type ReactElement,
  type ReactNode,
  type SelectHTMLAttributes,
  type TextareaHTMLAttributes,
} from 'react';
import { CaretDown, CheckCircle, MagnifyingGlass, WarningCircle, X } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import styles from './Field.module.css';

interface FieldProps {
  label: string;
  hint?: ReactNode;
  error?: ReactNode;
  success?: ReactNode;
  optional?: boolean;
  hideLabel?: boolean;
  className?: string;
  /**
   * A single control from this module, or a wrapper holding one (a password field with its
   * visibility toggle). Field wires id, aria-describedby and aria-invalid onto a bare control by
   * cloning. That cannot reach a control inside a wrapper, so for those either pass `id`
   * explicitly or let Field find the control's own id — in both cases Field only points the
   * label at it, and the wrapper's caller puts `aria-describedby` and `aria-invalid` on the real
   * control (see `fieldProps` in `lib/fieldProps.ts`).
   */
  children: ReactElement;
  id?: string;
}

/**
 * The id of the control this field labels.
 *
 * Usually that is the child itself. When the child is a wrapper — a password field with a toggle
 * beside it — the id sits on the control inside it, and the label has to point at that, or the
 * input ends up with no accessible name at all.
 */
function controlId(node: ReactNode): string | undefined {
  if (!isValidElement(node)) return undefined;
  const own = (node.props as { id?: string }).id;
  if (own) return own;
  for (const child of Children.toArray((node.props as { children?: ReactNode }).children)) {
    const nested = controlId(child);
    if (nested) return nested;
  }
  return undefined;
}

export function Field({ label, hint, error, success, optional, hideLabel, className, children, id: explicitId }: FieldProps) {
  const autoId = useId();
  // Keep a control's own id so error summaries and anchors can point at it.
  const own = isValidElement(children) ? (children.props as { id?: string }).id : undefined;
  const found = explicitId || controlId(children);
  const id = found || autoId;
  const messageId = `${id}-message`;
  const message = error ?? success ?? hint;
  // Cloning only makes sense onto a bare control: an explicit id, or an id found inside a wrapper,
  // means the real control is nested and the caller wires its aria attributes itself.
  const wraps = Boolean(explicitId) || (found !== undefined && found !== own);
  const control =
    !wraps && isValidElement(children)
      ? cloneElement(children as ReactElement<Record<string, unknown>>, {
          id,
          'aria-describedby': message ? messageId : undefined,
          'aria-invalid': error ? true : undefined,
          'data-valid': success ? true : undefined,
        })
      : children;

  return (
    <div className={cx(styles.field, className)}>
      <label htmlFor={id} className={cx(styles.label, hideLabel && 'sr-only')}>
        <span>{label}</span>
        {optional && <span className={styles.optional}>Optional</span>}
      </label>
      {control}
      {message && (
        <p id={messageId} className={cx(styles.message, error ? styles.error : success ? styles.success : undefined)} aria-live={error ? 'polite' : undefined}>
          {error && <WarningCircle size={15} />}
          {!error && success && <CheckCircle size={15} />}
          <span>{message}</span>
        </p>
      )}
    </div>
  );
}

type ForceFocus = { forceFocus?: boolean };

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement> & ForceFocus>(function Input({ className, forceFocus, ...rest }, ref) {
  return <input ref={ref} className={cx(styles.control, className)} data-force={forceFocus ? 'focus' : undefined} {...rest} />;
});

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaHTMLAttributes<HTMLTextAreaElement>>(function Textarea({ className, ...rest }, ref) {
  return <textarea ref={ref} className={cx(styles.control, className)} {...rest} />;
});

export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(function Select({ className, children, ...rest }, ref) {
  return (
    <span className={styles.selectWrap}>
      <select ref={ref} className={cx(styles.control, className)} {...rest}>
        {children}
      </select>
      <CaretDown size={13} className={styles.selectCaret} />
    </span>
  );
});

interface SearchInputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'onChange'> {
  value: string;
  onValueChange: (value: string) => void;
  end?: ReactNode;
}

export const SearchInput = forwardRef<HTMLInputElement, SearchInputProps>(function SearchInput({ value, onValueChange, className, end, ...rest }, ref) {
  return (
    <span className={styles.searchWrap}>
      <MagnifyingGlass size={16} className={styles.searchIcon} />
      <input ref={ref} type="search" value={value} onChange={(e) => onValueChange(e.target.value)} className={cx(styles.control, className)} {...rest} />
      <span className={styles.searchEnd}>
        {value ? (
          <button type="button" aria-label="Clear search" onClick={() => onValueChange('')} className={styles.clear}>
            <X size={14} />
          </button>
        ) : (
          end
        )}
      </span>
    </span>
  );
});
