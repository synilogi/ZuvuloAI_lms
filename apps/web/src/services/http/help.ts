import type { HelpArticleDetail, HelpArticleRow, HelpCategoryRow, HelpService } from '../contracts';
import { get } from './client';

export const httpHelp: HelpService = {
  listCategories: (audience) => get<HelpCategoryRow[]>('/help/categories', { audience }),
  listArticles: (query) => get<HelpArticleRow[]>('/help/articles', query),
  getArticle: (slug, audience) => get<HelpArticleDetail>(`/help/articles/${slug}`, { audience }),
};
