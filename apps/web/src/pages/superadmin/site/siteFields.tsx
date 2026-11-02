import { useId, useState } from 'react';
import { UploadSimple, X } from '@phosphor-icons/react';
import { Button } from '@/components/ui/Button/Button';
import { InlineMessage } from '@/components/ui/Feedback/Feedback';
import { Field, Input } from '@/components/ui/Field/Field';
import { siteImageSrc } from '@/pages/marketing/siteImage';
import { services } from '@/services';

/** A `datetime-local` value for an ISO date, in the browser's own time. Empty for none. */
export function toLocalInput(iso: string | null | undefined): string {
  if (!iso) return '';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

/** The ISO date a `datetime-local` value means; undefined when empty or unreadable. */
export function fromLocalInput(value: string): string | undefined {
  if (!value) return undefined;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? undefined : date.toISOString();
}

/** A date and time, or none. */
export function DateTimeField({ label, hint, value, onChange }: { label: string; hint?: string; value: string | null | undefined; onChange: (iso: string | undefined) => void }) {
  const id = useId();
  return (
    <Field label={label} hint={hint} optional>
      <Input id={id} type="datetime-local" value={toLocalInput(value)} onChange={(e) => onChange(fromLocalInput(e.target.value))} />
    </Field>
  );
}

/** Uploads an image and places it on the website, with a preview and a way to take it off. */
export function SiteImageField({ label, hint, value, onChange }: { label: string; hint?: string; value: string; onChange: (url: string) => void }) {
  const id = useId();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();
  const src = siteImageSrc(value);

  const upload = async (file: File) => {
    setBusy(true);
    setError(undefined);
    try {
      const uploaded = await services.media.upload(file);
      if (!uploaded.id) throw new Error('That image could not be uploaded.');
      const placed = await services.site.placeImage(uploaded.id);
      onChange(placed.url);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'That image could not be uploaded.');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <p style={{ margin: '0 0 var(--s-2)', fontWeight: 600, fontSize: 14 }}>{label}</p>
      {hint && <p style={{ margin: '0 0 var(--s-2)', color: 'var(--muted)', fontSize: 13 }}>{hint}</p>}
      <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 'var(--s-3)' }}>
        {src && <img src={src} alt="" width={96} height={64} style={{ objectFit: 'cover', borderRadius: 'var(--r-sm)' }} />}
        <input
          id={id}
          type="file"
          accept="image/png,image/jpeg,image/webp"
          className="sr-only"
          disabled={busy}
          onChange={(e) => {
            const file = e.target.files?.[0];
            e.target.value = '';
            if (file) void upload(file);
          }}
        />
        <Button size="sm" iconStart={<UploadSimple size={15} />} loading={busy} onClick={() => document.getElementById(id)?.click()}>
          {src ? 'Replace image' : 'Upload image'}
        </Button>
        {src && (
          <Button size="sm" iconStart={<X size={15} />} onClick={() => onChange('')}>
            Remove
          </Button>
        )}
      </div>
      {error && <InlineMessage kind="error" title={error} />}
    </div>
  );
}
