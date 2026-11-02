/*
 * What an uploaded image really is, read from its bytes: its format and its pixel size.
 *
 * The file name and the declared type are the client's to choose (`lib/media.ts`); a brand asset is served to every
 * visitor, so it is judged by its contents alone. Each format is read by walking its own structure rather than by
 * matching a few leading bytes, and a file whose structure does not hold together — truncated, or carrying something
 * after the image ends — is not an image as far as this is concerned.
 */

export type ImageFormat = 'png' | 'jpeg' | 'webp' | 'ico';

export interface ImageInfo {
  format: ImageFormat;
  width: number;
  height: number;
}

/** The type each format is served as, and the extension it is stored under — never the client's. */
export const IMAGE_FORMATS: Record<ImageFormat, { mime: string; ext: string; exts: readonly string[] }> = {
  png: { mime: 'image/png', ext: '.png', exts: ['.png'] },
  jpeg: { mime: 'image/jpeg', ext: '.jpg', exts: ['.jpg', '.jpeg'] },
  webp: { mime: 'image/webp', ext: '.webp', exts: ['.webp'] },
  ico: { mime: 'image/x-icon', ext: '.ico', exts: ['.ico'] },
};

const PNG_SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
/** No brand asset is anywhere near this; a header claiming more is a decompression bomb or nonsense. */
const MAX_SIDE = 16_384;

const sane = (width: number, height: number) => width > 0 && height > 0 && width <= MAX_SIDE && height <= MAX_SIDE;

/** PNG: the signature, IHDR first, then chunks that tile the file exactly and end with IEND. */
function readPng(data: Buffer): ImageInfo | null {
  if (data.length < 8 + 25 + 12 || !data.subarray(0, 8).equals(PNG_SIGNATURE)) return null;
  if (data.readUInt32BE(8) !== 13 || data.toString('latin1', 12, 16) !== 'IHDR') return null;
  const width = data.readUInt32BE(16);
  const height = data.readUInt32BE(20);
  let offset = 8;
  let ended = false;
  while (offset + 12 <= data.length) {
    const length = data.readUInt32BE(offset);
    const type = data.toString('latin1', offset + 4, offset + 8);
    if (!/^[A-Za-z]{4}$/.test(type)) return null;
    const next = offset + 12 + length;
    if (next > data.length) return null;
    offset = next;
    if (type === 'IEND') {
      ended = true;
      break;
    }
  }
  // Nothing may follow the image: bytes after IEND are how a second file hides inside a PNG.
  if (!ended || offset !== data.length) return null;
  return sane(width, height) ? { format: 'png', width, height } : null;
}

/** JPEG: SOI, then segments up to the frame header that carries the size; the file ends with EOI. */
function readJpeg(data: Buffer): ImageInfo | null {
  if (data.length < 4 || data[0] !== 0xff || data[1] !== 0xd8) return null;
  if (data[data.length - 2] !== 0xff || data[data.length - 1] !== 0xd9) return null;
  let offset = 2;
  while (offset + 4 <= data.length) {
    if (data[offset] !== 0xff) return null;
    const marker = data[offset + 1];
    // Fill bytes before a marker.
    if (marker === 0xff) {
      offset += 1;
      continue;
    }
    // Start of scan: the frame header always comes before it.
    if (marker === 0xda || marker === 0xd9) return null;
    const length = data.readUInt16BE(offset + 2);
    if (length < 2 || offset + 2 + length > data.length) return null;
    const isFrame = marker >= 0xc0 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc;
    if (isFrame) {
      if (length < 7) return null;
      const height = data.readUInt16BE(offset + 5);
      const width = data.readUInt16BE(offset + 7);
      return sane(width, height) ? { format: 'jpeg', width, height } : null;
    }
    offset += 2 + length;
  }
  return null;
}

/** WebP: a RIFF container of type WEBP whose stated length is the file's, and whose first chunk carries the size. */
function readWebp(data: Buffer): ImageInfo | null {
  if (data.length < 30 || data.toString('latin1', 0, 4) !== 'RIFF' || data.toString('latin1', 8, 12) !== 'WEBP') return null;
  const riffEnd = data.readUInt32LE(4) + 8;
  // A RIFF chunk is padded to an even length; some writers count the pad, some do not.
  if (riffEnd !== data.length && riffEnd + 1 !== data.length) return null;
  const chunk = data.toString('latin1', 12, 16);
  let width = 0;
  let height = 0;
  if (chunk === 'VP8 ') {
    if (data[23] !== 0x9d || data[24] !== 0x01 || data[25] !== 0x2a) return null;
    width = data.readUInt16LE(26) & 0x3fff;
    height = data.readUInt16LE(28) & 0x3fff;
  } else if (chunk === 'VP8L') {
    if (data[20] !== 0x2f) return null;
    const bits = data.readUInt32LE(21);
    width = (bits & 0x3fff) + 1;
    height = ((bits >>> 14) & 0x3fff) + 1;
  } else if (chunk === 'VP8X') {
    width = data.readUIntLE(24, 3) + 1;
    height = data.readUIntLE(27, 3) + 1;
  } else return null;
  return sane(width, height) ? { format: 'webp', width, height } : null;
}

/** ICO: a directory of images, each a PNG or a bitmap that lies wholly inside the file. Its size is its largest image's. */
function readIco(data: Buffer): ImageInfo | null {
  if (data.length < 6 + 16 || data.readUInt16LE(0) !== 0 || data.readUInt16LE(2) !== 1) return null;
  const count = data.readUInt16LE(4);
  if (count < 1 || count > 32) return null;
  const directoryEnd = 6 + count * 16;
  if (directoryEnd > data.length) return null;
  let width = 0;
  let height = 0;
  for (let i = 0; i < count; i += 1) {
    const entry = 6 + i * 16;
    // A side of 0 means 256.
    const w = data[entry] || 256;
    const h = data[entry + 1] || 256;
    const size = data.readUInt32LE(entry + 8);
    const start = data.readUInt32LE(entry + 12);
    if (size < 16 || start < directoryEnd || start + size > data.length) return null;
    const isPng = data.subarray(start, start + 8).equals(PNG_SIGNATURE);
    const isBitmap = data.readUInt32LE(start) === 40;
    if (!isPng && !isBitmap) return null;
    if (w * h > width * height) {
      width = w;
      height = h;
    }
  }
  return sane(width, height) ? { format: 'ico', width, height } : null;
}

/** The image `data` holds, or `null` when it is not a whole, well-formed PNG, JPEG, WebP or ICO. */
export function readImageInfo(data: Buffer): ImageInfo | null {
  try {
    return readPng(data) ?? readJpeg(data) ?? readWebp(data) ?? readIco(data);
  } catch {
    // A read past the end of a malformed file: not an image.
    return null;
  }
}
