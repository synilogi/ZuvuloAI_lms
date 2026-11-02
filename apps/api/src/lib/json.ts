/** SQLite has no native array/object columns — these read and write the JSON text columns. */
export function readJson<T>(value: string | null | undefined, fallback: T): T {
  if (!value) return fallback;
  try {
    return JSON.parse(value) as T;
  } catch {
    return fallback;
  }
}

export function writeJson(value: unknown): string {
  return JSON.stringify(value ?? null);
}
