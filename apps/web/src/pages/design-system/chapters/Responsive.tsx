import { useState } from 'react';
import { ArrowRight, ArrowSquareOut, BookOpenText, HandTap } from '@phosphor-icons/react';
import { breakpointFor, verifiedWidths } from '@/design/tokens';
import { useElementWidth } from '@/hooks/useElementWidth';
import { useViewport } from '@/hooks/useViewport';
import { cx } from '@/lib/cx';
import { Button } from '@/components/ui/Button/Button';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { CourseCurriculum } from '@/components/lms/course/CourseCurriculum';
import { usePreferences } from '@/providers/PreferencesProvider';
import { useSession } from '@/providers/SessionProvider';
import { foundationsCourse } from '@/services/mock/fixtures/catalog';
import { foundationsProgress } from '@/services/mock/fixtures/learner';
import { ChapterIntro, DocSection, Notes, Specimen } from '../doc/Doc';
import { SPECIMENS, type SpecimenId } from '../preview/specimens';
import styles from './Chapters.module.css';

export default function Responsive() {
  return (
    <>
      <ChapterIntro title="Responsive">
        The LMS recomposes rather than shrinks. Below 768px the shell swaps its chrome, side panels become sheets, sticky asides become bottom bars and tables
        become structured lists. Components themselves respond to their container, so they adapt wherever they are placed.
      </ChapterIntro>
      <Viewport />
      <DevicePreview />
      <Recomposition />
      <Touch />
    </>
  );
}

function Viewport() {
  const { width, breakpoint, isDesktop } = useViewport();
  return (
    <DocSection
      id="viewport"
      index={1}
      title="Live viewport"
      lead="Resize the window — the readout, the shell and every container-query component on this page respond immediately."
    >
      <div className={styles.viewportFigure}>
        <span className={styles.viewportNumber}>{width}</span>
        <span className={styles.viewportMeta}>
          px · {breakpoint} · {isDesktop ? 'desktop shell' : 'mobile shell'}
        </span>
      </div>
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
    </DocSection>
  );
}

const DEVICES: Record<string, { label: string; width: number; height: number }> = {
  mobile: { label: 'Mobile', width: 375, height: 760 },
  tablet: { label: 'Tablet', width: 768, height: 1000 },
  desktop: { label: 'Desktop', width: 1280, height: 820 },
  large: { label: 'Large desktop', width: 1920, height: 1080 },
};

function DevicePreview() {
  const [specimen, setSpecimen] = useState<SpecimenId>('course-overview');
  const [device, setDevice] = useState<string>('mobile');
  const [customWidth, setCustomWidth] = useState<number | null>(null);
  const [stageRef, stageWidth] = useElementWidth<HTMLDivElement>();
  const { theme } = usePreferences();
  const { role } = useSession();

  const base = DEVICES[device];
  const frameWidth = customWidth ?? base.width;
  const frameHeight = customWidth ? (customWidth < 768 ? 760 : 900) : base.height;
  const available = Math.max(200, stageWidth - 48);
  const scale = Math.min(1, available / frameWidth, 640 / frameHeight);
  const src = `/design-system/specimen/${specimen}?frame=1&theme=${theme}&role=${SPECIMENS[specimen].role ?? role}`;

  return (
    <DocSection
      id="device-preview"
      index={2}
      title="Across devices"
      lead="Composition studies rendered inside the real shell, in a frame at true device width and scaled to fit. Pick a composition and a width."
    >
      <div className={styles.deviceStage}>
        <div className={styles.deviceControls}>
          <SegmentedControl
            label="Composition"
            size="sm"
            value={specimen}
            onChange={setSpecimen}
            segments={(Object.keys(SPECIMENS) as SpecimenId[]).map((id) => ({ value: id, label: SPECIMENS[id].label }))}
          />
          <SegmentedControl
            label="Device"
            size="sm"
            value={customWidth ? 'custom' : device}
            onChange={(v) => {
              if (v === 'custom') return;
              setDevice(v);
              setCustomWidth(null);
            }}
            segments={Object.entries(DEVICES).map(([id, d]) => ({ value: id, label: d.label }))}
          />
        </div>
        <div className={styles.widthChips} role="group" aria-label="Exact width">
          {verifiedWidths.map((w) => (
            <button
              key={w}
              type="button"
              aria-pressed={frameWidth === w}
              className={cx(styles.widthChip, frameWidth === w && styles.widthChipOn)}
              onClick={() => setCustomWidth(w)}
            >
              {w}
            </button>
          ))}
        </div>

        <div ref={stageRef} className={styles.deviceViewport} style={{ height: frameHeight * scale + 48 }}>
          <div className={styles.deviceFrame} style={{ width: frameWidth, height: frameHeight, transform: `scale(${scale})` }}>
            <iframe key={`${specimen}-${theme}`} title={`${SPECIMENS[specimen].label} at ${frameWidth}px`} src={src} loading="lazy" />
          </div>
        </div>
        <div className={styles.deviceCaption}>
          <span>
            {SPECIMENS[specimen].label} · {frameWidth} × {frameHeight} · {breakpointFor(frameWidth)} · {Math.round(scale * 100)}%
          </span>
          <a href={src.replace('frame=1&', '')} target="_blank" rel="noreferrer">
            Open full size <ArrowSquareOut size={13} />
          </a>
        </div>
        <p className={styles.caption}>{SPECIMENS[specimen].description}</p>
      </div>
    </DocSection>
  );
}

