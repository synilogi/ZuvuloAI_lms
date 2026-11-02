import { useEffect, type RefObject } from 'react';

/*
 * The home page's motion, kept small: everything that moves is a transform or an opacity, so nothing re-lays out.
 * CSS does the drawing (Landing.module.css); this file only decides *when* — which sections have come into view, and
 * where the pointer and the scroll put the hero's parallax. With reduced motion asked for, by the system or by the
 * app's own setting (`data-motion="reduced"`), none of it runs and every section simply shows.
 */

/** Whether the person asked for less motion: the system setting, or the app's own preference. */
export function prefersReducedMotion(): boolean {
  if (typeof window === 'undefined') return true;
  return window.matchMedia?.('(prefers-reduced-motion: reduce)').matches === true || document.documentElement.dataset.motion === 'reduced';
}

/**
 * Sections below the fold fade and rise in as they arrive. Only sections not yet on screen are hidden first — the ones
 * already in view at load are never hidden, so nothing flashes — and each is revealed once, then left alone.
 */
export function useSectionReveal(root: RefObject<HTMLElement | null>) {
  useEffect(() => {
    const el = root.current;
    if (!el || prefersReducedMotion() || typeof IntersectionObserver === 'undefined') return;
    const sections = Array.from(el.querySelectorAll<HTMLElement>(':scope > section:not([data-hero])'));
    const below = sections.filter((s) => s.getBoundingClientRect().top > window.innerHeight * 0.9);
    for (const s of below) s.dataset.reveal = 'pending';

    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          (entry.target as HTMLElement).dataset.reveal = 'in';
          observer.unobserve(entry.target);
        }
      },
      { rootMargin: '0px 0px -8% 0px', threshold: 0.06 },
    );
    for (const s of below) observer.observe(s);
    return () => {
      observer.disconnect();
      // Leave nothing hidden behind if the page unmounts mid-scroll and is shown again.
      for (const s of below) delete s.dataset.reveal;
    };
  }, [root]);
}

/**
 * The hero's parallax: the pointer tilts the scene a touch, and scrolling lets the phone rise faster than the panel.
 * Pointer and scroll only record where they are; one animation frame writes three CSS variables (`--px`, `--py`,
 * `--sy`) on each piece marked `data-parallax` — on those pieces alone, and registered as non-inheriting in
 * Landing.module.css, so a frame restyles four elements rather than the whole hero. Off screen, the scroll listener is
 * detached and the floating animations pause.
 */
export function useHeroMotion(hero: RefObject<HTMLElement | null>) {
  useEffect(() => {
    const el = hero.current;
    if (!el || prefersReducedMotion()) return;
    const finePointer = window.matchMedia?.('(pointer: fine)').matches === true;
    const pieces = Array.from(el.querySelectorAll<HTMLElement>('[data-parallax]'));
    let px = 0;
    let py = 0;
    let frame = 0;

    const write = () => {
      frame = 0;
      const rect = el.getBoundingClientRect();
      // 0 while the hero sits at the top, 1 once it has scrolled a full height away.
      const sy = Math.min(1, Math.max(0, -rect.top / Math.max(1, rect.height)));
      for (const piece of pieces) {
        piece.style.setProperty('--px', px.toFixed(3));
        piece.style.setProperty('--py', py.toFixed(3));
        piece.style.setProperty('--sy', sy.toFixed(3));
      }
    };
    const schedule = () => {
      if (!frame) frame = requestAnimationFrame(write);
    };
    const onPointer = (e: PointerEvent) => {
      const rect = el.getBoundingClientRect();
      px = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
      py = ((e.clientY - rect.top) / rect.height - 0.5) * 2;
      schedule();
    };
    const onLeave = () => {
      px = 0;
      py = 0;
      schedule();
    };

    if (finePointer) {
      el.addEventListener('pointermove', onPointer, { passive: true });
      el.addEventListener('pointerleave', onLeave, { passive: true });
    }

    let listening = false;
    const visibility = new IntersectionObserver(([entry]) => {
      const onScreen = entry.isIntersecting;
      if (onScreen) delete el.dataset.offscreen;
      else el.dataset.offscreen = 'true';
      if (onScreen && !listening) window.addEventListener('scroll', schedule, { passive: true });
      if (!onScreen && listening) window.removeEventListener('scroll', schedule);
      listening = onScreen;
    });
    visibility.observe(el);
    schedule();

    return () => {
      if (frame) cancelAnimationFrame(frame);
      visibility.disconnect();
      window.removeEventListener('scroll', schedule);
      el.removeEventListener('pointermove', onPointer);
      el.removeEventListener('pointerleave', onLeave);
      for (const piece of pieces) for (const name of ['--px', '--py', '--sy']) piece.style.removeProperty(name);
      delete el.dataset.offscreen;
    };
  }, [hero]);
}
