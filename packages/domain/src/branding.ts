/*
 * The platform's own branding: the logo and favicon of the ZuviloAI website, its sign-in screens and the workspace
 * chrome. One set for the whole platform, replaced by the Super Admin alone. It is not an academy's appearance
 * (`AppearanceSettings`, in `settings.ts`): an academy never sets it, and saving it never touches an academy.
 *
 * The rules a file must meet are here so the Super Admin's screen and the API judge an upload the same way. The
 * screen's verdict is a courtesy; the API's is the one that counts.
 */

export const BRAND_ASSET_KINDS = ['logo', 'favicon'] as const;
export type BrandAssetKind = (typeof BRAND_ASSET_KINDS)[number];

export const isBrandAssetKind = (value: unknown): value is BrandAssetKind => BRAND_ASSET_KINDS.includes(value as BrandAssetKind);

export interface BrandAssetRule {
  label: string;
  /** The formats accepted, as people name them. */
  formats: string;
  /** Allow-list: the declared type and the file extension must both be here, and the bytes must agree. */
  mimes: readonly string[];
  exts: readonly string[];
  maxBytes: number;
  minWidth: number;
  minHeight: number;
  maxWidth: number;
  maxHeight: number;
  /** Width ÷ height, inclusive. */
  minAspect: number;
  maxAspect: number;
  /** What to prepare, in one line. */
  guidance: string;
}

const KB = 1024;

export const BRAND_ASSET_RULES: Record<BrandAssetKind, BrandAssetRule> = {
  logo: {
    label: 'Logo',
    formats: 'PNG, JPG or WebP',
    mimes: ['image/png', 'image/jpeg', 'image/webp'],
    exts: ['.png', '.jpg', '.jpeg', '.webp'],
    maxBytes: 1024 * KB,
    minWidth: 128,
    minHeight: 64,
    maxWidth: 2400,
    maxHeight: 1200,
    minAspect: 1,
    maxAspect: 6,
    guidance: 'A horizontal logo on a transparent background works best — it is shown about 40 px tall in headers.',
  },
  favicon: {
    label: 'Favicon',
    formats: 'PNG or ICO',
    mimes: ['image/png', 'image/x-icon', 'image/vnd.microsoft.icon'],
    exts: ['.png', '.ico'],
    maxBytes: 256 * KB,
    minWidth: 48,
    minHeight: 48,
    maxWidth: 1024,
    maxHeight: 1024,
    // Square, with a pixel or two of tolerance for an export that is off by one.
    minAspect: 0.97,
    maxAspect: 1.03,
    guidance: 'A square icon, ideally 512 × 512. It is also the compact mark where the full logo does not fit.',
  },
};

/** What is known about a file being offered as a brand asset. Anything not yet known is left out and not judged. */
export interface BrandAssetFacts {
  /** The file's name, for its extension. */
  name?: string;
  mime?: string;
  bytes?: number;
  width?: number;
  height?: number;
}

const kb = (bytes: number) => (bytes >= 1024 * KB ? `${Math.round((bytes / (1024 * KB)) * 10) / 10} MB` : `${Math.round(bytes / KB)} KB`);

const extensionOf = (name: string) => {
  const dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.slice(dot).toLowerCase();
};

/** Why a file cannot be this brand asset, in words for the person choosing it. Empty when it can. */
export function brandAssetIssues(kind: BrandAssetKind, facts: BrandAssetFacts): string[] {
  const rule = BRAND_ASSET_RULES[kind];
  const issues: string[] = [];
  const wrongType =
    (facts.name !== undefined && !rule.exts.includes(extensionOf(facts.name))) || (facts.mime !== undefined && !rule.mimes.includes(facts.mime.toLowerCase()));
  if (wrongType) issues.push(`The ${rule.label.toLowerCase()} must be a ${rule.formats} file.`);
  if (facts.bytes !== undefined && facts.bytes > rule.maxBytes)
    issues.push(`The ${rule.label.toLowerCase()} can be at most ${kb(rule.maxBytes)} — this file is ${kb(facts.bytes)}.`);
  if (facts.width !== undefined && facts.height !== undefined) {
    const { width, height } = facts;
    const size = `${width} × ${height}`;
    if (width < rule.minWidth || height < rule.minHeight)
      issues.push(`The ${rule.label.toLowerCase()} must be at least ${rule.minWidth} × ${rule.minHeight} pixels — this image is ${size}.`);
    else if (width > rule.maxWidth || height > rule.maxHeight)
      issues.push(`The ${rule.label.toLowerCase()} can be at most ${rule.maxWidth} × ${rule.maxHeight} pixels — this image is ${size}.`);
    const aspect = height > 0 ? width / height : 0;
    if (aspect < rule.minAspect || aspect > rule.maxAspect)
      issues.push(
        kind === 'favicon'
          ? `The favicon must be square — this image is ${size}.`
          : `The logo must be between square and ${rule.maxAspect} times as wide as it is tall — this image is ${size}.`,
      );
  }
  return issues;
}

/** A brand asset as a page loads it. `url` is a path on the API, new for every upload, so it can be cached for good. */
export interface BrandAsset {
  url: string;
  mime: string;
  width: number;
  height: number;
}

/**
 * The platform's branding as every visitor reads it (`GET /public/branding`). `null` means the built-in ZuviloAI
 * asset, which every client carries itself — so branding still shows when the API cannot be reached.
 */
export interface PlatformBranding {
  logo: BrandAsset | null;
  favicon: BrandAsset | null;
}

/** A saved asset as the Super Admin's screen shows it. */
export interface SavedBrandAsset extends BrandAsset {
  /** The name of the file that was uploaded, cleaned. */
  name: string;
  sizeBytes: number;
  updatedAt: string;
  /** Who uploaded it, by name. */
  updatedBy?: string;
}

/** The branding settings (`GET /superadmin/branding`). `null` — the default is in use. */
export interface PlatformBrandingSettings {
  logo: SavedBrandAsset | null;
  favicon: SavedBrandAsset | null;
}
