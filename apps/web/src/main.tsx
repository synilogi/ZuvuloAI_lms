import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

import '@fontsource-variable/fraunces/standard.css';
import '@fontsource-variable/fraunces/standard-italic.css';
import '@fontsource/plus-jakarta-sans/400.css';
import '@fontsource/plus-jakarta-sans/500.css';
import '@fontsource/plus-jakarta-sans/600.css';
import '@fontsource/plus-jakarta-sans/700.css';

import './styles/tokens.css';
import './styles/density.css';
import './styles/base.css';
import './styles/typography.css';

import { App } from './app/App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
