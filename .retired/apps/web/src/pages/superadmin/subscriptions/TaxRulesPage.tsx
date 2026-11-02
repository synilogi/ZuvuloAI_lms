import { useEffect, useState, type FormEvent } from 'react';
import { Archive, Percent, Plus, Trash } from '@phosphor-icons/react';
import type { TaxRule, TaxRuleInput } from '@syniastrolms/domain';
import { parseMajorAmount, taxRuleIssues } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { formatDate, plural } from '@/lib/format';
import { Switch } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { PrototypeNote, SubscriptionTabs, useListParams } from './subscriptionMeta';
import styles from './Subscriptions.module.css';

/** 1800 basis points read as "18%"; 950 as "9.5%". */
const ratePercent = (rateBps: number) => `${(rateBps / 100).toLocaleString('en-IN', { maximumFractionDigits: 2 })}%`;

/** Where a rule applies: "IN", or "IN · KA" for one region of it. */
const placeOf = (rule: Pick<TaxRule, 'country' | 'region'>) => (rule.region ? `${rule.country} · ${rule.region}` : `${rule.country} — whole country`);

/**
 * The tax charged on academy invoices, by country or region (subscriptions.md §25). A new rule for a place
 * retires the one already there; tax already charged keeps the rule it was charged under, so a retired rule
 * stays on the list as history.
 */
export default function TaxRulesPage() {
  const toast = useToast();
  const { params, update } = useListParams();
  const show = params.get('show') === 'all' ? 'all' : 'active';
  const [creating, setCreating] = useState(false);
  const [retiring, setRetiring] = useState<TaxRule | null>(null);

  const list = useAsync(`subs:tax-rules:${show}`, () => services.subscriptions.listTaxRules({ includeRetired: show === 'all' }));
  const rows = list.data ?? [];
  const reload = () => list.run().catch(() => undefined);

  const retire = async () => {
    if (!retiring) return;
    const rule = await services.subscriptions.retireTaxRule(retiring.id);
    setRetiring(null);
    toast({ kind: 'success', title: `${rule.name} retired`, text: `Invoices for ${placeOf(rule)} carry no tax from this rule from now on.` });
    await reload();
  };

  const columns: Column<TaxRule>[] = [
    {
      key: 'name',
      header: 'Tax',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.stack}>
          <span className={styles.cellTitle}>{r.name}</span>
          <span className={styles.cellMeta}>{placeOf(r)}</span>
        </span>
      ),
    },
    {
      key: 'components',
      header: 'Made up of',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.stack}>
          <span>{r.components.map((c) => `${c.code} ${ratePercent(c.rateBps)}`).join(' + ')}</span>
          <span className={styles.cellMeta}>
            {ratePercent(r.components.reduce((sum, c) => sum + c.rateBps, 0))} in all · {r.inclusive ? 'included in prices' : 'added to prices'}
          </span>
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      width: '120px',
      mobile: 'status',
      render: (r) =>
        r.retiredAt ? (
          <Badge size="sm" tone="neutral">
            Not in use
          </Badge>
        ) : (
          <Badge size="sm" tone="accent">
            In use
          </Badge>
        ),
    },
    {
      key: 'dates',
      header: 'Dates',
      width: '190px',
      mobile: 'detail',
      render: (r) => (
        <span className={styles.stack}>
          <span>Set {formatDate(r.createdAt)}</span>
          {r.retiredAt && <span className={styles.cellMeta}>Stopped {formatDate(r.retiredAt)}</span>}
        </span>
      ),
    },
    {
      key: 'actions',
      header: 'Actions',
      width: '110px',
      align: 'end',
      mobile: 'detail',
      render: (r) =>
        r.retiredAt ? null : (
          <Button size="sm" onClick={() => setRetiring(r)} iconStart={<Archive size={14} />}>
            Retire
          </Button>
        ),
    },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Tax"
        count={list.data ? plural(rows.length, 'rule') : undefined}
        description="The tax added to Admins’ invoices, such as GST. The right rule is picked from each Admin’s billing address. Adding a rule for a place replaces the one already there."
        actions={
          <Button variant="primary" onClick={() => setCreating(true)} iconStart={<Plus size={16} />}>
            Add tax rule
          </Button>
        }
      />
      <SubscriptionTabs />
      <PrototypeNote>Demo rules. No invoice is taxed by them.</PrototypeNote>

      <div className={styles.controls}>
        <SegmentedControl<'active' | 'all'>
          label="Show"
          value={show}
          onChange={(v) => update({ show: v === 'all' ? 'all' : undefined })}
          segments={[
            { value: 'active', label: 'In use' },
            { value: 'all', label: 'Include old rules' },
          ]}
        />
      </div>

      {list.status === 'error' && !list.data ? (
        <PlatformError title="Tax rules didn’t load" error={list.error} onRetry={reload} />
      ) : list.data && rows.length === 0 ? (
        <StateMessage
          icon={<Percent size={26} />}
          title="No tax rules"
          actions={
            <Button variant="primary" onClick={() => setCreating(true)} iconStart={<Plus size={16} />}>
              Add tax rule
            </Button>
          }
        >
          Without a rule for an Admin’s country, its invoices carry no tax.
        </StateMessage>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Tax rules"
            rows={rows}
            columns={columns}
            rowKey={(r) => r.id}
            rowLabel={(r) => `${r.name} — ${placeOf(r)}`}
            loading={!list.data}
            skeletonRows={3}
          />
        </div>
      )}

      <TaxRuleDialog
        open={creating}
        onClose={() => setCreating(false)}
        onSaved={async (rule) => {
          setCreating(false);
          toast({
            kind: 'success',
            title: `${rule.name} set for ${placeOf(rule)}`,
            text: 'New invoices there are taxed by it. Any rule it replaced is retired.',
          });
          await reload();
        }}
      />
      <ConfirmDialog
        open={Boolean(retiring)}
        onClose={() => setRetiring(null)}
        onConfirm={retire}
        tone="danger"
        icon={<Archive size={20} />}
        title={`Retire ${retiring?.name}?`}
        description={retiring ? placeOf(retiring) : undefined}
        confirmLabel="Retire rule"
      >
        New invoices for this place carry no tax from this rule until another is set. Invoices already issued keep the tax they were charged.
      </ConfirmDialog>
    </div>
  );
}

