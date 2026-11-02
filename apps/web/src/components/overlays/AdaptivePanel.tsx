import type { ComponentProps } from 'react';
import { useViewport } from '@/hooks/useViewport';
import { BottomSheet, Drawer } from './Overlay';

/** Secondary detail panel: a right-edge drawer on desktop, a bottom sheet below 768px. */
export function AdaptivePanel(props: ComponentProps<typeof Drawer>) {
  const { isMobile } = useViewport();
  return isMobile ? <BottomSheet {...props} /> : <Drawer {...props} />;
}
