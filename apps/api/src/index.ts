import { Elysia } from 'elysia';
import { cors } from '@elysiajs/cors';
import { healthRoute } from './features/health/health.route';
import { exampleRoute } from './features/example/example.route';

export const app = new Elysia()
  .use(cors())
  .use(healthRoute)
  .use(exampleRoute);

if (import.meta.main) {
  const port = Number(process.env.PORT ?? 3000);
  app.listen(port);
  console.log(`[api] listening on http://localhost:${port}`);
}
