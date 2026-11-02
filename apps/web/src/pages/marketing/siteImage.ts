import { API_BASE_URL } from '@/services/http/client';

/** The address to load a website image from: the API serves them, and it may live on another origin. */
export const siteImageSrc = (url: string | undefined) => {
  if (!url) return undefined;
  return url.startsWith('/public/') ? `${API_BASE_URL}${url}` : url;
};
