import type { HTMLAttributes, ReactNode } from 'react';
import type { Tone } from '@/design/tokens';
import { cx } from '@/lib/cx';
import styles from './Badge.module.css';

export const toneClass = (tone: Tone) => styles[tone];

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  tone?: Tone;
  icon?: ReactNode;
  dot?: boolean;
  size?: 'sm' | 'md';
  appearance?: 'soft' | 'outline' | 'solid';
}

export function Badge({ tone = 'neutral', icon, dot, size = 'md', appearance = 'soft', className, children, ...rest }: BadgeProps) {
  return (
    <span
      className={cx(styles.badge, styles[tone], icon && styles.withIcon, size === 'sm' && styles.sm, appearance !== 'soft' && styles[appearance], className)}
      {...rest}
    >
      {dot && <span className={styles.dot} aria-hidden="true" />}
      {icon}
      {children}
    </span>
  );
}

export function CountBadge({ tone = 'info', children, label }: { tone?: Tone; children: ReactNode; label?: string }) {
  return (
    <span className={cx(styles.count, styles[tone])} aria-label={label}>
      {children}
    </span>
  );
}

export function Kbd({ children, plain }: { children: ReactNode; plain?: boolean }) {
  return <kbd className={cx(styles.kbd, plain && styles.kbdPlain)}>{children}</kbd>;
}

export function IconChip({
  tone = 'accent',
  size = 'md',
  children,
  className,
}: {
  tone?: Tone;
  size?: 'md' | 'lg' | 'xl';
  children: ReactNode;
  className?: string;
}) {
  return (
    <span className={cx(styles.chip, styles[tone], size === 'lg' && styles.chipLg, size === 'xl' && styles.chipXl, className)} aria-hidden="true">
      {children}
    </span>
  );
}
