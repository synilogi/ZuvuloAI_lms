import { useEffect, useState, type FormEvent } from 'react';
import { billingDetailsIssues, emptyBillingDetails, type BillingDetails, type BillingDetailsField } from '@syniastrolms/domain';
import { ErrorSummary } from '@/components/forms/Forms';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input } from '@/components/ui/Field/Field';
import { Modal } from '@/components/overlays/Overlay';
import styles from '@/pages/superadmin/Platform.module.css';

const FIELD_ID: Record<BillingDetailsField, string> = {
  legalName: 'billing-legal-name',
  email: 'billing-email',
  addressLine1: 'billing-address-1',
  addressLine2: 'billing-address-2',
  city: 'billing-city',
  region: 'billing-region',
  postalCode: 'billing-postal-code',
  country: 'billing-country',
  taxRegistration: 'billing-tax-registration',
};

/**
 * The academy's billing details: where its invoices are addressed, and what tax is worked out from. Checked here
 * with the server's own rules so the form can say what is missing; the server checks them again on save.
 */
export function BillingDetailsDialog({
  open,
  initial,
  reason,
  onClose,
  onSave,
}: {
  open: boolean;
  initial: BillingDetails | null;
  /** Why the form opened, when something is waiting for it (a plan chosen before the address was set). */
  reason?: string;
  onClose: () => void;
  onSave: (details: BillingDetails) => Promise<void>;
}) {
  const [form, setForm] = useState<BillingDetails>(initial ?? emptyBillingDetails());
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [serverError, setServerError] = useState<string>();

  useEffect(() => {
    if (!open) return;
    setForm(initial ?? emptyBillingDetails());
    setAttempt(0);
    setServerError(undefined);
  }, [open, initial]);

  const issues = billingDetailsIssues(form).map((i) => ({ field: FIELD_ID[i.field], message: i.message }));
  const shown = serverError ? [...issues, { field: FIELD_ID.legalName, message: serverError }] : issues;
  const errorFor = (field: BillingDetailsField) => (attempt > 0 ? issues.find((i) => i.field === FIELD_ID[field])?.message : undefined);
  const set = (field: BillingDetailsField) => (e: { target: { value: string } }) => setForm({ ...form, [field]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setServerError(undefined);
    if (issues.length) return;
    setSaving(true);
    try {
      await onSave({
        ...form,
        country: form.country.trim().toUpperCase(),
        region: form.region?.trim() ? form.region.trim().toUpperCase() : undefined,
        addressLine2: form.addressLine2?.trim() || undefined,
        taxRegistration: form.taxRegistration?.trim() || undefined,
      });
    } catch (err) {
      setServerError(err instanceof Error ? err.message : 'The billing details could not be saved.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={initial ? 'Edit billing details' : 'Add billing details'}
      description={reason ?? 'Invoices are addressed here, and tax is worked out from the country and region.'}
      width={520}
    >
      <form className={styles.form} onSubmit={submit} noValidate>
        <ErrorSummary issues={attempt > 0 ? shown : serverError ? shown : []} attempt={attempt} title="Fix these before saving" />
        <Field label="Legal name" hint="The name the LMS is billed under." error={errorFor('legalName')}>
          <Input id={FIELD_ID.legalName} value={form.legalName} onChange={set('legalName')} placeholder="Saraswati Coaching Pvt Ltd" autoFocus />
        </Field>
        <Field label="Billing email" hint="Invoices and receipts go here." error={errorFor('email')}>
          <Input id={FIELD_ID.email} type="email" value={form.email} onChange={set('email')} placeholder="accounts@example.com" />
        </Field>
        <Field label="Address" error={errorFor('addressLine1')}>
          <Input
            id={FIELD_ID.addressLine1}
            value={form.addressLine1}
            onChange={set('addressLine1')}
            placeholder="Street and number"
            autoComplete="address-line1"
          />
        </Field>
        <Field label="Address line 2" optional>
          <Input id={FIELD_ID.addressLine2} value={form.addressLine2 ?? ''} onChange={set('addressLine2')} autoComplete="address-line2" />
        </Field>
        <Field label="City" error={errorFor('city')}>
          <Input id={FIELD_ID.city} value={form.city} onChange={set('city')} autoComplete="address-level2" />
        </Field>
        <Field label="State or region code" hint="For example KA for Karnataka." optional error={errorFor('region')}>
          <Input id={FIELD_ID.region} value={form.region ?? ''} onChange={set('region')} maxLength={10} />
        </Field>
        <Field label="Postal code" error={errorFor('postalCode')}>
          <Input id={FIELD_ID.postalCode} value={form.postalCode} onChange={set('postalCode')} autoComplete="postal-code" />
        </Field>
        <Field label="Country code" hint="Two letters, for example IN." error={errorFor('country')}>
          <Input id={FIELD_ID.country} value={form.country} onChange={set('country')} maxLength={2} autoComplete="country" />
        </Field>
        <Field label="Tax registration" hint="GSTIN or equivalent, if the LMS has one." optional error={errorFor('taxRegistration')}>
          <Input id={FIELD_ID.taxRegistration} value={form.taxRegistration ?? ''} onChange={set('taxRegistration')} />
        </Field>
        <div className={styles.formActions}>
          <Button type="button" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" variant="primary" loading={saving}>
            Save billing details
          </Button>
        </div>
      </form>
    </Modal>
  );
}
