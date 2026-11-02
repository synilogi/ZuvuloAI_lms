/*
 * A strong password for a new account, made in the browser from the platform's cryptographic random source.
 * It is shown to the super admin once, sent to the API once, and never stored here.
 */

const LOWER = 'abcdefghijkmnpqrstuvwxyz';
const UPPER = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const DIGITS = '23456789';
const SYMBOLS = '!@#$%*-_+?';
/** Look-alikes (l/1, O/0, I) are left out, so a password read aloud or retyped survives. */
const ALL = LOWER + UPPER + DIGITS + SYMBOLS;

type Random = (values: Uint32Array) => Uint32Array;

const defaultRandom: Random = (values) => crypto.getRandomValues(values);

/** `length` characters (at least 12), with at least one lowercase, uppercase, digit and symbol, in random order. */
export function generatePassword(length = 16, random: Random = defaultRandom): string {
  const size = Math.max(12, length);
  const values = random(new Uint32Array(size * 2));
  const pick = (set: string, i: number) => set[values[i] % set.length];
  const chars = [pick(LOWER, 0), pick(UPPER, 1), pick(DIGITS, 2), pick(SYMBOLS, 3)];
  for (let i = chars.length; i < size; i++) chars.push(pick(ALL, i));
  // Shuffle (Fisher–Yates) with the second half of the random values, so the guaranteed classes are not up front.
  for (let i = chars.length - 1; i > 0; i--) {
    const j = values[size + i] % (i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join('');
}
