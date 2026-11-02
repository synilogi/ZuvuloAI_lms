import { useState } from 'react';
import { funnelRates } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { Skeleton } from '@/components/ui/Feedback/Feedback';
import { Field, Select } from '@/components/ui/Field/Field';
import { useAsync } from '@/hooks/useAsync';
import { formatCount } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import styles from '../affiliates/Affiliates.module.css';

/** Who reaches the website, and where they stop (docs/19). Counts of pages and orders only: nothing here identifies anyone. */
export default function VisitorsPage() {
  const [days, setDays] = useState(30);
  const report = useAsync(`site:visitors:${days}`, () => services.site.visitors(days));
  if (report.status === 'error' && !report.data) {
    return <PlatformError title="The visitor figures didn’t load" error={report.error} onRetry={() => void report.run().catch(() => undefined)} />;
  }
  const data = report.data;
  const rates = data ? funnelRates(data.funnel) : [];
  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Visitors"
        description="How many people reach the website and how far they get. Counted without cookies, so nothing here identifies anyone. Bots and browsers that ask not to be tracked are left out."
      />
      <Field label="Period">
        <Select id="visitors-days" value={String(days)} onChange={(e) => setDays(Number(e.target.value))}>
          <option value="7">Last 7 days</option>
          <option value="30">Last 30 days</option>
          <option value="90">Last 90 days</option>
        </Select>
      </Field>
      {!data ? (
        <Skeleton height={320} radius="var(--r-lg)" />
      ) : (
        <>
          <section className={styles.panel} aria-labelledby="visitors-funnel">
            <h2 id="visitors-funnel" className={styles.panelTitle}>
              From visit to order
            </h2>
            <p className={styles.panelHint}>
              {data.from} to {data.to}. Each percentage is the share of the step above.
            </p>
            <div className={styles.tableWrap}>
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th>Step</th>
                    <th>Count</th>
                    <th>From the step above</th>
                  </tr>
                </thead>
                <tbody>
                  {data.funnel.map((step, i) => (
                    <tr key={step.label}>
                      <td>{step.label}</td>
                      <td>{formatCount(step.count)}</td>
                      <td>{rates[i] === null ? '–' : `${rates[i]}%`}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
          <section className={styles.panel} aria-labelledby="visitors-pages">
            <h2 id="visitors-pages" className={styles.panelTitle}>
              Most visited pages
            </h2>
            {data.topPages.length === 0 ? (
              <p className={styles.muted}>No visits counted in this period yet.</p>
            ) : (
              <div className={styles.tableWrap}>
                <table className={styles.table}>
                  <thead>
                    <tr>
                      <th>Page</th>
                      <th>Views</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.topPages.map((p) => (
                      <tr key={p.path}>
                        <td>{p.path}</td>
                        <td>{formatCount(p.views)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>
        </>
      )}
    </div>
  );
}
