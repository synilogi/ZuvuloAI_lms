import { useEffect, useId, useState, type FormEvent } from 'react';
import { CheckCircle, CreditCard, Eye, EyeSlash, Lightning, PlugsConnected, Power, WarningCircle } from '@phosphor-icons/react';
import { formatDate, formatTime } from '@/lib/format';
import { cx } from '@/lib/cx';
import { platformErrorOf } from '@/lib/platformErrors';
import { useAsync } from '@/hooks/useAsync';
import { PageHeader } from '@/components/page/PageHeader';
import { ChoiceCards, ErrorSummary } from '@/components/forms/Forms';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { GATEWAY_ENVIRONMENTS, services, type GatewayEnvironment, type GatewayTestResult, type GatewayView } from '@/services';
import { API_BASE_URL } from '@/services/http/client';
import { PLATFORM_EYEBROW, PlatformError } from './platformMeta';
import {
  MASKED,
  SLOT_STATUS_LABEL,
  TEST_RESULT_TITLE,
  activationReason,
  blankValues,
  credentialsPayload,
  environmentLabel,
  environmentSwitchBlocker,
  fieldInputId,
  gatewayActions,
  fieldIsSet,
  gatewayFormIssues,
  hasAnyCredentials,
  hasTyped,
  slotStatus,
  storedValue,
  testResultTone,
  webhookUrl,
  type GatewayValues,
} from './paymentGatewayMeta';
import { Fact, PrototypeNote } from './subscriptions/subscriptionMeta';
import { SalesTabs } from './sales/salesMeta';
import styles from './subscriptions/Subscriptions.module.css';
import own from './PaymentGateways.module.css';

/*
 * The gateways course payments go through (docs/16, D-PLAT-07). A super admin stores each gateway's test and live
 * credentials, enables it, checks it, chooses which environment new payments use, and chooses the one gateway
 * new payments go through. Credentials go to the server and are sealed there with PAYMENT_CREDENTIALS_KEY — a
 * key the server administrator sets, never entered here. This page never receives a secret, so it can never
 * show one. Every rule is the server's; a refusal is shown in its own words.
 */

const when = (iso: string | null) => (iso ? `${formatDate(iso)}, ${formatTime(iso)}` : 'Never');
const message = (e: unknown, fallback: string) => (e instanceof Error && e.message ? e.message : fallback);

const SLOT_TONE = { configured: 'accent', 'needs-reentry': 'warn', 'not-configured': 'neutral' } as const;

