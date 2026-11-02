import { useEffect, useRef, useState, type FormEvent } from 'react';
import { useBlocker, useNavigate, useParams } from 'react-router-dom';
import { CheckCircle, Circle, FloppyDisk, Stack } from '@phosphor-icons/react';
import type { BillingCycle, FeatureKey, LimitKey, Plan, PlanInput, PlanStatus } from '@syniastrolms/domain';
import {
  BYTES_PER_GB,
  FEATURE_GROUPS,
  LIMIT_KEYS,
  annualSavingPercent,
  currencyDigits,
  minorToMajor,
  parseMajorAmount,
  reachablePlanStatuses,
  validatePlan,
} from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useViewport } from '@/hooks/useViewport';
import { plural } from '@/lib/format';
import { ChoiceCards, ErrorSummary, FormSection, Switch, type Choice, type FieldIssue } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { PlanStatusError, services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote, SUBS_BASE, cyclePer, limitLabel, money } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/** Which DOM id each validation issue points at, so the error summary can move focus to the field. */
const FIELD: Record<string, string> = {
  name: 'plan-name',
  description: 'plan-description',
  code: 'plan-code',
  monthlyPrice: 'plan-monthly',
  annualPrice: 'plan-annual',
  cycles: 'plan-cycle-monthly',
  trialDays: 'plan-trial-days',
  currency: 'plan-currency',
  limits: 'plan-limit-learners',
  features: 'plan-feature-courses-manage',
};

/** A catalogue key as a DOM id fragment: `live_classes.max` → `live-classes-max`. */
const idPart = (key: string) => key.replace(/[._]/g, '-');

/** Every status as a choice; the editor offers only those the plan can reach from where it stands. */
const STATUS_CHOICES: Choice<PlanStatus>[] = [
  { value: 'draft', label: 'Draft', description: 'Being written. It is not offered and cannot be bought.', icon: <Circle size={18} /> },
  { value: 'active', label: 'Active', description: 'Offered to new Admins and shown in the change-plan picker.', icon: <CheckCircle size={18} /> },
  { value: 'archived', label: 'Archived', description: 'Closed to new sign-ups. Admins already on it keep it.', icon: <Stack size={18} /> },
];

const EMPTY: PlanInput = {
  name: '',
  description: '',
  code: '',
  monthlyPrice: 0,
  annualPrice: 0,
  currency: 'INR',
  cycles: ['monthly', 'annual'],
  trialEnabled: true,
  trialDays: 14,
  limits: { 'learners.max': 250, 'instructors.max': 3, 'courses.max': 15, 'storage.bytes': 50 * BYTES_PER_GB, 'live_classes.max': 8, 'admin_accounts.max': 2 },
  features: ['courses.manage', 'assessments.manage'],
  status: 'draft',
  order: 0,
};

export default function PlanEditorPage() {
  const { planId } = useParams();
  const query = useAsync(`subs:plan-editor:${planId ?? 'new'}`, () =>
    Promise.all([planId ? services.subscriptions.getPlan(planId) : Promise.resolve(null), services.subscriptions.listPlans()]).then(([detail, list]) => ({
      detail,
      plans: list.rows.map((r) => r.plan),
    })),
  );
  usePageCrumbs(
    query.data?.detail
      ? [{ label: query.data.detail.plan.name, to: `${SUBS_BASE}/plans/${planId}` }, { label: 'Edit' }]
      : [{ label: planId ? 'Edit' : 'New plan' }],
  );

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.narrow}>
        {notFound ? (
          <StateMessage kind="error" title="Plan not found" actions={<LinkButton to={`${SUBS_BASE}/plans`}>Back to plans</LinkButton>}>
            This plan no longer exists. It may have been removed since the link was made.
          </StateMessage>
        ) : (
          <PlatformError title="The plan form didn’t load" error={query.error} onRetry={() => query.run().catch(() => undefined)} />
        )}
      </div>
    );
  }
  if (!query.data) {
    return (
      <div className={styles.narrow} aria-busy="true">
        <Skeleton width="40%" height={30} radius="var(--r-xs)" />
        <Skeleton height={560} radius="var(--r-lg)" />
      </div>
    );
  }

  const plan = query.data.detail?.plan ?? null;
  return (
    <Editor key={plan?.id ?? 'new'} plan={plan} others={query.data.plans.filter((p) => p.id !== plan?.id)} subscribers={query.data.detail?.subscribers ?? 0} />
  );
}

