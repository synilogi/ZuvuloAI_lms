import { useState, type FormEvent } from 'react';
import { isBankAccount, isIfsc, isPan, MLM_KYC_MAX_DOCUMENTS, MLM_KYC_STATUS_LABEL, type MlmKycInput } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, LinkButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Field, Input } from '@/components/ui/Field/Field';
import { useAsync } from '@/hooks/useAsync';
import { services, ServiceError } from '@/services';
import { AffiliateNav } from './affiliateNav';
import styles from './Affiliate.module.css';

const empty: MlmKycInput = { legalName: '', pan: '', bankAccount: '', ifsc: '', accountHolder: '', upiId: '' };

/** What is wrong with the form, field by field. The API applies the same rules. */
export function kycIssues(f: MlmKycInput): Partial<Record<keyof MlmKycInput, string>> {
  const out: Partial<Record<keyof MlmKycInput, string>> = {};
  if (f.legalName.trim().length < 2) out.legalName = 'Enter your name as on your PAN.';
  if (!isPan(f.pan.trim().toUpperCase())) out.pan = 'Enter your PAN as printed, such as ABCDE1234F.';
  if (!isBankAccount(f.bankAccount.replace(/\s/g, ''))) out.bankAccount = 'Enter your account number, digits only.';
  if (!isIfsc(f.ifsc.trim().toUpperCase())) out.ifsc = 'Enter your bank’s IFSC, such as HDFC0001234.';
  if (f.accountHolder.trim().length < 2) out.accountHolder = 'Enter the name on the account.';
  return out;
}

/** The member's identity and bank details. Stored encrypted, and shown from then on as last digits only. */
export default function AffiliateKycPage() {
  const toast = useToast();
  const kyc = useAsync('affiliate:kyc', () => services.affiliateEarnings.kyc());
  const [form, setForm] = useState(empty);
  const [attempt, setAttempt] = useState(0);
  const [error, setError] = useState<string>();
  const [saving, setSaving] = useState(false);
  const [documents, setDocuments] = useState<{ id: string; name: string }[]>([]);
  const [uploading, setUploading] = useState(false);
  const addDocument = async (file: File | undefined) => {
    if (!file) return;
    setUploading(true);
    setError(undefined);
    try {
      const stored = await services.media.upload(file);
      const id = stored.id;
      if (id) setDocuments((d) => [...d, { id, name: file.name }]);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setUploading(false);
    }
  };
  const issues = attempt > 0 ? kycIssues(form) : {};
  const set = (key: keyof MlmKycInput) => (e: { target: { value: string } }) => setForm((f) => ({ ...f, [key]: e.target.value }));

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    if (Object.keys(kycIssues(form)).length) return;
    setError(undefined);
    setSaving(true);
    try {
      await services.affiliateEarnings.submitKyc({ ...form, upiId: form.upiId?.trim() || undefined, documentIds: documents.map((d) => d.id) });
      toast({ kind: 'success', title: 'Sent for review', text: 'We’ll tell you when it has been checked.' });
      setForm(empty);
      setDocuments([]);
      setAttempt(0);
      await kyc.run();
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  if (kyc.status === 'error' && kyc.error instanceof ServiceError && kyc.error.reason === 'NOT_AN_AFFILIATE') {
    return (
      <div className={styles.page}>
        <PageHeader title="Identity check" />
        <StateMessage title="You’re not in the affiliate program yet" actions={<LinkButton to="/affiliate">Open the overview</LinkButton>}>
          You can read about it and join from the overview.
        </StateMessage>
      </div>
    );
  }
  const k = kyc.data;

  return (
    <div className={styles.page}>
      <PageHeader title="Identity check" description="We need this before paying any withdrawal. Your PAN and account number are stored encrypted." />
      <AffiliateNav />
      {kyc.status === 'error' && !k ? (
        <StateMessage kind="error" title="This page didn’t load" actions={<Button onClick={() => void kyc.run().catch(() => undefined)}>Try again</Button>}>
          {kyc.error.message}
        </StateMessage>
      ) : !k ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : (
        <>
          {k.status !== 'none' && (
            <section className={styles.panel} aria-labelledby="kyc-status">
              <h2 id="kyc-status" className={styles.panelTitle}>
                Status <Badge size="sm">{MLM_KYC_STATUS_LABEL[k.status]}</Badge>
              </h2>
              {k.rejectionReason && (
                <InlineMessage kind="warn" title="Please change this">
                  {k.rejectionReason}
                </InlineMessage>
              )}
              <p className={styles.muted}>
                {k.legalName} · PAN ending {k.panLast4} · {k.accountHolder}, account ending {k.bankAccountLast4}, {k.ifsc}
                {k.documents.length > 0 && ` · ${k.documents.length} document${k.documents.length === 1 ? '' : 's'} attached`}
              </p>
            </section>
          )}
          <section className={styles.panel} aria-labelledby="kyc-form">
            <h2 id="kyc-form" className={styles.panelTitle}>
              {k.status === 'none' ? 'Your details' : 'Update your details'}
            </h2>
            {k.status === 'verified' && (
              <p className={styles.muted}>Changing verified details sends them back for review, and you can’t withdraw until they are checked again.</p>
            )}
            <form className={styles.form} onSubmit={submit} noValidate>
              {error && <InlineMessage kind="error" title={error} />}
              <Field label="Name on your PAN" error={issues.legalName}>
                <Input id="kyc-name" value={form.legalName} maxLength={120} autoComplete="name" onChange={set('legalName')} />
              </Field>
              <Field label="PAN" error={issues.pan}>
                <Input id="kyc-pan" value={form.pan} maxLength={10} autoComplete="off" onChange={set('pan')} />
              </Field>
              <Field label="Name on the bank account" error={issues.accountHolder}>
                <Input id="kyc-holder" value={form.accountHolder} maxLength={120} onChange={set('accountHolder')} />
              </Field>
              <Field label="Account number" error={issues.bankAccount}>
                <Input id="kyc-account" inputMode="numeric" value={form.bankAccount} maxLength={24} autoComplete="off" onChange={set('bankAccount')} />
              </Field>
              <Field label="IFSC" error={issues.ifsc}>
                <Input id="kyc-ifsc" value={form.ifsc} maxLength={11} autoComplete="off" onChange={set('ifsc')} />
              </Field>
              <Field label="UPI ID" optional>
                <Input id="kyc-upi" value={form.upiId ?? ''} maxLength={80} autoComplete="off" onChange={set('upiId')} />
              </Field>
              <Field label="Identity documents" optional hint="A PAN card and a cancelled cheque help us check faster. PDF or image.">
                <input
                  id="kyc-documents"
                  type="file"
                  accept="application/pdf,image/png,image/jpeg"
                  disabled={uploading || documents.length >= MLM_KYC_MAX_DOCUMENTS}
                  onChange={(e) => {
                    void addDocument(e.target.files?.[0]);
                    e.target.value = '';
                  }}
                />
              </Field>
              {documents.length > 0 && (
                <ul aria-label="Attached documents">
                  {documents.map((d) => (
                    <li key={d.id}>
                      {d.name}{' '}
                      <Button size="sm" onClick={() => setDocuments((all) => all.filter((x) => x.id !== d.id))}>
                        Remove
                      </Button>
                    </li>
                  ))}
                </ul>
              )}
              <div>
                <Button type="submit" variant="primary" loading={saving}>
                  Send for review
                </Button>
              </div>
            </form>
          </section>
        </>
      )}
    </div>
  );
}
