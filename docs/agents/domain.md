# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Layout

Single-context. Domain language and architectural decisions live at the repo root:

```
/
├── CONTEXT.md                     ← domain glossary (may not exist yet)
├── docs/decisions/                ← ADRs
│   └── 0001-monorepo-structure.md
└── apps/, packages/, ...
```

## Before exploring, read these

- **`CONTEXT.md`** at the repo root — domain glossary for the project.
- **`docs/decisions/`** — read ADRs that touch the area you're about to work in.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The producer skill (`/grill-with-docs`) creates them lazily when terms or decisions actually get resolved.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR in `docs/decisions/`, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0001 (monorepo structure) — but worth reopening because…_
