/** Deterministic randomness for generated mock data — the same seed yields the same academy on every load. */

export function createRandom(seed: number) {
  let a = seed >>> 0;
  const next = () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  return {
    next,
    between: (min: number, max: number) => min + next() * (max - min),
    int: (min: number, max: number) => Math.floor(min + next() * (max - min + 1)),
    chance: (p: number) => next() < p,
    pick: <T>(items: readonly T[]) => items[Math.floor(next() * items.length)],
    shuffle: <T>(items: T[]) => {
      const out = [...items];
      for (let i = out.length - 1; i > 0; i--) {
        const j = Math.floor(next() * (i + 1));
        [out[i], out[j]] = [out[j], out[i]];
      }
      return out;
    },
  };
}

export type Random = ReturnType<typeof createRandom>;

/** Stable hash of a string, for per-record seeds. */
export function hashSeed(text: string) {
  let h = 2166136261;
  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 16777619);
  return h >>> 0;
}

export const DAY_MS = 86_400_000;

export const addDays = (iso: string | Date, days: number) => new Date(new Date(iso).getTime() + days * DAY_MS);

/** ISO timestamp in IST for generated dates. */
export function toIST(date: Date): string {
  const ist = new Date(date.getTime() + 5.5 * 3_600_000);
  return `${ist.toISOString().slice(0, 19)}+05:30`;
}

/** YYYY-MM-DD in IST. */
export const dayKey = (date: Date | string) => toIST(new Date(date)).slice(0, 10);
