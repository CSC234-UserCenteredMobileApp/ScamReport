import { Trash2 } from 'lucide-react';
import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useParams } from 'react-router-dom';
import { toast } from 'sonner';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { PageHeader } from '@/components/page-header';
import { AnnouncementStatusBadge } from '@/features/announcements/components/status-badge';
import { AttachmentList } from '@/features/announcements/components/attachment-list';
import { DeleteConfirmDialog } from '@/features/announcements/components/delete-confirm-dialog';
import { EditorForm, type EditorFormValues } from '@/features/announcements/components/editor-form';
import { PublishConfirmDialog } from '@/features/announcements/components/publish-confirm-dialog';
import { useAnnouncement } from '@/features/announcements/api/detail';
import {
  useDeleteAnnouncement,
  usePublishAnnouncement,
  useUnpublishAnnouncement,
  useUpdateAnnouncement,
} from '@/features/announcements/api/mutations';

export function AnnouncementsEditPage() {
  const { t } = useTranslation('announcements');
  const { id = '' } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data, isLoading, isError, error } = useAnnouncement(id);
  const item = data?.item;

  const update = useUpdateAnnouncement();
  const publish = usePublishAnnouncement();
  const unpublish = useUnpublishAnnouncement();
  const del = useDeleteAnnouncement();

  const [publishOpen, setPublishOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [pendingPublishValues, setPendingPublishValues] = useState<EditorFormValues | null>(null);

  // 404 from the server → bounce to list (the toast keeps the cause visible).
  useEffect(() => {
    if (isError && error && 'status' in error && (error as { status?: number }).status === 404) {
      toast.error(t('toast.notFound'));
      navigate('/announcements', { replace: true });
    }
  }, [isError, error, navigate, t]);

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-12" />
        <Skeleton className="h-96" />
      </div>
    );
  }

  if (isError || !item) {
    return (
      <Alert variant="destructive" role="alert">
        <AlertTitle>{t('error')}</AlertTitle>
        <AlertDescription>{t('error')}</AlertDescription>
      </Alert>
    );
  }

  const locked = item.status === 'published';
  const submitting =
    update.isPending || publish.isPending || unpublish.isPending || del.isPending;

  const onSave = (values: EditorFormValues) => {
    update.mutate(
      { id, body: values },
      {
        onSuccess: () => toast.success(t('toast.saved')),
        onError: () => toast.error(t('toast.saveError')),
      },
    );
  };

  const onPublishRequest = (values: EditorFormValues) => {
    setPendingPublishValues(values);
    setPublishOpen(true);
  };

  const onPublishConfirm = () => {
    const finish = () => {
      publish.mutate(
        { id, body: { pushToFcm: true } },
        {
          onSuccess: () => {
            toast.success(t('toast.published'));
            setPublishOpen(false);
          },
          onError: () => {
            toast.error(t('toast.publishError'));
          },
        },
      );
    };

    // If the user edited fields in the same gesture, persist them before
    // publishing. Publish locks the row server-side, so a stale save would
    // 409.
    if (pendingPublishValues) {
      update.mutate(
        { id, body: pendingPublishValues },
        { onSuccess: finish, onError: () => toast.error(t('toast.saveError')) },
      );
      setPendingPublishValues(null);
    } else {
      finish();
    }
  };

  const onUnpublish = () => {
    unpublish.mutate(
      { id },
      {
        onSuccess: () => toast.success(t('toast.unpublished')),
        onError: () => toast.error(t('toast.actionError')),
      },
    );
  };

  const onDelete = () => {
    del.mutate(
      { id },
      {
        onSuccess: () => {
          toast.success(t('toast.deleted'));
          navigate('/announcements', { replace: true });
        },
        onError: () => toast.error(t('toast.actionError')),
      },
    );
  };

  return (
    <div className="space-y-6">
      <PageHeader
        title={t('edit.title')}
        subtitle={item.title}
        actions={<AnnouncementStatusBadge status={item.status} />}
      />

      {locked && (
        <Alert>
          <AlertTitle>{t('edit.lockedTitle')}</AlertTitle>
          <AlertDescription>{t('edit.lockedBody')}</AlertDescription>
        </Alert>
      )}

      <EditorForm
        mode={locked ? 'locked' : 'edit'}
        submitting={submitting}
        initialValues={{ title: item.title, body: item.body, category: item.category }}
        primaryLabel={locked ? t('action.unpublish') : t('action.publish')}
        secondaryLabel={locked ? undefined : t('action.saveDraft')}
        onSubmit={(v) => (locked ? onUnpublish() : onPublishRequest(v))}
        onSecondary={onSave}
      />

      <AttachmentList
        announcementId={id}
        attachments={item.attachments}
        disabled={locked}
      />

      {!locked && (
        <div className="flex justify-end">
          <Button
            type="button"
            variant="destructive"
            onClick={() => setDeleteOpen(true)}
            disabled={submitting}
          >
            <Trash2 className="mr-2 size-4" aria-hidden />
            {t('action.delete')}
          </Button>
        </div>
      )}

      <PublishConfirmDialog
        open={publishOpen}
        onOpenChange={setPublishOpen}
        submitting={publish.isPending || update.isPending}
        onConfirm={onPublishConfirm}
      />

      <DeleteConfirmDialog
        open={deleteOpen}
        onOpenChange={setDeleteOpen}
        submitting={del.isPending}
        title={item.title}
        onConfirm={onDelete}
      />
    </div>
  );
}