export default function PaymentGatewaysPage() {
  const toast = useToast();
  const query = useAsync('platform:payment-gateways', () => services.paymentGateways.list());
  const data = query.data;
  const reload = () => query.run().catch(() => undefined);

  const [configuring, setConfiguring] = useState<GatewayView | null>(null);
  const [activating, setActivating] = useState<GatewayView | null>(null);
  const [turningOff, setTurningOff] = useState(false);
  const [switching, setSwitching] = useState<{ gateway: GatewayView; environment: GatewayEnvironment } | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [results, setResults] = useState<Record<string, GatewayTestResult>>({});
  const [choice, setChoice] = useState<string>('');

  const active = data?.rows.find((g) => g.provider === data.active) ?? data?.rows.find((g) => g.isActive);
  // The selector starts on the active gateway, and follows it after every reload.
  useEffect(() => setChoice(data?.active ?? ''), [data?.active]);
  const chosen = data?.rows.find((g) => g.provider === choice);

  const run = async (key: string, action: () => Promise<unknown>, fallback: string) => {
    setBusy(key);
    try {
      await action();
      await reload();
    } catch (e) {
      toast({ kind: 'error', title: 'That didn’t work', text: message(e, fallback) });
    } finally {
      setBusy(null);
    }
  };

  const toggle = (g: GatewayView) =>
    run(
      `enable:${g.provider}`,
      async () => {
        const next = await services.paymentGateways.update(g.provider, { enabled: !g.enabled });
        toast({ kind: 'success', title: next.enabled ? `${next.label} enabled` : `${next.label} disabled` });
      },
      'The gateway could not be changed.',
    );

  const switchEnvironment = async (g: GatewayView, environment: GatewayEnvironment) => {
    const next = await services.paymentGateways.update(g.provider, { environment });
    toast({ kind: 'success', title: `${next.label} now uses ${environmentLabel(next.environment).toLowerCase()} credentials`, text: 'For new payments only.' });
    await reload();
  };

  const requestSwitch = (g: GatewayView, environment: GatewayEnvironment) => {
    if (environment === g.environment) return;
    // Moving the gateway that takes payments deserves a pause; any other is only configuration.
    if (g.isActive) setSwitching({ gateway: g, environment });
    else run(`env:${g.provider}`, () => switchEnvironment(g, environment), 'The environment could not be changed.');
  };

  const test = async (g: GatewayView) => {
    setBusy(`test:${g.provider}`);
    try {
      const result = await services.paymentGateways.test(g.provider, g.environment);
      setResults((all) => ({ ...all, [g.provider]: result }));
    } catch (e) {
      setResults((all) => ({
        ...all,
        [g.provider]: { ok: false, checked: false, environment: g.environment, detail: message(e, 'The check could not be run.') },
      }));
    } finally {
      setBusy(null);
    }
  };

  const activate = async () => {
    if (!activating) return;
    const next = await services.paymentGateways.activate(activating.provider);
    setActivating(null);
    toast({ kind: 'success', title: `${next.label} is now the active gateway`, text: `New payments go through it, with its ${next.environment} credentials.` });
    await reload();
  };

  const turnOff = async () => {
    const { deactivated } = await services.paymentGateways.deactivate();
    setTurningOff(false);
    const label = data?.rows.find((g) => g.provider === deactivated)?.label;
    toast({
      kind: 'success',
      title: 'Online payment is off',
      text: label ? `${label} no longer takes new payments. Learners cannot buy courses until a gateway is active.` : 'No gateway was active.',
    });
    await reload();
  };

  const saved = async (g: GatewayView, environment: GatewayEnvironment) => {
    setConfiguring(null);
    setResults((all) => {
      const next = { ...all };
      delete next[g.provider];
      return next;
    });
    toast({ kind: 'success', title: `${g.label} ${environment} credentials saved` });
    await reload();
  };

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Payment setup"
        description="Connect a payment provider, such as Razorpay, so learners can buy courses online. Course money settles to this account. Keys are stored encrypted — once saved, a secret key is never shown again, here or anywhere."
      />
      <SalesTabs />
      <PrototypeNote>Demo gateways. Nothing typed here is kept, and no gateway is ever contacted.</PrototypeNote>

      {query.status === 'error' && !data ? (
        <PlatformError title="Payment setup didn’t load" error={query.error} onRetry={reload} />
      ) : !data ? (
        <div className={styles.sections} aria-busy="true">
          <Skeleton height={180} radius="var(--r-lg)" />
          <Skeleton height={320} radius="var(--r-lg)" />
          <Skeleton height={320} radius="var(--r-lg)" />
        </div>
      ) : (
        <div className={styles.sections}>
          {!data.vaultConfigured && (
            <InlineMessage kind="warn" title="Secure credential storage is not configured on the server.">
              Gateway credentials are encrypted with PAYMENT_CREDENTIALS_KEY, a master key the server administrator sets on the API server — it is never entered
              here. Until it is set and the API restarted, saving credentials is refused and nothing is stored.
            </InlineMessage>
          )}

          <section className={styles.panel} aria-labelledby="online-payments-title">
            <div className={styles.panelHead}>
              <h2 id="online-payments-title" className={styles.panelTitle}>
                Online payments
              </h2>
              {active ? (
                <Badge size="sm" tone="accent" icon={<Lightning size={13} />}>
                  On
                </Badge>
              ) : (
                <Badge size="sm" tone="neutral">
                  Off
                </Badge>
              )}
            </div>
            {active ? (
              <p className={styles.muted}>
                New payments go through <strong>{active.label}</strong>, with its <strong>{active.environment}</strong> credentials. Orders already made keep
                their own gateway.
              </p>
            ) : (
              <p className={styles.muted}>Online payment is off, so learners cannot buy paid courses. Set a provider as active to start selling.</p>
            )}

            <ChoiceCards<string>
              legend="Active gateway"
              value={choice}
              onChange={setChoice}
              columns={2}
              choices={data.rows.map((g) => {
                const reason = g.isActive ? null : activationReason(g);
                const state = `${g.configured ? 'Configured' : 'Not configured'} (${g.environment}) · ${g.enabled ? 'Enabled' : 'Disabled'}${g.isActive ? ' · Active' : ''}`;
                return { value: g.provider, label: g.label, description: reason ? `${state}. ${reason}` : state, disabled: Boolean(reason) };
              })}
            />
            <div className={styles.headerActions}>
              <Button
                variant="primary"
                iconStart={<Lightning size={16} />}
                disabled={!chosen || chosen.isActive || !chosen.canActivate}
                onClick={() => chosen && setActivating(chosen)}
              >
                Set as active
              </Button>
              <Button iconStart={<Power size={16} />} disabled={!active} onClick={() => setTurningOff(true)}>
                Turn off online payment
              </Button>
            </div>
          </section>

          {data.rows.map((g) => (
            <GatewayCard
              key={g.provider}
              gateway={g}
              vaultConfigured={data.vaultConfigured}
              busy={busy}
              result={results[g.provider]}
              onConfigure={() => setConfiguring(g)}
              onToggle={() => toggle(g)}
              onTest={() => test(g)}
              onActivate={() => setActivating(g)}
              onSwitch={(env) => requestSwitch(g, env)}
            />
          ))}
        </div>
      )}

      {configuring && (
        <ConfigureDialog
          key={configuring.provider}
          gateway={configuring}
          vaultConfigured={data?.vaultConfigured ?? true}
          onClose={() => setConfiguring(null)}
          onSaved={saved}
        />
      )}

      <ConfirmDialog
        open={Boolean(activating)}
        onClose={() => setActivating(null)}
        onConfirm={activate}
        icon={<Lightning size={20} />}
        title={activating ? `Set ${activating.label} as the active gateway?` : ''}
        confirmLabel="Set as active"
      >
        <ul className={styles.checklist}>
          <li className={styles.checkItem}>
            <CheckCircle size={16} aria-hidden="true" />
            <span>
              Only new payments go through {activating?.label}, with its {activating?.environment} credentials.
            </span>
          </li>
          <li className={styles.checkItem}>
            <CheckCircle size={16} aria-hidden="true" />
            <span>Orders that already exist keep their original gateway and environment.</span>
          </li>
          {active && activating && active.provider !== activating.provider && (
            <li className={styles.checkItem}>
              <CheckCircle size={16} aria-hidden="true" />
              <span>{active.label} stops taking new payments, and keeps its credentials.</span>
            </li>
          )}
        </ul>
      </ConfirmDialog>

      <ConfirmDialog
        open={Boolean(switching)}
        onClose={() => setSwitching(null)}
        onConfirm={async () => {
          if (!switching) return;
          await switchEnvironment(switching.gateway, switching.environment);
          setSwitching(null);
        }}
        tone={switching?.environment === 'live' ? 'danger' : 'default'}
        title={switching ? `Switch ${switching.gateway.label} to ${switching.environment}?` : ''}
        confirmLabel={switching ? `Use ${switching.environment} credentials` : 'Switch'}
      >
        <ul className={styles.checklist}>
          <li className={styles.checkItem}>
            <WarningCircle size={16} aria-hidden="true" />
            <span>
              {switching?.gateway.label} is the active gateway: new payments will use its {switching?.environment} credentials
              {switching?.environment === 'live' ? ' and charge Admins real money' : ' and take no real money'}.
            </span>
          </li>
          <li className={styles.checkItem}>
            <CheckCircle size={16} aria-hidden="true" />
            <span>Payments already made keep the environment they were made in.</span>
          </li>
        </ul>
      </ConfirmDialog>

      <ConfirmDialog
        open={turningOff}
        onClose={() => setTurningOff(false)}
        onConfirm={turnOff}
        tone="danger"
        icon={<Power size={20} />}
        title="Turn off online payment?"
        confirmLabel="Turn off online payment"
      >
        <ul className={styles.checklist}>
          <li className={styles.checkItem}>
            <WarningCircle size={16} aria-hidden="true" />
            <span>No gateway is active: learners cannot buy paid courses, and new checkouts are refused.</span>
          </li>
          <li className={styles.checkItem}>
            <WarningCircle size={16} aria-hidden="true" />
            <span>Free courses still open as usual.</span>
          </li>
          <li className={styles.checkItem}>
            <CheckCircle size={16} aria-hidden="true" />
            <span>{active ? `${active.label}’s` : 'Every gateway’s'} credentials stay stored.</span>
          </li>
        </ul>
      </ConfirmDialog>
    </div>
  );
}

