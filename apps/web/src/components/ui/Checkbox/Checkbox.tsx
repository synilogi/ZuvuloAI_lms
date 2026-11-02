import { useEffect, useRef, type InputHTMLAttributes, type ReactNode } from 'react';
import { Check, Minus } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import styles from './Checkbox.module.css';

interface CheckboxProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label: ReactNode;
  hideLabel?: boolean;
  indeterminate?: boolean;
}

export function Checkbox({ label, hideLabel, indeterminate, className, checked, ...rest }: CheckboxProps) {
  const ref = useRef<HTMLInputElement>(null);
  useEffect(() => {
    if (ref.current) ref.current.indeterminate = !!indeterminate;
  }, [indeterminate]);

  return (
    <label className={cx(styles.wrap, className)}>
      <span className={styles.boxWrap}>
        <input ref={ref} type="checkbox" className={styles.input} checked={checked} {...rest} />
        <span className={styles.box} aria-hidden="true">
          {indeterminate ? <Minus size={12} weight="bold" /> : <Check size={12} weight="bold" />}
        </span>
      </span>
      <span className={cx(hideLabel && 'sr-only', styles.label)}>{label}</span>
    </label>
  );
}
