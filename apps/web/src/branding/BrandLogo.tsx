import { useState } from 'react';
import { cx } from '@/lib/cx';
import { useBranding } from './BrandingProvider';
import { BRAND_NAME, DEFAULT_BRAND } from './defaults';
import styles from './BrandLogo.module.css';

export type BrandLogoVariant = 'lockup' | 'full' | 'mark';

interface BrandLogoProps {
  /**
   * `lockup` — symbol beside the wordmark, for headers. `full` — the whole logo, for sign-in and other roomy places.
   * `mark` — the symbol alone, where the logo does not fit.
   */
  variant?: BrandLogoVariant;
  /** Empty when the logo sits inside something already named (a link labelled "ZuviloAI home"). */
  alt?: string;
  className?: string;
}

/**
 * The platform's logo — the one place every screen draws it from. It shows what the Super Admin saved: their logo for
 * `lockup` and `full`, their favicon for `mark`. With nothing saved, or when a saved file fails to load, it shows the
 * built-in ZuviloAI artwork in the cut made for that spot, set for the light or the dark theme.
 */
export function BrandLogo({ variant = 'lockup', alt = BRAND_NAME, className }: BrandLogoProps) {
  const { logo, favicon } = useBranding();
  const saved = variant === 'mark' ? favicon : logo;
  // The address that failed, so a new upload is tried afresh.
  const [failed, setFailed] = useState<string>();

  if (saved && saved.url !== failed) {
    return (
      <span className={cx(styles.logo, styles[variant], styles.saved, className)}>
        <img src={saved.url} alt={alt} width={saved.width} height={saved.height} decoding="async" onError={() => setFailed(saved.url)} />
      </span>
    );
  }

  const art = DEFAULT_BRAND[variant];
  return (
    <span className={cx(styles.logo, styles[variant], className)}>
      <img className={styles.onLight} src={art.light} alt={alt} width={art.width} height={art.height} decoding="async" />
      {/* The same artwork for a dark surface; fetched only once the dark theme shows it. */}
      {art.dark !== art.light && (
        <img className={styles.onDark} src={art.dark} alt={alt} width={art.width} height={art.height} decoding="async" loading="lazy" />
      )}
    </span>
  );
}
