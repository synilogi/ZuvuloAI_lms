import { CheckCircle, Info, Warning, WarningCircle } from '@phosphor-icons/react';
import type { ReactNode } from 'react';

import { cx } from '@/lib/cx';

import styles from './Feedback.module.css';

export type AlertTone = 'info' | 'success' | 'warn' | 'danger';

const ICONS: Record<AlertTone, ReactNode> = {
  info: <Info size={18} weight="fill" />,
  success: <CheckCircle size={18} weight="fill" />,
  warn: <Warning size={18} weight="fill" />,
  danger: <WarningCircle size={18} weight="fill" />,
};

export interface InlineAlertProps {
  tone?: AlertTone;
  title?: ReactNode;
  children?: ReactNode;
  /** A button or link at the end (e.g. "Go to billing"). */
  action?: ReactNode;
  className?: string;
}

/** A message inside the page. Danger and warning are announced (`role="alert"`); info and success are polite. */
export function InlineAlert({ tone = 'info', title, children, action, className }: InlineAlertProps) {
  return (
    <div className={cx(styles.alert, styles[tone], className)} role={tone === 'danger' || tone === 'warn' ? 'alert' : 'status'}>
      <span className={styles.alertIcon} aria-hidden="true">
        {ICONS[tone]}
      </span>
      <div className={styles.alertBody}>
        {title && <strong className={styles.alertTitle}>{title}</strong>}
        {children && <div>{children}</div>}
      </div>
      {action && <div className={styles.alertAction}>{action}</div>}
    </div>
  );
}

/** A full-width strip above the page (academy-wide subscription state, offline). */
export function Banner(props: InlineAlertProps) {
  return <InlineAlert {...props} className={cx(styles.banner, props.className)} />;
}
