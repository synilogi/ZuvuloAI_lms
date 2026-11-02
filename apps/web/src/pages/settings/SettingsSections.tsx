import { Link } from 'react-router-dom';
import type {
  CourseFormat,
  CourseVisibility,
  EnrollmentPolicy,
  LatePolicy,
  LessonCompletionRule,
  ReleasePolicy,
  CourseCompletionRule,
} from '@syniastrolms/domain';
import { ChoiceCards, FormSection, Switch } from '@/components/forms/Forms';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { Field, Input, Select } from '@/components/ui/Field/Field';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { useSession } from '@/providers/SessionProvider';
import { numberValue, SettingsForm, toNumber } from './SettingsForm';
import styles from './Settings.module.css';

/* ─── General ─── */

export function GeneralSettingsPage() {
  return (
    <SettingsForm section="general" description="The platform’s name and the defaults new courses and lessons start with.">
      {({ value: v, update, errorFor }) => (
        <>
          <FormSection id="academy" title="Platform" description="How the platform introduces itself to learners.">
            <div className={styles.twoUp}>
              <Field label="Platform name" error={errorFor('academyName')}>
                <Input id="academyName" value={v.academyName} onChange={(e) => update({ academyName: e.target.value })} maxLength={60} />
              </Field>
              <Field label="Support email" error={errorFor('supportEmail')} hint="Printed in emails and on help pages.">
                <Input id="supportEmail" type="email" value={v.supportEmail} onChange={(e) => update({ supportEmail: e.target.value })} />
              </Field>
              <Field label="Learner language">
                <Select value={v.language} onChange={(e) => update({ language: e.target.value as typeof v.language })}>
                  <option value="en-IN">English (India)</option>
                  <option value="hi-IN">हिन्दी — Hindi</option>
                </Select>
              </Field>
            </div>
          </FormSection>

          <FormSection id="enrolment" title="Enrolment" description="Defaults for new courses. Each course can change them.">
            <ChoiceCards<CourseVisibility>
              legend="Course visibility"
              columns={3}
              value={v.defaultVisibility}
              onChange={(defaultVisibility) => update({ defaultVisibility })}
              choices={[
                { value: 'public', label: 'Public', description: 'Listed in the catalog for everyone.' },
                { value: 'unlisted', label: 'Unlisted', description: 'Reachable by link, not listed.' },
                { value: 'private', label: 'Private', description: 'Only invited learners see it.' },
              ]}
            />
            <ChoiceCards<EnrollmentPolicy>
              legend="How learners enrol"
              columns={3}
              value={v.enrollment}
              onChange={(enrollment) => update({ enrollment })}
              choices={[
                { value: 'open', label: 'Open', description: 'Anyone can enrol straight away.' },
                { value: 'approval', label: 'On approval', description: 'Requests wait for an admin.' },
                { value: 'invite', label: 'Invite only', description: 'Admins enrol learners themselves.' },
              ]}
            />
            <Field label="Access after enrolling" className={styles.narrow}>
              <Select
                value={v.accessMonths === null ? 'lifetime' : String(v.accessMonths)}
                onChange={(e) => update({ accessMonths: e.target.value === 'lifetime' ? null : Number(e.target.value) })}
              >
                <option value="6">6 months</option>
                <option value="12">12 months</option>
                <option value="24">24 months</option>
                <option value="lifetime">Lifetime</option>
              </Select>
            </Field>
          </FormSection>

          <FormSection id="lessons" title="New lessons" description="What a lesson starts with when an instructor adds it.">
            <Field label="Default length" error={errorFor('lessonDuration')} hint="Minutes" className={styles.narrow}>
              <Input
                id="lessonDuration"
                type="number"
                inputMode="numeric"
                min={1}
                max={240}
                value={numberValue(v.lessonDefaults.durationMin)}
                onChange={(e) => update({ lessonDefaults: { ...v.lessonDefaults, durationMin: toNumber(e.target.value) } })}
              />
            </Field>
            <ChoiceCards<LessonCompletionRule>
              legend="A lesson is finished when"
              columns={3}
              value={v.lessonDefaults.completion}
              onChange={(completion) => update({ lessonDefaults: { ...v.lessonDefaults, completion } })}
              choices={[
                { value: 'view', label: 'It’s opened', description: 'Quickest; suits short readings.' },
                { value: 'time', label: 'Most of it is watched', description: 'Uses the progress rule in Learning.' },
                { value: 'check', label: 'Its check is passed', description: 'For lessons with a question at the end.' },
              ]}
            />
            <div className={styles.switches}>
              <Switch
                checked={v.lessonDefaults.allowComments}
                onChange={(allowComments) => update({ lessonDefaults: { ...v.lessonDefaults, allowComments } })}
                label="Discussion under lessons"
                description="Learners can ask questions on the lesson page."
              />
              <Switch
                checked={v.lessonDefaults.allowDownloads}
                onChange={(allowDownloads) => update({ lessonDefaults: { ...v.lessonDefaults, allowDownloads } })}
                label="Downloadable resources"
                description="Worksheets and PDFs can be saved for offline study."
              />
              <Switch
                checked={v.lessonDefaults.previewFirstLesson}
                onChange={(previewFirstLesson) => update({ lessonDefaults: { ...v.lessonDefaults, previewFirstLesson } })}
                label="First lesson is a free preview"
                description="Visitors can watch it before enrolling."
              />
            </div>
          </FormSection>
        </>
      )}
    </SettingsForm>
  );
}

