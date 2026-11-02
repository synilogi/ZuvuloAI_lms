import { useState } from 'react';
import {
  Bell,
  BookOpenText,
  CalendarBlank,
  Certificate,
  ChalkboardTeacher,
  ChartLineUp,
  ChatsCircle,
  ClipboardText,
  Clock,
  Compass,
  Exam,
  HourglassMedium,
  LockSimple,
  PaperPlaneTilt,
  PencilLine,
  Play,
  PlayCircle,
  SealCheck,
  UsersThree,
  VideoCamera,
} from '@phosphor-icons/react';
import { lessonState, chapterProgress } from '@syniastrolms/domain';
import { breakpointFor, verifiedWidths, zIndex, type Density } from '@/design/tokens';
import { useViewport } from '@/hooks/useViewport';
import { cx } from '@/lib/cx';
import { Button } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { LessonRow } from '@/components/lms/course/CourseCurriculum';
import { LessonSegments, Meter } from '@/components/lms/progress/Meters';
import { ProgressRing } from '@/components/lms/progress/ProgressRing';
import { StatusNode } from '@/components/lms/status/Status';
import { statusRegistry, type StatusKey } from '@/components/lms/status/statusRegistry';
import { usePreferences } from '@/providers/PreferencesProvider';
import { foundationsCourse } from '@/services/mock/fixtures/catalog';
import { foundationsProgress } from '@/services/mock/fixtures/learner';
import { ChapterIntro, Column, Columns, DocSection, Notes, Specimen, Token } from '../doc/Doc';
import styles from './Chapters.module.css';

export default function Foundations() {
  return (
    <>
      <ChapterIntro title="Foundations">
        The shell’s token layer, carried over value for value, plus the smallest set of extensions the learning experience needs. Nothing on this page
        introduces a new hue, typeface or curve.
      </ChapterIntro>
      <Principles />
      <Color />
      <Typography />
      <SpacingDensity />
      <Surfaces />
      <ShapeMotion />
      <Layout />
      <Iconography />
    </>
  );
}

/* ─── 01 Principles ─────────────────────────────────────────────────────── */

const PRINCIPLES = [
  {
    title: 'Typography before containers',
    text: 'Hierarchy is carried by scale, weight and space. A box is the last tool, not the first — most learning content sits directly on the page.',
  },
  {
    title: 'Surfaces are earned',
    text: 'A surface appears when content must be held apart: a reading canvas, a table, an action that follows you. Everything else stays on the ground.',
  },
  {
    title: 'Density follows the task',
    text: 'A lesson breathes, a dashboard balances, an admin table packs. The same components change rhythm through one density attribute.',
  },
  {
    title: 'State is never color alone',
    text: 'Every learning state has a label, an icon and a node shape. Tone reinforces the meaning; it never carries it by itself.',
  },
  {
    title: 'The tradition, in fine line',
    text: 'Fine geometry — grids, rings of points, orbits — appears as hairline structure in covers, ranks and seals. Never as decoration.',
  },
];

function Principles() {
  return (
    <DocSection
      id="principles"
      index={1}
      title="Principles"
      lead="Five decisions every LMS screen inherits. When a new pattern is needed, it answers to these first."
    >
      <ol className={styles.principles}>
        {PRINCIPLES.map((p) => (
          <li key={p.title} className={styles.principle}>
            <span className={styles.principleMark} aria-hidden="true" />
            <h3 className={styles.principleTitle}>{p.title}</h3>
            <p className={styles.principleText}>{p.text}</p>
          </li>
        ))}
      </ol>
    </DocSection>
  );
}

/* ─── 02 Color ──────────────────────────────────────────────────────────── */

const TONES: { name: string; tone: string; steps: string[]; states: StatusKey[] }[] = [
  { name: 'Accent', tone: 'accent', steps: ['--accent-soft', '--accent', '--accent-ink'], states: ['in-progress', 'completed', 'passed', 'eligible', 'draft'] },
  { name: 'Info', tone: 'info', steps: ['--info-soft', '--info', '--info-ink'], states: ['enrolled', 'upcoming', 'submitted', 'starting-soon'] },
  { name: 'Warn', tone: 'warn', steps: ['--warn-soft', '--warn', '--warn-ink'], states: ['under-review'] },
  { name: 'Danger', tone: 'danger', steps: ['--danger-soft', '--danger', '--danger-ink'], states: ['live', 'failed', 'overdue'] },
  {
    name: 'Neutral',
    tone: 'neutral',
    steps: ['--surface-2', '--faint', '--muted'],
    states: ['locked', 'not-enrolled', 'expired', 'not-eligible', 'not-started', 'cancelled'],
  },
];

