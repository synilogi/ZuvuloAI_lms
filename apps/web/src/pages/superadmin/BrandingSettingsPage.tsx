import { useEffect, useId, useRef, useState, type DragEvent, type FormEvent } from 'react';
import { ArrowCounterClockwise, FloppyDisk, Image as ImageIcon, UploadSimple, X } from '@phosphor-icons/react';
import { BRAND_ASSET_KINDS, BRAND_ASSET_RULES, brandAssetIssues, type BrandAssetKind } from '@syniastrolms/domain';
import { useBranding } from '@/branding/BrandingProvider';
import { BRAND_NAME, DEFAULT_BRAND } from '@/branding/defaults';
import { readImageSize } from '@/branding/imageFile';
import { useAsync } from '@/hooks/useAsync';
import { cx } from '@/lib/cx';
import { formatDate } from '@/lib/format';
import { PageHeader } from '@/components/page/PageHeader';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { ServiceError, services, type SavedBrandAsset } from '@/services';
import { PLATFORM_EYEBROW, PlatformError, formatBytes } from './platformMeta';
import page from './Platform.module.css';
import styles from './Branding.module.css';

/*
 * The platform's logo and favicon. A super admin picks a file, sees it as it will be shown — on a light and a dark
 * surface, and in a browser tab — and saves; or puts the built-in ZuviloAI branding back. The checks made here as a
 * file is picked are the API's own rules (`brandAssetIssues`), shown early; the API checks the file itself again
 * and is the one that decides. Nothing on this page concerns an academy's own appearance.
 */

/** A file picked and not yet saved. */
interface Picked {
  file: File;
  /** The browser's own copy, for the preview. */
  url: string;
  width?: number;
  height?: number;
  issues: string[];
  /** Still being measured. */
  reading: boolean;
}

type Picks = Partial<Record<BrandAssetKind, Picked>>;

const DEFAULT_PREVIEW: Record<BrandAssetKind, { light: string; dark: string }> = {
  logo: DEFAULT_BRAND.lockup,
  favicon: DEFAULT_BRAND.mark,
};

const accept = (kind: BrandAssetKind) => [...BRAND_ASSET_RULES[kind].mimes, ...BRAND_ASSET_RULES[kind].exts].join(',');

const limits = (kind: BrandAssetKind) => {
  const rule = BRAND_ASSET_RULES[kind];
  const size =
    kind === 'favicon' ? `square, ${rule.minWidth} to ${rule.maxWidth} px` : `${rule.minWidth} × ${rule.minHeight} to ${rule.maxWidth} × ${rule.maxHeight} px`;
  return `${rule.formats} · up to ${formatBytes(rule.maxBytes)} · ${size}`;
};

const message = (e: unknown, fallback: string) => (e instanceof Error && e.message ? e.message : fallback);

