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
  auth: {
    me: ['auth', 'me'] as const,
  },
  scammers: {
    all: ['scammers'] as const,
    dossier: (id: string) => ['scammers', 'dossier', id] as const,
    search: (q: string) => ['scammers', 'search', q] as const,
  },
  persons: {
    all: ['persons'] as const,
    dossier: (id: string) => ['persons', 'dossier', id] as const,
  },
  platformSummary: {
    all: ['platform-summary'] as const,
    inRange: (from?: string, to?: string) =>
      ['platform-summary', from ?? 'default', to ?? 'default'] as const,
  },
  scamTypes: {
    list: ['scam-types'] as const,
  },
  reportSearch: {
    results: (q: string) => ['report-search', q] as const,
  },
} as const;
