# ScamReport — Final Pitch Deck

**Audience:** industry committee + technical commentators
**Duration:** 10–15 min + Q&A
**Format:** Google Slides (paste each "Slide" block into a slide; "Script" goes in the speaker-notes pane)
**Presenter:** solo, rotating between three orchestration personas

Roles for this deck (use whichever framing you prefer on Slide 2):
- **The Orchestrator** — plan, decompose, delegate
- **The Architect / Reviewer** — design specs, ADRs, review gates
- **The QA / Release Engineer** — tests, coverage, observability, rollback

Total slide count target: **14–16 slides**. Each minute of talk ≈ 1–1.5 slides.

---

## Section 1 — Title & Team Introduction (1 min)

### Slide 1 — Title

```
ScamReport
Community-powered scam intelligence for Thailand

Final pitch · CSC234 · 2026
[Your name] — Orchestrator · Architect · QA
```

Visual: app logo (or warm-coral splash from `app_theme.dart`) on the left, screenshot of the feed on the right.

### Slide 2 — How I built this

Three orchestration personas, one human:

| Persona | What they did |
|---|---|
| Orchestrator | Plan mode, task decomposition, agent dispatch |
| Architect / Reviewer | ADRs, design specs, PR gating |
| QA / Release | Test authoring, coverage, Crashlytics, rollback |

> "AI that **writes** code may not **approve** it." — `docs/ai-workflow.md`

### Script — Section 1 (≈60s)

> Good morning. I'm [Name], and over the next twelve minutes I'll walk you through ScamReport — a community-powered scam intelligence app for Thailand — and, just as importantly, **how** it was built. Because the engineering story here is not "I wrote a Flutter app." It's "I ran a small AI engineering team."
>
> I played three roles. As the **Orchestrator** I broke each feature down in plan mode before any code was written. As the **Architect and Reviewer** I authored design specs and ADRs, and I gated every pull request — including the ones the AI wrote. As the **QA and Release Engineer** I owned test coverage, Crashlytics, and the rollback plan. The hard rule I borrowed from our team workflow doc is on the slide: *AI that writes code may not approve it.* That single constraint shaped everything else.

---

## Section 2 — The Problem & Business Solution (2 min)

### Slide 3 — The Enterprise Challenge

- Thailand recorded **~600,000 cybercrime complaints** in the last reporting cycle (Royal Thai Police data — verify your exact citation before the talk).
- Most scam intelligence today lives in **closed group chats** — Line, Facebook, family threads. Knowledge dies with each conversation.
- Banks and telcos have data but no consumer-facing channel for **citizen reports** to flow back into shared intelligence.
- **Pain point**: a victim today has nowhere to (a) check a number/URL/account in 5 seconds, (b) report it once, or (c) learn from what others have already flagged.

### Slide 4 — The Solution: ScamReport

Three core loops:

1. **Check** — paste a phone number, URL, or bank account → AI verdict + community history.
2. **Report** — one-tap submission with AI-assisted drafting; goes to moderator queue.
3. **Stay informed** — verified feed of recent scams + push alerts from official sources.

Backed by:
- **Admin moderation portal** (web) — moderators triage submissions before they hit the public feed.
- **Real-time alerts** mirrored to mobile via Firestore for offline-first reads.

### Slide 5 — Target Users & Personas

| Persona | Need |
|---|---|
| **Aunty Som, 58, Bangkok** | Wants to check a "tax refund" SMS before clicking. Reads Thai only. |
| **Tee, 24, university student** | Got scammed once; wants to warn others and look up sellers. |
| **Khun Wirat, moderator, NGO partner** | Reviews 50–100 submissions a day via the web admin portal. |

Design evidence: per-screen specs under `docs/design/` — built from prototype HTML, distilled into `docs/design-review.md`.

### Script — Section 2 (≈2 min)

> Thailand has a scam problem the size of a small country's GDP. Hundreds of thousands of complaints per year, and most of the intelligence lives in private Line groups — your aunt warns her friends, your friends warn each other, and three days later the same scammer hits someone in the next neighbourhood who never got the message.
>
> Banks and telcos have data, but no consumer-facing pipe. Victims today have nowhere to do three obvious things: **check** before they click, **report** when they get hit, and **stay informed** when official agencies push alerts.
>
> ScamReport is those three loops. Check, report, stay informed — plus a moderator-only web portal where our NGO partners triage submissions before they go public. We designed for three personas: a 58-year-old Thai speaker who reads SMS on a phone with one bar of signal, a 24-year-old who wants to fight back after being scammed, and the moderator on the other end of the queue. Every screen in the app was specced before code was written — those specs live in `docs/design/` and were the input to every implementation prompt.

