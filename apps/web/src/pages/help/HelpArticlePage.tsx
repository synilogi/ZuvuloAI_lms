import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { ArrowLeft, ThumbsDown, ThumbsUp } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { formatDate } from '@/lib/format';
import { PageHeader, SectionHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { ArticleBody } from '@/components/lms/content/ArticleBody';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { ArticleRow } from './HelpCenterPage';
import { AudienceBadge, readTime, useHelpBase } from './helpMeta';
import styles from './Help.module.css';

/** One guide: the full text, then a quick "was this helpful" and a few related articles. */
export default function HelpArticlePage() {
  const { slug } = useParams();
  const base = useHelpBase();
  const toast = useToast();
  const [feedback, setFeedback] = useState<'helpful' | 'not-helpful' | null>(null);

  const query = useAsync(`help-article:${slug}`, () => services.help.getArticle(slug!));
  const data = query.data?.article.slug === slug ? query.data : undefined;
  usePageCrumbs(
    data
      ? [{ label: 'Help Centre', to: base }, { label: data.categoryName, to: `${base}/${data.article.categoryId}` }, { label: data.article.title }]
      : [{ label: 'Help Centre', to: base }],
  );

  if (query.status === 'error' && !data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.narrowPage}>
        <StateMessage
          kind="error"
          title={notFound ? 'This article doesn’t exist' : 'The article didn’t load'}
          actions={
            <LinkButton to={base} variant="primary" iconStart={<ArrowLeft size={16} />}>
              Back to the Help Centre
            </LinkButton>
          }
        >
          {notFound ? 'It may have moved, or the address may be mistyped.' : query.error.message}
        </StateMessage>
      </div>
    );
  }

  if (!data) {
    return (
      <div className={styles.narrowPage} aria-busy="true">
        <Skeleton width="35%" height={14} />
        <Skeleton width="80%" height={34} radius="var(--r-xs)" />
        <Skeleton height={320} radius="var(--r-lg)" />
      </div>
    );
  }

  const { article, categoryName, related } = data;

  const sendFeedback = (value: 'helpful' | 'not-helpful') => {
    setFeedback(value);
    toast({
      kind: 'success',
      title: value === 'helpful' ? 'Thanks — glad that helped' : 'Thanks for the feedback',
      text: value === 'helpful' ? undefined : 'We’ll use this to improve the article.',
    });
  };

  return (
    <div className={styles.narrowPage}>
      <PageHeader
        back={{ label: categoryName, to: `${base}/${article.categoryId}` }}
        title={article.title}
        description={article.summary}
        meta={
          <span className={styles.articleFacts}>
            {readTime(article.readMinutes)} · Updated {formatDate(article.updatedAt)}
            <AudienceBadge audience={article.audience} />
          </span>
        }
      />

      <article className={styles.articleCard}>
        <ArticleBody body={article.body} />
      </article>

      <div className={styles.feedbackCard} role="group" aria-label="Was this article helpful?">
        <span className={styles.feedbackLabel}>Was this article helpful?</span>
        <div className={styles.feedbackButtons}>
          <Button
            size="sm"
            variant={feedback === 'helpful' ? 'primary' : 'secondary'}
            iconStart={<ThumbsUp size={15} weight={feedback === 'helpful' ? 'fill' : 'regular'} />}
            disabled={feedback !== null}
            onClick={() => sendFeedback('helpful')}
          >
            Yes
          </Button>
          <Button
            size="sm"
            variant={feedback === 'not-helpful' ? 'primary' : 'secondary'}
            iconStart={<ThumbsDown size={15} weight={feedback === 'not-helpful' ? 'fill' : 'regular'} />}
            disabled={feedback !== null}
            onClick={() => sendFeedback('not-helpful')}
          >
            Not really
          </Button>
        </div>
        {feedback && <span className={styles.feedbackThanks}>Thanks for letting us know.</span>}
      </div>

      {related.length > 0 && (
        <section aria-labelledby="help-related-title">
          <SectionHeader id="help-related-title" title={`More on ${categoryName.toLowerCase()}`} />
          <ul className={styles.articleList}>
            {related.map((r) => (
              <ArticleRow key={r.article.id} row={r} to={`${base}/article/${r.article.slug}`} />
            ))}
          </ul>
        </section>
      )}
    </div>
  );
}
