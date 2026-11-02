/** Where API requests go: the configured URL in production, the dev server's `/api` proxy otherwise (D-05). */
export function resolveApiBaseUrl(env: { VITE_API_BASE_URL?: string; PROD: boolean }): string {
  const configured = env.VITE_API_BASE_URL?.trim();
  if (configured) return configured.replace(/\/+$/, '');
  if (env.PROD) throw new Error('VITE_API_BASE_URL must be set for a production build.');
  return '/api';
}

export const APP_NAME = import.meta.env.VITE_APP_NAME?.trim() || 'ShubhLMS';
