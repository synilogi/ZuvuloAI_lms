import { Router } from 'express';
import type { HelpArticle, HelpAudience, HelpCategory } from '@syniastrolms/domain';

import { db } from '../lib/db.js';
import { optionalId, parseQuery, searchText, z } from '../lib/validate.js';
import { asyncHandler, notFound } from '../lib/errors.js';
import { readJson } from '../lib/json.js';

export const helpRouter = Router();

function mapCategory(row: { id: string; name: string; description: string; icon: string; order: number }): HelpCategory {
  return { id: row.id, name: row.name, description: row.description, icon: row.icon as HelpCategory['icon'], order: row.order };
}

function mapArticle(row: {
  id: string;
  slug: string;
  categoryId: string;
  title: string;
  summary: string;
  body: string;
  audience: string;
  tagsJson: string;
  readMinutes: number;
  updatedAt: Date;
  popular: boolean;
}): HelpArticle {
  return {
    id: row.id,
    slug: row.slug,
    categoryId: row.categoryId,
    title: row.title,
    summary: row.summary,
    body: row.body,
    audience: row.audience as HelpAudience,
    tags: readJson<string[]>(row.tagsJson, []),
    readMinutes: row.readMinutes,
    updatedAt: row.updatedAt.toISOString(),
    popular: row.popular || undefined,
  };
}

function visibleTo(audience: string, viewer?: HelpAudience) {
  return audience === 'all' || !viewer || audience === viewer;
}

helpRouter.get(
  '/categories',
  asyncHandler(async (req, res) => {
    const { audience } = parseQuery(req, z.object({ audience: optionalId })) as { audience?: HelpAudience };
    const categories = await db.helpCategory.findMany({ orderBy: { order: 'asc' }, include: { articles: true } });
    res.json(categories.map((c) => ({ category: mapCategory(c), articleCount: c.articles.filter((a) => visibleTo(a.audience, audience)).length })));
  }),
);

helpRouter.get(
  '/articles',
  asyncHandler(async (req, res) => {
    const { search, categoryId, audience } = parseQuery(req, z.object({ search: searchText, categoryId: optionalId, audience: optionalId })) as {
      search?: string;
      categoryId?: string;
      audience?: HelpAudience;
    };
    const articles = await db.helpArticle.findMany({
      where: { ...(categoryId ? { categoryId } : {}) },
      include: { category: true },
      orderBy: [{ popular: 'desc' }, { updatedAt: 'desc' }],
    });
    let rows = articles
      .filter((a) => visibleTo(a.audience, audience as HelpAudience | undefined))
      .map((a) => ({ article: mapArticle(a), categoryName: a.category.name }));
    if (search) {
      const q = search.toLowerCase();
      rows = rows.filter(
        (r) =>
          r.article.title.toLowerCase().includes(q) || r.article.summary.toLowerCase().includes(q) || r.article.tags.some((t) => t.toLowerCase().includes(q)),
      );
    }
    res.json(rows);
  }),
);

helpRouter.get(
  '/articles/:slug',
  asyncHandler(async (req, res) => {
    const { audience } = parseQuery(req, z.object({ audience: optionalId })) as { audience?: HelpAudience };
    const article = await db.helpArticle.findUnique({ where: { slug: req.params.slug }, include: { category: true } });
    if (!article || !visibleTo(article.audience, audience)) throw notFound('not-found');
    const related = await db.helpArticle.findMany({ where: { categoryId: article.categoryId, id: { not: article.id } }, take: 3 });
    res.json({
      article: mapArticle(article),
      categoryName: article.category.name,
      related: related.map((a) => ({ article: mapArticle(a), categoryName: article.category.name })),
    });
  }),
);
