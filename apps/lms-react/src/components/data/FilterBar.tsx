import { Funnel } from '@phosphor-icons/react';
import { useState, type ReactNode } from 'react';

import { Button } from '@/components/ui/Button';
import { BottomSheet } from '@/components/ui/Dialog';
import { useBreakpoint } from '@/lib/useMediaQuery';

import styles from './Data.module.css';

export interface FilterBarProps {
  /** Usually a SearchInput; always visible. */
  search?: ReactNode;
  /** Filter controls (selects, status chips). Inline from 640px; in a bottom sheet below. */
  filters?: ReactNode;
  /** How many filters differ from their defaults — shown on the mobile button. */
  activeCount?: number;
  onClear?: () => void;
  /** Right-hand actions (view toggle, export…). */
  actions?: ReactNode;
}

export function FilterBar({ search, filters, activeCount = 0, onClear, actions }: FilterBarProps) {
  const wide = useBreakpoint('sm');
  const [open, setOpen] = useState(false);

  return (
    <div className={styles.filterBar}>
      {search && <div className={styles.filterSearch}>{search}</div>}
      {filters &&
        (wide ? (
          <div className={styles.filterControls}>
            {filters}
            {onClear && activeCount > 0 && (
              <Button variant="ghost" size="sm" onClick={onClear}>
                Clear filters
              </Button>
            )}
          </div>
        ) : (
          <>
            <Button icon={<Funnel size={16} />} onClick={() => setOpen(true)} aria-haspopup="dialog">
              Filters{activeCount > 0 ? ` (${activeCount})` : ''}
            </Button>
            <FilterSheet open={open} onOpenChange={setOpen} onClear={activeCount > 0 ? onClear : undefined}>
              {filters}
            </FilterSheet>
          </>
        ))}
      {actions && <div className={styles.filterActions}>{actions}</div>}
    </div>
  );
}

export interface FilterSheetProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  children: ReactNode;
  onClear?: () => void;
}

/** Filters on phones. Changes apply as they are made; "Show results" closes the sheet. */
export function FilterSheet({ open, onOpenChange, children, onClear }: FilterSheetProps) {
  return (
    <BottomSheet
      open={open}
      onOpenChange={onOpenChange}
      title="Filters"
      footer={
        <>
          {onClear && <Button onClick={onClear}>Clear filters</Button>}
          <Button variant="primary" onClick={() => onOpenChange(false)}>
            Show results
          </Button>
        </>
      }
    >
      <div className={styles.sheetFilters}>{children}</div>
    </BottomSheet>
  );
}
