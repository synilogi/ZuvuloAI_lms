import { act, render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useState } from 'react';
import { describe, expect, it, vi } from 'vitest';

import { setViewportWidth } from '@/test/viewport';

import { DataTable, type Column, type SortState } from './DataTable';
import { FilterBar } from './FilterBar';
import { SearchInput } from './SearchInput';

interface Row {
  id: string;
  title: string;
  status: string;
  learners: number;
}

const rows: Row[] = [
  { id: 'c1', title: 'Vedic Foundations', status: 'Published', learners: 42 },
  { id: 'c2', title: 'Reading Dashas', status: 'Draft', learners: 0 },
];

const columns: Column<Row>[] = [
  { key: 'title', header: 'Course', cell: (row) => row.title, sortKey: 'title', card: 'title' },
  { key: 'status', header: 'Status', cell: (row) => row.status, card: 'status' },
  { key: 'learners', header: 'Learners', cell: (row) => row.learners, sortKey: 'enrolled', align: 'end', hideBelow: 'lg' },
];

function Table(props: { onSort?: (sort: SortState) => void; selectable?: boolean }) {
  const [sort, setSort] = useState<SortState>({ key: 'title', direction: 'asc' });
  const [selected, setSelected] = useState<string[]>([]);
  return (
    <DataTable
      rows={rows}
      columns={columns}
      getRowId={(row) => row.id}
      caption="Courses"
      sort={sort}
      onSortChange={(next) => {
        setSort(next);
        props.onSort?.(next);
      }}
      rowActions={(row) => <button type="button">Actions for {row.title}</button>}
      selection={props.selectable ? { selectedIds: selected, onChange: setSelected, rowLabel: (row) => `Select ${row.title}` } : undefined}
    />
  );
}

describe('DataTable', () => {
  it('renders a captioned table on wide screens with sortable headers', async () => {
    const onSort = vi.fn();
    render(<Table onSort={onSort} />);
    const table = screen.getByRole('table', { name: 'Courses' });
    expect(within(table).getAllByRole('row')).toHaveLength(3);
    expect(screen.getByRole('columnheader', { name: /Course/ })).toHaveAttribute('aria-sort', 'ascending');
    await userEvent.click(screen.getByRole('button', { name: /Course/ }));
    expect(onSort).toHaveBeenLastCalledWith({ key: 'title', direction: 'desc' });
    await userEvent.click(screen.getByRole('button', { name: /Learners/ }));
    expect(onSort).toHaveBeenLastCalledWith({ key: 'enrolled', direction: 'asc' });
    expect(screen.getByRole('button', { name: 'Actions for Reading Dashas' })).toBeInTheDocument();
  });

  it('turns rows into cards below 640px from the same columns', () => {
    render(<Table />);
    act(() => setViewportWidth(360));
    expect(screen.queryByRole('table')).not.toBeInTheDocument();
    const list = screen.getByRole('list', { name: 'Courses' });
    const cards = within(list).getAllByRole('listitem');
    expect(cards).toHaveLength(2);
    expect(cards[0]).toHaveTextContent('Vedic Foundations');
    expect(within(cards[0]!).getByText('Learners')).toBeInTheDocument();
    expect(within(cards[0]!).getByText('42')).toBeInTheDocument();
  });

  it('selects rows individually and by page', async () => {
    render(<Table selectable />);
    const all = screen.getByRole('checkbox', { name: 'Select all rows on this page' });
    await userEvent.click(screen.getByRole('checkbox', { name: 'Select Vedic Foundations' }));
    expect((all as HTMLInputElement).indeterminate).toBe(true);
    await userEvent.click(all);
    expect(screen.getByRole('checkbox', { name: 'Select Reading Dashas' })).toBeChecked();
    await userEvent.click(all);
    expect(screen.getByRole('checkbox', { name: 'Select Vedic Foundations' })).not.toBeChecked();
  });
});

describe('SearchInput', () => {
  it('applies after a pause, at once on Enter, and clears on Escape', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    const onChange = vi.fn();
    render(<SearchInput value="" onChange={onChange} label="Search courses" />);
    const input = screen.getByRole('searchbox', { name: 'Search courses' });
    await userEvent.type(input, 'moon');
    expect(onChange).not.toHaveBeenCalledWith('moon');
    act(() => {
      vi.advanceTimersByTime(320);
    });
    expect(onChange).toHaveBeenLastCalledWith('moon');

    await userEvent.type(input, ' sign{Enter}');
    expect(onChange).toHaveBeenLastCalledWith('moon sign');
    await userEvent.keyboard('{Escape}');
    expect(onChange).toHaveBeenLastCalledWith('');
    expect(input).toHaveValue('');
    vi.useRealTimers();
  });
});

describe('FilterBar', () => {
  const filters = (
    <label>
      Status
      <select>
        <option>All</option>
      </select>
    </label>
  );

  it('shows filters inline on wide screens with a clear action', async () => {
    const onClear = vi.fn();
    render(<FilterBar filters={filters} activeCount={1} onClear={onClear} />);
    expect(screen.getByRole('combobox', { name: 'Status' })).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Clear filters' }));
    expect(onClear).toHaveBeenCalled();
  });

  it('moves filters into a bottom sheet on phones', async () => {
    render(<FilterBar filters={filters} activeCount={2} onClear={() => {}} />);
    act(() => setViewportWidth(360));
    expect(screen.queryByRole('combobox', { name: 'Status' })).not.toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Filters (2)' }));
    const sheet = await screen.findByRole('dialog', { name: 'Filters' });
    expect(within(sheet).getByRole('combobox', { name: 'Status' })).toBeInTheDocument();
    await userEvent.click(within(sheet).getByRole('button', { name: 'Show results' }));
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });
});
