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
import { notificationsRoute } from './features/notifications/notifications.route';
import { adminNotificationsRoute } from './features/admin-notifications/admin-notifications.route';
import { adminScammersRoute } from './features/admin-scammers/admin-scammers.route';
import { adminPersonsRoute } from './features/admin-persons/admin-persons.route';
import { adminPlatformSummaryRoute } from './features/admin-platform-summary/admin-platform-summary.route';
import { adminExportsRoute } from './features/admin-exports/admin-exports.route';
import { adminAiEvalRoute } from './features/admin-ai-eval/admin-ai-eval.route';
import { adminScamOverviewRoute } from './features/admin-scam-overview/admin-scam-overview.route';

// CORS allowlist for the admin web portal (apps/web) and Flutter web dev (apps/mobile).
// Project-scoped Vercel preview pattern intentionally NOT `*.vercel.app` —
// wildcard would allow any Vercel-hosted site to call this API.
// Localhost regex covers Flutter web's random dev port plus any other local tooling.
export const WEB_ORIGINS: (string | RegExp)[] = [
  'http://localhost:5173',
  'https://scamreport-admin.vercel.app',
  /^https:\/\/scamreport-admin-[a-z0-9-]+\.vercel\.app$/,
  /^http:\/\/localhost:\d+$/,
  /^http:\/\/127\.0\.0\.1:\d+$/,
];

export const app = new Elysia()
  .use(
    cors({
      origin: WEB_ORIGINS,
      methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Authorization', 'Content-Type'],
      credentials: false,
      maxAge: 600,
    }),
  )
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
  .use(notificationsRoute)
  .use(adminNotificationsRoute)
  .use(adminScammersRoute)
  .use(adminPersonsRoute)
  .use(adminPlatformSummaryRoute)
  .use(adminExportsRoute)
  .use(adminAiEvalRoute)
  .use(adminScamOverviewRoute);

if (import.meta.main) {
  const port = Number(process.env.PORT ?? 3000);
  app.listen(port);
  console.log(`[api] listening on http://localhost:${port}`);
}
