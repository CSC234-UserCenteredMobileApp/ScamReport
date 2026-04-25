# GEMINI.md — ScamReport

This is a mobile product built on Flutter (app) + Elysia.js (backend on Bun) + a shared TypeBox contract package.

## Architecture

- **`apps/mobile`**: Flutter app. Feature-first layout (`lib/features/<feature>/{data,domain,presentation}`).
- **`apps/api`**: Elysia.js + Prisma backend. Feature-first layout (`src/features/<feature>/`).
- **`packages/shared`**: TypeBox schemas shared between api and mobile.

## Contract-first Workflow

Every endpoint starts with a schema in `packages/shared`.
1. Edit/add schema in `packages/shared/src/schemas/<area>.ts`.
2. Re-export from `packages/shared/src/index.ts`.
3. Import in `apps/api/src/features/<name>/<name>.route.ts` and use as a validator.
4. **CRITICAL:** Run `./scripts/codegen.sh` from the repo root to regenerate Dart types into `apps/mobile/lib/core/api_types/`.
5. Consume the Dart types in `apps/mobile/lib/features/<feature>/data/`.

## Top-level Commands (run from repo root)

| Command | Purpose |
| --- | --- |
| `bun install` | Install all workspace deps |
| `bun run dev` | Run api + mobile concurrently |
| `bun run test` | Run all tests across workspaces |
| `bun run typecheck` | Typecheck shared + api |
| `bun run lint` | Run `dart analyze` on mobile |
| `bun run prisma:generate` | Generate Prisma client |

## Testing Expectations (PR Checklist)

- **api:** `bun --filter @my-product/api test` must pass if api was touched.
- **mobile:** `cd apps/mobile && dart analyze && flutter test` must pass if mobile was touched.
- **Manual:** Manually exercise the affected flow on at least one platform.

## Workspace Specific Rules

When working within a specific app, make sure to read its local `GEMINI.md`:
- `apps/api/GEMINI.md`
- `apps/mobile/GEMINI.md`
- `packages/shared/GEMINI.md`
