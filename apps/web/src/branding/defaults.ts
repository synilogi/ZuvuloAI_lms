import favicon from '@/assets/brand/favicon-32.png';
import touchIcon from '@/assets/brand/apple-touch-icon.png';
import fullLight from '@/assets/brand/logo-full.png';
import fullDark from '@/assets/brand/logo-full-dark.png';
import lockupLight from '@/assets/brand/logo-lockup.png';
import lockupDark from '@/assets/brand/logo-lockup-dark.png';
import mark from '@/assets/brand/logo-mark.png';
import markDark from '@/assets/brand/logo-mark-dark.png';

/*
 * The official ZuviloAI brand assets, built into the app (cut from brand/zuviloai-logo.png by brand/make_assets.py).
 * They are the default, and the fallback whenever a saved asset cannot be loaded — so the brand shows without the
 * API. Bundled, so each address carries a content hash and a new build is never shown from an old cache.
 */

export const BRAND_NAME = 'ZuviloAI';

/** A built-in image and its pixel size. `dark` is the same artwork set for a dark surface. */
export interface DefaultBrandImage {
  light: string;
  dark: string;
  width: number;
  height: number;
}

export const DEFAULT_BRAND = {
  /** Symbol beside the wordmark — headers. */
  lockup: { light: lockupLight, dark: lockupDark, width: 394, height: 112 },
  /** The logo as supplied: symbol over wordmark — sign-in and other roomy places. */
  full: { light: fullLight, dark: fullDark, width: 640, height: 604 },
  /** The symbol alone, on a square — where the logo does not fit. The dark cut is for a dark surface; a white tile shows the light one. */
  mark: { light: mark, dark: markDark, width: 256, height: 256 },
  favicon,
  touchIcon,
} as const satisfies Record<'lockup' | 'full' | 'mark', DefaultBrandImage> & { favicon: string; touchIcon: string };
