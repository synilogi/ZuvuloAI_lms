import { fileURLToPath, URL } from 'node:url';

import react from '@vitejs/plugin-react';
import { defineConfig, loadEnv } from 'vite';
import { configDefaults } from 'vitest/config';

// The API admits one CORS origin (the existing app's). In development this app calls `/api/*` on its own origin and
// Vite forwards it to the API with the prefix removed, so running it locally needs no backend change (D-05).
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), 'VITE_');
  const apiTarget = env.VITE_API_PROXY_TARGET || 'http://localhost:4000';

  return {
    plugins: [react()],
    resolve: {
      alias: { '@': fileURLToPath(new URL('./src', import.meta.url)) },
    },
    css: {
      modules: { localsConvention: 'camelCase' },
    },
    server: {
      port: 5174,
      strictPort: true,
      proxy: {
        '/api': {
          target: apiTarget,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, ''),
        },
      },
    },
    preview: { port: 5174, strictPort: true },
    build: { sourcemap: false },
    test: {
      environment: 'jsdom',
      setupFiles: ['./src/test/setup.ts'],
      include: ['src/**/*.test.{ts,tsx}'],
      exclude: [...configDefaults.exclude, 'e2e/**'],
      css: { modules: { classNameStrategy: 'non-scoped' } },
      restoreMocks: true,
    },
  };
});
