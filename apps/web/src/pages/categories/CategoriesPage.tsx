import { useEffect, useState, type FormEvent } from 'react';
import { Link, useLocation, useMatch, useNavigate, useSearchParams } from 'react-router-dom';
import { ArrowDown, ArrowUp, DotsThree, Eye, FolderSimplePlus, MagnifyingGlass, PencilSimple, Plus, Trash } from '@phosphor-icons/react';
import type { Category, CategoryGlyph as Glyph, CategoryInput, CategoryStatus, Level } from '@syniastrolms/domain';
import { useAsync } from '@/hooks/useAsync';
import { usePermissions } from '@/hooks/usePermissions';
import { useNow } from '@/hooks/useNow';
import { useViewport } from '@/hooks/useViewport';
import { formatCount, formatDate, formatRelative, plural } from '@/lib/format';
import { ChoiceCards, ErrorSummary, type FieldIssue } from '@/components/forms/Forms';
import { PageHeader } from '@/components/page/PageHeader';
import { Badge } from '@/components/ui/Badge/Badge';
import { Button, IconButton, LinkButton } from '@/components/ui/Button/Button';
import { Checkbox } from '@/components/ui/Checkbox/Checkbox';
import { DataTable, type Column } from '@/components/ui/DataTable/DataTable';
import { Field, Input, SearchInput, Select, Textarea } from '@/components/ui/Field/Field';
import { InlineMessage, Skeleton, StateMessage } from '@/components/ui/Feedback/Feedback';
import { Menu } from '@/components/ui/Menu/Menu';
import { SegmentedControl } from '@/components/ui/SegmentedControl/SegmentedControl';
import { AdaptivePanel } from '@/components/overlays/AdaptivePanel';
import { ConfirmDialog } from '@/components/overlays/ConfirmDialog';
import { Modal } from '@/components/overlays/Overlay';
import { useToast } from '@/components/overlays/Toast/ToastProvider';
import { CategoryGlyph, glyphLabels } from '@/components/lms/course/CategoryGlyph';
import { CourseCover } from '@/components/lms/course/CourseCover';
import { CourseStatusBadge } from '@/components/lms/course/CourseStatus';
import { usePageCrumbs } from '@/shell/PageCrumbs';
import { services, type CategoryRow, type CategorySort } from '@/services';
import styles from './Categories.module.css';

const BASE = '/admin/categories';
const GLYPHS: Glyph[] = ['sun', 'moon', 'houses', 'orbits', 'nakshatra', 'hourglass', 'lotus', 'compass'];
const STATUS_META: Record<CategoryStatus, { label: string; tone: 'accent' | 'neutral'; description: string }> = {
  active: { label: 'Active', tone: 'accent', description: 'Shown in the catalog, filters and course pages.' },
  hidden: { label: 'Hidden', tone: 'neutral', description: 'Kept for staff. Learners don’t see it; its courses stay reachable.' },
};

