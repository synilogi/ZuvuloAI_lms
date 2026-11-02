import { useState, type ReactNode } from 'react';
import { CaretDown, CaretUp, CaretUpDown } from '@phosphor-icons/react';
import { cx } from '@/lib/cx';
import { Checkbox } from '../Checkbox/Checkbox';
import { Skeleton } from '../Feedback/Feedback';
import styles from './DataTable.module.css';

export interface Column<T> {
  key: string;
  header: string;
  render: (row: T) => ReactNode;
  sortable?: boolean;
  align?: 'start' | 'end';
  width?: string;
  /**
   * How the column recomposes in narrow containers:
   * primary — the item's heading · status — top-right · meta — the line under the heading
   * detail — inside the expandable row · hidden — omitted
   */
  mobile: 'primary' | 'status' | 'meta' | 'detail' | 'hidden';
  /** Omit from the wide table — for a combined summary that only the narrow list needs. */
  listOnly?: boolean;
}

export interface SortState {
  key: string;
  direction: 'asc' | 'desc';
}

interface DataTableProps<T> {
  rows: T[];
  columns: Column<T>[];
  rowKey: (row: T) => string;
  label: string;
  rowLabel: (row: T) => string;
  selectable?: boolean;
  selected?: Set<string>;
  onSelectedChange?: (next: Set<string>) => void;
  sort?: SortState;
  onSortChange?: (next: SortState) => void;
  loading?: boolean;
  empty?: ReactNode;
  skeletonRows?: number;
  /** Draws the table in its own card — for pages that place it straight on the canvas. */
  framed?: boolean;
}

/**
 * Dense data table for management views. A real <table> in wide containers; below 640px
 * each row recomposes into a structured list item with an explicit disclosure for detail
 * columns — nothing is hover-only.
 */