/* ─── One gateway ─────────────────────────────────────────────────────────── */

function EnvironmentSwitch({ gateway: g, disabled, onSwitch }: { gateway: GatewayView; disabled: boolean; onSwitch: (env: GatewayEnvironment) => void }) {
  const name = useId();
  return (
    <fieldset className={own.envSwitch} disabled={disabled}>
      <legend className="sr-only">Mode for new payments</legend>
      {GATEWAY_ENVIRONMENTS.map((env) => {
        const blocker = environmentSwitchBlocker(g, env);
        const selected = g.environment === env;
        return (
          <label key={env} className={cx(own.envOption, selected && own.envSelected, blocker && own.envDisabled)} title={blocker ?? undefined}>
            <input type="radio" name={name} value={env} checked={selected} disabled={Boolean(blocker)} onChange={() => onSwitch(env)} />
            {environmentLabel(env)}
          </label>
        );
      })}
    </fieldset>
  );
}

function GatewayCard({
  gateway: g,
  vaultConfigured,
  busy,
  result,
  onConfigure,
  onToggle,
  onTest,
  onActivate,
  onSwitch,
}: {
  gateway: GatewayView;
  vaultConfigured: boolean;
  busy: string | null;
  result?: GatewayTestResult;
  onConfigure: () => void;
  onToggle: () => void;
  onTest: () => void;
  onActivate: () => void;
  onSwitch: (env: GatewayEnvironment) => void;
}) {
  const actions = gatewayActions(g, vaultConfigured);
  const titleId = `gateway-${g.provider}-title`;
  const tone = result ? testResultTone(result) : null;

  return (
    <section className={styles.panel} aria-labelledby={titleId}>
      <div className={styles.panelHead}>
        <h2 id={titleId} className={styles.panelTitle}>
          {g.label}
        </h2>
        {g.isActive && (
          <Badge size="sm" tone="accent" icon={<Lightning size={13} />}>
            Active
          </Badge>
        )}
      </div>

      {!g.implemented && g.unavailableReason && (
        <InlineMessage kind="info" title="Cannot take payments yet.">
          {g.unavailableReason}
        </InlineMessage>
      )}
      {g.fieldsProvisional && <InlineMessage kind="info">Fields are provisional until {g.label}’s merchant API contract is confirmed.</InlineMessage>}
      {g.needsReentry && (
        <InlineMessage kind="warn" title={`Enter the ${g.environment} credentials again.`}>
          They were saved under a different encryption key and can no longer be read, so {g.label} cannot use them until they are saved again.
        </InlineMessage>
      )}

      <dl className={own.statusRows}>
        <Fact
          label={`Credentials (${g.environment})`}
          value={
            <Badge size="sm" tone={SLOT_TONE[slotStatus(g.credentials[g.environment])]}>
              {SLOT_STATUS_LABEL[slotStatus(g.credentials[g.environment])]}
            </Badge>
          }
        />
        <Fact
          label="Status"
          value={
            <Badge size="sm" tone={g.enabled ? 'info' : 'neutral'}>
              {g.enabled ? 'Enabled' : 'Disabled'}
            </Badge>
          }
        />
        <Fact label="Mode for new payments" value={<EnvironmentSwitch gateway={g} disabled={busy === `env:${g.provider}`} onSwitch={onSwitch} />} />
        <Fact label="Active" value={g.isActive ? 'Yes' : 'No'} />
        <Fact label="Last updated" value={when(g.updatedAt)} />
      </dl>

      <h3 className={own.sectionTitle}>Credentials</h3>
      <div className={own.slots}>
        {GATEWAY_ENVIRONMENTS.map((env) => {
          const slot = g.credentials[env];
          const status = slotStatus(slot);
          return (
            <div key={env} className={own.slot}>
              <div className={own.slotHead}>
                <h4 className={own.slotTitle}>{environmentLabel(env)}</h4>
                <Badge size="sm" tone={SLOT_TONE[status]} icon={status === 'configured' ? <CheckCircle size={13} /> : undefined}>
                  {SLOT_STATUS_LABEL[status]}
                </Badge>
              </div>
              <dl className={styles.rows}>
                {g.fields.map((field) => (
                  <div key={field.key} className={styles.row}>
                    <dt className={styles.rowLabel}>{field.label}</dt>
                    <dd className={cx(styles.rowValue, status === 'configured' && styles.mono)}>
                      {field.secret && storedValue(g, env, field.key) === MASKED ? (
                        <span aria-label={`${field.label} is set`}>{MASKED}</span>
                      ) : (
                        storedValue(g, env, field.key)
                      )}
                    </dd>
                  </div>
                ))}
                <div className={styles.row}>
                  <dt className={styles.rowLabel}>Configured</dt>
                  <dd className={styles.rowValue}>{when(slot.configuredAt)}</dd>
                </div>
              </dl>
            </div>
          );
        })}
      </div>

      <dl className={styles.facts}>
        <Fact label="Payment events address (webhook URL)" value={<span className={styles.mono}>{webhookUrl(API_BASE_URL, g.provider)}</span>} />
      </dl>
      <p className={styles.muted}>
        Give {g.label} this webhook URL, for test and live alike: payments are confirmed by its signed webhooks, not by the browser.
      </p>

      {result && tone && (
        <InlineMessage kind={tone} title={`${TEST_RESULT_TITLE[tone]} (${result.environment})`}>
          {result.detail}
        </InlineMessage>
      )}

      <div className={styles.headerActions}>
        <Button variant={hasAnyCredentials(g) ? 'secondary' : 'primary'} iconStart={<CreditCard size={16} />} onClick={onConfigure}>
          {actions.configure.label}
        </Button>
        <Button onClick={onToggle} loading={busy === `enable:${g.provider}`} disabled={actions.toggle.disabled} title={actions.toggle.reason}>
          {actions.toggle.label}
        </Button>
        <Button iconStart={<PlugsConnected size={16} />} onClick={onTest} loading={busy === `test:${g.provider}`}>
          {actions.test.label}
        </Button>
        {!g.isActive && (
          <Button iconStart={<Lightning size={16} />} onClick={onActivate} disabled={actions.activate.disabled} title={actions.activate.reason}>
            {actions.activate.label}
          </Button>
        )}
      </div>
      {!g.isActive && actions.activate.reason && <p className={styles.muted}>Cannot be set active: {actions.activate.reason}</p>}
      {actions.toggle.reason && <p className={styles.muted}>{actions.toggle.reason}</p>}
      {!g.testSupported && <p className={styles.muted}>Test configuration cannot check {g.label}’s credentials with the gateway yet.</p>}
    </section>
  );
}