interface ComponentRow {
  code: string;
  label: string;
  /** The rate as typed, in per cent: "9" or "9.5". */
  rate: string;
}

const emptyComponent = (): ComponentRow => ({ code: '', label: '', rate: '' });

/** A per-cent rate typed to at most two decimals, as whole basis points: "9.5" is 950. NaN for anything else. */
const toBps = (rate: string) => parseMajorAmount(rate, 'INR') ?? Number.NaN;

function TaxRuleDialog({ open, onClose, onSaved }: { open: boolean; onClose: () => void; onSaved: (rule: TaxRule) => void | Promise<void> }) {
  const [name, setName] = useState('');
  const [country, setCountry] = useState('IN');
  const [region, setRegion] = useState('');
  const [inclusive, setInclusive] = useState(false);
  const [components, setComponents] = useState<ComponentRow[]>([emptyComponent()]);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setName('GST');
    setCountry('IN');
    setRegion('');
    setInclusive(false);
    setComponents([{ code: 'GST', label: 'Goods and Services Tax', rate: '18' }]);
    setAttempt(0);
    setError(null);
  }, [open]);

  const input: TaxRuleInput = {
    name: name.trim(),
    country: country.trim().toUpperCase(),
    ...(region.trim() ? { region: region.trim().toUpperCase() } : {}),
    inclusive,
    components: components.map((c) => ({ code: c.code.trim().toUpperCase(), label: c.label.trim(), rateBps: toBps(c.rate) })),
  };
  const issues = taxRuleIssues(input);
  const setComponent = (i: number, next: Partial<ComponentRow>) => setComponents((all) => all.map((c, j) => (j === i ? { ...c, ...next } : c)));

  const save = async (e?: FormEvent) => {
    e?.preventDefault();
    setAttempt((a) => a + 1);
    setError(null);
    if (issues.length) return;
    setSaving(true);
    try {
      await onSaved(await services.subscriptions.createTaxRule(input));
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={saving ? () => undefined : onClose}
      title="Add tax rule"
      description="The tax for a country, or one region of it. It replaces the rule in force there."
      icon={<Percent size={20} />}
      width={620}
      footer={
        <>
          <Button onClick={onClose} disabled={saving}>
            Cancel
          </Button>
          <Button variant="primary" type="submit" form="tax-rule-form" loading={saving}>
            Set rule
          </Button>
        </>
      }
    >
      <form id="tax-rule-form" className={styles.dialogBody} onSubmit={save} noValidate>
        {attempt > 0 && issues.length > 0 && (
          <InlineMessage kind="error" title="Fix these first">
            {issues.join(' ')}
          </InlineMessage>
        )}
        {error && (
          <InlineMessage kind="error" title="Couldn’t set the rule.">
            {error}
          </InlineMessage>
        )}
        <Field label="Name" hint="As it appears on an invoice, e.g. GST.">
          <Input value={name} onChange={(e) => setName(e.target.value)} maxLength={80} />
        </Field>
        <div className={styles.fieldPair}>
          <Field label="Country" hint="Two letters, e.g. IN.">
            <Input value={country} onChange={(e) => setCountry(e.target.value.toUpperCase())} maxLength={2} spellCheck={false} />
          </Field>
          <Field label="Region" optional hint="A short code, e.g. KA. Leave empty for the whole country.">
            <Input value={region} onChange={(e) => setRegion(e.target.value.toUpperCase())} maxLength={10} spellCheck={false} />
          </Field>
        </div>
        <Switch
          checked={inclusive}
          onChange={setInclusive}
          label="Prices already include this tax"
          description="Off: the tax is added on top of the plan price. On: it is taken out of it."
        />
        <fieldset className={styles.dialogBody}>
          <legend className={styles.factLabel}>Components · {components.length} of 5</legend>
          {components.map((c, i) => (
            <div key={i} className={styles.fieldPair}>
              <Field label="Code" hideLabel={i > 0}>
                <Input value={c.code} onChange={(e) => setComponent(i, { code: e.target.value.toUpperCase() })} maxLength={16} placeholder="CGST" />
              </Field>
              <Field label="Label" hideLabel={i > 0}>
                <Input value={c.label} onChange={(e) => setComponent(i, { label: e.target.value })} maxLength={80} placeholder="Central GST" />
              </Field>
              <Field label="Rate (%)" hideLabel={i > 0}>
                <Input
                  type="number"
                  min={0}
                  max={100}
                  step={0.01}
                  inputMode="decimal"
                  value={c.rate}
                  onChange={(e) => setComponent(i, { rate: e.target.value })}
                />
              </Field>
              {components.length > 1 && (
                <IconButton
                  size="sm"
                  label={`Remove ${c.code || 'component'}`}
                  icon={<Trash size={16} />}
                  onClick={() => setComponents((all) => all.filter((_, j) => j !== i))}
                />
              )}
            </div>
          ))}
          {components.length < 5 && (
            <Button size="sm" onClick={() => setComponents((all) => [...all, emptyComponent()])} iconStart={<Plus size={14} />}>
              Add component
            </Button>
          )}
        </fieldset>
        <p className={styles.muted}>
          {Number.isFinite(input.components.reduce((s, c) => s + c.rateBps, 0))
            ? `${ratePercent(input.components.reduce((s, c) => s + c.rateBps, 0))} in all.`
            : 'Enter each rate as a percentage, to at most two decimal places.'}{' '}
          Invoices already issued keep the tax they were charged.
        </p>
      </form>
    </Modal>
  );
}