function Editor({ plan, others, subscribers }: { plan: Plan | null; others: Plan[]; subscribers: number }) {
  const navigate = useNavigate();
  const toast = useToast();
  const { isMobile } = useViewport();

  const initial: PlanInput = plan
    ? {
        name: plan.name,
        description: plan.description,
        code: plan.code,
        monthlyPrice: plan.monthlyPrice,
        annualPrice: plan.annualPrice,
        currency: plan.currency,
        cycles: [...plan.cycles],
        trialEnabled: plan.trialEnabled,
        trialDays: plan.trialDays || 14,
        limits: { ...plan.limits },
        features: [...plan.features],
        status: plan.status,
        order: plan.order,
      }
    : { ...EMPTY, order: others.length + 1, limits: { ...EMPTY.limits }, cycles: [...EMPTY.cycles], features: [...EMPTY.features] };

  const [form, setForm] = useState<PlanInput>(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const leaving = useRef(false);

  const set = <K extends keyof PlanInput>(key: K, value: PlanInput[K]) => setForm((f) => ({ ...f, [key]: value }));
  const setLimit = (key: LimitKey, value: number | null) => setForm((f) => ({ ...f, limits: { ...f.limits, [key]: value } }));
  const toggleFeature = (key: FeatureKey, on: boolean) => setForm((f) => ({ ...f, features: on ? [...f.features, key] : f.features.filter((k) => k !== key) }));
  const toggleCycle = (cycle: BillingCycle, on: boolean) =>
    setForm((f) => ({ ...f, cycles: on ? [...new Set([...f.cycles, cycle])] : f.cycles.filter((c) => c !== cycle) }));

  const dirty = JSON.stringify(form) !== JSON.stringify(initial);
  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !leaving.current && currentLocation.pathname !== nextLocation.pathname);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const all = validatePlan(
    form,
    others.map((p) => p.code),
  );
  const issues: FieldIssue[] = attempt ? all.map((i) => ({ field: FIELD[i.field], message: i.message })) : [];
  const errorFor = (field: keyof typeof FIELD) => issues.find((i) => i.field === FIELD[field])?.message;

  const readiness = [
    { done: form.name.trim().length >= 3 && form.description.trim().length >= 10, label: 'Named and described' },
    { done: /^[A-Z0-9][A-Z0-9-]{1,23}$/.test(form.code.trim().toUpperCase()), label: 'Has a unique plan code' },
    {
      // A cycle on sale is charged through the gateway, which cannot charge nothing.
      done: form.cycles.length > 0 && form.cycles.every((c) => (c === 'annual' ? form.annualPrice : form.monthlyPrice) > 0),
      label: 'Priced on every cycle offered',
    },
    { done: form.features.length > 0, label: 'At least one feature turned on' },
    { done: form.status === 'active', label: 'Set to Active so Admins can buy it' },
  ];

  const save = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setError(null);
    if (all.length) return;
    setSaving(true);
    try {
      const saved = plan ? await services.subscriptions.updatePlan(plan.id, form) : await services.subscriptions.createPlan(form);
      leaving.current = true;
      toast({
        kind: 'success',
        title: plan ? 'Plan saved' : `${saved.name} created`,
        text: saved.status === 'active' ? 'It is offered to new Admins from now on.' : 'Saved as a draft — nobody can buy it yet.',
      });
      navigate(`${SUBS_BASE}/plans/${saved.id}`, { replace: true });
    } catch (err) {
      if (err instanceof PlanStatusError) {
        // The terms were stored and only the status move was refused. A new plan now exists as a draft:
        // carry on from it, so saving again edits it rather than creating it a second time.
        leaving.current = true;
        toast({
          kind: 'error',
          title: plan ? 'Saved, but the status didn’t change' : `${err.plan.name} saved as a draft, not published`,
          text: err.message,
        });
        navigate(plan ? `${SUBS_BASE}/plans/${err.plan.id}` : `${SUBS_BASE}/plans/${err.plan.id}/edit`, { replace: true });
        return;
      }
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const actions = (
    <div className={styles.formActions}>
      <Button onClick={() => navigate(plan ? `${SUBS_BASE}/plans/${plan.id}` : `${SUBS_BASE}/plans`)} disabled={saving}>
        Cancel
      </Button>
      <Button type="submit" form="plan-form" variant="primary" loading={saving} iconStart={<FloppyDisk size={16} />}>
        {plan ? 'Save changes' : 'Create a plan'}
      </Button>
    </div>
  );

  const annualSaving = annualSavingPercent(form);
  const reachable = reachablePlanStatuses(plan?.status ?? null);

  return (
    <div className={styles.narrow}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        back={{ label: plan ? plan.name : 'Plans', to: plan ? `${SUBS_BASE}/plans/${plan.id}` : `${SUBS_BASE}/plans` }}
        title={plan ? 'Edit plan' : 'Create a plan'}
        description={
          plan && subscribers > 0
            ? `${plural(subscribers, 'academy', 'academies')} on this plan. Changing the price here does not re-bill anyone — it applies to new subscriptions.`
            : 'What an Admin gets and what it pays. Save it as a draft while you work on it.'
        }
      />
      <PrototypeNote>A demo plan: the change lasts until the page is reloaded.</PrototypeNote>

      <form id="plan-form" className={styles.form} onSubmit={save} noValidate>
        <ErrorSummary issues={issues} attempt={attempt} />
        {error && (
          <InlineMessage kind="error" title="Couldn’t save.">
            {error}
          </InlineMessage>
        )}

        <FormSection id="identity" title="Name and description" description="What the plan is called, and a short code used on invoices and reports.">
          <Field label="Plan name" error={errorFor('name')}>
            <Input id="plan-name" value={form.name} onChange={(e) => set('name', e.target.value)} placeholder="Growth" autoFocus={!plan} />
          </Field>
          <Field label="Short description" error={errorFor('description')} hint="One sentence on who the plan is for.">
            <Textarea id="plan-description" rows={2} value={form.description} onChange={(e) => set('description', e.target.value)} />
          </Field>
          <Field label="Internal plan code" error={errorFor('code')} hint="Capitals, digits and hyphens, e.g. GROWTH or PRO-2026. It has to be unique.">
            <Input id="plan-code" value={form.code} onChange={(e) => set('code', e.target.value.toUpperCase())} placeholder="GROWTH" spellCheck={false} />
          </Field>
        </FormSection>

        <FormSection id="pricing" title="Price" description="Whether Admins pay monthly, yearly or either, and what each costs.">
          <fieldset className={styles.fieldPair}>
            <legend className="sr-only">Billing cycles offered</legend>
            <Checkbox
              id="plan-cycle-monthly"
              label="Monthly"
              checked={form.cycles.includes('monthly')}
              onChange={(e) => toggleCycle('monthly', e.target.checked)}
            />
            <Checkbox label="Annual" checked={form.cycles.includes('annual')} onChange={(e) => toggleCycle('annual', e.target.checked)} />
          </fieldset>
          {errorFor('cycles') && <p className={styles.muted}>{errorFor('cycles')}</p>}

          <div className={styles.fieldPair}>
            <Field label="Monthly price" error={errorFor('monthlyPrice')} hint={form.cycles.includes('monthly') ? undefined : 'Not offered on this plan.'}>
              <PriceInput
                id="plan-monthly"
                amount={form.monthlyPrice}
                currency={form.currency}
                disabled={!form.cycles.includes('monthly')}
                onChange={(minor) => set('monthlyPrice', minor)}
              />
            </Field>
            <Field label="Annual price" error={errorFor('annualPrice')} hint={form.cycles.includes('annual') ? undefined : 'Not offered on this plan.'}>
              <PriceInput
                id="plan-annual"
                amount={form.annualPrice}
                currency={form.currency}
                disabled={!form.cycles.includes('annual')}
                onChange={(minor) => set('annualPrice', minor)}
              />
            </Field>
          </div>
          <Field label="Currency" hint="A subscription stays in the currency it was sold in.">
            <Select id="plan-currency" value={form.currency} onChange={(e) => set('currency', e.target.value)}>
              <option value="INR">Indian rupee (INR)</option>
            </Select>
          </Field>
          {form.cycles.includes('monthly') && form.cycles.includes('annual') && form.monthlyPrice > 0 && (
            <p className={styles.muted}>
              {money(form.monthlyPrice, form.currency)} {cyclePer('monthly')} · {money(form.annualPrice, form.currency)} {cyclePer('annual')}
              {annualSaving > 0 ? ` — paying yearly saves ${annualSaving}%.` : ' — paying yearly saves nothing at these prices.'}
            </p>
          )}
        </FormSection>

        <FormSection id="trial" title="Free trial" description="Days Admins can use the plan before paying anything.">
          <Switch
            checked={form.trialEnabled}
            onChange={(v) => set('trialEnabled', v)}
            label="Offer a free trial"
            description="New Admins start without paying."
          />
          <Field label="Trial length in days" error={errorFor('trialDays')} hint="Between 1 and 90 days.">
            <Input
              id="plan-trial-days"
              type="number"
              min={1}
              max={90}
              inputMode="numeric"
              value={form.trialDays}
              disabled={!form.trialEnabled}
              onChange={(e) => set('trialDays', Number(e.target.value))}
            />
          </Field>
        </FormSection>

        <FormSection
          id="limits"
          title="Limits"
          description="The most an Admin on this plan can have — for example students or storage. Tick Unlimited where there is no cap."
        >
          {errorFor('limits') && (
            <InlineMessage kind="error" title="Check the limits.">
              {errorFor('limits')}
            </InlineMessage>
          )}
          <div className={styles.limits}>
            {LIMIT_KEYS.map((key) => {
              const value = form.limits[key];
              // Storage is held in bytes and entered in GB; every other limit is a count.
              const scale = key === 'storage.bytes' ? BYTES_PER_GB : 1;
              return (
                <div key={key} className={styles.limitField}>
                  <Field label={`${limitLabel(key)}${scale === 1 ? '' : ' (GB)'}`}>
                    <Input
                      id={`plan-limit-${idPart(key.split('.')[0])}`}
                      type="number"
                      min={1}
                      inputMode="numeric"
                      value={value === null ? '' : value / scale}
                      disabled={value === null}
                      placeholder="Unlimited"
                      onChange={(e) => setLimit(key, e.target.value === '' ? null : Math.round(Number(e.target.value) * scale))}
                    />
                  </Field>
                  <Checkbox
                    label="Unlimited"
                    checked={value === null}
                    onChange={(e) => setLimit(key, e.target.checked ? null : (plan?.limits[key] ?? EMPTY.limits[key] ?? 1))}
                  />
                </div>
              );
            })}
          </div>
        </FormSection>

        <FormSection id="features" title="Features" description="Which parts of the LMS this plan switches on. Keep at least one.">
          {errorFor('features') && (
            <InlineMessage kind="error" title="Nothing is turned on.">
              {errorFor('features')}
            </InlineMessage>
          )}
          {FEATURE_GROUPS.map((group) => (
            <div key={group.id} className={styles.featureGroup}>
              <h3 className={styles.featureGroupTitle}>{group.label}</h3>
              {group.features.map((feature) => (
                <Switch
                  key={feature.key}
                  id={`plan-feature-${idPart(feature.key)}`}
                  checked={form.features.includes(feature.key)}
                  onChange={(v) => toggleFeature(feature.key, v)}
                  label={feature.label}
                  description={feature.description}
                />
              ))}
            </div>
          ))}
        </FormSection>

        <FormSection id="visibility" title="Who can buy it" description="Whether Admins can choose this plan today." aside={<Readiness items={readiness} />}>
          <ChoiceCards<PlanStatus>
            legend="Plan status"
            hideLegend
            value={form.status}
            onChange={(v) => set('status', v)}
            columns={1}
            choices={STATUS_CHOICES.filter((c) => reachable.includes(c.value))}
          />
          {plan && plan.status !== 'draft' && <p className={styles.muted}>A plan that has been offered never goes back to draft.</p>}
        </FormSection>

        {!isMobile && actions}
      </form>

      {isMobile && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{actions}</div>}>
          <span />
        </StickyActionBar>
      )}

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description="Your changes to this plan haven’t been saved."
        footer={
          <>
            <Button onClick={() => blocker.reset?.()}>Keep editing</Button>
            <Button variant="danger" onClick={() => blocker.proceed?.()}>
              Discard changes
            </Button>
          </>
        }
      />
    </div>
  );
}

