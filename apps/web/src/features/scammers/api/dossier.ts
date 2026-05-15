import { useQuery } from '@tanstack/react-query';
import type { ScammerDossierResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function useScammerDossier(id: string) {
  return useQuery<ScammerDossierResponse>({
    queryKey: queryKeys.scammers.dossier(id),
    queryFn: () =>
      apiFetch(`/admin/scammers/${id}/dossier`, validators.scammerDossier),
    enabled: Boolean(id),
  });
}
