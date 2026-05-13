import { flexRender, getCoreRowModel, useReactTable, type ColumnDef } from '@tanstack/react-table';
import { formatDistanceToNowStrict } from 'date-fns';
import { enUS, th } from 'date-fns/locale';
import { MoreHorizontal } from 'lucide-react';
import { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import type { AdminQueueItem } from '@my-product/shared';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { StatusBadge } from '@/features/moderation/components/status-badge';
import type { ModerationActionKind } from '@/features/moderation/api/actions';

interface QueueTableProps {
  items: AdminQueueItem[];
  onAction: (item: AdminQueueItem, kind: ModerationActionKind) => void;
}

export function QueueTable({ items, onAction }: QueueTableProps) {
  const { t, i18n } = useTranslation('moderation');
  const navigate = useNavigate();
  const locale = i18n.language === 'th' ? th : enUS;

  const columns = useMemo<ColumnDef<AdminQueueItem>[]>(
    () => [
      {
        id: 'type',
        header: () => t('col.type'),
        accessorKey: 'scamTypeCode',
        cell: ({ row }) => (
          <Badge variant="secondary">
            {i18n.language === 'th'
              ? row.original.scamTypeLabelTh
              : row.original.scamTypeLabelEn}
          </Badge>
        ),
      },
      {
        id: 'title',
        header: () => t('col.title'),
        accessorKey: 'title',
        cell: ({ row }) => (
          <span className="line-clamp-1 font-medium">{row.original.title}</span>
        ),
      },
      {
        id: 'age',
        header: () => t('col.age'),
        cell: ({ row }) =>
          formatDistanceToNowStrict(new Date(row.original.submittedAt), {
            locale,
          }),
      },
      {
        id: 'evidence',
        header: () => t('col.evidence'),
        accessorKey: 'evidenceCount',
        cell: ({ row }) => row.original.evidenceCount,
      },
      {
        id: 'status',
        header: () => t('col.status'),
        cell: ({ row }) => <StatusBadge status={row.original.status} />,
      },
      {
        id: 'actions',
        header: () => <span className="sr-only">{t('col.actions')}</span>,
        cell: ({ row }) => {
          const isFlagged = row.original.status === 'flagged';
          return (
            <div className="flex items-center justify-end gap-1">
              <Button
                variant="outline"
                size="sm"
                onClick={() => navigate(`/moderation/${row.original.id}`)}
              >
                {t('action.review')}
              </Button>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button
                    variant="ghost"
                    size="icon"
                    aria-label={t('col.actions')}
                  >
                    <MoreHorizontal />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem onSelect={() => onAction(row.original, 'approve')}>
                    {t('action.approve')}
                  </DropdownMenuItem>
                  <DropdownMenuItem onSelect={() => onAction(row.original, 'reject')}>
                    {t('action.reject')}
                  </DropdownMenuItem>
                  {isFlagged ? (
                    <DropdownMenuItem onSelect={() => onAction(row.original, 'unflag')}>
                      {t('action.unflag')}
                    </DropdownMenuItem>
                  ) : (
                    <DropdownMenuItem onSelect={() => onAction(row.original, 'flag')}>
                      {t('action.flag')}
                    </DropdownMenuItem>
                  )}
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          );
        },
      },
    ],
    [t, i18n.language, locale, navigate, onAction],
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
