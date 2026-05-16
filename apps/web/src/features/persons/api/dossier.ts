import { useQuery } from '@tanstack/react-query';
import type { PersonDossierResponse } from '@my-product/shared';
import { apiFetch } from '@/lib/api/client';
import { validators } from '@/lib/api/validators';
import { queryKeys } from '@/lib/api/query-keys';

export function usePersonDossier(id: string) {
  return useQuery<PersonDossierResponse>({
    queryKey: queryKeys.persons.dossier(id),
    queryFn: () =>
      apiFetch(`/admin/persons/${id}/dossier`, validators.personDossier),
    enabled: Boolean(id),
  });
}
