import { Fragment, type ReactNode } from 'react';
import { cx } from '@/lib/cx';
import { formatDay, formatTime } from '@/lib/format';
import { StatusLabel, StatusNodeFor } from '../status/Status';
import type { StatusKey } from '../status/statusRegistry';
import styles from './ProgressTimeline.module.css';

export interface TimelineItem {
  id: string;
  at: string;
  title: string;
  status: StatusKey;
  statusLabel?: string;
  kind?: ReactNode;
  meta?: ReactNode;
  action?: ReactNode;
}

interface ProgressTimelineProps {
  items: TimelineItem[];
  now: Date;
  label: string;
}

/**
 * Chronology with a visible "now". Elapsed rail is accent, the future is a neutral line,
 * so a learner can see at a glance what is behind them and what is next.
 */
export function ProgressTimeline({ items, now, label }: ProgressTimelineProps) {
  const sorted = [...items].sort((a, b) => new Date(a.at).getTime() - new Date(b.at).getTime());
  const nowIndex = sorted.findIndex((i) => new Date(i.at).getTime() > now.getTime());
  const splitAt = nowIndex === -1 ? sorted.length : nowIndex;

  return (
    <div className={styles.root}>
      <ol className={styles.list} aria-label={label}>
        {sorted.map((item, i) => {
          const past = i < splitAt;
          return (
            <Fragment key={item.id}>
              {i === splitAt && <NowMarker now={now} />}
              <li className={cx(styles.item, past ? styles.past : styles.future, item.status === 'live' && styles.live)}>
                <time className={styles.time} dateTime={item.at}>
                  <span className={styles.day}>{formatDay(item.at)}</span>
                  <span className={styles.clock}>{formatTime(item.at)}</span>
                </time>
                <span className={styles.rail} aria-hidden="true">
                  <StatusNodeFor status={item.status} size={18} />
                </span>
                <div className={styles.content}>
                  <span className={styles.mobileTime}>
                    {formatDay(item.at)} · {formatTime(item.at)}
                  </span>
                  <div className={styles.titleRow}>
                    {item.kind && <span className={styles.kind}>{item.kind}</span>}
                    <span className={styles.title}>{item.title}</span>
                  </div>
                  <div className={styles.metaRow}>
                    <StatusLabel status={item.status} label={item.statusLabel} />
                    {item.meta && <span className={styles.meta}>{item.meta}</span>}
                  </div>
                  {item.action && <div className={styles.action}>{item.action}</div>}
                </div>
              </li>
            </Fragment>
          );
        })}
        {splitAt === sorted.length && <NowMarker now={now} />}
      </ol>
    </div>
  );
}

function NowMarker({ now }: { now: Date }) {
  return (
    <li className={styles.now} aria-label={`Now, ${formatTime(now.toISOString())}`}>
      <span className={styles.nowLabel}>Now · {formatTime(now.toISOString())}</span>
      <span className={styles.nowLine} aria-hidden="true" />
    </li>
  );
}
