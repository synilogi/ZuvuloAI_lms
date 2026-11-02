import { Children, createContext, useCallback, useContext, useEffect, useMemo, useState, type CSSProperties, type ReactNode } from 'react';
import { cx } from '@/lib/cx';
import { pad2 } from '@/lib/format';
import styles from './Doc.module.css';

/* ─── Section registry (feeds "On this page") ───────────────────────────── */

interface Entry {
  id: string;
  title: string;
  index: number;
}

interface Registry {
  entries: Entry[];
  register: (entry: Entry) => () => void;
}

const SectionRegistry = createContext<Registry | null>(null);

export function SectionRegistryProvider({ children }: { children: ReactNode }) {
  const [entries, setEntries] = useState<Entry[]>([]);
  const register = useCallback((entry: Entry) => {
    setEntries((prev) => [...prev.filter((e) => e.id !== entry.id), entry].sort((a, b) => a.index - b.index));
    return () => setEntries((prev) => prev.filter((e) => e.id !== entry.id));
  }, []);
  const value = useMemo(() => ({ entries, register }), [entries, register]);
  return <SectionRegistry.Provider value={value}>{children}</SectionRegistry.Provider>;
}

export const useSectionEntries = () => useContext(SectionRegistry)?.entries ?? [];

/* ─── Chapter intro ─────────────────────────────────────────────────────── */

export function ChapterIntro({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className={styles.chapterIntro}>
      <h2 className={styles.chapterTitle}>{title}</h2>
      <p className={styles.chapterLead}>{children}</p>
    </div>
  );
}

/* ─── Section ───────────────────────────────────────────────────────────── */

interface DocSectionProps {
  id: string;
  index: number;
  title: string;
  lead?: ReactNode;
  children: ReactNode;
  /** Components the section documents — shown as a quiet reference line. */
  api?: string[];
}

export function DocSection({ id, index, title, lead, children, api }: DocSectionProps) {
  const register = useContext(SectionRegistry)?.register;
  useEffect(() => register?.({ id, title, index }), [register, id, title, index]);

  return (
    <section id={id} className={styles.section} aria-labelledby={`${id}-title`}>
      <header className={styles.sectionHead}>
        <span className={styles.sectionIndex} aria-hidden="true">
          {pad2(index)}
        </span>
        <div className={styles.sectionHeadText}>
          <h2 id={`${id}-title`} className={styles.sectionTitle}>
            {title}
          </h2>
          {lead && <p className={styles.sectionLead}>{lead}</p>}
          {api && (
            <p className={styles.api}>
              {api.map((name) => (
                <code key={name}>{name}</code>
              ))}
            </p>
          )}
        </div>
      </header>
      <div className={styles.sectionBody}>{children}</div>
    </section>
  );
}

/* ─── Specimen ──────────────────────────────────────────────────────────── */

interface SpecimenProps {
  label?: string;
  /**
   * page — sits directly on the page (journeys, timelines, type).
   * panel — on a primary surface, for components that live on surfaces in product.
   * sunken — a secondary surface, for comparisons and state grids.
   */
  surface?: 'page' | 'panel' | 'sunken';
  notes?: ReactNode;
  toolbar?: ReactNode;
  density?: 'immersive' | 'balanced' | 'dense';
  children: ReactNode;
  className?: string;
}

export function Specimen({ label, surface = 'page', notes, toolbar, density, children, className }: SpecimenProps) {
  return (
    <div className={cx(styles.specimen, notes && styles.withNotes, className)}>
      <div className={styles.specimenMain}>
        {(label || toolbar) && (
          <div className={styles.specimenBar}>
            {label && <span className={styles.specimenLabel}>{label}</span>}
            {toolbar && <div className={styles.specimenToolbar}>{toolbar}</div>}
          </div>
        )}
        <div className={cx(styles.stage, styles[surface])} data-density={density}>
          {children}
        </div>
      </div>
      {notes && <aside className={styles.notes}>{notes}</aside>}
    </div>
  );
}

/* ─── Notes ─────────────────────────────────────────────────────────────── */

export function Notes({ items }: { items: { term: string; text: ReactNode }[] }) {
  return (
    <dl className={styles.noteList}>
      {items.map((item) => (
        <div key={item.term}>
          <dt>{item.term}</dt>
          <dd>{item.text}</dd>
        </div>
      ))}
    </dl>
  );
}

export function Token({ children }: { children: ReactNode }) {
  return <code className={styles.token}>{children}</code>;
}

/* ─── Columns — side-by-side specimens separated by hairlines, not boxes ── */

export function Columns({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={cx(styles.columns, className)} style={{ '--cols': Children.count(children) } as CSSProperties}>
      {children}
    </div>
  );
}

export function Column({ title, children, caption }: { title?: string; caption?: ReactNode; children: ReactNode }) {
  return (
    <div className={styles.column}>
      {title && <h3 className={styles.columnTitle}>{title}</h3>}
      {caption && <p className={styles.columnCaption}>{caption}</p>}
      {children}
    </div>
  );
}