function Readiness({ items }: { items: { done: boolean; label: string }[] }) {
  const done = items.filter((i) => i.done).length;
  return (
    <div>
      <p className={styles.factLabel}>
        Ready to offer · {done} of {items.length}
      </p>
      <ul className={styles.checklist}>
        {items.map((item) => (
          <li key={item.label} className={`${styles.checkItem} ${item.done ? styles.checkDone : ''}`}>
            {item.done ? <CheckCircle size={15} weight="fill" /> : <Circle size={15} />}
            <span>{item.label}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

/**
 * A price typed in rupees and kept in paise. The field holds exactly what was typed, so "3999.5" is
 * not rewritten under the cursor; the form receives the amount in minor units, parsed as text so no
 * floating-point multiply is involved, or NaN for text that is not an amount — which `validatePlan`
 * then refuses with the field's own message.
 */
function PriceInput({
  id,
  amount,
  currency,
  disabled,
  onChange,
}: {
  id: string;
  amount: number;
  currency: string;
  disabled: boolean;
  onChange: (minor: number) => void;
}) {
  const [text, setText] = useState(() => (Number.isFinite(amount) ? String(minorToMajor(amount, currency)) : ''));
  const digits = currencyDigits(currency);
  return (
    <Input
      id={id}
      type="number"
      min={0}
      step={digits === 0 ? 1 : 1 / 10 ** digits}
      inputMode={digits === 0 ? 'numeric' : 'decimal'}
      value={text}
      disabled={disabled}
      onChange={(e) => {
        setText(e.target.value);
        onChange(parseMajorAmount(e.target.value, currency) ?? Number.NaN);
      }}
    />
  );
}
