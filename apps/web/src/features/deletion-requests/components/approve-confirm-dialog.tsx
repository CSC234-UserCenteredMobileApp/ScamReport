import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

interface ApproveConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  submitting: boolean;
  handle: string;
  onConfirm: () => void;
}

export function ApproveConfirmDialog({
  open,
  onOpenChange,
  submitting,
  handle,
  onConfirm,
}: ApproveConfirmDialogProps) {
  const { t } = useTranslation('announcements');
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t('deletionRequests.approve.title')}</DialogTitle>
          <DialogDescription className="line-clamp-2">{handle}</DialogDescription>
        </DialogHeader>
        <p className="text-sm text-muted-foreground">
          {t('deletionRequests.approve.body')}
        </p>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={submitting}
          >
            {t('deletionRequests.cancel')}
          </Button>
          <Button
            type="button"
            variant="destructive"
            onClick={onConfirm}
            disabled={submitting}
          >
            {t('deletionRequests.approve.confirm')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
