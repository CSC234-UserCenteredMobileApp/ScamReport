import { flexRender, getCoreRowModel, useReactTable, type ColumnDef } from '@tanstack/react-table';
import { format } from 'date-fns';
import { enUS, th } from 'date-fns/locale';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import type { AdminAnnouncementListItem } from '@my-product/shared';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { AnnouncementStatusBadge } from './status-badge';
import { CategoryBadge } from './category-badge';

interface AnnouncementsTableProps {
  items: AdminAnnouncementListItem[];
}

export function AnnouncementsTable({ items }: AnnouncementsTableProps) {
  const { t, i18n } = useTranslation('announcements');
  const navigate = useNavigate();
  const locale = i18n.language === 'th' ? th : enUS;

  const columns = useMemo<ColumnDef<AdminAnnouncementListItem>[]>(
    () => [
      {
        id: 'title',
        header: () => t('col.title'),
        accessorKey: 'title',
        cell: ({ row }) => (
          <span className="line-clamp-1 font-medium">{row.original.title}</span>
        ),
      },
      {
        id: 'category',
        header: () => t('col.category'),
        cell: ({ row }) => <CategoryBadge category={row.original.category} />,
      },
      {
        id: 'status',
        header: () => t('col.status'),
        cell: ({ row }) => <AnnouncementStatusBadge status={row.original.status} />,
      },
      {
        id: 'createdAt',
        header: () => t('col.createdAt'),
        cell: ({ row }) =>
          format(new Date(row.original.createdAt), 'PP', { locale }),
      },
      {
        id: 'publishedAt',
        header: () => t('col.publishedAt'),
        cell: ({ row }) =>
          row.original.publishedAt
            ? format(new Date(row.original.publishedAt), 'PP', { locale })
            : '—',
      },
      {
        id: 'actions',
        header: () => <span className="sr-only">{t('col.actions')}</span>,
        cell: ({ row }) => (
          <div className="flex justify-end">
            <Button
              variant="outline"
              size="sm"
              onClick={() => navigate(`/announcements/${row.original.id}/edit`)}
            >
              {t('action.edit')}
            </Button>
          </div>
        ),
      },
    ],
    [t, locale, navigate],
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
