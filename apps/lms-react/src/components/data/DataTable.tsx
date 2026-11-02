import { CaretDown, CaretUp, CaretUpDown } from '@phosphor-icons/react';
import type { ReactNode } from 'react';

import { cx } from '@/lib/cx';
import { useBreakpoint } from '@/lib/useMediaQuery';

import styles from './Data.module.css';

export type SortDirection = 'asc' | 'desc';

export interface SortState {
  key: string;
  direction: SortDirection;
}

export interface Column<T> {
  key: string;
  header: ReactNode;
  cell: (row: T) => ReactNode;
  /** Makes the header a sort button. The value is sent to the API as the sort key. */
  sortKey?: string;
  align?: 'start' | 'end';
  width?: string;
  /** Hide in the table under this breakpoint (tablet condensed view). */
  hideBelow?: 'lg' | 'xl';
  /**
   * Its role in the mobile card: `title` (one column, usually a link to the detail page), `status` (top right),
   * `field` (a labelled row — the default) or `hidden`.
   */
  card?: 'title' | 'status' | 'field' | 'hidden';
  /** Label for the card field when `header` is not plain text. */
  cardLabel?: string;
}

export interface DataTableProps<T> {
  rows: T[];
  columns: Column<T>[];
  getRowId: (row: T) => string;
  /** Accessible name of the table (visually hidden caption). */
  caption: string;
  sort?: SortState;
  onSortChange?: (sort: SortState) => void;
  /** Per-row actions (usually a Menu). Rendered in the last column / the card footer. */
  rowActions?: (row: T) => ReactNode;
  /** Label each row's selection checkbox; enables selection. */
  selection?: {
    selectedIds: string[];
    onChange: (ids: string[]) => void;
    rowLabel: (row: T) => string;
  };
  /** Shows a thin progress bar while a new page or filter loads over the current rows. */
  refreshing?: boolean;
}

function SortIcon({ active, direction }: { active: boolean; direction?: SortDirection }) {
  if (!active) return <CaretUpDown size={12} aria-hidden="true" />;
  return direction === 'asc' ? <CaretUp size={12} aria-hidden="true" /> : <CaretDown size={12} aria-hidden="true" />;
}

/**
 * Server-driven table. Sorting and paging are the API's job: the table only reports what the user asked for.
 * Loading, empty and error states are rendered by the page around it, from the query state.
 */
export function DataTable<T>({ rows, columns, getRowId, caption, sort, onSortChange, rowActions, selection, refreshing = false }: DataTableProps<T>) {
  const wide = useBreakpoint('sm');

  const toggleAll = () => {
    if (!selection) return;
    const ids = rows.map(getRowId);
    const allSelected = ids.every((id) => selection.selectedIds.includes(id));
    selection.onChange(allSelected ? selection.selectedIds.filter((id) => !ids.includes(id)) : Array.from(new Set([...selection.selectedIds, ...ids])));
  };

  const toggle = (id: string) => {
    if (!selection) return;
    selection.onChange(selection.selectedIds.includes(id) ? selection.selectedIds.filter((x) => x !== id) : [...selection.selectedIds, id]);
  };

  const indicator = refreshing ? <div className={styles.refreshing} role="progressbar" aria-label="Updating results" /> : null;

  if (!wide) {
    const title = columns.find((column) => column.card === 'title') ?? columns[0];
    const status = columns.find((column) => column.card === 'status');
    const fields = columns.filter((column) => column !== title && column !== status && column.card !== 'hidden');
    return (
      <div className={styles.wrap}>
        {indicator}
        <ul className={styles.cards} aria-label={caption}>
          {rows.map((row) => {
            const id = getRowId(row);
            return (
              <li key={id} className={cx(styles.card, selection?.selectedIds.includes(id) && styles.selected)}>
                <div className={styles.cardTop}>
                  {selection && (
                    <input type="checkbox" aria-label={selection.rowLabel(row)} checked={selection.selectedIds.includes(id)} onChange={() => toggle(id)} />
                  )}
                  <div className={styles.cardTitle}>{title?.cell(row)}</div>
                  {status?.cell(row)}
                </div>
                {fields.length > 0 && (
                  <dl className={styles.cardFields}>
                    {fields.map((column) => (
                      <div key={column.key} style={{ display: 'contents' }}>
                        <dt>{column.cardLabel ?? column.header}</dt>
                        <dd>{column.cell(row)}</dd>
                      </div>
                    ))}
                  </dl>
                )}
                {rowActions && <div>{rowActions(row)}</div>}
              </li>
            );
          })}
        </ul>
      </div>
    );
  }

  const pageIds = rows.map(getRowId);
  const allChecked = selection !== undefined && pageIds.length > 0 && pageIds.every((id) => selection.selectedIds.includes(id));
  const someChecked = selection !== undefined && pageIds.some((id) => selection.selectedIds.includes(id));

  return (
    <div className={styles.wrap}>
      {indicator}
      <div className={styles.scroller}>
        <table className={styles.table}>
          <caption className="visually-hidden">{caption}</caption>
          <thead>
            <tr>
              {selection && (
                <th scope="col" className={styles.checkCell}>
                  <input
                    type="checkbox"
                    aria-label="Select all rows on this page"
                    checked={allChecked}
                    ref={(element) => {
                      if (element) element.indeterminate = someChecked && !allChecked;
                    }}
                    onChange={toggleAll}
                  />
                </th>
              )}
              {columns.map((column) => {
                const active = sort?.key === column.sortKey;
                return (
                  <th
                    key={column.key}
                    scope="col"
                    style={{ width: column.width }}
                    className={cx(
                      column.align === 'end' && styles.end,
                      column.hideBelow === 'lg' && styles.hideBelowLg,
                      column.hideBelow === 'xl' && styles.hideBelowXl,
                    )}
                    aria-sort={column.sortKey && active ? (sort!.direction === 'asc' ? 'ascending' : 'descending') : undefined}
                  >
                    {column.sortKey && onSortChange ? (
                      <button
                        type="button"
                        className={styles.sortButton}
                        onClick={() => onSortChange({ key: column.sortKey!, direction: active && sort!.direction === 'asc' ? 'desc' : 'asc' })}
                      >
                        {column.header}
                        <SortIcon active={active} direction={sort?.direction} />
                      </button>
                    ) : (
                      column.header
                    )}
                  </th>
                );
              })}
              {rowActions && (
                <th scope="col" className={styles.actionsCell}>
                  <span className="visually-hidden">Actions</span>
                </th>
              )}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => {
              const id = getRowId(row);
              const checked = selection?.selectedIds.includes(id) ?? false;
              return (
                <tr key={id} className={cx(checked && styles.selected)}>
                  {selection && (
                    <td className={styles.checkCell}>
                      <input type="checkbox" aria-label={selection.rowLabel(row)} checked={checked} onChange={() => toggle(id)} />
                    </td>
                  )}
                  {columns.map((column) => (
                    <td
                      key={column.key}
                      className={cx(
                        column.align === 'end' && styles.end,
                        column.hideBelow === 'lg' && styles.hideBelowLg,
                        column.hideBelow === 'xl' && styles.hideBelowXl,
                      )}
                    >
                      {column.cell(row)}
                    </td>
                  ))}
                  {rowActions && <td className={styles.actionsCell}>{rowActions(row)}</td>}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
