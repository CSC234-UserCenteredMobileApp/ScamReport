import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { PageHeader } from '@/components/page-header';
import { EditorForm, type EditorFormValues } from '@/features/announcements/components/editor-form';
import { PublishConfirmDialog } from '@/features/announcements/components/publish-confirm-dialog';
import {
  useCreateAnnouncement,
  usePublishAnnouncement,
} from '@/features/announcements/api/mutations';

export function AnnouncementsNewPage() {
  const { t } = useTranslation('announcements');
  const navigate = useNavigate();
  const create = useCreateAnnouncement();
  const publish = usePublishAnnouncement();

  const [publishOpen, setPublishOpen] = useState(false);
  const [pendingValues, setPendingValues] = useState<EditorFormValues | null>(null);

  const submitting = create.isPending || publish.isPending;

  const onSaveDraft = (values: EditorFormValues) => {
    create.mutate(values, {
      onSuccess: (res) => {
        toast.success(t('toast.created'));
        navigate(`/announcements/${res.item.id}/edit`);
      },
      onError: () => {
        toast.error(t('toast.saveError'));
      },
    });
  };

  const onPublishRequest = (values: EditorFormValues) => {
    setPendingValues(values);
    setPublishOpen(true);
  };

  const onPublishConfirm = async () => {
    if (!pendingValues) return;
    try {
      const created = await create.mutateAsync(pendingValues);
      const id = created.item.id;
      try {
        await publish.mutateAsync({ id, body: { pushToFcm: true } });
        toast.success(t('toast.published'));
        setPublishOpen(false);
        setPendingValues(null);
        navigate(`/announcements/${id}/edit`);
      } catch {
        // Create succeeded, publish failed: draft persisted, send the user to
        // the edit page so they can retry without retyping.
        toast.error(t('toast.publishError'));
        setPublishOpen(false);
        setPendingValues(null);
        navigate(`/announcements/${id}/edit`);
      }
    } catch {
      toast.error(t('toast.saveError'));
      // Leave dialog open so the user can retry or cancel.
    }
  };

  return (
    <div className="space-y-6">
      <PageHeader title={t('new.title')} subtitle={t('new.subtitle')} />
      <EditorForm
        mode="create"
        submitting={submitting}
        primaryLabel={t('action.publish')}
        secondaryLabel={t('action.saveDraft')}
        onSubmit={onPublishRequest}
        onSecondary={onSaveDraft}
      />
      <p className="text-xs text-muted-foreground">{t('new.attachmentsHint')}</p>

      <PublishConfirmDialog
        open={publishOpen}
        onOpenChange={(open) => {
          setPublishOpen(open);
          if (!open) setPendingValues(null);
        }}
        submitting={submitting}
        onConfirm={onPublishConfirm}
      />
    </div>
  );
}
