import { useSyncExternalStore } from 'react';

/** Breakpoints shared with tokens.css (CSS variables cannot be used inside @media). */
export const BREAKPOINTS = { sm: 640, md: 768, lg: 1024, xl: 1280 } as const;
export type Breakpoint = keyof typeof BREAKPOINTS;

/** `true` while the viewport is at least `min` pixels wide. Defaults to desktop where matchMedia is unavailable. */
export function useMinWidth(min: number): boolean {
  const query = `(min-width: ${min}px)`;
  return useSyncExternalStore(
    (onChange) => {
      if (typeof window === 'undefined' || !window.matchMedia) return () => {};
      const list = window.matchMedia(query);
      list.addEventListener('change', onChange);
      return () => list.removeEventListener('change', onChange);
    },
    () => (typeof window !== 'undefined' && window.matchMedia ? window.matchMedia(query).matches : true),
    () => true,
  );
}

/** `true` at or above the named breakpoint. */
export const useBreakpoint = (name: Breakpoint) => useMinWidth(BREAKPOINTS[name]);
