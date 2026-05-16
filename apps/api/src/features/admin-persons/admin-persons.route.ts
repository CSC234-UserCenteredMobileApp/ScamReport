import { Elysia, t } from 'elysia';
import { PersonDossierResponse } from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { getPersonDossier } from './admin-persons.service';
import { renderPdf, shortId } from '../../core/pdf/pdf-generator';
import { personTemplate } from '../../core/pdf/templates/person';

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
  )

  .get(
    '/admin/persons/:id/pdf',
    async ({ params, set }) => {
      const dossier = await getPersonDossier(params.id);
      if (!dossier) {
        set.status = 404;
        return { error: 'Person not found' };
      }
      const bytes = await renderPdf(personTemplate(dossier));
      return new Response(bytes as BodyInit, {
        status: 200,
        headers: {
          'Content-Type': 'application/pdf',
          'Content-Disposition': `attachment; filename="scamreport-person-${shortId(dossier.person.id)}.pdf"`,
          'Cache-Control': 'no-store',
        },
      });
    },
    { params: uuidParam },
  );
