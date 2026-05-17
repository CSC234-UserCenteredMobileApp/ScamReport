// Wires the export dialog's submit handler to the right downloader and
// surfaces success/error via sonner. Caller passes `filters` (the queue's
// active filters) and the form values from the dialog.

import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';
import { ApiError } from '@/lib/api/client';
import {
  downloadReportsCsv,
  downloadBundle,
  type ExportFilters,
} from '../api/export';

export interface ExportFormValues {
  format: 'csv' | 'bundle';
  bundleFormat: 'xlsx' | 'zip';
  from?: string;   // yyyy-mm-dd or empty
  to?: string;
}

function isoFrom(date: string | undefined, end: '00:00:00' | '23:59:59'): string | undefined {
  if (!date) return undefined;
  return `${date}T${end}Z`;
}

export function useExport() {
  const { t } = useTranslation('moderation');
  const [submitting, setSubmitting] = useState(false);

  async function run(values: ExportFormValues, baseFilters: ExportFilters): Promise<boolean> {
    setSubmitting(true);
    try {
      const merged: ExportFilters = {
        ...baseFilters,
        from: isoFrom(values.from, '00:00:00'),
        to: isoFrom(values.to, '23:59:59'),
      };
      if (values.format === 'csv') {
        await downloadReportsCsv(merged);
      } else {
        await downloadBundle(merged, values.bundleFormat);
      }
      toast.success(t('export.success'));
      return true;
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        toast.error(t('export.errorAuth'));
      } else {
        toast.error(t('export.error'));
      }
      return false;
    } finally {
      setSubmitting(false);
    }
  }

  return { submitting, run };
}
