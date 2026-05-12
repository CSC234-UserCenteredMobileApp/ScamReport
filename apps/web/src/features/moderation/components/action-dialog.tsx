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
import type { ModerationActionKind } from '@/features/moderation/api/actions';

const titleKeyMap: Record<ModerationActionKind, string> = {
  approve: 'dialog.approveTitle',
  reject: 'dialog.rejectTitle',
  flag: 'dialog.flagTitle',
  unflag: 'dialog.unflagTitle',
};

const remarkSchema = z.object({
  remark: z.string().trim().min(1),
});
type RemarkFormValues = z.infer<typeof remarkSchema>;

interface ActionDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  kind: ModerationActionKind | null;
  reportTitle: string;
  submitting: boolean;
  onSubmit: (remark: string) => void;
}

export function ActionDialog({
  open,
  onOpenChange,
  kind,
  reportTitle,
  submitting,
  onSubmit,
}: ActionDialogProps) {
  const { t } = useTranslation('moderation');
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<RemarkFormValues>({
    resolver: zodResolver(remarkSchema),
    defaultValues: { remark: '' },
  });

  useEffect(() => {
    if (open) reset({ remark: '' });
  }, [open, kind, reset]);

  const titleKey = kind ? titleKeyMap[kind] : 'dialog.approveTitle';

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t(titleKey)}</DialogTitle>
          <DialogDescription className="line-clamp-2">{reportTitle}</DialogDescription>
        </DialogHeader>
        <form
          onSubmit={handleSubmit((v) => onSubmit(v.remark))}
          noValidate
          className="space-y-4"
        >
          <div className="space-y-2">
            <Label htmlFor="remark">{t('dialog.remarkLabel')}</Label>
            <Textarea
              id="remark"
              placeholder={t('dialog.remarkPlaceholder')}
              aria-invalid={errors.remark ? 'true' : undefined}
              {...register('remark')}
            />
            {errors.remark && (
              <p className="text-xs text-destructive" role="alert">
                {t('dialog.remarkRequired')}
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
              {t('dialog.cancel')}
            </Button>
            <Button type="submit" disabled={submitting}>
              {t('dialog.submit')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
