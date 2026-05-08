// Per-user / per-message limits for Ask AI. Centralised so the route layer
// and the service share constants. Rate limiting + abuse hooks live here too
// (PRD §3.3 — conversations are logged per user for abuse monitoring).

import { getPrisma } from '../../core/db/client';

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

// Daily turn cap. Override via env in production (Remote Config flag flips
// can stop a runaway user via a rollout, but the hard floor is here).
export const DAILY_TURN_CAP = Number(process.env.ASK_AI_DAILY_TURN_CAP ?? 30);
const DAY_MS = 24 * 60 * 60 * 1000;

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

export class AskAiRateLimitError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = 'AskAiRateLimitError';
  }
}

/**
 * Enforces the per-user daily turn cap. Counts user-role messages in the
 * last 24h across all of the caller's conversations. Throws 429 with
 * `code: 'rate_limited'` once the cap is exceeded.
 *
 * Skipped when DAILY_TURN_CAP <= 0 (test override).
 */
export async function assertWithinDailyTurnCap(userId: string): Promise<void> {
  if (DAILY_TURN_CAP <= 0) return;
  const since = new Date(Date.now() - DAY_MS);
  const prisma = getPrisma();
  const count = await prisma.aiMessage.count({
    where: {
      role: 'user',
      createdAt: { gte: since },
      conversation: { userId },
    },
  });
  if (count >= DAILY_TURN_CAP) {
    throw new AskAiRateLimitError(
      429,
      'rate_limited',
      `Daily Ask AI turn cap reached (${DAILY_TURN_CAP}/24h). Try again tomorrow.`,
    );
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
