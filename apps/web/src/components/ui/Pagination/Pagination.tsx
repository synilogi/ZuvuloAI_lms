import { CaretLeft, CaretRight } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import { IconButton } from '../Button/Button';
import styles from './Pagination.module.css';

interface PaginationProps {
  page: number;
  pageCount: number;
  onChange: (page: number) => void;
  summary?: string;
}

/** Page numbers to show: all of them when few, otherwise the ends and the pages around the current one. */
export function pageWindow(page: number, pageCount: number): (number | 'gap')[] {
  if (pageCount <= 7) return Array.from({ length: pageCount }, (_, i) => i + 1);
  const from = Math.max(2, Math.min(page - 1, pageCount - 4));
  const to = Math.min(pageCount - 1, Math.max(page + 1, 5));
  const middle = Array.from({ length: to - from + 1 }, (_, i) => from + i);
  return [1, ...(from > 2 ? ['gap' as const] : []), ...middle, ...(to < pageCount - 1 ? ['gap' as const] : []), pageCount];
}

export function Pagination({ page, pageCount, onChange, summary }: PaginationProps) {
  const pages = pageWindow(page, pageCount);
  return (
    <nav className={styles.bar} aria-label="Pagination">
      {summary && <span className={styles.summary}>{summary}</span>}
      <div className={styles.pages}>
        <IconButton label="Previous page" boxed icon={<CaretLeft size={15} />} disabled={page <= 1} onClick={() => onChange(page - 1)} />
        {pages.map((p, i) =>
          p === 'gap' ? (
            <span key={`gap-${i}`} className={styles.gap} aria-hidden="true">
              …
            </span>
          ) : (
            <button
              key={p}
              type="button"
              aria-current={p === page ? 'page' : undefined}
              aria-label={`Page ${p}`}
              className={cx(styles.page, p === page && styles.current)}
              onClick={() => onChange(p)}
            >
              {p}
            </button>
          ),
        )}
        <IconButton label="Next page" boxed icon={<CaretRight size={15} />} disabled={page >= pageCount} onClick={() => onChange(page + 1)} />
      </div>
    </nav>
  );
}
