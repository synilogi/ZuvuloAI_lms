import type { ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { useViewport } from '@/hooks/useViewport';
import { useShellLayout } from '@/shell/ShellLayoutContext';
import styles from './Actions.module.css';

interface StickyActionBarProps {
  /** Desktop: rendered in place and kept in view while the page scrolls. */
  children: ReactNode;
  /** Mobile: a compact bar fixed above the bottom navigation. */
  mobile: ReactNode;
  /** Keep the desktop content visible inline on mobile as well (above the fold content). */
  keepInlineOnMobile?: boolean;
}

/** Desktop sticky aside → mobile sticky bottom action. */
export function StickyActionBar({ children, mobile, keepInlineOnMobile }: StickyActionBarProps) {
  const { isMobile } = useViewport();
  const { bottomInset } = useShellLayout();

  if (!isMobile) return <div className={styles.sticky}>{children}</div>;

  return (
    <>
      {keepInlineOnMobile && children}
      <div className={styles.mobileSpacer} aria-hidden="true" />
      {createPortal(
        <div className={styles.mobileBar} style={{ bottom: `calc(${bottomInset}px + env(safe-area-inset-bottom))` }}>
          {mobile}
        </div>,
        document.body,
      )}
    </>
  );
}
