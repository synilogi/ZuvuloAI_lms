/* Bundles the API into one file (dist/index.js) that plain node runs, for production. Everything is inside it except Prisma, whose
 * generated client and query engine load from disk; deploy.sh copies those beside it. Run: npm run build -w @syniastrolms/api */
import { build } from 'esbuild';
import { resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');

await build({
  absWorkingDir: root,
  entryPoints: ['src/index.ts'],
  outfile: 'dist/index.js',
  bundle: true,
  platform: 'node',
  format: 'esm',
  target: 'node20',
  sourcemap: true,
  external: ['@prisma/client', '.prisma/client'],
  // Some dependencies are CommonJS and call `require`, which an ES module has to be given.
  banner: { js: "import { createRequire as __createRequire } from 'node:module'; const require = __createRequire(import.meta.url);" },
  logLevel: 'warning',
});
console.log('[build] apps/api/dist/index.js');
