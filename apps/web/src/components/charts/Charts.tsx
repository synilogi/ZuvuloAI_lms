import { useId, useState, type KeyboardEvent, type PointerEvent, type ReactNode } from 'react';
import { useElementWidth } from '@/hooks/useElementWidth';
import { cx } from '@/lib/cx';
import styles from './Charts.module.css';

/*
 * Charts follow one set of rules: a single hue for a single measure, 2px lines, rounded data
 * ends on a quiet baseline, recessive grid and axes, a hover and keyboard read-out for every
 * mark, and a data table for assistive technology. Text never takes the series color.
 */

export interface ChartDatum {
  /** Axis label, e.g. "7 Sep". */
  label: string;
  /** Tooltip heading, e.g. "Week of 7 Sep". Defaults to label. */
  detail?: string;
  value: number;
}

/** Rounds up to a readable axis maximum that divides into four even steps. */
export function niceMax(max: number, steps = 4) {
  if (max <= 0) return steps;
  const raw = max / steps;
  const mag = Math.pow(10, Math.floor(Math.log10(raw)));
  const step = [1, 2, 2.5, 5, 10].map((m) => m * mag).find((s) => s >= raw) ?? 10 * mag;
  return step * steps;
}

const compact = new Intl.NumberFormat('en-IN', { notation: 'compact', maximumFractionDigits: 1 });
const fmtAxis = (n: number) => (n >= 10000 ? compact.format(n) : n.toLocaleString('en-IN'));

interface BaseChartProps {
  data: ChartDatum[];
  /** Accessible name and table caption. */
  label: string;
  /** Unit after the value in the read-out: "enrollments", "learners". */
  unit: string;
  height?: number;
  formatValue?: (n: number) => string;
  /** Index of a mark that is still accruing (today, this week) — drawn hatched and called out. */
  partialIndex?: number;
  partialNote?: string;
}

function useReadout(count: number) {
  const [active, setActive] = useState<number | null>(null);
  const onKeyDown = (e: KeyboardEvent) => {
    if (count === 0) return;
    const current = active ?? count - 1;
    let next = current;
    if (e.key === 'ArrowRight') next = Math.min(count - 1, current + 1);
    else if (e.key === 'ArrowLeft') next = Math.max(0, current - 1);
    else if (e.key === 'Home') next = 0;
    else if (e.key === 'End') next = count - 1;
    else if (e.key === 'Escape') {
      setActive(null);
      return;
    } else return;
    e.preventDefault();
    setActive(next);
  };
  return { active, setActive, onKeyDown };
}

