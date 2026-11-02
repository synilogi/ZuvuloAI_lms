import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import type { ReactNode } from 'react';

import { cx } from '@/lib/cx';

import styles from './Nav.module.css';

export type MenuEntry =
  { type?: 'item'; label: ReactNode; onSelect: () => void; icon?: ReactNode; danger?: boolean; disabled?: boolean } | { type: 'separator' };

export interface MenuProps {
  /** The button that opens the menu (usually an IconButton "More actions for …"). */
  trigger: ReactNode;
  items: MenuEntry[];
  align?: 'start' | 'end';
}

/** Row and page action menus. Arrow keys move, Enter/Space select, Escape closes and returns focus to the trigger. */
export function Menu({ trigger, items, align = 'end' }: MenuProps) {
  return (
    <DropdownMenu.Root modal={false}>
      <DropdownMenu.Trigger asChild>{trigger}</DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content className={styles.menu} align={align} sideOffset={4} collisionPadding={8}>
          {items.map((item, index) =>
            item.type === 'separator' ? (
              <DropdownMenu.Separator key={index} className={styles.menuSeparator} />
            ) : (
              <DropdownMenu.Item
                key={index}
                className={cx(styles.menuItem, item.danger && styles.menuDanger)}
                disabled={item.disabled}
                onSelect={item.onSelect}
              >
                {item.icon}
                {item.label}
              </DropdownMenu.Item>
            ),
          )}
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  );
}
