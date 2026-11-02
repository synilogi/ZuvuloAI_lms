import { useRef, type KeyboardEvent, type ReactNode } from 'react';

import styles from './Nav.module.css';

export interface SegmentOption<V extends string> {
  value: V;
  label: ReactNode;
}

export interface SegmentedControlProps<V extends string> {
  options: SegmentOption<V>[];
  value: V;
  onChange: (value: V) => void;
  label: string;
}

/** A small single-choice switcher (grid/list, month/week/list). Radio-group semantics with arrow-key movement. */
export function SegmentedControl<V extends string>({ options, value, onChange, label }: SegmentedControlProps<V>) {
  const buttons = useRef<(HTMLButtonElement | null)[]>([]);

  const onKeyDown = (event: KeyboardEvent<HTMLButtonElement>, index: number) => {
    const step = event.key === 'ArrowRight' || event.key === 'ArrowDown' ? 1 : event.key === 'ArrowLeft' || event.key === 'ArrowUp' ? -1 : 0;
    if (!step) return;
    event.preventDefault();
    const next = (index + step + options.length) % options.length;
    onChange(options[next]!.value);
    buttons.current[next]?.focus();
  };

  return (
    <div className={styles.segmented} role="radiogroup" aria-label={label}>
      {options.map((option, index) => {
        const checked = option.value === value;
        return (
          <button
            key={option.value}
            ref={(element) => {
              buttons.current[index] = element;
            }}
            type="button"
            role="radio"
            aria-checked={checked}
            tabIndex={checked ? 0 : -1}
            className={styles.segment}
            onClick={() => onChange(option.value)}
            onKeyDown={(event) => onKeyDown(event, index)}
          >
            {option.label}
          </button>
        );
      })}
    </div>
  );
}
