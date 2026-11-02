import { useState } from 'react';
import { Archive, Globe, LinkSimple, LockSimple } from '@phosphor-icons/react';
import type { CategoryGlyph as CategoryGlyphName, CourseStatus } from '@syniastrolms/domain';
import { CategoryGlyph, glyphLabels } from '@/components/lms/course/CategoryGlyph';
import { ChoiceCards, ErrorSummary, ListInput, Switch, TagInput } from '@/components/forms/Forms';
import { Button } from '@/components/ui/Button/Button';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CourseStatusBadge } from '@/components/lms/course/CourseStatus';
import { Column, Columns, DocSection, Notes, Specimen } from '../doc/Doc';
import styles from './Chapters.module.css';

/** Form controls beyond the shell's inputs, and the pattern for decisions with consequences. */
export function FormsSection() {
  const toast = useToast();
  const [visibility, setVisibility] = useState('public');
  const [certificate, setCertificate] = useState(true);
  const [tags, setTags] = useState(['Algebra', 'Board exams']);
  const [outcomes, setOutcomes] = useState(['Solve quadratic equations by factorisation', 'Find the nature of the roots']);
  const [confirming, setConfirming] = useState(false);
  const [glyph, setGlyph] = useState<CategoryGlyphName>('nakshatra');

  return (
    <DocSection
      id="forms"
      index={9}
      title="Forms and decisions"
      lead="Long forms are split into titled sections with the explanation beside the fields. Errors are summarised at the top with links to each field. Anything with consequences — publishing, archiving — goes through a dialog that lists what will happen before the button that does it."
      api={['FormSection', 'ChoiceCards', 'Switch', 'TagInput', 'ListInput', 'ErrorSummary', 'ConfirmDialog', 'CourseStatusBadge']}
    >
      <Columns>
        <Column title="Choice cards" caption="A radio group for options that need a sentence each.">
          <ChoiceCards
            legend="Visibility after publishing"
            columns={1}
            value={visibility}
            onChange={setVisibility}
            choices={[
              { value: 'public', label: 'Public', description: 'Listed in the catalog and search.', icon: <Globe size={18} /> },
              { value: 'unlisted', label: 'Unlisted', description: 'Anyone with the link can enrol.', icon: <LinkSimple size={18} /> },
              { value: 'private', label: 'Private', description: 'Only invited learners can enrol.', icon: <LockSimple size={18} /> },
            ]}
          />
        </Column>
        <Column title="Switch, tags and lists" caption="Switches apply to the form value; tags and ordered lists edit in place.">
          <div className={styles.formStack}>
            <Switch checked={certificate} onChange={setCertificate} label="Award a certificate" description="Issued when completion rules are met." />
            <TagInput label="Tags" value={tags} onChange={setTags} suggestions={['Divisional charts', 'D9', 'Marriage']} />
            <ListInput label="Outcome" value={outcomes} onChange={setOutcomes} addLabel="Add outcome" min={3} max={6} />
          </div>
        </Column>
      </Columns>

      <Specimen
        label="Visual choices · category emblems"
        notes={<Notes items={[{ term: 'Emblems', text: 'Categories use the covers’ fine-line language, reduced to a mark that reads at 24px.' }]} />}
      >
        <ChoiceCards
          legend="Emblem"
          hideLegend
          columns={4}
          value={glyph}
          onChange={setGlyph}
          choices={(['sun', 'moon', 'houses', 'orbits', 'nakshatra', 'hourglass', 'lotus', 'compass'] as const).map((g) => ({
            value: g,
            label: glyphLabels[g],
            visual: <CategoryGlyph glyph={g} size={44} />,
          }))}
        />
      </Specimen>

      <Specimen
        label="Error summary and a decision"
        surface="panel"
        notes={
          <Notes
            items={[
              { term: 'Summary', text: 'Takes focus when a submit fails; each line moves focus to its field.' },
              { term: 'Consequences', text: 'Listed before the action. Destructive actions need an explicit acknowledgement.' },
              { term: 'Failure', text: 'The dialog stays open and shows the error — nothing is lost.' },
            ]}
          />
        }
      >
        <div className={styles.formStack}>
          <ErrorSummary
            issues={[
              { field: 'ds-missing-title', message: 'Give the course a title.' },
              { field: 'ds-missing-category', message: 'Choose a category.' },
            ]}
          />
          <div className={styles.inlineRow}>
            {(['draft', 'published', 'archived'] as CourseStatus[]).map((s) => (
              <CourseStatusBadge key={s} status={s} />
            ))}
            <Button variant="danger" iconStart={<Archive size={16} />} onClick={() => setConfirming(true)}>
              Archive course…
            </Button>
          </div>
        </div>
        <ConfirmDialog
          open={confirming}
          onClose={() => setConfirming(false)}
          onConfirm={async () => {
            await new Promise((r) => setTimeout(r, 900));
            setConfirming(false);
            toast({ kind: 'success', title: 'Specimen archived', text: 'Nothing was changed — this is the design system.' });
          }}
          tone="danger"
          icon={<Archive size={20} />}
          title="Archive this course?"
          description="Class 10 Mathematics"
          confirmLabel="Archive course"
          acknowledge="I understand new learners can no longer enrol"
        >
          <ul className={styles.impactList}>
            <li>The course closes to new enrollments and leaves every catalog.</li>
            <li>522 enrolled learners keep access to lessons and recordings.</li>
            <li>Archived courses can be restored to drafts later.</li>
          </ul>
        </ConfirmDialog>
      </Specimen>
    </DocSection>
  );
}
