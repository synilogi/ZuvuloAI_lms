import { Play } from '@phosphor-icons/react';
import type { AppearanceSettings, BrandAccent, CertificateSettings } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { cx } from '@/lib/cx';
import { ChoiceCards, FormSection, Switch } from '@/components/forms/Forms';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { CertificateDocument } from '@/components/lms/certificate/CertificateDocument';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { services, type TemplateSummary } from '@/services';
import { numberValue, SettingsForm, toNumber } from './SettingsForm';
import styles from './Settings.module.css';

/* ─── Certificates ─── */

function CertificatePreview({ value, templates }: { value: CertificateSettings; templates?: TemplateSummary[] }) {
  const summary = templates?.find((t) => t.template.id === value.defaultTemplateId) ?? templates?.[0];
  return (
    <div className={styles.previewCard}>
      <span className={styles.previewLabel}>Preview</span>
      {!summary ? (
        <Skeleton height={220} radius="var(--r-md)" />
      ) : (
        <div className={cx(styles.certificateFrame, !value.enabled && styles.dimmed)}>
          <CertificateDocument
            template={{
              ...summary.template,
              showHours: value.fields.hours,
              showScore: value.fields.score,
              signatories: value.fields.signatures ? summary.template.signatories : [],
            }}
            learnerName="Ananya Rao"
            courseTitle="Class 10 Science"
            levelTitle={value.fields.level ? 'Beginner' : undefined}
            completedAt="2026-06-02T12:00:00+05:30"
            issuedAt="2026-06-02T12:00:00+05:30"
            credentialId={`${value.credentialPrefix || 'SA'}-JY-2026-04817`}
            hours={14}
            finalScore={88}
          />
        </div>
      )}
      <p className={styles.previewNote}>
        {value.enabled
          ? `${summary?.template.name ?? 'The default template'}${value.publicVerification ? ' · anyone can verify it with the credential ID' : ' · verification is private'}.`
          : 'Certificates are switched off — learners won’t see certificate requirements on courses.'}
      </p>
    </div>
  );
}

