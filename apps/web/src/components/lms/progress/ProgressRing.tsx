import { useEffect, useState, type ReactNode } from 'react';
import { clampPercent } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import styles from './Progress.module.css';

const SIZES = {
  xs: { box: 20, stroke: 3, font: 0 },
  sm: { box: 36, stroke: 3.5, font: 10.5 },
  md: { box: 56, stroke: 5, font: 14 },
  lg: { box: 96, stroke: 7, font: 24 },
  xl: { box: 148, stroke: 9, font: 38 },
} as const;

export type RingSize = keyof typeof SIZES;

interface ProgressRingProps {
  /** 0–100 */
  value: number;
  /** Accessible name — "Course progress", "Chapter 3". */
  label: string;
  size?: RingSize;
  tone?: 'accent' | 'info' | 'warn' | 'danger';
  /** Per-segment completion (0–1) — draws a radial segmented ring, e.g. one arc per chapter. */
  segments?: number[];
  /** Marks a threshold on the ring, e.g. a pass mark or certificate eligibility at 80. */
  threshold?: number;
  /** Replaces the numeric center. */
  center?: ReactNode;
  caption?: ReactNode;
  hideValue?: boolean;
  /** Text in place of the percentage, e.g. "9/15". */
  valueText?: string;
  className?: string;
}

/**
 * Radial progress. Single-value rings animate from their previous value; segmented rings
 * show structure (chapters) and completion together. The unfilled track is a light step of
 * the same accent ramp, so the whole ring reads as one measure.
 */
export function ProgressRing({
  value,
  label,
  size = 'md',
  tone = 'accent',
  segments,
  threshold,
  center,
  caption,
  hideValue,
  valueText,
  className,
}: ProgressRingProps) {
  const { box, stroke, font } = SIZES[size];
  const pct = clampPercent(value);
  const [drawn, setDrawn] = useState(0);

  useEffect(() => {
    const frame = requestAnimationFrame(() => setDrawn(pct));
    return () => cancelAnimationFrame(frame);
  }, [pct]);

  const r = (box - stroke) / 2;
  const c = 2 * Math.PI * r;
  const mid = box / 2;

  const thresholdPoint = (at: number) => {
    const angle = (at / 100) * 2 * Math.PI - Math.PI / 2;
    const inner = r - stroke / 2 - 1.5;
    const outer = r + stroke / 2 + 1.5;
    return { x1: mid + inner * Math.cos(angle), y1: mid + inner * Math.sin(angle), x2: mid + outer * Math.cos(angle), y2: mid + outer * Math.sin(angle) };
  };

  return (
    <span
      className={cx(styles.ring, styles[tone], className)}
      style={{ width: box, height: box }}
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={pct}
      aria-valuetext={`${pct}%`}
    >
      <svg width={box} height={box} viewBox={`0 0 ${box} ${box}`} aria-hidden="true">
        {segments && segments.length > 1 ? (
          <SegmentArcs segments={segments} r={r} c={c} mid={mid} stroke={stroke} />
        ) : (
          <g transform={`rotate(-90 ${mid} ${mid})`}>
            <circle cx={mid} cy={mid} r={r} fill="none" strokeWidth={stroke} className={styles.ringTrack} />
            <circle
              cx={mid}
              cy={mid}
              r={r}
              fill="none"
              strokeWidth={stroke}
              strokeLinecap={drawn > 0 ? 'round' : 'butt'}
              strokeDasharray={c}
              strokeDashoffset={c * (1 - drawn / 100)}
              className={styles.ringValue}
            />
          </g>
        )}
        {threshold !== undefined && <line {...thresholdPoint(threshold)} strokeWidth={2} strokeLinecap="round" className={styles.ringThreshold} />}
      </svg>
      {size !== 'xs' && !hideValue && (
        <span className={styles.ringCenter}>
          {center ?? (
            <span className={styles.ringValueText} style={{ fontSize: valueText && valueText.length > 3 ? font * 0.85 : font }}>
              {valueText ?? (
                <>
                  {pct}
                  <span className={styles.ringUnit}>%</span>
                </>
              )}
            </span>
          )}
          {caption && (size === 'lg' || size === 'xl') && <span className={styles.ringCaption}>{caption}</span>}
        </span>
      )}
    </span>
  );
}

function SegmentArcs({ segments, r, c, mid, stroke }: { segments: number[]; r: number; c: number; mid: number; stroke: number }) {
  const gap = 2 + stroke * 0.35;
  const arc = (c - gap * segments.length) / segments.length;
  return (
    <g transform={`rotate(-90 ${mid} ${mid})`}>
      {segments.map((fraction, i) => {
        const offset = -(i * (arc + gap));
        const filled = Math.max(0, Math.min(1, fraction)) * arc;
        return (
          <g key={i}>
            <circle
              cx={mid}
              cy={mid}
              r={r}
              fill="none"
              strokeWidth={stroke}
              strokeDasharray={`${arc} ${c}`}
              strokeDashoffset={offset}
              className={styles.ringTrack}
            />
            {filled > 0 && (
              <circle
                cx={mid}
                cy={mid}
                r={r}
                fill="none"
                strokeWidth={stroke}
                strokeDasharray={`${filled} ${c}`}
                strokeDashoffset={offset}
                className={styles.ringValue}
              />
            )}
          </g>
        );
      })}
    </g>
  );
}
