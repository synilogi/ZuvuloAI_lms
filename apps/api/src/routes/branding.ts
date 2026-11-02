import { Router, type RequestHandler } from 'express';
import multer from 'multer';
import { BRAND_ASSET_KINDS, BRAND_ASSET_RULES, isBrandAssetKind, type BrandAssetKind } from '@syniastrolms/domain';

import { brandingSettings, findBrandFile, publicBranding, restoreBranding, saveBranding, type BrandUpload } from '../lib/branding.js';
import { ApiError, asyncHandler, badRequest, notFound } from '../lib/errors.js';

/*
 * The platform's logo and favicon, in two halves.
 *
 * `superadminBrandingRouter` is mounted inside the Super Admin router, so `requireSuperAdmin` and the platform
 * context already apply to every route in it — before the upload is read. No academy role reaches it, and nothing
 * in it takes an academy: there is one branding, the platform's.
 *
 * `publicBrandingRouter` is what every page reads, signed in or not: where the current logo and favicon are, and
 * the files themselves. It is read-only.
 */

const LARGEST = Math.max(...BRAND_ASSET_KINDS.map((kind) => BRAND_ASSET_RULES[kind].maxBytes));

// Held in memory until judged (`lib/branding.ts`): at most two small images, and nothing reaches the disk unless it passes.
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: LARGEST, files: BRAND_ASSET_KINDS.length, fields: 0 } }).fields(
  BRAND_ASSET_KINDS.map((name) => ({ name, maxCount: 1 })),
);

/** Reads the upload, answering multer's own refusals in this surface's words. */
const receive: RequestHandler = (req, res, next) =>
  upload(req, res, (err: unknown) => {
    if (!err) return next();
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') return next(new ApiError(413, `A branding file can be at most ${Math.round(LARGEST / 1_048_576)} MB.`));
      return next(badRequest('Send the logo in the `logo` field and the favicon in the `favicon` field, one file each.'));
    }
    next(err);
  });

export const superadminBrandingRouter = Router();

superadminBrandingRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    res.json(await brandingSettings());
  }),
);

/** Multipart: `logo` and/or `favicon`. Whatever is sent replaces what was saved; a kind not sent is left as it is. */
superadminBrandingRouter.put(
  '/',
  receive,
  asyncHandler(async (req, res) => {
    const files = (req.files ?? {}) as Partial<Record<BrandAssetKind, BrandUpload[]>>;
    res.json(await saveBranding(req, { logo: files.logo?.[0], favicon: files.favicon?.[0] }));
  }),
);

/** Back to the built-in ZuviloAI logo and favicon. */
superadminBrandingRouter.delete(
  '/',
  asyncHandler(async (req, res) => {
    res.json(await restoreBranding(req));
  }),
);

/** Back to the built-in asset for one kind: `logo` or `favicon`. */
superadminBrandingRouter.delete(
  '/:kind',
  asyncHandler(async (req, res) => {
    if (!isBrandAssetKind(req.params.kind)) throw notFound('Not found.');
    res.json(await restoreBranding(req, [req.params.kind]));
  }),
);

export const publicBrandingRouter = Router();

/** Always asked afresh, so a change shows on the next page load. The files it points at are what gets cached. */
publicBrandingRouter.get(
  '/',
  asyncHandler(async (_req, res) => {
    res.set('Cache-Control', 'no-cache').json(await publicBranding());
  }),
);

/**
 * A saved brand file. Only the file a current row names is served — the name in the address is looked up, never
 * joined to a path — and as the type the server found in its bytes. A replaced or removed asset answers 404, and
 * the page falls back to the built-in one.
 */
publicBrandingRouter.get(
  '/assets/:name',
  asyncHandler(async (req, res) => {
    const file = await findBrandFile(req.params.name);
    if (!file) throw notFound('File not found.');
    await new Promise<void>((resolve, reject) =>
      res.sendFile(
        file.name,
        {
          root: file.dir,
          dotfiles: 'deny',
          headers: {
            'Content-Type': file.mime,
            'X-Content-Type-Options': 'nosniff',
            // The name is new for every upload, so this address never holds different bytes.
            'Cache-Control': 'public, max-age=31536000, immutable',
            // Shown as an image and nothing else, even when opened on its own.
            'Content-Security-Policy': "default-src 'none'; sandbox",
          },
        },
        (err) => (err ? reject(err) : resolve()),
      ),
    ).catch((err: NodeJS.ErrnoException) => {
      if (err.code === 'ENOENT') throw notFound('File not found.');
      if (!res.headersSent) throw err;
    });
  }),
);
