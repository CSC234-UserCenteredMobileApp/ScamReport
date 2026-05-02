# CLAUDE.md — `apps/api`

Elysia.js backend on Bun. **Feature-first layout** mirroring the mobile app: a feature lives in `src/features/<feature>/` and owns its route, service, and (eventually) tests. Cross-cutting pieces live in `src/core/`.

## Layout

```
apps/api/
├── prisma.config.ts                  # Prisma v7 CLI config (migrations URL = DIRECT_URL)
├── prisma/schema.prisma              # datasource has only `provider`; URLs live elsewhere
└── src/
    ├── index.ts                      # app composition, .use(…) chain
    ├── generated/prisma/             # gitignored — output of `bun run prisma:generate`
    ├── features/
    │   └── <feature>/
    │       ├── <feature>.route.ts    # Elysia plugin (required)
    │       ├── <feature>.service.ts  # business logic (add when the route grows)
    │       └── <feature>.test.ts     # optional, co-located (see "Tests" below)
    └── core/
        ├── db/client.ts              # `getPrisma()` lazy singleton (uses @prisma/adapter-pg)
        ├── firebase/admin.ts         # firebase-admin App singleton (verifies ID tokens, sends FCM)
        ├── supabase/
        │   ├── client.ts             # SupabaseClient singleton (service role)
        │   └── storage.ts            # uploadFile / getSignedUrl / deleteFile helpers
        ├── gemini/client.ts          # Gemini SDK singleton + generateText(prompt) + embed(text) helpers
        ├── middleware/
        │   └── auth.middleware.ts    # Bearer ID token → request.user (defined; not yet attached)
        └── lib/                      # shared utils
```

## Patterns

- **Route files are plugins.** `<feature>.route.ts` exports `new Elysia().get/post(...)`. `src/index.ts` composes them via `.use(…)`.
- **Validation via shared schemas.** Import from `@my-product/shared` and pass as `body` / `response`. Elysia validates at runtime and types at compile time.
- **Prisma (v7).** Import `getPrisma()` from `../../core/db/client` and call it inside a handler — the singleton boots lazily on first call. Two URLs: `DATABASE_URL` (pooled, runtime, used by the driver adapter) and `DIRECT_URL` (direct, migrations only, set in `prisma.config.ts`). Re-run `bun run prisma:generate` whenever you edit `schema.prisma`; it emits to `src/generated/prisma/` (gitignored).
- **Middleware.** Cross-cutting Elysia plugins live in `src/core/middleware/` and are wired in `src/index.ts`. `auth.middleware.ts` is wired but not yet attached to any route — `.use(requireAuth)` from a feature route to gate it.
- **Services.** If a route's handler grows beyond a few lines or touches the DB in multiple places, extract into `<feature>.service.ts` alongside the route.
- **External services.** Firebase Admin (`core/firebase/admin.ts`), Supabase (`core/supabase/client.ts`) and Gemini (`core/gemini/client.ts`) are lazy singletons — they only read env vars on first use, so the api boots cleanly even when those vars aren't set yet.

## Adding a new route

1. Add or extend the TypeBox schema in `packages/shared/src/schemas/<area>.ts` and re-export from `packages/shared/src/index.ts`.
2. Create `src/features/<feature>/<feature>.route.ts` exporting an Elysia plugin. Use the shared schema as `body` / `response`.
3. Register the plugin in `src/index.ts` with `.use(xRoute)`.
4. Add a test (see "Tests" below).

## Tests

For now tests live at `apps/api/test/<name>.test.ts` and call `app.handle(new Request(...))`. Once real features accumulate tests, the team can decide whether to co-locate them as `src/features/<feature>/<feature>.test.ts`. Either is fine — just pick one and be consistent.

## Commands

- `bun run dev` — server with `--watch`
- `bun test` — run tests
- `bun run typecheck` — `tsc --noEmit`
- `bun run prisma:generate` — regenerate the Prisma client after editing `schema.prisma`
- `bun run prisma:migrate` — create / apply a migration
