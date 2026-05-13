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
import { Skeleton } from '@/components/ui/skeleton';
import { useSubscriberCount } from '@/features/announcements/api/subscriber-count';

interface PublishConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  submitting: boolean;
  onConfirm: () => void;
}

export function PublishConfirmDialog({
  open,
  onOpenChange,
  submitting,
  onConfirm,
}: PublishConfirmDialogProps) {
  const { t } = useTranslation('announcements');
  // Lazy: react-query keeps the count cached across opens, so this only hits
  // the backend the first time the editor is mounted in a session.
  const { data, isLoading } = useSubscriberCount();

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{t('publish.confirmTitle')}</DialogTitle>
          {isLoading ? (
            <Skeleton className="h-4 w-48" />
          ) : (
            <DialogDescription>
              {t('publish.confirmBody', { count: data?.count ?? 0 })}
            </DialogDescription>
          )}
        </DialogHeader>
        <DialogFooter>
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={submitting}
          >
            {t('publish.cancel')}
          </Button>
          <Button type="button" onClick={onConfirm} disabled={submitting}>
            {t('publish.confirm')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