const RULES = [
  {
    from: 'Sidebar',
    to: 'Header, bottom bar, drawer',
    text: 'Four primary destinations move to the bottom bar; everything else lives in the menu drawer with 48px rows. Search opens full screen.',
  },
  {
    from: 'Side panel',
    to: 'Bottom sheet',
    text: 'AdaptivePanel renders a drawer at ≥768px and a thumb-anchored sheet below — same content, same API.',
    demo: true,
  },
  {
    from: 'Sticky aside action',
    to: 'Sticky bottom bar',
    text: 'StickyActionBar keeps the primary action in the aside on desktop and pins a compact bar above the bottom nav on phones.',
  },
  {
    from: 'Table',
    to: 'Structured list',
    text: 'DataTable swaps to list items under 640px of container: heading, status, one meta line, and an explicit Details disclosure.',
  },
  {
    from: 'Multi-column',
    to: 'Prioritised flow',
    text: 'The action and progress come first, then content, then supporting detail — order is decided per composition, not by source order.',
  },
  {
    from: 'Hover',
    to: 'Explicit action',
    text: 'Tooltips only repeat what is on screen. Anything a learner needs — a lock reason, a due date — is written inline.',
  },
];

function Recomposition() {
  const [open, setOpen] = useState(false);
  return (
    <DocSection id="recomposition" index={3} title="Recomposition rules" lead="What changes below the composition breakpoint, and why.">
      <ol className={styles.rules}>
        {RULES.map((r) => (
          <li key={r.from} className={styles.rule}>
            <span className={styles.ruleFromTo}>
              <span className={styles.ruleFrom}>{r.from}</span>
              <ArrowRight size={15} className={styles.ruleArrow} />
              <span>{r.to}</span>
            </span>
            <span className={styles.ruleText}>{r.text}</span>
            <span className={styles.ruleAction}>
              {r.demo && (
                <Button size="sm" iconStart={<BookOpenText size={15} />} onClick={() => setOpen(true)}>
                  Try it
                </Button>
              )}
            </span>
          </li>
        ))}
      </ol>
      <AdaptivePanel open={open} onClose={() => setOpen(false)} eyebrow="Class 10 Mathematics" title="Curriculum">
        <div data-density="immersive">
          <CourseCurriculum
            course={foundationsCourse}
            snapshot={foundationsProgress}
            currentLessonId={foundationsProgress.lastLessonId}
            onSelectLesson={() => setOpen(false)}
          />
        </div>
      </AdaptivePanel>
    </DocSection>
  );
}

function Touch() {
  return (
    <DocSection id="touch" index={4} title="Touch & input" lead="Phones get their own ergonomics, not a scaled desktop.">
      <Specimen
        notes={
          <Notes
            items={[
              { term: 'Targets', text: 'Every control is at least 44 × 44 below 768px, including icon buttons, lesson rows and menu items.' },
              { term: 'Inputs', text: '16px text on mobile prevents zoom on focus.' },
              { term: 'Safe areas', text: 'Bottom bar, sheets and sticky actions respect env(safe-area-inset-*).' },
            ]}
          />
        }
      >
        <div className={styles.touchDemo}>
          <span className={styles.touchLabel}>
            <span className={styles.touchTarget}>
              <HandTap size={20} />
            </span>
            44 × 44
          </span>
          <span className={styles.touchLabel}>
            <Button variant="primary" size="lg">
              Resume lesson
            </Button>
            Primary · 44px
          </span>
        </div>
      </Specimen>
    </DocSection>
  );
}
