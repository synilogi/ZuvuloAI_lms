import { DotsThree, Plus } from '@phosphor-icons/react';
import { useState } from 'react';

import { DataTable, type SortState } from '@/components/data/DataTable';
import { FilterBar } from '@/components/data/FilterBar';
import { SearchInput } from '@/components/data/SearchInput';
import { Banner, InlineAlert } from '@/components/feedback/InlineAlert';
import { ChartSkeleton, KpiSkeleton, Spinner, TableSkeleton } from '@/components/feedback/Skeleton';
import { EmptyState, ErrorState, FilteredEmptyState, ForbiddenState, NotFoundState } from '@/components/feedback/states';
import { useToast } from '@/components/feedback/Toast';
import { PageHeader } from '@/components/layout/PageHeader';
import {
  Avatar,
  Badge,
  Button,
  Card,
  Checkbox,
  Checklist,
  Combobox,
  ConfirmDialog,
  DateInput,
  Dialog,
  Drawer,
  ErrorSummary,
  Field,
  FileDrop,
  IconButton,
  KeyValueList,
  KpiTile,
  Menu,
  Pagination,
  Popover,
  ProgressBar,
  ProgressRing,
  RadioGroup,
  SegmentedControl,
  Select,
  Switch,
  Tabs,
  TagInput,
  Textarea,
  TextInput,
  Timeline,
  Tooltip,
  type ComboboxOption,
} from '@/components/ui';

import styles from './Gallery.module.css';

/*
 * Development-only component gallery (REACT-001). It is loaded only when import.meta.env.DEV is true, so the
 * production bundle never contains it. The labels below are specimen text for showing states — not product data,
 * and nothing here is fetched or presented as real.
 */

interface SpecimenRow {
  id: string;
  name: string;
  state: string;
  count: number;
}

const SPECIMEN_ROWS: SpecimenRow[] = [
  { id: 'a', name: 'Specimen row A', state: 'Active', count: 3 },
  { id: 'b', name: 'Specimen row B', state: 'Draft', count: 0 },
];

const SPECIMEN_OPTIONS: ComboboxOption[] = [
  { value: 'one', label: 'Option one' },
  { value: 'two', label: 'Option two', description: 'With a description' },
];

