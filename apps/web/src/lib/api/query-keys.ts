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
  announcements: {
    all: ['announcements'] as const,
    list: ['announcements', 'list'] as const,
    detail: (id: string) => ['announcements', 'detail', id] as const,
  },
  notifications: {
    subscriberCount: ['notifications', 'subscriber-count'] as const,
  },
  deletionRequests: {
    all: ['deletion-requests'] as const,
    list: (status?: string) =>
      ['deletion-requests', 'list', status ?? 'all'] as const,
  },
  auth: {
    me: ['auth', 'me'] as const,
  },
} as const;
