import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { CategoryGlyph } from '@/components/lms/course/CategoryGlyph';
import { useAsync } from '@/hooks/useAsync';
import { plural } from '@/lib/format';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import { PageHero } from './SiteParts';
import styles from './Marketing.module.css';
import site from './Site.module.css';

/** `/categories`: every active category with how many published courses it holds. */
export default function CategoriesPage() {
  const query = useAsync('site:categories', () =>
    Promise.all([services.catalog.listCategories(), services.catalog.listCourses()]).then(([categories, courses]) => ({ categories, courses })),
  );
  const data = query.data;
  const categories = data?.categories.filter((c) => c.status === 'active') ?? [];

  return (
    <MarketingChrome>
      <PageHero eyebrow="Categories" title="Browse courses by category">
        Choose a subject to see every course in it.
      </PageHero>
      <section className={styles.section} aria-label="Categories">
        {query.status === 'error' && !data ? (
          <StateMessage
            kind="error"
            title="The categories didn’t load"
            actions={
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            }
          >
            {query.error.message}
          </StateMessage>
        ) : !data ? (
          <Skeleton height={280} radius="var(--r-lg)" />
        ) : categories.length === 0 ? (
          <StateMessage title="No categories yet">Courses will be organised here as they are published.</StateMessage>
        ) : (
          <ul className={site.categoryGrid}>
            {categories.map((c) => (
              <li key={c.id}>
                <Link to={`/courses?category=${c.id}`} className={site.categoryCard}>
                  <CategoryGlyph glyph={c.glyph} size={40} />
                  <h2>{c.name}</h2>
                  {c.description && <p>{c.description}</p>}
                  <p className={site.categoryCount}>{plural(data.courses.filter((course) => course.categoryId === c.id).length, 'course')}</p>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </section>
    </MarketingChrome>
  );
}
