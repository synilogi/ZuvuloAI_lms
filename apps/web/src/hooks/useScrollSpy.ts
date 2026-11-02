import { useEffect, useState } from 'react';

/**
 * Tracks which section is currently being read inside a scroll container.
 * Sections are matched by id; the last section whose top has crossed the
 * reading line wins.
 */
export function useScrollSpy(ids: string[], root: HTMLElement | null, offset = 120) {
  const [active, setActive] = useState<string | undefined>(ids[0]);
  // A stable key so a new array with the same ids doesn't re-subscribe.
  const key = ids.join('|');

  useEffect(() => {
    const list = key ? key.split('|') : [];
    const scroller: HTMLElement | Window = root ?? window;
    const update = () => {
      const rootTop = root ? root.getBoundingClientRect().top : 0;
      let current = list[0];
      for (const id of list) {
        const el = document.getElementById(id);
        if (el && el.getBoundingClientRect().top - rootTop <= offset) current = id;
      }
      setActive(current);
    };
    update();
    scroller.addEventListener('scroll', update, { passive: true });
    return () => scroller.removeEventListener('scroll', update);
  }, [key, root, offset]);

  return active;
}