export default function CategoriesPage() {
  const { can } = usePermissions();
  const { pathname } = useLocation();
  const match = useMatch(`${BASE}/:categoryId/*`);
  const categoryId = match?.params.categoryId === 'new' ? undefined : match?.params.categoryId;
  const navigate = useNavigate();
  const toast = useToast();
  const now = useNow();
  const { isMobile } = useViewport();
  const [params, setParams] = useSearchParams();
  const [deleting, setDeleting] = useState<CategoryRow | null>(null);

  const mode = pathname.endsWith('/new') ? 'create' : pathname.endsWith('/edit') ? 'edit' : categoryId ? 'view' : null;
  const search = params.get('q') ?? '';
  const status = (params.get('status') as CategoryStatus | 'all') ?? 'all';
  const sort = (params.get('sort') as CategorySort) ?? 'order';
  const keep = params.toString() ? `?${params.toString()}` : '';
  const close = () => navigate(`${BASE}${keep}`);

  const update = (next: Record<string, string | undefined>) => {
    const p = new URLSearchParams(params);
    for (const [key, value] of Object.entries(next)) {
      if (!value || (key === 'status' && value === 'all') || (key === 'sort' && value === 'order')) p.delete(key);
      else p.set(key, value);
    }
    setParams(p, { replace: true });
  };

  const query = { search, status, sort };
  const list = useAsync(JSON.stringify(query), () => services.categories.list(query));
  const levels = useAsync('levels', () => services.catalog.listLevels());
  const reload = () => list.run().catch(() => undefined);

  const rows = list.data?.rows ?? [];
  const counts = list.data?.counts;
  const filtered = Boolean(search) || status !== 'all';
  const active = mode === 'edit' || mode === 'view' ? rows.find((r) => r.category.id === categoryId) : undefined;

  usePageCrumbs(mode === 'create' ? [{ label: 'New category' }] : active ? [{ label: active.category.name }] : []);

  const move = async (row: CategoryRow, dir: -1 | 1) => {
    try {
      await services.categories.update(row.category.id, { order: row.category.order + dir });
      toast({
        kind: 'success',
        title: `${row.category.name} moved ${dir === -1 ? 'up' : 'down'}`,
        text: `Now position ${row.category.order + dir} in the catalog.`,
      });
      reload();
    } catch (e) {
      toast({ kind: 'error', title: 'Couldn’t reorder', text: (e as Error).message });
    }
  };

  const total = counts?.all ?? 0;
  const actionsFor = (row: CategoryRow) => (
    <span className={styles.rowActions}>
      <IconButton
        size="sm"
        label={`Edit ${row.category.name}`}
        icon={<PencilSimple size={16} />}
        onClick={() => navigate(`${BASE}/${row.category.id}/edit${keep}`)}
      />
      <Menu
        align="end"
        width={210}
        trigger={(props) => <IconButton {...props} size="sm" label={`More actions for ${row.category.name}`} icon={<DotsThree size={18} weight="bold" />} />}
        sections={[
          {
            items: [
              { id: 'view', label: 'View details', icon: <Eye size={17} />, onSelect: () => navigate(`${BASE}/${row.category.id}${keep}`) },
              { id: 'edit', label: 'Edit', icon: <PencilSimple size={17} />, onSelect: () => navigate(`${BASE}/${row.category.id}/edit${keep}`) },
            ],
          },
          {
            label: 'Display order',
            items: [
              { id: 'up', label: 'Move up', icon: <ArrowUp size={17} />, disabled: row.category.order <= 1, onSelect: () => move(row, -1) },
              { id: 'down', label: 'Move down', icon: <ArrowDown size={17} />, disabled: row.category.order >= total, onSelect: () => move(row, 1) },
            ],
          },
          { items: [{ id: 'delete', label: 'Delete…', icon: <Trash size={17} />, tone: 'danger', onSelect: () => setDeleting(row) }] },
        ]}
      />
    </span>
  );

  const columns: Column<CategoryRow>[] = [
    {
      key: 'order',
      header: 'Order',
      width: '64px',
      mobile: 'hidden',
      render: (r) => <span className={styles.order}>{String(r.category.order).padStart(2, '0')}</span>,
    },
    {
      key: 'name',
      header: 'Category',
      mobile: 'primary',
      render: (r) => (
        <span className={styles.nameCell}>
          <CategoryGlyph glyph={r.category.glyph} size={40} />
          <span className={styles.nameText}>
            <Link to={`${BASE}/${r.category.id}${keep}`} className={styles.name}>
              {r.category.name}
            </Link>
            <span className={styles.description}>{r.category.description}</span>
          </span>
        </span>
      ),
    },
    {
      key: 'courses',
      header: 'Courses',
      width: '130px',
      mobile: 'meta',
      render: (r) => (
        <span className={styles.countCell}>
          <span className="tabular">{plural(r.courseCount, 'course')}</span>
          <span className={styles.subtle}>{r.courseCount ? `${r.publishedCount} published` : 'None yet'}</span>
        </span>
      ),
    },
    {
      key: 'status',
      header: 'Status',
      width: '104px',
      mobile: 'status',
      render: (r) => (
        <Badge tone={STATUS_META[r.category.status].tone} dot>
          {STATUS_META[r.category.status].label}
        </Badge>
      ),
    },
    {
      key: 'updated',
      header: 'Updated',
      width: '130px',
      mobile: 'detail',
      render: (r) => (
        <time dateTime={r.category.updatedAt} title={formatDate(r.category.updatedAt)} className={styles.nowrap}>
          {formatRelative(r.category.updatedAt, now)}
        </time>
      ),
    },
    { key: 'actions', header: 'Actions', width: '96px', align: 'end', mobile: 'hidden', render: actionsFor },
  ];

  return (
    <div className={styles.page}>
      <PageHeader
        title="Categories"
        count={counts ? plural(counts.all, 'category', 'categories') : undefined}
        description="Categories organise the catalog by subject. Learners browse and filter by them, and a category can span several levels of the path."
        actions={
          can('catalog.categories.manage') && (
            <LinkButton to={`${BASE}/new${keep}`} iconStart={<Plus size={16} />}>
              Add category
            </LinkButton>
          )
        }
      />

      <div className={styles.controls} hidden={counts?.all === 0 && !filtered}>
        <SegmentedControl<CategoryStatus | 'all'>
          label="Category status"
          value={status}
          onChange={(v) => update({ status: v })}
          segments={[
            { value: 'all', label: 'All', count: counts?.all },
            { value: 'active', label: 'Active', count: counts?.active },
            { value: 'hidden', label: 'Hidden', count: counts?.hidden },
          ]}
        />
        <div className={styles.toolbar}>
          <div className={styles.search}>
            <SearchInput value={search} onValueChange={(v) => update({ q: v })} placeholder="Search categories" aria-label="Search categories" />
          </div>
          <Field label="Sort" hideLabel className={styles.sort}>
            <Select value={sort} onChange={(e) => update({ sort: e.target.value })}>
              <option value="order">Display order</option>
              <option value="name">Name A–Z</option>
              <option value="courses">Most courses</option>
              <option value="updated">Recently updated</option>
            </Select>
          </Field>
        </div>
      </div>

      {list.status === 'error' && !list.data ? (
        <StateMessage
          kind="error"
          title="Categories didn’t load"
          actions={
            <Button variant="primary" onClick={reload}>
              Try again
            </Button>
          }
        >
          {list.error.message}
        </StateMessage>
      ) : list.data && rows.length === 0 ? (
        filtered ? (
          <StateMessage
            icon={<MagnifyingGlass size={26} />}
            title={search ? `No categories match “${search}”` : `No ${status} categories`}
            actions={<Button onClick={() => update({ q: undefined, status: undefined })}>Clear filters</Button>}
          >
            Try another word, or show every status.
          </StateMessage>
        ) : (
          <StateMessage
            icon={<FolderSimplePlus size={26} />}
            title="No categories yet"
            actions={
              <LinkButton to={`${BASE}/new`} iconStart={<Plus size={16} />}>
                Add your first category
              </LinkButton>
            }
          >
            Start with the broad subjects learners look for — School Mathematics, Science, Competitive Exams.
          </StateMessage>
        )
      ) : isMobile ? (
        <ul className={styles.cards} aria-label="Categories" aria-busy={!list.data || undefined}>
          {!list.data
            ? Array.from({ length: 4 }, (_, i) => (
                <li key={i} className={styles.card}>
                  <Skeleton width={44} height={44} radius="var(--r-md)" />
                  <span className={styles.cardText}>
                    <Skeleton width="60%" height={12} />
                    <Skeleton width="90%" height={8} />
                  </span>
                </li>
              ))
            : rows.map((r) => (
                <li key={r.category.id} className={styles.card}>
                  <CategoryGlyph glyph={r.category.glyph} size={44} />
                  <span className={styles.cardText}>
                    <Link to={`${BASE}/${r.category.id}${keep}`} className={styles.name}>
                      {r.category.name}
                    </Link>
                    <span className={styles.cardMeta}>
                      {plural(r.courseCount, 'course')} · updated {formatRelative(r.category.updatedAt, now)}
                    </span>
                  </span>
                  <span className={styles.cardSide}>
                    <Badge size="sm" tone={STATUS_META[r.category.status].tone} dot>
                      {STATUS_META[r.category.status].label}
                    </Badge>
                    {actionsFor(r)}
                  </span>
                </li>
              ))}
        </ul>
      ) : (
        <div className={styles.tablePanel}>
          <DataTable
            label="Categories"
            rows={rows}
            columns={columns}
            rowKey={(r) => r.category.id}
            rowLabel={(r) => r.category.name}
            loading={!list.data}
            skeletonRows={6}
          />
        </div>
      )}

      {mode === 'view' && categoryId && (
        <CategoryDetails
          id={categoryId}
          levels={levels.data ?? []}
          onClose={close}
          onEdit={() => navigate(`${BASE}/${categoryId}/edit${keep}`)}
          onDelete={(row) => setDeleting(row)}
        />
      )}
      {(mode === 'create' || mode === 'edit') && levels.data && list.data && (
        <CategoryForm
          key={`${mode}-${categoryId ?? 'new'}`}
          category={mode === 'edit' ? active?.category : undefined}
          missing={mode === 'edit' && !active}
          levels={levels.data}
          total={total}
          onClose={close}
          onSaved={(saved, created) => {
            toast({ kind: 'success', title: created ? 'Category added' : 'Category saved', text: saved.name });
            reload();
            navigate(`${BASE}/${saved.id}${keep}`);
          }}
        />
      )}

      {deleting && (
        <DeleteCategoryDialog
          row={deleting}
          onClose={() => setDeleting(null)}
          onDeleted={(moved) => {
            toast({
              kind: 'success',
              title: `${deleting.category.name} deleted`,
              text: moved ? `${plural(moved, 'course')} moved to the new category.` : 'No courses were affected.',
            });
            setDeleting(null);
            if (mode) close();
            reload();
          }}
        />
      )}
    </div>
  );
}