---

## Section 3 — Live Application Demonstration (3–4 min)

**Pre-demo checklist** (do this 5 minutes before talk):
- Backend running: `bun run dev` from repo root → `http://localhost:3000` healthy.
- Android emulator: ScamReport installed, logged out, fresh state.
- Chrome tab: Flutter web build OR `flutter run -d chrome` on second monitor.
- Admin web (`apps/web`): logged in as moderator, queue has 2–3 pending reports.
- Browser tab pre-loaded: GitHub repo, `firestore.rules`, Crashlytics dashboard.

### Slide 6 — Demo Map

```
Android phone               Web (Chrome)              Admin portal
    │                            │                         │
1. Login (email + pw)            │                         │
2. Feed (verified scams) ◀─── live Firestore mirror ────── │
3. Submit a report ──────────────POST /reports ──────────▶ Postgres
                                                            │
                                                  4. Moderator approves
5. Push notification ◀─────── FCM ─────────────────────────│
6. My Reports (mirror) ◀──── Firestore listener ────────── │
```

### Demo script — talk while you click (≈3:30)

**[Phone]** Log in as Aunty Som's account. *"Standard Firebase Auth — email and password. We didn't ship biometric for this build; that's on the roadmap."*

**[Phone]** Land on the feed. *"This is the verified feed — every card here was reviewed by a moderator. The data is read from a Firestore mirror, which means…"* — toggle **airplane mode**. *"…the feed still works offline. The mirror is populated by our backend; the mobile app never writes to Firestore directly. Postgres remains the system of record."*

**[Phone]** Turn data back on. Open **Check** → paste a known-bad number. *"AI scores it, shows community history, suggests next steps. The AI call is server-side Gemini — never client-side, so we never ship an API key in the app binary."*

**[Phone]** Tap **Report** → fill the form → submit. *"This goes over HTTPS to our Elysia API. The schema is validated on the server with TypeBox — same schema that generated the Dart types you just saw the form use."*

**[Web admin]** Switch screens. Show the moderation queue → approve the report you just submitted. *"Moderator sees it instantly. Approve. That handler then calls `mirrorMyReport` and `mirrorAlert` — the reporter's mobile sees their status flip from pending to verified in real time."*

**[Phone]** Show the push notification arrive → tap into "My Reports". *"Status changed. Push delivered by FCM. End-to-end loop, under sixty seconds."*

**[Chrome web]** Switch tab. *"Same Flutter codebase running in the browser. The web build deliberately omits report submission and the admin screens — public surface only. The CORS allowlist on our API was the bug we shipped the morning of this presentation; one-line regex fix, PR #94 if you want to see it."*

**[Optional A11y beat — 20s if time allows]** Pull up Android Settings → Display Size → bump to "Largest" → return to app. *"Text scales. Tap targets stay over 48dp. We use semantic widgets for the AI score card and filter chips so TalkBack reads the verdict correctly."*

---

## Section 4 — Multi-Agent AI Orchestration (2–3 min)

### Slide 7 — Four agents, one human gate

```
            ┌──────────────┐
   prompt ──▶  Orchestrator │  plan mode · task decomposition
            └──────┬───────┘
                   │
         ┌─────────┼──────────┐
         ▼         ▼          ▼
     ┌──────┐ ┌────────┐ ┌──────────┐
     │ Eng. │ │ Archi- │ │   QA     │
     │      │ │ tect   │ │          │
     └───┬──┘ └────┬───┘ └────┬─────┘
         │        │           │
         └────────┴───────────┘
                  │
                  ▼
            ┌──────────┐
            │ Security │  PRs touching auth/RBAC/secrets
            └────┬─────┘
                 │
                 ▼
            ┌──────────┐
            │  Human   │ ◀── final approval, always
            └──────────┘
```

Defined in `.claude/agents/`. Workflow documented in `docs/ai-workflow.md`.

### Slide 8 — Plan Mode in practice

Real example — "add forgot-password flow":

1. **Orchestrator** wrote a plan: 4 tasks (route, screen, email template, test).
2. **Architect** reviewed the plan against the design spec → flagged that the screen needed Thai/English ARB entries and a rate-limit on the API.
3. **Engineer** implemented; opened PR.
4. **Architect (fresh session)** reviewed the diff → found one Riverpod provider leaking across layers; sent it back.
5. **QA** authored the widget test for the success/error states + ran `bun run test`.
6. **Human** (me) merged.

