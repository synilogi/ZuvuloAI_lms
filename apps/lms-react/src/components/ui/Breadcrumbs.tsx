import { CaretRight } from '@phosphor-icons/react';
import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';

import styles from './Nav.module.css';

export interface Crumb {
  label: ReactNode;
  /** Omit for the current page (the last crumb). */
  to?: string;
}

export function Breadcrumbs({ items }: { items: Crumb[] }) {
  if (items.length === 0) return null;
  return (
    <nav aria-label="Breadcrumb" className={styles.crumbs}>
      <ol>
        {items.map((crumb, index) => {
          const last = index === items.length - 1;
          return (
            <li key={index}>
              {crumb.to && !last ? <Link to={crumb.to}>{crumb.label}</Link> : <span aria-current={last ? 'page' : undefined}>{crumb.label}</span>}
              {!last && <CaretRight size={12} aria-hidden="true" />}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
