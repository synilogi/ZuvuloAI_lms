import type { ReactNode } from 'react';
import { CheckCircle, Play, XCircle } from '@phosphor-icons/react';
import type { ProgressState } from '@syniastrolms/domain';
import { clampPercent } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { formatClock } from '@/lib/format';
import styles from './Progress.module.css';

/* ─── Meter ─────────────────────────────────────────────────────────────── */

interface MeterProps {
  value: number;
  label: string;
  /** Visible label row above the bar. */
  showLabel?: boolean;
  valueText?: ReactNode;
  size?: 'xs' | 'sm' | 'md';
  tone?: 'accent' | 'info' | 'warn' | 'danger';
  /** Marks a threshold on the bar, 0–100. */
  threshold?: number;
  className?: string;
}

/** Linear ratio against a whole. The shell's progress bar, with an optional threshold tick. */
export function Meter({ value, label, showLabel, valueText, size = 'md', tone = 'accent', threshold, className }: MeterProps) {
  const pct = clampPercent(value);
  return (
    <div className={cx(styles.meter, styles[tone], className)}>
      {showLabel && (
        <div className={styles.meterRow}>
          <span className={styles.meterLabel}>{label}</span>
          <span className={styles.meterValue}>{valueText ?? `${pct}%`}</span>
        </div>
      )}
      <div className={cx(styles.bar, styles[`bar-${size}`])} role="progressbar" aria-label={label} aria-valuemin={0} aria-valuemax={100} aria-valuenow={pct}>
        <span className={styles.barFill} style={{ width: `${pct}%` }} />
        {threshold !== undefined && <span className={styles.barThreshold} style={{ left: `${threshold}%` }} aria-hidden="true" />}
      </div>
    </div>
  );
}

/* ─── Lesson segments (chapter progress) ─────────────────────────────────── */

export interface SegmentItem {
  id: string;
  state: ProgressState;
  fraction?: number;
  title?: string;
}

interface LessonSegmentsProps {
  items: SegmentItem[];
  label: string;
  summary?: ReactNode;
  className?: string;
}

/**
 * One segment per lesson — shows where in a chapter the learner is, not just how much.
 * Locked lessons use the shell's hatch, so they read differently from "not started"
 * without relying on color.
 */
export function LessonSegments({ items, label, summary, className }: LessonSegmentsProps) {
  const done = items.filter((i) => i.state === 'completed').length;
  return (
    <div className={cx(styles.segmentsWrap, className)}>
      <div className={styles.segments} role="img" aria-label={`${label}: ${done} of ${items.length} lessons completed`}>
        {items.map((item) => (
          <span key={item.id} className={cx(styles.segment, styles[`seg-${item.state}`])} title={item.title}>
            {item.state === 'in-progress' && <span className={styles.segmentFill} style={{ width: `${Math.round((item.fraction ?? 0.5) * 100)}%` }} />}
          </span>
        ))}
      </div>
      {summary && <div className={styles.segmentsSummary}>{summary}</div>}
    </div>
  );
}

/* ─── Video progress ───────────────────────────────────────────────────── */

interface VideoProgressProps {
  positionSec: number;
  durationSec: number;
  /** Chapter start times in seconds — drawn as gaps in the bar. */
  chapters?: number[];
  showTimes?: boolean;
  className?: string;
}

export function VideoProgress({ positionSec, durationSec, chapters = [], showTimes = true, className }: VideoProgressProps) {
  const pct = durationSec === 0 ? 0 : clampPercent((positionSec / durationSec) * 100);
  const remaining = Math.max(0, durationSec - positionSec);
  return (
    <div className={cx(styles.video, className)}>
      <div
        className={styles.videoBar}
        role="progressbar"
        aria-label="Watched"
        aria-valuemin={0}
        aria-valuemax={Math.round(durationSec)}
        aria-valuenow={Math.round(positionSec)}
        aria-valuetext={`${formatClock(positionSec)} of ${formatClock(durationSec)}`}
      >
        <span className={styles.videoFill} style={{ width: `${pct}%` }} />
        {chapters
          .filter((t) => t > 0 && t < durationSec)
          .map((t) => (
            <span key={t} className={styles.videoChapter} style={{ left: `${(t / durationSec) * 100}%` }} aria-hidden="true" />
          ))}
        <span className={styles.videoHead} style={{ left: `${pct}%` }} aria-hidden="true" />
      </div>
      {showTimes && (
        <div className={styles.videoTimes}>
          <span className={styles.videoResume}>
            <Play size={12} weight="fill" /> Resume at {formatClock(positionSec)}
          </span>
          <span>{Math.ceil(remaining / 60)} min left</span>
        </div>
      )}
    </div>
  );
}

/* ─── Score against a pass mark ─────────────────────────────────────────── */

export function ScoreMeter({ score, passMark, label = 'Score' }: { score: number; passMark: number; label?: string }) {
  const passed = score >= passMark;
  return (
    <div className={cx(styles.score, passed ? styles.accent : styles.danger)}>
      <div className={styles.scoreRow}>
        <span className={styles.scoreValue}>
          {score}
          <span className={styles.ringUnit}>%</span>
        </span>
        <span className={styles.scoreVerdict}>
          {passed ? <CheckCircle size={15} weight="fill" /> : <XCircle size={15} weight="fill" />}
          {passed ? 'Passed' : 'Below pass mark'}
        </span>
      </div>
      <div className={cx(styles.bar, styles['bar-sm'])} role="meter" aria-label={label} aria-valuemin={0} aria-valuemax={100} aria-valuenow={score}>
        <span className={styles.barFill} style={{ width: `${clampPercent(score)}%` }} />
        <span className={styles.barThreshold} style={{ left: `${passMark}%` }} aria-hidden="true" />
      </div>
      <div className={styles.scorePass} style={{ paddingLeft: `min(${passMark}%, calc(100% - 7em))` }}>
        Pass mark {passMark}%
      </div>
    </div>
  );
}
