import { Elysia } from 'elysia';
import { cors } from '@elysiajs/cors';
import { healthRoute } from './features/health/health.route';
import { authRoute } from './features/auth/auth.route';
import { statsRoute } from './features/stats/stats.route';
import { announcementsRoute } from './features/announcements/announcements.route';
import { reportsRoute } from './features/reports/reports.route';
import { adminReportsRoute } from './features/admin-reports/admin-reports.route';
import { adminAnnouncementsRoute } from './features/admin-announcements/admin-announcements.route';
import { checkRoute } from './features/check/check.route';
import { askAiRoute } from './features/ask-ai/ask-ai.route';
import { scamTypesRoute } from './features/scam-types/scam-types.route';
import { userRoute } from './features/user/user.route';

export const app = new Elysia()
  .use(cors())
  .use(healthRoute)
  .use(authRoute)
  .use(statsRoute)
  .use(announcementsRoute)
  .use(reportsRoute)
  .use(adminReportsRoute)
  .use(adminAnnouncementsRoute)
  .use(checkRoute)
  .use(askAiRoute)
  .use(scamTypesRoute)
  .use(userRoute);

if (import.meta.main) {
  const port = Number(process.env.PORT ?? 3000);
  app.listen(port);
  console.log(`[api] listening on http://localhost:${port}`);
}
