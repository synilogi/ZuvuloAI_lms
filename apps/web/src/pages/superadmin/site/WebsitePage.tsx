import { useEffect, useState } from 'react';
import { Plus, Trash } from '@phosphor-icons/react';
import { SITE_LIMITS, type SiteContent } from '@syniastrolms/domain';
import { PageHeader } from '@/components/page/PageHeader';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { useAsync } from '@/hooks/useAsync';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import styles from '../affiliates/Affiliates.module.css';

/** What must be right before saving, in words, by the field's id. The API checks the same limits. */
export function siteContentIssues(c: SiteContent): Record<string, string> {
  const issues: Record<string, string> = {};
  if (c.heroTitle.trim().length < 3) issues['site-hero-title'] = 'The headline needs a few words.';
  if (c.heroText.trim().length < 3) issues['site-hero-text'] = 'The line under the headline needs a few words.';
  c.testimonials.forEach((t, i) => {
    if (t.quote.trim().length < 3) issues[`site-quote-${i}`] = `Testimonial ${i + 1} needs its quote.`;
    if (!t.name.trim()) issues[`site-quote-name-${i}`] = `Testimonial ${i + 1} needs the person’s name.`;
  });
  c.faqs.forEach((f, i) => {
    if (f.q.trim().length < 3) issues[`site-faq-q-${i}`] = `Question ${i + 1} needs its question.`;
    if (f.a.trim().length < 3) issues[`site-faq-a-${i}`] = `Question ${i + 1} needs its answer.`;
  });
  return issues;
}

