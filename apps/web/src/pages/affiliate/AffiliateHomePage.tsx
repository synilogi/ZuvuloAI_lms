import { useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { CheckCircle, Copy, Handshake, ShareNetwork } from '@phosphor-icons/react';
import type { AffiliateActivation, AffiliateMe, MlmLeg } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, ServiceError } from '@/services';
import { AffiliateNav } from './affiliateNav';
import { FiguresPanel } from './AffiliateVolumePage';
import styles from './Affiliate.module.css';

/*
 * The learner's affiliate home (MLM-001): their code, referral link and QR, who referred them, where their own
 * referrals go, what activates them — the eligible course — and their legs' volume (MLM-003). A learner outside the
 * program opts in here. Later modules add earnings and the wallet.
 */
export default function AffiliateHomePage() {
  const me = useAsync('affiliate:me', () => services.affiliate.me());
  if (me.status === 'error' && me.data === undefined) {
    return (
      <div className={styles.page}>
        <PageHeader title="Affiliate program" />
        <StateMessage
          kind="error"
          title="The affiliate program didn’t load"
          actions={<Button onClick={() => me.run().catch(() => undefined)}>Try again</Button>}
        >
          {me.error?.message}
        </StateMessage>
      </div>
    );
  }
  if (me.data === undefined) {
    return (
      <div className={styles.page} aria-busy="true">
        <PageHeader title="Affiliate program" />
        <Skeleton height={220} radius="var(--r-lg)" />
      </div>
    );
  }
  return me.data ? <AffiliateHome me={me.data} reload={() => me.run().catch(() => undefined)} /> : <OptIn onJoined={() => me.run().catch(() => undefined)} />;
}

const STATUS_LABEL: Record<AffiliateMe['status'], { label: string; tone: 'neutral' | 'accent' | 'warn' | 'danger'; meaning: string }> = {
  pending: { label: 'Not yet active', tone: 'neutral', meaning: 'Buy the eligible course to activate your account and start earning on your team.' },
  active: { label: 'Active', tone: 'accent', meaning: 'Your account earns matching income and counts towards ranks.' },
  suspended: { label: 'Suspended', tone: 'warn', meaning: 'Your account is paused by the platform. Contact support.' },
  terminated: { label: 'Closed', tone: 'danger', meaning: 'Your affiliate account has been closed.' },
};

