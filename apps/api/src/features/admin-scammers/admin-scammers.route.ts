import { Elysia, t } from 'elysia';
import {
  LinkScammerRequest,
  LinkScammerResponse,
  SearchScammersResponse,
  ScammerDossierResponse,
} from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import {
  AdminScammerError,
  getDossier,
  linkScammer,
  search,
} from './admin-scammers.service';

const uuidParam = t.Object({ id: t.String({ format: 'uuid' }) });
const errorBody = t.Object({ error: t.String() });

export const adminScammersRoute = new Elysia()
  .use(requireRole('admin'))

  .get(
    '/admin/scammers/search',
    async ({ query }) => search(query.identifier, query.q),
    {
      query: t.Object({
        identifier: t.Optional(t.String()),
        q: t.Optional(t.String()),
      }),
      response: SearchScammersResponse,
    },
  )

  .get(
    '/admin/scammers/:id/dossier',
    async ({ params, set }) => {
      const dossier = await getDossier(params.id);
      if (!dossier) {
        set.status = 404;
        return { error: 'Scammer not found' };
      }
      return dossier;
    },
    {
      params: uuidParam,
      response: { 200: ScammerDossierResponse, 404: errorBody },
    },
  )

  .post(
    '/admin/reports/:id/link-scammer',
    async ({ params, body, set }) => {
      try {
        return await linkScammer(params.id, body);
      } catch (err) {
        if (err instanceof AdminScammerError) {
          set.status = err.status;
          return { error: err.message };
        }
        throw err;
      }
    },
    {
      params: uuidParam,
      body: LinkScammerRequest,
      response: { 200: LinkScammerResponse, 404: errorBody, 400: errorBody },
    },
  );
