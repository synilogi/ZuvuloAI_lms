import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useState } from 'react';
import { describe, expect, it, vi } from 'vitest';

import { Button } from './Button';
import { ConfirmDialog, type ConfirmDialogProps } from './ConfirmDialog';
import { Dialog, Drawer } from './Dialog';
import { Popover, Tooltip, TooltipProvider } from './Popover';

function DialogHarness({ dismissible = true }: { dismissible?: boolean }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <Button onClick={() => setOpen(true)}>Open dialog</Button>
      <Dialog
        open={open}
        onOpenChange={setOpen}
        title="Change plan"
        description="Pick the new plan."
        dismissible={dismissible}
        footer={<Button variant="primary">Confirm</Button>}
      >
        <input aria-label="Plan" />
      </Dialog>
    </>
  );
}

describe('Dialog', () => {
  it('is named, traps focus, closes on Escape and restores focus', async () => {
    render(<DialogHarness />);
    const opener = screen.getByRole('button', { name: 'Open dialog' });
    await userEvent.click(opener);
    const dialog = await screen.findByRole('dialog', { name: 'Change plan' });
    expect(dialog).toHaveAccessibleDescription('Pick the new plan.');
    expect(dialog).toContainElement(document.activeElement as HTMLElement);
    for (let i = 0; i < 5; i += 1) {
      await userEvent.tab();
      expect(dialog).toContainElement(document.activeElement as HTMLElement);
    }
    await userEvent.keyboard('{Escape}');
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
    await waitFor(() => expect(opener).toHaveFocus());
  });

  it('ignores Escape while not dismissible', async () => {
    render(<DialogHarness dismissible={false} />);
    await userEvent.click(screen.getByRole('button', { name: 'Open dialog' }));
    await userEvent.keyboard('{Escape}');
    expect(screen.getByRole('dialog', { name: 'Change plan' })).toBeInTheDocument();
  });
});

describe('Drawer', () => {
  it('opens as a named dialog, closes with its close button and restores focus', async () => {
    function Harness() {
      const [open, setOpen] = useState(false);
      return (
        <>
          <Button onClick={() => setOpen(true)}>Edit category</Button>
          <Drawer open={open} onOpenChange={setOpen} title="Edit category">
            <input aria-label="Name" />
          </Drawer>
        </>
      );
    }
    render(<Harness />);
    const opener = screen.getByRole('button', { name: 'Edit category' });
    await userEvent.click(opener);
    const drawer = await screen.findByRole('dialog', { name: 'Edit category' });
    await userEvent.tab();
    await userEvent.tab();
    expect(drawer).toContainElement(document.activeElement as HTMLElement);
    await userEvent.click(screen.getByRole('button', { name: 'Close' }));
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
    await waitFor(() => expect(opener).toHaveFocus());
  });
});

describe('ConfirmDialog', () => {
  function Harness(props: Partial<ConfirmDialogProps>) {
    const [open, setOpen] = useState(true);
    return (
      <ConfirmDialog
        open={open}
        onOpenChange={setOpen}
        title="Revoke this certificate?"
        description="The learner is told, and verification will show it as revoked."
        confirmLabel="Revoke certificate"
        tone="danger"
        onConfirm={() => {}}
        {...props}
      />
    );
  }

  it('requires a reason of the minimum length before confirming', async () => {
    const onConfirm = vi.fn();
    render(<Harness reason={{ label: 'Reason', minLength: 3 }} onConfirm={onConfirm} />);
    await userEvent.click(screen.getByRole('button', { name: 'Revoke certificate' }));
    expect(onConfirm).not.toHaveBeenCalled();
    expect(screen.getByText('Enter at least 3 characters.')).toBeInTheDocument();
    await userEvent.type(screen.getByRole('textbox', { name: /Reason/ }), 'Issued in error');
    await userEvent.click(screen.getByRole('button', { name: 'Revoke certificate' }));
    expect(onConfirm).toHaveBeenCalledWith('Issued in error');
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  });

  it('stays open and shows the message when the action fails', async () => {
    render(<Harness onConfirm={() => Promise.reject(new Error('This certificate was already revoked.'))} />);
    await userEvent.click(screen.getByRole('button', { name: 'Revoke certificate' }));
    expect(await screen.findByText('This certificate was already revoked.')).toBeInTheDocument();
    expect(screen.getByRole('dialog')).toBeInTheDocument();
  });

  it('cancels without acting', async () => {
    const onConfirm = vi.fn();
    render(<Harness onConfirm={onConfirm} />);
    await userEvent.click(screen.getByRole('button', { name: 'Cancel' }));
    expect(onConfirm).not.toHaveBeenCalled();
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
  });
});

describe('Popover and Tooltip', () => {
  it('opens a popover and closes it with Escape, returning focus', async () => {
    render(
      <Popover label="Recent notifications" trigger={<Button>Notifications</Button>}>
        <p>Nothing new</p>
      </Popover>,
    );
    const trigger = screen.getByRole('button', { name: 'Notifications' });
    await userEvent.click(trigger);
    expect(await screen.findByRole('dialog', { name: 'Recent notifications' })).toHaveTextContent('Nothing new');
    await userEvent.keyboard('{Escape}');
    await waitFor(() => expect(screen.queryByRole('dialog')).not.toBeInTheDocument());
    expect(trigger).toHaveFocus();
  });

  it('shows a tooltip on keyboard focus', async () => {
    render(
      <TooltipProvider>
        <Tooltip content="Not included in your plan">
          <Button>Publish</Button>
        </Tooltip>
      </TooltipProvider>,
    );
    await userEvent.tab();
    expect(await screen.findByRole('tooltip')).toHaveTextContent('Not included in your plan');
  });
});
