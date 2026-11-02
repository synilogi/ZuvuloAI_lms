import { useEffect, useRef, useState, type FormEvent } from 'react';
import { Link, useBlocker, useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, CheckCircle, FloppyDisk, Plus, Star, Stamp, Trash } from '@phosphor-icons/react';
import type { CertificateTemplate, CertificateTemplateInput } from '@syniastrolms/domain';
import { validateTemplate } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { cx } from '@/lib/cx';
import { formatRelative, plural } from '@/lib/format';
import { ChoiceCards, ErrorSummary, FormSection, Switch, type FieldIssue } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { StickyActionBar } from '@/components/lms/actions/StickyActionBar';
import { CertificateDocument } from '@/components/lms/certificate/CertificateDocument';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services } from '@/services';
import { CertificateTabs } from './CertificatesPage';
import styles from './Certificates.module.css';

const SAMPLE = {
  learnerName: 'Ananya Rao',
  courseTitle: 'Class 10 Mathematics',
  levelTitle: 'Beginner',
  completedAt: '2026-09-12T18:00:00+05:30',
  issuedAt: '2026-09-14T11:00:00+05:30',
  credentialId: 'AD-VF-2026-00000',
  hours: 24,
  finalScore: 86,
};

export default function TemplatesPage() {
  const now = useNow();
  const toast = useToast();
  const list = useAsync('certificate-templates', () => services.certificates.listTemplates());

  const makeDefault = async (t: CertificateTemplate) => {
    await services.certificates.setDefaultTemplate(t.id).catch(() => undefined);
    toast({ kind: 'success', title: `${t.name} is now the default`, text: 'Courses without their own template print on it.' });
    list.run().catch(() => undefined);
  };

  return (
    <div className={styles.page}>
      <PageHeader
        title="Certificates"
        description="The designs certificates are printed on. Each course uses one template; courses without their own use the default."
        actions={
          <LinkButton to="/admin/certificates/templates/new" iconStart={<Plus size={16} />}>
            New template
          </LinkButton>
        }
      />
      <CertificateTabs />
      {list.status === 'error' && !list.data ? (
        <StateMessage
          kind="error"
          title="Templates didn’t load"
          actions={
            <Button variant="primary" onClick={() => list.run().catch(() => undefined)}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : !list.data ? (
        <ul className={styles.templateGrid} aria-busy="true">
          {Array.from({ length: 3 }, (_, i) => (
            <li key={i}>
              <Skeleton height={320} radius="var(--r-lg)" />
            </li>
          ))}
        </ul>
      ) : list.data.length === 0 ? (
        <StateMessage
          icon={<Stamp size={26} />}
          title="No templates yet"
          actions={<LinkButton to="/admin/certificates/templates/new">Design the first template</LinkButton>}
        >
          A template sets the heading, layout, colour and signatories printed on a certificate.
        </StateMessage>
      ) : (
        <ul className={styles.templateGrid}>
          {list.data.map(({ template: t, courses, issued }) => (
            <li key={t.id} className={styles.templateCard}>
              <Link to={`/admin/certificates/templates/${t.id}`} className={styles.templatePreview} aria-label={`Edit ${t.name}`}>
                <CertificateDocument template={t} {...SAMPLE} />
              </Link>
              <div className={styles.templateBody}>
                <div className={styles.templateHead}>
                  <Link to={`/admin/certificates/templates/${t.id}`} className={styles.cellTitle}>
                    {t.name}
                  </Link>
                  {t.isDefault && (
                    <Badge size="sm" tone="accent" icon={<Star size={12} weight="fill" />}>
                      Default
                    </Badge>
                  )}
                </div>
                <span className={styles.cellMeta}>
                  {plural(courses.length, 'course')} · {plural(issued, 'certificate')} issued · updated {formatRelative(t.updatedAt, now)}
                </span>
                <span className={styles.muted}>
                  {courses.length
                    ? courses.map((c) => c.title).join(', ')
                    : t.isDefault
                      ? 'Used by every course without its own template'
                      : 'Not assigned to a course'}
                </span>
                <div className={styles.templateActions}>
                  <LinkButton size="sm" to={`/admin/certificates/templates/${t.id}`}>
                    Edit
                  </LinkButton>
                  {!t.isDefault && (
                    <Button size="sm" variant="ghost" onClick={() => makeDefault(t)}>
                      Make default
                    </Button>
                  )}
                </div>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

/* ─── Editor ───────────────────────────────────────────────────────────── */

const BLANK: CertificateTemplateInput = {
  name: '',
  style: 'classic',
  accent: 'emerald',
  heading: 'Certificate of Completion',
  statement: 'has completed the course of study in',
  signatories: [{ name: 'Kavita Menon', title: 'Director' }],
  showScore: true,
  showHours: true,
};

export function TemplateEditorPage() {
  const { templateId } = useParams();
  const isNew = !templateId || templateId === 'new';
  const query = useAsync(`template:${templateId}`, () =>
    isNew
      ? services.certificates.getTemplate('tpl-classic').then((s) => ({ ...s, template: null as CertificateTemplate | null, courses: [] }))
      : services.certificates.getTemplate(templateId!).then((s) => ({ ...s, template: s.template as CertificateTemplate | null })),
  );
  usePageCrumbs([{ label: query.data?.template?.name ?? (isNew ? 'New template' : 'Template') }]);

  if (query.status === 'error' && !query.data) {
    const notFound = (query.error as { code?: string }).code === 'not-found';
    return (
      <div className={styles.page}>
        <StateMessage
          kind="error"
          title={notFound ? 'Template not found' : 'The template didn’t load'}
          actions={
            notFound ? (
              <LinkButton to="/admin/certificates/templates" iconStart={<ArrowLeft size={16} />}>
                Back to templates
              </LinkButton>
            ) : (
              <Button variant="primary" onClick={() => query.run().catch(() => undefined)}>
                Try again
              </Button>
            )
          }
        >
          {query.error.message}
        </StateMessage>
      </div>
    );
  }
  if (!query.data) {
    return (
      <div className={styles.page} aria-busy="true">
        <Skeleton width="30%" height={30} radius="var(--r-xs)" />
        <div className={styles.editorGrid}>
          <Skeleton height={560} radius="var(--r-lg)" />
          <Skeleton height={360} radius="var(--r-lg)" />
        </div>
      </div>
    );
  }
  return (
    <TemplateEditor
      key={query.data.template?.id ?? 'new'}
      template={query.data.template}
      courseIds={query.data.courses.map((c) => c.id)}
      allCourses={query.data.allCourses}
    />
  );
}

function TemplateEditor({
  template,
  courseIds,
  allCourses,
}: {
  template: CertificateTemplate | null;
  courseIds: string[];
  allCourses: { id: string; title: string; templateId: string }[];
}) {
  const navigate = useNavigate();
  const toast = useToast();
  const { isMobile } = useViewport();
  const initial = {
    ...(template
      ? {
          name: template.name,
          style: template.style,
          accent: template.accent,
          heading: template.heading,
          statement: template.statement,
          signatories: template.signatories,
          showScore: template.showScore,
          showHours: template.showHours,
        }
      : BLANK),
    courseIds,
  };
  const [form, setForm] = useState(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const leaving = useRef(false);
  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => setForm((f) => ({ ...f, [key]: value }));
  const dirty = JSON.stringify(form) !== JSON.stringify(initial);

  const blocker = useBlocker(({ currentLocation, nextLocation }) => dirty && !leaving.current && currentLocation.pathname !== nextLocation.pathname);
  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  const all = validateTemplate(form);
  const issues: FieldIssue[] = attempt ? all.map((i) => ({ field: `template-${i.field}`, message: i.message })) : [];
  const errorFor = (field: string) => issues.find((i) => i.field === `template-${field}`)?.message;
  const moving = form.courseIds.filter((id) => !courseIds.includes(id) && allCourses.find((c) => c.id === id)?.templateId !== template?.id);

  const save = async (e?: FormEvent) => {
    e?.preventDefault();
    setAttempt((a) => a + 1);
    setError(null);
    if (all.length) return;
    setSaving(true);
    try {
      const saved = await services.certificates.saveTemplate(template?.id ?? null, form);
      leaving.current = true;
      toast({ kind: 'success', title: template ? 'Template saved' : 'Template created', text: `${saved.name} · certificates issued from now on use it` });
      navigate('/admin/certificates/templates');
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSaving(false);
    }
  };

  const setSignatory = (i: number, patch: Partial<{ name: string; title: string }>) =>
    set(
      'signatories',
      form.signatories.map((s, j) => (j === i ? { ...s, ...patch } : s)),
    );
  const actions = (
    <div className={styles.editorActions}>
      <Button onClick={() => navigate('/admin/certificates/templates')} disabled={saving}>
        Cancel
      </Button>
      <Button type="submit" form="template-form" variant="primary" iconStart={<FloppyDisk size={16} />} loading={saving}>
        {template ? 'Save template' : 'Create template'}
      </Button>
    </div>
  );

  return (
    <div className={styles.page}>
      <PageHeader
        back={{ label: 'Templates', to: '/admin/certificates/templates' }}
        title={template ? `Edit ${template.name}` : 'New template'}
        description="Changes apply to certificates issued from now on. Certificates already issued keep the design they were printed with."
        meta={
          template?.isDefault && (
            <Badge tone="accent" icon={<Star size={12} weight="fill" />}>
              Default template
            </Badge>
          )
        }
      />
      <div className={styles.editorGrid}>
        <form id="template-form" className={styles.form} onSubmit={save} noValidate>
          <ErrorSummary issues={issues} attempt={attempt} />
          {error && (
            <InlineMessage kind="error" title="Couldn’t save.">
              {error}
            </InlineMessage>
          )}
          <FormSection id="design" title="Design" description="Layout and colour. The preview updates as you choose.">
            <Field label="Template name" error={errorFor('name')}>
              <Input id="template-name" value={form.name} onChange={(e) => set('name', e.target.value)} placeholder="Advanced programmes" />
            </Field>
            <ChoiceCards
              legend="Layout"
              columns={3}
              value={form.style}
              onChange={(v) => set('style', v)}
              choices={[
                { value: 'classic', label: 'Classic', description: 'Double frame with quiet corner geometry.' },
                { value: 'modern', label: 'Modern', description: 'Aligned left beside a colour band.' },
                { value: 'minimal', label: 'Minimal', description: 'A single rule and plenty of space.' },
              ]}
            />
            <ChoiceCards
              legend="Colour"
              columns={3}
              value={form.accent}
              onChange={(v) => set('accent', v)}
              choices={[
                { value: 'emerald', label: 'Emerald', icon: <span className={cx(styles.swatch, styles.swatchEmerald)} /> },
                { value: 'saffron', label: 'Saffron', icon: <span className={cx(styles.swatch, styles.swatchSaffron)} /> },
                { value: 'indigo', label: 'Indigo', icon: <span className={cx(styles.swatch, styles.swatchIndigo)} /> },
              ]}
            />
          </FormSection>

          <FormSection id="wording" title="Wording" description="The heading and the line that introduces the course.">
            <Field label="Heading" error={errorFor('heading')}>
              <Input id="template-heading" value={form.heading} onChange={(e) => set('heading', e.target.value)} />
            </Field>
            <Field label="Statement" error={errorFor('statement')} hint="Read as: Ananya Rao … this statement … Class 10 Mathematics.">
              <Input id="template-statement" value={form.statement} onChange={(e) => set('statement', e.target.value)} />
            </Field>
            <Switch
              checked={form.showHours}
              onChange={(v) => set('showHours', v)}
              label="Show study hours"
              description="The course length in hours, under the course title."
            />
            <Switch
              checked={form.showScore}
              onChange={(v) => set('showScore', v)}
              label="Show final assessment score"
              description="Leave off for courses graded pass or fail."
            />
          </FormSection>

          <FormSection id="signatories" title="Signatories" description="Printed with a signature line. Up to two.">
            <div id="template-signatories" tabIndex={-1} className={styles.signatories}>
              {form.signatories.map((s, i) => (
                <div key={i} className={styles.signatoryRow}>
                  <Field label={`Name ${i + 1}`} hideLabel>
                    <Input
                      aria-label={`Signatory ${i + 1} name`}
                      value={s.name}
                      onChange={(e) => setSignatory(i, { name: e.target.value })}
                      placeholder="Dr. Meenakshi Iyer"
                    />
                  </Field>
                  <Field label={`Title ${i + 1}`} hideLabel>
                    <Input
                      aria-label={`Signatory ${i + 1} title`}
                      value={s.title}
                      onChange={(e) => setSignatory(i, { title: e.target.value })}
                      placeholder="Dean of Studies"
                    />
                  </Field>
                  <IconButton
                    label={`Remove signatory ${i + 1}`}
                    icon={<Trash size={16} />}
                    disabled={form.signatories.length <= 1}
                    onClick={() =>
                      set(
                        'signatories',
                        form.signatories.filter((_, j) => j !== i),
                      )
                    }
                  />
                </div>
              ))}
              {errorFor('signatories') && <p className={styles.error}>{errorFor('signatories')}</p>}
              {form.signatories.length < 2 && (
                <Button
                  size="sm"
                  variant="ghost"
                  iconStart={<Plus size={14} />}
                  onClick={() => set('signatories', [...form.signatories, { name: '', title: '' }])}
                >
                  Add signatory
                </Button>
              )}
            </div>
          </FormSection>

          <FormSection id="courses" title="Courses" description="Courses that print on this template. A course can use one template at a time.">
            <ul className={styles.courseChecks}>
              {allCourses.map((c) => {
                const elsewhere = c.templateId !== template?.id && !courseIds.includes(c.id);
                return (
                  <li key={c.id}>
                    <Checkbox
                      checked={form.courseIds.includes(c.id)}
                      onChange={(e) => set('courseIds', e.target.checked ? [...form.courseIds, c.id] : form.courseIds.filter((id) => id !== c.id))}
                      label={
                        <span className={styles.stack}>
                          <span>{c.title}</span>
                          {elsewhere && <span className={styles.cellMeta}>Currently on another template</span>}
                        </span>
                      }
                    />
                  </li>
                );
              })}
            </ul>
            {moving.length > 0 && (
              <InlineMessage kind="info" title={`${plural(moving.length, 'course')} will move to this template`}>
                Their next certificates print on it. Certificates already issued don’t change.
              </InlineMessage>
            )}
          </FormSection>
        </form>

        <aside className={styles.previewSide} aria-label="Preview">
          <p className={styles.previewLabel}>
            <CheckCircle size={14} aria-hidden="true" /> Live preview with sample details
          </p>
          <CertificateDocument template={form} {...SAMPLE} />
          {!isMobile && actions}
        </aside>
      </div>

      {isMobile && (
        <StickyActionBar mobile={<div className={styles.mobileBar}>{actions}</div>}>
          <span />
        </StickyActionBar>
      )}

      <Modal
        open={blocker.state === 'blocked'}
        onClose={() => blocker.reset?.()}
        title="Leave without saving?"
        description="Your changes to this template haven’t been saved."
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
