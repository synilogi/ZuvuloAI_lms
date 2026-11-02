import { CheckCircle, XCircle } from '@phosphor-icons/react';
import type { HTMLAttributes, ReactNode } from 'react';

import { cx } from '@/lib/cx';

import styles from './Display.module.css';

export type Tone = 'neutral' | 'accent' | 'success' | 'info' | 'warn' | 'danger';

export interface BadgeProps {
  tone?: Tone;
  children: ReactNode;
  /** Hide the leading dot. */
  plain?: boolean;
  className?: string;
}

export function Badge({ tone = 'neutral', plain = false, className, children }: BadgeProps) {
  return <span className={cx(styles.badge, styles[tone], plain && styles.plain, className)}>{children}</span>;
}

/** How one status value looks: its tone and its words. */
export interface StatusStyle {
  tone: Tone;
  label: string;
}

/**
 * Declares how the statuses of one domain (course, lesson, subscription…) render. Each module defines its map once
 * and every screen reuses it, so "past_due" never reads differently on two pages.
 */
export function defineStatusMap<S extends string>(map: Record<S, StatusStyle>): Record<S, StatusStyle> {
  return map;
}

export interface StatusBadgeProps<S extends string> {
  status: S;
  map: Record<S, StatusStyle>;
}

/** Renders a status through its domain's map. An unknown value shows as neutral with its raw text. */
export function StatusBadge<S extends string>({ status, map }: StatusBadgeProps<S>) {
  const style = map[status] ?? { tone: 'neutral' as const, label: String(status) };
  return <Badge tone={style.tone}>{style.label}</Badge>;
}

export function Tag({ children, className }: { children: ReactNode; className?: string }) {
  return <span className={cx(styles.tag, className)}>{children}</span>;
}

export interface CardProps extends Omit<HTMLAttributes<HTMLElement>, 'title'> {
  title?: ReactNode;
  description?: ReactNode;
  /** Actions shown at the top right of the card. */
  actions?: ReactNode;
  /** Heading level of the title (defaults to h2). */
  headingLevel?: 2 | 3 | 4;
}

export function Card({ title, description, actions, headingLevel = 2, className, children, ...rest }: CardProps) {
  const Heading = `h${headingLevel}` as const;
  return (
    <section className={cx(styles.card, className)} {...rest}>
      {(title || actions) && (
        <header className={styles.cardHeader}>
          <div>
            {title && <Heading className={styles.cardTitle}>{title}</Heading>}
            {description && <p className={styles.cardDescription}>{description}</p>}
          </div>
          {actions}
        </header>
      )}
      {children}
    </section>
  );
}

export interface AvatarProps {
  name: string;
  src?: string | null;
  size?: number;
}

export const initials = (name: string) =>
  name
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]!.toUpperCase())
    .join('') || '?';

/** A person's picture, or their initials when there is none. The name is the accessible label. */
export function Avatar({ name, src, size = 36 }: AvatarProps) {
  return (
    <span className={styles.avatar} style={{ width: size, height: size, fontSize: Math.round(size * 0.38) }} role="img" aria-label={name}>
      {src ? <img src={src} alt="" /> : <span aria-hidden="true">{initials(name)}</span>}
    </span>
  );
}

export interface KeyValueListProps {
  items: { label: ReactNode; value: ReactNode }[];
  className?: string;
}

export function KeyValueList({ items, className }: KeyValueListProps) {
  return (
    <dl className={cx(styles.kv, className)}>
      {items.map((item, index) => (
        <div key={index} style={{ display: 'contents' }}>
          <dt>{item.label}</dt>
          <dd>{item.value ?? '—'}</dd>
        </div>
      ))}
    </dl>
  );
}

const clampPercent = (value: number) => Math.max(0, Math.min(100, Number.isFinite(value) ? value : 0));

export interface ProgressBarProps {
  /** 0–100. */
  value: number;
  label: string;
  /** Show the label and percentage above the bar. */
  showLabel?: boolean;
}