/* ─── Credentials ─────────────────────────────────────────────────────────── */

/**
 * Entering or replacing one environment's credentials. No input is ever prefilled with what is stored —
 * there is nothing to prefill it with — and a blank input keeps the stored value, so replacing one secret
 * needs nothing else typed again. What is typed lives only in this dialog's state: it is dropped when the
 * environment changes, when the dialog closes, and when it unmounts.
 */
function ConfigureDialog({
  gateway: g,
  vaultConfigured,
  onClose,
  onSaved,
}: {
  gateway: GatewayView;
  vaultConfigured: boolean;
  onClose: () => void;
  onSaved: (g: GatewayView, environment: GatewayEnvironment) => Promise<void>;
}) {
  const [environment, setEnvironment] = useState<GatewayEnvironment>(g.environment);
  const [values, setValues] = useState<GatewayValues>(() => blankValues(g));
  const [shown, setShown] = useState<Record<string, boolean>>({});
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [serverError, setServerError] = useState<unknown>(null);
  const [confirmDiscard, setConfirmDiscard] = useState(false);

  const clear = () => {
    setValues(blankValues(g));
    setShown({});
  };
  // The page mounts this dialog only while it is open, so nothing typed outlives it.

  const slot = g.credentials[environment];
  const needsAll = !slot.configured || slot.needsReentry;
  const issues = gatewayFormIssues(g, environment, values);
  const storage = platformErrorOf(serverError);

  const close = () => {
    clear();
    onClose();
  };
  const requestClose = () => {
    if (saving) return;
    if (hasTyped(values)) setConfirmDiscard(true);
    else close();
  };

  const chooseEnvironment = (env: GatewayEnvironment) => {
    setEnvironment(env);
    clear();
    setAttempt(0);
    setServerError(null);
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(null);
    if (issues.length) return;
    setSaving(true);
    try {
      const next = await services.paymentGateways.configure(g.provider, { environment, credentials: credentialsPayload(g, values) });
      clear();
      await onSaved(next, environment);
    } catch (err) {
      setServerError(err);
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <Modal
        open
        onClose={requestClose}
        title={hasAnyCredentials(g) ? `Replace ${g.label} credentials` : `Configure ${g.label}`}
        description="Test and live credentials are stored separately. Once saved, secrets are encrypted on the server and never shown again."
        width={540}
      >
        <form className={styles.form} onSubmit={submit} noValidate autoComplete="off">
          {!vaultConfigured && (
            <InlineMessage kind="warn" title="Secure credential storage is not configured on the server.">
              The server administrator must set PAYMENT_CREDENTIALS_KEY and restart the API before credentials can be saved.
            </InlineMessage>
          )}
          <ErrorSummary issues={attempt ? issues : []} attempt={attempt} title="Fix these before saving" />

          <ChoiceCards<GatewayEnvironment>
            legend="Environment"
            value={environment}
            onChange={chooseEnvironment}
            columns={2}
            choices={GATEWAY_ENVIRONMENTS.map((env) => {
              const s = g.credentials[env];
              const hint = s.configured && s.hint.keyId ? ` · ${s.hint.keyId}` : '';
              return {
                value: env,
                label: environmentLabel(env),
                description: `${SLOT_STATUS_LABEL[slotStatus(s)]}${hint}${env === g.environment ? ' · used for new payments' : ''}`,
              };
            })}
          />
          <p className={styles.muted}>
            {needsAll
              ? `Every field is needed: the ${environment} environment has no usable credentials.`
              : `Fill in only what you are replacing. A field left blank keeps the stored ${environment} value.`}{' '}
            Switching environment clears what you typed.
          </p>

          {g.fields.map((field) => {
            const id = fieldInputId(g.provider, field.key);
            const set = fieldIsSet(g, environment, field.key);
            const error = attempt ? issues.find((i) => i.field === id)?.message : undefined;
            const help = set ? (field.secret ? 'Leave blank to keep the existing secret.' : 'Leave blank to keep the stored value.') : field.help;
            const input = (
              <Input
                id={id}
                name={id}
                type={field.secret && !shown[field.key] ? 'password' : 'text'}
                autoComplete={field.secret ? 'new-password' : 'off'}
                spellCheck={false}
                value={values[field.key] ?? ''}
                onChange={(e) => setValues((v) => ({ ...v, [field.key]: e.target.value }))}
                placeholder={set ? (field.secret ? MASKED : (slot.hint[field.key] ?? 'Leave blank to keep')) : undefined}
              />
            );
            return (
              <Field key={`${environment}:${field.key}`} label={field.label} hint={set && field.help ? `${help} ${field.help}` : help} error={error}>
                {field.secret ? (
                  <div className={own.secretRow}>
                    {input}
                    <button
                      type="button"
                      className={own.secretToggle}
                      onClick={() => setShown((s) => ({ ...s, [field.key]: !s[field.key] }))}
                      aria-label={shown[field.key] ? `Hide ${field.label}` : `Show ${field.label}`}
                      aria-pressed={Boolean(shown[field.key])}
                      aria-controls={id}
                    >
                      {shown[field.key] ? <EyeSlash size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                ) : (
                  input
                )}
              </Field>
            );
          })}

          {Boolean(serverError) &&
            (storage ? (
              // The title already says what the server said; the body says who can fix it.
              <InlineMessage kind="warn" title={storage.title}>
                {storage.body}
              </InlineMessage>
            ) : (
              <InlineMessage kind="error" title="Not saved.">
                {message(serverError, 'The credentials could not be saved.')}
              </InlineMessage>
            ))}

          <div className={styles.formActions}>
            <Button type="button" onClick={requestClose} disabled={saving}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" loading={saving}>
              Save {environment} credentials
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={confirmDiscard}
        onClose={() => setConfirmDiscard(false)}
        onConfirm={() => {
          setConfirmDiscard(false);
          close();
        }}
        tone="danger"
        title="Discard what you typed?"
        description="Nothing has been saved. The values you entered are cleared."
        confirmLabel="Discard"
      />
    </>
  );
}
