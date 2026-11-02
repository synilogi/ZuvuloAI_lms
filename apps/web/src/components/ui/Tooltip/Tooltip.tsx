import { cloneElement, useId, useState, type ReactElement } from 'react';
import { cx } from '@/lib/cx';
import styles from './Tooltip.module.css';

interface TooltipProps {
  content: string;
  side?: 'top' | 'right' | 'bottom';
  children: ReactElement;
  /** Keep visible — for documentation only. */
  forceOpen?: boolean;
}

/**
 * Supplementary label on hover and keyboard focus. Never the only place information lives —
 * touch devices have no hover, so critical detail must also appear inline.
 */
export function Tooltip({ content, side = 'top', children, forceOpen }: TooltipProps) {
  const id = useId();
  const [open, setOpen] = useState(false);
  const visible = forceOpen || open;

  const trigger = cloneElement(children as ReactElement<Record<string, unknown>>, {
    'aria-describedby': id,
    onMouseEnter: () => setOpen(true),
    onMouseLeave: () => setOpen(false),
    onFocus: () => setOpen(true),
    onBlur: () => setOpen(false),
  });

  return (
    <span className={styles.wrap} onKeyDown={(e) => e.key === 'Escape' && setOpen(false)}>
      {trigger}
      <span id={id} role="tooltip" className={cx(styles.tip, styles[side], visible && styles.visible)}>
        {content}
      </span>
    </span>
  );
}