function Color() {
  return (
    <DocSection
      id="color"
      index={2}
      title="Color"
      lead="One accent, three supporting tones and a neutral ramp — all from the shell. In the LMS each tone is assigned by meaning, so a learner builds a reliable reading of state."
      api={['tokens.css']}
    >
      <Specimen
        label="Surfaces"
        notes={
          <Notes
            items={[
              { term: 'Order', text: 'Page ground → primary surface → secondary → sunken. Each step is a few percent of lightness, never a hue shift.' },
              {
                term: 'Lines',
                text: (
                  <>
                    <Token>--border</Token> for hairlines; <Token>--border-strong</Token> (LMS) for controls and unmet markers.
                  </>
                ),
              },
            ]}
          />
        }
      >
        <div className={styles.surfaceLadder}>
          {[
            ['--bg', 'Page ground'],
            ['--surface', 'Primary surface'],
            ['--surface-2', 'Secondary'],
            ['--surface-3', 'Sunken'],
          ].map(([token, label], i) => (
            <div key={token} className={styles.surfaceStep} style={{ background: `var(${token})`, marginLeft: i * 28 }}>
              <span className={styles.surfaceName}>{label}</span>
              <Token>{token}</Token>
            </div>
          ))}
        </div>
      </Specimen>

      <Specimen label="Tones, by meaning">
        <div className={styles.toneTable}>
          {TONES.map((t) => (
            <div key={t.name} className={styles.toneRow}>
              <div className={styles.toneName}>{t.name}</div>
              <div className={styles.toneStrip}>
                {t.steps.map((s) => (
                  <span key={s} className={styles.toneSwatch} style={{ background: `var(${s})` }}>
                    <span className={styles.toneToken}>{s.replace('--', '')}</span>
                  </span>
                ))}
              </div>
              <ul className={styles.toneStates} aria-label={`${t.name} states`}>
                {t.states.map((s) => {
                  const def = statusRegistry[s];
                  const Icon = def.icon;
                  return (
                    <li key={s}>
                      <Icon size={14} weight="fill" className={styles[`ink-${t.tone}`]} />
                      {def.label}
                    </li>
                  );
                })}
              </ul>
            </div>
          ))}
        </div>
      </Specimen>

      <Columns>
        <Column
          title="Ink"
          caption="Three steps. Most interface text is --text or --muted; --faint is for metadata and never for anything a learner must read to proceed."
        >
          <div className={styles.inkStack}>
            <span style={{ color: 'var(--text)' }}>Understanding the Twelve Houses</span>
            <span style={{ color: 'var(--muted)' }}>8 lessons · 3h 06m · Dr. Meenakshi Iyer</span>
            <span style={{ color: 'var(--faint)' }}>Updated 2 Sep 2026</span>
          </div>
        </Column>
        <Column title="LMS extensions" caption="Derived with color-mix from the shell tokens — no new hues.">
          <ul className={styles.extList}>
            <li>
              <span className={styles.extSwatch} style={{ background: 'var(--track)' }} />
              <Token>--track</Token> meter and ring track
            </li>
            <li>
              <span className={styles.extSwatch} style={{ background: 'var(--border-strong)' }} />
              <Token>--border-strong</Token> controls, unmet
            </li>
            <li>
              <span className={styles.extSwatch} style={{ background: 'var(--surface-2)', backgroundImage: 'var(--hatch)' }} />
              <Token>--hatch</Token> locked, unavailable
            </li>
            <li>
              <span className={styles.extSwatch} style={{ background: 'var(--scrim)' }} />
              <Token>--scrim</Token> overlay backdrop
            </li>
          </ul>
        </Column>
      </Columns>
    </DocSection>
  );
}

/* ─── 03 Typography ─────────────────────────────────────────────────────── */