export function CertificateSettingsPage() {
  const templates = useAsync('settings-templates', () => services.certificates.listTemplates());
  return (
    <SettingsForm
      section="certificates"
      description="Whether courses award certificates, what they show and how they can be checked."
      preview={(value) => <CertificatePreview value={value} templates={templates.data} />}
    >
      {({ value: v, update, errorFor }) => (
        <>
          <div className={styles.switches}>
            <Switch
              checked={v.enabled}
              onChange={(enabled) => update({ enabled })}
              label="Award certificates"
              description="Courses with a certificate show its requirements and award it on completion."
            />
          </div>
          {!v.enabled && <InlineMessage kind="warn">Certificates already issued stay valid and can still be verified.</InlineMessage>}

          <FormSection id="issuing" title="Issuing" description="When a finished course becomes a certificate.">
            <ChoiceCards<'auto' | 'review'>
              legend="Issue"
              columns={2}
              value={v.autoIssue ? 'auto' : 'review'}
              onChange={(choice) => update({ autoIssue: choice === 'auto' })}
              choices={[
                { value: 'auto', label: 'Automatically', description: 'As soon as a learner meets the requirements.' },
                { value: 'review', label: 'After an admin checks', description: 'They wait in Certificates → Ready to issue.' },
              ]}
            />
            <div className={styles.twoUp}>
              <Field label="Minimum final score" error={errorFor('minScore')} hint="Percent on the final assessment">
                <Input
                  id="minScore"
                  type="number"
                  inputMode="numeric"
                  min={0}
                  max={100}
                  disabled={!v.enabled}
                  value={numberValue(v.minScore)}
                  onChange={(e) => update({ minScore: toNumber(e.target.value) })}
                />
              </Field>
              <Field label="Valid for">
                <Select
                  disabled={!v.enabled}
                  value={v.validityMonths === null ? 'never' : String(v.validityMonths)}
                  onChange={(e) => update({ validityMonths: e.target.value === 'never' ? null : Number(e.target.value) })}
                >
                  <option value="never">Never expires</option>
                  <option value="12">12 months</option>
                  <option value="24">24 months</option>
                  <option value="36">36 months</option>
                </Select>
              </Field>
            </div>
          </FormSection>

          <FormSection id="on-certificate" title="On the certificate" description="The template and details printed for new certificates.">
            <Field label="Default template" error={errorFor('defaultTemplateId')}>
              <Select
                id="defaultTemplateId"
                disabled={!v.enabled || !templates.data}
                value={v.defaultTemplateId}
                onChange={(e) => update({ defaultTemplateId: e.target.value })}
              >
                {templates.data ? (
                  templates.data.map((t) => (
                    <option key={t.template.id} value={t.template.id}>
                      {t.template.name}
                    </option>
                  ))
                ) : (
                  <option value={v.defaultTemplateId}>Loading templates…</option>
                )}
              </Select>
            </Field>
            <fieldset className={styles.fieldset} disabled={!v.enabled}>
              <legend className={styles.legend}>Show</legend>
              <div className={styles.checks}>
                <Checkbox label="Hours of study" checked={v.fields.hours} onChange={(e) => update({ fields: { ...v.fields, hours: e.target.checked } })} />
                <Checkbox
                  label="Final assessment score"
                  checked={v.fields.score}
                  onChange={(e) => update({ fields: { ...v.fields, score: e.target.checked } })}
                />
                <Checkbox label="Course level" checked={v.fields.level} onChange={(e) => update({ fields: { ...v.fields, level: e.target.checked } })} />
                <Checkbox
                  label="Signatures"
                  checked={v.fields.signatures}
                  onChange={(e) => update({ fields: { ...v.fields, signatures: e.target.checked } })}
                />
              </div>
              <p className={styles.fieldNote}>The learner’s name, the course, the completion date and the credential ID are always shown.</p>
            </fieldset>
            <div className={styles.twoUp}>
              <Field label="Credential ID prefix" error={errorFor('credentialPrefix')} hint="2 to 4 capital letters">
                <Input
                  id="credentialPrefix"
                  value={v.credentialPrefix}
                  maxLength={4}
                  onChange={(e) => update({ credentialPrefix: e.target.value.toUpperCase().replace(/[^A-Z]/g, '') })}
                />
              </Field>
            </div>
            <div className={styles.switches}>
              <Switch
                checked={v.publicVerification}
                onChange={(publicVerification) => update({ publicVerification })}
                label="Public verification"
                description="Anyone with a credential ID can confirm a certificate is genuine."
              />
            </div>
          </FormSection>
        </>
      )}
    </SettingsForm>
  );
}

/* ─── Appearance ─── */

const ACCENTS: { value: BrandAccent; label: string }[] = [
  { value: 'emerald', label: 'Emerald' },
  { value: 'saffron', label: 'Saffron' },
  { value: 'indigo', label: 'Indigo' },
  { value: 'plum', label: 'Plum' },
];

