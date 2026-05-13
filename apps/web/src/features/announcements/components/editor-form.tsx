import { zodResolver } from '@hookform/resolvers/zod';
import { useEffect } from 'react';
import { Controller, useForm } from 'react-hook-form';
import { useTranslation } from 'react-i18next';
import { z } from 'zod';
import type { AnnouncementCategory } from '@my-product/shared';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { cn } from '@/lib/utils';

const TITLE_MAX = 200;
const BODY_MAX = 5000;

const categories: AnnouncementCategory[] = ['fraud_alert', 'tips', 'platform_update'];

const editorSchema = z.object({
  title: z.string().trim().min(1).max(TITLE_MAX),
  body: z.string().trim().min(1).max(BODY_MAX),
  category: z.enum(['fraud_alert', 'tips', 'platform_update']),
});
export type EditorFormValues = z.infer<typeof editorSchema>;

export type EditorMode = 'create' | 'edit' | 'locked';

interface EditorFormProps {
  mode: EditorMode;
  initialValues?: Partial<EditorFormValues>;
  submitting?: boolean;
  primaryLabel: string;
  secondaryLabel?: string;
  onSubmit: (values: EditorFormValues) => void;
  onSecondary?: (values: EditorFormValues) => void;
}

export function EditorForm({
  mode,
  initialValues,
  submitting = false,
  primaryLabel,
  secondaryLabel,
  onSubmit,
  onSecondary,
}: EditorFormProps) {
  const { t } = useTranslation('announcements');
  const locked = mode === 'locked';

  const {
    register,
    handleSubmit,
    control,
    reset,
    watch,
    getValues,
    formState: { errors, isValid },
  } = useForm<EditorFormValues>({
    resolver: zodResolver(editorSchema),
    mode: 'onChange',
    defaultValues: {
      title: initialValues?.title ?? '',
      body: initialValues?.body ?? '',
      category: initialValues?.category ?? 'fraud_alert',
    },
  });

  useEffect(() => {
    reset({
      title: initialValues?.title ?? '',
      body: initialValues?.body ?? '',
      category: initialValues?.category ?? 'fraud_alert',
    });
  }, [initialValues?.title, initialValues?.body, initialValues?.category, reset]);

  const titleLen = watch('title')?.length ?? 0;
  const bodyLen = watch('body')?.length ?? 0;

  return (
    <form
      onSubmit={handleSubmit(onSubmit)}
      noValidate
      className="space-y-6"
      aria-label={t('editor.formLabel')}
    >
      <fieldset disabled={locked} className="space-y-6 disabled:opacity-60">
        <div className="space-y-2">
          <Label>{t('editor.category')}</Label>
          <Controller
            control={control}
            name="category"
            render={({ field }) => (
              <div role="radiogroup" aria-label={t('editor.category')} className="flex flex-wrap gap-2">
                {categories.map((c) => {
                  const selected = field.value === c;
                  return (
                    <button
                      key={c}
                      type="button"
                      role="radio"
                      aria-checked={selected}
                      onClick={() => field.onChange(c)}
                      className={cn(
                        'rounded-xl border px-3 py-1.5 text-sm transition-colors',
                        selected
                          ? 'border-primary bg-primary text-primary-foreground'
                          : 'border-border bg-card text-foreground hover:bg-muted',
                      )}
                    >
                      {t(`category.${c}`)}
                    </button>
                  );
                })}
              </div>
            )}
          />
          {errors.category && (
            <p className="text-xs text-destructive" role="alert">
              {t('editor.errors.categoryRequired')}
            </p>
          )}
        </div>

        <div className="space-y-2">
          <div className="flex items-end justify-between">
            <Label htmlFor="title">{t('editor.title')}</Label>
            <span className="text-xs text-muted-foreground">
              {titleLen}/{TITLE_MAX}
            </span>
          </div>
          <Input
            id="title"
            maxLength={TITLE_MAX}
            aria-invalid={errors.title ? 'true' : undefined}
            {...register('title')}
          />
          {errors.title && (
            <p className="text-xs text-destructive" role="alert">
              {t('editor.errors.titleRequired')}
            </p>
          )}
        </div>

        <div className="space-y-2">
          <div className="flex items-end justify-between">
            <Label htmlFor="body">{t('editor.body')}</Label>
            <span className="text-xs text-muted-foreground">
              {bodyLen}/{BODY_MAX}
            </span>
          </div>
          <Textarea
            id="body"
            rows={10}
            maxLength={BODY_MAX}
            aria-invalid={errors.body ? 'true' : undefined}
            className="font-mono text-sm"
            {...register('body')}
          />
          {errors.body && (
            <p className="text-xs text-destructive" role="alert">
              {t('editor.errors.bodyRequired')}
            </p>
          )}
        </div>
      </fieldset>

      <div className="flex flex-wrap justify-end gap-2">
        {secondaryLabel && onSecondary && !locked && (
          <Button
            type="button"
            variant="outline"
            disabled={submitting || !isValid}
            onClick={() => onSecondary(getValues())}
          >
            {secondaryLabel}
          </Button>
        )}
        <Button type="submit" disabled={submitting || !isValid || locked}>
          {primaryLabel}
        </Button>
      </div>
    </form>
  );
}
