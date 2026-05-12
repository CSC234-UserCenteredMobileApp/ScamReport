export const queryKeys = {
  moderation: {
    all: ['moderation'] as const,
    queue: (scamType?: string) =>
      ['moderation', 'queue', scamType ?? 'all'] as const,
    detail: (id: string) => ['moderation', 'detail', id] as const,
  },
  auth: {
    me: ['auth', 'me'] as const,
  },
} as const;
