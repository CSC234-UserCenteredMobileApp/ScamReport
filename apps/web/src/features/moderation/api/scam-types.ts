import { useQuery } from '@tanstack/react-query';
import { apiFetch } from '@/lib/api/client';
import { queryKeys } from '@/lib/api/query-keys';
import { validators } from '@/lib/api/validators';

export function useScamTypes() {
  return useQuery({
    queryKey: queryKeys.scamTypes.list,
    queryFn: () => apiFetch('/scam-types', validators.scamTypes),
    staleTime: 10 * 60 * 1000, // scam types rarely change
  });
}
