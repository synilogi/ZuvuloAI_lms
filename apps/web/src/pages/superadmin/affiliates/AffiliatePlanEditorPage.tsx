import { useEffect, useRef, useState, type FormEvent } from 'react';
import { useBlocker, useNavigate, useParams } from 'react-router-dom';
import { FloppyDisk, Plus, Trash } from '@phosphor-icons/react';
import type { MlmCapBand, MlmPlanTerms, MlmPlanTermsInput, MlmProgramCourse, MlmRankTier } from '@syniastrolms/domain';
import {
  MLM_CAP_OVERFLOW_POLICIES,
  MLM_CARRY_FORWARD_POLICIES,
  MLM_MAX_CAP_BANDS,
  MLM_MAX_TIERS,
  MLM_REWARD_KINDS,
  MLM_SPILLOVER_RULES,
  minorToMajor,
  parseMajorAmount,
  validateMlmPlanTerms,
} from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { ErrorSummary, FormSection, Switch, type FieldIssue } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { useViewport } from '@/hooks/useViewport';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote } from '../subscriptions/subscriptionMeta';
import { CAP_OVERFLOW_LABEL, CARRY_FORWARD_LABEL, PLAN_PATH, REWARD_KIND_LABEL, SPILLOVER_LABEL, compactMoney, fieldId } from './affiliateMeta';
import styles from './Affiliates.module.css';

/**
 * Edits a draft version of the affiliate plan. Every term is validated by the domain's `validateMlmPlanTerms`, the
 * same rules the API applies, so what saves here is what the engines will run. Only drafts are editable: an active or
 * retired version is read on the plan page, and a change to it starts as a new draft.
 */
export default function AffiliatePlanEditorPage() {
  const { versionId = '' } = useParams();
  const query = useAsync(`affiliates:plan-editor:${versionId}`, () => services.affiliatesPlatform.getPlanVersion(versionId).then((terms) => ({ terms })));
  usePageCrumbs(
    query.data ? [{ label: `Version ${query.data.terms.version}`, to: `${PLAN_PATH}?version=${versionId}` }, { label: 'Edit' }] : [{ label: 'Edit' }],
  );

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.narrow}>
        {notFound ? (
          <StateMessage kind="error" title="Version not found" actions={<LinkButton to={PLAN_PATH}>Back to the plan</LinkButton>}>
            This version no longer exists. A deleted draft leaves no trace.
          </StateMessage>
        ) : (
          <PlatformError title="The plan editor didn’t load" error={query.error} onRetry={() => query.run().catch(() => undefined)} />
        )}
      </div>
    );
  }
  if (!query.data) {
    return (
      <div className={styles.narrow} aria-busy="true">
        <Skeleton width="40%" height={30} radius="var(--r-xs)" />
        <Skeleton height={640} radius="var(--r-lg)" />
      </div>
    );
  }
  if (query.data.terms.status !== 'draft') {
    return (
      <div className={styles.narrow}>
        <StateMessage
          kind="error"
          title={`Version ${query.data.terms.version} is ${query.data.terms.status}`}
          actions={<LinkButton to={`${PLAN_PATH}?version=${versionId}`}>View it</LinkButton>}
        >
          Only a draft can be edited. To change the plan, create a new draft from this version on the plan page.
        </StateMessage>
      </div>
    );
  }
  return <Editor key={versionId} version={query.data.terms} />;
}

const toInput = (v: MlmPlanTerms): MlmPlanTermsInput => ({
  programTenantId: v.programTenantId,
  eligibleCourseIds: [...v.eligibleCourseIds],
  currency: v.currency,
  cvBasisPoints: v.cvBasisPoints,
  matchingRateBps: v.matchingRateBps,
  payoutCeilingBps: v.payoutCeilingBps,
  normalPayoutBps: v.normalPayoutBps,
  matchingRunHourIst: v.matchingRunHourIst,
  cvEligibilityDelayDays: v.cvEligibilityDelayDays,
  capOverflowPolicy: v.capOverflowPolicy,
  carryForwardPolicy: v.carryForwardPolicy,
  carryExpiryDays: v.carryExpiryDays,
  spilloverRule: v.spilloverRule,
  withdrawalMinAmount: v.withdrawalMinAmount,
  withdrawalRequiresKyc: v.withdrawalRequiresKyc,
  tdsBps: v.tdsBps,
  liabilityPeriod: v.liabilityPeriod,
  note: v.note,
  capBands: v.capBands.map((b) => ({ ...b })),
  tiers: v.tiers.map((t) => ({ ...t })),
});

