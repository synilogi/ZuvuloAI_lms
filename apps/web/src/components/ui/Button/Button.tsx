import { forwardRef, type ButtonHTMLAttributes, type ReactNode } from 'react';
import { Link, type LinkProps } from 'react-router-dom';
import { Check } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import { Spinner } from '../Spinner/Spinner';
import styles from './Button.module.css';

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'quiet' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';
/** Forces a visual state for documentation. Never use in product screens. */
export type ForcedState = 'hover' | 'focus' | 'active' | 'selected';

interface CommonProps {
  variant?: ButtonVariant;
  size?: ButtonSize;
  iconStart?: ReactNode;
  iconEnd?: ReactNode;
  block?: boolean;
  forceState?: ForcedState;
}

export interface ButtonProps extends CommonProps, ButtonHTMLAttributes<HTMLButtonElement> {
  loading?: boolean;
  /** Shows a confirmed state with a check — use briefly after an action succeeds. */
  succeeded?: boolean;
}

export function buttonClass({ variant = 'secondary', size = 'md', block }: CommonProps) {
  return cx(styles.button, styles[variant], size !== 'md' && styles[size], block && styles.block);
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = 'secondary', size = 'md', iconStart, iconEnd, block, loading, succeeded, forceState, className, children, disabled, type = 'button', ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      className={cx(buttonClass({ variant, size, block }), loading && styles.loading, succeeded && styles.success, className)}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      data-force={forceState}
      {...rest}
    >
      {succeeded ? <Check size={16} weight="bold" /> : iconStart}
      {children !== undefined && <span>{children}</span>}
      {!succeeded && iconEnd}
      {loading && (
        <span className={styles.spinner}>
          <Spinner size={16} label="Working" />
        </span>
      )}
    </button>
  );
});

export interface IconButtonProps extends Omit<ButtonProps, 'iconStart' | 'iconEnd' | 'children' | 'block'> {
  /** Accessible name — required because the button has no visible text. */
  label: string;
  icon: ReactNode;
  boxed?: boolean;
}

export const IconButton = forwardRef<HTMLButtonElement, IconButtonProps>(function IconButton(
  { label, icon, variant = 'quiet', size = 'md', boxed, className, type = 'button', forceState, ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      aria-label={label}
      title={rest.title}
      data-force={forceState}
      className={cx(styles.button, styles.icon, styles[boxed ? 'secondary' : variant], boxed && styles.boxed, size !== 'md' && styles[size], className)}
      {...rest}
    >
      {icon}
    </button>
  );
});

export interface LinkButtonProps extends CommonProps, LinkProps {}

export function LinkButton({ variant = 'secondary', size = 'md', iconStart, iconEnd, block, className, children, ...rest }: LinkButtonProps) {
  return (
    <Link className={cx(buttonClass({ variant, size, block }), className)} {...rest}>
      {iconStart}
      <span>{children}</span>
      {iconEnd}
    </Link>
  );
}