/* ─── Details ──────────────────────────────────────────────────────────── */

function CategoryDetails({
  id,
  levels,
  onClose,
  onEdit,
  onDelete,
}: {
  id: string;
  levels: Level[];
  onClose: () => void;
  onEdit: () => void;
  onDelete: (row: CategoryRow) => void;
}) {
  const detail = useAsync(`category:${id}`, () => services.categories.get(id));
  const d = detail.data;
  return (
    <AdaptivePanel
      open
      onClose={onClose}
      eyebrow="Category"
      title={d?.category.name ?? 'Category'}
      width={480}
      footer={
        d && (
          <>
            <Button variant="danger" iconStart={<Trash size={16} />} onClick={() => onDelete(d)}>
              Delete
            </Button>
            <Button variant="primary" iconStart={<PencilSimple size={16} />} onClick={onEdit}>
              Edit category
            </Button>
          </>
        )
      }
    >
      {detail.status === 'error' && !d ? (
        <StateMessage kind="error" title="Details didn’t load" compact>
          {detail.error.message}
        </StateMessage>
      ) : !d ? (
        <div className={styles.detailSkeleton}>
          <Skeleton width={96} height={96} radius="var(--r-lg)" />
          <Skeleton width="80%" height={12} />
          <Skeleton width="60%" height={12} />
        </div>
      ) : (
        <div className={styles.detail}>
          <div className={styles.detailHead}>
            <CategoryGlyph glyph={d.category.glyph} size={88} />
            <div>
              <Badge tone={STATUS_META[d.category.status].tone} dot>
                {STATUS_META[d.category.status].label}
              </Badge>
              <p className={styles.detailDescription}>{d.category.description}</p>
            </div>
          </div>
          <dl className={styles.detailFigures}>
            <div>
              <dt>Courses</dt>
              <dd>{d.courseCount}</dd>
            </div>
            <div>
              <dt>Published</dt>
              <dd>{d.publishedCount}</dd>
            </div>
            <div>
              <dt>Learners</dt>
              <dd>{formatCount(d.learnerCount)}</dd>
            </div>
          </dl>
          <div>
            <h4 className={styles.detailLabel}>Levels</h4>
            <div className={styles.levelChips}>
              {levels
                .filter((l) => d.category.levelIds.includes(l.id))
                .map((l) => (
                  <Badge key={l.id}>{l.name}</Badge>
                ))}
            </div>
          </div>
          <div>
            <h4 className={styles.detailLabel}>Courses in this category</h4>
            {d.courses.length ? (
              <ul className={styles.detailCourses}>
                {d.courses.map((c) => (
                  <li key={c.id}>
                    <CourseCover motif={c.coverMotif} imageUrl={c.coverImageUrl} className={styles.detailCover} />
                    <span className={styles.nameText}>
                      <Link to={`/admin/courses/${c.id}`} className={styles.name}>
                        {c.title}
                      </Link>
                      <span className={styles.subtle}>{c.enrolledCount ? `${formatCount(c.enrolledCount)} learners` : 'No learners yet'}</span>
                    </span>
                    <CourseStatusBadge status={c.status} size="sm" />
                  </li>
                ))}
              </ul>
            ) : (
              <p className={styles.subtle}>No courses yet. Choose this category when creating or editing a course.</p>
            )}
          </div>
          <p className={styles.subtle}>
            Position {d.category.order} in the catalog · Updated {formatDate(d.category.updatedAt)}
          </p>
        </div>
      )}
    </AdaptivePanel>
  );
}

