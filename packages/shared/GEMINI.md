# GEMINI.md — `@my-product/shared`

The **contract layer** between `apps/mobile` and `apps/api`.

## Rules & Patterns

- **TypeBox only**: `@sinclair/typebox` is the only runtime dependency. All schemas must be defined with it.
- **Define schemas**: Use `Type.Object({...})`.
- **Export static types**: Export the companion TS type via `export type X = Static<typeof XSchema>;`.
- **Re-export**: Every new schema file must be re-exported from `src/index.ts`.
- **CRITICAL**: After any schema change, you MUST run `./scripts/codegen.sh` from the repo root to regenerate the mobile app's Dart types.

## Example

```ts
import { Type, type Static } from '@sinclair/typebox';

export const ThingRequest = Type.Object({
  name: Type.String({ minLength: 1 }),
});
export type ThingRequest = Static<typeof ThingRequest>;
```

## Commands

- `bun run typecheck` — type-check the package
- `bun test` — run schema tests
