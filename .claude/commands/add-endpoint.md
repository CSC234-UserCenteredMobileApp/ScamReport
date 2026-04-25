---
description: Add a new API endpoint end-to-end (shared schema → feature route → register → test)
---

Add a new API endpoint for: $ARGUMENTS

Follow these steps in order:

1. **Define the contract** in `packages/shared/src/schemas/`.
   - Create or extend a file in `packages/shared/src/schemas/<area>.ts`.
   - Export TypeBox schemas for the request body (if any) and the response using `Type.Object({...})` from `@sinclair/typebox`.
   - Export the inferred TS type via `type Foo = Static<typeof FooSchema>`.
   - Re-export from `packages/shared/src/index.ts`.

2. **Create the route plugin** at `apps/api/src/features/<feature>/<feature>.route.ts`.
   - Export an Elysia plugin: `export const xRoute = new Elysia().get/post(...)`.
   - Import schemas from `@my-product/shared` and pass them as `body` / `response`.
   - For DB access: `import { prisma } from '../../core/db/client';`
   - If the handler grows, extract logic into `apps/api/src/features/<feature>/<feature>.service.ts`.

3. **Register the plugin** in `apps/api/src/index.ts` by adding `.use(xRoute)` to the app chain.

4. **Write a test** at `apps/api/test/<name>.test.ts` that calls the route via `app.handle(new Request(...))` and asserts status + body shape.

5. **Regenerate Dart types** so the mobile app sees the new schema:
   ```bash
   ./scripts/codegen.sh
   ```

6. **Verify:**
   - `bun run typecheck`
   - `bun test` in `apps/api`

Before you start, read `apps/api/CLAUDE.md` for the feature-first conventions and `packages/shared/CLAUDE.md` for the contract rules.
