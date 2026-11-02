import { useEffect } from 'react';

let locks = 0;

/** Prevents the page behind an overlay from scrolling. Nested overlays share one lock. */
export function useBodyScrollLock(active: boolean) {
  useEffect(() => {
    if (!active) return;
    locks += 1;
    const { overflow } = document.body.style;
    document.body.style.overflow = 'hidden';
    return () => {
      locks -= 1;
      if (locks === 0) document.body.style.overflow = overflow;
    };
  }, [active]);
}
