/*
 * The server's clock — the only clock billing reads (subscriptions.md §7: never trust the frontend clock).
 *
 * Trial starts and ends, periods, grace windows and every "has its moment come?" check read `now()`
 * here. No service function takes a time from its caller, so nothing a request carries — a header, a
 * body field, a browser's idea of the date — can move a trial or a grace period. Tests move this clock
 * with `setClock`; nothing else does.
 */

let fixed: number | null = null;

export const now = (): Date => new Date(fixed ?? Date.now());

/** Pins the clock to `at` — for tests. `null` lets it run again. */
export function setClock(at: Date | string | null): void {
  fixed = at === null ? null : new Date(at).getTime();
}