export function DataTable<T>({
  rows,
  columns,
  rowKey,
  label,
  rowLabel,
  selectable,
  selected = new Set(),
  onSelectedChange,
  sort,
  onSortChange,
  loading,
  empty,
  skeletonRows = 5,
  framed,
}: DataTableProps<T>) {
  const [expanded, setExpanded] = useState<Set<string>>(new Set());
  const keys = rows.map(rowKey);
  const allSelected = keys.length > 0 && keys.every((k) => selected.has(k));
  const someSelected = keys.some((k) => selected.has(k));

  const toggleAll = () => onSelectedChange?.(allSelected ? new Set([...selected].filter((k) => !keys.includes(k))) : new Set([...selected, ...keys]));
  const toggle = (key: string) => {
    const next = new Set(selected);
    if (next.has(key)) next.delete(key);
    else next.add(key);
    onSelectedChange?.(next);
  };
  const toggleExpanded = (key: string) =>
    setExpanded((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });

  const sortBy = (key: string) => onSortChange?.({ key, direction: sort?.key === key && sort.direction === 'asc' ? 'desc' : 'asc' });

  const tableColumns = columns.filter((c) => !c.listOnly);
  const primary = columns.find((c) => c.mobile === 'primary');
  const status = columns.filter((c) => c.mobile === 'status');
  const meta = columns.filter((c) => c.mobile === 'meta');
  const detail = columns.filter((c) => c.mobile === 'detail');

  return (
    <div className={cx(styles.root, framed && styles.framed)} aria-busy={loading || undefined}>
      {/* Wide: table */}
      <div className={styles.tableWrap}>
        <table className={styles.table} aria-label={label}>
          <thead>
            <tr>
              {selectable && (
                <th scope="col" className={styles.checkCol}>
                  <Checkbox label="Select all on this page" hideLabel checked={allSelected} indeterminate={!allSelected && someSelected} onChange={toggleAll} />
                </th>
              )}
              {tableColumns.map((col) => (
                <th
                  key={col.key}
                  scope="col"
                  style={{ width: col.width }}
                  className={cx(col.align === 'end' && styles.end)}
                  aria-sort={sort?.key === col.key ? (sort.direction === 'asc' ? 'ascending' : 'descending') : undefined}
                >
                  {col.sortable ? (
                    <button type="button" className={styles.sortButton} onClick={() => sortBy(col.key)}>
                      {col.header}
                      {sort?.key === col.key ? (
                        sort.direction === 'asc' ? (
                          <CaretUp size={12} weight="bold" />
                        ) : (
                          <CaretDown size={12} weight="bold" />
                        )
                      ) : (
                        <CaretUpDown size={12} />
                      )}
                    </button>
                  ) : (
                    col.header
                  )}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {loading
              ? Array.from({ length: skeletonRows }, (_, i) => (
                  <tr key={`s${i}`}>
                    {selectable && <td className={styles.checkCol} />}
                    {tableColumns.map((col) => (
                      <td key={col.key}>
                        <Skeleton width={col.mobile === 'primary' ? '70%' : '50%'} height={10} />
                      </td>
                    ))}
                  </tr>
                ))
              : rows.map((row) => {
                  const key = rowKey(row);
                  return (
                    <tr key={key} className={cx(selected.has(key) && styles.selectedRow)}>
                      {selectable && (
                        <td className={styles.checkCol}>
                          <Checkbox label={`Select ${rowLabel(row)}`} hideLabel checked={selected.has(key)} onChange={() => toggle(key)} />
                        </td>
                      )}
                      {tableColumns.map((col) => (
                        <td key={col.key} className={cx(col.align === 'end' && styles.end)}>
                          {col.render(row)}
                        </td>
                      ))}
                    </tr>
                  );
                })}
          </tbody>
        </table>
      </div>

      {/* Narrow: structured list */}
      <ul className={styles.list} aria-label={label}>
        {loading
          ? Array.from({ length: 3 }, (_, i) => (
              <li key={`s${i}`} className={styles.item}>
                <div className={styles.itemBody}>
                  <Skeleton width="60%" height={12} />
                  <Skeleton width="85%" height={8} />
                </div>
              </li>
            ))
          : rows.map((row) => {
              const key = rowKey(row);
              const open = expanded.has(key);
              return (
                <li key={key} className={cx(styles.item, selected.has(key) && styles.selectedRow)}>
                  {selectable && (
                    <Checkbox
                      label={`Select ${rowLabel(row)}`}
                      hideLabel
                      checked={selected.has(key)}
                      onChange={() => toggle(key)}
                      className={styles.itemCheck}
                    />
                  )}
                  <div className={styles.itemBody}>
                    <div className={styles.itemHead}>
                      <div className={styles.itemPrimary}>{primary?.render(row)}</div>
                      {status.map((c) => (
                        <div key={c.key}>{c.render(row)}</div>
                      ))}
                    </div>
                    {meta.map((c) => (
                      <div key={c.key} className={styles.itemMeta}>
                        {c.render(row)}
                      </div>
                    ))}
                    {detail.length > 0 && (
                      <>
                        <button
                          type="button"
                          className={styles.itemToggle}
                          aria-expanded={open}
                          aria-label={`${open ? 'Hide details' : 'Details'} for ${rowLabel(row)}`}
                          onClick={() => toggleExpanded(key)}
                        >
                          {open ? 'Hide details' : 'Details'} <CaretDown size={12} className={cx(styles.itemCaret, open && styles.itemCaretOpen)} />
                        </button>
                        {open && (
                          <dl className={styles.itemDetail}>
                            {detail.map((c) => (
                              <div key={c.key}>
                                <dt>{c.header}</dt>
                                <dd>{c.render(row)}</dd>
                              </div>
                            ))}
                          </dl>
                        )}
                      </>
                    )}
                  </div>
                </li>
              );
            })}
      </ul>

      {!loading && rows.length === 0 && <div className={styles.empty}>{empty}</div>}
    </div>
  );
}
