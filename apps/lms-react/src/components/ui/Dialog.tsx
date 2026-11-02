import { X } from '@phosphor-icons/react';
import * as RadixDialog from '@radix-ui/react-dialog';
import { useLayoutEffect, useRef, type ReactNode } from 'react';

import { cx } from '@/lib/cx';

import { IconButton } from './Button';
import styles from './Overlay.module.css';

/**
 * Radix returns focus only to its own `Dialog.Trigger`. Our dialogs open from ordinary buttons, row menus and
 * code, so remember whatever had focus when the dialog opened and give focus back to it on close.
 */
function useReturnFocus(open: boolean) {
  const previous = useRef<HTMLElement | null>(null);
  useLayoutEffect(() => {
    if (open) previous.current = document.activeElement instanceof HTMLElement ? document.activeElement : null;
  }, [open]);
  return (event: Event) => {
    event.preventDefault();
    const target = previous.current;
    previous.current = null;
    if (target?.isConnected) target.focus();
  };
}

export interface DialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Required: every dialog is named by its title. */
  title: ReactNode;
  description?: ReactNode;
  children?: ReactNode;
  /** Buttons at the bottom (primary last). */
  footer?: ReactNode;
  size?: 'sm' | 'md' | 'lg';
  /** `auto` becomes a bottom sheet under 640px; `sheet` is always one. */
  presentation?: 'auto' | 'sheet';
  /** Keep the dialog open on outside click (use while a request runs or a form is dirty). */
  dismissible?: boolean;
}

/** Modal dialog: traps focus, closes on Escape, returns focus to the element that opened it. */
export function Dialog({ open, onOpenChange, title, description, children, footer, size = 'md', presentation = 'auto', dismissible = true }: DialogProps) {
  const onCloseAutoFocus = useReturnFocus(open);
  return (
    <RadixDialog.Root open={open} onOpenChange={onOpenChange}>
      <RadixDialog.Portal>
        <RadixDialog.Overlay className={styles.scrim} />
        <RadixDialog.Content
          className={cx(styles.dialog, styles[presentation], size !== 'md' && styles[size])}
          onCloseAutoFocus={onCloseAutoFocus}
          onPointerDownOutside={(event) => {
            if (!dismissible) event.preventDefault();
          }}
          onEscapeKeyDown={(event) => {
            if (!dismissible) event.preventDefault();
          }}
        >
          <header className={styles.header}>
            <div>
              <RadixDialog.Title className={styles.title}>{title}</RadixDialog.Title>
              {description ? (
                <RadixDialog.Description className={styles.description}>{description}</RadixDialog.Description>
              ) : (
                <RadixDialog.Description className="visually-hidden">{title}</RadixDialog.Description>
              )}
            </div>
            <RadixDialog.Close asChild>
              <IconButton label="Close" icon={<X size={18} />} size="sm" disabled={!dismissible} />
            </RadixDialog.Close>
          </header>
          {children !== undefined && <div className={styles.body}>{children}</div>}
          {footer && <footer className={styles.footer}>{footer}</footer>}
        </RadixDialog.Content>
      </RadixDialog.Portal>
    </RadixDialog.Root>
  );
}

/** A dialog that is always a bottom sheet (filters on mobile, quick pickers). */
export function BottomSheet(props: Omit<DialogProps, 'presentation'>) {
  return <Dialog {...props} presentation="sheet" />;
}

export interface DrawerProps extends Omit<DialogProps, 'presentation' | 'size'> {
  size?: 'md' | 'lg';
}

/** Side panel for create/edit/detail next to a list (categories, calendar events). Full width on phones. */
export function Drawer({ open, onOpenChange, title, description, children, footer, size = 'md', dismissible = true }: DrawerProps) {
  const onCloseAutoFocus = useReturnFocus(open);
  return (
    <RadixDialog.Root open={open} onOpenChange={onOpenChange}>
      <RadixDialog.Portal>
        <RadixDialog.Overlay className={styles.scrim} />
        <RadixDialog.Content
          className={cx(styles.drawer, size === 'lg' && styles.lg)}
          onCloseAutoFocus={onCloseAutoFocus}
          onPointerDownOutside={(event) => {
            if (!dismissible) event.preventDefault();
          }}
          onEscapeKeyDown={(event) => {
            if (!dismissible) event.preventDefault();
          }}
        >
          <header className={styles.header}>
            <div>
              <RadixDialog.Title className={styles.title}>{title}</RadixDialog.Title>
              {description ? (
                <RadixDialog.Description className={styles.description}>{description}</RadixDialog.Description>
              ) : (
                <RadixDialog.Description className="visually-hidden">{title}</RadixDialog.Description>
              )}
            </div>
            <RadixDialog.Close asChild>
              <IconButton label="Close" icon={<X size={18} />} size="sm" disabled={!dismissible} />
            </RadixDialog.Close>
          </header>
          <div className={styles.body}>{children}</div>
          {footer && <footer className={styles.footer}>{footer}</footer>}
        </RadixDialog.Content>
      </RadixDialog.Portal>
    </RadixDialog.Root>
  );
}
