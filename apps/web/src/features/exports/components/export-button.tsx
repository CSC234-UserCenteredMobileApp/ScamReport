// PageHeader actions-slot button that opens the export dialog. Receives the
// queue page's currently-active filters so the dialog's filter summary can
// show what will be in the file before the user commits.

import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Download } from 'lucide-react';
import { Button } from '@/components/ui/button';
import type { ExportFilters } from '../api/export';
import { useExport } from '../hooks/use-export';
import { ExportDialog } from './export-dialog';

interface ExportButtonProps {
  filters: ExportFilters;
}

export function ExportButton({ filters }: ExportButtonProps) {
  const { t } = useTranslation('moderation');
  const [open, setOpen] = useState(false);
  const { submitting, run } = useExport();

  return (
    <>
      <Button variant="outline" size="sm" onClick={() => setOpen(true)} className="gap-2">
        <Download className="size-4" aria-hidden />
        {t('action.export')}
      </Button>
      <ExportDialog
        open={open}
        onOpenChange={setOpen}
        filters={filters}
        submitting={submitting}
        onSubmit={(values) => run(values, filters)}
      />
    </>
  );
}
