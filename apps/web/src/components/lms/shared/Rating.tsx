import { Star } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import styles from './Rating.module.css';

/** A course or instructor rating. The number carries the value; the star only marks what it is. */
export function Rating({
  value,
  count,
  size = 'sm',
  empty = 'No ratings yet',
}: {
  value: number | null | undefined;
  count?: number;
  size?: 'sm' | 'lg';
  empty?: string;
}) {
  if (!value) return <span className={styles.empty}>{empty}</span>;
  return (
    <span className={cx(styles.rating, size === 'lg' && styles.large)}>
      <Star size={size === 'lg' ? 18 : 13} weight="fill" aria-hidden="true" className={styles.star} />
      <span className="tabular">{value.toFixed(1)}</span>
      <span className="sr-only"> out of 5</span>
      {count !== undefined && (
        <span className={styles.count}>
          ({count.toLocaleString('en-IN')}
          <span className="sr-only"> ratings</span>)
        </span>
      )}
    </span>
  );
}
