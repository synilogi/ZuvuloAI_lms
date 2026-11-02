import type { MediaFile } from '@syniastrolms/domain';

import type { MediaService } from '../contracts';

/** Where each demo upload can be shown from: a local object URL, kept for the page's lifetime. */
const demoFiles = new Map<string, string>();

/** The address a demo upload is shown from, by its id (`undefined` once the page has reloaded). */
export const mockMediaUrl = (id: string) => demoFiles.get(id);

/** Demo upload: nothing leaves the browser — progress is simulated so the interface can show every phase. */
export const mediaService: MediaService = {
  upload: (file, onProgress) =>
    new Promise<MediaFile>((resolve) => {
      let progress = 0;
      const tick = () => {
        progress = Math.min(100, progress + 9 + Math.random() * 14);
        onProgress?.(progress);
        if (progress < 100) window.setTimeout(tick, 220);
        else
          window.setTimeout(() => {
            const id = `demo-media-${demoFiles.size + 1}-${Date.now().toString(36)}`;
            const url = URL.createObjectURL(file);
            demoFiles.set(id, url);
            resolve({ id, url, mime: file.type, name: file.name, sizeMb: Math.max(0.1, Math.round((file.size / 1_048_576) * 10) / 10) });
          }, 900);
      };
      window.setTimeout(tick, 220);
    }),
};
