import '@fontsource-variable/fraunces';
import '@fontsource/plus-jakarta-sans/400.css';
import '@fontsource/plus-jakarta-sans/600.css';
import '@fontsource/plus-jakarta-sans/700.css';
import '@/styles/tokens.css';
import '@/styles/globals.css';

import { lazy, StrictMode, Suspense } from 'react';
import { createRoot } from 'react-dom/client';

import { App } from '@/app/App';
import { ToastProvider } from '@/components/feedback/Toast';
import { TooltipProvider } from '@/components/ui/Popover';

const root = document.getElementById('root');
if (!root) throw new Error('The #root element is missing from index.html.');

// The component gallery exists only in development builds: with DEV false this branch and its dynamic import
// are removed from the production bundle (REACT-001, verified by grepping dist/).
const Gallery = import.meta.env.DEV ? lazy(() => import('@/dev/Gallery')) : null;
const showGallery = Gallery !== null && window.location.pathname === '/__ui';

createRoot(root).render(
  <StrictMode>
    <TooltipProvider>
      <ToastProvider>
        {showGallery && Gallery ? (
          <Suspense fallback={null}>
            <Gallery />
          </Suspense>
        ) : (
          <App />
        )}
      </ToastProvider>
    </TooltipProvider>
  </StrictMode>,
);
