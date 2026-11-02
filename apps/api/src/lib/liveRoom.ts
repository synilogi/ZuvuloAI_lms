import { createHmac, createPrivateKey, randomBytes, timingSafeEqual } from 'node:crypto';
import { readFileSync } from 'node:fs';

import jwt from 'jsonwebtoken';

import { ApiError } from './errors.js';

/*
 * The video service behind the built-in live room (docs/modules/live-classes.md). Two providers, one shape:
 *
 *   jitsi — a public Jitsi Meet server (JITSI_DOMAIN, meet.jit.si by default). No accounts, no tokens: the
 *           room's unguessable name is the only key. meet.jit.si asks a moderator to sign in and limits embedded
 *           calls, and records nothing, so it is for development and trials only.
 *   jaas  — 8x8 Jitsi as a Service, chosen as soon as JAAS_APP_ID, JAAS_KID and a private key are set. Every
 *           join carries a token this server signs (RS256), so the host is the moderator and learners are not,
 *           and with JAAS_WEBHOOK_SECRET set the host can record: JaaS posts RECORDING_UPLOADED and the API keeps
 *           the file (lib/liveSessions.ts).
 *
 * The browser and the app connect straight to the provider with what `roomJoin` returns; nothing streams
 * through this API.
 */

export type LiveRoomProvider = 'jitsi' | 'jaas';

export interface LiveRoomConfig {
  provider: LiveRoomProvider;
  /** The server the clients connect to: `meet.jit.si`, a self-hosted domain, or `8x8.vc`. */
  domain: string;
  /** Whether a class in this room can be recorded and kept. */
  recording: boolean;
  jaas?: { appId: string; kid: string; privateKey: string; webhookSecret?: string };
}

/** What a client needs to enter a class's room. */
export interface RoomJoin {
  provider: LiveRoomProvider;
  domain: string;
  /** The room as the client names it — JaaS rooms are `<appId>/<name>`. */
  room: string;
  /** Signed for this person and this room; absent on a public Jitsi server. */
  jwt?: string;
  /** Shown as the meeting's title. */
  subject: string;
  displayName: string;
  email?: string;
  /** The host: can mute others, end the meeting for everyone, and (JaaS) record. */
  moderator: boolean;
  recording: boolean;
}

const JAAS_DOMAIN = '8x8.vc';
/** How long a join token stays valid: the longest class (4 h) plus its overrun. */
const TOKEN_HOURS = 6;

function privateKeyFrom(env: NodeJS.ProcessEnv) {
  if (env.JAAS_PRIVATE_KEY_FILE) return readFileSync(env.JAAS_PRIVATE_KEY_FILE, 'utf8');
  // A PEM pasted into one .env line keeps its line breaks as `\n`.
  return env.JAAS_PRIVATE_KEY?.replace(/\\n/g, '\n');
}

/** The configured video service. A half-configured JaaS is an error, never a silent fall back to the public server. */
export function liveRoomConfig(env: NodeJS.ProcessEnv = process.env): LiveRoomConfig {
  const appId = env.JAAS_APP_ID?.trim();
  const kid = env.JAAS_KID?.trim();
  const privateKey = privateKeyFrom(env)?.trim();
  if (appId || kid || privateKey) {
    const missing = [!appId && 'JAAS_APP_ID', !kid && 'JAAS_KID', !privateKey && 'JAAS_PRIVATE_KEY or JAAS_PRIVATE_KEY_FILE'].filter(Boolean);
    if (missing.length) throw new Error(`Live room: JaaS is partly configured — set ${missing.join(', ')} too, or remove the JaaS settings.`);
    // A key that cannot sign would surface only as a failed join, on a host's first class: refuse it at boot instead.
    let key;
    try {
      key = createPrivateKey(privateKey!);
    } catch {
      throw new Error('Live room: the JaaS private key cannot be read. Paste the whole PEM from the JaaS console, BEGIN and END lines included.');
    }
    if (key.asymmetricKeyType !== 'rsa') throw new Error('Live room: the JaaS private key must be the RSA key the JaaS console made.');
    const webhookSecret = env.JAAS_WEBHOOK_SECRET?.trim() || undefined;
    return { provider: 'jaas', domain: JAAS_DOMAIN, recording: !!webhookSecret, jaas: { appId: appId!, kid: kid!, privateKey: privateKey!, webhookSecret } };
  }
  return { provider: 'jitsi', domain: env.JITSI_DOMAIN?.trim() || 'meet.jit.si', recording: false };
}

