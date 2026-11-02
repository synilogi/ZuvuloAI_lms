import { useEffect, useId, useRef, useState, type KeyboardEvent } from 'react';

import { cx } from '@/lib/cx';

import { useFieldControl } from './Field';
import styles from './Form.module.css';

export interface ComboboxOption {
  value: string;
  label: string;
  /** Secondary text under the label (email, course code…). */
  description?: string;
}

export interface ComboboxProps {
  /** Options to show for the current text. The caller filters them (locally or from the API). */
  options: ComboboxOption[];
  value: ComboboxOption | null;
  onChange: (option: ComboboxOption | null) => void;
  /** Called as the user types — use it to filter or to query the API. */
  onInputChange?: (text: string) => void;
  id?: string;
  placeholder?: string;
  loading?: boolean;
  emptyText?: string;
  disabled?: boolean;
}

/** Single-choice combobox following the ARIA 1.2 pattern (text input + listbox, arrow keys, Enter, Escape). */
export function Combobox({ options, value, onChange, onInputChange, id, placeholder, loading = false, emptyText = 'No matches', disabled }: ComboboxProps) {
  const control = useFieldControl({ id });
  const listId = useId();
  const [open, setOpen] = useState(false);
  const [text, setText] = useState(value?.label ?? '');
  const [active, setActive] = useState(0);
  const root = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setText(value?.label ?? '');
  }, [value]);

  useEffect(() => {
    if (!open) return;
    const close = (event: MouseEvent) => {
      if (!root.current?.contains(event.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);

  const choose = (option: ComboboxOption) => {
    onChange(option);
    setText(option.label);
    setOpen(false);
  };

  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      if (!open) setOpen(true);
      else setActive((index) => Math.min(index + 1, options.length - 1));
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      setActive((index) => Math.max(index - 1, 0));
    } else if (event.key === 'Enter' && open) {
      event.preventDefault();
      const option = options[active];
      if (option) choose(option);
    } else if (event.key === 'Escape') {
      if (open) {
        event.preventDefault();
        setOpen(false);
      } else if (value) {
        onChange(null);
        setText('');
      }
    }
  };

  const activeId = open && options[active] ? `${listId}-${active}` : undefined;

  return (
    <div className={styles.combo} ref={root}>
      <input
        {...control}
        className={styles.control}
        role="combobox"
        aria-expanded={open}
        aria-controls={listId}
        aria-autocomplete="list"
        aria-activedescendant={activeId}
        autoComplete="off"
        value={text}
        placeholder={placeholder}
        disabled={disabled}
        onChange={(event) => {
          setText(event.target.value);
          setActive(0);
          setOpen(true);
          onInputChange?.(event.target.value);
          if (value && event.target.value === '') onChange(null);
        }}
        onFocus={() => setOpen(true)}
        onKeyDown={onKeyDown}
      />
      {open && (
        <ul id={listId} role="listbox" className={styles.listbox}>
          {loading ? (
            <li className={styles.optionEmpty} aria-live="polite">
              Loading…
            </li>
          ) : options.length === 0 ? (
            <li className={styles.optionEmpty}>{emptyText}</li>
          ) : (
            options.map((option, index) => (
              // Keyboard selection happens on the input (aria-activedescendant); the click is the pointer path.
              <li
                key={option.value}
                id={`${listId}-${index}`}
                role="option"
                aria-selected={value?.value === option.value}
                className={cx(styles.option, index === active && styles.optionActive)}
                onMouseDown={(event) => event.preventDefault()}
                onMouseEnter={() => setActive(index)}
                onClick={() => choose(option)}
              >
                <div>{option.label}</div>
                {option.description && <div className={styles.choiceDescription}>{option.description}</div>}
              </li>
            ))
          )}
        </ul>
      )}
    </div>
  );
}