/* ─── Form ─────────────────────────────────────────────────────────────── */

interface FormProps {
  category?: Category;
  missing: boolean;
  levels: Level[];
  total: number;
  onClose: () => void;
  onSaved: (category: Category, created: boolean) => void;
}

function CategoryForm({ category, missing, levels, total, onClose, onSaved }: FormProps) {
  const initial: CategoryInput = category
    ? {
        name: category.name,
        description: category.description,
        glyph: category.glyph,
        status: category.status,
        levelIds: category.levelIds,
        order: category.order,
      }
    : { name: '', description: '', glyph: 'sun', status: 'active', levelIds: [], order: total + 1 };
  const [form, setForm] = useState(initial);
  const [attempt, setAttempt] = useState(0);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [confirmDiscard, setConfirmDiscard] = useState(false);
  const dirty = JSON.stringify(form) !== JSON.stringify(initial);
  const maxOrder = category ? total : total + 1;

  const validate = (): FieldIssue[] => {
    const issues: FieldIssue[] = [];
    if (!form.name.trim()) issues.push({ field: 'category-name', message: 'Name the category.' });
    else if (form.name.trim().length > 40) issues.push({ field: 'category-name', message: 'Keep the name under 40 characters.' });
    if (!form.description.trim()) issues.push({ field: 'category-description', message: 'Add a short description learners will see.' });
    else if (form.description.length > 160) issues.push({ field: 'category-description', message: 'Keep the description under 160 characters.' });
    if (!form.levelIds.length) issues.push({ field: 'category-levels', message: 'Choose at least one level.' });
    if (!Number.isInteger(form.order) || form.order < 1 || form.order > maxOrder)
      issues.push({ field: 'category-order', message: `Display order must be between 1 and ${maxOrder}.` });
    return issues;
  };
  const issues = attempt ? validate() : [];
  const errorFor = (field: string) => issues.find((i) => i.field === field)?.message;
  const set = <K extends keyof CategoryInput>(key: K, value: CategoryInput[K]) => setForm((f) => ({ ...f, [key]: value }));

  const submit = async (e?: FormEvent) => {
    e?.preventDefault();
    setAttempt((a) => a + 1);
    setError(null);
    if (validate().length) return;
    setSaving(true);
    try {
      const saved = category ? await services.categories.update(category.id, form) : await services.categories.create(form);
      onSaved(saved, !category);
    } catch (err) {
      setError((err as Error).message);
      setSaving(false);
    }
  };

  const requestClose = () => (dirty && !saving ? setConfirmDiscard(true) : onClose());

  useEffect(() => {
    if (!dirty) return;
    const warn = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener('beforeunload', warn);
    return () => window.removeEventListener('beforeunload', warn);
  }, [dirty]);

  return (
    <>
      <AdaptivePanel
        open
        onClose={requestClose}
        eyebrow={category ? 'Edit category' : 'New category'}
        title={category ? category.name : 'Add a category'}
        width={520}
        footer={
          !missing && (
            <>
              <Button onClick={requestClose} disabled={saving}>
                Cancel
              </Button>
              <Button type="submit" form="category-form" variant="primary" loading={saving}>
                {category ? 'Save changes' : 'Add category'}
              </Button>
            </>
          )
        }
      >
        {missing ? (
          <StateMessage kind="error" title="Category not found" compact>
            It may have been deleted. Close this panel to return to the list.
          </StateMessage>
        ) : (
          <form id="category-form" className={styles.form} onSubmit={submit} noValidate>
            <ErrorSummary issues={issues} attempt={attempt} title="Fix these before saving" />
            {error && (
              <InlineMessage kind="error" title="Couldn’t save.">
                {error}
              </InlineMessage>
            )}
            <div className={styles.formPreview} aria-hidden="true">
              <CategoryGlyph glyph={form.glyph} size={56} />
              <span>
                <span className={styles.name}>{form.name.trim() || 'Category name'}</span>
                <span className={styles.description}>{form.description.trim() || 'A short description learners will see.'}</span>
              </span>
            </div>
            <Field label="Name" error={errorFor('category-name')} hint={`${form.name.trim().length}/40`}>
              <Input id="category-name" value={form.name} onChange={(e) => set('name', e.target.value)} placeholder="Rajasthan State Exams" autoFocus />
            </Field>
            <Field
              label="Short description"
              error={errorFor('category-description')}
              hint={`${form.description.length}/160 · Shown in the catalog under the name.`}
            >
              <Textarea
                id="category-description"
                rows={3}
                value={form.description}
                onChange={(e) => set('description', e.target.value)}
                placeholder="The 27 lunar mansions — their deities, symbols and use in timing."
              />
            </Field>
            <ChoiceCards<Glyph>
              legend="Emblem"
              columns={4}
              value={form.glyph}
              onChange={(v) => set('glyph', v)}
              choices={GLYPHS.map((g) => ({ value: g, label: glyphLabels[g], visual: <CategoryGlyph glyph={g} size={44} /> }))}
            />
            <fieldset id="category-levels" tabIndex={-1} className={styles.levels}>
              <legend className={styles.legend}>Levels</legend>
              <div className={styles.levelOptions}>
                {levels.map((l) => (
                  <Checkbox
                    key={l.id}
                    label={l.name}
                    checked={form.levelIds.includes(l.id)}
                    onChange={(e) => set('levelIds', e.target.checked ? [...form.levelIds, l.id] : form.levelIds.filter((x) => x !== l.id))}
                  />
                ))}
              </div>
              {errorFor('category-levels') && <p className={styles.fieldError}>{errorFor('category-levels')}</p>}
            </fieldset>
            <ChoiceCards<CategoryStatus>
              legend="Status"
              columns={2}
              value={form.status}
              onChange={(v) => set('status', v)}
              choices={(['active', 'hidden'] as const).map((s) => ({ value: s, label: STATUS_META[s].label, description: STATUS_META[s].description }))}
            />
            <Field
              label="Display order"
              error={errorFor('category-order')}
              hint={`Position 1 to ${maxOrder} in the catalog and filters. Others shift to make room.`}
            >
              <Input
                id="category-order"
                type="number"
                inputMode="numeric"
                min={1}
                max={maxOrder}
                value={form.order}
                onChange={(e) => set('order', Number(e.target.value))}
              />
            </Field>
          </form>
        )}
      </AdaptivePanel>
      <Modal
        open={confirmDiscard}
        onClose={() => setConfirmDiscard(false)}
        title="Discard your changes?"
        description={category ? `Edits to ${category.name} haven’t been saved.` : 'This category hasn’t been added yet.'}
        footer={
          <>
            <Button onClick={() => setConfirmDiscard(false)}>Keep editing</Button>
            <Button variant="danger" onClick={onClose}>
              Discard
            </Button>
          </>
        }
      />
    </>
  );
}

