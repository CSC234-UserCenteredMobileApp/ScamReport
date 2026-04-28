# AI workflow — ScamReport

This document describes how the team uses Claude Code agents to build, review, and ship code. The workflow is designed for the CSC234 term-assignment rubric, which mandates:

- A multi-agent AI workflow with specialised roles.
- The AI that **writes** code is **not** the AI that **approves** it (writer ≠ approver).
- Every member of the team must be able to explain code their agents produced.

The agents themselves are configured in [`.claude/agents/`](../.claude/agents/). The human role split is in the team's term plan (see `~/.claude/plans/task-scaffold-flutter-greedy-curry.md` Workstreams section).

## The four agents

| Agent | File | Role | May write to |
| --- | --- | --- | --- |
| `engineer` | `.claude/agents/engineer.md` | Implements features per spec. Writes code + tests. Opens PRs. | All source + test files |
| `architect` | `.claude/agents/architect.md` | Reviews diffs against Clean-Arch / schema / design rules. | Reviews only — read-only on source |
| `qa` | `.claude/agents/qa.md` | Authors / extends test suite, runs coverage + a11y + perf gates. | Test files + quality docs only |
| `security-reviewer` | `.claude/agents/security-reviewer.md` | Audits security-touching PRs (auth, RBAC, secrets, validation, Firestore rules). | Security review docs only |

Other Claude Code agents in the project (the `feature-dev`, `superpowers`, `Explore`, `Plan` agents bundled with the harness) remain available as helpers for research and planning. They do **not** replace the four roles above for any merge-relevant decision.

## The loop — per feature

```
                ┌───────────────────────────────────────┐
                │  Plan Mode (orchestrator + architect) │
                │  → ~/.claude/plans/<task>.md          │
                └────────────┬──────────────────────────┘
                             │ approved plan
                             ▼
                ┌───────────────────────────────────────┐
                │  engineer  → branch + PR              │
                │  - writes code + tests                │
                │  - runs lint / typecheck / test       │
                └────────────┬──────────────────────────┘
                             │ PR opened (writer agent stops)
                             ▼
                ┌───────────────────────────────────────┐
                │  architect (different session)        │
                │  - audits Clean-Arch + schema         │
                │  - audits design fidelity             │
                │  - approves / requests changes        │
                └────────────┬──────────────────────────┘
                             │ if approved
                             ▼
                ┌───────────────────────────────────────┐
                │  qa (different session)               │
                │  - extends tests if gaps              │
                │  - runs coverage + a11y + perf gates  │
                │  - reports verdict                    │
                └────────────┬──────────────────────────┘
                             │ if pass
                             ▼
        ┌───────────────────────────────────────────────────┐
        │  security-reviewer (different session)             │
        │  triggered only if security surface touched        │
        │  - secret scan + auth + Firestore rules audit      │
        └────────────┬───────────────────────────────────────┘
                     │ if pass
                     ▼
                ┌─────────────────────────┐
                │  human reviewer signs off │
                │  → merge                  │
                └─────────────────────────┘
```

## Writer ≠ approver — how we enforce it

The rubric requires that a different agent (or human) approves than the one that authored. Mechanically:

1. **Every agent has a `Hard rules` section in its `.md` file forbidding it from approving its own output.** When the engineer has authored a PR, it stops. A separate Claude Code session (a fresh context, a different agent) handles the review pass.
2. **Sessions are recorded.** Each `.claude/projects/.../<session>.jsonl` is the evidence of which agent did what. On merge, the human reviewer attaches the relevant session IDs to the PR description (see PR template).
3. **PR description carries the agent trail.** Every PR's description ends with:

   ```
   Author agent: engineer · session <id>
   Architect agent: architect · session <id>
   QA agent: qa · session <id>
   Security agent: security-reviewer · session <id> (or "n/a" if no security surface)
   Human approver: <name>
   ```

4. **A PR where the same session ID appears twice in the trail is auto-rejected** by the human reviewer (rubric violation). This is the mechanical floor; the spirit is that you genuinely run different sessions.

## When each agent is invoked

| Trigger | Invoke |
| --- | --- |
| New plan needed | Plan Mode (any session); save to `~/.claude/plans/`. The orchestrator (P1) drives it. |
| Plan approved → start coding | `engineer` agent in a fresh session |
| `engineer` opened PR | `architect` agent in a different session |
| `architect` approved | `qa` agent in a different session |
| Diff touches auth / RBAC / secrets / Firestore / validation / uploads | additionally, `security-reviewer` in a different session |
| Failing CI step | `engineer` (in a new session) fixes; restart loop from architect |

## Human responsibilities (the rubric's accountability rule)

Each human owner is responsible for **explaining** the code their agents produced:

- **P1 Orchestrator** explains why the plan was structured the way it was, and why specific agent prompts were chosen. Owns this document and `CLAUDE.md`.
- **P2 Architect / Reviewer** explains every architecture choice the architect agent enforced. Owns `docs/architecture.md` and the audit report's architecture section.
- **P3 QA / Release** explains coverage numbers, accessibility findings, and any test that was added. Owns `docs/accessibility-checklist.md` + `docs/performance-budget.md`.
- **P4 Mobile Engineer** must be able to walk through any line of Flutter code in the repo on demand. Owns the audit report's mobile-implementation section.
- **P5 Backend / Security Engineer** must be able to walk through any line of API / migration / Firestore-rules code. Owns the audit report's security section.

If during the final viva a member cannot explain code in their area, the rubric says the team loses points. Treat that as the primary quality gate.

## Plan-Mode discipline

- Every non-trivial change (more than ~3 files or any new feature) starts with Plan Mode.
- Plans live in `~/.claude/plans/<task>.md`. They are versioned per task.
- The plan is approved by a human (the Architect or Orchestrator) before the `engineer` agent runs.
- On significant scope drift mid-implementation, the engineer **stops** and edits the plan, then restarts from review.

## Evidence trail

For the rubric's evidence package (see `docs/evidence/README.md`):

- `evidence/plan-mode/` — sanitised excerpts from `~/.claude/projects/<project>/<session>.jsonl`. Pick one per major feature, redacting any temporary credentials.
- `evidence/ci-runs/` — links to passing CI runs corresponding to each merged PR.
- `evidence/coverage/` — the lcov + Codecov badge state per release tag.

## When this document changes

Every time the team changes how agents are invoked or who owns what, update this file in the same PR. The audit report's "AI workflow" section is generated from this document — keeping them out of sync hurts the rubric grade.
