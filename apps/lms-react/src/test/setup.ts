import '@testing-library/jest-dom/vitest';

import { cleanup } from '@testing-library/react';
import { afterEach, beforeEach } from 'vitest';

import { setViewportWidth } from './viewport';

// jsdom has no layout engine. These stand-ins cover what Radix primitives and our responsive hooks call.
class ResizeObserverStub {
  observe() {}
  unobserve() {}
  disconnect() {}
}
globalThis.ResizeObserver ??= ResizeObserverStub as unknown as typeof ResizeObserver;
Element.prototype.scrollIntoView ??= function scrollIntoView() {};
Element.prototype.hasPointerCapture ??= () => false;
Element.prototype.releasePointerCapture ??= () => {};
Element.prototype.setPointerCapture ??= () => {};

beforeEach(() => {
  setViewportWidth(1280);
});

afterEach(() => {
  cleanup();
});
