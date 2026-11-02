/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** The API's public URL in production. Unset in development, where `/api` is proxied (vite.config.ts). */
  readonly VITE_API_BASE_URL?: string;
  /** Product name for document titles. */
  readonly VITE_APP_NAME?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
