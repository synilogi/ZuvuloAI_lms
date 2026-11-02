import { useMemo, useState } from 'react';
import { useParams } from 'react-router-dom';
import { ArrowLeft, MagnifyingGlass } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { SearchInput } from '@/components/ui/Field/Field';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { ArticleRow } from './HelpCenterPage';
import { HelpCategoryGlyph, useHelpBase } from './helpMeta';
import styles from './Help.module.css';

/** One topic's articles, with a search that narrows just this list. */
export default function HelpCategoryPage() {
  const { categoryId } = useParams();
  const base = useHelpBase();
  const [search, setSearch] = useState('');

  const query = useAsync(`help-category:${categoryId}`, () =>
    Promise.all([services.help.listCategories(), services.help.listArticles({ categoryId })]).then(([categories, articles]) => ({ categories, articles })),
  );
  const data = query.data;
  const category = data?.categories.find((c) => c.category.id === categoryId);
  usePageCrumbs([{ label: 'Help Centre', to: base }, { label: category?.category.name ?? 'Topic' }]);

  const shown = useMemo(() => {
    if (!data) return [];
    const q = search.trim().toLowerCase();
    if (!q) return data.articles;
    return data.articles.filter((r) => `${r.article.title} ${r.article.summary} ${r.article.tags.join(' ')}`.toLowerCase().includes(q));
  }, [data, search]);

  if (query.status === 'error' && !data) {
    return (
      <div className={styles.narrowPage}>
        <StateMessage
          kind="error"
          title="This topic didn’t load"
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

  if (!data) {
    return (
      <div className={styles.narrowPage} aria-busy="true">
        <Skeleton width="30%" height={14} />
        <Skeleton width="55%" height={30} radius="var(--r-xs)" />
        <Skeleton height={280} radius="var(--r-lg)" />
      </div>
    );
  }

  if (!category) {
    return (
      <div className={styles.narrowPage}>
        <StateMessage
          icon={<MagnifyingGlass size={26} />}
          title="This topic doesn’t exist"
          actions={
            <LinkButton to={base} variant="primary" iconStart={<ArrowLeft size={16} />}>
              Back to the Help Centre
            </LinkButton>
          }
        >
          It may have moved, or the address may be mistyped.
        </StateMessage>
      </div>
    );
  }

  return (
    <div className={styles.narrowPage}>
      <div className={styles.categoryHeadIcon}>
        <HelpCategoryGlyph icon={category.category.icon} size="lg" />
      </div>
      <PageHeader back={{ label: 'Help Centre', to: base }} title={category.category.name} description={category.category.description} />

      <div className={styles.searchRow}>
        <SearchInput
          value={search}
          onValueChange={setSearch}
          placeholder={`Search ${category.category.name.toLowerCase()}`}
          aria-label={`Search ${category.category.name}`}
        />
      </div>

      {shown.length === 0 ? (
        <StateMessage
          icon={<MagnifyingGlass size={26} />}
          title="No articles match"
          actions={<Button onClick={() => setSearch('')}>Show every article</Button>}
        >
          Try another word, or clear the search.
        </StateMessage>
      ) : (
        <>
          <p className={styles.muted}>{plural(shown.length, 'article')}</p>
          <ul className={styles.articleList}>
            {shown.map((r) => (
              <ArticleRow key={r.article.id} row={r} to={`${base}/article/${r.article.slug}`} />
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
