import { describe, expect, it, vi } from 'vitest';
import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { EditorForm } from '@/features/announcements/components/editor-form';
import { renderWithProviders } from '../helpers';

describe('EditorForm', () => {
  it('keeps primary disabled until title + body are filled', async () => {
    const onSubmit = vi.fn();
    renderWithProviders(
      <EditorForm
        mode="create"
        primaryLabel="Save"
        onSubmit={onSubmit}
      />,
    );
    const submit = screen.getByRole('button', { name: 'Save' });
    expect(submit).toBeDisabled();
    const user = userEvent.setup();
    await user.type(screen.getByLabelText('Title'), 'Hello there');
    await user.type(screen.getByLabelText('Body'), 'Some body content goes here.');
    expect(submit).toBeEnabled();
  });

  it('counts characters live', async () => {
    renderWithProviders(
      <EditorForm mode="create" primaryLabel="Save" onSubmit={() => undefined} />,
    );
    const user = userEvent.setup();
    await user.type(screen.getByLabelText('Title'), 'Hi');
    expect(screen.getByText('2/200')).toBeInTheDocument();
  });

  it('selecting category updates aria-checked', async () => {
    renderWithProviders(
      <EditorForm
        mode="create"
        primaryLabel="Save"
        initialValues={{ category: 'fraud_alert' }}
        onSubmit={() => undefined}
      />,
    );
    const fraud = screen.getByRole('radio', { name: 'Fraud alert' });
    const tips = screen.getByRole('radio', { name: 'Tips' });
    expect(fraud).toHaveAttribute('aria-checked', 'true');
    const user = userEvent.setup();
    await user.click(tips);
    expect(tips).toHaveAttribute('aria-checked', 'true');
    expect(fraud).toHaveAttribute('aria-checked', 'false');
  });

  it('disables fields when mode is locked', () => {
    renderWithProviders(
      <EditorForm
        mode="locked"
        primaryLabel="Unpublish"
        initialValues={{ title: 't', body: 'b', category: 'tips' }}
        onSubmit={() => undefined}
      />,
    );
    expect(screen.getByLabelText('Title')).toBeDisabled();
    expect(screen.getByLabelText('Body')).toBeDisabled();
  });

  it('invokes onSecondary with current form values when Save draft is clicked', async () => {
    const onSubmit = vi.fn();
    const onSecondary = vi.fn();
    renderWithProviders(
      <EditorForm
        mode="edit"
        primaryLabel="Publish"
        secondaryLabel="Save draft"
        initialValues={{ title: 'A title', body: 'A body', category: 'tips' }}
        onSubmit={onSubmit}
        onSecondary={onSecondary}
      />,
    );
    const user = userEvent.setup();
    await user.click(screen.getByRole('button', { name: 'Save draft' }));
    expect(onSecondary).toHaveBeenCalledWith({
      title: 'A title',
      body: 'A body',
      category: 'tips',
    });
    expect(onSubmit).not.toHaveBeenCalled();
  });
});