const TYPE_SCALE = [
  { role: 'Display', cls: 'type-display', spec: '44 / 1.02 · 700', sample: 'Quadratics' },
  { role: 'H1', cls: 'type-h1', spec: '28 / 1.1 · 700', sample: 'Class 10 Mathematics' },
  { role: 'H2', cls: 'type-h2', spec: '21 / 1.2 · 700', sample: 'Linear equations in two variables' },
  { role: 'H3', cls: 'type-h3', spec: '17 / 1.25 · 600', sample: 'Solving by substitution' },
  { role: 'H4', cls: 'type-h4', spec: '15 / 1.3 · 600', sample: 'Chapter 3 assessment' },
  {
    role: 'Body large',
    cls: 'type-body-lg',
    spec: '15 / 1.6 · 400',
    sample: 'Build fluency with ratios, percentages and equations through short lessons and worked examples.',
  },
  { role: 'Body', cls: 'type-body', spec: '14 / 1.5 · 400', sample: 'The discriminant — b² − 4ac — tells you how many real roots to expect.' },
  { role: 'Body small', cls: 'type-body-sm', spec: '13 / 1.45 · 400', sample: '9 lessons · 2h 55m · Dr. Meenakshi Iyer' },
  { role: 'Caption', cls: 'type-caption', spec: '12 / 1.4 · 500', sample: 'Due Fri, 19 Sep · in 4 days' },
  { role: 'Metadata', cls: 'type-meta', spec: '11.5 / 1.4 · 400', sample: 'Updated 2 Sep 2026' },
  { role: 'Label', cls: 'type-label', spec: '11 / 1.3 · 700 · +0.08em', sample: 'Chapter 02 · Polynomials' },
  { role: 'Numeric', cls: 'type-numeric', spec: 'Display face · tabular', sample: '84% · 18/20 · 4h 12m' },
];

function Typography() {
  return (
    <DocSection
      id="typography"
      index={3}
      title="Typography"
      lead="Plus Jakarta Sans for headings, numerals, reading and interface — headings set bold with tight tracking, body at reading weights. Fraunces is kept for certificates, where a formal document wants a serif. The scale is the same one throughout — display/44 is the large numeral."
    >
      <div className={styles.typeTable} role="table" aria-label="Type scale">
        {TYPE_SCALE.map((t) => (
          <div key={t.role} className={styles.typeRow} role="row">
            <span className={styles.typeRole} role="cell">
              {t.role}
              <span className={styles.typeSpec}>{t.spec}</span>
            </span>
            <span className={cx(t.cls, styles.typeSample)} role="cell" style={t.cls === 'type-numeric' ? { fontSize: 24 } : undefined}>
              {t.sample}
            </span>
          </div>
        ))}
      </div>

      <Specimen
        label="Hierarchy without boxes"
        notes={
          <Notes
            items={[
              {
                term: 'What carries it',
                text: 'Eyebrow in accent ink, a display title, a muted lead, faint metadata, then one progress line. No container, no border.',
              },
              {
                term: 'Reading measure',
                text: (
                  <>
                    Lesson prose uses <Token>type-reading</Token>: 16px at 1.72 line height, capped at 68ch.
                  </>
                ),
              },
            ]}
          />
        }
      >
        <div className={styles.hierarchyDemo}>
          <span className="type-eyebrow">Chapter 03 · Lesson 5 of 8</span>
          <h3 className={styles.hierarchyTitle}>Home and mother: the fourth house</h3>
          <p className="type-body-lg tone-muted">
            The fourth house describes the ground a person stands on — home, mother, inner contentment and the vehicles that carry them through life.
          </p>
          <p className="type-meta">17 min · Video · Dr. Meenakshi Iyer</p>
          <div className={styles.hierarchyProgress}>
            <Meter value={55} label="Lesson progress" size="sm" />
            <span className="type-caption tone-muted tabular">8 min left</span>
          </div>
        </div>
      </Specimen>
    </DocSection>
  );
}

/* ─── 04 Spacing & density ──────────────────────────────────────────────── */

const SPACING = [4, 8, 12, 16, 24, 32, 48, 64];
const DENSITY_VALUES: Record<Density, [string, string][]> = {
  immersive: [
    ['Section', '48'],
    ['Row padding', '16'],
    ['Body text', '15 / 1.65'],
    ['Control', '44'],
    ['Node', '24'],
    ['Container', '720 reading'],
  ],
  balanced: [
    ['Section', '32'],
    ['Row padding', '12'],
    ['Body text', '14 / 1.5'],
    ['Control', '40'],
    ['Node', '20'],
    ['Container', '1200 page'],
  ],
  dense: [
    ['Section', '24'],
    ['Row padding', '8'],
    ['Body text', '13 / 1.4'],
    ['Control', '34'],
    ['Node', '16'],
    ['Container', '1480 wide'],
  ],
};

