import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { PageHeader } from '@/components/page-header';
import { EditorForm, type EditorFormValues } from '@/features/announcements/components/editor-form';
import { useCreateAnnouncement } from '@/features/announcements/api/mutations';

export function AnnouncementsNewPage() {
  const { t } = useTranslation('announcements');
  const navigate = useNavigate();
  const create = useCreateAnnouncement();

  const onSubmit = (values: EditorFormValues) => {
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

  return (
    <div className="space-y-6">
      <PageHeader title={t('new.title')} subtitle={t('new.subtitle')} />
      <EditorForm
        mode="create"
        submitting={create.isPending}
        primaryLabel={t('action.saveDraft')}
        onSubmit={onSubmit}
      />
      <p className="text-xs text-muted-foreground">{t('new.attachmentsHint')}</p>
    </div>
  );
}
