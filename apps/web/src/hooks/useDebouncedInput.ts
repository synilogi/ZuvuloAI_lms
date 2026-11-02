import { useEffect, useRef, useState } from 'react';

/**
 * A search box's text, kept here as the person types and handed to `commit` (which writes the URL and so reloads the
 * list) once they pause. A change to `value` from elsewhere — a back button, a cleared filter — replaces the text.
 */
export function useDebouncedInput(value: string, commit: (next: string) => void, delayMs = 300): [string, (next: string) => void] {
  const [draft, setDraft] = useState(value);
  const timer = useRef<number>();
  const latestCommit = useRef(commit);
  latestCommit.current = commit;

  useEffect(() => {
    if (timer.current === undefined) setDraft(value);
  }, [value]);
  useEffect(() => () => window.clearTimeout(timer.current), []);

  const change = (next: string) => {
    setDraft(next);
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => {
      timer.current = undefined;
      latestCommit.current(next);
    }, delayMs);
  };
  return [draft, change];
}
