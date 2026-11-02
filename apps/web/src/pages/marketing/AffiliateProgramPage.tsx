import { ArrowRight } from '@phosphor-icons/react';
import { Link } from 'react-router-dom';
import { formatMoney, type PublicAffiliateRank } from '@syniastrolms/domain';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useAsync } from '@/hooks/useAsync';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import { PageHero, SectionHead } from './SiteParts';
import styles from './Marketing.module.css';
import site from './Site.module.css';

/*
 * `/affiliate-program` (docs/16 §2.6, D-PLAT-13). It explains the rules and publishes the active plan's own terms, read
 * from the server. It says what a rank needs and what the plan pays for it, and never what anyone will or could earn.
 */

export const AFFILIATE_DISCLOSURE = [
  'Joining this program does not guarantee any income. What a member receives, if anything, depends on verified course sales, the volume on both legs and the plan rules in force.',
  'Commission comes only from verified course sales, not from enrolling people. A refund reverses the volume the sale earned. Please do not join on the strength of anyone else’s results or promises.',
];

const STEPS = [
  {
    title: 'Register with a sponsor link',
    text: 'A member shares their link with you. Its referral code names your sponsor, and you confirm your details with a code we send.',
  },
  {
    title: 'Buy an eligible course',
    text: 'Your membership activates when your payment for an eligible course is verified. It is a course purchase first: the course is yours to take.',
  },
  {
    title: 'Take your place in the network',
    text: 'Each member has two legs, A and B. New members are placed under their sponsor, and a full position spills over to the next open place below it.',
  },
  {
    title: 'Volume is counted',
    text: 'Each verified sale adds commission volume (CV) up your two legs. Unmatched volume carries forward as the plan sets out.',
  },
];

/** What a rank's reward is, in words. */
export function rewardLabel(rank: Pick<PublicAffiliateRank, 'rewardKind' | 'rewardAmount' | 'rewardCapAmount'>, currency: string): string {
  if (rank.rewardKind === 'recognition') return 'Recognition';
  if (rank.rewardKind === 'certificate') return 'Certificate';
  return rank.rewardCapAmount !== null ? `Up to ${formatMoney(rank.rewardCapAmount, currency)}` : formatMoney(rank.rewardAmount, currency);
}

export default function AffiliateProgramPage() {
  const query = useAsync('site:affiliate-program', () => services.site.affiliateProgram());
  const program = query.data;

  return (
    <MarketingChrome>
      <PageHero
        eyebrow="Affiliate program"
        title="How the affiliate program works"
        actions={
          <LinkButton to="/register" variant="primary" size="lg" iconEnd={<ArrowRight size={18} />}>
            Create your account
          </LinkButton>
        }
      >
        An optional program for people who want to recommend our courses. Read the rules and the published plan below before deciding whether it suits you.
      </PageHero>

      <section className={styles.section} aria-labelledby="affiliate-disclosure">
        <div className={site.disclosure}>
          <h2 id="affiliate-disclosure">Please read this first</h2>
          {AFFILIATE_DISCLOSURE.map((p) => (
            <p key={p}>{p}</p>
          ))}
        </div>
      </section>

      <section className={styles.section} aria-labelledby="affiliate-steps">
        <SectionHead id="affiliate-steps" title="From sign-up to activation" />
        <ol className={site.pointGrid}>
          {STEPS.map((s, i) => (
            <li key={s.title}>
              <span className={site.pointNumber} aria-hidden="true">
                {String(i + 1).padStart(2, '0')}
              </span>
              <h3>{s.title}</h3>
              <p>{s.text}</p>
            </li>
          ))}
        </ol>
      </section>

      <section className={styles.section} aria-labelledby="affiliate-plan">
        <SectionHead id="affiliate-plan" title="The current plan">
          These terms come directly from the plan in force, and the company can publish a new version.
        </SectionHead>
        {query.status === 'error' && !program ? (
          <StateMessage
            kind="error"
            title="The plan didn’t load"
            actions={
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            }
          >
            {query.error.message}
          </StateMessage>
        ) : !program ? (
          <Skeleton height={240} radius="var(--r-lg)" />
        ) : !program.active ? (
          <StateMessage title="No plan is published yet">
            The program’s terms will appear here when a plan is in force. <Link to="/contact">Contact us</Link> with any questions.
          </StateMessage>
        ) : (
          <>
            <dl className={site.terms}>
              {program.course && (
                <div>
                  <dt>Eligible course</dt>
                  <dd>
                    <Link to={`/courses/${program.course.slug}`}>{program.course.title}</Link>
                    {program.course.priceAmount !== null && ` · ₹${program.course.priceAmount.toLocaleString('en-IN')}`}
                  </dd>
                </div>
              )}
              <div>
                <dt>Matching rate on matched CV</dt>
                <dd>{program.matchingRateBps / 100}%</dd>
              </div>
              <div>
                <dt>Rank qualification</dt>
                <dd>Exact 50:50 across legs A and B</dd>
              </div>
              <div>
                <dt>Smallest withdrawal</dt>
                <dd>{formatMoney(program.withdrawalMinAmount, program.currency)}</dd>
              </div>
              <div>
                <dt>Identity check (KYC)</dt>
                <dd>{program.withdrawalRequiresKyc ? 'Needed before withdrawing' : 'Not needed to withdraw'}</dd>
              </div>
            </dl>
            {program.ranks.length > 0 && (
              <div className={site.tableWrap} tabIndex={0} role="region" aria-label="Ranks and rewards">
                <table className={site.rankTable}>
                  <caption className="sr-only">Each rank, the group volume it needs, its one-time reward and its daily matching limit</caption>
                  <thead>
                    <tr>
                      <th scope="col">Rank</th>
                      <th scope="col">Group CV needed</th>
                      <th scope="col">Reward</th>
                      <th scope="col">Daily matching limit</th>
                    </tr>
                  </thead>
                  <tbody>
                    {program.ranks.map((r) => (
                      <tr key={r.order}>
                        <th scope="row">{r.name}</th>
                        <td>{(r.groupCv / 100).toLocaleString('en-IN')} CV</td>
                        <td>{rewardLabel(r, program.currency)}</td>
                        <td>{formatMoney(r.dailyCap, program.currency)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
            <p className={styles.muted}>
              Limits are ceilings set by the plan, not amounts anyone should expect to receive. Rewards need approval by the company. Higher ranks need very
              large sales volumes, and many members may never reach them. Members agree to the <Link to="/terms">terms</Link> and{' '}
              <Link to="/refunds">refund policy</Link>.
            </p>
          </>
        )}
      </section>
    </MarketingChrome>
  );
}
