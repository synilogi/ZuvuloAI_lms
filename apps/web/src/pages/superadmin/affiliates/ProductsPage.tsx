import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAsync } from '@/hooks/useAsync';
import { plural } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { Button } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { AffiliateTabs, PLAN_PATH } from './affiliateMeta';
import styles from './Affiliates.module.css';

/**
 * Which courses generate CV (MLM-003): the active version's eligible list against the program's catalogue. The
 * one change an active version allows; everything else about the plan is a new version.
 */
export default function ProductsPage() {
  const toast = useToast();
  const products = useAsync('affiliates:products', () => services.affiliatesPlatform.products());
  const [chosen, setChosen] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const data = products.data;

  useEffect(() => {
    if (data?.active) setChosen(data.active.eligibleCourseIds);
  }, [data]);

  const dirty = data?.active ? [...chosen].sort().join() !== [...data.active.eligibleCourseIds].sort().join() : false;
  const toggle = (id: string, on: boolean) => setChosen((c) => (on ? [...new Set([...c, id])] : c.filter((x) => x !== id)));
  const save = async () => {
    setSaving(true);
    try {
      await services.affiliatesPlatform.setProducts(chosen);
      toast({ kind: 'success', title: 'Eligible courses saved', text: 'Verified purchases of these courses generate CV from now on.' });
      await products.run();
    } catch (err) {
      toast({ kind: 'error', title: 'Couldn’t save the courses', text: (err as Error).message });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Eligible courses"
        count={data?.active ? plural(data.active.eligibleCourseIds.length, 'course') : undefined}
        description="A verified purchase of an eligible course activates the buyer and credits its CV to every leg above them. Sales of other courses stay outside the program."
      />
      <AffiliateTabs />
      <PrototypeNote>A demo plan: changes last until the page is reloaded.</PrototypeNote>
      {products.status === 'error' && !data ? (
        <PlatformError title="The courses didn’t load" error={products.error} onRetry={() => void products.run().catch(() => undefined)} />
      ) : !data ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : !data.active ? (
        <StateMessage title="No plan version is active">
          Courses become eligible through the plan: write a version, name its courses and activate it. <Link to={PLAN_PATH}>Open the plan.</Link>
        </StateMessage>
      ) : (
        <section className={styles.panel} aria-labelledby="eligible-courses">
          <div className={styles.panelHead}>
            <div>
              <h2 id="eligible-courses" className={styles.panelTitle}>
                Version {data.active.version}
              </h2>
              <p className={styles.panelHint}>
                Tick the courses whose verified purchases count. A course without a price cannot be sold, so it cannot be ticked.
              </p>
            </div>
            <Button variant="primary" onClick={() => void save()} loading={saving} disabled={!dirty || chosen.length === 0}>
              Save
            </Button>
          </div>
          {chosen.length === 0 && (
            <InlineMessage kind="error" title="At least one course must stay eligible.">
              An active version with no eligible course would activate nobody and credit nothing.
            </InlineMessage>
          )}
          {data.courses.length === 0 ? (
            <p className={styles.muted}>The program has no courses yet.</p>
          ) : (
            <ul className={styles.courseList}>
              {data.courses.map((c) => (
                <li key={c.id} className={styles.courseRow}>
                  <Checkbox
                    label={c.title}
                    checked={chosen.includes(c.id)}
                    onChange={(e) => toggle(c.id, e.target.checked)}
                    disabled={c.priceAmount === null}
                  />
                  <span className={`${styles.muted} ${styles.nowrap}`}>
                    {c.priceAmount === null ? 'No price set' : `₹${c.priceAmount.toLocaleString('en-IN')}`}
                    {c.status !== 'published' && ` · ${c.status}`}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </section>
      )}
    </div>
  );
}
