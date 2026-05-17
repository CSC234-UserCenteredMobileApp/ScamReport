import { Elysia } from 'elysia';
import { AdminScamOverviewResponse } from '@my-product/shared';
import { requireRole } from '../../core/middleware/require_role';
import { getScamOverview } from './admin-scam-overview.service';

export const adminScamOverviewRoute = new Elysia()
  .use(requireRole('admin'))
  .get('/admin/scam-overview', () => getScamOverview(), {
    response: AdminScamOverviewResponse,
  });
