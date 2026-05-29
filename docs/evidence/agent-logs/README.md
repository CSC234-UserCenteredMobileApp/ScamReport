# Agent logs — per-PR D4 evidence

> CSC234 D4 evidence. One Markdown file per merged PR capturing how the
> four-agent workflow applied to each change. Workflow standard:
> [`docs/ai-workflow.md`](../../ai-workflow.md). Honesty caveat — many
> PRs in the term were reviewed by humans + CI alone rather than a full
> rotation of separate `engineer` / `architect` / `qa` /
> `security-reviewer` Claude Code sessions; per-PR logs distinguish
> what actually ran. See [`docs/audit-report.md`](../../audit-report.md)
> §2.3 and the [Plan-Mode transcript](../plan-mode-transcript.md) for
> the framing.

## Real sessions in the local archive

These are the actual Claude Code sessions captured under
`~/.claude/projects/-home-aok-Projects-mobile-ScamReport*/`:

| Started at          | Session ID                                | First prompt (excerpt)                                        |
| ------------------- | ----------------------------------------- | ------------------------------------------------------------- |
| 2026-05-22T11:51:52 | `038720f5-2e98-4fff-a7a9-078dffada668` | Can you help me set up and run this project? |
| 2026-05-25T13:10:19 | `72315eba-fc5d-40e2-b529-5c385453da9d` | (none captured) |
| 2026-05-25T13:36:33 | `856e9719-6065-4468-9df4-95157ae91af4` | Right now I can't run flutter on chrome can you help me fix that? loo… |
| 2026-05-25T13:42:13 | `0f595506-d859-46ce-b99b-8366cbe60abe` | Base directory for this skill: ~/.claude/skills/setup-matt-po… |
| 2026-05-28T10:25:35 | `b24d22ef-e618-4255-8e54-eb11a3132ce7` | Base directory for this skill: ~/.claude/skills/setup-matt-po… |


## Per-PR index (91 merged PRs)

