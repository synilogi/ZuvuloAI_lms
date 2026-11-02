import { createContext, useContext } from 'react';

export interface ShellLayout {
  /** Height reserved at the bottom of the viewport by shell chrome (the mobile bottom nav). */
  bottomInset: number;
  /** The scrolling element that holds page content. */
  scrollRoot: HTMLElement | null;
  openCommandPalette: () => void;
}

export const ShellLayoutContext = createContext<ShellLayout>({ bottomInset: 0, scrollRoot: null, openCommandPalette: () => undefined });

export const useShellLayout = () => useContext(ShellLayoutContext);
