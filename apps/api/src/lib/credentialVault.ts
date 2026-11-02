import { createCipheriv, createDecipheriv, createHash, randomBytes } from 'node:crypto';

/*
 * Encryption at rest for payment-gateway credentials (SAAS-017). AES-256-GCM: every value sealed with a fresh
 * 96-bit IV, authenticated, so a tampered or mis-keyed ciphertext is refused rather than decrypted to noise.
 *
 * The key is a deployment secret — `PAYMENT_CREDENTIALS_KEY`, 32 random bytes as 64 hex characters or base64 —
 * and is never stored in the database, returned, or logged. What is stored beside a ciphertext is the key's
 * fingerprint (the first 16 hex characters of its SHA-256), so a value sealed under another key is recognised
 * and reported instead of failing obscurely. Nothing here logs; errors carry no secret and no ciphertext.
 */

const FORMAT = 'v1';

/** Raised when credentials cannot be sealed or opened: no key, a malformed key, or the wrong key. */
export class VaultError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'VaultError';
  }
}

function keyFrom(env: NodeJS.ProcessEnv): Buffer {
  const raw = env.PAYMENT_CREDENTIALS_KEY?.trim();
  if (!raw) throw new VaultError('PAYMENT_CREDENTIALS_KEY is not set, so gateway credentials cannot be stored or read.');
  const key = /^[0-9a-f]{64}$/i.test(raw) ? Buffer.from(raw, 'hex') : Buffer.from(raw, 'base64');
  if (key.length !== 32) throw new VaultError('PAYMENT_CREDENTIALS_KEY must be 32 bytes: 64 hex characters, or base64.');
  return key;
}

/** Whether a usable key is configured. */
export function vaultConfigured(env: NodeJS.ProcessEnv = process.env): boolean {
  try {
    keyFrom(env);
    return true;
  } catch {
    return false;
  }
}

/** The fingerprint of the configured key: identifies it, reveals nothing of it. */
export function vaultKeyId(env: NodeJS.ProcessEnv = process.env): string {
  return createHash('sha256').update(keyFrom(env)).digest('hex').slice(0, 16);
}

/** Seals a credentials object. Returns the ciphertext and the fingerprint of the key that sealed it. */
export function sealCredentials(value: Record<string, string>, env: NodeJS.ProcessEnv = process.env): { cipher: string; keyId: string } {
  const key = keyFrom(env);
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const body = Buffer.concat([cipher.update(JSON.stringify(value), 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return { cipher: [FORMAT, iv.toString('base64'), tag.toString('base64'), body.toString('base64')].join(':'), keyId: vaultKeyId(env) };
}

/** Opens sealed credentials. Refuses a value sealed under another key, or one that was altered. */
export function openCredentials(sealed: string, keyId: string, env: NodeJS.ProcessEnv = process.env): Record<string, string> {
  if (keyId !== vaultKeyId(env)) throw new VaultError('These gateway credentials were sealed under a different PAYMENT_CREDENTIALS_KEY. Re-enter them.');
  const [format, iv, tag, body] = sealed.split(':');
  if (format !== FORMAT || !iv || !tag || !body) throw new VaultError('Stored gateway credentials are not in a format this version reads.');
  try {
    const decipher = createDecipheriv('aes-256-gcm', keyFrom(env), Buffer.from(iv, 'base64'));
    decipher.setAuthTag(Buffer.from(tag, 'base64'));
    const text = Buffer.concat([decipher.update(Buffer.from(body, 'base64')), decipher.final()]).toString('utf8');
    return JSON.parse(text) as Record<string, string>;
  } catch {
    throw new VaultError('Stored gateway credentials could not be opened: they were altered, or the key is wrong.');
  }
}
