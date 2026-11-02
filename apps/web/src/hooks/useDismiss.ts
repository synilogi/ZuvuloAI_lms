import { useEffect, useRef, type RefObject } from 'react';

/** Closes a popover on Escape or a pointer press outside the given elements. */
export function useDismiss(open: boolean, onDismiss: () => void, refs: RefObject<HTMLElement | null>[]) {
  const refsRef = useRef(refs);
  refsRef.current = refs;

  useEffect(() => {
    if (!open) return;
    const onPointer = (e: PointerEvent) => {
      const target = e.target as Node;
      if (refsRef.current.some((r) => r.current?.contains(target))) return;
      onDismiss();
    };
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.stopPropagation();
        onDismiss();
      }
    };
    document.addEventListener('pointerdown', onPointer);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('pointerdown', onPointer);
      document.removeEventListener('keydown', onKey);
    };
  }, [open, onDismiss]);
}
