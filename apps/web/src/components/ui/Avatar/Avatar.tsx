import type { Tone } from '@/design/tokens';
import { cx } from '@/lib/cx';
import { initials } from '@/lib/format';
import styles from './Avatar.module.css';

const TONES: Tone[] = ['accent', 'info', 'warn', 'danger'];

/** Stable tone per name so a person keeps their color everywhere. */
export function toneForName(name: string): Tone {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = (hash * 31 + name.charCodeAt(i)) >>> 0;
  return TONES[hash % TONES.length];
}

interface AvatarProps {
  name: string;
  size?: number;
  tone?: Tone;
  /** Decorative when the name is already visible next to it. */
  decorative?: boolean;
  className?: string;
}

export function Avatar({ name, size = 32, tone, decorative = true, className }: AvatarProps) {
  return (
    <span
      className={cx(styles.avatar, styles[tone ?? toneForName(name)], className)}
      style={{ width: size, height: size, fontSize: Math.round(size * 0.38) }}
      aria-hidden={decorative || undefined}
      role={decorative ? undefined : 'img'}
      aria-label={decorative ? undefined : name}
    >
      {initials(name)}
    </span>
  );
}

export function AvatarGroup({ names, max = 3, size = 30, label }: { names: string[]; max?: number; size?: number; label?: string }) {
  const shown = names.slice(0, max);
  const rest = names.length - shown.length;
  return (
    <span className={styles.group} role="img" aria-label={label ?? `${names.length} people`}>
      {shown.map((n) => (
        <Avatar key={n} name={n} size={size} className={styles.stacked} />
      ))}
      {rest > 0 && (
        <span
          className={cx(styles.avatar, styles.neutral, styles.stacked)}
          style={{ width: size, height: size, fontSize: Math.round(size * 0.34) }}
          aria-hidden="true"
        >
          +{rest}
        </span>
      )}
    </span>
  );
}
