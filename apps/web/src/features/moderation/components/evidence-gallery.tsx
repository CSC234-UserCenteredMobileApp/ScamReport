import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { AdminEvidenceFile } from '@my-product/shared';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { EvidenceThumb } from '@/features/moderation/components/evidence-thumb';

interface EvidenceGalleryProps {
  reportId: string;
  files: AdminEvidenceFile[];
}

interface ViewerState {
  url: string;
  kind: 'image' | 'pdf';
}

export function EvidenceGallery({ reportId, files }: EvidenceGalleryProps) {
  const { t } = useTranslation('moderation');
  const [viewer, setViewer] = useState<ViewerState | null>(null);

  if (files.length === 0) {
    return (
      <p className="rounded-lg border bg-muted/30 p-6 text-center text-sm text-muted-foreground">
        {t('detail.evidence')} — 0
      </p>
    );
  }

  return (
    <>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 md:grid-cols-4">
        {files.map((f) => (
          <EvidenceThumb
            key={f.id}
            reportId={reportId}
            file={f}
            onClick={(url) => setViewer({ url, kind: f.kind })}
          />
        ))}
      </div>

      <Dialog
        open={viewer !== null}
        onOpenChange={(open) => (open ? undefined : setViewer(null))}
      >
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>{t('evidence.viewerTitle')}</DialogTitle>
          </DialogHeader>
          {viewer?.kind === 'image' ? (
            <img
              src={viewer.url}
              alt={t('evidence.viewerTitle')}
              className="max-h-[70vh] w-full rounded object-contain"
            />
          ) : viewer?.kind === 'pdf' ? (
            <div className="space-y-3">
              <iframe
                src={viewer.url}
                title={t('evidence.viewerTitle')}
                className="h-[70vh] w-full rounded border bg-muted"
              />
              <p className="text-xs text-muted-foreground">
                {t('evidence.pdfFallback')}{' '}
                <a
                  href={viewer.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-primary underline-offset-2 hover:underline"
                >
                  {t('evidence.openFull')}
                </a>
              </p>
            </div>
          ) : null}
        </DialogContent>
      </Dialog>
    </>
  );
}