/* ─── Courses ─── */

export function CourseSettingsPage() {
  const { role } = useSession();
  return (
    <SettingsForm section="courses" description="Defaults for new courses, how they are published and what the catalog shows.">
      {({ value: v, update, errorFor }) => (
        <>
          <FormSection id="course-defaults" title="New courses" description="Where a course starts when an instructor creates it.">
            <ChoiceCards<CourseFormat>
              legend="Format"
              columns={3}
              value={v.defaultFormat}
              onChange={(defaultFormat) => update({ defaultFormat })}
              choices={[
                { value: 'self-paced', label: 'Self-paced', description: 'Learners study on their own schedule.' },
                { value: 'cohort', label: 'Cohort', description: 'A group starts together, with deadlines.' },
                { value: 'hybrid', label: 'Hybrid', description: 'Self-paced lessons with live classes.' },
              ]}
            />
            <ChoiceCards<ReleasePolicy>
              legend="Chapters open"
              columns={3}
              value={v.release}
              onChange={(release) => update({ release })}
              choices={[
                { value: 'all-at-once', label: 'All at once', description: 'Every chapter is open from enrolling.' },
                { value: 'sequential', label: 'In order', description: 'Each chapter opens as the last one ends.' },
                { value: 'scheduled', label: 'On dates', description: 'Chapters open on set days — for cohorts.' },
              ]}
            />
            <div className={styles.twoUp}>
              {/* Prices are each course's own (Free or Paid, in its editor); there is no academy-wide default any more. */}
              <p className={styles.fieldNote}>
                Each course is Free or Paid, set in its editor.
                {role === 'superadmin' && (
                  <>
                    {' '}
                    Paid courses are sold through <Link to="/superadmin/payment-gateways">Course payments</Link>.
                  </>
                )}
              </p>
              <Field label="Instructors per course" error={errorFor('maxInstructors')} hint="1 to 5">
                <Input
                  id="maxInstructors"
                  type="number"
                  inputMode="numeric"
                  min={1}
                  max={5}
                  value={numberValue(v.maxInstructors)}
                  onChange={(e) => update({ maxInstructors: toNumber(e.target.value) })}
                />
              </Field>
            </div>
          </FormSection>

          <FormSection id="publishing" title="Publishing" description="Keeps the catalog tidy.">
            <div className={styles.switches}>
              <Switch
                checked={v.requireReview}
                onChange={(requireReview) => update({ requireReview })}
                label="Review before publishing"
                description="Instructors send a course to an admin, who publishes it."
              />
            </div>
            <Field label="Archive courses nobody has opened for" className={styles.narrow}>
              <Select
                value={v.archiveInactiveMonths === null ? 'never' : String(v.archiveInactiveMonths)}
                onChange={(e) => update({ archiveInactiveMonths: e.target.value === 'never' ? null : Number(e.target.value) })}
              >
                <option value="never">Never archive</option>
                <option value="12">12 months</option>
                <option value="18">18 months</option>
                <option value="24">24 months</option>
              </Select>
            </Field>
          </FormSection>

          <FormSection id="catalog" title="In the catalog" description="What learners see before they enrol.">
            <div className={styles.switches}>
              <Switch
                checked={v.showRatings}
                onChange={(showRatings) => update({ showRatings })}
                label="Show ratings"
                description="Stars and the number of ratings on course cards."
              />
            </div>
            <Field label="Show ratings after" error={errorFor('minRatings')} hint="Ratings" className={styles.narrow}>
              <Input
                id="minRatings"
                type="number"
                inputMode="numeric"
                min={1}
                max={50}
                disabled={!v.showRatings}
                value={numberValue(v.minRatings)}
                onChange={(e) => update({ minRatings: toNumber(e.target.value) })}
              />
            </Field>
            <div className={styles.switches}>
              <Switch
                checked={v.showEnrolmentCount}
                onChange={(showEnrolmentCount) => update({ showEnrolmentCount })}
                label="Show how many learners enrolled"
                description="“2,846 learners” on the course page."
              />
            </div>
          </FormSection>
        </>
      )}
    </SettingsForm>
  );
}