function SpacingDensity() {
  const [density, setDensity] = useState<Density>('balanced');
  const chapter = foundationsCourse.chapters[2];

  return (
    <DocSection
      id="density"
      index={4}
      title="Spacing & density"
      lead="The shell’s 4-based scale, applied through three density modes. Components read --d-* variables, so the same curriculum row can sit in a lesson, a course page or an instructor outline."
    >
      <div className={styles.spacingScale}>
        {SPACING.map((px, i) => (
          <div key={px} className={styles.spacingRow}>
            <Token>s-{i + 1}</Token>
            <span className={styles.spacingBar} style={{ width: px * 3 }} />
            <span className={styles.spacingValue}>{px}</span>
          </div>
        ))}
      </div>

      <Specimen
        label="Same component, three densities"
        toolbar={
          <SegmentedControl
            label="Density"
            size="sm"
            value={density}
            onChange={setDensity}
            segments={[
              { value: 'immersive', label: 'Immersive' },
              { value: 'balanced', label: 'Balanced' },
              { value: 'dense', label: 'Dense' },
            ]}
          />
        }
        surface="panel"
        density={density}
        notes={
          <dl className={styles.densityValues}>
            {DENSITY_VALUES[density].map(([k, v]) => (
              <div key={k}>
                <dt>{k}</dt>
                <dd>{v}</dd>
              </div>
            ))}
            <p className={styles.densityWhen}>
              {density === 'immersive' && 'Lessons, video and reading. Focus over information.'}
              {density === 'balanced' && 'Dashboards, discovery, My learning, live classes, assignments.'}
              {density === 'dense' && 'Admin, instructor management, analytics, bulk operations.'}
            </p>
          </dl>
        }
      >
        <div className={styles.densityDemo}>
          <div className={styles.densityHead}>
            <span className={styles.densityTitle}>{chapter.title}</span>
            <LessonSegments
              label={chapter.title}
              items={chapter.lessons.map((l) => ({
                id: l.id,
                state: lessonState(l.id, foundationsProgress),
                fraction: foundationsProgress.lessons[l.id]?.fraction,
                title: l.title,
              }))}
              summary={`${chapterProgress(chapter, foundationsProgress).completed} of ${chapter.lessons.length} lessons`}
            />
          </div>
          <ol className={styles.plainList}>
            {chapter.lessons.slice(2, 7).map((l, i) => (
              <LessonRow
                key={l.id}
                lesson={l}
                index={i + 3}
                state={lessonState(l.id, foundationsProgress)}
                fraction={foundationsProgress.lessons[l.id]?.fraction}
                current={l.id === foundationsProgress.lastLessonId}
                onSelect={() => undefined}
              />
            ))}
          </ol>
        </div>
      </Specimen>
    </DocSection>
  );
}

/* ─── 05 Surfaces ───────────────────────────────────────────────────────── */

const LEVELS = [
  { name: 'Base page', token: '--bg', use: 'Journeys, timelines, rank ladders, editorial headers — content that should feel like the page itself.' },
  { name: 'Primary', token: '--surface', use: 'Reading canvas, tables, curriculum panels. Content held apart from the page.' },
  { name: 'Secondary', token: '--surface-2', use: 'Table headers, dialog footers, segmented tracks, date blocks, locked lessons.' },
  { name: 'Elevated', token: '--sh-md', use: 'Sticky course actions and the continue-learning panel — things that follow the reader.' },
  { name: 'Floating', token: '--sh-lg', use: 'Menus, popovers, toasts, the command palette.' },
  { name: 'Overlay', token: '--scrim', use: 'Modal, drawer, bottom sheet. The page behind is dimmed and inert.' },
];

