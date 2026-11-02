import type { ReactNode } from 'react';

import { Breadcrumbs, type Crumb } from '@/components/ui/Breadcrumbs';

import styles from './PageHeader.module.css';

export interface PageHeaderProps {
  title: ReactNode;
  subtitle?: ReactNode;
  breadcrumbs?: Crumb[];
  /** Total shown next to the title ("24 courses"). */
  count?: ReactNode;
  /** The page's main action; rendered last. */
  primaryAction?: ReactNode;
  /** Other actions, before the primary one. */
  secondaryActions?: ReactNode;
}

/** The top of every page: one h1, optional breadcrumbs, count and actions. */
export function PageHeader({ title, subtitle, breadcrumbs, count, primaryAction, secondaryActions }: PageHeaderProps) {
  return (
    <header className={styles.header}>
      {breadcrumbs && <Breadcrumbs items={breadcrumbs} />}
      <div className={styles.row}>
        <div className={styles.titles}>
          <h1 className={styles.title}>
            {title}
            {count !== undefined && <span className={styles.count}>{count}</span>}
          </h1>
          {subtitle && <p className={styles.subtitle}>{subtitle}</p>}
        </div>
        {(secondaryActions || primaryAction) && (
          <div className={styles.actions}>
            {secondaryActions}
            {primaryAction}
          </div>
        )}
      </div>
    </header>
  );
}