### Slide 9 — What the human caught that AI missed

| AI Reviewer noticed | Human caught additionally |
|---|---|
| Lint, type errors, obvious dead code | **Architectural drift** — a `presentation/` widget importing `data/` directly (skipping `domain/`) |
| Missing test files | **Cross-feature coupling** — two features both writing to the same Riverpod state without an explicit contract |
| Hardcoded strings | **Translation parity** — string added to `app_en.arb` only, not `app_th.arb`; lint doesn't catch it |
| Obvious secrets | **Indirect secrets** — a debug log line printing the full Firebase ID token in `debugPrint`. Subtle. |

### Script — Section 4 (≈2:30)

> The differentiator I want to spend a moment on is how this was built. I ran four specialised agents — Engineer, Architect, QA, Security — defined as role-scoped prompts in `.claude/agents/`. Every feature went through the same loop.
>
> Take "forgot password," which we shipped two weeks ago. The Orchestrator agent decomposed it into four tasks. The Architect agent reviewed the **plan**, not the code — and immediately flagged two things I hadn't thought about: it needed Thai and English string entries, and the API needed a rate limit so we don't become someone's password-reset DDoS. The Engineer wrote the code, and then — this is the critical step — a **fresh** Architect session reviewed the diff. Fresh, because the writing agent has a context bias toward defending its own choices. QA added the widget test. I, the human, signed off last.
>
> What did I catch that the AI Reviewer missed? Three patterns. First — and most often — **architectural drift**. A widget importing a repository directly, skipping the domain layer. The AI doesn't enforce the dependency arrow; the human does. Second, **translation parity** — a string added to `app_en.arb` but not `app_th.arb`. Lint won't catch that; users will. Third, the subtle one — a `debugPrint` line that logged the full Firebase ID token. Not a hardcoded secret, but a secret leak in a debug path. The pattern I learned: AI is excellent at the **local** review, the line-by-line audit. Humans are still better at the **systemic** review — does this fit how the rest of the codebase thinks?

---

## Section 5 — Enterprise Architecture & Data Modeling (2 min)

### Slide 10 — Clean Architecture, enforced

```
   presentation/ ─────▶ domain/ ◀───── data/
   (Riverpod,            (pure Dart,    (Firestore SDK,
    widgets,              entities,      HTTP, drift)
    go_router)            use-cases)
```

The arrow direction is the rule. PR's that violate it fail the Architect-agent review. From `docs/architecture.md`:

- `presentation/` never imports `data/` directly.
- `domain/` is pure Dart — no Flutter, no Firestore.
- `data/` implements interfaces declared in `domain/`.

### Slide 11 — System diagram (real one from `docs/architecture.md`)

```
┌────────────┐   HTTPS/JSON   ┌────────────┐   Prisma   ┌────────────┐
│  Flutter   │ ─────────────▶ │  Elysia    │ ─────────▶ │ Postgres   │
│  Android+  │                │  (Bun)     │            │ (Supabase) │
│  Web       │                └─────┬──────┘            └────────────┘
└─────┬──────┘                      │
      │                             ├─▶ Gemini (LLM + embeddings)
      │ Firestore read-only mirror  ├─▶ FCM (push)
      └──────────────────────────────▶ Firestore (mirror writes only)
                                     ▲
                                     │ TypeBox schemas
                            ┌────────┴─────────┐
                            │ packages/shared  │ ◀── single source of truth
                            └──────────────────┘
```

Highlight points:
- **Contract-first**: TypeBox schemas in `packages/shared` generate Dart types; mobile cannot drift from API.
- **Polyglot persistence done narrowly**: Postgres is system of record; Firestore mirrors only `alerts` and `my-reports` for offline reads. No two-master consistency problem.
- **Firestore rules** are public-read on `alerts`, owner-read on `my-reports`, **write: false** everywhere — clients cannot write to Firestore. Server-only via Admin SDK.

### Script — Section 5 (≈2 min)

