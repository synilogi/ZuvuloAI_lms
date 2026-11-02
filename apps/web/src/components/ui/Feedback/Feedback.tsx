import type { ReactNode } from 'react';
import { CheckCircle, Info, Warning, WarningCircle, XCircle } from '@phosphor-icons/react';
import type { Tone } from '@/design/tokens';
import { cx } from '@/lib/cx';
import { IconChip } from '../Badge/Badge';
import styles from './Feedback.module.css';

/* ─── Inline message (shell Alert) ─────────────────────────────────────── */

type MessageKind = 'info' | 'success' | 'warn' | 'error';
const KIND: Record<MessageKind, { tone: Tone; icon: ReactNode }> = {
  info: { tone: 'info', icon: <Info size={19} /> },
  success: { tone: 'accent', icon: <CheckCircle size={19} /> },
  warn: { tone: 'warn', icon: <Warning size={19} /> },
  error: { tone: 'danger', icon: <XCircle size={19} /> },
};

export function InlineMessage({ kind = 'info', title, children, action }: { kind?: MessageKind; title?: ReactNode; children?: ReactNode; action?: ReactNode }) {
  const { tone, icon } = KIND[kind];
  return (
    <div role={kind === 'error' ? 'alert' : 'status'} className={cx(styles.message, styles[tone])}>
      {icon}
      <span className={styles.messageBody}>
        {title && <strong>{title} </strong>}
        {children}
      </span>
      {action && <span className={styles.messageAction}>{action}</span>}
    </div>
  );
}

/* ─── Skeleton ─────────────────────────────────────────────────────────── */

export function Skeleton({
  width = '100%',
  height = 12,
  radius,
  className,
}: {
  width?: number | string;
  height?: number;
  radius?: string;
  className?: string;
}) {
  return <span className={cx(styles.skeleton, className)} style={{ width, height, borderRadius: radius }} aria-hidden="true" />;
}

/* ─── Empty / error / success states ───────────────────────────────────── */

interface StateMessageProps {
  kind?: 'empty' | 'error' | 'success';
  icon?: ReactNode;
  title: string;
  children?: ReactNode;
  actions?: ReactNode;
  compact?: boolean;
  /** The title's level in the page's outline. `h1` where this message is the page's only heading; it looks the same. */
  headingLevel?: 'h1' | 'h2' | 'h3';
}

export function StateMessage({ kind = 'empty', icon, title, children, actions, compact, headingLevel: Heading = 'h3' }: StateMessageProps) {
  const tone: Tone = kind === 'error' ? 'danger' : 'accent';
  const fallback = kind === 'error' ? <WarningCircle size={26} /> : kind === 'success' ? <CheckCircle size={26} /> : null;
  return (
    <div className={cx(styles.state, compact && styles.compact)} role={kind === 'error' ? 'alert' : undefined}>
      <IconChip tone={tone} size="xl">
        {icon ?? fallback}
      </IconChip>
      <Heading className={styles.stateTitle}>{title}</Heading>
      {children && <p className={styles.stateBody}>{children}</p>}
      {actions && <div className={styles.stateActions}>{actions}</div>}
    </div>
  );
}
