import { useCallback, useId, useRef, useState, type KeyboardEvent, type ReactNode } from 'react';
import { useDismiss } from '@/hooks/useDismiss';
import { cx } from '@/lib/cx';
import styles from './Menu.module.css';

export interface MenuItem {
  id: string;
  label: string;
  icon?: ReactNode;
  hint?: ReactNode;
  tone?: 'default' | 'danger';
  disabled?: boolean;
  onSelect?: () => void;
}

export interface MenuSection {
  label?: string;
  items: MenuItem[];
}

interface MenuProps {
  /** Renders the trigger; spread the given props onto a button. */
  trigger: (props: {
    ref: (el: HTMLButtonElement | null) => void;
    onClick: () => void;
    onKeyDown: (e: KeyboardEvent) => void;
    'aria-haspopup': 'menu';
    'aria-expanded': boolean;
    'aria-controls': string;
  }) => ReactNode;
  sections: MenuSection[];
  align?: 'start' | 'end';
  width?: number;
  header?: ReactNode;
}

/** Dropdown menu with roving focus (↑ ↓ Home End), Escape and outside-click dismissal. */
export function Menu({ trigger, sections, align = 'start', width = 220, header }: MenuProps) {
  const [open, setOpen] = useState(false);
  const id = useId();
  const wrapRef = useRef<HTMLSpanElement>(null);
  const triggerRef = useRef<HTMLButtonElement | null>(null);
  const listRef = useRef<HTMLDivElement>(null);

  const close = useCallback((restoreFocus = true) => {
    setOpen(false);
    if (restoreFocus) triggerRef.current?.focus();
  }, []);
  const dismiss = useCallback(() => setOpen(false), []);
  useDismiss(open, dismiss, [wrapRef]);

  const items = () => Array.from(listRef.current?.querySelectorAll<HTMLButtonElement>('[role="menuitem"]:not(:disabled)') ?? []);
  const focusAt = (index: number) => {
    const list = items();
    if (list.length === 0) return;
    list[(index + list.length) % list.length].focus();
  };

  const openAndFocus = (index: number) => {
    setOpen(true);
    requestAnimationFrame(() => focusAt(index));
  };

  const onTriggerKey = (e: KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      openAndFocus(0);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      openAndFocus(-1);
    }
  };

  const onListKey = (e: KeyboardEvent) => {
    const list = items();
    const i = list.indexOf(document.activeElement as HTMLButtonElement);
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      focusAt(i + 1);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      focusAt(i - 1);
    } else if (e.key === 'Home') {
      e.preventDefault();
      focusAt(0);
    } else if (e.key === 'End') {
      e.preventDefault();
      focusAt(-1);
    } else if (e.key === 'Tab') setOpen(false);
    else if (e.key === 'Escape') {
      e.preventDefault();
      close();
    }
  };

  return (
    <span ref={wrapRef} className={styles.wrap}>
      {trigger({
        ref: (el) => {
          triggerRef.current = el;
        },
        onClick: () => setOpen((o) => !o),
        onKeyDown: onTriggerKey,
        'aria-haspopup': 'menu',
        'aria-expanded': open,
        'aria-controls': id,
      })}
      {open && (
        <div id={id} ref={listRef} role="menu" className={cx(styles.menu, align === 'end' && styles.end)} style={{ width }} onKeyDown={onListKey}>
          {header}
          {sections.map((section, si) => (
            <div key={section.label ?? si} role="group" aria-label={section.label} className={styles.section}>
              {section.label && (
                <div className={styles.sectionLabel} aria-hidden="true">
                  {section.label}
                </div>
              )}
              {section.items.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  role="menuitem"
                  disabled={item.disabled}
                  className={cx(styles.item, item.tone === 'danger' && styles.danger)}
                  onClick={() => {
                    close();
                    item.onSelect?.();
                  }}
                >
                  {item.icon && <span className={styles.icon}>{item.icon}</span>}
                  <span className={styles.label}>{item.label}</span>
                  {item.hint && <span className={styles.hint}>{item.hint}</span>}
                </button>
              ))}
            </div>
          ))}
        </div>
      )}
    </span>
  );
}
