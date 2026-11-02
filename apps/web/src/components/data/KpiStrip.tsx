import type { ReactNode } from 'react';
import { ArrowDownRight, ArrowRight, ArrowUpRight } from '@phosphor-icons/react';
import type { Kpi } from '@syniastrolms/domain';
import { kpiChange } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { Sparkline } from '@/components/charts/Charts';
import { Skeleton } from '@/components/ui/Feedback/Feedback';
import styles from './Data.module.css';

interface DeltaProps {
  kpi: Pick<Kpi, 'value' | 'previous' | 'unit'>;
  /** Which direction is good news. "neutral" draws no judgement. */
  good?: 'up' | 'down' | 'neutral';
  /** Show the raw difference ("+2") instead of a percentage — for small counts. */
  absolute?: boolean;
  /** Comparison period, read by screen readers and shown after the change: "vs August". */
  period?: string;
}

/** A change with its direction spelled out by arrow and sign, never by color alone. */
export function Delta({ kpi, good = 'up', absolute, period }: DeltaProps) {
  const change = kpiChange(kpi);
  const diff = kpi.value - kpi.previous;
  const amount = absolute ? Math.abs(diff).toLocaleString('en-IN') : `${change.amount.toLocaleString('en-IN')}${change.unit === 'pts' ? ' pts' : '%'}`;
  const sign = change.direction === 'up' ? '+' : change.direction === 'down' ? '−' : '';
  const tone = change.direction === 'flat' || good === 'neutral' ? 'flat' : change.direction === good ? 'good' : 'bad';
  const Icon = change.direction === 'up' ? ArrowUpRight : change.direction === 'down' ? ArrowDownRight : ArrowRight;
  const words = change.direction === 'flat' ? 'no change' : `${change.direction === 'up' ? 'up' : 'down'} ${amount}`;

  return (
    <span className={styles.deltaWrap}>
      <span className={cx(styles.delta, styles[tone])}>
        <Icon size={13} weight="bold" aria-hidden="true" />
        <span aria-hidden="true">{change.direction === 'flat' ? 'No change' : `${sign}${amount}`}</span>
        <span className="sr-only">{words}</span>
      </span>
      {period && <span className={styles.period}>{period}</span>}
    </span>
  );
}

export interface KpiItem {
  id: string;
  label: string;
  kpi: Kpi;
  /** Formatted headline value. */
  value: string;
  good?: DeltaProps['good'];
  absolute?: boolean;
  period?: string;
  /** One quiet line of context under the change. */
  note?: ReactNode;
}

/** Headline figures as a typographic band — hairlines between figures instead of a row of cards. */
export function KpiStrip({ items, label, loading }: { items: KpiItem[]; label: string; loading?: boolean }) {
  return (
    <div className={styles.stripWrap}>
      <dl className={styles.strip} aria-label={label} aria-busy={loading || undefined}>
        {items.map((item) => (
          <div key={item.id} className={styles.kpi}>
            <dt className={styles.kpiLabel}>{item.label}</dt>
            {loading ? (
              <dd className={styles.kpiBody}>
                <Skeleton width={84} height={26} radius="var(--r-xs)" />
                <Skeleton width={120} height={10} />
              </dd>
            ) : (
              <dd className={styles.kpiBody}>
                <span className={styles.kpiValueRow}>
                  <span className={styles.kpiValue}>{item.value}</span>
                  <Sparkline values={item.kpi.series} className={styles.kpiSpark} />
                </span>
                <Delta kpi={item.kpi} good={item.good} absolute={item.absolute} period={item.period} />
                {item.note && <span className={styles.kpiNote}>{item.note}</span>}
              </dd>
            )}
          </div>
        ))}
      </dl>
    </div>
  );
}

/** A labelled figure for inline summaries — smaller than a KPI, no container. */
export function Figure({ label, value, children }: { label: string; value: ReactNode; children?: ReactNode }) {
  return (
    <div className={styles.figure}>
      <span className={styles.figureValue}>{value}</span>
      <span className={styles.figureLabel}>{label}</span>
      {children}
    </div>
  );
}
