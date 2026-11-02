import { useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, CheckCircle, Minus } from '@phosphor-icons/react';
import type { BillingCycle, Plan, PublicPlanCatalogue } from '@syniastrolms/domain';
import { PlanOfferCard, PlanOfferNote } from '@/components/plan/PlanOfferCard';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useAsync } from '@/hooks/useAsync';
import { offeredCycles } from '@/pages/onboarding/welcomeFlow';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import { FAQS } from './siteContent';
import { CtaBanner, FaqList, PageHero, SectionHead } from './SiteParts';
import { bestAnnualSaving, compareRows, ordered, planCta } from './pricing';
import styles from './Marketing.module.css';

/** The billing questions, for the pricing page's own FAQ. */
const PRICING_FAQS = FAQS.filter((f) => /trial|pay|tax|change plans|cancel|limits/i.test(f.q));

export const usePublicPlans = () => useAsync('public-plans', () => services.signup.plans());

/** The tax line under the plans, from the server's rule. */
const taxNote = (tax: PublicPlanCatalogue['tax']) =>
  !tax
    ? 'Prices are in INR.'
    : tax.inclusive
      ? `Prices include ${tax.name}.`
      : `Prices are before tax; ${tax.name} at ${tax.rateBps / 100}% is added at checkout for Indian billing addresses.`;

/** The plans on sale, with the cycle toggle and each plan's way to start. Used by the pricing page and the home page. */
function PlanCards({
  plans,
  cycle,
  onCycle,
  showToggle = true,
}: {
  plans: Plan[];
  cycle: BillingCycle;
  onCycle: (c: BillingCycle) => void;
  showToggle?: boolean;
}) {
  const cycles = offeredCycles(plans);
  const saving = bestAnnualSaving(plans);
  return (
    <>
      {showToggle && cycles.length > 1 && (
        <div className={styles.pricingControls}>
          <SegmentedControl<BillingCycle>
            label="Billing cycle"
            value={cycle}
            onChange={onCycle}
            segments={[
              { value: 'monthly', label: 'Monthly' },
              { value: 'annual', label: saving ? `Annual — save up to ${saving}%` : 'Annual' },
            ]}
          />
        </div>
      )}
      <ul className={styles.planGrid}>
        {plans.map((p) => {
          const cta = planCta(p, cycle);
          return (
            <PlanOfferCard
              key={p.id}
              plan={p}
              cycle={cycle}
              actions={
                cta.kind === 'start' ? (
                  <>
                    <LinkButton to={cta.to} variant="primary" block>
                      {cta.label}
                    </LinkButton>
                    <PlanOfferNote>
                      {p.trialEnabled && p.trialDays > 0 ? 'No payment needed to start.' : 'Activated once your payment is confirmed.'}
                    </PlanOfferNote>
                  </>
                ) : (
                  <Button block onClick={() => onCycle(cta.cycle)}>
                    {cta.label}
                  </Button>
                )
              }
            />
          );
        })}
      </ul>
    </>
  );
}

function PlansLoading() {
  return (
    <div className={styles.planGrid} role="status" aria-label="Loading the plans">
      {[0, 1, 2].map((i) => (
        <Skeleton key={i} height={420} radius="var(--r-lg)" />
      ))}
    </div>
  );
}

function PlansError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <StateMessage
      kind="error"
      title="The plans didn’t load"
      actions={
        <>
          <Button variant="primary" onClick={onRetry}>
            Try again
          </Button>
          <LinkButton to="/contact?topic=sales">Ask our team</LinkButton>
        </>
      }
    >
      {message}
    </StateMessage>
  );
}

/** The home page's pricing section: the first three plans on sale, monthly, with a link to the rest. The page owns the request, so its hero reads the same plans. */
export function PlanTeaser({ catalogue }: { catalogue: ReturnType<typeof usePublicPlans> }) {
  const [cycle, setCycle] = useState<BillingCycle>('monthly');
  if (catalogue.status === 'error' && !catalogue.data)
    return <PlansError message={catalogue.error?.message ?? 'Something went wrong.'} onRetry={() => catalogue.run().catch(() => undefined)} />;
  if (!catalogue.data) return <PlansLoading />;
  const plans = ordered(catalogue.data.plans)
    .filter((p) => p.cycles.includes('monthly'))
    .slice(0, 3);
  if (!plans.length) return null;
  return (
    <>
      <PlanCards plans={plans} cycle={cycle} onCycle={setCycle} showToggle={false} />
      <LinkButton to="/pricing" variant="ghost" iconEnd={<ArrowRight size={16} />}>
        Compare every plan
      </LinkButton>
    </>
  );
}

/** `/pricing`: every plan on sale, priced by the server, with a full comparison and the billing questions. */
export default function PricingPage() {
  const catalogue = usePublicPlans();
  const [cycle, setCycle] = useState<BillingCycle>('monthly');
  const plans = catalogue.data ? ordered(catalogue.data.plans) : [];
  const rows = compareRows(plans);

  return (
    <MarketingChrome>
      <PageHero eyebrow="Pricing" title="Plans for every size of school">
        Start with a free trial on most plans. Upgrade the moment you need more — you pay only the difference for the rest of your period.
      </PageHero>

      <section className={styles.section} aria-label="Plans">
        {catalogue.status === 'error' && !catalogue.data ? (
          <PlansError message={catalogue.error?.message ?? 'Something went wrong.'} onRetry={() => catalogue.run().catch(() => undefined)} />
        ) : !catalogue.data ? (
          <PlansLoading />
        ) : plans.length === 0 ? (
          <StateMessage title="Plans are being updated" actions={<LinkButton to="/contact?topic=sales">Talk to sales</LinkButton>}>
            No plan is on sale right now. Our team will set you up directly.
          </StateMessage>
        ) : (
          <>
            <PlanCards plans={plans} cycle={cycle} onCycle={setCycle} />
            <p className={styles.pricingNote}>
              {taxNote(catalogue.data.tax)} Need something else? <Link to="/contact?topic=sales">Talk to sales</Link>.
            </p>
          </>
        )}
      </section>

      {plans.length > 0 && (
        <section className={styles.section} aria-labelledby="compare-heading">
          <SectionHead id="compare-heading" title="Compare plans" />
          <div className={styles.compareWrap} tabIndex={0} role="region" aria-labelledby="compare-heading">
            <table className={styles.compareTable}>
              <thead>
                <tr>
                  <th scope="col">
                    <span className="sr-only">Plan</span>
                  </th>
                  {plans.map((p) => (
                    <th key={p.id} scope="col">
                      {p.name}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rows.limits.map((r) => (
                  <tr key={r.label}>
                    <th scope="row">{r.label}</th>
                    {r.cells.map((c, i) => (
                      <td key={plans[i].id}>{c}</td>
                    ))}
                  </tr>
                ))}
                {rows.features.map((r) => (
                  <tr key={r.label}>
                    <th scope="row">{r.label}</th>
                    {r.cells.map((c, i) => (
                      <td key={plans[i].id}>
                        {c ? (
                          <CheckCircle size={18} weight="fill" className={styles.yes} role="img" aria-label="Included" />
                        ) : (
                          <Minus size={18} className={styles.no} role="img" aria-label="Not included" />
                        )}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      <section className={styles.section} aria-labelledby="pricing-faq">
        <SectionHead id="pricing-faq" title="Billing questions" />
        <FaqList faqs={PRICING_FAQS} />
      </section>

      <CtaBanner title="Not sure which plan fits?">
        Start on a free trial and change plans any time, or tell us about your LMS and we’ll recommend one.
      </CtaBanner>
    </MarketingChrome>
  );
}
