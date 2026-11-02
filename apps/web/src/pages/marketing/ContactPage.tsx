import { useId, useState, type FormEvent } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import type { InquiryKind } from '@syniastrolms/domain';
import { Button } from '@/components/ui/Button/Button';
import { Field, Input, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, StateMessage } from '@/components/ui/Feedback/Feedback';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { API_MODE } from '@/lib/apiMode';
import { services } from '@/services';
import { MarketingChrome } from './MarketingChrome';
import { COMPANY, CONTACT_TOPICS, SUPPORT_EMAIL } from './siteContent';
import { PageHero } from './SiteParts';
import { CONTACT_COPY, contactIssues, contactPayload, emptyContact, topicFrom, type ContactForm } from './contactForm';
import styles from './Marketing.module.css';

/** `/contact`: a question, an order or support. Stored for the Super Admin's inbox. */
export default function ContactPage() {
  const [params, setParams] = useSearchParams();
  const [form, setForm] = useState<ContactForm>(() => emptyContact(topicFrom(params)));
  const [attempt, setAttempt] = useState(0);
  const [error, setError] = useState<string>();
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);
  const ids = { name: useId(), email: useId(), phone: useId(), message: useId() };

  const copy = CONTACT_COPY[form.kind];
  const issues = contactIssues(form);
  const shown = attempt > 0 ? issues : {};
  const summary: FieldIssue[] = (['name', 'email', 'phone', 'message'] as const).filter((k) => shown[k]).map((k) => ({ field: ids[k], message: shown[k]! }));
  const set = (patch: Partial<ContactForm>) => setForm((f) => ({ ...f, ...patch }));
  const setKind = (kind: InquiryKind) => {
    set({ kind });
    setParams({ topic: kind }, { replace: true });
  };

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setAttempt((a) => a + 1);
    setError(undefined);
    if (Object.keys(issues).length) return;
    setSending(true);
    try {
      await services.site.contact(contactPayload(form));
      setSent(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Your message could not be sent.');
    } finally {
      setSending(false);
    }
  };

  return (
    <MarketingChrome>
      <PageHero eyebrow="Contact" title={copy.title}>
        {copy.lead}
      </PageHero>
      <div className={styles.contactLayout}>
        {sent ? (
          <StateMessage
            kind="success"
            title="Thanks — we’ve got your message"
            actions={
              <Button
                onClick={() => {
                  setSent(false);
                  setAttempt(0);
                  setForm(emptyContact(form.kind));
                }}
              >
                Send another
              </Button>
            }
          >
            Our team will reply to {form.email}.{API_MODE === 'mock' ? ' (Demo build: nothing was sent.)' : ''}
          </StateMessage>
        ) : (
          <form className={styles.contactForm} onSubmit={submit} noValidate aria-label={copy.title}>
            <div className={styles.topicSwitch}>
              <SegmentedControl<InquiryKind>
                label="What do you need?"
                value={form.kind}
                onChange={setKind}
                segments={CONTACT_TOPICS.map((t) => ({ value: t.value, label: t.label }))}
              />
            </div>
            <ErrorSummary issues={summary} attempt={attempt} title="Fix these before sending" />
            {error && (
              <InlineMessage kind="error" title="Your message wasn’t sent.">
                {error}
              </InlineMessage>
            )}
            <div className={styles.formRow}>
              <Field label="Your name" error={shown.name}>
                <Input id={ids.name} value={form.name} onChange={(e) => set({ name: e.target.value })} autoComplete="name" />
              </Field>
              <Field label="Email" error={shown.email}>
                <Input id={ids.email} type="email" value={form.email} onChange={(e) => set({ email: e.target.value })} autoComplete="email" />
              </Field>
            </div>
            <Field label="Phone" optional error={shown.phone}>
              <Input id={ids.phone} type="tel" value={form.phone} onChange={(e) => set({ phone: e.target.value })} autoComplete="tel" />
            </Field>
            <Field label={copy.message} error={shown.message}>
              <Textarea id={ids.message} rows={5} value={form.message} onChange={(e) => set({ message: e.target.value })} />
            </Field>
            {/* Never visible to people: a bot that fills it is accepted and ignored. */}
            <div className={styles.honeypot} aria-hidden="true">
              <label>
                Website
                <input tabIndex={-1} autoComplete="off" value={form.website} onChange={(e) => set({ website: e.target.value })} />
              </label>
            </div>
            <Button type="submit" variant="primary" size="lg" loading={sending}>
              {copy.button}
            </Button>
            <p className={styles.pricingNote}>
              We use your details only to reply. See our <Link to="/privacy">privacy policy</Link>.
            </p>
          </form>
        )}
        <aside className={styles.contactAside}>
          <div className={styles.asideCard}>
            <h2>Ready to start now?</h2>
            <p>Browse the catalogue without an account, and create one when you are ready.</p>
            <Link to="/courses">Explore courses →</Link>
          </div>
          <div className={styles.asideCard}>
            <h2>Looking for answers?</h2>
            <p>
              The <Link to="/support">Help Centre</Link> and <Link to="/faq">FAQ</Link> cover the common questions.
            </p>
          </div>
          <div className={styles.asideCard}>
            <h2>Email and phone</h2>
            <p>
              <a href={`mailto:${SUPPORT_EMAIL}`}>{SUPPORT_EMAIL}</a>
              <br />
              <a href={COMPANY.phoneHref}>{COMPANY.phone}</a>
            </p>
          </div>
          <div className={styles.asideCard}>
            <h2>Company</h2>
            <address>
              {COMPANY.name}
              {COMPANY.addressLines.map((line) => (
                <span key={line}>
                  <br />
                  {line}
                </span>
              ))}
            </address>
          </div>
        </aside>
      </div>
    </MarketingChrome>
  );
}
