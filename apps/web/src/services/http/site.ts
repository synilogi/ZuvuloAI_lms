import type { AdminBundle, BlogPost, BundlePurchaseView, PublicAffiliateProgram, PublicBundle, PublicMentor, PublicStats, SiteContent } from '@syniastrolms/domain';
import type { BundleCheckoutStart, BundleConfirmation, BundleQuote, SiteService } from '../contracts';
import { del, get, post, put } from './client';

/** The website's contact form, editable content and marketplace, against `/public/*`, `/learning/*` and `/superadmin/sales/*`. */
export const httpSite: SiteService = {
  contact: async (input) => {
    await post<{ received: true }>('/public/inquiries', input);
  },
  content: () => get<SiteContent>('/public/site'),
  affiliateProgram: () => get<PublicAffiliateProgram>('/public/affiliate-program'),
  adminContent: () => get<SiteContent>('/superadmin/sales/site'),
  saveContent: (input) => put<SiteContent>('/superadmin/sales/site', input),
  stats: () => get<PublicStats>('/public/stats'),
  mentors: () => get<PublicMentor[]>('/public/mentors'),
  mentor: (id) => get<{ mentor: PublicMentor; courseSlugs: string[] }>(`/public/mentors/${encodeURIComponent(id)}`),
  bundles: () => get<PublicBundle[]>('/public/bundles'),
  bundle: (slug) => get<PublicBundle>(`/public/bundles/${encodeURIComponent(slug)}`),
  posts: (kind) => get<BlogPost[]>('/public/posts', kind ? { kind } : undefined),
  post: (slug) => get<BlogPost>(`/public/posts/${encodeURIComponent(slug)}`),
  quoteBundle: (bundleId) => post<BundleQuote>(`/learning/bundles/${encodeURIComponent(bundleId)}/quote`),
  startBundlePurchase: (bundleId) => post<BundleCheckoutStart>(`/learning/bundles/${encodeURIComponent(bundleId)}/purchase`),
  confirmBundlePurchase: (purchaseId, completion) => post<BundleConfirmation>(`/learning/bundle-purchases/${encodeURIComponent(purchaseId)}/confirm`, completion),
  getBundlePurchase: (purchaseId) => get<BundlePurchaseView>(`/learning/bundle-purchases/${encodeURIComponent(purchaseId)}`),
  adminBundles: () => get<AdminBundle[]>('/superadmin/sales/bundles'),
  createBundle: (input) => post<AdminBundle>('/superadmin/sales/bundles', input),
  updateBundle: (id, input) => put<AdminBundle>(`/superadmin/sales/bundles/${encodeURIComponent(id)}`, input),
  deleteBundle: async (id) => {
    await del<void>(`/superadmin/sales/bundles/${encodeURIComponent(id)}`);
  },
  adminPosts: () => get<BlogPost[]>('/superadmin/sales/posts'),
  createPost: (input) => post<BlogPost>('/superadmin/sales/posts', input),
  updatePost: (id, input) => put<BlogPost>(`/superadmin/sales/posts/${encodeURIComponent(id)}`, input),
  deletePost: async (id) => {
    await del<void>(`/superadmin/sales/posts/${encodeURIComponent(id)}`);
  },
  placeImage: (mediaId) => post<{ url: string }>('/superadmin/sales/site/images', { mediaId }),
};
