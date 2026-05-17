export const queryKeys = {
  moderation: {
    all: ['moderation'] as const,
    queues: ['moderation', 'queue'] as const,
    queue: (p: {
      q?: string;
      status?: string;
      priority?: string;
      confidence?: string;
      scam_type?: string;
      page: number;
      page_size: number;
    }) =>
      [
        'moderation',
        'queue',
        p.q ?? '',
        p.status ?? 'all',
        p.priority ?? 'all',
        p.confidence ?? 'all',
        p.scam_type ?? 'all',
        p.page,
        p.page_size,
      ] as const,
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
  aiEval: {
    all: ['ai-eval'] as const,
    latest: ['ai-eval', 'latest'] as const,
    history: (limit: number) => ['ai-eval', 'history', limit] as const,
  },
  scamOverview: {
    all: ['scam-overview'] as const,
  },
} as const;
