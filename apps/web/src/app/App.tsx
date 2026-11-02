import { IconContext } from '@phosphor-icons/react';
import { RouterProvider } from 'react-router-dom';
import { ToastProvider } from '@/components/overlays/Toast/ToastProvider';
import { BrandingProvider } from '@/branding/BrandingProvider';
import { PreferencesProvider } from '@/providers/PreferencesProvider';
import { SessionProvider } from '@/providers/SessionProvider';
import { useViewport } from '@/hooks/useViewport';
import { router } from './router';

/** Phosphor duotone is the shell's icon language; icons are decorative unless labelled. */
const iconDefaults = { weight: 'duotone' as const, size: 18, 'aria-hidden': true, focusable: false };

function Providers() {
  const { isMobile } = useViewport();
  return (
    <ToastProvider bottomOffset={isMobile ? 58 : 0}>
      <RouterProvider router={router} future={{ v7_startTransition: true }} />
    </ToastProvider>
  );
}

export function App() {
  return (
    <IconContext.Provider value={iconDefaults}>
      <PreferencesProvider>
        <BrandingProvider>
          <SessionProvider>
            <Providers />
          </SessionProvider>
        </BrandingProvider>
      </PreferencesProvider>
    </IconContext.Provider>
  );
}
