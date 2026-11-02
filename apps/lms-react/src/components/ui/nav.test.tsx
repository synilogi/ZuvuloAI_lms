import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useState } from 'react';
import { MemoryRouter } from 'react-router-dom';
import { describe, expect, it, vi } from 'vitest';

import { Breadcrumbs } from './Breadcrumbs';
import { IconButton } from './Button';
import { Menu } from './Menu';
import { Pagination } from './Pagination';
import { SegmentedControl } from './SegmentedControl';
import { Tabs } from './Tabs';

describe('Tabs', () => {
  function Harness() {
    const [tab, setTab] = useState('overview');
    return (
      <Tabs
        label="Instructor sections"
        value={tab}
        onValueChange={setTab}
        items={[
          { value: 'overview', label: 'Overview', content: <p>Overview panel</p> },
          { value: 'courses', label: 'Courses', count: 3, content: <p>Courses panel</p> },
        ]}
      />
    );
  }

  it('moves between tabs with arrow keys', async () => {
    render(<Harness />);
    const overview = screen.getByRole('tab', { name: 'Overview' });
    await userEvent.click(overview);
    await userEvent.keyboard('{ArrowRight}');
    const courses = screen.getByRole('tab', { name: 'Courses 3' });
    expect(courses).toHaveFocus();
    expect(courses).toHaveAttribute('aria-selected', 'true');
    expect(screen.getByRole('tabpanel')).toHaveTextContent('Courses panel');
  });
});

describe('SegmentedControl', () => {
  it('is a radio group that follows arrow keys', async () => {
    const onChange = vi.fn();
    render(
      <SegmentedControl
        label="View"
        value="grid"
        onChange={onChange}
        options={[
          { value: 'grid', label: 'Grid' },
          { value: 'list', label: 'List' },
        ]}
      />,
    );
    const grid = screen.getByRole('radio', { name: 'Grid' });
    expect(grid).toHaveAttribute('aria-checked', 'true');
    expect(screen.getByRole('radio', { name: 'List' })).toHaveAttribute('tabindex', '-1');
    grid.focus();
    await userEvent.keyboard('{ArrowRight}');
    expect(onChange).toHaveBeenCalledWith('list');
  });
});

describe('Breadcrumbs', () => {
  it('links ancestors and marks the current page', () => {
    render(
      <MemoryRouter>
        <Breadcrumbs items={[{ label: 'Courses', to: '/admin/courses' }, { label: 'Vedic Foundations' }]} />
      </MemoryRouter>,
    );
    expect(screen.getByRole('navigation', { name: 'Breadcrumb' })).toBeInTheDocument();
    expect(screen.getByRole('link', { name: 'Courses' })).toHaveAttribute('href', '/admin/courses');
    expect(screen.getByText('Vedic Foundations')).toHaveAttribute('aria-current', 'page');
  });
});

describe('Pagination', () => {
  it('describes the range and disables moves past either end', async () => {
    const onPageChange = vi.fn();
    const onPageSizeChange = vi.fn();
    render(<Pagination page={1} pageSize={25} total={60} noun="courses" onPageChange={onPageChange} onPageSizeChange={onPageSizeChange} />);
    expect(screen.getByText('1–25 of 60 courses')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Previous page' })).toBeDisabled();
    await userEvent.click(screen.getByRole('button', { name: 'Next page' }));
    expect(onPageChange).toHaveBeenCalledWith(2);
    await userEvent.selectOptions(screen.getByLabelText('Rows per page'), '50');
    expect(onPageSizeChange).toHaveBeenCalledWith(50);
  });

  it('handles an empty result', () => {
    render(<Pagination page={1} pageSize={25} total={0} onPageChange={() => {}} />);
    expect(screen.getByText('0–0 of 0 results')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Next page' })).toBeDisabled();
  });
});

describe('Menu', () => {
  it('opens from the keyboard, selects an item and returns focus on Escape', async () => {
    const onEdit = vi.fn();
    render(
      <Menu
        trigger={<IconButton label="More actions for Vedic Foundations" icon={<svg />} />}
        items={[{ label: 'Edit', onSelect: onEdit }, { type: 'separator' }, { label: 'Archive', onSelect: () => {}, danger: true, disabled: true }]}
      />,
    );
    const trigger = screen.getByRole('button', { name: 'More actions for Vedic Foundations' });
    trigger.focus();
    await userEvent.keyboard('{Enter}');
    expect(await screen.findByRole('menu')).toBeInTheDocument();
    expect(screen.getByRole('menuitem', { name: 'Archive' })).toHaveAttribute('aria-disabled', 'true');
    await userEvent.keyboard('{Escape}');
    expect(screen.queryByRole('menu')).not.toBeInTheDocument();
    expect(trigger).toHaveFocus();

    await userEvent.keyboard('{Enter}');
    await userEvent.click(await screen.findByRole('menuitem', { name: 'Edit' }));
    expect(onEdit).toHaveBeenCalledTimes(1);
  });
});
