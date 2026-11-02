import type { ReactNode } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { cx } from '@/lib/cx';
import styles from './RouteTabs.module.css';

export interface RouteTab {
  to: string;
  label: string;
  icon?: ReactNode;
  count?: number;
  /** Match the path exactly — for the first tab, whose path prefixes the others. */
  end?: boolean;
  /** Other path prefixes that belong to this tab, e.g. a chapter page under Curriculum. */
  also?: string[];
}

/** Sub-pages of one record (Overview, Curriculum, Lessons) as links in the shell's pill track. */
export function RouteTabs({ label, tabs }: { label: string; tabs: RouteTab[] }) {
  const { pathname } = useLocation();
  return (
    <nav aria-label={label} className={styles.track}>
      {tabs.map((tab) => {
        const also = tab.also?.some((prefix) => pathname.startsWith(prefix));
        return (
          <NavLink
            key={tab.to}
            to={tab.to}
            end={tab.end}
            className={({ isActive }) => cx(styles.tab, (isActive || also) && styles.active)}
            aria-current={also ? 'page' : undefined}
          >
            {tab.icon}
            <span>{tab.label}</span>
            {tab.count !== undefined && <span className={styles.count}>{tab.count.toLocaleString('en-IN')}</span>}
          </NavLink>
        );
      })}
    </nav>
  );
}