export default function BrandingSettingsPage() {
  const toast = useToast();
  const branding = useBranding();
  const query = useAsync('platform:branding', () => services.branding.settings());
  const data = query.data;
  const reload = () => query.run().catch(() => undefined);

  const [picks, setPicks] = useState<Picks>({});
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string>();
  /** What to put back: one asset, or both. */
  const [restoring, setRestoring] = useState<BrandAssetKind | 'all' | null>(null);

  // The previews are the browser's copies of the picked files: released when replaced, and when the page is left.
  const live = useRef<Picks>({});
  live.current = picks;
  useEffect(() => () => Object.values(live.current).forEach((p) => URL.revokeObjectURL(p.url)), []);

  const drop = (kind: BrandAssetKind) =>
    setPicks((all) => {
      const { [kind]: gone, ...rest } = all;
      if (gone) URL.revokeObjectURL(gone.url);
      return rest;
    });

  const pick = (kind: BrandAssetKind, file: File) => {
    setSaveError(undefined);
    const url = URL.createObjectURL(file);
    const facts = { name: file.name, mime: file.type || undefined, bytes: file.size };
    const early = brandAssetIssues(kind, facts);
    setPicks((all) => {
      if (all[kind]) URL.revokeObjectURL(all[kind].url);
      return { ...all, [kind]: { file, url, issues: early, reading: early.length === 0 } };
    });
    if (early.length) return;
    // Its real size decides the rest; a file the browser cannot draw is not an image.
    readImageSize(file).then(
      (size) =>
        setPicks((all) =>
          all[kind]?.url === url ? { ...all, [kind]: { ...all[kind], ...size, reading: false, issues: brandAssetIssues(kind, { ...facts, ...size }) } } : all,
        ),
      () =>
        setPicks((all) =>
          all[kind]?.url === url
            ? {
                ...all,
                [kind]: {
                  ...all[kind],
                  reading: false,
                  issues: [`This file could not be read as an image. Choose a ${BRAND_ASSET_RULES[kind].formats} file.`],
                },
              }
            : all,
        ),
    );
  };

  const chosen = BRAND_ASSET_KINDS.filter((kind) => picks[kind]);
  const ready = chosen.length > 0 && chosen.every((kind) => !picks[kind]!.reading && picks[kind]!.issues.length === 0);
  const hasSaved = !!data && (!!data.logo || !!data.favicon);

  const save = async (e: FormEvent) => {
    e.preventDefault();
    if (!ready || saving) return;
    setSaving(true);
    setSaveError(undefined);
    try {
      await services.branding.save(Object.fromEntries(chosen.map((kind) => [kind, picks[kind]!.file])));
      chosen.forEach(drop);
      await Promise.all([reload(), branding.refresh()]);
      const what = chosen.length === 2 ? 'logo and favicon are' : `${chosen[0]} is`;
      toast({ kind: 'success', title: 'Branding saved', text: `The new ${what} live across the platform.` });
    } catch (err) {
      // The server's verdict on each file goes beside that file; anything else is said once, above the buttons.
      const refused = err instanceof ServiceError ? (err.issues ?? []) : [];
      if (refused.length) {
        setPicks((all) => {
          const next = { ...all };
          for (const kind of BRAND_ASSET_KINDS) {
            const mine = refused.filter((i) => i.field === kind).map((i) => i.message);
            if (next[kind] && mine.length) next[kind] = { ...next[kind], issues: mine };
          }
          return next;
        });
        setSaveError('The server did not accept these files. Nothing was changed.');
      } else setSaveError(message(err, 'The branding could not be saved. Nothing was changed.'));
      toast({ kind: 'error', title: 'Branding not saved', text: 'Check the files and try again.' });
    } finally {
      setSaving(false);
    }
  };

  const restore = async () => {
    if (!restoring) return;
    const kind = restoring === 'all' ? undefined : restoring;
    await services.branding.restore(kind);
    (kind ? [kind] : BRAND_ASSET_KINDS).forEach(drop);
    setRestoring(null);
    await Promise.all([reload(), branding.refresh()]);
    toast({
      kind: 'success',
      title: kind ? `Default ${kind} restored` : 'Default branding restored',
      text: `The built-in ${BRAND_NAME} ${kind ?? 'logo and favicon'} ${kind ? 'is' : 'are'} back in use.`,
    });
  };

  return (
    <div className={page.page}>
      <PageHeader
        eyebrow={PLATFORM_EYEBROW}
        title="Branding"
        description={`The ${BRAND_NAME} logo, and the small icon shown in browser tabs (the favicon), used on the website, the sign-in screens and every workspace.`}
        actions={
          <Button onClick={() => setRestoring('all')} disabled={!hasSaved || saving} iconStart={<ArrowCounterClockwise size={16} />}>
            Restore default branding
          </Button>
        }
      />

      {query.status === 'error' && !data ? (
        <PlatformError title="The branding settings didn’t load" error={query.error} onRetry={reload} />
      ) : !data ? (
        <div className={styles.grid} aria-busy="true" aria-label="Loading the branding settings">
          <Skeleton height={420} radius="var(--r-lg)" />
          <Skeleton height={420} radius="var(--r-lg)" />
        </div>
      ) : (
        <form onSubmit={save} className={styles.form} noValidate>
          <div className={styles.grid}>
            {BRAND_ASSET_KINDS.map((kind) => (
              <AssetCard
                key={kind}
                kind={kind}
                saved={data[kind]}
                picked={picks[kind]}
                busy={saving}
                onPick={(file) => pick(kind, file)}
                onClear={() => drop(kind)}
                onRestore={() => setRestoring(kind)}
              />
            ))}
          </div>

          {saveError && <InlineMessage kind="error">{saveError}</InlineMessage>}

          <div className={styles.saveBar}>
            <p className={styles.saveNote}>
              {chosen.length === 0
                ? 'Choose a new logo or favicon to preview it here. Nothing changes until you save.'
                : ready
                  ? `Ready to save: ${chosen.join(' and ')}. Every visitor sees the change on their next page load.`
                  : 'Fix the files marked above before saving.'}
            </p>
            <div className={styles.saveActions}>
              <Button onClick={() => chosen.forEach(drop)} disabled={chosen.length === 0 || saving}>
                Discard
              </Button>
              <Button type="submit" variant="primary" disabled={!ready} loading={saving} iconStart={<FloppyDisk size={16} />}>
                Save changes
              </Button>
            </div>
          </div>
        </form>
      )}

      <ConfirmDialog
        open={restoring !== null}
        onClose={() => setRestoring(null)}
        onConfirm={restore}
        title={restoring === 'all' ? `Restore the default ${BRAND_NAME} branding?` : `Restore the default ${restoring ?? 'asset'}?`}
        description={
          restoring === 'all'
            ? `The uploaded logo and favicon are removed, and the built-in ${BRAND_NAME} ones are shown everywhere again.`
            : `The uploaded ${restoring} is removed, and the built-in ${BRAND_NAME} one is shown everywhere again.`
        }
        confirmLabel="Restore default"
        icon={<ArrowCounterClockwise size={20} />}
      >
        <p className={styles.confirmNote}>Accounts and courses are not affected. You can upload a file again at any time.</p>
      </ConfirmDialog>
    </div>
  );
}