/** Website management (docs/16 §2.6): the home page's headline, featured courses, testimonials and questions. */
export default function WebsitePage() {
  const toast = useToast();
  const stored = useAsync('site:admin', () => services.site.adminContent());
  const courses = useAsync('site:admin:courses', () => services.catalog.listCourses());
  const [form, setForm] = useState<SiteContent | null>(null);
  const [issues, setIssues] = useState<Record<string, string>>({});
  const [error, setError] = useState<string>();
  const [saving, setSaving] = useState(false);
  useEffect(() => {
    if (stored.data) setForm(stored.data);
  }, [stored.data]);

  if (stored.status === 'error' && !stored.data) {
    return <PlatformError title="The website content didn’t load" error={stored.error} onRetry={() => void stored.run().catch(() => undefined)} />;
  }
  if (!form) return <Skeleton height={420} radius="var(--r-lg)" />;

  const patch = (next: Partial<SiteContent>) => setForm({ ...form, ...next });
  const unpicked = (courses.data ?? []).filter((c) => !form.featuredCourseIds.includes(c.id));
  const coursesFailed = courses.status === 'error' && !courses.data;
  // Only a list that did load can say a course isn't on it.
  const featuredName = (id: string) =>
    courses.data
      ? (courses.data.find((c) => c.id === id)?.title ?? 'A course that is not published now')
      : coursesFailed
        ? 'Course name unavailable'
        : 'Loading…';

  const save = async () => {
    const found = siteContentIssues(form);
    setIssues(found);
    // The page is long: the first problem is also named at the top, beside the button that found it.
    setError(Object.values(found)[0]);
    if (Object.keys(found).length > 0) return;
    setSaving(true);
    try {
      setForm(await services.site.saveContent(form));
      toast({ kind: 'success', title: 'The website is updated', text: 'Visitors see the changes on their next visit.' });
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className={styles.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Website"
        description="The words visitors see on the home page. Courses and categories come from the catalogue."
        actions={
          <Button variant="primary" loading={saving} onClick={() => void save()}>
            Save changes
          </Button>
        }
      />
      {error && <InlineMessage kind="error" title={error} />}

      <section className={styles.form} aria-labelledby="site-hero">
        <h2 id="site-hero">Headline</h2>
        <Field label="Headline" error={issues['site-hero-title']}>
          <Input id="site-hero-title" value={form.heroTitle} maxLength={SITE_LIMITS.heroTitle} onChange={(e) => patch({ heroTitle: e.target.value })} />
        </Field>
        <Field label="Line under the headline" error={issues['site-hero-text']}>
          <Textarea id="site-hero-text" rows={3} value={form.heroText} maxLength={SITE_LIMITS.heroText} onChange={(e) => patch({ heroText: e.target.value })} />
        </Field>
      </section>

      <section className={styles.form} aria-labelledby="site-featured">
        <h2 id="site-featured">Featured courses</h2>
        <p className={styles.muted}>Shown first, in this order. The most popular courses fill any remaining places.</p>
        {coursesFailed && (
          <InlineMessage kind="warn" title="The course list didn’t load">
            Your featured courses are unchanged.{' '}
            <Button size="sm" onClick={() => void courses.run().catch(() => undefined)}>
              Try again
            </Button>
          </InlineMessage>
        )}
        {form.featuredCourseIds.map((id) => (
          <div key={id} className={styles.formActions}>
            <span>{featuredName(id)}</span>
            <IconButton
              label="Remove from featured"
              icon={<Trash size={16} />}
              onClick={() => patch({ featuredCourseIds: form.featuredCourseIds.filter((x) => x !== id) })}
            />
          </div>
        ))}
        {form.featuredCourseIds.length < SITE_LIMITS.featured && (
          <Field label="Add a course">
            <Select
              id="site-featured-add"
              value=""
              disabled={!courses.data}
              onChange={(e) => {
                if (e.target.value) patch({ featuredCourseIds: [...form.featuredCourseIds, e.target.value] });
              }}
            >
              <option value="">{courses.data ? 'Choose a published course' : coursesFailed ? 'The course list didn’t load' : 'Loading courses…'}</option>
              {unpicked.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.title}
                </option>
              ))}
            </Select>
          </Field>
        )}
      </section>

      <section className={styles.form} aria-labelledby="site-testimonials">
        <h2 id="site-testimonials">Testimonials</h2>
        <p className={styles.muted}>Add only real quotes, with the person’s permission. The section stays hidden while this list is empty.</p>
        {form.testimonials.map((t, i) => {
          const set = (next: Partial<typeof t>) => patch({ testimonials: form.testimonials.map((x, j) => (j === i ? { ...x, ...next } : x)) });
          return (
            <fieldset key={i} className={styles.form}>
              <legend>Testimonial {i + 1}</legend>
              <Field label="Quote" error={issues[`site-quote-${i}`]}>
                <Textarea id={`site-quote-${i}`} rows={3} value={t.quote} maxLength={SITE_LIMITS.quote} onChange={(e) => set({ quote: e.target.value })} />
              </Field>
              <Field label="Name" error={issues[`site-quote-name-${i}`]}>
                <Input id={`site-quote-name-${i}`} value={t.name} maxLength={SITE_LIMITS.name} onChange={(e) => set({ name: e.target.value })} />
              </Field>
              <Field label="What they did here" optional>
                <Input id={`site-quote-role-${i}`} value={t.role} maxLength={SITE_LIMITS.role} onChange={(e) => set({ role: e.target.value })} />
              </Field>
              <div className={styles.formActions}>
                <Button iconStart={<Trash size={16} />} onClick={() => patch({ testimonials: form.testimonials.filter((_, j) => j !== i) })}>
                  Remove testimonial
                </Button>
              </div>
            </fieldset>
          );
        })}
        {form.testimonials.length < SITE_LIMITS.testimonials && (
          <div className={styles.formActions}>
            <Button iconStart={<Plus size={16} />} onClick={() => patch({ testimonials: [...form.testimonials, { quote: '', name: '', role: '' }] })}>
              Add testimonial
            </Button>
          </div>
        )}
      </section>

      <section className={styles.form} aria-labelledby="site-faqs">
        <h2 id="site-faqs">Questions</h2>
        <p className={styles.muted}>The first six appear on the home page, and all of them on the FAQ page.</p>
        {form.faqs.map((f, i) => {
          const set = (next: Partial<typeof f>) => patch({ faqs: form.faqs.map((x, j) => (j === i ? { ...x, ...next } : x)) });
          return (
            <fieldset key={i} className={styles.form}>
              <legend>Question {i + 1}</legend>
              <Field label="Question" error={issues[`site-faq-q-${i}`]}>
                <Input id={`site-faq-q-${i}`} value={f.q} maxLength={SITE_LIMITS.q} onChange={(e) => set({ q: e.target.value })} />
              </Field>
              <Field label="Answer" error={issues[`site-faq-a-${i}`]}>
                <Textarea id={`site-faq-a-${i}`} rows={3} value={f.a} maxLength={SITE_LIMITS.a} onChange={(e) => set({ a: e.target.value })} />
              </Field>
              <div className={styles.formActions}>
                <Button iconStart={<Trash size={16} />} onClick={() => patch({ faqs: form.faqs.filter((_, j) => j !== i) })}>
                  Remove question
                </Button>
              </div>
            </fieldset>
          );
        })}
        {form.faqs.length < SITE_LIMITS.faqs && (
          <div className={styles.formActions}>
            <Button iconStart={<Plus size={16} />} onClick={() => patch({ faqs: [...form.faqs, { q: '', a: '' }] })}>
              Add question
            </Button>
          </div>
        )}
      </section>
    </div>
  );
}
