# CLAUDE.md — ScamReport

Mobile product built on Flutter (app) + Elysia.js (backend on Bun) + a shared TypeBox contract package. Schemas live once in `packages/shared` and are imported by the API as Elysia validators; the mobile app gets Dart types via codegen.

## Layout

- `apps/mobile/` — Flutter app (feature-first: `core/` + `features/<feature>/{data,domain,presentation}`)
- `apps/api/` — Elysia.js + Prisma backend
- `packages/shared/` — TypeBox schemas shared between api and mobile (contract layer)
- `scripts/` — `dev.sh` (runs api + mobile), `codegen.sh` (TypeBox → Dart)
- `docs/` — architecture + ADRs + per-screen design specs (`docs/design/index.md`)

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

## Design

Tokens live in `apps/mobile/lib/core/theme/app_theme.dart` (warm coral primary, `VerdictPalette` extension). Per-screen specs live in [`docs/design/`](./docs/design/index.md). For a feature implementation task, load `docs/design-review.md` (tokens + inventory) plus the relevant `docs/design/screens/<screen>.md` — do **not** open the prototype HTML in `~/Documents/`; it's 1.4 MB per role and already distilled into the spec docs.

## Multi-agent workflow

The project uses four specialised Claude Code agents — `engineer`, `architect`, `qa`, `security-reviewer` — defined in [`.claude/agents/`](./.claude/agents/). Per the term-assignment rubric, the AI that **writes** code may not be the AI that **approves** it: the engineer ships a PR, then a fresh session running the architect agent reviews it, the qa agent extends tests + runs gates, and the security-reviewer agent audits any PR touching auth / RBAC / Firestore / secrets / validation. A human approver signs off last.

Full loop, per-agent rules, and evidence-trail conventions live in [`docs/ai-workflow.md`](./docs/ai-workflow.md). Plan-Mode discipline + the team's role split are described there as well. Update both this section and `docs/ai-workflow.md` in the same PR whenever the workflow changes.
