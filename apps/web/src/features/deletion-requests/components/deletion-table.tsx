import { flexRender, getCoreRowModel, useReactTable, type ColumnDef } from '@tanstack/react-table';
import { format, formatDistanceToNowStrict } from 'date-fns';
import { enUS, th } from 'date-fns/locale';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import type { AdminDeletionRequestItem } from '@my-product/shared';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { DeletionStatusBadge } from './status-badge';

interface DeletionTableProps {
  items: AdminDeletionRequestItem[];
  onApprove: (item: AdminDeletionRequestItem) => void;
  onReject: (item: AdminDeletionRequestItem) => void;
}

export function DeletionTable({ items, onApprove, onReject }: DeletionTableProps) {
  const { t, i18n } = useTranslation('announcements');
  const locale = i18n.language === 'th' ? th : enUS;

  const columns = useMemo<ColumnDef<AdminDeletionRequestItem>[]>(
    () => [
      {
        id: 'handle',
        header: () => t('deletionRequests.col.handle'),
        cell: ({ row }) => (
          <span className="font-mono text-sm">{row.original.userHandle}</span>
        ),
      },
      {
        id: 'requestedAt',
        header: () => t('deletionRequests.col.requested'),
        cell: ({ row }) =>
          formatDistanceToNowStrict(new Date(row.original.requestedAt), { locale }),
      },
      {
        id: 'purgeDueAt',
        header: () => t('deletionRequests.col.purgeDue'),
        cell: ({ row }) =>
          format(new Date(row.original.purgeDueAt), 'PP', { locale }),
      },
      {
        id: 'status',
        header: () => t('deletionRequests.col.status'),
        cell: ({ row }) => <DeletionStatusBadge status={row.original.status} />,
      },
      {
        id: 'actions',
        header: () => (
          <span className="sr-only">{t('deletionRequests.col.actions')}</span>
        ),
        cell: ({ row }) => {
          if (row.original.status !== 'pending') return null;
          return (
            <div className="flex items-center justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => onReject(row.original)}
              >
                {t('deletionRequests.action.reject')}
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={() => onApprove(row.original)}
              >
                {t('deletionRequests.action.approve')}
              </Button>
            </div>
          );
        },
      },
    ],
    [t, locale, onApprove, onReject],
  );

  const table = useReactTable({
    data: items,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div className="overflow-hidden rounded-lg border bg-card">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((hg) => (
            <TableRow key={hg.id}>
              {hg.headers.map((header) => (
                <TableHead key={header.id}>
                  {flexRender(header.column.columnDef.header, header.getContext())}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows.map((row) => (
            <TableRow key={row.id}>
              {row.getVisibleCells().map((cell) => (
                <TableCell key={cell.id}>
                  {flexRender(cell.column.columnDef.cell, cell.getContext())}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
