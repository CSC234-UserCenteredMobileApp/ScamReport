# ask-ai — Conversational AI Search (P-09)

**PRD:** FR-4 / P-09  **Roles:** guest (gate), user, admin
**Flutter:** `apps/mobile/lib/features/ask_ai/presentation/ask_ai_screen.dart` (planned)
**Route:** `/search` (internal screen key; display label is "Ask AI")

**Snapshots:** `../snapshots/user/search.txt`
**Screenshots:** `../screenshots/user/search.png`

> `docs/design/screens/search.md` is deprecated — do not implement from that file.

## Purpose

Conversational AI interface that lets users describe a suspected scam in natural language and get back guidance, similar past reports, and a reporting prompt. Replaces keyword search (old P-09 spec).

## Layout

### Guest view (sign-in gate)

- Top bar: "Ask AI" title, no back arrow (root tab)
- Gate card:
  - Headline: `Sign up to use Ask AI`
  - Body: `Ask a natural-language question about a scam — like "parcel held SMS from Kerry" — and find similar past reports.`
  - Primary CTA: `Create free account` → `login` (register mode)
  - Ghost CTA: `Maybe later` → dismisses gate, returns to previous tab
- Bottom nav visible (standard 5-tab layout)

### Authenticated view (empty / initial state)

- Top bar: `Ask ScamReport` title + `BETA` badge, no back arrow (root tab)
- Stats line: `Trained on 2,184 community reports` (muted)
- Welcome bubble: `Hi, I'm your scam radar.`
- Prompt body: `Tell me what happened — a weird SMS, a suspicious call, a too-good offer — and I'll tell you if others have seen it.`
- Disclaimer footer: `AI can make mistakes · check important info` (muted)
- Text input + send button at the bottom (above bottom nav)
- Bottom nav visible

## Interactions

- Tapping the input area raises the keyboard; bottom nav stays visible above keyboard.
- Send → appends user bubble, shows typing indicator, then appends AI response bubble.
- AI response may include: plain-text explanation, a list of similar reports (tapping a report navigates to `report-detail`), and a "Report this" CTA that pre-populates `submit-report`.
- Conversation history persists per-session; not persisted across sessions (no server-side history in v1).

## Role variants

| Role | View |
|------|------|
| Guest | Sign-in gate (sign-up CTA + "Maybe later") |
| User | Full chat interface |
| Admin | Full chat interface (same as user; no admin-specific controls) |

## Notes

- Screen key in router is `search`; GoRouter route is `/search`. Do not change the route — deep links and the bottom-nav `setTab('search')` call depend on it.
- The `BETA` badge signals the feature is experimental; pair with the disclaimer footer on all authenticated states.
- Per FR-4.4: Ask AI must not display a Scam / Suspicious / Safe / Unknown verdict label. It guides and surfaces similar reports; it does not classify.
- Bottom nav label is "Ask AI" for guest + user roles. Admin role shows "Moderate" in the 3rd slot (Ask AI tab is still accessible, just not the highlighted tab for admins).
