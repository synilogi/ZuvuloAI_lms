import { useEffect, useState } from 'react';
import { API_BASE_URL, getToken } from '@/services/http/client';

const isLocal = (path: string) => path.startsWith('blob:') || path.startsWith('data:');
/** Only a path on the API host is fetched: the token is never sent anywhere else. */
const isApiPath = (path: string) => path.startsWith('/') && !path.startsWith('//');

/**
 * An image the API serves (`/catalog/covers/<id>`, `/media/<id>`) as an address an `<img>` can show. Those routes
 * read the session from the Authorization header — it decides the academy, and whether a draft's cover may be
 * seen — and an `<img>` cannot send one, so the bytes are fetched and shown from an object URL. A local address (a
 * demo upload's `blob:`) passes straight through. `undefined` while loading, and when there is none or it fails.
 */
export function useApiImage(path: string | undefined): string | undefined {
  const [src, setSrc] = useState<string>();

  useEffect(() => {
    setSrc(undefined);
    if (!path || isLocal(path) || !isApiPath(path)) return;
    const controller = new AbortController();
    let objectUrl: string | undefined;
    const token = getToken();
    fetch(`${API_BASE_URL}${path}`, { headers: token ? { Authorization: `Bearer ${token}` } : {}, signal: controller.signal })
      .then((res) => (res.ok ? res.blob() : undefined))
      .then((blob) => {
        if (!blob || !blob.type.startsWith('image/')) return;
        objectUrl = URL.createObjectURL(blob);
        setSrc(objectUrl);
      })
      .catch(() => undefined);
    return () => {
      controller.abort();
      if (objectUrl) URL.revokeObjectURL(objectUrl);
    };
  }, [path]);

  return path && isLocal(path) ? path : src;
}
