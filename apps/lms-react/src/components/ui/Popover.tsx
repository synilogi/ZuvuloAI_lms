import * as RadixPopover from '@radix-ui/react-popover';
import * as RadixTooltip from '@radix-ui/react-tooltip';
import type { ReactNode } from 'react';

import styles from './Overlay.module.css';

export interface PopoverProps {
  trigger: ReactNode;
  children: ReactNode;
  /** Accessible name of the popover content. */
  label: string;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  align?: 'start' | 'center' | 'end';
}

/** Non-modal floating panel (notification bell list, filter details). Escape closes and returns focus. */
export function Popover({ trigger, children, label, open, onOpenChange, align = 'end' }: PopoverProps) {
  return (
    <RadixPopover.Root open={open} onOpenChange={onOpenChange}>
      <RadixPopover.Trigger asChild>{trigger}</RadixPopover.Trigger>
      <RadixPopover.Portal>
        <RadixPopover.Content className={styles.popover} align={align} sideOffset={6} collisionPadding={8} aria-label={label}>
          {children}
        </RadixPopover.Content>
      </RadixPopover.Portal>
    </RadixPopover.Root>
  );
}

/** Wrap the app once so tooltips share one delay. */
export const TooltipProvider = ({ children }: { children: ReactNode }) => <RadixTooltip.Provider delayDuration={400}>{children}</RadixTooltip.Provider>;

export interface TooltipProps {
  content: ReactNode;
  /** A focusable element; the tooltip appears on hover and on keyboard focus. */
  children: ReactNode;
}

/** Supplementary text only — never the only place an essential instruction lives. */
export function Tooltip({ content, children }: TooltipProps) {
  return (
    <RadixTooltip.Root>
      <RadixTooltip.Trigger asChild>{children}</RadixTooltip.Trigger>
      <RadixTooltip.Portal>
        <RadixTooltip.Content className={styles.tooltip} sideOffset={6} collisionPadding={8}>
          {content}
        </RadixTooltip.Content>
      </RadixTooltip.Portal>
    </RadixTooltip.Root>
  );
}
