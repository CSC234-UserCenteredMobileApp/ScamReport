# Architecture

## The three pieces

```
┌─────────────────┐        HTTPS / JSON         ┌─────────────────┐
│  apps/mobile    │ ──────────────────────────▶ │    apps/api     │
│  (Flutter)      │                              │  (Elysia, Bun)  │
└─────────────────┘                              └────────┬────────┘
          ▲                                               │
          │ Dart types (generated)                        │ Prisma
          │                                               ▼
          │                                        ┌─────────────┐
          │                                        │  PostgreSQL │
          │                                        └─────────────┘
          │
  ┌───────┴────────────────────────────────┐
  │          packages/shared               │
  │   TypeBox schemas = JSON Schema        │
  │   (the single source of truth)         │
  └────────────────────────────────────────┘
```

### `apps/mobile` — Flutter

- Feature-first: everything for a feature lives under `lib/features/<feature>/{data,domain,presentation}`.
- `core/` holds cross-cutting wiring: theme, router (go_router), DI (Riverpod + Firebase init), local cache (`drift`/SQLite + `shared_preferences` + `flutter_secure_storage`).
- State: Riverpod. HTTP: standard Dart client calling api with generated Dart types.

### `apps/api` — Elysia on Bun

- Feature-first: each feature lives under `src/features/<feature>/` and owns its `<feature>.route.ts` (and `<feature>.service.ts` when the route grows).
- Route files export an Elysia plugin; `src/index.ts` composes them.
- Validation via TypeBox schemas imported from `@my-product/shared` (Elysia accepts them natively).
- DB: Prisma. Schema in `prisma/schema.prisma`; client singleton at `src/core/db/client.ts`.
- Cross-cutting concerns (auth, logging) live in `src/core/middleware/` as Elysia plugins.

### `packages/shared` — the contract layer

- All request/response schemas live here as TypeBox (`@sinclair/typebox`).
- Single runtime dep: `@sinclair/typebox`.
- Exports through `src/index.ts`.
- TypeBox schemas are JSON Schema, which is what feeds the Dart codegen.

### External services

The api fans out to three external services; mobile never talks to them directly:

| Service | What it's for | Where in the api |
| --- | --- | --- |
| Firebase | Auth (verify ID tokens), FCM push, Analytics, Crashlytics | `src/core/firebase/admin.ts` and `src/core/middleware/auth.middleware.ts`. Mobile-side init in `apps/mobile/lib/core/di/firebase.dart`. |
| Supabase | Postgres host + Storage. Mobile uploads files via the api, never directly. | Postgres → Prisma (`DATABASE_URL` / `DIRECT_URL`). Storage → `src/core/supabase/`. |
| Gemini | LLM service for AI-powered features (future) | `src/core/gemini/client.ts` (`generateText(prompt)` helper). |

All three are lazy singletons — the api boots even when their env vars aren't set; the first call into a missing service throws a clear error.

## Contract-first workflow

Every endpoint starts with a schema in `packages/shared`.

```
1. Edit / add schema in packages/shared/src/schemas/<area>.ts
2. Re-export from packages/shared/src/index.ts
3. Import in apps/api/src/features/<name>/<name>.route.ts and use as body / response validator
4. Run ./scripts/codegen.sh to regenerate Dart types into apps/mobile/lib/core/api_types/
5. Consume the Dart types in apps/mobile/lib/features/<feature>/data/
```

This keeps the two apps from drifting: there is no handwritten DTO on either side.

## Where to add things

| You want to... | Go to |
| --- | --- |
| Add a new API endpoint | `/add-endpoint` slash command, or follow `HOW_TO_CONTRIBUTE.md` §4 |
| Add a new mobile feature | `/add-feature` slash command, or follow `HOW_TO_CONTRIBUTE.md` §4 |
| Change a schema | Edit `packages/shared/`, then run codegen |
| Add cross-cutting middleware | `apps/api/src/core/middleware/` |
| Add theme / routing / DI | `apps/mobile/lib/core/` |
| Change DB schema | `apps/api/prisma/schema.prisma`, then `bun run prisma:generate` and create a migration |

## Testing strategy

- **Unit tests** where the logic lives. `apps/api/test/` for routes and services; `apps/mobile/test/features/` for domain + presentation.
- **Schema tests** (optional) under `packages/shared/test/` for any schema with non-trivial refinements.
- **Integration tests** for the api run against a real Postgres (test database). Do not mock Prisma for route tests — the value is in catching schema drift.
- **Widget tests** for any `presentation/` widget with conditional rendering.

Run everything: `bun run test` from the repo root.

## Conventions

- No business logic in Flutter widgets.
- Small widgets, `const` constructors wherever possible.
- Route files stay thin — push logic into `src/features/<feature>/<feature>.service.ts` (feature-local) or `src/core/lib/` (truly cross-cutting).
- Prisma client is a singleton; never instantiate `new PrismaClient()` outside `src/core/db/client.ts`.

## Not in this repo

- iOS / Android platform folders — generated locally by `flutter create .`; not committed beyond what Flutter emits.
- Firebase config (`google-services.json`, `GoogleService-Info.plist`) — gitignored; see `HOW_TO_CONTRIBUTE.md` §3.
- CI workflows — added when the team decides on a provider.