function Surfaces() {
  return (
    <DocSection
      id="surfaces"
      index={5}
      title="Surfaces & elevation"
      lead="Six levels, used on purpose. The default is the page; each step up has to justify itself."
    >
      <div className={styles.surfaceSplit}>
        <div className={styles.surfaceDiagram} aria-hidden="true">
          <div className={styles.lvBase}>
            <span className={styles.lvLabel}>Base</span>
            <div className={styles.lvPrimary}>
              <span className={styles.lvLabel}>Primary</span>
              <div className={styles.lvSecondary}>
                <span className={styles.lvLabel}>Secondary</span>
              </div>
            </div>
            <div className={styles.lvElevated}>
              <span className={styles.lvLabel}>Elevated</span>
            </div>
            <div className={styles.lvFloating}>
              <span className={styles.lvLabel}>Floating</span>
            </div>
          </div>
        </div>
        <ol className={styles.levelList}>
          {LEVELS.map((l, i) => (
            <li key={l.name}>
              <span className={styles.levelIndex}>{i + 1}</span>
              <span>
                <span className={styles.levelName}>
                  {l.name} <Token>{l.token}</Token>
                </span>
                <span className={styles.levelUse}>{l.use}</span>
              </span>
            </li>
          ))}
        </ol>
      </div>
    </DocSection>
  );
}

/* ─── 06 Shape & motion ─────────────────────────────────────────────────── */

function ShapeMotion() {
  const [value, setValue] = useState(38);
  const [done, setDone] = useState(false);
  const [open, setOpen] = useState(false);
  const { reduceMotion, setReduceMotion } = usePreferences();

  const replay = () => {
    setValue((v) => (v === 38 ? 64 : 38));
    setDone((d) => !d);
    setOpen((o) => !o);
  };

  return (
    <DocSection
      id="shape-motion"
      index={6}
      title="Radius, lines & motion"
      lead="Radii and shadows are the shell’s. Motion keeps its single curve — cubic-bezier(.2,.8,.2,1) — at 120ms for feedback, 200ms for layout, 240ms for panels and 300ms for progress."
    >
      <Columns>
        <Column title="Radius">
          <div className={styles.radii}>
            {[
              ['xs', 6],
              ['sm', 9],
              ['md', 12],
              ['lg', 16],
              ['xl', 22],
              ['pill', 999],
            ].map(([n, v]) => (
              <span key={n} className={styles.radius}>
                <span className={styles.radiusBox} style={{ borderRadius: v as number }} />
                <Token>r-{n}</Token>
              </span>
            ))}
          </div>
          <p className="type-caption tone-muted">Controls r-sm · panels r-lg · sheets r-xl · badges pill.</p>
        </Column>
        <Column title="Elevation">
          <div className={styles.radii}>
            {['sm', 'md', 'lg'].map((s) => (
              <span key={s} className={styles.radius}>
                <span className={styles.shadowBox} style={{ boxShadow: `var(--sh-${s})` }} />
                <Token>sh-{s}</Token>
              </span>
            ))}
          </div>
          <p className="type-caption tone-muted">No glow, no colored shadows. Dark theme deepens, it doesn’t brighten.</p>
        </Column>
      </Columns>

      <Specimen
        label="Motion"
        surface="panel"
        toolbar={
          <>
            <Checkbox label="Preview reduced motion" checked={reduceMotion} onChange={(e) => setReduceMotion(e.target.checked)} />
            <Button size="sm" variant="primary" onClick={replay}>
              Play transitions
            </Button>
          </>
        }
        notes={
          <Notes
            items={[
              { term: 'Progress · 300ms', text: 'Rings, meters and orbits ease to their new value.' },
              { term: 'State · 260ms', text: 'A node settles when a lesson completes — once, at the moment it happens.' },
              { term: 'Layout · 200ms', text: 'Curriculum chapters expand by grid rows, not height guesses.' },
              { term: 'Reduced motion', text: 'The OS setting or this preview collapses every duration to 1ms. Live pulses stop.' },
            ]}
          />
        }
      >
        <div className={styles.motionDemo}>
          <div className={styles.motionItem}>
            <ProgressRing value={value} size="lg" label="Course progress" caption="Course" />
            <span className="type-caption tone-muted">Progress change</span>
          </div>
          <div className={styles.motionItem}>
            <span className={styles.motionNodes}>
              <StatusNode shape="filled" size={24} />
              <StatusNode shape="filled" size={24} />
              {done ? <StatusNode key="done" shape="filled" size={24} settle /> : <StatusNode key="partial" shape="partial" size={24} fraction={0.55} />}
              <StatusNode shape="ring" tone="neutral" size={24} />
            </span>
            <span className="type-caption tone-muted">Lesson completion</span>
          </div>
          <div className={cx(styles.motionItem, styles.motionExpand)}>
            <div className={cx(styles.expandDemo, open && styles.expandOpen)}>
              <div className={styles.expandHead}>Chapter 03 · 8 lessons</div>
              <div className={styles.expandBody}>
                <div>
                  <p>Zeros of a polynomial</p>
                  <p>Relationship between zeros and coefficients</p>
                  <p>Wealth and speech: the second house</p>
                </div>
              </div>
            </div>
            <span className="type-caption tone-muted">Expand</span>
          </div>
        </div>
      </Specimen>
    </DocSection>
  );
}

