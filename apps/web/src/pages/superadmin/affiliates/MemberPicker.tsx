import { useId, useState } from 'react';
import { useAsync } from '@/hooks/useAsync';
import { useDebouncedInput } from '@/hooks/useDebouncedInput';
import { Button } from '@/components/ui/Button/Button';
import { Field, SearchInput } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { services } from '@/services';
import { AffiliateStatusBadge } from './affiliateMeta';
import styles from './Affiliates.module.css';

export interface PickedMember {
  id: string;
  code: string;
  name: string;
}

interface MemberPickerProps {
  label: string;
  hint?: string;
  value: PickedMember | null;
  onChange: (member: PickedMember | null) => void;
  /** Someone who cannot be chosen here: the member being moved or re-sponsored. */
  excludeId?: string;
}

/** Finds a member by code, name or email and hands back the record, so nobody has to know an internal id. */
export function MemberPicker({ label, hint, value, onChange, excludeId }: MemberPickerProps) {
  const id = useId();
  const [query, setQuery] = useState('');
  const [text, setText] = useDebouncedInput(query, setQuery);
  const search = query.trim();
  const found = useAsync(`affiliates:picker:${search}`, () =>
    search ? services.affiliatesPlatform.listMembers({ search, pageSize: 8 }) : Promise.resolve(null),
  );
  const rows = (found.data?.rows ?? []).filter((m) => m.id !== excludeId);

  if (value) {
    return (
      <Field label={label} hint={hint}>
        <div className={styles.pickerChosen}>
          <span className={styles.stack}>
            <span className={styles.cellTitle}>{value.name}</span>
            <span className={styles.cellMeta}>{value.code}</span>
          </span>
          <Button size="sm" onClick={() => onChange(null)}>
            Change
          </Button>
        </div>
      </Field>
    );
  }

  return (
    <div className={styles.picker}>
      <Field label={label} hint={hint} id={id}>
        <SearchInput id={id} value={text} onValueChange={setText} placeholder="Code or name" autoComplete="off" />
      </Field>
      {!search ? null : found.status === 'error' ? (
        <InlineMessage kind="error" title="The search didn’t work.">
          {found.error.message}
        </InlineMessage>
      ) : found.status === 'loading' && !found.data ? (
        <Skeleton height={56} radius="var(--r-md)" />
      ) : rows.length === 0 ? (
        <p className={styles.muted}>{found.status === 'loading' ? 'Searching…' : 'Nobody matches that code or name.'}</p>
      ) : (
        <ul className={styles.pickerList} aria-label="Matching members">
          {rows.map((m) => (
            <li key={m.id}>
              <button
                type="button"
                className={styles.pickerOption}
                onClick={() => {
                  setText('');
                  setQuery('');
                  onChange({ id: m.id, code: m.code, name: m.name });
                }}
              >
                <span className={styles.stack}>
                  <span className={styles.cellTitle}>{m.name}</span>
                  <span className={styles.cellMeta}>{m.code}</span>
                </span>
                <AffiliateStatusBadge status={m.status} />
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
