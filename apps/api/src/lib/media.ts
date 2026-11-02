import { mkdirSync } from 'node:fs';
import path from 'node:path';

/** Where uploaded files live. Relative paths resolve against the API's working directory (apps/api). */
export const UPLOAD_DIR = path.resolve(process.env.UPLOAD_DIR ?? path.join(process.cwd(), 'uploads'));

export type MediaKind = 'video' | 'document' | 'image';

const MB = 1024 * 1024;

/** Allow-list: both the declared MIME type and the file extension must match a kind. */
export const MEDIA_KINDS: Record<MediaKind, { mimes: string[]; exts: string[]; maxBytes: number }> = {
  video: { mimes: ['video/mp4', 'video/webm', 'video/quicktime'], exts: ['.mp4', '.webm', '.mov'], maxBytes: 500 * MB },
  document: { mimes: ['application/pdf'], exts: ['.pdf'], maxBytes: 25 * MB },
  image: { mimes: ['image/png', 'image/jpeg', 'image/webp'], exts: ['.png', '.jpg', '.jpeg', '.webp'], maxBytes: 5 * MB },
};

export const MAX_UPLOAD_BYTES = Math.max(...Object.values(MEDIA_KINDS).map((k) => k.maxBytes));

export function classifyUpload(originalName: string, mime: string): { kind: MediaKind; ext: string } | null {
  const ext = path.extname(originalName).toLowerCase();
  for (const [kind, rule] of Object.entries(MEDIA_KINDS) as [MediaKind, (typeof MEDIA_KINDS)[MediaKind]][]) {
    if (rule.mimes.includes(mime.toLowerCase()) && rule.exts.includes(ext)) return { kind, ext };
  }
  return null;
}

export function ensureUploadDir(): string {
  mkdirSync(UPLOAD_DIR, { recursive: true });
  return UPLOAD_DIR;
}

/** Strips path separators, quotes and control characters so the name is safe to echo in headers. */
export function safeFileName(name: string): string {
  return (
    name
      .replace(/[/\\"]/g, '_')
      .replace(/[^\x20-\x7E]/g, '_')
      .slice(0, 180) || 'file'
  );
}

/** A `Content-Disposition` value: the ASCII name quoted, and the same name percent-encoded for clients that read `filename*`. */
export const contentDisposition = (name: string) => `inline; filename="${safeFileName(name)}"; filename*=UTF-8''${encodeURIComponent(safeFileName(name))}`;

/**
 * Whether a file's first bytes are what its extension says (SAAS-023): the declared type and name are the
 * client's to choose, the bytes are not. PDF `%PDF-`; PNG's eight-byte signature; JPEG `FF D8 FF`; WebP a RIFF
 * container of type `WEBP`; MP4 and MOV an ISO box `ftyp` at offset 4; WebM the EBML header `1A 45 DF A3`.
 */
export function matchesSignature(ext: string, head: Buffer): boolean {
  const at = (offset: number, bytes: number[] | string) => {
    const want = typeof bytes === 'string' ? Buffer.from(bytes, 'latin1') : Buffer.from(bytes);
    return head.length >= offset + want.length && head.subarray(offset, offset + want.length).equals(want);
  };
  switch (ext) {
    case '.pdf':
      return at(0, '%PDF-');
    case '.png':
      return at(0, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    case '.jpg':
    case '.jpeg':
      return at(0, [0xff, 0xd8, 0xff]);
    case '.webp':
      return at(0, 'RIFF') && at(8, 'WEBP');
    case '.mp4':
    case '.mov':
      return at(4, 'ftyp');
    case '.webm':
      return at(0, [0x1a, 0x45, 0xdf, 0xa3]);
    default:
      return false;
  }
}
