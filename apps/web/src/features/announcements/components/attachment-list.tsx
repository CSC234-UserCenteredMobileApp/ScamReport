import { FileText, Trash2, Upload } from 'lucide-react';
import { useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { toast } from 'sonner';
import type { AnnouncementAttachment } from '@my-product/shared';
import { Button } from '@/components/ui/button';
import {
  useDeleteAttachment,
  useUploadAttachment,
} from '@/features/announcements/api/attachments';

const ALLOWED_MIME = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'application/pdf',
]);
const MAX_BYTES = 10 * 1024 * 1024;
const MAX_ATTACHMENTS = 10;

interface AttachmentListProps {
  announcementId: string;
  attachments: AnnouncementAttachment[];
  disabled?: boolean;
}

export function AttachmentList({
  announcementId,
  attachments,
  disabled = false,
}: AttachmentListProps) {
  const { t } = useTranslation('announcements');
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const [progress, setProgress] = useState<number | null>(null);
  const upload = useUploadAttachment();
  const remove = useDeleteAttachment();

  const atLimit = attachments.length >= MAX_ATTACHMENTS;

  const validate = (file: File): string | null => {
    if (!ALLOWED_MIME.has(file.type)) return t('attachments.errors.mime');
    if (file.size > MAX_BYTES) return t('attachments.errors.size');
    return null;
  };

  const submit = (file: File) => {
    const err = validate(file);
    if (err) {
      toast.error(err);
      return;
    }
    setProgress(0);
    upload.mutate(
      {
        announcementId,
        file,
        onProgress: (loaded, total) => setProgress(Math.round((loaded / total) * 100)),
      },
      {
        onSuccess: () => {
          toast.success(t('attachments.uploaded'));
          setProgress(null);
        },
        onError: () => {
          toast.error(t('attachments.errors.upload'));
          setProgress(null);
        },
      },
    );
  };

  const onPick = () => inputRef.current?.click();

  return (
    <section aria-label={t('attachments.heading')} className="space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold">
          {t('attachments.heading')} ({attachments.length}/{MAX_ATTACHMENTS})
        </h3>
        <Button
          type="button"
          variant="outline"
          size="sm"
          disabled={disabled || atLimit || upload.isPending}
          onClick={onPick}
        >
          <Upload className="mr-2 size-4" aria-hidden />
          {t('attachments.add')}
        </Button>
        <input
          ref={inputRef}
          type="file"
          className="sr-only"
          accept="image/jpeg,image/png,image/webp,image/gif,application/pdf"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) submit(f);
            e.target.value = '';
          }}
        />
      </div>

      {!disabled && !atLimit && (
        <div
          onDragOver={(e) => {
            e.preventDefault();
            setDragOver(true);
          }}
          onDragLeave={() => setDragOver(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDragOver(false);
            const f = e.dataTransfer.files?.[0];
            if (f) submit(f);
          }}
          className={`rounded-lg border-2 border-dashed p-6 text-center text-sm transition-colors ${
            dragOver ? 'border-primary bg-primary/5' : 'border-border text-muted-foreground'
          }`}
        >
          {t('attachments.dropHint')}
          {progress !== null && (
            <p className="mt-2 text-xs">{t('attachments.uploading', { percent: progress })}</p>
          )}
        </div>
      )}

      {attachments.length === 0 ? (
        <p className="text-sm text-muted-foreground">{t('attachments.empty')}</p>
      ) : (
        <ul className="grid grid-cols-2 gap-3 md:grid-cols-3">
          {attachments.map((a) => (
            <li
              key={a.id}
              className="group relative overflow-hidden rounded-lg border bg-card"
            >
              <div className="flex aspect-video items-center justify-center bg-muted">
                {a.kind === 'image' && a.signedUrl ? (
                  <img
                    src={a.signedUrl}
                    alt=""
                    className="size-full object-cover"
                    loading="lazy"
                  />
                ) : (
                  <FileText className="size-8 text-muted-foreground" aria-hidden />
                )}
              </div>
              <div className="flex items-center justify-between gap-2 p-2 text-xs">
                <span className="line-clamp-1 text-muted-foreground">
                  {a.kind === 'pdf' ? 'PDF' : a.mimeType.split('/')[1]?.toUpperCase() ?? 'IMG'}
                </span>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon"
                  aria-label={t('attachments.delete')}
                  disabled={disabled || remove.isPending}
                  onClick={() =>
                    remove.mutate(
                      { announcementId, attachmentId: a.id },
                      {
                        onSuccess: () => toast.success(t('attachments.deleted')),
                        onError: () => toast.error(t('attachments.errors.delete')),
                      },
                    )
                  }
                >
                  <Trash2 className="size-4" aria-hidden />
                </Button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
