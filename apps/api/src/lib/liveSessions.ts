import { createWriteStream } from 'node:fs';
import { mkdir, rename, rm } from 'node:fs/promises';
import path from 'node:path';
import { Readable, Transform } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import type { ReadableStream as WebReadableStream } from 'node:stream/web';

import { ROOM_OVERRUN_MIN } from '@syniastrolms/domain';

import { db } from './db.js';
import { readJson, writeJson } from './json.js';
import { liveRoomConfig, verifyJaasSignature } from './liveRoom.js';
import { UPLOAD_DIR } from './media.js';
import { describeError, observe, webhookFailed } from './observe.js';
import { runAsPlatform, runInTenant } from './tenancy.js';

/*
 * A live class's session in the built-in room: the host ends it (or the scheduler closes a room left open),
 * which settles attendance; and, when the video service records, the recording it posts is downloaded and kept
 * under UPLOAD_DIR/live-recordings for the academy's learners to watch.
 */

/** What `LiveClass.recordingJson` holds. Only `durationMin`, `availableUntil` and `status` ever leave the API (mapLive). */
export interface StoredRecording {
  status: 'processing' | 'ready' | 'failed';
  durationMin: number;
  availableUntil: string;
  /** The kept file, under RECORDING_DIR. */
  fileName?: string;
  /** The provider's pre-signed download link, until the file is kept. Never sent to a client. */
  sourceUrl?: string;
  sourceExpiresAt?: string;
  attempts?: number;
}

export const RECORDING_DIR = path.join(UPLOAD_DIR, 'live-recordings');
/** How long learners can watch a recording after the class. */
const recordingDays = () => Math.max(1, Number(process.env.LIVE_RECORDING_DAYS) || 30);
const MAX_RECORDING_BYTES = 4 * 1024 ** 3;
const MAX_DOWNLOAD_ATTEMPTS = 5;

/**
 * Closes the room: stamps `endedAt` and settles attendance — every registered learner who never joined is
 * marked absent. Idempotent: an already-ended class is left as it was. Returns whether this call ended it.
 */
export async function endLiveClass(liveClassId: string, at = new Date()): Promise<boolean> {
  return db.$transaction(async (tx) => {
    const ended = await tx.liveClass.updateMany({ where: { id: liveClassId, startedAt: { not: null }, endedAt: null }, data: { endedAt: at } });
    if (!ended.count) return false;
    await tx.liveRegistration.updateMany({ where: { liveClassId, attended: null }, data: { attended: false } });
    return true;
  });
}

/** Rooms the host left open past their slot and the overrun: closed as if the host had ended them then. Per academy. */
export async function closeStaleRooms(now = new Date()): Promise<number> {
  const open = await db.liveClass.findMany({ where: { startedAt: { not: null }, endedAt: null }, select: { id: true, startsAt: true, durationMin: true } });
  let closed = 0;
  for (const live of open) {
    const closesAt = live.startsAt.getTime() + (live.durationMin + ROOM_OVERRUN_MIN) * 60_000;
    if (closesAt <= now.getTime() && (await endLiveClass(live.id, new Date(closesAt)))) closed++;
  }
  return closed;
}

export interface LiveWebhookResult {
  status: number;
  body: { received: boolean; outcome?: string; message?: string };
}

/**
 * `POST /webhooks/jaas` — JaaS events for the academy's rooms. The signature is checked over the raw bytes
 * before a word is read. Only RECORDING_UPLOADED is acted on: it names the room (`fqn` = `<appId>/<room>`) and
 * carries a link valid for 24 hours, so the file is fetched straight away and retried by the scheduler.
 */