function AppearancePreview({ value }: { value: AppearanceSettings }) {
  const dark = value.learnerTheme === 'dark';
  return (
    <div className={styles.previewCard}>
      <span className={styles.previewLabel}>Learner home preview</span>
      <div
        className={styles.brandPreview}
        data-accent={value.accent}
        data-theme-preview={dark ? 'dark' : 'light'}
        data-density={value.density}
        role="img"
        aria-label={`Preview of the learner home: ${value.brandName}, ${value.accent} accent, ${dark ? 'dark' : 'light'} theme, ${value.density} spacing`}
      >
        <div className={styles.pvTop}>
          <span className={styles.pvMark}>{(value.brandName.trim()[0] ?? 'a').toLowerCase()}</span>
          <span className={styles.pvBrand}>
            <strong>{value.brandName.trim() || 'ZuviloAI'}</strong>
            <span>Learning</span>
          </span>
        </div>
        <p className={styles.pvGreeting}>Good evening, Ananya</p>
        <p className={styles.pvWelcome}>{value.welcomeMessage.trim() || 'Your next lesson is waiting.'}</p>
        <div className={styles.pvCourse}>
          {value.coverArt ? <CourseCover motif="houses" className={styles.pvCover} /> : <span className={styles.pvCoverPlain} />}
          <div className={styles.pvCourseText}>
            <span className={styles.pvEyebrow}>Chapter 3 · lesson 5</span>
            <strong>Quadratic equations: the discriminant</strong>
            <span className={styles.pvBar}>
              <span style={{ width: '38%' }} />
            </span>
            <span className={styles.pvMeta}>38% of Class 10 Mathematics</span>
          </div>
        </div>
        <span className={styles.pvButton}>
          <Play size={12} weight="fill" /> Resume lesson
        </span>
      </div>
      <p className={styles.previewNote}>
        {value.learnerTheme === 'system'
          ? 'Shown light; learners on a dark device see the dark theme.'
          : `Learners start in the ${value.learnerTheme} theme and can switch.`}
      </p>
    </div>
  );
}

export function AppearanceSettingsPage() {
  return (
    <SettingsForm
      section="appearance"
      description="How the learner app looks. The preview updates as you change things."
      preview={(value) => <AppearancePreview value={value} />}
    >
      {({ value: v, update, errorFor }) => (
        <>
          <FormSection id="brand" title="Brand" description="The name and colour learners see.">
            <Field label="Brand name" error={errorFor('brandName')}>
              <Input id="brandName" value={v.brandName} maxLength={40} onChange={(e) => update({ brandName: e.target.value })} />
            </Field>
            <fieldset className={styles.fieldset}>
              <legend className={styles.legend}>Accent colour</legend>
              <div className={styles.swatches} role="radiogroup" aria-label="Accent colour">
                {ACCENTS.map((a) => (
                  <label key={a.value} className={styles.swatch} data-accent={a.value}>
                    <input type="radio" name="accent" value={a.value} checked={v.accent === a.value} onChange={() => update({ accent: a.value })} />
                    <span className={styles.swatchDot} aria-hidden="true" />
                    {a.label}
                  </label>
                ))}
              </div>
              <p className={styles.fieldNote}>Used for buttons, progress and links. Status colours — live, overdue, passed — stay the same.</p>
            </fieldset>
            <Field
              label="Welcome message"
              error={errorFor('welcomeMessage')}
              hint={`${v.welcomeMessage.trim().length} of 160 characters · under the greeting on learner home`}
            >
              <Textarea id="welcomeMessage" rows={2} value={v.welcomeMessage} onChange={(e) => update({ welcomeMessage: e.target.value })} />
            </Field>
          </FormSection>

          <FormSection id="learner-app" title="Learner app" description="Starting points; learners can change the theme for themselves.">
            <ChoiceCards<AppearanceSettings['learnerTheme']>
              legend="Theme"
              columns={3}
              value={v.learnerTheme}
              onChange={(learnerTheme) => update({ learnerTheme })}
              choices={[
                { value: 'system', label: 'Match the device', description: 'Light or dark, as the learner’s device is set.' },
                { value: 'light', label: 'Light', description: 'Off-white pages, best in daylight.' },
                { value: 'dark', label: 'Dark', description: 'Easier on the eyes for evening study.' },
              ]}
            />
            <ChoiceCards<AppearanceSettings['density']>
              legend="Spacing"
              columns={2}
              value={v.density}
              onChange={(density) => update({ density })}
              choices={[
                { value: 'comfortable', label: 'Comfortable', description: 'Room to breathe — the default.' },
                { value: 'compact', label: 'Compact', description: 'More on screen for dense course lists.' },
              ]}
            />
            <div className={styles.switches}>
              <Switch
                checked={v.coverArt}
                onChange={(coverArt) => update({ coverArt })}
                label="Course cover art"
                description="Line-drawn charts on course cards, generated from each course’s theme."
              />
            </div>
          </FormSection>
        </>
      )}
    </SettingsForm>
  );
}
