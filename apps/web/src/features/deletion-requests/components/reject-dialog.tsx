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
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';

const REASON_MAX = 500;

const rejectSchema = z.object({
  reason: z.string().trim().min(1).max(REASON_MAX),
});
type RejectFormValues = z.infer<typeof rejectSchema>;

interface RejectDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  submitting: boolean;
  handle: string;
  onSubmit: (reason: string) => void;
}

export function RejectDialog({
  open,
  onOpenChange,
  submitting,
  handle,
  onSubmit,
}: RejectDialogProps) {
  const { t } = useTranslation('announcements');
  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors, isValid },
  } = useForm<RejectFormValues>({
    resolver: zodResolver(rejectSchema),
    mode: 'onChange',
    defaultValues: { reason: '' },
  });

  useEffect(() => {
    if (open) reset({ reason: '' });
  }, [open, reset]);

  const reasonLen = watch('reason')?.length ?? 0;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t('deletionRequests.reject.title')}</DialogTitle>
          <DialogDescription className="line-clamp-2">{handle}</DialogDescription>
        </DialogHeader>
        <form
          onSubmit={handleSubmit((v) => onSubmit(v.reason))}
          noValidate
          className="space-y-4"
        >
          <div className="space-y-2">
            <div className="flex items-end justify-between">
              <Label htmlFor="reason">{t('deletionRequests.reject.reasonLabel')}</Label>
              <span className="text-xs text-muted-foreground">
                {reasonLen}/{REASON_MAX}
              </span>
            </div>
            <Textarea
              id="reason"
              rows={5}
              maxLength={REASON_MAX}
              aria-invalid={errors.reason ? 'true' : undefined}
              placeholder={t('deletionRequests.reject.reasonPlaceholder')}
              {...register('reason')}
            />
            {errors.reason && (
              <p className="text-xs text-destructive" role="alert">
                {t('deletionRequests.reject.reasonRequired')}
              </p>
            )}
          </div>
          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
              disabled={submitting}
            >
              {t('deletionRequests.cancel')}
            </Button>
            <Button type="submit" disabled={submitting || !isValid}>
              {t('deletionRequests.reject.confirm')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
