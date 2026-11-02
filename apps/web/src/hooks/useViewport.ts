import { useEffect, useState } from 'react';
import { breakpointFor, breakpoints } from '@/design/tokens';

function read() {
  return typeof window === 'undefined' ? 1440 : window.innerWidth;
}

/** Live viewport width and the shell's composition switch (desktop ≥ 768). */
export function useViewport() {
  const [width, setWidth] = useState(read);

  useEffect(() => {
    let frame = 0;
    const onResize = () => {
      cancelAnimationFrame(frame);
      frame = requestAnimationFrame(() => setWidth(read()));
    };
    window.addEventListener('resize', onResize);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener('resize', onResize);
    };
  }, []);

  return {
    width,
    breakpoint: breakpointFor(width),
    isDesktop: width >= breakpoints.md,
    isMobile: width < breakpoints.md,
  };
}
