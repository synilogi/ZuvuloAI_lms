import type { ReactNode } from 'react';
import { Link } from 'react-router-dom';
import { ArrowDownRight, ArrowRight, ArrowUpRight, CaretRight } from '@phosphor-icons/react';
import { kpiChange, type Kpi } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { Sparkline } from '@/components/charts/Charts';
import { Skeleton } from '@/components/ui/Feedback/Feedback';
import styles from './StatCards.module.css';

/** The category hue a stat card is drawn in (tokens.css, Part C) — tells the cards apart at a glance. */
export type StatHue = 'violet' | 'blue' | 'green' | 'orange' | 'pink' | 'gold';

/**
 * A change said in words: "Up 12% from last month", "2 fewer than last week", "Same as last month". The arrow and the
 * colour repeat what the words already say, so nothing depends on colour alone.
 */
export function Change({
  kpi,
  since,
  good = 'up',
  absolute,
  noun,
}: {
  kpi: Pick<Kpi, 'value' | 'previous' | 'unit'>;
  /** What it is compared with, read as "from …": "last month", "last week", "the 4 weeks before". */
  since: string;
  good?: 'up' | 'down' | 'neutral';
  /** Count the difference ("2 more") instead of a percentage — for small numbers. */
  absolute?: boolean;
  /** The thing counted, for an absolute change: "2 more courses than last month". */
  noun?: [one: string, many: string];
}) {
  const change = kpiChange(kpi);
  const diff = Math.abs(kpi.value - kpi.previous);
  const tone = change.direction === 'flat' || good === 'neutral' ? 'flat' : change.direction === good ? 'good' : 'bad';
  const Icon = change.direction === 'up' ? ArrowUpRight : change.direction === 'down' ? ArrowDownRight : ArrowRight;

  let words: string;
  if (change.direction === 'flat') words = `Same as ${since}`;
  else if (absolute) {
    const thing = noun ? ` ${diff === 1 ? noun[0] : noun[1]}` : '';
    words = `${diff.toLocaleString('en-IN')} ${change.direction === 'up' ? 'more' : 'fewer'}${thing} than ${since}`;
  } else if (change.unit === 'pts') {
    words = `${change.direction === 'up' ? 'Up' : 'Down'} ${change.amount.toLocaleString('en-IN')} ${change.amount === 1 ? 'point' : 'points'} from ${since}`;
  } else {
    words = `${change.direction === 'up' ? 'Up' : 'Down'} ${change.amount.toLocaleString('en-IN')}% from ${since}`;
  }

  return (
    <span className={cx(styles.change, styles[`change_${tone}`])}>
      <Icon size={13} weight="bold" aria-hidden="true" />
      {words}
    </span>
  );
}

export interface StatItem {
  id: string;
  /** Plain name of the figure: "Students". */
  label: string;
  /** One sentence on what is counted, in everyday words. */
  help: string;
  icon: ReactNode;
  hue: StatHue;
  /** The figure with what it read before. Without one — a count with no history — the card shows no change line. */
  kpi?: Kpi;
  /** The headline value, formatted. */
  value: string;
  /** What the change is measured from: "last month". Needed with `kpi`. */
  since?: string;
  good?: 'up' | 'down' | 'neutral';
  absolute?: boolean;
  noun?: [string, string];
  /** A short extra fact under the change: "1 draft not published yet". */
  note?: ReactNode;
  /** Where the card leads — only when this account may open that page. */
  to?: string;
  /** What the link says to a screen reader and on hover. */
  linkLabel?: string;
}

/**
 * The headline figures as cards: what it is, the number, how it changed — in that order, in plain words. `columns` is
 * how many sit side by side where there is room (2 on a narrow screen, 1 on a phone).
 */
export function StatCards({ items, label, columns = 4 }: { items: StatItem[]; label: string; columns?: 3 | 4 }) {
  return (
    <div className={styles.wrap}>
      <ul className={styles.stats} aria-label={label} data-columns={columns}>
        {items.map((item) => {
          const body = (
            <>
              <span className={styles.statHead}>
                <span className={styles.statIcon} data-hue={item.hue} aria-hidden="true">
                  {item.icon}
                </span>
                <span className={styles.statLabel}>{item.label}</span>
                {item.to && <CaretRight size={14} className={styles.statCaret} aria-hidden="true" />}
              </span>
              <span className={styles.statValueRow}>
                <span className={styles.statValue}>{item.value}</span>
                {item.kpi && <Sparkline values={item.kpi.series} className={styles.statSpark} />}
              </span>
              {item.kpi && item.since && <Change kpi={item.kpi} since={item.since} good={item.good} absolute={item.absolute} noun={item.noun} />}
              <span className={styles.statHelp}>{item.help}</span>
              {item.note && <span className={styles.statNote}>{item.note}</span>}
              {item.to && item.linkLabel && <span className="sr-only">. {item.linkLabel}</span>}
            </>
          );
          return (
            <li key={item.id} className={styles.stat} data-hue={item.hue}>
              {item.to ? (
                <Link to={item.to} className={styles.statLink} title={item.linkLabel}>
                  {body}
                </Link>
              ) : (
                <div className={styles.statLink}>{body}</div>
              )}
            </li>
          );
        })}
      </ul>
    </div>
  );
}

/** Four placeholder cards while the figures load. */
export function StatCardsSkeleton({ labels, columns = 4 }: { labels: string[]; columns?: 3 | 4 }) {
  return (
    <div className={styles.wrap}>
      <ul className={styles.stats} aria-label="Key numbers" aria-busy="true" data-columns={columns}>
        {labels.map((label) => (
          <li key={label} className={styles.stat}>
            <div className={styles.statLink}>
              <span className={styles.statHead}>
                <Skeleton width={34} height={34} radius="var(--r-md)" />
                <span className={styles.statLabel}>{label}</span>
              </span>
              <Skeleton width={84} height={28} radius="var(--r-xs)" />
              <Skeleton width={150} height={10} />
              <Skeleton width="90%" height={8} />
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