/** Basis points as the percentage typed: 1250 ↔ "12.5". An unreadable entry becomes NaN, which validation names. */
const bpsText = (bps: number): string => (Number.isFinite(bps) ? String(bps / 100) : '');
const bpsOfText = (text: string): number => {
  const n = Number(text.trim());
  return text.trim() === '' || !Number.isFinite(n) ? Number.NaN : Math.round(n * 100);
};
/** Minor units as the rupees typed: 500000 ↔ "5000". */
const rupeesText = (minor: number, currency: string): string => (Number.isFinite(minor) ? String(minorToMajor(minor, currency)) : '');
const minorOfText = (text: string, currency: string): number => (text.trim() === '' ? Number.NaN : (parseMajorAmount(text, currency) ?? Number.NaN));
const intOfText = (text: string): number => (text.trim() === '' ? Number.NaN : Number(text));

function Editor({ version }: { version: MlmPlanTerms }) {
  const navigate = useNavigate();
  const toast = useToast();
  const { isMobile } = useViewport();
  const initial = toInput(version);
  const [form, setForm] = useState<MlmPlanTermsInput>(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const leaving = useRef(false);
  const courses = useAsync(`affiliates:plan-courses:${form.programTenantId}`, () =>
    form.programTenantId ? services.affiliatesPlatform.programCourses(form.programTenantId) : Promise.resolve([] as MlmProgramCourse[]),
  );

  const set = <K extends keyof MlmPlanTermsInput>(key: K, value: MlmPlanTermsInput[K]) => setForm((f) => ({ ...f, [key]: value }));
  const setBand = (i: number, patch: Partial<MlmCapBand>) => setForm((f) => ({ ...f, capBands: f.capBands.map((b, j) => (j === i ? { ...b, ...patch } : b)) }));
  const setTier = (i: number, patch: Partial<MlmRankTier>) => setForm((f) => ({ ...f, tiers: f.tiers.map((t, j) => (j === i ? { ...t, ...patch } : t)) }));
  const renumber = (tiers: MlmRankTier[]) => tiers.map((t, i) => ({ ...t, order: i + 1 }));
  const toggleCourse = (id: string, on: boolean) =>
    setForm((f) => ({ ...f, eligibleCourseIds: on ? [...new Set([...f.eligibleCourseIds, id])] : f.eligibleCourseIds.filter((c) => c !== id) }));

  const dirty = JSON.stringify(form) !== JSON.stringify(initial);
  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !leaving.current && currentLocation.pathname !== nextLocation.pathname);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const all = validateMlmPlanTerms(form);
  const issues: FieldIssue[] = attempt ? all.map((i) => ({ field: fieldId(i.field), message: i.message })) : [];
  const errorFor = (field: string) => issues.find((i) => i.field === fieldId(field))?.message;

  const save = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setError(null);
    if (all.length) return;
    setSaving(true);
    try {
      const saved = await services.affiliatesPlatform.updatePlanVersion(version.id, form);
      leaving.current = true;
      toast({ kind: 'success', title: `Version ${saved.version} saved`, text: 'Still a draft. Activate it from the plan page when it is ready.' });
      navigate(`${PLAN_PATH}?version=${saved.id}`, { replace: true });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const currency = form.currency || 'INR';
  const actions = (
    <div className={styles.formActions}>
      <Button onClick={() => navigate(`${PLAN_PATH}?version=${version.id}`)} disabled={saving}>
        Cancel
      </Button>
      <Button type="submit" form="mlm-plan-form" variant="primary" loading={saving} iconStart={<FloppyDisk size={16} />}>
        Save draft
      </Button>
    </div>
  );

  return (
    <div className={styles.narrow}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        back={{ label: 'Affiliate plan', to: `${PLAN_PATH}?version=${version.id}` }}
        title={`Edit version ${version.version}`}
        description="Every compensation term of the program. Amounts are in whole rupees; rates in percent. The draft is checked as you type and saved only when every rule holds."
      />
      <PrototypeNote>A demo draft: the change lasts until the page is reloaded.</PrototypeNote>
      <form id="mlm-plan-form" className={styles.form} onSubmit={save} noValidate>
        <ErrorSummary issues={issues} attempt={attempt} />
        {error && (
          <InlineMessage kind="error" title="Couldn’t save.">
            {error}
          </InlineMessage>
        )}

        <FormSection
          id="program"
          title="Program"
          description="Which courses generate CV when sold. The program runs on the platform's one workspace (docs/16, D-PLAT-01)."
        >
          <Field
            label="Eligible courses"
            error={errorFor('eligibleCourseIds')}
            hint="A verified sale of one of these generates CV. Only a priced course can be sold."
          >
            {courses.status === 'error' ? (
              <p className={styles.issue}>The platform’s courses didn’t load.</p>
            ) : !courses.data ? (
              <Skeleton height={48} radius="var(--r-md)" />
            ) : courses.data.length === 0 ? (
              <p className={styles.muted}>The platform has no courses yet.</p>
            ) : (
              <ul className={styles.courseList} id={fieldId('eligibleCourseIds')}>
                {courses.data.map((c) => (
                  <li key={c.id} className={styles.courseRow}>
                    <Checkbox
                      label={c.title}
                      checked={form.eligibleCourseIds.includes(c.id)}
                      onChange={(e) => toggleCourse(c.id, e.target.checked)}
                      disabled={c.priceAmount === null}
                    />
                    <span className={`${styles.muted} ${styles.nowrap}`}>
                      {c.priceAmount === null ? 'No price set' : `₹${c.priceAmount.toLocaleString('en-IN')}`}
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </Field>
          <Field label="Note" optional error={errorFor('note')} hint="What this version changes and why, for the people who edit the plan.">
            <Textarea id={fieldId('note')} rows={2} value={form.note} onChange={(e) => set('note', e.target.value)} />
          </Field>
        </FormSection>

        <FormSection
          id="compensation"
          title="Compensation"
          description="CV is a share of each sale; matching pays a share of the weaker leg; the ceiling caps what the company pays out in a period."
        >
          <div className={styles.fieldRow}>
            <Field label="Currency" error={errorFor('currency')}>
              <Input id={fieldId('currency')} value={form.currency} maxLength={3} onChange={(e) => set('currency', e.target.value.toUpperCase())} />
            </Field>
            <Field label="CV per sale (%)" error={errorFor('cvBasisPoints')} hint="100 = the whole net amount">
              <Input
                id={fieldId('cvBasisPoints')}
                inputMode="decimal"
                value={bpsText(form.cvBasisPoints)}
                onChange={(e) => set('cvBasisPoints', bpsOfText(e.target.value))}
              />
            </Field>
            <Field label="Matching (%)" error={errorFor('matchingRateBps')} hint="of matched CV">
              <Input
                id={fieldId('matchingRateBps')}
                inputMode="decimal"
                value={bpsText(form.matchingRateBps)}
                onChange={(e) => set('matchingRateBps', bpsOfText(e.target.value))}
              />
            </Field>
            <Field label="Payout ceiling (%)" error={errorFor('payoutCeilingBps')} hint="of gross eligible sales">
              <Input
                id={fieldId('payoutCeilingBps')}
                inputMode="decimal"
                value={bpsText(form.payoutCeilingBps)}
                onChange={(e) => set('payoutCeilingBps', bpsOfText(e.target.value))}
              />
            </Field>
            <Field label="Normal payout (%)" error={errorFor('normalPayoutBps')} hint="planning figure, reported only">
              <Input
                id={fieldId('normalPayoutBps')}
                inputMode="decimal"
                value={bpsText(form.normalPayoutBps)}
                onChange={(e) => set('normalPayoutBps', bpsOfText(e.target.value))}
              />
            </Field>
          </div>
        </FormSection>

        <FormSection
          id="matching"
          title="Matching run, carry-forward and placement"
          description="When the daily run happens, when a sale’s CV starts counting, and what happens to volume the cap did not pay for."
        >
          <div className={styles.fieldRow}>
            <Field label="Run after (hour, IST)" error={errorFor('matchingRunHourIst')}>
              <Input
                id={fieldId('matchingRunHourIst')}
                inputMode="numeric"
                value={Number.isFinite(form.matchingRunHourIst) ? String(form.matchingRunHourIst) : ''}
                onChange={(e) => set('matchingRunHourIst', intOfText(e.target.value))}
              />
            </Field>
            <Field label="CV counts after (days)" error={errorFor('cvEligibilityDelayDays')} hint="0 = at once">
              <Input
                id={fieldId('cvEligibilityDelayDays')}
                inputMode="numeric"
                value={Number.isFinite(form.cvEligibilityDelayDays) ? String(form.cvEligibilityDelayDays) : ''}
                onChange={(e) => set('cvEligibilityDelayDays', intOfText(e.target.value))}
              />
            </Field>
          </div>
          <Field label="Matched volume above the daily cap" error={errorFor('capOverflowPolicy')}>
            <Select
              id={fieldId('capOverflowPolicy')}
              value={form.capOverflowPolicy}
              onChange={(e) => set('capOverflowPolicy', e.target.value as MlmPlanTermsInput['capOverflowPolicy'])}
            >
              {MLM_CAP_OVERFLOW_POLICIES.map((p) => (
                <option key={p} value={p}>
                  {CAP_OVERFLOW_LABEL[p]}
                </option>
              ))}
            </Select>
          </Field>
          <div className={styles.fieldRow}>
            <Field label="Unmatched strong-leg CV" error={errorFor('carryForwardPolicy')}>
              <Select
                id={fieldId('carryForwardPolicy')}
                value={form.carryForwardPolicy}
                onChange={(e) => {
                  const policy = e.target.value as MlmPlanTermsInput['carryForwardPolicy'];
                  setForm((f) => ({ ...f, carryForwardPolicy: policy, carryExpiryDays: policy === 'expire-days' ? (f.carryExpiryDays ?? 90) : null }));
                }}
              >
                {MLM_CARRY_FORWARD_POLICIES.map((p) => (
                  <option key={p} value={p}>
                    {CARRY_FORWARD_LABEL[p]}
                  </option>
                ))}
              </Select>
            </Field>
            {form.carryForwardPolicy === 'expire-days' && (
              <Field label="Expires after (days)" error={errorFor('carryExpiryDays')}>
                <Input
                  id={fieldId('carryExpiryDays')}
                  inputMode="numeric"
                  value={form.carryExpiryDays === null || !Number.isFinite(form.carryExpiryDays) ? '' : String(form.carryExpiryDays)}
                  onChange={(e) => set('carryExpiryDays', intOfText(e.target.value))}
                />
              </Field>
            )}
          </div>
          <Field label="Spillover" error={errorFor('spilloverRule')} hint="Where a referral goes when the sponsor’s chosen position is taken.">
            <Select
              id={fieldId('spilloverRule')}
              value={form.spilloverRule}
              onChange={(e) => set('spilloverRule', e.target.value as MlmPlanTermsInput['spilloverRule'])}
            >
              {MLM_SPILLOVER_RULES.map((r) => (
                <option key={r} value={r}>
                  {SPILLOVER_LABEL[r]}
                </option>
              ))}
            </Select>
          </Field>
        </FormSection>

        <FormSection id="withdrawals" title="Withdrawals" description="What an affiliate needs before money leaves the wallet.">
          <div className={styles.fieldRow}>
            <Field label={`Minimum withdrawal (${currency})`} error={errorFor('withdrawalMinAmount')}>
              <Input
                id={fieldId('withdrawalMinAmount')}
                inputMode="decimal"
                value={rupeesText(form.withdrawalMinAmount, currency)}
                onChange={(e) => set('withdrawalMinAmount', minorOfText(e.target.value, currency))}
              />
            </Field>
            <Field label="TDS at payout (%)" error={errorFor('tdsBps')} hint="0 until the company decides a rate">
              <Input id={fieldId('tdsBps')} inputMode="decimal" value={bpsText(form.tdsBps)} onChange={(e) => set('tdsBps', bpsOfText(e.target.value))} />
            </Field>
          </div>
          <Switch
            id={fieldId('withdrawalRequiresKyc')}
            checked={form.withdrawalRequiresKyc}
            onChange={(on) => set('withdrawalRequiresKyc', on)}
            label="Verified KYC required to withdraw"
            description="Earning does not need KYC; taking money out does."
          />
        </FormSection>

        <FormSection
          id="bands"
          title="Daily matching caps"
          description="Each rank points at a band; the band’s cap is the most matching income the rank earns in a day."
        >
          {errorFor('capBands') && <p className={styles.issue}>{errorFor('capBands')}</p>}
          <div className={styles.tableWrap}>
            <table className={styles.editTable}>
              <thead>
                <tr>
                  <th>Key</th>
                  <th className={styles.wide}>Label</th>
                  <th>Daily cap ({currency})</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {form.capBands.map((b, i) => (
                  <tr key={i}>
                    <td>
                      <Input
                        id={fieldId(`capBands.${i}.key`)}
                        aria-label={`Band ${i + 1} key`}
                        value={b.key}
                        onChange={(e) => setBand(i, { key: e.target.value.toLowerCase() })}
                      />
                      {errorFor(`capBands.${i}.key`) && <p className={styles.issue}>{errorFor(`capBands.${i}.key`)}</p>}
                    </td>
                    <td className={styles.wide}>
                      <Input
                        id={fieldId(`capBands.${i}.label`)}
                        aria-label={`Band ${i + 1} label`}
                        value={b.label}
                        onChange={(e) => setBand(i, { label: e.target.value })}
                      />
                      {errorFor(`capBands.${i}.label`) && <p className={styles.issue}>{errorFor(`capBands.${i}.label`)}</p>}
                    </td>
                    <td>
                      <Input
                        id={fieldId(`capBands.${i}.dailyCap`)}
                        aria-label={`Band ${i + 1} daily cap`}
                        inputMode="decimal"
                        value={rupeesText(b.dailyCap, currency)}
                        onChange={(e) => setBand(i, { dailyCap: minorOfText(e.target.value, currency) })}
                      />
                      {errorFor(`capBands.${i}.dailyCap`) && <p className={styles.issue}>{errorFor(`capBands.${i}.dailyCap`)}</p>}
                    </td>
                    <td className={styles.rowRemove}>
                      <Button
                        size="sm"
                        iconStart={<Trash size={14} />}
                        onClick={() =>
                          set(
                            'capBands',
                            form.capBands.filter((_, j) => j !== i),
                          )
                        }
                        disabled={form.capBands.length <= 1}
                      >
                        Remove
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className={styles.tableActions}>
            <Button
              size="sm"
              iconStart={<Plus size={14} />}
              disabled={form.capBands.length >= MLM_MAX_CAP_BANDS}
              onClick={() => set('capBands', [...form.capBands, { key: '', label: '', dailyCap: Number.NaN }])}
            >
              Add a band
            </Button>
          </div>
        </FormSection>

        <FormSection
          id="ranks"
          title="Ranks and rewards"
          description="In ascending order of group CV. Half of each rank’s group CV must come from the A leg and half from the B leg; excess on one leg never counts for the other."
        >
          {errorFor('tiers') && <p className={styles.issue}>{errorFor('tiers')}</p>}
          <div className={styles.tableWrap}>
            <table className={styles.editTable}>
              <thead>
                <tr>
                  <th>#</th>
                  <th className={styles.wide}>Rank</th>
                  <th>Group CV ({currency})</th>
                  <th>Reward</th>
                  <th>Amount</th>
                  <th>Up to</th>
                  <th>Cap band</th>
                  <th>Vesting (days)</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {form.tiers.map((t, i) => (
                  <tr key={i}>
                    <td className={styles.muted}>{t.order}</td>
                    <td className={styles.wide}>
                      <Input
                        id={fieldId(`tiers.${i}.name`)}
                        aria-label={`Rank ${i + 1} name`}
                        value={t.name}
                        onChange={(e) => setTier(i, { name: e.target.value })}
                      />
                      {errorFor(`tiers.${i}.name`) && <p className={styles.issue}>{errorFor(`tiers.${i}.name`)}</p>}
                    </td>
                    <td>
                      <Input
                        id={fieldId(`tiers.${i}.groupCv`)}
                        aria-label={`Rank ${i + 1} group CV`}
                        inputMode="decimal"
                        value={rupeesText(t.groupCv, currency)}
                        onChange={(e) => setTier(i, { groupCv: minorOfText(e.target.value, currency) })}
                      />
                      <p className={styles.muted}>{Number.isFinite(t.groupCv) ? `${compactMoney(t.groupCv / 2, currency)} per leg` : ''}</p>
                      {errorFor(`tiers.${i}.groupCv`) && <p className={styles.issue}>{errorFor(`tiers.${i}.groupCv`)}</p>}
                    </td>
                    <td>
                      <Select
                        id={fieldId(`tiers.${i}.rewardKind`)}
                        aria-label={`Rank ${i + 1} reward kind`}
                        value={t.rewardKind}
                        onChange={(e) => {
                          const kind = e.target.value as MlmRankTier['rewardKind'];
                          setTier(i, {
                            rewardKind: kind,
                            rewardAmount: kind === 'cash' ? t.rewardAmount : 0,
                            rewardCapAmount: kind === 'cash' ? t.rewardCapAmount : null,
                          });
                        }}
                      >
                        {MLM_REWARD_KINDS.map((k) => (
                          <option key={k} value={k}>
                            {REWARD_KIND_LABEL[k]}
                          </option>
                        ))}
                      </Select>
                    </td>
                    <td>
                      <Input
                        id={fieldId(`tiers.${i}.rewardAmount`)}
                        aria-label={`Rank ${i + 1} reward amount`}
                        inputMode="decimal"
                        disabled={t.rewardKind !== 'cash'}
                        value={t.rewardKind === 'cash' ? rupeesText(t.rewardAmount, currency) : ''}
                        onChange={(e) => setTier(i, { rewardAmount: e.target.value.trim() === '' ? 0 : minorOfText(e.target.value, currency) })}
                      />
                      {errorFor(`tiers.${i}.rewardAmount`) && <p className={styles.issue}>{errorFor(`tiers.${i}.rewardAmount`)}</p>}
                    </td>
                    <td>
                      <Input
                        id={fieldId(`tiers.${i}.rewardCapAmount`)}
                        aria-label={`Rank ${i + 1} reward up to`}
                        inputMode="decimal"
                        disabled={t.rewardKind !== 'cash'}
                        value={t.rewardCapAmount === null ? '' : rupeesText(t.rewardCapAmount, currency)}
                        onChange={(e) => setTier(i, { rewardCapAmount: e.target.value.trim() === '' ? null : minorOfText(e.target.value, currency) })}
                      />
                      {errorFor(`tiers.${i}.rewardCapAmount`) && <p className={styles.issue}>{errorFor(`tiers.${i}.rewardCapAmount`)}</p>}
                    </td>
                    <td>
                      <Select
                        id={fieldId(`tiers.${i}.capBandKey`)}
                        aria-label={`Rank ${i + 1} cap band`}
                        value={t.capBandKey}
                        onChange={(e) => setTier(i, { capBandKey: e.target.value })}
                      >
                        <option value="">Choose</option>
                        {form.capBands.map((b) => (
                          <option key={b.key} value={b.key}>
                            {b.label || b.key}
                          </option>
                        ))}
                      </Select>
                      {errorFor(`tiers.${i}.capBandKey`) && <p className={styles.issue}>{errorFor(`tiers.${i}.capBandKey`)}</p>}
                    </td>
                    <td>
                      <Input
                        id={fieldId(`tiers.${i}.vestingDays`)}
                        aria-label={`Rank ${i + 1} vesting days`}
                        inputMode="numeric"
                        value={Number.isFinite(t.vestingDays) ? String(t.vestingDays) : ''}
                        onChange={(e) => setTier(i, { vestingDays: intOfText(e.target.value) })}
                      />
                      {errorFor(`tiers.${i}.vestingDays`) && <p className={styles.issue}>{errorFor(`tiers.${i}.vestingDays`)}</p>}
                    </td>
                    <td className={styles.rowRemove}>
                      <Button
                        size="sm"
                        iconStart={<Trash size={14} />}
                        onClick={() => set('tiers', renumber(form.tiers.filter((_, j) => j !== i)))}
                        disabled={form.tiers.length <= 1}
                      >
                        Remove
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className={styles.tableActions}>
            <Button
              size="sm"
              iconStart={<Plus size={14} />}
              disabled={form.tiers.length >= MLM_MAX_TIERS}
              onClick={() =>
                set(
                  'tiers',
                  renumber([
                    ...form.tiers,
                    {
                      order: 0,
                      name: '',
                      groupCv: Number.NaN,
                      rewardKind: 'cash',
                      rewardAmount: Number.NaN,
                      rewardCapAmount: null,
                      capBandKey: form.capBands[form.capBands.length - 1]?.key ?? '',
                      vestingDays: 0,
                    },
                  ]),
                )
              }
            >
              Add a rank
            </Button>
          </div>
        </FormSection>

        {isMobile ? <StickyActionBar mobile={actions}>{actions}</StickyActionBar> : actions}
      </form>
      {blocker.state === 'blocked' && (
        <InlineMessage kind="error" title="You have unsaved changes.">
          <Button size="sm" onClick={() => blocker.reset?.()}>
            Keep editing
          </Button>{' '}
          <Button size="sm" variant="primary" onClick={() => blocker.proceed?.()}>
            Leave without saving
          </Button>
        </InlineMessage>
      )}
    </div>
  );
}
