import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, expect, it, vi } from 'vitest';

import { Button, IconButton, LinkButton } from './Button';

describe('Button', () => {
  it('activates with Enter and Space, and defaults to type="button"', async () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Save course</Button>);
    const button = screen.getByRole('button', { name: 'Save course' });
    expect(button).toHaveAttribute('type', 'button');
    button.focus();
    await userEvent.keyboard('{Enter}');
    await userEvent.keyboard(' ');
    expect(onClick).toHaveBeenCalledTimes(2);
  });

  it('is busy and disabled while loading', async () => {
    const onClick = vi.fn();
    render(
      <Button loading onClick={onClick}>
        Publishing
      </Button>,
    );
    const button = screen.getByRole('button', { name: 'Publishing' });
    expect(button).toBeDisabled();
    expect(button).toHaveAttribute('aria-busy', 'true');
    await userEvent.click(button);
    expect(onClick).not.toHaveBeenCalled();
  });

  it('does not act when disabled', async () => {
    const onClick = vi.fn();
    render(
      <Button disabled onClick={onClick}>
        Archive
      </Button>,
    );
    await userEvent.click(screen.getByRole('button', { name: 'Archive' }));
    expect(onClick).not.toHaveBeenCalled();
  });
});

describe('IconButton', () => {
  it('is named by its label', () => {
    render(<IconButton label="More actions for Vedic Foundations" icon={<svg />} />);
    expect(screen.getByRole('button', { name: 'More actions for Vedic Foundations' })).toBeInTheDocument();
  });
});

describe('LinkButton', () => {
  it('navigates like a link', async () => {
    render(
      <MemoryRouter initialEntries={['/']}>
        <Routes>
          <Route path="/" element={<LinkButton to="/admin/courses/new">Add course</LinkButton>} />
          <Route path="/admin/courses/new" element={<p>New course page</p>} />
        </Routes>
      </MemoryRouter>,
    );
    await userEvent.click(screen.getByRole('link', { name: 'Add course' }));
    expect(screen.getByText('New course page')).toBeInTheDocument();
  });
});