> One diagram, two ideas. First, the dependency arrow. Presentation depends on domain; data depends on domain; domain depends on nothing. That's the dependency-inversion principle written in directory names, and the Architect agent fails any PR that bends it. It's also why this codebase is testable — domain has no Flutter import, so I can run domain tests in plain Dart without spinning up a widget tree.
>
> Second — polyglot persistence done narrowly. We use Postgres as system of record and Firestore as a read-only mirror for two specific things: the alerts feed and a user's own report history. Why? Because offline-first reads on mobile are easier with a Firestore listener than with HTTP polling, but cross-store consistency is hard. By making Firestore strictly a mirror — server-only writes through the Admin SDK, **client writes denied by rules** — we get the offline UX without the two-master problem. The Firestore rules file is forty lines, and most of those are comments explaining the policy.

---

## Section 6 — Reliability, Observability & Quality Gates (2 min)

### Slide 12 — Four Quality Gates

| Gate | How we measure | Where |
|---|---|---|
| **Correctness** | Unit + widget + integration tests. Integration tests hit a **real Postgres**, not a mock — schema drift surfaces here. | `apps/api/test/`, `apps/mobile/test/` |
| **Security** | No plaintext secrets (config files gitignored; see `HOW_TO_CONTRIBUTE.md` §3). Server-side AI calls only. Firestore rules deny by default. Security agent reviews auth/RBAC/secrets PRs. | `firestore.rules`, `.claude/agents/security-reviewer.md` |
| **A11y & performance** | Semantic widgets on AI score card + filter chips. Cached network images. Const constructors enforced by lint. Thai/English localisation 100% parity. | Lint config, l10n ARB files |
| **Observability** | Crashlytics for crashes + non-fatal errors. Structured logs on the API. | `apps/mobile/lib/core/observability/`, server logs |

### Slide 13 — Rollback as a feature flag flip

```dart
// apps/mobile/lib/core/feature_flags/feature_flags.dart
bool isEnabled(String key) => _rc.getBool(key);
```

- Major risky feature this build: **SMS scan overlay banner** — reads incoming SMS via platform channel and surfaces a banner.
- Gated behind `sms_scan_enabled` in **Firebase Remote Config**.
- Rollback path: flip the flag in the Firebase Console → next app launch (or next `fetchAndActivate`) silently disables the feature. **No app store redeploy. No code change. No migration revert.**
- Full rollback playbook: `docs/rollback-plan.md`.

### Script — Section 6 (≈2 min)

> Four quality gates, one for each thing I care about as a release engineer.
>
> Correctness: tests at every layer. The thing I want to highlight is the integration tests — they hit a **real Postgres**, not a mocked Prisma client. I learned the hard way on a previous project that mocked database tests pass right up until your migration breaks in production. Real database, every commit.
>
> Security: no plaintext secrets in the repo; the Firebase config files are gitignored and bootstrapped from examples in CI. Every AI call is server-side, so the Gemini key never ships in an APK. Firestore rules deny by default — we explicitly opened two read paths and one of them is owner-only. Security agent reviews any PR that touches auth or RBAC.
>
> A11y and performance: semantic widgets where verdicts matter, dynamic type scales correctly, list views use `const` constructors so they don't rebuild on scroll. Lint blocks `print`. Hundred-percent string parity between English and Thai — every key in `app_en.arb` exists in `app_th.arb` or we don't ship.
>
> Observability: Crashlytics is wired in `main.dart` before `runApp`. Structured logs on the API.
>
> And the most important slide in this section — **rollback is a config flip, not a deploy**. The riskiest thing we shipped this build is an SMS-scan overlay that reads incoming texts via a platform channel. It's gated behind `sms_scan_enabled` in Firebase Remote Config. If it misbehaves in production, I open the Firebase Console, flip the flag, and the next time the app calls `fetchAndActivate` the feature is gone. No app-store review. No code change. That's the rollback plan.

---

## Section 7 — Conclusion & Next Steps (1 min)

### Slide 14 — Where we land

- **Technically robust**: clean architecture, contract-first schemas, real-database tests, default-deny Firestore rules, observable in production.
- **Business-ready**: cross-platform (Android + Web), Thai-first with English parity, moderator portal live, rollback is a config flip.
- **AI-orchestrated, human-gated**: four role-scoped agents, fresh-session review, human approval mandatory.

### Slide 15 — One lesson learned

> **The hardest part of AI-driven development isn't writing prompts — it's resisting the temptation to merge the AI's first answer.**
>
> The Architect agent in a fresh session catches what the writing agent defends. The human catches what the Architect agent doesn't have a rule for. Each layer of review costs minutes; missing one costs days.

### Slide 16 — Call to action

- **Audit us.** Repo is public on GitHub. `CLAUDE.md` documents the agent setup. CI logs are open.
- **Questions welcome.** Especially on Firestore rules, the contract layer, or the agent prompts themselves.

