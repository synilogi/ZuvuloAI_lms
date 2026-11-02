import react from '@vitejs/plugin-react';
import { fileURLToPath, URL } from 'node:url';
import { configDefaults, defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
  },
  css: {
    modules: { localsConvention: 'camelCase' },
  },
  server: { port: 5173 },
  test: {
    // e2e/ holds Playwright specs, which use a different `test`/`expect` and their own runner
    // (`npm run e2e`) — Vitest's default glob would otherwise pick them up and fail on import.
    exclude: [...configDefaults.exclude, 'e2e/**'],
  },
});
