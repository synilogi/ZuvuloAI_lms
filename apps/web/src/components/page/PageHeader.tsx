import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { ArrowLeft } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import styles from './Page.module.css';

interface PageHeaderProps {
  title: ReactNode;
  /** The shell's pill eyebrow — a date, a workspace or a record type. */
  eyebrow?: ReactNode;
  /** Quiet figure beside the title, e.g. "16 courses". */
  count?: ReactNode;
  description?: ReactNode;
  actions?: ReactNode;
  /** Parent destination for detail pages. The shell breadcrumb stays the primary path back. */
  back?: { label: string; to: string };
  /** Extra line under the description — status, metadata. */
  meta?: ReactNode;
  className?: string;
}

/** The shell's page header: pill eyebrow, 34/26px display title, 15px lead at 64ch, actions aligned to the title's baseline. */
export function PageHeader({ title, eyebrow, count, description, actions, back, meta, className }: PageHeaderProps) {
  return (
    <header className={cx(styles.header, className)}>
      <div className={styles.headerText}>
        {back && (
          <Link to={back.to} className={styles.back}>
            <ArrowLeft size={14} aria-hidden="true" />
            {back.label}
          </Link>
        )}
        {eyebrow && <span className={styles.eyebrow}>{eyebrow}</span>}
        <h1 className={styles.title}>
          {title}
          {count !== undefined && <span className={styles.count}>{count}</span>}
        </h1>
        {description && <p className={styles.description}>{description}</p>}
        {meta && <div className={styles.meta}>{meta}</div>}
      </div>
      {actions && <div className={styles.actions}>{actions}</div>}
    </header>
  );
}

interface SectionHeaderProps {
  title: ReactNode;
  description?: ReactNode;
  actions?: ReactNode;
  id?: string;
  as?: 'h2' | 'h3';
  count?: ReactNode;
}

/** Section heading inside a page. Hierarchy comes from type and a hairline, not a container. */
export function SectionHeader({ title, description, actions, id, as: Heading = 'h2', count }: SectionHeaderProps) {
  return (
    <div className={styles.sectionHead}>
      <div className={styles.sectionText}>
        <Heading id={id} className={styles.sectionTitle}>
          {title}
          {count !== undefined && <span className={styles.sectionCount}>{count}</span>}
        </Heading>
        {description && <p className={styles.sectionDescription}>{description}</p>}
      </div>
      {actions && <div className={styles.sectionActions}>{actions}</div>}
    </div>
  );
}
