# GEMINI.md — ScamReport

This is a mobile product built on Flutter (app) + Elysia.js (backend on Bun) + a shared TypeBox contract package.

## Product Context

The **Scam Report Platform** is an Android-only application (MVP) that allows users to quickly verify suspicious phone numbers, URLs, or messages against a community-sourced scam database.
- **Quick Verdicts**: Returns a colour-coded verdict (Scam, Suspicious, Safe, Unknown) within 3 seconds.
- **AI Semantic Search**: Provides natural-language search over scam reports using RAG (Gemini + `pgvector`).
- **Proactive Interception**: Share-sheet and clipboard scanning features on Android.

## Architecture

The project follows a monorepo structure with three main areas:
- **`apps/mobile`**: Flutter app. Feature-first layout (`lib/features/<feature>/{data,domain,presentation}`). Uses Riverpod for state and `drift` for local SQLite caching.
- **`apps/api`**: Elysia.js + Prisma backend. Feature-first layout (`src/features/<feature>/`).
- **`packages/shared`**: TypeBox schemas shared between api and mobile.

**Core Infrastructure:**
- **Data Layer**: PostgreSQL on **Supabase** (Postgres 15) utilizing **`pgvector`** for semantic similarity search.
- **Auth & Push**: **Firebase Authentication** (Google OAuth/Email) and **Firebase Cloud Messaging (FCM)** for status change alerts and announcements.
- **AI/LLM**: **Gemini API** (`text-embedding-004`) for generating embeddings of scam reports.

## Key Documentation

Always refer to these files for detailed rules and specs:
- **`PRODUCT-REQUIREMENTS.md`**: Authoritative source for product flows, user roles, and functional requirements.
- **`DATABASE_DESIGN.md`**: Detailed schema definitions, enumerated types, and Row-Level Security (RLS) policies.
- **`docs/architecture.md`**: High-level system design, external service mapping, and cross-app workflows.
- **`HOW_TO_CONTRIBUTE.md`**: Development setup, branch conventions, and environment configuration.

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
