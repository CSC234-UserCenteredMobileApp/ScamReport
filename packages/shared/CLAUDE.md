# CLAUDE.md — `@my-product/shared`

This package is the **contract layer** between `apps/mobile` and `apps/api`. All request/response schemas live here as TypeBox, and both apps import from here so they can't drift apart.

## Rules

- **TypeBox only.** `@sinclair/typebox` is the only runtime dependency. Don't add validation libs, HTTP clients, or anything else here.
- Schemas are defined with `Type.Object({...})` and the companion TS type is exported via `type X = Static<typeof XSchema>`.
- Every new schema file is re-exported from `src/index.ts`.
- When a schema changes, run `./scripts/codegen.sh` from the repo root so the mobile app's Dart types regenerate.

## Pattern

```ts
import { Type, type Static } from '@sinclair/typebox';

export const ThingRequest = Type.Object({
  name: Type.String({ minLength: 1 }),
});
export type ThingRequest = Static<typeof ThingRequest>;

export const ThingResponse = Type.Object({
  id: Type.String(),
  createdAt: Type.String({ format: 'date-time' }),
});
export type ThingResponse = Static<typeof ThingResponse>;
```

The api imports these directly as Elysia validators:

```ts
.post('/things', handler, { body: ThingRequest, response: ThingResponse })
```

## Commands

- `bun run typecheck` — type-check the package
- `bun test` — run schema tests (when present)