/* ─── Delete ───────────────────────────────────────────────────────────── */

function DeleteCategoryDialog({ row, onClose, onDeleted }: { row: CategoryRow; onClose: () => void; onDeleted: (moved: number) => void }) {
  const [destination, setDestination] = useState('');
  const hasCourses = row.courseCount > 0;
  // Every other category is a valid destination, whatever the list is currently filtered to.
  const all = useAsync(`categories-all:${row.category.id}`, () => services.catalog.listCategories());
  const options = (all.data ?? []).filter((c) => c.id !== row.category.id).sort((a, b) => a.order - b.order);
  return (
    <ConfirmDialog
      open
      onClose={onClose}
      onConfirm={async () => {
        const result = await services.categories.remove(row.category.id, hasCourses ? { moveCoursesTo: destination } : undefined);
        onDeleted(result.moved);
      }}
      tone="danger"
      icon={<Trash size={20} />}
      title={`Delete ${row.category.name}?`}
      description="This can’t be undone."
      confirmLabel={hasCourses ? `Move courses and delete` : 'Delete category'}
      blocked={hasCourses && !destination}
    >
      <ul className={styles.impact}>
        {hasCourses ? (
          <>
            <li>
              {plural(row.courseCount, 'course')} ({row.publishedCount} published, {formatCount(row.learnerCount)} learners) will move to the category you
              choose.
            </li>
            <li>Learners keep their enrollments and progress; only the course’s category changes.</li>
          </>
        ) : (
          <li>No courses use this category, so nothing else changes.</li>
        )}
        <li>Categories after it move up one place in the display order.</li>
      </ul>
      {hasCourses && (
        <Field label="Move its courses to">
          <Select value={destination} onChange={(e) => setDestination(e.target.value)}>
            <option value="">Choose a category</option>
            {options.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
                {c.status === 'hidden' ? ' (hidden)' : ''}
              </option>
            ))}
          </Select>
        </Field>
      )}
    </ConfirmDialog>
  );
}
