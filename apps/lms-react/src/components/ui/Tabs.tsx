import * as RadixTabs from '@radix-ui/react-tabs';
import type { ReactNode } from 'react';

import styles from './Nav.module.css';

export interface TabItem {
  value: string;
  label: ReactNode;
  /** A count next to the label (from the server's `counts`). */
  count?: number;
  content: ReactNode;
  disabled?: boolean;
}

export interface TabsProps {
  items: TabItem[];
  /** Controlled value — bind it to the URL with the query-state hooks (REACT-002). */
  value: string;
  onValueChange: (value: string) => void;
  /** Accessible name of the tab list. */
  label: string;
}

/** Arrow keys move between tabs; Home/End jump; the panel is the next Tab stop. */
export function Tabs({ items, value, onValueChange, label }: TabsProps) {
  return (
    <RadixTabs.Root value={value} onValueChange={onValueChange}>
      <RadixTabs.List className={styles.tabList} aria-label={label}>
        {items.map((item) => (
          <RadixTabs.Trigger key={item.value} value={item.value} className={styles.tab} disabled={item.disabled}>
            {item.label}
            {item.count !== undefined && <span className={styles.tabCount}>{item.count}</span>}
          </RadixTabs.Trigger>
        ))}
      </RadixTabs.List>
      {items.map((item) => (
        <RadixTabs.Content key={item.value} value={item.value} className={styles.tabPanel}>
          {item.content}
        </RadixTabs.Content>
      ))}
    </RadixTabs.Root>
  );
}
