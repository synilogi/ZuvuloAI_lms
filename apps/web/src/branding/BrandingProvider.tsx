import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { BrandAsset, PlatformBranding } from '@syniastrolms/domain';
import { services } from '@/services';

/*
 * The platform's branding, for every page: the logo and favicon the Super Admin saved, or `null` for the built-in
 * ZuviloAI ones (`defaults.ts`). Asked of the server once per page load; the last answer is remembered so a returning
 * visitor sees the right logo at once, and it is corrected the moment the server answers. A failed request changes
 * nothing — the remembered or built-in branding stays.
 *
 * This is the platform's alone. An academy's appearance settings are read elsewhere and never pass through here.
 */

const BUILT_IN: PlatformBranding = { logo: null, favicon: null };
const CACHE_KEY = 'zuviloai:branding';

interface BrandingValue extends PlatformBranding {
  /** Asks the server again — after the Super Admin saves, so the change shows without a reload. */
  refresh: () => Promise<void>;
}

// Outside a provider (a component drawn on its own) the built-in branding shows.
const BrandingContext = createContext<BrandingValue>({ ...BUILT_IN, refresh: async () => undefined });

const isAsset = (value: unknown): value is BrandAsset =>
  !!value && typeof value === 'object' && typeof (value as BrandAsset).url === 'string' && /^https?:\/\//.test((value as BrandAsset).url);

function remembered(): PlatformBranding {
  try {
    const stored = JSON.parse(localStorage.getItem(CACHE_KEY) ?? 'null') as Partial<PlatformBranding> | null;
    return { logo: isAsset(stored?.logo) ? stored.logo : null, favicon: isAsset(stored?.favicon) ? stored.favicon : null };
  } catch {
    return BUILT_IN;
  }
}

function remember(branding: PlatformBranding) {
  try {
    // Only addresses that will still mean something on the next visit — never the demo build's in-memory files.
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify({ logo: isAsset(branding.logo) ? branding.logo : null, favicon: isAsset(branding.favicon) ? branding.favicon : null }),
    );
  } catch {
    /* ignore */
  }
}

/**
 * Points the page's icon links (`index.html`, marked `data-brand-icon`) at the saved favicon, or back at the
 * built-in ones. A saved favicon's address is new for every upload, so the browser never shows a stale one.
 */
function applyFavicon(favicon: BrandAsset | null) {
  for (const link of document.querySelectorAll<HTMLLinkElement>('link[data-brand-icon]')) {
    if (link.dataset.builtIn === undefined)
      link.dataset.builtIn = JSON.stringify([link.getAttribute('href'), link.getAttribute('type'), link.getAttribute('sizes')]);
    const [href, type, sizes] = (favicon ? [favicon.url, favicon.mime, null] : JSON.parse(link.dataset.builtIn)) as (string | null)[];
    const set = (name: string, value: string | null) => (value === null ? link.removeAttribute(name) : link.setAttribute(name, value));
    set('type', type);
    set('sizes', sizes);
    set('href', href);
  }
}

export function BrandingProvider({ children }: { children: ReactNode }) {
  const [branding, setBranding] = useState<PlatformBranding>(remembered);

  const refresh = useCallback(async () => {
    try {
      const current = await services.branding.current();
      setBranding(current);
      remember(current);
    } catch {
      /* The server could not be asked: what is showing stays. */
    }
  }, []);

  useEffect(() => void refresh(), [refresh]);
  useEffect(() => applyFavicon(branding.favicon), [branding.favicon]);

  const value = useMemo(() => ({ ...branding, refresh }), [branding, refresh]);
  return <BrandingContext.Provider value={value}>{children}</BrandingContext.Provider>;
}

export const useBranding = () => useContext(BrandingContext);
