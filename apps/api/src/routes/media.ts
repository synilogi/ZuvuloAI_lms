import { randomUUID } from 'node:crypto';
import { open, unlink } from 'node:fs/promises';
import path from 'node:path';
import { Router } from 'express';
import multer from 'multer';

import { db } from '../lib/db.js';
import { tenant } from '../lib/tenancy.js';
import { ApiError, asyncHandler, badRequest, notFound } from '../lib/errors.js';
import { requireAuth } from '../lib/auth.js';
import {
  MAX_UPLOAD_BYTES,
  MEDIA_KINDS,
  classifyUpload,
  contentDisposition,
  ensureUploadDir,
  matchesSignature,
  safeFileName,
  type MediaKind,
} from '../lib/media.js';
import { canReadMedia } from '../lib/mediaAccess.js';

export const mediaRouter = Router();

/** The first bytes of a stored upload, for its signature. */
async function readHead(filePath: string): Promise<Buffer> {
  const handle = await open(filePath, 'r');
  try {
    const head = Buffer.alloc(16);
    const { bytesRead } = await handle.read(head, 0, 16, 0);
    return head.subarray(0, bytesRead);
  } finally {
    await handle.close();
  }
}

/**
 * The upload's limits are chosen by who sends it, before a byte is written: staff may send video, up to the largest
 * kind; a learner's hand-in is a document or an image, so a learner's request is cut off at that size and a video is
 * refused before it reaches the disk.
 */
const uploadFor = (staff: boolean) =>
  multer({
    storage: multer.diskStorage({
      destination: (_req, _file, cb) => cb(null, ensureUploadDir()),
      // Never reuse the client's file name on disk.
      filename: (_req, file, cb) => cb(null, `${randomUUID()}${classifyUpload(file.originalname, file.mimetype)?.ext ?? ''}`),
    }),
    limits: { fileSize: staff ? MAX_UPLOAD_BYTES : Math.max(MEDIA_KINDS.document.maxBytes, MEDIA_KINDS.image.maxBytes), files: 1 },
    fileFilter: (_req, file, cb) => {
      const classified = classifyUpload(file.originalname, file.mimetype);
      if (!classified) cb(badRequest('Only MP4/WebM/MOV video, PDF documents and PNG/JPG/WebP images can be uploaded.'));
      else if (classified.kind === 'video' && !staff) cb(new ApiError(403, 'Only instructors and admins can upload video.'));
      else cb(null, true);
    },
  }).single('file');
const staffUpload = uploadFor(true);
const learnerUpload = uploadFor(false);
const isStaff = (role: string | undefined) => role === 'instructor' || role === 'admin' || role === 'superadmin';

function toMediaFile(row: { id: string; originalName: string; sizeBytes: number; mime: string; kind: string }) {
  return {
    id: row.id,
    name: row.originalName,
    sizeMb: Math.max(0.1, Math.round((row.sizeBytes / 1_048_576) * 10) / 10),
    url: `/media/${row.id}`,
    mime: row.mime,
    kind: row.kind as MediaKind,
  };
}

/** Multipart upload, field `file`. Any signed-in account may upload (lesson media, assignment attachments). */
mediaRouter.post(
  '/upload',
  requireAuth,
  (req, res, next) => (isStaff(req.auth?.role) ? staffUpload : learnerUpload)(req, res, next),
  asyncHandler(async (req, res) => {
    const file = req.file;
    if (!file) throw badRequest('Attach a file in the `file` field.');
    const classified = classifyUpload(file.originalname, file.mimetype)!;
    // Video is course material: staff upload it. A learner's uploads are hand-ins — documents and
    // images — so a learner cannot post a half-gigabyte file through the assignment attachment field.
    const uploaderIsStaff = isStaff(req.auth!.role);
    if (classified.kind === 'video' && !uploaderIsStaff) {
      await unlink(file.path).catch(() => undefined);
      throw new ApiError(403, 'Only instructors and admins can upload video.');
    }
    if (file.size > MEDIA_KINDS[classified.kind].maxBytes) {
      await unlink(file.path).catch(() => undefined);
      throw new ApiError(
        413,
        `${classified.kind === 'video' ? 'Videos' : classified.kind === 'document' ? 'Documents' : 'Images'} can be at most ${Math.round(MEDIA_KINDS[classified.kind].maxBytes / 1_048_576)} MB.`,
      );
    }
    // The name and declared type are the client's; the bytes must agree with them (SAAS-023).
    if (!matchesSignature(classified.ext, await readHead(file.path))) {
      await unlink(file.path).catch(() => undefined);
      throw badRequest('The file’s contents do not match its type. Upload the original PDF, image or video.');
    }
    const data = {
      ...tenant(),
      ownerUserId: req.auth!.sub,
      kind: classified.kind,
      originalName: safeFileName(file.originalname),
      mime: file.mimetype.toLowerCase(),
      sizeBytes: file.size,
      storageName: path.basename(file.path),
    };
    // Staff uploads count against the plan's storage and are refused in restricted mode. A learner's
    // hand-in is serving the academy's learners: it counts, but is never refused (§21, SAAS-011).
    const row = await db
      .$transaction((tx) => tx.mediaAsset.create({ data }))
      .catch(async (err: unknown) => {
        await unlink(file.path).catch(() => undefined);
        throw err;
      });
    res.status(201).json(toMediaFile(row));
  }),
);

/**
 * Streams a stored file (Range requests supported for video).
 *
 * Who may read it follows who uploaded it. Course material — anything a member of staff uploaded —
 * stays readable by every signed-in account, because that is what lesson video, documents and images
 * are for. A learner's own upload is their hand-in: only they and the academy's staff may open it, so
 * one learner can no longer read another's attachment by holding its id. A refusal answers 404, the
 * same way `lib/scope.ts` hides records that are out of scope.
 */
mediaRouter.get(
  '/:id',
  requireAuth,
  asyncHandler(async (req, res) => {
    const row = await db.mediaAsset.findUnique({ where: { id: req.params.id } });
    if (!row) throw notFound('File not found.');

    // Reading follows what the viewer may open (`lib/mediaAccess.ts`); a refusal is the same 404 as no file.
    // The platform super admin is not an academy bypass either.
    if (!(await canReadMedia(req.auth!, row))) throw notFound('File not found.');
    const filePath = path.join(ensureUploadDir(), row.storageName);
    await new Promise<void>((resolve, reject) =>
      res.sendFile(
        filePath,
        {
          headers: {
            'Content-Type': row.mime,
            'Content-Disposition': contentDisposition(row.originalName),
            'X-Content-Type-Options': 'nosniff',
            'Cache-Control': 'private, max-age=3600',
          },
          dotfiles: 'deny',
        },
        (err) => (err ? reject(err) : resolve()),
      ),
    ).catch((err: NodeJS.ErrnoException) => {
      if (err.code === 'ENOENT') throw notFound('File not found.');
      if (!res.headersSent) throw err;
    });
  }),
);
