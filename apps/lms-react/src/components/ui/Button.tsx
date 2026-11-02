import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from 'react';
import { Link, type LinkProps } from 'react-router-dom';

import { cx } from '@/lib/cx';

import styles from './Button.module.css';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';

interface CommonProps {
  variant?: ButtonVariant;
  size?: ButtonSize;
  /** Stretch to the container's width. */
  block?: boolean;
  /** Shown before the label. */
  icon?: ReactNode;
}

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement>, CommonProps {
  /** Shows progress and disables the button while an action runs. */
  loading?: boolean;
}

const classes = ({ variant = 'secondary', size = 'md', block }: CommonProps, extra?: string) =>
  cx(styles.button, styles[variant], size !== 'md' && styles[size], block && styles.block, extra);

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant, size, block, icon, loading = false, disabled, type = 'button', className, children, ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      className={classes({ variant, size, block }, className)}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      {...rest}
    >
      {loading ? <span className={styles.spinner} aria-hidden="true" /> : icon}
      {children}
    </button>
  );
});

export interface IconButtonProps extends Omit<ButtonProps, 'children' | 'icon' | 'block'> {
  /** Accessible name — required because the button has no visible text. */
  label: string;
  icon: ReactNode;
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  { label, icon, variant = 'ghost', size, className, ...rest },
  ref,
) {
  return (
    <Button ref={ref} variant={variant} size={size} className={cx(styles.icon, className)} aria-label={label} title={label} {...rest}>
      {icon}
    </Button>
  );
});

export interface LinkButtonProps extends LinkProps, CommonProps {}

/** A link that looks like a button — for navigation, never for actions. */
export const LinkButton = forwardRef<HTMLAnchorElement, LinkButtonProps>(function LinkButton(
  { variant, size, block, icon, className, children, ...rest },
  ref,
) {
  return (
    <Link ref={ref} className={classes({ variant, size, block }, className)} {...rest}>
      {icon}
      {children}
    </Link>
  );
});
