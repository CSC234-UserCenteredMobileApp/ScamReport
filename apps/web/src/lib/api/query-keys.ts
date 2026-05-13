export const queryKeys = {
  moderation: {
    all: ['moderation'] as const,
    queues: ['moderation', 'queue'] as const,
    queue: (scamType?: string) =>
      ['moderation', 'queue', scamType ?? 'all'] as const,
    detail: (id: string) => ['moderation', 'detail', id] as const,
    evidenceUrl: (reportId: string, fileId: string) =>
      ['moderation', 'evidence-url', reportId, fileId] as const,
  },
  auth: {
    me: ['auth', 'me'] as const,
  },
} as const;