/* ─── Learning ─── */

export function LearningSettingsPage() {
  return (
    <SettingsForm section="learning" description="How progress is counted, when a course is finished, and what learners can change for themselves.">
      {({ value: v, update, errorFor }) => (
        <>
          <FormSection id="progress-rules" title="Progress" description="How lessons and courses are marked as finished.">
            <Field
              label="A video or reading counts as finished at"
              error={errorFor('completionThreshold')}
              hint="Percent watched or read"
              className={styles.narrow}
            >
              <Input
                id="completionThreshold"
                type="number"
                inputMode="numeric"
                min={50}
                max={100}
                step={5}
                value={numberValue(v.completionThreshold)}
                onChange={(e) => update({ completionThreshold: toNumber(e.target.value) })}
              />
            </Field>
            <ChoiceCards<CourseCompletionRule>
              legend="A course is finished when a learner has"
              columns={3}
              value={v.courseCompletion}
              onChange={(courseCompletion) => update({ courseCompletion })}
              choices={[
                { value: 'all-lessons', label: 'Finished every lesson', description: 'Quizzes and assignments are optional.' },
                { value: 'lessons-and-assessments', label: 'Lessons and passed assessments', description: 'Every lesson, quiz and assignment.' },
                { value: 'percentage', label: 'Finished a share of lessons', description: 'For courses with optional material.' },
              ]}
            />
            {v.courseCompletion === 'percentage' && (
              <Field label="Share of lessons" error={errorFor('completionPercent')} hint="Percent" className={styles.narrow}>
                <Input
                  id="completionPercent"
                  type="number"
                  inputMode="numeric"
                  min={50}
                  max={100}
                  step={5}
                  value={numberValue(v.completionPercent)}
                  onChange={(e) => update({ completionPercent: toNumber(e.target.value) })}
                />
              </Field>
            )}
            <div className={styles.switches}>
              <Switch
                checked={v.chapterGate}
                onChange={(chapterGate) => update({ chapterGate })}
                label="Pass each chapter’s quiz to open the next"
                description="Keeps learners from skipping ahead of what they understand."
              />
            </div>
          </FormSection>

          <FormSection id="assessment-rules" title="Quizzes and assignments" description="Defaults for new quizzes and assignments.">
            <div className={styles.twoUp}>
              <Field label="Quiz attempts" error={errorFor('quizAttempts')} hint="The higher score counts">
                <Input
                  id="quizAttempts"
                  type="number"
                  inputMode="numeric"
                  min={1}
                  max={10}
                  value={numberValue(v.quizAttempts)}
                  onChange={(e) => update({ quizAttempts: toNumber(e.target.value) })}
                />
              </Field>
              <Field label="Wait before a retake">
                <Select value={String(v.retakeWaitHours)} onChange={(e) => update({ retakeWaitHours: Number(e.target.value) })}>
                  <option value="0">No wait</option>
                  <option value="12">12 hours</option>
                  <option value="24">A day</option>
                  <option value="48">Two days</option>
                  <option value="72">Three days</option>
                </Select>
              </Field>
            </div>
            <ChoiceCards<LatePolicy>
              legend="Late assignments"
              columns={3}
              value={v.latePolicy}
              onChange={(latePolicy) => update({ latePolicy })}
              choices={[
                { value: 'accept', label: 'Accept', description: 'Marked late, scored as normal.' },
                { value: 'penalty', label: 'Accept with a penalty', description: 'A share of the score is taken off.' },
                { value: 'reject', label: 'Don’t accept', description: 'Handing in closes at the deadline.' },
              ]}
            />
            {v.latePolicy === 'penalty' && (
              <Field label="Penalty" error={errorFor('latePenalty')} hint="Percent of the score" className={styles.narrow}>
                <Input
                  id="latePenalty"
                  type="number"
                  inputMode="numeric"
                  min={1}
                  max={100}
                  value={numberValue(v.latePenalty)}
                  onChange={(e) => update({ latePenalty: toNumber(e.target.value) })}
                />
              </Field>
            )}
          </FormSection>

          <FormSection id="risk" title="Learners at risk" description="When a learner with a course in progress shows as at risk on dashboards and reports.">
            <Field label="Quiet days before at risk" error={errorFor('atRiskDays')} hint="Inactive starts at 45 days" className={styles.narrow}>
              <Input
                id="atRiskDays"
                type="number"
                inputMode="numeric"
                min={3}
                max={44}
                value={numberValue(v.atRiskDays)}
                onChange={(e) => update({ atRiskDays: toNumber(e.target.value) })}
              />
            </Field>
          </FormSection>

          <FormSection id="learner-preferences" title="Learner preferences" description="What learners can choose for themselves.">
            <div className={styles.switches}>
              {(
                [
                  ['playbackSpeed', 'Playback speed', 'Learners can play lessons from 0.75× to 2×.'],
                  ['captionsByDefault', 'Captions on by default', 'Learners can still turn them off.'],
                  ['downloadNotes', 'Download their notes', 'Lesson notes can be saved as a PDF.'],
                  ['showRank', 'Show their rank', 'The rank and next milestone appear in the sidebar.'],
                  ['studyReminders', 'Study reminders', 'Learners can set a daily study time and get a nudge.'],
                ] as const
              ).map(([key, label, description]) => (
                <Switch
                  key={key}
                  checked={v.learnerPreferences[key]}
                  onChange={(on) => update({ learnerPreferences: { ...v.learnerPreferences, [key]: on } })}
                  label={label}
                  description={description}
                />
              ))}
            </div>
          </FormSection>
        </>
      )}
    </SettingsForm>
  );
}

