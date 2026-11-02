import type { ReactNode } from 'react';
import { cx } from '@/lib/cx';
import styles from './Charts.module.css';

export interface BarListItem {
  key: string;
  label: ReactNode;
  value: number;
  /** Formatted value beside the bar; defaults to the number. */
  display?: ReactNode;
  /** A quieter second figure after the value, e.g. a completion rate. */
  note?: ReactNode;
}

/**
 * Ranked horizontal bars for comparing a handful of categories. One hue, one measure, the value
 * written beside every bar so nothing depends on reading bar length alone.
 */
export function BarList({ items, label, max, className }: { items: BarListItem[]; label: string; max?: number; className?: string }) {
  const top = max ?? Math.max(1, ...items.map((i) => i.value));
  return (
    <ul className={cx(styles.barList, className)} aria-label={label}>
      {items.map((item) => (
        <li key={item.key} className={styles.barItem}>
          <span className={styles.barLabel}>{item.label}</span>
          <span className={styles.barTrack} aria-hidden="true">
            <span className={styles.barValueFill} style={{ width: `${Math.max(item.value > 0 ? 1.5 : 0, (item.value / top) * 100)}%` }} />
          </span>
          <span className={styles.barFigure}>
            <span className="tabular">{item.display ?? item.value.toLocaleString('en-IN')}</span>
            {item.note && <span className={styles.barNote}>{item.note}</span>}
          </span>
        </li>
      ))}
    </ul>
  );
}
