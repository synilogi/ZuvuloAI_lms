import type { BrandAsset, BrandAssetKind, PlatformBranding, PlatformBrandingSettings } from '@syniastrolms/domain';

import type { BrandingService } from '../contracts';
import { API_BASE_URL, del, get, request } from './client';

/** The API names a brand file by a path on itself; a page needs the whole address. */
const absolute = <T extends BrandAsset>(asset: T | null): T | null => (asset ? { ...asset, url: `${API_BASE_URL}${asset.url}` } : null);

const resolved = <T extends { logo: BrandAsset | null; favicon: BrandAsset | null }>(branding: T): T => ({
  ...branding,
  logo: absolute(branding.logo),
  favicon: absolute(branding.favicon),
});

/**
 * The platform's logo and favicon: read by every page from `GET /public/branding`, changed by the Super Admin through
 * `/superadmin/branding` — where the server alone decides who may, and what a file must be.
 */
export const httpBranding: BrandingService = {
  current: async () => resolved(await get<PlatformBranding>('/public/branding')),
  settings: async () => resolved(await get<PlatformBrandingSettings>('/superadmin/branding')),
  save: async (files) => {
    const form = new FormData();
    for (const kind of ['logo', 'favicon'] as const satisfies readonly BrandAssetKind[]) {
      const file = files[kind];
      if (file) form.append(kind, file, file.name);
    }
    return resolved(await request<PlatformBrandingSettings>('/superadmin/branding', { method: 'PUT', body: form }));
  },
  restore: async (kind) => resolved(await del<PlatformBrandingSettings>(kind ? `/superadmin/branding/${kind}` : '/superadmin/branding')),
};