/**
 * Whether the built-in room can run here. A production server never falls back to the public meet.jit.si in silence:
 * nobody can start a class there (it waits for a meet.jit.si moderator sign-in) and embedded calls are cut off. It is
 * allowed only when the owner says so with LIVE_ROOM_PUBLIC_JITSI=allow. Outside-meeting links are unaffected.
 */
export function liveRoomUsable(cfg: LiveRoomConfig, env: NodeJS.ProcessEnv = process.env): boolean {
  if (cfg.provider !== 'jitsi' || cfg.domain !== 'meet.jit.si') return true;
  return env.NODE_ENV !== 'production' || env.LIVE_ROOM_PUBLIC_JITSI?.trim() === 'allow';
}

/** Refuses (503) to open or join the built-in room where it cannot run — before anything about the class is written. */
export function assertLiveRoomUsable(cfg: LiveRoomConfig, env: NodeJS.ProcessEnv = process.env) {
  if (!liveRoomUsable(cfg, env))
    throw new ApiError(
      503,
      'Live classes are not set up on this server yet. Ask the platform team to connect the video service.',
      undefined,
      'LIVE_ROOM_NOT_CONFIGURED',
    );
}

/** A fresh room name: unguessable, so knowing a class's id never lets anyone into its room. */
export const newRoomName = () => `shubh-${randomBytes(12).toString('hex')}`;

export function roomJoin(
  cfg: LiveRoomConfig,
  opts: {
    roomName: string;
    subject: string;
    user: { id: string; name: string; email?: string | null };
    moderator: boolean;
    now?: Date;
    /** When the way in stops working: the class's own close, so a token can't reopen a room after the class. */
    expiresAt?: Date;
  },
): RoomJoin {
  const base = {
    provider: cfg.provider,
    domain: cfg.domain,
    subject: opts.subject,
    displayName: opts.user.name,
    email: opts.user.email ?? undefined,
    moderator: opts.moderator,
    recording: cfg.recording && opts.moderator,
  };
  if (cfg.provider !== 'jaas' || !cfg.jaas) return { ...base, room: opts.roomName };
  const { appId, kid, privateKey } = cfg.jaas;
  const now = Math.floor((opts.now ?? new Date()).getTime() / 1000);
  const token = jwt.sign(
    {
      aud: 'jitsi',
      iss: 'chat',
      sub: appId,
      room: opts.roomName,
      nbf: now - 30,
      exp: Math.min(now + TOKEN_HOURS * 3600, opts.expiresAt ? Math.floor(opts.expiresAt.getTime() / 1000) : Infinity),
      context: {
        user: { id: opts.user.id, name: opts.user.name, email: opts.user.email ?? undefined, moderator: opts.moderator ? 'true' : 'false' },
        features: {
          recording: opts.moderator && cfg.recording ? 'true' : 'false',
          livestreaming: 'false',
          transcription: 'false',
          'outbound-call': 'false',
          'sip-outbound-call': 'false',
        },
      },
    },
    privateKey,
    { algorithm: 'RS256', header: { alg: 'RS256', kid: `${appId}/${kid}`, typ: 'JWT' } },
  );
  return { ...base, room: `${appId}/${opts.roomName}`, jwt: token };
}

/** How old a webhook's timestamp may be before it is refused as a replay. */
const WEBHOOK_TOLERANCE_SEC = 5 * 60;

/**
 * JaaS signs each webhook: `X-Jaas-Signature: t=<unix>,v1=<base64 HMAC-SHA256 of "<t>.<raw body>">`. Only `v1`
 * counts (a downgrade is refused), the comparison is constant-time, and a stale timestamp is a replay.
 */
export function verifyJaasSignature(raw: Buffer, header: string | undefined, secret: string, now = new Date()): boolean {
  if (!header) return false;
  let t: string | undefined;
  const sigs: string[] = [];
  for (const part of header.split(',')) {
    const i = part.indexOf('=');
    if (i < 0) continue;
    const key = part.slice(0, i).trim();
    const value = part.slice(i + 1).trim();
    if (key === 't') t = value;
    else if (key === 'v1') sigs.push(value);
  }
  if (!t || !/^\d+$/.test(t) || !sigs.length) return false;
  if (Math.abs(Math.floor(now.getTime() / 1000) - Number(t)) > WEBHOOK_TOLERANCE_SEC) return false;
  const expected = createHmac('sha256', secret).update(`${t}.`).update(raw).digest();
  return sigs.some((sig) => {
    const given = Buffer.from(sig, 'base64');
    return given.length === expected.length && timingSafeEqual(given, expected);
  });
}
