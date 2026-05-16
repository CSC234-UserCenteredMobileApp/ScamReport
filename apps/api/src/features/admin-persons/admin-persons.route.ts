import { Elysia, t } from 'elysia';
import { PersonDossierResponse } from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { getPersonDossier } from './admin-persons.service';

const uuidParam = t.Object({ id: t.String({ format: 'uuid' }) });
const errorBody = t.Object({ error: t.String() });

export const adminPersonsRoute = new Elysia()
  .use(requireRole('admin'))

  .get(
    '/admin/persons/:id/dossier',
    async ({ params, set }) => {
      const dossier = await getPersonDossier(params.id);
      if (!dossier) {
        set.status = 404;
        return { error: 'Person not found' };
      }
      return dossier;
    },
    {
      params: uuidParam,
      response: { 200: PersonDossierResponse, 404: errorBody },
    },
  );
