import { useState, type ReactNode } from 'react';
import {
  ArrowRight,
  BookOpenText,
  CalendarPlus,
  Copy,
  DotsThree,
  DownloadSimple,
  Archive,
  MagnifyingGlass,
  Plus,
  Trash,
  VideoCamera,
} from '@phosphor-icons/react';
import type { Role } from '@syniastrolms/domain';
import { cx } from '@/lib/cx';
import { Avatar, AvatarGroup } from '@/components/ui/Avatar/Avatar';
import { Badge, CountBadge, Kbd } from '@/components/ui/Badge/Badge';
import { Button, IconButton, type ForcedState } from '@/components/ui/Button/Button';
import { Field, Input, SearchInput, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { Spinner } from '@/components/ui/Spinner/Spinner';
import { Tooltip } from '@/components/ui/Tooltip/Tooltip';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { BottomSheet, Drawer, Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CourseCurriculum } from '@/components/lms/course/CourseCurriculum';
import { CourseMeta, courseMetaItems } from '@/components/lms/course/CourseIdentity';
import { useShellLayout } from '@/shell/ShellLayoutContext';
import { bottomDestinations, flatItems, navigation } from '@/shell/navigation';
import { simulation } from '@/services/mock/mockServices';
import { services } from '@/services';
import { foundationsCourse } from '@/services/mock/fixtures/catalog';
import { foundationsProgress } from '@/services/mock/fixtures/learner';
import { ChapterIntro, DocSection, Notes, Specimen } from '../doc/Doc';
import { LearnerManagement } from '../specimens/LearnerManagement';
import { FiguresSection } from './DataDisplay';
import { FormsSection } from './FormsDecisions';
import styles from './Chapters.module.css';

export default function Components() {
  return (
    <>
      <ChapterIntro title="Components">
        The shell’s component kit, extended where learning needs it: loading and success on buttons, validation on fields, a bottom sheet, an adaptive panel,
        and a data table that recomposes on small screens.
      </ChapterIntro>
      <Buttons />
      <Fields />
      <MenusBadges />
      <Navigation />
      <Overlays />
      <Feedback />
      <DataSection />
      <FiguresSection />
      <FormsSection />
    </>
  );
}

/* ─── Buttons ───────────────────────────────────────────────────────────── */

const FORCED: { name: string; state?: ForcedState; props?: Record<string, unknown> }[] = [
  { name: 'Default' },
  { name: 'Hover', state: 'hover' },
  { name: 'Focus', state: 'focus' },
  { name: 'Active', state: 'active' },
  { name: 'Selected', state: 'selected' },
  { name: 'Disabled', props: { disabled: true } },
  { name: 'Loading', props: { loading: true } },
  { name: 'Success', props: { succeeded: true } },
];

function Buttons() {
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const save = () => {
    setSaving(true);
    setSaved(false);
    window.setTimeout(() => {
      setSaving(false);
      setSaved(true);
      window.setTimeout(() => setSaved(false), 1800);
    }, 900);
  };

  return (
    <DocSection
      id="buttons"
      index={1}
      title="Buttons"
      lead="The shell’s five variants at 13.5px/600, r-sm. The LMS adds loading and a brief success confirmation, and a 44px size for primary actions on touch."
      api={['Button', 'IconButton', 'LinkButton']}
    >
      <Specimen
        label="Variants"
        notes={
          <Notes
            items={[
              { term: 'One primary', text: 'A view has one primary action — Enroll, Resume, Submit. Everything else is secondary or quieter.' },
              { term: 'Danger', text: 'Soft by default. Destructive actions confirm in a modal before they run.' },
            ]}
          />
        }
      >
        <div className={styles.stack}>
          <div className={styles.row}>
            <Button variant="primary">Resume lesson</Button>
            <Button>Save draft</Button>
            <Button variant="ghost">Preview</Button>
            <Button variant="quiet">Skip</Button>
            <Button variant="danger" iconStart={<Trash size={16} />}>
              Withdraw
            </Button>
            <IconButton boxed label="More actions" icon={<DotsThree size={18} />} />
            <IconButton boxed label="Duplicate" icon={<Copy size={17} />} />
          </div>
          <div className={styles.row}>
            <Button variant="primary" size="sm">
              Small
            </Button>
            <Button variant="primary">Medium</Button>
            <Button variant="primary" size="lg" iconEnd={<ArrowRight size={16} />}>
              Large · 44px
            </Button>
            <Button variant="primary" loading={saving} succeeded={saved} onClick={save}>
              {saved ? 'Saved' : 'Save and continue'}
            </Button>
          </div>
        </div>
      </Specimen>

      <Specimen label="Interaction states" surface="sunken">
        <div className={styles.stateGrid}>
          {FORCED.map((f) => (
            <div key={f.name} className={styles.stateCell}>
              <span className={styles.stateName}>{f.name}</span>
              <Button variant="primary" forceState={f.state} {...f.props}>
                Enroll
              </Button>
              <Button forceState={f.state} {...f.props}>
                {f.name === 'Selected' ? 'Saved' : 'Save'}
              </Button>
            </div>
          ))}
        </div>
      </Specimen>
    </DocSection>
  );
}

/* ─── Fields ────────────────────────────────────────────────────────────── */

function Fields() {
  const [query, setQuery] = useState('');
  return (
    <DocSection
      id="fields"
      index={2}
      title="Inputs, select & search"
      lead="40px controls with the shell’s accent focus ring. Validation adds an icon and a message, so errors never rely on a red border alone. On mobile, text is 16px and controls grow to 44px."
    >
      <Specimen label="States" surface="panel">
        <div className={styles.fieldGrid}>
          <Field label="Course title" hint="Shown to learners on the course page.">
            <Input placeholder="Class 10 Mathematics" />
          </Field>
          <Field label="Lesson title">
            <Input defaultValue="Home and mother: the fourth house" forceFocus />
          </Field>
          <Field label="Duration (minutes)" error="Enter a duration between 1 and 240.">
            <Input defaultValue="0" inputMode="numeric" />
          </Field>
          <Field label="Course URL" success="Available — zuviloai.com/learn/foundations">
            <Input defaultValue="foundations" />
          </Field>
          <Field label="Level">
            <Select defaultValue="beginner">
              <option value="beginner">Beginner</option>
              <option value="intermediate">Intermediate</option>
              <option value="advanced">Advanced</option>
              <option value="master">Master</option>
            </Select>
          </Field>
          <Field label="Certificate template" hint="Unlocks after the course is published.">
            <Input disabled defaultValue="ZuviloAI · Foundations" />
          </Field>
          <Field label="Search lessons">
            <SearchInput value={query} onValueChange={setQuery} placeholder="Try “algebra”" end={<Kbd>⌘K</Kbd>} />
          </Field>
          <Field label="Reflection" optional>
            <Textarea placeholder="What did the fourth house reveal about your own chart?" rows={3} />
          </Field>
        </div>
      </Specimen>
    </DocSection>
  );
}

/* ─── Menus, badges ─────────────────────────────────────────────────────── */

function MenusBadges() {
  const toast = useToast();
  return (
    <DocSection
      id="menus"
      index={3}
      title="Menus, badges & identity"
      lead="Dropdowns use roving focus (↑ ↓ Home End) and close on Escape or outside press. Badges are soft tone pills with a dot or icon — the LMS status badges build on them."
      api={['Menu', 'Badge', 'CountBadge', 'Avatar', 'Tooltip', 'Kbd']}
    >
      <div className={styles.rowLg}>
        <Menu
          trigger={(p) => (
            <Button {...p} iconEnd={<DotsThree size={16} />}>
              Course actions
            </Button>
          )}
          sections={[
            {
              items: [
                {
                  id: 'dup',
                  label: 'Duplicate course',
                  icon: <Copy size={17} />,
                  onSelect: () => toast({ kind: 'success', title: 'Course duplicated', text: 'Class 10 Mathematics (copy)' }),
                },
                {
                  id: 'exp',
                  label: 'Export learners',
                  icon: <DownloadSimple size={17} />,
                  hint: 'CSV',
                  onSelect: () => toast({ kind: 'info', title: 'Export started', text: '2,846 learners' }),
                },
                { id: 'arch', label: 'Archive', icon: <Archive size={17} />, disabled: true },
              ],
            },
            {
              items: [
                {
                  id: 'del',
                  label: 'Delete course',
                  icon: <Trash size={17} />,
                  tone: 'danger',
                  onSelect: () => toast({ kind: 'warn', title: 'Delete needs confirmation', text: 'Destructive actions confirm in a modal.' }),
                },
              ],
            },
          ]}
        />
        <Tooltip content="Visible to enrolled learners only" side="bottom" forceOpen>
          <Button variant="quiet" size="sm">
            Visibility
          </Button>
        </Tooltip>
        <span className={styles.row}>
          <AvatarGroup
            names={['Ananya Rao', 'Siddharth Menon', 'Farah Qureshi', 'Arjun Nair', 'Lakshmi Pillai', 'Meera Krishnan']}
            max={3}
            label="46 learners attending"
          />
          <span className={styles.caption}>46 attending</span>
        </span>
        <span className={styles.row}>
          <Avatar name="Dr. Meenakshi Iyer" size={36} decorative={false} />
          <Avatar name="Acharya Vinod Shastri" size={36} decorative={false} />
          <Avatar name="Pooja Deshpande" size={36} decorative={false} />
        </span>
      </div>
      <div className={styles.row}>
        <Badge tone="accent" dot>
          Published
        </Badge>
        <Badge tone="info" dot>
          In review
        </Badge>
        <Badge tone="warn" dot>
          At risk
        </Badge>
        <Badge tone="danger" dot>
          Refunded
        </Badge>
        <Badge tone="neutral" dot>
          Draft
        </Badge>
        <Badge tone="accent" appearance="outline">
          Hybrid
        </Badge>
        <CountBadge>12</CountBadge>
        <CountBadge tone="warn">14</CountBadge>
        <Kbd>⌘K</Kbd>
        <Kbd>⌘B</Kbd>
      </div>
    </DocSection>
  );
}

/* ─── Navigation ────────────────────────────────────────────────────────── */

/** Only the roles with a navigation to document — Super Admin has none yet. */
type DocumentedRole = Exclude<Role, 'superadmin'>;

const ROLE_TITLES: Record<DocumentedRole, { title: string; note: string }> = {
  student: { title: 'Student', note: 'Flat, short, one level of nesting. Live and due counts are the only badges.' },
  instructor: { title: 'Instructor', note: 'Teaching tools grouped; the review queue carries the only warning count.' },
  admin: { title: 'Admin', note: 'Four groups, nested areas open on demand. Management lives one level down.' },
};

function Navigation() {
  const [role, setRole] = useState<DocumentedRole>('student');
  return (
    <DocSection
      id="navigation"
      index={4}
      title="Navigation"
      lead="The shell’s sidebar, grouped per role and disclosed progressively. Students get fewer, flatter destinations; staff get depth. Below 768px four destinations move to the bottom bar and the rest to the menu drawer."
      api={['Sidebar', 'navigation.tsx', 'SegmentedControl']}
    >
      <div className={styles.miniNavs}>
        {(Object.keys(ROLE_TITLES) as DocumentedRole[]).map((r) => (
          <MiniNav key={r} role={r} />
        ))}
      </div>
      <Specimen
        label="Segmented control · tabs"
        notes={<Notes items={[{ term: 'Keyboard', text: 'Arrow keys move selection; the tab list is a single tab stop.' }]} />}
      >
        <SegmentedControl
          label="Viewing as"
          value={role}
          onChange={setRole}
          segments={[
            { value: 'student', label: 'Student' },
            { value: 'instructor', label: 'Instructor' },
            { value: 'admin', label: 'Admin' },
          ]}
        />
        <p className={cx(styles.caption, styles.spaced)}>{ROLE_TITLES[role].note}</p>
      </Specimen>
    </DocSection>
  );
}

function MiniNav({ role }: { role: DocumentedRole }) {
  const bottom = bottomDestinations[role].map((id) => flatItems(role).find((i) => i.id === id)!);
  const firstItem = navigation[role][0].items[0];
  return (
    <figure className={styles.miniNav} aria-label={`${ROLE_TITLES[role].title} navigation`}>
      <figcaption className={styles.miniNavTitle}>
        <span className="type-h4">{ROLE_TITLES[role].title}</span>
        <span className={styles.caption}>{flatItems(role).length} destinations</span>
      </figcaption>
      <div className={styles.miniNavFrame} aria-hidden="true">
        {navigation[role]
          .filter((g) => g.id !== 'internal')
          .map((g) => (
            <div key={g.id}>
              {g.label && <div className={styles.miniGroup}>{g.label}</div>}
              {g.items.map((item) => (
                <div key={item.id}>
                  <div className={cx(styles.miniItem, item.id === firstItem.id && styles.miniItemActive)}>
                    {item.icon}
                    <span className={styles.miniItemLabel}>{item.label}</span>
                  </div>
                  {item.children && role === 'student' && (
                    <div className={styles.miniKids}>
                      {item.children.map((k) => (
                        <span key={k.to}>{k.label}</span>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          ))}
      </div>
      <div className={styles.miniBottom} aria-hidden="true">
        {bottom.map((b, i) => (
          <span key={b.id} className={cx(i === 0 && styles.miniBottomActive)}>
            {b.icon}
            {b.short ?? b.label}
          </span>
        ))}
        <span>
          <DotsThree size={18} />
          More
        </span>
      </div>
    </figure>
  );
}

/* ─── Overlays ──────────────────────────────────────────────────────────── */

function Overlays() {
  const toast = useToast();
  const { openCommandPalette } = useShellLayout();
  const [open, setOpen] = useState<'modal' | 'drawer' | 'sheet' | 'adaptive' | null>(null);
  const close = () => setOpen(null);

  const rows: { name: string; use: ReactNode; action: ReactNode }[] = [
    {
      name: 'Modal',
      use: 'Commits — enroll, submit, delete. Blocks the page until answered.',
      action: (
        <Button size="sm" onClick={() => setOpen('modal')}>
          Open modal
        </Button>
      ),
    },
    {
      name: 'Drawer',
      use: 'Secondary detail beside a list the learner shouldn’t lose — a lesson’s details, a learner’s record.',
      action: (
        <Button size="sm" onClick={() => setOpen('drawer')}>
          Open drawer
        </Button>
      ),
    },
    {
      name: 'Bottom sheet',
      use: 'The mobile drawer. Anchored to the thumb, dismissed by drag, Escape or backdrop.',
      action: (
        <Button size="sm" onClick={() => setOpen('sheet')}>
          Open sheet
        </Button>
      ),
    },
    {
      name: 'Adaptive panel',
      use: 'One API that becomes a drawer at ≥768px and a sheet below. Use it by default for side detail.',
      action: (
        <Button size="sm" variant="primary" onClick={() => setOpen('adaptive')}>
          Open curriculum
        </Button>
      ),
    },
    {
      name: 'Toast',
      use: 'Confirms something that already happened. Never the only record of an error.',
      action: (
        <>
          <Button size="sm" onClick={() => toast({ kind: 'success', title: 'Lesson completed', text: 'Home and mother: the fourth house' })}>
            Success
          </Button>
          <Button
            size="sm"
            onClick={() =>
              toast({
                kind: 'info',
                title: 'Class starts in 8 minutes',
                text: 'Doubt-clearing: Quadratic equations',
                action: { label: 'Join', onClick: () => undefined },
              })
            }
          >
            Info
          </Button>
          <Button size="sm" onClick={() => toast({ kind: 'warn', title: 'Draft not submitted', text: 'Due Friday, 11:59 PM' })}>
            Warning
          </Button>
          <Button size="sm" onClick={() => toast({ kind: 'error', title: 'Upload failed', text: 'The file is over 20 MB.' })}>
            Error
          </Button>
        </>
      ),
    },
    {
      name: 'Command palette',
      use: 'Search and next steps from anywhere. Contextual — it knows what is live and what is due.',
      action: (
        <Button size="sm" iconStart={<MagnifyingGlass size={15} />} onClick={openCommandPalette}>
          Open ⌘K
        </Button>
      ),
    },
  ];

  return (
    <DocSection
      id="overlays"
      index={5}
      title="Overlays"
      lead="Modal, drawer and toast from the shell; bottom sheet and adaptive panel added for learning on phones. All share focus trapping, Escape, backdrop dismissal and scroll lock."
      api={['Modal', 'Drawer', 'BottomSheet', 'AdaptivePanel', 'ToastProvider', 'CommandPalette']}
    >
      <div className={styles.overlayTable}>
        {rows.map((r) => (
          <div key={r.name} className={styles.overlayRow}>
            <span className={styles.overlayName}>{r.name}</span>
            <span className={styles.overlayUse}>{r.use}</span>
            <span className={styles.overlayAction}>{r.action}</span>
          </div>
        ))}
      </div>

      <Modal
        open={open === 'modal'}
        onClose={close}
        icon={<CalendarPlus size={20} />}
        title="Schedule live class"
        description="Enrolled learners get a calendar invite and a reminder 15 minutes before."
        footer={
          <>
            <Button onClick={close}>Cancel</Button>
            <Button
              variant="primary"
              onClick={() => {
                close();
                toast({ kind: 'success', title: 'Live class scheduled', text: 'Thu, 24 Sep · 7:00 PM IST' });
              }}
            >
              Schedule
            </Button>
          </>
        }
      >
        <Field label="Title">
          <Input defaultValue="Doubt-clearing: the Twelve Houses" data-autofocus />
        </Field>
        <Field label="Starts">
          <Input type="datetime-local" defaultValue="2026-09-24T19:00" />
        </Field>
      </Modal>

      <Drawer
        open={open === 'drawer'}
        onClose={close}
        eyebrow="Lesson 05"
        title="Home and mother: the fourth house"
        footer={
          <>
            <Button onClick={close}>Close</Button>
            <Button variant="primary" block onClick={close}>
              Resume lesson
            </Button>
          </>
        }
      >
        <CourseMeta variant="list" items={courseMetaItems(foundationsCourse).slice(0, 4)} />
        <p className="type-body tone-muted">
          Drawers carry secondary detail without losing the list behind them. They share the modal’s elevation and dismissal rules.
        </p>
      </Drawer>

      <BottomSheet
        open={open === 'sheet'}
        onClose={close}
        eyebrow="Live class"
        title="Reading dignities in real charts"
        footer={
          <>
            <Button onClick={close}>Later</Button>
            <Button variant="primary" iconStart={<VideoCamera size={16} />} onClick={close}>
              Join now
            </Button>
          </>
        }
      >
        <p className="type-body tone-muted">46 learners attending · with Dr. Meenakshi Iyer · started 22 minutes ago.</p>
      </BottomSheet>

      <AdaptivePanel
        open={open === 'adaptive'}
        onClose={close}
        eyebrow="Class 10 Mathematics"
        title="Curriculum"
        footer={
          <Button variant="primary" block iconStart={<BookOpenText size={16} />} onClick={close}>
            Resume lesson
          </Button>
        }
      >
        <div data-density="immersive">
          <CourseCurriculum
            course={foundationsCourse}
            snapshot={foundationsProgress}
            currentLessonId={foundationsProgress.lastLessonId}
            onSelectLesson={close}
          />
        </div>
      </AdaptivePanel>
    </DocSection>
  );
}

/* ─── Feedback ──────────────────────────────────────────────────────────── */

function Feedback() {
  const [retrying, setRetrying] = useState(false);
  const [recovered, setRecovered] = useState(false);
  const toast = useToast();

  const retry = async () => {
    setRetrying(true);
    try {
      await services.learner.listAssignments();
      setRecovered(true);
      toast({ kind: 'success', title: 'Assignments loaded' });
    } finally {
      setRetrying(false);
    }
  };

  return (
    <DocSection
      id="feedback"
      index={6}
      title="Loading, empty, error & success"
      lead="Every data region has four faces. Loading keeps the layout’s shape; empty says what would be here and how to get it; error says what failed and offers the fix; success confirms in place."
    >
      <div className={styles.progressGrid}>
        <div className={styles.progressItem}>
          <span className={styles.progressItemTitle}>Loading</span>
          <div>
            {[0, 1, 2].map((i) => (
              <div key={i} className={styles.skeletonRow}>
                <Skeleton width={48} height={48} radius="var(--r-sm)" />
                <div className={styles.skeletonLines}>
                  <Skeleton width={`${70 - i * 12}%`} height={12} />
                  <Skeleton width={`${45 + i * 8}%`} height={9} />
                </div>
              </div>
            ))}
          </div>
          <span className={styles.row}>
            <Spinner /> <span className={styles.caption}>Spinner — only for actions under a second or two.</span>
          </span>
        </div>
        <div className={styles.progressItem}>
          <span className={styles.progressItemTitle}>Empty</span>
          <StateMessage
            compact
            icon={<CalendarPlus size={26} />}
            title="No live classes this week"
            actions={
              <Button size="sm" iconStart={<Plus size={15} />}>
                Browse recordings
              </Button>
            }
          >
            Your next session, Trigonometry in practice, is on Thursday. Recordings of past classes stay available for 30 days.
          </StateMessage>
        </div>
        <div className={styles.progressItem}>
          <span className={styles.progressItemTitle}>Error</span>
          {recovered ? (
            <StateMessage
              compact
              kind="success"
              title="Back on track"
              actions={
                <Button size="sm" onClick={() => setRecovered(false)}>
                  Show error again
                </Button>
              }
            >
              Seven assignments loaded.
            </StateMessage>
          ) : (
            <StateMessage
              compact
              kind="error"
              title="Assignments didn’t load"
              actions={
                <Button size="sm" variant="primary" loading={retrying} onClick={retry}>
                  Try again
                </Button>
              }
            >
              We couldn’t reach ZuviloAI. Your work is saved — nothing was lost.
            </StateMessage>
          )}
        </div>
      </div>
      <div className={styles.stack}>
        <InlineMessage kind="info" title="Cohort starts Monday.">
          Join the welcome session on 21 Sep at 7:00 PM IST.
        </InlineMessage>
        <InlineMessage kind="success" title="Submission received.">
          Your instructor usually responds within 3 days.
        </InlineMessage>
        <InlineMessage kind="warn" title="3 lessons have no captions.">
          Accessibility checks run before publish.
        </InlineMessage>
        <InlineMessage
          kind="error"
          title="Payment didn’t go through."
          action={
            <Button
              size="sm"
              variant="quiet"
              onClick={() => toast({ kind: 'info', title: 'Payment details', text: 'Payment is a specimen here — no card is charged.' })}
            >
              Update card
            </Button>
          }
        >
          Your enrollment is held for 24 hours.
        </InlineMessage>
      </div>
    </DocSection>
  );
}

/* ─── Data ──────────────────────────────────────────────────────────────── */

function DataSection() {
  const [key, setKey] = useState(0);
  return (
    <DocSection
      id="data"
      index={7}
      title="Data table"
      lead="The dense end of the system. Sort, filter, select in bulk, paginate — on real mock services with latency. Below 640px of container width, rows recompose into a structured list with explicit details."
      api={['DataTable', 'Pagination', 'Checkbox']}
    >
      <Specimen
        label="Learner management · dense"
        density="dense"
        surface="panel"
        toolbar={
          <Button
            size="sm"
            variant="quiet"
            onClick={() => {
              simulation.failNext = true;
              setKey((k) => k + 1);
            }}
          >
            Simulate a failed load
          </Button>
        }
      >
        <LearnerManagement key={key} />
      </Specimen>
    </DocSection>
  );
}
