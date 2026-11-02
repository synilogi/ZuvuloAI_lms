/**
 * One CSV cell. A spreadsheet must not run a cell as a formula, and names come from people, so text starting with a formula
 * character is neutralised. Numbers are written as they are.
 */
export const csvCell = (v: string | number | null): string => {
  if (v === null) return '';
  let s = String(v);
  if (typeof v === 'string' && /^[=+\-@\t\r]/.test(s)) s = `'${s}`;
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};
