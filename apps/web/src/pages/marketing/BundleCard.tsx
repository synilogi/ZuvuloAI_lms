import { Link } from 'react-router-dom';
import { ArrowRight, Clock, Stack } from '@phosphor-icons/react';
import type { PublicBundle } from '@syniastrolms/domain';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { formatDuration, formatINR, plural } from '@/lib/format';
import { siteImageSrc } from './siteImage';
import styles from './Home.module.css';

/** A bundle's cover: its own image, or the covers of its first courses side by side. */
export function BundleCover({ bundle, className }: { bundle: PublicBundle; className?: string }) {
  const src = siteImageSrc(bundle.coverUrl);
  if (src) return <img src={src} alt="" loading="lazy" className={`${styles.bundleCoverImage} ${className ?? ''}`} />;
  return (
    <div className={`${styles.bundleMosaic} ${className ?? ''}`} aria-hidden="true">
      {bundle.courses.slice(0, 2).map((c) => (
        <CourseCover key={c.id} motif={c.coverMotif as never} imageUrl={c.coverImageUrl} className={styles.bundleMosaicTile} />
      ))}
    </div>
  );
}

/** The price, with what the courses cost apart struck through when that is more. */
export function BundlePrice({ bundle }: { bundle: PublicBundle }) {
  const saving = bundle.separatePrice - bundle.price;
  return (
    <p className={styles.bundlePrice}>
      <strong>{formatINR(bundle.price)}</strong>
      {saving > 0 && (
        <>
          <s>{formatINR(bundle.separatePrice)}</s>
          <span>Save {formatINR(saving)}</span>
        </>
      )}
    </p>
  );
}

export function BundleCard({ bundle, headingLevel: Heading = 'h3' }: { bundle: PublicBundle; headingLevel?: 'h2' | 'h3' }) {
  return (
    <li className={styles.bundleCard}>
      <BundleCover bundle={bundle} className={styles.bundleCardCover} />
      <div className={styles.bundleCardBody}>
        <Heading className={styles.bundleCardTitle}>
          <Link to={`/bundles/${bundle.slug}`}>{bundle.title}</Link>
        </Heading>
        <p className={styles.bundleFacts}>
          <span>
            <Stack size={15} aria-hidden="true" /> {plural(bundle.courseCount, 'course')}
          </span>
          {bundle.durationMin > 0 && (
            <span>
              <Clock size={15} aria-hidden="true" /> {formatDuration(bundle.durationMin)}
            </span>
          )}
        </p>
        {bundle.summary && <p className={styles.bundleSummary}>{bundle.summary}</p>}
        <BundlePrice bundle={bundle} />
        <span className={styles.bundleExplore}>
          Explore bundle <ArrowRight size={15} aria-hidden="true" />
        </span>
      </div>
    </li>
  );
}