| PR | Date       | Area   | Title                                                                  | Surfaces touched           |
| -- | ---------- | ------ | ---------------------------------------------------------------------- | -------------------------- |
| [#97](pr-97.md) | 2026-05-29 | docs   | docs: D4 evidence (UJM + rollback drill + PM + runtime + crashlytics) | secrets, uploads |
| [#96](pr-96.md) | 2026-05-28 | mixed  | feat: CSC234 submission — D1 format gate + D2 audit report + D4 evide… | auth, RBAC, Firestore, uploads |
| [#95](pr-95.md) | 2026-05-28 | web    | feat(web): readability pass on ai-eval + dashboard charts | none |
| [#94](pr-94.md) | 2026-05-25 | mobile | fix(api): allow Flutter web dev origins in CORS allowlist | RBAC, cors |
| [#93](pr-93.md) | 2026-05-25 | chore  | chore(cleanup): production polish | auth, secrets |
| [#92](pr-92.md) | 2026-05-17 | mixed  | feat(auth) + fix(moderation): forgot-password flow + queue pagination… | auth, RBAC, validation, cors |
| [#91](pr-91.md) | 2026-05-17 | mobile | feat(announcements): reduce admin create-flow steps on web + mobile | RBAC |
| [#90](pr-90.md) | 2026-05-17 | mixed  | feat(moderation): redesign queue UI with search, filters popover, pag… | RBAC, validation |
| [#89](pr-89.md) | 2026-05-17 | mobile | feat(mobile): wire Crashlytics reporter + non-fatal logging | auth, uploads |
| [#88](pr-88.md) | 2026-05-17 | web    | feat: forgot password, remove Google auth + account deletion, admin UX | auth, RBAC, validation |
| [#87](pr-87.md) | 2026-05-17 | web    | feat(admin): bilingual scam-overview dashboard + crawler ingest | auth, RBAC, Firestore, validation |
| [#86](pr-86.md) | 2026-05-17 | mixed  | fix(ai-eval): propagate eval crashes via set -o pipefail | RBAC, secrets, uploads |
| [#85](pr-85.md) | 2026-05-17 | web    | feat(admin): AI accuracy dashboard + richer /check eval | auth, RBAC, secrets |
| [#84](pr-84.md) | 2026-05-17 | mixed  | feat(seed): drive dev data through real submit+moderate flow | RBAC, Firestore, secrets, uploads |
| [#83](pr-83.md) | 2026-05-17 | web    | feat(admin): bulk report export — CSV + analytics bundle | auth, RBAC, Firestore, uploads, cors |
| [#82](pr-82.md) | 2026-05-16 | mixed  | feat(ai-eval): headless drift alarm — labelled cases + cron | RBAC, secrets, uploads |
| [#81](pr-81.md) | 2026-05-16 | mixed  | feat(db): HNSW index on report_embeddings for fast RAG | validation, uploads |
| [#80](pr-80.md) | 2026-05-16 | web    | feat(web): admin UX improvements — dashboard, search, filters, breadc… | RBAC, validation |
| [#79](pr-79.md) | 2026-05-16 | api    | feat(api): clear report_embeddings on reject + withdraw | RBAC |
| [#78](pr-78.md) | 2026-05-16 | mobile | fix(mobile): hide My Reports and Delete Account for admin in Me tab | RBAC |
| [#77](pr-77.md) | 2026-05-16 | mixed  | feat(ai-score): re-embed on edit + Person fullName in canonical input | RBAC |
| [#76](pr-76.md) | 2026-05-16 | mixed  | feat(reports): persist suspected_name_at_submit end-to-end | RBAC, validation |
| [#75](pr-75.md) | 2026-05-16 | web    | feat(api/pdf): embed evidence images in admin report PDF | auth, RBAC, uploads |
| [#74](pr-74.md) | 2026-05-16 | mixed  | feat: separate scammer entity, AI eval harness, authority dossier | auth, RBAC, validation, uploads |
| [#73](pr-73.md) | 2026-05-15 | chore  | chore: remove GEMINI.md files from project | none |
| [#70](pr-70.md) | 2026-05-13 | mobile | fix(mobile): resolve inconsistent JVM target compatibility | auth |
| [#69](pr-69.md) | 2026-05-13 | mobile | feat(mobile): modernise moderation queue with search + filters (A-01) | auth, RBAC, Firestore, secrets, uploads |
| [#68](pr-68.md) | 2026-05-13 | mobile | feat(mobile): share-to-app routes shared text to Verdict (FR-9.1) | auth, RBAC, Firestore, secrets |
| [#67](pr-67.md) | 2026-05-13 | web    | feat(web): A-04 admin deletion requests page wired to real API | auth, RBAC |
| [#66](pr-66.md) | 2026-05-13 | web    | feat(api,web): A-03 admin announcements editor + subscriber-count | auth, RBAC, Firestore, validation, uploads |
| [#65](pr-65.md) | 2026-05-13 | web    | fix(web): scope optimistic update to queue queries only | RBAC |
| [#64](pr-64.md) | 2026-05-13 | web    | feat(api,web): A-02 admin review detail page | auth, RBAC, validation, uploads |
| [#63](pr-63.md) | 2026-05-13 | mobile | feat(mobile,api): admin moderation UI refresh + report-owner notifica… | auth, RBAC, validation, uploads |
| [#62](pr-62.md) | 2026-05-13 | mixed  | fix(announcements): image URLs from API + editor UX improvements | uploads |
| [#61](pr-61.md) | 2026-05-13 | mobile | feat(mobile): feed/settings/search UX improvements + fix Android netw… | RBAC |
| [#60](pr-60.md) | 2026-05-13 | mobile | feat(mobile+api): My Reports page, Edit Report page, evidence upload | RBAC, Firestore, uploads |
| [#58](pr-58.md) | 2026-05-13 | web    | fix(web): recover from /auth/sync failure instead of trapping on /no-… | auth, RBAC |
| [#57](pr-57.md) | 2026-05-12 | web    | feat(web): scaffold admin web portal (A-01 moderation queue) | auth, RBAC, Firestore, validation, cors |
| [#55](pr-55.md) | 2026-05-12 | mixed  | feat(ask-ai): surface verified reports as evidence cards in chat | auth, RBAC, validation, uploads |
| [#54](pr-54.md) | 2026-05-12 | web    | fix(admin-reports): resolve Firebase UID to users.id before moderatio… | auth, RBAC, Firestore, validation |
| [#53](pr-53.md) | 2026-05-12 | web    | fix(admin-mod): action failure visibility + AI score quality improvem… | auth, RBAC, Firestore, uploads |
| [#52](pr-52.md) | 2026-05-12 | mobile | feat(mobile): Report CTAs open Ask AI with auto-sent seed | auth, RBAC, Firestore, secrets, validation |
| [#51](pr-51.md) | 2026-05-12 | web    | chore(admin-review): refactor AI scoring + render AiScoreCard in queu… | auth, RBAC, validation |
| [#50](pr-50.md) | 2026-05-12 | web    | feat: announcement attachments + admin deletion request review | auth, RBAC, uploads |
| [#49](pr-49.md) | 2026-05-12 | mixed  | fix(ask-ai): surface underlying send error in the retry banner | auth |
| [#48](pr-48.md) | 2026-05-11 | api    | fix(api): resolve admin role from Postgres in requireRole | auth, RBAC |
| [#47](pr-47.md) | 2026-05-11 | web    | feat: admin announcement CRUD + user delete-account request | auth, RBAC, validation |
| [#46](pr-46.md) | 2026-05-10 | web    | refactor(moderation): rewrite A-01 + A-02; drop reporterHandle (FR-7.… | auth, RBAC, Firestore, validation |
| [#45](pr-45.md) | 2026-05-10 | mixed  | feat(ask-ai): iter-5 — server draft sync + language locking + view-dr… | auth, uploads |
| [#44](pr-44.md) | 2026-05-09 | mixed  | feat(search): verified-report search page with filter and sort | validation |
| [#43](pr-43.md) | 2026-05-09 | mixed  | feat(ask-ai): iter-4 — per-conversation draft, redraft preserves edit… | validation, uploads |
| [#42](pr-42.md) | 2026-05-08 | mixed  | feat(ask-ai): iter-3 — session persistence + optimistic send + retry … | uploads |
| [#41](pr-41.md) | 2026-05-08 | mixed  | fix(ask-ai): image-only send + render attachments via signed URLs | validation |
| [#40](pr-40.md) | 2026-05-08 | mixed  | feat(ask-ai): iter-2 polish — smooth send, editor evidence, conversat… | validation, uploads |
| [#38](pr-38.md) | 2026-05-08 | mixed  | fix(ask-ai,reports): resolve internal users.id from firebase_uid | auth, validation, uploads |
| [#37](pr-37.md) | 2026-05-08 | mixed  | feat(ask-ai): P-09 conversational AI chat + reports submit pipeline | auth, RBAC, Firestore, secrets, validation, uploads |
| [#36](pr-36.md) | 2026-05-05 | mobile | fix(ci): remove redundant dart analyze, simplify mobile coverage, add… | auth, validation |
| [#35](pr-35.md) | 2026-05-05 | mixed  | fix(call-screening): persist state, warn instead of block, fix stale … | none |
| [#34](pr-34.md) | 2026-05-04 | mixed  | fix(sms): fix smishing detection pipeline and add system notifications | auth, RBAC |
| [#33](pr-33.md) | 2026-05-04 | api    | feat(api): Phase 3 Gemini AI content analysis in runCheck() | none |
| [#32](pr-32.md) | 2026-05-04 | api    | feat(api): POST /check endpoint — text/phone/url verdict lookup | none |
| [#31](pr-31.md) | 2026-05-04 | mixed  | feat(check): Quick Verdict Check — POST /check + CheckInput/Verdict s… | auth |
| [#30](pr-30.md) | 2026-05-04 | mobile | feat: dynamic backend URL config + Flutter web support | none |
| [#29](pr-29.md) | 2026-05-04 | mixed  | feat: Android call screening — block scam callers offline (FR-9.x) | auth, RBAC, validation |
| [#28](pr-28.md) | 2026-05-04 | mobile | feat(reports): P-04 report detail page — API + mobile | auth, RBAC, secrets, validation, uploads |
| [#27](pr-27.md) | 2026-05-04 | mobile | feat(mobile): SMS smishing detection — on-device scan + alerts integr… | auth, RBAC, validation |
| [#26](pr-26.md) | 2026-05-03 | mobile | feat(mobile): A-01 mod queue + A-02 admin review screens | auth, RBAC, uploads |
| [#25](pr-25.md) | 2026-05-03 | api    | feat: RAG retrieval + admin reports API (A-01/A-02 backend) | auth, RBAC, validation |
| [#24](pr-24.md) | 2026-05-02 | mixed  | feat: crawler import pipeline, pgvector embeddings, schema + codebase… | validation |
| [#23](pr-23.md) | 2026-05-02 | mixed  | feat(alerts): implement AlertsScreen and AnnouncementDetailScreen (P-… | auth, RBAC, validation |
| [#22](pr-22.md) | 2026-05-02 | mixed  | feat: add verified reports feed screen | auth |
| [#21](pr-21.md) | 2026-05-02 | mixed  | feat: sync home screen and bottom nav to 2026-05-01 prototype | RBAC |
| [#20](pr-20.md) | 2026-05-01 | mixed  | design: sync screenshots and snapshots from new bundled prototypes | RBAC |
| [#19](pr-19.md) | 2026-05-01 | mixed  | feat: Ask AI schema (AiMessageAttachment) + stale AI Search cleanup | RBAC, validation, uploads |
| [#18](pr-18.md) | 2026-05-01 | docs   | docs: sync i18n docs and compress CLAUDE.md | auth |
| [#17](pr-17.md) | 2026-04-29 | mixed  | Feat/languages | auth |
| [#16](pr-16.md) | 2026-04-29 | mixed  | feat(home): home screen — AppShell + API routes + shared widgets | RBAC, validation |
| [#15](pr-15.md) | 2026-04-29 | mixed  | Revert "feat(province-filter): regional alerts feed filter (OQ-3 / FR… | auth |
| [#14](pr-14.md) | 2026-04-29 | mixed  | feat(province-filter): regional alerts feed filter (OQ-3 / FR-8.6) | auth, RBAC, Firestore, secrets, validation, uploads |
| [#13](pr-13.md) | 2026-04-29 | mixed  | Feat/legal screens | auth |
| [#12](pr-12.md) | 2026-04-29 | mobile | fix(mobile): tappable Terms/Privacy links in register consent block | auth |
| [#11](pr-11.md) | 2026-04-29 | mobile | feat(mobile): Privacy Policy + Terms of Service screens (P-07/P-08) | auth, RBAC |
| [#10](pr-10.md) | 2026-04-29 | mobile | feat(mobile): guest-first flow + Settings/Me screen (P-12) | auth, RBAC, Firestore, secrets |
| [#9](pr-09.md) | 2026-04-29 | mobile | feat(mobile): Settings / Me screen (P-12 / FR-10.2) | auth, RBAC, Firestore, secrets |
| [#8](pr-08.md) | 2026-04-29 | mobile | feat(mobile): home screen presentation layer | validation |
| [#7](pr-07.md) | 2026-04-28 | ci     | chore(infra): S2 quality gates — coverage, security workflow, .fireba… | auth, RBAC, Firestore, secrets, uploads |
| [#6](pr-06.md) | 2026-04-28 | chore  | chore(codeowners): swap placeholder initials for real GitHub handles | auth |
| [#5](pr-05.md) | 2026-04-28 | chore  | chore(infra): S2 prerequisites — Firestore config, RBAC, sprint board | auth, RBAC, Firestore, validation |
| [#3](pr-03.md) | 2026-04-28 | docs   | update .md file to make it sync with product requirements | none |
| [#2](pr-02.md) | 2026-04-28 | docs   | add gemini-agents and update GEMINI.md | none |
| [#1](pr-01.md) | 2026-04-28 | docs   | Add design flow in docs/design. | none |
