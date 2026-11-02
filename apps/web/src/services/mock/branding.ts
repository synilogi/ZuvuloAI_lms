import { BRAND_ASSET_KINDS, brandAssetIssues, type BrandAssetKind, type PlatformBrandingSettings, type SavedBrandAsset } from '@syniastrolms/domain';

import { readImageSize } from '@/branding/imageFile';
import { ServiceError, type BrandingService } from '../contracts';
import { respond } from './simulation';

/*
 * The demo build's branding: kept in memory for the visit, the files shown from the browser's own copy. It applies
 * the same rules the API does (`brandAssetIssues`), so the screen behaves as it will against the real server.
 */

let saved: PlatformBrandingSettings = { logo: null, favicon: null };

const forget = (asset: SavedBrandAsset | null) => {
  if (asset?.url.startsWith('blob:')) URL.revokeObjectURL(asset.url);
};

export const brandingService: BrandingService = {
  current: () =>
    respond(() => {
      const shown = (asset: SavedBrandAsset | null) => (asset ? { url: asset.url, mime: asset.mime, width: asset.width, height: asset.height } : null);
      return { logo: shown(saved.logo), favicon: shown(saved.favicon) };
    }, 120),
  settings: () => respond(() => saved, 300),
  save: async (files) => {
    const offered = BRAND_ASSET_KINDS.flatMap((kind) => (files[kind] ? [{ kind, file: files[kind] }] : []));
    if (!offered.length) throw new ServiceError('Choose a logo or a favicon to upload.', 'conflict', 'VALIDATION_FAILED');
    const issues: { field: string; message: string }[] = [];
    const next: Partial<Record<BrandAssetKind, SavedBrandAsset>> = {};
    for (const { kind, file } of offered) {
      const size = await readImageSize(file).catch(() => undefined);
      const found = size
        ? brandAssetIssues(kind, { name: file.name, mime: file.type, bytes: file.size, ...size })
        : [`The ${kind} file is not an image that can be read. Upload the original file.`];
      issues.push(...found.map((message) => ({ field: kind, message })));
      if (size && !found.length)
        next[kind] = { url: '', mime: file.type, ...size, name: file.name, sizeBytes: file.size, updatedAt: new Date().toISOString(), updatedBy: 'You (demo)' };
    }
    if (issues.length)
      throw new ServiceError(`Check the files and try again. ${issues.map((i) => i.message).join(' ')}`, 'conflict', 'VALIDATION_FAILED', issues, 400);
    for (const { kind, file } of offered) {
      forget(saved[kind]);
      saved = { ...saved, [kind]: { ...next[kind]!, url: URL.createObjectURL(file) } };
    }
    return respond(() => saved, 700);
  },
  restore: (kind) => {
    for (const k of kind ? [kind] : BRAND_ASSET_KINDS) {
      forget(saved[k]);
      saved = { ...saved, [k]: null };
    }
    return respond(() => saved, 400);
  },
};
