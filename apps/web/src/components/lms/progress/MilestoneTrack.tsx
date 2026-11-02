import type { CSSProperties, ReactNode } from 'react';
import { Check } from '@phosphor-icons/react';
import { clampPercent } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import styles from './MilestoneTrack.module.css';

export interface Milestone {
  id: string;
  /** Position on the track, 0–100. */
  at: number;
  label: string;
  detail?: string;
  icon?: ReactNode;
  /** The milestone the learner is working toward right now — e.g. certificate eligibility. */
  emphasis?: boolean;
}

interface MilestoneTrackProps {
  value: number;
  milestones: Milestone[];
  label: string;
  youLabel?: string;
}

/**
 * Progress measured against meaningful points rather than an abstract 100.
 * Wide containers place labels under their markers; narrow containers list them.
 */
export function MilestoneTrack({ value, milestones, label, youLabel = 'You' }: MilestoneTrackProps) {
  const pct = clampPercent(value);
  const sorted = [...milestones].sort((a, b) => a.at - b.at);
  const next = sorted.find((m) => m.at > pct);
  // Labels that would collide with their neighbour drop to a second row.
  const rows = sorted.reduce<number[]>((acc, m, i) => {
    acc.push(i > 0 && m.at - sorted[i - 1].at < 26 && acc[i - 1] === 0 ? 1 : 0);
    return acc;
  }, []);
  const twoRows = rows.includes(1);

  return (
    <div className={styles.root}>
      <div className={styles.trackArea}>
        <span className={styles.you} style={{ left: `${pct}%` }} aria-hidden="true">
          <span className={styles.youLabel}>
            {youLabel} · <span className="tabular">{pct}%</span>
          </span>
        </span>
        <div
          className={styles.track}
          role="progressbar"
          aria-label={label}
          aria-valuemin={0}
          aria-valuemax={100}
          aria-valuenow={pct}
          aria-valuetext={`${pct}%${next ? `, next milestone: ${next.label} at ${next.at}%` : ', all milestones reached'}`}
        >
          <span className={styles.fill} style={{ width: `${pct}%` }} />
        </div>
        {sorted.map((m) => {
          const reached = pct >= m.at;
          return (
            <span
              key={m.id}
              className={cx(styles.marker, reached && styles.reached, m.emphasis && styles.emphasis)}
              style={{ left: `${m.at}%` }}
              aria-hidden="true"
            >
              {reached ? <Check size={9} weight="bold" /> : m.emphasis ? m.icon : null}
            </span>
          );
        })}
      </div>

      <ol className={cx(styles.labels, twoRows && styles.twoRows)}>
        {sorted.map((m, i) => {
          const reached = pct >= m.at;
          const align = i === sorted.length - 1 && m.at > 88 ? 'end' : m.at < 8 ? 'start' : 'center';
          return (
            <li
              key={m.id}
              className={cx(styles.label, reached && styles.labelReached, m === next && styles.labelNext, styles[align], rows[i] === 1 && styles.row2)}
              style={{ '--at': `${m.at}%` } as CSSProperties}
            >
              <span className={styles.labelAt}>{m.at}%</span>
              <span className={styles.labelText}>{m.label}</span>
              {m.detail && <span className={styles.labelDetail}>{m.detail}</span>}
              <span className="sr-only">{reached ? '(reached)' : m === next ? '(next)' : ''}</span>
            </li>
          );
        })}
      </ol>
    </div>
  );
}
