import { Skeleton } from '@/components/ui/Feedback/Feedback';
import styles from './Pages.module.css';

export function PageLoading() {
  return (
    <div className={styles.loading} role="status" aria-label="Loading page">
      <Skeleton width={140} height={22} />
      <Skeleton width="62%" height={34} radius="var(--r-sm)" />
      <Skeleton width="48%" height={14} />
      <Skeleton width="100%" height={180} radius="var(--r-lg)" className={styles.loadingBlock} />
    </div>
  );
}
