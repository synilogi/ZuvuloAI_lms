import { useEffect, type RefObject } from 'react';

const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

/**
 * Keeps keyboard focus inside a dialog while it is open, moves focus in on open,
 * and restores it to the trigger on close.
 */
export function useFocusTrap(active: boolean, containerRef: RefObject<HTMLElement | null>) {
  useEffect(() => {
    if (!active) return;
    const container = containerRef.current;
    if (!container) return;
    const previous = document.activeElement as HTMLElement | null;

    const focusables = () => Array.from(container.querySelectorAll<HTMLElement>(FOCUSABLE)).filter((el) => el.offsetParent !== null);
    const initial = container.querySelector<HTMLElement>('[data-autofocus]') ?? focusables()[0] ?? container;
    initial.focus({ preventScroll: true });

    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return;
      const items = focusables();
      if (items.length === 0) {
        e.preventDefault();
        return;
      }
      const first = items[0];
      const last = items[items.length - 1];
      if (e.shiftKey && document.activeElement === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && document.activeElement === last) {
        e.preventDefault();
        first.focus();
      }
    };
    container.addEventListener('keydown', onKey);
    return () => {
      container.removeEventListener('keydown', onKey);
      previous?.focus?.({ preventScroll: true });
    };
  }, [active, containerRef]);
}
