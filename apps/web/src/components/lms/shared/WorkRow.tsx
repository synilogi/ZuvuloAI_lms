import type { ReactNode } from 'react';
import { cx } from '@/lib/cx';
import { dateParts } from '@/lib/format';
import styles from './WorkRow.module.css';

interface WorkRowProps {
  lead: ReactNode;
  title: ReactNode;
  eyebrow?: ReactNode;
  meta?: ReactNode;
  status?: ReactNode;
  action?: ReactNode;
  /** Draws attention to the row without a container — used for live and overdue items. */
  emphasis?: 'live' | 'attention';
  muted?: boolean;
  as?: 'li' | 'div';
}

/**
 * The shared anatomy of a scheduled or gradable item — lead, what, state, next step.
 * Rows sit on hairlines, not in cards. Wide containers align state and action in columns;
 * narrow containers stack them under the title with the action full width.
 */
export function WorkRow({ lead, title, eyebrow, meta, status, action, emphasis, muted, as: Tag = 'li' }: WorkRowProps) {
  return (
    <Tag className={cx(styles.row, Tag === 'div' && styles.standalone, emphasis && styles[emphasis], muted && styles.muted)}>
      <span className={styles.lead}>{lead}</span>
      <span className={styles.main}>
        {eyebrow && <span className={styles.eyebrow}>{eyebrow}</span>}
        <span className={styles.title}>{title}</span>
        {meta && <span className={styles.meta}>{meta}</span>}
      </span>
      {status && <span className={styles.status}>{status}</span>}
      {action && <span className={styles.action}>{action}</span>}
    </Tag>
  );
}

export function WorkList({ children, label }: { children: ReactNode; label: string }) {
  return (
    <div className={styles.listWrap}>
      <ul className={styles.list} aria-label={label}>
        {children}
      </ul>
    </div>
  );
}

/** Calendar-leaf date for scheduled items. */
export function DateBlock({ iso, highlight }: { iso: string; highlight?: boolean }) {
  const { day, month, weekday } = dateParts(iso);
  return (
    <span className={cx(styles.date, highlight && styles.dateHighlight)} aria-hidden="true">
      <span className={styles.dateWeekday}>{weekday}</span>
      <span className={styles.dateDay}>{day}</span>
      <span className={styles.dateMonth}>{month}</span>
    </span>
  );
}