/* ─── Notifications ─── */

const REMINDERS = [
  { minutes: 1440, label: 'A day before' },
  { minutes: 60, label: 'An hour before' },
  { minutes: 15, label: '15 minutes before' },
];

export function AcademyNotificationSettingsPage() {
  return (
    <SettingsForm section="notifications" description="What the platform sends to learners and staff, and who it comes from.">
      {({ value: v, update, errorFor }) => (
        <>
          <InlineMessage kind="info" title="People still choose for themselves.">
            These are what the platform sends. Each learner and instructor can turn off what they don’t want in their own{' '}
            <Link to="/admin/notifications/preferences">notification preferences</Link>.
          </InlineMessage>
          <FormSection id="sender" title="Sender" description="How emails and text messages are signed.">
            <div className={styles.twoUp}>
              <Field label="Sender name" error={errorFor('senderName')}>
                <Input id="senderName" value={v.senderName} onChange={(e) => update({ senderName: e.target.value })} />
              </Field>
              <Field label="Reply-to email" error={errorFor('replyTo')} hint="Where replies to platform emails go.">
                <Input id="replyTo" type="email" value={v.replyTo} onChange={(e) => update({ replyTo: e.target.value })} />
              </Field>
            </div>
            <div className={styles.switches}>
              <Switch
                checked={v.smsEnabled}
                onChange={(smsEnabled) => update({ smsEnabled })}
                label="Text messages"
                description="For live classes and deadlines. Learners opt in on their own preferences."
              />
            </div>
          </FormSection>

          <FormSection id="to-learners" title="To learners" description="Sent automatically as learners study.">
            <div className={styles.switches}>
              <Switch
                checked={v.learner.enrolmentConfirmation}
                onChange={(on) => update({ learner: { ...v.learner, enrolmentConfirmation: on } })}
                label="Enrolment confirmation"
                description="With how to start and when access ends."
              />
              <Switch
                checked={v.learner.weeklyDigest}
                onChange={(on) => update({ learner: { ...v.learner, weeklyDigest: on } })}
                label="Weekly progress summary"
                description="Monday morning: what they finished and what’s next."
              />
              <Switch
                checked={v.learner.inactivityNudge}
                onChange={(on) => update({ learner: { ...v.learner, inactivityNudge: on } })}
                label="Nudge when a learner goes quiet"
                description="Sent when they reach the at-risk days set in Learning."
              />
              <Switch
                checked={v.learner.certificateIssued}
                onChange={(on) => update({ learner: { ...v.learner, certificateIssued: on } })}
                label="Certificate issued"
                description="With the link to download and share it."
              />
            </div>
            <fieldset className={styles.fieldset}>
              <legend className={styles.legend}>Live class reminders</legend>
              <div className={styles.checks}>
                {REMINDERS.map((r) => (
                  <Checkbox
                    key={r.minutes}
                    label={r.label}
                    checked={v.learner.liveReminderMinutes.includes(r.minutes)}
                    onChange={(e) =>
                      update({
                        learner: {
                          ...v.learner,
                          liveReminderMinutes: (e.target.checked
                            ? [...v.learner.liveReminderMinutes, r.minutes]
                            : v.learner.liveReminderMinutes.filter((m) => m !== r.minutes)
                          ).sort((a, b) => b - a),
                        },
                      })
                    }
                  />
                ))}
              </div>
            </fieldset>
            <Field
              label="Remind about assignment deadlines"
              error={errorFor('assignmentReminderDays')}
              hint="Days before · 0 for no reminder"
              className={styles.narrow}
            >
              <Input
                id="assignmentReminderDays"
                type="number"
                inputMode="numeric"
                min={0}
                max={14}
                value={numberValue(v.learner.assignmentReminderDays)}
                onChange={(e) => update({ learner: { ...v.learner, assignmentReminderDays: toNumber(e.target.value) } })}
              />
            </Field>
          </FormSection>

          <FormSection id="to-staff" title="To instructors and admins" description="Work that needs someone’s attention.">
            <div className={styles.switches}>
              <Switch
                checked={v.staff.newSubmission}
                onChange={(on) => update({ staff: { ...v.staff, newSubmission: on } })}
                label="New submissions"
                description="To the course’s instructors."
              />
              <Switch
                checked={v.staff.reviewOverdue}
                onChange={(on) => update({ staff: { ...v.staff, reviewOverdue: on } })}
                label="Reviews past 48 hours"
                description="To the reviewer, and a daily roll-up to admins."
              />
              <Switch
                checked={v.staff.dailyEnrolments}
                onChange={(on) => update({ staff: { ...v.staff, dailyEnrolments: on } })}
                label="Daily enrolment summary"
                description="One email each evening to admins."
              />
              <Switch
                checked={v.staff.courseReview}
                onChange={(on) => update({ staff: { ...v.staff, courseReview: on } })}
                label="Courses waiting for review"
                description="To admins, when an instructor sends one."
              />
            </div>
          </FormSection>
        </>
      )}
    </SettingsForm>
  );
}
