import { useState } from 'react';
import { CheckCircle, Copy, PlugsConnected, Receipt } from '@phosphor-icons/react';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { formatDate } from '@/lib/format';
import { purchaseAmount } from '@/lib/coursePricing';
import { ChoiceCards, FormSection, Switch, type FieldIssue } from '@/components/forms/Forms';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { services, ServiceError, type CourseSaleRow, type CourseSalesSettings, type GatewayEnvironment } from '@/services';
import { API_BASE_URL } from '@/services/http/client';
import {
  SALE_STATUS,
  blankKeys,
  environmentBlocker,
  keyInputId,
  keyIssues,
  keyPayload,
  needsReviewCount,
  webhookAddress,
  type KeyValues,
} from './coursePaymentsMeta';
import styles from './Settings.module.css';
import own from './CoursePayments.module.css';

const ENVIRONMENTS: GatewayEnvironment[] = ['test', 'live'];
const ENV_LABEL: Record<GatewayEnvironment, string> = { test: 'Test', live: 'Live' };

/**
 * Settings › Course payments: the academy's own Razorpay account, which learners' payments for its paid courses settle
 * to. Keys are entered per environment and never shown again; the server checks every payment with Razorpay before a
 * course opens.
 */
export default function CoursePaymentsSettingsPage() {
  const { can } = usePermissions();
  const editable = can('settings.edit');
  const query = useAsync('course-sales-settings', () => services.courseSales.settings());
  const [latest, setLatest] = useState<CourseSalesSettings | null>(null);
  const settings = latest ?? query.data;

  if (query.status === 'error' && !settings) {
    return (
      <StateMessage
        kind="error"
        title="Course payments didn’t load"
        actions={
          <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
            Try again
          </Button>
        }
      >
        {query.error.message}
      </StateMessage>
    );
  }
  if (!settings) {
    return (
      <div className={styles.skeleton} aria-busy="true" aria-label="Loading course payments">
        <Skeleton width="30%" height={22} radius="var(--r-xs)" />
        <Skeleton height={160} radius="var(--r-md)" />
        <Skeleton height={220} radius="var(--r-md)" />
      </div>
    );
  }

  return (
    <div className={own.stack}>
      <div className={styles.form}>
        <header className={styles.formHead}>
          <h2 className={styles.formTitle}>Course payments</h2>
          <p className={styles.formDescription}>
            Sell paid courses through your own Razorpay account: learners’ payments go straight to it. A paid course opens to a learner only after the payment
            is confirmed with Razorpay.
          </p>
        </header>

        {settings.ready ? (
          <InlineMessage kind="success" title="Learners can buy paid courses.">
            Payments are taken in {settings.environment === 'live' ? 'live mode — real money' : 'test mode — no real money'}.
          </InlineMessage>
        ) : (
          <InlineMessage kind="warn" title="Learners can’t buy paid courses yet.">
            {settings.notReadyReason ?? 'Save your Razorpay keys and turn payments on.'}
          </InlineMessage>
        )}
        {!settings.storageConfigured && (
          <InlineMessage kind="error" title="Keys can’t be saved on this server yet.">
            Secure storage for payment keys isn’t configured. Contact ZuviloAI support.
          </InlineMessage>
        )}
        {!editable && <p className={styles.muted}>Read only — you don’t have permission to change settings.</p>}

        <PaymentSwitch settings={settings} editable={editable} onSaved={setLatest} />

        <FormSection
          id="course-sales-keys"
          title="Razorpay keys"
          description="From Razorpay Dashboard › Account & Settings › API Keys. Test and live keys are kept apart. Secrets are never shown again — leave a secret blank to keep the saved one."
        >
          <div className={own.slots}>
            {ENVIRONMENTS.map((env) => (
              <KeyPanel key={env} environment={env} settings={settings} editable={editable} onSaved={setLatest} />
            ))}
          </div>
        </FormSection>

        <WebhookSection settings={settings} />
      </div>

      <SalesList />
    </div>
  );
}

/* ─── On / off, and test or live ─── */

