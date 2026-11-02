import type { HelpAudience } from '@syniastrolms/domain';
import type { HelpArticleDetail, HelpArticleRow, HelpCategoryRow, HelpService } from '../contracts';
import { ServiceError } from '../contracts';
import { helpArticles, helpCategories } from './fixtures/help';
import { respond, scenario } from './simulation';

const categoryName = (categoryId: string) => helpCategories.find((c) => c.id === categoryId)?.name ?? '';

/** Whether an article shows to a given role — 'all' articles show everywhere. */
const forAudience = (audience: HelpAudience, viewer?: HelpAudience) => !viewer || audience === 'all' || audience === viewer;

const row = (article: (typeof helpArticles)[number]): HelpArticleRow => ({ article, categoryName: categoryName(article.categoryId) });

function related(article: (typeof helpArticles)[number]): HelpArticleRow[] {
  return helpArticles
    .filter((a) => a.categoryId === article.categoryId && a.id !== article.id)
    .slice(0, 3)
    .map(row);
}

export const helpService: HelpService = {
  listCategories: (audience) =>
    respond((): HelpCategoryRow[] => {
      if (scenario() === 'empty') return [];
      return [...helpCategories]
        .sort((a, b) => a.order - b.order)
        .map((category) => ({ category, articleCount: helpArticles.filter((a) => a.categoryId === category.id && forAudience(a.audience, audience)).length }))
        .filter((c) => c.articleCount > 0);
    }, 420),

  listArticles: ({ search = '', categoryId, audience }) =>
    respond((): HelpArticleRow[] => {
      if (scenario() === 'empty') return [];
      const q = search.trim().toLowerCase();
      return helpArticles
        .filter((a) => forAudience(a.audience, audience))
        .filter((a) => !categoryId || a.categoryId === categoryId)
        .filter((a) => !q || `${a.title} ${a.summary} ${a.tags.join(' ')}`.toLowerCase().includes(q))
        .sort((a, b) => (b.popular ? 1 : 0) - (a.popular ? 1 : 0) || b.updatedAt.localeCompare(a.updatedAt))
        .map(row);
    }, 480),

  getArticle: (slug, audience) =>
    respond((): HelpArticleDetail => {
      const article = helpArticles.find((a) => a.slug === slug && forAudience(a.audience, audience));
      if (!article) throw new ServiceError('This article doesn’t exist, or isn’t open to your workspace.', 'not-found');
      return { ...row(article), related: related(article) };
    }, 420),
};
