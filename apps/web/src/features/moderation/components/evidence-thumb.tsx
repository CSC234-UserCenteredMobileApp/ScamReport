import { ExternalLink, FileText, Loader2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import type { AdminEvidenceFile } from '@my-product/shared';
import { Button } from '@/components/ui/button';
import { useEvidenceUrl } from '@/features/moderation/api/evidence-url';

interface EvidenceThumbProps {
  reportId: string;
  file: AdminEvidenceFile;
  onClick: (url: string) => void;
}

export function EvidenceThumb({ reportId, file, onClick }: EvidenceThumbProps) {
  const { t } = useTranslation('moderation');
  const { data, isLoading, isError } = useEvidenceUrl(reportId, file.id);

  if (isLoading) {
    return (
      <div
        className="flex aspect-square items-center justify-center rounded-lg border bg-muted text-muted-foreground"
        aria-label={t('evidence.loading')}
      >
        <Loader2 className="size-5 animate-spin" aria-hidden />
      </div>
    );
  }

  if (isError || !data) {
    return (
      <div className="flex aspect-square flex-col items-center justify-center gap-1 rounded-lg border bg-muted p-2 text-center text-xs text-muted-foreground">
        <FileText className="size-5" aria-hidden />
        <span>{t('evidence.missing')}</span>
      </div>
    );
  }

  return (
    <div className="group relative overflow-hidden rounded-lg border bg-card">
      {file.kind === 'image' ? (
        <button
          type="button"
          onClick={() => onClick(data.url)}
          className="block aspect-square w-full"
          aria-label={t('evidence.viewerTitle')}
        >
          <img
            src={data.url}
            alt={file.mimeType}
            loading="lazy"
            className="size-full object-cover transition-transform group-hover:scale-105"
          />
        </button>
      ) : (
        <button
          type="button"
          onClick={() => onClick(data.url)}
          className="flex aspect-square w-full flex-col items-center justify-center gap-2 bg-muted text-muted-foreground transition-colors hover:bg-muted/70"
          aria-label={t('evidence.viewerTitle')}
        >
          <FileText className="size-8" aria-hidden />
          <span className="text-xs font-medium uppercase">PDF</span>
        </button>
      )}

      <Button
        asChild
        variant="ghost"
        size="icon"
        className="absolute right-1 top-1 size-7 bg-background/70 opacity-0 transition-opacity group-hover:opacity-100"
      >
        <a
          href={data.url}
          target="_blank"
          rel="noopener noreferrer"
          aria-label={t('evidence.openFull')}
          onClick={(e) => e.stopPropagation()}
        >
          <ExternalLink className="size-3.5" aria-hidden />
        </a>
      </Button>
    </div>
  );
}
