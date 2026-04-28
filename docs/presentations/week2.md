# Week-2 Demo — 2026-04-30

> Standup-style outline. Five-to-seven minutes. Speaker: P1 (Orchestrator). Audience: course staff + team self-review. Goal: prove that Sprint 1 produced a coherent foundation and that Sprint 2 has unambiguous scope.

## Agenda (~6 min)

1. **Where we are in the rubric** — 30 sec
2. **Plan freeze** — 1 min
3. **Multi-agent workflow walkthrough** — 1.5 min (key rubric line item)
4. **Design specs in repo** — 1 min
5. **Live demo: login flow on Android** — 1.5 min
6. **Sprint-2 commitments + risk register** — 30 sec

---

## 1. Rubric position

- Term assignment = "Enterprise-Grade Mobile Application", 100 pts.
- 5-week window, currently end of week 1 (started 2026-04-28). Final demo 2026-05-21.
- Stack approved by professor (Bun + Elysia + Postgres + Prisma + Flutter + Firebase Auth). Polyglot persistence achieved with **narrow Firestore mirror** (alerts + my-reports), not a full rewrite.

## 2. Plan freeze

Approved plan locked at `~/.claude/plans/task-scaffold-flutter-greedy-curry.md`. Highlights:

- 4 sprints; Sprint 2 = foundations (RBAC, CI gates, biometric, Verdict + Feed).
- 5-person role split (Orchestrator / Architect / QA / Mobile / Backend-Security).
- 10 locked decisions cover platform scope, persistence, anonymisation, coverage target.

Show the **doc-sync map** table from the plan — every code change carries the matching `.md` updates in the same PR.

## 3. Multi-agent workflow (rubric weight: high)

Walk through the loop in `docs/ai-workflow.md`:

```
Plan Mode → engineer → architect → qa → security-reviewer → human approver → merge
```

Key claim — **writer ≠ approver, mechanically enforced**:

- 4 agent definitions in `.claude/agents/` (engineer, architect, qa, security-reviewer)
- Every PR description ends with the agent-trail block (session IDs)
- A PR where the same session ID appears twice is auto-rejected by the human reviewer

**Demo artifact:** show one example `.claude/agents/architect.md` "Hard rules" section + a sample PR description with session IDs filled in.

## 4. Design specs in repo

Per-screen specs already distilled into `docs/design/`. Cover what each contains (layout / states / interactions / role variants) and the alignment with PRD §4 IDs (P-01..A-03).

Highlight the **OQ-1 override** in `docs/design-review.md`: the prototype's `User_3a91`-style mask is rejected in favour of full reporter anonymisation in admin views (PRD v1.2 FR-7.4 + FR-7.8).

## 5. Live demo — Android login flow

- Cold-start the app on a Pixel 5 emulator profile.
- Show: Splash → Login (P-01) → Email + Google buttons → register flow (P-02) → land on placeholder home.
- Theme already implements the warm coral palette and `VerdictPalette` extension; show one verdict colour to seed the visual identity.
- Web build not in this demo (S3 work).

## 6. Sprint-2 commitments

| # | Workstream item | Owner | Verifies via |
| --- | --- | --- | --- |
| 1 | RBAC middleware + tests | P5 | unit test |
| 2 | `POST /check` schema + route + verdict screen P-13 | P5 + P4 | route test + widget test |
| 3 | Verified Feed P-03 (Postgres-read) | P4 | widget test |
| 4 | go_router redirect for `/mod` + `/admin/*` | P4 | router test |
| 5 | CI coverage gate (≥ 80%) added | P3 | failing PR proof |
| 6 | `.github/workflows/security.yml` (gitleaks + bun audit + dart analyze) | P3 + P5 | green CI run |
| 7 | Biometric service + Settings toggle | P4 | manual test |

### Risks

- Codecov vs alternative — confirm by mid-S2 (open follow-up #2 in plan).
- Firebase project ownership / billing — open follow-up #1.
- Cache + emulator performance during the demo — record a fallback screencap.

---

## Slides outline (if making a deck)

1. Title + sprint number + date
2. Rubric position
3. Plan-freeze table (decisions)
4. Multi-agent diagram + agent-trail example
5. Doc-sync map
6. Design specs preview
7. Live-demo placeholder slide
8. Sprint-2 commitments
9. Risks + open questions
10. Q&A