/* ─── 07 Layout ─────────────────────────────────────────────────────────── */

function Layout() {
  const { width, breakpoint } = useViewport();
  return (
    <DocSection
      id="layout"
      index={7}
      title="Layout, breakpoints & layers"
      lead="Three content widths, the shell’s breakpoints, and one z-index ladder. The composition switch happens at 768px — below it the shell recomposes rather than shrinks."
    >
      <Specimen label="Containers">
        <div className={styles.containers}>
          {[
            ['Reading', 720, 'Lessons and long-form. Immersive.'],
            ['Page', 1200, 'The shell’s content width. Balanced.'],
            ['Wide', 1480, 'Admin tables and analytics. Dense.'],
          ].map(([name, px, use]) => (
            <div key={name} className={styles.containerRow}>
              <span className={styles.containerBar} style={{ width: `${((px as number) / 1480) * 100}%` }}>
                <span className={styles.containerName}>{name}</span>
                <span className="tabular">{px}px</span>
              </span>
              <span className={styles.containerUse}>{use}</span>
            </div>
          ))}
        </div>
      </Specimen>

      <Columns>
        <Column title="Breakpoints" caption={`This window: ${width}px · ${breakpoint}`}>
          <div className={styles.bpChips}>
            {verifiedWidths.map((w, i) => {
              const on = width >= w && (i === verifiedWidths.length - 1 || width < verifiedWidths[i + 1]);
              return (
                <span key={w} className={cx(styles.bpChip, on && styles.bpChipOn)}>
                  {w}
                  <span className={styles.bpName}>{breakpointFor(w)}</span>
                </span>
              );
            })}
          </div>
        </Column>
        <Column title="Layers">
          <ol className={styles.zLadder}>
            {Object.entries(zIndex)
              .sort((a, b) => b[1] - a[1])
              .map(([name, z]) => (
                <li key={name}>
                  <span className="tabular">{z}</span>
                  {name.replace(/([A-Z])/g, ' $1').toLowerCase()}
                </li>
              ))}
          </ol>
        </Column>
      </Columns>
    </DocSection>
  );
}

/* ─── 08 Iconography ────────────────────────────────────────────────────── */

const ICONS = [
  ['Video lesson', PlayCircle],
  ['Reading', BookOpenText],
  ['Live class', VideoCamera],
  ['Practice', PencilLine],
  ['Assignment', ClipboardText],
  ['Assessment', Exam],
  ['Certificate', Certificate],
  ['Rank', SealCheck],
  ['Locked', LockSimple],
  ['Upcoming', CalendarBlank],
  ['Submitted', PaperPlaneTilt],
  ['Under review', HourglassMedium],
  ['Resume', Play],
  ['Duration', Clock],
  ['Explore', Compass],
  ['Community', ChatsCircle],
  ['Notifications', Bell],
  ['Instructor', ChalkboardTeacher],
  ['Learners', UsersThree],
  ['Analytics', ChartLineUp],
] as const;

function Iconography() {
  return (
    <DocSection
      id="icons"
      index={8}
      title="Iconography"
      lead="Phosphor, duotone — the shell’s icon language. One icon per concept across the product, 16–22px, in ink colors."
    >
      <Specimen
        notes={
          <Notes
            items={[
              { term: 'Weights', text: 'Duotone by default. Fill only for status glyphs inside badges. Bold only for check marks inside nodes.' },
              { term: 'Labels', text: 'Icons are decorative. The text beside them carries the meaning; icon-only buttons always have an accessible name.' },
            ]}
          />
        }
      >
        <ul className={styles.iconGrid}>
          {ICONS.map(([label, Icon]) => (
            <li key={label}>
              <Icon size={22} />
              <span>{label}</span>
            </li>
          ))}
        </ul>
      </Specimen>
    </DocSection>
  );
}
