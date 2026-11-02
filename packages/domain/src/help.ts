/**
 * Knowledge base content: short, task-focused articles grouped by category. Content is
 * hand-written and stored as mock data (see `services/mock/fixtures/help.ts`); this file only
 * carries the shape so the future API can serve the same structure.
 */

import type { ID, ISODateTime } from './catalog';

/** Who an article is written for. 'all' shows to every role. */
export type HelpAudience = 'all' | 'student' | 'instructor' | 'admin';

/** A closed set of icons for category tiles — kept small so every category has a clear glyph. */
export type HelpCategoryIcon = 'rocket' | 'book' | 'clipboard' | 'video' | 'certificate' | 'chart' | 'gear' | 'users';

export interface HelpCategory {
  id: ID;
  name: string;
  description: string;
  icon: HelpCategoryIcon;
  /** Display order in the hub. */
  order: number;
}

export interface HelpArticle {
  id: ID;
  slug: string;
  categoryId: ID;
  title: string;
  /** One or two sentences shown on cards and in search results. */
  summary: string;
  /** Markdown compatible with `ArticleBody`: `## heading`, `> quote`, `- item`, `1. item`, `**bold**`, `_em_`, links. */
  body: string;
  audience: HelpAudience;
  tags: string[];
  readMinutes: number;
  updatedAt: ISODateTime;
  /** Surfaced first on the hub's "Popular articles" list. */
  popular?: boolean;
}