function DataTable({ data, label, unit, formatValue }: Pick<BaseChartProps, 'data' | 'label' | 'unit' | 'formatValue'>) {
  // Tables ignore width clipping, so the visually hidden wrapper is a div.
  return (
    <div className="sr-only">
      <table>
        <caption>{label}</caption>
        <thead>
          <tr>
            <th scope="col">Period</th>
            <th scope="col">{unit}</th>
          </tr>
        </thead>
        <tbody>
          {data.map((d) => (
            <tr key={d.label + d.detail}>
              <th scope="row">{d.detail ?? d.label}</th>
              <td>{formatValue ? formatValue(d.value) : d.value}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function Tooltip({
  x,
  width,
  datum,
  unit,
  formatValue,
  note,
}: {
  x: number;
  width: number;
  datum: ChartDatum;
  unit: string;
  formatValue?: (n: number) => string;
  note?: ReactNode;
}) {
  const left = Math.max(70, Math.min(width - 70, x));
  return (
    <div className={styles.tooltip} style={{ left }} aria-hidden="true">
      <span className={styles.tooltipLabel}>{datum.detail ?? datum.label}</span>
      <span className={styles.tooltipValue}>
        {formatValue ? formatValue(datum.value) : datum.value.toLocaleString('en-IN')} <span className={styles.tooltipUnit}>{unit}</span>
      </span>
      {note && <span className={styles.tooltipNote}>{note}</span>}
    </div>
  );
}

const M = { top: 14, right: 10, bottom: 26, left: 38 };

function xLabelIndexes(count: number, width: number) {
  const max = Math.max(2, Math.floor(width / 76));
  const every = Math.max(1, Math.ceil(count / max));
  return new Set(Array.from({ length: count }, (_, i) => i).filter((i) => (count - 1 - i) % every === 0));
}

/* ─── Trend (line + area) ──────────────────────────────────────────────── */

export function TrendChart({ data, label, unit, height = 220, formatValue, partialIndex, partialNote }: BaseChartProps) {
  const [ref, width] = useElementWidth<HTMLDivElement>();
  const gradientId = `g${useId().replace(/:/g, '')}`;
  const { active, setActive, onKeyDown } = useReadout(data.length);
  const w = Math.max(0, width);
  const innerW = Math.max(1, w - M.left - M.right);
  const innerH = height - M.top - M.bottom;
  const max = niceMax(Math.max(...data.map((d) => d.value), 0));
  const x = (i: number) => M.left + (data.length <= 1 ? innerW / 2 : (i / (data.length - 1)) * innerW);
  const y = (v: number) => M.top + innerH - (v / max) * innerH;

  const pts = data.map((d, i) => `${x(i).toFixed(1)},${y(d.value).toFixed(1)}`);
  // A still-accruing final point is joined by a dashed segment so it doesn't read as a drop.
  const solidPts = partialIndex !== undefined && partialIndex === data.length - 1 && data.length > 1 ? pts.slice(0, -1) : pts;
  const line = `M${solidPts.join(' L')}`;
  const area = `M${x(0).toFixed(1)},${M.top + innerH} L${pts.join(' L')} L${x(data.length - 1).toFixed(1)},${M.top + innerH} Z`;

  const labels = xLabelIndexes(data.length, innerW);
  const last = data.length - 1;
  const shown = active ?? null;

  const onPointer = (e: PointerEvent<SVGRectElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const rel = (e.clientX - rect.left) / rect.width;
    setActive(Math.round(rel * (data.length - 1)));
  };

  return (
    <div
      ref={ref}
      className={styles.chart}
      style={{ height }}
      role="group"
      aria-roledescription="chart"
      aria-label={`${label}. Use arrow keys to read values.`}
      tabIndex={0}
      onKeyDown={onKeyDown}
      onBlur={() => setActive(null)}
    >
      {w > 0 && data.length > 0 && (
        <svg width={w} height={height} className={styles.svg} aria-hidden="true">
          <defs>
            <linearGradient id={gradientId} x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" className={styles.areaStopTop} />
              <stop offset="100%" className={styles.areaStopBottom} />
            </linearGradient>
          </defs>
          {[0, 1, 2, 3, 4].map((t) => {
            const value = (max / 4) * t;
            return (
              <g key={t}>
                <line x1={M.left} x2={w - M.right} y1={y(value)} y2={y(value)} className={t === 0 ? styles.baseline : styles.grid} />
                <text x={M.left - 8} y={y(value)} dy="0.32em" textAnchor="end" className={styles.axisText}>
                  {fmtAxis(value)}
                </text>
              </g>
            );
          })}
          {data.map((d, i) =>
            labels.has(i) ? (
              <text key={i} x={x(i)} y={height - 8} textAnchor={i === 0 ? 'start' : i === last ? 'end' : 'middle'} className={styles.axisText}>
                {d.label}
              </text>
            ) : null,
          )}
          <path d={area} fill={`url(#${gradientId})`} />
          {solidPts !== pts && <line x1={x(last - 1)} y1={y(data[last - 1].value)} x2={x(last)} y2={y(data[last].value)} className={styles.linePartial} />}
          <path d={line} className={styles.line} />
          {shown !== null && <line x1={x(shown)} x2={x(shown)} y1={M.top} y2={M.top + innerH} className={styles.crosshair} />}
          <circle cx={x(shown ?? last)} cy={y(data[shown ?? last].value)} r={4.5} className={styles.point} />
          <rect
            x={M.left}
            y={M.top}
            width={innerW}
            height={innerH}
            className={styles.hit}
            onPointerMove={onPointer}
            onPointerDown={onPointer}
            onPointerLeave={() => setActive(null)}
          />
        </svg>
      )}
      {shown !== null && data[shown] && (
        <Tooltip x={x(shown)} width={w} datum={data[shown]} unit={unit} formatValue={formatValue} note={shown === partialIndex ? partialNote : undefined} />
      )}
      <DataTable data={data} label={label} unit={unit} formatValue={formatValue} />
      <span className="sr-only" aria-live="polite">
        {shown !== null && data[shown] ? `${data[shown].detail ?? data[shown].label}: ${data[shown].value} ${unit}` : ''}
      </span>
    </div>
  );
}

/* ─── Columns ──────────────────────────────────────────────────────────── */

export function ColumnChart({ data, label, unit, height = 180, formatValue, partialIndex, partialNote }: BaseChartProps) {
  const [ref, width] = useElementWidth<HTMLDivElement>();
  const patternId = `p${useId().replace(/:/g, '')}`;
  const { active, setActive, onKeyDown } = useReadout(data.length);
  const w = Math.max(0, width);
  const innerW = Math.max(1, w - M.left - M.right);
  const innerH = height - M.top - M.bottom;
  const max = niceMax(Math.max(...data.map((d) => d.value), 0));
  const band = innerW / Math.max(1, data.length);
  const gap = band > 14 ? 3 : 2;
  const barW = Math.max(2, band - gap);
  const y = (v: number) => M.top + innerH - (v / max) * innerH;
  const labels = xLabelIndexes(data.length, innerW);

  return (
    <div
      ref={ref}
      className={styles.chart}
      style={{ height }}
      role="group"
      aria-roledescription="chart"
      aria-label={`${label}. Use arrow keys to read values.`}
      tabIndex={0}
      onKeyDown={onKeyDown}
      onBlur={() => setActive(null)}
    >
      {w > 0 && data.length > 0 && (
        <svg width={w} height={height} className={styles.svg} aria-hidden="true">
          <defs>
            <pattern id={patternId} width="5" height="5" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <rect width="5" height="5" className={styles.hatchBack} />
              <line x1="0" y1="0" x2="0" y2="5" className={styles.hatchLine} />
            </pattern>
          </defs>
          {[0, 1, 2, 3, 4].map((t) => {
            const value = (max / 4) * t;
            return (
              <g key={t}>
                {t > 0 && <line x1={M.left} x2={w - M.right} y1={y(value)} y2={y(value)} className={styles.grid} />}
                <text x={M.left - 8} y={y(value)} dy="0.32em" textAnchor="end" className={styles.axisText}>
                  {fmtAxis(value)}
                </text>
              </g>
            );
          })}
          {data.map((d, i) => {
            const h = Math.max(d.value > 0 ? 2 : 0, (d.value / max) * innerH);
            const bx = M.left + i * band + gap / 2;
            const by = M.top + innerH - h;
            const r = Math.min(4, barW / 2, h);
            const path = `M${bx},${M.top + innerH} L${bx},${by + r} Q${bx},${by} ${bx + r},${by} L${bx + barW - r},${by} Q${bx + barW},${by} ${bx + barW},${by + r} L${bx + barW},${M.top + innerH} Z`;
            return (
              <path
                key={i}
                d={path}
                className={cx(styles.bar, active === i && styles.barActive, i === partialIndex && styles.barPartial)}
                fill={i === partialIndex ? `url(#${patternId})` : undefined}
              />
            );
          })}
          <line x1={M.left} x2={w - M.right} y1={M.top + innerH} y2={M.top + innerH} className={styles.baseline} />
          {data.map((d, i) =>
            labels.has(i) ? (
              <text key={i} x={M.left + i * band + band / 2} y={height - 8} textAnchor="middle" className={styles.axisText}>
                {d.label}
              </text>
            ) : null,
          )}
          {data.map((_, i) => (
            <rect
              key={i}
              x={M.left + i * band}
              y={M.top}
              width={band}
              height={innerH}
              className={styles.hit}
              onPointerEnter={() => setActive(i)}
              onPointerDown={() => setActive(i)}
              onPointerLeave={() => setActive(null)}
            />
          ))}
        </svg>
      )}
      {active !== null && data[active] && (
        <Tooltip
          x={M.left + active * band + band / 2}
          width={w}
          datum={data[active]}
          unit={unit}
          formatValue={formatValue}
          note={active === partialIndex ? partialNote : undefined}
        />
      )}
      <DataTable data={data} label={label} unit={unit} formatValue={formatValue} />
      <span className="sr-only" aria-live="polite">
        {active !== null && data[active] ? `${data[active].detail ?? data[active].label}: ${data[active].value} ${unit}` : ''}
      </span>
    </div>
  );
}

/* ─── Sparkline ────────────────────────────────────────────────────────── */

/** Direction at a glance beside a figure. Decorative — the figure and its change carry the meaning. */
export function Sparkline({ values, width = 72, height = 24, className }: { values: number[]; width?: number; height?: number; className?: string }) {
  if (values.length < 2) return null;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const range = max - min || 1;
  const pad = 3;
  const pts = values.map((v, i) => [pad + (i / (values.length - 1)) * (width - pad * 2), pad + (1 - (v - min) / range) * (height - pad * 2)] as const);
  const [lx, ly] = pts[pts.length - 1];
  return (
    <svg width={width} height={height} className={cx(styles.spark, className)} aria-hidden="true">
      <polyline points={pts.map((p) => p.join(',')).join(' ')} className={styles.sparkLine} />
      <circle cx={lx} cy={ly} r={2.5} className={styles.sparkDot} />
    </svg>
  );
}
