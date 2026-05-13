import { describe, it, expect } from 'vitest';
import { screen, within } from '@testing-library/react';
import type { ModerationRecord } from '@my-product/shared';
import { AuditTrail } from '@/features/moderation/components/audit-trail';
import { renderWithProviders } from '../helpers';

const submittedAt = '2026-01-01T08:00:00Z';

const records: ModerationRecord[] = [
  {
    adminId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    action: 'flag',
    remark: 'Need second pair of eyes.',
    createdAt: '2026-01-01T10:00:00Z',
  },
  {
    adminId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    action: 'unflag',
    remark: 'False alarm.',
    createdAt: '2026-01-01T12:00:00Z',
  },
  {
    adminId: null,
    action: 'approve',
    remark: '',
    createdAt: '2026-01-01T14:00:00Z',
  },
];

describe('AuditTrail', () => {
  it('renders only the synthetic Submitted row when no actions exist', () => {
    renderWithProviders(<AuditTrail records={[]} submittedAt={submittedAt} />);
    const trail = screen.getByTestId('audit-trail');
    const items = within(trail).getAllByRole('listitem');
    expect(items).toHaveLength(1);
    expect(items[0]).toHaveTextContent(/Submitted/);
  });

  it('renders actions newest-first with the synthetic Submitted row at the bottom', () => {
    renderWithProviders(<AuditTrail records={records} submittedAt={submittedAt} />);
    const items = within(screen.getByTestId('audit-trail')).getAllByRole('listitem');
    expect(items).toHaveLength(4);
    expect(items[0]).toHaveTextContent('Approve');
    expect(items[1]).toHaveTextContent('Unflag');
    expect(items[2]).toHaveTextContent(/Flag/);
    expect(items[3]).toHaveTextContent(/Submitted/);
  });

  it('renders the anonymous admin label when adminId is null', () => {
    renderWithProviders(<AuditTrail records={records} submittedAt={submittedAt} />);
    expect(screen.getByText('System')).toBeInTheDocument();
  });
});
