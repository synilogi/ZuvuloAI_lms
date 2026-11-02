import { MagnifyingGlass, X } from '@phosphor-icons/react';
import { useEffect, useRef, useState } from 'react';

import { IconButton } from '@/components/ui/Button';

import styles from './Data.module.css';

export interface SearchInputProps {
  /** The applied search (usually from the URL). */
  value: string;
  /** Called after the user pauses typing (debounced), on Enter, and on clear. */
  onChange: (value: string) => void;
  label: string;
  placeholder?: string;
  debounceMs?: number;
}

export function SearchInput({ value, onChange, label, placeholder, debounceMs = 300 }: SearchInputProps) {
  const [draft, setDraft] = useState(value);
  const latest = useRef(onChange);
  latest.current = onChange;

  useEffect(() => {
    setDraft(value);
  }, [value]);

  useEffect(() => {
    if (draft === value) return;
    const timer = window.setTimeout(() => latest.current(draft.trim()), debounceMs);
    return () => window.clearTimeout(timer);
  }, [draft, value, debounceMs]);

  return (
    <div className={styles.search} role="search">
      <MagnifyingGlass size={16} className={styles.searchIcon} aria-hidden="true" />
      <input
        type="search"
        className={styles.searchInput}
        aria-label={label}
        placeholder={placeholder ?? label}
        value={draft}
        onChange={(event) => setDraft(event.target.value)}
        onKeyDown={(event) => {
          if (event.key === 'Enter') onChange(draft.trim());
          if (event.key === 'Escape' && draft) {
            event.preventDefault();
            setDraft('');
            onChange('');
          }
        }}
      />
      {draft && (
        <IconButton
          className={styles.searchClear}
          label="Clear search"
          icon={<X size={14} />}
          size="sm"
          onClick={() => {
            setDraft('');
            onChange('');
          }}
        />
      )}
    </div>
  );
}
