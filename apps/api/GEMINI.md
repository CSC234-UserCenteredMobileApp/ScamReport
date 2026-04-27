# GEMINI.md — `apps/api`

Elysia.js backend on Bun. **Feature-first layout**.

## Layout & Patterns

- **Feature-first**: A feature lives in `src/features/<feature>/` and owns its route (`<feature>.route.ts`), service (`<feature>.service.ts`), and tests.
- **Route files are plugins**: `<feature>.route.ts` exports `new Elysia().get/post(...)`. `src/index.ts` composes them.
- **Validation**: Import TypeBox schemas from `@my-product/shared` and pass them as `body` / `response`.
- **Prisma (v7)**: Import `getPrisma()` from `../../core/db/client` inside a handler. It is a lazy singleton. Use `DATABASE_URL` for driver adapter and `DIRECT_URL` for migrations (set in `prisma.config.ts`).
- **Services**: Extract logic into `<feature>.service.ts` if a route's handler grows.
- **Middleware**: Cross-cutting plugins live in `src/core/middleware/`. Use `auth.middleware.ts` for Bearer ID token validation. **Note**: Middleware must be manually attached to routes via `.use(requireAuth)`.

## External Services

Integrations live in `src/core/` and use lazy singletons that boot only on first use:
- **Firebase Admin**: `core/firebase/admin.ts` (ID token verification, FCM).
- **Supabase**: `core/supabase/client.ts` (storage helpers).
- **Gemini**: `core/gemini/client.ts` (Gemini SDK client).

## Adding a new route

1. Define/extend TypeBox schema in `packages/shared`.
2. Create `src/features/<feature>/<feature>.route.ts` exporting an Elysia plugin, using the shared schema.
3. Register the plugin in `src/index.ts` with `.use(xRoute)`.
4. Add a test in `test/<name>.test.ts` or co-located. Tests should use `app.handle(new Request(...))`.

## Commands

- `bun run dev` — start server with watch mode
- `bun test` — run tests
- `bun --filter @my-product/api test` — run specific api tests
- `bun run typecheck` — `tsc --noEmit`
- `bun run prisma:generate` — regenerate Prisma client (outputs to `src/generated/prisma/`)
- `bun run prisma:migrate` — create / apply a migration
