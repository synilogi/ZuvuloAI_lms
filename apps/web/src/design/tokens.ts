/**
 * JS mirror of the token values that code needs to reason about (breakpoints,
 * z-index, motion). CSS remains the source for visual values — see styles/tokens.css.
 */

export const breakpoints = {
  xs: 320,
  sm: 414,
  md: 768, // shell switches from mobile to desktop composition here
  lg: 1024,
  xl: 1280,
  '2xl': 1440,
  '3xl': 1920,
} as const;

export type BreakpointName = keyof typeof breakpoints | 'base';

/** Widths the LMS is verified against. */
export const verifiedWidths = [320, 375, 390, 414, 768, 1024, 1280, 1440, 1920] as const;

export function breakpointFor(width: number): BreakpointName {
  if (width >= breakpoints['3xl']) return '3xl';
  if (width >= breakpoints['2xl']) return '2xl';
  if (width >= breakpoints.xl) return 'xl';
  if (width >= breakpoints.lg) return 'lg';
  if (width >= breakpoints.md) return 'md';
  if (width >= breakpoints.sm) return 'sm';
  if (width >= breakpoints.xs) return 'xs';
  return 'base';
}

export const motion = {
  fast: 120,
  base: 200,
  slow: 240,
  progress: 300,
  easing: 'cubic-bezier(0.2,0.8,0.2,1)',
} as const;

export const zIndex = {
  sticky: 20,
  tooltip: 60,
  popover: 70,
  navDrawer: 90,
  searchSheet: 95,
  drawer: 98,
  modal: 100,
  toast: 110,
} as const;

export type Density = 'immersive' | 'balanced' | 'dense';
export type Tone = 'accent' | 'info' | 'warn' | 'danger' | 'neutral';
