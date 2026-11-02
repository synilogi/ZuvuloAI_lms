import { X } from '@phosphor-icons/react';
import { useState, type KeyboardEvent } from 'react';

import { cx } from '@/lib/cx';

import { Tag } from './display';
import { useFieldControl } from './Field';
import displayStyles from './Display.module.css';
import styles from './Form.module.css';

export interface TagInputProps {
  value: string[];
  onChange: (value: string[]) => void;
  id?: string;
  placeholder?: string;
  /** Largest number of tags; further input is ignored. */
  max?: number;
  disabled?: boolean;
}

/** A list of short free-text values. Enter or comma adds; Backspace on an empty box removes the last. */
export function TagInput({ value, onChange, id, placeholder = 'Type and press Enter', max, disabled }: TagInputProps) {
  const [draft, setDraft] = useState('');
  const control = useFieldControl({ id });

  const add = () => {
    const next = draft.trim();
    if (!next || value.some((tag) => tag.toLowerCase() === next.toLowerCase()) || (max !== undefined && value.length >= max)) {
      setDraft('');
      return;
    }
    onChange([...value, next]);
    setDraft('');
  };

  const onKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === 'Enter' || event.key === ',') {
      event.preventDefault();
      add();
    } else if (event.key === 'Backspace' && draft === '' && value.length > 0) {
      onChange(value.slice(0, -1));
    }
  };

  return (
    <div className={cx(styles.control, styles.tags)}>
      {value.map((tag) => (
        <Tag key={tag}>
          {tag}
          <button
            type="button"
            aria-label={`Remove ${tag}`}
            disabled={disabled}
            onClick={() => onChange(value.filter((t) => t !== tag))}
            className={displayStyles.tagRemove}
          >
            <X size={12} aria-hidden="true" />
          </button>
        </Tag>
      ))}
      <input
        {...control}
        className={styles.tagsInput}
        value={draft}
        placeholder={value.length === 0 ? placeholder : undefined}
        disabled={disabled}
        onChange={(event) => setDraft(event.target.value)}
        onKeyDown={onKeyDown}
        onBlur={add}
      />
    </div>
  );
}