function PaymentSwitch({ settings, editable, onSaved }: { settings: CourseSalesSettings; editable: boolean; onSaved: (s: CourseSalesSettings) => void }) {
  const toast = useToast();
  const [enabled, setEnabled] = useState(settings.enabled);
  const [environment, setEnvironment] = useState<GatewayEnvironment>(settings.environment);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string>();
  const dirty = enabled !== settings.enabled || environment !== settings.environment;
  const blocker = environmentBlocker(settings, environment, enabled);

  const save = async () => {
    setSaving(true);
    setError(undefined);
    try {
      const next = await services.courseSales.update({ enabled, environment });
      onSaved(next);
      toast({ kind: 'success', title: enabled ? 'Course payments are on' : 'Course payments are off', text: `${ENV_LABEL[environment]} mode.` });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <FormSection id="course-sales-mode" title="Payments" description="Turn online payment for paid courses on or off, and choose which keys new purchases use.">
      <Switch
        checked={enabled}
        disabled={!editable}
        onChange={setEnabled}
        label="Take online payments for paid courses"
        description="Off: learners can’t buy paid courses. Free courses are not affected."
      />
      <ChoiceCards<GatewayEnvironment>
        legend="Mode for new purchases"
        columns={2}
        value={environment}
        onChange={(v) => editable && setEnvironment(v)}
        choices={[
          { value: 'test', label: 'Test', description: 'Razorpay test keys. No real money moves.', disabled: !editable },
          { value: 'live', label: 'Live', description: 'Razorpay live keys. Learners pay real money.', disabled: !editable },
        ]}
      />
      {blocker && <p className={styles.fieldNote}>{blocker}</p>}
      {error && (
        <InlineMessage kind="error" title="Not saved.">
          {error}
        </InlineMessage>
      )}
      {editable && (
        <div>
          <Button variant="primary" onClick={() => void save()} loading={saving} disabled={!dirty || saving || Boolean(blocker)}>
            Save payment settings
          </Button>
        </div>
      )}
    </FormSection>
  );
}

/* ─── One environment's keys ─── */

function KeyPanel({
  environment,
  settings,
  editable,
  onSaved,
}: {
  environment: GatewayEnvironment;
  settings: CourseSalesSettings;
  editable: boolean;
  onSaved: (s: CourseSalesSettings) => void;
}) {
  const toast = useToast();
  const slot = settings.credentials[environment];
  const [values, setValues] = useState<KeyValues>(() => blankKeys(settings));
  const [attempt, setAttempt] = useState(0);
  const [serverIssues, setServerIssues] = useState<FieldIssue[]>([]);
  const [saving, setSaving] = useState(false);
  const [testing, setTesting] = useState(false);
  const [result, setResult] = useState<{ ok: boolean; detail: string } | null>(null);
  const [error, setError] = useState<string>();
  const issues = [...(attempt > 0 ? keyIssues(settings, environment, values) : []), ...serverIssues];
  const errorFor = (key: string) => issues.find((i) => i.field === keyInputId(environment, key))?.message;
  const typed = Object.values(values).some((v) => v.trim());

  const save = async () => {
    setAttempt((a) => a + 1);
    setServerIssues([]);
    setError(undefined);
    setResult(null);
    if (keyIssues(settings, environment, values).length) return;
    setSaving(true);
    try {
      const next = await services.courseSales.saveCredentials(environment, keyPayload(values));
      // What was typed is dropped once sent: no secret stays in the page.
      setValues(blankKeys(settings));
      setAttempt(0);
      onSaved(next);
      toast({ kind: 'success', title: `${ENV_LABEL[environment]} keys saved` });
    } catch (err) {
      const fields = err instanceof ServiceError ? (err.issues ?? []) : [];
      const known = fields.filter((i) => settings.fields.some((f) => f.key === i.field));
      if (known.length) setServerIssues(known.map((i) => ({ field: keyInputId(environment, i.field), message: i.message })));
      else setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const test = async () => {
    setTesting(true);
    setResult(null);
    setError(undefined);
    try {
      setResult(await services.courseSales.test(environment));
    } catch (err) {
      setResult({ ok: false, detail: (err as Error).message });
    } finally {
      setTesting(false);
    }
  };

  return (
    <section className={own.slot} aria-labelledby={`course-sales-${environment}-title`}>
      <div className={own.slotHead}>
        <h3 id={`course-sales-${environment}-title`} className={own.slotTitle}>
          {ENV_LABEL[environment]} keys
        </h3>
        <Badge size="sm" tone={slot.configured ? 'accent' : 'neutral'} icon={slot.configured ? <CheckCircle size={13} /> : undefined}>
          {slot.configured ? 'Saved' : 'Not saved'}
        </Badge>
      </div>
      {slot.configured && (
        <p className={styles.muted}>
          Key id {slot.keyIdHint ?? 'saved'}
          {slot.updatedAt ? ` · updated ${formatDate(slot.updatedAt)}` : ''}
        </p>
      )}
      {settings.fields.map((field) => (
        <Field
          key={field.key}
          label={field.label}
          error={errorFor(field.key)}
          hint={field.secret ? (slot.configured ? 'Saved. Leave blank to keep it.' : field.help) : field.help}
        >
          <Input
            id={keyInputId(environment, field.key)}
            type={field.secret ? 'password' : 'text'}
            autoComplete="off"
            spellCheck={false}
            disabled={!editable}
            value={values[field.key] ?? ''}
            placeholder={field.secret && slot.configured ? '••••••••••••' : field.key === 'keyId' ? (slot.keyIdHint ?? `rzp_${environment}_…`) : ''}
            onChange={(e) => setValues((v) => ({ ...v, [field.key]: e.target.value }))}
          />
        </Field>
      ))}
      {error && (
        <InlineMessage kind="error" title="Not saved.">
          {error}
        </InlineMessage>
      )}
      {result && (
        <InlineMessage kind={result.ok ? 'success' : 'error'} title={result.ok ? 'Connection works.' : 'Connection failed.'}>
          {result.detail}
        </InlineMessage>
      )}
      {editable && (
        <div className={own.actions}>
          <Button
            variant={slot.configured ? 'secondary' : 'primary'}
            onClick={() => void save()}
            loading={saving}
            disabled={saving || (slot.configured && !typed)}
          >
            {slot.configured ? `Replace ${environment} keys` : `Save ${environment} keys`}
          </Button>
          <Button iconStart={<PlugsConnected size={16} />} onClick={() => void test()} loading={testing} disabled={!slot.configured || testing}>
            Test connection
          </Button>
        </div>
      )}
    </section>
  );
}

/* ─── The webhook ─── */

function WebhookSection({ settings }: { settings: CourseSalesSettings }) {
  const toast = useToast();
  const url = webhookAddress(API_BASE_URL, settings.webhookPath);
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(url);
      toast({ kind: 'success', title: 'Webhook URL copied' });
    } catch {
      toast({ kind: 'error', title: 'Couldn’t copy the URL', text: url });
    }
  };
  return (
    <FormSection
      id="course-sales-webhook"
      title="Webhook"
      description="In Razorpay Dashboard › Account & Settings › Webhooks, add this URL with your webhook secret, and choose the payment events (payment.authorized, payment.captured, payment.failed). It lets a payment open the course even if the learner closes the page."
    >
      <div className={own.webhook}>
        <code className={own.url}>{url}</code>
        <Button size="sm" iconStart={<Copy size={15} />} onClick={() => void copy()}>
          Copy
        </Button>
      </div>
      <p className={styles.fieldNote}>The same URL serves test and live; each is checked with its own webhook secret.</p>
    </FormSection>
  );
}

/* ─── Sales ─── */

const saleColumns: Column<CourseSaleRow>[] = [
  { key: 'course', header: 'Course', mobile: 'primary', render: (r) => r.courseTitle },
  {
    key: 'status',
    header: 'Status',
    mobile: 'status',
    render: (r) => (
      <span className={own.badges}>
        <Badge size="sm" tone={SALE_STATUS[r.status].tone}>
          {SALE_STATUS[r.status].label}
        </Badge>
        {r.reviewReason && (
          <Badge size="sm" tone="warn" title={r.reviewReason}>
            Needs review
          </Badge>
        )}
      </span>
    ),
  },
  {
    key: 'learner',
    header: 'Learner',
    mobile: 'meta',
    render: (r) => (
      <span>
        {r.learner.name}
        <span className={own.sub}>{r.learner.email}</span>
      </span>
    ),
  },
  { key: 'amount', header: 'Amount', align: 'end', mobile: 'meta', render: (r) => <span className="tabular">{purchaseAmount(r)}</span> },
  { key: 'date', header: 'Date', mobile: 'meta', render: (r) => (r.paidAt ? `Paid ${formatDate(r.paidAt)}` : `Ordered ${formatDate(r.createdAt)}`) },
  { key: 'mode', header: 'Mode', mobile: 'detail', render: (r) => (r.environment === 'live' ? 'Live' : r.environment === 'test' ? 'Test' : r.environment) },
  {
    key: 'order',
    header: 'Razorpay order',
    mobile: 'detail',
    render: (r) => (
      <span className={own.mono}>
        {r.providerOrderId}
        {r.providerPaymentId ? <span className={own.sub}>{r.providerPaymentId}</span> : null}
      </span>
    ),
  },
  { key: 'review', header: 'Review', mobile: 'detail', render: (r) => r.reviewReason ?? '—' },
];

function SalesList() {
  const query = useAsync('course-sales-rows', () => services.courseSales.purchases());
  const rows = query.data ?? [];
  const review = needsReviewCount(rows);
  return (
    <section className={styles.form} aria-labelledby="course-sales-title">
      <header className={styles.formHead}>
        <h2 id="course-sales-title" className={styles.formTitle}>
          Course sales
        </h2>
        <p className={styles.formDescription}>The latest 200 orders for your paid courses, newest first. Refunds are made in your Razorpay dashboard.</p>
      </header>
      {review > 0 && (
        <InlineMessage kind="warn" title={`${review === 1 ? 'One payment needs' : `${review} payments need`} review.`}>
          Money arrived that opened nothing new — for example a learner who already had the course. Check it in Razorpay and refund it if needed.
        </InlineMessage>
      )}
      {query.status === 'error' && !query.data ? (
        <InlineMessage
          kind="error"
          title="The sales didn’t load."
          action={
            <Button size="sm" onClick={() => query.run().catch(() => undefined)}>
              Retry
            </Button>
          }
        >
          {query.error.message}
        </InlineMessage>
      ) : (
        <DataTable
          rows={rows}
          columns={saleColumns}
          rowKey={(r) => r.id}
          label="Course sales"
          rowLabel={(r) => `${r.courseTitle} · ${r.learner.name}`}
          loading={!query.data}
          empty={
            <StateMessage kind="empty" icon={<Receipt size={26} />} title="No course sales yet" compact>
              Orders appear here as soon as a learner starts buying a paid course.
            </StateMessage>
          }
        />
      )}
    </section>
  );
}
