import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';

type Theme = 'light' | 'dark';

interface Preferences {
  theme: Theme;
  sidebarCollapsed: boolean;
  /** Previews reduced motion without changing the OS setting. */
  reduceMotion: boolean;
  toggleTheme: () => void;
  setTheme: (theme: Theme) => void;
  toggleSidebar: () => void;
  setReduceMotion: (on: boolean) => void;
}

const PreferencesContext = createContext<Preferences | null>(null);
const KEY = 'syniastrolms:preferences';
const isFramed = new URLSearchParams(window.location.search).has('frame');

function readStored(): Partial<Pick<Preferences, 'theme' | 'sidebarCollapsed' | 'reduceMotion'>> {
  const params = new URLSearchParams(window.location.search);
  const fromUrl = params.get('theme');
  try {
    const stored = JSON.parse(localStorage.getItem(KEY) ?? '{}');
    return { ...stored, ...(fromUrl === 'dark' || fromUrl === 'light' ? { theme: fromUrl } : {}) };
  } catch {
    return fromUrl === 'dark' || fromUrl === 'light' ? { theme: fromUrl } : {};
  }
}

export function PreferencesProvider({ children }: { children: ReactNode }) {
  const initial = useMemo(readStored, []);
  const [theme, setTheme] = useState<Theme>(initial.theme ?? 'light');
  const [sidebarCollapsed, setCollapsed] = useState(initial.sidebarCollapsed ?? false);
  const [reduceMotion, setReduceMotion] = useState(initial.reduceMotion ?? false);

  useEffect(() => {
    const root = document.documentElement;
    if (theme === 'dark') root.setAttribute('data-theme', 'dark');
    else root.removeAttribute('data-theme');
    if (reduceMotion) root.setAttribute('data-motion', 'reduced');
    else root.removeAttribute('data-motion');
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', theme === 'dark' ? '#121219' : '#f6f6fa');
    if (isFramed) return;
    try {
      localStorage.setItem(KEY, JSON.stringify({ theme, sidebarCollapsed, reduceMotion }));
    } catch {
      /* storage unavailable — preferences stay in memory */
    }
  }, [theme, sidebarCollapsed, reduceMotion]);

  const toggleTheme = useCallback(() => setTheme((t) => (t === 'dark' ? 'light' : 'dark')), []);
  const toggleSidebar = useCallback(() => setCollapsed((c) => !c), []);

  const value = useMemo(
    () => ({ theme, sidebarCollapsed, reduceMotion, toggleTheme, setTheme, toggleSidebar, setReduceMotion }),
    [theme, sidebarCollapsed, reduceMotion, toggleTheme, toggleSidebar],
  );

  return <PreferencesContext.Provider value={value}>{children}</PreferencesContext.Provider>;
}

export function usePreferences() {
  const ctx = useContext(PreferencesContext);
  if (!ctx) throw new Error('usePreferences must be used inside <PreferencesProvider>');
  return ctx;
}
