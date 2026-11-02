import { useEffect } from 'react';
import { Link, useParams, useSearchParams } from 'react-router-dom';
import { ArrowSquareOut } from '@phosphor-icons/react';
import { BLOG_KINDS, BLOG_KIND_LABELS, type BlogKind } from '@syniastrolms/domain';
import { metaDescription, setPageMeta } from '@/app/pageMeta';
import { ArticleBody } from '@/components/lms/content/ArticleBody';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { useJsonLd } from '@/hooks/useJsonLd';
import { formatDate } from '@/lib/format';
import { services } from '@/services';
import { PostCard } from './LandingPage';
import { MarketingChrome } from './MarketingChrome';
import { PageHero } from './SiteParts';
import { siteImageSrc } from './siteImage';
import styles from './Home.module.css';
import marketing from './Marketing.module.css';

/* The website's blog and resources (docs/17): what the Super Admin has published, by kind. */

/** `/blog`. */
export function BlogPage() {
  const [params] = useSearchParams();
  const asked = params.get('kind') as BlogKind | null;
  const kind = asked && BLOG_KINDS.includes(asked) ? asked : undefined;
  const query = useAsync(`site:posts:${kind ?? 'all'}`, () => services.site.posts(kind));
  return (
    <MarketingChrome>
      <PageHero eyebrow="Blog and resources" title="Blog and resources">
        Articles, free resources, webinars, live workshops and career guidance from the ZuviloAI team.
      </PageHero>
      <section className={marketing.section} aria-label="Posts">
        <nav className={styles.kindTabs} aria-label="Filter by kind">
          <Link to="/blog" aria-current={!kind}>
            All
          </Link>
          {BLOG_KINDS.map((k) => (
            <Link key={k} to={`/blog?kind=${k}`} aria-current={kind === k}>
              {BLOG_KIND_LABELS[k]}
            </Link>
          ))}
        </nav>
        {query.status === 'error' && !query.data ? (
          <StateMessage
            kind="error"
            title="The posts didn’t load"
            actions={
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            }
          >
            {query.error.message}
          </StateMessage>
        ) : !query.data ? (
          <Skeleton height={280} radius="var(--r-lg)" />
        ) : query.data.length === 0 ? (
          <StateMessage
            title={kind ? 'Nothing here yet' : 'No posts yet'}
            actions={
              <LinkButton variant="primary" to="/courses">
                Explore courses
              </LinkButton>
            }
          >
            New articles and resources will appear here as they are published.
          </StateMessage>
        ) : (
          <ul className={styles.postGrid}>
            {query.data.map((p) => (
              <PostCard key={p.id} post={p} headingLevel="h2" />
            ))}
          </ul>
        )}
      </section>
    </MarketingChrome>
  );
}

/** `/blog/:slug`. */
export function BlogPostPage() {
  const { slug = '' } = useParams();
  const query = useAsync(`site:post:${slug}`, () => services.site.post(slug));
  const post = query.data;

  useEffect(() => {
    if (post)
      setPageMeta({
        title: `${post.title} · ZuviloAI`,
        description: metaDescription(post.excerpt),
        path: `/blog/${post.slug}`,
        ...(post.coverUrl ? { image: siteImageSrc(post.coverUrl) } : {}),
      });
  }, [post]);
  useJsonLd(
    post && {
      '@context': 'https://schema.org',
      '@type': 'Article',
      headline: post.title,
      description: post.excerpt,
      datePublished: post.publishAt ?? post.createdAt,
      dateModified: post.updatedAt,
      publisher: { '@type': 'Organization', name: 'ZuviloAI' },
    },
  );

  if (query.status === 'error' && !post) {
    const missing = (query.error as { code?: string }).code === 'not-found';
    return (
      <MarketingChrome>
        <StateMessage
          kind={missing ? 'empty' : 'error'}
          title={missing ? 'This post isn’t available' : 'The post didn’t load'}
          actions={
            missing ? (
              <LinkButton variant="primary" to="/blog">
                See all posts
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {missing ? 'It may have been withdrawn, or the link may be wrong.' : query.error.message}
        </StateMessage>
      </MarketingChrome>
    );
  }
  if (!post) {
    return (
      <MarketingChrome>
        <Skeleton height={480} radius="var(--r-lg)" />
      </MarketingChrome>
    );
  }
  const cover = siteImageSrc(post.coverUrl);
  return (
    <MarketingChrome>
      <article className={styles.post}>
        <span className={styles.eyebrow}>
          <Link to={`/blog?kind=${post.kind}`}>{BLOG_KIND_LABELS[post.kind]}</Link>
        </span>
        <h1>{post.title}</h1>
        <p className={styles.postMeta}>{post.eventAt ? `Takes place on ${formatDate(post.eventAt)}` : formatDate(post.publishAt ?? post.createdAt)}</p>
        {cover && <img src={cover} alt="" className={styles.postCover} />}
        {post.excerpt && <p className={styles.detailLead}>{post.excerpt}</p>}
        {post.body && <ArticleBody body={post.body} />}
        {post.externalUrl && (
          <p>
            <a href={post.externalUrl} target="_blank" rel="noopener noreferrer">
              Open the link <ArrowSquareOut size={15} aria-hidden="true" />
            </a>
          </p>
        )}
      </article>
    </MarketingChrome>
  );
}
