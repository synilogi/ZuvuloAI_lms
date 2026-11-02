/*
 * The platform's own logo and favicon.
 *
 * The built-in ZuviloAI assets ship inside every client, so there is nothing to store for them: a kind with no row —
 * or a row whose file has gone missing — is simply the default. An uploaded asset is a file under UPLOAD_DIR/branding
 * with a name this module chose, and a `PlatformBrandAsset` row that points at it. A replacement gets a new name, so
 * its address is new too and can be cached for good; the old file is removed once the row no longer points at it.
 *
 * Only the Super Admin's router writes here. Nothing in this module reads or writes an academy's rows: an academy's
 * appearance is `Settings.appearanceJson` (`lib/settings.ts`), and the two never meet.
 */
import { randomUUID } from 'node:crypto';
import { existsSync, mkdirSync } from 'node:fs';
import { unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';
import type { Request } from 'express';
import {
  BRAND_ASSET_KINDS,
  BRAND_ASSET_RULES,
  brandAssetIssues,
  type BrandAsset,
  type BrandAssetKind,
  type PlatformBranding,
  type PlatformBrandingSettings,
  type SavedBrandAsset,
} from '@syniastrolms/domain';

import { recordAuditLog } from './audit.js';
import { db } from './db.js';
import { badRequest } from './errors.js';
import { IMAGE_FORMATS, readImageInfo, type ImageInfo } from './imageInfo.js';
import { ensureUploadDir, safeFileName } from './media.js';

export const BRANDING_AUDIT_ACTIONS = { updated: 'branding.updated', restored: 'branding.restored' } as const;

/** Every name this module gives a stored file. Anything else asked for is not one of ours, whatever it resolves to. */
const STORAGE_NAME = /^(logo|favicon)-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(png|jpg|webp|ico)$/;

export const isBrandStorageName = (name: string) => STORAGE_NAME.test(name);

/** Where uploaded brand assets live: a folder of their own, beside the academies' media and never among it. */
export function brandingDir(): string {
  const dir = path.join(ensureUploadDir(), 'branding');
  mkdirSync(dir, { recursive: true });
  return dir;
}

const assetUrl = (storageName: string) => `/public/branding/assets/${storageName}`;

interface AssetRow {
  kind: string;
  storageName: string;
  originalName: string;
  mime: string;
  sizeBytes: number;
  width: number;
  height: number;
  updatedById: string | null;
  updatedAt: Date;
}

/** A saved row whose file is where it should be. One whose file is gone counts as not saved: the default shows. */
const usable = (row: AssetRow | undefined): row is AssetRow =>
  !!row && isBrandStorageName(row.storageName) && existsSync(path.join(brandingDir(), row.storageName));

const toAsset = (row: AssetRow): BrandAsset => ({ url: assetUrl(row.storageName), mime: row.mime, width: row.width, height: row.height });

async function savedRows(): Promise<Partial<Record<BrandAssetKind, AssetRow>>> {
  const rows = await db.platformBrandAsset.findMany();
  return Object.fromEntries(rows.filter(usable).map((row) => [row.kind, row]));
}

/** What every visitor's page reads: where the logo and favicon are, or `null` for the built-in ones. */
export async function publicBranding(): Promise<PlatformBranding> {
  const rows = await savedRows();
  return { logo: rows.logo ? toAsset(rows.logo) : null, favicon: rows.favicon ? toAsset(rows.favicon) : null };
}

/** The same, with what the Super Admin's screen shows about each saved file. */
export async function brandingSettings(): Promise<PlatformBrandingSettings> {
  const rows = await savedRows();
  const editorIds = [...new Set(Object.values(rows).flatMap((row) => (row.updatedById ? [row.updatedById] : [])))];
  const editors = editorIds.length ? await db.user.findMany({ where: { id: { in: editorIds } }, select: { id: true, name: true } }) : [];
  const saved = (row: AssetRow | undefined): SavedBrandAsset | null =>
    row
      ? {
          ...toAsset(row),
          name: row.originalName,
          sizeBytes: row.sizeBytes,
          updatedAt: row.updatedAt.toISOString(),
          updatedBy: editors.find((e) => e.id === row.updatedById)?.name,
        }
      : null;
  return { logo: saved(rows.logo), favicon: saved(rows.favicon) };
}

/** The stored file a public address names, when it is the one currently saved. */
export async function findBrandFile(name: string): Promise<{ dir: string; name: string; mime: string } | null> {
  if (!isBrandStorageName(name)) return null;
  const row = await db.platformBrandAsset.findUnique({ where: { storageName: name }, select: { storageName: true, mime: true } });
  // The name sent is only ever compared; the path is built from the row's own.
  return row ? { dir: brandingDir(), name: row.storageName, mime: row.mime } : null;
}

/** An uploaded file as it arrives: held in memory, never written until it has been judged. */
export interface BrandUpload {
  originalname: string;
  mimetype: string;
  size: number;
  buffer: Buffer;
}

interface Judged {
  kind: BrandAssetKind;
  upload: BrandUpload;
  info: ImageInfo;
}

/**
 * Judges one upload: its name and declared type against the allow-list, its size, then its bytes — which must be a
 * whole image of a format this kind accepts, the one its name says — and last its dimensions and proportions.
 */
function judge(kind: BrandAssetKind, upload: BrandUpload): { info?: ImageInfo; issues: string[] } {
  const rule = BRAND_ASSET_RULES[kind];
  const label = rule.label.toLowerCase();
  const issues = brandAssetIssues(kind, { name: upload.originalname, mime: upload.mimetype, bytes: upload.size });
  if (issues.length) return { issues };
  const info = readImageInfo(upload.buffer);
  if (!info) return { issues: [`The ${label} file is not a valid ${rule.formats} image. Upload the original file.`] };
  const ext = path.extname(upload.originalname).toLowerCase();
  const format = IMAGE_FORMATS[info.format];
  if (!format.exts.includes(ext) || !rule.exts.includes(format.ext))
    return { issues: [`The ${label} file’s contents do not match its type. Upload the original file.`] };
  return { info, issues: brandAssetIssues(kind, { width: info.width, height: info.height }) };
}

async function removeFiles(names: string[]) {
  const dir = brandingDir();
  await Promise.all(names.filter(isBrandStorageName).map((name) => unlink(path.join(dir, name)).catch(() => undefined)));
}

/**
 * Saves the uploaded logo and/or favicon as the platform's. Every file is judged before anything is written; one
 * refusal refuses the request, naming each problem by its field. Audited, in the transaction that saves the rows.
 */
export async function saveBranding(req: Request, uploads: Partial<Record<BrandAssetKind, BrandUpload>>): Promise<PlatformBrandingSettings> {
  const offered = BRAND_ASSET_KINDS.flatMap((kind) => (uploads[kind] ? [{ kind, upload: uploads[kind] }] : []));
  if (!offered.length) throw badRequest('Choose a logo or a favicon to upload.');

  const judged: Judged[] = [];
  const issues: { field: BrandAssetKind; message: string }[] = [];
  for (const { kind, upload } of offered) {
    const verdict = judge(kind, upload);
    issues.push(...verdict.issues.map((message) => ({ field: kind, message })));
    if (verdict.info && !verdict.issues.length) judged.push({ kind, upload, info: verdict.info });
  }
  if (issues.length) throw badRequest('Check the files and try again.', issues);

  const dir = brandingDir();
  const stored = judged.map((j) => ({ ...j, storageName: `${j.kind}-${randomUUID()}${IMAGE_FORMATS[j.info.format].ext}` }));
  const previous = await db.platformBrandAsset.findMany({ where: { kind: { in: stored.map((s) => s.kind) } }, select: { storageName: true } });
  try {
    // `wx`: a new file only — a stored asset is never written over.
    for (const s of stored) await writeFile(path.join(dir, s.storageName), s.upload.buffer, { flag: 'wx', mode: 0o644 });
    await db.$transaction(async (tx) => {
      for (const s of stored) {
        const data = {
          storageName: s.storageName,
          originalName: safeFileName(s.upload.originalname),
          mime: IMAGE_FORMATS[s.info.format].mime,
          sizeBytes: s.upload.size,
          width: s.info.width,
          height: s.info.height,
          updatedById: req.auth?.sub ?? null,
        };
        await tx.platformBrandAsset.upsert({ where: { kind: s.kind }, create: { kind: s.kind, ...data }, update: data });
      }
      await recordAuditLog(
        req,
        {
          action: BRANDING_AUDIT_ACTIONS.updated,
          targetType: 'branding',
          meta: Object.fromEntries(
            stored.map((s) => [s.kind, { format: s.info.format, width: s.info.width, height: s.info.height, sizeBytes: s.upload.size }]),
          ),
        },
        tx,
      );
    });
  } catch (err) {
    await removeFiles(stored.map((s) => s.storageName));
    throw err;
  }
  await removeFiles(previous.map((p) => p.storageName));
  return brandingSettings();
}

/** Puts the built-in ZuviloAI asset back for each kind named: its row and its file are removed. Audited when anything was. */
export async function restoreBranding(req: Request, kinds: readonly BrandAssetKind[] = BRAND_ASSET_KINDS): Promise<PlatformBrandingSettings> {
  const rows = await db.platformBrandAsset.findMany({ where: { kind: { in: [...kinds] } }, select: { kind: true, storageName: true } });
  if (rows.length) {
    await db.$transaction(async (tx) => {
      await tx.platformBrandAsset.deleteMany({ where: { kind: { in: rows.map((r) => r.kind) } } });
      await recordAuditLog(req, { action: BRANDING_AUDIT_ACTIONS.restored, targetType: 'branding', meta: { assets: rows.map((r) => r.kind) } }, tx);
    });
    await removeFiles(rows.map((r) => r.storageName));
  }
  return brandingSettings();
}
