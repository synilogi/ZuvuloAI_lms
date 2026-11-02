import { useState } from 'react';
import { ArrowDown, ArrowUp, PencilSimple, Plus, Trash } from '@phosphor-icons/react';
import { BUNDLE_LIMITS, type AdminBundle, type BundleInput } from '@syniastrolms/domain';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton } from '@/components/ui/Button/Button';
import { InlineMessage, Skeleton } from '@/components/ui/Feedback/Feedback';
import { Field, Input, Select, Textarea } from '@/components/ui/Field/Field';
import { useAsync } from '@/hooks/useAsync';
import { saleDisplay } from '@/lib/coursePricing';
import { formatINR, plural } from '@/lib/format';
import { services } from '@/services';
import { PLATFORM_EYEBROW, PlatformError } from '../platformMeta';
import { DateTimeField, SiteImageField } from './siteFields';
import styles from '../affiliates/Affiliates.module.css';

const STATUS_TONE = { published: 'accent', draft: 'neutral', archived: 'warn' } as const;
const EMPTY: BundleInput = { title: '', summary: '', description: '', coverUrl: '', price: 0, courseIds: [], status: 'draft', publishAt: null, order: 0 };

const inputOf = (b: AdminBundle): BundleInput => ({
  title: b.title,
  summary: b.summary,
  description: b.description,
  coverUrl: b.coverUrl,
  price: b.price,
  courseIds: b.courseIds,
  status: b.status,
  publishAt: b.publishAt ?? null,
  order: b.order,
});

/** What must be right before saving, in words. The API checks the same rules and more. */
export function bundleIssue(input: BundleInput): string | undefined {
  if (input.title.trim().length < 3) return 'Give the bundle a name.';
  if (!Number.isInteger(input.price) || input.price < 1) return 'Enter a price of at least ₹1, in whole rupees.';
  if (input.status === 'published' && input.courseIds.length < BUNDLE_LIMITS.minCourses) return 'A published bundle needs at least two courses.';
  return undefined;
}