interface AssetCardProps {
  kind: BrandAssetKind;
  saved: SavedBrandAsset | null;
  picked?: Picked;
  busy: boolean;
  onPick: (file: File) => void;
  onClear: () => void;
  onRestore: () => void;
}

function AssetCard({ kind, saved, picked, busy, onPick, onClear, onRestore }: AssetCardProps) {
  const rule = BRAND_ASSET_RULES[kind];
  const inputId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const [over, setOver] = useState(false);
  // A saved file that will not load is shown as what a visitor gets instead: the built-in one.
  const [broken, setBroken] = useState<string>();

  const savedUrl = saved && saved.url !== broken ? saved.url : undefined;
  const shown = picked?.url ?? savedUrl;
  const preview = { light: shown ?? DEFAULT_PREVIEW[kind].light, dark: shown ?? DEFAULT_PREVIEW[kind].dark };
  const state = picked ? 'picked' : saved ? 'saved' : 'default';
  const issues = picked?.issues ?? [];

  const onDrop = (e: DragEvent) => {
    e.preventDefault();
    setOver(false);
    const file = e.dataTransfer.files[0];
    if (file && !busy) onPick(file);
  };

  return (
    <section className={styles.card} aria-labelledby={`${inputId}-title`}>
      <div className={styles.cardHead}>
        <h2 id={`${inputId}-title`} className={styles.cardTitle}>
          {rule.label}
        </h2>
        {state === 'picked' ? (
          <Badge size="sm" tone={issues.length ? 'danger' : 'warn'} dot>
            {issues.length ? 'Can’t be used' : 'Not saved yet'}
          </Badge>
        ) : (
          <Badge size="sm" tone={state === 'saved' ? 'accent' : 'neutral'}>
            {state === 'saved' ? 'Custom' : `${BRAND_NAME} default`}
          </Badge>
        )}
      </div>

      <div
        className={cx(styles.stage, over && styles.stageOver)}
        onDragOver={(e) => {
          e.preventDefault();
          setOver(true);
        }}
        onDragLeave={() => setOver(false)}
        onDrop={onDrop}
      >
        <figure className={cx(styles.swatch, styles.swatchLight)}>
          <img className={styles[kind]} src={preview.light} alt={`${rule.label} on a light background`} onError={() => saved && setBroken(saved.url)} />
          <figcaption>Light</figcaption>
        </figure>
        <figure className={cx(styles.swatch, styles.swatchDark)}>
          <img className={styles[kind]} src={preview.dark} alt={`${rule.label} on a dark background`} />
          <figcaption>Dark</figcaption>
        </figure>
        {kind === 'favicon' && (
          <figure className={styles.tab}>
            <span className={styles.tabChip}>
              <img src={preview.light} alt="" />
              <span>{BRAND_NAME}</span>
            </span>
            <figcaption>Browser tab</figcaption>
          </figure>
        )}
      </div>

      <dl className={styles.facts}>
        {picked ? (
          <>
            <Fact label="Selected file" value={picked.file.name} />
            <Fact
              label="Size"
              value={`${picked.width && picked.height ? `${picked.width} × ${picked.height} px · ` : picked.reading ? 'Measuring… · ' : ''}${formatBytes(picked.file.size)}`}
            />
          </>
        ) : saved ? (
          <>
            <Fact label="Saved file" value={saved.name} />
            <Fact label="Size" value={`${saved.width} × ${saved.height} px · ${formatBytes(saved.sizeBytes)}`} />
            <Fact label="Updated" value={`${formatDate(saved.updatedAt)}${saved.updatedBy ? ` by ${saved.updatedBy}` : ''}`} />
          </>
        ) : (
          <Fact label="In use" value={`The built-in ${BRAND_NAME} ${kind}`} />
        )}
      </dl>

      {issues.length > 0 && (
        <InlineMessage kind="error" title="This file can’t be used.">
          {issues.join(' ')}
        </InlineMessage>
      )}
      {saved && broken === saved.url && !picked && (
        <InlineMessage kind="warn">
          The saved file could not be loaded, so visitors see the built-in {kind}. Upload it again, or restore the default.
        </InlineMessage>
      )}

      <div className={styles.cardActions}>
        <input
          ref={inputRef}
          id={inputId}
          type="file"
          accept={accept(kind)}
          className="sr-only"
          tabIndex={-1}
          aria-label={`Choose a ${kind} file`}
          disabled={busy}
          onChange={(e) => {
            const file = e.target.files?.[0];
            if (file) onPick(file);
            e.target.value = '';
          }}
        />
        <Button onClick={() => inputRef.current?.click()} disabled={busy} iconStart={picked ? <ImageIcon size={16} /> : <UploadSimple size={16} />}>
          {picked ? 'Choose a different file' : saved ? `Replace ${kind}` : `Upload ${kind}`}
        </Button>
        {picked && (
          <Button variant="ghost" onClick={onClear} disabled={busy} iconStart={<X size={16} />}>
            Remove selection
          </Button>
        )}
        {saved && !picked && (
          <Button variant="ghost" onClick={onRestore} disabled={busy} iconStart={<ArrowCounterClockwise size={16} />}>
            Restore default
          </Button>
        )}
      </div>

      <p className={styles.hint}>
        {rule.guidance} <span className={styles.limits}>{limits(kind)}. You can also drop a file on the preview.</span>
      </p>
    </section>
  );
}

const Fact = ({ label, value }: { label: string; value: string }) => (
  <div className={styles.fact}>
    <dt>{label}</dt>
    <dd>{value}</dd>
  </div>
);
