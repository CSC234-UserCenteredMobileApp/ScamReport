# CLAUDE.md — ScamReport

Mobile product built on Flutter (app) + Elysia.js (backend on Bun) + a shared TypeBox contract package. Schemas live once in `packages/shared` and are imported by the API as Elysia validators; the mobile app gets Dart types via codegen.

## Layout

- `apps/mobile/` — Flutter app (feature-first: `core/` + `features/<feature>/{data,domain,presentation}`)
- `apps/api/` — Elysia.js + Prisma backend
- `packages/shared/` — TypeBox schemas shared between api and mobile (contract layer)
- `scripts/` — `dev.sh` (runs api + mobile), `codegen.sh` (TypeBox → Dart)
- `docs/` — architecture + ADRs

## Working on a single app — read this

Start Claude **inside** the app you're editing so only its `CLAUDE.md` loads:

```bash
cd apps/api && claude
cd apps/mobile && claude
cd packages/shared && claude
```

Starting from the repo root loads this file only — fine for cross-cutting changes, wasteful for single-app work.

## Top-level commands (run from repo root)

| Command | Purpose |
| --- | --- |
| `bun install` | Install all workspace deps |
| `bun run dev` | Run api + mobile concurrently |
| `bun run test` | Run all tests across workspaces |
| `bun run typecheck` | Typecheck shared + api |
| `bun run lint` | Run `dart analyze` on mobile |
| `bun run prisma:generate` | Generate Prisma client |

## Details

Stack overview, contract-first workflow, and testing strategy live in [`docs/architecture.md`](./docs/architecture.md). Don't inline that here.
