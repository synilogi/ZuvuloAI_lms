import { act } from '@testing-library/react';

type Listener = (event: MediaQueryListEvent) => void;

let width = 1280;
const lists = new Set<{ query: string; listeners: Set<Listener> }>();

const matches = (query: string) => {
  const min = /min-width:\s*(\d+)px/.exec(query);
  const max = /max-width:\s*(\d+)px/.exec(query);
  return (!min || width >= Number(min[1])) && (!max || width <= Number(max[1]));
};

window.matchMedia = (query: string) => {
  const entry = { query, listeners: new Set<Listener>() };
  lists.add(entry);
  return {
    get matches() {
      return matches(query);
    },
    media: query,
    onchange: null,
    addEventListener: (_: string, listener: Listener) => entry.listeners.add(listener),
    removeEventListener: (_: string, listener: Listener) => entry.listeners.delete(listener),
    addListener: (listener: Listener) => entry.listeners.add(listener),
    removeListener: (listener: Listener) => entry.listeners.delete(listener),
    dispatchEvent: () => true,
  } as MediaQueryList;
};

/** Simulates a viewport width for `matchMedia`-driven components (DataTable, FilterBar). */
export function setViewportWidth(next: number) {
  width = next;
  act(() => {
    for (const entry of lists) for (const listener of entry.listeners) listener({ matches: matches(entry.query), media: entry.query } as MediaQueryListEvent);
  });
}
