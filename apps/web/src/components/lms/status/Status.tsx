import type { ReactNode } from 'react';
import { Check, LockSimple } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import { Badge } from '@/components/ui/Badge/Badge';
import { statusRegistry, type NodeShape, type StatusKey } from './statusRegistry';
import styles from './Status.module.css';

interface StatusProps {
  status: StatusKey;
  /** Override the registry label with something more specific, e.g. "Passed · 84%". */
  label?: ReactNode;
}

/** Pill form — for lists and headers where the state needs to stand out. */
export function StatusBadge({ status, label, size = 'md' }: StatusProps & { size?: 'sm' | 'md' }) {
  const def = statusRegistry[status];
  const Icon = def.icon;
  return (
    <Badge
      tone={def.tone}
      size={size}
      icon={status === 'live' ? <span className={styles.liveDot} aria-hidden="true" /> : <Icon size={size === 'sm' ? 12 : 14} weight="fill" />}
    >
      {label ?? def.label}
    </Badge>
  );
}

/** Inline form — icon + text with no container, for dense rows and metadata lines. */
export function StatusLabel({ status, label, detail }: StatusProps & { detail?: ReactNode }) {
  const def = statusRegistry[status];
  const Icon = def.icon;
  return (
    <span className={cx(styles.inline, styles[def.tone])}>
      <Icon size={15} weight={def.shape === 'filled' ? 'fill' : 'duotone'} />
      <span className={styles.inlineLabel}>{label ?? def.label}</span>
      {detail && <span className={styles.inlineDetail}>{detail}</span>}
    </span>
  );
}

interface StatusNodeProps {
  shape: NodeShape;
  tone?: 'accent' | 'info' | 'warn' | 'danger' | 'neutral';
  size?: number;
  /** Accessible text. Nodes are decorative when a label is rendered alongside. */
  label?: string;
  /** 0–1, drawn for the partial shape. */
  fraction?: number;
  icon?: ReactNode;
  /** Plays the settle animation — use when a state has just changed, not on first render. */
  settle?: boolean;
  className?: string;
}

/** Path marker for journeys, timelines and curriculum rows. Shape carries state; tone reinforces it. */
export function StatusNode({ shape, tone = 'accent', size = 20, label, fraction = 0.5, icon, settle, className }: StatusNodeProps) {
  const glyph = Math.round(size * 0.55);
  const r = size / 2 - 1.5;
  const c = 2 * Math.PI * r;
  return (
    <span
      className={cx(styles.node, styles[shape], styles[tone], settle && styles.settle, className)}
      style={{ width: size, height: size }}
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      {shape === 'partial' && (
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className={styles.partialArc}>
          <circle cx={size / 2} cy={size / 2} r={r} fill="none" strokeWidth="2" className={styles.partialTrack} />
          <circle
            cx={size / 2}
            cy={size / 2}
            r={r}
            fill="none"
            strokeWidth="2"
            strokeLinecap="round"
            strokeDasharray={`${c * fraction} ${c}`}
            transform={`rotate(-90 ${size / 2} ${size / 2})`}
            className={styles.partialValue}
          />
        </svg>
      )}
      {icon ??
        (shape === 'filled' ? (
          <Check size={glyph} weight="bold" />
        ) : shape === 'dashed' && tone === 'neutral' ? (
          <LockSimple size={glyph} weight="bold" />
        ) : null)}
    </span>
  );
}

/** Maps an LMS status straight to its node. */
export function StatusNodeFor({ status, size, fraction, label }: { status: StatusKey; size?: number; fraction?: number; label?: string }) {
  const def = statusRegistry[status];
  const Icon = def.icon;
  const showIcon = def.shape === 'soft' || (def.shape === 'filled' && status !== 'completed') || status === 'not-eligible' || status === 'not-enrolled';
  return (
    <StatusNode
      shape={def.shape}
      tone={def.tone}
      size={size}
      fraction={fraction}
      label={label}
      icon={showIcon ? <Icon size={Math.round((size ?? 20) * 0.58)} weight={def.shape === 'filled' ? 'bold' : 'duotone'} /> : undefined}
    />
  );
}
