import type { MediaFile } from '@syniastrolms/domain';

import { ServiceError, type MediaService } from '../contracts';
import { getToken } from './client';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:4000';

/** Multipart upload through XMLHttpRequest so the drop zone can show real progress. */
export const httpMedia: MediaService = {
  upload: (file, onProgress) =>
    new Promise<MediaFile>((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open('POST', `${BASE_URL}/media/upload`);
      const token = getToken();
      if (token) xhr.setRequestHeader('Authorization', `Bearer ${token}`);
      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) onProgress?.(Math.round((e.loaded / e.total) * 100));
      };
      xhr.onerror = () => reject(new ServiceError('Could not reach the server.', 'network'));
      xhr.onload = () => {
        let body: { message?: string } & Partial<MediaFile> = {};
        try {
          body = JSON.parse(xhr.responseText);
        } catch {
          /* non-JSON failure body */
        }
        if (xhr.status >= 200 && xhr.status < 300) resolve(body as MediaFile);
        else reject(new ServiceError(body.message ?? 'The upload failed.', xhr.status === 404 ? 'not-found' : 'conflict'));
      };
      const form = new FormData();
      form.append('file', file, file.name);
      xhr.send(form);
    }),
};
