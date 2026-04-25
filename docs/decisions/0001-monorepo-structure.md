# ADR 0001: Monorepo structure

- **Status:** Accepted
- **Date:** 2026-04-24

## Context

We're building a mobile product with a Flutter client, a Bun-based Elysia.js backend, and shared contracts between them. Before writing features we needed to decide: one repo or three? If one, how should it be organised?

## Decision

1. **Single monorepo** with Bun workspaces.
2. **Three top-level areas:** `apps/mobile`, `apps/api`, `packages/shared`.
3. **Feature-first layout** inside `apps/mobile` (each feature owns its `data/domain/presentation` slice).
4. **Contract-first development** — every request/response has a TypeBox schema in `packages/shared` before any route or UI code is written. Dart types on the mobile side are generated, not handwritten.

## Rationale

### Why monorepo

- The three pieces ship together — an API change and its matching mobile change belong in one PR, reviewed once.
- Shared contracts need atomic updates across producer (api) and consumers (api + mobile). Separate repos push that coordination into release engineering; a monorepo makes it a single commit.
- The dev experience is better: one `bun install`, one `bun run dev`, one place for docs and ADRs.

### Why feature-first in Flutter

- The alternative (layered: `lib/models/`, `lib/screens/`, `lib/services/`) scales badly. Any non-trivial feature ends up touching five directories, and removing a feature is archaeology.
- Feature-first makes each feature a self-contained unit: move it, delete it, or extract it to a package later without ripple edits.
- `core/` carries the truly cross-cutting wiring (theme, router, DI) — the small subset that really is shared.

### Why TypeBox in `packages/shared` as the contract layer

- Elysia uses TypeBox natively for runtime validation. Schemas defined once work directly as route validators — no adapter layer.
- TypeBox schemas ARE JSON Schema, which makes Dart codegen straightforward (e.g. `quicktype --src-lang schema --lang dart`). Zod would have needed a conversion step.
- Zero-dep constraint on `packages/shared` (other than `@sinclair/typebox`) means the contract package is cheap to import anywhere in the monorepo.

## Consequences

- **Workflow discipline:** contributors must update `packages/shared` and run codegen before mobile changes. This is documented in `HOW_TO_CONTRIBUTE.md` and baked into `/add-endpoint`.
- **Bun lock-in on the backend:** scripts and workspaces assume Bun. Swapping to Node later would mean rewriting scripts and re-testing Elysia's Bun-specific code paths.
- **No per-package versioning.** The monorepo ships together; we don't version `packages/shared` separately.
- **Extraction is still possible.** Feature-first Flutter and a standalone `packages/shared` both leave clean seams if we ever want to split.

## Alternatives considered

- **Separate repos** — rejected; see rationale above.
- **Zod in shared** — rejected; requires conversion to produce Dart types and duplicates what Elysia already does with TypeBox.
- **Layered Flutter (`lib/models/`, `lib/screens/`, …)** — rejected; doesn't scale past a handful of features.
- **Drizzle instead of Prisma** — considered for raw speed on Bun, rejected for this team because Prisma's migration workflow and ergonomics fit the team's familiarity better.