export async function receiveJaasWebhook(raw: Buffer, headers: Record<string, string | undefined>): Promise<LiveWebhookResult> {
  const cfg = liveRoomConfig();
  const secret = cfg.jaas?.webhookSecret;
  if (!secret) return { status: 404, body: { received: false, message: 'Live room webhooks are not configured.' } };
  if (!verifyJaasSignature(raw, headers['x-jaas-signature'], secret)) {
    webhookFailed('jaas', 'signature');
    return { status: 401, body: { received: false, message: 'Signature check failed.' } };
  }
  let event: { eventType?: string; fqn?: string; data?: { preAuthenticatedLink?: string; durationSec?: number; duration?: number } };
  try {
    event = JSON.parse(raw.toString('utf8'));
  } catch {
    return { status: 400, body: { received: false, message: 'The body is not JSON.' } };
  }
  if (event.eventType !== 'RECORDING_UPLOADED') return { status: 200, body: { received: true, outcome: 'ignored' } };

  const roomName = event.fqn?.split('/').pop();
  const link = event.data?.preAuthenticatedLink;
  if (!roomName || !link || !/^https:\/\//.test(link)) return { status: 400, body: { received: false, message: 'The recording event names no room or link.' } };

  // A webhook belongs to no academy until its room says which: the one platform-wide read here.
  const live = await runAsPlatform('a recording webhook names its room', () =>
    db.liveClass.findUnique({ where: { roomName }, select: { id: true, tenantId: true } }),
  );
  if (!live) {
    webhookFailed('jaas', 'unknown-room');
    return { status: 200, body: { received: true, outcome: 'unknown-room' } };
  }

  const outcome = await runInTenant(live.tenantId, async () => {
    const row = await db.liveClass.findUniqueOrThrow({ where: { id: live.id } });
    const current = readJson<StoredRecording | null>(row.recordingJson, null);
    if (current?.status === 'ready') return 'duplicate';
    const seconds = event.data?.durationSec ?? event.data?.duration;
    const fromSession = row.startedAt && row.endedAt ? (row.endedAt.getTime() - row.startedAt.getTime()) / 60_000 : row.durationMin;
    const ended = row.endedAt ?? new Date();
    const recording: StoredRecording = {
      status: 'processing',
      durationMin: Math.max(1, Math.round(typeof seconds === 'number' && seconds > 0 ? seconds / 60 : fromSession)),
      availableUntil: new Date(ended.getTime() + recordingDays() * 86_400_000).toISOString(),
      sourceUrl: link,
      sourceExpiresAt: new Date(Date.now() + 24 * 3_600_000).toISOString(),
      attempts: 0,
    };
    await db.liveClass.update({ where: { id: row.id }, data: { recordingJson: writeJson(recording) } });
    return 'stored';
  });
  if (outcome === 'stored') void keepRecording(live.id, live.tenantId);
  return { status: 200, body: { received: true, outcome } };
}

const inFlight = new Set<string>();

/** Downloads one pending recording into RECORDING_DIR. Failures are counted and retried by the scheduler until the link expires. */
export async function keepRecording(liveClassId: string, tenantId: string): Promise<'ready' | 'failed' | 'skipped'> {
  if (inFlight.has(liveClassId)) return 'skipped';
  inFlight.add(liveClassId);
  try {
    return await runInTenant(tenantId, async () => {
      const row = await db.liveClass.findUnique({ where: { id: liveClassId }, select: { recordingJson: true } });
      const rec = readJson<StoredRecording | null>(row?.recordingJson ?? null, null);
      if (!rec || rec.status !== 'processing' || !rec.sourceUrl) return 'skipped';
      const save = (next: StoredRecording) => db.liveClass.update({ where: { id: liveClassId }, data: { recordingJson: writeJson(next) } });
      if (rec.sourceExpiresAt && new Date(rec.sourceExpiresAt) <= new Date()) {
        await save({ ...rec, status: 'failed', sourceUrl: undefined });
        return 'failed';
      }
      const fileName = `${liveClassId}.mp4`;
      const partial = path.join(RECORDING_DIR, `${fileName}.part`);
      try {
        await mkdir(RECORDING_DIR, { recursive: true });
        const res = await fetch(rec.sourceUrl);
        if (!res.ok || !res.body) throw new Error(`download answered ${res.status}`);
        let bytes = 0;
        const cap = new Transform({
          transform(chunk: Buffer, _enc, done) {
            bytes += chunk.length;
            done(bytes > MAX_RECORDING_BYTES ? new Error('recording is larger than the limit') : null, chunk);
          },
        });
        await pipeline(Readable.fromWeb(res.body as WebReadableStream), cap, createWriteStream(partial));
        await rename(partial, path.join(RECORDING_DIR, fileName));
        await save({ ...rec, status: 'ready', fileName, sourceUrl: undefined, sourceExpiresAt: undefined });
        return 'ready';
      } catch (err) {
        await rm(partial, { force: true });
        const attempts = (rec.attempts ?? 0) + 1;
        observe('job.failed', { job: 'live-recording', liveClassId, attempts, error: describeError(err) });
        await save({ ...rec, attempts, ...(attempts >= MAX_DOWNLOAD_ATTEMPTS ? { status: 'failed', sourceUrl: undefined } : {}) });
        return 'failed';
      }
    });
  } finally {
    inFlight.delete(liveClassId);
  }
}

/** The scheduler's retry: every recording of this academy still waiting to be kept. */
export async function keepPendingRecordings(tenantId: string): Promise<number> {
  const rows = await db.liveClass.findMany({ where: { recordingJson: { contains: '"status":"processing"' } }, select: { id: true } });
  let kept = 0;
  for (const { id } of rows) if ((await keepRecording(id, tenantId)) === 'ready') kept++;
  return kept;
}

/** The kept file of a class's recording, while it may still be watched. */
export function playableRecording(recordingJson: string | null, now = new Date()): string | null {
  const rec = readJson<StoredRecording | null>(recordingJson, null);
  if (rec?.status !== 'ready' || !rec.fileName || new Date(rec.availableUntil) <= now) return null;
  return path.join(RECORDING_DIR, path.basename(rec.fileName));
}