export function ProgressBar({ value, label, showLabel = false }: ProgressBarProps) {
  const percent = clampPercent(value);
  return (
    <div className={styles.progress}>
      {showLabel && (
        <div className={styles.progressLabel}>
          <span>{label}</span>
          <span>{Math.round(percent)}%</span>
        </div>
      )}
      <div className={styles.track} role="progressbar" aria-label={label} aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(percent)}>
        <div className={styles.fill} style={{ width: `${percent}%` }} />
      </div>
    </div>
  );
}

export function ProgressRing({ value, label, size = 44 }: { value: number; label: string; size?: number }) {
  const percent = clampPercent(value);
  const stroke = 4;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  return (
    <span className={styles.ring} role="progressbar" aria-label={label} aria-valuemin={0} aria-valuemax={100} aria-valuenow={Math.round(percent)}>
      <svg width={size} height={size} aria-hidden="true">
        <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke="var(--track)" strokeWidth={stroke} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--accent)"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={circumference * (1 - percent / 100)}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      <span className={styles.ringValue} aria-hidden="true">
        {Math.round(percent)}%
      </span>
    </span>
  );
}

export interface KpiChange {
  direction: 'up' | 'down' | 'flat';
  /** Already formatted ("+12%", "−3 pts"); REACT-006 computes it with the domain's kpiChange. */
  label: string;
  /** Whether "up" is good (default) — a rise in overdue reviews is not. */
  upIsGood?: boolean;
  /** What the change compares against ("vs previous 30 days"). */
  context?: string;
}

export interface KpiTileProps {
  label: string;
  value: ReactNode;
  change?: KpiChange;
}

export function KpiTile({ label, value, change }: KpiTileProps) {
  const good = change && change.direction !== 'flat' && (change.direction === 'up') === (change.upIsGood ?? true);
  const toneClass = !change || change.direction === 'flat' ? styles.flat : good ? styles.up : styles.down;
  return (
    <div className={styles.kpi}>
      <span className={styles.kpiLabel}>{label}</span>
      <span className={styles.kpiValue}>{value}</span>
      {change && (
        <span className={cx(styles.kpiChange, toneClass)}>
          <span className="visually-hidden">{change.direction === 'up' ? 'Up' : change.direction === 'down' ? 'Down' : 'No change'} </span>
          {change.label}
          {change.context ? ` ${change.context}` : ''}
        </span>
      )}
    </div>
  );
}

export interface TimelineItem {
  id: string;
  title: ReactNode;
  /** When, already formatted. */
  meta?: ReactNode;
  body?: ReactNode;
}

export function Timeline({ items, label }: { items: TimelineItem[]; label: string }) {
  return (
    <ol className={styles.timeline} aria-label={label}>
      {items.map((item) => (
        <li key={item.id} className={styles.timelineItem}>
          <div>{item.title}</div>
          {item.meta && <div className={styles.timelineMeta}>{item.meta}</div>}
          {item.body && <div>{item.body}</div>}
        </li>
      ))}
    </ol>
  );
}

export interface ChecklistItem {
  id: string;
  label: ReactNode;
  done: boolean;
}

/** Pass/fail requirements, e.g. a course's publish checklist. Status is in text, not colour alone. */
export function Checklist({ items, label }: { items: ChecklistItem[]; label: string }) {
  return (
    <ul className={styles.checklist} aria-label={label}>
      {items.map((item) => (
        <li key={item.id} className={styles.checkItem}>
          {item.done ? (
            <CheckCircle size={18} weight="fill" className={styles.checkDone} aria-hidden="true" />
          ) : (
            <XCircle size={18} weight="fill" className={styles.checkOpen} aria-hidden="true" />
          )}
          <span>
            <span className="visually-hidden">{item.done ? 'Done: ' : 'Not done: '}</span>
            {item.label}
          </span>
        </li>
      ))}
    </ul>
  );
}