export default function Gallery() {
  const toast = useToast();
  const [theme, setTheme] = useState<'system' | 'light' | 'dark'>('system');
  const [tab, setTab] = useState('one');
  const [dialog, setDialog] = useState(false);
  const [drawer, setDrawer] = useState(false);
  const [confirm, setConfirm] = useState(false);
  const [tags, setTags] = useState(['tag']);
  const [pick, setPick] = useState<ComboboxOption | null>(null);
  const [sort, setSort] = useState<SortState>({ key: 'name', direction: 'asc' });
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [view, setView] = useState<'grid' | 'list'>('grid');

  const applyTheme = (next: typeof theme) => {
    setTheme(next);
    if (next === 'system') document.documentElement.removeAttribute('data-theme');
    else document.documentElement.setAttribute('data-theme', next);
  };

  return (
    <main className={styles.page}>
      <PageHeader
        title="Component gallery"
        subtitle="Development only. Every shared component and state, in both themes."
        breadcrumbs={[{ label: 'Development' }, { label: 'Gallery' }]}
        primaryAction={
          <SegmentedControl
            label="Theme"
            value={theme}
            onChange={applyTheme}
            options={[
              { value: 'system', label: 'System' },
              { value: 'light', label: 'Light' },
              { value: 'dark', label: 'Dark' },
            ]}
          />
        }
      />

      <section className={styles.section} aria-labelledby="g-buttons">
        <h2 id="g-buttons">Buttons</h2>
        <div className={styles.row}>
          <Button variant="primary" icon={<Plus size={16} />}>
            Primary
          </Button>
          <Button>Secondary</Button>
          <Button variant="ghost">Ghost</Button>
          <Button variant="danger">Danger</Button>
          <Button loading>Loading</Button>
          <Button disabled>Disabled</Button>
          <Button size="sm">Small</Button>
          <IconButton label="More actions" icon={<DotsThree size={20} />} />
        </div>
      </section>

      <section className={styles.section} aria-labelledby="g-forms">
        <h2 id="g-forms">Forms</h2>
        <ErrorSummary errors={[{ fieldId: 'g-title', message: 'Enter a title.' }]} />
        <div className={styles.grid}>
          <Field label="Title" hint="A hint" error="Enter a title." required id="g-title">
            <TextInput />
          </Field>
          <Field label="Select">
            <Select placeholder="Choose one" options={[{ value: 'a', label: 'Choice A' }]} />
          </Field>
          <Field label="Date">
            <DateInput />
          </Field>
          <Field label="Combobox">
            <Combobox options={SPECIMEN_OPTIONS} value={pick} onChange={setPick} />
          </Field>
          <Field label="Tags">
            <TagInput value={tags} onChange={setTags} />
          </Field>
          <Field label="Textarea">
            <Textarea showCounter counterMax={120} />
          </Field>
        </div>
        <div className={styles.row}>
          <Checkbox label="Checkbox" description="With a description" />
          <Switch label="Switch" />
        </div>
        <RadioGroup
          legend="Radio group"
          name="g-radio"
          inline
          options={[
            { value: 'a', label: 'First' },
            { value: 'b', label: 'Second' },
          ]}
        />
        <FileDrop onFiles={(files) => toast.show({ title: `${files.length} file(s) chosen` })} hint="PDF up to 25 MB" accept=".pdf" />
      </section>

      <section className={styles.section} aria-labelledby="g-display">
        <h2 id="g-display">Display</h2>
        <div className={styles.row}>
          <Badge>Neutral</Badge>
          <Badge tone="success">Success</Badge>
          <Badge tone="info">Info</Badge>
          <Badge tone="warn">Warning</Badge>
          <Badge tone="danger">Danger</Badge>
          <Avatar name="Specimen Person" />
          <ProgressRing value={64} label="Specimen progress" />
        </div>
        <div className={styles.grid}>
          <Card title="Card" description="With a description" headingLevel={3}>
            <ProgressBar value={40} label="Progress" showLabel />
          </Card>
          <Card title="KPI" headingLevel={3}>
            <KpiTile label="Specimen figure" value="128" change={{ direction: 'up', label: '+12%', context: 'vs previous period' }} />
          </Card>
          <Card title="Key values" headingLevel={3}>
            <KeyValueList
              items={[
                { label: 'Label', value: 'Value' },
                { label: 'Empty', value: null },
              ]}
            />
          </Card>
          <Card title="Timeline & checklist" headingLevel={3}>
            <Timeline label="Specimen timeline" items={[{ id: '1', title: 'First event', meta: 'Specimen time' }]} />
            <Checklist
              label="Specimen checklist"
              items={[
                { id: 'a', label: 'Met', done: true },
                { id: 'b', label: 'Not met', done: false },
              ]}
            />
          </Card>
        </div>
      </section>

      <section className={styles.section} aria-labelledby="g-nav">
        <h2 id="g-nav">Navigation</h2>
        <Tabs
          label="Specimen tabs"
          value={tab}
          onValueChange={setTab}
          items={[
            { value: 'one', label: 'One', count: 2, content: <p>First panel</p> },
            { value: 'two', label: 'Two', content: <p>Second panel</p> },
          ]}
        />
        <div className={styles.toolbar}>
          <SegmentedControl
            label="View"
            value={view}
            onChange={setView}
            options={[
              { value: 'grid', label: 'Grid' },
              { value: 'list', label: 'List' },
            ]}
          />
          <Menu
            trigger={<Button>Menu</Button>}
            items={[{ label: 'Item', onSelect: () => {} }, { type: 'separator' }, { label: 'Danger item', onSelect: () => {}, danger: true }]}
          />
          <Popover label="Specimen popover" trigger={<Button>Popover</Button>}>
            Popover content
          </Popover>
          <Tooltip content="Tooltip text">
            <Button>Tooltip</Button>
          </Tooltip>
        </div>
      </section>

      <section className={styles.section} aria-labelledby="g-overlays">
        <h2 id="g-overlays">Overlays</h2>
        <div className={styles.row}>
          <Button onClick={() => setDialog(true)}>Dialog</Button>
          <Button onClick={() => setDrawer(true)}>Drawer</Button>
          <Button variant="danger" onClick={() => setConfirm(true)}>
            Confirm with reason
          </Button>
          <Button onClick={() => toast.show({ title: 'Saved', description: 'Specimen toast', action: { label: 'Undo', onClick: () => {} } })}>Toast</Button>
          <Button onClick={() => toast.show({ tone: 'danger', title: 'Specimen error' })}>Error toast</Button>
        </div>
        <Dialog
          open={dialog}
          onOpenChange={setDialog}
          title="Dialog"
          description="A bottom sheet under 640px."
          footer={<Button onClick={() => setDialog(false)}>Close</Button>}
        >
          <Field label="Inside the dialog">
            <TextInput />
          </Field>
        </Dialog>
        <Drawer open={drawer} onOpenChange={setDrawer} title="Drawer" footer={<Button onClick={() => setDrawer(false)}>Done</Button>}>
          Drawer content
        </Drawer>
        <ConfirmDialog
          open={confirm}
          onOpenChange={setConfirm}
          title="Confirm this?"
          description="States the consequence."
          confirmLabel="Do it"
          tone="danger"
          reason={{ label: 'Reason', minLength: 3 }}
          onConfirm={() => toast.show({ title: 'Confirmed' })}
        />
      </section>

      <section className={styles.section} aria-labelledby="g-data">
        <h2 id="g-data">Data</h2>
        <FilterBar
          search={<SearchInput value={search} onChange={setSearch} label="Search specimens" />}
          filters={
            <Field label="State">
              <Select options={[{ value: 'all', label: 'All' }]} />
            </Field>
          }
          activeCount={search ? 1 : 0}
          onClear={() => setSearch('')}
        />
        <DataTable
          rows={SPECIMEN_ROWS}
          caption="Specimen table"
          getRowId={(row) => row.id}
          sort={sort}
          onSortChange={setSort}
          columns={[
            { key: 'name', header: 'Name', cell: (row) => row.name, sortKey: 'name', card: 'title' },
            { key: 'state', header: 'State', cell: (row) => <Badge>{row.state}</Badge>, card: 'status' },
            { key: 'count', header: 'Count', cell: (row) => row.count, align: 'end', hideBelow: 'lg' },
          ]}
          rowActions={(row) => <IconButton label={`More actions for ${row.name}`} icon={<DotsThree size={20} />} />}
        />
        <Pagination page={page} pageSize={25} total={60} onPageChange={setPage} noun="specimens" />
      </section>

      <section className={styles.section} aria-labelledby="g-feedback">
        <h2 id="g-feedback">Feedback & states</h2>
        <Banner tone="warn" title="Banner">
          Academy-wide message.
        </Banner>
        <InlineAlert tone="info" title="Inline alert">
          Information.
        </InlineAlert>
        <div className={styles.grid}>
          <Card title="Table skeleton" headingLevel={3}>
            <TableSkeleton rows={3} />
          </Card>
          <Card title="KPI & chart skeleton" headingLevel={3}>
            <KpiSkeleton count={2} />
            <ChartSkeleton height={80} />
            <Spinner />
          </Card>
        </div>
        <div className={styles.grid}>
          <Card headingLevel={3} title="Empty">
            <EmptyState compact headingLevel={3} title="Nothing here yet" actions={<Button variant="primary">First action</Button>}>
              Explains the purpose.
            </EmptyState>
          </Card>
          <Card headingLevel={3} title="Filtered empty">
            <FilteredEmptyState compact query="“specimen”" onClear={() => {}} />
          </Card>
          <Card headingLevel={3} title="Error">
            <ErrorState compact onRetry={() => {}} />
          </Card>
          <Card headingLevel={3} title="Not found / forbidden">
            <NotFoundState />
            <ForbiddenState permissionLabel="View reports" />
          </Card>
        </div>
      </section>
    </main>
  );
}