### Script — Section 7 (≈1 min)

> To close: ScamReport is a Flutter app on Android and Web, an Elysia API on Bun, a Postgres system of record with a narrow Firestore mirror, Thai-first with English parity, observable through Crashlytics, and rollbackable through a single Remote Config flag. It was built by one human and four specialised AI agents under a hard rule: AI writes, AI reviews, **human merges**.
>
> The single thing I learned that I'd tell anyone trying this: the bottleneck in AI-driven development is not generation, it's review. Fresh-session review catches what same-session review misses. Human review catches what no agent has a rule for. Cutting either layer is where production bugs come from.
>
> Repo's on GitHub. Agent prompts are in `.claude/agents/`. CI logs are public. I'd love your audit and your questions.

---

## Q&A — Prep notes (NOT slides; keep these in your head)

Likely questions + crisp answers:

**Q: "How do you know the AI isn't just memorising answers?"**
> The architecture rules are enforced by the Architect *review* agent against the diff, not the writing agent. Fresh session, no shared context. The dependency arrow is checked structurally — does `presentation/` import `data/`? — not by trusting the writer.

**Q: "What happens if Firestore goes down?"**
> Reads degrade to last-cached. Writes don't happen on the client anyway. The mirror is server-side; if the API can't reach Firestore the mirror call is logged + Crashlytics-captured but doesn't fail the Postgres write. User-visible state remains correct.

**Q: "Why TypeBox, not OpenAPI / gRPC?"**
> TypeBox schemas are JSON Schema at runtime, which feeds our Dart codegen, **and** they're directly accepted as Elysia validators. One declaration, three consumers: API runtime validation, TypeScript inference for the admin web, and Dart codegen for mobile. OpenAPI would add a build step; gRPC would mean two protocols.

**Q: "Did the AI write the Firestore rules?"**
> Drafted by the Architect agent, reviewed by Security, signed off by me. Every rule has a comment citing the PRD clause it enforces. Read the file (~40 lines) — comments outweigh code.

**Q: "How many lines of code did you write vs. the AI?"**
> Honest answer: I wrote almost no production code by hand. I wrote prompts, plans, ADRs, design specs, and review comments. The code-to-spec ratio in this repo is roughly inverse to a traditional project — most of my output is in `docs/`, not `lib/`.

**Q: "What would you do differently next time?"**
> Two things. One — write the Architect-agent rules *first*, before any feature. The dependency-arrow rule landed early; it would have saved three or four PRs that needed re-architecting. Two — invest in a "translation parity" CI check earlier; we caught those gaps manually for too long.

**Q: "Show me your tests."**
> `bun run test` from repo root. Integration tests in `apps/api/test/` hit a real Postgres. Widget tests in `apps/mobile/test/features/`. Coverage report is generated on each PR.

**Q: "Walk me through one Firestore rule."**
> Pull up `firestore.rules`. `my-reports/{uid}/items/{reportId}`: `read` allowed iff `request.auth.uid == uid` — owner-only. `write: false` — clients never write; server does via Admin SDK. Default-deny block at the bottom catches anything not explicitly matched.

---

## Pre-flight checklist (run morning of the talk)

- [ ] `bun run dev` — API up on :3000
- [ ] `flutter run -d <android>` — Android build on emulator, logged out
- [ ] `flutter run -d chrome` — Web build on Chrome (second tab)
- [ ] Admin portal logged in as moderator, queue has 2–3 pending reports
- [ ] GitHub repo tab open: README, `firestore.rules`, `docs/architecture.md`, `.claude/agents/`
- [ ] Crashlytics dashboard tab open
- [ ] Phone on Do Not Disturb, screen brightness max
- [ ] Backup APK on USB stick in case live demo fails
- [ ] Bottle of water within arm's reach

---

## Timing rehearsal targets

| Section | Target | Hard cap |
|---|---|---|
| 1. Title & Team | 1:00 | 1:15 |
| 2. Problem & Solution | 2:00 | 2:30 |
| 3. Live Demo | 3:30 | 4:00 |
| 4. Multi-Agent AI | 2:30 | 3:00 |
| 5. Architecture | 2:00 | 2:30 |
| 6. Quality Gates | 2:00 | 2:30 |
| 7. Conclusion | 1:00 | 1:15 |
| **Total** | **14:00** | **17:00** |

Rehearse with a stopwatch twice. If you blow past 17:00, cut Section 4's "forgot-password example" — keep the table on Slide 9.
