import { CaretLeft, CaretRight } from '@phosphor-icons/react';
import { useId } from 'react';

import { IconButton } from './Button';
import styles from './Nav.module.css';

export const PAGE_SIZES = [10, 25, 50] as const;

export interface PaginationProps {
  /** 1-based. */
  page: number;
  pageSize: number;
  total: number;
  onPageChange: (page: number) => void;
  onPageSizeChange?: (pageSize: number) => void;
  /** What is being paged, for the accessible name ("courses"). */
  noun?: string;
}

export function Pagination({ page, pageSize, total, onPageChange, onPageSizeChange, noun = 'results' }: PaginationProps) {
  const sizeId = useId();
  const pages = Math.max(1, Math.ceil(total / pageSize));
  const current = Math.min(Math.max(1, page), pages);
  const from = total === 0 ? 0 : (current - 1) * pageSize + 1;
  const to = Math.min(total, current * pageSize);

  return (
    <nav className={styles.pagination} aria-label={`Pagination for ${noun}`}>
      <span aria-live="polite">
        {from}–{to} of {total} {noun}
      </span>
      <div className={styles.pages}>
        {onPageSizeChange && (
          <span className={styles.pageSize}>
            <label htmlFor={sizeId}>Rows per page</label>
            <select id={sizeId} value={pageSize} onChange={(event) => onPageSizeChange(Number(event.target.value))}>
              {PAGE_SIZES.map((size) => (
                <option key={size} value={size}>
                  {size}
                </option>
              ))}
            </select>
          </span>
        )}
        <IconButton
          label="Previous page"
          icon={<CaretLeft size={16} />}
          size="sm"
          variant="secondary"
          disabled={current <= 1}
          onClick={() => onPageChange(current - 1)}
        />
        <span>
          Page {current} of {pages}
        </span>
        <IconButton
          label="Next page"
          icon={<CaretRight size={16} />}
          size="sm"
          variant="secondary"
          disabled={current >= pages}
          onClick={() => onPageChange(current + 1)}
        />
      </div>
    </nav>
  );
}
