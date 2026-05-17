// Export-options dialog. Two parallel concerns:
//   1. format          — 'csv' (Quick CSV, queue scope) vs 'bundle' (multi-
//                         sheet analytics); when bundle, sub-pick xlsx/zip.
//   2. date range      — optional. Empty inputs → server applies the per-mode
//                         default (CSV = unbounded; bundle = last 30 days).
//
// Filter preview shows the queue's currently-active filters so the user
// understands what'll be in the file before clicking Download.

import { zodResolver } from '@hookform/resolvers/zod';
import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { ExportFilters } from '../api/export';
import type { ExportFormValues } from '../hooks/use-export';

const schema = z
  .object({
    format: z.enum(['csv', 'bundle']),
    bundleFormat: z.enum(['xlsx', 'zip']).default('xlsx'),
    from: z.string().optional().default(''),
    to: z.string().optional().default(''),
  })
  .refine((v) => !v.from || !v.to || v.from <= v.to, {
    path: ['to'],
    message: 'toBeforeFrom',
  });
type SchemaValues = z.infer<typeof schema>;

interface ExportDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  filters: ExportFilters;
  submitting: boolean;
  onSubmit: (values: ExportFormValues) => Promise<boolean>;
}

export function ExportDialog({
  open,
  onOpenChange,
  filters,
  submitting,
  onSubmit,
}: ExportDialogProps) {
  const { t } = useTranslation('moderation');
  const {
    register,
    handleSubmit,
    watch,
    reset,
    formState: { errors },
  } = useForm<SchemaValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      format: 'csv',
      bundleFormat: 'xlsx',
      from: '',
      to: '',
    },
  });
  const format = watch('format');

  useEffect(() => {
    if (open) {
      reset({ format: 'csv', bundleFormat: 'xlsx', from: '', to: '' });
    }
  }, [open, reset]);

  async function submit(v: SchemaValues) {
    const ok = await onSubmit({
      format: v.format,
      bundleFormat: v.bundleFormat,
      from: v.from || undefined,
      to: v.to || undefined,
    });
    if (ok) onOpenChange(false);
  }

  const filterSummary = describeFilters(filters, t);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t('export.dialog.title')}</DialogTitle>
          <DialogDescription>{t('export.dialog.description')}</DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit(submit)} noValidate className="space-y-5">
          <fieldset className="space-y-2">
            <legend className="text-sm font-medium">{t('export.dialog.formatLabel')}</legend>
            <label className="flex cursor-pointer items-start gap-2 rounded-md border p-2 text-sm">
              <input type="radio" value="csv" className="mt-0.5" {...register('format')} />
              <span>
                <span className="font-medium">{t('export.dialog.formatCsv')}</span>
                <span className="block text-xs text-muted-foreground">
                  {t('export.dialog.formatCsvHint')}
                </span>
              </span>
            </label>
            <label className="flex cursor-pointer items-start gap-2 rounded-md border p-2 text-sm">
              <input type="radio" value="bundle" className="mt-0.5" {...register('format')} />
              <span>
                <span className="font-medium">{t('export.dialog.formatBundle')}</span>
                <span className="block text-xs text-muted-foreground">
                  {t('export.dialog.formatBundleHint')}
                </span>
              </span>
            </label>
          </fieldset>

          {format === 'bundle' && (
            <fieldset className="space-y-2 rounded-md bg-muted/40 p-3">
              <legend className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
                {t('export.dialog.bundleFormatLabel')}
              </legend>
              <div className="flex flex-wrap gap-3 text-sm">
                <label className="flex items-center gap-2">
                  <input type="radio" value="xlsx" {...register('bundleFormat')} />
                  {t('export.dialog.bundleFormatXlsx')}
                </label>
                <label className="flex items-center gap-2">
                  <input type="radio" value="zip" {...register('bundleFormat')} />
                  {t('export.dialog.bundleFormatZip')}
                </label>
              </div>
            </fieldset>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1">
              <Label htmlFor="export-from" className="text-xs text-muted-foreground">
                {t('export.dialog.from')}
              </Label>
              <Input id="export-from" type="date" {...register('from')} />
            </div>
            <div className="flex flex-col gap-1">
              <Label htmlFor="export-to" className="text-xs text-muted-foreground">
                {t('export.dialog.to')}
              </Label>
              <Input id="export-to" type="date" {...register('to')} />
            </div>
          </div>
          {errors.to && (
            <p className="text-xs text-destructive" role="alert">
              {t('export.dialog.toBeforeFrom')}
            </p>
          )}
          <p className="text-xs text-muted-foreground">
            {format === 'csv'
              ? t('export.dialog.dateHintCsv')
              : t('export.dialog.dateHintBundle')}
          </p>

          <div className="rounded-md border bg-card p-3 text-xs">
            <p className="mb-1 font-medium uppercase tracking-wide text-muted-foreground">
              {t('export.dialog.summaryLabel')}
            </p>
            <p>{filterSummary}</p>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={submitting}
            >
              {t('export.dialog.cancel')}
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting ? t('export.dialog.downloading') : t('export.dialog.submit')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

type Translator = (key: string) => string;

function describeFilters(filters: ExportFilters, t: Translator): string {
  const parts: string[] = [];
  parts.push(
    filters.status && filters.status.length > 0
      ? `${t('export.dialog.statusPart')}: ${filters.status.join(', ')}`
      : `${t('export.dialog.statusPart')}: ${t('export.dialog.partAll')}`,
  );
  parts.push(
    filters.scamType
      ? `${t('export.dialog.scamTypePart')}: ${filters.scamType}`
      : `${t('export.dialog.scamTypePart')}: ${t('export.dialog.partAll')}`,
  );
  parts.push(
    filters.priority
      ? `${t('export.dialog.priorityPart')}: ${t('export.dialog.partPriority')}`
      : `${t('export.dialog.priorityPart')}: ${t('export.dialog.partAll')}`,
  );
  parts.push(
    filters.confidence
      ? `${t('export.dialog.confidencePart')}: ${filters.confidence}`
      : `${t('export.dialog.confidencePart')}: ${t('export.dialog.partAll')}`,
  );
  return parts.join(' · ');
}
