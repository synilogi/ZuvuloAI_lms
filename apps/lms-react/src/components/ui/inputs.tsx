import { forwardRef, useState, type InputHTMLAttributes, type ReactNode, type SelectHTMLAttributes, type TextareaHTMLAttributes } from 'react';

import { cx } from '@/lib/cx';

import { useFieldControl } from './Field';
import styles from './Form.module.css';

type NativeInput = Omit<InputHTMLAttributes<HTMLInputElement>, 'type'>;

function useControlProps<P extends { id?: string; className?: string; required?: boolean }>(props: P) {
  const field = useFieldControl(props as Parameters<typeof useFieldControl>[0]);
  return { ...props, ...field, className: cx(styles.control, props.className) };
}

export interface TextInputProps extends NativeInput {
  type?: 'text' | 'email' | 'password' | 'search' | 'tel' | 'url';
}

export const TextInput = forwardRef<HTMLInputElement, TextInputProps>(function TextInput({ type = 'text', ...props }, ref) {
  return <input ref={ref} type={type} {...useControlProps(props)} />;
});

export interface NumberInputProps extends NativeInput {
  /** Whole numbers only (the default) or decimals. */
  decimal?: boolean;
}

export const NumberInput = forwardRef<HTMLInputElement, NumberInputProps>(function NumberInput({ decimal = false, step, ...props }, ref) {
  return <input ref={ref} type="number" inputMode={decimal ? 'decimal' : 'numeric'} step={step ?? (decimal ? 'any' : 1)} {...useControlProps(props)} />;
});

export interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  /** Show "used / max" under the box. Uses `maxLength` when set, else `counterMax` (soft limit). */
  showCounter?: boolean;
  counterMax?: number;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(function Textarea(
  { showCounter = false, counterMax, onChange, value, defaultValue, ...props },
  ref,
) {
  const [length, setLength] = useState(() => String(value ?? defaultValue ?? '').length);
  const max = props.maxLength ?? counterMax;
  const shown = value !== undefined ? String(value).length : length;
  const control = useControlProps(props);
  return (
    <>
      <textarea
        ref={ref}
        value={value}
        defaultValue={defaultValue}
        onChange={(event) => {
          setLength(event.target.value.length);
          onChange?.(event);
        }}
        {...control}
      />
      {showCounter && (
        <span className={cx(styles.counter, max !== undefined && shown > max && styles.counterOver)} aria-live="polite">
          {max !== undefined ? `${shown} / ${max}` : shown}
        </span>
      )}
    </>
  );
});

export interface SelectOption {
  value: string;
  label: string;
  disabled?: boolean;
}

export interface SelectProps extends SelectHTMLAttributes<HTMLSelectElement> {
  options: SelectOption[];
  /** First, empty choice ("Choose a category"). */
  placeholder?: string;
}

/** A native select: accessible, and the platform's own picker on phones (D-12). */
export const Select = forwardRef<HTMLSelectElement, SelectProps>(function Select({ options, placeholder, ...props }, ref) {
  return (
    <select ref={ref} {...useControlProps(props)}>
      {placeholder !== undefined && <option value="">{placeholder}</option>}
      {options.map((option) => (
        <option key={option.value} value={option.value} disabled={option.disabled}>
          {option.label}
        </option>
      ))}
    </select>
  );
});

export const DateInput = forwardRef<HTMLInputElement, NativeInput>(function DateInput(props, ref) {
  return <input ref={ref} type="date" {...useControlProps(props)} />;
});

export const TimeInput = forwardRef<HTMLInputElement, NativeInput>(function TimeInput(props, ref) {
  return <input ref={ref} type="time" {...useControlProps(props)} />;
});

/** Local date and time, in the viewer's time zone. Convert to ISO before sending. */
export const DateTimeInput = forwardRef<HTMLInputElement, NativeInput>(function DateTimeInput(props, ref) {
  return <input ref={ref} type="datetime-local" {...useControlProps(props)} />;
});

export interface DateRange {
  from: string;
  to: string;
}

export interface DateRangeInputProps {
  legend: ReactNode;
  value: DateRange;
  onChange: (value: DateRange) => void;
  fromLabel?: string;
  toLabel?: string;
  disabled?: boolean;
}

export function DateRangeInput({ legend, value, onChange, fromLabel = 'From', toLabel = 'To', disabled }: DateRangeInputProps) {
  return (
    <fieldset className={styles.fieldset} disabled={disabled}>
      <legend className={styles.legend}>{legend}</legend>
      <div className={styles.range}>
        <input
          type="date"
          className={styles.control}
          aria-label={fromLabel}
          value={value.from}
          max={value.to || undefined}
          onChange={(event) => onChange({ ...value, from: event.target.value })}
        />
        <span aria-hidden="true">–</span>
        <input
          type="date"
          className={styles.control}
          aria-label={toLabel}
          value={value.to}
          min={value.from || undefined}
          onChange={(event) => onChange({ ...value, to: event.target.value })}
        />
      </div>
    </fieldset>
  );
}

export interface CheckboxProps extends NativeInput {
  label: ReactNode;
  description?: ReactNode;
}

export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(function Checkbox({ label, description, className, ...props }, ref) {
  return (
    <label className={cx(styles.choice, className)}>
      <input ref={ref} type="checkbox" {...props} />
      <span className={styles.choiceText}>
        <span>{label}</span>
        {description && <span className={styles.choiceDescription}>{description}</span>}
      </span>
    </label>
  );
});

export interface SwitchProps extends NativeInput {
  label: ReactNode;
  description?: ReactNode;
}

/** An on/off setting. A native checkbox with the switch role, so it is keyboard- and form-native. */
export const Switch = forwardRef<HTMLInputElement, SwitchProps>(function Switch({ label, description, className, ...props }, ref) {
  return (
    <label className={cx(styles.choice, className)}>
      <input ref={ref} type="checkbox" role="switch" className={styles.switch} {...props} />
      <span className={styles.choiceText}>
        <span>{label}</span>
        {description && <span className={styles.choiceDescription}>{description}</span>}
      </span>
    </label>
  );
});

export interface RadioOption {
  value: string;
  label: ReactNode;
  description?: ReactNode;
  disabled?: boolean;
}

export interface RadioGroupProps {
  legend: ReactNode;
  name: string;
  options: RadioOption[];
  value?: string;
  onChange?: (value: string) => void;
  inline?: boolean;
  disabled?: boolean;
  error?: ReactNode;
}

export function RadioGroup({ legend, name, options, value, onChange, inline = false, disabled, error }: RadioGroupProps) {
  return (
    <fieldset className={styles.fieldset} disabled={disabled} aria-invalid={error ? true : undefined}>
      <legend className={styles.legend}>{legend}</legend>
      <div className={inline ? styles.inline : undefined}>
        {options.map((option) => (
          <label key={option.value} className={styles.choice}>
            <input
              type="radio"
              name={name}
              value={option.value}
              checked={value === undefined ? undefined : value === option.value}
              disabled={option.disabled}
              onChange={() => onChange?.(option.value)}
            />
            <span className={styles.choiceText}>
              <span>{option.label}</span>
              {option.description && <span className={styles.choiceDescription}>{option.description}</span>}
            </span>
          </label>
        ))}
      </div>
      {error && <p className={styles.error}>{error}</p>}
    </fieldset>
  );
}