/** Course bundles (docs/17): what the website sells together, at one price. */
export default function BundlesPage() {
  const toast = useToast();
  const list = useAsync('site:admin:bundles', () => services.site.adminBundles());
  const courses = useAsync('site:admin:courses', () => services.catalog.listCourses());
  const [editing, setEditing] = useState<{ id?: string; input: BundleInput } | null>(null);
  const [removing, setRemoving] = useState<AdminBundle | null>(null);
  const [error, setError] = useState<string>();
  const [saving, setSaving] = useState(false);

  if (list.status === 'error' && !list.data) {
    return <PlatformError title="The bundles didn’t load" error={list.error} onRetry={() => void list.run().catch(() => undefined)} />;
  }

  const patch = (next: Partial<BundleInput>) => setEditing((e) => e && { ...e, input: { ...e.input, ...next } });
  const paidCourses = (courses.data ?? []).filter((c) => saleDisplay(c).kind === 'paid');
  const courseName = (id: string) => courses.data?.find((c) => c.id === id)?.title ?? 'A course not on sale now';
  const separate = editing
    ? editing.input.courseIds.reduce((sum, id) => {
        const sale = courses.data?.find((c) => c.id === id);
        const shown = sale ? saleDisplay(sale) : undefined;
        return sum + (shown?.kind === 'paid' ? shown.amount : 0);
      }, 0)
    : 0;

  const move = (index: number, by: -1 | 1) => {
    if (!editing) return;
    const ids = [...editing.input.courseIds];
    const [id] = ids.splice(index, 1);
    ids.splice(index + by, 0, id);
    patch({ courseIds: ids });
  };

  const save = async () => {
    if (!editing) return;
    const found = bundleIssue(editing.input);
    setError(found);
    if (found) return;
    setSaving(true);
    try {
      if (editing.id) await services.site.updateBundle(editing.id, editing.input);
      else await services.site.createBundle(editing.input);
      toast({ kind: 'success', title: editing.id ? 'The bundle is updated' : 'The bundle is created' });
      setEditing(null);
      await list.run().catch(() => undefined);
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
        title="Course bundles"
        description="Several paid courses sold together at one price. Bundles earn no affiliate volume, so a course on the affiliate plan is sold on its own."
        actions={
          <Button
            variant="primary"
            iconStart={<Plus size={16} />}
            onClick={() => {
              setError(undefined);
              setEditing({ input: EMPTY });
            }}
          >
            New bundle
          </Button>
        }
      />
      {!list.data ? (
        <Skeleton height={240} radius="var(--r-lg)" />
      ) : list.data.length === 0 ? (
        <div className={styles.empty}>No bundles yet. Create one to show it on the website.</div>
      ) : (
        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead>
              <tr>
                <th>Bundle</th>
                <th>Status</th>
                <th>Courses</th>
                <th>Price</th>
                <th>Orders</th>
                <th aria-label="Actions" />
              </tr>
            </thead>
            <tbody>
              {list.data.map((b) => (
                <tr key={b.id}>
                  <td>
                    <span className={styles.cellTitle}>{b.title}</span>
                    <span className={styles.cellMeta}>/bundles/{b.slug}</span>
                  </td>
                  <td>
                    <Badge tone={STATUS_TONE[b.status]}>
                      {b.status === 'published' && b.publishAt && Date.parse(b.publishAt) > Date.now()
                        ? 'Scheduled'
                        : b.status[0].toUpperCase() + b.status.slice(1)}
                    </Badge>
                  </td>
                  <td>{plural(b.courseIds.length, 'course')}</td>
                  <td>{formatINR(b.price)}</td>
                  <td>{b.orderCount}</td>
                  <td>
                    <div className={styles.rowActions}>
                      <IconButton
                        label={`Edit ${b.title}`}
                        icon={<PencilSimple size={16} />}
                        onClick={() => {
                          setError(undefined);
                          setEditing({ id: b.id, input: inputOf(b) });
                        }}
                      />
                      <IconButton label={`Delete ${b.title}`} icon={<Trash size={16} />} disabled={b.orderCount > 0} onClick={() => setRemoving(b)} />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Modal
        open={editing !== null}
        onClose={() => setEditing(null)}
        title={editing?.id ? 'Edit bundle' : 'New bundle'}
        width={640}
        footer={
          <>
            <Button onClick={() => setEditing(null)}>Cancel</Button>
            <Button variant="primary" loading={saving} onClick={() => void save()}>
              Save bundle
            </Button>
          </>
        }
      >
        {editing && (
          <div className={styles.form}>
            {error && <InlineMessage kind="error" title={error} />}
            <Field label="Name">
              <Input id="bundle-title" value={editing.input.title} maxLength={BUNDLE_LIMITS.title} onChange={(e) => patch({ title: e.target.value })} />
            </Field>
            <Field label="Short description" optional>
              <Input id="bundle-summary" value={editing.input.summary} maxLength={BUNDLE_LIMITS.summary} onChange={(e) => patch({ summary: e.target.value })} />
            </Field>
            <Field label="Full description" optional>
              <Textarea
                id="bundle-description"
                rows={4}
                value={editing.input.description}
                maxLength={BUNDLE_LIMITS.description}
                onChange={(e) => patch({ description: e.target.value })}
              />
            </Field>
            <SiteImageField
              label="Cover image"
              hint="Without one, the covers of the first courses are shown."
              value={editing.input.coverUrl}
              onChange={(coverUrl) => patch({ coverUrl })}
            />

            <fieldset className={styles.form}>
              <legend>Courses</legend>
              <p className={styles.muted}>A bundle needs at least two published, paid courses. A course on the affiliate plan can’t be included.</p>
              {editing.input.courseIds.map((id, i) => (
                <div key={id} className={styles.formActions} style={{ justifyContent: 'space-between', alignItems: 'center' }}>
                  <span>{courseName(id)}</span>
                  <span className={styles.rowActions}>
                    <IconButton label="Move up" icon={<ArrowUp size={15} />} disabled={i === 0} onClick={() => move(i, -1)} />
                    <IconButton
                      label="Move down"
                      icon={<ArrowDown size={15} />}
                      disabled={i === editing.input.courseIds.length - 1}
                      onClick={() => move(i, 1)}
                    />
                    <IconButton
                      label="Remove from bundle"
                      icon={<Trash size={15} />}
                      onClick={() => patch({ courseIds: editing.input.courseIds.filter((x) => x !== id) })}
                    />
                  </span>
                </div>
              ))}
              <Field label="Add a course">
                <Select
                  id="bundle-add-course"
                  value=""
                  disabled={!courses.data}
                  onChange={(e) => {
                    if (e.target.value) patch({ courseIds: [...editing.input.courseIds, e.target.value] });
                  }}
                >
                  <option value="">{courses.data ? 'Choose a paid, published course' : 'Loading courses…'}</option>
                  {paidCourses
                    .filter((c) => !editing.input.courseIds.includes(c.id))
                    .map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.title}
                      </option>
                    ))}
                </Select>
              </Field>
            </fieldset>

            <div className={styles.fieldRow}>
              <Field label="Bundle price (₹)" hint={separate > 0 ? `${formatINR(separate)} if bought one by one` : 'All-inclusive, in whole rupees.'}>
                <Input
                  id="bundle-price"
                  type="number"
                  min={1}
                  max={BUNDLE_LIMITS.maxPrice}
                  step={1}
                  value={editing.input.price || ''}
                  onChange={(e) => patch({ price: Math.trunc(Number(e.target.value)) || 0 })}
                />
              </Field>
              <Field label="Order on the website" hint="Lower numbers come first.">
                <Input
                  id="bundle-order"
                  type="number"
                  min={0}
                  step={1}
                  value={editing.input.order}
                  onChange={(e) => patch({ order: Math.max(0, Math.trunc(Number(e.target.value)) || 0) })}
                />
              </Field>
            </div>
            <div className={styles.fieldRow}>
              <Field label="Status">
                <Select id="bundle-status" value={editing.input.status} onChange={(e) => patch({ status: e.target.value as BundleInput['status'] })}>
                  <option value="draft">Draft: not on the website</option>
                  <option value="published">Published</option>
                  <option value="archived">Archived: no longer sold</option>
                </Select>
              </Field>
              <DateTimeField
                label="Publish from"
                hint="Leave empty to publish straight away."
                value={editing.input.publishAt}
                onChange={(publishAt) => patch({ publishAt: publishAt ?? null })}
              />
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={removing !== null}
        onClose={() => setRemoving(null)}
        tone="danger"
        title={`Delete ${removing?.title ?? 'this bundle'}?`}
        description="It leaves the website at once. Its courses are not affected."
        confirmLabel="Delete bundle"
        onConfirm={async () => {
          if (!removing) return;
          await services.site.deleteBundle(removing.id);
          setRemoving(null);
          toast({ kind: 'success', title: 'The bundle is deleted' });
          await list.run().catch(() => undefined);
        }}
      />
    </div>
  );
}
