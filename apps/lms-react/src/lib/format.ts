/** Formatting helpers. REACT-002 adds money, number, percent, date and duration formatting here. */

const BYTE_UNITS = ['B', 'KB', 'MB', 'GB', 'TB'] as const;

/** 1536 → "1.5 KB". Uses 1024 steps, like the API's upload limits (500 MB, 25 MB, 5 MB). */
export function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes < 0) return '—';
  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < BYTE_UNITS.length - 1) {
    value /= 1024;
    unit += 1;
  }
  const digits = unit === 0 || value >= 10 ? 0 : 1;
  return `${value.toFixed(digits)} ${BYTE_UNITS[unit]}`;
}
