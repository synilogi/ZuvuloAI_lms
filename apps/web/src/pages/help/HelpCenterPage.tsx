import { useMemo } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { ArrowRight, Lifebuoy, MagnifyingGlass, Question } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { plural } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { SearchInput } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { services, type HelpArticleRow } from '@/services';
import { AudienceBadge, HelpCategoryGlyph, readTime, useHelpBase } from './helpMeta';
import styles from './Help.module.css';

/** Hub: search everything, browse by topic, or jump to a popular article. */
export default function HelpCenterPage() {
  const base = useHelpBase();
  const [params, setParams] = useSearchParams();
  const search = params.get('q') ?? '';
  const setSearch = (q: string) => setParams(q ? { q } : {}, { replace: true });

  const query = useAsync('help-center', () =>
    Promise.all([services.help.listCategories(), services.help.listArticles({})]).then(([categories, articles]) => ({ categories, articles })),
  );
  const data = query.data;

  const results = useMemo(() => {
    if (!data) return [];
    const q = search.trim().toLowerCase();
    if (!q) return [];
    return data.articles.filter((r) => `${r.article.title} ${r.article.summary} ${r.article.tags.join(' ')}`.toLowerCase().includes(q));
  }, [data, search]);

  const popular = useMemo(() => {
    if (!data) return [];
    const flagged = data.articles.filter((r) => r.article.popular);
    return (flagged.length ? flagged : data.articles).slice(0, 5);
  }, [data]);

  if (query.status === 'error' && !data) {
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title="The Help Centre didn’t load"
          actions={
            <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }

  return (
    <div className={styles.page}>
      <PageHeader title="Help Centre" description="Short, practical guides to every part of ZuviloAI — search for something specific, or browse by topic." />

      <div className={styles.searchRow}>
        <SearchInput
          value={search}
          onValueChange={setSearch}
          placeholder="Search articles — “live class”, “certificate”, “review queue”…"
          aria-label="Search the Help Centre"
        />
      </div>

      {!data ? (
        <div className={styles.categoryGrid} aria-busy="true">
          {Array.from({ length: 6 }, (_, i) => (
            <Skeleton key={i} height={104} radius="var(--r-lg)" />
          ))}
        </div>
      ) : search.trim() ? (
        <section aria-labelledby="help-results-title">
          <SectionHeader id="help-results-title" title="Search results" count={results.length || undefined} />
          {results.length === 0 ? (
            <StateMessage
              icon={<MagnifyingGlass size={26} />}
              title="No articles match"
              actions={<Button onClick={() => setSearch('')}>Show every topic</Button>}
            >
              Try a shorter word, or browse by topic instead.
            </StateMessage>
          ) : (
            <ul className={styles.articleList}>
              {results.map((r) => (
                <ArticleRow key={r.article.id} row={r} to={`${base}/article/${r.article.slug}`} />
              ))}
            </ul>
          )}
        </section>
      ) : (
        <>
          <section aria-labelledby="help-topics-title">
            <SectionHeader id="help-topics-title" title="Browse by topic" />
            <ul className={styles.categoryGrid}>
              {data.categories.map((c) => (
                <li key={c.category.id}>
                  <Link to={`${base}/${c.category.id}`} className={styles.categoryTile}>
                    <HelpCategoryGlyph icon={c.category.icon} />
                    <span className={styles.categoryText}>
                      <span className={styles.categoryName}>{c.category.name}</span>
                      <span className={styles.muted}>{c.category.description}</span>
                      <span className={styles.categoryCount}>{plural(c.articleCount, 'article')}</span>
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </section>

          {popular.length > 0 && (
            <section aria-labelledby="help-popular-title">
              <SectionHeader id="help-popular-title" title="Popular articles" />
              <ul className={styles.articleList}>
                {popular.map((r) => (
                  <ArticleRow key={r.article.id} row={r} to={`${base}/article/${r.article.slug}`} />
                ))}
              </ul>
            </section>
          )}
        </>
      )}

      <section className={styles.contactCard} aria-labelledby="help-contact-title">
        <Question size={22} aria-hidden="true" />
        <div className={styles.contactText}>
          <h2 id="help-contact-title" className={styles.contactTitle}>
            Still stuck?
          </h2>
          <p className={styles.muted}>If a guide doesn’t cover it, write to us directly — replies usually arrive within a working day.</p>
        </div>
        <LinkButton to="/contact?topic=support" iconStart={<Lifebuoy size={16} />}>
          Contact support
        </LinkButton>
      </section>
    </div>
  );
}

export function ArticleRow({ row, to }: { row: HelpArticleRow; to: string }) {
  return (
    <li className={styles.articleRow}>
      <Link to={to} className={styles.articleLink}>
        <span className={styles.articleMain}>
          <span className={styles.articleTitle}>{row.article.title}</span>
          <span className={styles.articleSummary}>{row.article.summary}</span>
          <span className={styles.articleMeta}>
            {row.categoryName} · {readTime(row.article.readMinutes)}
            <AudienceBadge audience={row.article.audience} />
          </span>
        </span>
        <ArrowRight size={16} className={styles.articleArrow} aria-hidden="true" />
      </Link>
    </li>
  );
}