function AffiliateHome({ me, reload }: { me: AffiliateMe; reload: () => void }) {
  const toast = useToast();
  const activation = useAsync('affiliate:activation', () => services.affiliate.activation());
  const figures = useAsync('affiliate:figures', () => services.affiliate.figures());
  const [savingLeg, setSavingLeg] = useState(false);
  const status = STATUS_LABEL[me.status];

  const copy = async (text: string, what: string) => {
    try {
      await navigator.clipboard.writeText(text);
      toast({ kind: 'success', title: `${what} copied` });
    } catch {
      toast({ kind: 'error', title: `Couldn’t copy the ${what.toLowerCase()}`, text: 'Select it and copy it by hand.' });
    }
  };
  const share = async () => {
    const data = { title: `Join ${me.academy.name}`, text: `Join ${me.academy.name} with my link`, url: me.referralLink };
    if (typeof navigator.share === 'function') {
      try {
        await navigator.share(data);
        return;
      } catch {
        /* cancelled: fall through to copying */
      }
    }
    await copy(me.referralLink, 'Referral link');
  };
  const chooseLeg = async (leg: MlmLeg) => {
    if (leg === me.preferredLeg) return;
    setSavingLeg(true);
    try {
      await services.affiliate.setPreferredLeg(leg);
      toast({ kind: 'success', title: `New referrals go to leg ${leg}` });
      reload();
    } catch (err) {
      toast({ kind: 'error', title: 'Couldn’t change the leg', text: (err as Error).message });
    } finally {
      setSavingLeg(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={
          <>
            <Handshake size={13} weight="fill" aria-hidden="true" /> {me.academy.name}
          </>
        }
        title="Affiliate program"
        description="Share your link. Everyone who joins through it is placed in your team, and their verified course purchases build your A and B legs."
        meta={<Badge tone={status.tone}>{status.label}</Badge>}
      />
      <AffiliateNav />
      {!me.programActive && (
        <InlineMessage kind="info" title="The program isn’t running yet.">
          You can share your link and build your team now. Earnings start once the platform activates the plan.
        </InlineMessage>
      )}
      <section className={styles.panel} aria-labelledby="volume">
        <div className={styles.panelHead}>
          <h2 id="volume" className={styles.panelTitle}>
            Your legs
          </h2>
          <Link to="/affiliate/volume">See the ledger</Link>
        </div>
        {figures.status === 'error' ? (
          <p className={styles.muted}>Couldn’t load your figures: {figures.error?.message}</p>
        ) : !figures.data ? (
          <Skeleton height={96} radius="var(--r-md)" />
        ) : (
          <FiguresPanel figures={figures.data} />
        )}
      </section>
      <div className={styles.grid}>
        <section className={styles.panel} aria-labelledby="referral">
          <h2 id="referral" className={styles.panelTitle}>
            Your referral link
          </h2>
          <div className={styles.referralCard}>
            <img
              className={styles.qr}
              src={me.qrUrl.startsWith('data:') ? me.qrUrl : services.affiliate.qrUrl(me.code)}
              alt={`QR code for your referral link ${me.referralLink}`}
            />
            <div className={styles.referralText}>
              <div>
                <p className={styles.muted}>Your code</p>
                <p className={styles.code}>{me.code}</p>
              </div>
              <div className={styles.linkRow}>
                <Input readOnly value={me.referralLink} aria-label="Referral link" onFocus={(e) => e.currentTarget.select()} />
                <Button iconStart={<Copy size={16} />} onClick={() => void copy(me.referralLink, 'Referral link')}>
                  Copy
                </Button>
              </div>
              <div className={styles.linkRow}>
                <Button variant="primary" iconStart={<ShareNetwork size={16} />} onClick={() => void share()}>
                  Share
                </Button>
                <Button onClick={() => void copy(me.code, 'Code')}>Copy code</Button>
              </div>
              <p className={styles.muted}>Anyone who opens the link joins {me.academy.name} with you as their sponsor, on your preferred leg.</p>
              <div>
                <p className={styles.muted}>Links for one leg</p>
                <div className={styles.linkRow}>
                  <Input readOnly value={me.legLinks.A} aria-label="Link for leg A" onFocus={(e) => e.currentTarget.select()} />
                  <Button iconStart={<Copy size={16} />} onClick={() => void copy(me.legLinks.A, 'Leg A link')}>
                    Copy A
                  </Button>
                </div>
                <div className={styles.linkRow}>
                  <Input readOnly value={me.legLinks.B} aria-label="Link for leg B" onFocus={(e) => e.currentTarget.select()} />
                  <Button iconStart={<Copy size={16} />} onClick={() => void copy(me.legLinks.B, 'Leg B link')}>
                    Copy B
                  </Button>
                </div>
              </div>
              <p className={styles.muted}>
                Someone who joins through one of these goes on that leg, whatever your preferred leg is. If the place directly under you is taken, they go
                deeper in the same leg.
              </p>
            </div>
          </div>
        </section>

        <section className={styles.panel} aria-labelledby="placement">
          <h2 id="placement" className={styles.panelTitle}>
            Your place in the network
          </h2>
          <dl className={styles.facts}>
            <div className={styles.fact}>
              <dt className={styles.factLabel}>Sponsor</dt>
              <dd className={styles.factValue}>{me.sponsor ? `${me.sponsor.name} · ${me.sponsor.code}` : 'None'}</dd>
            </div>
            <div className={styles.fact}>
              <dt className={styles.factLabel}>Placed under</dt>
              <dd className={styles.factValue}>{me.placement ? `${me.placement.parentCode} · leg ${me.placement.leg}` : 'Not placed yet'}</dd>
            </div>
            <div className={styles.fact}>
              <dt className={styles.factLabel}>Status</dt>
              <dd className={styles.factValue}>{status.label}</dd>
            </div>
          </dl>
          <p className={styles.panelHint}>{status.meaning}</p>
          <div>
            <p className={styles.muted}>Where your new referrals are placed</p>
            <SegmentedControl<MlmLeg>
              label="Preferred leg"
              value={me.preferredLeg}
              onChange={(leg) => void chooseLeg(leg)}
              segments={[
                { value: 'A', label: 'A / Left' },
                { value: 'B', label: 'B / Right' },
              ]}
            />
            {savingLeg && <p className={styles.muted}>Saving…</p>}
          </div>
        </section>

        <section className={styles.panel} aria-labelledby="activation">
          <h2 id="activation" className={styles.panelTitle}>
            Activation
          </h2>
          <ActivationCard me={me} activation={activation.data} error={activation.status === 'error' ? activation.error : undefined} />
        </section>
      </div>
    </div>
  );
}

function ActivationCard({ me, activation, error }: { me: AffiliateMe; activation?: AffiliateActivation; error?: Error }) {
  if (error) return <p className={styles.muted}>Couldn’t load the eligible course: {error.message}</p>;
  if (!activation) return <Skeleton height={80} radius="var(--r-md)" />;
  if (me.status === 'active')
    return (
      <p className={styles.panelHint}>
        <CheckCircle size={16} weight="fill" aria-hidden="true" /> Active since {new Date(me.activatedAt ?? me.createdAt).toLocaleDateString('en-IN')}.
      </p>
    );
  if (!activation.programActive || activation.courses.length === 0)
    return <p className={styles.panelHint}>The platform hasn’t named the eligible course yet.</p>;
  return (
    <>
      <p className={styles.panelHint}>
        Buy one of these courses with a verified payment to activate your account. Your purchase also counts as CV for the people above you.
      </p>
      {activation.courses.map((c) => (
        <div key={c.id} className={styles.courseRow}>
          <div>
            <p className={styles.factValue}>{c.title}</p>
            <p className={styles.muted}>{c.priceAmount === null ? 'Not on sale yet' : `₹${c.priceAmount.toLocaleString('en-IN')}`}</p>
          </div>
          {c.purchase === 'enrolled' || c.purchase === 'paid' ? (
            <Badge tone="accent">Bought</Badge>
          ) : c.purchase === 'pending' ? (
            <Badge tone="warn">Payment in progress</Badge>
          ) : (
            <LinkButton variant="primary" to={`/learn/${c.id}`}>
              Buy the course
            </LinkButton>
          )}
        </div>
      ))}
    </>
  );
}

/** A learner not yet in the program: join with a sponsor's code, or without one. */
function OptIn({ onJoined }: { onJoined: () => void }) {
  const toast = useToast();
  const [code, setCode] = useState('');
  const [leg, setLeg] = useState<MlmLeg>('A');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string>();

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(undefined);
    try {
      await services.affiliate.enrol({ referralCode: code.trim() || undefined, preferredLeg: leg });
      toast({ kind: 'success', title: 'You’re in the affiliate program', text: 'Share your link to start building your team.' });
      onJoined();
    } catch (err) {
      setError(
        err instanceof ServiceError && err.reason === 'REFERRAL_INVALID'
          ? 'That code isn’t valid. Check it with the person who gave it to you, or leave it blank.'
          : (err as Error).message,
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Affiliate program"
        description="Earn by introducing learners. Share your link; everyone who joins through it is placed in your two-leg team, and their verified course purchases build your income."
      />
      <div className={styles.narrow}>
        <section className={styles.panel}>
          <h2 className={styles.panelTitle}>How it works</h2>
          <ol className={styles.steps}>
            <li>Join the program and get your own referral link and code.</li>
            <li>Buy the eligible course to activate your account.</li>
            <li>Share your link. New learners are placed in your A or B leg.</li>
            <li>Matching income is paid on the weaker leg’s verified sales; ranks reward balanced growth.</li>
          </ol>
        </section>
        <form className={`${styles.panel} ${styles.form}`} onSubmit={submit} noValidate>
          <h2 className={styles.panelTitle}>Join</h2>
          {error && (
            <InlineMessage kind="error" title="Couldn’t join.">
              {error}
            </InlineMessage>
          )}
          <Field label="Sponsor’s code" optional hint="If someone introduced you, enter their 8-character code. Otherwise leave it blank.">
            <Input
              id="affiliate-sponsor-code"
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="ABCD2345"
              autoCapitalize="characters"
              spellCheck={false}
              maxLength={12}
            />
          </Field>
          <div className={styles.legChoice}>
            <SegmentedControl<MlmLeg>
              label="Where your referrals go"
              value={leg}
              onChange={setLeg}
              segments={[
                { value: 'A', label: 'A / Left' },
                { value: 'B', label: 'B / Right' },
              ]}
            />
          </div>
          <div>
            <Button type="submit" variant="primary" loading={submitting}>
              Join the program
            </Button>
          </div>
          <p className={styles.muted}>
            By joining you agree to the <Link to="/terms">Terms of Service</Link>. Income depends on verified sales and is not guaranteed.
          </p>
        </form>
      </div>
    </div>
  );
}
