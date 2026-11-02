import { act, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';

import { Button } from '@/components/ui/Button';

import { Banner, InlineAlert } from './InlineAlert';
import { ChartSkeleton, DetailSkeleton, FormSkeleton, KpiSkeleton, Spinner, TableSkeleton } from './Skeleton';
import { EmptyState, ErrorState, FilteredEmptyState, ForbiddenState, NotFoundState } from './states';
import { ToastProvider, useToast } from './Toast';

describe('alerts', () => {
  it('announces danger and warnings, and states info politely', () => {
    render(
      <>
        <InlineAlert tone="danger" title="Payment overdue">
          Renew to keep adding courses.
        </InlineAlert>
        <Banner tone="info">Plans are not enforced yet.</Banner>
      </>,
    );
    expect(screen.getByRole('alert')).toHaveTextContent('Payment overdue');
    expect(screen.getByRole('status')).toHaveTextContent('Plans are not enforced yet.');
  });
});

describe('skeletons', () => {
  it('announce loading once and hide their shapes', () => {
    render(
      <>
        <TableSkeleton label="Loading courses" />
        <DetailSkeleton />
        <KpiSkeleton />
        <ChartSkeleton />
        <FormSkeleton />
        <Spinner label="Saving" />
      </>,
    );
    expect(screen.getByRole('status', { name: 'Saving' })).toBeInTheDocument();
    expect(screen.getByText('Loading courses')).toBeInTheDocument();
    expect(screen.getAllByRole('status', { busy: true })).toHaveLength(5);
  });
});

describe('states', () => {
  it('offers the first action in an empty state', () => {
    render(
      <EmptyState title="No plans yet" actions={<Button>Create plan</Button>}>
        Create your first subscription plan to start configuring platform offerings.
      </EmptyState>,
    );
    expect(screen.getByRole('heading', { name: 'No plans yet' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Create plan' })).toBeInTheDocument();
  });

  it('clears filters from a filtered-empty state', async () => {
    const onClear = vi.fn();
    render(<FilteredEmptyState query="“moon”" onClear={onClear} />);
    expect(screen.getByRole('heading')).toHaveTextContent('No results for “moon”');
    await userEvent.click(screen.getByRole('button', { name: 'Clear filters' }));
    expect(onClear).toHaveBeenCalled();
  });

  it('retries from an error state and shows human text', async () => {
    const onRetry = vi.fn();
    render(<ErrorState onRetry={onRetry} />);
    expect(screen.getByRole('alert')).toHaveTextContent('We could not load this');
    await userEvent.click(screen.getByRole('button', { name: 'Try again' }));
    expect(onRetry).toHaveBeenCalled();
  });

  it('names the missing permission and explains a not-found page', () => {
    render(
      <>
        <ForbiddenState permissionLabel="View reports" />
        <NotFoundState />
      </>,
    );
    expect(screen.getByText('View reports')).toBeInTheDocument();
    expect(screen.getByText(/may have been removed/)).toBeInTheDocument();
  });
});

describe('toasts', () => {
  function Trigger() {
    const toast = useToast();
    return (
      <>
        <Button onClick={() => toast.show({ title: 'Course archived', action: { label: 'Undo', onClick: undo } })}>Archive</Button>
        <Button onClick={() => toast.show({ tone: 'danger', title: 'Could not save', duration: 0 })}>Fail</Button>
      </>
    );
  }
  const undo = vi.fn();

  it('shows, runs its action and dismisses itself after its duration', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    render(
      <ToastProvider>
        <Trigger />
      </ToastProvider>,
    );
    await userEvent.click(screen.getByRole('button', { name: 'Archive' }));
    expect(screen.getByText('Course archived')).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Undo' }));
    expect(undo).toHaveBeenCalled();
    expect(screen.queryByText('Course archived')).not.toBeInTheDocument();

    await userEvent.click(screen.getByRole('button', { name: 'Archive' }));
    act(() => {
      vi.advanceTimersByTime(5100);
    });
    expect(screen.queryByText('Course archived')).not.toBeInTheDocument();
    vi.useRealTimers();
  });

  it('keeps a sticky error until dismissed', async () => {
    render(
      <ToastProvider>
        <Trigger />
      </ToastProvider>,
    );
    await userEvent.click(screen.getByRole('button', { name: 'Fail' }));
    expect(screen.getByRole('alert')).toHaveTextContent('Could not save');
    await userEvent.click(screen.getByRole('button', { name: 'Dismiss notification' }));
    expect(screen.queryByText('Could not save')).not.toBeInTheDocument();
  });

  it('requires the provider', () => {
    const Orphan = () => {
      useToast();
      return null;
    };
    vi.spyOn(console, 'error').mockImplementation(() => {});
    expect(() => render(<Orphan />)).toThrow(/ToastProvider/);
  });
});
