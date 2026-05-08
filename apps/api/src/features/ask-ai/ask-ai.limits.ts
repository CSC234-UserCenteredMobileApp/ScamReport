// Per-user / per-message limits for Ask AI. Centralised so the route layer
// and the service share constants. PR-7 will add per-user-per-day rate
// limiting on top of these.

export const MAX_ATTACHMENTS_PER_MESSAGE = 3;
export const MAX_ATTACHMENT_BYTES = 10 * 1024 * 1024; // 10 MB
export const ALLOWED_ATTACHMENT_MIME = new Set<string>([
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'application/pdf',
]);

export const ATTACHMENTS_BUCKET = 'chat-attachments';

export class AskAiAttachmentError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly code: string,
  ) {
    super(message);
    this.name = 'AskAiAttachmentError';
  }
}

export interface AttachmentInput {
  bytes: Uint8Array;
  mimeType: string;
}

export function validateAttachment(input: AttachmentInput): void {
  if (!ALLOWED_ATTACHMENT_MIME.has(input.mimeType)) {
    throw new AskAiAttachmentError(
      `Unsupported attachment type: ${input.mimeType}`,
      415,
      'unsupported_media_type',
    );
  }
  if (input.bytes.byteLength === 0) {
    throw new AskAiAttachmentError('Attachment is empty', 400, 'empty_attachment');
  }
  if (input.bytes.byteLength > MAX_ATTACHMENT_BYTES) {
    throw new AskAiAttachmentError(
      'Attachment too large (max 10MB)',
      413,
      'attachment_too_large',
    );
  }
}

export function extFromMime(mime: string): string {
  switch (mime) {
    case 'image/jpeg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    case 'application/pdf':
      return 'pdf';
    default:
      return 'bin';
  }
}
